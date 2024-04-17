#!/usr/bin/fish

set node_cnt 4
set nvme_path "."
set replica_cnt 3

set server_node_cnt $node_cnt
set shard_node_cnt $node_cnt
set mongo_path $nvme_path/tmp/mongo
echo mongo_path:$mongo_path
rm -r $mongo_path
for i in (seq 0 (math $server_node_cnt - 1))
  echo mkdir $mongo_path/configsvr/data/node$i
  mkdir -p $mongo_path/configsvr/data/node$i
end 
for i in (seq 0 (math $shard_node_cnt - 1))
  for j in (seq 0 2)
    echo mkdir $mongo_path/shardsvr/data/node$i/r$j
    mkdir -p $mongo_path/shardsvr/data/node$i/r$j
  end
end
mkdir -p $mongo_path/routersvr