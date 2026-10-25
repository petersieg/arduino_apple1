CC = cc
CFLAGS = -O2 -Wall -Wextra -std=c99
CPPFLAGS = -I. -include console.h

TARGET = apple1
SOURCES = main.c cpu.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SOURCES) console.h avr/pgmspace.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $(SOURCES)

clean:
	rm -f $(TARGET) *.o

