; ------------------------------------------------------------
; ChatGPT 2026-10-16 - P.Sieg
; Apple-1: 8-Bit-Pseudozufallszahlen als HEX ausgeben
; Assembler: ca65
; Startadresse: $0300
; Ausgabe: $01 bis $FF
; ------------------------------------------------------------

.setcpu "6502"

ECHO = $FFEF

.segment "CODE"

.org $0300

start:
    LDA #$A5
    STA seed

main:
    JSR random8
    STA value

    ; High-Nibble ausgeben
    LDA value
    LSR
    LSR
    LSR
    LSR
    JSR print_hex

    ; Low-Nibble ausgeben
    LDA value
    AND #$0F
    JSR print_hex

    ; Wagenruecklauf
    LDA #$0D
    JSR ECHO

    JMP main

; ------------------------------------------------------------
; Zufallsgenerator (8-Bit-LFSR)
; Rueckgabe: A = Zufallswert
; ------------------------------------------------------------

random8:
    LDA seed
    ASL
    BCC no_xor
    EOR #$1D

no_xor:
    STA seed
    BNE random_ok

    LDA #$A5
    STA seed

random_ok:
    LDA seed
    RTS

; ------------------------------------------------------------
; Hex-Ziffer ausgeben
; Eingabe: A = Wert 0..15
; ------------------------------------------------------------

print_hex:
    AND #$0F
    CMP #$0A
    BCC hex_digit

    ADC #$06

hex_digit:
    ADC #'0'
    JMP ECHO

; ------------------------------------------------------------
; Variablen
; ------------------------------------------------------------

.segment "BSS"

seed:   .res 1
value:  .res 1

