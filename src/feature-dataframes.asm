;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP_CATEGORY dataframes, "Data Frames (FEATURE__DATAFRAMES)", "Allocates downward-growing data stack frames from a 16-bit pointer. Similar to C, these frames are valid within a function call's scope, as they are marked on the CPU stack."

ZPVAR dsptr, dataframes, 2, "Pointer to the dataframe head.  Must be directly initialized before use."


OP dsalloc, none, dataframes, "Allocate rP bytes as a new data stack frame, pushing the old location on the CPU stack."
 sec
 lda dsptr
 pha
 sbc 0,x
 sta dsptr
 lda dsptr+1
 pha
 sbc 1,x
 sta dsptr+1
 jmp mainLoop0

OP dspop, none, dataframes, "Discard the most recently allocated data stack frame, restoring state from the CPU stack."
 pla
 sta dsptr+1
 pla
 sta dsptr
 jmp mainLoop0




;; Pointer access into the data stack frame
OP dsi, imm8, dataframes, "rP := pointer to dataframe(imm8)"
 lda dsptr
 adc (iptr),y
 sta 0,x
 lda dsptr+1
 adc #0
 sta 1,x
 jmp mainLoop1

OP getdsptr, none, dataframes, "rP = pointer to dataframe(rP)"
 lda 0,x
 adc dsptr
 sta 0,x
 lda #0
 adc dsptr+1
 sta 1,x
 jmp mainLoop0



 ;; TODO - a single function entry instruction could allocate both regs & dataframes, as well as single return function
 ;; TODO - a data stack that wasn't tied to function scope would be more forth-like, but the frame links would need to be on the data stack itself.  That should probably be an acheron lib instead.

                                              
.if 0   ;; 8-bit sized version, would be more appropriate for integrating with a single entry instruction that allocated both regs and dataframes. 
 
OP dsallocm, imm8m1, dataframes, "Allocate imm8 (1-256) bytes as a new data stack frame, marking this on the CPU stack."
 lda dsptr
 sbc (iptr),y
 bcs :+
  dec dsptr+1
:jmp mainLoop1

OP dspopm, none, dataframes, "Free the last data stack frame, consuming the mark from the CPU stack."
 pla
 adc dsptr
 bcc :+
  inc dsptr+1
:jmp mainLoop0

.endif


