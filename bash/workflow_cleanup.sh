#!/bin/bash

# This has been written by Zachary Stall
# Date 5 August 2020
# This script will allow the user to input the date and execute a worklfow cleanup
# that will remove any worklfows in a non executing status older than the date entered.

echo Enter date to cleanup. Any worklfow older than this date in a non-executing state will be cleaned up.
echo To cleanup ALL workflows, enter the date for tomorrow. Format: year-month-day ex 2020-04-30

read usr_date

psql -U reachengine -d studio -c "select workflow_execution_cleanup('$usr_date');"
