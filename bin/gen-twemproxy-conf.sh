#!/usr/bin/env bash

REDIS_URLS=${TWEMPROXY_URLS:-REDISCLOUD_URL}
n=1

for REDIS_URL in $REDIS_URLS
do
  echo "Setting ${REDIS_URL}_TWEMPROXY config var"
  eval REDIS_URL_VALUE=\$$REDIS_URL

  # redis://rediscloud:UV0d4ikbK7UIegq5@pub-redis-19886.us-east-1-1.2.ec2.garantiadata.com:19886
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

  let "n += 1"
done

chmod go-rwx /app/vendor/twemproxy/*
