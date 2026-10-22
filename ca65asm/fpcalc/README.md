# Apple-1 Woz FP Calculator (ca65)

This project targets an Apple-1 with RAM available from `$0000` through `$1FFF` (8 KiB). It creates a flat 4096-byte image mapped at `$1000-$1FFF`.

## Contents

- `calc.s` — calculator front end, decimal parser, scientific-format output, and running accumulator.
- `wozfp.s` — the user-supplied Steve Wozniak/Roy Rankin 6502 floating-point source. Its mathematical instructions and constants are preserved; only the fixed-address `.org`/padding directives were replaced with ca65 segments so the linker can place the original regions at `$1D00`, `$1E00`, and `$1F00`.
- `util.s` — user-supplied Apple-1 PIA helpers. `PrintChar` sets bit 7 for the Apple-1 display.
- `apple1.cfg` — linker layout.
- `Makefile` — ca65/ld65 build.

## Build

Install cc65 (which supplies `ca65` and `ld65`), then run:

```sh
make
```

The output is `calc.bin`, a flat 4 KiB image for `$1000-$1FFF`. The linker map is `calc.map`.

## Memory map

- `$1000-$1CFF`: calculator and I/O helpers (must fit before `$1D00`)
- `$1D00-$1DFF`: original Woz/Rankin logarithm routines and constants
- `$1E00-$1EFF`: original exponential routine and constants
- `$1F00-$1FFF`: original basic floating-point routines
- `$0040-$0059`: original Woz FP workspace
- `$0060-$0087`: calculator workspace
- `$D010-$D012`: Apple-1 keyboard/display PIA registers

The image is not a self-describing executable; it must be loaded at `$1000` and started at `$1000` using the monitor or a suitable loader for your Apple-1 setup.

## Use

1. Start at `$1000`.
2. Enter a decimal number and press Return.
3. Enter an operator (`+`, `-`, `*`, `/`) and then the next decimal number followed by Return.
4. Each result becomes the accumulator for the next operation.
5. Enter `C` at the operator prompt, or while entering a number, to clear and start over.

The output format is scientific notation with seven displayed significant digits, e.g. `1.234500E+01`. The six digits after the decimal point are rounded to nearest using one guard digit; ties round upward. Digits are buffered so rounding can carry into the leading digit and exponent. The parser accepts a leading minus and one decimal point and accumulates at most seven input digits; extra digits are ignored. This is a compact calculator UI, not a full BASIC-style expression parser.

## Important verification note

This source package was assembled from the uploaded source files, but the build could not be run in this environment because `ca65`/`ld65` are not installed here. Please run `make` with cc65 before loading it on hardware. Any linker error (especially a segment overflow before `$1D00` or within the fixed 256-byte original routine regions) must be resolved before use. Arithmetic edge cases such as division by zero and out-of-range values are not trapped by this UI; the original routines use `BRK` for certain errors.

## Source provenance

The supplied original floating-point source identifies itself as the July 5, 1976 BASIC floating-point routines by R. Rankin and S. Wozniak. `util.s` includes the Apache License 2.0 notice for Jeff Tranter's 2012 utility code; that notice is retained.

---

floating point calculator using original wozfp.s routines
load at $1000 and start with 1000R - needs 8k Ram!

If anybody want the original routines removed, please let me know, before any other action.

https://www.applefritter.com/node/6876

https://github.com/jefftranter/6502/tree/master/asm/wozfp

```
; ChatGPT 2026-10-22 P.Sieg
; Apple-1 Wozniak/Rankin floating-point calculator
; ca65, NMOS 6502, 8 KiB RAM ($0000-$1FFF)
; Program entry: $1000. Original math code is in wozfp.s; only
; assembler/linker directives were changed to place it at $1D00-$1FFF.
; 
; wozfp.s from: https://raw.githubusercontent.com/jefftranter/6502/master/asm/wozfp/wozfp.s
;           JULY 5, 1976
;     BASIC FLOATING POINT ROUTINES
;       FOR 6502 MICROPROCESSOR
;       BY R. RANKIN AND S. WOZNIAK
; Die rechtliche und praktische Situation gestaltet sich wie folgt:
; Urheberrecht & Status: Der Programmcode wurde ursprünglich im August 1976 im Dr. Dobb’s Journal 
; veröffentlicht und später im Handbuch des Apple II (dem sogenannten „Red Book“, 1978) abgedruckt. 
; Rechtlich gesehen handelt es sich dabei um urheberrechtlich geschützten Code (oft Apple zugeschrieben).
; Praxis in der Retro-Community: Da der Code vor Jahrzehnten als gedrucktes Listing für Bastler 
; und den Homebrew Computer Club freigegeben wurde, wird er in der Retrocomputing-Szene wie 
; Public Domain behandelt. Sie finden den Code frei zugänglich auf Plattformen wie 6502.org oder 
; GitHub zur nicht-kommerziellen Nutzung und für Emulatoren.
; ---
; util.s from: https://raw.githubusercontent.com/jefftranter/6502/master/asm/wozfp/util.s
; Copyright (C) 2012 by Jeff Tranter <tranter@pobox.com>
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
```


