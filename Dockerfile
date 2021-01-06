FROM alpine:3.12
RUN apk add --no-cache \
    bash=5.1.0-r0 \
    && rm -rf /var/cache/apk
WORKDIR /
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
