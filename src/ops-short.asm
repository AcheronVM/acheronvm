;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

; Ops that are small in size and can use 6502 branch operations to reach back to the mainLoop



PSEUDO setp, "imm", regs, "Becomes clrp, setp8, or setp16.", {" .if (imm > 255) .or (imm < 0)",EOL,"   setp16 imm",EOL," .elseif (imm > 0)",EOL,"   setp8 imm",EOL," .else",EOL,"   clrp",EOL," .endif"}

OP derefb, none, mem, "rP := memory(rP) byte"
 lda (0,x)
 bcc doSet8
OP ldrptr, ra, regs, "rP := current address of rA.  Note that task switching or otherwise swapping out zp can leave this pointer dangling."
 get_ra
 iny
 bcc doSet8
OP hibyte, none, bits, "rP := upper byte of rP."
 lda 1,x
 bcc doSet8
OP clrp, none, regs, "rP := 0"
 lda #0
 beq doSet8
OP setp8, imm8, regs, "rP := imm8"
 lda (iptr),y
 iny
.export doSet8
doSet8: ;; note that .Y must match mainLoop0 here, advanced past the last operand
 sta 0,x
OP lobyte, none, bits, "rP := lower byte of rP."
 lda #0
 sta 1,x
 beq mainLoop0

OP movep, rd, regs, "rD := rP.  Effectively move rP and its value to another register."
 stx zptemp
 get_rd
 save_y
 ldy zptemp
 bcc :+

OP copyr, ra, regs, "rP := rA.  Copy another register into rP."
 get_ra_y
:lda 0,y
 sta 0,x
 lda 1,y
 sta 1,x
 bcc mainLoopRestoreY

OP setp16, imm16, regs, "rP := imm16"
 lda (iptr),y
 sta 0,x
 iny
 lda (iptr),y
 sta 1,x
 bcc mainLoop1

OP clrmb, none, mem, "memory(rP) byte := 0"
 lda #0
 sta (0,x)
 bcc mainLoop0

 
.if !OPCODE_ENCODING__WBIT
OP _with, rd, regs, "Explicitly select rP in an individual instruction."
 get_rd
 jmp mainLoop0
.endif
