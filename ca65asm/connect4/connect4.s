; ChatGPT 2020-10-20 P.Sieg
; ============================================================
; CONNECT4.S - 4 GEWINNT fuer Apple-1
; CPU: MOS 6502
; Assembler: ca65
; Startadresse: $0300
;
; Spieler:   X
; Computer:  O
; Spielfeld: 7 Spalten x 6 Reihen
; Eingabe:   Tasten 1 bis 7
;
; Apple-1:
;   KBD   = $D010
;   KBDCR = $D011
;   DSP   = $D012
; ============================================================

.setcpu "6502"

KBD   = $D010
KBDCR = $D011
DSP   = $D012

.segment "ZEROPAGE"
strptr:     .res 2

.segment "CODE"
.org $300

start:
        JSR new_game

main_loop:
        JSR print_board

        LDA #<msg_turn
        STA strptr
        LDA #>msg_turn
        STA strptr+1
        JSR print_string

read_move:
		JSR get_key

        ; Nur Zeichen 1 bis 7 akzeptieren
        CMP #'1'
        BCC read_move
        CMP #'8'
        BCS read_move

        ; ASCII in Spaltenindex 0 bis 6 umwandeln
        SEC
        SBC #'1'
        STA colsel

        ; Freies Feld in dieser Spalte suchen
        JSR find_slot
        BCS column_full

        ; Spielerstein setzen
        LDA #'X'
        STA board,Y

        JSR check_player_win
        BNE player_wins

        JSR board_full
        BNE draw_game

        JSR computer_move

        JSR check_computer_win
        BNE computer_wins

        JSR board_full
        BNE draw_game

        JMP main_loop

column_full:
        LDA #<msg_full
        STA strptr
        LDA #>msg_full
        STA strptr+1
        JSR print_string
        JMP read_move

player_wins:
        JSR print_board
        LDA #<msg_player_win
        STA strptr
        LDA #>msg_player_win
        STA strptr+1
        JSR print_string
        JMP game_over

computer_wins:
        JSR print_board
        LDA #<msg_computer_win
        STA strptr
        LDA #>msg_computer_win
        STA strptr+1
        JSR print_string
        JMP game_over

draw_game:
        JSR print_board
        LDA #<msg_draw
        STA strptr
        LDA #>msg_draw
        STA strptr+1
        JSR print_string

game_over:
        LDA #<msg_again
        STA strptr
        LDA #>msg_again
        STA strptr+1
        JSR print_string

again_key:
        JSR get_key
        AND #$DF
        CMP #'Y'
	BNE again_no
        JMP start
again_no:
        CMP #'N'
        BEQ stop_game
        JMP again_key

stop_game:
        JMP $FF1F
        
; ------------------------------------------------------------
; Neues Spiel: alle 42 Felder leeren
; ------------------------------------------------------------

new_game:
        LDX #41
        LDA #' '
clear_loop:
        STA board,X
        DEX
        BPL clear_loop
        RTS

get_key:
    	; Auf Tastendruck warten: Bit 7 von KBDCR
    	lda KBDCR
    	bpl get_key

    	; Apple-I-Tastatur lesen, hohes Bit entfernen
    	lda KBD
    	and #$7F
		;RTS - runs through put_char by intention!
		
; ------------------------------------------------------------
; Zeichen ausgeben
; Eingang A = ASCII
; ------------------------------------------------------------

put_char:
        PHA
display_wait:
        BIT DSP
        BMI display_wait
        PLA
        STA DSP
        RTS

newline:
        LDA #$0D
        JSR put_char
        RTS

print_string:
        LDY #0
print_string_loop:
        LDA (strptr),Y
        BEQ print_string_done
        JSR put_char
        INY
        BNE print_string_loop
print_string_done:
        RTS

; ------------------------------------------------------------
; Spielfeld anzeigen
; Zeile 0 ist oben, Zeile 5 ist unten.
; ------------------------------------------------------------

print_board:
        JSR newline

        LDA #<msg_header
        STA strptr
        LDA #>msg_header
        STA strptr+1
        JSR print_string

        LDA #0
        STA row

