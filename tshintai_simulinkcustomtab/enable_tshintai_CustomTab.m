%% カスタムタブを有効化
movefile('resources', 'resources_');
slCreateToolstripComponent("tshintai_CustomTab");

%%
rmdir('resources', 's');
movefile('resources_', 'resources');
%%
slReloadToolstripConfig;
