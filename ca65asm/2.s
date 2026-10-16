; ------------------------------------------------------------
; ChatGPT 2026-10-16 P.Sieg
; Apple-1 Zufallszahlengenerator fuer ca65
; CPU: MOS 6502
; Ausgabe: Dezimalzahlen 1..255 ueber den Woz Monitor
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
        JSR print_number

        LDA #$0D        ; Wagenruecklauf
        JSR ECHO

        JMP main

; ------------------------------------------------------------
; 8-Bit-Pseudozufallsgenerator
; Rueckgabe: A = 1..255
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
; Dezimalzahl ausgeben
; Eingabe: value
; ------------------------------------------------------------

print_number:
        LDA #0
        STA hundreds
        STA tens

        LDA value

hundreds_loop:
        CMP #100
        BCC tens_loop_start
        SEC
        SBC #100
        INC hundreds
        JMP hundreds_loop

tens_loop_start:
        CMP #10
        BCC ones_ready
        SEC
        SBC #10
        INC tens
        JMP tens_loop_start

ones_ready:
        STA ones

        LDA hundreds
        BEQ print_tens
        CLC
        ADC #'0'
        JSR ECHO

print_tens:
        LDA hundreds
        BNE print_tens_digit

        LDA tens
        BEQ print_ones

print_tens_digit:
        LDA tens
        CLC
        ADC #'0'
        JSR ECHO

print_ones:
        LDA ones
        CLC
        ADC #'0'
        JSR ECHO
        RTS

; ------------------------------------------------------------
; Variablen
; ------------------------------------------------------------

.segment "BSS"
seed:       .res 1
value:      .res 1
hundreds:   .res 1
tens:       .res 1
ones:       .res 1

