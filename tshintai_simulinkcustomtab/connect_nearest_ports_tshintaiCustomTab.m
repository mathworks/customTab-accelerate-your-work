function connect_nearest_ports_tshintaiCustomTab()
%% 説明
% コメントアウトされていないブロックの未接続ポートを、
% 最も近い入力、出力ポート同士の組み合わせで接続する。
% ブロックが選択されていれば、選択されているブロック群の
% 範囲内で接続を行う。
%%
max_port_num = 8;
max_combination = int64(factorial(max_port_num));

no_selected_flag = false;

this_system = gcs;
selected_block_list = find_system(this_system, ...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'Commented', 'off', ...
    'Selected','on');
if (numel(selected_block_list) < 1.5)
    no_selected_flag = true;
elseif strcmp(selected_block_list{1}, this_system)
    block_list = selected_block_list(2:end);
    if (numel(block_list) < 1.5)
        no_selected_flag = true;
    end
else
    block_list = selected_block_list;
end

if (no_selected_flag)
    block_list = find_system(this_system, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1, ...
        'Commented', 'off');
    if (numel(block_list) == 1)
        return;
    elseif strcmp(block_list{1}, this_system)
        block_list = block_list(2:end);
    end
end

%%
[disconnected_inport_list, disconnected_outport_list] = ...
    get_disconnected_lists_tshintaiCustomTab(block_list);

if ( isempty(disconnected_inport_list{1, 1}) || ...
        isempty(disconnected_outport_list{1, 1}) )
    return;
end

%%
inport_num  = numel(disconnected_inport_list(:, 1));
outport_num = numel(disconnected_outport_list(:, 1));
if (inport_num > outport_num)
    bigger_inout_num  = inport_num;
    smaller_inout_num = outport_num;
    in_is_bigger = true;
else
    bigger_inout_num  = outport_num;
    smaller_inout_num = inport_num;
    in_is_bigger = false;
end

if (smaller_inout_num > max_port_num)
    error_too_many_disconnected_ports;
end

combination_num = int64(1);
for i = int64(0):(smaller_inout_num - int64(1))
    combination_num = combination_num * (int64(bigger_inout_num) - i);
end
if (combination_num > max_combination)
    error_too_many_disconnected_ports;
end

%%
inport_max_Y_pos = -inf;
for i = 1:inport_num
    if (inport_max_Y_pos < disconnected_inport_list{i, 5}(2))
        inport_max_Y_pos = disconnected_inport_list{i, 5}(2);
    end
end

outport_max_Y_pos = -inf;
for i = 1:outport_num
    if (outport_max_Y_pos < disconnected_outport_list{i, 5}(2))
        outport_max_Y_pos = disconnected_outport_list{i, 5}(2);
    end
end

%%
% 入力と出力の全組み合わせを抽出するために、組み合わせのリスト
% 「choose_list」を作成する。この組み合わせの一つ一つに対して
% 順列をリスト化すると、全てのポートの組み合わせを表現できる。
choose_list = int64(nchoosek(1:bigger_inout_num, smaller_inout_num));
each_choose_perms_num = int64(factorial(smaller_inout_num));
perms_list_one_step = zeros(1, smaller_inout_num, 'int64');

choose_index      = int64(1);
perms_index       = int64(1);

%%
% combination_vecにはポート組み合わせパターンを記録する。
% combination_vecは、列方向の1要素目から
% smaller_inout_num要素目まで
% [入力ポートハンドル, 出力ポートハンドル]という
% 組み合わせのベクトルを並べる。
combination_vec = cell(1, smaller_inout_num);

% 最終的に求める最小スコアの組み合わせパターンを以下に記録する。
combination_min_vec = combination_vec;

% 同時に、全ポート組み合わせパターンに対する距離の評価を行う
nearest_min_score = inf;
distance_weight_factor = [1, 100];
right_to_left_factor = 100;
self_block_penalty_bias = 1e6;

for i = 1:combination_num
    temp_distance = 0;

    % choose_listから1ステップずつ順列を生成する
    if (perms_index == int64(1))
        perms_list_one_step = choose_list(choose_index, :);
    else
        [perms_list_one_step, status] = ...
            one_step_permutation(perms_list_one_step, smaller_inout_num);

        if (status == int64(0))
            perms_index = int64(1);
            break;
        end
    end

    for j = 1:smaller_inout_num
        if in_is_bigger
            inport_index  = perms_list_one_step(1, j);
            outport_index = j;
        else
            inport_index  = j;
            outport_index = perms_list_one_step(1, j);
        end

        combination_vec{1, j} = [...
            disconnected_inport_list{inport_index, 3}, ...
            disconnected_outport_list{outport_index, 3}];

        port_pos_dif = disconnected_inport_list{inport_index, 5} - ...
            disconnected_outport_list{outport_index, 5};

        temp_distance = temp_distance + ...
            sum(abs(port_pos_dif) .* distance_weight_factor);
        
        % 同じブロック内でポートを繋ごうとしている場合はペナルティを加える。
        if strcmp(disconnected_inport_list{inport_index, 1}, ...
                disconnected_outport_list{outport_index, 1})
            temp_distance = temp_distance + self_block_penalty_bias;
        end
        
        % 右から左へ線を繋ごうとしている場合はペナルティを加える
        % ただし、一番下のポート同士を繋ぐ場合はペナルティを加えない
        if (port_pos_dif(1) < 0)
            if (int64(inport_max_Y_pos) ~= int64(disconnected_inport_list{inport_index, 5}(2)) && ...
                int64(outport_max_Y_pos) ~= int64(disconnected_outport_list{outport_index, 5}(2)))
                temp_distance = temp_distance + ...
                    abs(port_pos_dif(1)) * right_to_left_factor;
            end
        end
    end

    if (nearest_min_score > temp_distance)
        combination_min_vec = combination_vec;
        nearest_min_score = temp_distance;
    end

    perms_index = perms_index + int64(1);
    if (perms_index > each_choose_perms_num)
        perms_index = int64(1);
        choose_index = choose_index + int64(1);
    end

%     if (mod(i, 1000) == 0)
%     disp(['Progress: ', num2str(100 * double(i) / double(combination_num)), ' [%]']);
%     end
end

%%
for i = 1:smaller_inout_num
    inout_handles = combination_min_vec{1, i};
    delete_unconnected_line(inout_handles(1));
    delete_unconnected_line(inout_handles(2));
    add_line(this_system, inout_handles(2), inout_handles(1), ...
        'autorouting','smart');
end

end


function delete_unconnected_line(outport_handle)
    line_handle = get_param(outport_handle, 'Line');
    if (line_handle > -0.5)
        delete_line(line_handle);
    end
end

function error_too_many_disconnected_ports()

error('未接続ポートの数が多すぎるため、処理を実行できません。');

end

function [next_array, status] = one_step_permutation(array, array_length)
%%
ZERO = int64(0);
ONE = int64(1);
array64 = int64(array);
array_length64 = int64(array_length);
next_array = array64;
status = ONE;

%%
left = int64(array_length64) - ONE;
while (left >= ONE && array64(left) >= array64(left + ONE))
    left = left - ONE;
end

if (left < ONE)
    status = ZERO;
    return;
end

%%
right = int64(array_length64);
while(array64(left) >= array64(right))
    right = right - ONE;
end

t = array64(left);
array64(left) = array64(right);
array64(right) = t;

left = left + ONE;
right = array_length64;

%%
while(left < right)
    t = array64(left);
    array64(left) = array64(right);
    array64(right) = t;
    
    left = left + ONE;
    right = right - ONE;
end

%%
next_array = array64;

end

