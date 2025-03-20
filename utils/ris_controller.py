import logging
import time
import serial
import os
import re
import numpy as np

logger = logging.getLogger(__name__)

class RISController:
    """
    Controller for RIS (Reconfigurable Intelligent Surface) devices.
    Implements direct control by sending 810 bytes packet.
    """
    
    def __init__(self, matlab_engine=None):
        """
        Initialize the RIS Controller
        
        Args:
            matlab_engine: Optional MATLAB engine instance (not used in this implementation)
        """
        self.matlab_engine = None  # We don't use MATLAB engine in this implementation
    
    def _find_closest_data_file(self, xr, yr, zr):
        """
        找到最接近的數據文件
        使用歐式距離計算最接近的參數組合
        """
        # 獲取所有數據文件
        data_dir = "RIS_BusData"
        all_files = [f for f in os.listdir(data_dir) if f.endswith('_hex_data.txt')]
        
        if not all_files:
            raise ValueError(f"No data files found in {data_dir}")
        
        min_distance = float('inf')
        closest_file = None
        
        for file in all_files:
            try:
                # 從文件名提取坐標
                coords = file.split('_')
                file_xr = float(coords[coords.index('xr') + 1])
                file_yr = float(coords[coords.index('yr') + 1])
                file_zr = float(coords[coords.index('zr') + 1])
                
                # 計算歐式距離
                distance = np.sqrt((xr - file_xr)**2 + (yr - file_yr)**2 + (zr - file_zr)**2)
                
                logger.debug(f"File: {file}, Distance: {distance}")
                
                # 更新最近的文件
                if distance < min_distance:
                    min_distance = distance
                    closest_file = file
            except (ValueError, IndexError) as e:
                logger.warning(f"Skipping invalid filename: {file}, Error: {e}")
                continue
        
        if closest_file is None:
            raise ValueError("No valid data files found")
        
        full_path = os.path.join(data_dir, closest_file)
        logger.info(f"Selected data file: {full_path} (distance: {min_distance:.2f})")
        return full_path

    def process_and_send(self, params):
        """
        Process parameters and send to device
        
        Args:
            params (dict): Dictionary of parameters for RIS control
            
        Returns:
            dict: Result of the operation
        """
        try:
            xr = params.get("xr", 0)
            yr = params.get("yr", 0)
            zr = params.get("zr", 390)
            
            # 找到最接近的數據文件
            data_file = self._find_closest_data_file(xr, yr, zr)
            
            # 讀取數據文件並驗證大小
            with open(data_file, 'rb') as f:
                packet = f.read()
            
            if len(packet) != 810:
                # 如果數據不是 810 bytes，嘗試處理文本格式
                with open(data_file, 'r') as f:
                    hex_data = f.read().strip()
                    # 移除所有空白字符
                    hex_data = ''.join(hex_data.split())
                    # 轉換為 bytes
                    packet = bytes.fromhex(hex_data)
            
            if len(packet) != 810:
                raise ValueError(f"Invalid packet size after processing: {len(packet)} bytes (expected 810)")
            
            # 使用環境變量中的串口設備
            port_name = os.getenv('SERIAL_PORT', '/dev/ttyUSB0')
            
            logger.info(f"Sending {len(packet)} bytes to RIS device on {port_name}")
            self.send_via_serial(port_name, packet)
            
            return {
                "status": "success",
                "message": "Data sent to RIS device using direct serial communication",
                "data_file": os.path.basename(data_file)
            }
            
        except Exception as e:
            logger.error(f"Error in RIS processing: {str(e)}", exc_info=True)
            raise

    def _prepare_fixed_packet(self, id_panel="01", xr=0, yr=0, zr=390):
        """
        Prepare packet based on receiver coordinates by selecting the nearest pre-calculated data
        
        Args:
            id_panel (str): Panel ID (default: "01")
            xr (float): Receiver x coordinate
            yr (float): Receiver y coordinate
            zr (float): Receiver z coordinate
            
        Returns:
            bytes: 810 bytes packet
        """
        try:
            # Fixed transmitter position from filenames
            xi = 200
            yi = 0
            zi = 390
            
            # Pre-defined receiver positions from data files
            rx_positions = [
                (-200, -200), (-200, 0), (-200, 200),
                (0, -200), (0, 0), (0, 200),
                (200, -200), (200, 0), (200, 200)
            ]
            
            # Find nearest position
            min_distance = float('inf')
            nearest_pos = None
            
            for rx, ry in rx_positions:
                # Calculate Euclidean distance in XY plane (since z is constant)
                distance = ((xr - rx) ** 2 + (yr - ry) ** 2) ** 0.5
                if distance < min_distance:
                    min_distance = distance
                    nearest_pos = (rx, ry)
            
            # Construct filename based on nearest position - using integer values
            filename = f"RIS_BusData/xi_{int(xi)}_yi_{int(yi)}_zi_{int(zi)}_xr_{int(nearest_pos[0])}_yr_{int(nearest_pos[1])}_zr_{int(zr)}_hex_data.txt"
            
            logger.info(f"Selected data file: {filename} (distance: {min_distance:.2f})")
            
            # Read and parse hex data from file
            with open(filename, 'r') as f:
                hex_str = f.read().strip().replace('\n', ' ')
                hex_bytes = bytes.fromhex(hex_str)
                
            if len(hex_bytes) != 810:
                raise ValueError(f"Invalid data size in file: {len(hex_bytes)} bytes (expected 810)")
                
            return hex_bytes
            
        except Exception as e:
            logger.error(f"Error preparing packet from data file: {str(e)}")
            raise

    def send_via_serial(self, port_name, packet):
        """
        Send data packet directly via serial port
        
        Args:
            port_name (str): Full port name (e.g. 'COM14' or '/dev/ttyS3')
            packet (bytes): Data packet to send (810 bytes)
            
        Returns:
            bytes: Response data
        """
        try:
            # 驗證數據包大小
            if len(packet) != 810:
                raise ValueError(f"Invalid packet size: {len(packet)} bytes (expected 810)")
            
            # 檢查串口設備是否存在
            if not os.path.exists(port_name):
                raise FileNotFoundError(f"Serial port {port_name} does not exist")
            
            # 檢查串口權限
            try:
                with open(port_name, 'rb') as f:
                    pass
            except PermissionError:
                raise PermissionError(f"No permission to access {port_name}")
            
            # 打開串口連接
            ser = None
            try:
                # 使用基本的串口配置
                ser = serial.Serial(
                    port=port_name,
                    baudrate=28800,
                    bytesize=serial.EIGHTBITS,
                    parity=serial.PARITY_NONE,
                    stopbits=serial.STOPBITS_ONE,
                    timeout=1,
                    exclusive=False
                )
                
                # 發送數據
                logger.info(f"Sending {len(packet)} bytes to {port_name}")
                ser.write(packet)
                logger.info("Data sent. Waiting for response...")
                
                # 等待響應
                time.sleep(1)
                response_data = ser.read(ser.in_waiting)
                
                if response_data:
                    response_hex = response_data.hex().upper()
                    logger.info(f"Received response: {response_hex}")
                else:
                    logger.warning("No response received from RIS")
                
                return response_data
                
            finally:
                if ser and ser.is_open:
                    ser.close()
            
        except serial.SerialException as e:
            logger.error(f"Serial communication error: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Error in serial communication: {str(e)}")
            raise 