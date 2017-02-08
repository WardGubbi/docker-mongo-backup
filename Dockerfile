FROM alpine:3.3

RUN  apk add mongodb-tools \
        --update-cache \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing && \
    rm -rf /var/lib/apk/*

ADD backupandcopy.sh /backupandcopy.sh
COPY backupcronfile /var/spool/cron/crontabs/root 

VOLUME ["/var/log/"]

CMD crond -l 2 -f  
