#!/bin/sh

function writeSquidConf {

cat <<EOF > /etc/squid/squid.conf

access_log stdio:/var/log/squid/access.log

http_access allow all

http_port 3128
http_port 3129 intercept
https_port 3130 transparent ssl-bump cert=/etc/squid/ssl_cert/myCA.pem

coredump_dir /var/cache/squid

cache_peer $PROXY_HOST parent $PROXY_PORT 0 default $PROXY_LOGIN
never_direct allow all

ssl_bump splice all

EOF

}

if [ ! -z $PROXY_USER ] && [ ! -z $PROXY_PW ] ; then
    echo "setting proxy login"
    export PROXY_LOGIN="login=$PROXY_USER:$PROXY_PW"
fi
if [ -z $PROXY_HOST ]; then
    echo "environment variable PROXY_HOST was not set. Exiting"
    exit 1
fi
if [ -z $PROXY_PORT ]; then
    export PROXY_PORT=3128
fi

echo "writing squid.conf"

writeSquidConf

mkdir -p /etc/squid/ssl_cert /var/spool/squid

openssl req -new -newkey rsa:2048 -sha256 -days 365000 -nodes -x509 -keyout /etc/squid/ssl_cert/myCA.pem -out /etc/squid/ssl_cert/myCA.pem -subj "/C=DE/ST=BW/CN=squid"
/usr/lib/squid/ssl_crtd -c -s /var/spool/squid/ssl_db

exec /usr/sbin/squid -sYCN
