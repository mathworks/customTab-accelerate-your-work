function disable_and_open_lib_block_tshintaiCustomTab()
%% 説明
% 選択したライブラリリンクされたブロックのライブラリリンクを無効にし、
% そのブロックの内部を開きます。
%%
selected_block_list = find_system(gcs, ...
    'LookUnderMasks', 'all', ...
    'SearchDepth',1, ...
    'Selected','on');

if isempty(selected_block_list)
    return;
else
    list_num = numel(selected_block_list);
end

%%
for i = 1:list_num
    linked_block_path = get_param(selected_block_list{i}, 'ReferenceBlock');
    if ~isempty(linked_block_path)
        set_param(selected_block_list{i}, 'LinkStatus', 'inactive');
        open_system(selected_block_list{i}, 'force');
    end
end

end