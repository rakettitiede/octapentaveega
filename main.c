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
volatile unsigned char screen[384] =
	{
	" Hello world!! This is Attiny85 "
	" displaying 32x12 characters on "
	" VGA with 5x8 pixel characters. "
	"      (C) 2015 by //Jartza      "
	" \x05\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x04"
	"\x05\x03 HERE BE DRAGONS! BEWARE!!! \x05\x03"
	"\x02\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x03"
	"D\xce\xef\xa0\xc1\xf4\xf4\xe9\xee\xf9\xf3\xa0\xe8\xe1\xf6\xe5\xa0\xe2\xe5\xe5\xee\xa0\xef\xf6\xe5\xf2\xe3\xec\xef\xe3\xeb\xe5\xe4\xe4\xf5\xf2\xe9\xee\xe7\xa0\xf4\xe8\xe9\xf3\xa0\xf0\xf2\xef\xea\xe5\xe3\xf4\xa0\xa8\xf2\xf5\xee\xa0\xc0\xb2\xb0\xcd\xc8\xfa\xa9"
	"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
	"abcdefg     mnopqrstuvwxyz123456"
	"7890,.-!\"#$%&/()+-ABCDEFGHI KL N"	
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
	static uint8_t line[64] = {};
	static uint16_t font_addr = 0x1800;
	static uint8_t* font_high = (uint8_t *) (&font_addr) + 1;

	// Create VSYNC pulses and also exit asap if we're
	// outside screen-visible area (to save clock cycles)
	if (++vline > VMAX) {
		if (vline == 525) {
			vline = 0;
			alt_cnt = 0;
			alt = 0;
			char_x = 0;
			scr_buf_off = 0;
			font_line = 0;
			(*font_high) = 0x18;
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

	// Fetch and fill 8 bytes to buffer for next drawable line.
	// Each horizontal line is drawn 4 times, so we get full 32 bytes
	// for next horizontal line this way
	uint8_t *lineptr;
	uint8_t *fillptr = (uint8_t *)&line[(alt ^ 32) + char_x];
	uint8_t *screenptr = (uint8_t *)&screen[scr_buf_off + char_x];

	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
	*fillptr++ = pgm_read_byte(font_addr + (*screenptr++));
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
		(*font_high)++;
		if (++font_line == 0x08) {
			font_line = 0;
			scr_buf_off += 32;
			(*font_high) = 0x18;
		}
	}
}

int main(void) {
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB4);
	PORTB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
	USICR = (1 << USIWM0);

	cli();

	// HSYNC timer. Prescaler 4, Compare value = 159 = 31.8us
	TCCR1 = (1 << CTC1) | (1 << CS10) | (1 << CS11);
    GTCCR = 1 << PWM1B | 1 << COM1B1;
	OCR1A = 130;
	OCR1B = 139;
	OCR1C = 158;
	TIMSK |= (1 << OCIE1A);

	// Sleep mode
	set_sleep_mode(SLEEP_MODE_IDLE);

	// Give slaves time to set up
	_delay_ms(500);


	uint8_t bits = 1;
	for(uint8_t i = 0; i < 64; i++) {
		// if (bits++ & 4) screen[320 + i] = 65 + i;
		// 	else screen[320 + i] = 32;
		screen[320 + i] = 65 + i;
		if (bits == 7) bits = 1;
	}

	// Enable interrupts
	sei();

	// NEVER DO ANYTHING MORE HERE!
	// We reserve registers for only ISR
	for(;;) sleep_mode();
}

