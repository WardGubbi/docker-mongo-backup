#!/bin/bash

# Source mounted secrets if available
if [ -f /etc/secrets/env ]; then
  . /etc/secrets/env
fi

# Check if each var is declared and if not,
# set a sensible default
if [ -z "${MONGODB_URL}" ]; then
  MONGODB_URL=mongodb://mongononident-0.mongononident.mongo,mongononident-1.mongononident.mongo,mongononident-2.mongononident.mongo:27017/meteor?replicaSet=rs0
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
database="$(echo $database |  cut -d? -f1)" 

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

# Now write these all to case file that can be sourced
# by then cron job - we need to do this because
# env vars passed to docker will not be available
# in the contenxt of then running cron script.

echo "
export MONGODB_HOST=$MONGODB_HOST
export MONGODB_DATABASE_FROM=$MONGODB_DATABASE_FROM
export MONGODB_DATABASE_TO=$MONGODB_DATABASE_TO
 " > /mongodb_env.sh
echo "[MONGO_BACKUP] Starting backup script."

# Now launch cron. Tail logs in the foreground
cron && tail -fq /var/log/cron.log
