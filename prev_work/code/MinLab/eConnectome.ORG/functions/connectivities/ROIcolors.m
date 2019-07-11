function cmap = ROIcolors(num)
% ROIcolors - generate colors for ROIs
%               
% Usage: cmap = ROIcolors(num)
%
% Input: num - is the number of ROIs
%
% Output: cmap - is the generated colors 
%
% Program Author: Yakang Dai, University of Minnesota, USA
%
% User feedback welcome: e-mail: econnect@umn.edu
%

% License
% ==============================================================
% This program is part of the eConnectome.
% 
% Copyright (C) 2010 Regents of the University of Minnesota. All rights reserved.
% Correspondence: binhe@umn.edu
% Web: econnectome.umn.edu
%
% This program is free software for academic research: you can redistribute it and/or modify
% it for non-commercial uses, under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see http://www.gnu.org/copyleft/gpl.html.
%
% This program is for research purposes only. This program
% CAN NOT be used for commercial purposes. This program 
% SHOULD NOT be used for medical purposes. The authors 
% WILL NOT be responsible for using the program in medical
% conditions.
% ==========================================

% Revision Logs
% ==========================================
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

if num < 1
    return;
end
basecolors = zeros(7,3);
basecolors(1,:) = [0.0, 0.5, 0.0];
basecolors(2,:) = [0, 0.6, 0.9];
basecolors(3,:) = [0.6, 0.42, 0.56];
basecolors(4,:) = [0.7, 0.5, 0.2];
basecolors(5,:) = [0.5, 0.5, 1.0];
basecolors(6,:) = [0.1, 0.9, 0.1];
basecolors(7,:) = [0.9, 0.4, 0.2];

% repeat the 7 colors
cmap = zeros(num,3);
for i = 1:num
    j = mod(i,7);
    if j == 0
        j = 7;
    end
    cmap(i,:) = basecolors(j,:);
end
