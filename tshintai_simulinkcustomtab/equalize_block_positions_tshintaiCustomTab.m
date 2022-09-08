function equalize_block_positions_tshintaiCustomTab()
%% 説明
% 選択した二つのブロックの間隔と同じになるように、
% 他のブロック同士の間隔を自動的に調整する。
% 調整されるブロックは、その二つのブロックと信号線で
% 繋がれているブロックと、そのブロックに直接繋がっている他のブロックである。
% また、そのブロックは1番目のInport, Outportを介して繋がっている場合に、
% かつ、信号線の流れが左から右に流れる向きである場合にのみ
% 繋がっていると判定し、間隔を調整する。
% また、ブロックを一つだけ選択した場合は、そのブロックが
% Inportのみ、またはOutportのみ存在する場合に、その1番目のポートから
% 繋がる先のブロックの間隔を調整する。
%%
current_layer = gcs;
selected_block_list = find_system(current_layer, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1, ...
        'Selected','on');

if (numel(selected_block_list) < 1)
    return;
end

if strcmp(selected_block_list{1}, current_layer)
    if numel(selected_block_list) < 2
        return;
    end
    selected_block_list = selected_block_list(2:end);
end

if numel(selected_block_list) > 2.5
    return;
end

if numel(selected_block_list) < 1.5
    selected_block_list = get_connected_block_pair(selected_block_list, ...
                            current_layer);
    if isempty(selected_block_list)
        return;
    end
end

%%
block_pos_mat = zeros(2, 4);
for i = 1:size(block_pos_mat, 1)
    block_pos_mat(i, :) = get_param(selected_block_list{i}, ...
        'Position');
end

block_pos_x_dif = (block_pos_mat(2, 1) + block_pos_mat(2, 3)) - ...
                  (block_pos_mat(1, 1) + block_pos_mat(1, 3));

if (block_pos_x_dif > 0)
    right_block_path = selected_block_list{2};
    left_block_path  = selected_block_list{1};

    right_left_side_pos = block_pos_mat(2, 1);
    left_right_side_pos = block_pos_mat(1, 3);
else
    right_block_path = selected_block_list{1};
    left_block_path  = selected_block_list{2};

    right_left_side_pos = block_pos_mat(1, 1);
    left_right_side_pos = block_pos_mat(2, 3);
end

block_distance = right_left_side_pos - left_right_side_pos;
if (block_distance < 0)
    error('ブロックが重なっています。距離を空けて配置してください。');
end

%%
connected_blocks_right_side = find_connected_blocks( ...
    right_block_path, true);
connected_blocks_left_side = find_connected_blocks( ...
    left_block_path, false);

%%
if ~isempty(connected_blocks_right_side)
    arrange_distance_of_blocks(connected_blocks_right_side, ...
        block_distance, true);
end
if ~isempty(connected_blocks_left_side)
    arrange_distance_of_blocks(connected_blocks_left_side, ...
        block_distance, false);
end

end


function block_pair = get_connected_block_pair(block_list, current_layer)
block_pair = '';

port_handles = get_param(block_list{1}, 'PortHandles');
side_info = check_block_connection_is_one_side(port_handles);

if side_info{1}
    if ~side_info{2}
        line_handle = get_param(port_handles.Outport(1), 'Line');
        block_handle = get_param(line_handle, 'DstBlockHandle');
    else
        line_handle = get_param(port_handles.Inport(1), 'Line');
        block_handle = get_param(line_handle, 'SrcBlockHandle');
    end

    if numel(block_handle) > 1.5
        block_handle = find_nearest_block(block_list{1}, block_handle);
    end
    block_name = get_param(block_handle, 'Name');

    block_pair = cell(2, 1);
    block_pair{1} = block_list{1};
    block_pair{2} = [current_layer, '/', block_name];
end

end

function side_info = check_block_connection_is_one_side(port_handles)
% side_infoは、1番目に一方だけブロックが接続されているかどうか、
% 2番目にどちらの側かをしめすフラグを格納する。右側がtrueである。
side_info = cell(2, 1);

no_inport = false;
no_outport = false;

if isempty(port_handles.Inport)
    no_inport = true;
else
    line_handle = get_param(port_handles.Inport, 'Line');
    if (line_handle < 0)
        no_inport = true;
    else
        block_handle = get_param(line_handle, 'SrcBlockHandle');
        if (block_handle < 0)
            no_inport = true;
        end
    end
end
if isempty(port_handles.Outport)
    no_outport = true;
else
    line_handle = get_param(port_handles.Outport, 'Line');
    if (line_handle < 0)
        no_outport = true;
    else
        block_handle = get_param(line_handle, 'SrcBlockHandle');
        if (block_handle < 0)
            no_outport = true;
        end
    end
end

side_info{1} = xor(no_inport, no_outport);
side_info{2} = no_outport & side_info{1};

end

function nearest_block_handle = find_nearest_block(source_block, ...
    block_handle)

if numel(block_handle) < 1.5
    nearest_block_handle = block_handle;
else
    position_0 = get_param(source_block, 'Position');
    pos_vec_0 = [(position_0(3) + position_0(1)) / 2; ...
                 (position_0(4) + position_0(2)) / 2];
    min_distance = inf;
    min_index = 0;

    for i = 1:numel(block_handle)
        block_position = get_param(block_handle(i), 'Position');
        block_pos_vec = [(block_position(3) + block_position(1)) / 2; ...
                         (block_position(4) + block_position(2)) / 2];
        block_distance = sum((block_pos_vec - pos_vec_0) .^ 2);

        if (min_distance > block_distance)
            min_distance = block_distance;
            min_index = i;
        end

    end

    nearest_block_handle = block_handle(min_index);
end

end

function connected_blocks_info = find_connected_blocks( ...
    source_block_path, right_flag)
% right_flagがtrueのとき、右側に繋がるブロックを探す。
% right_flagがfalseのとき、左側に繋がるブロックを探す。

% connected_blocks_infoの各要素は順番に
% 1番目の要素が繋がっているブロックの名前、ハンドル、
% そのブロックの1番目の入力ポートハンドル、1番目の出力ポートハンドル、
% 接続元のブロックハンドル（source_block_pathに近い方を元とする）、
% そのブロックの2番目以降の入力ポートに接続されているブロックハンドル、
% そのブロックの2番目以降の出力ポートに接続されているブロックハンドル、
%%
if right_flag
    block_destination = 'DstBlockHandle';
else
    block_destination = 'SrcBlockHandle';
end

% 最初にsource_block_pathのブロック情報を記録する。
% 5番目のブロックハンドルは自分自身とする。
connected_blocks_info = cell(1, 7);

block_text = strsplit(source_block_path, '/');
connected_blocks_info{1, 1} = block_text{end};
connected_blocks_info{1, 2} = ...
    get_param(source_block_path, 'Handle');

port_handles = get_param(source_block_path, 'PortHandles');

if ~isempty(port_handles.Inport)
    connected_blocks_info{1, 3} = port_handles.Inport(1);
    connected_blocks_info{1, 6} = ...
        get_other_block_handles(port_handles.Inport, 'SrcBlockHandle');
end
if ~isempty(port_handles.Outport)
    connected_blocks_info{1, 4} = port_handles.Outport(1);
    connected_blocks_info{1, 7} = ...
        get_other_block_handles(port_handles.Outport, 'DstBlockHandle');
end
connected_blocks_info{1, 5} = connected_blocks_info{1, 2};



%%
if (right_flag)
    if isempty(port_handles.Outport)
        return;
    else
        source_port_handle = port_handles.Outport(1);
    end
else
    if isempty(port_handles.Inport)
        return;
    else
        source_port_handle = port_handles.Inport(1);
    end
end


%%
while(1)
    line_handle = get_param(source_port_handle, 'Line');
    if (line_handle < 0)
        break;
    end

    parent_block_path = get_param(source_port_handle, 'Parent');
    source_block_handle = get_param(parent_block_path, 'Handle');
    dest_block_handles = get_param(line_handle, block_destination);
    dest_block_handle = dest_block_handles(1);
    
    % もしブロックの接続信号線が左から右になっていない場合は
    % 繋がっていないものとする
    wrong_connection = check_wrong_direction_connection( ...
    source_block_handle, dest_block_handle, right_flag);
    if (wrong_connection)
        break;
    end
    
    dest_block_name = get_param(dest_block_handle, 'Name');

    dest_block_port_handles = get_param(dest_block_handle, 'PortHandles');

    temp_info = cell(1, 7);
    temp_info{1, 1} = dest_block_name;
    temp_info{1, 2} = dest_block_handle;
    if ~isempty(dest_block_port_handles.Inport)
        temp_info{1, 3} = dest_block_port_handles.Inport(1);
        temp_info{1, 6} = get_other_block_handles( ...
            dest_block_port_handles.Inport, 'SrcBlockHandle');
    end
    if ~isempty(dest_block_port_handles.Outport)
        temp_info{1, 4} = dest_block_port_handles.Outport(1);
        temp_info{1, 7} = get_other_block_handles( ...
            dest_block_port_handles.Outport, 'DstBlockHandle');
    end
    temp_info{1, 5} = source_block_handle;

    connected_blocks_info = [ ...
        connected_blocks_info; temp_info];


    if (right_flag)
        if isempty(dest_block_port_handles.Outport)
            break;
        else
            source_port_handle = ...
                dest_block_port_handles.Outport(1);
        end
    else
        if isempty(dest_block_port_handles.Inport)
            break;
        else
            source_port_handle = ...
                dest_block_port_handles.Inport(1);
        end
    end
