;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

NATIVE clear_rstack, regs, jsr, "Initializes an empty register stack.  This is the minimum initialization needed for basic test code, but note that other features may not be initialized (globals, dataframes, etc)."
 lda #rstackTop
 sta rptr
 sta pptr
 rts

NATIVE acheronNest, flow, jsr, "Enter Acheron mode as if called as a subroutine, interpreting bytecodes immediately after the JSR instruction.  When this code ret's, the prior running Acheron code will resume."
 pla
 tax
 pla
 tay
 
 lda iptr
 pha
 lda iptr+1
 pha
 
 stx iptr
 sty iptr+1
 jmp :+
 
NATIVE acheron, flow, jsr, "Enter Acheron mode, interpreting bytecodes immediately after the JSR instruction."
 pla
 sta iptr
 pla
 sta iptr+1
 ; JSR puts the address before the instruction to run onto the stack, so start at offset 1
:ldy #1
 ldx pptr
 jmp mainLoop0

OP native, none, flow, "Enter 6502 mode, starting at the byte after this instruction."
 stx pptr
 tya
 adc iptr
 sta iptr
 bcc :+
  inc iptr+1
:jmp (iptr)


OP mgrow, nslots, regs, "Push a mark of the register stack, and grow it by imm8 slots.  rP is unchanged."
 lda rptr
 pha
OP grow, nslots, regs, "Grow the register stack by imm8 slots.  rP is unchanged."
 lda rptr
 adc (iptr),y
 sta rptr
 jmp mainLoop1

OP shrinkm, none, regs, "Shrink the register stack to last mark, and pop it.  The resulting r0 becomes the new rP."
 pla
 bcc :+
OP shrink, pslots, regs, "Shrink the register stack by imm8 slots.  The resulting r0 becomes the new rP."
 lda rptr
 adc (iptr),y
:sta rptr
 sta pptr
 jmp mainLoop1


OP bswap, none, bits, "Swap high and low bytes of rP."
 dey
 save_y
 ldy 0,x
 lda 1,x
 sta 0,x
 sty 1,x
 jmp mainLoopRestoreY









;OPWITH nswap
; get_rd
OP nswap, none, bits, "Swap nybbles of the low byte of rP."
 ; from David Galloway, http://www.6502.org/source/general/SWN.html
 lda 0,x
 asl
 adc #$80
 rol
 asl
 adc #$80
 rol
 sta 0,x
 jmp mainLoop0

OP negate, none, math, "rP := -rP"
 sec
OP not, none, bits, "rP := rP ^ $ffff"
 lda #0
 sbc 0,x
 sta 0,x
 lda #0
 sbc 1,x
 sta 1,x
 jmp mainLoop0




OP andr, ra, bits, "rP := rP & rA"
 get_ra_y
 lda 0,x
 and 0,y
 sta 0,x
 lda 1,x
 and 1,y
 sta 1,x
 jmp mainLoopRestoreY

OP orr, ra, bits, "rP := rP | rA"
 get_ra_y
 lda 0,x
 ora 0,y
 sta 0,x
 lda 1,x
 ora 1,y
 sta 1,x
 jmp mainLoopRestoreY

OP xorr, ra, bits, "rP := rP ^ rA"
 get_ra_y
 lda 0,x
 eor 0,y
 sta 0,x
 lda 1,x
 eor 1,y
 sta 1,x
 jmp mainLoopRestoreY



OP andi, imm16, bits, "rP := rP & imm16"
 lda 0,x
 and (iptr),y
 sta 0,x
 iny
 lda 1,x
 and (iptr),y
 sta 1,x
 jmp mainLoop1

OP ori, imm16, bits, "rP := rP | imm16"
 lda 0,x
 ora (iptr),y
 sta 0,x
 iny
 lda 1,x
 ora (iptr),y
 sta 1,x
 jmp mainLoop1

OP xori, imm16, bits, "rP := rP ^ imm16"
 lda 0,x
 eor (iptr),y
 sta 0,x
 iny
 lda 1,x
 eor (iptr),y
 sta 1,x
 jmp mainLoop1



OP tohex, none, bits, "Convert rP into a 2-byte ASCII hex representation of its low byte, e.g. $00f1 => $3146 (little endian, so 'f1')."
 lda 0,x
 and #$0f
 jsr :+
 sta 1,x
 lda 0,x
 lsr
 lsr
 lsr
 lsr
 jsr :+
 sta 0,x
 jmp mainLoop0
 
:cmp #$0a
 bcc :+
  adc #6
:adc #'0'
 rts
 
OP fromhex, none, bits, "Convert rP from a 2-byte ASCII hex representation into an 8-bit value.  This operation is case-insensitive."
 lda 0,x
 jsr :+
 asl
 asl
 asl
 asl
 sta zptemp
 lda 1,x
 jsr :+
 ora zptemp
 jmp doSet8
 
:and #$5f   ; mask out upper/lowercase differences
 sbc #'0'-1 ; note carry is clear hence the -1 on the constant
 cmp #$0a
 bcc :+
  sbc #7
:rts

OP signx, none, bits, "Sign extend an 8-bit value in rP into 16 bits."
 lda 0,x
 bpl :+
 lda #$ff
 bmi :++
:lda #0
:sta 1,x
 jmp mainLoop0

