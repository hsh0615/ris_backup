#!/bin/bash

# 檢查 USB/IP 客戶端是否已安裝
if ! command -v usbip &> /dev/null; then
    echo "Installing USB/IP client..."
    apt-get update && apt-get install -y usbip
fi

# 加載必要的內核模塊
modprobe usbip_host
modprobe vhci-hcd

# 獲取環境變量
USBIP_HOST=${USBIP_HOST:-host.docker.internal}
USBIP_PORT=${USBIP_PORT:-3240}

# Wait for USB/IP service to be available
echo "Waiting for USB/IP service..."
while ! nc -z $USBIP_HOST $USBIP_PORT; do
    sleep 1
done
echo "USB/IP service is available"

# List available devices
echo "Listing available USB/IP devices..."
usbip list -r $USBIP_HOST -p $USBIP_PORT

# If a specific device is specified in environment variable, attach it
if [ ! -z "$USBIP_DEVICE_BUSID" ]; then
    echo "Attaching specified device: $USBIP_DEVICE_BUSID"
    usbip attach -r $USBIP_HOST -p $USBIP_PORT -b $USBIP_DEVICE_BUSID
fi

# 等待設備連接
sleep 2

# 檢查設備是否成功連接
if lsusb | grep -q "Remote USB device"; then
    echo "USB device successfully attached"
else
    echo "Failed to attach USB device"
    exit 1
fi 