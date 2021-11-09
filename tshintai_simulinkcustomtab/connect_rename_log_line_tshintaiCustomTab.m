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
selected_lines = find_system(gcs,...
    'SearchDepth', 1, ...
    'FindAll','on', ...
    'Type','Line', ...
    'Selected','on');

if numel(selected_lines) == 1
    connect_line_to_port(selected_lines);
else
    connect_block_to_block_repeatedly();
end

end

function connect_line_to_port(selected_lines)
%%
block_list = find_system(gcs, 'SearchDepth', 1);
if numel(block_list) < 2
    return;
end
block_list = block_list(2:end);

%%
% disconnected_inport_list, disconnected_outport_listは、
% 信号線が接続されていないポートの
% 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別を記録する。
[disconnected_inport_list, ~] = ...
    get_disconnected_lists(block_list);

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

    add_line(gcs, outport_handle, disconnected_inport_list{RM_indx(i), 3}, ...
        'autorouting','smart');
end

end

function connect_block_to_block_repeatedly()

while(1)
    %%
    selected_block_list = find_system(gcs, ...
        'SearchDepth',1, ...
        'Selected','on');

    if (isempty(selected_block_list) || strcmp(selected_block_list{1}, gcs))
        selected_block_list = find_system(gcs, ...
            'SearchDepth',1);
        if (numel(selected_block_list) == 1)
            return;
        else
            selected_block_list = selected_block_list(2:end);
        end
    end

    %%
    for i = 1:numel(selected_block_list)
        selected_block_list{i}  = strrep(selected_block_list{i}, newline, ' ');
    end

    %%
    % disconnected_inport_list, disconnected_outport_listは、
    % 信号線が接続されていないポートの
    % 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別を記録する。
    [disconnected_inport_list, disconnected_outport_list] = ...
    get_disconnected_lists(selected_block_list);

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

function [disconnected_inport_list, disconnected_outport_list] = ...
    get_disconnected_lists(block_list)

disconnected_inport_list = cell(1, 4);
disconnected_outport_list = cell(1, 4);

for i = 1:numel(block_list)

    try
        port_handle = get_param(block_list{i}, 'PortHandles');
    catch
        continue;
    end

    % Inport, Enable, Trigger, Ifaction, Resetを合わせた
    % 入力ポートを定義する
    % g_inport_handleはハンドルと上記のポート種別を格納する
    g_inport_handle = set_general_inport(port_handle);

    % 入力ポート、出力ポートの数を調べる
    inport_num = numel(g_inport_handle(:, 1));
    outport_num = numel(port_handle.Outport);

    if (inport_num == 0 && outport_num == 0)
        continue;
    end

    port_info = get_param(block_list{i}, 'PortConnectivity');

    for j = 1:inport_num
        if (port_info(j).SrcBlock < 0)
            disconnected_inport_list = add_port_info( ...
                disconnected_inport_list, block_list{i}, ...
                j, g_inport_handle{j, 1}, g_inport_handle{j, 2});
        end
    end
    for j = 1:outport_num
        if isempty(port_info(j + inport_num).DstBlock)
            disconnected_outport_list = add_port_info( ...
                disconnected_outport_list, block_list{i}, ...
                j, port_handle.Outport(j), 'Outport');
        end
    end

end

end

function g_inport_handle = set_general_inport(port_handle)

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

function disconnected_port_list = add_port_info( ...
    disconnected_port_list, parent_block_name, port_num, ...
    port_handle, type)

if isempty(disconnected_port_list{1, 1})
    disconnected_port_list{1, 1} = parent_block_name;
    disconnected_port_list{1, 2} = port_num;
    disconnected_port_list{1, 3} = port_handle;
    disconnected_port_list{1, 4} = type;
else
    port_list = cell(1, 4);
    port_list{1, 1} = parent_block_name;
    port_list{1, 2} = port_num;
    port_list{1, 3} = port_handle;
    port_list{1, 4} = type;
    disconnected_port_list = [disconnected_port_list; port_list];
end

end

