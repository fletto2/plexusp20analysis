#include <stdio.h>
#include <string.h>
main(){
	char line[100];
	register int i, k, l, m;
	k = 0;
top:
	if ( gets(line) == 0 ) exit();
	l = k;
	k = strlen(line) * 35000;
	if (strchr(line,"") == 0) m = 200000;
		else m = 2000000;
	if (m < l) m = l;
	if (m < k) m = k;
	printf("%s\n",line);
	i = 0;
loop:	if (i++ < m) goto loop;
	goto top;
	}
