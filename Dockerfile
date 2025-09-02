FROM alpine:3.22

RUN apk add --no-cache --purge --clean-protected -u ca-certificates sysbench && rm -rf /var/cache/apk/*

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
