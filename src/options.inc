;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.


;----------------------
; Feature inclusion

.define FEATURE__EXCEPTIONS 1
.define FEATURE__GLOBALS 1
.define FEATURE__TRAPS 1
.define FEATURE__DATAFRAMES 1
.define FEATURE__ABSOLUTE_ADDRESSING 1

;----------------------
; Text file generation

;.define EOL 13,10  ; DOS, Windows
.define EOL 10     ; Linux, OSX, etc


;----------------------
; Platform-specific file format for the binary output

;.define PLATFORM_ENCODING raw      ; no header
.define PLATFORM_ENCODING cbm_prg  ; 2-byte load address header


;----------------------
; Opcode allocation & dispatch

.define OPCODE_ENCODING__WBIT     1   ; Uses MSB to signal a 'with' adjustment.  128 instructions max.
.define OPCODE_ENCODING__SPARSE   0   ; Only even opcodes are used (so 128 max), for maximum performance in direct dispatch.
.define OPCODE_ENCODING__BYTE     0   ; 256 instructions, has to span up to 512 bytes of dispatch table.

.define OPTIMIZE_SIZE 1
.define OPTIMIZE_SPEED 0





.define SMALL_MEMOPS OPTIMIZE_SIZE
.define FAST_MEMOPS  OPTIMIZE_SPEED



