/* SID */
/* @(#)conf.c	5.8 9/29/86 */

/*
 *  Configuration information
 */

/* features */

#define	MEMORY_0	1	/* ????? */
#define	TTY_0	1		/* ????? */
#define	ERRLOG_0	1	/* ????? */
#define	POWER	0		/* no restart after power failuure */
#define	PRF_0	1		/* include kernel profile stuff */
#define	MESG	1		/* include message stuff */
#define	SEMA	1		/* include semaphore stuff */
#define	SHMEM	1		/* include shared memory stuff */

/* miscellaneous limits */

#include <sys/maxuser.h>

#ifndef NOS
#define	NPROC	(MAXUSER * 2 + 50)	/* <= 255-due to hardware proc id*/
#else
#define	NPROC	(MAXUSER * 2 + 100)	/* <= 255-due to hardware proc id*/
#endif

#ifndef KICKER

#if NPROC > 255
#undef NPROC
#define NPROC 255
#endif

#else

#if NPROC > 2047
#undef NPROC
#define NPROC 2047
#endif

#endif

#define	NBUF	0		/* defaults to 10% of physical memory if 0 */
#define	NPBUF	(NPROC / 25 + 2)/* physio buffers */
#define	NINODE	(NPROC * 2)	/* open inodes */
#define	NFILE	(NPROC * 2)	/* open files */
#define	NMOUNT	40		/* mount table */
#define	CMAPSIZ	50		/* ????? */
#define	SMAPSIZ	(NPROC / 2)	/* swap map size */
#define	DMAPSIZ	10		/* ????? */
#define	NCALL	(NPROC / 2)	/* call out table */
#define	NTEXT	(NPROC / 2)	/* shared text segment table */
#if NOS || robin
#define	NCLIST	80		/* ????? */
#else
#define	NCLIST	20		/* low because of ICP/ACP */
#endif
#define	NSABUF	14		/* ????? */
#define	MAXUP	25		/* max processes per user */
#define	NHBUF	64		/* ????? */
#define	CDLIMIT	(1L<<11)	/* default max file size ( 2 Mb ) */

/* network operating system */

#define	N_ATTACH	NPROC	/* number of "attaches'/host (68k) */
#define	N_HOSTS	(NPROC / 3)	/* max num of net hosts known to local host */
#define	N_VC	(NPROC * 2)	/* # of free virtual connection descripters */
#define	NFTBUF	125		/* size of ft buffer (kbytes)  max = 127 (robin only) */ 
#define	NRMOUNT	(NPROC / 2)	/* number of remote mount */
#define	NDFSWE	(NPROC / 3)	/* number of dfs work entries */
#define	NDFSPRO	NPROC		/* number of dfs processes */

/* messages */

#define	MSGMAP	NPROC		/* message segment map size */
#define	MSGMAX	8192		/* max message size */
#define	MSGMNB	16384		/* max bytes in a message queue */
#define	MSGMNI	(MSGMAP / 2)	/* max # of message queues */
#define	MSGSSZ	8		/* message segment size */
#define	MSGTQL	(MSGMAP / 2)	/* # of message headers */
#define	MSGSEG	(MSGMAP * 10)	/* # of message segments */

/* semaphores */

#define	SEMMNS	(NPROC / 2)	/* # of semaphores in the system */
#define	SEMMAP	(SEMMNS / 5)	/* # of entries in semaphore map */
#define	SEMMNI	(SEMMNS / 5)	/* # of semaphore identifiers */
#define	SEMMNU	(SEMMNS / 2)	/* # of undo structures in the system */
#define	SEMUME	10		/* undo entries per structure */
#define	SEMMSL	25		/* max semaphores per identifier */
#define	SEMOPM	10		/* max # operations per semop() call */
#define	SEMVMX	32767		/* max value for semaphore */
#define	SEMAEM	16384		/* adjustment range */

/* shared memory */

#define	SHMMNI	NPROC		/* max number of shmem segments in the system */
#define	SHMMAX	(128*1024)	/* max size of shared memory segment */
#define	SHMMIN	1		/* minimum size of shmem segment */
#define	SHMSEG	6		/* max shmem segments per user */
#define	SHMBRK	16		/* gap between data and shmem areas */
#define	SHMALL	(SHMMNI * 5)	/* max system wide shared memory clicks */

/* include files */

