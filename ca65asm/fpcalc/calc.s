; ChatGPT 2026-10-22 P.Sieg
; Apple-1 Wozniak/Rankin floating-point calculator
; ca65, NMOS 6502, 8 KiB RAM ($0000-$1FFF)
; Program entry: $1000. Original math code is in wozfp.s; only
; assembler/linker directives were changed to place it at $1D00-$1FFF.
; 
; wozfp.s from: https://raw.githubusercontent.com/jefftranter/6502/master/asm/wozfp/wozfp.s
;           JULY 5, 1976
;     BASIC FLOATING POINT ROUTINES
;       FOR 6502 MICROPROCESSOR
;       BY R. RANKIN AND S. WOZNIAK
; Die rechtliche und praktische Situation gestaltet sich wie folgt:
; Urheberrecht & Status: Der Programmcode wurde ursprünglich im August 1976 im Dr. Dobb’s Journal 
; veröffentlicht und später im Handbuch des Apple II (dem sogenannten „Red Book“, 1978) abgedruckt. 
; Rechtlich gesehen handelt es sich dabei um urheberrechtlich geschützten Code (oft Apple zugeschrieben).
; Praxis in der Retro-Community: Da der Code vor Jahrzehnten als gedrucktes Listing für Bastler 
; und den Homebrew Computer Club freigegeben wurde, wird er in der Retrocomputing-Szene wie 
; Public Domain behandelt. Sie finden den Code frei zugänglich auf Plattformen wie 6502.org oder 
; GitHub zur nicht-kommerziellen Nutzung und für Emulatoren.
; ---
; util.s from: https://raw.githubusercontent.com/jefftranter/6502/master/asm/wozfp/util.s
; Copyright (C) 2012 by Jeff Tranter <tranter@pobox.com>
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

.setcpu "6502"
.segment "CODE"

.import GetKey, PrintChar, PrintCR, PrintString, PrintSpace
.import FADD, FSUB, FMUL, FDIV, FLOAT, FIX

; Wozniak/Rankin floating-point workspace (same addresses as original).
SIGN = $40
X2   = $41
M2   = $42
X1   = $45
M1   = $46
E    = $49
ZZ   = $4D
T    = $51
SEXP = $55
INT  = $59

; Application workspace, outside the original FP scratch area.
ACCUM      = $60       ; running result, 4 bytes
OPERAND    = $64       ; parsed second number, 4 bytes
SAVED      = $68       ; temporary FP value, 4 bytes
TENBUF     = $6C       ; constant 10, 4 bytes
ONEBUF     = $70       ; constant 1, 4 bytes
PTR        = $74       ; string pointer, 2 bytes
OPERATOR   = $76
DIGITS     = $77
FRACCOUNT  = $78
SEENDOT    = $79
NEGFLAG    = $7A
DIGITVAL   = $7B
DECTEMP    = $7C
DECEXP     = $7D       ; signed decimal exponent for scientific output
OUTCOUNT   = $7E
OUTDIGIT   = $7F
TMP        = $80
NORMBUF    = $84       ; normalized FP value for output formatter
OUTBUF     = $88       ; seven numeric digits: leading digit + six decimals
OUTINDEX   = $8F

.export start

start:
        CLD
        LDA #$83            ; 10 = 1.25 * 2^3
        STA TENBUF
        LDA #$50
        STA TENBUF+1
        LDA #0
        STA TENBUF+2
        STA TENBUF+3
        LDA #$80            ; 1.0 = 1.0 * 2^0
        STA ONEBUF
        LDA #$40
        STA ONEBUF+1
        LDA #0
        STA ONEBUF+2
        STA ONEBUF+3
        JSR ClearState
        LDX #<welcome
        LDY #>welcome
        JSR PrintString

; Initial value, then repeated operator + value calculations.
GetFirst:
        LDX #<numberPrompt
        LDY #>numberPrompt
        JSR PrintString
        JSR ReadNumber
        BCC @firstNumberOK
        JMP DoClear
@firstNumberOK:
        JSR SaveM1ToAccum
        LDX #<resultText
        LDY #>resultText
        JSR PrintString
        JSR PrintM1Scientific
        JSR PrintCR

