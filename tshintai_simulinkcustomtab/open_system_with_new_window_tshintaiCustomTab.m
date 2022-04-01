function open_system_with_new_window_tshintaiCustomTab()
%% 説明
% 選択したブロックを新しいウィンドウで開きます。
% 選択していない場合は、現在の階層を対象に開きます。
% 参照モデル、参照サブシステムなどを対象とした機能です。
% 普通のブロックを選択して実行した場合、ブロックパラメータが開きます。
%%
model_root = bdroot;
selected_block_list = find_system(gcs, ...
    'SearchDepth',1, ...
    'Selected','on');

if ( (numel(selected_block_list) > 1) && ...
        strcmp(selected_block_list{1}, gcs) )
    selected_block_list = selected_block_list(2:end);
elseif numel(selected_block_list) < 1
    selected_block_list = cell(1, 1);
    selected_block_list{1} = gcs;
end

if isempty(selected_block_list)
    return;
end

%%
for i = 1:numel(selected_block_list)

    if strcmp(selected_block_list{i}, model_root)

        open_system_near_bdroot(selected_block_list{i}, model_root);

    else

        if strcmp(get_param(selected_block_list{i}, 'Variant'), 'on')
            sub_block_list = find_system(selected_block_list{i}, ...
                'SearchDepth', 1, ...
                'regexp', 'on', 'BlockType', 'SubSystem|ModelReference');
            if numel(sub_block_list) < 1.5
                return;
            end

            block_path_to_open = sub_block_list{2};
        else
            block_path_to_open = selected_block_list{i};
        end

        if strcmp(get_param(block_path_to_open, 'BlockType'), ...
                'ModelReference')
            ref_model_name = get_param(block_path_to_open, 'ModelName');
            open_system_near_bdroot(ref_model_name, model_root);

        else

            try
                subsystem_ref_name = get_param(block_path_to_open, ...
                    'ReferencedSubsystem');
            catch
                subsystem_ref_name = '';
            end

            if ~isempty(subsystem_ref_name)
                open_system_near_bdroot(subsystem_ref_name, model_root);
            else
                open_system_near_bdroot(block_path_to_open, model_root);
            end

        end
    end
end

end

function open_system_near_bdroot(model_name, model_root)
%%
open_system(model_name, 'window');

if strcmp(model_root, model_name)
    return;
end

%%
location_offset = 30;
root_location = get_param(model_root, 'Location');
model_location = get_param(model_name, 'Location');

if ~isempty(root_location(root_location <= 0))
    % 位置情報にマイナス値がある場合、
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
