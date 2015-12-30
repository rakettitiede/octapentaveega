#################################################################################
##                                                                             ##
##   Very simple ANSI-tester Python application for Attiny85 VGA               ##
##                                                                             ##
##                                                                             ##
##   (C) Copyright 2015 Jari Tulilahti                                         ##
##                                                                             ## 
##   All right and deserved.                                                   ## 
##                                                                             ##
##   Licensed under the Apache License, Version 2.0 (the "License")#           ##
##   you may not use this file except in compliance with the License.          ##
##   You may obtain a copy of the License at                                   ##
##                                                                             ##
##       http://www.apache.org/licenses/LICENSE-2.0                            ##
##                                                                             ##
##   Unless required by applicable law or agreed to in writing, software       ##
##   distributed under the License is distributed on an "AS IS" BASIS,         ##
##   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ##
##   See the License for the specific language governing permissions and       ##
##   limitations under the License.                                            ##
##                                                                             ##
#################################################################################

import serial
import time
import random
import sys

# Give port name of your UART as first argument. No error checking
# here, sorry.
#
ser = serial.Serial(sys.argv[1], 9600,  timeout = 1)

serwrite = lambda x: ser.write(bytearray(map(ord, x)))
move_to = lambda x, y: serwrite("\x1B[{0};{1}H".format(y, x))
set_color = lambda fg, bg = 0: serwrite("\x1B[3{0};4{1}m".format(fg, bg))

serwrite("xxxxx\x08") # dismiss if we're left in ANSI mode...
serwrite("\x1B[2J") # Clear screen
serwrite("\x1B[m") # Reset colors
serwrite("\x1B[?7l") # disable wrap

# Show color map
scrolltext = "Attiny85 VGA, displaying 32x14 characters on screen " \
	"with 6x8 pixel font. Single Attiny85 for Black & White output, " \
	"Three Attiny85s for 8 color output :=) " \
	"Industry standard VGA 640x480 @ 60Hz. It's called OctaPentaVeega...                                   "

a = 0
b = 0
c = 0
d = 0

while True:
	move_to(31, 0)
	serwrite(scrolltext[a])
	serwrite("\x1B[0[")

	move_to(31, 5)
	serwrite(scrolltext[b])
	serwrite("\x1B[5[")
	serwrite(scrolltext[b+1])
	serwrite("\x1B[5[")

	move_to(31, 10)
	serwrite(scrolltext[c])
	serwrite("\x1B[10[")
	serwrite(scrolltext[c+1])
	serwrite("\x1B[10[")
	serwrite(scrolltext[c+2])
	serwrite("\x1B[10[")

	move_to(31, 15)
	serwrite(scrolltext[d])
	serwrite("\x1B[15[")
	serwrite(scrolltext[d+1])
	serwrite("\x1B[15[")
	serwrite(scrolltext[d+2])
	serwrite("\x1B[15[")
	serwrite(scrolltext[d+3])
	serwrite("\x1B[15[")

	a += 1
	b += 2
	c += 3
	d += 4

	if a > len(scrolltext) - 1:
		a = 0

	if b > len(scrolltext) - 2:
		b = 0

	if c > len(scrolltext) - 3:
		c = 0

	if d > len(scrolltext) - 4:
		d = 0

ser.close()
