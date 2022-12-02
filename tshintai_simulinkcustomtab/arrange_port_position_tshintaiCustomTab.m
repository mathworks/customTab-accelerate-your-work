function arrange_port_position_tshintaiCustomTab()
%% 説明
% 選択したブロック同士のポート位置が横一列に揃うように
% ブロックの上下位置を並べ替える。
% 何も選択されていない場合は、今の階層のブロック全てに対して実行される。
% また、同じ線で接続されたブロックグループを探し、
% そのグループごとに並べる。
% 合わせる位置は、同じブロックグループの終端ブロックの
% 接続先ポート位置である。
% 出力ポートの先にブロックが繋がっていない場合、
% 入力ポートの先に繋がっているブロックの出力ポート位置に合わせる。
%%
current_layer = gcs;
selected_block_list = find_system(current_layer, ...
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1, ...
        'Selected','on');

if (numel(selected_block_list) < 1 || ...
   (numel(selected_block_list) == 1 && strcmp(selected_block_list{1}, gcs)))
    layer_block_list = find_system(current_layer, ...
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1);
    if numel(layer_block_list) > 1.5
        selected_block_list = layer_block_list;
    else
        return;
    end

end


if strcmp(selected_block_list{1}, current_layer)
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
dst_block_info = cell(numel(selected_block_list), 5);
dst_block_valid_flag = true(numel(selected_block_list), 1);
for i = 1:numel(selected_block_list)
    % dst_block_infoの要素については「block_info_connected_from」
    % のコメントを参照。
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
    if (dst_block_info{i, 5})
        % 入力ポートの先に合わせるブロックである場合は、自身の接続先とする
        block_group_info{i, 2} = dst_block_info{i, 4};
    else
        % 接続先の終端ブロックを探す
        find_flag = false;
        terminal_block = dst_block_info{i, 1};
        previous_block = src_block_names{i};
        while_count = 0;
        while_max = 10000;

        while(~find_flag)
            find_index = 0;
            for j = 1:numel(dst_block_info(:, 1))
                if strcmp(terminal_block, src_block_names{j})
                    if ~(dst_block_info{j, 5})
                        % 見つけた終端ブロックが入力ポートに合わせたいブロック
                        % である場合は終端とみなさない。
                        find_index = j;
                    end
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

            while_count = while_count + 1;
            if (while_count >= while_max)
                % whileループが上限を超えた場合、無限ループしていると判定し、
                % 関数を終了させる。
                return;
            end
        end

        block_group_info{i, 1} = terminal_block;

        for j = 1:numel(src_block_names)
            if strcmp(src_block_names{j}, terminal_block)
                block_group_info{i, 2} = dst_block_info{j, 4};
                break;
            end
        end
    end
end

%%
% 先に出力ポートで合わせるブロックを移動させ、
% その後入力ポートで合わせるブロックを移動させる。
move_position(src_block_names, dst_block_info, ...
    block_group_info, false);
move_position(src_block_names, dst_block_info, ...
    block_group_info, true);

%%
% 最後にブロック中心座標または一番目の出力ポート座標が同じブロックを探し、
% それを見つけた場合は接続先ポートの位置にY座標を修正する。
if numel(src_block_names) < 1.5
    % 信号線を整えてから終わる
    arrange_line(current_layer);
    return;
end
block_match_th = 10;

block_pos_list = zeros(numel(src_block_names), 4);
port_pos_list  = zeros(numel(src_block_names), 2);
for i = 1:numel(src_block_names)
    block_pos_list(i, :) = get_param(src_block_names{i, 1}, 'Position');
    port_handles = get_param(src_block_names{i, 1}, 'PortHandles');
    if ~isempty(port_handles.Outport)
        port_pos_list(i, :) = get_param(port_handles.Outport(1), 'Position');
    else
        port_pos_list(i, :) = [inf, inf];
    end
end

