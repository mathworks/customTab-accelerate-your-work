function arrange_port_position_tshintaiCustomTab()
%% 説明
% 選択したブロック同士のポート位置が横一列に揃うように
% ブロックの上下位置を並べ替えます。
% また、同じ線で接続されたブロックグループを探し、
% そのグループごとに並べます。
% 合わせる位置は、選択されたブロックの終端ブロックの
% 　接続先ポート位置である。
%%
selected_block_list = find_system(gcs, ...
        'SearchDepth',1, ...
        'Selected','on');

if numel(selected_block_list) < 1
    return;
end

if strcmp(selected_block_list{1}, gcs)
    if numel(selected_block_list) < 2
        return;
    end
    selected_block_list = selected_block_list(2:end);
end

% 名前に改行が含まれている場合、スペースに置き換える
for i = 1:numel(selected_block_list)
    name = strrep(selected_block_list(i), newline, ' ');
    selected_block_list(i) = name;
end

%%
dst_block_info = cell(numel(selected_block_list), 3);
dst_block_valid_flag = true(numel(selected_block_list), 1);
for i = 1:numel(selected_block_list)
    % dst_block_infoの要素はそれぞれ、
    % 一番上の出力ポートから接続されているブロック名、
    % その接続元ポート上下位置、接続先ポート上下位置である。
    dst_block_info(i, :) = ...
        block_info_connected_from(selected_block_list{i});
    if isempty(dst_block_info{i, 1})
        dst_block_valid_flag(i) = false;
    end
end
dst_block_info = dst_block_info(dst_block_valid_flag, :);
if isempty(dst_block_info)
    return;
end
src_block_names = selected_block_list(dst_block_valid_flag);

%%
% block_group_infoの要素はそれぞれ
% 繋がっているブロックグループの終端ブロック名、
% ブロックグループの右端のブロックが接続されている終端ポート位置である。
block_group_info = cell(numel(src_block_names), 2);

for i = 1:numel(src_block_names)
    % 接続先の終端ブロックを探す
    find_flag = false;
    terminal_block = dst_block_info{i, 1};
    previous_block = src_block_names{i};
    while(~find_flag)
        find_index = 0;
        for j = 1:numel(dst_block_info(:, 1))
            if strcmp(terminal_block, src_block_names{j})
                find_index = j;
                break;
            end
        end
        
        if (find_index > 0.5)
            previous_block = terminal_block;
            terminal_block = dst_block_info{find_index, 1};
        else
            terminal_block = previous_block;
            find_flag = true;
        end
    end

    block_group_info{i, 1} = terminal_block;

    for j = 1:numel(src_block_names)
        if strcmp(src_block_names{j}, terminal_block)
            block_group_info{i, 2} = dst_block_info{j, 3};
            break;
        end
    end
end

%%
for i = 1:numel(src_block_names)
    pos_diff = block_group_info{i, 2} - dst_block_info{i, 2};

    now_pos = get_param(src_block_names{i}, 'Position');
    next_pos = zeros(1, 4);
    next_pos(1) = now_pos(1);
    next_pos(2) = now_pos(2) + pos_diff;
    next_pos(3) = now_pos(3);
    next_pos(4) = now_pos(4) + pos_diff;

    set_param(src_block_names{i}, 'Position', next_pos);

end

end


function dst_block_info = block_info_connected_from(block_path)
% dst_block_infoの要素はそれぞれ、
% 一番上の出力ポートから接続されているブロック名、
% その接続元ポート上下位置、接続先ポート上下位置である。
dst_block_info = cell(1, 3);
dst_block_info{1, 1} = '';
dst_block_info{1, 2} = [];
dst_block_info{1, 3} = [];

port_handles = get_param(block_path, 'PortHandles');

if numel(port_handles.Outport) < 1
    return;
end

block_position = get_param(block_path, 'Position');
port_position_Y = zeros(numel(port_handles.Outport), 1);
port_valid_flag = true(numel(port_handles.Outport), 1);

for i = 1:numel(port_handles.Outport)
    port_position = ...
        get_param(port_handles.Outport(i), 'Position');

    % ポート位置がブロックの右側面にない場合、無効とする
    if abs(block_position(3) + 5 - port_position(1)) > 0.5
        port_valid_flag(i) = false;
    end
    
    port_position_Y(i) = port_position(2);
end

port_position_Y = port_position_Y(port_valid_flag);
if isempty(port_position_Y)
    return;
end

%%
[min_val, min_index] = min(port_position_Y);

line_handle = get_param(port_handles.Outport(min_index), 'Line');
if (line_handle < 0)
    return;
end
dst_block_handles = get_param(line_handle, 'DstBlockHandle');
if (dst_block_handles < 0)
    return;
end

% 接続先ブロックが複数ある場合、最もポート位置が近いブロックを選択する。
if numel(dst_block_handles) > 1.5
    src_port_handle = get_param(line_handle, 'SrcPortHandle');
    src_port_pos = get_param(src_port_handle, 'Position');
    dst_port_handles = get_param(line_handle, 'DstPortHandle');

    pos_dif = inf;
    near_port_index = 1;
    for i = 1:numel(dst_block_handles)
        dst_port_pos = get_param(dst_port_handles(i), 'Position');
        if (pos_dif > norm(dst_port_pos - src_port_pos))
            pos_dif = norm(dst_port_pos - src_port_pos);
            near_port_index = i;
        end
    end

    dst_block_handle = dst_block_handles(near_port_index);
    dst_port_handle = dst_port_handles(near_port_index);
else
    dst_block_handle = dst_block_handles(1);
    dst_port_handle = get_param(line_handle, 'DstPortHandle');
end

%%
name = get_param(dst_block_handle, 'Name');
name = strrep(name, newline, ' ');

parent = get_param(dst_block_handle, 'Parent');
dst_block_info{1, 1} = [parent, '/', name];

pos = get_param(dst_port_handle, 'Position');
dst_block_info{1, 2} = min_val;
dst_block_info{1, 3} = pos(2);

end