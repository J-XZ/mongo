#!/bin/bash

# 获取所有包含 'mongo' 的进程ID
pids=$(pgrep -f mongo)

# 检查是否找到任何包含 'mongo' 的进程
if [ -z "$pids" ]; then
    echo "没有找到包含 'mongo' 的进程。"
    exit 1
fi

# 遍历所有找到的进程ID
for pid in $pids; do
    echo "调整进程 PID $pid 的文件描述符限制为 1000000"

    # 检查进程是否存在
    if [ -d /proc/$pid ]; then
        # 使用 prlimit 提高文件描述符限制
        sudo prlimit --pid $pid --nofile=1000000:1000000

        # 验证修改是否成功
        new_limit=$(cat /proc/$pid/limits | grep "Max open files")
        echo "PID $pid 的新文件描述符限制: $new_limit"
    else
        echo "进程 PID $pid 不存在或已终止。"
    fi
done

