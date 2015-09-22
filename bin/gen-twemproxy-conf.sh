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

  DB=$(echo ${REDIS_URL_VALUE} | perl -lne 'print "$1 $2 $3 $4 $5 $6" if /^redis(?:ql)?:\/\/([^:]+):([^@]+)@(.*?):(.*?)(\\?.*)?$/')
  DB_URI=( $DB )
  DB_USER=${DB_URI[0]}
  DB_PASS=${DB_URI[1]}
  DB_HOST=${DB_URI[2]}
  DB_PORT=${DB_URI[3]}

  NEW_URL=redis://${DB_USER}:${DB_PASS}@127.0.0.1:620${n}
  export ${REDIS_URL}_TWEMPROXY=${NEW_URL}
  echo "Pointing to ${DB_HOST}:${DB_PORT}"

  cat >> /app/vendor/twemproxy/twemproxy.yml << EOFEOF
${REDIS_URL}:
  listen: 127.0.0.1:620${n}
  redis: true
  redis_auth: ${DB_PASS}
  servers:
   - ${DB_HOST}:${DB_PORT}:1
EOFEOF

  cat >> /app/vendor/stunnel/stunnel-twemproxy.conf << EOFEOF
[${REDIS_URL}]
client = yes
accept  = /tmp/.s.REDIS.620${n}
connect = ${DB_HOST}:${DB_PORT}
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/twemproxy/*
chmod go-rwx /app/vendor/stunnel/*
