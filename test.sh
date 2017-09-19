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
	compile "$1"
	r=`./$bin`
	
	if [ "$r" != "$2" ]; then
		echo "Expected $2 but got $r ($1)"
		exit
	fi
	echo "test passed $1 == $2"
}

dub build > /dev/null
if [ $? -ne 0 ]; then
  echo "Build Failed"
  exit
fi

test "1234" "1234"

toilet -f smblock  "all test passed" --gay
