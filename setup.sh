#!/bin/bash

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 打印信息函數
print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 檢查是否以 root 運行
if [ "$EUID" -eq 0 ]; then 
    print_error "請不要以 root 用戶運行此腳本"
    exit 1
fi

# 更新系統
print_info "更新系統..."
sudo apt-get update

# 安裝必要的包
print_info "安裝必要的包..."
sudo apt-get install -y \
    docker.io \
    docker-compose \
    netcat-openbsd

# 創建 docker 組（如果不存在）
print_info "設置 Docker 權限..."
sudo groupadd docker || true
sudo usermod -aG docker $USER

# 設置串口權限
print_info "設置串口權限..."
sudo groupadd dialout || true
sudo usermod -aG dialout $USER

# 創建串口設備（如果不存在）
print_info "創建串口設備..."
sudo mknod -m 666 /dev/ttyS3 c 4 67 2>/dev/null || true

# 設置串口權限
sudo chmod 666 /dev/ttyS3 2>/dev/null || true

# 創建必要的目錄
print_info "創建必要的目錄..."
mkdir -p config logs RIS_BusData

# 設置目錄權限
print_info "設置目錄權限..."
chmod 755 config logs RIS_BusData

# 停止現有服務
print_info "停止現有服務..."
docker-compose down || true

# 重新構建鏡像
print_info "構建 Docker 鏡像..."
docker build -t ris-server:test .

# 啟動服務
print_info "啟動服務..."
docker-compose up -d

# 等待服務啟動
print_info "等待服務啟動..."
sleep 5

# 檢查服務狀態
print_info "檢查服務狀態..."
docker ps | grep ris-server

# 檢查日誌
print_info "檢查服務日誌..."
docker-compose logs --tail=20

print_info "設置完成！"
print_warn "請注意：您需要重新登錄以使組權限生效"
print_warn "您可以運行 'newgrp docker dialout' 來立即應用組權限"
print_info "服務應該已經在 http://localhost:5000 運行" 