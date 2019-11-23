;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP_CATEGORY mem, "Memory Operations"
OP_CATDOC mem, "Indexed modes take immediate constants, and are intended to reference structure slots without modifying the base pointer. Traversing through memory in order would instead use incp/decp or add/sub instructions on the address register."
OP_CATDOC mem, "Indexing uses (zp),y addressing behind the scenes, so is limited to +255. Referencing 16-bit data at an index of 255 will wrap to an index of 0 for the high byte and probably break things."
OP_CATDOC mem, "Memory stores keep rP pointing at the data register, so the destination address should be computed before the value to store into it."
OP_CATDOC mem, "Note that ldm commands will not work to load into rP.  Use deref instead."

.if SMALL_MEMOPS

; TODO - This is a compact code version of these routines, sharing code bodies containing dynamic flags to choose what to do.
;        Could write a set of faster, separate versions of each of these routines, too, for a different speed/size tradeoff


;-----------------
; Store


.if FEATURE__ABSOLUTE_ADDRESSING
 ; Store to absolute address
OP stmba, imm16, mem, "memory(imm16) byte := rP"
 sec
OP stma, imm16, mem, "memory(imm16) := rP"
 ; This is a double-indirection through iptr, so have to copy to zp
 lda (iptr),y
 sta zptemp
 iny
 lda (iptr),y
 sta zptemp+1
 save_y
 ldy #0
 lda 0,x
 sta (zptemp),y
 bcs :+
  lda 1,x
  iny
  sta (zptemp),y
:jmp mainLoopRestoreY
.endif

;; TODO -reevaluate if we want this format, has a broken SEC anyway
.if 0
; Store reg to mem(prior)
OP stmbpi, rdimm8, mem, "memory(rP + imm8) byte := rD"
 sec
OP stmbp, rd, mem, "memory(rP) byte := rD"
 inc doByte
 .byte $a9
OP stmpi, rdimm8, mem, "memory(rP + imm8) := rD"
 sec
OP stmp, rd, mem, "memory(rP) := rD"
 stx pptr
;; FIXME - this is broken, needs to use get_rd, which ruins the carry flag
 lda (iptr),y  ; get reg src into .X
 tax
 lda pptr
 jmp doStore
.endif


OP stmbi, imm8ra, mem, "memory(rA + imm8) byte := rP."
 sec
OP stmi, imm8ra, mem, "memory(rA + imm8) := rP."
 lda (iptr),y
 iny
 bne :+
OP stmb, ra, mem, "memory(rA) byte := rP."
 sec
OP stm, ra, mem, "memory(rA) := rP."
 lda #0

 ; C = set for byte mode
 ; A = offset for (),Y
 ; X = rP (data to write)
 ; Y = ready to read rA from iptr
 ; Note that I still don't like this, zptemp and php waste over a dozen cycles.
 ;  Better would be A = address reg, .Y = indirect offset, .X = data reg, but they're hard to load up that way without bigger code
 ;  Maybe the FAST_MEMOPS could do it that way or something
:sta zptemp
 php   ; save the carry flag for post-get_ra
 clc
 get_ra
 sta :+ + 1
 sta :++ + 1
 save_y
 ldy zptemp
 lda 0,x
:sta (0),y
 plp
 bcs :++
  iny
  lda 1,x
: sta (0),y
:jmp mainLoopRestoreY


        ;; Fiddling with individual implementations, and switching rP to the data address when not indexing
.if 0
        OP stmb, rd, mem, "memory(rD) byte := rP"
        lda 0,x
        pha
        get_rd
        pla
        sta (0,x)
        jmp mainLoop1

        OP stm, rd, mem, "memory(rD) := rP"
        get_ra
        sta :++ +1
        sty save_y
        ldy #1
:        lda 1,x
:        sta (0),y
         dex
         dey
        bpl :-
        ldx :- + 1   ; Read rP back into .X
        jmp mainLoopRestoreY


        OP stmbi, raimm8, mem, "memory(rA + imm8) byte := rP."
        get_ra
        sta :+ + 1
        iny
        lda (iptr),y
        save_y
        tay
        lda 0,x
