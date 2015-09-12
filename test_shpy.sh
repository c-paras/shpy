#!/bin/sh

tmp1=/tmp/shell_output_$$.txt
tmp2=/tmp/python_output_$$.txt
code=/tmp/python_code_$$.py

for file in ~/ass1/examples/$1/*.sh
do
	base=`basename "$file" .sh`
	if [ "$base" == "pwd" -o "$base" == "single" ]
	then
		#skips subset 0 exceptions
		~/ass1/shpy.pl "$file" > code
		echo
		cat code
		echo "$base SKIPPED"
		echo
	elif [ "$base" == "for_gcc" -o "$base" == "for_read0" ]
	then
		#skips subset 1 exceptions
		~/ass1/shpy.pl "$file" > code
		echo
		cat code
		echo "$base SKIPPED"
		echo
	else
		sh "$file" > tmp1
		~/ass1/shpy.pl "$file" > code
		python -u code > tmp2
		diff tmp1 tmp2  && echo "$base SUCCEEDED" || echo "$base FAILED"
	fi
done
echo "ALL TESTS SUCCEEDED"
rm tmp1 tmp2 code
