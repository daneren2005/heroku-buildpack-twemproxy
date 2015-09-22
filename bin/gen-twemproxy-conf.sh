#!/usr/bin/env bash

REDIS_URLS=${TWEMPROXY_URLS:-REDISCLOUD_URL}
n=1

# Enable this option to prevent stunnel failure with Amazon RDS when a dyno resumes after sleeping
if [ -z "${ENABLE_STUNNEL_AMAZON_RDS_FIX}" ]; then
  AMAZON_RDS_STUNNEL_OPTION=""
else
  AMAZON_RDS_STUNNEL_OPTION="options = NO_TICKET"
fi

mkdir -p /app/vendor/stunnel/var/run/stunnel/
cat >> /app/vendor/stunnel/stunnel-twemproxy.conf << EOFEOF
foreground = yes

options = NO_SSLv2
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE
socket = r:TCP_NODELAY=1
options = NO_SSLv3
${AMAZON_RDS_STUNNEL_OPTION}
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
EOFEOF

for REDIS_URL in $REDIS_URLS
do
  echo "Setting ${REDIS_URL}_TWEMPROXY config var"
  eval REDIS_URL_VALUE=\$$REDIS_URL
  export ${REDIS_URL}_TWEMPROXY=${REDIS_URL_VALUE}

  cat >> /app/vendor/twemproxy/twemproxy.yml << EOFEOF
${REDIS_URL}:
	listen: 127.0.0.1:620${n}
	redis: true
	servers:
		- /tmp/.s.REDIS.620${n}
EOFEOF

  cat >> /app/vendor/stunnel/stunnel-twemproxy.conf << EOFEOF
[${REDIS_URL}]
client = yes
accept  = /tmp/.s.REDIS.620${n}
connect = ${REDIS_URL_VALUE}
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/twemproxy/*
chmod go-rwx /app/vendor/stunnel/*
