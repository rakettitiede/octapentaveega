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
	push r30
	push r31

	; HSYNC
	sbi PORTB, PB2			; HSYNC HIGH
	.rept 73
		nop
	.endr
	cbi PORTB, PB2			; HSYNC LOW

	; VSYNC
	vsync_low:
		lds	ZL, vline
		lds	ZH, (vline)+1
		cpi ZL, 0xCF		; 462(+1) VSYNC end
		sbci ZH, 0x01
		brne vsync_high
		cbi PORTB, PB0		; VSYNC low

	vsync_high:
		lds	ZH, (vline)+1
		cpi ZL, 0xCD		; 460(+1) VSYNC start
		sbci ZH, 0x01
		brne vline_increase
		sbi PORTB, PB0		; VSYNC high

	vline_increase:
		lds	ZH, (vline)+1
		adiw ZL, 0x01
		sts vline, ZL
		sts (vline)+1, ZH

	; Check if we've done 525 lines = full screen
		cpi ZL, 0x0D		; 525(+1)
		sbci ZH, 0x02
		brne vsync_done
		sts vline, r1
		sts (vline)+1, r1
		rjmp isr_end

	; Next check if we're outside visible area
	vsync_done:
		lds	ZL, vline
		lds ZH, (vline)+1
		cpi ZL, 0x80		; Visible area low byte
		sbci ZH, 0x01
		brcs draw_pixels
		rjmp isr_end

	draw_pixels:
		sbi PORTB, PB1
		.rept 480
			nop
		.endr
		cbi PORTB, PB1

	isr_end:
		pop r31
		pop r30
		pop r1
		out SREG, r2
		reti
