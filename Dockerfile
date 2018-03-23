FROM icyleafcn/alpine:3.7

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY hpr /app/hpr
COPY deps/ /

WORKDIR /app

RUN apk add --update --no-cache git bash openssh-client

VOLUME ["/app/config", "/app/repositories"]

EXPOSE 8848/tcp

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["hpr:init"]
