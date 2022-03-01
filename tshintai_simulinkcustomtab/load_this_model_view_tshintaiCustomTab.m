function load_this_model_view_tshintaiCustomTab()
%% 説明
% save_this_SDI_view_tshintaiCustomTabで保存された
% このモデル名に紐づいた設定ファイルを読み込みます。
%%
model_name = bdroot;
SDI_view_file_name = [model_name, '__SDI__view__', '.mldatx'];

if exist(SDI_view_file_name, 'file')
    Simulink.sdi.loadView(SDI_view_file_name);
end

end