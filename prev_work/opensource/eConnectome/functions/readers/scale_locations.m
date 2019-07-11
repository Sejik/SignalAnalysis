function scaledlocs = scale_locations(customlocs,custommarks,stdmarks)
% scale_locations - scale customized locations according to 
%                   customized landmarks and standard landmarks. 
%
% Usage: scaledlocs = scale_locations(customlocs,custommarks,stdmarks)
%
% Input: customlocs - is a 2D array (N * 3) for customized locations in the landmark space.
%        custommarks - is a 2D array for the locations of customized landmarks 
%                      in the landmark space.
%        stdmarks - is a 2D array for the locations of standard landmarks
%                   in the landmark space.
%
% Output: scaledlocs - is a 2D array (N * 3) for the scaled locations.
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

std_L_X = ( norm(stdmarks(3,:)) + norm(stdmarks(2,:)) )/2;
std_L_Y = norm( stdmarks(1,:) );

custom_L_X = ( norm(custommarks(3,:)) + norm(custommarks(2,:)) )/2;
custom_L_Y = norm( custommarks(1,:) );

xscale = std_L_X/custom_L_X;
yscale = std_L_Y/custom_L_Y;
zscale = (xscale+yscale)/2;
scaledlocs = customlocs .* repmat([xscale,yscale,zscale],length(customlocs),1);