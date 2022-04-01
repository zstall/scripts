#!/bin/sh

dir="/redata/postgres/data/pg_xlog"
cleanupCommand="/usr/pgsql-9.6/bin/pg_archivecleanup"
count=$(ls "${dir}/" | wc -l)

# Get the output for disk usage on the specified dir above !IMPORTANT! This should be the archive dir for hafo
output=`df -H ${dir}`
# Get the integer value of the disck usage
usep=$(echo $output | awk '{ print $12 }' | cut -d'%' -f1 | grep -iv use  )

# echo to the suer what the percentage is at
echo "Disk Space Used:" $usep "%"

# check if the arhive directory is above 90 percent usage and there are more than 20 files
if [[ ${usep} -ge 90 && ${count} -ge 6 ]]; then
        # use nullglob in case there are no matching files
        shopt -s nullglob

        # create an array with all the filer/dir inside ~/myDir
        arr=(${dir}/*)

        numToDelete=$((count/2))
        # create an array with all the filer/dir inside ~/myDir
        echo "There are $count files, getting the $numToDelete newest file."
        fileToDelete=$(basename "${arr[$numToDelete]}")
        echo "Selected file for pg_archivecleanup: "$fileToDelete

        echo "Running pg_archivecleanup"
        "${cleanupCommand}" "${dir}" "${fileToDelete}" -d
else echo "check complete";

fi