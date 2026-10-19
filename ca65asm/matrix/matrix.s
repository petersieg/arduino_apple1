; ChatGPT 2026-10-19 P.Sieg

;40 Spalten mit eigenen Geschwindigkeiten von 1 bis 4 Animationsschritten.
;Zufällige hexadezimale Zeichen von 0 bis F.
;Weiße Kopfzeichen und grüne Spuren.
;Unterschiedliche Spurlängen zwischen 4 und 19 Zeichen.
;Gezieltes Löschen der Spuren und Positionieren des Cursors, 
;ohne jedes Bild komplett neu zu zeichnen.

; ============================================================
; APPLE-1 MATRIX RAIN -- ca65
; CPU: 6502
; Terminal: VT100 / ANSI, 40 columns x 24 rows
; Load address: $0300
;
; 40 independent columns, individual speeds and trail lengths.
; Output: Apple-1 PIA at $D012 / status at $D012
; ============================================================

.setcpu "6502"

PIA_DSP = $D012

.segment "CODE"
.org $300

start:
        CLD
        LDX #$FF
        TXS

        ; Clear screen, cursor home
        JSR clear_screen
        JSR color_green

        ; Initialize PRNG
        LDA #$A7
        STA rng

        ; Initialize all 40 columns
        JSR color_white
        LDX #$00

init_loop:
        STX col_idx

        LDA #$00
        STA head,X

        ; Trail length: 4..19
        JSR random_byte
        AND #$0F
        CLC
        ADC #$04
        STA length,X

        ; Speed: 1..4 frames per step
        JSR random_byte
        AND #$03
        CLC
        ADC #$01
        STA speed,X
        STA timer,X

        ; Draw initial white head at row 0
        LDA #$00
        STA rowval
        LDA col_idx
        STA colval
        JSR print_at

        JSR random_char
        JSR putc

        LDX col_idx
        INX
        CPX #40
        BNE init_loop

; ------------------------------------------------------------
; Main animation loop
; ------------------------------------------------------------

main_loop:
        LDX #$00

column_loop:
        STX col_idx

        ; Independent speed countdown
        DEC timer,X
        BEQ continue_here
        JMP next_column

continue_here:
        LDA speed,X
        STA timer,X

        ; Has this stream reached the bottom?
        LDA head,X
        CMP #24
        BCS reset_column

        ; Turn old white head into green trail
        STA rowval
        LDA col_idx
        STA colval
        JSR print_at

        JSR color_green
        JSR random_char
        JSR putc

        ; Advance head
        LDX col_idx
        LDA head,X
        CLC
        ADC #$01
        STA newrow
        STA head,X

        ; Erase tail at newrow - length
        LDX col_idx
        LDA newrow
        SEC
        SBC length,X
        BCC no_tail

        STA rowval
        STA tailrow
        LDA col_idx
        STA colval
        JSR print_at

        LDA #' '
        JSR putc

no_tail:
        ; Draw new white head if still on screen
        LDA newrow
        CMP #24
        BCS next_column

        STA rowval
        LDA col_idx
        STA colval
        JSR print_at

        JSR color_white
        JSR random_char
        JSR putc

        JMP next_column

; ------------------------------------------------------------
; Reset a stream after it reaches the bottom.
; Clear only this column and restart at row zero.
; ------------------------------------------------------------

reset_column:
        JSR color_green

        LDA #$00
        STA clearrow

clear_column_loop:
        LDA clearrow
        STA rowval
        LDA col_idx
        STA colval
        JSR print_at

        LDA #' '
        JSR putc

        INC clearrow
        LDA clearrow
        CMP #24
        BNE clear_column_loop

        ; Restart at row zero
        LDX col_idx
        LDA #$00
        STA head,X

        LDA #$00
        STA rowval
        LDA col_idx
        STA colval
        JSR print_at

        JSR color_white
        JSR random_char
        JSR putc

next_column:
        LDX col_idx
        INX
        CPX #40
        BEQ continue_column
        JMP column_loop

continue_column:
        ; Animation pacing
        JSR delay
        JMP main_loop

; ============================================================
; Apple-1 character output
;
; First remove bit 7 from the ASCII character.
; Then set bit 7 for the Apple-1 PIA output strobe.
; The actual character data is in bits 0..6.
; ============================================================

putc:
        AND #$7F

        PHA
@wait:
        BIT PIA_DSP
        BMI @wait

        PLA
        AND #$7F
        ORA #$80
        STA PIA_DSP
        RTS

; ============================================================
; VT100 cursor positioning
; rowval, colval are zero-based (0..23, 0..39)
; Emits ESC [ row ; column H
; ============================================================

print_at:
        LDA #$1B
        JSR putc
        LDA #'['
        JSR putc

        LDA rowval
        CLC
        ADC #$01
        JSR print_decimal

        LDA #';'
        JSR putc

        LDA colval
        CLC
        ADC #$01
        JSR print_decimal

        LDA #'H'
        JSR putc
        RTS

; Print unsigned A as decimal (1..40)
print_decimal:
        STA decval
        LDA #$00
        STA tens

decimal_loop:
        LDA decval
        CMP #10
        BCC decimal_done

        SEC
        SBC #10
        STA decval
        INC tens
        JMP decimal_loop

decimal_done:
        LDA tens
        BEQ decimal_ones

        CLC
        ADC #'0'
        JSR putc

decimal_ones:
        LDA decval
        CLC
        ADC #'0'
        JSR putc
        RTS

; ============================================================
; VT100 colors
; ============================================================

clear_screen:
        LDA #$1B
        JSR putc
        LDA #'['
        JSR putc
        LDA #'2'
        JSR putc
        LDA #'J'
        JSR putc

        LDA #$1B
        JSR putc
        LDA #'['
        JSR putc
        LDA #'H'
        JSR putc
        RTS

color_green:
        LDA #$1B
        JSR putc
        LDA #'['
        JSR putc
        LDA #'3'
        JSR putc
        LDA #'2'
        JSR putc
        LDA #'m'
        JSR putc
        RTS

color_white:
        LDA #$1B
        JSR putc
        LDA #'['
        JSR putc
        LDA #'1'
        JSR putc
        LDA #';'
        JSR putc
        LDA #'3'
        JSR putc
        LDA #'7'
        JSR putc
        LDA #'m'
        JSR putc
        RTS

; ============================================================
; Random printable hexadecimal character
; Returns ASCII in A
; ============================================================

random_char:
        JSR random_byte
        AND #$0F
        TAX
        LDA charset,X
        RTS

; 8-bit LFSR pseudo-random generator
random_byte:
        LDA rng
        ASL A
        BCC random_no_xor
        EOR #$1D

random_no_xor:
        BNE random_ok
        LDA #$A7

random_ok:
        STA rng
        RTS

; ============================================================
; Timing delay (approximate; depends on CPU clock)
; ============================================================

delay:
        LDY #$20
delay_outer:
        LDX #$FF
delay_inner:
        DEX
        BNE delay_inner
        DEY
        BNE delay_outer
        RTS

; ============================================================
; Variables and tables
; ============================================================

charset:
        .byte "0123456789ABCDEF"

rng:       .byte $A7
col_idx:   .byte $00
rowval:    .byte $00
colval:    .byte $00
newrow:    .byte $00
tailrow:   .byte $00
clearrow:  .byte $00
decval:    .byte $00
tens:      .byte $00

head:      .res 40
length:    .res 40
speed:     .res 40
timer:     .res 40

