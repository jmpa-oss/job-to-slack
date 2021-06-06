FROM alpine:3.12
RUN apk add --no-cache \
    bash=5.0.17-r0 \
    jq=1.6-r1 \
    curl=7.77.0-r0 \
    && rm -rf /var/cache/apk
WORKDIR /
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
