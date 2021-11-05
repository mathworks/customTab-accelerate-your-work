function close_delete_test_harness_tshintaiCustomTab()
%% 説明
% そのモデルがテストハーネスの場合、そのテストハーネスを閉じて削除します。
% テストハーネスではない場合、その階層にあるブロックに関連付けられている
% テストハーネスを全て削除します。
%%
model_name = bdroot;

%%
try
    isharness = get_param(model_name, 'IsHarness');
    if strcmp(isharness, 'off')

        find_and_delete_harness(model_name);

    else

        this_harness_name = model_name;
        close_system(model_name);

        harness_list = sltest.harness.find(bdroot);
        if isempty(harness_list)
            return;
        end

        for i = 1:numel(harness_list)
            if strcmp(harness_list(i).name, this_harness_name)
                sltest.harness.delete(harness_list(i).ownerFullPath, ...
                    this_harness_name);
            end
        end

    end

catch

    find_and_delete_harness(model_name);

end

end

function find_and_delete_harness(model_name)

harness_list = sltest.harness.find(model_name);
if isempty(harness_list)
    return;
end

for i = 1:numel(harness_list)
    sltest.harness.delete(harness_list(i).ownerFullPath, ...
        harness_list(i).name);
end

end
