#!/bin/sh

test=t

echo 'this is a $test"'
echo 'this is a $test""'
echo 'this is a $test'''
echo 'this is a "$test"'
echo 'this is a "$test'
echo 'this is a ""$test'
echo '"this is a'' $test'
echo 'this is a te''st'
echo 'this is " a test'

echo -n 'this is a $test"'
echo -n 'this is a $test""'
echo -n 'this is a $test'''
echo -n 'this is a "$test"'
echo -n 'this is a "$test'
echo -n 'this is a ""$test'
echo -n '"this is a'' $test'
echo -n 'this is a te''st'
echo -n 'this is " a test'

echo "this is a $test'"
echo "this is a $test''"
echo "this is a '$test"
echo "this is a ''$test"
echo "this is a '$test'"
echo "'this is a $test"
echo "this is a'' test"
echo "this is a 'test"
echo "this i'''s a test"

echo -n "this is a $test'"
echo -n "this is a $test''"
echo -n "this is a '$test"
echo -n "this is a ''$test"
echo -n "this is a '$test'"
echo -n "'this is a $test"
echo -n "this is a'' test"
echo -n "this is a 'test"
echo -n "this i'''s a test"

echo this is a $test
echo "this is a $test"
echo 'this is a $test'

echo -n this is a $test
echo -n "this is a $test"
echo -n 'this is a $test'

echo this is a$test
echo this is a $test
echo this is a '$test'
echo this is a $test$test
echo this is a$test$test""
echo this is a $test$test''
echo this is a ''$test$test$test
echo this is a''$test$test$test

echo "this is a$test"
echo "this is a $test"
echo "this is a '$test'"
echo "this is a $test$test"
echo "this is a$test$test"""
echo "this is a $test$test''"
echo "this is a ''$test$test$test"
echo "this is a''$test$test$test"

echo -n this is a$test
echo -n this is a $test
echo -n this is a '$test'
echo -n this is a $test$test
echo -n this is a$test$test""
echo -n this is a $test$test''
echo -n this is a ''$test$test$test
echo -n this is a''$test$test$test

echo -n "this is a$test"
echo -n "this is a $test"
echo -n "this is a '$test'"
echo -n "this is a $test$test"
echo -n "this is a$test$test"""
echo -n "this is a $test$test''"
echo -n "this is a ''$test$test$test"
echo -n "this is a''$test$test$test"

echo """"
echo ''''
echo "''"
echo '""'

echo -n """"
echo -n ''''
echo -n "''"
echo -n '""'

echo " "
echo ' '
echo ""
echo ''
echo

echo -n " "
echo -n ' '
echo -n ""
echo -n ''
echo -n
