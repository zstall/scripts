#!/bin/bash

echo This script will get last name, first name, username, email, and role.
echo It will write the output of this to a csv called users_and_roles in the /tmp Directory
echo Press enter to start
read n
psql -U reachengine -d studio -c "\copy (select su.first_name, su.last_name, su.email_address, su.user_name, sr.role_name AS Role_Name, sr.id as Role_ID FROM security_user as su JOIN security_user_security_role as susr ON susr.security_user_id = su.id JOIN security_role as sr ON sr.id = susr.security_role_id order by 4) to /tmp/users_and_roles.csv with csv header;"
echo Done
