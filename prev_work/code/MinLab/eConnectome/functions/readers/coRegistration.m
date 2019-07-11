function locations = coRegistration(customlocs,custommarks)
% coRegistration - Co-Registrate customized electrode locations with landmarks to standard spaces
%
% Usage: locations = coRegistration(customlocs,custommarks)
%
% Input: customlocs - is a 2D array (N * 3) for customized electrode locations.
%        custommarks - is a 2D array for the locations of landmarks (Nz, T9/LPA, T10/RPA).
%
% Output: locations - stores electrode locations. It has nbchan (number of channels) structures.
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
% Brain Model:
% The skin model constructed from the standard Montreal Neurological Institute (MNI) brain 
% is used in the program. See below for detailed description of MNI Brain model: 
% Collins, D. L., Neelin, P., Peters, T. M., Evans, A. C., 
% Automatic 3D intersubject registration of MR volumetric data in standardized Talairach space. 
% J. Comput. Assist. Tomogr. 18(2): 192-205 (1994).
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

load('fiducial.mat');
load('italyskin.mat');
load('colinbemskin.mat');

% for customized locations and marks
[customlocs, custommarks] = get_new_locations(customlocs, custommarks);

% for italy skin
[stdlocs, stdmarks] = get_new_locations(italyskin.Vertices, fiducial.italyskin);
scaledlocs = scale_locations(customlocs,custommarks,stdmarks);
idx_on_italyskin = m_dsearchn(stdlocs,scaledlocs);

% for colin bem skin
[stdlocs, stdmarks] = get_new_locations(colinbemskin.Centers, fiducial.colinbemskin);
scaledlocs = scale_locations(customlocs,custommarks,stdmarks);
idx_on_colinbemskin = m_dsearchn(stdlocs,scaledlocs);

italyskin_xy = load('italyskin-in-xy.mat');
italyskin_xyz = load('italyskin-in-xyz.mat');

len = length(customlocs);
for i = 1:len
    idx = idx_on_italyskin(i);
    
    locations(i).x = italyskin_xy.xy(idx,1);
    locations(i).y = italyskin_xy.xy(idx,2);
    locations(i).radius = sqrt(italyskin_xy.xy(idx,:)*italyskin_xy.xy(idx,:)');
    xy2normal = italyskin_xy.xy(idx,:)/norm(italyskin_xy.xy(idx,:));
    axisxnormal = [1, 0]';
    costheta = xy2normal*axisxnormal;
    locations(i).theta = acosd(costheta);
    if italyskin_xy.xy(idx,2) > 0
        locations(i).theta = acosd(costheta);
    else
        locations(i).theta = - acosd(costheta);
    end    
    
    locations(i).X = italyskin_xyz.xyz(idx,1);
    locations(i).Y = italyskin_xyz.xyz(idx,2);
    locations(i).Z = italyskin_xyz.xyz(idx,3);
    locations(i).sph_radius = sqrt(italyskin_xyz.xyz(idx,:)*italyskin_xyz.xyz(idx,:)');
    xy2normal = italyskin_xyz.xyz(idx,1:2)/norm(italyskin_xyz.xyz(idx,1:2));
    axisxnormal = [1, 0]';
    cosphi = xy2normal*axisxnormal;
    if italyskin_xyz.xyz(idx,2) > 0
        locations(i).sph_phi = acosd(cosphi);
    else
        locations(i).sph_phi = - acosd(cosphi);
    end
    costheta = italyskin_xyz.xyz(idx,3)/locations(i).sph_radius;
    if italyskin_xyz.xyz(idx,3) > 0
        locations(i).sph_theta = acosd(costheta);
    else
        locations(i).sph_theta = - acosd(costheta);
    end    
    
    locations(i).italyskinidx = idx;
    locations(i).colinbemskinidx = idx_on_colinbemskin(i);    
end