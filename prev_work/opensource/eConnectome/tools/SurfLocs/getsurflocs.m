function [surflocs, electrodelocs] = getsurflocs(electrodelocs)
% getsurflocs - generate a surface through the electrodes over the cortex
%                      model with the locations of the electrodes
%
% Usage: [surflocs, electrodelocs] = getsurflocs(electrodelocs)
%             
% Input: electrodelocs - the structure includes the following fields: 
%                                    - electrodelocs.X stores x elements of the locations of the electrodes, where electrodelocs.X(i,j) is 
%                                       the x element of the electrode at grid (i, j).  
%                                    - electrodelocs.Y stores y elements of the locations of the electrodes, where electrodelocs.Y(i,j) is 
%                                       the y element of the electrode at grid (i, j)
%                                    - electrodelocs.Z stores z elements of the locations of the electrodes, where electrodelocs.Z(i,j) is 
%                                       the z element of the electrode at grid (i, j) 
%                                    - electrodelocs.row is the number of rows of the electrodes
%                                    - electrodelocs.column is the number of columns of the electrodes
%
% Output: surflocs - the structure includes the following fields: 
%                              - surflocs.X stores x elements of the locations of the surface grids, where surflocs.X(i,j) is 
%                                the x element of the location of the surface grid (i, j).  
%                              - surflocs.Y stores y elements of the locations of the surface grids, where surflocs.Y(i,j) is 
%                                the y element of the location of the surface grid (i, j)
%                              - surflocs.Z stores z elements of the locations of the surface grids, where surflocs.Z(i,j) is 
%                                the z element of the location of the surface grid (i, j) 
%
%              electrodelocs - two more fields are added to the input electrodelocs:
%                                    - electrodelocs.rowindex stores the row indices of the electrodes on the surface grids
%                                    - electrodelocs.columnindex stores the column indices of the electrodes on the surface grids
%
% Description: Original electrode mesh (Row*Column) is upsampled to a new mesh (newRow*newColumn) .
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

subsize = [5,5];
surflocs.row = (subsize(1)-1)*(electrodelocs.row-1)+1;
surflocs.column = (subsize(2)-1)*(electrodelocs.column-1)+1;
surflocs.X = zeros(surflocs.row,surflocs.column);
surflocs.Y = surflocs.X;
surflocs.Z = surflocs.X;

% indices in surflocs for electrodes
electrodelocs.rowindex = ([1:electrodelocs.row]-1)*(subsize(1)-1)+1;
electrodelocs.columnindex = ([1:electrodelocs.column]-1)*(subsize(2)-1)+1;

for j = 1:electrodelocs.column-1
    for i = 1:electrodelocs.row-1
        locations(1,:) = [electrodelocs.X(i,j), electrodelocs.Y(i,j), electrodelocs.Z(i,j)];
        locations(2,:) = [electrodelocs.X(i+1,j), electrodelocs.Y(i+1,j), electrodelocs.Z(i+1,j)];
        locations(3,:) = [electrodelocs.X(i+1,j+1), electrodelocs.Y(i+1,j+1), electrodelocs.Z(i+1,j+1)];
        locations(4,:) = [electrodelocs.X(i,j+1), electrodelocs.Y(i,j+1), electrodelocs.Z(i,j+1)];
        [subX,subY,subZ] = submesh(locations,subsize(1),subsize(2));
        ip = electrodelocs.rowindex(i);
        jp = electrodelocs.columnindex(j);
        ip1 = ip+subsize(1)-1;
        jp1 = jp+subsize(2)-1;
        surflocs.X(ip:ip1,jp:jp1) = subX;
        surflocs.Y(ip:ip1,jp:jp1) = subY; 
        surflocs.Z(ip:ip1,jp:jp1) = subZ;
    end
end
