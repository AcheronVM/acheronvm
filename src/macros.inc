;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

;-------------------------
; Output helpers

.define HEXCHAR(b) (('0'+(b))*((b)<=9) + ('a'+(b)-10)*((b)>9))
.define HEXBYTE(b) HEXCHAR(((b)>>4)&$f), HEXCHAR((b)&$f)
.define HEXWORD(b) HEXCHAR(((b)>>12)&$f), HEXCHAR(((b)>>8)&$f), HEXCHAR(((b)>>4)&$f), HEXCHAR((b)&$f)

.macro indent var, args, size
  .repeat .max(1,size-.strlen(args)-.strlen(.string(var)))
   .byte " "
  .endrepeat
.endmacro

.macro file_section name
 .byte EOL, ";------------------",EOL,"; ",name,EOL,EOL
.endmacro



;-------------------------
; Opcode generation

.if OPCODE_ENCODING__SPARSE
 .define opcodesPerInstruction 2
.else
 .define opcodesPerInstruction 1
.endif

.if OPCODE_ENCODING__WBIT
 .define maxOpcode 128
.else
 .define maxOpcode 256
.endif


.macro outputOpcode prefix
 .ifblank prefix
  .byte '$'
 .else
  .byte prefix
 .endif
.byte HEXBYTE((_opvec - dispatchTable)/2 * opcodesPerInstruction)
.endmacro

.macro EMIT name, category, doc, operands, bytespec, operandspecdoc
 .pushseg

 .segment "INCFILE_OPCODES"
 .byte "opcode_", .string(name), " "
 indent name, "", 20
 .byte "= "
 outputOpcode
 .byte EOL

 .segment "INCFILE_INSTRUCTIONS"

 .if OPCODE_ENCODING__WBIT

  .byte ".define ", .string(name), "(", operands, ")"
  indent name, operands, 20
  .byte "__wbit opcode_", .string(name)
  indent name, "", 10
  .byte ", {", bytespec, "}", EOL
  
 .else
 
  .byte ".define ", .string(name), "(", operands, ")"
  indent name, operands, 26
  .byte "__checkwith opcode_", .string(name), ","
  indent name, "", 10
  .byte "opcode_with_", .string(name), ","
  indent name, "", 10
  .byte "{", bytespec, "}", EOL

 .endif

 .segment "OPDESC_"
 .byte " (op (opcode "
  outputOpcode "#x"
 .byte ") (name ", '"', .string(name), '"', ") (category ", .string(category), ") (operandtext ", '"', operands, '"', ") (doc ", '"', doc, '"', "))", EOL
 
 .popseg
.endmacro




; This defines 'with' opcode variants for non-WBIT encodings
.if !OPCODE_ENCODING__WBIT
.macro OPWITH name
 .ident(.concat("_with_", .string(name))):
 .pushseg
 
 .segment "DISPATCH"
 .scope
  _opvec: .word .ident(.concat("_with_", .string(name)))

  .segment "INCFILE_OPCODES"
  .byte "opcode_with_", .string(name)
  indent name, "", 20 - 4
  .byte "= "
  outputOpcode
  .byte EOL
 .endscope
 .popseg
.endmacro
.endif



;-------------------------
; Zeropage management

.import __ZPSTACK_START__, __ZPSTACK_SIZE__

.define CURRENT_ZP_LOC <(zpTop + 1 + __ZPSTACK_START__ - *)   ; * is start + delta, we want start + size - delta

.macro ZPVAR name, category, size, doc, nolabel
 .exportzp name
 .pushseg
 .ifnblank nolabel
 .else
  .segment "ZPSTACK": zeropage
  .res size
  name = CURRENT_ZP_LOC
 .endif
 .segment "INCFILE_IMPORTS"
 .byte ".importzp ",.string(name),EOL
 .segment "OPDESC_"
 .byte " (zeropage (name ",'"',.string(name),'"',") (category ",.string(category),") (size ",.string(size),") (doc ",'"',doc,'"',"))",EOL
 .popseg
.endmacro






;-------------------------
; Declarations


.macro PSEUDO name, operands, category, doc, contents
 .pushseg
 .segment "OPDESC_"
 .byte " (pseudo-op (name ",'"',.string(name),'"',") (category ",.string(category),") (operands ",'"',operands,'"',") (doc ",'"',doc,'"',"))",EOL
 .segment "INCFILE_PSEUDO"
 .byte ".macro ",.string(name), " ", operands,EOL, contents,EOL, ".endmacro",EOL,EOL
 .popseg
.endmacro

.macro NATIVE name, category, calltype, doc, nolabel
 .ifnblank nolabel
 .else
 .export name
 name:
 .endif
 .pushseg
 .segment "OPDESC_"
 .byte " (native (name ",'"',.string(name),'"',") (calltype ",'"',.string(calltype),'"',") (category ",.string(category),") (doc ",'"',doc,'"',"))",EOL
 .segment "INCFILE_IMPORTS"
 .byte ".import ",.string(name),EOL
 .popseg
.endmacro

.macro OP_CATEGORY name, title, doc
 .pushseg
 .segment "OPDESC_"
 .byte " (category (name ", .string(name), ") (title ", '"', title, '"', ")"
 .ifnblank doc
   .byte " (category-doc ", '"',  doc, '"', ")"
 .endif
 .byte ")",EOL
 .popseg
.endmacro

.macro OP_CATDOC name, doc
 .pushseg
 .segment "OPDESC_"
 .byte " (category-doc (category ", .string(name), ") (doc ", '"', doc, '"', "))", EOL
 .popseg
.endmacro



;-------------------------
; Operand decoding

; All get reg operations require carry clear, as they perform an additon.
; They should leave carry clear, given that the register address doesn't
; wrap around zeropage.

.macro get_ra  ; .A = rA, requires carry clear
 lda (iptr),y
 adc rptr
.endmacro

.macro get_rd  ; .X = rD, requires carry clear
 get_ra
 tax
.endmacro

.macro save_y
 sty iptr_offset
.endmacro

.macro tay_save  ; saves .Y and does tay
 save_y
 tay
.endmacro

.macro get_ra_y ; .Y = rA, saving the old value of .Y
 get_ra
 tay_save
.endmacro
