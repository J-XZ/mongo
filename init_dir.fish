#!/usr/bin/fish

set server_node_cnt 4
set shard_node_cnt 4
set nvme_path "."

set mongo_path $nvme_path/tmp/mongo
echo mongo_path:$mongo_path
rm -r $mongo_path
for i in (seq 0 (math $server_node_cnt - 1))
  echo mkdir $mongo_path/configsvr/data/node$i
  mkdir -p $mongo_path/configsvr/data/node$i
end 
for i in (seq 0 (math $shard_node_cnt - 1))
  echo mkdir $mongo_path/shardsvr/data/node$i
  mkdir -p $mongo_path/shardsvr/data/node$i
end
mkdir -p $mongo_path/routersvr