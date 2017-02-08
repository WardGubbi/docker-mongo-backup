#!/bin/bash

source /mongodb_env.sh

MYDATE=`date +%Y-%m-%d`
MONTH=$(date +%m)
YEAR=$(date +%Y)
MYBASEDIR=/backups
MYBACKUPDIR=${MYBASEDIR}/${YEAR}/${MONTH}
mkdir -p ${MYBACKUPDIR}
cd ${MYBACKUPDIR}

echo "[MONGO_BACKUP] Backup running to $MYBACKUPDIR" >> /var/log/cron.log
echo "[MONGO_BACKUP] Backing up DB $MONGODB_DATABASE_FROM on host $MONGODB_HOST"  >> /var/log/cron.log

DUMP_OUTPUT="$(mongodump -h $MONGODB_HOST -d $MONGODB_DATABASE_FROM 2>&1)"

if [ $? -ne 0 ]; then
  echo "[MONGO_BACKUP] Error: Failed to backup $MONGODB_DATABASE_FROM. Error was: $DUMP_OUTPUT" >> /var/log/cron.log
  exit 0
else
  echo "[MONGO_COPY] Copying DB $MONGODB_DATABASE_FROM on host $MONGODB_HOST to $MONGODB_DATABASE_TO"  >> /var/log/cron.log   
  COPY_OUTPUT="$(mongorestore -h MONGODB_HOST -d MONGODB_DATABASE_TO dump)"
  if [ $? -ne 0 ]; then
    echo "[MONGO_COPY] Error: Failed to copy $MONGODB_DATABASE_FROM. to  $MONGODB_DATABASE_TO Error was: $COPY_OUTPUT" >> /var/log/cron.log
    exit 0
  fi
fi

FILENAME=${MYBACKUPDIR}/${MONGODB_DATABASE}.${MYDATE}.dump.tgz
tar -zcvf $FILENAME dump
rm -rf dump
