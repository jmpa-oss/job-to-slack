FROM alpine:3.12
RUN apk add --no-cache bash \
    && rm -rf /var/cache/apk
WORKDIR /
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
