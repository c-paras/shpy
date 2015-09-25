#!/bin/sh

tmp1=/tmp/shell_output_$$.txt
tmp2=/tmp/python_output_$$.txt
code=/tmp/python_code_$$.py

#aborts if current test failed
abort_tests() {
	echo
	echo "Test: $1 FAILED"
	echo "$0: testing aborted"
	exit 1
}

#runs all demo and test files in the current directory
for file in demo??.sh test??.sh
do
	base=`basename "$file" .sh`

	if [ "$base" == "demo00" ]
        then
		#compares output of shell and python code for dimension 4 by 7
		sh "$file" 4 7 > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code 4 7 > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	else
		#compares output of shell and python code
		sh "$file" > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	fi
done

echo
echo "ALL TESTS SUCCEEDED"
rm $tmp1 $tmp2 $code
