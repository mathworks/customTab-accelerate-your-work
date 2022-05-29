function open_config_tshintaiCustomTab()
%% 説明
% モデルの今開いている階層のコンフィギュレーションパラメーターを開く。
% 例えば、上位階層のモデルから参照モデルを開いている時、
% その参照先のモデルのコンフィギュレーションパラメーターを開く。
% そのモデルがコンフィギュレーション参照を行っている場合は、
% 参照先のコンフィギュレーションパラメーターを開く。
%%
top_model_name = bdroot;
this_model_name = gcs;

if strcmp(top_model_name, this_model_name)
    activeConfigObj = getActiveConfigSet(top_model_name);
else
    try
        subsystem_ref_name = get_param( ...
            this_model_name, 'ReferencedSubsystem');
    catch
        subsystem_ref_name = '';
    end

    if (exist(this_model_name, 'file') == 4)
        % 参照モデルである
        activeConfigObj = getActiveConfigSet(this_model_name);
    elseif ~isempty(subsystem_ref_name)
        % 参照サブシステムである
        activeConfigObj = getActiveConfigSet(subsystem_ref_name);
    else
        activeConfigObj = getActiveConfigSet(top_model_name);
    end
end


%%
open_config(activeConfigObj)

end


function open_config(activeConfigObj)

if isa(activeConfigObj, 'Simulink.ConfigSet')
    activeConfigObj.openDialog;
elseif isa(activeConfigObj, 'Simulink.ConfigSetRef')
    referencedConfigObj = getRefConfigSet(activeConfigObj);
    referencedConfigObj.openDialog
else
    % Do Nothing.
end

end
