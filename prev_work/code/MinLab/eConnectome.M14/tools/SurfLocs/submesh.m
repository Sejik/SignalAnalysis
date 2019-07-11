function [X,Y,Z] = submesh(locations,row,column)
% submesh - generate a mesh with row*column grids using four counter-clockwise points 
%
% Usage: [X,Y,Z] = submesh(locations,row,column)
%             
% Input: locations - the locations of the four counter-clockwise points,
%                            where locations(1,:) is the left top, locations(2,:) is the left bottom, 
%                            locations(3,:) is the right bottom, locations(4,:) is the right top.
%           row - the number of rows of the mesh.
%           column - the number of columns of the mesh.
%
% Output: X - x elements of the locations of the generated grids, where X(i,j) is 
%                   the x element of the grid (i, j)
%              Y - y elements of the locations of the generated grids, where Y(i,j) is 
%                   the y element of the grid (i, j)
%              Z - z elements of the locations of the generated grids, where Z(i,j) is 
%                   the z element of the grid (i, j)
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

X = zeros(row,column);
Y = X;
Z = X;

% left top
X(1,1) = locations(1,1);
Y(1,1) = locations(1,2);
Z(1,1) = locations(1,3);

% left bottom
X(row,1) = locations(2,1);
Y(row,1) = locations(2,2);
Z(row,1) = locations(2,3);

% right bottom
X(row,column) = locations(3,1);
Y(row,column) = locations(3,2);
Z(row,column) = locations(3,3);

% right top
X(1,column) = locations(4,1);
Y(1,column) = locations(4,2);
Z(1,column) = locations(4,3);

% generate first and last columns
j = 1;
interval = (locations(2,:)-locations(1,:))/(row-1);
for i = 2:row-1
    pos = locations(1,:)+(i-1)*interval;
    X(i,j) = pos(1);
    Y(i,j) = pos(2);
    Z(i,j) = pos(3);
end
j = column;
interval = (locations(3,:)-locations(4,:))/(row-1);
for i = 2:row-1
    pos = locations(4,:)+(i-1)*interval;
    X(i,j) = pos(1);
    Y(i,j) = pos(2);
    Z(i,j) = pos(3);
end

% generate each rows
for i = 1:row
    interval = ([X(i,column),Y(i,column),Z(i,column)]-[X(i,1),Y(i,1),Z(i,1)]) / (column-1);
    for j = 2:column-1
        pos = [X(i,1),Y(i,1),Z(i,1)] + (j-1)*interval;
        X(i,j) = pos(1);
        Y(i,j) = pos(2);
        Z(i,j) = pos(3);
    end
end