print_row:
        LDA #0
        STA col

print_col:
        LDX row
        LDA row_offsets,X
        CLC
        ADC col
        TAY

        LDA board,Y
        JSR put_char

        INC col
        LDA col
        CMP #7
        BEQ end_print_row

        LDA #'|'
        JSR put_char
        JMP print_col

end_print_row:
        JSR newline

        LDX row
        CPX #5
        BEQ print_board_done

        LDA #'-'
        JSR put_char
        LDA #'+'
        JSR put_char
        LDA #'-'
        JSR put_char
        LDA #'+'
        JSR put_char
        LDA #'-'
        JSR put_char
        LDA #'+'
        JSR put_char
        LDA #'-'
        JSR put_char
        LDA #'+'
        JSR put_char
        LDA #'-'
        JSR put_char
        LDA #'+'
        JSR put_char
        LDA #'-'
        JSR put_char
        LDA #'+'
        JSR put_char
        LDA #'-'
        JSR put_char
        JSR newline

        INC row
        JMP print_row

print_board_done:
        LDA #<msg_columns
        STA strptr
        LDA #>msg_columns
        STA strptr+1
        JSR print_string
        RTS

; ------------------------------------------------------------
; Freies Feld in einer Spalte finden
;
; Eingang: colsel = 0..6
; Ausgang: Y = Feldindex, Carry=0 bei Erfolg
;          Carry=1, wenn die Spalte voll ist
; ------------------------------------------------------------

find_slot:
        LDX #5
find_slot_loop:
        LDA row_offsets,X
        CLC
        ADC colsel
        TAY

        LDA board,Y
        CMP #' '
        BEQ slot_found

        DEX
        BPL find_slot_loop

        SEC
        RTS

slot_found:
        CLC
        RTS

; ------------------------------------------------------------
; Computerzug
;
; 1. Eigenen Gewinnzug suchen
; 2. Spieler-Gewinnzug blockieren
; 3. Mitte, dann Ecken, dann Seiten
; ------------------------------------------------------------

computer_move:
        LDA #0
        STA colsel

computer_try_win:
        JSR find_slot
        BCS computer_win_next

        STY slot

        LDA #'O'
        STA board,Y
        LDA #'O'
        JSR check_win

        BNE computer_keep_win

        LDY slot
        LDA #' '
        STA board,Y

computer_win_next:
        INC colsel
        LDA colsel
        CMP #7
        BNE computer_try_win

        LDA #0
        STA colsel

computer_try_block:
        JSR find_slot
        BCS computer_block_next

        STY slot

        LDA #'X'
        STA board,Y
        LDA #'X'
        JSR check_win

        BNE computer_block_found

        LDY slot
        LDA #' '
        STA board,Y

computer_block_next:
        INC colsel
        LDA colsel
        CMP #7
        BNE computer_try_block

        LDX #0

; ------------------------------------------------------------
; Computer-Fallback
; Mitte bevorzugen, danach weitere Spalten versuchen.
; moveidx bleibt erhalten, da find_slot X veraendert.
; ------------------------------------------------------------

computer_fallback:
        LDA #0
        STA moveidx

computer_fallback_loop:
        LDX moveidx
        LDA move_order,X
        STA colsel

        JSR find_slot
        BCC computer_place

        INC moveidx
        LDA moveidx
        CMP #7
        BNE computer_fallback_loop

        RTS

computer_keep_win:
        RTS

computer_block_found:
        LDY slot
        LDA #'O'
        STA board,Y
        RTS

computer_place:
        LDA #'O'
        STA board,Y
        RTS

; ------------------------------------------------------------
; Gewinnpruefung
;
; Eingang: A = 'X' oder 'O'
; Ausgang: A = 1 bei vier in einer Reihe, sonst 0
;
; Es werden vier Richtungen geprueft:
; horizontal, vertikal, diagonal rechts, diagonal links.
; ------------------------------------------------------------

check_player_win:
        LDA #'X'
        JMP check_win

check_computer_win:
        LDA #'O'

check_win:
        STA mark
        LDA #0
        STA row

