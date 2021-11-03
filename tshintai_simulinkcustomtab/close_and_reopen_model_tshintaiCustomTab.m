function close_and_reopen_model_tshintaiCustomTab()
%% 説明
% モデルファイルを保存せずに閉じ、そのモデルファイルを再度開きます。
% モデルを保存された状態に戻すことが目的です。
%%
model_name = bdroot;

close_system(model_name, 0);
open_system(model_name);

end