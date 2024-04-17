use ycsb;
db.createCollection("usertable");
sh.enableSharding("ycsb");
sh.shardCollection("ycsb.usertable", { "_id": 1 });