#include	"sys/param.h"
#include	"sys/types.h"
#include	"sys/sysmacros.h"
#include	"sys/space.h"
#include	"sys/systm.h"

/*
	Routines used by all machine types in their switch tables
*/
extern	nodev(), nulldev();
extern	dkopen(), dkclose(), dkread(), dkwrite(), dkstrategy(), 
	dkioctl(), dktab;
extern	miopen(), miclose(), miread(), miwrite(), mistrategy(), 
	miioctl();
extern	mtopen(), mtclose(), mtread(), mtwrite(), mtstrategy(),
	mtioctl(), mttab;
extern	mmread(), mmwrite();
extern  ramopen(),rambclose(),ramread(),ramwrite(),ramstrategy(),ramioctl();
extern	erropen(), errclose(), errread();
extern	syopen(), syclose(), syread(), sywrite(), syioctl();
extern	prfread(), prfwrite(), prfioctl();
extern	tropen(),  trclose(),  trread(),  trioctl(),  trsave();
#ifdef NOS
extern	etopen(), etclose(), etread(), etwrite();
extern	ncfopen(), ncfclose(), ncfread(), ncfwrite(), ncfioctl();
extern vttyopen(), vttyclose(), vttyread(), vttywrite(), vttyioctl();
#endif


#if defined(LUNDELL) | defined(SCHROEDER)
/*
	The switch tables for LUNDELL and SCHROEDER machines
*/
extern	rmopen(), rmclose(), rmread(), rmwrite(), rmstrategy(),
	rmioctl(), rmtab; 
extern	crmopen(), crmclose(), crmread(), crmwrite(); 
extern	icopen(), icclose(), icread(), icwrite(), icioctl();
extern	spopen(), spclose(), spread(), spwrite(), spioctl();
extern	ppopen(), ppclose(), ppread(), ppwrite(), ppioctl();
extern	aicopen(), aicclose(), aicread(), aicwrite(), aicioctl();
extern	aspopen(), aspclose(), aspread(), aspwrite(), aspioctl();
extern	appopen(), appclose(), appread(), appwrite(), appioctl();
extern	vpmopen(), vpmclose(), vpmread(), vpmwrite(), vpmioctl();
extern	vbopen(), vbclose(), vbread(), vbwrite(), vbioctl();
extern	vhopen(), vhclose(), vhread(), vhwrite(), vhioctl();
extern	vsopen();
extern	imopen(),imclose(),imread(),imwrite(),imioctl();
extern	hdlcopen(), hdlcclose(), hdlcread(), hdlcwrite(), hdlcioctl();
extern  ftopen(), ftclose(), ftread(), ftwrite();

extern	ptopen(), ptclose(), ptread(), ptwrite(), ptstrategy(),
	ptioctl(),pttab;
extern	pdopen(), pdclose(), pdread(), pdwrite(), pdstrategy(), 
	pdioctl(), pdtab;
extern	xyopen(), xyclose(), xyread(), xywrite(), xystrategy(), 
	xyioctl(), xytab;
extern	usopen(), usclose(), usread(), uswrite(), usioctl();
extern  odbopen(), odbclose(), odstrategy(),odtab;
extern  odropen(),odrclose(),odread(),odwrite(),odioctl();
extern ccbioctl();




int	(*bdevsw[])() =
{
/* 0*/	miopen, miclose, mistrategy, (int (*)())&dktab,	/* mirror dk */
/* 1*/	nodev,  nodev,   nodev,      (int (*)())0,	/*  mt */
/* 2*/	pdopen, pdclose, pdstrategy, (int (*)())&pdtab,	/* pd */
/* 3*/	ramopen,rambclose,ramstrategy,(int (*)())0,	/* ram */
/* 4*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 5*/	nodev,  nodev,   nodev,      (int (*)())0,	/* rm */
/* 6*/	xyopen, xyclose, xystrategy, (int (*)())&xytab, /* xy */
/* 7*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 8*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 9*/	odbopen, odbclose, odstrategy,(int (*)())&odtab,/* od */
/* Plexus promises never to use the following 5 devices so that users may */
/*10*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*11*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*12*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*13*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*14*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* We make no promises from here on */
	0
};




