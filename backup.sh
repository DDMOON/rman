!/bin/bash
#================================
#=set_variable
#================================
source /home/oracle/.bash_profile
export ORACLE_SID=PROD
bdate=$(date +"%d_%m_%Y")
mkdir -pv /u03/backup/${ORACLE_SID}/${bdate}
tapedir=/u03/tape/${ORACLE_SID}
backupdir=/u03/backup/${ORACLE_SID}/${bdate}
logdir=/home/oracle/scripts/logs
rezserver=ip_address_rez_server
export bdate tapedir backupdir logdir rezserver
#=================================
#=show start time rman backup job
#=================================
echo "$(date +"%Y/%m/%d|%H:%M") :: start backup" >> ${logdir}/${ORACLE_SID}_backup_${bdate}.log
#================================
#=RMAN
#================================
rman target / log = ${logdir}/${ORACLE_SID}_backup_${bdate}.log append<<EOF
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${backupdir}/%F';
backup tag 'DB_${bdate}' FORMAT '${backupdir}/%d_DB_%u_%s_%p' as compressed backupset database plus archivelog tag 'ARCH_${bdate}' FORMAT '${backupdir}/%d_ARCH_%u_%s_%p';
delete noprompt obsolete;
exit
EOF
#=================================
#=show finish time rman backup job
#=================================
echo "$(date +"%Y/%m/%d|%H:%M") :: Finish backup" >> ${logdir}/${ORACLE_SID}_backup_${bdate}.log
#================================
#=create_links, chmod backup
#================================
find ${tapedir} -type l -exec rm -rv {} \;
find ${backupdir} -type f -exec chmod -v o+r {} \;
find ${backupdir} -type f -exec ln -vs {} ${tapedir} \;
#=================================
#=delete old dirs, archive old logs
#=================================
find /u03/backup/hot/${ORACLE_SID} -type d -empty -exec rm -rvf {} \;
find ${logdir} -maxdepth 1 -name "*.log" -type f -mtime +4 -exec mv -v {} ${logdir}/arch/ \;
find ${logdir}/arch/ -name "*.log" -type f -exec gzip -v {} \;
#=================================
#=scp_to_standby server
#=================================
rsync -avz --progress --ignore-existing /u03/tape/* ${rezserver}:/${tapedir}/
#=================================
#=show finish time rman backup job
#=================================
echo "$(date +"%Y/%m/%d|%H:%M") :: finish backup" >> ${logdir}/${ORACLE_SID}_backup_${bdate}.log
