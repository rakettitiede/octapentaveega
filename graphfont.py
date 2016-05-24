#
#   Quick'n'Dirty Font Creator & Reorganizer for Attiny85 VGA.
# 
#   Copyright 2015-2016 Jari Tulilahti
#   
#   All right and deserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
import sys
import functools

pixels = [ 0b00000000, 0b00001100, 0b11110000, 0b11111100 ]

font = [0] * 256 * 10

pixrows = 3

for char in range(256):
	row = 0
	number = char 
	for i in range(4):
		pixrows ^= 1
		pix = pixels[(number >> 6) & 3]
		number <<= 2
		for x in range(pixrows):
			font[(char * 10) + row] = pix
			row += 1

f = open("pixels.inc", "w")

f.write( ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;   32 x 16 character VGA output with UART for Attiny85.                      ;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;   Copyright 2015-2016 Jari Tulilahti                                        ;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;   All right and deserved                                                    ;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;   Licensed under the Apache License, Version 2.0 (the \"License\");           ;;\n")
f.write( ";;   you may not use this file except in compliance with the License.          ;;\n")
f.write( ";;   You may obtain a copy of the License at                                   ;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;       http://www.apache.org/licenses/LICENSE-2.0                            ;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;   Unless required by applicable law or agreed to in writing, software       ;;\n")
f.write( ";;   distributed under the License is distributed on an \"AS IS\" BASIS,         ;;\n")
f.write( ";;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ;;\n")
f.write( ";;   See the License for the specific language governing permissions and       ;;\n")
f.write( ";;   limitations under the License.                                            ;;\n")
f.write( ";;                                                                             ;;\n")
f.write( ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n")
f.write("\n")
f.write( "; Automatically generated file. DO NOT EDIT!\n")
f.write("\n")
f.write( ".cseg\n")
f.write( ".org 0x600\n")
f.write("\n")
f.write( "pixels:\n")
f.write( "\t.db ")

cnt = 0

for i in range(10):
	for h in range(256):
		fontline = font[(h * 10) + i]
		f.write("0x{0:02x}".format(fontline))
		cnt += 1
		if cnt == 8:
			if [h, i] == [255, 9]:
				f.write("\n")
			else:
				f.write("\n\t.db ")
				cnt = 0
		else:
			f.write(", ")

f.write("\n")
f.close()
