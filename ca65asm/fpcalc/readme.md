## floating point calculator using original wozfp.s routines

### load at $1000 and start with 1000R - needs 8k Ram!

If anybody want the original routines removed, please let me know, before any other action.

https://www.applefritter.com/node/6876

https://6502.org/source/floats/wozfp1.txt

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
