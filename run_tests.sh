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

	if [ "$base" == "test02" ]
	then
		#compares output of shell and python code for input args of 4 and 5
		sh "$file" 4 5 > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code 4 5 > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "test03" ]
	then
		#compares output of shell and python code for input args of t, e, s, t
		sh "$file" t e s t > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code t e s t > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "test04" ]
	then
		#compares output of shell and python code for input args file1 and file2
		sh "$file" file1 file2 > $tmp1
		sleep 2 #delay to account for latency
		~/ass1/shpy.pl "$file" > $code
		python -u $code file1 file2 > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "demo03" ]
	then
		#compares output of shell and python code for sequence -4 3 18
		sh "$file" -4 3 18 > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code -4 3 18 > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "demo01" ]
	then
		#compares output of shell and python code for dimension 8 by 12
		sh "$file" 8 12 > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code 8 12 > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "demo02" ]
	then
		#compares output of shell and python code for input args -4 5 10 -15 100
		sh "$file" -4 5 10 -15 100 > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code -4 5 10 -15 100 > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "demo04" ]
	then
		#compares output of shell and python code and provides stdin
		sh "$file" < examples/input > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code < examples/input > $tmp2
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
