function connect_rename_log_line_tshintaiCustomTab()
%% 説明
% ブロックや信号線の選択状態に応じて以下のどちらかの処理を行います。
% 1. 信号線が一つだけ選択されている場合、未接続の入力ポートをリスト化し、
%    選択したポートとその信号線を接続します。
% 2. ブロックが選択されている場合はその選択されているブロックの中で、
%    何も選択されていなければ今のモデル階層の中で、
%    接続可能な未接続ポートの組み合わせをリスト化し、
%    選択したポート同士を接続します。
% 接続後、信号名を入力し、シミュレーションデータインスペクターに
% ログする設定を行います。
% ダイアログでキャンセルを入力した場合は、その場で処理を終了します。
% ポートリストは、接続可能な未接続ポートの組み合わせが存在する限り
% 繰り返し表示されます。
%%
selected_lines = check_only_lines_selected(gcs);

if numel(selected_lines) == 1
    connect_line_to_port(selected_lines);
else
    connect_block_to_block_repeatedly();
end

end

function selected_lines = check_only_lines_selected(this_system)
%%
selected_line_list = find_system(this_system,...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'FindAll','on', ...
    'Type','Line', ...
    'Selected','on');

selected_block_list = find_system(this_system, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth',1, ...
        'Selected','on');

%%
line_only = false;
if isempty(selected_block_list)
    line_only = true;
elseif numel(selected_block_list) == 1
    if strcmp(selected_block_list{1}, this_system)
        line_only = true;
    end
end

%%
if line_only
    % 一つの信号線を選択していても、分岐している信号線は複数のハンドルを持つ。
    % そのため、同じ線かどうかをここで判定する。
    selected_lines = check_line_duplicated(selected_line_list);
else
    selected_lines = [];
end

end

function valid_line_handle = check_line_duplicated(selected_lines)
%%
if numel(selected_lines) < 1.5

    valid_line_handle = selected_lines;

else

    % source_handle_listはハンドル、ハンドルの数を格納する
    source_handle_list = cell(numel(selected_lines), 2);

    for i = 1:numel(selected_lines)
        source_handle_list{i, 1} = get_param(selected_lines(i), 'SrcPortHandle');
        source_handle_list{i, 2} = numel(source_handle_list{i, 1});
    end

    valid_line_handle = [];
    if max(cell2mat(source_handle_list(:, 2))) == 1
        vec = cell2mat(source_handle_list(:, 1));
        if max(vec - mean(vec)) < eps
            valid_line_handle = selected_lines;
        end
    end

    if ~isempty(valid_line_handle)
        valid_line_handle = valid_line_handle(1);
    end

end

end

function connect_line_to_port(selected_lines)
%%
block_list = find_system(gcs, ...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1);
if numel(block_list) < 2
    return;
end
block_list = block_list(2:end);

%%
% disconnected_inport_list, disconnected_outport_listは、
% 信号線が接続されていないポートの
% 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別を記録する。
[disconnected_inport_list, ~] = ...
    get_disconnected_lists_tshintaiCustomTab(block_list);

if isempty(disconnected_inport_list{1, 1})
    return;
end

%%
if (size(disconnected_inport_list, 1) == 1)
    RM_indx = 1;
else
    disconnected_inport_text = cell(size(disconnected_inport_list, 1), 1);
    for i = 1:numel(disconnected_inport_text)
        block_name = strsplit(disconnected_inport_list{i, 1}, '/');

        disconnected_inport_text{i} = [...
            block_name{end}, ', Inport ', ...
            num2str(disconnected_inport_list{i, 2})];
    end

    % ダイアログ表示のため、改行を置換する
    for i = 1:numel(disconnected_inport_text)
        disconnected_inport_text{i} = ...
            strrep(disconnected_inport_text{i}, newline, ' ');
    end

    [RM_indx, tf] = listdlg( ...
        'ListString', disconnected_inport_text, ...
        'PromptString', {'接続するポートの組み合わせを選択してください：'}, ...
        'ListSize', [500, 400]);
    if ~(tf)
        return;
    end
end

%%
for i = 1:numel(RM_indx)
    % すでに未接続線（赤線）が存在している場合は、事前に削除しておく。
    line_handle = get_param(disconnected_inport_list{RM_indx(i), 3}, 'Line');
    if (line_handle > -0.5)
        delete_line(line_handle);
    end

    outport_handle = get_param(selected_lines, 'SrcPortHandle');

    % 信号線を綺麗に繋げるため、一旦ソ－スブロックを接続先の位置に合わせる
    src_port_pos = get_param(outport_handle, 'Position');
    dst_port_pos = get_param(disconnected_inport_list{RM_indx(i), 3}, 'Position');
    port_y_dif = dst_port_pos(2) - src_port_pos(2);

    parent_block_name = get_param(outport_handle, 'Parent');
    parent_block_pos = get_param(parent_block_name, 'Position');
    next_block_pos = [...
        parent_block_pos(1), ...
        parent_block_pos(2) + port_y_dif, ...
        parent_block_pos(3), ...
        parent_block_pos(4) + port_y_dif, ...
        ];

    set_param(parent_block_name, 'Position', next_block_pos);
    route_line_of_port(outport_handle);

    % 線を接続
    add_line(gcs, outport_handle, disconnected_inport_list{RM_indx(i), 3}, ...
        'autorouting','smart');

    % ブロック位置を戻す
    set_param(parent_block_name, 'Position', parent_block_pos);

