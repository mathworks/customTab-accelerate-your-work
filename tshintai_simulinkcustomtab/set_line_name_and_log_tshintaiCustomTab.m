function set_line_name_and_log_tshintaiCustomTab()
%% 説明
% 選択した信号線に名前を付け、シミュレーションデータインスペクター
% にログする設定を行う。
% 名前を入力しなかった場合、その信号線の名前を消し、
% ログ設定を解除する。
%%
this_system = gcs;
selected_line_list = find_system(this_system,...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'FindAll','on', ...
    'Type','Line', ...
    'Selected','on');

%%
src_port_handles = zeros(numel(selected_line_list), 1);
for i = 1:numel(selected_line_list)
    src_port_handles(i) = get_param(selected_line_list(i), ...
        'SrcPortHandle');
end

% 同じポートから出ている信号線に対しては1回だけダイアログを表示するようにするため、
% ここで同じポートの信号は省く
[~, s_line_index] = unique(src_port_handles);

for i = (s_line_index)'
    src_port_handle = get_param(selected_line_list(i), ...
        'SrcPortHandle');
    if (src_port_handle > -0.5)
        parent_block_path = get_param(src_port_handle, 'Parent');
        temp_text = strsplit(parent_block_path, '/');
        parent_block_name = temp_text(end);
        port_number = get_param(src_port_handle, 'PortNumber');
        now_line_name = get_param(selected_line_list(i), ...
                            'Name');

        prompt = parent_block_name + " の出力ポート " + ...
            num2str(port_number) + ...
            " の信号線の名前を入力してください：";
        dlgtitle = 'Input';
        dims = [1 35];
        definput = {now_line_name};
        answer = inputdlg(prompt, dlgtitle, dims, definput);
        if isempty(answer) || (strlength(answer) == 0)
            if ~isempty(now_line_name)
                set_param(selected_line_list(i), ...
                            'Name', '');
                Simulink.sdi.markSignalForStreaming(...
                    selected_line_list(i), 'off');
            end
        else
            set_param(selected_line_list(i), ...
                            'Name', answer{1});
            Simulink.sdi.markSignalForStreaming(...
                    selected_line_list(i), 'on');
        end
    end
end

end
