%% カスタムタブを有効化
slReloadToolstripConfig;
CT_obj = slLoadedToolstripComponents;

tab_is_not_loaded = true;
for i = 1:numel(CT_obj)
    if strcmp(CT_obj(i).name, 'tshintai_CustomTab')
        tab_is_not_loaded = false;
        break;
    end
end

%%
if tab_is_not_loaded
    movefile('resources', 'resources_');
    slCreateToolstripComponent("tshintai_CustomTab");

    rmdir('resources', 's');
    movefile('resources_', 'resources');

    slReloadToolstripConfig;
end
