function locations = MEGcoRegistration(MEGmarks, MEGlocs, MEGnorms)
% MEGcoRegistration - co-registrate MEG sensor locations with the standard brain.
%
% Usage: locations = MEGcoRegistration(MEGmarks, MEGlocs, MEGnorms)
%
% Input: MEGmarks - is a 2D array (3 * 3) for the locations of landmarks (Nz, T9/LPA, T10/RPA) in measurement space.
%           MEGlocs - is a 2D array (N * 3) for MEG sensor locations in measurement space.
%           MEGnorms - is a 2D array (N * 3) for MEG sensor normals in measurement space.
%
% Output: locations - co-registrated MEG sensor locations. It has 7 fields:
%              - locations.italybrain stores co-registered MEG locations in the space of the Italian brain.
%              - locations.colinbrain stores co-registered MEG locations in the space of the standard MNI brain (the Colin brain).
%              - locations.normals.italybrain stores co-registered MEG normals in the space of the Italian brain.
%              - locations.normals.colinbrain stores co-registered MEG normals in the space of the standard MNI brain (the Colin brain).
%              - locations.landmarks.italybrain stores co-registered MEG landmarks in the space of the Italian brain.
%              - locations.landmarks.colinbrain stores co-registered MEG landmarks in the space of the standard MNI brain (the Colin brain).
%              - locations.surf stores the cap surface through MEG sensors.
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
% Yakang Dai, 14-Jan-2011 15:20:30
% Release Version 2.0 beta 
%
% ==========================================

% load('fiducial.mat');

% MEG_center = mean(MEGmarks);
% MEGlocs = MEGlocs - repmat(MEG_center, length(MEGlocs),1);
% MEGmarks = MEGmarks - repmat(MEG_center,3,1);
% 
% italyskin_center = mean(fiducial.italyskin);
% italyskin_marks = fiducial.italyskin - repmat(italyskin_center,3,1);
% 
% % MEGmarks and italyskin_marks have the same center.
% % Compute A in MEGmarks*A = italyskin_marks, 
% % and transform MEG locations into italyskin_marks  system
% A = pinv(MEGmarks) * italyskin_marks;
% locations.italybrain = MEGlocs * A + repmat(italyskin_center, length(MEGlocs),1);
% 
% colinbemskin_center = mean(fiducial.colinbemskin);
% colinbemskin_marks = fiducial.colinbemskin - repmat(colinbemskin_center,3,1);
% 
% % MEGmarks and colinbemskin_marks have the same center.
% % Compute B in MEGmarks*B = colinbemskin_marks, 
% % and transform MEG locations into colinbemskin_marks system 
% B = inv(MEGmarks) * colinbemskin_marks;
% locations.colinbrain = MEGlocs * B + repmat(colinbemskin_center,
% length(MEGlocs),1);

locations.surf = getCapSurf(MEGlocs);

CoR = load('CoR.mat');

MEGCoR = getCoR(MEGmarks);
num = length(MEGlocs);
MEGlocs = (MEGlocs+repmat(MEGCoR.translation,num,1))*MEGCoR.rotation; % locations
MEGmarks = (MEGmarks+repmat(MEGCoR.translation,3,1))*MEGCoR.rotation; % marks
if ~isempty(MEGnorms)
    MEGnorms = (MEGnorms+repmat(MEGCoR.translation,num,1))*MEGCoR.rotation; % normals
    ori = [0,0,0];
    MEGori = (ori+MEGCoR.translation)*MEGCoR.rotation; % origin
end

scale = CoR.italyskin.size ./ MEGCoR.size;
locations.italybrain = MEGlocs .* repmat(scale,num,1);
locations.landmarks.italybrain = MEGmarks .* repmat(scale,3,1);
if ~isempty(MEGnorms)
    locations.normals.italybrain = MEGnorms .* repmat(scale,num,1); % to get normals in the italybrain space 
    ori_italybrain = MEGori .* scale;
    locations.normals.italybrain = locations.normals.italybrain - repmat(ori_italybrain,num,1);
    for i = 1:num
        normal = locations.normals.italybrain(i,:);
        locations.normals.italybrain(i,:) = normal / norm(normal); 
    end
else
    locations.normals.italybrain = [];
end

scale = CoR.colinbemskin.size ./ MEGCoR.size;
locations.colinbrain = MEGlocs .* repmat(scale,num,1);
locations.landmarks.colinbrain = MEGmarks .* repmat(scale,3,1);
if ~isempty(MEGnorms)
    locations.normals.colinbrain = MEGnorms .* repmat(scale,num,1); % to get normals in the colinbrain space 
    ori_colinbrain  = MEGori .* scale;
    locations.normals.colinbrain = locations.normals.colinbrain - repmat(ori_colinbrain,num,1);
    for i = 1:num
        normal = locations.normals.colinbrain(i,:);
        locations.normals.colinbrain(i,:) = normal / norm(normal); 
    end
else
    locations.normals.colinbrain = [];
end


