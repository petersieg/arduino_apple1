CA65 ?= ca65
LD65 ?= ld65

.PHONY: all clean
all: 4xttt.bin

4xttt.o: 4xttt.s
	$(CA65) --cpu 6502 -g -l 4xttt.lst -o $@ $<

4xttt.bin: 4xttt.o apple1.cfg
	$(LD65) -C apple1.cfg -o $@ -m 4xttt.map -Ln 4xttt.lbl $<

clean:
	rm -f 4xttt.o 4xttt.bin 4xttt.lst 4xttt.map 4xttt.lbl
