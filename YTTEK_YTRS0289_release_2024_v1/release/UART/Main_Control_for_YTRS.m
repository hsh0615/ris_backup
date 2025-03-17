%% Main Test for YTRS

addpath('./Tool');
% Test Case:
% Case 1: Point to Direction
% Case 2: Point to Point
% Case 3: Direction to Point
% Case 4: Direction to Direction

% Test Case
RIS_Case = 2;

%% Parameter Setting
% Freq
freq = 29.4; % unit: GHz 28.9: N:28.6

% TX
xi = 600;    % unit: mm
yi = 0;   % unit: mm
zi = 0;  % unit: mm

% RX
xr = 600;  % uint: mm
yr = 0;    % uint: mm
zr = 600;  % uint: mm

% TX
theta_i = 0;     % unit: degree
phi_i = 0;       % unit: degree

% RX
theta_r = 60;   % unit: degree
phi_r = 0;       % unit: degree

% Normalize bits
bits = 1;   % Range: 1~11

% Panel
num_px = 1;
num_py = 1; % MAX. = 2;

id_panel = '01'; % RIS ID (HEX)
% id_panel = dec2hex(0:255);

% Figure
% fig = 0, Off
% fig = 1, Plot phase distribution
% fig = 2, Calculate and plot array factor
% fig = 3, Both
fig =  0;

my_COM = 14;


%% Calculate Phase Distribution
switch RIS_Case
    case 1
        % P to D
        [phs_out,phs_re]=cal_ris_phs_p2d(freq,xi,yi,zi,theta_r,phi_r,bits,num_px,num_py,fig);
    case 2
        % P to P
        [phs_out,phs_re]=cal_ris_phs_p2p(freq,xi,yi,zi,xr,yr,zr,bits,num_px,num_py,fig);
    case 3
        % D to P
        [phs_out,phs_re]=cal_ris_phs_d2p(freq,theta_i,phi_i,xr,yr,zr,bits,num_px,num_py,fig);
    case 4
        % D to D
        [phs_out,phs_re]=cal_ris_phs_d2d(freq,theta_i,phi_i,theta_r,phi_r,bits,num_px,num_py,fig);
    otherwise
        % P to D
        [phs_out,phs_re]=cal_ris_phs_p2d(freq,xi,yi,zi,theta_r,phi_r,bits,num_px,num_py,fig);
end


%%
num_panel = size(phs_out,3);

for np = 1:num_panel    
    % Transform Phase into Voltage
    % vol_out: 20x20
    phs_out = phs_out + 60;
    disp(phs_out)
    [vol_out] = phs2vol(phs_out(:,:,np),freq);
    %[vol_out] = ones(20, 20)*0;  
    disp(vol_out);
    id = id_panel(np,:);
    RIS_CMD_Write_Frame(id,vol_out,my_COM);
end



