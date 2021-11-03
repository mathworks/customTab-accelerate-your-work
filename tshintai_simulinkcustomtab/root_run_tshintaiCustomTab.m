function root_run_tshintaiCustomTab()
%% 説明
% モデルを参照している参照構造の最上位階層のモデルを実行します。
% 最上位階層のモデルが複数ある場合、ダイアログで選択します。
% 上位階層のモデルが閉じられている場合は、検索されません。
%%
child_model_name = bdroot;

loaded_models = Simulink.allBlockDiagrams('model');
loaded_models_name = get_param(loaded_models,'Name');

other_models_name = loaded_models_name(~strcmp(loaded_models_name, ...
    child_model_name));

if (numel(other_models_name) < 1)
    set_param(child_model_name, 'SimulationCommand', 'start');
    return;
end

%%
related = false(numel(other_models_name), 1);
for i = 1:numel(other_models_name)

    [ref_model_name, ~] = find_mdlrefs(other_models_name{i});
    find_name = ref_model_name(strcmp(ref_model_name, child_model_name));

    if ~isempty(find_name)
        related(i) = true;
    end
end

related_model_name = other_models_name(related);
if (numel(related_model_name) < 1)
    set_param(child_model_name, 'SimulationCommand', 'start');
    return;
end

%%
related_score = zeros(numel(related_model_name), 1);

for i = 1:numel(related_model_name)
    
    [ref_model_name, ~] = find_mdlrefs(related_model_name{i});
    ref_model_name = ref_model_name(~strcmp(ref_model_name, ...
                                            related_model_name{i}));

    for j = 1:numel(related_model_name)
        for k = 1:numel(ref_model_name)
            if strcmp(related_model_name{j}, ref_model_name{k})
                related_score(j) = related_score(j) + 1;
            end
        end
    end

end

%%
root_model_index = find(related_score == min(related_score));

if (numel(root_model_index) > 1)
    [RM_indx, tf] = listdlg('SelectionMode','single', ...
        'ListString', related_model_name(root_model_index), ...
        'PromptString', {'実行するモデルを選択してください：'}, ...
        'ListSize', [250, 300]);
    if ~(tf)
        return;
    end

    set_param(related_model_name{RM_indx}, 'SimulationCommand', 'start');

else

    set_param(related_model_name{root_model_index(1)}, ...
        'SimulationCommand', 'start');

end

end