function open_system_with_new_window_tshintaiCustomTab()
%% 説明
% 選択したブロックを新しいウィンドウで開きます。
% 選択していない場合は、現在の階層を対象に開きます。
% 参照モデル、参照サブシステムなどを対象とした機能です。
% 普通のブロックを選択して実行した場合、ブロックパラメータが開きます。
%%
model_root = bdroot;
selected_block_list = find_system(gcs, ...
    'MatchFilter', @Simulink.match.allVariants, ...
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

        open_system_near_bdroot_tshintaiCustomTab(selected_block_list{i}, model_root);

    else
        try
            is_variant = get_param(selected_block_list{i}, 'Variant');
        catch
            is_variant = 'off';
        end

        if strcmp(is_variant ,'on')
            sub_block_list = find_system(selected_block_list{i}, ...
                'MatchFilter', @Simulink.match.allVariants, ...
                'SearchDepth', 1, ...
                'regexp', 'on', 'BlockType', 'SubSystem|ModelReference');
            if numel(sub_block_list) < 1.5
                return;
            end

            block_path_to_open = sub_block_list{2};
        else
            block_path_to_open = selected_block_list{i};
        end

        if strcmp(get_param(block_path_to_open, 'BlockType'), ...
                'ModelReference')
            ref_model_name = get_param(block_path_to_open, 'ModelName');
            open_system_near_bdroot_tshintaiCustomTab(ref_model_name, model_root);

        else

            try
                subsystem_ref_name = get_param(block_path_to_open, ...
                    'ReferencedSubsystem');
            catch
                subsystem_ref_name = '';
            end

            if ~isempty(subsystem_ref_name)
                open_system_near_bdroot_tshintaiCustomTab(subsystem_ref_name, model_root);
            else
                open_system_near_bdroot_tshintaiCustomTab(block_path_to_open, model_root);
            end

        end
    end
end

end
