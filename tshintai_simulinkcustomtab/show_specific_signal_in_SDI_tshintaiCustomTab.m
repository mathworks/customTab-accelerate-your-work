function show_specific_signal_in_SDI_tshintaiCustomTab()
%% 説明
% シミュレーションデータインスペクターに
% ログされた変数を選択して可視化します。
%%
PARAMETER = struct;
PARAMETER.MAX_ROW = 2;
PARAMETER.MAX_COLUMN = 4;
PARAMETER.MAX_PLOT_INDEX = PARAMETER.MAX_COLUMN * PARAMETER.MAX_ROW;

%%
Run_IDs = Simulink.sdi.getAllRunIDs;
if isempty(Run_IDs)
    return;
end

last_Run_ID = Simulink.sdi.getRun(Run_IDs(end));

%%
signal_IDs = last_Run_ID.getAllSignalIDs;
if isempty(signal_IDs)
    return;
end

%%
% signal_infoの1列目はID、2列目はHD、3列目は名前を格納する
signal_info = cell(numel(signal_IDs), 3);

for i = 1:numel(signal_IDs)
    signal_info{i, 1} = signal_IDs(i);
    signal_info{i, 2} = last_Run_ID.getSignal(signal_IDs(i));
    signal_info{i, 3} = signal_info{i, 2}.Name;

    size_vec = size(signal_info{i, 2}.Values.Data);

    if ((numel(size_vec) >= 3) || ...
        (size_vec(2) >= 2) )
        signal_info{i, 3} = ['/*Not Scalar*/ ', signal_info{i, 3}];
    end

    if strcmp(signal_info{i, 2}.Dimensions, 'variable')
        signal_info{i, 3} = ['/*Variable*/ ', signal_info{i, 3}];
    end
end

%%
[RM_indx, ~] = listdlg('ListString', signal_info(:, 3), ...
    'PromptString', {'可視化する信号を選択してください：'}, ...
    'ListSize', [400, 400]);
if isempty(RM_indx)
    return;
end

selected_signal_info = signal_info(RM_indx, :);
selected_signal_num = numel(RM_indx);

%%
Simulink.sdi.clearAllSubPlots;
Simulink.sdi.clearPreferences;
Simulink.sdi.view;

%%
if selected_signal_num == 1
    Simulink.sdi.setSubPlotLayout(1, 1);
else
    column_num = floor((selected_signal_num - 1) / PARAMETER.MAX_ROW) + 1;
    if (column_num > PARAMETER.MAX_COLUMN)
        Simulink.sdi.setSubPlotLayout(PARAMETER.MAX_COLUMN, PARAMETER.MAX_ROW);
    else
        Simulink.sdi.setSubPlotLayout(column_num, PARAMETER.MAX_ROW);
    end
end

%%
plot_position_index = [1, 1];
for i = 1:selected_signal_num
        selected_signal_info{i, 2}.plotOnSubPlot( ...
        plot_position_index(1), plot_position_index(2), true);

    plot_position_index = update_plot_position( ...
        plot_position_index, PARAMETER);
end

end

function index_out = update_plot_position(index_in, PARAMETER)
%%
index_out = [1, 1];

%%
unique_index = PARAMETER.MAX_ROW * (index_in(1) - 1) + index_in(2);

unique_index = unique_index + 1;
if (unique_index > PARAMETER.MAX_PLOT_INDEX)
    unique_index = 1;
end

%%
index_out(1) = floor((unique_index - 1) / PARAMETER.MAX_ROW) + 1;

mod_index = mod(unique_index, PARAMETER.MAX_ROW);
if (mod_index == 0)
    index_out(2) = PARAMETER.MAX_ROW;
else
    index_out(2) = mod_index;
end

end
