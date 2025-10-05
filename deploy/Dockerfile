FROM alpine
WORKDIR /blog
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo
CMD ["hugo", "server", "--bind", "0.0.0.0"]