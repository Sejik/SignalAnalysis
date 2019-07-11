function surf = getCapSurf(MEGlocs)
% getCapSurf - construct cap surface from MEG sensor locations 
%
% Usage:   surf = getCapSurf(MEGlocs)
%               MEGlocs - stores the locations of the MEG sensors. 
%               surf - stores the cap surface constructed from MEGlocs.
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
% Yakang Dai, 14-Jan-2011 15:00:30
% Release Version 2.0 beta
%
% ==========================================

num = length(MEGlocs);

center = mean(MEGlocs);
dirs = MEGlocs - repmat(center, num, 1);
normdirs = zeros(num,3);

% construct zdir
for i = 1:num
    normdirs(i,:) = dirs(i,:)/norm(dirs(i,:));
end
zdir = mean(normdirs);
zdir = zdir/norm(zdir);

% construct xdir that is orthogonal to zdir
[V, Idx] = max(zdir);
a = zdir(1);
b = zdir(2);
c = zdir(3);
switch Idx
    case 1
        m = sqrt(1/(2+(b+c)^2/a^2));
        xdir(1) = -(b+c)*m/a;
        xdir(2) = m;
        xdir(3) = m;
    case 2
        m = sqrt(1/(2+(a+c)^2/b^2));
        xdir(1) = m;
        xdir(2) = -(a+c)*m/b;
        xdir(3) = m;        
    case 3
        m = sqrt(1/(2+(a+b)^2/c^2));
        xdir(1) = m;
        xdir(2) = m;
        xdir(3) = -(a+b)*m/c;        
end

% construct ydir that is orthogonal to xdir and zdir
ydir = cross(zdir, xdir);
ydir = ydir/norm(ydir);

% project MEG sensors to X-Y plane and construct 2D topography
x = zeros(num,1);
y = x;
for i = 1:num
    alpha = acos(dot(zdir, normdirs(i,:)));
    x(i,1) = dot(xdir, dirs(i,:))*alpha;
    y(i,1) = dot(ydir, dirs(i,:))*alpha;
end
surf.tri = delaunay(x,y);
surf.x = x;
surf.y = y;
