clear
clc
close all


%%
addpath('./Tool');


%%
my_COM = 14;


%%
id_panel_m = [];
for loop_num = 1:1
    id_panel = [];
    while (1)
        % Get board ID
        read_value = RIS_CMD_Read_Func('FF','00',my_COM);
    
        if read_value == 0
            break;
        end
    
        read_value = read_value(end);
        read_value = dec2hex(read_value,2);
        id_panel = cat(1,id_panel,read_value);
    
        % Open Level Shifter #3
        RIS_CMD_Write_Func(read_value,'0F','00',my_COM)
    end

    num_panel = size(id_panel,1);
%     for np = 1:num_panel
%         RIS_CMD_Write_Func(id_panel(np,:),'0F','01',my_COM)
%         pause(1)
%     end

    loop_num
    id_panel

    if num_panel == 1
        disp('Read Global ID Success!')
        id_tmp = id_panel';
        id_tmp = id_tmp(:);
        id_tmp = id_tmp';
        id_panel_m = cat(1,id_panel_m,id_tmp);
    else
        disp('Read Global ID Fail!')
        break;
    end
end


