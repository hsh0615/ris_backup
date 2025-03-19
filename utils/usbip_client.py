import os
import subprocess
import logging
from typing import Optional, List, Dict

logger = logging.getLogger(__name__)

class USBIPClient:
    def __init__(self, host: str = "host.docker.internal", port: int = 3240):
        self.host = host
        self.port = port
        self.attached_busid = None

    def list_remote_devices(self) -> List[Dict[str, str]]:
        """列出遠程 USB 設備"""
        try:
            cmd = f"usbip list -r {self.host} -p {self.port}"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"Failed to list remote devices: {result.stderr}")
                return []

            devices = []
            for line in result.stdout.split('\n'):
                if 'busid' in line:
                    parts = line.strip().split()
                    if len(parts) >= 3:
                        devices.append({
                            'busid': parts[0],
                            'vendor_id': parts[1],
                            'product_id': parts[2]
                        })
            return devices
        except Exception as e:
            logger.error(f"Error listing remote devices: {str(e)}")
            return []

    def attach_device(self, busid: str) -> bool:
        """連接指定的 USB 設備"""
        try:
            # 加載必要的內核模塊
            subprocess.run(['modprobe', 'usbip_host'], check=True)
            subprocess.run(['modprobe', 'vhci-hcd'], check=True)

            # 連接設備
            cmd = f"usbip attach -r {self.host} -p {self.port} -b {busid}"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"Failed to attach device: {result.stderr}")
                return False

            self.attached_busid = busid
            logger.info(f"Successfully attached device {busid}")
            return True
        except Exception as e:
            logger.error(f"Error attaching device: {str(e)}")
            return False

    def detach_device(self) -> bool:
        """斷開連接的 USB 設備"""
        if not self.attached_busid:
            return True

        try:
            cmd = f"usbip detach -p 0"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"Failed to detach device: {result.stderr}")
                return False

            self.attached_busid = None
            logger.info("Successfully detached device")
            return True
        except Exception as e:
            logger.error(f"Error detaching device: {str(e)}")
            return False

    def is_device_attached(self) -> bool:
        """檢查是否有設備已連接"""
        return self.attached_busid is not None

    def get_attached_device(self) -> Optional[str]:
        """獲取當前連接的設備 ID"""
        return self.attached_busid 