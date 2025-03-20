import os
import sys
import logging
import time
from flask import Flask, request, jsonify
from werkzeug.exceptions import HTTPException
from config import load_config

# 先加載配置
config = load_config()

# Configure logging
logging.basicConfig(
    level=getattr(logging, config['logging']['level'].upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(config['logging']['file'])
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 初始化RIS控制器
from utils.ris_controller import RISController
ris_controller = RISController()

# 添加請求日誌中間件
@app.before_request
def log_request_info():
    logger.info('Request Headers: %s', dict(request.headers))
    logger.info('Request URL: %s %s', request.method, request.url)
    if request.is_json:
        logger.info('Request Body: %s', request.get_json())

@app.after_request
def log_response_info(response):
    logger.info('Response Status: %s', response.status)
    logger.info('Response Headers: %s', dict(response.headers))
    return response

@app.route('/set_ris', methods=['POST'])
def set_ris():
    """
    完整的RIS控制API端點，支持所有參數的自定義
    """
    data = request.json
    if not data:
        return jsonify({
            "error": {
                "code": "NO_DATA",
                "message": "未收到JSON數據"
            }
        }), 400

    try:
        # 驗證必要的參數
        required_params = ['xr', 'yr', 'zr']
        missing_params = [param for param in required_params if param not in data]
        if missing_params:
            return jsonify({
                "error": {
                    "code": "MISSING_PARAMETERS",
                    "message": f"缺少必要的參數: {', '.join(missing_params)}"
                }
            }), 400

        # Extract parameters with defaults
        try:
            params = {
                "RIS_Case": int(data.get("RIS_Case", config['ris']['default_params']['RIS_Case'])),
                "freq": float(data.get("freq", config['ris']['default_params']['freq'])),
                "xi": float(data.get("xi", config['ris']['default_params']['xi'])),
                "yi": float(data.get("yi", config['ris']['default_params']['yi'])),
                "zi": float(data.get("zi", config['ris']['default_params']['zi'])),
                "xr": float(data['xr']),
                "yr": float(data['yr']),
                "zr": float(data['zr']),
                "theta_i": float(data.get("theta_i", config['ris']['default_params']['theta_i'])),
                "phi_i": float(data.get("phi_i", config['ris']['default_params']['phi_i'])),
                "theta_r": float(data.get("theta_r", config['ris']['default_params']['theta_r'])),
                "phi_r": float(data.get("phi_r", config['ris']['default_params']['phi_r'])),
                "bits": float(data.get("bits", config['ris']['default_params']['bits'])),
                "num_px": float(data.get("num_px", config['ris']['default_params']['num_px'])),
                "num_py": float(data.get("num_py", config['ris']['default_params']['num_py'])),
                "fig": float(data.get("fig", config['ris']['default_params']['fig'])),
                "id_panel": data.get("id_panel", config['ris']['default_params']['id_panel']),
                "com_port": int(data.get("com_port", config['ris']['default_com_port']))
            }
        except ValueError as e:
            return jsonify({
                "error": {
                    "code": "INVALID_PARAMETER_TYPE",
                    "message": f"參數類型錯誤: {str(e)}"
                }
            }), 400
        
        logger.info(f"Processing request with parameters: {params}")
        
        # 使用預計算方式處理請求
        logger.info("Using pre-calculated approach")
        result = ris_controller.process_and_send(params)
        
        return jsonify(result)

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        return jsonify({
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": f"服務器內部錯誤: {str(e)}"
            }
        }), 500

@app.route('/set_ris_position', methods=['POST'])
def set_ris_position():
    """
    簡化版的RIS控制API端點，只需要提供接收端位置
    其他參數使用配置文件中的默認值
    
    請求格式:
    {
        "xr": 15.7,        // 接收端 X 坐標
        "yr": 8.9,         // 接收端 Y 坐標
        "zr": 3.1         // 接收端 Z 坐標
    }
    """
    data = request.json
    if not data:
        return jsonify({
            "error": {
                "code": "NO_DATA",
                "message": "未收到JSON數據"
            }
        }), 400

    try:
        # 驗證必要的參數
        required_params = ['xr', 'yr', 'zr']
        missing_params = [param for param in required_params if param not in data]
        if missing_params:
            return jsonify({
                "error": {
                    "code": "MISSING_PARAMETERS",
                    "message": f"缺少必要的參數: {', '.join(missing_params)}"
                }
            }), 400

        try:
            # 使用配置文件中的默認值，只更新接收端位置
            params = config['ris']['default_params'].copy()
            params.update({
                "xr": float(data['xr']),
                "yr": float(data['yr']),
                "zr": float(data['zr']),
                "com_port": config['ris']['default_com_port']
            })
        except ValueError as e:
            return jsonify({
                "error": {
                    "code": "INVALID_PARAMETER_TYPE",
                    "message": f"參數類型錯誤: {str(e)}"
                }
            }), 400

        logger.info(f"Processing simplified request with receiver position: ({params['xr']}, {params['yr']}, {params['zr']})")
        
        # 使用預計算方式處理請求
        logger.info("Using pre-calculated approach")
        result = ris_controller.process_and_send(params)
        
        # 簡化返回結果
        return jsonify({
            "status": "success",
            "position": {
                "xr": params['xr'],
                "yr": params['yr'],
                "zr": params['zr']
            },
            "control_method": "pre_calculated"
        })

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        return jsonify({
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": f"服務器內部錯誤: {str(e)}"
            }
        }), 500

