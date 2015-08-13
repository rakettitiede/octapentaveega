;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                             ;;
;;   32 x 14 character VGA output with UART for Attiny85.                      ;;
;;                                                                             ;;
;;                                                                             ;;
;;   Copyright 2015 Jari Tulilahti                                             ;;
;;                                                                             ;;
;;   Licensed under the Apache License, Version 2.0 (the "License");           ;;
;;   you may not use this file except in compliance with the License.          ;;
;;   You may obtain a copy of the License at                                   ;;
;;                                                                             ;;
;;       http://www.apache.org/licenses/LICENSE-2.0                            ;;
;;                                                                             ;;
;;   Unless required by applicable law or agreed to in writing, software       ;;
;;   distributed under the License is distributed on an "AS IS" BASIS,         ;;
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ;;
;;   See the License for the specific language governing permissions and       ;;
;;   limitations under the License.                                            ;;
;;                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "tn85def.inc"
.include "font.inc"

; Registers have been named for easier access.
; in addition we use all of the X, Y and Z
; register pairs for pointers to different buffers
;
; X (r26:r27) is pointer to screen buffer, also used while
;             clearing the screen
; Y (r28:r29) is pointer to either predraw, or currently being
;             drawn buffer
; Z (r30:r31) pointer is used for fetching the data from flash
;             with lpm instruction
;

.def zero		= r0		; Register for value 0
.def one		= r1		; Register for value 1
.def alt		= r2		; Buffer alternating value
.def alt_cnt		= r3		; Buffer alternating counter
.def char_x		= r4		; Predraw-buffer x-offset
.def uart_seq		= r5		; UART sequence
.def uart_next		= r6		; Next UART sequence
.def clear_cnt		= r7		; Screen clear counter
.def uart_byte		= r8		; UART receiving counter & data
.def colors_fg		= r9		; Foreground color
.def colors_bg		= r10		; Background (4..7) color
.def ansi_val1		= r11		; Storage for ANSI cmd value
.def ansi_val2		= r12		; Storage for ANSI cmd value
.def vline_lo		= r13		; Vertical line low byte
.def vline_hi		= r14		; Vertical line high byte
; r15 unused
.def temp		= r16		; Temporary register
.def temp2		= r17		; Temporary register 2
.def font_hi		= r18		; Font Flash addr high byte
.def scroll_lo		= r19		; Screen scroll offset low
.def scroll_hi		= r20		; Screen scroll offset high
.def ansi_state		= r21 		; ANSI command states described below
.def uart_buf		= r22		; UART buffer
.def state		= r23 		; Bitmask for several states described below
.def cursor_lo		= r24		; Cursor offset low
.def cursor_hi		= r25		; Cursor offset high
					; r26 .. r31 described above

; state: (bits)
;
.equ st_clear		= 0		; Screen clear mode active bit
.equ st_wrap		= 1		; Wrap mode active bit
.equ st_uart		= 2		; UART data in buffer
.equ st_scroll		= 3		; Scroll-clear in action
.equ st_clear_val	= (1 << 0)	; Value to set/clear clear mode
.equ st_wrap_val	= (1 << 1)	; Value to set/clear wrap mode
.equ st_uart_val	= (1 << 2)	; Value to set/clear UART buffer state
.equ st_scroll_val	= (1 << 3)	; Value to set/clear scroll-clear state

