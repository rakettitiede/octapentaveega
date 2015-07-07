/*
 * Define global variables for both C and ASM code used
 */
#define VMAX_VALUE 385
#define VMAX_ASM VMAX_VALUE - 256 + 1

#ifdef __ASSEMBLER__

	#define sregstore r2
 	#define eorval r3
 	#define VMAX VMAX_ASM

#else

#include <stdint.h>

	register uint8_t sregstore __asm__("r2");
	register uint8_t eorval __asm__("r3");
 	#define VMAX VMAX_VALUE

#endif
