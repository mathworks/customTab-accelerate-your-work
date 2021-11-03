function create_open_test_harness_tshintaiCustomTab()
%% 説明
% 選択したサブシステム、参照モデルなどにテストハーネスを作成して開きます。
% すでにテストハーネスが作成されている場合、そのハーネスを開きます。
% 複数のテストハーネスが作成されている場合、
% ダイアログで開くハーネスを選択します。
% 選択するブロックは一つだけでなければなりません。
% 何も選択されていない場合、現在のモデル階層に対して
% テストハーネスを作成し、開きます。
% 開いたハーネスには信号線の次元とデータ型を表示する設定を行います。
% ハーネスの入力ポートは削除し、信号にそのポート名を付けます。
%%
model_name = bdroot;
system_name = gcs;
selected_block_list = find_system(system_name, ...
    'SearchDepth', 1, ...
    'Selected','on');

if ( (numel(selected_block_list) > 1) && ...
     strcmp(selected_block_list{1}, system_name) )
    selected_block_list = selected_block_list(2:end);
end

%%
if isempty(selected_block_list)

    harness_list = sltest.harness.find(system_name, 'SearchDepth', 0);

    if isempty(harness_list)

        harness_name = [system_name, '_harness'];
        create_open_new_harness(model_name, system_name, harness_name);

    elseif numel(harness_list) == 1

        sltest.harness.open(system_name, harness_list(1).name);

    else

        choose_from_multiple_harnesses(harness_list, system_name);

    end

elseif numel(selected_block_list) > 1
    return;
else

    harness_list = sltest.harness.find(selected_block_list{1});

    if isempty(harness_list)

        block_name = get_param(selected_block_list{1}, 'Name');
        harness_name = [block_name, '_harness'];
        create_open_new_harness(model_name, selected_block_list{1}, harness_name);

    elseif numel(harness_list) == 1

        sltest.harness.open(selected_block_list{1}, harness_list(1).name);

    else

        choose_from_multiple_harnesses(harness_list, selected_block_list{1});

    end

end

end

function choose_from_multiple_harnesses(harness_list, system_name)

harness_name_list = cell(numel(harness_list), 1);
for i = 1:numel(harness_list)
    harness_name_list{i} = harness_list(i).name;
end

[RM_indx, tf] = listdlg('SelectionMode','single', ...
    'ListString', harness_name_list, ...
    'PromptString', {'開くテストハーネスを選択してください：'}, ...
    'ListSize', [250, 300]);
if ~(tf)
    return;
end

sltest.harness.open(system_name, ...
    harness_name_list(RM_indx));

end

function create_open_new_harness(model_name, system_name, harness_name)
%%
sltest.harness.create(system_name, 'Name', harness_name, ...
    'CreateWithoutCompile', true);

sltest.harness.open(system_name, harness_name);

%%
BW_access = get_param(model_name, 'EnableAccessToBaseWorkspace');
if strcmp(BW_access, 'off')
    set_param(harness_name, 'EnableAccessToBaseWorkspace', 'off');
end

%%
set_param(harness_name, 'ShowPortDataTypes', 'on');
set_param(harness_name, 'ShowLineDimensions', 'on');

%%
inport_list = find_system(harness_name, ...
    'SearchDepth',1, ...
    'regexp', 'on', 'blocktype', 'Inport');

if (numel(inport_list) < 1)
    return;
end

for i = 1:numel(inport_list)
    inport_name = get_param(inport_list{i}, 'Name');
    inport_pos  = get_param(inport_list{i}, 'Position');
    port_handle = get_param(inport_list{i}, 'PortHandles');
    line_handle = get_param(port_handle.Outport, 'Line');
    set_param(line_handle, 'Name', inport_name);

    sc_block_name = [harness_name, '/SC_', num2str(i)];
    add_block(['simulink/Signal Attributes/', ...
        'Signal', newline, 'Conversion'], ...
        sc_block_name);

    delete_block(inport_list{i});

    set_param(sc_block_name, 'Position', inport_pos);

    Simulink.sdi.markSignalForStreaming(line_handle, 'on');
end

end
