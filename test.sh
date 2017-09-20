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

if [ "$1" = "run" ]; then
  compile `cat`
  ./$bin

  exit
fi

test "1234" "1234"
test "0xFF" "255"
test "1.234" "1.234000"
test "0.234" "0.234000"
test "12+34" "46"
test "12.3+4" "16.300000"
test "12+3.4" "15"
test "1.2+3.4" "4.600000"

toilet -f smblock  "all test passed" --gay
