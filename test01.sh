#This script demonstrates poorly formatted code
#Inconsistent indentation and unnecessary whitespace is included
#Note the intended absence of the hashbang line

	  test=5 #dummy variable used to assess variable interpolation

#this for loop should execute six times
	for var in hello      world         $test 'single quotes' 42      "double quotes"
do
	if [ -e shpy.pl ] && [ -e test01.sh ] #echo will only proceed if these files exist
           then
                           echo $var
		fi
		done
