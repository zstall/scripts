#!/bin/bash


currentDate=$(date --date "-0 days" +'%F')

# Ask for start time:
echo "Enter start time for query (example: '2021-05-07 14:30:00'):"

read startTime

# Ask for end time:
echo "Enter end time for query (example '2021-05-07 17:30:00'):"

read endTime

emailList='zstall@levelsbeyond.com mstock@levelsbeyond.com'

function sqlAvgWorkflows
{
local start="${startTime}"
local end="${endTime}"

local sql=$(cat <<EOF
\COPY (select v.execution_label_expression, avg(e.date_updated - e.date_created) as avg_duration, min(e.date_updated - e.date_created) as min_duration, max(e.date_updated - e.date_created) as max_duration, count(e.workflow_version_id) from workflow_execution e inner join workflow_version v on e.workflow_version_id=v.id where e.date_created between '${start}' and '${end}' group by v.execution_label_expression order by 5 desc) to '/tmp/${currentDate}-Avg-workflows.csv' with csv header;
EOF
)

   echo "$sql"
}

function sqlAllWorkflows
{
local start="${startTime}"
local end="${endTime}"

local sql=$(cat <<EOF
\COPY (select (date_updated - date_created) as duration, execution_label, date_created, date_updated, status from workflow_execution where date_created between '${start}' and '${end}' order by duration desc) to '/tmp/${currentDate}-All-workflows.csv' with csv header;
EOF
)
   echo "$sql"
}

function runSQL
{
    psql -d "studio" -U "reachengine" -t -f ${sqlFile}
}

function mailReport
{

local attachmentOne="/tmp/${currentDate}-Avg-workflows.csv"
local attachmentTwo="/tmp/${currentDate}-All-workflows.csv"

   echo "Have some data :)" | mailx -s "NFL Workflow Data" -a "${attachmentOne}" -a "${attachmentTwo}" "${emailList}"

}

sql=$(sqlAvgWorkflows)
sqlFile=/tmp/sql.sql
    touch $sqlFile
    echo "$sql" > "$sqlFile"

runSQL

sql=$(sqlAllWorkflows)
sqlFile=/tmp/sql.sql
    touch $sqlFile
    echo "$sql" > "$sqlFile"

runSQL

# mailReport