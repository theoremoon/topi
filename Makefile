all:
	./topi > hoge.asm
	nasm -f elf64 -o hoge.o hoge.asm
	gcc -o hoge hoge.o driver.c
	