NextOperator:
        LDX #<operatorPrompt
        LDY #>operatorPrompt
        JSR PrintString
        JSR GetKey
        JSR PrintChar
        JSR PrintCR
        CMP #'C'
        BEQ DoClear
        CMP #'c'
        BEQ DoClear
        CMP #'+'
        BEQ OperatorOK
        CMP #'-'
        BEQ OperatorOK
        CMP #'*'
        BEQ OperatorOK
        CMP #'/'
        BEQ OperatorOK
        JMP NextOperator
OperatorOK:
        STA OPERATOR
        LDX #<numberPrompt
        LDY #>numberPrompt
        JSR PrintString
        JSR ReadNumber
        BCS DoClear
        JSR SaveM1ToOperand
        JSR LoadOperandToM1
        JSR LoadAccumToM2
        LDA OPERATOR
        CMP #'-'
        BEQ DoSub
        CMP #'/'
        BEQ DoDiv
        CMP #'*'
        BEQ DoMul
        ; FADD is commutative; M1=operand, M2=accumulator.
        JSR FADD
        JMP CalculationDone
DoSub:  ; Original FSUB computes M2 - M1, i.e. accumulator - operand.
        JSR FSUB
        JMP CalculationDone
DoMul:  JSR FMUL
        JMP CalculationDone
DoDiv:  ; Original FDIV computes M2 / M1, i.e. accumulator / operand.
        JSR FDIV
CalculationDone:
        JSR SaveM1ToAccum
        LDX #<resultText
        LDY #>resultText
        JSR PrintString
        JSR PrintM1Scientific
        JSR PrintCR
        JMP NextOperator

DoClear:
        JSR ClearState
        JMP GetFirst

ClearState:
        LDA #0
        STA OPERATOR
        STA DIGITS
        STA FRACCOUNT
        STA SEENDOT
        STA NEGFLAG
        LDX #3
@z:     STA ACCUM,X
        STA OPERAND,X
        DEX
        BPL @z
        RTS

; Read one decimal number from keyboard until CR. Supports sign, one dot,
; and at most seven entered digits. Returns FP value in X1/M1; C=1 if C pressed.
ReadNumber:
        LDA #0
        STA DIGITS
        STA FRACCOUNT
        STA SEENDOT
        STA NEGFLAG
        STA SAVED
        STA SAVED+1
        STA SAVED+2
        STA SAVED+3
        LDX #<emptyPrompt
        LDY #>emptyPrompt
        JSR PrintString
@read:  JSR GetKey
        CMP #'C'
        BNE @notUpperC
        JMP @cancel
@notUpperC:
        CMP #'c'
        BNE @notLowerC
        JMP @cancel
@notLowerC:
        CMP #$0D
        BNE @notCR
        JMP @finish
@notCR:
        JSR PrintChar
        CMP #'-'
        BNE @notMinus
        LDA DIGITS
        ORA SEENDOT
        BNE @read
        LDA #1
        STA NEGFLAG
        JMP @read
@notMinus:
        CMP #'.'
        BNE @notDot
        LDA SEENDOT
        BNE @read
        LDA #1
        STA SEENDOT
        JMP @read
@notDot:
        CMP #'0'
        BCC @read
        CMP #'9'+1
        BCS @read
        SEC
        SBC #'0'
        STA DIGITVAL
        LDA DIGITS
        CMP #7
        BCS @ignoredigit
        INC DIGITS
        LDA SEENDOT
        BEQ @accumulate
        INC FRACCOUNT
@accumulate:
        LDA DIGITS
        CMP #1
        BNE @moreDigit
        ; First digit: convert integer digit to Woz FP.
        LDA #0
        STA M1
        STA M1+2
        LDA DIGITVAL
        STA M1+1
        JSR FLOAT
        JMP @read
@moreDigit:
        ; Leading zeroes need no FP multiply (and avoid multiplying FP zero).
        LDA X1
        ORA M1
        ORA M1+1
        ORA M1+2
        BEQ @zeroAccumulator
        ; FP accumulator *= 10.
        JSR LoadTenToM2
        JSR FMUL
        JSR SaveM1ToSaved
        ; Convert the new digit to FP, then add old accumulator.
        LDA #0
        STA M1
        STA M1+2
        LDA DIGITVAL
        STA M1+1
        JSR FLOAT
        JSR LoadSavedToM2
        JSR FADD
        JMP @read
@zeroAccumulator:
        LDA #0
        STA M1
        STA M1+2
        LDA DIGITVAL
        STA M1+1
        JSR FLOAT
        JMP @read
