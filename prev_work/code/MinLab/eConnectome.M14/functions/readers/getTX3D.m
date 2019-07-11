function [pos2d, pos3d, idx] = getTX3D(labels)
% getTX3D - get standard 2D/3D locations for standard 10-20/10-10/10-5 labels.
%
% Usage: [pos2d, pos3d, idx] = getTX3D(labels)
%
% Input: labels - is a cell array for standard 10-20/10-10/10-5 labels.
%
% Output: pos2d - a 2D array storing the standard 2D locations for the electrodes.
%              pos3d - a 2D array storing the standard 3D locations for the electrodes.
%              idx - a vector storing indices of the electrode labels in
%                      the cell array storing the standard labels.
%
% 10-5 System:
% The standard 10-5 system and electrode locations in spherical head model 
% developed by R. Oostenveld and P. Praamstra are used. 
% See below for detailed description of the 10-5 System: 
% R. Oostenveld and P. Praamstra. The five percent electrode system for
% high-resolution EEG and ERP measurements. Clin Neurophysiol, 112:713-719, 2001.
% http://robertoostenveld.ruhosting.nl/index.php/electrode/
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

labelsclass = class(labels);
if ~strcmp(labelsclass,'cell')
    errordlg('Input labels must be cell array!');
    return;
end
TXlabels = load('10-X-Labels.mat');
TXlabels = lower(TXlabels.labels);
labels = lower(labels);
len = length(labels);
TXlocations2d = load('10-X-Locations-2D-Nose-Y.mat');
TXlocations3d = load('10-X-Locations-3D-Nose-Y.mat');
for i = 1:len
    currentlabel = labels(i);
    index = strmatch(currentlabel, TXlabels, 'exact');
    if isempty(index)
        idx(i) = nan;
        pos2d(i,1) = nan;
        pos2d(i,2) = nan;
        pos3d(i,1) = nan;
        pos3d(i,2) = nan;
        pos3d(i,3) = nan;
    else
        idx(i) = index;
        pos2d(i,:) = TXlocations2d.locations(idx(i),:);
        pos3d(i,:) = TXlocations3d.locations(idx(i),:);
    end
end