function locations = stdLocations(labels)
% stdLocations - get locations for standard 10-20/10-10/10-5 labels.
%
% Usage: locations = stdLocations(labels)
%
% Input: labels - is a cell array for standard 10-20/10-10/10-5 labels.
%
% Output: locations - stores electrode locations. It has nbchan (number of channels) structures, 
%              each structure has 12 fields:
%              - locations(i).x is the x element of standard 2D location of the i-th electrode.
%              - locations(i).y is the y element of standard 2D location of the i-th electrode.
%              - locations(i).radius is the radius element of standard 2D location of the i-th electrode.
%              - locations(i).theta is the theta element of standard 2D location of the i-th electrode.
%              - locations(i).X is the X element of standard 3D location of the i-th electrode.
%              - locations(i).Y is the Y element of standard 3D location of the i-th electrode.
%              - locations(i).Z is the Z element of standard 3D location of the i-th electrode.
%              - locations(i).sph_radius is the sph_radius element of standard 3D location of the i-th electrode.
%              - locations(i).sph_phi is the sph_phi element of standard 3D location of the i-th electrode.
%              - locations(i).sph_theta is the sph_theta element of standard 3D location of the i-th electrode.
%              - locations(i).italyskinidx is the location index of the i-th electrode on the scalp model.
%              - locations(i).colinbemskinidx is the location index of the i-th electrode on the skin model of 
%                the standard MNI brain (the Colin brain).
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

[pos2d, pos3d, idx] = getTX3D(labels);
TXitalyskinidx = load('10-X-Idx-On-ItalySkin.mat');
TXcolinskinidx = load('10-X-Idx-On-ColinBemSkin.mat');
len = length(labels);
for i = 1:len
    if isnan(pos2d(i))       
        locations(i).x = [];
        locations(i).y = [];
        locations(i).theta = [];
        locations(i).radius = [];
    else
        locations(i).x = pos2d(i,1);
        locations(i).y = pos2d(i,2);
        
        locations(i).radius = sqrt(pos2d(i,:)*pos2d(i,:)');
        xy2normal = pos2d(i,:)/norm(pos2d(i,:));
        axisxnormal = [1, 0]';
        costheta = xy2normal*axisxnormal;
        locations(i).theta = acosd(costheta);
        if pos2d(i,2) > 0
            locations(i).theta = acosd(costheta);
        else
            locations(i).theta = - acosd(costheta);
        end
    end
    
    if isnan(pos3d(i))
        locations(i).X = [];
        locations(i).Y = [];
        locations(i).Z = [];
        locations(i).sph_theta = [];    
        locations(i).sph_phi = [];    
        locations(i).sph_radius = [];    
    else
        locations(i).X = pos3d(i,1);
        locations(i).Y = pos3d(i,2);
        locations(i).Z = pos3d(i,3);
        
        locations(i).sph_radius = sqrt(pos3d(i,:)*pos3d(i,:)');
        xy2normal = pos3d(i,1:2)/norm(pos3d(i,1:2));
        axisxnormal = [1, 0]';
        cosphi = xy2normal*axisxnormal;
        if pos3d(i,2) > 0
            locations(i).sph_phi = acosd(cosphi);
        else
            locations(i).sph_phi = - acosd(cosphi);
        end
        costheta = pos3d(i,3)/locations(i).sph_radius;
        if pos3d(i,3) > 0
            locations(i).sph_theta = acosd(costheta);
        else
            locations(i).sph_theta = - acosd(costheta);
        end
    end
    
    if isnan(idx(i))
        locations(i).italyskinidx = 0;
        locations(i).colinbemskinidx = 0;
    else
        locations(i).italyskinidx = TXitalyskinidx.idx(idx(i));
        locations(i).colinbemskinidx = TXcolinskinidx.idx(idx(i));
    end
    
end