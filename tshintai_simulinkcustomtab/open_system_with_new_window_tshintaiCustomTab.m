function open_system_with_new_window_tshintaiCustomTab()
%% 説明
% 選択したブロックを新しいウィンドウで開きます。
% 選択していない場合は、現在の階層を対象に開きます。
% 参照モデル、参照サブシステムなどを対象とした機能です。
% 普通のブロックを選択して実行した場合、ブロックパラメータが開きます。
%%
model_root = bdroot;
selected_block_list = find_system(gcs, ...
    'SearchDepth',1, ...
    'Selected','on');

if ( (numel(selected_block_list) > 1) && ...
        strcmp(selected_block_list{1}, gcs) )
    selected_block_list = selected_block_list(2:end);
elseif numel(selected_block_list) < 1
    selected_block_list = cell(1, 1);
    selected_block_list{1} = gcs;
end

if isempty(selected_block_list)
    return;
end

%%
for i = 1:numel(selected_block_list)

    if strcmp(selected_block_list{i}, model_root)

        open_system(selected_block_list{i});

    else

        if strcmp(get_param(selected_block_list{i}, 'BlockType'), ...
                'ModelReference')
            ref_model_name = get_param(selected_block_list{i}, 'ModelName');
            open_system(ref_model_name);

        else

            try
                subsystem_ref_name = get_param(selected_block_list{i}, ...
                    'ReferencedSubsystem');
            catch
                subsystem_ref_name = '';
            end

            if ~isempty(subsystem_ref_name)
                open_system(subsystem_ref_name);
            else
                open_system(selected_block_list{i}, 'window');
            end

        end
    end
end

end