function create_bus_source_tshintaiCustomTab()
%% 説明
% ConstantブロックとBus Assignmentブロックを使って
% 非バーチャルバス信号を構築する。
% ベースワークスペース、モデルワークスペース、slddのいずれかに
% 格納されているバスオブジェクトをデータ型に指定できる。
%%
this_model_name = bdroot;
subsys_path = gcs;
relative_distance = 100;

sldd_name = get_param(this_model_name, 'DataDictionary');
if isempty(sldd_name)
    sldd_data_set = '';
else
    sldd_obj = Simulink.data.dictionary.open(sldd_name);
    sldd_data_set = getSection(sldd_obj, 'Design Data');
end

model_ws = get_param(this_model_name, 'ModelWorkspace');

%%
unselect_all_blocks_tshintaiCustomTab(subsys_path);

%%
base_ws_val_list = evalin('base', 'who');
model_ws_val_list = evalin(model_ws, 'who');
if isempty(sldd_data_set)
    sldd_val_list = '';
else
    sldd_val_list = evalin(sldd_data_set, 'who');
end

%%
number_of_variable = ...
    numel(base_ws_val_list) + numel(model_ws_val_list) + ...
    numel(sldd_val_list);
if (number_of_variable == 0)
    return;
end

% variable_infoは変数名、格納先、
% バスオブジェクトかどうかのフラグを格納する。
variable_info = cell(number_of_variable, 3);

%%
total_index = 1;

for i = 1:numel(base_ws_val_list)
    variable_info{total_index, 1} = base_ws_val_list{i};
    variable_info{total_index, 2} = 'base';
    variable_info{total_index, 3} = ...
        check_object_is_bus('base', base_ws_val_list{i});

    total_index = total_index + 1;
end

for i = 1:numel(model_ws_val_list)
    variable_info{total_index, 1} = model_ws_val_list{i};
    variable_info{total_index, 2} = 'model';
    variable_info{total_index, 3} = ...
        check_object_is_bus(model_ws, model_ws_val_list{i});

    total_index = total_index + 1;
end

for i = 1:numel(sldd_val_list)
    variable_info{total_index, 1} = sldd_val_list{i};
    variable_info{total_index, 2} = 'sldd';
    variable_info{total_index, 3} = ...
        check_object_is_bus(sldd_data_set, sldd_val_list{i});

    total_index = total_index + 1;
end

%%
bus_variable_info = variable_info(cell2mat(variable_info(:, 3)), :);
if isempty(bus_variable_info)
    return;
end

if (numel(bus_variable_info(:, 1)) == 1)
    bus_to_be_created = bus_variable_info;
else
    [RM_indx, ~] = listdlg('ListString', bus_variable_info(:, 1), ...
            'PromptString', {'作成するバスオブジェクトを選択してください：'}, ...
            'SelectionMode', 'single', ...
            'ListSize', [300, 400]);
    if isempty(RM_indx)
        return;
    end

    bus_to_be_created = bus_variable_info(RM_indx, :);
end

%%
Constant_name = 'Constant__CBS';
[Constant_path, Constant_name] = ...
    create_unique_block_name_tshintaiCustomTab( ...
    this_model_name, subsys_path, Constant_name);

BusAssginment_name = 'Bus_Assginment__CBS';
[BusAssginment_path, BusAssginment_name] = ...
    create_unique_block_name_tshintaiCustomTab( ...
    this_model_name, subsys_path, BusAssginment_name);

add_block('simulink/Sources/Constant', Constant_path);
set_param(Constant_path, 'ShowName', 'off');

add_block(['simulink/Signal', newline , 'Routing', ...
           '/Bus', newline, 'Assignment'], BusAssginment_path);
set_param(BusAssginment_path, 'ShowName', 'off');

set_param(Constant_path, 'Value', '0');
set_param(Constant_path, 'OutDataTypeStr', ...
    ['Bus: ', bus_to_be_created{1, 1}]);

%%
Constant_pos = get_param(Constant_path, 'Position');
BusAssginment_pos = get_param(BusAssginment_path, 'Position');
center_of_Constant = [(Constant_pos(1) + Constant_pos(3)) / 2;
                      (Constant_pos(2) + Constant_pos(4)) / 2;];

BusAssginment_pos_new = [...
        center_of_Constant(1) + relative_distance, ...
        center_of_Constant(2), ...
        center_of_Constant(1) + relative_distance + ...
                BusAssginment_pos(3) - BusAssginment_pos(1), ...
        center_of_Constant(2) + BusAssginment_pos(4) - BusAssginment_pos(2), ...
        ];
set_param(BusAssginment_path, 'Position', BusAssginment_pos_new);

%%
Constant_port_handles = get_param(Constant_path, 'PortHandles');
BusAssginment_port_handles = get_param( ...
    BusAssginment_path, 'PortHandles');

add_line(subsys_path, ...
    Constant_port_handles.Outport(1), BusAssginment_port_handles.Inport(1), ...
    'autorouting', 'smart');

%%
set_param(Constant_path, 'Selected', 'on');
set_param(BusAssginment_path, 'Selected', 'on');

end


function flag = check_object_is_bus(workspace, val_name)
COMMA = char(39);

try
    flag = evalin(workspace, ...
        ['isa(', val_name, ',' , COMMA, ...
        'Simulink.Bus', COMMA, ');']);
catch
    flag = false;
end

end
