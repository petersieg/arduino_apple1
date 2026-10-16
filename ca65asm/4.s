; ChatGPT 2026-10-16 P.Sieg
; Apple-1: Zufällige Ausgabe von "/" und "\"
; Assembler: ca65
; Ausgabe: Apple-1 Monitor-Routine ECHO ($FFEF)

.setcpu "6502"

ECHO = $FFEF

.segment "CODE"

.org $300

start:
    ; Zufalls-Seed initialisieren
    LDA #$A7
    STA seed

loop:
    ; Einfachen 8-Bit-Pseudozufallsgenerator aufrufen
    JSR random

    ; Bit 0 bestimmt das auszugebende Zeichen
    AND #$01
    BEQ slash

backslash:
    LDA #$5C        ; ASCII "\"
    JSR ECHO
    JMP loop

slash:
    LDA #$2F        ; ASCII "/"
    JSR ECHO
    JMP loop

; -------------------------------------------------
; 8-Bit-Pseudozufallsgenerator
; Linear Feedback Shift Register (LFSR)
; -------------------------------------------------
random:
    LDA seed
    ASL A           ; Links schieben
    BCC no_xor
    EOR #$1D        ; Rückkopplung
no_xor:
    STA seed
    RTS

.segment "BSS"
seed:
    .res 1

