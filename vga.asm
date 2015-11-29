;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                            ;;
;;  32 x 14 character VGA output with UART for Attiny85.                      ;;
;;                                                                            ;;
;;  (C) Copyright 2015 Jari Tulilahti                                         ;;
;;                                                                            ;;
;;  All right and deserved.                                                   ;;
;;                                                                            ;;
;;  Licensed under the Apache License, Version 2.0 (the "License");           ;;
;;  you may not use this file except in compliance with the License.          ;;
;;  You may obtain a copy of the License at                                   ;;
;;                                                                            ;;
;;      http://www.apache.org/licenses/LICENSE-2.0                            ;;
;;                                                                            ;;
;;  Unless required by applicable law or agreed to in writing, software       ;;
;;  distributed under the License is distributed on an "AS IS" BASIS,         ;;
;;  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ;;
;;  See the License for the specific language governing permissions and       ;;
;;  limitations under the License.                                            ;;
;;                                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
.def one 		= r1		; Register for value 1
.def alt 		= r2		; Buffer alternating value
.def alt_cnt		= r3		; Buffer alternating counter
.def char_x		= r4		; Predraw-buffer x-offset
.def uart_seq		= r5		; UART sequence
.def uart_next		= r6		; Next UART sequence
.def clear_cnt		= r7		; Screen clear counter
.def uart_byte		= r8		; UART receiving counter & data
.def color_fg		= r9		; Foreground color
.def color_bg		= r10		; Background (4..7) color
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
.def state		= r23 		; Bitmask for states described below
.def cursor_lo		= r24		; Cursor offset low
.def cursor_hi		= r25		; Cursor offset high
					; r26 .. r31 described above

; state: (bits)
;
.equ st_clear		= 0		; Screen clear mode active bit
.equ st_wrap		= 1		; Wrap mode active bit
.equ st_uart		= 2		; UART data in buffer
.equ st_scroll		= 3		; Scroll-clear in action
.equ st_left		= 4		; Scroll row left
.equ st_row_first 	= 5		; Scroll row left, first half
.equ st_clear_val 	= (1 << 0)	; Value to set/clear clear mode
.equ st_wrap_val 	= (1 << 1)	; Value to set/clear wrap mode
.equ st_uart_val 	= (1 << 2)	; Value to set/clear UART buffer state
.equ st_scroll_val 	= (1 << 3)	; Value to set/clear scroll-clear state
.equ st_left_val 	= (1 << 4)	; Value to set/clear row-scroll
.equ st_row_first_val 	= (1 << 5)	; Value to set/clear first-half-scroll

; ansi_state: (value)
;
; 0 : None
; 1 : ESC received
; 2 : Opening bracket "[" received
; 3 : Two values received


; Constants
;
.equ UART_WAIT		= 130		; HSYNC timer value where we start to
					; look for UART samples (or handle
					; data received)
.equ HSYNC_WAIT		= 157		; HSYNC value to start precalculating
					; the pixels and drawing to screen
.equ JITTERVAL		= 8		; Must be in sync with HSYNC_WAIT value.
					; We want Timer0 counter to be 0-4 in
					; jitterfix label. AVR Studio simulator
					; was used to sync this value.
.equ VSYNC_LOW		= 480 - 256	; Turn VSYNC low on this vertical line
.equ VSYNC_HIGH		= VSYNC_LOW + 2	; Turn VSYNC high on this vertical line
.equ VSYNC_FULL		= 525 - 512	; Full screen is this many lines
.equ VISIBLE		= 452 - 256	; Visible vline count (+4 lines)
.equ UART_XOR		= 124		; UART sequence magic XORing value
.equ UART_INIT 		= 100		; UART sequence initial value after start
.equ UART_FIRST 	= 24		; UART first sequence
.equ ALT_XOR		= 32		; Buffer flipping value
.equ DEFAULT_COLOR_FG 	= 7		; White foreground
.equ DEFAULT_COLOR_BG 	= 0		; Black background

