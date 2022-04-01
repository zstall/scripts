#!/bin/bash

##Set PSQL Connection String
function setParams()
{
    local rootFile=/reachengine/tomcat/conf/Catalina/localhost/ROOT.xml

      PGHOST=$(cat $rootFile | grep -m 1 'jdbcUrl' | cut -d ":" -f 3 | cut -c3-100)
      PGPORT=$(cat $rootFile | grep -m 1 'jdbcUrl' | cut -d "/" -f 3 | cut -d ":" -f 2)
      PGDB=$(cat $rootFile | grep -m 1 'jdbcUrl' | cut -d "/" -f 4 | cut -d "?" -f 1)
      PGUSER=$(cat $rootFile | grep -m 1 'dataSource.user' | cut -d '"' -f 2)
      PGPASS=$(cat $rootFile | grep -m 1 'dataSource.password' | cut -d '"' -f 2)
}

##Add PSQL Connection String in .pgpass
function appendToPGPass()
{
    grep -qxF ${1} ~/.pgpass || echo ${1} >> ~/.pgpass
}

##Determine RE Version
function findVersion()
{
   local FILE=/reachengine/tomcat/webapps/ROOT/META-INF/maven/com.levelsbeyond.re-studio/re-studio-server/pom.properties
    if test -f "$FILE"; then
        twothree=true
        :
    else
        twothree=false
    fi

   echo ${twothree}
}

##Formatting Lines
function lineBreak()
{
    for i in $( eval echo {0..$1} )
    do
      echo -n "_"
    done
}

##Get list of subflows from the a parent // LISTOFWFS
function getListOfSubflows()
{

    local SqlSelect="SELECT DISTINCT id FROM"
    local RelName="workflow_execution"
    local WhereClause="WHERE parent_workflow_workflow_execution_id = ${1} AND status != 'COMPLETED';"

    local query="${SqlSelect} ${RelName} ${WhereClause}"
      #echo ${query}

    psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${query}"
}

##Get list of workflow steps from a set of subflows // LISTOFSTEPS
function getListOfSteps()
{

    local SqlSelect="SELECT DISTINCT id FROM"
    local RelName="abstract_workflow_step_execution"
    local WhereClause="WHERE workflow_workflow_execution_id = ${1} AND status != 'COMPLETED';"

    local query="${SqlSelect} ${RelName} ${WhereClause}"
      #echo ${query}

    psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${query}"
}

##Abandon Workflows
function abandonFlows()
{
    local SqlUpdate="UPDATE workflow_execution SET status = 'ABANDONED'"
    local WhereClause="WHERE id = ${1};"

    local query="${SqlUpdate} ${WhereClause}"
      #echo ${query}

    psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${query}"
}

##Abandon Steps
function abandonSteps()
{
    local SqlUpdate="UPDATE abstract_workflow_step_execution SET status = 'ABANDONED'"
    local WhereClause="WHERE id = ${1};"

    local query="${SqlUpdate} ${WhereClause}"
      #echo ${query}

    psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${query}"
}

##Flush steps from queues 2.7+
function flushQueuesNew()
{
  local sqlDelete="DELETE FROM"
  local relName="workflow_queue_step_execution"
  local whereClause="WHERE step_execution_id = ${1}"

  local query="${sqlDelete} ${relName} ${whereClause}"
  #echo ${query}

  queuedStepsRemoved=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${query}")
}

##Flush steps from queues 2.3.X
function flushQueuesOld()
{
    local sqlDelete="DELETE FROM"
    local relName="workflow_queue_step"
    local whereClause="WHERE step_id = ${1}"

    local query="${sqlDelete} ${relName} ${whereClause}"
    #echo ${query}

    queuedStepsRemoved=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${query}")
}

