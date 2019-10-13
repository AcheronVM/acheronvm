;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

;--------------------------------
; Operand encodings

.define OPLABEL(name) .ident(.concat("op_", .string(name)))
 

.macro OP name, args, category, desc
 .pushseg
 .ident(.concat("op_", .string(name))):
 .segment "DISPATCH"
 .scope
 _opvec: .word .ident(.concat("op_", .string(name)))
 .if .xmatch(args,none)
   EMIT name, category, desc, "", ""

 .elseif .xmatch(args,rd)
   EMIT name, category, desc, "rD", ", ((rD)<<1)"
 .elseif .xmatch(args,ra)
   EMIT name, category, desc, "rA", ", ((rA)<<1)"
 .elseif .xmatch(args,rdra)
   EMIT name, category, desc, "rD, rA", ", ((rD)<<1), ((rA)<<1)"

 .elseif .xmatch(args,imm8)
   EMIT name, category, desc, "imm8", ", imm8"
 .elseif .xmatch(args,imm8m1)
   EMIT name, category, desc, "imm8p", ", ((imm8p)-1)"
 .elseif .xmatch(args,imm8o1)
   EMIT name, category, desc, "imm8p", ", <(imm8p)", "For pre-decrementing loops, 1-255 works as normal, and 256 gets encoded to 0 which runs 256 times."
 .elseif .xmatch(args,imm16)
   EMIT name, category, desc, "imm16", ", <(imm16), >(imm16)"
   
 .elseif .xmatch(args,rel8)
   EMIT name, category, desc, "rel8", ", <((rel8) - * + 1)" ; * is the address of the operand byte, so +1 to get back to the opcode byte
 .elseif .xmatch(args,imm8rel8)
   EMIT name, category, desc, "imm8, rel8", ", imm8, <((rel8) - * + 1)"
 .elseif .xmatch(args,imm16rel8)
   EMIT name, category, desc, "imm16, rel8", ", <(imm16), >(imm16), <((rel8) - * + 1)"
 .elseif .xmatch(args,rarel8)
   EMIT name, category, desc, "rA, rel8", ", ((rA)<<1), <((rel8) - * + 1)"
 .elseif .xmatch(args, rel8neg)
   EMIT name, category, desc, "rel8neg", "(* - (rel8neg))"
 .elseif .xmatch(args, imm8rel8neg)
   EMIT name, category, desc, "imm8, rel8neg", ", imm8, (* - (rel8neg))"
 .elseif .xmatch(args, imm8rd)
   EMIT name, category, desc, "rD, imm8", ", (imm8), ((rD)<<1)"
 .elseif .xmatch(args, imm8ra)
   EMIT name, category, desc, "rA, imm8", ", (imm8), ((rA)<<1)"

 .elseif .xmatch(args,rdimm16)
   EMIT name, category, desc, "rD, imm16", ", ((rD)<<1), <(imm16), >(imm16)"
 .elseif .xmatch(args,rdimm8)
   EMIT name, category, desc, "rD, imm8", ", ((rD)<<1), (imm8)"
 .elseif .xmatch(args,raimm8)
   EMIT name, category, desc, "rA, imm8", ", ((rA)<<1), (imm8)"
 .elseif .xmatch(args,nslots)
   EMIT name, category, desc, "imm8", ", (-((imm8)<<1)) & $ff", "Creates a negative rptr delta from imm8."
 .elseif .xmatch(args,pslots)
   EMIT name, category, desc, "imm8", ", ((imm8)<<1)", "Creates a positive rptr delta from imm8."

; Add more operand encodings here.

; The last 3 fields of the EMIT macro are:
;  source code parameters
;  conversion from parameters to .byte format, including a leading comma
;  optional HTML documentation of this encoding


 .else
   .error .concat("Instruction ",.string(name)," has an unknown operand encoding: ",.string(args))
 .endif
 .endscope
 .popseg
.endmacro