int	(*cdevsw[])() =
{
/* 0*/	usopen,	usclose,usread,	uswrite,usioctl,0,	/* console */
/* 1*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	
/* 2*/	nulldev,nulldev,mmread,	mmwrite,nodev,0, 		/* mem */
/*3*/	miopen, miclose, miread, miwrite, miioctl,0,	/* mirror dk */
/* 4*/	mtopen,	mtclose,mtread,	mtwrite,mtioctl,0,	/* mt */
/* 5*/	pdopen,	pdclose,pdread,	pdwrite,pdioctl,0,	/* pd */
/* 6*/	ptopen,	ptclose,ptread,	ptwrite,ptioctl,0,	/* pt */
/* 7*/	ramopen,nulldev,ramread,ramwrite,ramioctl,0,	/* ram */
/* 8*/	rmopen,	rmclose,rmread,	rmwrite,rmioctl,0,	/* rm */
/* 9*/	xyopen, xyclose, xyread, xywrite, xyioctl,0,	/* xy */
/*10*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*11*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*12*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*13*/	syopen,	nulldev,syread,	sywrite,syioctl,0,	/* tty */
/*14*/	icopen,	icclose,icread,	icwrite,nodev,0,	/* icp ic */
/*15*/	spopen,	spclose,spread,	spwrite,spioctl,0,	/* icp sp */
/*16*/	ppopen,	ppclose,ppread,	ppwrite,ppioctl,0,	/* icp pp */
#ifdef NOS
/*17*/	ncfopen,ncfclose,ncfread,ncfwrite,ncfioctl,0,
#else
/*17*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*18*/	vpmopen,vpmclose,vpmread,vpmwrite,vpmioctl,0,	/* icp vpm */
/*19*/	tropen, trclose, trread, trsave,  trioctl,0,	/* trace */
/*20*/	erropen,errclose,errread,nodev, nodev,0, 	/* err */
/*21*/	nulldev,nulldev,prfread,prfwrite,prfioctl,0,	/* prf */
#ifdef NOS
/*22*/	vttyopen,vttyclose,vttyread,vttywrite,vttyioctl,0,/* vtty */
#else
/*22*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*23*/	imopen,imclose,imread,	imwrite,imioctl,0,	/* im */
/*24*/	hdlcopen,hdlcclose,hdlcread,hdlcwrite,hdlcioctl,0,	/* icp hdlc */
/*25*/  ftopen,ftclose,ftread,ftwrite,nodev,0,		/* ft */
/*26*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*27*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*28*/	crmopen,crmclose,crmread,crmwrite,nodev,0,	/* crm (caching rm) */
/*29*/	nulldev,nulldev,nodev,nodev,ccbioctl,0,		/* ccb */
/*30*/	aicopen,aicclose,aicread,aicwrite,nodev,0,	/* acp ic */
/*31*/	aspopen,aspclose,aspread,aspwrite,aspioctl,0,	/* acp sp */
/*32*/	appopen,appclose,appread,appwrite,appioctl,0,	/* acp pp */
/*33*/	vbopen,vbclose,vbread,vbwrite,vbioctl,0,	/* acp vpm bisync */
/*34*/	vhopen,vhclose,vhread,vhwrite,vhioctl,0,	/* acp vpm hdlc */
/*35*/	vsopen,vhclose,vhread,vhwrite,vhioctl,0,	/* acp vpm sdlc */
/*36*/	nodev,nodev,nodev,nodev,nodev,0,		/* acp dynamic dnld */
/*37*/	odropen,odrclose,odread,odwrite,odioctl,0,	/* od */
/*38*/	nodev,nodev,nodev,nodev,nodev,0,		/* msna */
/*39*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- pts device */
/*40*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- ptc device */
/*41*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- Dnet device */
/*42*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- Net device */
/*43*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- ddn device */
/*44*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- xtty */
/*45*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- admin */
/*46*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- xmem */
/*47*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- socket */
/*48*/	nodev,nodev,nodev,nodev,nodev,0,		/*  */
/*49*/	nodev,nodev,nodev,nodev,nodev,0,		/*  */
/* Plexus promises never to use the following 10 devices so that users may */
/*50*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*51*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*52*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*53*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*54*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*55*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*56*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*57*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*58*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*59*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/* We make no promises from here on */
};
#endif

#ifdef ROBIN
/*
	The switch tables for ROBIN machines
*/
extern	rmopen(), rmclose(), rmread(), rmwrite(), rmstrategy(),
	rmioctl(), rmtab; 
