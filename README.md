# RIS 控制服務器

這是一個用於控制可重構智能表面(Reconfigurable Intelligent Surface, RIS)的API服務器。該服務器使用Python與MATLAB引擎進行通信，以控制RIS硬件。

## 系統要求

- Windows操作系統
- Python 3.8（與MATLAB Engine API兼容）
- MATLAB（已安裝）
- Docker（可選，用於容器化部署）

## 項目結構

```
RIS_API_SERVER/
├── YTTEK_YTRS0289_release_2024_v1/    # MATLAB工具箱（已包含在專案中）
├── utils/                              # Python工具類
├── app.py                             # 主應用服務器
├── config.py                          # 配置文件
├── requirements.txt                   # Python依賴
├── .env                              # 環境變量配置
├── Dockerfile                        # Docker構建文件
├── docker-compose.yml               # Docker編排文件
└── start_ris_server.bat              # 本地啟動腳本
```

## 快速開始

### 使用 Docker（推薦）

1. 確保已安裝 Docker 和 Docker Compose

2. 配置環境變量：
   - 複製 `.env.example` 為 `.env`（如果尚未創建）
   - 修改 `.env` 中的配置，特別是 MATLAB 路徑和串口設置

3. 構建和啟動容器：
   ```bash
   docker-compose up -d --build
   ```

4. 查看日誌：
   ```bash
   docker-compose logs -f
   ```

5. 停止服務：
   ```bash
   docker-compose down
   ```

### 本地運行（不使用 Docker）

1. 運行`setup_venv_py38.bat`腳本以設置Python環境：
   ```
   setup_venv_py38.bat
   ```

2. 運行`start_ris_server.bat`腳本：
   ```
   start_ris_server.bat
   ```

## Docker 注意事項

1. MATLAB 掛載：
   - 確保 `.env` 中的 `DOCKER_MATLAB_VOLUME` 指向正確的 MATLAB 安裝路徑
   - Windows 路徑需要使用正斜杠 `/`

2. 串口訪問：
   - 容器需要特權模式訪問串口設備
   - 確保 `.env` 中的 `DOCKER_COM_PORT_MAPPING` 設置正確

3. 故障排除：
   - 如果無法訪問串口，檢查 Docker 用戶是否在 `dialout` 組中
   - 確保 MATLAB 許可證在容器中可用

## API文檔

服務器提供以下API端點：

- `GET /`: 服務器狀態頁面
- `GET /health`: 健康檢查
- `POST /set_ris`: 完整的RIS控制
- `POST /set_ris_position`: 簡化版RIS控制

## 故障排除

### Docker 相關問題

1. MATLAB Engine API 問題：
   - 確保 MATLAB 目錄正確掛載
   - 檢查容器內 MATLAB 路徑權限

2. 串口訪問問題：
   - 確保 Docker 有串口訪問權限
   - 檢查串口設備映射是否正確

3. 容器啟動失敗：
   - 檢查日誌：`docker-compose logs ris-api`
   - 確認環境變量配置正確

### 一般問題

### MATLAB Engine API安裝問題

如果MATLAB Engine API安裝失敗，您可以嘗試手動安裝：

1. 打開MATLAB
2. 在MATLAB命令窗口運行：
   ```matlab
   cd(fullfile(matlabroot,'extern','engines','python'))
   system('python setup.py install')
   ```

### Python版本兼容性

MATLAB Engine API可能與某些Python版本不兼容。如果您遇到兼容性問題，請確保使用Python 3.8，這是已知與大多數MATLAB版本兼容的版本。 