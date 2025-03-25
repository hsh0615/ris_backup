import os
import logging
from dotenv import load_dotenv

# 加載 .env 文件
load_dotenv()

logger = logging.getLogger(__name__)

def load_config():
    """
    Load configuration from environment variables.
    """
    return {
        "server": {
            "host": os.getenv("SERVER_HOST", "0.0.0.0"),
            "port": int(os.getenv("SERVER_PORT", 5000)),
            "debug": os.getenv("FLASK_DEBUG", "0").lower() in ("true", "1", "yes")
        },
        "matlab": {
            "toolbox_path": os.getenv("MATLAB_TOOLBOX_PATH", "YTTEK_YTRS0289_release_2024_v1/release/UART/Tool")
        },
        "ris": {
            "default_com_port": int(os.getenv("RIS_DEFAULT_COM_PORT", 14)),
            "use_matlab": os.getenv("RIS_USE_MATLAB", "true").lower() in ("true", "1", "yes"),
            "default_params": {
                "freq": float(os.getenv("RIS_DEFAULT_FREQ", 28.0)),
                "xi": float(os.getenv("RIS_DEFAULT_XI", 10.5)),
                "yi": float(os.getenv("RIS_DEFAULT_YI", 5.2)),
                "zi": float(os.getenv("RIS_DEFAULT_ZI", 2.3)),
                "bits": int(os.getenv("RIS_DEFAULT_BITS", 8)),
                "fig": int(os.getenv("RIS_DEFAULT_FIG", 3)),
                "num_px": int(os.getenv("RIS_DEFAULT_NUM_PX", 1)),
                "num_py": int(os.getenv("RIS_DEFAULT_NUM_PY", 1)),
                "theta_i": float(os.getenv("RIS_DEFAULT_THETA_I", 0)),
                "phi_i": float(os.getenv("RIS_DEFAULT_PHI_I", 0)),
                "theta_r": float(os.getenv("RIS_DEFAULT_THETA_R", 60)),
                "phi_r": float(os.getenv("RIS_DEFAULT_PHI_R", 0)),
                "RIS_Case": int(os.getenv("RIS_DEFAULT_CASE", 2)),
                "id_panel": os.getenv("RIS_DEFAULT_PANEL_ID", "01")
            }
        },
        "logging": {
            "level": os.getenv("LOG_LEVEL", "INFO"),
            "file": os.getenv("LOG_FILE", "logs/ris_server.log")
        }
    } 
