#!/bin/bash
compiler='./topi'
asm='tmp.asm'
obj='tmp.o'
bin='tmp.out'
function compile {
	echo "$1" | $compiler  > $asm
	if [ $? -ne 0 ]; then
		echo "Failed to Compile $1"
		exit
	fi

	nasm -f elf64 -o $obj $asm
	if [ $? -ne 0 ]; then
		echo "Failed to Assemble $asm"
		exit
	fi

	gcc -o $bin $obj driver.c
	if [ $? -ne 0 ]; then
		echo "Failed to Compile $obj"
		exit
	fi
}

function test {
	compile $1
	r=`./$bin`
	
	if [ "$r" != "$2" ]; then
		echo "Expected $2 but got $r"
		exit
	fi
	echo "test passed $1 == $2"
}

dub build
if [ $? -ne 0 ]; then
	echo "Build Failed"
	exit
fi

test '1+1' '2'
test '2-1' '1'
test '100' '100'
test '2*4' '8'
test '1+2*3+4' '11'
test '1*2+3*4' '14'
test '(1+2)*3+4' '13'
