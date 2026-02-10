// 12.01.2015 (c) P.Sieg simple Apple 1 emulator based on arduino_6502 
// project from miker00lz (Mike Chambers)
// Link: http://forum.arduino.cc/index.php?topic=193216.0
// apple 1 roms are (c) Steve Wozniak / Apple Inc. Status is Freeware
// according to: http://www.callapple.org/soft/ap1/emul.html
// a1 assembler (c) 9/2006 San Bergmans released as freeware
// Link: http://www.sbprojects.com
// My code released under GNU GPL V2

uint8_t curkey = 0;
uint8_t iskey  = 0;

extern "C" {
  uint16_t getpc();
  uint8_t getop();
  void exec6502(int32_t tickcount);
  void reset6502();
  void serout(uint8_t val) {
    //Serial.print(val, HEX);
    //Serial.println();
    if (val == 13) {
      Serial.println();
      }
    else {
      Serial.write(val);
      }  
  }
  uint8_t isakey() {
    if (Serial.available()) iskey  = 0x80;
    else iskey = 0;
    return(iskey);
  }
  uint8_t getkey() {
    curkey = Serial.read() & 0x7F;
    // make a-z => A-Z
    if ((curkey >= 97) && (curkey <= 122)) curkey = curkey - 0x20;
    return(curkey);
  }
  void clearkey() {
    curkey = 0;
  }
  void printhex(uint16_t val) {
    Serial.print(val, HEX);
    Serial.println();
  }
}

void setup () {
  Serial.begin (9600);
  Serial.println("apple 1 emulator");
  Serial.println ();

  reset6502();
}

void loop () {
  exec6502(100); //if timing is enabled, this value is in 6502 clock ticks. otherwise, simply instruction count.
}

