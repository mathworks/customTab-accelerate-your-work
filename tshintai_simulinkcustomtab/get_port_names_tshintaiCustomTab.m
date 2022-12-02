function port_names = get_port_names_tshintaiCustomTab(...
    disconnected_list, ...
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
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'SearchDepth', 1, ...
        'regexp', 'on', 'blocktype', port_type, ...
        'Port', num2str(disconnected_list{index, 2}));
else
    lower_port_list = find_system(disconnected_list{index, 1}, ...
        'MatchFilter', @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
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
