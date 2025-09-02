FROM alpine:3.22
ARG PORT=8080
ENV PORT=$PORT

RUN apk add --no-cache lighttpd sysbench

ADD entrypoint.sh /entrypoint.sh

EXPOSE $PORT
HEALTHCHECK --start-period=5s --interval=1m --timeout=1s CMD wget -O - http://localhost:8000/ || exit 1

ENTRYPOINT [ "/entrypoint.sh" ]
