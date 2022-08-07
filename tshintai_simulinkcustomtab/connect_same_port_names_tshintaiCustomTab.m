function connect_same_port_names_tshintaiCustomTab()
%%
% 現在の階層の中から未接続のInport, Outport, 
% Subsystem, Stateflowブロックのポートを探し、
% 同じ名前のポート名同士を接続する。
%%
this_layer = gcs;
block_list = find_system(this_layer, ...
            'SearchDepth',1);
block_list = block_list(2:end);

%%
% disconnected_inport_listは
% 信号線が接続されていない入力ポートの、all_outport_listは
% 全ての出力ポートの
% 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別、
% ポート位置を記録する。
[disconnected_inport_list, ~] = ...
    get_disconnected_lists_tshintaiCustomTab(block_list);
all_outport_list = ...
    get_all_outport_lists_tshintaiCustomTab(block_list);

if ( isempty(disconnected_inport_list{1, 1}) || ...
        isempty(all_outport_list{1, 1}) )
    return;
end

%%
% ここでStateflowブロックの有無を確認し、
% Stateflowブロックかどうかのフラグを記録する。
ThisMachine = find(sfroot, '-isa', 'Stateflow.Machine', ...
                          'Name', bdroot);
chart_list = find(ThisMachine, '-isa', 'Stateflow.Chart', ...
    '-or', '-isa', 'Stateflow.TruthTableChart', ...
    '-or', '-isa', 'Stateflow.StateTransitionTableChart');

chart_inport_names  = cell(size(disconnected_inport_list, 1), 1);
chart_outport_names = cell(size(all_outport_list, 1), 1);

for i = 1:numel(chart_list)
    path_text = chart_list(i).Path;

    chart_input_list = chart_list(i).find('-isa', 'Stateflow.Data', ...
        '-and', 'Scope', 'Input');
    for j = 1:size(disconnected_inport_list, 1)
        if strcmp(path_text, disconnected_inport_list{j, 1})
            chart_inport_names{j, 1} = ...
                chart_input_list(disconnected_inport_list{j, 2}).Name;
        end
    end

    chart_output_list = chart_list(i).find('-isa', 'Stateflow.Data', ...
        '-and', 'Scope', 'Output');
    for j = 1:size(all_outport_list, 1)
        if strcmp(path_text, all_outport_list{j, 1})
            chart_outport_names{j, 1} = ...
                chart_output_list(all_outport_list{j, 2}).Name;
        end
    end
end

%%
% ここで、MATLAB Functionブロックの有無を確認し、情報を記録する。
% 1番目にブロックの名前、2番目にInput, Outputハンドルを保存する。
MF_block_info = get_MF_block_info(this_layer);

MF_inport_names  = cell(size(disconnected_inport_list, 1), 2);
MF_outport_names = cell(size(all_outport_list, 1), 2);

for i = 1:numel(MF_block_info)
    for j = 1:size(disconnected_inport_list, 1)
        split_text = strsplit(disconnected_inport_list{j, 1}, '/');
        block_name = split_text{end};

        if strcmp(MF_block_info(i).Name, block_name)
            MF_inport_names{j, 1} = disconnected_inport_list{j, 1};
            MF_inport_names{j, 2} = ...
                MF_block_info(i).Inputs(disconnected_inport_list{j, 2});
        end
    end

    for j = 1:size(all_outport_list, 1)
        split_text = strsplit(all_outport_list{j, 1}, '/');
        block_name = split_text{end};

        if strcmp(MF_block_info(i).Name, block_name)
            MF_outport_names{j, 1} = all_outport_list{j, 1};
            MF_outport_names{j, 2} = ...
                MF_block_info(i).Outputs(all_outport_list{j, 2});
        end
    end
end

%%
inport_names = get_port_names(disconnected_inport_list, ...
                    chart_inport_names, MF_inport_names);
outport_names = get_port_names(all_outport_list, ...
                    chart_outport_names, MF_outport_names);

%%
for i = 1:numel(inport_names)
    for j = 1:numel(outport_names)
        if (strcmp(inport_names{i}, outport_names{j}) && ...
            ~strcmp(disconnected_inport_list{i, 1}, ...
                    all_outport_list{j, 1}) )
            try
                add_line(this_layer, ...
                    all_outport_list{j, 3}, ...
                    disconnected_inport_list{i, 3}, ...
                    'autorouting','smart');
            catch
                % 接続できない時は諦める。
            end
        end
    end
end

end


function port_names = get_port_names(disconnected_list, ...
    chart_port_names, MF_port_names)
port_names  = cell(size(disconnected_list, 1), 1);

for i = 1:numel(port_names)
    if ~isempty(chart_port_names{i})
        port_names{i, 1} = chart_port_names{i};
    elseif ~isempty(MF_port_names{i, 1})
        port_names{i, 1} = MF_port_names{i, 2}.Name;
    else
        block_type = get_param(disconnected_list{i, 1}, 'BlockType');
        if ( strcmp(block_type, 'SubSystem') || ...
                strcmp(block_type, 'ModelReference')  )

            if strcmp(disconnected_list{i, 4}, 'Inport')
                port_names{i, 1} = ...
                    get_port_name_from_subsystem(disconnected_list, i, 'Inport', ...
                    block_type);
            elseif strcmp(disconnected_list{i, 4}, 'Outport')
                port_names{i, 1} = ...
                    get_port_name_from_subsystem(disconnected_list, i, 'Outport', ...
                    block_type);
            else
                port_names{i, 1} = '';
            end
        else
            try
                element_name = get_param(disconnected_list{i, 1}, 'Element');
            catch
                element_name = '';
            end
            if isempty(element_name)
                text = strsplit(disconnected_list{i, 1}, '/');
                port_names{i, 1} = text{end};
            else
                port_names{i, 1} = element_name;
            end
        end
    end
end

end

function port_name = get_port_name_from_subsystem( ...
    disconnected_list, index, port_type, block_type)
port_name = '';

if strcmp(block_type, 'ModelReference')
    ref_model_name = get_param(disconnected_list{index, 1}, 'ModelName');
    lower_port_list = find_system(ref_model_name, ...
        'SearchDepth', 1, ...
        'regexp', 'on', 'blocktype', port_type, ...
        'Port', num2str(disconnected_list{index, 2}));
else
    lower_port_list = find_system(disconnected_list{index, 1}, ...
        'SearchDepth', 1, ...
        'regexp', 'on', 'blocktype', port_type, ...
        'Port', num2str(disconnected_list{index, 2}));
end

if isempty(lower_port_list)
    return;
end

if numel(lower_port_list) > 1.5
    try
        port_name = get_param(lower_port_list{1}, 'PortName');
    catch
        port_name = '';
    end
else
    text = strsplit(string(lower_port_list), '/');
    port_name = text{end};
end

end

function MF_block_info = get_MF_block_info(this_system)

bd = get_param(this_system, "Object");
MF_block_info = find(bd,"-isa","Stateflow.EMChart");

end
