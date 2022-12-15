function [new_block_path, new_block_name] = ...
    create_unique_block_name_tshintaiCustomTab(...
    model_name, block_parent, block_name)

block_handle = Simulink.findBlocks(model_name, 'Name', block_name);

if isempty(block_handle)
    new_block_path = [block_parent, '/', block_name];
    new_block_name = block_name;
else
    name_counter = 1;
    block_flag = true;
    while(block_flag)
        avoid_block_name = [block_name, '_', num2str(name_counter)];
        block_handle = Simulink.findBlocks( ...
            model_name, 'Name', avoid_block_name);

        if isempty(block_handle)
            new_block_path = [block_parent, '/', avoid_block_name];
            new_block_name = avoid_block_name;

            block_flag = false;
        else
            name_counter = name_counter + 1;
        end
    end
end

end