##Loop through both functions until no additional subflows are found // LISTOFWFS and LISTOFSTEPS are complete
function looper()
{
    local NEXT="${parentID}" #NEXT array contains WF Executions to abandon and parse in the next loop
    local count=1

    echo "Finding all Workflows and Workflow Steps to Abandon for Parent Workflow ID: ${parentID}"
      lineBreak "82"
    echo && echo

    while :
    do
      for flow in $NEXT
      do
      local TEMPSTEPS+=$(getListOfSteps ${flow}) ##Set the list of WF Steps to a temp array
  for i in "${TEMPSTEPS[@]}";
          do
            if [ -z "${i// }" ]; then
              unset TEMPSTEPS ##If array only has 1 value and it's null, clear it.
            fi
          done

        echo "Workflow Step IDs found to Abandon:"
        printf '%s\n' "${TEMPSTEPS[@]}"
        local TEMPWFS+=$(getListOfSubflows ${flow}) ##et this list of WF Subflows to a temp array
          for i in "${TEMPWFS[@]}";
          do
            if [ -z "${i// }" ]; then
              unset TEMPWFS ##If array only has 1 value and it's null, clear it.
            fi
          done

        echo "Subflow IDs found to Abandon & Parse for additional Workflows and Steps:"
        printf '%s\n' "${TEMPWFS[@]}" 
      done

      if [[ ${#TEMPSTEPS[@]} -gt 0 && ${#TEMPWFS[@]} -gt 0 ]]; then ##Found both steps and subflows
        LISTOFSTEPS+=( ${TEMPSTEPS} )
        LISTOFWFS+=( ${TEMPWFS} )
        NEXT=${TEMPWFS}
          unset TEMPWFS
          unset TEMPSTEPS

      elif [[ ${#TEMPSTEPS[@]} -eq 0 && ${#TEMPWFS[@]} -gt 0 ]]; then #Found only subflows
        LISTOFWFS+=( ${TEMPWFS} )
        NEXT=( ${TEMPWFS} )
          unset TEMPWFS
          unset TEMPSTEPS

      elif [[ ${#TEMPSTEPS[@]} -gt 0 && ${#TEMPWFS[@]} -eq 0 ]]; then #Found only steps
        LISTOFSTEPS+=( ${TEMPSTEPS} )
          unset NEXT
          unset TEMPSTEPS
          unset TEMPWFS

      elif [[ ${#NEXT[@]} -eq 0 ]]; then #Nothing left to parse, end loop
        LISTOFWFS+=( ${parentID} )
          echo "Found all workflows and steps"
            lineBreak "71"
          echo && echo
            break;
      fi

      echo
      echo "Loop ${count} complete. Parsing additional subflows if applicable."
      echo && echo && echo
      count=$((count+1))

    done
}

echo && echo

parentID=$1

##Configure PSQL Connection
setParams
PGPASSSTRING=${PGHOST}:${PGPORT}:${PGDB}:${PGUSER}:${PGPASS}
appendToPGPass "$PGPASSSTRING"


##Main function to loop through and find all necessary Workflows and Steps to Abandon
looper

##Loop through each array of Workflows and Steps and send them to the Abandon functions

flowCount=${#LISTOFWFS[@]}
  echo "There are $flowCount Workflows to Abandon"
    for i in ${LISTOFWFS[@]}
    do
      abandonFlows $i
        echo "Workflow Execution ID $i has been set to Abandoned"
    done
  echo

stepCount=${#LISTOFSTEPS[@]}
  echo "There are $stepCount Workflow Steps to Abandon"
    for i in ${LISTOFSTEPS[@]}
    do
      abandonSteps $i
      echo "Workflow Step ID: $i has been set to Abandoned"
    done

echo
echo "Abandoned all necessary Workflows and Workflow Steps!"
lineBreak "71"
echo && echo 

##Remove all Workflow Steps from queues

twothree=$(findVersion)
  if ${twothree}; then
    echo "Flushing out workflow queues of any steps abandoned above.."
    echo
      for i in ${LISTOFSTEPS[@]}
      do
        flushQueuesOld $i
          echo "Workflow Step ID: $i has been removed from queue, if applicable."
      done
    echo
    echo "Flushed ${stepCount} workflow steps from queues!"
    echo
 else
    echo "Flushing out workflow queues of any steps abandoned above.."
    echo
      for i in ${LISTOFSTEPS[@]}
      do
        flushQueuesNew $i
          echo "Workflow Step ID: $i has been removed from queue, if applicable."
      done
    echo
    echo "Flushed ${stepCount} workflow steps from queues!"
    echo
 fi
