function simout = root_run_tshintaiCustomTab(sim_command_flag)
%% 説明
% モデルを参照している参照構造の最上位階層のモデルを実行します。
% 最上位階層のモデルが複数ある場合、ダイアログで選択します。
% 上位階層のモデルが閉じられている場合は、検索されません。
%%
simout = '';
if (nargin < 0.5)
    sim_command_flag = false;
end

%%
% RoadRunner用の「Simulink.ScenarioSimulation」変数がある場合、
% RoadRunnerを実行する。
COMMA = char(39);
var_list = evalin('base', 'who;');
for i = 1:numel(var_list)
    command_text = ['isa(', var_list{i}, ', ', COMMA, ...
                    'Simulink.ScenarioSimulation', COMMA, ');'];
    rr_flag = evalin('base', command_text);
    if (rr_flag)
        run_rr_text = [var_list{i}, '.set(', ...
            COMMA, 'SimulationCommand', COMMA, ...
            ', ', COMMA, 'Start', COMMA, ');'];
        evalin('base', run_rr_text);

        simout = var_list{i};

        return;
    end
end

%%
child_model_name = bdroot;
if strcmp(get_param(child_model_name, "IsHarness"), 'on')
    % テストハーネスモデルの場合、そのモデルを実行
    simout = run_model(child_model_name, sim_command_flag);
    return;
else
    child_model_info = Simulink.MDLInfo(child_model_name);
end

loaded_models = Simulink.allBlockDiagrams('model');
loaded_models_name = get_param(loaded_models,'Name');

other_models_name = loaded_models_name(~strcmp(loaded_models_name, ...
    child_model_name));

if (numel(other_models_name) < 1)
    if strcmp(child_model_info.BlockDiagramType, 'Model')
        simout = run_model(child_model_name, sim_command_flag);
    end
    return;
end

%%
if strcmp(child_model_info.BlockDiagramType, 'Model')
    related_model_name = find_model_referencing(...
        other_models_name, child_model_name);

    if (numel(related_model_name) < 1)
        simout = run_model(child_model_name, sim_command_flag);
        return;
    end

elseif strcmp(child_model_info.BlockDiagramType, 'Subsystem')
    related_model_name = find_subsystem_referencing(...
        child_model_name);

    if (numel(related_model_name) < 1)
        return;
    end
else
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

    simout = run_model(related_model_name{RM_indx}, sim_command_flag);

else

    simout = run_model(related_model_name{root_model_index(1)}, ...
        sim_command_flag);

end

end


function related_model_name = find_model_referencing(...
    other_models_name, child_model_name)

related = false(numel(other_models_name), 1);
for i = 1:numel(other_models_name)

    [ref_model_name, ~] = find_mdlrefs(other_models_name{i});
    find_name = ref_model_name(strcmp(ref_model_name, child_model_name));

    if ~isempty(find_name)
        related(i) = true;
    end
end

related_model_name = other_models_name(related);

end


function related_model_name = find_subsystem_referencing(...
    child_model_name)
related_model_name = [];

if strcmp(version('-release'), '2021b')
    % Do Nothing.
else
    model_name = ...
        Simulink.SubsystemReference.getActiveInstances(...
        child_model_name);

    if numel(model_name) < 1.5
        return;
    end

    related_model_name = cell(numel(model_name) - 1, 1);
    valid_model_flag = true(numel(related_model_name), 1);
    for i = 2:numel(model_name)
        temp = strsplit(model_name{i}, '/');
        related_model_name{i - 1} = temp{1};

        info = Simulink.MDLInfo(temp{1});
        if ~strcmp(info.BlockDiagramType, 'Model')
            valid_model_flag(i - 1) = false;
        end
    end

    % サブシステムと被っているモデル名を外す
    related_model_name = related_model_name(valid_model_flag);
    related_model_name = unique(related_model_name);
end

end

function simout = run_model(model_name, sim_command_flag)

if sim_command_flag
    simout = sim(model_name);
else
    set_param(model_name, 'SimulationCommand', 'start');
    simout = '';
end

end
