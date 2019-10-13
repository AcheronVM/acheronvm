# Copyright 2012, 2019 White Flame.  This file is part of AcheronVM, which is licensed under the GNU Lesser General Public License version 3.

LISP = clisp
#LISP = sbcl --script

# Final output filename
BINFILE = acheron.prg


obj/%.o: src/%.asm
	ca65 -l obj/$(@F).lst $< -g -o $@ -I src

all: clean acheron docs

clean:
	- mkdir -p obj
	- mkdir -p bin
	- rm -f obj/*
	- rm -f bin/*

docs:
	- $(LISP) src/build-docs.lisp > bin/instruction-set.html

acheron: clean obj/acheron.o
	ld65 -Ln bin/labels -C src/acheron.cfg -m obj/map -o bin/$(BINFILE) obj/acheron.o
	# Display size information for each component. Only the above line is necessary for the build.
	@grep '^[^_]* Size=' obj/map
	@grep '\._size__' bin/labels
	@ls -l bin/acheron.prg

# Test project
test: acheron obj/test.o
	ld65 -Ln bin/labels -C src/acheron.cfg -m obj/map -o bin/$(BINFILE) obj/test.o obj/acheron.o
	@grep ' CODE .* Size=' obj/map
	@echo Launch address: `grep ' \.start$$' bin/labels | awk '{ print $$2 }' | head -1`

# Sample docs for webpage
sample: acheron docs
	- mkdir -p sample
	- rm -f sample/*
	cp bin/*.html sample/
	cp bin/*.inc sample/
