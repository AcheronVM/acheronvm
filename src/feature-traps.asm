;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

;-------------------
; Trap support

OP_CATEGORY traps, "Monitor Traps (FEATURE__TRAPS)"

OP_CATDOC traps, "The trap system allows breaking into native code before each instruction is executed, or when exceptions are thrown.  Native code can then check the iptr for breakpoint matches, resume, single-step, swap tasks, or do whatever it wants."
OP_CATDOC traps, "When the trap runs, the iptr points to the beginning of the instruction yet to be executed."
OP_CATDOC traps, "These handlers self-modify the main loop, so there is no runtime overhead when this feature is included and disabled, besides the memory footprint. Since the selfmod happens only on native instruction boundaries, it is safe to enable/disable traps from interrupt handlers. Preemptive task switchers should use this sort of approach."

; This overwrites the 'BMI _iptrOverflow' check on .Y increment in the dispatcher to 'BNE _instructionTrapJump'.
; Since .Y should never wrap past $FF, this should always branch.
NATIVE enableInstructionTrap, traps, jsr, "Enable the instruction trap to call <.A >.X."
 sta _instructionTrapJump +1
 stx _instructionTrapJump +2
 lda #$90 ;bne
 sta _instructionTrapSelfmod
 lda #_instructionTrapJump - _instructionTrapSelfmod - 2
 sta _instructionTrapSelfmod + 1
 rts

NATIVE disableInstructionTrap, traps, jsr, "Disable the break functionality."
 lda #$30 ;bmi
 sta _instructionTrapSelfmod
 lda #_iptrOverflow - _instructionTrapSelfmod - 2
 sta _instructionTrapSelfmod + 1
 rts

NATIVE continueFromInstructionTrap, traps, jmp, "Continue running the VM after a break was triggered.  If the break is still enabled, this effectively single-steps."
 ; Simulate what the selfmod stuff did
 ldy #0
 lda (iptr),y
 ; Restore register state
 ldx pptr
 jmp _instructionTrapResume

trapTramp:
 jsr normalizeState
 ; Default vector just continues
 jmp continueFromInstructionTrap


 ; Rolls .Y into iptr, and saves .X in pptr
normalizeState:
 tya
 clc
 adc iptr
 sta iptr
 bcc :+
  inc iptr+1
:stx pptr
 rts

.if FEATURE__EXCEPTIONS

exceptionTramp:
 jsr normalizeState
_exceptionTrapVector:
 jmp continueFromExceptionTrap

NATIVE enableExceptionTrap, traps, jsr, "Enable the exception trap to call <.A >.X"
 sta _exceptionTrapVector+1
 stx _exceptionTrapVector+2
 lda #<exceptionTramp
 sta _exceptionTrapSelfmod+1
 lda #>exceptionTramp
 sta _exceptionTrapSelfmod+2
 rts

NATIVE disableExceptionTrap, traps, jsr, "Disable exception trap."
 lda #<_exceptionTrapDisabled
 sta _exceptionTrapSelfmod+1
 lda #>_exceptionTrapDisabled
 sta _exceptionTrapSelfmod+2
 rts

NATIVE continueFromExceptionTrap, traps, jmp, "Continue processing the exception thrown."
 ldy #1
 ldx pptr
 clc
 jmp _exceptionTrapDisabled

.endif
