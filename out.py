#!/usr/bin/python2.7 -u
import sys

test = 't'

#echo 'this is a $test"'
#echo "this is a $test'"
#echo '"this is a $test'
#echo "'this is a $test"

#echo "this is a '$test'"

print 'this', 'is', 'a', test
print 'this', 'is', 'a', test
print 'this is a $test'
print 'this', 'is', 'a', test, 
sys.stdout.write('')
print 'this', 'is', 'a', test, 
sys.stdout.write('')
sys.stdout.write('this is a $test')

#echo this is a$test
#echo this is a $testa
#echo """"
#echo ''''
#echo "''"
#echo '""'

#echo " "
#echo ' '
print
print
print

#echo -n " "
#echo -n ' '
#echo -n ""
#echo -n ''
#echo -n
