/*  */
#include "_sccsid.h"
_SCCSID("@(#)date.c	1.1","4/19/84")

/*
 * date(t) -- returns a pointer to the current date and time in ascii
 *	t is a time as returned by time(2)
 */
#include	"lp.h"

SCCSID("@(#)date.c	3.1")

#define	DAYSIZE		4
#define	DATESIZE	13

char *
date(t)
time_t t;
{
	char *ctime(), *dp;

	dp = ctime(&t) + DAYSIZE;
	*(dp + DATESIZE -1) = '\0';
	return(dp);
}
