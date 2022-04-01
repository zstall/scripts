#!/bin/bash

user='reachengine'
db='studio'
psswd='levelsbeyond'
yes='yes'
t='t'

echo This script will enable you to check the current cron status and change the cron status for both the Weekly and Daily Archives

checkStatus () {
echo
echo
 weekly=$(psql -U $user -d $db -W $psswd -c "SELECT enabled_flag from workflow_cron_config where id = 280;")
 weekly=$(echo $weekly | cut -c29-30)
    if [ ${weekly} == ${t} ];then
      echo The Weekly Archive Cron is currently enabled.
    else
      echo The Weekly Archive Cron is currently disabled.
    fi

 daily=$(psql -U $user -d $db -W $psswd  -c "SELECT enabled_flag from workflow_cron_config where id = 280;")
 daily=$(echo $daily | cut -c29-30)
    if [ ${daily} == ${t} ];then
      echo The Daily Archive Cron is currently enabled.
    else
      echo The Daily Archive Cron is currently disabled.
    fi
echo
echo
}

checkStatus

echo Would you like to update the Weekly Archive Cron? Yes/No  && read changeWeekly
echo
  if [ ${changeWeekly} == ${yes} ];then
        echo Type ENABLE/DISABLE to change the status of the cron. && read ableWeekly
          if [ ${ableWeekly} == 'DISABLE' ];then
              psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = false where id = 280;"
            elif [ ${ableWeekly} == 'disable' ];then
              psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = false where id = 280;"
            elif [ ${ableWeekly} == 'ENABLE' ];then
              psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = true where id = 280;"
            elif [ ${ableWeekly} == 'enable' ];then
              psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = true where id = 280;"
          fi
  fi

checkStatus

echo Would you like to update the Daily Archive Cron? Yes/No  && read changeDaily
echo
 if [ ${changeDaily,,} == ${yes} ];then
        echo Type ENABLE/DISABLE to change the status of the cron. && read ableDaily
          if [ ${ableDaily} == 'DISABLE' ];then
               psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = false where id = 280;"
            elif [ ${ableDaily} == 'disable' ];then
               psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = false where id = 280;"
            elif [ ${ableDaily} == 'ENABLE' ];then
              psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = true where id = 280;"
            elif [ ${ableDaily} == 'enable' ];then
              psql -U $user -d $db -W $psswd  -c "UPDATE workflow_cron_config set enabled_flag = true where id = 280;"
          fi
  fi

checkStatus

exit