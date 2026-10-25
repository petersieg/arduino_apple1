# Apple-1 Konsolenemulator (macOS / Linux)

Dieses Verzeichnis enthält `main.c`, ein Makefile und einen kleinen Host-
Kompatibilitätsheader. Kopiere diese Dateien neben das originale `cpu.c` aus
dem Ordner `arduino_6502_apple1/arduino_apple1_rp2040` des Projekts
[petersieg/arduino_apple1](https://github.com/petersieg/arduino_apple1/tree/master/arduino_6502_apple1/arduino_apple1_rp2040).

`cpu.c` wird nicht verändert. Der Header `avr/pgmspace.h` ersetzt nur die
AVR-Programmspeicher-Makros auf dem Hostsystem.

## Bauen

```sh
make
```

Voraussetzung ist ein C-Compiler (Clang oder GCC) und `make`.

## Starten

Nur den Apple-1 Monitor starten:

```sh
./apple1
```

Ein Binärprogramm laden; die Adresse wird hexadezimal angegeben:

```sh
./apple1 programm.bin 0280
```

Die Ladeadresse ist die Startadresse des Roh-Binärinhalts. Es wird kein
Dateiheader erwartet. `Ctrl-Q` beendet den Emulator.

## Hinweise

- Das Terminal wird während der Emulation in den nicht-kanonischen Modus
  geschaltet; die ursprünglichen Terminaleinstellungen werden beim Beenden
  wiederhergestellt.
- Die Apple-1-Tastatur ist historisch großgeschrieben; Kleinbuchstaben werden
  daher in Großbuchstaben umgewandelt.
- Das Original `cpu.c` enthält einen 32-KiB-Array `RAM`. Ob ein Programm in
  den gesamten 64-KiB-Adressraum geladen werden kann, hängt von der
  Speicherabbildung des CPU-Cores ab. Die üblichen RAM-Ladeadressen wie
  `$0280` liegen innerhalb des Arrays.
- `cpu.c` referenziert `RAM` und enthält die Apple-1 ROMs. Das Projekt bleibt
  unter der Lizenz des Originalprojekts (GNU GPL v2 laut Quelltextkommentar).
