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
serwrite("\x1BT") # disable tricoder
serwrite("\x1B[2J") # Clear screen
serwrite("\x1B[m") # Reset colors
serwrite("\x1B[?7h") # enable wrap
serwrite("\x1B[0]") # disable graphics

for x in range(512):
	ch = x % 256
	if ch in [8,10,13,27,127]: # Escape special characters
		serwrite(chr(27) + chr(ch))
	else:
		serwrite(chr(ch))
	if x == 510:
		serwrite("\x1B[?7l") # disable wrap

ser.flush()
ser.close()