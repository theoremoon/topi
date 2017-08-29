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

function testast {
	ast=`echo $1 | $compiler -a`
	if [ $? -ne 0 ]; then
		echo "Failed to Output AST of $1"
		exit
	fi

	if [ "$ast" != "$2" ]; then
		echo "Expected $2 but got $ast ($1)"
		exit
	fi

	echo "test passed $1 => $2"
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

dub build
if [ $? -ne 0 ]; then
	echo "Build Failed"
	exit
fi

testast '1' '1'
testast '1+5' '(+ 1 5)'
testast '4+5' '(+ 4 5)'
testast '6-5' '(- 6 5)'
testast '1+2+3' '(+ (+ 1 2) 3)'
testast '5-4+3' '(+ (- 5 4) 3)'
testast '1+2*3' '(+ 1 (* 2 3))'
testast '1*2+3' '(+ (* 1 2) 3)'
testast '{1+1; 2*3;}' '{(+ 1 1); (* 2 3)}'

test '1' '1'
test '1+5' '6'
test '4+5' '9'
test '6-5' '1'
test '1+2+3' '6'
test '5-4+3' '4'
test '1+2*3' '7'
test '1*2+3' '5'
test '{1+1; 2*3;}' '6'
