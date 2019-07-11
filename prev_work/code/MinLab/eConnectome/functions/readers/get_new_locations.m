function [new_locations, new_marks] = get_new_locations(locations, marks)
% get_new_locations - transform locations and landmarks to the landmark space. 
%
% Usage: [new_locations, new_marks] = get_new_locations(locations, marks)
%
% Input: locations - is a 2D array (N * 3) for locations in X space.
%        marks - is a 2D array for the locations of landmarks (Nz, T9/LPA, T10/RPA) in X space.
%
% Output: new_locations - is a 2D array (N * 3) for the locations in the landmark space.
%         new_marks - is a 2D array for the locations of landmarks (Nz, T9/LPA, T10/RPA) 
%                     in the landmark space.
%
% The landmark space is constructed by the locations of landmarks (Nz, T9/LPA, T10/RPA).
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

Nz = marks(1,:);
LPA = marks(2,:);
RPA = marks(3,:);
center = (LPA+RPA)/2;
center2RPA = (RPA-center)/norm(RPA-center);
center2Nz = (Nz-center)/norm(Nz-center);
center2Cz = cross(center2RPA,center2Nz);

Z_norm = center2Cz/norm(center2Cz);
Y_norm = center2Nz;
X_norm = cross(Y_norm,Z_norm);
X_norm = X_norm/norm(X_norm);
rotation(:,1) = X_norm;
rotation(:,2) = Y_norm;
rotation(:,3) = Z_norm;

% transform to new coordinate system
new_locations = locations - repmat(center,length(locations),1);
new_locations = new_locations * rotation;

new_marks = marks - repmat(center,3,1);
new_marks = new_marks * rotation;
