#!/bin/sh

# Script to gather metadata form stats for product
# This script will give the user the option to select a 2.3.x or newer system,
# and add a client name
# LevelsBeyond - Zach Stall
# 14 July 2021

##################################################################################
## FUNCTIONS FOR SCRIPT ##
##################################################################################

# Options for User
function getUserInput()
{
    echo "Select an option below:"
    echo "
    1. 2.3.x System -> Get metadata form data [1]
    2. 2.7.x or higher -> Get metadata form data [2]
    3. quit [q]"

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

#Function to get data from 2.3.x system
function twoThreeGetData()
{    
    # psql commands to create table of assets with dup metadata fields
    # each query below targets a seperate type of metadata field
    local sqlQueryMetadataFieldsPerForm="SELECT form.name AS form_name, string_agg(field.name, ', ') AS metadata_field_name FROM ingest_form_data_object form INNER JOIN ingest_form_metadata_property_data_object formProperty ON form.id = formProperty.form_ingest_form_data_object_id INNER JOIN metadata_field field ON field.id = formProperty.property_id GROUP BY 1 ORDER BY form.name ASC"

    local sqlQueryMetadataFieldPerMetadataGroup="SELECT grp.name AS group_name, string_agg(field.name, ', ') AS metadata_field_name FROM metadata_group grp INNER JOIN metadata_group_field groupField ON grp.id = groupField.metadata_group_id INNER JOIN metadata_field field ON groupField.metadata_field_id = field.id GROUP BY 1 ORDER BY grp.name ASC"

    local sqlQueryAllGroupMemebersByMetadatGroup="SELECT mg.name as group_name, string_agg(su.user_name, ', ') FROM security_user su INNER JOIN security_user_security_role susr ON su.id = susr.security_user_id INNER JOIN security_role_permission_context srpc ON srpc.security_role_id = susr.security_role_id INNER JOIN metadata_group mg ON mg.id = srpc.data_object_id GROUP BY 1"

    local sqlQueryMetadataFormMembers="select ifdo.name as form_name, string_agg(su.user_name, ', ') as user_name from ingest_form_data_object ifdo inner join security_role_ingest_form_data_object srif on ifdo.id = srif.ingest_form_data_object_id inner join security_role sr on srif.security_role_id = sr.id inner join security_role_security_user srsu on srsu.security_role_id = sr.id inner join security_user su on su.id = srsu.security_user_id group by 1"
    
    # Run commands to generate tables
    echo "Running Commands to Create Dir /tmp/$1"
    mkdir /tmp/$1
    echo && echo
    echo "Running PSQL commands to copy data to /tmp/$1"
    echo 'COMMAND: ' ${sqlQueryMetadataFieldsPerForm}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryMetadataFieldsPerForm}) to '/tmp/$1/Metadata_Fields_Per_Form.csv' with csv header")
    echo 
    echo 'COMMAND: ' ${sqlQueryMetadataFieldPerMetadataGroup}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryMetadataFieldPerMetadataGroup}) to '/tmp/$1/Metadata_Field_Per_Metadata_Group.csv' with csv header")
    echo
    echo 'COMMAND: ' ${sqlQueryAllGroupMemebersByMetadatGroup}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryAllGroupMemebersByMetadatGroup}) to '/tmp/$1/All_Group_Memebers_by_Metadat_Group.csv' with csv header")
    echo
    echo 'COMMAND: ' ${sqlQueryMetadataFormMembers}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryMetadataFormMembers}) to '/tmp/$1/Metadata_Form_Members.csv' with csv header")
    echo
    echo "Taring up temp file, and placing it in directory where script is run"
    tar -cvf $1.tar.gz /tmp/$1/
    echo "Directory complete. SCP down $1.tar.gz"
    echo "Removing direcotry in temp"
    rm -rf /tmp/$1

}

