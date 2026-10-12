# arduino

Mainly my apple 1 emulator based on Mike Chambers 6502 emulation code.

Links:

https://wiki.reactivemicro.com/images/e/ec/LearnToProgramAnApple1.pdf

https://bitsavers.trailing-edge.com/pdf/apple/apple_I/AppleI_BasicMan.pdf

https://github.com/ebruchez/apple1-party/tree/main - tools and libs using cc65 to build apps for apple 1

https://github.com/petersieg/napple1 - nice apple 1 emulator using ncurses

## minicom usage

ASCII file upload with char and line delay:
```
Integration into Minicom:

You can configure ascii-xfr as a custom file transfer protocol inside Minicom by pressing Ctrl-A then O (Configure Minicom) 
-> File transfer protocols, and adding an entry (-c = char delay in ms; -l = line delay in ms):
• Name: Ascii
• Program: /usr/bin/ascii-xfr -sv -c 10 -l 200

Minicom Built-in Character/Line Delay Options

If you are pasting text directly inside Minicom and dropping characters due to slow remote buffers:
1. Press Ctrl-A, then Z to open the help menu.
2. Press T (Terminal settings) to adjust line delays or configure character/newline pacing.
```
   
### some others files:

f-gen.zip - simple frequency generator; just arduino uno required - python tkinter gui on PC

dramarduino.zip - 4164/41256 DRAM Tester with Arduino UNO

pw_freqcnt.zip - frequency counter

A1replica.zip - Apple 1 replica gerber files - see: https://www.applefritter.com/content/apple-1-replica-gerber-files

And the revised A1replica file: Rev. 3 Modifications of Russian A1 By Logan Greer.zip
see: https://www.applefritter.com/content/rev1-modifications-russian-apple-1-files
and: https://www.applefritter.com/content/modifications-russian-apple-1-project-finished


