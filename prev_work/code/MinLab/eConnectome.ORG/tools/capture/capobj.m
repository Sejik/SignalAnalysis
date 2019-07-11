function figHandle = capobj(axHandle, figName)
% capobj - capture all objects in the axis to a new figure
%
% Usage: figHandle = capobj(axHandle, figName)
%             
% Input: axHandle - the handle of an axis  
%           figName - the name for the new figure  
%
% Output: figHandle - the handle of the new figure
% 
% Description: all objects in the axis and the associated colorbar 
% can be copied into a new figure. The figure can be edited and 
% exported as all kinds of file formats supported by MATLAB.
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
% Yakang Dai, 29-Mar-2010 17:45:30
% Release Version 1.0
%
% ==========================================

cminmax = caxis(axHandle);

if ischar(figName)
    figHandle = figure('Name',figName,'NumberTitle','off');
else
    figHandle = figure;
end

haxes = axes;
set(haxes, 'DataAspectRatio', [1 1 1]);
box off;
axis off;
axis vis3d;

copyobj(allchild(axHandle),haxes);
colorbar;
caxis(cminmax);
