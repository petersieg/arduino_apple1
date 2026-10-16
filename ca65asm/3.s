;Danke. Bitte erzeuge ein 6502 apple 1 program, das zufallsgesteuert eine 
;text meldung über mehere Zeilen ausgibt für ca65 assembler

;Gerne! Hier ist ein vollständiges 6502-Programm für den Apple-1, 
;geschrieben für den ca65-Assembler. Es wählt zufällig eine Textmeldung 
;aus und gibt sie über mehrere Zeilen auf dem Bildschirm aus. 
;Anschließend wartet es kurz und wählt eine neue Meldung.

;Die Ausgabe erfolgt über die Woz-Monitor-Routine ECHO bei $FFEF. 
;Zeilenumbrüche werden mit Carriage Return ($0D) erzeugt.

; ============================================================
; Apple-1 - Zufallsgesteuerte Textmeldungen
; ca65 / MOS 6502
; Startadresse: $0300
; Keine Zero Page
; ============================================================

.setcpu "6502"

ECHO = $FFEF

.segment "CODE"
.org $300
.export start

start:
    LDA #$A5
    STA seed

new_message:
    JSR random8

    ; Zufallswert auf 0..2 reduzieren
reduce:
    CMP #3
    BCC choose
    SEC
    SBC #3
    JMP reduce

choose:
    CMP #0
    BEQ show0
    CMP #1
    BEQ show1
    JMP show2

show0:
    LDA #<text0
    STA read_text+1
    LDA #>text0
    STA read_text+2
    JMP print_start

show1:
    LDA #<text1
    STA read_text+1
    LDA #>text1
    STA read_text+2
    JMP print_start

show2:
    LDA #<text2
    STA read_text+1
    LDA #>text2
    STA read_text+2

print_start:
    LDX #$00

print_loop:
read_text:
    LDA $FFFF,X
    BEQ print_end

    ; Apple-1: Bit 7 fuer die Zeichenausgabe setzen
    ORA #$80
    JSR ECHO

    INX
    BNE print_loop

    ; Schutz: Text darf nicht 256 Bytes erreichen
    JMP print_end

print_end:
    ; Zwei Zeilenumbrueche
    LDA #$8D
    JSR ECHO
    LDA #$8D
    JSR ECHO

    ; Kurze Pause
    LDY #$20
pause1:
    LDX #$00
pause2:
    DEX
    BNE pause2
    DEY
    BNE pause1

    JMP new_message

; ------------------------------------------------------------
; 8-Bit-Pseudozufallsgenerator
; ------------------------------------------------------------

random8:
    LDA seed
    ASL
    BCC random_no_xor
    EOR #$1D

random_no_xor:
    STA seed
    BNE random_return
    LDA #$A5
    STA seed

random_return:
    LDA seed
    RTS

; ------------------------------------------------------------
; Texte: $0D wird durch ORA #$80 zu $8D
; ------------------------------------------------------------

text0:
    .byte "HALLO APPLE-1!",$0D
    .byte "DER ZUFALL SPRICHT.",$0D
    .byte "COMPUTER IST BEREIT.",$00

text1:
    .byte "HEUTE IST DEIN TAG!",$0D
    .byte "NEUE IDEEN WARTEN.",$0D
    .byte "PROBIERE ETWAS AUS.",$00

text2:
    .byte "GRUESSE VOM 6502!",$0D
    .byte "ACHT BIT VOLLER SPASS.",$0D
    .byte "WAS KOMMT ALS NAECHSTES?",$00

.segment "BSS"
seed:
    .res 1


