;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP roll, imm8, bits, "rP := (rP << imm8) | (rP >> (16 - imm8)), imm8 is nonzero."
 lda (iptr),y
 tay_save
 lda 1,x
: cmp #$80
  rol 0,x
  rol
  dey
 bne :-
 sta 1,x
 jmp mainLoopRestoreY

OP shl, imm8, bits, "rP := rP << imm8 (nonzero), bits shift into the carry stack."
 lda (iptr),y
 tay_save
: asl 0,x
  rol 1,x
  ror cstack
  dey
 bne :-
 jmp mainLoopRestoreY

; lda, asl a, sta = 10 + 2*numbits cycles
; asl mem = 6*numbits cycles
; same for 2 bits, better for more

OP shr, imm8, bits, "rP := rP >> imm8 (nonzero), bits shift into the carry stack."
 lda (iptr),y
 tay_save
: lsr 1,x
  ror 0,x
  ror cstack
  dey
 bne :-
 jmp mainLoopRestoreY

OP sshr, imm8, bits, "rP := rP >>> imm8 (nonzero), bits shift into the carry stack."
 lda (iptr),y
 tay_save
 lda 1,x
: cmp #$80
  ror
  ror 0,x
  ror cstack
  dey
 bne :-
 sta 1,x
 jmp mainLoopRestoreY


OP addea2, ra, bits, "rP := rP + (rA << 1).  Does not affect carry."
 get_ra_y
 lda 0,y
 asl
 bcc :+
  inc 1,x
  clc
:adc 0,x
 sta 0,x
 lda 1,y
 adc 1,x
 sta 1,x
 jmp mainLoopRestoreY

