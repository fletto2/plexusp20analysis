/* SID @(#)name.c	5.3 */

/* @(#)name.c	6.1 */
#include "sys/utsname.h"

#if defined(ROBIN)+defined(LUNDELL)+defined(SCHROEDER)+defined(KICKER) != 1
******* exactly one machine type constant must be defined **************
#endif

struct utsname utsname = {
	SYS,
	NODE,
	REL,
	VER,
	MACH,
};
