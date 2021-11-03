function close_project_tshintaiCustomTab()
%% 説明
% プロジェクトを開いている場合、プロジェクトを閉じます。
% 開いていない場合、何もしません。
%%
try
    projObj = currentProject;
    projObj.close;
catch
    
end

end