win_row_loop:
        LDA #0
        STA col

win_col_loop:
        LDX row
        LDA row_offsets,X
        CLC
        ADC col
        TAY

        LDA board,Y
        CMP mark
        BEQ win_check_directions
        JMP win_next_cell

win_check_directions:
        ; Horizontal: col muss <= 3 sein
        LDA col
        CMP #4
        BCS win_skip_horizontal

        JSR set_line_base
        LDA #1
        STA line_step
        JSR test_line
        BNE win_yes

win_skip_horizontal:
        ; Vertikal: row muss <= 2 sein
        LDA row
        CMP #3
        BCS win_skip_vertical

        JSR set_line_base
        LDA #7
        STA line_step
        JSR test_line
        BNE win_yes

win_skip_vertical:
        ; Diagonal nach rechts unten
        LDA row
        CMP #3
        BCS win_skip_diag_right

        LDA col
        CMP #4
        BCS win_skip_diag_right

        JSR set_line_base
        LDA #8
        STA line_step
        JSR test_line
        BNE win_yes

win_skip_diag_right:
        ; Diagonal nach links unten
        LDA row
        CMP #3
        BCS win_skip_diag_left

        LDA col
        CMP #3
        BCC win_skip_diag_left

        JSR set_line_base
        LDA #6
        STA line_step
        JSR test_line
        BNE win_yes

win_skip_diag_left:

win_next_cell:
        INC col
        LDA col
        CMP #7
        BEQ win_next_row
        JMP win_col_loop

win_next_row:
        INC row
        LDA row
        CMP #6
        BEQ win_no

        JMP win_row_loop

win_yes:
        LDA #1
        RTS

win_no:
        LDA #0
        RTS

; Basisindex der aktuellen Zeile/Spalte berechnen
set_line_base:
        LDX row
        LDA row_offsets,X
        CLC
        ADC col
        STA line_base
        RTS

; Vier Felder mit mark vergleichen.
; line_base = Startindex, line_step = Abstand.
; Ergebnis A = 1 bei Treffer, sonst 0.
test_line:
        LDY line_base
        LDX #4

test_line_loop:
        LDA board,Y
        CMP mark
        BNE test_line_no

        DEX
        BEQ test_line_yes

        TYA
        CLC
        ADC line_step
        TAY
        JMP test_line_loop

test_line_yes:
        LDA #1
        RTS

test_line_no:
        LDA #0
        RTS

; ------------------------------------------------------------
; Pruefen, ob alle 42 Felder belegt sind
; A = 1 wenn voll, sonst 0
; ------------------------------------------------------------

board_full:
        LDX #0

board_full_loop:
        LDA board,X
        CMP #' '
        BEQ board_not_full

        INX
        CPX #42
        BNE board_full_loop

        LDA #1
        RTS

board_not_full:
        LDA #0
        RTS

; ------------------------------------------------------------
; Meldungen und Konstanten
; ------------------------------------------------------------

.segment "RODATA"

msg_header:
        .byte "1|2|3|4|5|6|7",$0D,0

msg_columns:
        .byte "SPALTE 1-7",$0D,0

msg_turn:
        .byte "DEIN ZUG (1-7): ",0

msg_full:
        .byte $0D,"SPALTE VOLL!",$0D,0

msg_player_win:
        .byte $0D,"DU HAST GEWONNEN!",$0D,0

msg_computer_win:
        .byte $0D,"COMPUTER GEWINNT!",$0D,0

msg_draw:
        .byte $0D,"UNENTSCHIEDEN!",$0D,0

msg_again:
        .byte "NEUES SPIEL? Y/N ",0

row_offsets:
        .byte 0,7,14,21,28,35

; Reihenfolge fuer den Computer:
; Mitte, links/rechts davon, dann aussen.
move_order:
        .byte 3,2,4,1,5,0,6

.segment "BSS"

board:
        .res 42

row:
        .res 1

col:
        .res 1

colsel:
        .res 1

slot:
        .res 1

mark:
        .res 1

line_base:
        .res 1

line_step:
        .res 1

moveidx:
        .res 1
        

