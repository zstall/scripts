#!/bin/sh

echo "Enter text for Metadata Field Option that will be fixed (ex: Human): "
read fieldOption
echo "Select an Option [1, 2, 3]
        1. Check number of assets to be updated [1]
        2. Check field option [2]
        3. Update assets to undeleted field option [3]
        4. quit [q]"
read selectOption
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

function cleanUpFieldOptions()
{
    local sqlUpdate="
    UPDATE matadata_stored_data
    SET metadata_field_option_id = (
            SELECT id
            FROM metadata_field_option
            WHERE text = '$1'
            AND deleted = false
            ORDER BY date_created DESC
            limit 1
    ) WHERE metadata_field_id = (
            SELECT metadata_field_id
            FROM metadata_field_option
            WHERE text = '$1'
            AND deleted = 'false'
    ) AND metadata_field_option_id = (
            SELECT id
            FROM metadata_field_option
            WHERE text = '$1'
            AND deleted = 'true'
    ) AND asset_id in (
            SELECT asset_id
            FROM metadata_stored_data
            WHERE metadata_field_option_id = (
                SELECT id
                FROM metadata_field_option
                WHERE text = '$1'
                AND deleted = 'true'
        ) AND deleted = false);"

    echo ${sqlUpdate}
    assetUpdated=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlUpdate}")

}

function getNumberOfAssets() {
    local sqlSelect="
    SELECT count(asset_id)
    FROM metadata_stored_data
    WHERE metadata_field_id = (
            SELECT metadata_field_id
            FROM metadata_field_option
            WHERE text = '$1'
            AND deleted = 'false'
            ORDER BY date_created DESC limit 1
    ) AND metadata_field_option_id = (
            SELECT id
            FROM metadata_field_option
            WHERE text = '$1'
            AND deleted = 'true'
    ) AND asset_id in (
            SELECT asset_id
            FROM metadata_stored_data
            WHERE metadata_field_option_id = (
                    SELECT id
                    FROM metadata_field_option
                    WHERE text = '$1'
                    AND deleted = 'true'
        ) AND deleted = false);
    "
    echo ${sqlSelect}
    assetNum=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")
}

function checkOption() {
    local sqlSelect="
    SELECT text, deleted, id
    FROM metadata_field_option
    WHERE text = '$1';
    "
    echo ${sqlSelect}
    checkOption=$(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -t -c "${sqlSelect}")

}

## Configuration Params ##
setParams

PGPASSSTRING=${PGHOST}:${PGPORT}:${PGDB}:${PGUSER}:${PGPASS}
#echo ${PGPASSSTRING}

setPGPass "$PGPASSSTRING"

if [ "$selectOption" -eq "1" ];then
        getNumberOfAssets "$fieldOption";
        echo "The number of assets that need to be updated it: ${assetNum}"

elif [ "$selectOption" -eq "2" ];then
        checkOption "$fieldOption";
        echo "Field Option output is: ${checkOption}"

elif [ "$selectOption" -eq "3" ];then
        cleanUpFieldOptions "$fieldOption";
        echo "Number of Assets Updated:" 
        echo "${assetUpdated}"

elif [ "$selectOption" -eq "q" ];then
        echo "Exiting script"
fi