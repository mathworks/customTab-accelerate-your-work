function save_this_SDI_view_tshintaiCustomTab()
%% 説明
% 今のシミュレーションデータインスペクターのViewを
% ファイルに保存します。ファイル名にはモデル名を含めます。
% これにより、load_this_model_view_tshintaiCustomTab
% の方でモデル名に紐づいたファイルを読み込むことができます。
%%
model_name = bdroot;
SDI_view_file_name = [model_name, '__SDI__view__', '.mldatx'];

Simulink.sdi.saveView(SDI_view_file_name);

end