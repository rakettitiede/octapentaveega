;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                      ;;
;; 32 x 14 character VGA output with UART for Attiny85. ;;
;;                                                      ;;
;; (C) Jari Tulilahti 2015. All right and deserved.     ;;
;;                                                      ;;
;;     //Jartza                                         ;;
;;                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "tn85def.inc"
.include "font.inc"

; Registers have been named for easier access.
; On top of these we use all of the X, Y and Z
; register pairs for pointers to different buffers
;
; X (r26:r27) is pointer to screen buffer
; Y (r28:r29) is pointer to either predraw, or currently being
;             drawn buffer
; Z (r30:r31) pointer is used for fetching the data from flash
;             with lpm instruction
;
.def zero	= r0	; Register containing value 0
.def one	= r1	; Register containing value 1
.def alt	= r2	; Buffer alternating value
.def char_x	= r3	; Predraw-buffer x-offset
.def alt_eor	= r4	; XOR-value to buffer alternating
.def uart_eor	= r5	; XOR-value to UART sequencing
.def uart_seq	= r6	; UART sequence
.def uart_next	= r7	; Next UART sequence
.def clear_mode	= r8 	; Draw pixels or clear screen?
.def clear_cnt	= r9 	; Screen clear counter
.def temp	= r16	; Temporary register
.def font_hi	= r17	; Font Flash addr high byte
.def vline_lo	= r18	; Vertical line low byte
.def vline_hi	= r19	; Vertical line high byte
.def alt_cnt	= r20	; Buffer alternating counter
.def uart_byte	= r21	; UART "buffer"
.def scr_ind_lo	= r24	; UART -> screenbuffer index low byte
.def scr_ind_hi	= r25	; UART -> screenbuffer index high byte

; Some constant values
;
.equ UART_WAIT	= 129	; HSYNC timer value where we start looking
			; for UART samples (or handle received data)
.equ HSYNC_WAIT	= 157	; Here we start precalculating the pixels
			; and drawing to screen
.equ JITTERVAL	= 8	; This must be synced with HSYNC_WAIT value.
			; We want Timer0 counter to be 0-4 in
			; jitterfix label. I used AVR Studio simulator
			; to sync this value

; Pins used for different signals
;
.equ UART_PIN	= PB0	
.equ RGB_PIN	= PB1
.equ VSYNC_PIN	= PB2
.equ HSYNC_PIN	= PB4

; All of the 512 byte SRAM is used for buffers.
; drawbuf is actually used in two parts, 32
; bytes for currently drawn horizontal line and
; 32 bytes for predrawing the next horizontal
; pixel line. Buffer is flipped when single
; line has been drawn 4 times.
;
.dseg
.org 0x60

drawbuf:
	.byte 64
screenbuf:
	.byte 448
screen_end:

; Start the code section. We don't have any
; vectors, instead our main starts at 0x00.
; Also stack is not used, so stack address
; is undefined.
;

.cseg
.org 0x00

main:
	; Set default values to registers
	;
	clr zero		; Zero the zero-register
	clr one
	inc one			; Register to hold value 1
	ldi temp, 32
	mov alt_eor, temp	; Buffer XORing value
	ldi temp, 124
	mov uart_eor, temp	; UART sequence XORing value
	clr scr_ind_hi		; Clear screen index high
	clr scr_ind_lo		; Clear screen index low
	clr clear_mode

	; Set GPIO directions
	;
	sbi DDRB, VSYNC_PIN
	sbi DDRB, RGB_PIN
	sbi DDRB, HSYNC_PIN
	cbi DDRB, UART_PIN

	; Set USI mode
	;
	sbi USICR, USIWM0

set_timers:
	; HSYNC timer. Prescaler 4, Compare value = 159 = 31.8us
	; We generate HSYNC pulse with PWM
	;
	ldi temp, (1 << CTC1) | (1 << CS10) | (1 << CS11);
	out TCCR1, temp
	ldi temp, (1 << PWM1B) | (1 << COM1B1)
	out GTCCR, temp
	ldi temp, 130
	out OCR1A, temp
	ldi temp, 139
	out OCR1B, temp
	ldi temp, 158
	out OCR1C, temp

	; Jitter fix timer. Runs without prescaler.
	;
	ldi temp, (1 << WGM01)
	out TCCR0A, temp
	ldi temp, (1 << CS00)
	out TCCR0B, temp
	ldi temp, 158
	out OCR0A, temp

	; TCNT0 value has been calculated using simulator
	; and clock cycle counting to be in sync with
	; HSYNC timer value in TCNT1 in "jitterfix"
	;
	out TCNT1, zero
	ldi temp, JITTERVAL
	out TCNT0, temp

	; We jump to the end of the VGA routine, setting
	; sane values for the registers for first screen.
	; screen_done jumps back to wait_uart
	;
	rjmp screen_done

wait_uart:
	; Wait for HSYNC timer to reach specified value
	; for UART.
	;
	in temp, TCNT1
	cpi temp, UART_WAIT
	brne wait_uart

