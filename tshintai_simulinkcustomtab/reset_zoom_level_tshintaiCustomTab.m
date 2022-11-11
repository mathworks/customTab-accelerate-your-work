function reset_zoom_level_tshintaiCustomTab()
%% 説明
% モデル内の全てのサブシステム階層のズームレベルを
% キャンバス内のブロックが丁度全部見える状態にフィットさせる。
%%
top_model_name = bdroot;
subsystem_list = find_system(top_model_name, ...
    'LookUnderMasks', 'on', ...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'BlockType', 'SubSystem');

% MATLAB Functionブロックに対しては実行しない
bd_object = get_param(top_model_name, "Object");
MF_block_info = find(bd_object, "-isa", "Stateflow.EMChart");

% Stateflowブロックに対しては実行しない
ThisMachine = find(sfroot, '-isa', 'Stateflow.Machine', ...
                          'Name', top_model_name);
if isempty(ThisMachine)
    chart_list = '';
else
    chart_list = find(ThisMachine, '-isa', 'Stateflow.Chart', ...
    '-or', '-isa', 'Stateflow.TruthTableChart', ...
    '-or', '-isa', 'Stateflow.StateTransitionTableChart');
end

%%
top_model_tabbed = false;

for i = 1:numel(subsystem_list)
    is_MFB = false;
    for j = 1:numel(MF_block_info)
        if strcmp(MF_block_info(j).Path, subsystem_list{i})
            is_MFB = true;
            break;
        end
    end

    is_SFB = false;
    for j = 1:numel(chart_list)
        if strcmp(chart_list(j).Path, subsystem_list{i})
            is_SFB = true;
            break;
        end
    end

    if (~is_MFB && ~is_SFB)
        open_system(subsystem_list{i}, 'force');

        if ~top_model_tabbed
            open_system(top_model_name, 'tab');
            top_model_tabbed = true;
        end
        set_param(subsystem_list{i}, ...
            'ZoomFactor', 'FitSystem');
        close_system(subsystem_list{i});
    end
end

open_system(top_model_name);
set_param(top_model_name, 'ZoomFactor', 'FitSystem');

end
