;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP callp, none, flow, "Call subroutine at the address held in rP."
 tya
 adc iptr
 pha
 lda iptr+1
 adc #0
 pha
OP jumpp, none, flow, "Jump to address held in rP."
 lda 0,x
 sta iptr
 lda 1,x
 sta iptr+1
 ldy #0
 jmp mainLoop0

OP call, imm16, flow, "Call subroutine at imm16."
 tya
 adc #2  ; skip over operand for the return address, note that Y ~< 128
 adc iptr
 pha
 lda iptr+1
 adc #0
 pha
OP jump, imm16, flow, "Jump to imm16."
 lda (iptr),y
 sta zptemp
 iny
 lda (iptr),y
 sta iptr+1
 lda zptemp
 sta iptr
 ldy #0
 jmp mainLoop0 ; 47 clock cycles

.export op_ret, op_retm
OP retm, none, flow, "Pop & restore the register stack mark from mgrow, return from subroutine.  Resets rP to the returned r0."
 pla
 sta rptr
 sta pptr
OP ret, none, flow, "Return from subroutine."
 pla
 sta iptr+1
 pla
 sta iptr
 ldy #0
 jmp mainLoop0


OP calln, imm16, flow, "Call native 6502 subroutine at imm16.  .X points to rP.  .X and .Y are saved and restored."
 lda (iptr),y
 sta :+ +1
 iny
 lda (iptr),y
 sta :+ +2
 save_y
 stx pptr
:jsr *
 ldx pptr  ; 36 cycles
 jmp mainLoopRestoreY

 ; TODO - calln alternative
.if 0
 jsr normalizeState 
 jsr :+
 ldy #0
 ldx pptr
 jmp mainLoop0
:jmp (iptr)
.endif

.if 0

; Implementation of a single-byte instruction whose implementation is an acheron call:
; Need some way to get the implementation label in here for a runtime call.  Don't want these splatted literally.

; Hmm, if we could push these in a subroutine, then just jsr acheron at the call site, followed by acheron code ending with ret would be fine
 tya
 adc iptr
 pha
 lda iptr+1
 adc #0
 pha
 
 lda #<:+
 sta iptr
 lda #>:+
 sta iptr+1
 ldy #0
 jmp mainLoop0
: ; Acheron code goes here, ending in ret/retm
;; This is a 22 byte stump, plus 2 byes for dispatch entry table.  Not the end of the world for a first attempt, I guess

; Considering "jsr acheronimp", the 2 bytes on the stack indicate where acheron code bytes start, but teh current iptr needs to go onto to stack, too
; The above ignores being called into it and has the data pushed forward...  yeahl, selfmod

; The first part of pushing the old address is common between call, callp, and this which is annoying
; Tons of these also just store into iptr and continue, however loading from different places


.endif