end

% 選択されている線が未接続（赤線）の場合は削除する
try
    if get_param(selected_lines, 'DstPortHandle') < 0
        delete_line(selected_lines);
    end
catch
end

end

function connect_block_to_block_repeatedly()
%%
while(1)
    %%
    selected_block_list = find_system(gcs, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1, ...
        'Selected','on');

    if (isempty(selected_block_list) || strcmp(selected_block_list{1}, gcs))
        selected_block_list = find_system(gcs, ...
            'LookUnderMasks', 'all', ...
            'SearchDepth', 1);
        if (numel(selected_block_list) == 1)
            return;
        else
            selected_block_list = selected_block_list(2:end);
        end
    end

    %%
    % ダイアログ表示のため、改行を置換する
    for i = 1:numel(selected_block_list)
        selected_block_list{i}  = strrep(selected_block_list{i}, newline, ' ');
    end

    %%
    % disconnected_inport_list, disconnected_outport_listは、
    % 信号線が接続されていないポートの
    % 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別を記録する。
    [disconnected_inport_list, disconnected_outport_list] = ...
    get_disconnected_lists_tshintaiCustomTab(selected_block_list);

    if ( isempty(disconnected_inport_list{1, 1}) || ...
            isempty(disconnected_outport_list{1, 1}) )
        return;
    end

    %%
    % combination_listは、入力ポート番号、出力ポート番号、
    % その組み合わせの名前、入力ポートハンドル、出力ポートハンドルを格納している
    combination_list = cell(size(disconnected_inport_list, 1) * ...
        size(disconnected_outport_list, 1), 5);

    list_num = 1;
    for i = 1:size(disconnected_outport_list, 1)
        for j = 1:size(disconnected_inport_list, 1)
            combination_list{list_num, 1} = disconnected_inport_list{j, 2};
            combination_list{list_num, 2} = disconnected_outport_list{i, 2};

            inport_text = strsplit(disconnected_inport_list{j, 1}, '/');
            outport_text = strsplit(disconnected_outport_list{i, 1}, '/');
            combination_list{list_num, 3} = ...
                [outport_text{end}, ', ', ...
                disconnected_outport_list{i, 4}, ...
                num2str(combination_list{list_num, 2}), ...
                ' -> ', inport_text{end}, ', ', ...
                disconnected_inport_list{j, 4}, ...
                num2str(combination_list{list_num, 1})];

            combination_list{list_num, 4} = disconnected_inport_list{j, 3};
            combination_list{list_num, 5} = disconnected_outport_list{i, 3};

            list_num = list_num + 1;
        end
    end

    %%
    if (size(combination_list, 1) == 1)
        RM_indx = 1;
    else
        [RM_indx, tf] = listdlg('SelectionMode','single', ...
            'ListString', combination_list(:, 3), ...
            'PromptString', {'接続するポートの組み合わせを選択してください：'}, ...
            'ListSize', [500, 400]);
        if ~(tf)
            return;
        end
    end

    %%
    % すでに未接続線（赤線）が存在している場合は、事前に削除しておく。
    line_handle = get_param(combination_list{RM_indx, 4}, 'Line');
    if (line_handle > -0.5)
        delete_line(line_handle);
    end
    line_handle = get_param(combination_list{RM_indx, 5}, 'Line');
    if (line_handle > -0.5)
        delete_line(line_handle);
    end

    add_line(gcs, combination_list{RM_indx, 5}, combination_list{RM_indx, 4}, ...
        'autorouting','smart');

    %%
    line_handle = get_param(combination_list{RM_indx, 4}, 'Line');

    %%
    prompt = {'信号名を入力してください：'};
    dlgtitle = 'Input';
    dims = [1 35];
    definput = "sig";
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    if isempty(answer) || (strlength(answer) == 0)
        continue;
    end

    set_param(line_handle, 'Name', answer{1});

    %%
    Simulink.sdi.markSignalForStreaming(line_handle, 'on');

end

end


function route_line_of_port(dst_port_handle)

line_handle = get_param(dst_port_handle, 'Line');
Simulink.BlockDiagram.routeLine(line_handle);

end