end

end

function wrong_connection = check_wrong_direction_connection( ...
    source_block_handle, dest_block_handle, right_flag)
wrong_connection = false;

source_pos = get_param(source_block_handle, 'Position');
dest_pos   = get_param(dest_block_handle,   'Position');
pos_dif = (dest_pos(1) + dest_pos(3)) - ...
    (source_pos(1) + source_pos(3));
if (right_flag)
    if (pos_dif <= 0)
        wrong_connection = true;
    end
else
    if (pos_dif >= 0)
        wrong_connection = true;
    end
end

end

function arrange_distance_of_blocks(blocks_info, ...
    block_distance, right_flag)
%%
% blocks_infoの各要素については
% find_connected_blocks関数のコメントを参照。
%%

for i = 1:size(blocks_info, 1)
    dest_position = get_param(blocks_info{i, 2}, 'Position');
    next_dest_pos = dest_position;

    % 自身の位置を調整
    if (i > 1)
        source_position = get_param(blocks_info{i, 5}, 'Position');

        if (right_flag)
            next_dest_pos = calc_right_side_off_position( ...
                source_position, dest_position, block_distance);
        else
            next_dest_pos = calc_left_side_off_position( ...
                source_position, dest_position, block_distance);
        end

        set_param(blocks_info{i, 2}, 'Position', next_dest_pos);        
    end
    dest_position = next_dest_pos;
    
    % 他のブロックの位置を調整
    for j = 1:numel(blocks_info{i, 6})
        if (blocks_info{i, 6}(j) < 0)
            continue;
        end

        wrong_connection = check_wrong_direction_connection( ...
            blocks_info{i, 2}, blocks_info{i, 6}(j), false);
        if (wrong_connection)
            continue;
        end

        sub_block_pos = get_param(blocks_info{i, 6}(j), 'Position');
        
        next_dest_pos = calc_left_side_off_position( ...
                dest_position, sub_block_pos, block_distance);

        set_param(blocks_info{i, 6}(j), 'Position', next_dest_pos);
    end
    for j = 1:numel(blocks_info{i, 7})
        if (blocks_info{i, 7}(j) < 0)
            continue;
        end

        wrong_connection = check_wrong_direction_connection( ...
            blocks_info{i, 2}, blocks_info{i, 7}(j), true);
        if (wrong_connection)
            continue;
        end

        if (blocks_info{i, 7}(j) < 0)
            continue;
        end

        sub_block_pos = get_param(blocks_info{i, 7}(j), 'Position');

        next_dest_pos = calc_right_side_off_position( ...
            dest_position, sub_block_pos, block_distance);

        set_param(blocks_info{i, 7}(j), 'Position', next_dest_pos);
    end
end

end

function block_handles = get_other_block_handles( ...
    port_handles, block_destination)
block_handles = '';

if numel(port_handles) < 1.5
    return;
end

block_handles = -1 * ones(numel(port_handles) - 1, 1, 'double');

for i = 2:numel(port_handles)
    line_handle = get_param(port_handles(i), 'Line');
    if (line_handle < 0)
        continue;
    end

    block_handles(i - 1) = get_param(line_handle, block_destination);
end

end

function next_dest_pos = calc_right_side_off_position( ...
    source_position, dest_position, block_distance)
next_dest_pos = zeros(1, 4);

next_dest_pos(1) = source_position(3) + block_distance;
next_dest_pos(2) = dest_position(2);
next_dest_pos(3) = next_dest_pos(1) ...
    + (dest_position(3) - dest_position(1));
next_dest_pos(4) = dest_position(4);

end

function next_dest_pos = calc_left_side_off_position( ...
    source_position, dest_position, block_distance)
next_dest_pos = zeros(1, 4);

next_dest_pos(3) = source_position(1) - block_distance;
next_dest_pos(1) = next_dest_pos(3) ...
    + (dest_position(1) - dest_position(3));
next_dest_pos(2) = dest_position(2);
next_dest_pos(4) = dest_position(4);

end
