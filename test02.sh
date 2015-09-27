#!/bin/sh
#This script demonstrates various ways to initialise variables
#Formats of initialisation include `expr .+` and $(expr .+) and the $((.+)) shell syntax

#basic variable initialisation
var0="this is a test"
echo $var0
var=65536
echo $var
var=$#
echo $var
var=$1
echo $var
var=$2
echo $var

#cases involving var=`expr .+`
var=`expr $# + $1 + $2`
echo $var
var=`expr $2 / $1 +    $#`
echo $var
var=`expr '(' 42 + $#     \) '*' -7` #unnecessary whitespace
echo $var
var=`expr 19 % 2 - 1`
echo $var
var=`expr 42 /    '(' 16 -     $# \)` #unnecessary whitespace
echo $var

#cases involving var=$(expr .+)
var=$(expr 14 \* $1)
echo $var
var=$(expr "(" $2 '*' 8 ")" "*" 16)
echo $var
var=$(expr 2 "*" 5)
echo $var
var=$(expr \( 16 % 4 \) + $var)
echo $var
var=$(expr   \(     15 %    4 ')' \* 6) #unnecessary whitespace
echo $var

#cases involving var=$((.+))
var=$((5 ** 3))
echo $var
var=$((($# ** 5) / 5))
echo $var
var=$(($var   +   $2)) #unnecessary whitespace
echo $var
var=$((19 * (5 ** 2)))
echo $var
var=$(($var / $var))
echo $var
