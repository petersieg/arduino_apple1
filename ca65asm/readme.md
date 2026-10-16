## Simple poor mans ide with ca65 (from cc65 package)

Info from: Link: https://github.com/cc65/cc65/discussions/2123

Assemble script:
```
#!/bin/sh
ca65 $1.s
ld65 -o $1.bin -t none $1.o none.lib
```
Copy bin (*.o) to napple1 prog directory (here always fixed to test.bin - up 2 you):
```
#!/bin/sh
cp $1.o ../napple1/prog/test.bin
cd ../napple1
./napple1
```
Use Shift-P to load bin file. Give correct start address! (Start Address)R

Then create an Apple 1 compatible hex file using https://github.com/davidly/hd
```
hd -w:0x1000 ttt >ttt.hex
```
