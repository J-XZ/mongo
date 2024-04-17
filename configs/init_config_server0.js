rs.initiate({
  _id: "configsvr_rs",
  configsvr: true,
  // 列出每个config server的ip和端口，其中第一个会作为主复制节点，其余是从复制节点
  members: [
    { _id : 0, host : "127.0.0.1:27017" },
    { _id : 1, host : "127.0.0.1:27018" },
    { _id : 2, host : "127.0.0.1:27019" }
  ]
})