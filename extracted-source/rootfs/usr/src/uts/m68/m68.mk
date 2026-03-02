# 
# SID @(#)m68.mk	5.3

MAKE = $(PFX)make

all: system drivers other network commun  icp

icp: icpstuff acpstuff 
# icp: icpstuff acpstuff vpmicpstuff hdlcicp

# machine is not part of all since it is now done from cf.mk
machine:
	cd ml; $(MAKE) -f ml.mk "FRC=$(FRC)"

system:
	cd os; $(MAKE) -f os.mk "FRC=$(FRC)"

drivers:
	cd io; $(MAKE) -f io.mk "FRC=$(FRC)"

other:
	cd pwb; $(MAKE) -f pwb.mk "FRC=$(FRC)"

network:
	if [ "$(NOSFLAG)" ] ; then \
		cd pnet; $(MAKE) -f pnet.mk "FRC=$(FRC)" "INCRT=$(INCRT)" ; \
	else \
		cd pnet; $(MAKE) -f pnetstub.mk "FRC=$(FRC)" ; \
	fi

commun:
	if [ "$(BUILDICP)" ] ; then \
		$(MAKE) -f m68.mk "FRC=$(FRC)" icp ; \
	fi

acpstuff:
	cd acp; $(MAKE) -f acp.mk acp "SYS=acp5" "VER=m68" "FRC=FRC"
	cd acp; $(MAKE) -f acp.mk install

icpstuff:
	cd icp; $(MAKE) -f icp.mk clean
	cd icp; $(MAKE) -f icp.mk icp "FRC=$(FRC)"
	cd icp; $(MAKE) -f icp.mk install
	cd icp; $(MAKE) -f icp.mk clean

vpmicpstuff:
	cd icp; $(MAKE) -f icpvpm.mk68 clean
	cd icp; $(MAKE) -f icpvpm.mk68 vpm0 "FRC=$(FRC)" "INCRT=$(ROOT)$(INCRT)"
	cd icp; $(MAKE) -f icpvpm.mk68 clean

hdlcicp:
	cd icp/hdlc; $(MAKE) -f icpvpmh.mk68 clean
	cd icp/hdlc; $(MAKE) -f icpvpmh.mk68 vpm0 "FRC=$(FRC)" \
		"INCRT=$(ROOT)$(INCRT)"
	cd icp/hdlc; $(MAKE) -f icpvpmh.mk68 clean

clean:
clean:
	cd ml; $(MAKE) -f ml$.mk clean "INCRT=$(INCRT)"\
		"ROOT=$(ROOT)"
	cd os; $(MAKE) -f os.mk clean "INCRT=$(INCRT)"\
		"ROOT=$(ROOT)"
	cd io; $(MAKE) -f io.mk clean "INCRT=$(INCRT)"\
		"ROOT=$(ROOT)"
	cd pwb; $(MAKE) -f pwb.mk clean "INCRT=$(INCRT)" "ROOT=$(ROOT)"
	cd pnet; $(MAKE) -f pnetstub.mk clean "FRC=$(FRC)" "INCRT=$(INCRT)"

clobber:
	cd ml; $(MAKE) -f ml.mk clobber "INCRT=$(INCRT)"\
		"ROOT=$(ROOT)"
	cd os; $(MAKE) -f os.mk clobber "INCRT=$(INCRT)"\
		"ROOT=$(ROOT)"
	cd io; $(MAKE) -f io.mk clobber "INCRT=$(INCRT)"\
		"ROOT=$(ROOT)"
	cd pwb; $(MAKE) -f pwb.mk clobber "INCRT=$(INCRT)" "ROOT=$(ROOT)"
	cd pnet; $(MAKE) -f pnetstub.mk clobber "FRC=$(FRC)" "INCRT=$(INCRT)"

print:
	cd /$(ROOT)/usr/include; lnum sys/*.h *.h icp/*.h > /dev/lp
	cd /$(ROOT)/usr/src/uts/m68/ml; $(MAKE) -f ml.mk print "ROOT=$(ROOT)"
	cd /$(ROOT)/usr/src/uts/m68/os; $(MAKE) -f os.mk print "ROOT=$(ROOT)"
	cd /$(ROOT)/usr/src/uts/m68/io; $(MAKE) -f io.mk print "ROOT=$(ROOT)"
	cd /$(ROOT)/usr/src/uts/m68/pwb; $(MAKE) -f pwb.mk print "ROOT=$(ROOT)"
	cd /$(ROOT)/usr/src/uts/m68/cf; $(MAKE) -f cf.mk print "ROOT=$(ROOT)"
	cd /$(ROOT)/usr/src/uts/m68/icp; $(MAKE) -f icp.mk print "ROOT=$(ROOT)"
	cd /$(ROOT)/usr/src/uts/m68/pnet; $(MAKE) -f pnetstub.mk print "ROOT=$(ROOT)"

cxref:
	cxref ml/*.s os/*.c io/*.c cf/*.[cs] pwb/*.c icp/*/*.[cs] pnet/*/*.c h/*.h > cxref.$(REL)

FRC:
