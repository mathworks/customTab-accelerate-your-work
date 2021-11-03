function diff_with_latest_commit_sldd_tshintaiCustomTab()
%% 説明
% モデルに関連付けられているslddファイルの現在の保存状態と
% ローカルリポジトリの最新コミット状態を比較します。
% Gitのコマンドを使用しているため、Gitがインストールされていること、
% slddファイルがGit管理されていることが前提となります。
%%
linked_sldd_name = get_param(bdroot,'DataDictionary');

if isempty(linked_sldd_name)
    return;
end

sldd_file_fullPath = '';
if exist(linked_sldd_name, 'file')
    SLDDObj = Simulink.data.dictionary.open(linked_sldd_name);
    saveChanges(SLDDObj);
    SLDDObj.hide;
    SLDDObj.close;

    sldd_file_fullPath = which(linked_sldd_name);
else
    return;
end

sldd_file = strsplit(linked_sldd_name, '.');
copyfile(sldd_file_fullPath, [sldd_file{1}, '_temp.sldd']);

%%
[~, commit_hash] = system('git rev-parse HEAD');
hash_text = strsplit(commit_hash, newline);

system(['git checkout ', hash_text{1}, ' "', sldd_file_fullPath, '"']);

%%
movefile(sldd_file_fullPath, [sldd_file{1}, '_', hash_text{1}, '.sldd']);
movefile([sldd_file{1}, '_temp.sldd'], sldd_file_fullPath);

%%
visdiff(sldd_file_fullPath, [sldd_file{1}, '_', hash_text{1}, '.sldd']);

end