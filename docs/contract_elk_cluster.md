# Contract ELK Cluster

## Migrate Shards Off Nodes

1. To reallocate all shards off the elk nodes you want to decommission, ssh onto any one of them, then run this command:
  ```
  curl -XPUT localhost:9200/_cluster/settings -d '{
    "transient" :{
        "cluster.routing.allocation.exclude._ip": "<ip_of_node1>,<ip_of_node2>,...",
        "cluster.routing.allocation.cluster_concurrent_rebalance": "25"
     }
  }';echo
  ```

2. You **SHOULD NOT CONTINUE** unless all shards are migrated.


## Stop Services

1. **NOTE:** If one of the nodes you want to decommission is a **master node** of the ELK cluster, **refrain from shutting down** that node until you have stopped all others, if any. This is to ensure that none of the nodes that you are decommissioning will be elected as the new master node, possibly reallocating shards back onto this node.

2. **In this order**, stop these services on the non-master nodes, followed finally by the master node:
  - Logstash
  - Kibana
  - Elasticsearch



## Cancel Nodes

1. Once you have [Migrated All Shards Off the Node(s)](https://github.com/IBM/cuttle/blob/master/docs/contract_elk_cluster.md#migrate-shards-off-nodes) and you have [Stopped ELK Services](https://github.com/IBM/cuttle/blob/master/docs/contract_elk_cluster.md#stop-services)
