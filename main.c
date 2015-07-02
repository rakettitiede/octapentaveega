#include <avr/io.h>
#include <util/delay.h>

int main(void)
{
  DDRB = 0b00000010;
  for(;;){
    _delay_ms(1000);
    PORTB ^= 0b00000010;
  }
  return 0;
}

