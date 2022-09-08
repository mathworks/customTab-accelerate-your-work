function connect_same_port_names_tshintaiCustomTab()
%%
% 現在の階層の中から未接続のInport, Outport, 
% Subsystem, Stateflowブロック、MATLAB Function ブロック
% のポートを探し、同じ名前のポート名同士を接続する。
% また、Inportブロックについて、同じポート名が無いが、
% 信号名で同じものがあれば、その信号に対して接続する。
%%
this_layer = gcs;
block_list = find_system(this_layer, ...
            'LookUnderMasks', 'all', ...
            'SearchDepth', 1);
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
inport_names = get_port_names_tshintaiCustomTab(...
                    disconnected_inport_list, ...
                    chart_inport_names, MF_inport_names);
outport_names = get_port_names_tshintaiCustomTab(...
                    all_outport_list, ...
                    chart_outport_names, MF_outport_names);

%%
line_connected_flag = false(size(disconnected_inport_list, 1), 1);
for i = 1:numel(inport_names)
    for j = 1:numel(outport_names)
        if (strcmp(inport_names{i}, outport_names{j}) && ...
            ~strcmp(disconnected_inport_list{i, 1}, ...
                    all_outport_list{j, 1}) )
            try
                delete_unconnected_outport_line(all_outport_list{j, 3});
                delete_unconnected_inport_line(disconnected_inport_list{i, 3});
                add_line(this_layer, ...
                    all_outport_list{j, 3}, ...
                    disconnected_inport_list{i, 3}, ...
                    'autorouting','smart');
                line_connected_flag(i) = true;
            catch
                % 接続できない時は諦める。
            end
        end
    end
end

%%
this_layer_line_handles = find_system(this_layer, ...
    'LookUnderMasks', 'all', ...
    'SearchDepth', 1, ...
    'FindAll', 'on', ...
    'type', 'line');

line_names = cell(numel(this_layer_line_handles), 1);
line_prop_names = cell(numel(this_layer_line_handles), 1);
line_src_handles = cell(numel(this_layer_line_handles), 1);
for i = 1:numel(line_names)
    line_src_handles{i} = get_param(this_layer_line_handles(i), 'SrcPortHandle');
    if (line_src_handles{i} > 0)
        line_prop_names{i} = get_param(line_src_handles{i}, ...
            'PropagatedSignals');
        line_names{i} = get_param(this_layer_line_handles(i), 'Name');
    else
        line_src_handles{i} = -1;
        line_names{i} = '';
    end
    
end

%%
for i = 1:size(disconnected_inport_list, 1)
    if ~line_connected_flag(i)
        for j = 1:numel(line_names)
            if (strcmp(inport_names{i}, line_names{j}) || ...
                strcmp(inport_names{i}, line_prop_names{j}))
                try
                    add_line(this_layer, ...
                        line_src_handles{j}, ...
                        disconnected_inport_list{i, 3}, ...
                        'autorouting','smart');
                catch

                end
            end
        end
    end
end

end


function delete_unconnected_outport_line(outport_handle)
    line_handle = get_param(outport_handle, 'Line');
    if (line_handle > -0.5)
        dst_block_name = get_param(line_handle, 'DstBlock');
        if isempty(dst_block_name)
            delete_line(line_handle);
        end
    end
end

function delete_unconnected_inport_line(inport_handle)
    line_handle = get_param(inport_handle, 'Line');
    if (line_handle > -0.5)
        delete_line(line_handle);
    end
end

function MF_block_info = get_MF_block_info(this_system)

bd = get_param(this_system, "Object");
MF_block_info = find(bd,"-isa","Stateflow.EMChart");

end
