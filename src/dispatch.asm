;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.



;-----------------------------------------------------
; The actual dispatcher code, taking in the opcode byte in .A
; This is in a single-use macro for organizing the code, because there's different options wrapping around it
.macro _dispatcher table

.if OPCODE_ENCODING__SPARSE

  clc
  sta :+ +1
: jmp (table)

; 7 bytes, 11 cycles

.elseif OPCODE_ENCODING__BYTE

  asl
  bcc :++
   clc
   sta :+ +1
:  jmp (table)
: sta :+ +1
: jmp (table + $0100)

; 16 bytes, 14-15 cycles 

.elseif OPCODE_ENCODING__WBIT

  asl
  sta :+ +1
  bcc :+
   ; Perform 'with' operation
   clc
   get_rd
   iny
: jmp (table)

; 15 bytes, 14-25 cycles (14 cycle dispatch + optional 11 cycle 'with' operation embedded)

.else
 .error "No dispatch code found for the selected OPCODE_ENCODING option"
.endif

.endmacro





;-----------------------------------------------------
; On op entry:
;  .X = pptr
;  .Y = offset from iptr of current byte read
;  .C = clear

; On op exit:
;  .X = pptr
;  iptr offset is either in .Y, or in iptr_offset via save_y



mainLoop2: ; Loop back when .Y is 1 before the last operand of the op, usually an early exit
 iny
mainLoop1:  ; Loop back when .Y is at the last operand of the op
 iny

OP noop, none, flow, "No operation."
mainLoop0:  ; Loop back when .Y points to the next instruction, normal for a 0-operand op

 lda (iptr),y  ; selfmod to bcc?  carry needs to be clear on reentry
 iny
.if FEATURE__TRAPS
 _instructionTrapSelfmod:
 _instructionTrapResume = *+2
.endif
 bmi _iptrOverflow

 _dispatcher dispatchTable

mainLoopRestoreY: ; Loop back when .Y was saved at the last parameter of the op, like mainLoop1
 ldy iptr_offset
 bpl mainLoop1
 iny  ; shift to a mainLoop0 style return
 ; fall through to overflow handler




;-----------------------------------------------------
; Utility branches

_iptrOverflow:
 tya
 ldy #0
 clc
 adc iptr
 sta iptr
 bcc mainLoop0
 inc iptr+1
 bcs mainLoop0

.if FEATURE__TRAPS
_instructionTrapJump:
 jmp trapTramp
.endif

