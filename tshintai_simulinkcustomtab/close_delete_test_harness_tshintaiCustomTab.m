function close_delete_test_harness_tshintaiCustomTab()
%% 説明
% そのモデルがテストハーネスの場合、そのテストハーネスを閉じて削除します。
% テストハーネスではない場合、その階層にあるブロックに関連付けられている
% テストハーネスを全て削除します。
%%
try
    isharness = get_param(gcs, 'IsHarness');
    if strcmp(isharness, 'off')

        find_and_delete_harness(gcs);

    else

        this_harness_name = gcs;
        close_system(gcs);

        harness_list = sltest.harness.find(gcs);
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

    find_and_delete_harness(gcs);

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
