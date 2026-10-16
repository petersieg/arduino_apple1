; HELLO WORLD - Apple-1 text via WozMon ECHO ($FFEF).
ECHO = $FFEF
.segment "CODE"
.org $300
start:
    ldx #0
loop:
    lda msg,x
    beq done
    ora #$80
    jsr ECHO
    inx
    bne loop
done:
    jmp done
msg:
    .byte $0D, "HELLO WORLD", $0D, $00
end:

