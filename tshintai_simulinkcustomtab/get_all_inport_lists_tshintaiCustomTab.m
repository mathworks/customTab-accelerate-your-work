function all_inport_list = ...
    get_all_inport_lists_tshintaiCustomTab(block_list, general_flag)
%%
% all_inport_listは、入力ポートの
% 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別、
% ポート位置を記録する。
%%
all_inport_list = cell(1, 5);

for i = 1:numel(block_list)

    try
        port_handle = get_param(block_list{i}, 'PortHandles');
    catch
        continue;
    end

    % 入力ポートの数を調べる
    if (general_flag)
        g_inport_handle = set_general_inport(port_handle);
        inport_num = size(g_inport_handle, 1);

        port_handles = zeros(inport_num, 1);
        for j = 1:inport_num
            port_handles(j) = g_inport_handle{j, 1};
        end
    else
        inport_num = numel(port_handle.Inport);
        port_handles = port_handle.Inport;
    end

    if (inport_num == 0)
        continue;
    end

    for j = 1:inport_num
        all_inport_list = add_port_info( ...
            all_inport_list, block_list{i}, ...
            j, port_handles(j), 'Inport', ...
            get_param(port_handles(j), 'Position'));
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
