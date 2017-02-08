#!/bin/bash

source /mongodb_env.sh

MYDATE=`date +%Y-%m-%d`
MONTH=$(date +%m)
YEAR=$(date +%Y)
HOUR=$(date +%H)
MINUTE=$(date +%M)
MYBASEDIR=/backups
MYBACKUPDIR=${MYBASEDIR}/${YEAR}/${MONTH}/${HOUR}${MINUTE}
mkdir -p ${MYBACKUPDIR}
cd ${MYBACKUPDIR}
ls -al

echo "[MONGO_BACKUP] Backup running to $MYBACKUPDIR" >> /var/log/cron.log
echo "[MONGO_BACKUP] Backing up DB $MONGODB_DATABASE_FROM on host $MONGODB_HOST"  >> /var/log/cron.log

mongodump -h $MONGODB_HOST -d $MONGODB_DATABASE_FROM >> /var/log/cron.log
if [ $? -ne 0 ]; then
  echo "[MONGO_BACKUP] Error: Failed to backup $MONGODB_DATABASE_FROM"
  exit 0
else
  echo "[MONGO_COPY] Copying DB $MONGODB_DATABASE_FROM on host $MONGODB_HOST to $MONGODB_DATABASE_TO"  >> /var/log/cron.log
  mongorestore -h $MONGODB_HOST -d $MONGODB_DATABASE_TO dump/${MONGODB_DATABASE_FROM} >> /var/log/cron.log
  if [ $? -ne 0 ]; then
    echo "[MONGO_COPY] Error: Failed to copy $MONGODB_DATABASE_FROM to $MONGODB_DATABASE_TO"
    exit 0
  fi
fi

FILENAME=${MYBACKUPDIR}/${MONGODB_DATABASE_FROM}.${MYDATE}.dump.tgz
tar -zcvf $FILENAME dump
rm -rf dump
