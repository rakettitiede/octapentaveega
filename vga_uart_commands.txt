Attiny85 VGA ANSI escape codes:
===============================

Attiny85 VGA supports a limited subset of ANSI escapes.

ANSI sequence begins when "Escape" 0x1B (ascii 27 / ESC) character
followed by [ character is encountered.

Following ANSI escapes are supported:
-----------------------------------------------------------------------------
Move cursor location		<ESC>[#row#;#column#H	#row# = 0 .. 13
				<ESC>[#row#;#column#f	#colunn# = 0 .. 31

Leaving both values undefined moves to (0,0):
<ESC>[H is equal to <ESC>[0;0H

Moving cursor outside defined area has undefined effect.
-----------------------------------------------------------------------------
Clear screen and move cursor	<ESC>[2J
to upper left corner (0,0)
-----------------------------------------------------------------------------
Set colors (or reset to		<ESC>[#color#;#color#m
default color). Selected
color will stay active until
reset or new color selected.

#color# = color number		Foreground	Background
	black			   30		   40
	red			   31		   41
	green			   32		   42
	yellow			   33		   43
	blue			   34		   44
	magenta			   35		   45
	cyan			   36		   46
	white			   37		   47
	reset to defaults	   0

Color command supports maximum two arguments. Suggested way is to use
value 0 only alone in a command: <ESC>[0m resets colors to default.

Example: <ESC>[34;47m activates blue text with white background color.
-----------------------------------------------------------------------------

<ESC><ESC> sends ASCII character 27 to screen.
