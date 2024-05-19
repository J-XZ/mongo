rs.initiate({
  _id: "configsvr_rs",
  configsvr: true,
  // 列出每个config server的ip和端口，其中第一个会作为主复制节点，其余是从复制节点
  members: [
    { _id : 0, host : "10.10.1.3:27017" },
    { _id : 1, host : "10.10.1.4:27017" },
    { _id : 2, host : "10.10.1.5:27017" }
  ]
})
