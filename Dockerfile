FROM alpine:3.3

RUN apk add --no-cache mongodb-tools

ADD backupandcopy.sh /backupandcopy.sh
COPY backupcronfile /var/spool/cron/crontabs/root 

CMD crond -l 2 -f  
