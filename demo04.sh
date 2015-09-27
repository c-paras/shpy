#!/bin/sh
#This script simulates a user login form

#obtains user details
echo Enter username:
read username
echo Enter password:
read password

#authenticates user
if [ $username == "hello" ] && [ $password == "world" ]
then
	#proceeds if user authentication succeeded
	echo "You have been successfully authenticated"
	exit 0
else
	#exits with error status if authentication was unsuccessful
	echo "Authentication failed"
	echo "Wrong username or password"
	exit 1
fi
