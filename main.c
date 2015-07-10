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
volatile uint8_t alter = 0;
volatile uint8_t altcnt = 4;
volatile uint8_t *screenptr = &screen[0];
volatile uint16_t screenidx = 0;

int main(void) {
	DDRB |= (1 << PB0);
	DDRB |= (1 << PB1);
	DDRB |= (1 << PB2);
	PORTB &= ~(1 << PB0);
	PORTB &= ~(1 << PB1);
	PORTB &= ~(1 << PB2);
	USICR = (1 << USIWM0);
	eorval = 32;

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
	for(uint8_t i = 0; i < 32; i++) 
		line[i] = 168;
	for(uint8_t i = 32; i < 64; i++) 
		line[i] = 84;

	// Enable interrupts
	sei();

	for(;;) sleep_mode();
}

