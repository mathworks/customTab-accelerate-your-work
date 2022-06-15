function close_and_reopen_model_tshintaiCustomTab()
%% 説明
% モデルファイルを保存せずに閉じ、そのモデルファイルを再度開きます。
% モデルを保存された状態に戻すことが目的です。
%%
model_name = bdroot;

if strcmp(get_param(model_name, 'IsHarness'), 'on')
    close_system(model_name);

    harness_list = sltest.harness.find(bdroot);
    if isempty(harness_list)
        return;
    end

    for i = 1:numel(harness_list)
        if strcmp(harness_list(i).name, model_name)
            harness_owner_name = harness_list(i).ownerFullPath;
        end
    end

    %%
    root_model_name = strsplit(harness_owner_name, '/');

    close_system(root_model_name{1}, 0);
    open_system(root_model_name{1});
    sltest.harness.open(harness_owner_name, model_name);
else
    %%
    close_system(model_name, 0);
    open_system(model_name);
end

end
