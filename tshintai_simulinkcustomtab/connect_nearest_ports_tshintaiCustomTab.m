function connect_nearest_ports_tshintaiCustomTab()
%% 説明
% コメントアウトされていないブロックの未接続ポートを、
% 最も近い入力、出力ポート同士の組み合わせで接続する。
%%
this_system = gcs;
block_list = find_system(this_system, ...
    'SearchDepth',1, ...
    'Commented', 'off');
if (numel(block_list) == 1)
    return;
elseif strcmp(block_list{1}, this_system)
    block_list = block_list(2:end);
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

combination_num = 1;
for i = 0:(smaller_inout_num - 1)
    combination_num = combination_num * (bigger_inout_num - i);
end

%%
% 入力と出力の全組み合わせを抽出するために、順列のリスト
% 「perms_list」を作成する。順列のリストは、多い方のポートを
% 少ない方のポート数分だけ抽出し、それを並べた時の順列である。
choose_list = nchoosek(1:bigger_inout_num, smaller_inout_num);
perms_list = zeros(combination_num, smaller_inout_num);
perms_num = combination_num / size(choose_list, 1);
for i = 0:(size(choose_list, 1) - 1)
    perms_list((i * perms_num + 1):((i + 1) * perms_num), :) = ...
        perms(choose_list(i + 1, :));
end

%%
% combination_listには全てのポート組み合わせパターンを記録する。
% combination_listは、行方向の1要素目からcombination_num要素目まで
% ポート同士の組み合わせパターンを並べる。
% また、列方向の1要素目からsmaller_inout_num要素目まで
% [入力ポートハンドル, 出力ポートハンドル]という
% 組み合わせのベクトルを並べる。
combination_list = cell(combination_num, smaller_inout_num);

% 同時に、全ポート組み合わせパターンに対する距離の評価を行う
nearest_score = zeros(combination_num, 1);
distance_weight_factor = [1, 100];
right_to_left_factor = 100;
penalty_bias = 1e6;

for i = 1:combination_num
    temp_distance = 0;
    for j = 1:smaller_inout_num
        if in_is_bigger
            inport_index  = perms_list(i, j);
            outport_index = j;
        else
            inport_index  = j;
            outport_index = perms_list(i, j);
        end

        combination_list{i, j} = [...
            disconnected_inport_list{inport_index, 3}, ...
            disconnected_outport_list{outport_index, 3}];

        port_pos_dif = disconnected_inport_list{inport_index, 5} - ...
            disconnected_outport_list{outport_index, 5};

        temp_distance = temp_distance + ...
            sum(abs(port_pos_dif) .* distance_weight_factor);
        
        % 同じブロック内でポートを繋ごうとしている場合はペナルティを加える。
        if strcmp(disconnected_inport_list{inport_index, 1}, ...
                disconnected_outport_list{outport_index, 1})
            temp_distance = temp_distance + penalty_bias;
        end
        
        % 右から左へ線を繋ごうとしている場合はペナルティを加える。
        if (port_pos_dif(1) < 0)
            temp_distance = temp_distance + ...
                abs(port_pos_dif(1)) * right_to_left_factor;
        end
    end

    nearest_score(i) = temp_distance;
end

%%
[~, min_score_index] = min(nearest_score);

for i = 1:smaller_inout_num
    inout_handles = combination_list{min_score_index, i};
    add_line(this_system, inout_handles(2), inout_handles(1), ...
        'autorouting','smart');
end

end

