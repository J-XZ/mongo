#!/usr/bin/fish

# 使用 ps 命令查找所有 mongod 进程
set mongod_pids (ps aux | grep mongo | grep -v grep | awk '{print $2}')

# 遍历所有进程并逐个关闭
for pid in $mongod_pids
    echo "Stopping mongod process with PID: $pid"
    kill $pid
end

echo "All mongod processes have been stopped."