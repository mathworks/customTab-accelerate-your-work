function rounded_name = round_long_harness_name_tshintaiCustomTab(original_name)

if (length(original_name) >= 58)
    harness_name_temp = string(original_name);
    del_pos = length(original_name) - 56;
    head_char = harness_name_temp.extractBefore(2);
    rounded_string = harness_name_temp.extractAfter(del_pos);
    rounded_name = char(head_char + rounded_string);
else
    rounded_name = original_name;
end

end
