function [ hit_count ] = fnc_countByCharacter( loss_res, label )
%FNC_COUNTBYCHARACTER Summary of this function goes here
%   Detailed explanation goes here
lind= [1:size(label,1)]*label;
loss_res_inv = abs(loss_res - 1);
correct_character = lind .* loss_res_inv;
unique_lind = unique(lind);
hit_count = histc(correct_character(:),unique_lind);


end

