function create_constant_mux_source_tshintaiCustomTab()
%% 説明
% ConstantブロックとMuxブロックを組み合わせた
% ベクトル信号を構築する。
% ダイアログに入力された数値に合わせてベクトルの配列数を調整する。
%%
this_model_name = bdroot;
subsys_path = gcs;
port_distance = 40;
edge_length = 48;
distance_cons_mux = 60;

%%
unselect_all_blocks_tshintaiCustomTab(subsys_path);

%%
answer = inputdlg({'ベクトルの要素数を入力してください'}, ...
    '要素数', [1 40], {'3'});

if isempty(answer)
    return;
end

try
    num_of_elements = str2double(answer);
catch
    return;
end

if (num_of_elements < 1.5)
    error('2以上の整数を入力してください');
end
if isnan(num_of_elements)
    error('数字を入力してください');
end

%%
% Constant_infoはConstantブロックのパスと名前を格納する。
Constant_info = cell(num_of_elements, 2);
for i = 1:num_of_elements
    Constant_info{i, 2} = ['Constant_', num2str(i), '__CCM'];
    [Constant_info{i, 1}, Constant_info{i, 2}] = ...
        create_unique_block_name_tshintaiCustomTab( ...
            this_model_name, subsys_path, Constant_info{i, 2});
end

Mux_name = 'Mux__CCM';
[Mux_path, Mux_name] = ...
    create_unique_block_name_tshintaiCustomTab( ...
    this_model_name, subsys_path, Mux_name);

%%
Mux_block_size = [5, ...
    port_distance * (num_of_elements - 1) + edge_length];

add_block('simulink/Signal Routing/Mux', Mux_path);
set_param(Mux_path, 'ShowName', 'off');

Mux_pos = get_param(Mux_path, 'Position');
Mux_pos_new = [...
    Mux_pos(1), ...
    Mux_pos(2), ...
    Mux_pos(1) + Mux_block_size(1), ...
    Mux_pos(2) + Mux_block_size(2)];
set_param(Mux_path, 'Position', Mux_pos_new);

set_param(Mux_path, 'Inputs', num2str(num_of_elements));
set_param(Mux_path, 'Selected', 'on');

%%
Mux_port_handles =get_param(Mux_path, 'PortHandles');
for i = 1:num_of_elements
    add_block('simulink/Sources/Constant', Constant_info{i, 1});
    set_param(Constant_info{i, 1}, 'ShowName', 'off');

    block_pos = get_param(Constant_info{i, 1}, 'Position');
    Constant_size = [block_pos(3) - block_pos(1), ...
                     block_pos(4) - block_pos(2)];
    Constant_center_pos = [...
        (block_pos(3) + block_pos(1)) / 2, ...
        (block_pos(4) + block_pos(2)) / 2];
    each_Mux_port_position = get_param(...
        Mux_port_handles.Inport(i), 'Position');
    offset_vec = [...
        each_Mux_port_position(1) - distance_cons_mux, ...
        each_Mux_port_position(2) - Constant_center_pos(2)];
    block_pos_new = [...
        offset_vec(1) - Constant_size(1), ...
        block_pos(2) + offset_vec(2), ...
        offset_vec(1), ...
        block_pos(4) + offset_vec(2)];
    set_param(Constant_info{i, 1}, 'Position', block_pos_new);
    Constant_port_handles = get_param(...
        Constant_info{i, 1}, 'PortHandles');

    %%
    add_line(subsys_path, ...
        Constant_port_handles.Outport(1), ...
        Mux_port_handles.Inport(i), ...
        'autorouting', 'smart');

    set_param(Constant_info{i, 1}, 'Selected', 'on');
end

end
