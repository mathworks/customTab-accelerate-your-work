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
% disconnected_inport_list, disconnected_outport_listは、
% 信号線が接続されていないポートの
% 親ブロックの名前、ポート番号、ポートのハンドル、ポート種別、
% ポート位置を記録する。
[disconnected_inport_list, disconnected_outport_list] = ...
    get_disconnected_lists_tshintaiCustomTab(block_list);

if ( isempty(disconnected_inport_list{1, 1}) || ...
        isempty(disconnected_outport_list{1, 1}) )
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
chart_outport_names = cell(size(disconnected_outport_list, 1), 1);

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
    for j = 1:size(disconnected_outport_list, 1)
        if strcmp(path_text, disconnected_outport_list{j, 1})
            chart_outport_names{j, 1} = ...
                chart_output_list(disconnected_outport_list{j, 2}).Name;
        end
    end
end

%%
inport_names = get_port_names(disconnected_inport_list, chart_inport_names);
outport_names = get_port_names(disconnected_outport_list, chart_outport_names);

%%
for i = 1:numel(inport_names)
    for j = 1:numel(outport_names)
        if (strcmp(inport_names{i}, outport_names{j}) && ...
            ~strcmp(disconnected_inport_list{i, 1}, ...
                    disconnected_outport_list{j, 1}) )
            try
                add_line(this_layer, ...
                    disconnected_outport_list{j, 3}, ...
                    disconnected_inport_list{i, 3}, ...
                    'autorouting','smart');
            catch
                % 接続できない時は諦める。
            end
        end
    end
end

end


function port_names = get_port_names(disconnected_list, chart_port_names)
port_names  = cell(size(disconnected_list, 1), 1);

for i = 1:numel(port_names)
    if ~isempty(chart_port_names{i})
        port_names{i, 1} = chart_port_names{i};
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
            text = strsplit(disconnected_list{i, 1}, '/');
            port_names{i, 1} = text{end};
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