; Pins used for different signals
;
.equ UART_PIN	= PB0	
.equ RGB_PIN	= PB1
.equ VSYNC_PIN	= PB2
.equ HSYNC_PIN	= PB4

; General purpose IO registers used as storage
;
.equ LEFT_CNT	= GPIOR0

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

; Start the code section. 
; Only two vectors used. RESET for all versions
; and INT0 for slaves (synchronization)
.cseg
.org 0x00

vectors:
	rjmp main
.ifdef VGA_SLAVE
	rjmp slave_sync
.endif

main:
	; Set default values to registers
	;
	clr zero			; Zero the zero-register
	clr uart_seq 			; Zero UART sequence
	clr uart_next 			; Zero UART next
	clr state			; Zero state
	clr vline_lo			; Vertical line low
	clr vline_hi 			; Vertical line high
	clr alt 			; Alternate value
	ldi temp, 4
	mov alt_cnt, temp		; Alternating counter
	clr char_x			; X offset
	ldi font_hi, 0x18		; Font flash addr high byte

	clr one				; Register to hold
	inc one				; the value 1

	; Enable wrap-mode by default
	;
	sbr state, st_wrap_val

	; Set default colors
	;
	ldi temp, DEFAULT_COLOR_FG
	mov color_fg, temp		; Default foreground
	ldi temp, DEFAULT_COLOR_BG
	mov color_bg, temp		; Default background

	; Make sure we clear the screen right after start
	;
	sbr state, st_clear_val		; Initiate clear mode
	clr clear_cnt			; Clear counter zeroed
	ldi XL, low(drawbuf)		; Start from the beginning
	ldi XH, high(drawbuf)		; of SRAM

	; Set GPIO directions
	;
.ifdef VGA_MASTER

	sbi DDRB, HSYNC_PIN		; Master drives both HSYNC
	sbi DDRB, VSYNC_PIN		; and VSYNC
.else
	cbi DDRB, VSYNC_PIN		; Slave sync to VSYNC, set as input
	sbi PORTB, VSYNC_PIN		; Enable pull-up
.endif
	sbi DDRB, RGB_PIN
	cbi DDRB, UART_PIN
	; 
	; Enable UART PULL-UP
	sbi PORTB, UART_PIN

	; Set USI mode
	;
	sbi USICR, USIWM0


.ifdef VGA_SLAVE

	slave_setup:
		; Slave synchronization happens with INT0, which listens
		; to falling edge of VSYNC. We also put the slave to
		; sleep-mode IDLE, from sleep we get jitter-free jump
		; to ISR. We never return from ISR and we don't use stack
		; so we don't care about stack pointer nor the return
		; address in stack. 
		;

		; First we delay for a moment - waiting for the power to 
		; stabilize and giving master some time to start VSYNC
		; properly (50 millisecondish delay)

		ldi temp, 16

	waiting:
		clr ZH
		clr ZL

	wait_a_bit:
		sbiw ZH:ZL, 1
		brne wait_a_bit		; Loop 65536 times

		dec temp
		brne waiting		; Loop 65536 * 16 times

		ldi temp, (1 << INT0)
		out GIMSK, temp		; Enable INT0

		ldi temp, (1 << SE) | (1 << ISC01)
		out MCUCR, temp		; Enable sleep and edge INT0

		sei			; Enable interrupts

		sleep			; Go to sleep

	slave_sync:
		; We continue here after INT0 has triggered.
		;
		cli
		out GIMSK, zero		; Disable interrupts

		; Sync vertical line
		;
		ldi temp, 225
		mov vline_lo, temp
		mov vline_hi, one

		; Delay for final sync
		;
		ldi temp, 192
	slave_wait:
		dec temp
		brne slave_wait

		nop
		nop
		nop
		nop
		nop

.endif


set_timers:
	; HSYNC timer. Prescaler 4, Compare value = 159 = 31.8us
	; We generate HSYNC pulse with PWM
	;
	ldi temp, (1 << CS10) | (1 << CS11);
	out TCCR1, temp

	; Slave has comparator B disconnected from output pin
