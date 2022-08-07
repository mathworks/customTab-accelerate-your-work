function all_outport_list = ...
    get_all_outport_lists_tshintaiCustomTab(block_list)
%%
% connected_outport_listは、信号線が接続されている出力ポートの
% 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別、
% ポート位置、ポート名を記録する。
%%
all_outport_list = cell(1, 5);

for i = 1:numel(block_list)

    try
        port_handle = get_param(block_list{i}, 'PortHandles');
    catch
        continue;
    end

    % 出力ポートの数を調べる
    outport_num = numel(port_handle.Outport);

    if (outport_num == 0)
        continue;
    end

    for j = 1:outport_num
        all_outport_list = add_port_info( ...
            all_outport_list, block_list{i}, ...
            j, port_handle.Outport(j), 'Outport', ...
            get_param(port_handle.Outport(j), 'Position'));
    end

end

end


function connected_port_list = add_port_info( ...
    connected_port_list, parent_block_name, port_num, ...
    port_handle, type, position)
%%
if isempty(connected_port_list{1, 1})
    connected_port_list{1, 1} = parent_block_name;
    connected_port_list{1, 2} = port_num;
    connected_port_list{1, 3} = port_handle;
    connected_port_list{1, 4} = type;
    connected_port_list{1, 5} = position;
else
    port_list = cell(1, 4);
    port_list{1, 1} = parent_block_name;
    port_list{1, 2} = port_num;
    port_list{1, 3} = port_handle;
    port_list{1, 4} = type;
    port_list{1, 5} = position;
    connected_port_list = [connected_port_list; port_list];
end

end
