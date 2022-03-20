function open_config_tshintaiCustomTab()
%% 説明
% モデルのコンフィギュレーションパラメーターを開く。
% そのモデルのコンフィギュレーションパラメーターが参照の場合は、
% 参照先のコンフィギュレーションパラメーターを開く。
%%
model_name = bdroot;
activeConfigObj = getActiveConfigSet(model_name);

%%
if isa(activeConfigObj, 'Simulink.ConfigSet')
    activeConfigObj.openDialog;
elseif isa(activeConfigObj, 'Simulink.ConfigSetRef')
    referencedConfigObj = getRefConfigSet(activeConfigObj);
    referencedConfigObj.openDialog
else
    % Do Nothing.
end

end
