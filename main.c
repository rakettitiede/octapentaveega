#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <util/delay.h>
#include <string.h>
#include <stdint.h>
#include "font.h"

typedef union {
	uint16_t word;
	uint8_t arr[2];
} magic;

volatile uint8_t line[36] = {};
volatile uint8_t linebuffer[36] = {};
volatile uint8_t screen[396] = { 72, 101, 108, 108, 111 };
volatile magic vline;
uint16_t charindex = 0; 

#define VMIN 61
#define VMAX 445

ISR(TIM1_COMPA_vect) {
	PORTB |= (1 << PB0);
	vline.arr[0] = 0;
	vline.arr[1] = 0;
}

ISR(TIM0_COMPA_vect) {
	PORTB |= (1 << PB2);
	__asm__ volatile(".rept 72\n\tnop\n\t.endr\n\t");
	PORTB &= ~(1 << PB2);

	vline.word++;
	if (vline.word == 2) PORTB &= ~(1 << PB0);

	if (vline.word < VMIN || vline.word > VMAX) {
		return;
	}

	__asm__ volatile(".rept 6\n\tnop\n\t.endr\n\t");

	USIDR = line[0];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[1];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[2];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[3];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[4];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[5];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[6];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[7];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[8];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[9];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[10];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[11];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[12];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[13];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[14];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[15];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[16];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[17];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[18];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[19];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[20];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[21];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[22];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[23];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[24];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[25];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[26];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[27];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[28];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[29];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[30];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[31];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[32];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[33];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[34];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);

	USIDR = line[35];
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
	USICR |= (1 << USICLK);
}

int main(void) {
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
	PORTB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
	USICR = (1 << USIWM0);

	cli();

	// HSYNC Timer
	// Timer0 Prescaler = 8, Compare = 0x4F 
	TCCR0A = (1 << WGM01);
	TCCR0B = (1 << CS01);
	TIMSK |= (1 << OCIE0A);
	OCR0A = 80;

	//VSYNC
	TCCR1 = (1 << CTC1) | (1 << CS12) | (1 << CS13);
	OCR1A = 161;
	OCR1C = 161;
	TIMSK |= (1 << OCIE1A);

	// Sleep mode
	set_sleep_mode(SLEEP_MODE_IDLE);

	// Enable interrupts
	sei();

	for(uint8_t j = 0; j < 36; j++) line[j] = 21 << 3;

	for(;;) {
	}
}

