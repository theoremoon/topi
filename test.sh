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

testast '1;' '(func _func () {1})'
testast '1+2;' '(func _func () {(+ 1 2)})'
testast '3-2;' '(func _func () {(- 3 2)})'
testast '1+2*3;' '(func _func () {(+ 1 (* 2 3))})'
testast '(1+2)*3;' '(func _func () {(* (+ 1 2) 3)})'
testast '1;2+3;' '(func _func () {1 (+ 2 3)})'
testast 'a;' '(func _func () {a})'
testast '1+abc;' '(func _func () {(+ 1 abc)})'
testast '{1; 2; 3; {1+2;}}' '(func _func () {{1 2 3 {(+ 1 2)}}})'
testast 'Func tako(){1+2;}tako();' '(func tako () {(+ 1 2)}) (func _func () {(tako)})'
testast 'Func tako(){Int a=10;a;} tako();' '(func tako () {(def Int:a 10) a}) (func _func () {(tako)})'
testast 'Func(Int) add1(a){a+1;} add1(10);' '(func add1 (Int:a) {(+ a 1)}) (func _func () {(add1 10)})'
testast '1==1;' '(func _func () {(== 1 1)})'
testast '0; if (1 == 1) { 1; }' '(func _func () {0 (cond ((== 1 1) {1}))})'
testast '0; if (1 == 1) { 1; } elseif (1 == 2) { 2; } else { 3; }' '(func _func () {0 (cond ((== 1 1) {1}) ((== 1 2) {2}) {3})})'
testast '"hello";' '(func _func () {"hello"})'
testast '0 1 2 3' '(func _func () {0 1 2 3})'

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
test 'Func(Int) add1(a){a+1;} add1(10);' '11'
test '0; if (1 == 1) { 1; }' '1'
test 'Int a=1;if a==1 { 1; } elseif a==2 { 2; } else { 3; }' '1'
test 'Int a=2;if a==1 { 1; } elseif a==2 { 2; } else { 3; }' '2'
test 'Int a=3;if a==1 { 1; } elseif a==2 { 2; } else { 3; }' '3'
echo "ALL TEST PASSED" 
