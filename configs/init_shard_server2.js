rs.initiate({
  _id : "shardsvr2_rs",
  members: [
    { _id : 0, host : "127.0.0.1:27027" },
    { _id : 1, host : "127.0.0.1:27028" },
    { _id : 2, host : "127.0.0.1:27029" },
  ]
})