.ifdef VGA_MASTER
	ldi temp, (1 << PWM1B) | (1 << COM1B1)
.else
	ldi temp, (1 << PWM1B)
.endif
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
	ldi temp, UART_FIRST		; First sequence after start
	mov uart_seq, temp		; bit is 4 HSYNC cycles
	ldi temp, UART_INIT		; Init next sequence value
	mov uart_next, temp
	rjmp wait_hsync			; Start bit handling done

uart_receive:
	; Seems we are already receiving. Roll the UART
	; sequence variable to see if it's time to sample
	; a bit or not
	;
	ror uart_seq			; Roll sequence right
	brcs uart_sample_seq		; If C flag was set, we sample
	rjmp uart_gotdata		; If not, check if we got data in buffer

uart_sample_seq:
	; We are ready to sample a bit, but first let's
	; check if we need to update UART sequence
	; (if uart_seq contains value 1) or are we just
	; waiting for stop bit (uart_seq contains 7)
	;
	ldi temp, 3
	cp uart_seq, temp		; Stop bit sequence
	brne uart_seq_update
	clr uart_seq			; Stop bit. Clear uart_seq (wait start)
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

	sbrc state, st_left
	rjmp row_left

	sbrs state, st_uart		; Do we have something in buffer?
	rjmp wait_hsync			; If we don't, go wait HSYNC

	cbr state, st_uart_val		; We have byte, clear UART buffer state

	cpse ansi_state, zero		; Are we in ANSI handling mode?
	rjmp handle_ansi		; Yes we are, jump to handle ansi

	cpi uart_buf, 27		; Special case: ESC
	breq handle_esc
	cpi uart_buf, 13		; Special case: CR
	breq handle_cr_or_lf
	cpi uart_buf, 10		; Special case: LF
	breq handle_cr_or_lf
	cpi uart_buf, 8			; Special case: BS
	breq handle_bs

	rjmp not_special

handle_bs:
	; Backspace
	;
	cp scroll_lo, cursor_lo
	cpc scroll_hi, cursor_hi	; Cursor at 0,0?
	breq backspace_done		; Yes. Do nothing


	cp cursor_lo, zero
	cpc cursor_hi, zero
	brne backspace_no_ovf		; No overflow

	ldi cursor_lo, 192		; Reset cursor location
	ldi cursor_hi, 1

backspace_no_ovf:
	sbiw cursor_hi:cursor_lo, 1 	; Move cursor backwards
	ldi uart_buf, 32
	ldi YL, low(screenbuf)		; Get screenbuffer address
	ldi YH, high(screenbuf)
	add YL, cursor_lo		; Move pointer to cursor
	adc YH, cursor_hi		; location
	st Y, uart_buf			; Store byte

backspace_done:
	rjmp wait_hsync


handle_esc:
	; ESC received, commence ANSI-escape parsing mode
	;
	ldi ansi_state, 1		; Set ANSI parsing mode on
	clr ansi_val1			; Clear ANSI values
	clr ansi_val2			; Clear ANSI values
	rjmp wait_hsync

handle_cr_or_lf:
	; We treat CR and LF the same
	;
	andi cursor_lo, 224		; First column
	adiw cursor_hi:cursor_lo, 32	; Next line
	rjmp check_cursor_ovf

not_special:
	; Not special, store character into buffer
	;
	mov temp, color_fg
	sbrs temp, COLOR_BIT		; skip if fg_color has our bit.
	rjmp no_fg_match

	mov temp, color_bg		; Check if bg_color has our bit.
	sbrc temp, COLOR_BIT		; Skip if it does not (store byte as-is)
	ldi uart_buf, 160		; fg & bg both match = reverse space
	rjmp store_char_to_buffer

no_fg_match:
	mov temp, color_bg		; Check if bg_color has our bit.
	sbrs temp, COLOR_BIT
	rjmp no_fg_bg_match		; Neither fore or background matches.

	ldi temp, 128
	eor uart_buf, temp		; Only background matches, reverse char
	rjmp store_char_to_buffer

