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

.def zero	= r0
.def one	= r1
.def alt	= r2
.def loop_1	= r3
.def loop_2	= r4
.def char_x	= r5
.def eorval	= r6
.def temp	= r16 
.def font_hi	= r17
.def vline_lo	= r18
.def vline_hi	= r19
.def alt_cnt	= r20

.equ HSYNC_WAIT	= 140

.dseg

drawbuf:
	.byte 64
screenbuf:
	.byte 448

.cseg
.org 0x00

main:
	; Set default values to registers
	;
	clr zero		; Zero the zero-register
	clr one
	inc one			; Register to hold value 1
	ldi temp, 32
	mov eorval, temp	; Buffer XORing value

	; Set GPIO directions
	;
	sbi DDRB, PB0
	sbi DDRB, PB1
	sbi DDRB, PB4
	cbi DDRB, PB2

	; Set USI mode
	;
	sbi USICR, USIWM0

fillscreen:
	; TODO: Remove. Just for testing
	clr loop_1
	clr loop_2
	clr char_x
	ldi YL, low(screenbuf)
	ldi YH, high(screenbuf)
filloop:
	ldi temp, 1
	st Y+, char_x
	inc char_x
	add loop_1, temp
	adc loop_2, zero
	cp loop_2, temp
	brne filloop
	ldi temp, 192
	cp loop_1, temp
	brne filloop

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
	; TCNT0 value has been calculated using simulator
	; and clock cycle counting to be in sync with
	; HSYNC timer
	ldi temp, (1 << WGM01)
	out TCCR0A, temp
	ldi temp, (1 << CS00)
	out TCCR0B, temp
	ldi temp, 158
	out OCR0A, temp
	ldi temp, 86
	out TCNT0, temp

	; We jump to the end of the VGA routine, setting
	; sane values for the registers for first screen.
	; screen_done jumps back to wait_hsync
	;
	rjmp screen_done

wait_hsync:
	; Wait for HSYNC timer to reach specified value
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
	; If timer start value is good, we jump over 0-3 nops
	;
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
	; We are in visible area. Fetch 8 bytes for next drawable line
	; and draw pixels for current line. We repeat each line 4 times
	; so finally we get 32 bytes for the next drawable line and
	; repeat the process. X register already contains pointer to
	; screen buffer, set in "screen_done"
	;
	ldi YL, low(drawbuf)	; Get predraw buffer address
	ldi YH, high(drawbuf)	; to Y register by alternating
	eor alt, eorval		; alt with eorval and adding
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

	; Increase predraw buffer offset by 8
	;
	ldi temp, 8
	add char_x, temp

	
	; Draw pixels, pushing them out from USI. We repeat this
	; 32 times using macro, without looping, as timing is important
	;
	ldi YL, low(drawbuf)	; Get current draw buffer address
	ldi YH, high(drawbuf)	; to Y register. Notice we don't add
	eor alt, eorval		; the high byte as we've reserved the
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
	; Time to do some housekeeping if we
	; have drawn the current line 4 times
	;
	inc alt_cnt
	cpi alt_cnt, 4
	breq housekeeping
	rjmp wait_hsync		; Return to HSYNC waiting

housekeeping:
	; Advance to next line, alternate buffers
	; and do some other housekeeping after pixels
	; have been drawn
	;
	clr alt_cnt		; Reset drawn line counter
	clr char_x		; Reset offset in predraw buffer
	eor alt, eorval		; Alternate between buffers
	inc font_hi		; Increase font line

	; Check if we have drawn one character line
	cpi font_hi, 0x20
	brne housekeep_done	; Not yet
	ldi font_hi, 0x18
	rjmp wait_hsync

housekeep_done:
	sbiw XH:XL, 32		; Switch screenbuffer back to beginning of line
	rjmp wait_hsync		; Return waiting to HSYNC

vertical_blank:
	; Check if we need to switch VSYNC low
	;
	cpi vline_lo, 0xCE	; Low (462)
	cpc vline_hi, one	; High (462)
	brne check_vsync_off
	cbi PORTB, PB0		; Vsync low
	rjmp wait_hsync

check_vsync_off:
	; Check if we need to switch VSYNC high
	;
	cpi vline_lo, 0xD0	; Low (464)
	cpc vline_hi, one	; High (464)
	brne check_vlines
	sbi PORTB, PB0		; Vsync high
	rjmp wait_hsync

check_vlines:
	; Have we done 525 lines?
	;
	ldi temp, 2		; High byte (525)
	cpi vline_lo, 0x0D	; Low (525)
	cpc vline_hi, temp	; High (525)
	breq screen_done

vblank:
	; We are outside visible screen with "nothing to do"
	;
	rjmp wait_hsync

screen_done:
	; We have drawn full screen, initialize values
	; back to start values for next refresh
	;
	clr vline_lo
	clr vline_hi
	clr alt
	clr alt_cnt
	clr char_x
	ldi XL, low(screenbuf)	; Pointer to start of 
	ldi XH, high(screenbuf)	; the screen buffer
	ldi font_hi, 0x18	; Font flash addr high byte

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
	rjmp wait_hsync
