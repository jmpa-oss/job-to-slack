FROM alpine:3.12
RUN apk add --no-cache \
    bash=5.0.17-r0 \
    jq=1.6-r1 \
    curl=7.69.1-r3 \
    && rm -rf /var/cache/apk
WORKDIR /
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
