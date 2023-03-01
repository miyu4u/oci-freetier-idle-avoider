FROM alpine

RUN apk add --no-cache --purge \
    sysbench \
    && rm -rf /var/cache/apk/*

ENTRYPOINT [ "sysbench" ]