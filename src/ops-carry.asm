;; Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

ZPVAR cstack, math, 1, "Carry stack.  MSB is the current carry bit."


OP dupc, none, bits, "Duplicate the top carry bit."
 lda cstack
 bpl op_pushcc
OP pushcs, none, bits, "Push a set carry bit."
 sec
OP pushcc, none, bits, "Push a clear carry bit."
 ror cstack
 jmp mainLoop0

OP dropc, none, bits, "Discard the most recent carry bit."
 asl cstack
 jmp mainLoop0

OP flipc, none, bits, "Flip the state of the most recent carry bit, leaving it on the carry stack."
 lda cstack
 eor #$80
 sta cstack
 jmp mainLoop0

