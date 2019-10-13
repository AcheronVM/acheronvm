;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP pushp, none, regs, "Push rP to the CPU stack."
 lda 0,x
 pha
 lda 1,x
 pha
 bcc mainLoop0

OP popp, none, regs, "Pop rP from the CPU stack."
 pla
 sta 1,x
 pla
 sta 0,x
 bcc mainLoop0

OP dropp, none, regs, "Drop a 16-bit value from the CPU stack."
 pla
 pla
 bcc mainLoop0

OP getsp, none, regs, "rP := CPU stack pointer"
 lda #1
 sta 1,x
 stx :+ +1
 txa
 tsx
:stx 0
 tax
 bcc mainLoop0

OP setsp, none, regs, "CPU stack pointer := rP.  Only the low byte is used."
 stx pptr
 lda 0,x
 tax
 txs
 ldx pptr
 bcc mainLoop0
