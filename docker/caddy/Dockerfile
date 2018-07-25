FROM alpine

ADD dist/caddy /usr/bin/caddy

ADD Caddyfile /caddy/Caddyfile

EXPOSE 80 443

VOLUME /caddy /data

WORKDIR /data

ENTRYPOINT ["/usr/bin/caddy"]

CMD ["--conf", "/caddy/Caddyfile", "--log", "stdout"]