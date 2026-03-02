/* SID @(#)conf.c	1.22 */

/*
 *  Configuration information
 */


#define	MEMORY_0 1
#define	TTY_0 1
#define	ERRLOG_0 1
#define PRF_0 1
#define MESG 1
#define SEMA 1
#define SHMEM 1

#define	NBUF	0	/* defaults to 10% of physical memory if 0 */
#define NPBUF	3		
#define	NINODE	200		
#define	NFILE	175		
#define	NMOUNT	13		
#define	CMAPSIZ	50
#define	SMAPSIZ	50
#define DMAPSIZ 10
#define	NCALL	80		
#define	NPROC	100	/* DO NOT SET HIGHER THAN 255-due to init process*/
#define	NTEXT	40		
#if NOS || robin
#define	NCLIST	80
#else
#define	NCLIST	20
#endif
#define	NSABUF	14		
#define	POWER	0
#define	MAXUP	25
#define	NHBUF	64
#define CDLIMIT (1L<<11)	/* default max file size */
#define N_ATTACH  60		/* number of "attaches'/host (68k) */
#define N_HOSTS   30		/* max num of net hosts known to local host */
#define N_VC	 150		/* # of free virtual connection descripters */
#define NFTBUF	125		/* size of ft buffer (kbytes)  max = 127 (robin
				   only) */ 
#define	NRMOUNT		30	/* number of remote mount */
#define NDFSWE		24	/* number of dfs work entries */
#define	NDFSPRO		100	/* number of dfs processes */

#define	MSGMAP	100
#define	MSGMAX	8192
#define	MSGMNB	16384
#define	MSGMNI	50
#define	MSGSSZ	8
#define	MSGTQL	40
#define	MSGSEG	1024

#define	SEMMAP	10
#define	SEMMNI	10
#define	SEMMNS	60
#define	SEMMNU	30
#define	SEMMSL	25
#define	SEMOPM	10
#define	SEMUME	10
#define	SEMVMX	32767
#define	SEMAEM	16384

#define	SHMMAX	(128*1024)
#define	SHMMIN	1
#define	SHMMNI	100
#define	SHMSEG	6
#define	SHMBRK	16
#define	SHMALL	512

#include	"sys/param.h"
#include	"sys/types.h"
#include	"sys/sysmacros.h"
#include	"sys/space.h"
#include	"sys/systm.h"


extern	nodev(), nulldev();
extern	dkopen(), dkclose(), dkread(), dkwrite(), dkstrategy(), 
	dkioctl(), dktab;
extern	mtopen(), mtclose(), mtread(), mtwrite(), mtstrategy(),
	mtioctl(), mttab;
extern	rmopen(), rmclose(), rmread(), rmwrite(), rmstrategy(),
	rmioctl(), rmtab; 
extern	crmopen(), crmclose(), crmread(), crmwrite(); 
extern	syopen(), syclose(), syread(), sywrite(), syioctl();
extern	icopen(), icclose(), icread(), icwrite(), icioctl();
extern	spopen(), spclose(), spread(), spwrite(), spioctl();
extern	ppopen(), ppclose(), ppread(), ppwrite(), ppioctl();
extern	mmread(), mmwrite();
extern	erropen(), errclose(), errread();
extern	prfread(), prfwrite(), prfioctl();
extern	vpmopen(), vpmclose(), vpmread(), vpmwrite(), vpmioctl();
extern	tropen(),  trclose(),  trread(),  trioctl(),  trsave();
extern	imopen(),imclose(),imread(),imwrite(),imioctl();
extern	hdlcopen(), hdlcclose(), hdlcread(), hdlcwrite(), hdlcioctl();
extern  ftopen(), ftclose(), ftread(), ftwrite();

#ifdef robin
extern	scopen(), scclose(), scread(), scwrite(), scstrategy(), 
	scioctl(), sctab;
extern	fpopen(), fpclose(), fpread(), fpwrite(), fpstrategy(),
	bfpopen(),fpioctl(),fptab;
extern	tpopen(), tpclose(), tpread(), tpwrite(), tpstrategy(),
	tpioctl(),tptab;
extern	dlopen(), dlclose(), dlread(), dlwrite(), dlioctl();
extern	rkopen(), rkclose(), rkread(), rkwrite(), rkioctl();
extern	coopen();
#else
extern	ptopen(), ptclose(), ptread(), ptwrite(), ptstrategy(),
	ptioctl(),pttab;
extern	pdopen(), pdclose(), pdread(), pdwrite(), pdstrategy(), 
	pdioctl(), pdtab;
extern	xyopen(), xyclose(), xyread(), xywrite(), xystrategy(), 
	xyioctl(), xytab;
extern	usopen(), usclose(), usread(), uswrite(), usioctl();
#endif


#ifdef NOS
extern	etopen(), etclose(), etread(), etwrite();
extern	ncfopen(), ncfclose(), ncfread(), ncfwrite(), ncfioctl();
extern vttyopen(), vttyclose(), vttyread(), vttywrite(), vttyioctl();
#endif

