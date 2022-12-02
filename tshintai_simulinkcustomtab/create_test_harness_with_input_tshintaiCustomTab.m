function create_test_harness_with_input_tshintaiCustomTab()
%% 説明
% 現在のモデルを実行した結果、そのサブシステムに入力される
% 信号データをそのままテストハーネスの入力データとして用いる形で、
% テストハーネスを新規作成する。
%%
COMMA = char(39);
model_name = bdroot;
system_name = gcs;
added_name = '__harness__FW';

selected_block_list = find_system(system_name, ...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'Selected','on');

if ( (numel(selected_block_list) > 1) && ...
        strcmp(selected_block_list{1}, system_name) )
    selected_block_list = selected_block_list(2:end);
end

%%
subsystem_type = check_block_is_subsystem_tshintaiCustomTab( ...
    selected_block_list{1});

if (subsystem_type(1) == 0 || subsystem_type(1) == 3)
    error('サブシステム、サブシステム参照を選択してください。');
end

%%
block_path = selected_block_list{1};
harness_name = replace_bad_names([block_path, added_name]);
harness_name = round_long_harness_name_tshintaiCustomTab(harness_name);

harness_list = sltest.harness.find(block_path);

harness_exists_flag = false;
for i = 1:numel(harness_list)
    if strcmp(harness_list(i).name, harness_name)
        harness_exists_flag = true;
    end
end

%%
if (harness_exists_flag)
    error('すでに入力継承テストハーネスが存在しています。');
end

%%
block_name = get_param(block_path, 'Name');
block_path_str = strsplit(block_path, '/');
subsystem_path = '';
end_1 = numel(block_path_str) - 1;

for i = 1:end_1
    subsystem_path = [subsystem_path, block_path_str{i}];
    if i < end_1
        subsystem_path = [subsystem_path, '/'];
    end
end
temp_block_path = [subsystem_path, '/', block_name, added_name];
sub_block_path = [temp_block_path, '/', block_name];

block_handle = get_param(block_path, 'Handle');
Simulink.BlockDiagram.createSubsystem(block_handle, 'Name', ...
    [block_name, added_name]);

%%
[set_line_info, logsout_name] = ...
    set_input_logging(model_name, sub_block_path);
if isempty(set_line_info)
    error('入力ポートが存在していません。');
end

%%
block_ts_obj = Simulink.Block.getSampleTimes(sub_block_path);
block_ts = block_ts_obj.Value(1);

%%
eval([model_name, '([],[],[],', COMMA, 'compile', ...
        COMMA, ');']);

port_handles = get_param(sub_block_path, 'Porthandles');
port_data_types = cell(numel(port_handles.Inport), 1);
for i = 1:numel(port_data_types)
    port_data_types{i} = get_param(...
        port_handles.Inport(i), 'CompiledPortDataType');
end

eval([model_name, '([],[],[],', COMMA, 'term', ...
        COMMA, ');']);

%%
% モデルを実行して入力データを保存する
simout = root_run_tshintaiCustomTab(true);

% RoadRunnerを実行した場合は、終わるまで待たせる。
if isa(simout, 'char')
    command_text = ['isa(', simout, ', ', COMMA, ...
        'Simulink.ScenarioSimulation', COMMA, ');'];
    rr_flag = evalin('base', command_text);
else
    rr_flag = false;
end

if (rr_flag)
    running_flag = true;
    while running_flag
        check_running_text = ['strcmp(get(rrSim,', COMMA, ...
            'SimulationStatus', COMMA, '), ', COMMA, ...
            'Running', COMMA, ');'];
        running_flag = evalin('base', check_running_text);
        pause(0.5);
    end

    simout = evalin('base', 'simout;');
end

round_set_line_name = cell(size(set_line_info, 1), 1);
for i = 1:size(set_line_info, 1)
    round_set_line_name{i} = round_long_harness_name_tshintaiCustomTab(set_line_info{i, 2});
    eval([round_set_line_name{i}, ' = simout.', ...
          logsout_name, '.get(set_line_info{i, 2});']);
    save([round_set_line_name{i}, '.mat'], round_set_line_name{i});
end

clear_input_logging(sub_block_path, set_line_info);

%%
sltest.harness.create(sub_block_path, 'Name', harness_name, ...
    'Source', 'From Workspace', ...
    'CreateWithoutCompile', true);
sltest.harness.open(sub_block_path, harness_name);

%%
BW_access = get_param(model_name, 'EnableAccessToBaseWorkspace');
if strcmp(BW_access, 'off')
    set_param(harness_name, 'EnableAccessToBaseWorkspace', 'off');
end
set_param(harness_name, 'ShowPortDataTypes', 'on');
set_param(harness_name, 'ShowLineDimensions', 'on');

%%
harness_workspace = get_param(harness_name, 'ModelWorkspace');

