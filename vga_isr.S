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
.extern screenptr
.extern vline
.extern alter
.extern altcnt

TIM1_COMPA_vect:
		in r2, SREG			; Save SREG

		; Store registers
		push r1
		eor	r1, r1
		push r16
		push r17
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
		mov r16, ZH
		cpi ZL, 0xCF		; 462(+1) VSYNC end
		sbci ZH, 0x01
		brne vsync_high
		cbi PORTB, PB0		; VSYNC low

	vsync_high:
		mov ZH, r16
		cpi ZL, 0xCD		; 460(+1) VSYNC start
		sbci ZH, 0x01
		brne vline_increase
		sbi PORTB, PB0		; VSYNC high

	vline_increase:
		mov ZH, r16
		adiw ZL, 0x01
		sts vline, ZL
		sts (vline)+1, ZH

	; Check if we've done 525 lines = full screen
		cpi ZL, 0x0D		; 525(+1)
		sbci ZH, 0x02
		brne vsync_done
		sts vline, r1
		sts (vline)+1, r1
		rjmp clear_stuff

	; Next check if we're outside visible area
	vsync_done:
		lds	ZL, vline
		lds ZH, (vline)+1
		cpi ZL, 0x80		; Visible area low byte
		sbci ZH, 0x01
		brcs draw_pixels
		;
		; Clear variables when outside visible area (one screen done)
		;
	clear_stuff:
		ldi r16, 0x04
		sts altcnt, r16
		sts alter, r1
		sts screenidx, r1
		sts (screenidx)+1, r1
		rjmp isr_end

	draw_pixels:
		lds r16, alter
		ldi ZL, lo8(line)
		ldi ZH, hi8(line)
		add ZL, r16
		adc ZH, r1

		ld r16, Z
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+1
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+2
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+3
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+4
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+5
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+6
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+7
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+8
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+9
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+10
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+11
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+12
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+13
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+14
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+15
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+16
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+17
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+18
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+19
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+20
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+21
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+22
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+23
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+24
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+25
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+26
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+27
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+28
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+29
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+30
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		ldd r16, Z+31
		out USIDR, r16
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK
		sbi USICR, USICLK

		lds r17, altcnt
		dec r17
		brne alterdone
		ldi r17, 0x04

		lds r16, alter
		eor r16, eorval
		sts alter, r16

	alterdone:
		sts altcnt, r17

	isr_end:
		pop r31
		pop r30
		pop r17
		pop r16
		pop r1
		out SREG, r2
		reti