int	(*bdevsw[])() =
{
/* 0*/	dkopen, dkclose, dkstrategy, (int (*)())&dktab,	/* dk */
/* 1*/	mtopen, mtclose, mtstrategy, (int (*)())&mttab,	/* mt */
#ifndef robin
/* 2*/	pdopen, pdclose, pdstrategy, (int (*)())&pdtab,	/* pd */
#else
/* 2*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
#endif
/* 3*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 4*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
/* 5*/	rmopen, rmclose, rmstrategy, (int (*)())&rmtab,	/* rm */
#ifndef robin
/* 6*/	xyopen, xyclose, xystrategy, (int (*)())&xytab, /* xy */
#else
/* 6*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
#endif
#ifndef robin
/* 7*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
#else
/* 7*/	scopen, scclose, scstrategy, (int (*)())&sctab,	/* sc */
#endif
#ifndef robin
/* 8*/	nodev,  nodev,   nodev,      (int (*)())0,	/*    */
#else
/* 8*/	bfpopen, fpclose, fpstrategy, (int (*)())&fptab,/* fp */
#endif
	0
};

int	(*cdevsw[])() =
{
#ifndef robin
/* 0*/	usopen,	usclose,usread,	uswrite,usioctl,0,	/* console */
#else
/* 0*/	coopen,	dlclose,dlread,	dlwrite,dlioctl,0,	/* console */
#endif
/* 1*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,	
/* 2*/	nulldev,nulldev,mmread,	mmwrite,nodev,0, 		/* mem */
/* 3*/	dkopen,	dkclose,dkread,	dkwrite,dkioctl,0,	/* dk */
/* 4*/	mtopen,	mtclose,mtread,	mtwrite,mtioctl,0,	/* mt */
#ifdef robin
/* 5*/	nodev ,	nodev ,nodev ,	nodev ,nodev ,0,	/*    */
/* 6*/	tpopen,	tpclose,tpread,	tpwrite,tpioctl,0,	/* tp */
#else
/* 5*/	pdopen,	pdclose,pdread,	pdwrite,pdioctl,0,	/* pd */
/* 6*/	ptopen,	ptclose,ptread,	ptwrite,ptioctl,0,	/* pt */
#endif
/* 7*/	nodev ,	nodev ,nodev ,	nodev ,nodev ,0,	/* not used */
/* 8*/	rmopen,	rmclose,rmread,	rmwrite,rmioctl,0,	/* rm */
#ifndef robin
/* 9*/	xyopen, xyclose, xyread, xywrite, xyioctl,0,	/* xy */
#else
/* 9*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*10*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*11*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*12*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
/*13*/	syopen,	nulldev,syread,	sywrite,syioctl,0,	/* tty */
/*14*/	icopen,	icclose,icread,	icwrite,nodev,0,	/* ic */
#ifdef robin
/*15*/	dlopen,	dlclose,dlread,	dlwrite,dlioctl,0,	/* sp */
#else
/*15*/	spopen,	spclose,spread,	spwrite,spioctl,0,	/* sp */
#endif
/*16*/	ppopen,	ppclose,ppread,	ppwrite,ppioctl,0,	/* pp */
#ifdef NOS
/*17*/	ncfopen,ncfclose,ncfread,ncfwrite,ncfioctl,0,
#else
/*17*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*18*/	vpmopen,vpmclose,vpmread,vpmwrite,vpmioctl,0,	/* vpm */
/*19*/	tropen, trclose, trread, trsave,  trioctl,0,	/* trace */
/*20*/	erropen,errclose,errread,nodev, nodev,0, 		/* err */
/*21*/	nulldev,nulldev,prfread,prfwrite,prfioctl,0,	/* prf */
#ifdef NOS
/*22*/	vttyopen,vttyclose,vttyread,vttywrite,vttyioctl,0,/* vtty */
#else
/*22*/	nodev,	nodev, 	nodev,  nodev,  nodev,0,
#endif
#ifdef robin
/*23*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#else
/*23*/	imopen,imclose,imread,	imwrite,imioctl,0,	/* im */
#endif
/*24*/	hdlcopen,hdlcclose,hdlcread,hdlcwrite,hdlcioctl,0,	/* hdlc */
#ifdef robin
/*25*/  ftopen,ftclose,ftread,ftwrite,tpioctl,0,		/* ft */
#else
/*25*/  ftopen,ftclose,ftread,ftwrite,nodev,0,		/* ft */
#endif
#ifdef robin
/*26*/	fpopen,	fpclose, fpread, fpwrite, fpioctl, 0,	/* fp */
#else
/*26*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
#ifdef robin
/*27*/	rkopen,	rkclose, rkread, rkwrite, rkioctl, 0,	/* rk */
#else
/*27*/	nodev,	nodev, 	nodev, 	nodev, 	nodev,0,
#endif
/*28*/	crmopen,crmclose,crmread,crmwrite,nodev,0,	/* crm (caching rm) */
};


int	bdevcnt = 9;
int	cdevcnt	= 29;

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

struct locklist locklist[NFLOCKS];
#ifdef robin
int numctlrs = 1;		/* number of controllers. Max 4 */
int sbaddr[] = { 0 };		/* scsi bus addr, one for each of above */
#endif

	
int	(*pwr_clr[])() = 
{
	(int (*)())0
};

int	(*dev_init[])() = 
{
	(int (*)())0
};