extern	crmopen(), crmclose(), crmread(), crmwrite(); 
extern	icopen(), icclose(), icread(), icwrite(), icioctl();
extern	spopen(), spclose(), spread(), spwrite(), spioctl();
extern	ppopen(), ppclose(), ppread(), ppwrite(), ppioctl();
extern	aicopen(), aicclose(), aicread(), aicwrite(), aicioctl();
extern	aspopen(), aspclose(), aspread(), aspwrite(), aspioctl();
extern	appopen(), appclose(), appread(), appwrite(), appioctl();
extern	vpmopen(), vpmclose(), vpmread(), vpmwrite(), vpmioctl();
extern	vbopen(), vbclose(), vbread(), vbwrite(), vbioctl();
extern	vhopen(), vhclose(), vhread(), vhwrite(), vhioctl();
extern	vsopen();
extern	hdlcopen(), hdlcclose(), hdlcread(), hdlcwrite(), hdlcioctl();
extern  ftopen(), ftclose(), ftread(), ftwrite();

extern	scopen(), scclose(), scread(), scwrite(), scstrategy(), 
	scioctl(), sctab;
extern	fpopen(), fpclose(), fpread(), fpwrite(), fpstrategy(),
	bfpopen(),fpioctl(),fptab;
extern	tpopen(), tpclose(), tpread(), tpwrite(), tpstrategy(),
	tpioctl(),tptab;
extern	dlopen(), dlclose(), dlread(), dlwrite(), dlioctl();
extern	rkopen(), rkclose(), rkread(), rkwrite(), rkioctl();
extern	coopen();



int	(*bdevsw[])() =
{
/* 0*/	miopen, miclose, mistrategy, (int (*)())&dktab,	/* mirror dk */
/* 1*/	nodev,  nodev,   nodev,      (int (*)())0,	/*  mt */
/* 2*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 3*/	ramopen,rambclose,ramstrategy,(int (*)())0,	/* ram */
/* 4*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 5*/	nodev,  nodev,   nodev,      (int (*)())0,	/* rm */
/* 6*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 7*/	scopen, scclose, scstrategy, (int (*)())&sctab,	/* sc */
/* 8*/	bfpopen, fpclose, fpstrategy, (int (*)())&fptab,/* fp */
/* 9*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* Plexus promises never to use the following 5 devices so that users may */
/*10*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*11*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*12*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*13*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*14*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* We make no promises from here on */
	0
};



