#!/bin/bash

# Source mounted secrets if available
if [ -f /etc/secrets/env ]; then
  . /etc/secrets/env
fi

# Check if each var is declared and if not,
# set a sensible default
if [ -z "${MONGODB_URL}" ]; then
  MONGODB_URL=mongodb://mongononident-0.mongononident.mongo:27017/meteor
fi

# Parse DB URL
# extract the protocol
proto="$(echo $MONGODB_URL | grep :// | sed -e's,^\(.*://\).*,\1,g')"
# remove the protocol
url="$(echo ${MONGODB_URL/$proto/})"
# extract the user (if any)
user="$(echo $url | grep @ | cut -d@ -f1)"
# extract the host
host="$(echo ${url/$user@/} | cut -d/ -f1)"
# extract the DB name
database="$(echo $url | grep / | cut -d/ -f2-)"

if [ -z "${MONGODB_HOST}" ]; then
  MONGODB_HOST=$host
fi

if [ -z "${MONGODB_DATABASE_FROM}" ]; then
  MONGODB_DATABASE_FROM=$database
fi

if [ -z "${MONGODB_DATABASE_TO}" ]; then
  MONGODB_DATABASE_TO="${database}-staging"
fi

echo "Host $MONGODB_HOST , DBFrom $MONGODB_DATABASE_FROM , DBTo $MONGODB_DATABASE_TO"

echo "[MONGO_BACKUP] Starting backup script."


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
