;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP_CATEGORY math, "Arithmetic", "All add and sub variations push a carry bit, incp and decp do not. The looping constructs can make up for this, or use 'addi 1'/'subi 1' if you need the expense of propagating carry."

PSEUDO addi, "imm", math, "Becomes addi8, addi16, or subi8.", {" .if (imm > 255) .or (imm < -255)",EOL, "   addi16 imm",EOL, " .elseif (imm < 0)",EOL, "   subi8 -(imm)",EOL, " .elseif (imm <> 0)",EOL, "   addi8 imm",EOL, " .endif"}
PSEUDO addic, "imm", math, "Becomes addi8c, addi16c, or subi8c.", {" .if (imm > 255) .or (imm < -255)",EOL, "   addi16c imm",EOL, " .elseif (imm < 0)",EOL, "   subi8c -(imm)",EOL, " .elseif (imm <> 0)",EOL, "   addi8c imm",EOL, " .endif"}
PSEUDO subi, "imm", math, "Becomes subi8, addi16, or addi8.", {" .if (imm > 255) .or (imm < -255)",EOL, "   addi16 -(imm)",EOL, " .elseif (imm < 0)",EOL, "   addi8 -(imm)",EOL, " .elseif (imm <> 0)",EOL, "   subi8 imm",EOL, " .endif"}
PSEUDO subic, "imm", math, "Becomes subi8c, addi16c, or addi8c.", {" .if (imm > 255) .or (imm < -255)",EOL, "   addi16c -(imm)",EOL, " .elseif (imm < 0)",EOL, "   addi8c -(imm)",EOL, " .elseif (imm <> 0)",EOL, "   subi8c imm",EOL, " .endif"}

;-------------
; Addition

OP incp2, none, math, "rP := rP + 2"
 sec
OP incp, none, math, "rP := rP + 1"
 lda 0,x
 adc #1
 sta 0,x
 bcc :+
  inc 1,x
:jmp mainLoop0

OP addi8c, imm8m1, math, "rP := rP + imm8 (1-256) + carry"
 asl cstack
 .byte $a9
OP addi8, imm8m1, math, "rP := rP + imm8 (1-256)"
 sec
 lda 0,x
 adc (iptr),y
 sta 0,x
 bcc :+
  inc 1,x
  beq :+
   clc
:ror cstack
 jmp mainLoop1

OP addi16c, imm16, math, "rP := rP + imm16 + carry"
 asl cstack
OP addi16, imm16, math, "rP := rP + imm16"
 lda 0,x
 adc (iptr),y
 iny
 sta 0,x
 lda 1,x
 adc (iptr),y
 sta 1,x
 ror cstack
 jmp mainLoop1

OP addc, ra, math, "rP := rP + rA + carry"
 get_ra    ; this mucks with carry, so we have to set it afterwards, which sucks
 asl cstack
 jmp :+
OP add, ra, math, "rP := rP + rA"
 get_ra
:tay_save
 lda 0,x
 adc 0,y
 sta 0,x
 lda 1,x
 adc 1,y
 sta 1,x
 ror cstack
 jmp mainLoop1


;-------------
; Subtraction

OP decp, none, math, "rP := rP - 1"
 sec
OP decp2, none, math, "rP := rP - 2"
 lda 0,x
 sbc #$01
 sta 0,x
 bcs :+
  dec 1,x
:jmp mainLoop0


OP subi8c, imm8m1, math, "rP := rP - imm8 (1-256) - borrow"
 asl cstack
OP subi8, imm8m1, math, "rP := rP - imm8 (1-256)"
 ; The additional -1 is supplied by entering with carry clear
 lda 0,x
 sbc (iptr),y
 sta 0,x
 bcs :+
  ; Use SBC to output carry properly
  lda 1,x
  sbc #$00
  sta 1,x
:ror cstack
 jmp mainLoop1

OP subc, ra, math, "rP := rP - rA - borrow"
 get_ra    ; this mucks with carry, so we have to set it afterwards, which sucks
 asl cstack
 jmp :+
OP sub, ra, math, "rP := rP - rA"
 get_ra
 sec
:tay_save
 lda 0,x
 sbc 0,y
 sta 0,x
 lda 1,x
 sbc 1,y
 sta 1,x
 ror cstack
 jmp mainLoopRestoreY



;-------------
; Comparison

OP cmpr, ra, math, "Compare rP - rA and push carry result on stack, without affecting registers (0: rP&lt;rA, 1: rP&gt;=rA)"
 get_ra_y
 lda 0,x
 cmp 0,y
 lda 1,x
 sbc 1,y
 ror cstack
 jmp mainLoopRestoreY

OP cmpi16, imm16, math, "Compare rP - imm16 and push carry result on stack, without affecting registers"
 lda 0,x
 cmp (iptr),y
 lda 1,x
 iny
 sbc (iptr),y
 ror cstack
 jmp mainLoop1

OP cmpi8, imm8, math, "Compare rP - imm8 and push carry result on stack, without affecting registers"
 lda 0,x
 cmp (iptr),y
 lda 1,x
 sbc #$00
 ror cstack
 jmp mainLoop1