#Function to get data from 2.7.x+ system
function twoSevenPlusData()
{    
    # psql commands to create table of assets with dup metadata fields
    # each query below targets a seperate type of metadata field
    local sqlQueryMetadataFieldsPerForm="SELECT form.name AS form_name, string_agg(field.name, ', ') AS metadata_field_name FROM ingest_form_data_object form INNER JOIN ingest_form_metadata_property_data_object formProperty ON form.id = formProperty.form_ingest_form_data_object_id INNER JOIN metadata_field field ON field.id = formProperty.property_id GROUP BY 1 ORDER BY form.name ASC"

    local sqlQueryMetadataFieldPerMetadataGroup="SELECT grp.name AS group_name, string_agg(field.name, ', ') AS metadata_field_name FROM metadata_group grp INNER JOIN metadata_group_field groupField ON grp.id = groupField.metadata_group_id INNER JOIN metadata_field field ON groupField.metadata_field_id = field.id GROUP BY 1 ORDER BY grp.name ASC"

    local sqlQueryAllGroupMemebersByMetadatGroup="SELECT mg.name as group_name, string_agg(su.user_name, ', ') FROM security_user su INNER JOIN security_user_security_role susr ON su.id = susr.security_user_id INNER JOIN security_role_permission_context srpc ON srpc.security_role_id = susr.security_role_id INNER JOIN metadata_group mg ON mg.id = srpc.data_object_id GROUP BY 1"

    local sqlQueryMetadataFormMembers="SELECT ifdo.name as form_name, string_agg(su.user_name, ', ') as user_name FROM ingest_form_data_object ifdo INNER JOIN ingest_form_data_object_security_role ifdosr on ifdo.id = ifdosr.ingest_form_data_object_id INNER JOIN security_user_security_role susr on ifdosr.security_role_id = susr.security_role_id INNER JOIN security_user su on susr.security_user_id = su.id group by 1"
    
    # Run commands to generate tables
    echo "Running Commands to Create Dir /tmp/$1"
    mkdir /tmp/$1
    echo && echo
    echo "Running PSQL commands to copy data to /tmp/$1"
    echo 'COMMAND: ' ${sqlQueryMetadataFieldsPerForm}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryMetadataFieldsPerForm}) to '/tmp/$1/Metadata_Fields_Per_Form.csv' with csv header")
    echo 
    echo 'COMMAND: ' ${sqlQueryMetadataFieldPerMetadataGroup}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryMetadataFieldPerMetadataGroup}) to '/tmp/$1/Metadata_Field_Per_Metadata_Group.csv' with csv header")
    echo
    echo 'COMMAND: ' ${sqlQueryAllGroupMemebersByMetadatGroup}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryAllGroupMemebersByMetadatGroup}) to '/tmp/$1/All_Group_Memebers_by_Metadat_Group.csv' with csv header")
    echo
    echo 'COMMAND: ' ${sqlQueryMetadataFormMembers}
    echo $(psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER} -c "\copy (${sqlQueryMetadataFormMembers}) to '/tmp/$1/Metadata_Form_Members.csv' with csv header")
    echo
    echo "Taring up temp file, and placing it in directory where script is run"
    tar -cvf $1.tar.gz /tmp/$1/
    echo "Directory complete. SCP down $1.tar.gz"
    echo "Removing direcotry in temp"
    rm -rf /tmp/$1

}

#####################################################################################################################
## END FUNCTIONS ##
#####################################################################################################################
## START SCRIPT ##
#####################################################################################################################

## Configuration Params ##
setParams
PGPASSSTRING=${PGHOST}:${PGPORT}:${PGDB}:${PGUSER}:${PGPASS}
#echo ${PGPASSSTRING}
setPGPass "$PGPASSSTRING"

while [[ "$selectOption" != "q" ]]
do

    if [[ "$selectOption" -eq 1 ]];then
        echo "Enter Client Name: "
        read clientName
	    twoThreeGetData "$clientName";
        echo && echo
        echo "Done, exiting script"
        selectOption="q"
        
    elif [[ "$selectOption" -eq 2 ]];then
        echo "Enter Client Name: "
        read clientName
	    twoSevenPlusData "$clientName";
        echo && echo
        echo "Done, exiting script"
        selectOption="q"

    else 
        getUserInput;

    fi

done

echo "Exiting Script"
#####################################################################################################################
## END SCRIPT ##
#####################################################################################################################
