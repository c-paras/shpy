#!/bin/sh

tmp1=/tmp/shell_output_$$.txt
tmp2=/tmp/python_output_$$.txt
code=/tmp/python_code_$$.py
temp=/tmp/temp_code_$$.py
ref=/tmp/reference_code_$$.py

#aborts if current test failed
abort_tests() {
	echo
	echo "Test: $1 FAILED"
	echo "$0: testing aborted"
	exit 1
}

#runs each test in the specified directory
for file in ~/ass1/examples/[01234]/*.sh
do
	base=`basename "$file" .sh`
	if [ "$base" == "pwd" -o "$base" == "single" ]
	then
		reference_code="examples/0/$base.py"

		#compares python code output by program with reference code
		~/ass1/shpy.pl "$file" > $code
		cat $code | egrep -v '^#' | cat > $temp
		cat $reference_code | egrep -v '^#' | cat > $ref
		diff -B $temp $ref && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "for_gcc" ]
	then
		touch file1_$$.c file2_$$.c file3_$$.c #creates dummy .c files

		#compares output of shell and python code for input files file?_$$.c
		sh "$file" > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code > $tmp2
		rm file?_$$.c
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "for_read0" ]
	then
		#compares output of shell and python code for randomised input 1..10
		sh "$file" > $tmp1 < ~/ass1/examples/input
		~/ass1/shpy.pl "$file" > $code
		python -u $code > $tmp2 < ~/ass1/examples/input
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "args" ]
	then
		#compares output of shell and python code for input parameters arg?
		sh "$file" arg1 arg2 arg3 arg4 arg5 > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code arg1 arg2 arg3 arg4 arg5 > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "l" ]
	then
		#compares output of shell and python code for input file shpy.pl
		sh "$file" ~/ass1/shpy.pl > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code ~/ass1/shpy.pl > $tmp2
		diff $tmp1 $tmp2 && echo "Test: $base SUCCEEDED" && continue
		abort_tests "$base"
	elif [ "$base" == "sequence0" -o "$base" == "sequence1" ]
	then
		#compares output of shell and python code for sequence 3..15
		sh "$file" 3 15 > $tmp1
		~/ass1/shpy.pl "$file" > $code
		python -u $code 3 15 > $tmp2
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
rm $tmp1 $tmp2 $code $temp $ref
