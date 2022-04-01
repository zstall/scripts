#!/bin/sh

# Script to cleanup metadata stored data that has duplicate entries
# This script will give the user the option to view the effected assets list,
# and remove duplicates
#LevelsBeyond - Zach Stall
#26 June 2021

##################################################################################
## FUNCTIONS FOR SCRIPT ##
##################################################################################

# Options for User
function getUserInput()
{
    echo "Select an option below:"
    echo "**NOTE** Must Get Fields to Cleanup (option 2) before this script will cleanup any fields **NOTE**"
    echo "
    1. Check List of Metadata Fields for Cleanup [1]
    2. Get Fields to Cleanup [2]
    3. Cleanup Assets [3]
    4. quit [q]"

read selectOption
echo
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

# Prints the list of metadata fiels to be cleaned up.
# The fields array is defined below manually in the script
function printMetadataFields()
{
    echo
    for i in "${fields[@]}"; do echo "$i"; done
    echo
}

# Create a temp table of MetadataFields with a dup metadata stored data
# This temporary table is necisarry to get the list of metadata fields to add to the array for cleanup
function buildDupArray()
{    
    # psql commands to create table of assets with dup metadata fields
    # each query below targets a seperate type of metadata field
    local sqlTable1="
    SELECT
        d.asset_id, 
        d.asset_type,
        f.id as field_id,
        count(d.id) as data_count
    INTO TABLE 
        metadata_field_dups
    FROM
        metadata_field AS f
    INNER JOIN 
        metadata_field_option AS o ON o.metadata_field_id = f.id
    INNER JOIN 
        metadata_stored_data AS d ON d.metadata_field_id = f.id AND d.metadata_field_option_id = o.id
    WHERE
        f.list = true AND f.multi = false AND f.deleted = false AND f.archived_flag = false
    AND o.deleted = false
    AND d.deleted = false
    GROUP BY d.asset_id, d.asset_type, f.id
    HAVING count(d.id) > 1
    ORDER BY d.asset_type, d.asset_id, f.id;
    "

    local sqlTable2="
    SELECT
        d.asset_id, 
        d.asset_type,
        f.id as field_id,
        o.id as option_id,
        count(d.id) as data_count
    INTO TABLE 
        metadata_field_dups
    FROM
        metadata_field AS f
    INNER JOIN
        metadata_field_option AS o ON o.metadata_field_id = f.id
    INNER JOIN
        metadata_stored_data AS d ON d.metadata_field_id = f.id AND d.metadata_field_option_id = o.id
    WHERE
        f.list = true AND f.multi = true AND f.deleted = false AND f.archived_flag = false
    AND o.deleted = false
    AND d.deleted = false
    GROUP BY d.asset_id, d.asset_type, f.id, o.id
    HAVING count(d.id) > 1
    ORDER BY d.asset_type, d.asset_id, f.id, o.id;
    "
    
    local sqlTable3="
    SELECT
        d.asset_id, 
        d.asset_type, 
        f.id as field_id,
        count(d.id) as data_count
    INTO TABLE 
        metadata_field_dups
    FROM
        metadata_field AS f
    INNER JOIN metadata_stored_data AS d ON d.metadata_field_id = f.id
    WHERE
        f.list = false AND f.deleted = false AND f.archived_flag = false
    AND d.deleted = false
    GROUP BY d.asset_id, d.asset_type, f.id
    HAVING count(d.id) > 1
    ORDER BY d.asset_type, d.asset_id, f.id;
    "
    
    # Run commands to generate tables
    echo 'Generating temp tables to create an array of dup metadata fields to be removed'
    echo && echo
    echo 'Generating single picklist table'
    echo 'COMMAND: ' ${sqlTable1}
    echo 'Generating Table:'  $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlTable1}")
    # this method will query the temp table and add the metadata fields to the master array fields
    queryTempTable;
    dropTable "metadata_field_dups";

    echo 'Generating multiple picklist table'
    echo 'COMMAND: ' ${sqlTable2}
    echo 'Generating Table:'  $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlTable2}")
    queryTempTable;
    dropTable "metadata_field_dups";

    echo 'Generating string metadata field table'
    echo 'COMMAND: ' ${sqlTable3}
    echo 'Generating Table:'  $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlTable3}")
    queryTempTable;
    dropTable "metadata_field_dups";

    echo && echo
    echo "testing metadata field:"
    # Show the user the newly generated metadata fields
    printMetadataFields;
    # Double check that the temp table has been removed
    dropTable "metadata_field_dups";

}

 


# Query temp table and generate a list of metadata fields
function queryTempTable()
{
    # psql command to create table of assets with dup metadata fields
    local sqlTable="
    SELECT 
        label 
    FROM 
        metadata_field 
    WHERE id IN (
        SELECT 
            DISTINCT field_id 
        FROM metadata_field_dups);
    "
    echo
    echo 'COMMAND: ' ${sqlTable}
    # Run command to generate table
        
    # Store the output from the query into a local array to be appended to master array fields
    local dbArray=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlTable}")
    
    # Add the metadata fields to the master array fields
    for i in "${dbArray[@]}"; do 
        for j in "${i[@}]}": do 
            fields+=("$j"); 
        done
    done
}



