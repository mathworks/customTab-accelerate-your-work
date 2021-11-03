function match_block_size_tshintaiCustomTab()
%% 説明
% 選択状態のブロックのサイズを、フォーカスされたブロックのサイズに
% 一致させます。
% 選択状態のブロックが横方向より縦方向に長く配置されている場合、
% ブロックの位置をフォーカスされたブロックに合わせます。
%%
% 最初にStateflowのChart内Stateが選択されているかどうかを判別し、
% そうであればChart用の処理を実行する。
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
    selected_block_list = find_system(gcs, ...
        'SearchDepth',1, ...
        'Selected','on');

    if ( (numel(selected_block_list) > 1) && ...
            strcmp(selected_block_list{1}, gcs) )
        selected_block_list = selected_block_list(2:end);
    end

    if isempty(selected_block_list)
        return;
    end

    %%
    other_blocks_path = selected_block_list(~strcmp(selected_block_list, ...
        ref_block_path));

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
            max(block_pos_list(:, 2)) - min(block_pos_list(:, 2)) )

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