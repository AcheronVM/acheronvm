;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

; As opposed to branching, these looping instructions keep the loop state in a block of consecutive registers

OP decloop, rel8neg, flow, "Decrements rP by r[P+1], looping back 0-255 bytes if it hasn't underflowed yet."
 sec
 lda 0,x
 sbc 2,x
 sta 0,x
 lda 1,x
 sbc 3,x
 sta 1,x
 bcc :++
  ; Loop back if we haven't underflowed
: lda iptr
  sbc (iptr),y
  sta iptr
  bcs :+
   dec iptr+1
:jmp mainLoop1 ; Else, simply continue forward


OP decloopi, imm8rel8neg, flow, "Decrements rP by imm8, looping back imm8 bytes if it hasn't underflowed yet."
 sec
 lda 0,x
 sbc (iptr),Y
 iny
 sta 0,x
 lda 1,x
 sbc #0
 sta 0,x
 bcs :--
 jmp mainLoop1


; Older version, lots of operandss, piggybacks on the branch instructions

.if 0
OP decloop, imm8np1rel8, flow, "rP := rP - imm8 (1-256), branch until it wraps past zero.  Does not affect carry stack."
 get_imm8         ; imm8 needs to already be decremented and negated
 adc 0,x
 sta 0,x
 bcs ba_clc       ; branch if low byte didn't underflow
 lda 1,x          ; test to see if high byte will underflow
 beq :+
  dec 1,x         ; yes, dec and branch
  bcc ba          ; carry is known clear due to not taking bcs above
:dec 1,x
:jmp mainLoop2    ; doesn't need to be C here, but further ones need it to be
.endif
