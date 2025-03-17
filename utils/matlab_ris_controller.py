import logging
import time
from typing import Dict, Any, Tuple
import numpy as np

logger = logging.getLogger(__name__)

class MatlabRISController:
    """
    方案一：MATLAB參與運行的RIS控制器
    通過MATLAB Engine直接進行所有操作，包括相位計算和RIS控制
    """
    
    def __init__(self, matlab_engine):
        """
        初始化MATLAB RIS控制器
        
        Args:
            matlab_engine: 已初始化的MATLAB引擎實例
        """
        self.eng = matlab_engine
        logger.info("MATLAB RIS控制器已初始化")
    
    def process_and_send(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        處理參數並通過MATLAB直接控制RIS
        
        Args:
            params: 包含所有RIS控制參數的字典
        
        Returns:
            Dict[str, Any]: 操作結果，包含相位和電壓信息
        """
        try:
            # 1. 計算相位
            logger.info("開始計算RIS相位...")
            phs_out, phs_re = self._calculate_phase(params)
            logger.info("相位計算完成")
            
            # 2. 計算電壓
            logger.info("開始計算電壓分布...")
            vol_out = self._calculate_voltage(phs_out, params["freq"])
            logger.info("電壓計算完成")
            
            # 3. 通過MATLAB直接發送到RIS
            logger.info(f"通過MATLAB發送數據到RIS (COM{params['com_port']})...")
            self._send_to_ris(params["id_panel"], vol_out, params["com_port"])
            logger.info("數據發送完成")
            
            # 將MATLAB矩陣轉換為Python列表
            try:
                # 先轉換為numpy數組
                voltage_matrix = np.array(vol_out._data).reshape(vol_out.size[::-1]).T.tolist()
                
                # 記錄矩陣信息以便調試
                logger.info(f"電壓矩陣大小: {len(voltage_matrix)}x{len(voltage_matrix[0]) if voltage_matrix else 0}")
                logger.debug(f"電壓矩陣內容: {voltage_matrix}")
                
            except Exception as e:
                logger.error(f"矩陣轉換錯誤: {str(e)}")
                # 如果轉換失敗，嘗試直接獲取原始數據
                try:
                    # 使用MATLAB的size和get來獲取數據
                    rows = self.eng.size(vol_out, 1)
                    cols = self.eng.size(vol_out, 2)
                    voltage_matrix = [[self.eng.get(vol_out, i+1, j+1)[0][0] for j in range(int(cols))]
                                   for i in range(int(rows))]
                except Exception as e2:
                    logger.error(f"備用轉換也失敗: {str(e2)}")
                    voltage_matrix = []
            
            return {
                "status": "success",
                "message": "RIS配置已通過MATLAB完成",
                "details": {
                    "RIS_Case": params["RIS_Case"],
                    "frequency": params["freq"],
                    "panel_id": params["id_panel"],
                    "voltage_matrix": voltage_matrix
                }
            }
            
        except Exception as e:
            logger.error(f"RIS控制過程出錯: {str(e)}", exc_info=True)
            raise
    
    def _calculate_phase(self, params: Dict[str, Any]) -> Tuple[Any, Any]:
        """
        使用MATLAB計算RIS相位
        
        Args:
            params: RIS參數字典
        
        Returns:
            Tuple[Any, Any]: (相位輸出, 實際相位)
        """
        try:
            # 根據不同的Case選擇不同的計算函數
            ris_case = params["RIS_Case"]
            
            if ris_case == 1:
                # P to D
                return self.eng.cal_ris_phs_p2d(
                    params["freq"],
                    params["xi"], params["yi"], params["zi"],
                    params["theta_r"], params["phi_r"],
                    params["bits"],
                    params["num_px"], params["num_py"],
                    params["fig"],
                    nargout=2
                )
            elif ris_case == 2:
                # P to P
                return self.eng.cal_ris_phs_p2p(
                    params["freq"],
                    params["xi"], params["yi"], params["zi"],
                    params["xr"], params["yr"], params["zr"],
                    params["bits"],
                    params["num_px"], params["num_py"],
                    params["fig"],
                    nargout=2
                )
            elif ris_case == 3:
                # D to P
                return self.eng.cal_ris_phs_d2p(
                    params["freq"],
                    params["theta_i"], params["phi_i"],
                    params["xr"], params["yr"], params["zr"],
                    params["bits"],
                    params["num_px"], params["num_py"],
                    params["fig"],
                    nargout=2
                )
            elif ris_case == 4:
                # D to D
                return self.eng.cal_ris_phs_d2d(
                    params["freq"],
                    params["theta_i"], params["phi_i"],
                    params["theta_r"], params["phi_r"],
                    params["bits"],
                    params["num_px"], params["num_py"],
                    params["fig"],
                    nargout=2
                )
            else:
                # 默認使用 P to D
                logger.warning(f"未知的RIS_Case: {ris_case}，使用默認的P to D模式")
                return self.eng.cal_ris_phs_p2d(
                    params["freq"],
                    params["xi"], params["yi"], params["zi"],
                    params["theta_r"], params["phi_r"],
                    params["bits"],
                    params["num_px"], params["num_py"],
                    params["fig"],
                    nargout=2
                )
                
        except Exception as e:
            logger.error(f"相位計算錯誤: {str(e)}")
            raise
    
    def _calculate_voltage(self, phs_out: Any, freq: float, phase_offset: float = 60.0) -> Any:
        """
        使用MATLAB計算電壓分布
        
        Args:
            phs_out: 相位輸出
            freq: 頻率(GHz)
            phase_offset: 相位偏移(默認60.0)
        
        Returns:
            Any: 電壓分布矩陣
        """
        try:
            # 應用相位偏移
            phs_out_adj = self.eng.plus(phs_out, phase_offset)
            logger.debug(f"相位偏移後的值: {phs_out_adj}")
            
            # 確保輸入是 double 類型
            phs_out_adj = self.eng.double(phs_out_adj)
            
            # 計算電壓
            vol_out = self.eng.phs2vol(phs_out_adj, float(freq))
            
            # 確保輸出也是 double 類型
            vol_out = self.eng.double(vol_out)
            
            # 記錄調試信息
            try:
                size = self.eng.size(vol_out)
                logger.debug(f"電壓矩陣大小: {size[0]}x{size[1]}")
            except:
                logger.debug("無法獲取電壓矩陣大小")
            
            return vol_out
            
        except Exception as e:
            logger.error(f"電壓計算錯誤: {str(e)}")
            raise
    
    def _send_to_ris(self, id_panel: str, vol_out: Any, com_port: int) -> None:
        """
        使用MATLAB直接發送數據到RIS設備
        
        Args:
            id_panel: 面板ID
            vol_out: 電壓分布矩陣
            com_port: COM端口號
        """
        try:
            self.eng.RIS_CMD_Write_Frame(id_panel, vol_out, float(com_port), nargout=0)
        except Exception as e:
            logger.error(f"RIS數據發送錯誤: {str(e)}")
            raise
    
    def validate_parameters(self, params: Dict[str, Any]) -> None:
        """
        驗證輸入參數的有效性
        
        Args:
            params: 參數字典
        
        Raises:
            ValueError: 如果參數無效
        """
        required_params = {
            "RIS_Case": (int, "RIS場景必須是整數"),
            "freq": (float, "頻率必須是浮點數"),
            "xi": (float, "入射點X坐標必須是浮點數"),
            "yi": (float, "入射點Y坐標必須是浮點數"),
            "zi": (float, "入射點Z坐標必須是浮點數"),
            "xr": (float, "反射點X坐標必須是浮點數"),
            "yr": (float, "反射點Y坐標必須是浮點數"),
            "zr": (float, "反射點Z坐標必須是浮點數"),
            "theta_i": (float, "入射角theta必須是浮點數"),
            "phi_i": (float, "入射角phi必須是浮點數"),
            "theta_r": (float, "反射角theta必須是浮點數"),
            "phi_r": (float, "反射角phi必須是浮點數"),
            "bits": (float, "相位比特數必須是浮點數"),
            "num_px": (float, "X方向像素數必須是浮點數"),
            "num_py": (float, "Y方向像素數必須是浮點數"),
            "fig": (float, "繪圖標志必須是浮點數"),
            "id_panel": (str, "面板ID必須是字符串"),
            "com_port": (int, "COM端口必須是整數")
        }
        
        for param_name, (param_type, error_msg) in required_params.items():
            if param_name not in params:
                raise ValueError(f"缺少參數: {param_name}")
            if not isinstance(params[param_name], param_type):
                raise ValueError(error_msg)
    
    def test_connection(self, com_port: int) -> bool:
        """
        測試與RIS設備的連接
        
        Args:
            com_port: COM端口號
        
        Returns:
            bool: 連接是否成功
        """
        try:
            # 使用MATLAB發送測試命令
            self.eng.RIS_CMD_Write_Frame("01", [[0]*20]*20, float(com_port), nargout=0)
            return True
        except Exception as e:
            logger.error(f"RIS連接測試失敗: {str(e)}")
            return False 