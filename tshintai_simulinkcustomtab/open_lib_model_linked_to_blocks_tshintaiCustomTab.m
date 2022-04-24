function open_lib_model_linked_to_blocks_tshintaiCustomTab()
%% 説明
% 選択したライブラリリンクされたブロックの参照元を開きます。
%%
selected_block_list = find_system(gcs, ...
    'SearchDepth',1, ...
    'Selected','on');

if isempty(selected_block_list)
    return;
else
    list_num = numel(selected_block_list);
end

%%
for i = 1:list_num
    linked_block_path = get_linked_block_path(selected_block_list{i});
    if ~isempty(linked_block_path)
        path_text = strsplit(linked_block_path, '/');
        open_system(path_text{1});
        lib_block_path = find_system(path_text{1}, 'Name', path_text{end});
        lib_block_parent_path = get_param(lib_block_path, 'Parent');
        open_system(lib_block_parent_path);
    end
end

end

function linked_path = get_linked_block_path(block_path)

reference_path = get_param(block_path, 'ReferenceBlock');
ancestor_path = get_param(block_path, 'AncestorBlock');

if isempty(reference_path)
    linked_path = ancestor_path;
else
    linked_path = reference_path;
end

end