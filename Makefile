# This is a temp makefile
 
DEVICE     = attiny85
FUSES      = -B 12 -U lfuse:w:0xe0:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m
PROGRAMMER = -c usbasp
AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)
COMPILE = avra

# symbolic targets:
all:    vga.hex

flash:  all
	$(AVRDUDE) -U flash:w:vga.hex:i
 
fuse:
	$(AVRDUDE) $(FUSES)
 
install: flash fuse
 
clean:
	rm -f *.hex *.obj *.lst *.cof *~
 
vga.hex: vga.asm font.inc tn85def.inc
	$(COMPILE) vga.asm
