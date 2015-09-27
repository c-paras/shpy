#!/bin/sh
#This script demonstrates various uses of if, for and while statements
#Uses of compounded conditions and file test operators are included
#Nesting of control structures is included

#[ condition ] notation of test with boolean ||
if [ -e /dev/null ] || [ -r /dev/null ]
then
	echo first level of nesting

	#negation of test with boolean -a
	if ! test 2 -lt 5 -a -x /dev/null
	then
		echo second level of nesting

		#triple test condition with negation and boolean -o and -a
	      if test a == b -o ! 5 -eq 5 -a ! -w /dev/null #bad indentation
		then
			: #empty statement
		else
			echo third level of nesting

			#[ condition  ] notation with negation and boolean &&
			if [ "this is a test" != 'hello world' ] && [ ! -L /dev/null ]
			then

				echo fourth level of nesting

				#test condition with empty strings
				if ['' = ""]
				then
					echo fifth level of nesting 1
				fi

				#test condition involving \ escape
				if test 'teet' \< "test"
				then
					echo fifth level of nesting 2
				fi

			fi

		fi

	fi

fi

#for loop iterating over $*
for arg in $*
do
	echo $arg
done

#for loop iterating over "$*"
for arg in "$*"
do
	echo $arg
done

#for loop iterating over $*
for arg in $*
do
	echo $arg
done

#for loop iterating over "$@"
for arg in "$@"
do
        echo $arg
done

test=10 #dummy variable

#for loop iterating over a mixture of variables and strings
for arg in test '$test'    "$test"    $test  10
do
	echo $arg
done

#cmp test condition
if cmp test03.sh test03.sh
then
	echo files are identical
fi

#infinite loop with break
while ! diff /dev/null test03.sh
do
	  echo files are different #bad indentation
	break
done

i=10

#infinite loop
while true
do
	parity=$(expr $i % 2)

	#terminates loop after 10 iterations
	if test $i -eq 1
	then
		break
	elif [ $parity -eq 0 ]
	then
		echo $i #displays only even numbers
	fi

	i=$(($i - 1))
done

#infinite loop with negation
while ! false
do
	echo true
	exit 0
done