block_near_flag = false(numel(src_block_names), 1);
for i = 1:(numel(src_block_names) - 1)
    this_block_pos = zeros(2, 1);
    this_block_pos(1) = (block_pos_list(i, 1) + block_pos_list(i, 3)) / 2;
    this_block_pos(2) = (block_pos_list(i, 2) + block_pos_list(i, 4)) / 2;
    this_port_pos = port_pos_list(i, :);
    for j = (i + 1):numel(src_block_names)
        if ~(block_near_flag(j))
            next_block_pos = zeros(2, 1);
            next_block_pos(1) = ...
                (block_pos_list(j, 1) + block_pos_list(j, 3)) / 2;
            next_block_pos(2) = ...
                (block_pos_list(j, 2) + block_pos_list(j, 4)) / 2;

            distance = norm(this_block_pos - next_block_pos);
            if (distance < block_match_th)
                block_near_flag(i) = true;
                block_near_flag(j) = true;
                break;
            end

            next_port_pos = port_pos_list(j, :);
            distance = norm(this_port_pos - next_port_pos);
            if (distance < 1)
                block_near_flag(i) = true;
                block_near_flag(j) = true;
                break;
            end
        end
    end
end

%%
for i = 1:numel(src_block_names)
    if block_near_flag(i)
        dst_block_info = block_info_connected_from(src_block_names{i, 1});
        diff = dst_block_info{1, 4} - dst_block_info{1, 3};
        next_pos = zeros(1, 4);
        next_pos(1) = block_pos_list(i, 1);
        next_pos(2) = block_pos_list(i, 2) + diff;
        next_pos(3) = block_pos_list(i, 3);
        next_pos(4) = block_pos_list(i, 4) + diff;
        set_param(src_block_names{i, 1}, 'Position', next_pos);
    end
end

%%
% 信号線を整えてから終わる
arrange_line(current_layer);

end


function dst_block_info = block_info_connected_from(block_path)
% dst_block_infoの要素はそれぞれ、
% 一番上の出力ポートから接続されているブロック名、そのブロックの位置、
% その接続元ポート上下位置、接続先ポート上下位置である。
% ただし、出力ポートの先にブロックが繋がっていない場合は
% 一番上の入力ポートから接続されているブロック名、
% その接続元ポート上下位置、接続先ポート上下位置とする。
% 最後の要素は上記の"出力側"か"入力側"かのフラグである。
% 入力側の場合をtrueとする。
dst_block_info = cell(1, 4);
dst_block_info{1, 1} = '';
dst_block_info{1, 2} = [];
dst_block_info{1, 3} = [];
dst_block_info{1, 4} = [];
dst_block_info{1, 5} = false;

in_flag = false;
[port_position_Y, port_handles] = ...
    get_valid_port_position_Y(block_path, 'DstBlockHandle', in_flag);
if isempty(port_position_Y)
    in_flag = true;
    [port_position_Y, port_handles] = ...
        get_valid_port_position_Y(block_path, 'SrcBlockHandle', in_flag);
end

if in_flag
    block_destination = 'SrcBlockHandle';
    this_block_source = 'DstPortHandle';
    neighbor_block_port = 'SrcPortHandle';
else
    block_destination = 'DstBlockHandle';
    this_block_source = 'SrcPortHandle';
    neighbor_block_port = 'DstPortHandle';
end

%%
[min_val, min_index] = min(port_position_Y);

line_handle = get_param(port_handles(min_index), 'Line');
if (isempty(line_handle) || line_handle < 0)
    return;
end
dst_block_handles = get_param(line_handle, block_destination);
if (dst_block_handles < 0)
    return;
end

% 接続先ブロックが複数ある場合、最もポート位置が近いブロックを選択する。
if numel(dst_block_handles) > 1.5
    src_port_handle = get_param(line_handle, this_block_source);
    src_port_pos = get_param(src_port_handle, 'Position');
    dst_port_handles = get_param(line_handle, neighbor_block_port);

    pos_dif = inf;
    near_port_index = 1;
    for i = 1:numel(dst_block_handles)
        dst_port_pos = get_param(dst_port_handles(i), 'Position');
        pos_distance = norm(dst_port_pos - src_port_pos);
        if (pos_dif > pos_distance)
            pos_dif = pos_distance;
            near_port_index = i;
        end
    end

    dst_block_handle = dst_block_handles(near_port_index);
    dst_port_handle = dst_port_handles(near_port_index);
