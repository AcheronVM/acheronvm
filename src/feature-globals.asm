;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP_CATEGORY globals, "Global Variables (FEATURE__GLOBALS)"
OP_CATDOC globals, "Similar to the 6502's zeropage, 256 bytes of global storage (as opposed to register stack storage) are addressable in short form."
OP_CATDOC globals, "Dereferencing through gptr allows faster context switching and reusable code between processes with different global tables."

ZPVAR gptr, globals, 2, "Pointer to the globals area.  Must be directly initialized before use."

OP ldg, imm8, globals, "rP := global(imm8)"
 lda (iptr),y
 tay_save
 lda (gptr),y
 sta 0,x
 iny
 lda (gptr),y
 sta 1,x
 jmp mainLoopRestoreY

OP stg, imm8, globals, "global(imm8) := rP"
 lda (iptr),y
 tay_save
 lda 0,x
 sta (gptr),y
 iny
 lda 1,x
 sta (gptr),y
 jmp mainLoopRestoreY

OP getgptr, imm8, globals, "rP := pointer to global(rP)"
 lda 0,x
 adc gptr
 sta 0,x
 lda 1,x
 adc gptr+1
 sta 1,x
 jmp mainLoop0
