function save_dirty_models_tshintaiCustomTab()
%% 説明
% このボタンをクリックしたモデルの参照先モデルと自身を確認し、
% 変更されているものだけを保存します。
% これにより、確実に変更されたモデルだけをGitで判別できます。
%% Init
top_model_name = bdroot;
save_message_handle = warndlg('Now Saving ...');

%%
loaded_models = Simulink.allBlockDiagrams('model');
loaded_models_name = get_param(loaded_models,'Name');
loaded_models_name = arrange_list(loaded_models_name);

other_models_name = loaded_models_name(~strcmp(loaded_models_name, ...
    top_model_name));

[ref_model_name, ~] = find_mdlrefs(top_model_name, ...
            'MatchFilter', @Simulink.match.activeVariants);
ref_model_name = arrange_list(ref_model_name);

ref_model_list = ref_model_name(~strcmp(ref_model_name, top_model_name));

ref_model_loaded_flag = false(numel(ref_model_list), 1);
for i = 1:numel(ref_model_list)
    for j = 1:numel(other_models_name)
        if strcmp(other_models_name{j}, ref_model_list{i})
            ref_model_loaded_flag(i) = true;
            break;
        end
    end
end

loaded_ref_model_list = ref_model_list(ref_model_loaded_flag);

%% 
% ロードされていて、かつ最上位モデルから参照されている
% モデルに対してサブシステム参照を検索し、
% 変更されているものがあればそれを保存する。
for i = 1:numel(loaded_ref_model_list)
    find_and_save_dirty_subsystem(loaded_ref_model_list{i});
end

% 自身を保存する。
repeat_save_models(loaded_ref_model_list);


%%
% 最後に最上位階層モデルに対して
% サブシステム参照の保存と自身の保存を行う。
find_and_save_dirty_subsystem(top_model_name);

if strcmp(get_param(top_model_name, 'Dirty'), 'on')
    try
        save_system(top_model_name);
    catch
        % 保存できなかった時は諦める。
    end
end

%%
if isvalid(save_message_handle)
    delete(save_message_handle)
end

end


function arranged_list = arrange_list(list)

if isempty(list)
    arranged_list = cell(0, 0);
elseif ischar(list)
    arranged_list = cell(1, 0);
    arranged_list{1} = list;
else
    arranged_list = list;
end

end

function find_and_save_dirty_subsystem(model_name)

sub_sys_list = ...
    Simulink.SubsystemReference.getAllReferencedSubsystemBlockDiagrams( ...
    model_name);
sub_sys_list = arrange_list(sub_sys_list);

repeat_save_models(sub_sys_list);

end

function repeat_save_models(model_list)

if isempty(model_list)
    return;
else
    dirty_flag = false(numel(model_list), 1);

    % ここで、参照先モデルがDirtyである場合、
    % save_systemで保存できないため、ループを繰り返し実行し、
    % Dirtyを無くしていく。
    % ただし、参照モデルと参照サブシステムが入り乱れている場合は
    % Dirtyを全て解消することはできない。
    % よって、繰り返しの最大値を規定して、それ以上は行わないこととする。
    % （全てのモデルを保存しきることは諦める）
    loop_max = numel(model_list);

    for base_loop = 1:loop_max
        for i = 1:numel(model_list)
            if strcmp(get_param(model_list{i}, 'Dirty'), 'on')
                try
                    save_system(model_list{i});
                catch
                    dirty_flag(i) = true;
                end
            end
        end

        if sum(uint32(dirty_flag)) == uint32(0)
            break;
        end
    end

end

end
