CA65 ?= ca65
LD65  ?= ld65

all: calc.bin

calc.o: calc.s
	$(CA65) -g -o $@ $<

util.o: util.s
	$(CA65) -g -o $@ $<

wozfp.o: wozfp.s
	$(CA65) -g -o $@ $<

calc.bin: calc.o util.o wozfp.o apple1.cfg
	$(LD65) -C apple1.cfg -m calc.map -o $@ calc.o util.o wozfp.o

clean:
	rm -f *.o calc.bin calc.map

.PHONY: all clean
