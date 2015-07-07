/*
 * Define global variables for both C and ASM code used
 */

#ifdef __ASSEMBLER__

	#define sreg_save	r2
	#define flags		r16
	#define counter_hi    r4

#else

	#include <stdint.h>

	register uint8_t sreg_save asm("r2");
	register uint8_t flags     asm("r16");
	register uint8_t counter_hi asm("r4");

#endif
