#!/bin/sh
#This script demonstrates various uses of echo and echo -n
#A combination of no quotes, single quotes, double quotes and mixed quotes are included
#Variable interpolation and variable concatenation is also included

test=t #dummy variable to assess variable interpolation within quotes

echo 'this is a $test"'
echo 'this is a $test""'
echo 'this is a $test'''
echo 'this is a "$test"' #nested quotes
echo 'this is a "$test'
echo 'this is a ""$test'
echo '"this is a'' $test'
echo 'this is a te''st'
echo 'this is " a test'

#variable interpolation should not occur
echo -n 'this is a $test"'
echo -n 'this is a $test""'
echo -n 'this is a $test'''
echo -n 'this is a "$test"'
echo -n 'this is a "$test'
echo -n 'this is a ""$test' #unnecessary quotes
echo -n '"this is a'' $test'
echo -n 'this is a te''st'
echo -n 'this is " a test'

#variable interpolation should occur
echo "this is a $test'"
echo "this is a $test''"
echo "this is a '$test"
echo "this is a ''$test"
echo "this is a '$test'" #nested quotes
echo "'this is a $test"
echo "this is a'' test"
echo "this is a 'test"
echo "this i'''s a test" #unnecessary quotes

echo -n "this is a $test'"
echo -n "this is a $test''"
echo -n "this is a '$test"
echo -n "this is a ''$test"
echo -n "this is a '$test'"
echo -n "'this is a $test"
echo -n "this is a'' test"
echo -n "this is a 'test"
echo -n "this i'''s a test"

#back quotes and shell arithmetic
echo $(expr 5 - 2)
echo `expr 5 / 2`
echo $((5 ** 2))

#back quotes and shell arithmetic
echo -n $(expr 5 '*' 2)
echo -n `expr 5 % 2`
echo -n $((5 * 2))

echo this is a $test #unquoted string
echo "this is a $test"
echo 'this is a $test'

echo -n this is a $test
echo -n "this is a $test"
echo -n 'this is a $test'

echo this is a$test
echo this is a $test
echo this is a '$test' #single quoted variable
echo this is a $test$test
echo this is a$test$test""
echo this is a $test$test'' #double concatenation
echo this is a ''$test$test$test
echo this is a''$test$test$test #triple concatenation
echo this is a $test:
echo this is a $test$test:
echo this is a $test:$test

echo "this is a$test"
echo "this is a $test"
echo "this is a '$test'" #nested quotes
echo "this is a $test$test"
echo "this is a$test$test"""
echo "this is a $test$test''"
echo "this is a ''$test$test$test"
echo "this is a''$test$test$test"
echo "this is a $test:"
echo "this is a $test$test," #trailing chars
echo "this is a $test%$test"

echo -n this is a$test #leading chars
echo -n this is a $test
echo -n this is a '$test'
echo -n this is a $test$test
echo -n this is a$test$test"" #leading and trailing chars
echo -n this is a $test$test''
echo -n this is a ''$test$test$test
echo -n this is a''$test$test$test
echo -n this is a $test: #trailing : char
echo -n this is a $test$test,
echo -n this is a $test%$test

echo -n "this is a$test"
echo -n "this is a $test"
echo -n "this is a '$test'"
echo -n "this is a $test$test"
echo -n "this is a$test$test"""
echo -n "this is a $test$test''"
echo -n "this is a ''$test$test$test"
echo -n "this is a''$test$test$test"
echo -n "this is a $test:"
echo -n "this is a $test$test,"
echo -n "this is a $test%$test" #% separator

#empty strings with newlines
echo """"
echo ''''
echo "''"
echo '""'

#empty strings without newlines
echo -n """"
echo -n ''''
echo -n "''"
echo -n '""'

#blank strings with newlines
echo " "
echo ' '
echo ""
echo ''
echo

#blank strings without newlines
echo -n " "
echo -n ' '
echo -n ""
echo -n ''
echo -n
