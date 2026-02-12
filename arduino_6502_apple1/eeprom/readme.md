# This is a 8x32k chip serial eeprom bank

It can be utilized to copy ram to a disk (32k 24LC256 serial eeprom chip) and back.

Eagle (+JLCPCB gerber) in 8xeep.zip file.

pcb has errors! U7 has same address as U3. Footprint of smd IC's is too small (there are at least 2 footprints available for 24LC256 from Sparkfun. With some pin bending and difficult hand soldering, it can be used. 

Free for personell use.

eep.ino shows example code.

![pcb](https://github.com/petersieg/arduino/blob/master/arduino_6502_apple1/eeprom/8xeep.png)

New pcb ordered as of August 2018. Files are in 8xeep-2.zip.

![pcb](https://github.com/petersieg/arduino/blob/master/arduino_6502_apple1/eeprom/8xeep-2.png)

New pcb has arrived and soldering is a LOT easier now. Tested with first 4 eeproms and works as expected.

Picture of V1 and V2 for comparison:

![V1+2](https://github.com/petersieg/arduino/blob/master/arduino_6502_apple1/eeprom/8xeep%20V1u2.JPG)





