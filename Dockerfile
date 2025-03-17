# 使用 Python 3.8 作為基礎鏡像
FROM python:3.8-slim

# 設置工作目錄
WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    socat \
    && rm -rf /var/lib/apt/lists/*

# 創建啟動腳本
RUN echo '#!/bin/bash\n\
# 啟動 socat 在後台運行\n\
socat PTY,link=/dev/ttyS13,raw,echo=0 TCP:host.docker.internal:14 &\n\
\n\
# 等待一下確保 socat 啟動\n\
sleep 2\n\
\n\
# 啟動 Flask 應用\n\
flask run --host=0.0.0.0 --port=5000\n\
' > /app/start.sh && chmod +x /app/start.sh

# 複製所有必要文件
COPY . .

# 安裝 Python 依賴
RUN pip install --no-cache-dir -r requirements.txt

# 設置環境變量
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV FLASK_ENV=development
ENV FLASK_DEBUG=0
ENV SERVER_HOST=0.0.0.0
ENV SERVER_PORT=5000
ENV RIS_USE_MATLAB=false

# 暴露端口
EXPOSE 5000

# 使用啟動腳本作為入口點
CMD ["/app/start.sh"] 