@ignoredigit:
        JMP @read
@finish:
        JSR PrintCR
        LDA DIGITS
        BNE @haveDigits
        ; Empty line is interpreted as zero.
        LDA #0
        STA X1
        STA M1
        STA M1+1
        STA M1+2
        CLC
        RTS
@haveDigits:
        ; Divide by 10^FRACCOUNT, built with the original FMUL routine.
        LDA FRACCOUNT
        BEQ @sign
        JSR SaveM1ToSaved
        LDA ONEBUF
        STA X1
        LDA ONEBUF+1
        STA M1
        LDA ONEBUF+2
        STA M1+1
        LDA ONEBUF+3
        STA M1+2
@scale: LDA FRACCOUNT
        BEQ @scaled
        JSR LoadTenToM2
        JSR FMUL
        DEC FRACCOUNT
        JMP @scale
@scaled:
        ; M1=10^n; M2=original accumulated integer; FDIV=M2/M1.
        JSR LoadSavedToM2
        JSR FDIV
@sign:  LDA NEGFLAG
        BEQ @success
        JSR NegateM1
@success:
        CLC
        RTS
@cancel:
        JSR PrintCR
        SEC
        RTS

; M1/X1 -> app buffers and back.
SaveM1ToAccum:
        LDX #3
@a:     LDA X1,X
        STA ACCUM,X
        DEX
        BPL @a
        RTS
SaveM1ToOperand:
        LDX #3
@o:     LDA X1,X
        STA OPERAND,X
        DEX
        BPL @o
        RTS
SaveM1ToSaved:
        LDX #3
@s:     LDA X1,X
        STA SAVED,X
        DEX
        BPL @s
        RTS
LoadOperandToM1:
        LDX #3
@lo:    LDA OPERAND,X
        STA X1,X
        DEX
        BPL @lo
        RTS
LoadAccumToM2:
        LDX #3
@lm:    LDA ACCUM,X
        STA X2,X
        DEX
        BPL @lm
        RTS
LoadSavedToM1:
        LDX #3
@lsm1:  LDA SAVED,X
        STA X1,X
        DEX
        BPL @lsm1
        RTS
LoadSavedToM2:
        LDX #3
@ls:    LDA SAVED,X
        STA X2,X
        DEX
        BPL @ls
        RTS
LoadTenToM2:
        LDX #3
@lt:    LDA TENBUF,X
        STA X2,X
        DEX
        BPL @lt
        RTS
NegateM1:
        SEC
        LDA #0
        SBC M1+2
        STA M1+2
        LDA #0
        SBC M1+1
        STA M1+1
        LDA #0
        SBC M1
        STA M1
        RTS

; Print a number in scientific notation, seven significant digits, rounded.
; Digits are buffered so a carry can propagate through trailing 9s.
PrintM1Scientific:
        ; zero test
        LDA X1
        ORA M1
        ORA M1+1
        ORA M1+2
        BNE @nonzero
        LDA #'0'
        JSR PrintChar
        RTS
@nonzero:
        LDA M1
        BPL @positive
        LDA #'-'
        JSR PrintChar
        JSR NegateM1
@positive:
        LDA #0
        STA DECEXP
; Scale magnitude into [1,10).
@scaleDown:
        JSR SaveM1ToSaved
        JSR LoadTenToM2
        JSR FSUB               ; M1 = 10 - value
        LDA M1
        BMI @divideTen         ; negative means value > 10
        LDA X1
        ORA M1
        ORA M1+1
        ORA M1+2
        BEQ @divideTen         ; exact 10
        JSR LoadSavedToM1
        JMP @scaleUpCheck
@divideTen:
        JSR LoadSavedToM1
        LDX #3
@tenToM1:
        LDA TENBUF,X
        STA X1,X
        DEX
        BPL @tenToM1
        JSR LoadSavedToM2
        JSR FDIV               ; value / 10
        INC DECEXP
        JMP @scaleDown
@scaleUpCheck:
        JSR SaveM1ToSaved
        LDX #3
@oneToM1:
        LDA ONEBUF,X
        STA X1,X
        DEX
        BPL @oneToM1
        JSR LoadSavedToM2
        JSR FSUB               ; M1 = value - 1
        LDA M1
        BMI @multiplyTen       ; negative means value < 1
        ; value >= 1, restore normalized value for digit extraction
        JSR LoadSavedToM1
        JMP @normalized