no_fg_bg_match:
	ldi uart_buf, 32		; Store space if color doesn't match

store_char_to_buffer:
	ldi YL, low(screenbuf)		; Get screenbuffer address
	ldi YH, high(screenbuf)
	add YL, cursor_lo		; Move pointer to cursor
	adc YH, cursor_hi		; location
	st Y+, uart_buf			; Store byte

	sbrs state, st_wrap		; Check wrap mode
	rjmp no_wrap_increase		; Non-wrap mode

	adiw cursor_hi:cursor_lo, 1	; Increase cursor location
	rjmp check_cursor_ovf		; Normally in wrap-mode

no_wrap_increase:
	mov temp, cursor_lo		; We're in no-wrap-mode
	andi temp, 31			; Check if end-of-row
	cpi temp, 31
	breq check_cursor_ovf		; End-of-row, don't inc cursor
	adiw cursor_hi:cursor_lo, 1	; Otherwise increase cursor location

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

handle_ansi:
	; ANSI Escape handling
	;
	cpse ansi_state, one		; Do we have bracket yet?
	rjmp ansi_data			; Yes we do

	; Check for bracket
	;
	ldi temp, 91			; Ascii 91 = [
	cpse uart_buf, temp		; Was next character bracket?
	rjmp unknown_ansi		; No it was not..

	ldi ansi_state, 2		; Got bracket
	rjmp wait_hsync			; Go wait for HSYNC

ansi_data:
	; Handle ANSI values and commands.
	; If command has multiple values separated by semicolon
	; we only store the last two
	;
	cpi uart_buf, 59		; Ascii 59 = ;
	brne ansi_notsemi		; Was not semicolon

	; 
	; Got value separator (semicolon)
	mov ansi_val2, ansi_val1	; Move data to 2nd buffer
	clr ansi_val1			; And clear 1st buffer
	ldi ansi_state, 3		; Tell we have more than 1 value

	rjmp wait_hsync

ansi_notsemi:
	; Was not semicolon. Check if we got number or command
	;
	cpi uart_buf, 65		; Crude separation to numbers & letters
	brsh ansi_command		; It's command letter

ansi_value:
	; Value parser
	;
	mov temp, ansi_val1		; Multiply existing value by 10
	lsl ansi_val1			; ((n << 2) + n) << 1
	lsl ansi_val1
	add ansi_val1, temp
	lsl ansi_val1

	subi uart_buf, 48		; Subtract ascii value for "0"
	add ansi_val1, uart_buf		; Add result to value

	rjmp wait_hsync			; Wait for HSYNC

ansi_command:
	; Parse ANSI command
	;
	cpi uart_buf, 109		; m = set color
	breq ansi_set_color
	cpi uart_buf, 72		; H = move cursor
	breq ansi_move_xy
	cpi uart_buf, 102		; f = move cursor
	breq ansi_move_xy
	cpi uart_buf, 74		; J = clear screen
	breq ansi_clear_screen
	cpi uart_buf, 104		; h = enable wrap
	breq ansi_enable_wrap
	cpi uart_buf, 108		; l = disable wrap (lower case L)
	breq ansi_disable_wrap
	cpi uart_buf, 91		; [ = scroll row left
	breq ansi_scroll_row_left

	;
	; Unknown, dismiss ANSI
	clr ansi_state
	rjmp wait_hsync

ansi_scroll_row_left:
	sbr state, st_left_val		; Set row scrolling to happen later
	sbr state, st_row_first_val 	; and clear half a row at a time
	rjmp ansi_done

ansi_move_xy:
	clr cursor_hi			; Calculate cursor location
	mov cursor_lo, ansi_val2
	swap cursor_lo			; Shift left 4 times
	lsl cursor_lo			; shift once more = * 32
	rol cursor_hi			; push high bit to cursor_hi
	add cursor_lo, ansi_val1

	add cursor_lo, scroll_lo	; Add scroll offset to
	adc cursor_hi, scroll_hi	; cursor

	cpi cursor_lo, 192		; check if cursor overflows
	cpc cursor_hi, one		; the screen buffer
	brlo no_move_overflow

	subi cursor_lo, 192		; compensate overflow
	sbc cursor_hi, one		; by subtracting 448

no_move_overflow:
	rjmp ansi_done

ansi_enable_wrap:
	; Enable wrap
	;
	ldi temp, 157			; Check value
	cpse ansi_val1, temp		; ?7h = enable wrap
	rjmp ansi_done
	sbr state, st_wrap_val
	rjmp ansi_done

ansi_disable_wrap:
	; Disable wrap
	;
	ldi temp, 157			; Check value
	cpse ansi_val1, temp		; ?7l = disable wrap
	rjmp ansi_done
	cbr state, st_wrap_val
	rjmp ansi_done

ansi_clear_screen:
	; Screen clear
	;
	ldi temp, 2			; Check value
	cp ansi_val1, temp		; 2J = clear screen
	breq ansi_commence_clear
	clr ansi_state			; Dismiss, invalid number
	rjmp wait_hsync


ansi_commence_clear:
	; 2J received, clear the screen when we have time
	;
	sbr state, st_clear_val		; Initiate clear mode
	clr clear_cnt			; Clear counter zeroed
	ldi XL, low(drawbuf)		; Start from the beginning
	ldi XH, high(drawbuf)		; of SRAM
	clr ansi_state
	rjmp wait_hsync

unknown_ansi:
	; Unknown ANSI escape after ESC. If it's not left scroll
	; just print it into buffer
	;
	clr ansi_state

	ldi temp, 68			; Ascii 91 = D
	cpse uart_buf, temp		; Was it left scroll?
	rjmp not_special		; No it was not..

	in temp, LEFT_CNT		; Increase the
	ldi temp2, 32 			; screen left scroll
	cpse temp, temp2		; counter up to 32
	inc temp			; but not over it
	out LEFT_CNT, temp

	rjmp wait_hsync

ansi_set_color:
	; Set colors. We do same check for both values.
	;
	cp ansi_val1, zero		; Reset colors?
	breq ansi_color_reset

ansi_set_color_val:
	; Only check reset once
	;
	ldi temp, 40
	cp ansi_val1, temp		; Back- or foreground color?
	brlo ansi_color_fg		; Set foreground

	sub ansi_val1, temp		; Get real color value
	mov color_bg, ansi_val1		; Set it as background
	rjmp ansi_color_next

ansi_color_fg:
	; Color was foreground
	; 
	ldi temp, 30
	sub ansi_val1, temp		; Get real color value
	mov color_fg, ansi_val1		; Move it to foreground color

ansi_color_next:
	ldi temp, 3
	cpse ansi_state, temp		; Check for more values
	rjmp ansi_done			; No more values, we're done

	mov ansi_val1, ansi_val2	; Copy second value
	dec ansi_state			; No more values (max 2)
	rjmp ansi_set_color_val		; Do it again

ansi_color_reset:
	ldi temp, DEFAULT_COLOR_FG
	mov color_fg, temp		; Default foreground color
	ldi temp, DEFAULT_COLOR_BG
	mov color_bg, temp		; Default background color
	rjmp ansi_color_next

ansi_done:
	clr ansi_state			; Done Parsing ANSI
	rjmp wait_hsync			; Wait for HSYNC

row_left:
	; Scroll row left, one half at a time
	;
	ldi YL, low(screenbuf)		; Get screenbuffer address
	ldi YH, high(screenbuf)
	add YL, scroll_lo		; Add scroll offset low
	adc YH, scroll_hi		; Add scroll offset high

	clr temp2			; Calculate row address
	mov temp, ansi_val1 		; Take row number from ansi val1
	lsl temp 			; and multiply by 32
	lsl temp			; with left shifting 5 times
	lsl temp
	lsl temp
	lsl temp
	rol temp2

	add YL, temp 			; Add row address to screen
	adc YH, temp2 			; buffer address

	ldi temp, 2
	cpi YL, low(screen_end) 	; check for screen buffer
	cpc YH, temp			; address overflow
	brlo row_left_start

	subi YL, 192			; compensate overflow
	sbc YH, one			; by subtracting 448

row_left_start:
	sbrs state, st_row_first 	; First half of screen?
	rjmp row_left_second 		; nope, second

	.macro scr_left
		ldd temp, Y+1
		st Y+, temp
	.endmacro

	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left

	cbr state, st_row_first_val
	rjmp wait_hsync

row_left_second:
	; Second half of row-left-scroll
	;
	ldi temp, 16
	add YL, temp
	adc YH, zero

	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left
	scr_left

	ldi temp, 32
	st Y, temp

	cbr state, st_left_val
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

	; First 64 bytes (hline buffer) is cleared with zero
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
		ld temp, Y+		; Load byte from hline buffer, inc Y
		out USIDR, temp		; Throw byte into USI data register
		sbi USICR, USICLK	; Clock bit out to wire
		sbi USICR, USICLK	; Clock bit out to wire
		sbi USICR, USICLK	; Clock bit out to wire
		sbi USICR, USICLK	; Clock bit out to wire
		sbi USICR, USICLK	; Clock bit out to wire
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
	sbiw XH:XL, 32			; Switch screenbuffer back to 
					; the beginning of line
	rjmp wait_uart			; Return waiting to UART

vertical_sync:
	; Check if we need to switch VSYNC low
	; Only Master does this.
	;
.ifdef VGA_MASTER
	ldi temp, VSYNC_LOW
	cp vline_lo, temp		; Low
	cpc vline_hi, one		; High
	brne check_vsync_high
	cbi PORTB, VSYNC_PIN		; Vsync low
	rjmp wait_uart

check_vsync_high:
	; Check if we need to switch VSYNC high
	;
	ldi temp, VSYNC_HIGH
	cp vline_lo, temp		; Low
	cpc vline_hi, one		; High
	brne check_vlines
	sbi PORTB, VSYNC_PIN		; Vsync high
	rjmp wait_uart
.endif

check_vlines:
	; Have we done 525 lines?
	;
	ldi temp2, 2			; High byte (525)
	ldi temp, 13
	cp vline_lo, temp		; Low (525)
	cpc vline_hi, temp2		; High (525)
	breq screen_done

vblank:
	; We are outside visible screen
	;
	sbrc state, st_clear		; If bit it clear, we skip
	rjmp clear_screen 		; the jump to screen clearing

	ldi temp, VSYNC_HIGH + 1	; VSYNC back portch has begun?
	cp vline_lo, temp		; Low
	cpc vline_hi, one		; High
	brge check_vblank_scroll

	rjmp wait_uart			; Not yet back porch

check_vblank_scroll:
	in temp, LEFT_CNT		; Do we need to scroll screen left?
	cpse zero, temp			; Skip next command if we don't
	rjmp scroll_screen_left		; Yes we do, jump to scroll
	rjmp wait_uart			; No we don't need to

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

scroll_screen_left:
	in temp, LEFT_CNT
	dec temp
	out LEFT_CNT, temp

	ldi temp, 5
	add vline_lo, temp		; Scroll takes multiple
	adc vline_hi, zero		; horizontal lines, keep count

	ldi ZH, 1			; 447 High
	ldi ZL, 191			; 447 Low

	ldi YL, low(screenbuf)
	ldi YH, high(screenbuf)

;	.macro scr_left
;		ldd temp, Y+1
;		st Y+, temp
;	.endmacro

	left_scroll_loop:
		scr_left
		sbiw ZH:ZL, 1
		brne left_scroll_loop

	ldi temp, 32

	.macro emptylast
		st Y, temp
		sbiw YH:YL, 32
	.endmacro

	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast
	emptylast

	rjmp wait_uart
