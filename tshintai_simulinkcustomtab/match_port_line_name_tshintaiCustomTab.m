function match_port_line_name_tshintaiCustomTab()
%% 説明
% 今の階層以下のモデル内を検索し、
% 信号線が接続されているポートに対して以下の操作を行います。
% 1. 入力ポートの名前を、接続されている信号線の名前に変更します。
%    出力ポートの名前を、接続されている信号線の名前もしくは伝搬信号の
%    名前に変更します。信号線に名前が無い場合はポート名を変更しません。
% 2. 信号線の入力側の上位階層に信号線が接続されていれば、
%    その信号線の名前を変更します。出力側の上位階層に信号線が接続されていれば、
%    その信号線の名前を空にして「伝搬信号の表示」にチェックを入れます。
% 3. サブシステムの入力ポートに名前付きの信号線が接続されている場合、
%    そのポートの下位層のポート名を変更し、
%    信号線の名前を空にして「伝搬信号の表示」にチェックを入れます。
% 4. サブシステムの入力ポートに名前付きの信号線が接続されている場合、
%    そのポートの下位層のポート名を変更し、元々の信号線の
%    名前を空にして「伝搬信号の表示」にチェックを入れます。
%%
model_name = gcs;
port_list = find_system(model_name, ...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'regexp', 'on', 'blocktype', 'port');

if numel(port_list) > 0.5
    %%
    % connected_flagは信号線が接続されていればtrue、そうでなければfalse
    connected_flag = true(numel(port_list), 1);
    % port_typeは1のときInport、2のときOutport
    port_type      = -ones(numel(port_list), 1, 'int32');
    for i = 1:numel(port_list)
        port_info = get_param(port_list{i}, 'PortConnectivity');

        if isempty(port_info.SrcBlock)
            if isempty(port_info.DstBlock)
                connected_flag(i) = false;
            else
                port_type(i) = int32(1);
            end
        elseif ((port_info.SrcBlock < 0) && ...
                (isempty(port_info.DstBlock)) )
            connected_flag(i) = false;
        else
            port_type(i) = int32(2);
        end

    end

    connected_port_path = port_list(connected_flag);
    port_type_list = port_type(port_type > int32(0));

    %%
    line_names = cell(numel(connected_port_path), 1);
    % line_names_typeが0のときline_nameは実際の信号線の名前、
    % 1のときline_nameは伝搬信号の名前である。
    line_names_type = zeros(numel(line_names), 1, 'int32');
    dst_port_handles = cell(numel(connected_port_path), 1);

    for i = 1:numel(connected_port_path)
        port_handle = get_param(connected_port_path{i}, 'PortHandles');
        if isempty(port_handle.Inport)
            line_handle = get_param(port_handle.Outport, 'Line');

            try
                line_names{i} = get_param(line_handle, 'Name');
                if isempty(line_names{i})
                    line_names{i} = get_param(port_handle.Outport, 'PropagatedSignals');
                    line_names_type(i) = int32(1);
                end

                dst_port_handles{i} = get_param(line_handle, 'DstPortHandle');
            catch
                line_names{i} = '';
            end
        else
            line_handle = get_param(port_handle.Inport, 'Line');

            try
                line_names{i} = get_param(line_handle, 'Name');
                if isempty(line_names{i})
                    src_port_handle = get_param(line_handle, 'SrcPortHandle');
                    line_names{i} = get_param(src_port_handle, 'PropagatedSignals');
                    line_names_type(i) = int32(1);
                end

                dst_port_handles{i} = get_param(line_handle, 'DstPortHandle');
            catch
                line_names{i} = '';
            end
        end
    end
else
    connected_port_path = [];
end

%%
for i = 1:numel(connected_port_path)
    if ~isempty(line_names{i})
        block_handle = get_param(connected_port_path{i}, 'Handle');

        %% 1.
        try
            set_line_name(block_handle, line_names{i});
        catch
            % 編集不可であった場合は何もしない
        end

        %% 2.
        port_parent = get_param(block_handle, 'Parent');
        if ~strcmp(port_parent, bdroot)
            try
                port_handle = get_param(port_parent, 'PortHandles');
            catch
                continue;
            end

            if (port_type_list(i) == int32(1))
                port_handle_io = port_handle.Inport;

                port_num = str2double(get_param(block_handle, 'Port'));
                line_handle = get_param(port_handle_io(port_num), 'Line');
                try
                    if (line_names_type(i) == int32(0))
                        set_line_name(line_handle, line_names{i});
                    end
                catch
                    % 編集不可であった場合は何もしない
                end
            else
                port_handle_io = port_handle.Outport;

                port_num = str2double(get_param(block_handle, 'Port'));
                line_handle = get_param(port_handle_io(port_num), 'Line');
                try
                    set_line_name(line_handle, '');
                    set_param(port_handle_io(port_num), 'ShowPropagatedSignals', 'on')
                catch
                    % 編集不可であった場合は何もしない
                end
            end

        end

    end
end

%% 3.
SubSys_list = find_system(model_name, ...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'regexp', 'on', ...
    'blocktype', 'SubSystem');
if numel(SubSys_list) > 0.5
    % 編集不可のサブシステムを避けるため、リンクされたライブラリブロックを除外する。
    None_linked_SubSys_list = SubSys_list( ...
        strcmp(get_param(SubSys_list, 'LinkStatus'), 'none'));
else
    None_linked_SubSys_list = [];
end

for i = 1:numel(None_linked_SubSys_list)
    Subsys_port_handle = get_param(None_linked_SubSys_list{i}, ...
        'PortHandles');

    if numel(Subsys_port_handle.Inport) > 0
        for j = 1:numel(Subsys_port_handle.Inport)

            line_handle = get_param(Subsys_port_handle.Inport(j), 'Line');
            if (line_handle < 0)
                continue;
            end

            src_port_handle = get_param(line_handle, 'SrcPortHandle');
            line_prop_name = get_param(src_port_handle, 'PropagatedSignals');
            line_name = get_param(line_handle, 'Name');

            if (~isempty(line_name)) || (~isempty(line_prop_name))

                dst_port_num = get_param(Subsys_port_handle.Inport(j), 'PortNumber');

                dst_lower_port_list = find_system(None_linked_SubSys_list{i}, ...
                    'MatchFilter', @Simulink.match.activeVariants, ...
                    'SearchDepth', 1, ...
                    'regexp', 'on', 'blocktype', 'Inport', ...
                    'Port', num2str(dst_port_num));

                if numel(dst_lower_port_list) ~= 1
                    % 見つかったブロックが1個ではなかった場合は探索失敗
                    continue;
                end

                try
                    lower_port_handle = get_param(dst_lower_port_list{1}, ...
                        'PortHandles');
                    line_handle = get_param(lower_port_handle.Outport, 'Line');
                    set_line_name(line_handle, '');
                    set_param(lower_port_handle.Outport, 'ShowPropagatedSignals', 'on')
                    set_param(dst_lower_port_list{1}, ...
                        'Name', avoid_unsuitable_char(line_name));
                catch
                    continue;
                end

            end
        end
    end
end

%% 4.
SubSys_list = find_system(model_name, ...
    'MatchFilter', @Simulink.match.activeVariants, ...
    'regexp', 'on', ...
    'blocktype', 'SubSystem');
if numel(SubSys_list) > 0.5
    % 編集不可のサブシステムを避けるため、リンクされたライブラリブロックを除外する。
    None_linked_SubSys_list = SubSys_list( ...
        strcmp(get_param(SubSys_list, 'LinkStatus'), 'none'));
else
    None_linked_SubSys_list = [];
end

for i = 1:numel(None_linked_SubSys_list)
    Subsys_port_handle = get_param(None_linked_SubSys_list{i}, ...
        'PortHandles');

    if numel(Subsys_port_handle.Outport) > 0
        for j = 1:numel(Subsys_port_handle.Outport)

            line_handle = get_param(Subsys_port_handle.Outport(j), 'Line');
            if (line_handle < 0)
                continue;
            end
            line_name = get_param(line_handle, 'Name');

            if ~isempty(line_name)

                src_port_num = get_param(Subsys_port_handle.Outport(j), 'PortNumber');

                src_lower_port_list = find_system(None_linked_SubSys_list{i}, ...
                    'MatchFilter', @Simulink.match.activeVariants, ...
                    'SearchDepth', 1, ...
                    'regexp', 'on', 'blocktype', 'Outport', ...
                    'Port', num2str(src_port_num));

                if numel(src_lower_port_list) ~= 1
                    % 見つかったブロックが1個ではなかった場合は探索失敗
                    continue;
                end

                try
                    lower_port_handle = get_param(src_lower_port_list{1}, ...
                        'PortHandles');
                    lower_line_handle = get_param(lower_port_handle.Inport, 'Line');
                    set_line_name(lower_line_handle, line_name);
                    set_line_name(line_handle, '');
                    set_param(Subsys_port_handle.Outport(j), 'ShowPropagatedSignals', 'on');
                    set_param(src_lower_port_list{1}, ...
                        'Name', avoid_unsuitable_char(line_name));
                catch
                    continue;
                end

            end
        end
    end
