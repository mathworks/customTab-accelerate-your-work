function reset_model_color_and_close_tab_tshintaiCustomTab()
%% 説明
% モデル内のブロックの色をリセットし、タブを全て閉じます。
%%
model_name = bdroot;
block_list = find_system(model_name, ...
    'MatchFilter', @Simulink.match.activeVariants);

open_system(model_name);

for i = 2:size(block_list, 1)
    set_param(block_list{i, 1}, 'ForegroundColor', 'black');
    set_param(block_list{i, 1}, 'BackgroundColor', 'white');
    
    close_system(block_list{i, 1});
end

end