:       sta (0),y
        jmp mainLoopRestoreY

        OP stmbi, raimm8, mem, "memory(rA + imm8) byte := rP."
        get_ra
        sec
        bcs :+
        OP stmi, raimm8, mem, "memory(rA + imm8) := rP."
        get_ra
:       sta :+ + 1
        sta :++ + 1
        iny
        lda (iptr),y
        save_y
        tay

        lda 0,x
:       sta (0),y
        bcs :++
        iny
        lda 1,x
:       sta (0),y

:       jmp mainLoopRestoreY
.endif  

;-----------------
; Load


.if FEATURE__ABSOLUTE_ADDRESSING
OP ldmba, imm16, mem, "rP := memory(imm16) byte"
 sec
OP ldma, imm16, mem, "rP := memory(imm16)"
 lda (iptr),y
 sta zptemp
 iny
 lda (iptr),y
 sta zptemp+1
 save_y
 ldy #0
 lda (zptemp),y
 sta 0,x
 lda #0
 bcs :+
  iny
  lda (zptemp),y
:sta 1,x
 jmp mainLoopRestoreY
.endif


OP ldmbi, imm8rd, mem, "rD := memory(rP + imm8) byte"
 sec
OP ldmi, imm8rd, mem, "rD := memory(rP + imm8)"
 lda (iptr),y
 iny
 bne :+
OP ldmb, rd, mem, "rD := memory(rP) byte"
 sec
OP ldm, rd, mem, "rD := memory(rP)"
 lda #0

; Same lame interface as doStore, requiring zptemp and php
; C = set for byte mode
; A = offset for (),Y
; X = rP (address to read)
; Y = ready to read iptr for rD
:stx :+ +1
 stx :++ +1
 sta zptemp
 php
 clc
 get_rd  ; rD becomes the new rP pretty quickly, to receive the data
 save_y
 ldy zptemp
:lda (0),y
 sta 0,x
 lda #0
 plp
 bcs :++
  iny
: lda (0),y
:sta 1,x
 jmp mainLoopRestoreY


 
; TODO - the above doesn't support deref.  Different code, or bolt in safety for the same?
;   the get_ra is entangled in the above and maybe isn't the best to reuse
.if 1

;; 16-bit wide versions are combined, as 8-bit versions can be made really short
OP derefi, imm8, mem, "rP := memory(rP + imm8)"
 lda (iptr),y
 iny
 bne :+
OP deref, none, mem, "rP := memory(rP)"
 lda #0
:tay_save
 ; It's the same cycles but fewer bytes to copy rP to zptemp than to selfmodify lda(0),y to point to rP and load through that
 ; It's a few cycles longer than using (0,x) and inc for the non-indexed version, so combining them here is reasonable
 lda 0,x
 sta zptemp
 lda 1,x
 sta zptemp+1
 lda (zptemp),y
 sta 0,x
 iny
 lda (zptemp),y
 sta 1,x
 ldy iptr_offset
 jmp mainLoop0

OP derefbi, imm8, mem, "rP := memory(rP + imm8) byte"
 lda (iptr),y
 iny
 adc 0,x
 bcc :+
  inc 1,x
:lda (0,x)
 jmp doSet8

; derefb is found in ops-short.asm

.if 0
 ; Standalone version of deref, without index option.  Might be a speed/space tradeoff to use this instead
OP deref, none, mem, "rP := memory(rP)"
 lda (0,x)
 pha
 inc 0,x
 bne :+
  inc 1,x
:lda (0,x)
 sta 1,x
 pla
 sta 0,x
 jmp mainLoop0
.endif

 
.endif
 
;----------------
; Clear

;clrmb is in ops-short.asm

; TODO - needs a lot of pointers, so we don't modify rP or rA.
.if 0
OP clrmnr, ra, mem, "memory(rP .. rP+rA-1) := 0. Clears 0-65535 bytes of memory, starting at rP."
.scope clrmnr
 stx store+1
 stx pptr
 
 get_rd
 save_y

 ; Check for zero, abort if so
 ldy 1,x
 beq zeroCheck
notZero:
 iny          ; preincrement high byte for easier counting
 sty zptemp
 ldy 0,x      ; low byte of length into .Y


 lda #0
: dey
store:
  sta (0),y
 bne :-
 lda zptemp
 beq :+

:ldx pptr
 jmp mainLoopRestoreY

