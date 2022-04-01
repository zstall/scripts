#!/bin/sh

# Script to cleanup metadata stored data that has duplicate entries
# This script will give the user the option to view the effected assets list,
# and remove duplicates
#LevelsBeyond - Zach Stall
#26 June 2021

# Options for User
function getUserInput()
{
    echo "Select an option below:
    1. Check List of Metadata Fields for Cleanup [1]
    2. Check for Number of Assets to be Fixed [2]
    3. Cleanup Assets [3]
    4. quit [q]"

read selectOption
echo && echo
}


# Get parameters to connect to DB
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

# Simply prints the list of metadata fiels to be cleaned up.
function printMetadataFields()
{
    for i in "${fields[@]}"
    do
        echo "Metadata Field:" $i
    done
}


# Create a temp table of dup assets to work from
function buildDupMetadataEntriesTable()
{
    local sqlTable="
    SELECT
        asset_id,
        asset_type,
        metadata_field_id,
        metadata_field_option_id,
        count(id) as number_of_dups
    INTO TABLE dup_metadata_entries
    FROM metadata_stored_data
    WHERE metadata_field_id IN (
        SELECT id
        FROM metadata_field
        WHERE label = '$1')
    AND deleted = false
    GROUP by 1,2,3,4 HAVING COUNT(id) > 1;
    "
    echo 'COMMAND:' ${sqlTable}
    echo 'NUMBER OF ASSETS WITH DUPS:'  $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlTable}")
}


# Create a temp table get unique metadata_store_date ids and eliminate the duplicate
function buidToDeleteTable()
{
    local sqlTable="
        SELECT
            distinct on (asset_id) asset_id, 
            id as metadata_stored_data_id
        INTO TEMP TABLE to_delete 
        FROM metadata_stored_data 
        WHERE asset_id IN (
            SELECT asset_id 
            FROM dup_metadata_entries) 
        AND metadata_field_id IN (
            SELECT id 
            FROM metadata_field 
            WHERE label = '$1')
        AND deleted = false
        ORDER by asset_id asc;
    "
    echo 'COMMAND:' ${sqlTable}
    echo 'NUMBER OF ASSETS WITH DUPS:'  $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlTable}")

}

# Function to delete the duplicate metadata fields generated in to_delete table
function deleteDups()
{
    local sqlDelete="
        DELETE FROM 
            metadata_stored_data 
        WHERE 
            id IN (
                SELECT 
                    metadata_stored_data_id 
                FROM 
                    to_delete);
    "
    echo 'COMMAND:' ${sqlDelete}
    echo 'NUMBER OF DUPS CLEANED UP:' $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlDelete}") 
}

function dropTable()
{
    local sqlDrop="DROP TABLE IF EXISTS $1"
    echo 'COMMAND:' $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlDrop}")
}


# Print the number of assets effected, and needing to be fixed.
function numberOfAssets()
{
    local sqlDrop="DROP TABLE dup_metadata_entries;"
    for i in "${fields[@]}"
    do
        buildDupMetadataEntriesTable "$i";

        echo 'COMMAND: ' ${sqlDrop}
        echo 'TABLE DROPPED: ' $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "${sqlDrop}")

    done
}

# Delete Duplicated Metadata Field Options
function cleanUpDups()
{
    local sqlSelect="SELECT COUNT(asset_id) from dup_metadata_entries;"
    for i in "${fields[@]}"
    do
        # Build the dup table for the i entry in the array, the script will loop through this 
        # metadata field until all duplicates are deleted.
        dropTable "dup_metadata_entries";
        buildDupMetadataEntriesTable "$i";
        # Check that there are dups left, if they are continue looping
        num=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")
        while [[ "$num" != 0 ]]
        do
            # Build temp table to get dup metadata stored data ids
            buidToDeleteTable "$i";
            # Delete dups
            deleteDups;
            # Drop temp tables that have been cleaned
            dropTable "to_delete";
            dropTable "dup_metadata_entries";

            # Check for assets that more than just one dup
            buildDupMetadataEntriesTable "$i";
            num=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")
        done
    done
    dropTable "to_delete";
    dropTable "dup_metadata_entries";

}

# to be loaded up with all Metadata Fields needing fixed
fields=( 'Wazee Owner' 'Video Quality' )

## Configuration Params ##
setParams
PGPASSSTRING=${PGHOST}:${PGPORT}:${PGDB}:${PGUSER}:${PGPASS}
#echo ${PGPASSSTRING}
setPGPass "$PGPASSSTRING"

while [[ "$selectOption" != 'q']]
do

    if [ "$selectOption" -eq "1" ];then
        printMetadataFields;
        
    elif [ "$selectOption" -eq "2" ];then
        numberOfAssets;

    elif [ "selectOption" -eq "3"];then
        cleanUpDups;
    
    elif getUserInput;

    fi

done