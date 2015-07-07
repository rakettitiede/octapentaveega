/*
 * Define global variables for both C and ASM code used
 */
#define VMAX_VALUE 384
#define VMAX_ASM VMAX_VALUE - 256

#ifdef __ASSEMBLER__

	#define sregstore r2
	#define alter r3
 	#define eorrer r4
 	#define VMAX VMAX_ASM

#else

#include <stdint.h>

	register uint8_t sregstore __asm__("r2");
	register uint8_t alter __asm__("r3");
	register uint8_t eorrer __asm__("r4");
 	#define VMAX VMAX_VALUE

#endif