zeroCheck:
 lda 0,x
 bne notZero
 beq :-
.endscope
.endif
 
OP clrmn, imm8o1, mem, "memory(rP .. rP+imm8-1) := 0. Clears 1-256 bytes of memory, starting at rP."
 lda (iptr),y
 bcc :+
OP clrm, none, mem, "memory(rP) := 0"
 lda #2
 dey      ; shuffle back for mainLoop reentry
:tay_save
 stx :++ +1
 lda #0
 ; Loop such that .Y=0 gets written.  Highest offset is .Y-1, so .Y=0 does a full 255->0 span
: dey
: sta (0),y
 bne :--
 jmp mainLoopRestoreY


; TODO - sec vs get_rd is screwed up. needs to be converted to fully rP code anway
.if 0
OP clrmba, imm16, mem, "memory(imm16) := 0 byte.  Clear memory byte, absolute address."
 inc doByte
OP clrma, imm16, mem, "memory(imm16) := 0.  Clear memory, absolute address."
 iny
 lda (iptr),y
 sta zptemp
 iny
 lda (iptr),y
 sta zptemp+1
 lda #zptemp
 jmp doClear

OP clrmbpi, imm8, mem, "memory(rP + imm8) := 0 byte.  Clear memory byte at prior, indexed."
 sec
OP clrmbp, none, mem, "memory(rP) := 0 byte.  Clear memory byte at prior."
 inc doByte
 .byte $a9
OP clrmpi, imm8, mem, "memory(rP + imm8) := 0.  Clear memory at prior, indexed."
 sec
OP clrmp, none, mem, "memory(rP) := 0.  Clear memory at prior."
 txa
 jmp doClear

OP clrmb, rd, mem, "memory(rD) := 0 byte.  Clear memory byte."
 sec
OP clrmbi, rdimm8, mem, "memory(rD + imm8) := 0 byte.  Clear memory byte, indexed."
 inc doByte
 .byte $a9
OP clrmi, rdimm8, mem, "memory(rD + imm8) := 0.  Clear memory, indexed."
 sec
OP clrm, rd, mem, "memory(rD) := 0.  Clear memory."
 lda (iptr),y
 iny
 tax

; .A = dest reg
; .Y = intact from operand reading
doClear:
 sta :++  + 1
 sta :+++ + 1
 lda #0
 bcc :+
  lda (iptr),y
  iny
:tay_save

 lda #0
:sta (0),y
 bcc :++
: sta (0),y
  iny
  dec doByte
:clc
 jmp mainLoop0
.endif




.endif



; Register + Register indexed reads & writes
; TODO - versions with implicit ea2 or ea4?

OP ldmr, rdra, mem, "rD := memory(rP + rA). Load Memory, Register indexed."
 sec
OP ldmbr, rdra, mem, "rD := memory(rP + rA) byte.  Load Memory Byte, Register indexed."
 php
 clc
 ; Put the destination register into zptemp
 get_ra
 sta zptemp+2
 ; Calculate the 16-bit destination in zptemp
 get_ra_y
 lda 0,x
 adc 0,y
 sta zptemp
 lda 1,x
 adc 1,y
 sta zptemp+1
 ; Read the single byte
 ldy #0
 lda (zptemp),y
 ; Store into the new rP
 ldx zptemp+2
 sta 0,x
 plp
 bcs :+
  ; Word version
  iny
  lda (zptemp),y
  tay
:sty 1,x
 jmp mainLoopRestoreY

OP stmr, rdra, mem, "memory(rD + rA) := rP.  Store Memory, Register indexed."
 ; Save the high byte to store
 lda 1,x
 pha
 sec
OP stmbr, rdra, mem, "memory(rD + rA) byte := rP.  Store Memory Byte, Register indexed."
 php
 clc
 ; Save the byte to store, from the current rP
 lda 0,x
 sta zptemp+2
 ; Calculate the 16-bit destination
 get_rd
 get_ra_y
 lda 0,x
 adc 0,y
 sta zptemp
 lda 1,x
 adc 1,y
 sta zptemp+1
 ; Store
 ldy #0
 lda zptemp+2
 sta (zptemp),y
 plp
 bcc :+
  ; Write the high byte
  pla
  iny
  sta (zptemp),y
:jmp mainLoopRestoreY


