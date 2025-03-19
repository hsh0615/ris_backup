#!/bin/bash

# 安裝 USB/IP 服務器
echo "Installing USB/IP server..."
sudo apt-get update
sudo apt-get install -y usbip linux-tools-generic

# 加載必要的內核模塊
echo "Loading required kernel modules..."
sudo modprobe usbip_host
sudo modprobe vhci-hcd

# 創建 systemd 服務文件
echo "Creating USB/IP systemd service..."
sudo tee /etc/systemd/system/usbipd.service << 'EOL'
[Unit]
Description=USB/IP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/usbipd -D
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# 重新加載 systemd
sudo systemctl daemon-reload

# 啟動 USB/IP 服務
echo "Starting USB/IP service..."
sudo systemctl start usbipd
sudo systemctl enable usbipd

# 綁定要共享的 USB 設備
# 注意：需要替換 VENDOR_ID 和 PRODUCT_ID 為實際的設備 ID
# 可以通過 lsusb 命令獲取
echo "Binding USB device..."
# sudo usbip bind -b 1-1  # 取消註釋並修改為實際的設備 ID

echo "USB/IP server setup complete!"
echo "To bind a USB device, run:"
echo "1. lsusb  # 列出 USB 設備"
echo "2. sudo usbip bind -b <BUSID>  # 綁定設備"
echo "3. sudo usbip list -l  # 列出已綁定的設備" 