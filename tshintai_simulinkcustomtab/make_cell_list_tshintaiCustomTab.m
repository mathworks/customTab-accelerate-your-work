function cell_block_list = make_cell_list_tshintaiCustomTab(block_list)
%%
if isempty(block_list)
    return;
elseif ~iscell(block_list)
    cell_block_list = cell(1, 1);
    cell_block_list{1} = block_list;
else
    cell_block_list = block_list;
end

end