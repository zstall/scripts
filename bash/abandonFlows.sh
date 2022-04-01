#!/bin/bash

echo "Enter the timestamp to abandon all flows before that timestamp -- ex. 2020-12-17 02:28"
read timestamp
echo && echo

function setParams()
{
    local rootFile=/reachengine/tomcat/conf/Catalina/localhost/ROOT.xml

	PGHOST=$(cat $rootFile | grep -m 1 'jdbcUrl' | cut -d ":" -f 3 | cut -c3-100)
	PGPORT=$(cat $rootFile | grep -m 1 'jdbcUrl' | cut -d "/" -f 3 | cut -d ":" -f 2)
	PGDB=$(cat $rootFile | grep -m 1 'jdbcUrl' | cut -d "/" -f 4 | cut -d "?" -f 1)
	PGUSER=$(cat $rootFile | grep -m 1 'dataSource.user' | cut -d '"' -f 2)
	PGPASS=$(cat $rootFile | grep -m 1 'dataSource.password' | cut -d '"' -f 2)
}

function setPGPass()
{
    grep -qxF ${1} ~/.pgpass || echo ${1} >> ~/.pgpass
    chmod 0600 ~/.pgpass
}

function createTempTable()
{

  local sqlCreate="CREATE TABLE abandon_me AS"
  local sqlSelect="SELECT id FROM"
  local relName="workflow_execution"
  local whereClause="WHERE date_created < '${timestamp}' AND status IN ('EXECUTING','QUEUED','CREATED','PAUSED');"

  #echo ${sqlCreate} ${sqlSelect} ${relName} ${whereClause}

  local ignore=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlCreate} ${sqlSelect} ${relName} ${whereClause}")

}

function updateWorkflows()
{

  local sqlUpdate="UPDATE"
  local relName="workflow_execution"
  local setClause="SET status = 'ABANDONED'"
  local whereClause="WHERE id IN (SELECT id FROM abandon_me);"

  #echo ${sqlUpdate} ${relName} ${setClause} ${whereClause}

  workflowsUpdated=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlUpdate} ${relName} ${setClause} ${whereClause}")
}

function updateSteps()
{

  local sqlUpdate="UPDATE"
  local relName="abstract_workflow_step_execution"
  local setClause="SET status = 'ABANDONED'"
  local whereClause="WHERE workflow_workflow_execution_id IN (SELECT id FROM abandon_me) AND status != 'COMPLETED';"

  #echo ${sqlUpdate} ${relName} ${setClause} ${whereClause}

  stepsUpdated=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlUpdate} ${relName} ${setClause} ${whereClause}")
}


function flushQueues()
{

  local sqlDelete="DELETE FROM"
  local relName="workflow_queue_step_execution"
  local whereClause="WHERE step_execution_id IN (SELECT id FROM abstract_workflow_step_execution WHERE workflow_workflow_execution_id IN (SELECT id FROM abandon_me))"

  #echo ${sqlDelete} ${relName} ${whereClause}

  queuedStepsRemoved=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlDelete} ${relName} ${whereClause}")
}

function cleanup()
{

    local sqlDrop="DROP TABLE abandon_me;"

    #echo ${sqlDrop}

    local ignore=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlDrop}")
}


## Configuration Params ##
setParams

PGPASSSTRING=${PGHOST}:${PGPORT}:${PGDB}:${PGUSER}:${PGPASS}
#echo ${PGPASSSTRING}

setPGPass "$PGPASSSTRING"


## Cleanup Workflows ##
echo "Creating temp table with workflows to cleanup.."
createTempTable
echo

echo "Updating workflows / subflows to abandoned.."
updateWorkflows
workflowsUpdated=$(echo ${workflowsUpdated} | cut -d ' ' -f 2)
echo "Updated ${workflowsUpdated} workflows / subflows to abandoned!"
echo

echo "Updating workflow steps within the workflows to abandoned.. (if not completed)"
updateSteps
stepsUpdated=$(echo ${stepsUpdated} | cut -d ' ' -f 2)
echo "Updated ${stepsUpdated} workflow steps to abandoned!"
echo

echo "Flushing out workflow queues of any steps abandoned above.."
flushQueues
queuedStepsRemoved=$(echo ${queuedStepsRemoved} | cut -d ' ' -f 2)
echo "Flushed ${queuedStepsRemoved} workflow steps from queues!"
echo

echo "Cleaning up and removing temp table.."
cleanup