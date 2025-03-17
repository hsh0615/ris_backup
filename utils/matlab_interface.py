import os
import logging
import matlab.engine

logger = logging.getLogger(__name__)

class MatlabEngine:
    """
    Class to handle all interactions with the MATLAB engine.
    Provides methods to call MATLAB functions for RIS calculations.
    """
    
    def __init__(self, toolbox_path):
        """
        Initialize the MATLAB engine and add required paths.
        
        Args:
            toolbox_path (str): Path to the MATLAB toolbox directory
        """
        self.eng = None
        self.toolbox_path = toolbox_path
        self._start_engine()
        
    def _start_engine(self):
        """Start the MATLAB engine and add toolbox path"""
        try:
            logger.info("Starting MATLAB engine...")
            self.eng = matlab.engine.start_matlab()
            
            # Add toolbox path and its Tool subdirectory
            if os.path.exists(self.toolbox_path):
                # Add main toolbox path
                self.eng.addpath(self.toolbox_path)
                logger.info(f"Added MATLAB toolbox path: {self.toolbox_path}")
                
                # Add Tool subdirectory if it exists
                tool_path = os.path.join(self.toolbox_path, 'Tool')
                if os.path.exists(tool_path):
                    self.eng.addpath(tool_path)
                    logger.info(f"Added MATLAB Tool path: {tool_path}")
                
                # Verify required functions exist
                required_functions = [
                    'cal_ris_phs_p2p',
                    'cal_ris_phs_p2d',
                    'cal_ris_phs_d2p',
                    'cal_ris_phs_d2d',
                    'phs2vol',
                    'RIS_CMD_Write_Frame'
                ]
                
                for func in required_functions:
                    if not hasattr(self.eng, func):
                        logger.warning(f"Required MATLAB function '{func}' not found in path")
                
            else:
                logger.error(f"MATLAB toolbox path does not exist: {self.toolbox_path}")
                raise FileNotFoundError(f"MATLAB toolbox path not found: {self.toolbox_path}")
                
            logger.info("MATLAB engine started successfully")
            
        except Exception as e:
            logger.error(f"Failed to start MATLAB engine: {str(e)}")
            raise
    
    def shutdown(self):
        """Safely shut down the MATLAB engine"""
        if self.eng:
            try:
                self.eng.quit()
                logger.info("MATLAB engine shut down")
            except Exception as e:
                logger.error(f"Error shutting down MATLAB engine: {str(e)}")
    
    def __getattr__(self, name):
        """
        Proxy all unknown attributes to the MATLAB engine
        This allows direct access to MATLAB functions
        """
        if self.eng is None:
            raise RuntimeError("MATLAB engine not initialized")
        return getattr(self.eng, name)
    
    def calculate_phase(self, params):
        """
        Calculate RIS phase using MATLAB functions
        
        Args:
            params (dict): Dictionary containing calculation parameters
            
        Returns:
            tuple: (phase_output, phase_real)
        """
        try:
            # Extract parameters
            freq = float(params.get("freq"))
            xi = float(params.get("xi"))
            yi = float(params.get("yi"))
            zi = float(params.get("zi"))
            xr = float(params.get("xr"))
            yr = float(params.get("yr"))
            zr = float(params.get("zr"))
            bits = float(params.get("bits"))
            num_px = float(params.get("num_px"))
            num_py = float(params.get("num_py"))
            fig = float(params.get("fig"))
            
            logger.info(f"Calling MATLAB cal_ris_phs_p2p with freq={freq}, xi={xi}, yi={yi}, zi={zi}, "
                        f"xr={xr}, yr={yr}, zr={zr}, bits={bits}, num_px={num_px}, num_py={num_py}, fig={fig}")
            
            # Call the MATLAB function
            phs_out, phs_re = self.eng.cal_ris_phs_p2p(
                freq, xi, yi, zi, xr, yr, zr,
                bits, num_px, num_py, fig,
                nargout=2
            )
            
            logger.info("MATLAB cal_ris_phs_p2p calculation completed successfully")
            return phs_out, phs_re
            
        except Exception as e:
            logger.error(f"Error in MATLAB phase calculation: {str(e)}")
            raise
    
    def calculate_voltage(self, phs_out, freq, phase_offset=60.0):
        """
        Calculate voltage distribution from phase
        
        Args:
            phs_out: Phase output from calculate_phase
            freq (float): Frequency
            phase_offset (float): Phase offset adjustment (default: 60.0)
            
        Returns:
            matlab.double: Voltage map (typically 20x20)
        """
        try:
            # Adjust phase with offset
            logger.info(f"Adjusting phase with offset {phase_offset}")
            phs_out_adj = self.eng.plus(phs_out, phase_offset)
            
            # Convert phase to voltage
            logger.info(f"Converting phase to voltage with freq={freq}")
            vol_out = self.eng.phs2vol(phs_out_adj, freq)
            
            logger.info("Voltage calculation completed successfully")
            return vol_out
            
        except Exception as e:
            logger.error(f"Error in MATLAB voltage calculation: {str(e)}")
            raise
    
    def send_to_ris(self, id_panel, vol_out, com_port):
        """
        Send voltage data to RIS device using MATLAB function
        
        Args:
            id_panel (str): Panel ID
            vol_out: Voltage map from calculate_voltage
            com_port (int): COM port number
            
        Returns:
            bool: True if successful
        """
        try:
            logger.info(f"Sending data to RIS on COM{com_port} with panel ID {id_panel}")
            self.eng.RIS_CMD_Write_Frame(id_panel, vol_out, float(com_port), nargout=0)
            logger.info("Data sent to RIS successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error sending data to RIS: {str(e)}")
            raise 