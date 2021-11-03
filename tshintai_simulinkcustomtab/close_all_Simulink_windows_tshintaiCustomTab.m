function close_all_Simulink_windows_tshintaiCustomTab()
%% 説明
% 開いているSimulinkモデルを全て閉じます。
% モデルは保存して閉じます。
%%
while(1)
    if isempty(bdroot)
        break;
    end
    
    d_status = get_param(bdroot, 'Dirty');
    if strcmp(d_status, 'on')
        save_system(bdroot, [], 'SaveDirtyReferencedModels', true);
    end
    
    close_system(bdroot);
end


end