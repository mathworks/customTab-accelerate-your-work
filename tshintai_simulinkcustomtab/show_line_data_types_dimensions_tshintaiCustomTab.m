function show_line_data_types_dimensions_tshintaiCustomTab()
%% 説明
% モデルの「信号の次元」と「端子のデータ型」を表示させます。
%%
set_param(bdroot, 'ShowPortDataTypes', 'on');
set_param(bdroot, 'ShowLineDimensions', 'on');

set_param(bdroot,'SimulationCommand','Update');

end