function [disconnected_inport_list, disconnected_outport_list] = ...
    get_disconnected_lists_tshintaiCustomTab(block_list)
%%
% disconnected_inport_list, disconnected_outport_listは、
% 信号線が接続されていないポートの
% 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別、
% ポート位置を記録する。
%%
disconnected_inport_list = cell(1, 5);
disconnected_outport_list = cell(1, 5);

for i = 1:numel(block_list)

    try
        port_handle = get_param(block_list{i}, 'PortHandles');
    catch
        continue;
    end

    % Inport, Enable, Trigger, Ifaction, Resetを合わせた
    % 入力ポートを定義する
    % g_inport_handleはハンドルと上記のポート種別を格納する
    g_inport_handle = set_general_inport(port_handle);

    % 入力ポート、出力ポートの数を調べる
    inport_num = numel(g_inport_handle(:, 1));
    outport_num = numel(port_handle.Outport);

    if (inport_num == 0 && outport_num == 0)
        continue;
    end

    port_info = get_param(block_list{i}, 'PortConnectivity');

    for j = 1:inport_num
        if (port_info(j).SrcBlock < 0)
            disconnected_inport_list = add_port_info( ...
                disconnected_inport_list, block_list{i}, ...
                j, g_inport_handle{j, 1}, g_inport_handle{j, 2}, ...
                get_param(g_inport_handle{j, 1}, 'Position'));
        end
    end
    for j = 1:outport_num
        if isempty(port_info(j + inport_num).DstBlock)
            disconnected_outport_list = add_port_info( ...
                disconnected_outport_list, block_list{i}, ...
                j, port_handle.Outport(j), 'Outport', ...
                get_param(port_handle.Outport(j), 'Position'));
        end
    end

end

end

function g_inport_handle = set_general_inport(port_handle)
%%
inport_handle_type = create_port_handle_type( ...
    port_handle.Inport, 'Inport');
enable_handle_type = create_port_handle_type( ...
    port_handle.Enable, 'Enable');
trigger_handle_type = create_port_handle_type( ...
    port_handle.Trigger, 'Trigger');
ifaction_handle_type = create_port_handle_type( ...
    port_handle.Ifaction, 'Ifaction');
reset_handle_type = create_port_handle_type( ...
    port_handle.Reset, 'Reset');

g_inport_handle = [inport_handle_type; ...
                   enable_handle_type; ...
                   trigger_handle_type; ...
                   ifaction_handle_type; ...
                   reset_handle_type];

g_index = false(size(g_inport_handle, 1), 1);
for i = 1:numel(g_index)
    if ~isempty(g_inport_handle{i, 1})
        g_index(i) = true;
    end
end

g_inport_handle = g_inport_handle(g_index, :);

end

function port_handle_type = create_port_handle_type( ...
    port_handle_vec, type)
%%
port_handle_type = cell(1, 2);
for i = 1:numel(port_handle_vec)
    if isempty(port_handle_type{1, 1})
        port_handle_type{1, 1} = port_handle_vec(i);
        port_handle_type{1, 2} = type;
    else
        temp_handle = cell(1, 2);
        temp_handle{1, 1} = port_handle_vec(i);
        temp_handle{1, 2} = type;
        port_handle_type = [port_handle_type; temp_handle];
    end
end

end

function disconnected_port_list = add_port_info( ...
    disconnected_port_list, parent_block_name, port_num, ...
    port_handle, type, position)
%%
if isempty(disconnected_port_list{1, 1})
    disconnected_port_list{1, 1} = parent_block_name;
    disconnected_port_list{1, 2} = port_num;
    disconnected_port_list{1, 3} = port_handle;
    disconnected_port_list{1, 4} = type;
    disconnected_port_list{1, 5} = position;
else
    port_list = cell(1, 4);
    port_list{1, 1} = parent_block_name;
    port_list{1, 2} = port_num;
    port_list{1, 3} = port_handle;
    port_list{1, 4} = type;
    port_list{1, 5} = position;
    disconnected_port_list = [disconnected_port_list; port_list];
end

end
