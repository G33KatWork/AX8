OBJDIR = build/obj
PROJECTROOT = $(shell pwd)

#Uncomment this for the 1200 avr
#TARGET = a90s1200
#must be built first with avr-gcc
#HEXFILE = sw/1200_test/test.hex
#instance name, see a90s1200.vhd
#ROMNAME = ROM1200
#address width, see a90s1200.vhd
#ROMADDRESSWIDTH = 9

#Uncomment this for the 2313 avr
TARGET = a90s2313
HEXFILE = sw/2313_test/test.hex
#instance name, see a90s2313.vhd
ROMNAME = ROM2313
#address width, see a90s2313.vhd
ROMADDRESSWIDTH = 10

#Important! If you change this, change it in the scr files in build/scripts, too!
TARGETFPGA = xc3s700an-fgg484-4
BOARD = starterkit

TARGETFPGA = xc3s1200e-fg320-4
BOARD = nexys2

CONSTRAINTS = $(TARGET)_$(BOARD)_constraints.ucf
XSTSCRIPT = build/scripts/$(TARGET).scr

#--------------------------------------------------------------------

#root of your xilinx binaries
XILINXROOT = /opt/Xilinx/11.1/ISE/bin/lin
XILINXROOT = /home/david/Data/devel/apps/Xilinx/11.1/ISE/bin/lin

#be sure to build this tool, first
HEX2ROM = sw/hex2rom
XST = $(XILINXROOT)/xst
NGDBUILD = $(XILINXROOT)/ngdbuild
MAP = $(XILINXROOT)/map
PAR = $(XILINXROOT)/par
BITGEN = $(XILINXROOT)/bitgen

#--------------------------------------------------------------------

# main rule
all: $(TARGET).bit

buildrom:
	$(HEX2ROM) $(HEXFILE) $(ROMNAME) $(ROMADDRESSWIDTH)l16x > $(OBJDIR)/ROM.vhd

prepare:
	cat $(PROJECTROOT)/$(XSTSCRIPT).tpl | sed -e "s/TARGET/$(TARGETFPGA)/" > $(PROJECTROOT)/$(XSTSCRIPT) 

synthesize: prepare
	cd $(OBJDIR); $(XST) -ifn $(PROJECTROOT)/$(XSTSCRIPT)
	cd $(OBJDIR); $(NGDBUILD) -p $(TARGETFPGA) -uc $(PROJECTROOT)/$(CONSTRAINTS) $(TARGET).ngc $(TARGET).ngd

map:
	cd $(OBJDIR); $(MAP) -p $(TARGETFPGA) -cm speed -c 100 -tx on -o $(TARGET).ncd $(TARGET).ngd

placeandroute:
	cd $(OBJDIR); $(PAR) -ol std -t 1 $(TARGET).ncd -w $(TARGET).ncd

$(TARGET).bit: buildrom synthesize map placeandroute
	cd $(OBJDIR); $(BITGEN) -w $(TARGET).ncd $@
	mv $(OBJDIR)/$@ $(PROJECTROOT)

clean:
	rm -rf $(OBJDIR)/*
	rm -rf $(TARGET).bit

.PHONY: all clean

