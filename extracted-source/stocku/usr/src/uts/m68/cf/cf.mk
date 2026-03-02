# 
# SID @(#)cf.mk	1.8

AS=$(PFX)as
CPP=$(PFX)cpp
CC=$(PFX)cc
LD=$(PFX)ld

CFLAGS = -O $(DEFS) -I$(INCRT)
LDFLAGS=-x
FRC =
NAME = $(SYS)$(VER)

all:	init ../$(NAME)

init:
	-if cmp $(INCRT)/sys/maxuser.h\
			$(INCRT)/sys/maxuser$(USERS).h > /dev/null;\
		then echo "	USERS =" $(USERS);\
		else cp $(INCRT)/sys/maxuser$(USERS).h\
			$(INCRT)/sys/maxuser.h; echo "	USERS =" $(USERS);\
	fi;
	cd ../../../uts; $(MAKE) -f uts68.mk "FRC=$(FRC)"
	-$(CC) $(CFLAGS) -c -DSYS=\"`expr '$(SYS)' : '\(.\{1,8\}\)'`\" \
		-DNODE=\"`expr '$(NODE)' : '\(.\{1,8\}\)'`\" \
		-DREL=\"`expr '$(REL)' : '\(.\{1,8\}\)'`\" \
		-DMACH=\"`expr '$(MACH)' : '\(.\{1,8\}\)'`\" \
		-DVER=\"`expr '$(VER)' : '\(.\{1,8\}\)'`\" name.c


../$(NAME): low.o conf.o ../locore.o ../$(LIBPFX)lib[0-9] linesw.o name.o
	$(LD) $(LDFLAGS) low.o ../locore.o conf.o \
		linesw.o ../$(LIBPFX)lib[0-9] name.o  -o ../$(NAME)

clean:
	cd ../../../uts; $(MAKE) -f uts68.mk "INS=$(INS)" clean
	-rm -f *.o

clobber:	clean
	cd ../../../uts; $(MAKE) -f uts68.mk "INS=$(INS)" clobber
	-rm -f *.o

print:
	lnum cf.mk ../cf/*.s ../cf/*.c > /dev/lp


.c.o:
	$(CC) $(CFLAGS) -c $<

.s.o:
	/lib/$(CPP) -P - -DASLANG $(DEFS) $< >tempfile
	$(AS) tempfile -o $@
	rm -f tempfile


linesw.o:\
	$(INCRT)/sys/conf.h\
	$(FRC)

name.o:\
	$(INCRT)/sys/utsname.h\
	$(FRC)


conf.o:\
	$(INCRT)/sys/acct.h\
	$(INCRT)/sys/buf.h\
	$(INCRT)/sys/callo.h\
	$(INCRT)/sys/elog.h\
	$(INCRT)/sys/err.h\
	$(INCRT)/sys/file.h\
	$(INCRT)/sys/inode.h\
	$(INCRT)/sys/io.h\
	$(INCRT)/sys/map.h\
	$(INCRT)/sys/mount.h\
	$(INCRT)/sys/param.h\
	$(INCRT)/sys/peri.h\
	$(INCRT)/sys/proc.h\
	$(INCRT)/sys/space.h\
	$(INCRT)/sys/sysinfo.h\
	$(INCRT)/sys/sysmacros.h\
	$(INCRT)/sys/systm.h\
	$(INCRT)/sys/text.h\
	$(INCRT)/sys/tty.h\
	$(INCRT)/sys/types.h\
	$(INCRT)/sys/var.h\
	$(INCRT)/sys/remote.h\
	$(FRC)

low.o:\
	$(INCRT)/sys/param.h\
	$(INCRT)/sys/trap.h\
	$(INCRT)/sys/remote.h\
	$(FRC)


install:	all

.c.a:
	$(CC) -c $(CFLAGS) $<

FRC:
