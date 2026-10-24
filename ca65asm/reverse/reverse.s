
; ============================================================
; REVERSE - Apple I BASIC nach 6502 / ca65
;
; Ziel:       Apple I / Emulator mit Woz-Monitor
; Start:      $0300
; CPU:        NMOS 6502
; Toolchain:  ca65 / ld65 (cc65)
;
; Monitor:
;   $FFEF = ECHO
;   $FF00 = Monitor-Einstieg/Reset
;
; Apple-I-Hardware:
;   $D010 = KBD
;   $D011 = KBDCR
;
; Assemblieren:
;   ca65 -o reverse.o reverse.s
;   ld65 -C apple1.cfg -o reverse.bin reverse.o
;
; Laden des Binärabbilds nach $0300 und Start mit:
;   0300R
; ============================================================

.setcpu "6502"

ECHO    = $FFEF
MONITOR = $FF00
KBD     = $D010
KBDCR   = $D011
CR      = $0D

; ------------------------------------------------------------
; Zero Page
; ------------------------------------------------------------

.segment "ZEROPAGE"

ptr:        .res 2
i:          .res 1
j:          .res 1
n:          .res 1
tmp:        .res 1
digit:      .res 1
inputval:   .res 1
input_bad:  .res 1
digits_seen:.res 1
moves:      .res 1
seed:       .res 1
hundreds:   .res 1
tens:       .res 1

; ------------------------------------------------------------
; BSS
; ------------------------------------------------------------

.segment "BSS"

board:      .res 9
backup:     .res 9

; ------------------------------------------------------------
; CODE
; ------------------------------------------------------------
.org $300 ; <- manually inserted P.Sieg
.segment "CODE"

.export start

.proc start
    cld
    ldx #$FF
    txs

    lda #$A7
    sta seed

    lda #0
    sta moves

    lda #<title
    ldx #>title
    jsr print_string
    jsr newline

; ============================================================
; BASIC 100-180: Zufallspermutation erstellen
; ============================================================

new_game:
    ldx #0
    lda #0

clear_board:
    sta board,x
    inx
    cpx #9
    bne clear_board

    lda #1
    sta i

place_number:
    jsr random_0_19
    clc
    adc #1
    sta j

    ; Zufallszahl groesser als 9?
    cmp #10
    bcs place_number

    ; Index von 1..9 auf 0..8 umstellen
    sec
    sbc #1
    tax

    ; Position bereits belegt?
    lda board,x
    bne place_number

    ; Zahl eintragen
    lda i
    sta board,x

    inc i
    lda i
    cmp #10
    bne place_number

; ============================================================
; BASIC 190: Spielfeld ausgeben
; ============================================================

show_board:
    jsr print_board

; ============================================================
; BASIC 200: Umkehrlaenge abfragen
; ============================================================

ask_number:
    lda #<question
    ldx #>question
    jsr print_string

    jsr read_number
    sta n

    lda input_bad
    bne ask_number

; BASIC 210-220: N darf hoechstens 9 sein
    lda n
    cmp #10
    bcc check_minimum

    lda #<too_many
    ldx #>too_many
    jsr print_string
    jmp ask_number

; BASIC 230-241: N muss groesser als 1 sein
check_minimum:
    lda n
    cmp #2
    bcs reverse_prefix

    lda #<too_small
    ldx #>too_small
    jsr print_string
    jmp ask_number

; ============================================================
; BASIC 250: Zugzaehler erhoehen
; ============================================================

reverse_prefix:
    inc moves

; BASIC 260: B(I) = A(I), I=1..9
    ldx #0

copy_board:
    lda board,x
    sta backup,x
    inx
    cpx #9
    bne copy_board

; ============================================================
; BASIC 270:
; FOR I=1 TO N
;   J=N+1-I
;   A(J)=B(I)
; NEXT I
;
; Nullbasierte Indizes:
; board[N-1-i] = backup[i]
; ============================================================

    lda #0
    sta i

reverse_loop:
    lda n
    sec
    sbc #1
    sec
    sbc i
    tax

    ldy i
    lda backup,y
    sta board,x

    inc i
    lda i
    cmp n
    bcc reverse_loop

; ============================================================
; BASIC 280-310: Sortierpruefung
;
; Wenn board[i] > board[i+1], ist das Feld unsortiert.
; In diesem Fall zur Ausgabe zurueckkehren, ohne neu zu mischen.
; ============================================================

    ldx #0

check_order:
    lda board,x
    cmp board+1,x

    ; Links kleiner als rechts
    bcc next_pair

    ; Gleich
    beq next_pair

    ; Links groesser: noch nicht gewonnen
    jmp show_board

next_pair:
    inx
    cpx #8
    bne check_order

; ============================================================
; BASIC 320-330: Sieg
; ============================================================

    lda #<won_text
    ldx #>won_text
    jsr print_string

    lda moves
    jsr print_decimal

    lda #<moves_text
    ldx #>moves_text
    jsr print_string

    ; Zum Woz-Monitor zurueckkehren
    jmp MONITOR

.endproc

; ============================================================
; Zufallszahl 0..19
;
; 8-Bit-LFSR als Ersatz fuer BASIC-RND.
; Nicht identisch mit der BASIC-Zufallsfolge.
; ============================================================

.proc random_0_19
    lda seed
    asl a
    bcc random_no_xor
    eor #$1D

random_no_xor:
    bne random_save
    lda #$A7

random_save:
    sta seed

    and #$1F
    cmp #20
    bcc random_done

    sec
    sbc #20

