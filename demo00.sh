#!/bin/sh

#obtains input from user
if test $# -ne 2
then
	echo "Usage: $0 <height> <width>"
	exit 1
else
	height=$1
	width=$2
fi

pattern="@"
border='#'
i=1

#prints out rectangle
while [ $i -le $height ] #prints row by row
do
	j=1
	while test $j -le $width #prints column by column
	do

		#prints border and internal pattern
		if test $i -eq 1 -o $i -eq $height
		then
			echo -n $border
		elif [ $j -eq 1 -o $j -eq $width ]
		then
			echo -n $border
		else
			echo -n $pattern
		fi

		j=`expr $j + 1`
	done
	echo
	i=$(expr $i + 1)
done
