## Simple poor mans ide with ca65 (from cc65 package)

Info from: Link: https://github.com/cc65/cc65/discussions/2123

Assemble script:
```
#!/bin/sh
ca65 $1.s
ld65 -o $1.bin -t none $1.o none.lib
```
Copy bin (*.bin) to napple1 prog directory (here always fixed to test.bin - up 2 you):
```
#!/bin/sh
cp $1.bin ../napple1/prog/test.bin
cd ../napple1
./napple1
```
Use Shift-P to load bin file. Give correct start address! (Start Address)R

Then create an Apple 1 compatible hex file using bin2woz
```
-rw-r--r--  1 ich  staff     32 15 Okt 19:40 hello.bin
ich@Air-von-ich ca65asm % ./bin2woz hello.bin 0x300
0300: A2 00 BD 12 03 F0 08 09 80 20 EF FF E8 D0 F3 4C
0310: 0F 03 0D 48 45 4C 4C 4F 20 57 4F 52 4C 44 0D 00
```

1 - Erzeuge Zufallszahlen (1-255) und gib sie als HEX aus

2 - Erzeuge Zufallszahlen (1-255) und gib sie als Dezimalzahl aus

3 - Gib zufällig mehrzeilige Meldungen aus

4 - Gib zufällig / oder \ aus

reverse - sortiere bis 1..9

arecibo/arecibo - show arecibo message

matrix - matrix like screen output using vt100 esc sequences

connect4 - as name says ;-)

fpcalc - foating point calculator using original wozfp.s routines

4:

![4](https://github.com/petersieg/arduino_apple1/blob/master/ca65asm/4.png)

reverse:

![reverse](https://github.com/petersieg/arduino_apple1/blob/master/ca65asm/reverse.png)

arecibo:

![arecibo](https://github.com/petersieg/arduino_apple1/blob/master/ca65asm/arecibo.png)

matrix (only works on hardware emulator with serial output into terminal that can handle vt100 codes):

![matrix](https://github.com/petersieg/arduino_apple1/blob/master/ca65asm/matrix/matrix.png)

connect4:

![connect4](https://github.com/petersieg/arduino_apple1/blob/master/ca65asm/connect4/connect4.png)

fpcalc:

![calc](https://github.com/petersieg/arduino_apple1/blob/master/ca65asm/fpcalc/calc.png)


