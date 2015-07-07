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
	push r16
	in r16, SREG

	push r1
	eor	r1, r1
	push r24
	push r25


	; HSYNC
	sbi PORTB, PB2
	.rept 72
		nop
	.endr
	cbi PORTB, PB2

	; VSYNC
	lds	r24, vline
	lds	r25, (vline)+1
	cpi r24, 0xCF		; 462(+1) VSYNC end
	sbci r25, 0x01
	brne vsync_start
	cbi PORTB, PB0		; VSYNC low

	vsync_start:
		lds	r24, vline
		lds	r25, (vline)+1
		cpi r24, 0xCD		; 460(+1) VSYNC start
		sbci r25, 0x01
		brne vline_inc
		sbi PORTB, PB0		; VSYNC high

	vline_inc:
		lds	r24, vline
		lds	r25, (vline)+1
		adiw r24, 0x01
		sts vline, r24
		sts (vline)+1, r25

	vline_full:
		lds	r24, vline
		lds	r25, (vline)+1
		cpi r24, 0x0D		; 525(+1) Full screen
		sbci r25, 0x02
		brne vline_no525
		sts vline, r1
		sts (vline)+1, r1
		rjmp vsync_done

	vline_no525:
		nop
		nop
		nop
		nop
		nop

	vsync_done:
		nop

	isr_end:
		pop r25
		pop r24
		pop r1
		out SREG, r16
		pop r16
		reti
