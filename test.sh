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

testast '1;' '1'
testast '1+2;' '(+ 1 2)'
testast '3-2;' '(- 3 2)'
testast '1+2*3;' '(+ 1 (* 2 3))'
testast '(1+2)*3;' '(* (+ 1 2) 3)'
testast '1;2+3;' '1 (+ 2 3)'
testast 'a;' 'a'
testast '1+abc;' '(+ 1 abc)'
testast '{1; 2; 3; {1+2;}}' '{1 2 3 {(+ 1 2)}}'
testast 'Func tako(){1+2;}tako();' '(func tako () {(+ 1 2)}) (tako)'
testast 'Func tako(){Int a=10;a;} tako();' '(func tako () {(def a 10) a}) (tako)'
testast 'Func add1(Int a){a+1;} add1(10);' '(func add1 (Int:a) {(+ a 1)}) (add1 10)'

test '1;' '1'
test '1+1;' '2'
test '2-1;' '1'
test '100;' '100'
test '2*4;' '8'
test '1+2*3+4;' '11'
test '1*2+3*4;' '14'
test '(1+2)*3+4;' '13'
test '1;2+3;4*5+6;' '26'
test 'Func tako(){1;2*3;} tako()+1;' '7'
test 'Func tako(){Int a=10;a;} tako();' '10'
test 'Func tako(){Int a=10;Int b=20;a+b;} Int c=3;tako()+c;' '33'
test 'Func add1(Int a){a+1;} add1(10);' '11'

echo "ALL TEST PASSED" 
