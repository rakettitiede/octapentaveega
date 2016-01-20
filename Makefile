# Crude makefile for Attiny85 VGA project
# 
#  This is intended to be used with AVRA command-line assembler for AVR.
#   
set-defaults = $(eval VGACOLOR = red)
check-var-defined = $(if $(strip $($1)),,$(call set-defaults))
$(call check-var-defined,VGACOLOR)

# Some conditionals depending on color chosen. 
# 
# make VGACOLOR = red | green | blue
# make fuse VGACOLOR = red | green | blue
# make flash VGACOLOR = red | green | blue
# 
# Red color will be the "master", driving the hsync and vsync, green and blue
# are "slaves", just listening to UART and drawing pixels. Syncing happens
# connecting HSYNC (PB4) of master to PB0 of slaves. 
# 
# Leaving VGACOLOR undefined compiles "red" (master) by default
# 
# Master can be used standalone if you only need B/W output.
# 
# Oscillator clock (20MHz) connects like following:
# 
# OSC -> blue PB3
# blue PB4 -> green PB3
# green PB4 -> red PB3
#
ifeq ($(VGACOLOR),red)
	FUSES = -B 12 -U lfuse:w:0xe0:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m # External clock in to PB3, slow startup
	AVRAFLAGS = --define VGA_MASTER --define COLOR_BIT=0
else
	FUSES = -B 12 -U lfuse:w:0xa0:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m # Clock in to PB3, clock out from PB4, slow startup
	ifeq ($(VGACOLOR),green)
		AVRAFLAGS = --define VGA_SLAVE --define COLOR_BIT=1
	else
		AVRAFLAGS = --define VGA_SLAVE --define COLOR_BIT=2
	endif
endif

# Change this to reflect your programmer
#
#PROGRAMMER = -c avrispmkii -P /dev/cu.usbmodemU21 -B4
PROGRAMMER = -c usbasp

# Don't change below
#
DEVICE     = attiny85
AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)
COMPILE = avra $(AVRAFLAGS)

# symbolic targets:
all:    vga-$(VGACOLOR).hex

flash:  all
	$(AVRDUDE) -U flash:w:vga-$(VGACOLOR).hex:i
 
fuse:
	$(AVRDUDE) $(FUSES)
 
install: fuse flash
 
clean:
	rm -f *.hex *.obj *.lst *.cof *~
 
vga-red.hex vga-blue.hex vga-green.hex: vga.asm font.inc pixels.inc tn85def.inc
	$(COMPILE) -l vga.lst vga.asm
	mv vga.hex vga-$(VGACOLOR).hex

font.inc: vgafont.dat vgafont.py
	python vgafont.py

pixels.inc: graphfont.py
	python graphfont.py
