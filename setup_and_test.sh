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

# 安裝 Docker
print_info "安裝 Docker..."
# 移除舊版本
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# 安裝必要的套件
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加 Docker 的官方 GPG 密鑰
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 設置穩定版倉庫
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新套件列表
sudo apt-get update

# 安裝 Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 安裝 Docker Compose
print_info "安裝 Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 將用戶添加到 docker 群組
print_info "設置 Docker 權限..."
sudo groupadd docker || true
sudo usermod -aG docker $USER

# 設置串口權限
print_info "設置串口權限..."
sudo groupadd dialout || true
sudo usermod -aG dialout $USER
sudo chmod 666 /dev/ttyS* /dev/ttyUSB* 2>/dev/null || true

# 安裝其他必要的套件
print_info "安裝其他必要的套件..."
sudo apt-get install -y \
    curl \
    jq

# 創建必要的目錄
print_info "創建必要的目錄..."
mkdir -p config logs

# 複製配置文件
print_info "設置配置文件..."
cp .env.example .env

# 重新加載用戶組
print_info "重新加載用戶組..."
newgrp docker dialout

# 等待 Docker 服務啟動
print_info "等待 Docker 服務啟動..."
sleep 5

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
    
    # 測試 RIS 控制
    print_info "測試 RIS 控制："
    curl -X POST -H "Content-Type: application/json" -d '{"xr": 15.7, "yr": 8.9, "zr": 3.1}' http://localhost:5000/set_ris_position | jq '.'
    
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

# 提示用戶需要重新登入
print_warn "請注意：如果你遇到權限問題，請重新登入系統"
print_warn "或者執行："
echo "newgrp docker dialout" 