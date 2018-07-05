#!/bin/bash
export SDIR=/home/ged/gedstuff/code/tap/scripts
echo creating and running insert.sql...
cat $SDIR/inserthead.sql > insert.sql
java SheetReader >> insert.sql
mysql -t -u student < insert.sql
echo identifying room locks
#TODO per semester
mysql -N -u student timetable < $SDIR/roomlock.sql > roomlock.sh
chmod +x roomlock.sh
./roomlock.sh > roomlock.xml
echo deleteing incomplete rows...
mysql -t -u student < $SDIR/clean.sql > deleted.txt
echo performing data analysis...
mysql -t -u student timetable -e "SELECT lecturer,semester,SUM(hours) FROM timetable GROUP BY 1,2;" > lecturers.txt
mysql -t -u student timetable -e "SELECT course,campus,semester,SUM(hours) FROM timetable GROUP BY 1,2,3;" > courses.txt
mysql -t -u student timetable -e "SELECT campus,room,semester,SUM(hours) FROM timetable GROUP BY 1,2,3;" > rooms.txt
mysql -t -u student timetable -e "SELECT * FROM timetable;" > included.txt
mysql -t -u student timetable -e "SELECT campus,semester,SUM(hours) FROM timetable GROUP BY 1,2;" > campus.txt
cp $SDIR/analysis.html .
cp $SDIR/index.html .
echo generating students,teachers and subjects list...
mysql -N -u student < $SDIR/students.sql > temp.txt
tr -d '[:blank:]' < temp.txt > students.xml
mysql -N -u student < $SDIR/subjects.sql > temp.txt
tr -d '[:blank:]' < temp.txt > subjects.xml
mysql -N -u student < $SDIR/teachers.sql > temp.txt
tr -d '[:blank:]' < temp.txt > teachers.xml
for i in 1 2
do 
	echo generating activities for sem$i...
	mysql -N -u student < $SDIR/actsem$i.sql > actsem$i.xml
	tr -d '[:blank:]' < actsem$i.xml > temp.txt
	sed 's/<Teacher>NLR<\/Teacher>//' temp.txt  > actsem$i.xml
	echo generating time and space locks for sem$i...
	mysql -N -u student < $SDIR/timesem$i.sql > temp.txt
	tr -d '[:blank:]' < temp.txt > timelocksem$i.xml
	mysql -N -u student < $SDIR/spacesem$i.sql > temp.txt
	tr -d '[:blank:]' < temp.txt > spacelocksem$i.xml
	echo stitching sem$i.fet...
	cat $SDIR/top.xml > sem$i.fet #days and hours
	cat students.xml >> sem$i.fet
	cat teachers.xml >> sem$i.fet
	cat subjects.xml >> sem$i.fet
	cat $SDIR/tagslist.xml >> sem$i.fet #list of tags
	cat actsem$i.xml >> sem$i.fet
	cat $SDIR/roomsandbuildings.xml >> sem$i.fet #list of rooms and campuses
	cat $SDIR/timeconst.xml >> sem$i.fet #teacher not available times max days etc
	cat $SDIR/timesem$i.xml >> sem$i.fet #teacher not available for a semester
	cat timelocksem$i.xml >> sem$i.fet
	cat $SDIR/spaceconstsem$i.xml >> sem$i.fet #tags to rooms/room not avail/TODO split up
	cat roomlock.xml >> sem$i.fet #TODO needs to be split for sems.
	cat spacelocksem$i.xml >> sem$i.fet
done