# Create a temp table of assets with a dup metadata field
# This temporary table is necisarry to get the list of assets grouped by asset_id, metadata_field, and metadata_field_option_id.
# Once this table is created, the script now has a table of asset_ids that have duplicate metadata_fields to work from.
function buildDupMetadataEntriesTable()
{
    # psql command to create table of assets with dup metadata fields
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
    echo 'Generating temp table dup_metadata_entries'
    echo 'COMMAND: ' ${sqlTable}
    # Run command to generate table
    echo 'NUMBER OF ASSETS WITH DUPS:'  $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlTable}")
}


# Create a temp table get unique metadata_store_date ids and eliminate the duplicate
# This table uses the dup_metadata_entries temp table and the metadata field id to generate a list of distinct asset_ids and 
# the corresponsing metadata_stored_date id. This allows the script to have a list of duplicated metadata stored data ids
# to run a delete on.
function buidToDeleteTable()
{
    # psql command to create table of unique asset ids and there metadata_stored_data ids.
    local sqlTable="
        SELECT
            distinct on (asset_id) asset_id, 
            id as metadata_stored_data_id
        INTO TABLE to_delete 
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
    echo 'Generating temp table to_delete'
    echo 'COMMAND: ' ${sqlTable}
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

# Function to drop the "temp" tables
function dropTable()
{
    local sqlDrop="DROP TABLE IF EXISTS $1"
    echo 'ATTEMPTING TO DROP TEMP TABLE' $1':' $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlDrop}")
}


# Print the number of assets effected, and needing to be fixed.
function numberOfAssets()
{
    local sqlDrop="DROP TABLE dup_metadata_entries;"
    for i in "${fields[@]}"
    do
        # Build a dup metadata field entries table to generate the number of assets remaining with duplicates MF's
        buildDupMetadataEntriesTable "$i";

        echo 'COMMAND: ' ${sqlDrop}
        echo 'TABLE DROPPED: ' $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "${sqlDrop}")

    done
}

# Delete Duplicated Metadata Field Options
# This function generates the duplicate tables, and then removes the duplicates, and cleans up the temp tables
function cleanUpDups()
{
    local sqlSelect="SELECT COUNT(asset_id) from dup_metadata_entries;"
    # for loop to workf through each MF in fields array with duplicate MF's
    for i in "${fields[@]}"
    do
        # Build the dup table for the i entry in the array, the script will loop through this 
        # metadata field until all duplicates are deleted.
        echo "DROPPING dup_metadata_entries IF IT EXISTS"
        dropTable "dup_metadata_entries";
        buildDupMetadataEntriesTable "$i";
	    echo && echo
        # Check that there are dups left, if they are continue looping
        num=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")
        while [[ $num -gt 0 ]]
        do
            # Build temp table to get dup metadata stored data ids
            buidToDeleteTable "$i";
	        echo && echo
            # Delete dups
            deleteDups;
            echo && echo
            # Drop temp tables that have had the duplicate MF's deleted
            dropTable "to_delete";
            dropTable "dup_metadata_entries";
            echo && echo
            # Check for assets that have more than just one duplicate MF
            buildDupMetadataEntriesTable "$i";
            # if num is greater than 0, continue while loop on current MF until all are cleaned
            # if num is 0, exit while loop and move onto next MF group
            num=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")
	        echo && echo
        done
    done
    # When while and for loops are done, ensure all temp tables are removed if they exist
    dropTable "to_delete";
    dropTable "dup_metadata_entries";

}

#####################################################################################################################
## END FUNCTIONS ##
#####################################################################################################################
## START SCRIPT ##
#####################################################################################################################

# to be loaded up with all Metadata Fields needing fixed
# NOTE: in bash arrays, NO COMMAS. This will break the script. 
fields=()
## Configuration Params ##
setParams
PGPASSSTRING=${PGHOST}:${PGPORT}:${PGDB}:${PGUSER}:${PGPASS}
#echo ${PGPASSSTRING}
setPGPass "$PGPASSSTRING"

while [[ "$selectOption" != "q" ]]
do

    if [[ "$selectOption" -eq 1 ]];then
        printMetadataFields;
	    getUserInput;
        
    elif [[ "$selectOption" -eq 2 ]];then
        buildDupArray;
	    getUserInput;

    elif [[ "$selectOption" -eq 3 ]];then
        cleanUpDups;
	    getUserInput;
    
    else 
        getUserInput;

    fi

done

echo "Exiting Script"
#####################################################################################################################
## END SCRIPT ##
#####################################################################################################################
