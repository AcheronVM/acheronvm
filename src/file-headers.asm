;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

; This stuffs the output textfile segments with their header information

.segment "INCFILE_TOP"
 .byte ";=================================================",EOL
 .byte "; Autogenerated AcheronVM instruction definitions",EOL, "; See acheron.asm for source",EOL,EOL

file_section "Registers"

.repeat 128, n
 .byte ".define r", .sprintf("%d",n), " ", .sprintf("%d",n), EOL
.endrepeat
.byte EOL

;.byte ".repeat 128, n", EOL
;.byte " .define .ident(.sprintf(", '"', "r%d", '"', ",n)) n", EOL
;.byte ".endrepeat", EOL, EOL

.byte ".macro __doregname name, reg", EOL
.byte "  .ifnblank name", EOL
.byte "    name = reg", EOL
.byte "  .endif", EOL
.byte ".endmacro", EOL, EOL

.byte ".macro regnames n0, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30, n31", EOL
.repeat 32, n
 .byte " __doregname ", .sprintf("n%d, r%d",n,n), EOL
.endrepeat
.byte ".endmacro", EOL, EOL



.segment "INCFILE_IMPORTS"
file_section "Global Imports"

.segment "INCFILE_INSTRUCTIONS"
file_section "Instruction Implementations"

.byte "; Note that 'with' is a build-time construct that pushes itself into", EOL
.byte "; the encoding of the next assembled Acheron instruction.  It is", EOL
.byte "; not a standard instruction and generates no opcode itself.", EOL, EOL

.byte "::__with_flag .set 0", EOL
.byte "::__with_reg  .set 0", EOL, EOL

.byte ".macro with reg", EOL
.byte "  ::__with_flag .set 1", EOL
.byte "  ::__with_reg  .set (reg)", EOL
.byte ".endmacro", EOL, EOL


.if OPCODE_ENCODING__WBIT

.byte ".macro __wbit opcode, operands", EOL
.byte "  .if ::__with_flag", EOL
.byte "    ::__with_flag .set 0", EOL
.byte "    .byte $80+(opcode), ((::__with_reg)<<1) operands", EOL
.byte "  .else", EOL
.byte "    .byte opcode operands", EOL
.byte "  .endif", EOL
.byte ".endmacro", EOL, EOL

.else

.byte ".macro __checkwith opcode, with_opcode, operands", EOL
.byte "  .if ::__with_flag", EOL
.byte "    ::__with_flag .set 0", EOL
.byte "    .ifdef with_opcode", EOL
.byte "      .byte with_opcode, ((::__with_reg)<<1) operands", EOL
.byte "    .else", EOL
.byte "      _with ::__with_reg", EOL
.byte "      .byte opcode operands", EOL
.byte "    .endif", EOL
.byte "  .else", EOL
.byte "    .byte opcode operands", EOL
.byte "  .endif", EOL
.byte ".endmacro", EOL, EOL

.endif


.segment "INCFILE_PSEUDO"
file_section "Pseudo-instructions"


.segment "INCFILE_OPCODES"
file_section "Opcodes"

.segment "OPDESC_"
 .byte "(",EOL

.if (.xmatch(PLATFORM_ENCODING, cbm_prg))
 .segment "BIN_HEADER"
 ; TODO - parameterize this?
 .import __ACHERON_START__
 .word __ACHERON_START__
.endif


