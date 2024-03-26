all :
	nasm -g -F dwarf -f elf64 -l mprintf.lst mprintf.s
	gcc -c mprintf_call.cpp -o mprintf_call.o
	gcc -no-pie mprintf_call.o mprintf.o -o mprintf
