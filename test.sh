#!/bin/bash

compiler='./topi'
asm='tmp.asm'
obj='tmp.o'
bin='tmp.out'

all=0
passed=0

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

	all=$((all+1))
	
	if [ "$r" != "$2" ]; then
		echo -e "\e[31mExpected $2 but got $r ($1)\e[m"
	else
		echo "test passed $1 == $2"
		passed=$((passed+1))
	fi
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
if [ "$1" = "ast" ]; then
  $compiler -a
 
  exit
fi

test "1234" "1234"
test "0xFF" "255"
test "1.234" "1.234000"
test "0.234" "0.234000"
test "12+34" "46"
test "12.3+4" "16.300000"
test "12+3.4" "15.400000"
test "1.2+3.4" "4.600000"
test "1+2+3" "6"
test "1.2+3+4+5+6" "19.200000"
test "3-1" "2"
test "3.1-1" "2.100000"
test "3-1.1" "1.900000"
test "3.1-1.1" "2.000000"
test "1+2-3+4" "4"
test "1+2.0-3+4" "4.000000"
test "1+2*3" "7"
test "1*2+3" "5"
test "1.5*2" "3.000000"
test "2*3.4" "6.800000"
test "1.2*3.4" "4.080000"
test "+1" "1"
test "+1.0" "1.000000"
test "-1" "-1"
test "-1.0" "-1.000000"
test "(1+2)*3" "9"
test "(1+2)*(4+5)" "27"
test "4/2" "2"
test "5/2" "2"
test "5.0/2" "2.500000"
test "5/2.0" "2.500000"
test "10/3.0" "3.333333"
test "1+2*3/4" "2"
test "1+2*3/4.0" "2.500000"

if [ "$all" = "$passed" ]; then
  toilet -f smblock  "all test passed" --gay
else
  echo -e "\e[31msome test failed ($((all-passed))/${all})\e[m"
fi