int	(*cdevsw[])() =
{
/* 0*/	coopen,	dlclose,dlread,	dlwrite,dlioctl,0,	/* console */
/* 1*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	
/* 2*/	nulldev,nulldev,mmread,	mmwrite,nodev,0, 		/* mem */
/*3*/	miopen, miclose, miread, miwrite, miioctl,0,	/* mirror dk */
/* 4*/	mtopen,	mtclose,mtread,	mtwrite,mtioctl,0,	/* mt */
/* 5*/	nodev ,	nodev ,nodev ,	nodev ,nodev ,0,	/*    */
/* 6*/	tpopen,	tpclose,tpread,	tpwrite,tpioctl,0,	/* tp */
/* 7*/	ramopen,nulldev,ramread,ramwrite,ramioctl,0,	/* ram */
/* 8*/	rmopen,	rmclose,rmread,	rmwrite,rmioctl,0,	/* rm */
/* 9*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*10*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*11*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*12*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*13*/	syopen,	nulldev,syread,	sywrite,syioctl,0,	/* tty */
/*14*/	icopen,	icclose,icread,	icwrite,nodev,0,	/* icp ic */
/*15*/	dlopen,	dlclose,dlread,	dlwrite,dlioctl,0,	/* sp */
/*16*/	ppopen,	ppclose,ppread,	ppwrite,ppioctl,0,	/* icp pp */
#ifdef NOS
/*17*/	ncfopen,ncfclose,ncfread,ncfwrite,ncfioctl,0,
#else
/*17*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*18*/	vpmopen,vpmclose,vpmread,vpmwrite,vpmioctl,0,	/* icp vpm */
/*19*/	tropen, trclose, trread, trsave,  trioctl,0,	/* trace */
/*20*/	erropen,errclose,errread,nodev, nodev,0, 		/* err */
/*21*/	nulldev,nulldev,prfread,prfwrite,prfioctl,0,	/* prf */
#ifdef NOS
/*22*/	vttyopen,vttyclose,vttyread,vttywrite,vttyioctl,0,/* vtty */
#else
/*22*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*23*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*24*/	hdlcopen,hdlcclose,hdlcread,hdlcwrite,hdlcioctl,0,	/* icp hdlc */
/*25*/  ftopen,ftclose,ftread,ftwrite,tpioctl,0,		/* ft */
/*26*/	fpopen,	fpclose, fpread, fpwrite, fpioctl, 0,	/* fp */
/*27*/	rkopen,	rkclose, rkread, rkwrite, rkioctl, 0,	/* rk */
/*28*/	crmopen,crmclose,crmread,crmwrite,nodev,0,	/* crm (caching rm) */
/*29*/	nodev,nodev,nodev,nodev,nodev,0,		/* ccb */
/*30*/	aicopen,aicclose,aicread,aicwrite,nodev,0,	/* acp ic */
/*31*/	aspopen,aspclose,aspread,aspwrite,aspioctl,0,	/* acp sp */
/*32*/	appopen,appclose,appread,appwrite,appioctl,0,	/* acp pp */
/*33*/	vbopen,vbclose,vbread,vbwrite,vbioctl,0,	/* acp vpm bisync */
/*34*/	vhopen,vhclose,vhread,vhwrite,vhioctl,0,	/* acp vpm hdlc */
/*35*/	vsopen,vhclose,vhread,vhwrite,vhioctl,0,	/* acp vpm sdlc */
/*36*/	nodev,nodev,nodev,nodev,nodev,0,		/* acp dynamic dnld */
/*37*/	nodev,nodev,nodev,nodev,nodev,0,		/* od */
/*38*/	nodev,nodev,nodev,nodev,nodev,0,		/* msna */
/*39*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- pts device */
/*40*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- ptc device */
/*41*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- Dnet device */
/*42*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- Net device */
/*43*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- ddn device */
/*44*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- xtty */
/*45*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- admin */
/*46*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- xmem */
/*47*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- socket */
/*48*/	nodev,nodev,nodev,nodev,nodev,0,		/*  */
/*49*/	nodev,nodev,nodev,nodev,nodev,0,		/*  */
/* Plexus promises never to use the following 10 devices so that users may */
/*50*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*51*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*52*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*53*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*54*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*55*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*56*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*57*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*58*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*59*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/* We make no promises from here on */
};
#endif

#ifdef KICKER
/*
	The switch tables for KICKER machines

	NOTE THAT THE VCP ENTRIES HAVE NOT BEEN ADDED YET.
	THEY SHOULD REPLACE THE EQUIVLALENT ACP ENTRIES.
*/
extern	tthopen(), tthclose(), tthread(), tthwrite(), tthstrategy(),
	tthioctl(), tthtab; 
extern	tsopen(), tsclose(), tsread(), tswrite(), tsstrategy(),
	tsioctl(),tstab;
extern	smopen(), smclose(), smread(), smwrite(), smstrategy(), 
	smioctl(), smtab;
extern	usopen(), usclose(), usread(), uswrite(), usioctl();
extern  odbopen(), odbclose(), odstrategy(),odtab;
extern  odropen(),odrclose(),odread(),odwrite(),odioctl();
extern ccbioctl();




int	(*bdevsw[])() =
{
/* 0*/	miopen, miclose, mistrategy, (int (*)())&dktab,	/* mirror dk */
/* 1*/	nodev,  nodev,   nodev,      (int (*)())0,	/*  mt */
/* 2*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 3*/	ramopen,rambclose,ramstrategy,(int (*)())0,	/* ram */
/* 4*/	nodev,  nodev,   nodev,      (int (*)())0,	/*   */
/* 5*/	nodev,  nodev,   nodev,      (int (*)())0,	/* tth (rm) */
/* 6*/	smopen, smclose, smstrategy, (int (*)())&smtab, /* sm (xy) */
/* 7*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 8*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 9*/	odbopen, odbclose, odstrategy,(int (*)())&odtab,/* od */
/* Plexus promises never to use the following 5 devices so that users may */
/*10*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*11*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*12*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*13*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/*14*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* We make no promises from here on */
	0
};