@multiplyTen:
        JSR LoadSavedToM1
        JSR LoadTenToM2
        JSR FMUL
        DEC DECEXP
        JMP @scaleDown
@normalized:
        ; Preserve normalized FP value for digit extraction.
        JSR SaveNorm
        JSR FIX
        LDA M1+1
        STA OUTBUF             ; leading digit (numeric, not ASCII)
        ; remainder = normalized - first digit
        LDA #0
        STA M1
        STA M1+2
        LDA OUTBUF
        STA M1+1
        JSR FLOAT
        JSR LoadNormToM2
        JSR FSUB
        LDA #7                 ; six printed decimals plus guard digit
        STA OUTCOUNT
        LDA #1
        STA OUTINDEX
@fracLoop:
        JSR LoadTenToM2
        JSR FMUL
        JSR SaveM1ToSaved      ; preserve scaled fraction before FIX
        JSR FIX
        LDA M1+1
        STA OUTDIGIT
        LDA OUTCOUNT
        CMP #1
        BEQ @guardDigit
        LDX OUTINDEX
        LDA OUTDIGIT
        STA OUTBUF,X
        INC OUTINDEX
        JMP @subtractDigit
@guardDigit:
        ; Round to nearest at six decimal places; ties round upward.
        LDA OUTDIGIT
        CMP #5
        BCC @printRounded
        JSR RoundOutputDigits
        JMP @printRounded
@subtractDigit:
        ; scaled fraction - extracted digit
        JSR LoadSavedToM2
        LDA #0
        STA M1
        STA M1+2
        LDA OUTDIGIT
        STA M1+1
        JSR FLOAT
        JSR FSUB
        DEC OUTCOUNT
        BNE @fracLoop
@printRounded:
        LDA OUTBUF
        CLC
        ADC #'0'
        JSR PrintChar
        LDA #'.'
        JSR PrintChar
        LDX #1
@printFraction:
        LDA OUTBUF,X
        CLC
        ADC #'0'
        JSR PrintChar
        INX
        CPX #7
        BNE @printFraction
        JMP PrintExponent

; Increment the six decimal digits, carrying into the leading digit if needed.
RoundOutputDigits:
        LDX #6
@roundDigit:
        INC OUTBUF,X
        LDA OUTBUF,X
        CMP #10
        BCC @roundDone
        LDA #0
        STA OUTBUF,X
        DEX
        BPL @roundDigit
        ; 9.999999 rounded up: renormalize to 1.000000E+(exp+1).
        LDA #1
        STA OUTBUF
        INC DECEXP
@roundDone:
        RTS

SaveNorm:
        LDX #3
@sn:    LDA X1,X
        STA NORMBUF,X
        DEX
        BPL @sn
        RTS
LoadNormToM2:
        LDX #3
@ln:    LDA NORMBUF,X
        STA X2,X
        DEX
        BPL @ln
        RTS

PrintExponent:
        LDA #'E'
        JSR PrintChar
        LDA DECEXP
        BMI @expNeg
        LDA #'+'
        JSR PrintChar
        JMP @expDigits
@expNeg:
        LDA #'-'
        JSR PrintChar
@expDigits:
        ; Print absolute exponent as two decimal digits (range is <=38).
        LDA DECEXP
        BPL @absReady
        EOR #$FF
        CLC
        ADC #1
@absReady:
        STA TMP
        LDA #0
        STA OUTDIGIT
@tenLoop:
        LDA TMP
        CMP #10
        BCC @ones
        SEC
        SBC #10
        STA TMP
        INC OUTDIGIT
        JMP @tenLoop
@ones:
        LDA OUTDIGIT
        CLC
        ADC #'0'
        JSR PrintChar
        LDA TMP
        CLC
        ADC #'0'
        JSR PrintChar
        RTS

; Preserve original normalized FP value for scientific formatter.
; (NORMBUF is intentionally separate from the Woz scratch workspace.)

welcome:       .byte $0D,"WOZ FP CALCULATOR",$0D,"Enter decimal numbers; C clears.",$0D,0
numberPrompt:  .byte "Number (CR ends): ",0
operatorPrompt:.byte "Operator (+ - * /, C=clear): ",0
resultText:    .byte "Result: ",0
emptyPrompt:   .byte 0
