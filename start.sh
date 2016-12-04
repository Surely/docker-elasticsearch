#!/bin/bash
#
# /usr/local/bin/start.sh
# Start Elasticsearch, Logstash and Kibana services
#
# spujadas 2015-10-09; added initial pidfile removal and graceful termination

# WARNING - This script assumes that the ELK services are not running, and is
#   only expected to be run once, when the container is started.
#   Do not attempt to run this script if the ELK services are running (or be
#   prepared to reap zombie processes).


## handle termination gracefully

_term() {
  echo "Terminating ELK"
  service elasticsearch stop
  service logstash stop
  service kibana stop
  exit 0
}

trap _term SIGTERM


## remove pidfiles in case previous graceful termination failed
# NOTE - This is the reason for the WARNING at the top - it's a bit hackish,
#   but if it's good enough for Fedora (https://goo.gl/88eyXJ), it's good
#   enough for me :)

rm -f /var/run/elasticsearch/elasticsearch.pid /var/run/logstash.pid \
  /var/run/kibana5.pid

## initialise list of log files to stream in console (initially empty)
OUTPUT_LOGFILES=""


## start services as needed

### crond

service cron start


### Elasticsearch

#added by yuhao 2016-11-28 use customized data dir
#=================================================
#chown -R elasticsearch:elasticsearch /var/lib/elasticsearch
#=================================================
#end added by yuhao 2016-11-28 use customized data dir

if [ -z "$ELASTICSEARCH_START" ]; then
  ELASTICSEARCH_START=1
fi
if [ "$ELASTICSEARCH_START" -ne "1" ]; then
  echo "ELASTICSEARCH_START is set to something different from 1, not starting..."
else
  # override ES_HEAP_SIZE variable if set
  if [ ! -z "$ES_HEAP_SIZE" ]; then
    awk -v LINE="ES_HEAP_SIZE=\"$ES_HEAP_SIZE\"" '{ sub(/^#?ES_HEAP_SIZE=.*/, LINE); print; }' /etc/default/elasticsearch \
        > /etc/default/elasticsearch.new && mv /etc/default/elasticsearch.new /etc/default/elasticsearch
  fi
  # override ES_JAVA_OPTS variable if set
  if [ ! -z "$ES_JAVA_OPTS" ]; then
    awk -v LINE="ES_JAVA_OPTS=\"$ES_JAVA_OPTS\"" '{ sub(/^#?ES_JAVA_OPTS=.*/, LINE); print; }' /etc/default/elasticsearch \
        > /etc/default/elasticsearch.new && mv /etc/default/elasticsearch.new /etc/default/elasticsearch
  fi

  service elasticsearch start

  # wait for Elasticsearch to start up before either starting Kibana (if enabled)
  # or attempting to stream its log file
  # - https://github.com/elasticsearch/kibana/issues/3077

  # set number of retries (default: 30, override using ES_CONNECT_RETRY env var)
  re_is_numeric='^[0-9]+$'
  if ! [[ $ES_CONNECT_RETRY =~ $re_is_numeric ]] ; then
     ES_CONNECT_RETRY=30
  fi

  counter=0
  while [ ! "$(curl localhost:9200 2> /dev/null)" -a $counter -lt $ES_CONNECT_RETRY  ]; do
    sleep 1
    ((counter++))
    echo "waiting for Elasticsearch to be up ($counter/$ES_CONNECT_RETRY)"
  done
  if [ ! "$(curl localhost:9200 2> /dev/null)" ]; then
    echo "Couln't start Elasticsearch. Exiting."
    echo "Elasticsearch log follows below."
    cat /var/log/elasticsearch/elasticsearch.log
    exit 1
  fi

  # wait for cluster to respond before getting its name
  counter=0
  CLUSTER_NAME=
  while [ -z "$CLUSTER_NAME" -a $counter -lt 30 ]; do
    sleep 1
    ((counter++))
    CLUSTER_NAME=$(curl localhost:9200/_cat/health?h=cluster 2> /dev/null | tr -d '[:space:]')
    echo "Waiting for Elasticsearch cluster to respond ($counter/30)"
  done
  if [ -z "$CLUSTER_NAME" ]; then
    echo "Couln't get name of cluster. Exiting."
    echo "Elasticsearch log follows below."
    cat /var/log/elasticsearch/elasticsearch.log
    exit 1
  fi
  OUTPUT_LOGFILES+="/var/log/elasticsearch/${CLUSTER_NAME}.log "
