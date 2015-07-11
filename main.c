#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#include <string.h>
#include <stdint.h>
#include "font.h"

#define VMAX 388

volatile uint16_t vline = 464;
volatile uint8_t line[64] = {};
volatile unsigned char screen[384] =
	{
	" Hello world!! This is Attiny85 "
	" displaying 32x12 characters on "
	" VGA with heavy USI misusage... "
	"      (C) 2015 by //Jartza      "
	" \x05\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x04"
	"\x05\x03 Here be dragons! BEWARE!!! \x05\x03"
	"\x02\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x03"
	"D\xce\xef\xa0\xc1\xf4\xf4\xe9\xee\xf9\xf3\xa0\xe8\xe1\xf6\xe5\xa0\xe2\xe5\xe5\xee\xa0\xef\xf6\xe5\xf2\xe3\xec\xef\xe3\xeb\xe5\xe4\xe4\xf5\xf2\xe9\xee\xe7\xa0\xf4\xe8\xe9\xf3\xa0\xf0\xf2\xef\xea\xe5\xe3\xf4\xa0\xa8\xf2\xf5\xee\xa0\xc0\xb2\xb0\xcd\xc8\xfa\xa9"
	"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
	"abcdefghijklmnopqrstuvwxyz123456"
	"7890,.-!\"#$%&/()+-ABCDEFGHIJKLMN"	
	};

// We reserve a lot of registers and get warning but it's OK
// as we're not going to do anything in main (except sleep) nor
// in any other function and everything happens inside one ISR
register uint8_t font_line __asm__("r2");
register uint8_t alt __asm__("r3");
register uint8_t alt_cnt __asm__("r4");
register uint8_t char_x __asm__("r16");
register uint16_t scr_buf_off __asm__("r24");

ISR(TIM1_COMPA_vect) {
	uint8_t *lineptr;
	uint8_t *fillptr = (uint8_t *)&line[(alt ^ 32) + char_x];
	uint8_t *screenptr = (uint8_t *)&screen[scr_buf_off + char_x];
	static uint16_t font_addr = 0x1800;

	/*
	 * Create HSYNC. Spend 73 cycles between LOW and HIGH
	 */
	PORTB &= ~(1 << PB2); // HSYNC HIGH

	// Fetch and fill 3 bytes for next drawable line
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));

	// This is for timing.
	__asm__ volatile(".rept 28" "\t\n" "nop" "\t\n" ".endr" "\t\n" ); // TODO: use this to UART?
	
	PORTB |= (1 << PB2); // HSYNC LOW

	// Create VSYNC pulses and also exit asap if we're
	// outside screen-visible area (to save clock cycles)
	if (++vline > VMAX ) {
		if (vline == 525) {
			vline = 0;
			alt_cnt = 0;
			alt = 0;
			char_x = 0;
			scr_buf_off = 0;
			font_line = 0;
			font_addr = 0x1800;
			memset((void *)&line[0], 0, 32);
			return;
		}
		if (vline == 464) {
			PORTB |= (1 << PB0);
			return;
		}
		if (vline == 462) {
			PORTB &= ~(1 << PB0);
			return;
		}
		return;
	}

	// Fetch and fill 5 more bytes for next drawable line
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	char_x += 8;

	// Fetch the address to predrawn data
	lineptr = (uint8_t *)&line[alt];

	// Push byte to USI and push out bits as pixels
	// Loading USIDR with new value seems to push out
	// the 5th byte "for free", so we don't get any
	// blanks between pixels, which is nice
	// 
	// Do this 32 times unrolled, because
	// of the critical timing
	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = 0; // make sure we don't draw to porch

	// Have we drawn one "pixel line" (4 horizontal lines)?
	// If we have, increase font flash address, and possibly
	// the screen buffer if we've drawn one full
	// line of characters
	if (++alt_cnt == 4) {
		alt_cnt = 0;
		char_x = 0;
		alt ^= 32;
		font_addr += 0x100;
		if (++font_line == 0x08) {
			font_line = 0;
			scr_buf_off += 32;
			font_addr = 0x1800;
		}
	}
}

int main(void) {
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
	PORTB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
	USICR = (1 << USIWM0);

	cli();

	// HSYNC timer. Prescaler 4, Compare value = 159 = 31.8us
	TCCR1 = (1 << CTC1) | (1 << CS10) | (1 << CS11);
	OCR1A = 158;
	OCR1C = 158;
	TIMSK |= (1 << OCIE1A);

	// Sleep mode
	set_sleep_mode(SLEEP_MODE_IDLE);

	// Give slaves time to set up
	_delay_ms(500);

	// Enable interrupts
	sei();

	// NEVER DO ANYTHING MORE HERE!
	// We reserve registers for only ISR
	for(;;) sleep_mode();
}

