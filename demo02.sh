#!/bin/sh
#This script computes the sum of even and odd numbers in its arguments

even=0
odd=0

#aborts if no parameters are supplied
if test $# -lt 1
then
	echo "Usage: $0 <numbers>"
	exit 1
fi

#loops through each input argument
for num in "$@"
do
	parity=$(expr $num % 2) #determines parity of num

	#increments appropriate sum
	if [ $parity -eq 0 ]
	then
		even=$(($even + $num))
	else
		odd=$(($odd + $num))
	fi

done

echo The sum of all even numbers is $even
echo The sum of all odd numbers is $odd
