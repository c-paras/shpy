#!/bin/sh
#This script demonstrates various commands and filters being applied

#dummy variables
test1=a
test2=b
test3=c

test_file1=file1
test_file3=file3

#generates test files and directory
echo $test1 $test2 $test3 > $test_file1
echo $test1 $test2 > file2
echo "this is a test" > $test_file3
touch file4 #empty file
mkdir dir1
sleep 4 #delay to account for latency

#displays info about this file
ls test04.sh
ls -l test04.sh
ls -lastr test04.sh
ls -a -l -t test04.sh

#displays contents of files
cat $test_file1
head file2
tail $test_file3

#revokes all permissions from file2
chmod 000 file2

#sets full permissions to file2
if [ ! -r file2 ]
then
	chmod 777 file2
fi

#displays direcotry stats
ls
ls -l
ls -CmS
ls -lastr
ls -l -t

#displays stats of files given as args
ls "$@"
ls -a "$@"
ls -tla "$@"

#displays test file stats
wc $test_file1
wc -l file2
wc -c $test_file3

#copies file2 to dir1
cp $test_file3 dir1/
sleep 4 #delay to account for latency
ls -l dir1

#removes test files
rm $test_file1
rm file2
rm $test_file3
rm file4

#removes test directory
rm -r dir1
