;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

.include "options.inc"

.include "macros.inc"
.include "operand-encodings.inc"

;-------------
; Declare default infrastructure

.include "file-headers.asm"

ZPVAR zpTop, regs, 0, "Highest zeropage memory location in use, for copying out process context.", nolabel
zpTop = <(__ZPSTACK_START__ + __ZPSTACK_SIZE__ - 1)

.segment "ZPTEMP": zeropage
zptemp: .res 3

.segment "DISPATCH"
 .align 256
dispatchTable:

OP_CATEGORY regs, "Register and Stack Operations"
OP_CATDOC regs, "The mark for the register stack set by mgrow is put on the CPU stack.  It does not affect any registers and marks can nest."
OP_CATEGORY flow, "Flow Control"
OP_CATDOC flow, {"To call an Acheron subroutine from native code:<pre> jsr acheron", EOL, " call <i>label</i>", EOL, " native</pre>This supports reentrant usage from within native portions of a running Acheron call chain."}
OP_CATEGORY bits, "Bitwise Operations"

ZPVAR iptr, flow, 2, "Instruction pointer base.  This plus .Y addresses the current program byte.  The dispatcher keeps .Y in the range of 0 to 127, so overflow after INY does not need to be checked."
ZPVAR iptr_offset, flow, 1, "Temp storage for the .Y offset to iptr when using the register for other purposes."

ZPVAR rptr, regs, 1, "Pointer to the head of the register stack, which is also r0, and the lowest used byte in zp."
ZPVAR pptr, regs, 1, "Pointer to the prior register, rP."


.macro reportSize label, filename
 label:
 .include filename
 .ident (.concat("_size__", .string(label))) = * - name
 .export .ident (.concat("_size__", .string(label)))
 .endmacro
 
.macro reportSizeSince name
 :
 .ident (.concat("_size__", .string(name))) = :- - name
 .export .ident(.concat("_size__", .string(name)))
.endmacro

.segment "ACHERON"

;----------------------
; Included ops and features

ops_carry:     .include "ops-carry.asm"      reportSizeSince ops_carry
ops_addsub:    .include "ops-addsub.asm"     reportSizeSince ops_addsub
ops_loadstore: .include "ops-loadstore.asm"  reportSizeSince ops_loadstore
ops_loop:      .include "ops-loop.asm"       reportSizeSince ops_loop
ops_misc:      .include "ops-misc.asm"       reportSizeSince ops_misc
ops_muldiv:    .include "ops-muldiv.asm"     reportSizeSince ops_muldiv
ops_callret:   .include "ops-callret.asm"    reportSizeSince ops_callret
ops_shift:     .include "ops-shift.asm"      reportSizeSince ops_shift


.if FEATURE__GLOBALS
feature_globals:       .include "feature-globals.asm"     reportSizeSince feature_globals
.endif

.if FEATURE__EXCEPTIONS
feature_exceptions:    .include "feature-exceptions.asm"  reportSizeSince feature_exceptions
.endif

.if FEATURE__TRAPS
feature_traps:         .include "feature-traps.asm"       reportSizeSince feature_traps
.endif

.if FEATURE__DATAFRAMES
feature_dataframes:    .include "feature-dataframes.asm"  reportSizeSince feature_dataframes
.endif



;----------------------
; Instruction dispatch,
; along with branch instructions that need to reach it,
; and select small instructions to space save on bcc vs jmp

ops_short:     .include "ops-short.asm"      reportSizeSince ops_short
ops_cpustack:  .include "ops-cpustack.asm"   reportSizeSince ops_cpustack
dispatch:      .include "dispatch.asm"       reportSizeSince dispatch
ops_branch:    .include "ops-branch.asm"     reportSizeSince ops_branch
























;------------------------
; Closeout of scopes

ZPVAR rstackTop, regs, 0, "The memory location right after the register stack.  This is the value of rptr when the register stack is empty."

.segment "DISPATCH"
endDispatchTable:

.segment "OPDESC_"
.byte ")",EOL

numOpcodes = (endDispatchTable - dispatchTable) / 2
maxOpcodes = (maxOpcode / opcodesPerInstruction)
numOpcodesFree = maxOpcodes - numOpcodes

.segment "INCFILE_IMPORTS"
.byte EOL
.segment "INCFILE_OPCODES"
.byte EOL
.segment "INCFILE_INSTRUCTIONS"
.byte EOL
.segment "INCFILE_BOTTOM"
.byte EOL
.byte "; Number of allocated opcodes:  ", .sprintf("%d",numOpcodes), EOL
.byte "; Number of opcodes remaining:  ", .sprintf("%d",numOpcodesFree), EOL

.out .sprintf("%d / %d opcodes defined", numOpcodes, maxOpcodes)

.if numOpcodesFree < 0
.fatal .sprintf("!!! Instruction set overflow !!!")
.endif

