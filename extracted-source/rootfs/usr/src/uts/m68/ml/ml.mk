#
# SID @(#)ml.mk	5.2

FILES=end.o start.o copy.o cswitch.o math.o misc.o trap.o userio.o sky.o
AS=as
CPP=/lib/cpp
LD=/bin/ld
CFLAGS=$(DEFS)
ASFLAGS=
INCRT=/usr/include

all:	$(FILES)
	$(LD) -r -o ../locore.o $(FILES)

.s.o:
	$(CPP) -P - $(CFLAGS) -I$(INCRT) $< >tmp.s
	$(AS) $(ASFLAGS) tmp.s
	mv tmp.o $*.o
	rm tmp.s

copy.o:\
	rcopy.s\
	$(INCRT)/sys/param.h\
	$(INCRT)/sys/psl.h\
	$(INCRT)/sys/page.h\
	$(FRC)
cswitch.o:\
	$(INCRT)/sys/param.h\
	$(INCRT)/sys/psl.h\
	$(INCRT)/sys/page.h\
	$(INCRT)/sys/mtpr.h\
	$(FRC)
end.o:\
	$(INCRT)/sys/mtpr.h\
	$(FRC)
math.o:\
	$(FRC)
misc.o:\
	$(INCRT)/sys/psl.h\
	$(INCRT)/sys/page.h\
	$(INCRT)/sys/mtpr.h\
	$(FRC)
sky.o:\
	$(INCRT)/sys/sky.h\
	$(INCRT)/sys/param.h\
	$(INCRT)/sys/sysmacros.h\
	$(INCRT)/sys/mtpr.h\
	$(INCRT)/sys/psl.h\
	$(INCRT)/sys/page.h\
	$(INCRT)/sys/signal.h\
	$(FRC)
start.o:\
	rstart.s\
	$(INCRT)/sys/param.h\
	$(INCRT)/sys/mc146818.h\
	$(INCRT)/sys/mtpr.h\
	$(INCRT)/sys/usart.h\
	$(INCRT)/sys/page.h\
	$(INCRT)/sys/psl.h\
	$(FRC)
trap.o:\
	rtrap.s\
	strap.s\
	$(INCRT)/sys/trap.h\
	$(INCRT)/sys/mtpr.h\
	$(INCRT)/sys/mc146818.h\
	$(FRC)
userio.o:\
	ruserio.s\
	$(INCRT)/sys/param.h\
	$(INCRT)/sys/psl.h\
	$(INCRT)/sys/page.h\
	$(FRC)
