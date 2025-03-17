%% Main Test for YTRS (Multiple Measurements with Full Setup Time)

clear; clc;
addpath('./Tool');

% -- 基本參數設定 --
freq = 29.4; % GHz
xi = 600; yi = 0;  zi = 0;    % TX座標 (mm)
xr = 600; yr = 0;  zr = 600;  % RX座標 (mm)
bits = 6;                     % Range: 1~11
num_px = 2; 
num_py = 1;
id_panel = '01';              % RIS ID (HEX)
fig = 0;                      % 是否繪圖 (0=不畫, 1=phase, 2=array factor, 3=both)
my_COM = 14;

% -- 測試次數 --
N = 100;  % 您可依需求設定，如 30, 50, 100 ...

% -- 初始化儲存陣列 --
time_full_iter_all            = zeros(N,1);  % 完整測試(單次)所花費的時間
time_cal_ris_phs_p2p_all      = zeros(N,1);
time_phs2vol_all              = zeros(N,1);
time_RIS_CMD_Write_Frame_all  = zeros(N,1);

%% 開始進行多次測試
for iter = 1:N
    %--------------- 整體測試流程開始時間 ---------------
    t_full_start = tic;
    
    %--------------- cal_ris_phs_p2p ---------------
    t_start = tic;
    [phs_out, phs_re] = cal_ris_phs_p2p(freq, xi, yi, zi, ...
                                        xr, yr, zr, bits, ...
                                        num_px, num_py, fig);
    time_cal_ris_phs_p2p_all(iter) = toc(t_start);
    
    %--------------- phs2vol / RIS_CMD_Write_Frame ---------------
    % 這裡以所有 panel(通常是一塊或數塊) 的計算時間取平均，
    % 或您可自行記錄更細的資料。
    num_panel = size(phs_out,3);

    tmp_time_phs2vol             = zeros(num_panel,1);
    tmp_time_RIS_CMD_Write_Frame = zeros(num_panel,1);

    for np = 1:num_panel
        % 如果原程式需加 60，可保留
        phs_out(:,:,np) = phs_out(:,:,np) + 60;
        
        %------------------ phs2vol ------------------
        t_start = tic;
        vol_out = phs2vol(phs_out(:,:,np), freq);
        tmp_time_phs2vol(np) = toc(t_start);

        %----------- RIS_CMD_Write_Frame -----------
        t_start = tic;
        RIS_CMD_Write_Frame(id_panel, vol_out, my_COM);
        tmp_time_RIS_CMD_Write_Frame(np) = toc(t_start);
    end
    
    % 若有多塊 panel，這裡以平均時間作為該次測試此階段的代表
    time_phs2vol_all(iter) = mean(tmp_time_phs2vol);
    time_RIS_CMD_Write_Frame_all(iter) = mean(tmp_time_RIS_CMD_Write_Frame);

    %--------------- 整體測試流程結束時間 ---------------
    time_full_iter_all(iter) = toc(t_full_start);
end

%% 統計結果
mean_cal_ris_phs_p2p    = mean(time_cal_ris_phs_p2p_all);
std_cal_ris_phs_p2p     = std(time_cal_ris_phs_p2p_all);

mean_phs2vol            = mean(time_phs2vol_all);
std_phs2vol             = std(time_phs2vol_all);

mean_RIS_CMD_Write_Frame = mean(time_RIS_CMD_Write_Frame_all);
std_RIS_CMD_Write_Frame  = std(time_RIS_CMD_Write_Frame_all);

mean_full_iter          = mean(time_full_iter_all);
std_full_iter           = std(time_full_iter_all);

%% 顯示量測結果
fprintf('\n========== Execution Time (N=%d) ==========\n', N);
fprintf('cal_ris_phs_p2p      => mean = %.6f s, std = %.6f s\n', ...
    mean_cal_ris_phs_p2p, std_cal_ris_phs_p2p);
fprintf('phs2vol              => mean = %.6f s, std = %.6f s\n', ...
    mean_phs2vol, std_phs2vol);
fprintf('RIS_CMD_Write_Frame  => mean = %.6f s, std = %.6f s\n', ...
    mean_RIS_CMD_Write_Frame, std_RIS_CMD_Write_Frame);

fprintf('Full Setup/Iteration => mean = %.6f s, std = %.6f s\n', ...
    mean_full_iter, std_full_iter);

%% 分布圖 (直方圖)
figure('Name','Time Distribution','Position',[100 100 1600 400]);

subplot(1,4,1);
histogram(time_cal_ris_phs_p2p_all);
title('cal\_ris\_phs\_p2p Time Dist.');
xlabel('Time (s)'); ylabel('Frequency');
grid on;

subplot(1,4,2);
histogram(time_phs2vol_all);
title('phs2vol Time Dist.');
xlabel('Time (s)'); ylabel('Frequency');
grid on;

subplot(1,4,3);
histogram(time_RIS_CMD_Write_Frame_all);
title('RIS\_CMD\_Write\_Frame Time Dist.');
xlabel('Time (s)'); ylabel('Frequency');
grid on;

subplot(1,4,4);
histogram(time_full_iter_all);
title('Full Iteration Time Dist.');
xlabel('Time (s)'); ylabel('Frequency');
grid on;
