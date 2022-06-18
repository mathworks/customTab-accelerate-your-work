function create_open_test_harness_tshintaiCustomTab()
%% 説明
% 選択したブロック、サブシステム、参照モデルなどに対して
% テストハーネスを作成して開きます。
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
        create_open_new_harness(model_name, system_name, harness_name, 0);

    elseif numel(harness_list) == 1

        sltest.harness.open(system_name, harness_list(1).name);

    else

        choose_from_multiple_harnesses(harness_list, system_name);

    end

elseif numel(selected_block_list) > 1
    return;
else

    subsystem_type = check_block_is_subsystem_tshintaiCustomTab( ...
        selected_block_list{1});
    if (subsystem_type(1) == 1)
        % 通常のサブシステムの場合
        harness_list = sltest.harness.find(selected_block_list{1});

        if isempty(harness_list)

            block_name = get_param(selected_block_list{1}, 'Name');
            harness_name = replace_bad_names([block_name, '_harness']);
            create_open_new_harness(model_name, selected_block_list{1}, ...
                harness_name{1}, subsystem_type);

        elseif numel(harness_list) == 1

            sltest.harness.open(selected_block_list{1}, harness_list(1).name);

        else

            choose_from_multiple_harnesses(harness_list, selected_block_list{1});

        end
    elseif (subsystem_type(1) == 2)
        % 参照サブシステムの場合
        subsystem_ref_name = get_param(selected_block_list{1}, ...
            'ReferencedSubsystem');
        load_system(subsystem_ref_name);
        harness_list = sltest.harness.find(subsystem_ref_name);

        if isempty(harness_list)

            harness_name = replace_bad_names([subsystem_ref_name, '_harness']);
            create_open_new_harness(model_name, subsystem_ref_name, ...
                harness_name{1}, subsystem_type);

        else

            if (numel(harness_list) == 1)
                sltest.harness.open( ...
                    subsystem_ref_name, harness_list(1).name);
            else
                choose_from_multiple_harnesses( ...
                    harness_list, subsystem_ref_name);
            end

        end

    elseif (subsystem_type(1) == 3)
        % 参照モデルの場合
        ref_model_name = get_param(selected_block_list{1}, 'ModelName');
        load_system(ref_model_name);
        harness_list = sltest.harness.find(ref_model_name);

        if isempty(harness_list)

            harness_name = replace_bad_names([ref_model_name, '_harness']);
            create_open_new_harness(ref_model_name, ref_model_name, ...
                harness_name{1}, subsystem_type);

        else

            if (numel(harness_list) == 1)
                sltest.harness.open( ...
                    ref_model_name, harness_list(1).name);
            else
                choose_from_multiple_harnesses( ...
                    harness_list, ref_model_name);
            end

        end

    else
        % 通常のブロックの場合、
        % 参照サブシステムを作成してからテストハーネスを作成する
        save_system(model_name, [], 'OverwriteIfChangedOnDisk', true);

        block_handle = get_param(selected_block_list{1}, 'Handle');
        parent_name  = get_param(selected_block_list{1}, 'Parent');
        block_name   = replace_bad_names( ...
            get_param(selected_block_list{1}, 'Name'));
        subsystem_name = [block_name{1}, '__s'];
        subsystem_path = [parent_name, '/', subsystem_name];
        block_pos = get_param(selected_block_list{1}, 'Position');

        % 削除する時のため、ブロック名は修正する
        set_param(selected_block_list{1}, 'Name', block_name{1});

        Simulink.BlockDiagram.createSubsystem(block_handle, ...
            'Name', subsystem_name);
        set_param(subsystem_path, 'Position', block_pos);

        if exist([subsystem_name, '.slx'], 'file')
            delete([subsystem_name, '.slx']);
        end
        Simulink.SubsystemReference.convertSubsystemToSubsystemReference( ...
            subsystem_path, subsystem_name);

        harness_name = replace_bad_names([subsystem_name, '_harness']);
        create_open_new_harness(model_name, subsystem_name, ...
            harness_name{1}, 2);
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

function create_open_new_harness(model_name, system_path, harness_name, ...
    subsystem_type)
%%
sltest.harness.create(system_path, 'Name', harness_name, ...
    'CreateWithoutCompile', true);
sltest.harness.open(system_path, harness_name);

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

%%
outport_list = find_system(harness_name, ...
    'SearchDepth',1, ...
    'regexp', 'on', 'blocktype', 'Outport');

for i = 1:numel(outport_list)
    outport_name = get_param(outport_list{i}, 'Name');
    outport_pos  = get_param(outport_list{i}, 'Position');
    port_handle  = get_param(outport_list{i}, 'PortHandles');
    line_handle  = get_param(port_handle.Inport, 'Line');
    set_param(line_handle, 'Name', outport_name);

    disp_block_name = [harness_name, '/Display_', num2str(i)];
    add_block('simulink/Sinks/Display', ...
        disp_block_name);
    
    disp_block_pos = get_param(disp_block_name, 'Position');
    pos_distance_Y = ...
        (outport_pos(2) + outport_pos(4) - ...
        disp_block_pos(2) - disp_block_pos(4)) / 2;
    desired_pos = [...
        outport_pos(1), ...
        disp_block_pos(2) + pos_distance_Y, ...
        disp_block_pos(3) + outport_pos(1) - disp_block_pos(1), ...
        disp_block_pos(4) + pos_distance_Y ];

    delete_block(outport_list{i});

    set_param(disp_block_name, 'Position', desired_pos);

    Simulink.sdi.markSignalForStreaming(line_handle, 'on');

    set_param(disp_block_name, 'Commented', 'on');
end

%%
if (subsystem_type == 2)
    linked_sldd_name = get_param(model_name, 'DataDictionary');
    if ~isempty(linked_sldd_name)
        set_param(harness_name, 'DataDictionary', linked_sldd_name);
    end
    
    activeConfigObj = getActiveConfigSet(model_name);
    original_config_name = get_param(activeConfigObj, 'Name');

    harness_config_name = [system_path, '__harness_config'];
    set_param(activeConfigObj, 'Name', harness_config_name);
    attachConfigSetCopy(harness_name, activeConfigObj);
    setActiveConfigSet(harness_name, harness_config_name);

    set_param(activeConfigObj, 'Name', original_config_name);
end

end

function rep_block_list = replace_bad_names(block_list)
%%
block_list = make_cell_list_tshintaiCustomTab(block_list);

%%
rep_block_list = block_list;

for i = 1:numel(block_list)
    name = strrep(block_list{i}, newline, '_');
    name = strrep(name, ' ', '_');
    name = strrep(name, '-', '_');
    rep_block_list{i} = name;
end

end
