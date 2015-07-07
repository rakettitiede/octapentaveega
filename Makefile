# This is a prototype Makefile. Modify it according to your needs.
# You should at least check the settings for
# DEVICE ....... The AVR device you compile for
# CLOCK ........ Target AVR clock rate in Hertz
# OBJECTS ...... The object files created from your source files. This list is
#                usually the same as the list of source files with suffix ".o".
# PROGRAMMER ... Options to avrdude which define the hardware you use for
#                uploading to the AVR and the interface where this hardware
#                is connected. I am using Arduino UNO as ISP and for this the
#                programmer is avrisp
# FUSES ........ Parameters for avrdude to flash the fuses appropriately.
 
DEVICE     = attiny85
CLOCK      = 20000000
OBJECTS    = main.o vga_isr.o
FUSES      = -U lfuse:w:0xff:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m
PROGRAMMER = -c usbasp

AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)
COMPILE = avr-gcc -Wall -Os -flto -std=gnu99 -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)

# Place font data to specific address
LDFLAGS = \
#	-Wl,--section-start=.vgafont=0x1800

# symbolic targets:
all:    main.hex

# font rules
font.h: font.py
	python font.py > font.h
main.o: font.h

.c.o:
	$(COMPILE) -c $< -o $@
 
.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.
 
.c.s:
	$(COMPILE) -S $< -o $@
 
flash:  all
	$(AVRDUDE) -U flash:w:main.hex:i
 
fuse:
	$(AVRDUDE) $(FUSES)
 
# Xcode uses the Makefile targets "", "clean" and "install"
install: flash fuse
 
# if you use a bootloader, change the command below appropriately:
#load: all
#	bootloadHID main.hex
 
clean:
	rm -f main.hex main.elf $(OBJECTS) *~
 
# file targets:
main.elf: $(OBJECTS) font.h
	$(COMPILE) -o main.elf $(OBJECTS) $(LDFLAGS)
 
main.hex: main.elf
	rm -f main.hex
#	avr-objcopy -j .text -j .data -j .vgafont -O ihex main.elf main.hex
	avr-objcopy -j .text -j .data -O ihex main.elf main.hex
	avr-size --format=avr --mcu=$(DEVICE) main.elf
# If you have an EEPROM section, you must also create a hex file for the
# EEPROM and add it to the "flash" target.
 
# Targets for code debugging and analysis:
disasm: main.elf
	avr-objdump -d main.elf
 
cpp:
	$(COMPILE) -E main.c

