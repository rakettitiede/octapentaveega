;
; ASM ISR Vector implementation for Attiny85 VGA
;
#define _SFR_ASM_COMPAT 1
#define __SFR_OFFSET 0
#include <avr/io.h>
#include "globals.h"

.global TIM1_COMPA_vect
.extern line
.extern screen
.extern vline

TIM1_COMPA_vect:
	in r2, SREG			; Save SREG

	; Store registers
	push r1
	eor	r1, r1
	push r24
	push r25

	; HSYNC
	sbi PORTB, PB2			; HSYNC HIGH
	.rept 73
		nop
	.endr
	cbi PORTB, PB2			; HSYNC LOW

	; VSYNC
	vsync_low:
		lds	r24, vline
		lds	r25, (vline)+1
		cpi r24, 0xCF		; 462(+1) VSYNC end
		sbci r25, 0x01
		brne vsync_high
		cbi PORTB, PB0		; VSYNC low

	vsync_high:
		lds	r25, (vline)+1
		cpi r24, 0xCD		; 460(+1) VSYNC start
		sbci r25, 0x01
		brne vline_increase
		sbi PORTB, PB0		; VSYNC high

	vline_increase:
		lds	r25, (vline)+1
		adiw r24, 0x01
		sts vline, r24
		sts (vline)+1, r25

	; Check if we've done 525 lines = full screen
		cpi r24, 0x0D		; 525(+1)
		sbci r25, 0x02
		brne vsync_done
		sts vline, r1
		sts (vline)+1, r1
;		rjmp isr_end

	; Next check if we're outside visible area
	vsync_done:
;		lds	r24, vline
;		lds r25, (vline)+1
;		cpi r24, 0x80		; Visible area low byte
;		sbci r25, 0x01
;		brcs draw_pixels
;		rjmp isr_end

	draw_pixels:
		sbi PORTB, PB1
		.rept 400
			nop
		.endr
		cbi PORTB, PB1

	isr_end:
		pop r25
		pop r24
		pop r1
		out SREG, r2
		reti