@app.route('/health')
def health_check():
    """
    Health check endpoint
    """
    return jsonify({
        "status": "healthy",
        "controllers": {
            "pre_calculated": "available"
        }
    })

@app.route('/')
def index():
    """
    Home page showing server status
    """
    return """
    <html>
        <head>
            <title>RIS Control Server</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
                h1 { color: #4CAF50; }
                .container { max-width: 800px; margin: 0 auto; }
                .card { border: 1px solid #ddd; border-radius: 8px; padding: 20px; margin-bottom: 20px; }
                .success { color: green; }
                .code { font-family: monospace; background: #f5f5f5; padding: 2px 5px; border-radius: 3px; }
                .method { margin: 10px 0; padding: 10px; background: #f9f9f9; border-left: 4px solid #4CAF50; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>RIS Control Server</h1>
                <div class="card">
                    <h2>Status: <span class="success">Running</span></h2>
                    <p>The RIS Control Server is operational and ready to process requests.</p>
                    <p>Control method:</p>
                    <div class="method">
                        <h3>Pre-calculated Control</h3>
                        <p>使用預計算方式，延遲更低，適合固定場景。</p>
                    </div>
                </div>
                <div class="card">
                    <h2>API Usage</h2>
                    <p>Use the <code>/set_ris</code> endpoint with POST requests to configure the RIS device.</p>
                    <p>Example request:</p>
                    <pre><code>
{
    "RIS_Case": 2,
    "freq": 29.4,
    ...
}
                    </code></pre>
                </div>
            </div>
        </body>
    </html>
    """

# 添加全局錯誤處理器
@app.errorhandler(400)
def bad_request(e):
    return jsonify({
        "error": {
            "code": "BAD_REQUEST",
            "message": "請求格式錯誤或缺少必要參數"
        }
    }), 400

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({
        "error": {
            "code": "METHOD_NOT_ALLOWED",
            "message": "不支持的HTTP方法"
        }
    }), 405

@app.errorhandler(HTTPException)
def handle_http_exception(e):
    return jsonify({
        "error": {
            "code": e.name.upper().replace(' ', '_'),
            "message": e.description
        }
    }), e.code

@app.errorhandler(Exception)
def handle_exception(e):
    logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
    return jsonify({
        "error": {
            "code": "INTERNAL_SERVER_ERROR",
            "message": "服務器內部錯誤"
        }
    }), 500

if __name__ == '__main__':
    port = config['server']['port']
    host = config['server']['host']
    debug = config['server']['debug']
    
    logger.info(f"Starting RIS Server on {host}:{port} (debug={debug})")
    app.run(debug=debug, host=host, port=port) 