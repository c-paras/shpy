#!/bin/sh

tmp1=/tmp/shell_output_$$.txt
tmp2=/tmp/python_output_$$.txt
code=/tmp/python_code_$$.py

for file in ~/ass1/examples/$1/*.sh
do
	base=`basename "$file" .sh`
	if [ "$base" == "pwd" -o "$base" == "single" ]
	then
		echo "$base SKIPPED"
	else
		sh "$file" > tmp1
		~/ass1/shpy.pl "$file" > code
		python -u code > tmp2
		diff tmp1 tmp2  && echo "$base SUCCEEDED" || echo "$base FAILED"
	fi
done
rm tmp1 tmp2 code
