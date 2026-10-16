## Simple poor mans ide with ca65 (from cc65 package)

Info from: Link: https://github.com/cc65/cc65/discussions/2123

Assemble script:
```
#!/bin/sh
ca65 $1.s
ld65 -o $1.bin -t none $1.o none.lib
```
Copy bin (*.o) to napple1 prog directory:
```
#!/bin/sh
cp $1.o ../napple1/prog/test.bin
cd ../napple1
./napple1
```
Use Shift-P to load bin file. Give correct start address! (Start Address)R