random_done:
    rts
.endproc

; ============================================================
; Nullterminierten String ausgeben
;
; Eingang: A = Low-Byte, X = High-Byte
; ============================================================

.proc print_string
    sta ptr
    stx ptr+1

    ldy #0

print_string_loop:
    lda (ptr),y
    beq print_string_done

    jsr ECHO
    iny
    bne print_string_loop

print_string_done:
    rts
.endproc

; ============================================================
; Wagenruecklauf
; ============================================================

.proc newline
    lda #CR
    jsr ECHO
    rts
.endproc

; ============================================================
; Spielfeld ausgeben
; ============================================================

.proc print_board
    lda #<numbers
    ldx #>numbers
    jsr print_string
    jsr newline

    lda #<separator
    ldx #>separator
    jsr print_string
    jsr newline

    lda #'('
    jsr ECHO

    ldx #0

print_board_loop:
    lda board,x
    jsr print_decimal

    inx
    cpx #9
    beq print_board_end

    lda #' '
    jsr ECHO
    jmp print_board_loop

print_board_end:
    lda #')'
    jsr ECHO
    jsr newline

    lda #<separator2
    ldx #>separator2
    jsr print_string
    jsr newline
    jsr newline
    rts
.endproc

; ============================================================
; Dezimalzahl 0..255 ausgeben
; Ohne fuehrende Nullen.
; ============================================================

.proc print_decimal
    sta tmp

    lda #0
    sta hundreds
    sta tens

decimal_hundreds_loop:
    lda tmp
    cmp #100
    bcc decimal_tens_start

    sec
    sbc #100
    sta tmp

    inc hundreds
    jmp decimal_hundreds_loop

decimal_tens_start:
    lda #0
    sta tens

decimal_tens_loop:
    lda tmp
    cmp #10
    bcc decimal_output

    sec
    sbc #10
    sta tmp

    inc tens
    jmp decimal_tens_loop

decimal_output:
    ; Hunderter ausgeben, falls vorhanden
    lda hundreds
    beq decimal_check_tens

    clc
    adc #'0'
    jsr ECHO

    ; Nach Hundertern immer die Zehnerstelle ausgeben
    lda tens
    clc
    adc #'0'
    jsr ECHO
    jmp decimal_ones

decimal_check_tens:
    lda tens
    beq decimal_ones

    clc
    adc #'0'
    jsr ECHO

decimal_ones:
    lda tmp
    clc
    adc #'0'
    jsr ECHO
    rts
.endproc

; ============================================================
; Tastatureingabe einer Dezimalzahl
;
; Wartet auf RETURN.
; Ignoriert Leerzeichen.
; Nichtnumerische Zeichen machen die Eingabe ungueltig.
; Werte ueber 255 werden auf 255 begrenzt.
;
; Rueckgabe:
;   A         = Eingabewert
;   input_bad = 0 bei gueltiger Eingabe, sonst 1
; ============================================================

.proc read_number
    lda #0
    sta inputval
    sta input_bad
    sta digits_seen

read_number_char:
    ; Auf Tastendruck warten: Bit 7 von KBDCR
    lda KBDCR
    bpl read_number_char

    ; Apple-I-Tastatur lesen, hohes Bit entfernen
    lda KBD
    and #$7F

    ; RETURN?
    cmp #CR
    beq read_number_done

    ; Zeichen echoen
    jsr ECHO

    ; Leerzeichen ignorieren
    cmp #' '
    beq read_number_char

    ; Nur ASCII-Ziffern akzeptieren
    cmp #'0'
    bcc read_number_bad_char

    cmp #'9'+1
    bcs read_number_bad_char

    sec
    sbc #'0'
    sta digit
    inc digits_seen

    ; Pruefen, ob inputval*10+digit > 255 wird.
    ;
    ; inputval >= 26 -> immer groesser als 255
    ; inputval == 25 und digit >= 6 -> groesser als 255
    lda inputval
    cmp #26
    bcs read_number_saturate

    cmp #25
    bne read_number_multiply

    lda digit
    cmp #6
    bcs read_number_saturate

read_number_multiply:
    ; inputval * 10 = inputval * 8 + inputval * 2
    lda inputval
    asl a
    sta tmp                 ; 2*x

    asl a                   ; 4*x
    asl a                   ; 8*x

    clc
    adc tmp                 ; 10*x
    clc
    adc digit
    sta inputval

    jmp read_number_char

read_number_saturate:
    lda #255
    sta inputval
    jmp read_number_char

read_number_bad_char:
    lda #1
    sta input_bad
    jmp read_number_char

read_number_done:
    jsr newline

    ; Mindestens eine Ziffer erforderlich
    lda digits_seen
    bne read_number_return

    lda #1
    sta input_bad

read_number_return:
    lda inputval
    rts
.endproc

; ============================================================
; Texte
; ============================================================

.segment "RODATA"

title:
    .byte "R E V E R S E",0

numbers:
    .byte " 1 2 3 4 5 6 7 8 9",0

separator:
    .byte " -----------------",0

separator2:
    .byte "------------------",0

question:
    .byte "HOW MANY SHALL I REVERSE? ",0

too_many:
    .byte "OOPS! TOO MANY- I CAN REVERSE AT MOST 9",CR,0

too_small:
    .byte "OOPS ! TOO SMALL; YOU MUST REVERSE SOMETHING!",CR,0

won_text:
    .byte "YOU WON IN ",0

moves_text:
    .byte " MOVES",CR,0