for i = 1:size(set_line_info, 1)
    %%
    load_text = ['load(', COMMA, round_set_line_name{i}, ...
        '.mat', COMMA, ');'];
    evalin(harness_workspace, load_text);
    evalin(harness_workspace, [set_line_info{i, 3}, ' = ', round_set_line_name{i}, ';']);
    evalin(harness_workspace, [set_line_info{i, 3}, '.Name = ', ...
                    COMMA, set_line_info{i, 3}, COMMA, ';']);
    evalin(harness_workspace, ['clear ', round_set_line_name{i}]);
    eval(['delete ', round_set_line_name{i}, '.mat']);

    %%
    fw_block_path = [harness_name, '/', set_line_info{i, 3}];
    port_handles = get_param(fw_block_path, 'PortHandles');
    line_handle = get_param(port_handles.Outport(1), 'Line');
    set_param(line_handle, 'Name', set_line_info{i, 3});
    Simulink.sdi.markSignalForStreaming(line_handle, 'on');

    %%
    eval(['set_param(', COMMA, harness_name, '/', ...
        set_line_info{i, 3}, COMMA, ',', COMMA, ...
        'SampleTime', COMMA, ',', COMMA, ...
        num2str(block_ts), COMMA, ');']);

    %%
    eval(['set_param(', COMMA, harness_name, '/', ...
        set_line_info{i, 3}, COMMA, ',', COMMA, ...
        'OutDataTypeStr', COMMA, ',', COMMA, ...
        port_data_types{i}, COMMA, ');']);
end

%%
linked_sldd_name = get_param(model_name, 'DataDictionary');
if ~isempty(linked_sldd_name)
    set_param(harness_name, 'DataDictionary', linked_sldd_name);
end

%%
Simulink.BlockDiagram.expandSubsystem(temp_block_path);

area_handle = find_system(subsystem_path, ...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'FindAll', 'on', ...
    'type', 'annotation', ...
    'Name', [block_name, added_name]);
delete(area_handle);

end


function [line_info, logsout_name] = ...
    set_input_logging(model_name, block_path)
%%
% line_infoは、変更された信号線のハンドル、名前、ポート名を格納する。
block_path_cell = cell(1, 1);
block_path_cell{1} = block_path;

all_inport_list = get_all_inport_lists_tshintaiCustomTab(...
                    block_path_cell, true);
if isempty(all_inport_list{1, 1})
    line_info = '';
    logsout_name = '';
else
    empty_cell = cell(numel(all_inport_list), 1);

    inport_names = get_port_names_tshintaiCustomTab(...
        all_inport_list, empty_cell, empty_cell);

    line_info = cell(numel(inport_names), 3);

    for i = 1:numel(inport_names)
        line_info{i, 1} = get_param(all_inport_list{i, 3}, 'Line');
        line_info{i, 2} = replace_bad_names(...
            [block_path, '_', inport_names{i}]);
        set_param(line_info{i, 1}, 'Name', line_info{i, 2});
        Simulink.sdi.markSignalForStreaming(line_info{i, 1}, 'on');
        
        if isempty(inport_names{i})
            if strcmp('enable', get_param(all_inport_list{i, 3}, 'PortType'))
                line_info{i, 3} = 'Enable';
            elseif strcmp('trigger', get_param(all_inport_list{i, 3}, 'PortType'))
                line_info{i, 3} = 'Trigger';
            elseif strcmp('Reset', get_param(all_inport_list{i, 3}, 'PortType'))
                line_info{i, 3} = 'Reset';
            end
        else
            line_info{i, 3} = inport_names{i};
        end
    end

    %%
    activeConfigObj = getActiveConfigSet(model_name);
    if isa(activeConfigObj, 'Simulink.ConfigSet')
        ConfigObj = activeConfigObj;
    elseif isa(activeConfigObj, 'Simulink.ConfigSetRef')
        ConfigObj = getRefConfigSet(activeConfigObj);
    else
        error('コンフィギュレーションパラメーターが異常です。');
    end

    d_component = ConfigObj.getComponent('Data Import/Export');

    d_component.SignalLogging = 'on';
    d_component.SaveFormat = 'Dataset';
    d_component.ReturnWorkspaceOutputs = 'on';
    d_component.ReturnWorkspaceOutputsName = 'simout';

    logsout_name = d_component.SignalLoggingName;

end

end

function clear_input_logging(block_path, line_info)

for i = 1:size(line_info, 1)
    set_param(line_info{i, 1}, 'Name', '');
    Simulink.sdi.markSignalForStreaming(line_info{i, 1}, 'off');
end

end

function rep_name_string = replace_bad_names(name_string)
%%
name_temp = strrep(name_string, newline, '_');
name_temp = strrep(name_temp, ' ', '_');
name_temp = strrep(name_temp, '-', '_');
name_temp = strrep(name_temp, '/', '_');
name_temp = strrep(name_temp, '\', '_');
rep_name_string = name_temp;

end
