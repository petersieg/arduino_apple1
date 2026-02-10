# simple apple 1 emulator for arduino

```Header
// 12.01.2015 (c) P.Sieg simple Apple 1 emulator based on arduino_6502 
// project from miker00lz (Mike Chambers)
// Link: http://forum.arduino.cc/index.php?topic=193216.0
// apple 1 roms are (c) Steve Wozniak / Apple Inc. Status is Freeware
// according to: http://www.callapple.org/soft/ap1/emul.html
// a1 assembler (c) 9/2006 San Bergmans released as freeware
// Link: https://www.sbprojects.net/projects/apple1/a1asm.php
// My code released under GNU GPL V2

apple 1 woz monitor short overview

1. examining memory

<adr>.<adr><cr>

40.5f<cr> = mem from 40 to 5f

also:
40<cr> = just mem 40

.5f<cr> = from curr. mem to 5f

2. change memory

<adr>:<data><cr>

0000: 01<cr> (systems show 0000: xx = old mem contents)

also:
0000: <data1> <data2> ... <dataN><cr>

3. run a program

<adr><cr>
R<cr>

---

D020:0 -> Basic (default)
D020:1 -> Assembler (WOZMON gets back to wozmon)

E000
R

Send files though terminal program with char delay and line delay!
Lines must end with CR+LF!

To get back from basic to wozmon:
CALL -256

To get back to basic from wozmon (warm start):
E283R

---

woz monitor routines

getline = FF1F

prbyte = FFDC
will print content of reg. A
contents of A will be destroyed

prhex = FFE5
will print least sign. nibble from A as hex
contents of A will be destroyed

---

The next addresses are not exactly RAM locations, which doesn't make them less important though. They are the 6821 PIA control registers.
KBD 	$D010 	Keyboard input register. This register holds valid data when b7 of KBDCR is "1". 
		Reading KBD will automatically clear b7 of KBDCR.
		Bit b7 of KBD is permanently tied to +5V. The monitor expects only upper case characters.
 	 	 
KBDCR 	$D011 	The only bit which we are interested in in this register is the read-only bit b7. 
		It will be set by hardware whenever a key is pressed on the keyboard. 
		It is cleared again when the KBD location is read.
 	 	 
DSP 	$D012 	Bits b6..b0 are the character outputs for the terminal display. 
		Writing to this register will set b7 of DSP, which is the only input bit of this register.
		The terminal hardware will clear bit b7 as soon as the character is accepted. 
		This may take up to 16.7 ms though!
 	 	 
DSPCR 	$D013 	This register is better left untouched, it contains no useful data for a user program. 
		The Woz Monitor has initialized it for you. Changing the contents may kill the terminal 
		output until you press RESET again. 


```

