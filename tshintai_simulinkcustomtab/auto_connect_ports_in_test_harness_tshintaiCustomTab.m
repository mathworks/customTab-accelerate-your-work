function auto_connect_ports_in_test_harness_tshintaiCustomTab()
%% 説明
% テストハーネスでテストを行う対象のサブシステムの
% ポートの数が変化した時、「Signal spec. and routing」ブロックも
% 合わせて修正したい。この時、このスクリプトを実行することで
% 「Signal spec. and routing」を更新することができる。
%%
this_harness_name = bdroot;
if strcmp(get_param(this_harness_name, 'IsHarness'), 'off')
    return;
end

%%
generating_Signal_spec_handle = warndlg('Now regenerating ...');

%%
Signal_spec_outside_name = ...
    ['Output', newline, 'Conversion', newline 'Subsystem'];
Signal_spec_inside_name = ...
    ['Input', newline, 'Conversion', newline 'Subsystem'];
Signal_spec_inside_harness_path = ...
    [this_harness_name, '/', Signal_spec_inside_name];
Signal_spec_outside_harness_path = ...
    [this_harness_name, '/', Signal_spec_outside_name];

inside_old_exists = false;
outside_old_exists = false;
if (getSimulinkBlockHandle(Signal_spec_inside_harness_path) > -0.5)
    inside_old_exists = true;
end
if (getSimulinkBlockHandle(Signal_spec_outside_harness_path) > -0.5)
    outside_old_exists = true;
end

%%
close_system(this_harness_name);

harness_list = sltest.harness.find(bdroot);
if isempty(harness_list)
    if isvalid(generating_Signal_spec_handle)
        delete(generating_Signal_spec_handle)
    end
    return;
end

for i = 1:numel(harness_list)
    if strcmp(harness_list(i).name, this_harness_name)
        harness_owner_name = harness_list(i).ownerFullPath;
    end
end

% ここで、参照サブシステムである場合は事前に保存する必要がある
model_name_temp = strsplit(harness_owner_name, '/');
model_info = Simulink.MDLInfo(model_name_temp{1});
if numel(model_name_temp) < 1.5
    if strcmp(model_info.BlockDiagramType, 'Subsystem')
        save_system(model_name_temp{1}, [], 'SaveDirtyReferencedModels', true);
    end
end

harness_name_temp = [this_harness_name, '____temporary____'];
sltest.harness.create(harness_owner_name, 'Name', harness_name_temp, ...
    'CreateWithoutCompile', true);
sltest.harness.load(harness_owner_name, harness_name_temp);

%%
temp_model_handle = new_system;
load_system(temp_model_handle);
temp_model_name = get_param(0, 'CurrentSystem');

Signal_spec_inside_harness_temp_path = ...
    [harness_name_temp, '/', Signal_spec_inside_name];
Signal_spec_outside_harness_temp_path = ...
    [harness_name_temp, '/', Signal_spec_outside_name];
Signal_spec_inside_model_temp_path = ...
    [temp_model_name, '/', Signal_spec_inside_name];
Signal_spec_outside_model_temp_path = ...
    [temp_model_name, '/', Signal_spec_outside_name];

%%
inside_exists = false;
outside_exists = false;
if (getSimulinkBlockHandle(Signal_spec_inside_harness_temp_path) > -0.5)
    inside_exists = true;
end
if (getSimulinkBlockHandle(Signal_spec_outside_harness_temp_path) > -0.5)
    outside_exists = true;
end

%%
if (inside_exists)
add_block(Signal_spec_inside_harness_temp_path, ...
    Signal_spec_inside_model_temp_path);
end
if (outside_exists)
add_block(Signal_spec_outside_harness_temp_path, ...
    Signal_spec_outside_model_temp_path);
end

sltest.harness.close(harness_owner_name, harness_name_temp);
sltest.harness.delete(harness_owner_name, harness_name_temp);

%%
sltest.harness.open(harness_owner_name, this_harness_name);

if (inside_exists && inside_old_exists)
Signal_spec_inside_position = get_param(...
    Signal_spec_inside_harness_path, ...
    'Position');
end
if (outside_exists&& outside_old_exists)
Signal_spec_outside_position = get_param(...
    Signal_spec_outside_harness_path, ...
    'Position');
end

if (getSimulinkBlockHandle(Signal_spec_inside_harness_path) > -0.5)
    delete_block(Signal_spec_inside_harness_path);
end
if (getSimulinkBlockHandle(Signal_spec_outside_harness_path) > -0.5)
    delete_block(Signal_spec_outside_harness_path);
end

if (inside_exists)
add_block(Signal_spec_inside_model_temp_path, ...
    Signal_spec_inside_harness_path);
end
if (outside_exists)
add_block(Signal_spec_outside_model_temp_path, ...
    Signal_spec_outside_harness_path);
end

if (inside_exists && inside_old_exists)
set_param(Signal_spec_inside_harness_path, ...
    'Position', Signal_spec_inside_position);
end
if (outside_exists && outside_old_exists)
set_param(Signal_spec_outside_harness_path, ...
    'Position', Signal_spec_outside_position);
end

%%
close_system(temp_model_handle, 0);

if strcmp(model_info.BlockDiagramType, 'Model')
    top_model_name = strsplit(harness_owner_name, '/');
    save_system(top_model_name{1}, [], 'SaveDirtyReferencedModels', true);
elseif strcmp(model_info.BlockDiagramType, 'Subsystem')
    save_system(harness_owner_name, [], 'SaveDirtyReferencedModels', true);
else
    subsystem_type = check_block_is_subsystem_tshintaiCustomTab( ...
        harness_owner_name);
    if (subsystem_type == 0 || subsystem_type == 1)
        model_name = strsplit(harness_owner_name, '/');
        save_system(model_name{1}, [], 'SaveDirtyReferencedModels', true);
    else
        save_system(harness_owner_name, [], 'SaveDirtyReferencedModels', true);
    end
end

%%
if isvalid(generating_Signal_spec_handle)
    delete(generating_Signal_spec_handle)
end

end
