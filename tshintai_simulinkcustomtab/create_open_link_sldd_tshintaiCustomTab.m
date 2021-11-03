function create_open_link_sldd_tshintaiCustomTab()
%% 説明
% slddファイルが関連付けられていないモデルの場合、ファイルを新規作成し、
% モデルに関連付けます。その後そのファイルを開きます。
% すでに関連付けられている場合、そのファイルを開きます。
%%
model_name = bdroot;
linked_sldd_name = get_param(model_name, 'DataDictionary');

if isempty(linked_sldd_name)
    % sldd名を取得する
    prompt = {'slddファイル名を入力してください：'};
    dlgtitle = 'Input';
    dims = [1 35];
    definput = "system_data";
    answer = inputdlg(prompt,dlgtitle,dims,definput);

    if isempty(answer) || (strlength(answer) == 0)
        return;
    else
        sldd_full_name = [answer{1}, '.sldd'];
    end
    
    if exist(sldd_full_name, "file")
        % ファイルは作成しない
    else
        Simulink.data.dictionary.create(sldd_full_name);
    end
    set_param(model_name, 'DataDictionary', sldd_full_name);

    linked_sldd_name = sldd_full_name;
end

SLDDObj = Simulink.data.dictionary.open(linked_sldd_name);
SLDDObj.show;
SLDDObj.close;

end