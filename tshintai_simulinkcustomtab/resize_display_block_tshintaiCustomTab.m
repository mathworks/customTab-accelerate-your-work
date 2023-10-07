function resize_display_block_tshintaiCustomTab()
%% 説明
% モデル内に存在するDisplayブロックのサイズを、
% 接続されている信号の次元に合わせて、
% 信号の数値が全て見えるサイズに変更する。
%%
COMMA = char(39);
model_name = bdroot;

Display_size_data = struct;
Display_size_data.base_size = [90, 30];
Display_size_data.one_element_x_size = 75;
Display_size_data.one_element_y_size = 20;
Display_size_data.max_column_num = 20;
Display_size_data.max_row_num = 10;


%%
display_block_list = find_system(model_name, ...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'regexp', 'on', 'blocktype', 'Display');

if isempty(display_block_list)
    return;
end

%%
% 1番目はDisplayブロック名、
% 2番目は接続先信号の次元
display_block_num = numel(display_block_list);
display_block_info = cell(display_block_num, 2);

eval([model_name, '([],[],[],', COMMA, 'compile', ...
    COMMA, ');']);

for i = 1:numel(display_block_list)
    display_block_info{i, 1} = display_block_list{i};

    port_handles = get_param(display_block_info{i, 1}, 'PortHandles');
    display_block_info{i, 2} = get_param(port_handles.Inport(1), 'CompiledPortDimensions');
end

eval([model_name, '([],[],[],', COMMA, 'term', ...
    COMMA, ');']);

%%

for i = 1:display_block_num
    display_size = size(display_block_info{i, 2}, 2);
    if display_size == 2
        resize_display_block(display_block_info{i, 1}, ...
            display_block_info{i, 2}, Display_size_data);

    elseif display_size == 3
        resize_display_block(display_block_info{i, 1}, ...
            display_block_info{i, 2}(2:3), Display_size_data);
    else
        % Do Nothing.
    end
end


end

function resize_display_block(display_block_name, ...
    display_block_size_info, Display_size_data)
display_block_position = get_param(...
    display_block_name, 'Position');

display_block_position(3) = ...
    display_block_position(1) + ...
    Display_size_data.base_size(1) + ...
    Display_size_data.one_element_x_size * ...
    min(Display_size_data.max_row_num, ...
    (display_block_size_info(2) - 1));

display_block_position(4) = ...
    display_block_position(2) + ...
    Display_size_data.base_size(2) + ...
    Display_size_data.one_element_y_size * ...
    min(Display_size_data.max_column_num, ...
    (display_block_size_info(1) - 1));

set_param(display_block_name, 'Position', ...
    display_block_position);

end
