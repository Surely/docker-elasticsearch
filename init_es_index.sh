#!/bin/bash
#

curl -XPUT 'localhost:9200/_template/<MYSQL_DATABASE>?pretty' -d'
{
  "template": "birdego",
  "settings": {
    		"number_of_shards": 1,
    		"number_of_replicas": 0,
		"index.mapper.dynamic": false
  	},
    "mappings" : {
	     "_default_": {
	         "_all": {
		          "enabled": false
	          },
		        "_source": {
        		  "enabled": true
		        },
            "dynamic": false
	     },
      "product" : {
                "properties" : {
                    "id" : {
                        "type" : "integer",
                        "store" : "yes",
                        "index" : "not_analyzed"
                    },
                    "name" : {
                        "type" : "string",
                        "store" : "yes",
                        "index" : "analyzed",
                        "analyzer" : "cjk"
                    },
                    "name_customs" : {
                        "type" : "string",
                        "store" : "yes",
                        "index" : "analyzed",
                        "analyzer" : "cjk"
                    },
                    "customs_category_name" : {
                        "type" : "string",
                        "store" : "yes",
                        "index" : "analyzed",
                        "analyzer" : "cjk"
                    },
                    "customs_category_id" : {
                        "type" : "integer",
                        "store" : "yes",
                        "index" : "not_analyzed"
                    },
                    "material" : {
                        "type" : "string",
                        "store" : "yes",
                        "index" : "analyzed",
                        "analyzer" : "cjk"
                    },
                    "brand" : {
                        "type" : "string",
                        "store" : "yes",
                        "index" : "analyzed",
                        "analyzer" : "cjk"
                    },
                    "usage" : {
                        "type" : "string",
                        "store" : "yes",
                        "index" : "analyzed",
                        "analyzer" : "cjk"
                    }
                }
            }
        }
}'



curl -XPUT 'localhost:9200/<MYSQL_DATABASE>'
