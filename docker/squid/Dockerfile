FROM alpine

RUN apk --update add squid openssl \
  && rm -rf /var/cache/apk/*

EXPOSE 3128 3129 3130

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT /entrypoint.sh
