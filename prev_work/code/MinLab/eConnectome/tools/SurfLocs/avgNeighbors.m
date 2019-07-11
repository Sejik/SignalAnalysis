function [X,Y,Z] = avgNeighbors(vertices,X,Y,Z,row,column)
% avgNeighbors - get the mean location of the neighboring vertices of the brain model for each mesh grid  
%
% Usage: [X,Y,Z] = avgNeighbors(vertices,X,Y,Z,row,column)
%             
% Input: vertices - the vertices of the brain model, where vertices(i,:) is
%                           the location of the vertex i.
%           X - x elements of the locations of the mesh grids, where X(i,j) is 
%                   the x element of the grid (i, j)
%           Y - y elements of the locations of the mesh grids, where Y(i,j) is 
%                   the y element of the grid (i, j)
%           Z - z elements of the locations of the mesh grids, where Z(i,j) is 
%                   the z element of the grid (i, j) 
%           row - the number of rows of the mesh
%           column - the number of columns of the mesh
%
% Output: X - x elements of the new locations of the mesh grids, where X(i,j) is 
%                   the x element of the grid (i, j)
%              Y - y elements of the new locations of the mesh grids, where Y(i,j) is 
%                   the y element of the grid (i, j)
%              Z - z elements of the new locations of the mesh grids, where Z(i,j) is 
%                   the z element of the grid (i, j) 
%
% Description: The new location of each grid is the mean location of the grid's neighboring
% vertices of the brain model.
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

n = 20;
for j = 1:column
    for i = 1:row
        location = [X(i,j),Y(i,j),Z(i,j)];
        
        % use the average location of neighboring vertices 
        dists = sqrt( (vertices(:,1)-location(1)).^2 + (vertices(:,2)-location(2)).^2 + (vertices(:,3)-location(3)).^2 );
        [dists,idx] = sort(dists);
        pos = mean(vertices(idx(1:n),:));
        X(i,j) = pos(1);
        Y(i,j) = pos(2);
        Z(i,j) = pos(3);
    end
end
