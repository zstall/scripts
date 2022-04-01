#!/bin/bash

currentDate=$(date --date "-1 days" +'%F')
startHours='04:00:00'
midHours='08:00:00'
endHours='16:00:00'


#emailList='blangley@levelsbeyond.com wrosenberg@levelsbeyond.com dwood@levelsbeyond.com smonasco@levelsbeyond.com'
emailList='zstall@levelsbeyond.com mstock@levelsbeyond.com'

function buildSQL
{

local startTime="${currentDate} ${startHours}"
local endTime="${currentDate} ${endHours}"

local sql=$(cat <<EOF
\COPY (SELECT awse.step_type,REGEXP_REPLACE(awse.execution_label, ',', '\,', 'g'),awse.date_created,awse.start_date,awse.end_date,wf.NAME,wf.key_m_d,pw.NAME,pw.key_m_d,coalesce(wq.name, 'default') FROM abstract_workflow_step_execution awse INNER JOIN workflow_execution we ON ( we.id = awse.workflow_workflow_execution_id ) INNER JOIN workflow_version wv ON ( we.workflow_version_id = wv.id ) INNER JOIN workflow wf ON ( wf.id = wv.workflow_workflow_id ) LEFT JOIN workflow_queue wq ON ( wq.id = awse.queue_id ) LEFT JOIN workflow_execution pex ON (we.parent_workflow_workflow_execution_id = pex.id) LEFT JOIN workflow_version pexv ON (pex.workflow_version_id = pexv.id) LEFT JOIN workflow pw ON (pexv.workflow_workflow_id = pw.id) WHERE awse.date_created BETWEEN '${startTime}' AND '${endTime}') to '/reachengine/cmds/wfData/${currentDate}-NFL_Flows.csv' with (format csv, header);
EOF
)

  echo "$sql"
}

function buildStockSQLOne
{

local startTime="${currentDate} ${startHours}"
local endTime="${currentDate} ${midHours}"

local sql=$(cat <<EOF
\COPY (select v.execution_label_expression, avg(e.date_updated - e.date_created) as avg_duration, count(e.workflow_version_id) from workflow_execution e inner join workflow_version v on e.workflow_version_id=v.id where e.date_created between '${startTime}' and '${endTime}' group by v.execution_label_expression) to '/reachengine/cmds/wfData/${currentDate}-workflows.csv' with csv header;
EOF
)

  echo "$sql"
}

function buildStockSQLTwo
{

local startTime="${currentDate} ${startHours}"
local endTime="${currentDate} ${midHours}"

local sql=$(cat <<EOF
\COPY (select (date_updated - date_created) as duration, execution_label, date_created, date_updated, status from workflow_execution where date_created between '${startTime}' and '${endTime}' order by duration desc) to '/reachengine/cmds/wfData/${currentDate}-executions.csv' with csv header;
EOF
)

  echo "$sql"
}

function buildStockSQLThree
{

local startTime="${currentDate} ${startHours}"
local endTime="${currentDate} ${midHours}"

local sql=$(cat <<EOF
\COPY (SELECT a.hour, COALESCE(a.size, 0) AS assets, COALESCE(timeline.size, 0) AS timelines, COALESCE(marker.size, 0) AS markers, COALESCE(clip.size, 0) AS clips FROM (select date_part('hour', date_created) AS hour, COUNT(1) AS size FROM asset WHERE master_asset_asset_master_id is null AND date_created BETWEEN '${startTime}' AND '${endTime}' GROUP BY date_part('hour', date_created)) a LEFT OUTER JOIN (SELECT date_part('hour', date_created) AS hour, COUNT(1) AS size FROM timeline_segment where inventory_type = 'timeline' and date_created BETWEEN '${startTime}' AND '${endTime}' GROUP BY date_part('hour', date_created)) timeline	ON a.hour=timeline.hour	LEFT OUTER JOIN (SELECT date_part('hour', date_created) AS hour, COUNT(1) AS size FROM timeline_segment where inventory_type = 'marker' and date_created BETWEEN '${startTime}' AND '${endTime}' GROUP BY date_part('hour', date_created)) marker	ON a.hour=marker.hour	LEFT OUTER JOIN (SELECT date_part('hour', date_created) AS hour, COUNT(1) AS size FROM timeline_segment where inventory_type = 'clip' and date_created BETWEEN '${startTime}' AND '${endTime}' GROUP BY date_part('hour', date_created)) clip	ON a.hour=clip.hour	LEFT OUTER JOIN (SELECT date_part('hour', date_created) AS hour, COUNT(1) AS size FROM asset_collection where date_created BETWEEN '${startTime}' AND '${endTime}' GROUP BY date_part('hour', date_created)) collection	ON a.hour=collection.hour) to '/reachengine/cmds/wfData/${currentDate}-NFL-Diagnostics.csv' with (format csv, header);
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

local attachmentOne="/reachengine/cmds/wfData/${currentDate}-executions.csv"
local attachmentTwo="/reachengine/cmds/wfData/${currentDate}-workflows.csv"

   echo "Have some data :)" | mailx -s "NFL Workflow Data" -a "${attachmentOne}" -a "${attachmentTwo}" "${emailList}"

}

function cleanup
{

local reportFileOne="/reachengine/cmds/wfData/${currentDate}-NHL_Flows.csv"
local reportFileTwo="/reachengine/cmds/wfData/${currentDate}-NHLworkflows.csv"
local reportFileThree="/reachengine/cmds/wfData/${currentDate}-NHLexecutions.csv"

#Commented this out until I can get the mail command working
#  rm -f $reportFileOne
#  rm -f $reportFileTwo
#  rm -f $reportFileThree

  rm -f $sqlFile

}

#sql=$(buildSQL)
#sqlFile=/reachengine/cmds/wfData/sql.sql
#  touch $sqlFile
#  echo "$sql" > "$sqlFile"

#runSQL
#cleanup

sql=$(buildStockSQLOne)
sqlFile=/reachengine/cmds/wfData/sql.sql
  touch $sqlFile
  echo "$sql" > "$sqlFile"

runSQL
cleanup

sql=$(buildStockSQLTwo)
sqlFile=/reachengine/cmds/wfData/sql.sql
  touch $sqlFile
  echo "$sql" > "$sqlFile"

runSQL
cleanup

sql=$(buildStockSQLThree)
sqlFile=/reachengine/cmds/wfData/sql.sql
  touch $sqlFile
  echo "$sql" > "$sqlFile"

runSQL
cleanup

#mailReport --Unable to run due to filesize limitation of mailx
