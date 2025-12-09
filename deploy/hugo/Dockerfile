FROM alpine

WORKDIR /blog

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo

COPY blog/gladys .

CMD ["hugo"]
