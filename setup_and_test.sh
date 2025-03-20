#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印帶顏色的信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查是否以 root 權限運行
if [ "$EUID" -eq 0 ]; then 
    print_error "請不要使用 root 權限運行此腳本"
    exit 1
fi

# 更新系統
print_info "更新系統..."
sudo apt-get update
sudo apt-get upgrade -y

# 安裝必要的套件
print_info "安裝必要的套件..."
sudo apt-get install -y \
    docker.io \
    docker-compose \
    linux-tools-generic \
    linux-modules-extra-$(uname -r) \
    curl \
    jq

# 將用戶添加到 docker 群組
print_info "設置 Docker 權限..."
sudo usermod -aG docker $USER

# 加載 USB/IP 內核模塊
print_info "加載 USB/IP 內核模塊..."
sudo modprobe usbip_host || true
sudo modprobe vhci-hcd || true

# 啟動 USB/IP 服務器
print_info "啟動 USB/IP 服務器..."
sudo usbipd -D

# 創建必要的目錄
print_info "創建必要的目錄..."
mkdir -p config logs

# 複製配置文件
print_info "設置配置文件..."
cp .env.example .env

# 建立 Docker 鏡像
print_info "建立 Docker 鏡像..."
docker build -t ris-server:test .

# 啟動服務
print_info "啟動服務..."
docker-compose up -d

# 等待服務啟動
print_info "等待服務啟動..."
sleep 5

# 檢查服務狀態
print_info "檢查服務狀態..."
if curl -s http://localhost:5000/health > /dev/null; then
    print_info "服務已成功啟動！"
    
    # 測試 API
    print_info "測試 API..."
    
    # 檢查健康狀態
    print_info "健康狀態檢查："
    curl -s http://localhost:5000/health | jq '.'
    
    # 列出 USB/IP 設備
    print_info "USB/IP 設備列表："
    curl -s http://localhost:5000/usbip/devices | jq '.'
    
    # 檢查 USB/IP 狀態
    print_info "USB/IP 連接狀態："
    curl -s http://localhost:5000/usbip/status | jq '.'
    
    print_info "測試完成！"
    print_info "你可以使用以下命令查看日誌："
    echo "docker-compose logs -f"
else
    print_error "服務啟動失敗！"
    print_info "查看日誌："
    docker-compose logs
    exit 1
fi

# 提示用戶下一步操作
print_info "如果你想推送到 Docker Hub，請執行："
echo "docker login"
echo "docker tag ris-server:test your-username/ris-server:latest"
echo "docker push your-username/ris-server:latest" 