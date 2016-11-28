1. 基于 https://hub.docker.com/r/sebp/elk/ 镜像 5.0.1

2. es做搜索,　l一个ogstash做 mysql => es 同步,　kibana是禁用的 (ps: logstash默认配置了日志转发功能,这里在start.sh中禁用掉了)

3. 因为es默认所有的业务数据都要通过 restful api生成,所以利用了 init_es_index.sh 初始化ES

5. ES 搜索API :  
    https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html
       https://www.elastic.co/guide/en/elasticsearch/reference/current/search-uri-request.html
   常用搜索句子:
   http://localhost:9200/birdego/product/_search?q=brand:castlemil  查brand=castlemil的数据　
   http://localhost:9200/birdego/product/_search?q=brand:castlemil&stored_fields=name 同上,但只返回name字段　