uart_handling:
	; Check if we are already receiving,
	; UART buffer should not be 0 then.
	;
	cpi uart_byte, 0
	brne uart_receive

	; Check for start condition
	;
	sbic PINB, UART_PIN	; Skip rjmp if bit is cleared
	rjmp wait_hsync		; (detect start case)

	; Start detected, set values to registers
	;
	ldi uart_byte, 0x80	; C flag set when byte received
	ldi temp, 24		; First sequence after start
	mov uart_seq, temp	; bit is 4 HSYNC cycles
	ldi temp, 100		; Next sequence will be
	mov uart_next, temp	; 3 and 3 cycles
	rjmp wait_hsync		; Start bit handling done

uart_receive:
	; Seems we are already receiving. Roll the UART
	; sequence variable to see if it's time to sample
	; a bit or not
	;
	ror uart_seq		; Roll sequence right
	brcs uart_sample_seq	; If C flag was set, we sample
	rjmp wait_hsync		; If not, we just continue

uart_sample_seq:
	; We are ready to sample a bit, but first let's
	; check if we need to update UART sequence
	; (if uart_seq contains value 1) or are we just
	; waiting for stop bit (uart_seq contains 7)
	;
	ldi temp, 7
	cp uart_seq, temp	; Stop bit sequence
	brne uart_seq_update
	clr uart_byte		; Waited to stop, clear uart_byte
	rjmp wait_hsync		; Go wait for hsync

uart_seq_update:
	cp uart_seq, one
	brne uart_sample	; No need to update sequence
	eor uart_next, uart_eor	; Switch between "3,3" and "4" cycles
	mov uart_seq, uart_next ; and move it to next sequence

uart_sample:
	; Sample one bit from UART and update to screen if needed
	;
	sbic PINB, UART_PIN	; Skip sec if bit is clear
	sec			; Set Carry
	ror uart_byte		; Roll it to UART buffer
	brcs handle_data	; Do we have full byte?
	rjmp wait_hsync		; Not full byte yet

handle_data:
	; We got full byte from UART, handle it
	;
	cpi uart_byte, 27		; Special case: ESC
	breq handle_esc
	cpi uart_byte, 13		; Special case: Enter
	breq handle_enter
	rjmp not_special

handle_esc:
	mov clear_mode, one 		; Initiate clear mode
	clr scr_ind_lo			; Clear screen buffer index
	clr scr_ind_hi
	clr clear_cnt			; Clear counter zeroed
	ldi XL, low(drawbuf)		; Start from the beginning
	ldi XH, high(drawbuf)		; of SRAM
	rjmp check_index_overflow

handle_enter:
	andi scr_ind_lo, 224		; Beginning of line
	adiw scr_ind_hi:scr_ind_lo, 32	; Next line
	rjmp check_index_overflow

not_special:
	ldi YL, low(screenbuf)	; Get screenbuffer address
	ldi YH, high(screenbuf)	; 
	add YL, scr_ind_lo	; Add screen index to 
	adc YH, scr_ind_hi	; buffer address
	st Y, uart_byte		; Store byte to screenbuffer

	; Advance screen buffer index
	;
	adiw scr_ind_hi:scr_ind_lo, 1

check_index_overflow:
	ldi temp, 60		; Sequence to wait for stop
	mov uart_seq, temp	; bit. We also put temp data
	mov uart_byte, temp	; in UART buffer (skip start detect)

	; Check if screen index has overflown and reset
	;
	ldi temp, 0xC0
	cp scr_ind_lo, temp	; Compare low (448)
	cpc scr_ind_hi, one	; Compare high (448)
	brlo wait_hsync		; No overflow, wait hsync
	clr scr_ind_hi		; Clear hi
	clr scr_ind_lo		; Clear low

wait_hsync:
	; Wait for HSYNC timer to reach specified value
	; for screen drawing
	;
	in temp, TCNT1
	cpi temp, HSYNC_WAIT
	brne wait_hsync

jitterfix:
	; Read Timer0 counter and jump over nops with
	; ijmp using the value to fix the jitter
	;
	in temp, TCNT0
	ldi ZL, low(jitternop)
	ldi ZH, high(jitternop)
	add ZL, temp
	add ZH, zero
	ijmp

jitternop:
	; If timer start value is good, we jump over 0-4 nops
	;
	nop
	nop
	nop
	nop

check_visible:
	; Check if we are in visible screen area or in vertical blanking
	; area of the screen
	;
	add vline_lo, one	; Increase vertical line counter
	adc vline_hi, zero	; Increase high byte
	cpi vline_lo, 0xC4	; Visible area low byte (452)
	cpc vline_hi, one	; Visible area high byte (452)
	brlo visible_area
	rjmp vertical_blank

visible_area:
	; We are in visible area. Select if we actually draw pixels
	; or not. If we are clearing the screen, no need to draw 
	; pixels and we save cycles.
	;
	ldi ZL, low(visible_jumps)
	ldi ZH, high(visible_jumps)
	add ZL, clear_mode
	adc ZH, zero
	ijmp

visible_jumps:
	rjmp predraw 		; Draw pixels

clear_screen:
	; We jump here if clearing screen
	;
	ldi temp, 64

