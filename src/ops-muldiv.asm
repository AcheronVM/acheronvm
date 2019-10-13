;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP mul, ra, math, "rP:r[P+1] := rP * rA"
 lda #0
 sta 2,x
 sta 3,x
OP mac, ra, math, "rP:r[P+1] := rP * rA + r[P+1]"
 get_ra_y
_mac:
 lda 0,y
 sta zptemp
 lda 1,y
 sta zptemp+1
 ldy #16
 bne macEnter
: bcc :+
   clc
   lda zptemp
   adc 2,x
   sta 2,x
   lda zptemp+1
   adc 3,x
   sta 3,x
: ror 3,x
  ror 2,x
macEnter:
  ror 1,x
  ror 0,x
  dey
 bpl :--
 jmp mainLoopRestoreY

OP div, ra, math, "rP := quotient, r[P+1] := remainder, of rP/rA."
 get_ra_y
 lda #0
 sta 2,x
 sta 3,x
 beq _div
OP ldiv, ra, math, "rP := quotient, r[P+1] := remainder, of rP:r[P+1]/rA."
 get_ra_y
_div:
 lda 0,y    ; put rA (denominator) into zptemp
 sta zptemp
 lda 1,y
 sta zptemp+1
 lda #16
 sta zptemp+2
 bne divEnter
: rol 2,x
  rol 3,x
divEnter:
  ; See if numhi is greater than the denom (numhi - demon)
  lda 2,x
  bcs numOverflow ; from rol above, but clear when first entered
  sec
  sbc zptemp
  tay
  lda 3,x
  sbc zptemp+1
  bcc :+
   ; yes it was, so commit the subtraction and shift a 1-bit in
   sty 2,x
   numOverflowReturn:
   sta 3,x
: rol 0,x
  rol 1,x
  dec zptemp+2
 bpl :--
 jmp mainLoopRestoreY

 ; If we reach here, the numerator overflows into 17 bits without having gotten greater than the denom.
 ; This means it always will be larger than the denominator now.  Unconditionally subtract the low 16 bits, and assume carry set afterwards.
 ; See the mess here http://6502org.wikidot.com/errata-software-figforth
numOverflow:
 sbc zptemp
 sta 2,x
 lda 3,x
 sbc zptemp+1
 sec
 bcs numOverflowReturn
 
 

