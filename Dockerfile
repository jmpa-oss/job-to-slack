FROM alpine:3.12
RUN apk update \
    && apk upgrade \
    && apk add bash curl jq
WORKDIR /
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]