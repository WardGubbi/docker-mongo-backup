FROM zuolan/mongodb-tools

ADD backupandcopy.sh /backupandcopy.sh
COPY backupcronfile /var/spool/cron/crontabs/root 

VOLUME ["/var/log/"]

CMD crond -l 2 -f  
