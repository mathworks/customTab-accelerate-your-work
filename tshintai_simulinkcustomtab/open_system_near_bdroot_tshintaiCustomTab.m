function open_system_near_bdroot_tshintaiCustomTab(...
    model_name, model_root)
%%
open_system(model_name, 'window');

if strcmp(model_root, model_name)
    return;
end

%%
open_system(model_name);

%%
location_offset = 30;
root_location = get_param(model_root, 'Location');
try
    model_location = get_param(model_name, 'Location');
catch
    model_location = '';
end

if (~isempty(root_location(root_location <= 0)) || isempty(model_location))
    % 位置情報にマイナス値がある場合、またはLocationが取れない場合、
    % ウィンドウ位置を正しく動かせないのでここで中断する。
    return;
end

%%
starting_point = root_location(1:2) + location_offset;

next_position = [...
    starting_point(1), ...
    starting_point(2), ...
    starting_point(1) + (model_location(3) - model_location(1)), ...
    starting_point(2) + (model_location(4) - model_location(2)) ];

%%
set_param(model_name, 'Location', next_position);

%%
set_param(model_name, 'ZoomFactor', 'FitSystem');

%% 
% ここからの処理はリスクがあるため、デフォルトでは無効化している。
% 問題無いようであれば、以下のreturnを削除して有効化すること。
return;
%%
Tab_offset = [480, 40];
graphic_obj = groot;
origin_position = graphic_obj.PointerLocation;

%%
pointer_segment = 1;
Monitor_positions = graphic_obj.MonitorPositions;
for i = 1:size(Monitor_positions, 1)
    if (starting_point(1) >= Monitor_positions(i, 1) && ...
        starting_point(1) <= (Monitor_positions(i, 1) - 1 + Monitor_positions(i, 3)) && ...
        starting_point(2) >= Monitor_positions(i, 2) && ...
        starting_point(2) <= (Monitor_positions(i, 2) - 1 + Monitor_positions(i, 4)) )
            pointer_segment = i;
    end
end

vertical_offset = Monitor_positions(pointer_segment, 2) ...
    - 1 + Monitor_positions(pointer_segment, 4);

%%
pointer_position = [...
    next_position(1) + Tab_offset(1), ...
    vertical_offset - next_position(2) - Tab_offset(2), ...
    ];

graphic_obj.PointerLocation = pointer_position;

%% Javaの自動クリック機能を使用
import java.awt.Robot;
import java.awt.event.*;
mouse = Robot;
mouse.mousePress(InputEvent.BUTTON1_MASK);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);

graphic_obj.PointerLocation = origin_position;

end
