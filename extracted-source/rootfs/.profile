stty erase '^h' kill '^x' echoe
PATH=.:/usr/plx:/bin:/usr/bin:/etc
TZ=PST8PDT
TERM=vt100
EXINIT='set ai nows redraw sm'
export PATH TZ TERM EXINIT
sync
if [ -f /up ] ; then
	rm /up
	sync
	sleep 5
	banner NOW
	sync
else
	echo up > /up
	sync
	init 2
fi
