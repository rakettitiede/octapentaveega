#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <util/delay.h>
#include <string.h>
#include <stdint.h>
#include "font.h"

volatile uint8_t line[65] = {};
volatile uint8_t screen[384] = { 72, 101, 108, 108, 111 };
volatile uint16_t vline;
uint16_t charindex = 0; 

#define VMIN 61
#define VMAX 445

ISR(TIM1_COMPA_vect) {
	static uint8_t alter = 0;
	static uint8_t altcnt = 0;
	uint8_t *lineptr;

	PORTB |= (1 << PB2);
	__asm__ volatile(".rept 73\n\tnop\n\t.endr\n\t");
	PORTB &= ~(1 << PB2);

	if (vline == 2) PORTB &= ~(1 << PB0);
	if (vline == 0) PORTB |= (1 << PB0);

	if (++vline == 524) vline = 0;

	if (vline < VMIN || vline > VMAX) {
		altcnt = 0;
		alter = 0;
		return;
	}

	lineptr = &line[alter];

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = *lineptr++;
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	if (++altcnt == 4) {
		alter ^= 32;
		altcnt = 0;
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

	// Enable interrupts
	sei();

	for(uint8_t j = 0; j < 32; j++) line[j] = 31 << 3;
	for(uint8_t j = 32; j < 64; j++) line[j] = 17 << 3;

	for(;;) sleep_mode();
}