else
    dst_block_handle = dst_block_handles(1);
    dst_port_handle = get_param(line_handle, neighbor_block_port);
end

%%
name = get_param(dst_block_handle, 'Name');
name = strrep(name, newline, ' ');

parent = get_param(dst_block_handle, 'Parent');
dst_block_info{1, 1} = [parent, '/', name];
dst_block_info{1, 2} = get_param(dst_block_info{1, 1}, 'Position');

pos = get_param(dst_port_handle, 'Position');
dst_block_info{1, 3} = min_val;
dst_block_info{1, 4} = pos(2);
dst_block_info{1, 5} = in_flag;

end

function [port_position_Y, port_handles] = ...
    get_valid_port_position_Y(block_path, block_destination, in_flag)
%% 初期化
port_position_Y = [];

%%
temp = get_param(block_path, 'PortHandles');
if in_flag
    port_handles = temp.Inport;
    port_pos_offset = -15;
    port_pos_index = 1;
else
    port_handles = temp.Outport;
    port_pos_offset = 5;
    port_pos_index = 3;
end

if numel(port_handles) < 1
    return;
end

%%
block_position = get_param(block_path, 'Position');
port_position_Y = zeros(numel(port_handles), 1);
port_valid_flag = true(numel(port_handles), 1);

for i = 1:numel(port_handles)
    port_position = ...
        get_param(port_handles(i), 'Position');

    % ポート位置がブロックの左右側面にない場合、無効とする
    if abs(block_position(port_pos_index) + port_pos_offset - ...
            port_position(1)) > 0.5
        port_valid_flag(i) = false;
    end
    
    % ポートの先にブロックが繋がっていない場合、無効とする
    line_handle = get_param(port_handles(i), 'Line');
    if (isempty(line_handle) || line_handle < 0)
        port_valid_flag(i) = false;
    else
        dst_block_handles = get_param(line_handle, block_destination);
        if (isempty(dst_block_handles) || dst_block_handles(1) < 0)
            port_valid_flag(i) = false;
        end
    end


    port_position_Y(i) = port_position(2);
end

port_position_Y = port_position_Y(port_valid_flag);
if isempty(port_position_Y)
    return;
end

end

function move_position(src_block_names, dst_block_info, ...
    block_group_info, in_flag)

for i = 1:numel(src_block_names)
    if xor(~in_flag, dst_block_info{i, 5})
        if (in_flag)
            % もし接続先ブロックが移動していた場合、
            % そのオフセット分も加算する。
            block_pos = get_param(dst_block_info{i, 1}, 'Position');
            diff_correct = block_pos(2) - dst_block_info{i, 2}(2);
        else
            diff_correct = 0;
        end

        pos_diff = block_group_info{i, 2} - dst_block_info{i, 3} + ...
                    diff_correct;

        now_pos = get_param(src_block_names{i}, 'Position');
        next_pos = zeros(1, 4);
        next_pos(1) = now_pos(1);
        next_pos(2) = now_pos(2) + pos_diff;
        next_pos(3) = now_pos(3);
        next_pos(4) = now_pos(4) + pos_diff;

        set_param(src_block_names{i}, 'Position', next_pos);
    end
end

end


function arrange_line(current_layer)
%%
selected_line_list = find_system(current_layer,...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'FindAll','on', ...
    'Type','Line', ...
    'Selected','on');

Simulink.BlockDiagram.routeLine(selected_line_list);

%%
% 1本ずつ行うと更に整うので、ここでそれを行う。
for i = 1:numel(selected_line_list)
    Simulink.BlockDiagram.routeLine(selected_line_list(i));
end

end