int	(*cdevsw[])() =
{
/* 0*/	usopen,	usclose,usread,	uswrite,usioctl,0,	/* console */
/* 1*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	
/* 2*/	nulldev,nulldev,mmread,	mmwrite,nodev,0, 		/* mem */
/*3*/	miopen, miclose, miread, miwrite, miioctl,0,	/* mirror dk */
/* 4*/	mtopen,	mtclose,mtread,	mtwrite,mtioctl,0,	/* mt */
/* 5*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* pd */
/* 6*/	tsopen,	tsclose,tsread,	tswrite,tsioctl,0,	/* ts (pt) */
/* 7*/	ramopen,nulldev,ramread,ramwrite,ramioctl,0,	/* ram */
/* 8*/	tthopen,tthclose,tthread,tthwrite,tthioctl,0,	/* tth (rm) */
/* 9*/	smopen, smclose, smread, smwrite, smioctl,0,	/* sm (xy) */
/*10*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*11*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*12*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*13*/	syopen,	nulldev,syread,	sywrite,syioctl,0,	/* tty */
/*14*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* icp ic */
/*15*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* icp sp */
/*16*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* icp pp */
#ifdef NOS
/*17*/	ncfopen,ncfclose,ncfread,ncfwrite,ncfioctl,0,
#else
/*17*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*18*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* icp vpm */
/*19*/	tropen, trclose, trread, trsave,  trioctl,0,	/* trace */
/*20*/	erropen,errclose,errread,nodev, nodev,0, 	/* err */
/*21*/	nulldev,nulldev,prfread,prfwrite,prfioctl,0,	/* prf */
#ifdef NOS
/*22*/	vttyopen,vttyclose,vttyread,vttywrite,vttyioctl,0,/* vtty */
#else
/*22*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*23*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* im */
/*24*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* icp hdlc */
/*25*/  tsopen,tsclose,tsread,tswrite,nodev,0,		/* ts again for ft */
/*26*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*27*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*28*/	tthopen,tthclose,tthread,tthwrite,nodev,0,	/* tth again for crm */
/*29*/	nulldev,nulldev,nodev,nodev,ccbioctl,0,		/* ccb */
/*30*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* acp ic */
/*31*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* acp sp */
/*32*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* acp pp */
/*33*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* acp vpm bisync */
/*34*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* acp vpm hdlc */
/*35*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* acp vpm sdlc */
/*36*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	/* acp dynamic dnld */
/*37*/	odropen,odrclose,odread,odwrite,odioctl,0,	/* od */
/*38*/	nodev,nodev,nodev,nodev,nodev,0,		/* msna */
/*39*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- pts device */
/*40*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- ptc device */
/*41*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- Dnet device */
/*42*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- Net device */
/*43*/	nodev,nodev,nodev,nodev,nodev,0,		/* DDN -- ddn device */
/*44*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- xtty */
/*45*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- admin */
/*46*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- xmem */
/*47*/	nodev,nodev,nodev,nodev,nodev,0,		/* EXOS -- socket */
/*48*/	nodev,nodev,nodev,nodev,nodev,0,		/*  */
/*49*/	nodev,nodev,nodev,nodev,nodev,0,		/*  */
/* Plexus promises never to use the following 10 devices so that users may */
/*50*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*51*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*52*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*53*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*54*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*55*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*56*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*57*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*58*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/*59*/	nodev,nodev,nodev,nodev,nodev,0,		/*    */
/* We make no promises from here on */
};
#endif


int	bdevcnt = (sizeof(bdevsw)/sizeof(bdevsw[0]))/4;
int	cdevcnt	= (sizeof(cdevsw)/sizeof(cdevsw[0]))/6;

/* the following are initialized from sector 0 of disk drive 0 */
dev_t	rootdev	= makedev(0,1);
dev_t	pipedev = makedev(0,1);
dev_t	dumpdev	= makedev(0,1);
dev_t	swapdev	= makedev(0,1);
daddr_t	swplo	= 36000;
int	nswap	= 4000;



int	phypage;
int	diagswits=6;	/* defaults to index6==9600 */
int	leds;
short	cputype;
int	mbusto;
char	msgbuf[MSGBUFS];

/* set to 0 to disable overlapped seeking ( EMSP ) */
int xyoverlap = 1;


struct locklist locklist[NFLOCKS];
#ifdef robin
int numctlrs = 1;		/* number of controllers. Max 4 */
int sbaddr[] = { 0 };		/* scsi bus addr, one for each of above */
#endif

	
int	(*pwr_clr[])() = 
{
	(int (*)())0
};

extern ram_init();
int	(*dev_init[])() = 
{
	ram_init,
	(int (*)())0
};
