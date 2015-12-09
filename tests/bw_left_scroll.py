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

serwrite("xxxxx\x08") # dismiss if we're left in ANSI mode...
serwrite("\x1B[2J") # Clear screen
serwrite("\x1B[m") # Reset colors
serwrite("\x1B[?7l") # disable wrap

# Show color map
scrolltext = "               " \
	"Attiny85 VGA, displaying 32x14 characters on screen " \
	"with 6x8 pixel font. Single Attiny85 for Black & White output, " \
	"Three Attiny85s for 8 color output :=) " \
	"Industry standard VGA 640x480 @ 60Hz. It's called OctaPentaVeega..." \
	"                    "

a = 0

while True:
	for z in range(14):
		move_to(31, z)
		serwrite(scrolltext[a+(14 - z)])
		ser.flush()
	serwrite("\x1BD")
	ser.flush()

	a += 1

	if a > len(scrolltext) - 15:
		a = 0


ser.close()
