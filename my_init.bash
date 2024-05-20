clear

# 同步每个node的代码与node0相同
all_node_list=(0 1 2 3 4 5)
config_node_list=(3 4 5) #至少3个节点
shard_node_list=(3 4 5)  #至少3个节点
base_ip="10.10.1."
router_server=2
main_config_server=3
config_node_port=27017
router_node_port=27018
shard_node_base_port=27019

ans=""
for node in "${all_node_list[@]}"; do
  SHARE_COMMAND0="
git config --global --add safe.directory /users/ruixuan/code/mongo
cd /users/ruixuan/code/mongo
"
  SHARE_COMMAND1="
sudo fish /users/ruixuan/code/mongo/kill_all.fish
sudo git pull
sudo git add .
sudo git commit -m "tmp"
sudo git push
sudo git pull
sudo git config --global credential.helper store
"
  if [ $node -eq 0 ]; then
    COMMAND="
$SHARE_COMMAND0
$SHARE_COMMAND1
"
  else
    COMMAND="
$SHARE_COMMAND0
sudo git checkout -- .
sudo git reset --hard origin/branch_tags_4.2.5
sudo git clean -fd
$SHARE_COMMAND1
"
  fi
  echo "node$node sync code"
  # 运行并检查ssh的所有输出中是否包含"Already up to date"
  ssh -t node$node "$COMMAND"
  output=$(ssh node$node "$COMMAND")
  if [[ $output == *"Already up to date"* ]]; then
    ans="$ans node$node sync code success\n"
  else
    ans="$ans node$node sync code failed\n"
  fi
done
echo -e "$ans"

# 启动config server，元数据服务器三个副本
ans=""
for node in "${config_node_list[@]}"; do
  config_log_dir=/users/ruixuan/code/mongo/tmp/mongo/configsvr/data/node$node
  db_dir=/users/ruixuan/code/mongo/tmp/mongo/configsvr/data/node$node
  COMMAND="
sudo fish /users/ruixuan/code/mongo/kill_all.fish
cd /users/ruixuan/code/mongo
sudo rm -rf $config_log_dir
sudo mkdir -p $config_log_dir
sudo rm -rf $db_dir
sudo mkdir -p $db_dir
sudo /users/ruixuan/code/mongo/mongod \
--config /users/ruixuan/code/mongo/configs/config0.conf \
--dbpath $db_dir \
--logpath $config_log_dir/configsvr.log \
--bind_ip $base_ip$((node + 1)) \
--port $config_node_port
sleep 1
sudo ps -aux | grep -v grep | grep mongod
"
  echo -e "node$node run config_server\n"
  # 运行并检查ssh的所有输出中是否包含/users/ruixuan/code/mongo/mongod
  output=$(ssh node$node "$COMMAND")
  if [[ $output == *"/users/ruixuan/code/mongo/mongod"* ]]; then
    ans="$ans node$node run config_server success\n"
  else
    ans="$ans node$node run config_server failed\n"
  fi
done
echo -e "$ans"

# 在 node$main_config_server 配置config server，多个config server构成一个复制集
echo "node$main_config_server init 3 copy config server"
MEMBER_LIST=""
for ((i = 0; i < 3; i++)); do
  MEMBER_LIST="$MEMBER_LIST{ _id : $i, host : '$base_ip$((config_node_list[$i] + 1)):$config_node_port' },"
done
COMMAND="
cd /users/ruixuan/code/mongo
sudo ./mongo $base_ip$((main_config_server + 1)):$config_node_port --eval \"
rs.initiate({
  _id: 'configsvr_rs',
  configsvr: true,
  members: [
    $MEMBER_LIST
  ]
})\"
"
echo "COMMAND=$COMMAND"
output=$(ssh node$main_config_server "$COMMAND")
if [[ $output == *"\"ok\" : 1"* ]]; then
  echo "node$main_config_server init 3 copy config server success"
else
  echo $output
fi

# 在 node$router_server 配置 router server
router_log_dir=/users/ruixuan/code/mongo/tmp/mongo/routersvr
router_log_path=$router_log_dir/mongos.log
config_node_list_str=""
for config_node in "${config_node_list[@]}"; do
  config_node_list_str="$config_node_list_str$base_ip$((config_node + 1)):$config_node_port,"
