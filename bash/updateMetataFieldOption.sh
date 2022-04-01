#!/bin/sh

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
function setPGPass()
{
    grep -qxF ${1} ~/.pgpass || echo ${1} >> ~/.pgpass
    chmod 0600 ~/.pgpass
}

##Get the deleted metadata field option id's
function getMetaFieldOptions()
{
    local sqlSelect="
        SELECT id
        FROM metadata_field_option
        WHERE text = '$1'
        AND deleted = 'true'
        AND metadata_field_id = (
            SELECT id
            FROM metadata_field
            WHERE label = '$2'
        );
    "

    ##echo ${sqlSelect}
    optionIds=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")
}

##Check the number of assets to be updated based off the user input metadata field option text
function numAssetsUpdating()
{
    local sqlSelect="
        SELECT count(asset_id)
        FROM metadata_stored_data
        WHERE metadata_field_id = (
            SELECT distinct(metadata_field_id)
            FROM metadata_field_option
            WHERE text = '$1'
        ) AND metadata_field_option_id = $2
        AND asset_id in (
            SELECT asset_id
            FROM metadata_stored_data
            WHERE metadata_field_option_id = $2
        ) AND deleted = false;
    "

    ##echo ${sqlSelect}
    num=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")
}


##Update assets to undeleted (and newest) metadata field
function updateMetadataOption()
{
    local sqlUpdate="
        UPDATE metadata_stored_data
        SET metadata_field_option_id = (
            SELECT id
            FROM metadata_field_option
            WHERE text = '$1'
            AND deleted = false
            ORDER BY date_created DESC
            limit 1
        ) WHERE metadata_field_id = (
            SELECT distinct(metadata_field_id)
            FROM metadata_field_option
            WHERE text = '$1'
        ) AND metadata_field_option_id = $2
        AND asset_id in (
            SELECT asset_id
            FROM metadata_stored_data
            WHERE metadata_field_option_id = $2
        ) AND deleted = false;
    "
    echo "Updating all assets with metadata field option for text $1 with id: $2"
    numUpdated=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlUpdate}")
}

## Configuration Params ##
setParams
total=0

PGPASSSTRING=${PGHOST}:${PGPORT}:${PGDB}:${PGUSER}:${PGPASS}
#echo ${PGPASSSTRING}

setPGPass "$PGPASSSTRING"


##Get users text to be updated
echo "Enter text for Metadata Field Option that will be fixed (ex: Human): "
read fieldOption

echo "Enter label for Metadata Field to be updated (ex: Deliverable Title Name): "
read field

##Show the user how many MFO id's and assets could be updated for the given string
echo "Number of deleted metadata field options to be cleanup up for $fieldOption: "
getMetaFieldOptions "$fieldOption" "$field"
echo $optionIds

echo "Number of assets to be updated from id's above: "
for ids in $optionIds
do
    numAssetsUpdating "$fieldOption" "$ids"
    echo "For id $ids: $num"
    total=$(($total+$num))
done
echo && echo

##Check if the user wishes to proceed
echo "If you wish to proceed, type proceed: "
read userInput

if [ "$userInput" == "proceed" ];then

    for id in $optionIds
    do
        updateMetadataOption "$fieldOption" "$id"
        echo "Done: $numUpdated assets"
        echo && echo
    done
fi
echo "Number of assets updated: $total"