; ansi_state: (value)
;
; 0 : None
; 1 : ESC received
; 2 : [ Received
; 3: semicolon received


; Constants
;
.equ MY_COLOR	= 7			; Color bits. 7 = all (single attiny)
.equ UART_WAIT	= 130			; HSYNC timer value where we start looking
					; for UART samples (or handle received data)
.equ HSYNC_WAIT	= 157			; HSYNC value where we start precalculating
					; the pixels and drawing to screen
.equ JITTERVAL	= 8			; This must be synced with HSYNC_WAIT value.
					; We want Timer0 counter to be 0-4 in
					; jitterfix label. I used AVR Studio simulator
					; to sync this value.
.equ VSYNC_LOW	= 480 - 256		; Turn VSYNC low on this vertical line
.equ VSYNC_HIGH	= VSYNC_LOW + 2		; Turn VSYNC high on this vertical line
.equ VSYNC_FULL	= 525 - 512		; Full screen is this many lines
.equ VISIBLE	= 452 - 256		; Visible screen area in vlines (+4 lines)
.equ UART_XOR	= 124			; UART sequence magic XORing value
.equ ALT_XOR	= 32			; Buffer flipping value

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
	clr zero			; Zero the zero-register
	clr one
	inc one				; Register to hold value 1

	; Make sure we clear the SRAM first
	;
	sbr state, st_clear_val		; Initiate clear mode
	clr clear_cnt			; Clear counter zeroed
	ldi XL, low(drawbuf)		; Start from the beginning
	ldi XH, high(drawbuf)		; of SRAM

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
	; uart_seq should not be 0 then.
	;
	cp uart_seq, zero
	brne uart_receive

	; Check for start condition
	;
	sbic PINB, UART_PIN		; Skip rjmp if bit is cleared
	rjmp uart_gotdata		; Check if we have data in buffer then

	; Start detected, set values to registers
	;
	ldi temp, 128
	mov uart_byte, temp		; C flag set when byte received
	ldi temp, 24			; First sequence after start
	mov uart_seq, temp		; bit is 4 HSYNC cycles
	ldi temp, 100			; Init next sequence value
	mov uart_next, temp
	rjmp wait_hsync			; Start bit handling done

uart_receive:
	; Seems we are already receiving. Roll the UART
	; sequence variable to see if it's time to sample
	; a bit or not
	;
	ror uart_seq			; Roll sequence right
	brcs uart_sample_seq		; If C flag was set, we sample
	rjmp uart_gotdata		; If not, we check if we have data in buffer

uart_sample_seq:
	; We are ready to sample a bit, but first let's
	; check if we need to update UART sequence
	; (if uart_seq contains value 1) or are we just
	; waiting for stop bit (uart_seq contains 7)
	;
	ldi temp, 3
	cp uart_seq, temp		; Stop bit sequence
	brne uart_seq_update
	clr uart_seq			; Stop bit. Clear uart_seq (wait start bit)
	rjmp wait_hsync			; Go wait for hsync

uart_seq_update:
	cp uart_seq, one
	brne uart_sample		; No need to update sequence
	ldi temp, UART_XOR
	eor uart_next, temp		; Switch between "3,3" and "4" cycles
	mov uart_seq, uart_next 	; and move it to next sequence

uart_sample:
	; Sample one bit from UART and update to screen if needed
	;
	sbic PINB, UART_PIN		; Skip sec if bit is clear
	sec				; Set Carry
	ror uart_byte			; Roll it to UART buffer
	brcs handle_data		; Do we have full byte?
	rjmp wait_hsync			; Not full byte yet

handle_data:
	; We got full byte from UART, buffer it
	;
	ldi temp, 7			; Sequence to wait for stop
	mov uart_seq, temp		; bit.

	mov uart_buf, uart_byte		; Move it to buffer
	sbr state, st_uart_val		; Tell we have data in buffer
	rjmp wait_hsync

uart_gotdata:
	; Check if we have data and handle it
	;
	sbrc state, st_scroll		; We've scrolled, clear one line?
	rjmp scroll_later

	sbrs state, st_uart		; Do we have something in buffer?
	rjmp wait_hsync			; If we don't, go wait HSYNC

	; We do have byte
	;
	cbr state, st_uart_val		; Clear UART buffer state

	cpi uart_buf, 27		; Special case: ESC
	breq handle_esc
	cpi uart_buf, 13		; Special case: CR
	breq handle_cr
	cpi uart_buf, 10		; Special case: LF
	breq handle_lf

	rjmp not_special

handle_esc:
	sbr state, st_clear_val		; Initiate clear mode
	clr clear_cnt			; Clear counter zeroed
	ldi XL, low(drawbuf)		; Start from the beginning
	ldi XH, high(drawbuf)		; of SRAM
	rjmp wait_hsync

handle_cr:
	andi cursor_lo, 224		; First column
	rjmp wait_hsync			; No need to check overflow

handle_lf:
	andi cursor_lo, 224		; First column
	adiw cursor_hi:cursor_lo, 32	; Next line
	rjmp check_cursor_ovf

not_special:
	ldi YL, low(screenbuf)		; Get screenbuffer address
	ldi YH, high(screenbuf)
	add YL, cursor_lo		; Move pointer to cursor
	adc YH, cursor_hi		; location
	st Y, uart_buf			; Store byte
	adiw cursor_hi:cursor_lo, 1	; Increase cursor location

check_cursor_ovf:
	; Check if cursor overflows the screen buffer
	;
	cpi cursor_lo, 192		; Check buffer end
	cpc cursor_hi, one
	brne check_scroll		; Check if we need to scroll

	clr cursor_lo			; End of buffer reached,
	clr cursor_hi			; go back to beginning

check_scroll:
	; If cursor position matches the scroll offset, we're at the
	; end of screen and need to scroll.
	; TODO: If wrap mode disabled, don't scroll!
	;
	cp scroll_lo, cursor_lo
	cpc scroll_hi, cursor_hi	; Cursor at the scroll position?
	breq scroll_screen		; Yes, then we scroll
	rjmp wait_hsync			; If not, just wait HSYNC

scroll_screen:
	; We don't have enough time to scroll now, set scroll to happen
	; later, without loop
	;
	sbr state, st_scroll_val	; Set scrolling to happen later
	rjmp wait_hsync

scroll_later:
	; We're scrolling. Clear the "last line on screen"
	; and move the scroll offset.
	;
	ldi YL, low(screenbuf)		; Load screenbuffer address
	ldi YH, high(screenbuf)
	add YL, scroll_lo		; Add scroll offset
	adc YH, scroll_hi
	ldi temp, 32

	; Store space, unrolled 32 times
	;
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp
	st Y+, temp

	add scroll_lo, temp		; Move scroll offset by 32 bytes
	adc scroll_hi, zero		; (one row)

	cbr state, st_scroll_val	; Remove scroll-later state

	ldi temp, 192
	cp scroll_lo, temp		; Check if scroll needs to
	cpc scroll_hi, one		; roll over
	brne wait_hsync			; No, not yet

	clr scroll_lo			; Overflow, clear scroll offset
	clr scroll_hi

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
	adc ZH, zero
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
	add vline_lo, one
	adc vline_hi, zero
	ldi temp, VISIBLE
	cp vline_lo, temp		; Visible area low byte
	cpc vline_hi, one		; Visible area high byte
	brlo visible_area
	rjmp vertical_sync

visible_area:
	; We are in visible area. Select if we actually draw pixels
	; or not. If we are clearing the screen, no need to draw 
	; pixels.
	;
	sbrs state, st_clear
	rjmp predraw 			; Draw pixels

clear_screen:
	; We jump here if clearing screen
	;
	ldi temp, 64
	ldi temp2, 32

	; First 64 bytes is cleared with zero
	; but the rest with space (32)
	;
	cp clear_cnt, zero 		; Is this first iteration (drawbuf area)
	brne clear_loop 		; Not first, just jump to clearing
	clr temp2			; First iteration emptied with 2

clear_loop:
	st X+, temp2 			; X is set when we get clear command.
	dec temp 			; We clear the whole 512 bytes
	brne clear_loop 		; of memory 64 bytes at a time.

	inc clear_cnt			; Increase counter
	sbrs clear_cnt, 3		; Have we reached 8 yet?
	rjmp wait_uart			; Jump if we haven't

	cbr state, st_clear_val		; Everything cleared, clear state bit
	ldi XL, low(screenbuf)		; Reset X back to beginning of 
	ldi XH, high(screenbuf)		; screen buffer
	clr alt 			; Prevent crap on screen by
	ldi temp, 4 			; resetting alt and 
	mov alt_cnt, temp 		; alternating counter
	clr char_x			; and X-offset after clear
	clr scroll_hi
	clr scroll_lo
	clr cursor_hi
	clr cursor_lo
	rjmp wait_uart			; Done clearing


predraw:
	; Fetch 8 bytes for next drawable line
	; and draw pixels for current line. We repeat each line 4 times
	; so finally we get 32 bytes for the next drawable line and
	; repeat the process. X register already contains pointer to
	; screen buffer, set in "screen_done"
	;
	ldi YL, low(drawbuf)		; Get predraw buffer address
	ldi YH, high(drawbuf)		; to Y register by alternating
	ldi temp, ALT_XOR		; alt with XOR value
	eor alt, temp			; and adding result 
	add YL, alt			; to buffer address, also
	add YL, char_x			; add x-offset
	mov ZH, font_hi			; Font flash high byte

	; Fetch characters using macro, unrolled 8 times
	.macro fetch_char
		ld ZL, X+		; Load char from screen buffer (X) to ZL
		lpm temp, Z		; and fetch font byte from flash (Z)
		st Y+, temp		; then store it to predraw buffer (Y)
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
	ldi YL, low(drawbuf)		; Get current draw buffer address
	ldi YH, high(drawbuf)		; to Y register. Notice we don't add
	ldi temp, ALT_XOR		; the high byte as we've reserved the
	eor alt, temp 			; buffer from low 256 byte space
	add YL, alt			

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
	nop				; Wait for last pixel a while
	out USIDR, zero			; Zero USI data register

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
	rjmp wait_uart			; Return to HSYNC waiting

housekeeping:
	; Advance to next line, alternate buffers
	; and do some other housekeeping after pixels
	; have been drawn
	;
	ldi temp, 4
	mov alt_cnt, temp 		; Reset drawn line counter
	clr char_x			; Reset offset in predraw buffer
	ldi temp, ALT_XOR
	eor alt, temp 			; Alternate between buffers
	inc font_hi			; Increase font line

	; Check if we have drawn one character line
	cpi font_hi, 0x20
	brne housekeep_done		; Not yet full line

	; Scroll support
	;
	ldi temp, high(screen_end)
	cpi XL, low(screen_end)
	cpc XH, temp
	brne no_scr_ovf
	ldi XL, low(screenbuf)
	ldi XH, high(screenbuf)

no_scr_ovf:
	ldi font_hi, 0x18
	rjmp wait_uart

housekeep_done:
	sbiw XH:XL, 32			; Switch screenbuffer back to beginning of line
	rjmp wait_uart			; Return waiting to UART

vertical_sync:
	; Check if we need to switch VSYNC low
	;
	ldi temp, VSYNC_LOW
	cp vline_lo, temp		; Low (478)
	cpc vline_hi, one		; High (478)
	brne check_vsync_high
	cbi PORTB, VSYNC_PIN		; Vsync low
	rjmp wait_uart

check_vsync_high:
	; Check if we need to switch VSYNC high
	;
	ldi temp, VSYNC_HIGH
	cp vline_lo, temp		; Low (480)
	cpc vline_hi, one		; High (480)
	brne check_vlines
	sbi PORTB, VSYNC_PIN		; Vsync high
	rjmp wait_uart

check_vlines:
	; Have we done 525 lines?
	;
	ldi temp2, 2			; High byte (525)
	ldi temp, 13
	cp vline_lo, temp		; Low (525)
	cpc vline_hi, temp2		; High (525)
	breq screen_done

vblank:
	; We are outside visible screen with "nothing to do",
	; except when we are clearing the screen
	;
	sbrc state, st_clear		; If bit it clear, we skip
	rjmp clear_screen 		; the jump to screen clearing
	rjmp wait_uart

screen_done:
	; We have drawn full screen, initialize values
	; back to start values for next refresh
	;
	clr vline_lo			; Vertical line low
	clr vline_hi 			; Vertical line high
	clr alt 			; Alternate value
	ldi temp, 4
	mov alt_cnt, temp		; Alternating counter
	clr char_x			; X offset
	ldi font_hi, 0x18		; Font flash addr high byte

	sbrc state, st_clear		; If we are in screen clearing mode,
	rjmp wait_uart			; skip buffer clearing

	ldi XL, low(screenbuf)		; Pointer to start of 
	ldi XH, high(screenbuf)		; the screen buffer.
	add XL, scroll_lo		; Add scroll offset
	adc XH, scroll_hi		; to address

clear_drawbuf:
	; Write zeroes to line buffer
	;
	ldi YL, low(drawbuf)
	ldi YH, high(drawbuf)
	ldi temp, 32			; Clear 32 bytes

drawbuf_clear_loop:
	st Y+, zero
	dec temp
	brne drawbuf_clear_loop
	rjmp wait_uart
