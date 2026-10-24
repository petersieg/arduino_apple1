; ChatGPT 2026-10-24 P.Sieg
; Apple I 4x4 Tic-Tac-Toe
; ca65 / ld65
; Player: X ($10), computer: # ($11), empty cells display 0..F.
; Input: hexadecimal cell number (0-9, A-F).
;
; Assemble/link with: make
; Result: 4xttt.bin, linked to run at $1000.
; The raw binary must be loaded into memory at $1000 by your emulator
; or converted to the format required by your Apple I loader.
; Needs more than 8k Ram!

.setcpu "6502"
.export start

KBD     = $D010
KBDCR   = $D011
ECHO    = $FFEF

XMARK   = $58             ; 'X'
CMARK   = $23             ; '#'
SPACE   = $20
CR      = $0D

.segment "ZEROPAGE"
target:     .res 1
lineidx:    .res 1
idx:        .res 1
tmp:        .res 1

.segment "BSS"
board:      .res 16

.segment "RODATA"
hexdigits:
    .byte "0123456789ABCDEF"

; Ten possible winning lines, four cells per line.
lines:
    .byte  0, 1, 2, 3
    .byte  4, 5, 6, 7
    .byte  8, 9,10,11
    .byte 12,13,14,15
    .byte  0, 4, 8,12
    .byte  1, 5, 9,13
    .byte  2, 6,10,14
    .byte  3, 7,11,15
    .byte  0, 5,10,15
    .byte  3, 6, 9,12

; Computer fallback preference: central four, corners, then other cells.
preference:
    .byte 5, 6, 9,10, 0,3,12,15, 1,2,4,7,8,11,13,14

.segment "CODE"

start:
    jsr initboard

mainloop:
    jsr drawboard
    lda #'X'
    jsr putchar
    lda #'>'
    jsr putchar

readmove:
    jsr getchar
    ; Echo the typed character.
    jsr putchar
    jsr parsehex
    bcs badmove

    tax
    lda board,x
    cmp #16
    bcs badmove

    ; Player move.
    lda #16
    sta board,x
    lda #16
    sta target
    jsr checkwin
    bcs playerwin

    jsr hasempty
    bcc drawgame

    ; Computer first looks for a winning move, then blocks X.
    lda #17
    sta target
    jsr findtactical
    bcs computerplace

    lda #16
    sta target
    jsr findtactical
    bcs computerplace

    jsr choosefallback
    ; choosefallback returns chosen cell in idx.
computerplace:
    ldx idx
    lda #17
    sta board,x

    lda #17
    sta target
    jsr checkwin
    bcs computerwin

    jsr hasempty
    bcc drawgame
    jmp mainloop

badmove:
    jsr newline
    lda #'?'
    jsr putchar
    jsr newline
    jmp mainloop

playerwin:
    jsr drawboard
    lda #'X'
    jsr putchar
    lda #' '
    jsr putchar
    lda #'W'
    jsr putchar
    lda #'I'
    jsr putchar
    lda #'N'
    jsr putchar
    jsr newline
    jmp gameover

computerwin:
    jsr drawboard
    lda #'#'
    jsr putchar
    lda #' '
    jsr putchar
    lda #'W'
    jsr putchar
    lda #'I'
    jsr putchar
    lda #'N'
    jsr putchar
    jsr newline
    jmp gameover

drawgame:
    jsr drawboard
    lda #'D'
    jsr putchar
    lda #'R'
    jsr putchar
    lda #'A'
    jsr putchar
    lda #'W'
    jsr putchar
    jsr newline

gameover:
    JMP $FF1F

; ---- Apple I I/O ------------------------------------------------

putchar:
    ; Woz Monitor ECHO expects an ASCII character in A.
    ; Preserve A because callers often need the character afterwards
    ; (notably before parsehex).
    pha
    jsr ECHO
    pla
    rts

newline:
    lda #CR
    jsr putchar
    rts

; Wait for keyboard strobe, then return ASCII with bit 7 cleared.
getchar:
@wait:
    lda KBDCR
    bpl @wait
    lda KBD
    and #$7F
    rts

; ---- Board ------------------------------------------------------

initboard:
    ldx #0
@loop:
    txa
    sta board,x
    inx
    cpx #16
    bne @loop
    rts

drawboard:
    jsr newline
    ldx #0
@loop:
    lda board,x
    cmp #16
    bcs @occupied
    tay
    lda hexdigits,y
    jmp @print

@occupied:
    lda board,x
    cmp #16
    bne @computer
    lda #XMARK
    jmp @print
@computer:
    lda #CMARK

@print:
    jsr putchar
    lda #SPACE
    jsr putchar
    inx
    txa
    and #3
    bne @notrowend
    jsr newline
@notrowend:
    cpx #16
    bne @loop
    jsr newline
    rts

; Convert ASCII hex digit in A to 0..15.
; Carry clear on success, set on invalid input.
parsehex:
    cmp #'0'
    bcc @bad
    cmp #'9'+1
    bcc @digit
    and #$DF             ; uppercase ASCII
    cmp #'A'
    bcc @bad
    cmp #'F'+1
    bcs @bad
    sec
    sbc #'A'-10
    clc
    rts
@digit:
    sec
    sbc #'0'
    clc
    rts
@bad:
    sec
    rts

; Check whether four cells in a row equal target.
; Carry set if a winning line exists.
checkwin:
    lda #0
    sta lineidx
@nextline:
    lda lineidx
    asl
    asl
    tay

    lda lines,y
    tax
    lda board,x
    cmp target
    bne @next

    iny
    lda lines,y
    tax
    lda board,x
    cmp target
    bne @next

    iny
    lda lines,y
    tax
    lda board,x
    cmp target
    bne @next

    iny
    lda lines,y
    tax
    lda board,x
    cmp target
    bne @next

    sec
    rts
@next:
    inc lineidx
    lda lineidx
    cmp #10
    bne @nextline
    clc
    rts

; Find a move for TARGET that immediately completes a four-in-a-row.
; On success, returns candidate index in idx and Carry set.
; On failure, Carry clear. The board is restored after testing.
findtactical:
    ldx #0
@scan:
    lda board,x
    cmp #16
    bcs @used
    stx idx
    lda target
    sta board,x
    jsr checkwin
    bcc @restore_no
    ldx idx
    txa
    sta board,x           ; restore empty-cell value (its index)
    sec
    rts
@restore_no:
    ldx idx
    txa
    sta board,x
    ldx idx
@used:
    inx
    cpx #16
    bne @scan
    clc
    rts

; Choose first available cell in preference order.
choosefallback:
    ldx #0
@scan:
    lda preference,x
    tay
    lda board,y
    cmp #16
    bcc @found
    inx
    cpx #16
    bne @scan
    ; Should not occur because caller checks for an empty cell.
    lda #0
    sta idx
    rts
@found:
    sty idx
    rts

; Carry set if at least one empty cell remains.
hasempty:
    ldx #0
@scan:
    lda board,x
    cmp #16
    bcc @yes
    inx
    cpx #16
    bne @scan
    clc
    rts
@yes:
    sec
    rts
