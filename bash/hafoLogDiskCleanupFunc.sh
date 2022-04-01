#!/bin/sh

dir="/redata/postgres/data/pg_xlog"
dir2="/redata/postgres/archive"
cleanupCommand="/usr/pgsql-9.6/bin/pg_archivecleanup"

# 1 = dir 
run_cleanup () {
    count=$(ls "$1/" | wc -l)
    # Get the output for disk usage on the specified dir above !IMPORTANT! This should be the archive dir for hafo
    output=$(df -H "$1")
    # Get the integer value of the disck usage
    usep=$(echo $output | awk '{ print $12 }' | cut -d'%' -f1 | grep -iv use  )

    # echo to the suer what the percentage is at
    echo "Disk Space Used:" $usep "%"

    # check if the arhive directory is above 90 percent usage and there are more than 20 files
    if [[ ${usep} -ge 90 && ${count} -ge 6 ]]; then
            # use nullglob in case there are no matching files
            shopt -s nullglob

            # create an array with all the filer/dir inside ~/myDir
            arr=($1/*)

            numToDelete=$((count/2))
            # create an array with all the filer/dir inside ~/myDir
            echo "There are $count files, getting the $numToDelete newest file."
            fileToDelete=$(basename "${arr[$numToDelete]}")
            echo "Selected file for pg_archivecleanup: "$fileToDelete

            echo "Running pg_archivecleanup"
            "${cleanupCommand}" "$1" "${fileToDelete}" -d
    else echo "check complete";
    fi
}
run_cleanup $dir
run_cleanup $dir2
