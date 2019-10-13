;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.



.include "../bin/acheron.inc"


.code

 ;; NOTE: This code assumes we're running on the Commodore 64, but Acheron is platform independent.

 ;; For nosing around with vicemon, you can load the labels file, too:
 ;; x64 --moncommands bin/labels bin/acheron.prg

 CHRIN = $ffcf ; wait for a character. Does not return until the user presses the Return key
 GETIN = $ffe4 ; async, returns $00 if there's no buffered character

 ;; This address will be printed during the build
.export start
start:
 jsr test

 ;; To exit, remember that KERNAL is fine
 ;; but BASIC zp got trashed.
:jsr GETIN               ; wait for a character
 beq :-
 jmp ($a000)             ; cold start back to basic



test:
 jsr clear_rstack
 jsr acheron       ; Note that gptr has not been initialied, so we are not using global variables


 grow 1
 with r0
 call getChar
 stma $0400

 native
 rts


; Get a character
.proc getChar
  native
:  jsr GETIN
  beq :-
  ldx pptr
  sta 0,x
  lda #0
  sta 1,x
.import op_ret
  jmp op_ret
.endproc