done
config_node_list_str=${config_node_list_str%,}
echo -e "config_node_list_str=$config_node_list_str\nCOMMAND=$COMMAND\n"
COMMAND="
cd /users/ruixuan/code/mongo
sudo rm -rf $router_log_dir
sudo mkdir -p $router_log_dir
sudo ./mongos \
--config /users/ruixuan/code/mongo/configs/router0.conf \
--logpath $router_log_path \
--bind_ip $base_ip$((router_server + 1)) \
--port $router_node_port \
--configdb configsvr_rs/$config_node_list_str
"
echo "node$router_server run router_server"
output=$(ssh node$router_server "$COMMAND")
echo "$output"

# 启动shard server
shard_node_cnt=${#shard_node_list[@]}
for ((shard = 0; shard < shard_node_cnt; shard++)); do
  copy_list=()
  for ((i = 0; i < 3; i++)); do
    c=$(((shard + i) % shard_node_cnt))
    copy_list+=("${shard_node_list[$c]}")
  done
  echo "copy_list=${copy_list[@]}"
  this_shard_port=$((shard_node_base_port + shard))
  main_copy_node=${copy_list[0]}
  echo "main_copy_node=$main_copy_node"

  replSet="shardsvr$shard"
  for ((copy = 0; copy < 3; copy++)); do
    node_to_run="${copy_list[$copy]}"
    echo "run shard db on $node_to_run"
    db_path="/users/ruixuan/code/mongo/tmp/shardsvr/data/shard$shard/copy$copy"
    log_path="/users/ruixuan/code/mongo/tmp/shardsvr/log/shard$shard/copy$copy"
    this_node_ip=$base_ip$((node_to_run + 1))
    COMMAND="
      cd /users/ruixuan/code/mongo
      sudo rm -rf $db_path
      sudo mkdir -p $db_path
      sudo rm -rf $log_path
      sudo mkdir -p $log_path

      sudo ./mongod \
        --config /users/ruixuan/code/mongo/configs/shard0.conf \
        --dbpath $db_path \
        --logpath $log_path/shardsvr.log \
        --replSet $replSet \
        --bind_ip $this_node_ip \
        --port $this_shard_port
    "
    echo "node:$node_to_run COMMAND=$COMMAND"
    # read
    output=$(ssh node$node_to_run "$COMMAND")
    echo "$output"
    echo ""
    echo ""
  done

  MEMBER_LIST=""
  for ((i = 0; i < 3; i++)); do
    MEMBER_LIST="$MEMBER_LIST{ _id : $i, host : '$base_ip$((copy_list[$i] + 1)):$this_shard_port' },"
  done
  COMMAND="
    rs.initiate({
      _id : '$replSet',
      members: [
        $MEMBER_LIST
      ]
    })
  "
  COMMAND="
    cd /users/ruixuan/code/mongo
    sudo ./mongo --host $base_ip$((main_copy_node + 1)) --port $this_shard_port --eval \"$COMMAND\"
  "
  echo "node:$main_copy_node COMMAND=$COMMAND"
  # read
  output=$(ssh node$main_copy_node "$COMMAND")
  echo "$output"
  echo ""
  echo ""
done

# 连接到router节点，将分片服务器副本集添加到router管理的集群中

router_ip=$base_ip$((router_server + 1))

add_shard_command=""
for ((shard = 0; shard < shard_node_cnt; shard++)); do
  this_shard_port=$((shard_node_base_port + shard))
  replSet="shardsvr$shard"
  MEMBER_LIST=""
  for ((i = 0; i < 3; i++)); do
    MEMBER_LIST="$MEMBER_LIST$base_ip$((shard_node_list[$i] + 1)):$this_shard_port,"
  done
  MEMBER_LIST=${MEMBER_LIST%,}
  echo "$MEMBER_LIST"
  add_shard_command="$add_shard_command sh.addShard('$replSet/$MEMBER_LIST')
  "
done

COMMAND="
cd /users/ruixuan/code/mongo
sudo ./mongo $router_ip:$router_node_port --eval \"
  $add_shard_command
\"
"

echo "$COMMAND"

output=$(ssh node$router_server "$COMMAND")
echo "$output"

# 连接到router节点，配置按照key的字典序范围分片

COMMAND="
  cd /users/ruixuan/code/mongo
  sudo ./mongo $router_ip:$router_node_port <<EOF
use ycsb;
db.createCollection('usertable');
sh.enableSharding('ycsb');
sh.shardCollection('ycsb.usertable', { '_id': 1 });
EOF
"
echo "$COMMAND"

output=$(ssh node$router_server "$COMMAND")
echo "$output"

