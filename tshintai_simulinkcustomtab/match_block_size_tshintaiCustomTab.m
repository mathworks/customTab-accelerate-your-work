function match_block_size_tshintaiCustomTab()
%% 説明
% 選択状態のブロックのサイズを、フォーカスされたブロックのサイズに
% 一致させる。
% 選択されたブロックが1個だけの時、そのブロックと最も近いものに
% サイズを合わせる。
% 選択状態のブロックが横方向より縦方向に長く配置されている場合、
% ブロックの位置をフォーカスされたブロックに合わせる。
%%
% 最初にStateflowのChart内Stateが選択されているかどうかを判別し、
% そうであればChart用の処理を実行する。
this_layer = gcs;
chart_selected_objects = sfgco;

if ~isempty(chart_selected_objects)
    chart_selected_index = false(size(chart_selected_objects));
    for i = 1:numel(chart_selected_objects)
        if strcmp(chart_selected_objects(i).getDisplayClass, ...
                'Stateflow.State')
            chart_selected_index(i) = true;
        end

        chart_states = chart_selected_objects(chart_selected_index);
    end
else
    chart_states = [];
end

if numel(chart_states) > 1
    %Chart内State用の処理
    ref_state = chart_states(end);
    other_states = chart_states(1:end-1);

    % pos == [左辺の位置 上辺の位置 ブロックの横幅 ブロックの縦幅]
    ref_state_pos = ref_state.Position;

    for i = 1:numel(other_states)
        state_pos = other_states(i).Position;

        if ( abs(ref_state_pos(1) - state_pos(1)) < ...
             abs(ref_state_pos(2) - state_pos(2)) )

            new_pos = [ref_state_pos(1), ...
                       state_pos(2), ...
                       ref_state_pos(3), ...
                       ref_state_pos(4)];
        else
            new_pos = [state_pos(1), ...
                       ref_state_pos(2), ...
                       ref_state_pos(3), ...
                       ref_state_pos(4)];
        end

        set(other_states(i), 'Position', new_pos);
    end
else
    % Simulinkブロック用の処理

    ref_block_path = gcb;
    selected_block_list = find_system(this_layer, ...
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1, ...
        'Selected','on');

    if ( (numel(selected_block_list) > 1.5) && ...
            strcmp(selected_block_list{1}, this_layer) )

        % バリアントサブシステムの中のブロックを一致させる場合は、
        % 上手く選択したブロックを抽出できないので
        % ブロックを合わせる機能は実行しない
        if strcmp(get_param(selected_block_list{1}, 'Variant'), 'on')
            error('バリアントサブシステムの中のブロックは操作できません。');
        end

        selected_block_list = selected_block_list(2:end);
    elseif numel(selected_block_list) > 0.5
        if strcmp(selected_block_list{1}, this_layer)
            return;
        end
    end

    if isempty(selected_block_list)
        return;
    elseif numel(selected_block_list) < 1.5
        nearest_block = get_nearest_block_path(selected_block_list{1}, ...
                            this_layer);
        if isempty(nearest_block)
            return;
        end
        other_blocks_path = selected_block_list;
        ref_block_path = nearest_block;
    else
        other_blocks_path = selected_block_list(~strcmp(selected_block_list, ...
        ref_block_path));
    end

    %%
    % pos == [左端のX座標, 上端のY座標, 右端のX座標, 下端のY座標]
    ref_block_pos = get_param(ref_block_path, 'Position');
    other_blocks_pos = cell(numel(other_blocks_path), 1);
    for i = 1:numel(other_blocks_pos)
        other_blocks_pos{i} = get_param(other_blocks_path{i}, 'Position');
    end

    %%
    ref_block_width  = ref_block_pos(3) - ref_block_pos(1);
    ref_block_height = ref_block_pos(4) - ref_block_pos(2);

    for i = 1:numel(other_blocks_path)
        set_param(other_blocks_path{i}, 'Position', ...
            [other_blocks_pos{i}(1), ...
            other_blocks_pos{i}(2), ...
            other_blocks_pos{i}(1) + ref_block_width, ...
            other_blocks_pos{i}(2) + ref_block_height]);
    end

    %%
    block_arrange_factor = 1.5;

    % block_pos_listの1列目はブロック中心のX位置、2列目はY位置
    block_pos_list = zeros(numel(other_blocks_path) + 1, 2);

    block_pos_list(1, 1) = (ref_block_pos(1) + ref_block_pos(3)) / 2;
    block_pos_list(1, 2) = (ref_block_pos(2) + ref_block_pos(4)) / 2;
    for i = 1:numel(other_blocks_path)
        block_pos_list(i + 1, 1) = ...
            (other_blocks_pos{i}(1) + other_blocks_pos{i}(3)) / 2;
        block_pos_list(i + 1, 2) = ...
            (other_blocks_pos{i}(2) + other_blocks_pos{i}(4)) / 2;
    end

    if ( max(block_pos_list(:, 1)) - min(block_pos_list(:, 1)) < ...
            (max(block_pos_list(:, 2)) - min(block_pos_list(:, 2))) * ...
             block_arrange_factor)

        for i = 1:numel(other_blocks_pos)
            other_blocks_pos{i} = get_param(other_blocks_path{i}, 'Position');

            x_dif = ref_block_pos(1) - other_blocks_pos{i}(1);

            set_param(other_blocks_path{i}, 'Position', ...
                [other_blocks_pos{i}(1) + x_dif, ...
                other_blocks_pos{i}(2), ...
                other_blocks_pos{i}(3) + x_dif, ...
                other_blocks_pos{i}(4)]);
        end

    end

end

end

function nearest_block_path = get_nearest_block_path(...
    target_block_path, this_layer)
%%
target_position = get_param(target_block_path, 'Position');
target_vertex = [target_position(1), target_position(2);
                 target_position(1), target_position(4);
                 target_position(3), target_position(2);
                 target_position(3), target_position(4)];

block_list_temp = find_system(this_layer, ...
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1);

if numel(block_list_temp) < 2.5
    nearest_block_path = '';
    return;
end

if strcmp(block_list_temp{1}, this_layer)
    block_list = block_list_temp(2:end);
else
    block_list = block_list_temp;
end

match_vector = strcmp(block_list, target_block_path);
if sum(int32(match_vector)) < 1
    nearest_block_path = '';
    return;
end

other_block_list = block_list(~match_vector);

%%
block_distance = inf;
nearest_index = 0;
for i = 1:numel(other_block_list)
    other_position = get_param(other_block_list{i}, 'Position');
    other_vertex = [other_position(1), other_position(2);
                    other_position(1), other_position(4);
                    other_position(3), other_position(2);
                    other_position(3), other_position(4)];

    this_distance = zeros(16, 1);
    dist_index = 1;

    % 二つのブロックの4個の頂点間の距離を測り、最も短い距離を
    % ブロック間距離とする。
    for j = 1:4
        for k = 1:4
            this_distance(dist_index) = ...
                sum((other_vertex(j, :) - target_vertex(k, :)) .^2);
            dist_index = dist_index + 1;
        end        
    end

    this_min_distance = min(this_distance);

    if (this_min_distance < block_distance)
        block_distance = this_min_distance;
        nearest_index = i;
    end
end

nearest_block_path = other_block_list{nearest_index};

end
