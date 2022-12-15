function unselect_all_blocks_tshintaiCustomTab(this_system)

selected_block_list = find_system(this_system, ...
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth',1, ...
        'Selected','on');

if isempty(selected_block_list)
    return;
elseif (numel(selected_block_list) == 1)
    if strcmp(selected_block_list{1}, this_system)
        return;
    else
        block_list = selected_block_list;
    end
elseif strcmp(selected_block_list{1}, this_system)
    block_list = selected_block_list(2:end);
else
    block_list = selected_block_list;
end

for i = 1:numel(block_list)
    set_param(block_list{i}, 'Selected', 'off');
end

end
