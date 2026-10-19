; ============================================================
; Arecibo Message - Apple I - ca65
; Startadresse: $0300
; Ausgabe: 1679 Bits, 23 Zeichen pro Zeile
; Benötigt: message.bin (210 Bytes)
; ============================================================

.setcpu "6502"

.segment "ZEROPAGE"

data_ptr:       .res 2
bits_left:      .res 2
current_byte:   .res 1
bits_in_byte:   .res 1
line_count:     .res 1

.segment "CODE"

.org $0300

start:
        CLD

        ; Zeiger auf die Nachricht
        LDA #<arecibo_data
        STA data_ptr
        LDA #>arecibo_data
        STA data_ptr+1

        ; 1679 Bits = $068F
        LDA #$8F
        STA bits_left
        LDA #$06
        STA bits_left+1

        LDA #$00
        STA bits_in_byte
        STA line_count

next_bit:
        ; Sind alle Bits ausgegeben?
        LDA bits_left
        ORA bits_left+1
        BEQ finished

        ; Bei Bedarf neues Byte laden
        LDA bits_in_byte
        BNE have_byte

load_byte:
        LDY #$00
        LDA (data_ptr),Y
        STA current_byte

        INC data_ptr
        BNE pointer_ok
        INC data_ptr+1

pointer_ok:
        LDA #$08
        STA bits_in_byte

have_byte:
        ; MSB zuerst
        ASL current_byte
        BCS print_one

print_zero:
        LDA #' ' ;#$30
        JSR $FFEF
        JMP bit_done

print_one:
        LDA #'#' ;#$31
        JSR $FFEF

bit_done:
        DEC bits_in_byte

        ; 16-Bit-Bitzaehler dekrementieren
        LDA bits_left
        BNE dec_low
        DEC bits_left+1

dec_low:
        DEC bits_left

        ; Zeilenumbruch nach 23 Bits
        INC line_count
        LDA line_count
        CMP #23
        BNE next_bit

        LDA #$0D
        JSR $FFEF

        LDA #$00
        STA line_count
        JMP next_bit

finished:
        JMP start ;RTS

; ------------------------------------------------------------
; Nachrichtendaten
; ------------------------------------------------------------

arecibo_data:
        .incbin "message.bin"


