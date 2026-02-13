# Quick hack to compile it for esp-01

the a1.bin is ready to be flashed to a esp-01 at 0x0000.

Update 2022 - for esp32 insert the two forward declarations for setup() and loop():
```
// My code released under GNU GPL V2

uint8_t curkey = 0;
uint8_t iskey  = 0;

void setup (void);
void loop (void);

extern "C" {
```

