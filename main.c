#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <util/delay.h>
#include <string.h>
#include <stdint.h>
#include "globals.h"
#include "font.h"

volatile uint8_t line[64] = {};
volatile uint8_t screen[384] = {};
//volatile uint8_t screen[384] = { 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, 72, 101, 108, 108, 111, 32, };
volatile uint16_t vline = 462;

// ISR(TIM1_COMPA_vect) {
// 	static uint8_t alter = 0;
// 	static uint8_t altcnt = 0;
// 	volatile uint8_t *lineptr;

// 	PORTB |= (1 << PB2); // Hsync HIGH. Code should lose 70 cycles here
// 	__asm__ volatile(".rept 70\n\tnop\n\t.endr\n\t");
// 	PORTB &= ~(1 << PB2); // Hsync LOW

// 	if (vline == 464) PORTB &= ~(1 << PB0);
// 	if (vline == 462) PORTB |= (1 << PB0);
// 	vline++;

// 	if (vline > VMAX) {
// 		if (vline == 525) vline = 0;
// 		altcnt = 0;
// 		alter = 0;
// 		return;
// 	}

// 	lineptr = &line[alter];

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

// 	USIDR = *lineptr++;
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);
// 	USICR |= (1 << USICLK);

	// if (++altcnt == 4) {
	// 	alter ^= 32;
	// 	altcnt = 0;
	// }
// }

int main(void) {
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
	PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2));
	USICR = (1 << USIWM0);
	alter = 0;

	PORTB |= (1 << PB1);
	__asm__ volatile(".rept 70\n\tnop\n\t.endr\n\t");
	PORTB &= ~(1 << PB1);

	cli();

	// HSYNC timer. Prescaler 4, Compare value = 159 = 31.8us
	TCCR1 = (1 << CTC1) | (1 << CS10) | (1 << CS11);
	OCR1A = 158;
	OCR1C = 158;
	TIMSK |= (1 << OCIE1A);
	TCCR0A = 0;
	TCCR0B = (1 << CS00) | (1 << CS02);

	// Sleep mode
	set_sleep_mode(SLEEP_MODE_IDLE);

	// Fill first with pattern
	for(uint8_t i = 0; i < 64; i++) line[i] = i << 3;

	// Enable interrupts
	sei();

	for(;;) sleep_mode();
}

