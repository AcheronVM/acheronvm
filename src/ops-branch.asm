;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

; This should be placed right after the dispatch, so that its native branches can reach the main loop directly

; Branch instructions are located close to the dispatch to allow native branch tests to escape

OP bneg, rel8, flow, "Branch if rP is negative."
 lda 1,x
 bpl mainLoop1
 bmi op_ba

OP bpos, rel8, flow, "Branch if rP is non-negative."
 lda 1,x
 bmi mainLoop1
 bpl op_ba

OP bz, rel8, flow, "Branch if rP is zero."
 lda 0,x
 ora 1,x
 bne mainLoop1
 beq op_ba

OP bnz, rel8, flow, "Branch if rP is non-zero."
 lda 0,x
 ora 1,x
 beq mainLoop1
 bne op_ba

OP bnc, rel8, flow, "Pop a carry bit, branch if it is clear."
 asl cstack
 bcs mainLoop1
 bcc op_ba

OP bc, rel8, flow, "Pop a carry bit, branch if it is set."
 asl cstack
 bcc mainLoop1
 ;bcs ba_clc      ; fall through to ba_clc

ba_clc:
 clc
OP ba, rel8, flow, "Always branch."
 ; Adjust iptr while leaving .Y alone.  Means .Y needs to wrap as we iterate, but the math checks out
 lda (iptr),y     ; .A = signed low byte
 pha
 adc iptr
 sta iptr
 pla              ; Generate sign extended high byte
 and #$80
 bpl :+
  lda #$ff
:adc iptr+1
 sta iptr+1
 jmp mainLoop1    ; 11 instructions, 21 bytes, 31 cycles best case

 ;; Full version with 16-bit pointers and no addition.  Is it worth the drop in code density?  probably not
 ; lda (iptr),y
 ; pha
 ; iny
 ; lda (iptr),y
 ; sta iptr+1
 ; pla
 ; sta iptr
 ; ldy #0
 ; jmp mainLoop0  ; 9 instructions, 15 bytes, 30 cycles best case, also saves 2 cycles by mainLoop0 instead of mainLoop1

 
PSEUDO case, "imm, rel8", flow, "Becomes case8 or case16", {" .if (imm >= 0) .and (imm <=255)",EOL,"   case8 imm, rel8",EOL," .else",EOL,"   case16 imm, rel8",EOL," .endif"}

OP case8, imm8rel8, flow, "Branch if rP = imm8."
 lda (iptr),y     ; test low byte
 iny              ; prepare .Y for ba to read the rel8 byte
 cmp 0,x
 bne mainLoop1
 lda 1,x          ; fail if high byte of rP is nonzero
 beq ba_clc
 jmp mainLoop1

OP case16, imm16rel8, flow, "Branch if rP = imm16."
 lda (iptr),y     ; test low byte
 iny
 cmp 0,x
 bne :+
 lda (iptr),y     ; test high byte
 cmp 1,x
 beq ba_clc
:jmp mainLoop1

OP caser, rarel8, flow, "Branch if rP = rA"
 get_ra
 iny
 tay_save
 lda 0,x
 cmp 0,y
 bne :-   ;; TODO - where is this supposed to go?
 lda 1,x
 cmp 1,y
 bne :-
 ldy iptr_offset
 jmp ba_clc

 
 ;; Negative cases are of dubious utility for branch trees, as it would be a bunch of expensive taken branches in the common case
.if 0
OP ncaser, rarel8, flow, "Branch if rP != rA"
 get_ra_y
 lda 0,x
 cmp 0,y
 bne :-
 lda 1,x
 cmp 1,y
 bne :-
:ldy iptr_offset
mainLoop2_case:
 jmp mainLoop2

OP ncase, imm16rel8, flow, "Branch if rP != imm16"
 lda (iptr),y
 iny
 cmp 0,x
 bne mainLoop2_case
 lda (iptr),y
 cmp 1,x
 beq mainLoop2_case
 iny
 bne ba_clc

OP ncase8, imm8rel8, flow, "Branch if rP != imm8."
 lda (iptr),y
 iny
 cmp 0,x
 bne ba_clc
 lda 1,x             ; Branch if high byte is set to nonzero, automatically not equal
 bne ba_clc
 jmp mainLoop2
.endif


 ;; While clever & short, decloop really is a better solution for most uses of this
.if 0
OP bm1, rel8, flow, "Branch if rP is -1."
 lda 0,x
 and 1,x
 eor #$ff
 beq op_ba
:jmp mainLoop2

OP bnm1, rel8, flow, "Branch if rP is not -1."
 lda 0,x
 and 1,x
 eor #$ff
 beq :-
 bne op_ba
.endif