clear_loop:
	st X+, zero 		; X is set when we get clear command.
	dec temp 		; We clear the whole 512 bytes
	brne clear_loop 	; of memory 64 bytes at a time.

	inc clear_cnt
	sbrs clear_cnt, 3
	brne clear_next		; Not done yet

	clr clear_mode		; Done
	ldi XL, low(screenbuf)	; Reset X back to beginning of 
	ldi XH, high(screenbuf)	; screen buffer


clear_next:
	rjmp wait_uart		; Don't draw pixels


predraw:
	; Fetch 8 bytes for next drawable line
	; and draw pixels for current line. We repeat each line 4 times
	; so finally we get 32 bytes for the next drawable line and
	; repeat the process. X register already contains pointer to
	; screen buffer, set in "screen_done"
	;
	ldi YL, low(drawbuf)	; Get predraw buffer address
	ldi YH, high(drawbuf)	; to Y register by alternating
	eor alt, alt_eor	; alt with alt_eor and adding
	add YL, alt		; to buffer address, also
	add YL, char_x		; add x-offset
	mov ZH, font_hi		; Font flash high byte

	; Fetch characters using macro, unrolled 8 times
	.macro fetch_char
		ld ZL, X+	; Load char from screen buffer (X) to ZL
		lpm temp, Z	; and fetch font byte from flash (Z)
		st Y+, temp	; then store it to predraw buffer (Y)
	.endmacro

	fetch_char
	fetch_char
	fetch_char
	fetch_char
	fetch_char
	fetch_char
	fetch_char
	fetch_char
	
	; Draw pixels, pushing them out from USI. We repeat this
	; 32 times using macro, without looping, as timing is important
	;
	ldi YL, low(drawbuf)	; Get current draw buffer address
	ldi YH, high(drawbuf)	; to Y register. Notice we don't add
	eor alt, alt_eor	; the high byte as we've reserved the
	add YL, alt		; buffer from low 256 byte space

	.macro draw_char
		ld temp, Y+
		out USIDR, temp
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
	.endmacro

	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char
	draw_char

	; Make sure we don't draw to porch
	;
	nop			; Wait for last pixel a while
	out USIDR, zero		; Zero USI data register

check_housekeep:
	; Increase predraw buffer offset by 8
	;
	ldi temp, 8
	add char_x, temp

	; If we have drawn the current line 4 times,
	; time to do some housekeeping.
	;
	dec alt_cnt
	breq housekeeping
	rjmp wait_uart		; Return to HSYNC waiting

housekeeping:
	; Advance to next line, alternate buffers
	; and do some other housekeeping after pixels
	; have been drawn
	;
	ldi alt_cnt, 4		; Reset drawn line counter
	clr char_x		; Reset offset in predraw buffer
	eor alt, alt_eor	; Alternate between buffers
	inc font_hi		; Increase font line

	; Check if we have drawn one character line
	cpi font_hi, 0x20
	brne housekeep_done	; Not yet
	ldi font_hi, 0x18
	rjmp wait_uart

housekeep_done:
	sbiw XH:XL, 32		; Switch screenbuffer back to beginning of line
	rjmp wait_uart		; Return waiting to UART

vertical_blank:
	; Check if we need to switch VSYNC low
	;
	cpi vline_lo, 0xDE	; Low
	cpc vline_hi, one	; High
	brne check_vsync_off
	cbi PORTB, VSYNC_PIN	; Vsync low
	rjmp wait_uart

check_vsync_off:
	; Check if we need to switch VSYNC high
	;
	cpi vline_lo, 0xE0	; Low
	cpc vline_hi, one	; High
	brne check_vlines
	sbi PORTB, VSYNC_PIN	; Vsync high
	rjmp wait_uart

check_vlines:
	; Have we done 525 lines?
	;
	ldi temp, 2		; High byte (525)
	cpi vline_lo, 0x0D	; Low (525)
	cpc vline_hi, temp	; High (525)
	breq screen_done

vblank:
	; We are outside visible screen with "nothing to do",
	; except when we are clearing the screen
	;
	sbrc clear_mode, 0	; If bit it clear, we skip
	rjmp clear_screen 	; the jump to screen clearing
	rjmp wait_uart

screen_done:
	; We have drawn full screen, initialize values
	; back to start values for next refresh
	;
	clr vline_lo		; Vertical line low
	clr vline_hi 		; Vertical line high
	clr alt 		; Alternate value
	ldi alt_cnt, 4		; Alternating counter
	clr char_x		; X offset
	ldi font_hi, 0x18	; Font flash addr high byte

	sbrc clear_mode, 0	; If we are in screen clearing mode,
	rjmp wait_uart		; skip buffer clearing

	ldi XL, low(screenbuf)	; Pointer to start of 
	ldi XH, high(screenbuf)	; the screen buffer

clear_drawbuf:
	; Write zeroes to line buffer
	;
	ldi YL, low(drawbuf)
	ldi YH, high(drawbuf)
	ldi temp, 32

drawbuf_clear_loop:
	; Loop 32 times
	;
	st Y+, zero
	dec temp
	brne drawbuf_clear_loop
	rjmp wait_uart
