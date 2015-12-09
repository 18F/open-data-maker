#!/bin/bash

for shard in $(curl -XGET http://localhost:9200/_cat/shards | grep UNASSIGNED | awk '{print $2}'); do
    curl -XPOST 'localhost:9200/_cluster/reroute' -d '{
        "commands" : [ {
              "allocate" : {
                  "index" : "t37", 
                  "shard" : $shard, 
                  "node" : "datanode15", 
                  "allow_primary" : true
              }
            }
        ]
    }'
    sleep 5
done

