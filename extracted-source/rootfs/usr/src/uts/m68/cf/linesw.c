/* SID @(#)linesw.c	5.1 */

/*
 * Line Discipline Switch table
 */
#include "sys/conf.h"

extern	nulldev();
extern	ttopen(), ttclose(), ttread(), ttwrite(), ttin(), ttout();
extern	vttwrite(), vttread();
struct linesw linesw[] = {
/* 0 */	ttopen, ttclose, ttread, ttwrite, nulldev, ttin, ttout, nulldev,
/* 1 */	ttopen, nulldev, vttread, vttwrite, nulldev, nulldev, nulldev, nulldev
};
int	linecnt = 2;

/*
 * Virtual Terminal Switch Table
 */

#ifdef VT_VT100
extern	vt100input(), vt100output(), vt100ioctl();
#endif
#ifdef VT_HP45
extern	hp45input(), hp45output(), hp45ioctl();
#endif
struct termsw termsw[] = {
/*0*/	nulldev,	nulldev,	nulldev,	/* tty */
/*1*/
#ifdef VT_VT100
	vt100input,	vt100output,	vt100ioctl,	/* VT100 */
#else
	nulldev,	nulldev,	nulldev,
#endif
/*2*/
#ifdef VT_HP45
	hp45input,	hp45output,	hp45ioctl,	/* HP45 */
#else
	nulldev,	nulldev,	nulldev,
#endif
};

/* number of entries in termsw */
int termcnt = 3;
