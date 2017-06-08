.DEFAULT_GOAL := all

main.o: render.o
	gcc -c main.cpp -g

render.o:
	nasm -f elf64 -g -F dwarf -l render.lst render.asm

all: clean main.o render.o
	gcc -o aboard main.o render.o -lSDL

clean: FORCE
	-rm *.o
FORCE:
