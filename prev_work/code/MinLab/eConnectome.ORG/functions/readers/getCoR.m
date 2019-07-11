function CoR = getCoR(landmarks)
% getCoR - get translation and rotation parameters for co-registration
%
% Usage: CoR = getCoR(landmarks)
%
% Input: landmarks - is a 2D array (3 * 3) for the locations of landmarks (Nz, T9/LPA, T10/RPA).
%
% Output: CoR - translation, rotation and size parameters, including:
%                         CoR.translation - a 1x3 array storing the translation (dx, dy, dz) 
%                         CoR.rotation - a 3x3 array storing the rotation (xnormal, ynormal, znormal) 
%                         CoR.size - a 1x3 array storing the size of the landmarks 
%
% Y = (X+CoR.translation)*CoR.rotation
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
% Yakang Dai, 18-Jan-2011 13:20:40
% Release Version 2.0 beta 
%
% ==========================================

Nz = landmarks(1,:);
LPA = landmarks(2,:);
RPA = landmarks(3,:);
center = (Nz+LPA+RPA)/3;
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

CoR.translation = -center;
CoR.rotation = rotation;

CoR.size = zeros(1,3);
CoR.size(1,1) = norm(RPA-LPA);
CoR.size(1,2) = norm(Nz-center);
CoR.size(1,3) = (CoR.size(1,1)+CoR.size(1,2))/2;

