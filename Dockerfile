FROM sebp/elk:es501_l501_k501
MAINTAINER Allan Sun <allan.sun@bricre.com>

ENV ELASTICSEARCH_START=1
ENV LOGSTASH_START=1

ENV KIBANA_START=0
ENV ES_CONNECT_RETRY=180

ENV ES_HEAP_SIZE=16m
ENV LS_HEAP_SIZE=16m


COPY ./config /etc/elasticsearch

#run curl post  init Elastic Search  basic index structure
ADD ./init_es_index.sh /usr/local/bin/init_es_index.sh
RUN chmod +x /usr/local/bin/init_es_index.sh

#add logstash file for jdbc
ADD ./logstash.conf /etc/logstash/conf.d/mysql.conf

RUN mkdir /opt/logstash/driver
ADD ./mysql-connector-java-5.1.38.jar /opt/logstash/driver/mysql-connector-java-5.1.38.jar
RUN chmod +x /opt/logstash/driver/mysql-connector-java-5.1.38.jar

ADD ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 9200

CMD [ "/usr/local/bin/start.sh" ]


