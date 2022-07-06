function log_named_line_tshintaiCustomTab()
%%
% ブロックに接続されていて、かつ名前が付いている信号線を
% シミュレーションデータインスペクターにログするように設定します。
% また、Simscape変数のログ設定のOn, Offの切り替えも行います。
% ダイアログで選択したものはログ有効化し、選択されなかったものは
% ログ無効化します。
%%
model_name = bdroot;
block_list = find_system(model_name);

if numel(block_list) < 1
    return;
end

block_list = block_list(2:end);
line_list = cell(0);

for i = 1:numel(block_list)
    port_handle = get_param(block_list{i}, 'PortHandles');

    for j = 1:numel(port_handle.Outport)
        line_handle = get_param(port_handle.Outport(j), 'Line');

        if line_handle >= 0
            line_name = get_param(line_handle, 'Name');
            if ~isempty(line_name)
                line_info = cell(1, 2);
                line_info{1, 1} = line_name;
                line_info{1, 2} = line_handle;
                if isempty(line_list)
                    line_list = line_info;
                else
                    line_list = [line_list; line_info];
                end
            end
        end
    end

end

%%
if ~isempty(line_list)
    %%
    for i = 1:size(line_list, 1)
        line_list{i, 1} = strrep(line_list{i, 1}, newline, ' ');
    end

    %%
    initial_port_log_status = false(size(line_list, 1), 1);
    for i = 1:numel(initial_port_log_status)
        port = get_param(line_list{i, 2}, 'SrcPortHandle');
        if strcmp(get_param(port, 'DataLogging'), 'on')
            initial_port_log_status(i) = true;
        end
    end
else
    initial_port_log_status = false(0);
end

%%
% Simscapeのログ設定状態を調べて追加する。
config_obj = getActiveConfigSet(model_name);
config_Simscape_obj = config_obj.getComponent('Simscape');

if ~isempty(config_Simscape_obj)
    log_type_Simscape = get_param(config_Simscape_obj, ...
        'SimscapeLogType');
    log_to_SDI_Simscape = get_param(config_Simscape_obj, ...
        'SimscapeLogToSDI');

    logged_flag_Simscape = false;
    if (~strcmp(log_type_Simscape, 'none') && ...
            strcmp(log_to_SDI_Simscape, 'on') )
        logged_flag_Simscape = true;
    end

    line_list_Simscape = [line_list; ...
        {'<<Simscape>>', []}];
    initial_port_log_status_Simscape = ...
        [initial_port_log_status; logged_flag_Simscape];
else
    if isempty(line_list)
        return;
    else
        line_list_Simscape = line_list;
        initial_port_log_status_Simscape = ...
            initial_port_log_status;
    end
end

%%
list_index = 1:size(line_list_Simscape, 1);
[RM_indx, ~] = listdlg('ListString', line_list_Simscape(:, 1), ...
    'PromptString', {'ログする信号名を選択してください：'}, ...
    'InitialValue', list_index(initial_port_log_status_Simscape), ...
    'ListSize', [300, 400]);

if isempty(RM_indx)
    answer = questdlg('信号のログを全て解除しますか？', ...
    	'ログ解除', ...
    	'はい','いいえ','いいえ');
    if (strcmp(answer, 'いいえ') || isempty(answer))
        return;
    end
end

%%
for i = 1:numel(list_index)
    match_flag = false;
    for j = 1:numel(RM_indx)
        if (int32(list_index(i)) == int32(RM_indx(j)))
            match_flag = true;
        end
    end

    if (i == numel(list_index) && ...
        ~isempty(config_Simscape_obj) )
        % Simscapeのログ設定
        if (match_flag)
            set_param(config_Simscape_obj, ...
                'SimscapeLogType', 'all');
            set_param(config_Simscape_obj, ...
                'SimscapeLogToSDI', 'on');
        else
            set_param(config_Simscape_obj, ...
                'SimscapeLogType', 'none');
            set_param(config_Simscape_obj, ...
                'SimscapeLogToSDI', 'off');
        end
    else
        if (match_flag)
            Simulink.sdi.markSignalForStreaming(...
                line_list{i, 2}, 'on');
        else
            Simulink.sdi.markSignalForStreaming(...
                line_list{i, 2}, 'off');
        end
    end
end

end