end

%% Stateflow Chartブロックのポート名に対しては個別に対処する。

ThisMachine = find(sfroot, '-isa', 'Stateflow.Machine', ...
                          'Name', bdroot);
chart_list = find(ThisMachine, '-isa', 'Stateflow.Chart', ...
    '-or', '-isa', 'Stateflow.TruthTableChart', ...
    '-or', '-isa', 'Stateflow.StateTransitionTableChart');

for i = 1:numel(chart_list)
    chart_input_list = chart_list(i).find('-isa', 'Stateflow.Data', ...
                             '-and', 'Scope', 'Input');

    for j = 1:numel(chart_input_list)
        try
            port_handles = get_param(chart_input_list(j).Path, 'PortHandles');
        catch
            port_handles = '';
        end

        if ~isempty(port_handles)
            line_handle = get_param(...
                port_handles.Inport(chart_input_list(j).Port), 'Line');
            line_name = get_param(line_handle, 'Name');
            src_port_handle = get_param(line_handle, 'SrcPortHandle');
            line_prop_name = get_param(src_port_handle, 'PropagatedSignals');

            if ~isempty(line_name)
                try
                    chart_input_list(j).Name = avoid_unsuitable_char(line_name);
                catch
                    % 編集不可であった場合は何もしない
                end
            elseif ~isempty(line_prop_name)
                try
                    chart_input_list(j).Name = avoid_unsuitable_char(line_prop_name);
                catch
                    % 編集不可であった場合は何もしない
                end
            end
        end

    end

    chart_output_list = chart_list(i).find('-isa', 'Stateflow.Data', ...
        '-and', 'Scope', 'Output');

    for j = 1:numel(chart_output_list)
        port_handles = get_param(chart_output_list(j).Path, 'PortHandles');
        line_handle = get_param(...
            port_handles.Outport(chart_output_list(j).Port), 'Line');
        line_name = get_param(line_handle, 'Name');

        if ~isempty(line_name)
            try
                chart_output_list(j).Name = avoid_unsuitable_char(line_name);
            catch
                % 編集不可であった場合は何もしない
            end
        end

    end

end

%% MATLAB Function ブロックのポート名に対しても個別に対処する。
bd_object = get_param(model_name, "Object");
MF_block_info = find(bd_object, "-isa", "Stateflow.EMChart");

for i = 1:numel(MF_block_info)
    inport_object = MF_block_info(i).Inputs;
    outport_object = MF_block_info(i).Outputs;
    MF_port_handles = get_param(MF_block_info(i).Path, 'PortHandles');

    for j = 1:numel(inport_object)
        line_handle = get_param(MF_port_handles.Inport(j), 'Line');
        if (line_handle > -0.5)
            line_name = get_source_line_name(line_handle);
            if ~isempty(line_name)
                inport_object(j).Name = line_name;
            end
        end
    end

    for j = 1:numel(outport_object)
        line_handle = get_param(MF_port_handles.Outport(j), 'Line');
        if (line_handle > -0.5)
            line_name = get_source_line_name(line_handle);
            if ~isempty(line_name)
                outport_object(j).Name = line_name;
            end
        end
    end
end

end


function set_line_name(line_handle, new_line_name)

old_line_name = get_param(line_handle, 'Name');

if ~strcmp(new_line_name, old_line_name)
    set_param(line_handle, 'Name', new_line_name);
end

end

function line_name = get_source_line_name(line_handle)

src_port_handle = get_param(line_handle, 'SrcPortHandle');
if (src_port_handle > -0.5)
    prop_name = get_param(src_port_handle, 'PropagatedSignals');
    if ~isempty(prop_name)
        line_name = prop_name;
    else
        line_name = get_param(line_handle, 'Name');
    end
else
    line_name = '';
end

end

function out_text = avoid_unsuitable_char(in_text)

out_text = strrep(in_text, '<', '');
out_text = strrep(out_text, '>', '');

end
