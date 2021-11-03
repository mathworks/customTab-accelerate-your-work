function revert_Simulink_model_tshintaiCustomTab()
%% 説明
% モデルファイルを閉じ、
% その後ローカルリポジトリの最新コミットの状態に戻します。
% Gitのコマンドを使用しているため、Gitがインストールされていること、
% モデルファイルがGit管理されていることが前提となります。
%%
model_name = bdroot;
model_full_path = which(model_name);

%%
close_system(model_name, 0);

%%
system(['git checkout HEAD -- "', model_full_path, '"']);

%%
open_system(model_name);

end