fi


### Logstash

if [ -z "$LOGSTASH_START" ]; then
  LOGSTASH_START=1
fi
if [ "$LOGSTASH_START" -ne "1" ]; then
  echo "LOGSTASH_START is set to something different from 1, not starting..."
else
  # override LS_HEAP_SIZE variable if set
  if [ ! -z "$LS_HEAP_SIZE" ]; then
    awk -v LINE="LS_HEAP_SIZE=\"$LS_HEAP_SIZE\"" '{ sub(/^LS_HEAP_SIZE=.*/, LINE); print; }' /etc/init.d/logstash \
        > /etc/init.d/logstash.new && mv /etc/init.d/logstash.new /etc/init.d/logstash && chmod +x /etc/init.d/logstash
  fi

  # override LS_OPTS variable if set
  if [ ! -z "$LS_OPTS" ]; then
    awk -v LINE="LS_OPTS=\"$LS_OPTS\"" '{ sub(/^LS_OPTS=.*/, LINE); print; }' /etc/init.d/logstash \
        > /etc/init.d/logstash.new && mv /etc/init.d/logstash.new /etc/init.d/logstash && chmod +x /etc/init.d/logstash
  fi

#added by yuhao 2016-11-28 use logstash for jdbc only
#=================================================
if [ -z "$MYSQL_HOST" ]; then
  MYSQL_HOST=db
fi

if [ -z "$MYSQL_PORT" ]; then
  MYSQL_PORT=3306
fi

if [ -z "$SCHEDULER_INTERVAL_MINUTES" ]; then
  SCHEDULER_INTERVAL_MINUTES=5
fi

echo "init elastic search index."
sed -i \
    -e 's/<MYSQL_DATABASE>/'${MYSQL_DATABASE}'/g' \
    -e 's/<MYSQL_USER>/'${MYSQL_USER}'/g' \
    -e 's/<MYSQL_PASSWORD>/'${MYSQL_PASSWORD}'/g' \
    -e 's/<MYSQL_HOST>/'${MYSQL_HOST}'/g'\
    -e 's/<MYSQL_PORT>/'${MYSQL_PORT}'/g'\
    /usr/local/bin/init_es_index.sh
sh /usr/local/bin/init_es_index.sh
echo "init elastic search index."

  rm -rf /etc/logstash/conf.d/02-beats-input.conf
  rm -rf /etc/logstash/conf.d/10-syslog.conf
  rm -rf /etc/logstash/conf.d/11-nginx.conf
  rm -rf /etc/logstash/conf.d/30-output.conf

sed -i \
    -e 's/<MYSQL_DATABASE>/'${MYSQL_DATABASE}'/g' \
    -e 's/<MYSQL_USER>/'${MYSQL_USER}'/g' \
    -e 's/<MYSQL_PASSWORD>/'${MYSQL_PASSWORD}'/g' \
    -e 's/<MYSQL_HOST>/'${MYSQL_HOST}'/g'\
    -e 's/<MYSQL_PORT>/'${MYSQL_PORT}'/g'\
    -e 's/<SCHEDULER_INTERVAL_MINUTES>/'${SCHEDULER_INTERVAL_MINUTES}'/g'\
    /etc/logstash/conf.d/mysql.conf

#=================================================
#end added by yuhao 2016-11-28 use logstash for jdbc only


  
  service logstash start
  OUTPUT_LOGFILES+="/var/log/logstash/logstash-plain.log "
fi


### Kibana

if [ -z "$KIBANA_START" ]; then
  KIBANA_START=1
fi
if [ "$KIBANA_START" -ne "1" ]; then
  echo "KIBANA_START is set to something different from 1, not starting..."
else
  service kibana start
  OUTPUT_LOGFILES+="/var/log/kibana/kibana5.log "
fi

# Exit if nothing has been started
if [ "$ELASTICSEARCH_START" -ne "1" ] && [ "$LOGSTASH_START" -ne "1" ] \
  && [ "$KIBANA_START" -ne "1" ]; then
  >&2 echo "No services started. Exiting."
  exit 1
fi

tail -f $OUTPUT_LOGFILES &
wait

