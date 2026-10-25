/*
 * Minimal host compatibility shim for the AVR program-memory macros used by
 * the original cpu.c. cpu.c itself can remain unchanged.
 */
#ifndef HOST_AVR_PGMSPACE_H
#define HOST_AVR_PGMSPACE_H
#define PROGMEM
#define prog_char char
#define pgm_read_byte_near(address) (*(const unsigned char *)(address))
#define pgm_read_byte(address) (*(const unsigned char *)(address))
#endif
