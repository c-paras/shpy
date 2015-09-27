#!/bin/sh
#This script prints a sequence of integers between given bounds

#obtains input parameters
if test $# -lt 2
then
	echo "Usage: $0 <min> <optional increment> <max>"
	exit 1
elif [ $# -eq 2 ]
then
	min=$1
	inc=1
	max=$2
elif [ $# -eq 3 ]
then
	min=$1
	inc=$2
	max=$3
fi

#aborts if invalid parameters were supplied
if test $inc -eq 0
then
	echo $0: increment cannot be zero
	exit 1
elif test $max -le $min
then
	echo $0: max must be greater than min
	exit 1
fi

i=$min

#prints sequence of integers
while test $i -le $max
do
	echo $i
	i=`expr $i + $inc`
done
