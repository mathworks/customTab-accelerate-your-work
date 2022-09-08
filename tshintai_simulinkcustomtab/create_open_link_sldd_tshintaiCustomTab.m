function create_open_link_sldd_tshintaiCustomTab()
%% 説明
% slddファイルが関連付けられていないモデルの場合、ファイルを新規作成し、
% モデルに関連付ける。または、既存のslddファイルと関連付けることもできる。
% その後、そのslddファイルを開く。
% すでに関連付けられている場合、そのファイルを開く。
%%
model_name = bdroot;
linked_sldd_name = get_param(model_name, 'DataDictionary');

if isempty(linked_sldd_name)
    % プロジェクトが起動していない場合は現在のフォルダーを、
    % 起動している場合はプロジェクトパス内のslddファイルを探す。
    try
        this_pjObj = currentProject;
    catch
        this_pjObj = '';
    end

    if isempty(this_pjObj)
        dir_info = dir;
    else
        dir_info = [];
        root_searched = false;
        for i = 1:numel(this_pjObj.ProjectPath)
            cd(this_pjObj.ProjectPath(1, i).File);
            dir_info = [dir_info; dir];
            if strcmp(this_pjObj.ProjectPath(1, i).File, this_pjObj.RootFolder)
                root_searched = true;
            end
        end
        cd(this_pjObj.RootFolder);
        if ~root_searched
            dir_info = [dir_info; dir];
        end
    end

    sldd_info = get_sldd_info(dir_info);

    if isempty(sldd_info)
        sldd_full_name = get_sldd_name_to_create;
        if isempty(sldd_full_name)
            return;
        end

        if exist(sldd_full_name, "file")
            % ファイルは作成しない
        else
            Simulink.data.dictionary.create(sldd_full_name);
        end
        set_param(model_name, 'DataDictionary', sldd_full_name);

        linked_sldd_name = sldd_full_name;
    else
        sldd_names = cell(numel(sldd_info) + 1, 1);
        for i = 1:numel(sldd_info)
            sldd_names{i} = sldd_info(i).name;
        end
        sldd_names{end} = '<<新規作成>>';

        [RM_indx, ~] = listdlg('ListString', sldd_names, ...
            'PromptString', {'リンクするslddを選択してください：'}, ...
            'SelectionMode', 'single', ...
            'ListSize', [300, 400]);
        if isempty(RM_indx)
            return;
        elseif (RM_indx == numel(sldd_names))
            sldd_full_name = get_sldd_name_to_create;
            if isempty(sldd_full_name)
                return;
            end

            if exist(sldd_full_name, "file")
                % ファイルは作成しない
            else
                Simulink.data.dictionary.create(sldd_full_name);
            end
            set_param(model_name, 'DataDictionary', sldd_full_name);
        else
            sldd_full_name = sldd_info(RM_indx).name;
        end
        set_param(model_name, 'DataDictionary', sldd_full_name);

        linked_sldd_name = sldd_full_name;
    end
end


%%
SLDDObj = Simulink.data.dictionary.open(linked_sldd_name);
SLDDObj.show;
SLDDObj.close;

end


function sldd_full_name = get_sldd_name_to_create()
% sldd名を取得する
prompt = {'slddファイル名を入力してください：'};
dlgtitle = 'Input';
dims = [1 35];
definput = "system_data";
answer = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer) || (strlength(answer) == 0)
    sldd_full_name = '';
    return;
else
    sldd_full_name = [answer{1}, '.sldd'];
end

end

function sldd_info = get_sldd_info(dir_info)
%%
file_flag = false(numel(dir_info), 1);
for i = 1:numel(file_flag)
    file_flag(i) = ~(dir_info(i).isdir);
end

file_info = dir_info(file_flag);

%%
sldd_flag = false(numel(file_info), 1);
for i = 1:numel(file_info)
    text = strsplit(file_info(i).name, '.');
    if strcmp(text{end}, 'sldd')
        sldd_flag(i) = true;
    end
end

sldd_info = file_info(sldd_flag);

end
