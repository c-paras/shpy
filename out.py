#!/usr/bin/python2.7 -u

#Converted by shpy.pl [Sun Sep 20 18:44:04 2015]

import sys

#obtains input from user
if int((len(sys.argv) - 1)) != int(2):
	print "Usage:", sys.argv[0], "<height>", "<width>"
	sys.exit(1)
else:
	height = sys.argv[1]
	width = sys.argv[2]

pattern = '@'
border = '#'
i = 1

#prints out rectangle
while int(i) <= int(height): #prints row by row
	j = 1
	while int(j) <= int(width): #prints column by column

		#prints border and internal pattern
		if int(i) == int(1):
			print border, 
			sys.stdout.write('')
		elif int(j) == int(1):
			print border, 
			sys.stdout.write('')
		else:
			print pattern, 
			sys.stdout.write('')

		j = int(j) + 1
	print
	i = int(i) + 1
