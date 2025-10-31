#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# NOFX 统一镜像启动脚本
# 同时启动 Go 后端服务和 Nginx 前端服务
# ═══════════════════════════════════════════════════════════════

set -e

echo "🚀 启动 NOFX 统一服务..."

# 设置环境变量
export TZ=${TZ:-Asia/Shanghai}

# 创建必要的目录
mkdir -p /app/decision_logs

# 启动后端服务 (在后台运行)
echo "📡 启动后端服务..."
cd /app
nofx &
BACKEND_PID=$!

# 等待后端服务启动
echo "⏳ 等待后端服务启动..."
for i in {1..30}; do
    if curl -f http://localhost:8080/health >/dev/null 2>&1; then
        echo "✅ 后端服务已启动"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ 后端服务启动超时"
        exit 1
    fi
    sleep 2
done

# 启动 Nginx
echo "🌐 启动 Nginx 服务..."
nginx -g "daemon off;" &
NGINX_PID=$!

# 信号处理函数
cleanup() {
    echo "🛑 正在停止服务..."
    kill $BACKEND_PID $NGINX_PID 2>/dev/null || true
    wait $BACKEND_PID $NGINX_PID 2>/dev/null || true
    echo "✅ 服务已停止"
    exit 0
}

# 捕获信号
trap cleanup SIGTERM SIGINT

echo "✅ NOFX 统一服务已启动"
echo "   - 前端服务: http://localhost:80"
echo "   - 后端 API: http://localhost:8080"

# 等待进程
wait $BACKEND_PID $NGINX_PID