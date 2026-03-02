/* SID @(#)init.h	1.9 */
/* @(#)init.h	6.3 */
extern int clkstart(),cinit(),binit(),errinit(),iinit(),inoinit();
extern int finit();
#ifdef X25_0
extern x25init();
#endif
#ifdef BX25S_0
extern bxncinit();
extern sessinit();
#endif
#ifdef ST_0
extern	stinit();
#endif
#ifdef	VPM_0
extern	vpminit();
#endif
#ifdef EM_0
extern  eminit();
#endif
extern dkinit(),mtinit(),pdinit(),ptinit(),rminit(),siinit(),xyinit();
extern skyinit();
#ifdef robin
extern sqinit();
extern scinit();
extern fpinit();
extern tpinit();
extern initoff();
#endif
#ifdef NOS
extern etinit();
extern ncfinit();
#endif
#ifdef PIRATE
extern ccbinit();
#endif

/*	Array containing the addresses of the various initializing	*/
/*	routines executed by "main" at boot time.			*/

int (*init_tbl[])() = {
#ifdef robin
	sqinit,
	scinit,
	fpinit,
#endif
	dkinit,
	mtinit,
#ifndef robin
	pdinit,
	xyinit,			/* must come after pdinit; (kludge) JF */
	ptinit,
#else
	tpinit,
	initoff,
#endif
	rminit,
	siinit,
	skyinit,
#ifdef NOS
	etinit,
	ncfinit,
#endif
	inoinit,
	clkstart,
	cinit,
	binit,
	errinit,
	finit,
	iinit,
#ifdef	VPM_0
	vpminit,
#endif
#ifdef X25_0
	x25init,
#endif
#ifdef ST_0
	stinit,
#endif
#ifdef BX25S_0
        bxncinit,
        sessinit,
#endif
#ifdef EM_0
	eminit,
#endif
#ifdef PIRATE
	ccbinit,
#endif
	0
};
