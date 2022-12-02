function close_delete_test_harness_tshintaiCustomTab()
%% 説明
% そのモデルがテストハーネスの場合、そのテストハーネスを閉じて削除します。
% テストハーネスではない場合、その階層にあるブロックに関連付けられている
% テストハーネスを全て削除します。
%%
model_name = bdroot;
selected_block_list = find_system(gcs, ...
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1, ...
        'Selected','on');

%%
% 「__s」と末尾についたサブシステムが選択されていた場合、
% 「作成/開く」のスクリプトで作成された一時的なサブシステム
% であるので、元に戻す。
idx__s = 0;
for i = 1:numel(selected_block_list)
    if strcmp(selected_block_list{i}(end-2:end), '__s')
        idx__s = i;
        break;
    end
end

%%
if (idx__s > 0.5)
    find_and_delete_harness(model_name, selected_block_list, idx__s);
else
    try
        isharness = get_param(model_name, 'IsHarness');
        if strcmp(isharness, 'off')

            find_and_delete_harness(model_name, selected_block_list, idx__s);

        else

            this_harness_name = model_name;
            close_system(model_name);

            harness_list = sltest.harness.find(bdroot);
            if isempty(harness_list)
                return;
            end

            for i = 1:numel(harness_list)
                if strcmp(harness_list(i).name, this_harness_name)
                    sltest.harness.delete(harness_list(i).ownerFullPath, ...
                        this_harness_name);
                end
            end

        end

    catch

        find_and_delete_harness(model_name, selected_block_list, idx__s);

    end
end

end

function find_and_delete_harness(model_name, selected_block_list, idx__s)
%%
if ~isempty(selected_block_list)
    if (idx__s > 0.5)
        block_original_pos = ...
            get_param(selected_block_list{idx__s}, 'Position');
        parent_path = ...
            get_param(selected_block_list{idx__s}, 'Parent');
        s_text = strsplit(selected_block_list{idx__s}(1:end-3), '/');
        post_block_path = [parent_path, '/', s_text{end}];

        original_block_path = [...
            selected_block_list{idx__s}, '/', ...
            s_text{end}];
        
        try
            add_block(original_block_path, post_block_path);
        catch
            return;
        end

        delete_block(selected_block_list{idx__s});
        set_param(post_block_path, 'Position', block_original_pos);
    else
        if (numel(selected_block_list) > 1.5 || ...
            (numel(selected_block_list) < 1.5 && ...
             ~strcmp(selected_block_list, model_name)))
            harness_list = sltest.harness.find(model_name);
            if isempty(harness_list)
                return;
            end

            for i = 1:numel(selected_block_list)
                for j = 1:numel(harness_list)
                    if (~strcmp(gcs, selected_block_list{i}) && ...
                            strcmp(harness_list(j).ownerFullPath, ...
                            selected_block_list{i}))
                        sltest.harness.delete(harness_list(j).ownerFullPath, ...
                            harness_list(j).name);
                    end
                end
            end
        end
    end
else
    %%
    harness_list = sltest.harness.find(model_name);
    if isempty(harness_list)
        return;
    end

    for i = 1:numel(harness_list)
        sltest.harness.delete(harness_list(i).ownerFullPath, ...
            harness_list(i).name);
    end
end

end
