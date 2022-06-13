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
try
    save_system(this_harness_name);
catch
    error('モデルが保存できませんので、保存できるようにしてください。');
end
close_system(this_harness_name);

harness_list = sltest.harness.find(bdroot);
if isempty(harness_list)
    return;
end

for i = 1:numel(harness_list)
    if strcmp(harness_list(i).name, this_harness_name)
        harness_owner_name = harness_list(i).ownerFullPath;
    end
end

harness_name_temp = [this_harness_name, '____temporary____'];
sltest.harness.create(harness_owner_name, 'Name', harness_name_temp, ...
    'CreateWithoutCompile', true);
sltest.harness.load(harness_owner_name, harness_name_temp);

%%
Signal_spec_outside_name = ...
    ['Output', newline, 'Conversion', newline 'Subsystem'];
Signal_spec_inside_name = ...
    ['Input', newline, 'Conversion', newline 'Subsystem'];

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
Signal_spec_inside_harness_path = ...
    [this_harness_name, '/', Signal_spec_inside_name];
Signal_spec_outside_harness_path = ...
    [this_harness_name, '/', Signal_spec_outside_name];

add_block(Signal_spec_inside_harness_temp_path, ...
    Signal_spec_inside_model_temp_path);
add_block(Signal_spec_outside_harness_temp_path, ...
    Signal_spec_outside_model_temp_path);

sltest.harness.close(harness_owner_name, harness_name_temp);
sltest.harness.delete(harness_owner_name, harness_name_temp);

%%
sltest.harness.open(harness_owner_name, this_harness_name);

Signal_spec_inside_position = get_param(...
    Signal_spec_inside_harness_path, ...
    'Position');
Signal_spec_outside_position = get_param(...
    Signal_spec_outside_harness_path, ...
    'Position');

delete_block(Signal_spec_inside_harness_path);
delete_block(Signal_spec_outside_harness_path);

add_block(Signal_spec_inside_model_temp_path, ...
    Signal_spec_inside_harness_path);
add_block(Signal_spec_outside_model_temp_path, ...
    Signal_spec_outside_harness_path);

set_param(Signal_spec_inside_harness_path, ...
    'Position', Signal_spec_inside_position);
set_param(Signal_spec_outside_harness_path, ...
    'Position', Signal_spec_outside_position);

%%
close_system(temp_model_handle, 0);
save_system(harness_owner_name);

end
