#!/bin/sh
#This script lists the days of the week and the months of the year

i=0

#displays days of the week
for day in Mon Tue Wed Thu Fri
do
	i=`expr $i + 1`
	echo "Day no. $i is $day"
done

echo #group separator
i=0

#displays months of the year
for month in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
do
	i=$(($i + 1))
	echo "Month no. $i is" $month
done
