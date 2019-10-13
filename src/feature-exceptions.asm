;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

OP_CATEGORY exceptions, "Exception Handling (FEATURE__EXCEPTIONS)"
OP_CATDOC exceptions, "These are non-local returns that can also be used for error handling."
OP_CATDOC exceptions, "When a throw is triggered, the CPU and register stacks are restored to the state at the time of the catch, the register stack grows by 2 slots, and r0 & r1 become the exception tag and parameter, respectively, with rP pointing to r0. Usually a handler will use 'case' instructions to branch on desired tags, rethrowing the exception otherwise."
OP_CATDOC exceptions, "For handling 'finally' situations, normal code flow and exception rethrowing need to be handled in the same code:"
OP_CATDOC exceptions, {"<pre>  catch finally",EOL,"  ...",EOL,"  popcatch     ; normal fallthrough into the 'finally' clause",EOL,"  grow 2",EOL,"  with r0 clrp",EOL,"finally:",EOL,"  ...",EOL,"  throw r0,r1  ; ignored if no exception was thrown and r0 is still zero</pre>"}
OP_CATDOC exceptions, "Each catch context takes 5 bytes on the CPU stack."

ZPVAR currentCatch, exceptions, 1, "CPU stack position describing the currently registered exception handler."

OP catch, imm16, exceptions, "Register an exception handler routine at imm16, with rP:r[P+1] receiving the exception info."
 lda currentCatch  ; prior catch frame
 pha
 lda (iptr),y      ; push low
 iny
 pha
 lda (iptr),y      ; push high
 pha
 lda rptr          ; push rptr
 pha
 txa               ; save .X
 pha               ; push pptr
 tsx
 stx currentCatch
 tax
 jmp mainLoop1

OP throw, none, exceptions, "If rP is nonzero, throw an exception with tag rP and parameter r[P+1].  Can be used to rethrow from inside a catch handler."
 ; Do the zero check first
 lda 0,x
 ora 1,x
 beq :+
 
.if FEATURE__TRAPS
 ; Now that we know there's an exception, optionally enable traps
 ; This gets selfmodded to jump to the exception tramp
_exceptionTrapSelfmod = *+1
 jmp _exceptionTrapDisabled
_exceptionTrapDisabled = *
.endif

 ; Put old rP in .Y for later
 txa
 tay

 ldx currentCatch
 txs
 
 pla
 tax              ; pptr
 pla
 sta rptr         ; rptr
 pla
 sta iptr+1       ; high
 pla
 sta iptr         ; low
 pla
 sta currentCatch ; prior catch frame
 
 ; Copy the thrown rP & r[P+1]
 lda 0,y
 sta 0,x
 lda 1,y
 sta 1,x
 lda 2,y
 sta 2,x
 lda 3,y
 sta 3,x

 ldy #0
:jmp mainLoop0


OP popcatch, none, exceptions, "Discard the most recent exception handler."
 stx pptr
 tsx         ; pop 4 of the 5 bytes, discarding
 txa
 adc #4
 tax
 txs
 pla         ; pop & restore the prior catch pointer
 sta currentCatch
 ldx pptr
 jmp mainLoop0
