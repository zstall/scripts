#!/bin/bash

logDir=/reachengine/tomcat/logs/

reachLogs=Reach-Engine.log*
catLogs=catalina.out

localhostAccess=localhost_access_log.
localhostAccessNew=`date +%Y-%m-%d`
localhostAccessOld=`date +%Y-%m-%d -d "1 day ago"`
localhostAccessNewLog=${localhostAccess}$localhostAccessNew.txt
localhostAccessOldLog=${localhostAccess}$localhostAccessOld.txt

crashDirInit=/reachengine/tomcat/logs/crashReport
timestamp=`date +%Y-%m-%d_%H`

crashDir=${crashDirInit}/$timestamp
crashTar=$timestamp.tar.gz
crashDirTar=${crashDir}/$timestamp.tar.gz
reachLogDir=${crashDir}/reachLogs
catLogDir=${crashDir}/catLog
localhostLogDir=${crashDir}/localhostLog

isRoot=$(id -u)
if [[ isRoot -gt 0 ]]; then
     echo "Not the root user. Re-run using sudo."
     exit 0
fi

mkdir -p "$crashDir"
mkdir -p "$reachLogDir"
mkdir -p "$catLogDir"
mkdir -p "$localhostLogDir"


cp ${logDir}${reachLogs} ${reachLogDir}
cp ${logDir}${catLogs} ${catLogDir}
cp ${logDir}${localhostAccessNewLog} ${localhostLogDir}
cp ${logDir}${localhostAccessOldLog} ${localhostLogDir}
cp ${logDir}gc.log ${crashDir}


grep "Full GC" /reachengine/tomcat/logs/gc.log | awk '{print $1}' | awk -FT '{print $1}'| uniq -c > ${crashDir}/fullGcOutput.txt
free -m > ${crashDir}/freeMemOutput.txt
df -h > ${crashDir}/diskUsageOutput.txt
uptime > ${crashDir}/uptimeOutput.txt
w > ${crashDir}/wOutput.txt
ps -aux > ${crashDir}/psAuxOutput.txt
tail -n 100 /var/log/messages > ${crashDir}/varLogMessages.txt


chown -R reachengine:reachengine ${crashDir}

touch ${crashDirTar}

#sleep 10 #In place to ensure TAR success
tar --exclude=${crashDirTar} -czf ${crashDirTar} ${crashDir}
#sleep 10 #In place to ensure TAR success

chown -R reachengine:reachengine ${crashDirInit}

mv ${crashDirTar} /tmp/
chown -R reachengine:reachengine /tmp/${timestamp}*

rm -rf ${crashDirInit}

echo PLEASE PULL DOWN THE /tmp/$timestamp.tar.gz FILE AND SEND IT TO LEVELS BEYOND SUPPORT!

exit
