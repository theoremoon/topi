#!/bin/bash

compiler='./topi'
asm='tmp.asm'
obj='tmp.o'
bin='tmp.out'

all=0
passed=0

function compile {
  if [ $# -eq 0 ]; then
    $compiler > $asm
  else
    echo "$1" | $compiler  > $asm
  fi

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
  compile
  ./$bin
  exit
fi
if [ "$1" = "ast" ]; then
  $compiler -a
  exit
fi
if [ "$1" = "asm" ]; then
  $compiler
  exit
fi

test "print(1234)" "1234"
test "print(0xFF)" "255"
test "print(1.234)" "1.234000"
test "print(0.234)" "0.234000"
test "print(12+34)" "46"
test "print(12.3+4)" "16.300000"
test "print(12+3.4)" "15.400000"
test "print(1.2+3.4)" "4.600000"
test "print(1+2+3)" "6"
test "print(1.2+3+4+5+6)" "19.200000"
test "print(3-1)" "2"
test "print(3.1-1)" "2.100000"
test "print(3-1.1)" "1.900000"
test "print(3.1-1.1)" "2.000000"
test "print(1+2-3+4)" "4"
test "print(1+2.0-3+4)" "4.000000"
test "print(1+2*3)" "7"
test "print(1*2+3)" "5"
test "print(1.5*2)" "3.000000"
test "print(2*3.4)" "6.800000"
test "print(1.2*3.4)" "4.080000"
test "print(+1)" "1"
test "print(+1.0)" "1.000000"
test "print(-1)" "-1"
test "print(-1.0)" "-1.000000"
test "print((1+2)*3)" "9"
test "print((1+2)*(4+5))" "27"
test "print(4/2)" "2"
test "print(5/2)" "2"
test "print(5.0/2)" "2.500000"
test "print(5/2.0)" "2.500000"
test "print(10/3.0)" "3.333333"
test "print(1+2*3/4)" "2"
test "print(1+2*3/4.0)" "2.500000"

if [ "$all" = "$passed" ]; then
  toilet -f smblock  "all test passed" --gay
else
  echo -e "\e[31msome test failed ($((all-passed))/${all})\e[m"
fi
