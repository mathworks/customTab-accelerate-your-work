function subsystem_type = check_block_is_subsystem_tshintaiCustomTab( ...
    block_list)
%%
block_list = make_cell_list_tshintaiCustomTab(block_list);

%% 
% subsystem_typeは、0はサブシステムではない普通のブロック、
% 1は通常のサブシステム、2は参照サブシステム、
% 3は参照モデルを示す。
subsystem_type = zeros(numel(block_list), 1);

for i = 1:numel(block_list)
    if strcmp(get_param(block_list{i}, 'BlockType'), ...
            'SubSystem')
        try
            subsystem_ref_name = get_param(block_list{i}, ...
                    'ReferencedSubsystem');
        catch
            subsystem_ref_name = '';
        end

        if isempty(subsystem_ref_name)
            if strcmp( ...
                    get_param(block_list{i}, 'StaticLinkStatus'), ...
                    'resolved')
                % ライブラリリンクされたブロックは通常のブロック扱いとする
                subsystem_type(i) = 0;
            else
                subsystem_type(i) = 1;
            end
        else
            subsystem_type(i) = 2;
        end
    else
        if strcmp(get_param(block_list{i}, 'BlockType'), ...
                'ModelReference')
            subsystem_type(i) = 3;
        end
    end
end

end
