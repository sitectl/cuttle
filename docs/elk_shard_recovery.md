# ELK Shard Recovery

Try the following two commands if ES cluster status is red and there are
unallocated shards. **Be sure to fill in `node` in the first command.**

```
for index in $(curl -XGET http://localhost:9200/_cat/indices | awk '{print $3}'); do
for shard in $(curl -XGET http://localhost:9200/_cat/shards/$index | grep UNASSIGNED | awk '{print $2}'); do
    curl -XPOST 'localhost:9200/_cluster/reroute' -d "{
        \"commands\" : [ {
              \"allocate\" : {
                  \"index\" : \"$index\",
                  \"shard\" : $shard,
                  \"node\" : \"<REPLACE ME (EXAMPLE: sc0235)>\",
                  \"allow_primary\" : true
              }
            }
        ]
    }"
    sleep 5
done
done
```

```
curl -XPUT localhost:9200/_cluster/settings -d '{
"persistent" : {
"cluster.routing.allocation.enable": "ALL",
"cluster.routing.allocation.node_concurrent_recoveries" : "25",
"indices.recovery.max_bytes_per_sec": "500mb",
"indices.recovery.concurrent_streams": 8
}
}'
```
