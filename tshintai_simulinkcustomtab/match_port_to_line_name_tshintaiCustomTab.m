function match_port_to_line_name_tshintaiCustomTab()
%% 説明
% 信号線が選択されていない場合、今の階層のInport, Outportブロックの
% ブロック名を接続されている信号線の信号名へコピーする。
% 信号線が選択されている場合、その信号に対してのみ、コピーを実行する。
%%
this_system = gcs;

selected_line_list = find_system(this_system,...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'FindAll','on', ...
    'Type','Line', ...
    'Selected','on');

if isempty(selected_line_list)
    line_list = find_system(this_system,...
        'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'FindAll','on', ...
    'Type','Line');
else
    line_list = selected_line_list;
end

%%
for i = 1:numel(line_list)
    source_block_handle = get_param(line_list(i), 'SrcBlockHandle');
    destination_block_handle = get_param(line_list(i), 'DstBlockHandle');

    for j = 1:numel(destination_block_handle)
        set_line_name(destination_block_handle(j), line_list(i));
    end
    set_line_name(source_block_handle, line_list(i));
end

end


function set_line_name(block_handle, line_handle)

block_type = get_param(block_handle, 'BlockType');

if (strcmp(block_type, 'Outport') || ...
    strcmp(block_type, 'Inport') )
    element_name = get_param(block_handle, 'Element');
    if isempty(element_name)
        port_name = get_param(block_handle, 'PortName');
        set_param(line_handle, 'Name', port_name);
    else
        set_param(line_handle, 'Name', element_name);
    end
end

end
