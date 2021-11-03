%% カスタムタブを無効化
copyfile('resources', 'resources_');
slDestroyToolstripComponent("tshintai_CustomTab");
movefile('resources_', 'resources');
