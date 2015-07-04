#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <util/delay.h>
#include <stdint.h>

volatile uint8_t line[36];
volatile uint16_t vline = 0;

ISR(TIM1_COMPA_vect) {
	PORTB &= ~(1 << PB0);
	vline = 0;
}

ISR(TIM0_COMPA_vect) {
	PORTB |= (1 << PB2);
    __asm__ volatile(
        ".rept 74"						"\n\t" 
        "nop"							"\n\t"
        ".endr"							"\n\t"
    );
	PORTB &= ~(1 << PB2);

	vline++;
	if (vline == 3) PORTB |= (1 << PB0);
	if (vline < 35 || vline > 480) return;

    __asm__ volatile(
        ".rept 32"						"\n\t" 
        "nop"							"\n\t"
        ".endr"							"\n\t"
    );

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
	OCR0A = 79;

	//VSYNC
	TCCR1 = (1 << CTC1) | (1 << CS12) | (1 << CS13);
	OCR1A = 159;
	OCR1C = 159;
	TIMSK |= (1 << OCIE1A);

	set_sleep_mode(SLEEP_MODE_IDLE);

	sei();

	for(uint8_t i = 0; i < 36; i++) line[i] = 0xA8; //A8

	for(;;) sleep_mode();
}

