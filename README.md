# OctaPentaVeega

Fun hobby project to generate 32 x 16 characters of text on VGA output (or alternatively 64x64 pixel graphics, or split-screen graphics/text) from Attiny85 with 6x10 pixel font.

Data is read from UART at 9600bps. [Subset of ANSI escapes is supported](https://github.com/Jartza/octapentaveega/blob/master/vga_uart_protocol.txt).

Wiring 3 Attinys together gets you 8 color output :)

Links:
* <a href="https://www.youtube.com/watch?v=G1QWNDck0yU" target="_blank">Video: Ansi tester 8-color (ansitester.py)</a>
* <a href="https://www.youtube.com/watch?v=Vw5xGuLFy8Q" target="_blank">Video: Ansi tester Black & White (ansitester.py)</a>
* <a href="https://www.youtube.com/watch?v=YL0RwEtTN70" target="_blank">Video: Graphics mode (tricoder) & left scroll</a>
* <a href="https://www.youtube.com/watch?v=1iC2AHI5caI" target="_blank">Video: Full screen scroll (B/W)</a>
* <a href="https://www.youtube.com/watch?v=936m7FMS__c" target="_blank">Video: Full screen scroll (8-color)</a>
* <a href="https://drive.google.com/file/d/0B2dTzW9TMeBxN29YOVFsZFJ2Sm8/view?usp=sharing&resourcekey=0-qg94SZRgscnID9sQj7wqgg" target="_blank">Video: Multiple individual rows scroll (B/W)</a>
* <a href="https://drive.google.com/file/d/0B2dTzW9TMeBxQ1luNFhwcXl3QjA/view?usp=sharing&resourcekey=0-P5mUCc9mNvyFCUTxm9JVWQ" target="_blank">Picture: 6x10 pixel font</a>
* <a href="https://drive.google.com/file/d/0B2dTzW9TMeBxRzJOQVZMNFE0STg/view?usp=sharing&resourcekey=0-tbPVQ-RSZv2ljsOSo7lrrg" target="_blank">Picture: Generic (B/W)</a>

Board photos:
* <a href="https://drive.google.com/file/d/0B2dTzW9TMeBxaFFxam1uVW05NlE/view?usp=sharing&resourcekey=0-hj-EZfwC4E2AGv0eFjva1Q" target="_blank">B/W board</a>
* <a href="https://drive.google.com/file/d/0B2dTzW9TMeBxRXVzSUNCT1h2NHM/view?usp=sharing&resourcekey=0-VIRaT1kCkgjpB7zByPp_LA" target="_blank">8-color board</a>
* <a href="https://drive.google.com/file/d/0B2dTzW9TMeBxX2VmQmw3aXhWUDA/view?usp=sharing&resourcekey=0-ecXRcLez51cEmPnjZG1DXQ" target="_blank">8-color board back</a>
* <a href="https://drive.google.com/file/d/0B2dTzW9TMeBxUDQ4QUduWDV2TFE/view?usp=sharing&resourcekey=0-0n-sL1mumwSXGCBFCg1Kcg" target="_blank">Arduino shield, 8-color with level shifter (3.3 / 5v compatible)</a>


<p>
<img src="https://raw.githubusercontent.com/Jartza/octapentaveega/master/schematics.png" border="0">

//Jartza
