function MEG = pop_meg_matreader()
% pop_meg_matreader - read MAT file and return MEG structure
%
% Usage:         
%            1. type 
%               >> MEG = pop_meg_matreader
%               or call MEG = pop_meg_matreader to convert MAT file to MEG structure. 
%               Output: MEG - is the structure enclosing MEG data.
%               The recognizable MAT file format includes at least 10 fields: 
%               - MEG.name is the name for the MEG data.
%               - MEG.type is 'MEG'
%               - MEG.nbchan is the number of channels
%               - MEG.points is the number of sampling points
%               - MEG.srate is the sampling rate
%               - MEG.labels is a cell array of channel labels
%               - MEG.data is a 2D array ([m, n]) for MEG time series, 
%                 where m=nbchan and n=points.
%               - MEG.locations has nbchan structures
%                  - MEG.locations(i).X is the X element of the i-th location.
%                  - MEG.locations(i).Y is the Y element of the i-th location.
%                  - MEG.locations(i).Z is the Z element of the i-th location.
%               - MEG.marks is a 2D array ([3, 3]) for landmark locations, where
%                  - MEG.marks(1,:) is the Nz location
%                  - MEG.marks(2,:) is the T9/LPA location
%                  - MEG.marks(3,:) is the T10/RPA location
%               (3) For ERF data, the MEG structure includes an extra field:
%               - MEG.event stores the information for events.  
%
%               Please see the eConnectome Manual 
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable MAT file format for MEG.
%
%            2. call MEG = pop_meg_matreader from the megfc GUI ('Menu bar -> File -> Import -> MAT File'). 
%               The imported MEG will be made the current MEG and mastered by the 
%               document manager of the megfc GUI. 
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
% Yakang Dai, 01-Feb-2011 11:33:25
% Release Version 1.1
%
% ==========================================

[name pathstr]=uigetfile('*.mat', 'Select MEG File');
if name==0
    MEG = [];
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

MEG = load(Fullfilename);
if isempty(MEG)
    MEG = [];
    errordlg( ['Load ' Fullfilename ' error!'] );
    return;
end

names = fieldnames(MEG);
numfield = length(names);
if numfield ~= 1 
    MEG = [];
    errordlg('The input is not a valid MEG MAT File');
    return;
end

field = char(names);

reqfields = {'nbchan','points','srate','labels','data','locations','marks','normals'};
fields = isfield(MEG.(field),reqfields);
if ~all(fields)
    idx = find(fields==0);
    missed = strcat(reqfields(idx));
    errordlg(['Miss fields:' missed]);
end
    
MEG = MEG.(field);
if ~isfield(MEG,'name') | isempty(MEG.name)
    [pathstr, name, ext, versn] = fileparts(Fullfilename);
    MEG.name = name;
end

if ~isfield(MEG,'type') | isempty(MEG.type)
    MEG.type = 'MEG';
end

if isempty(MEG.nbchan)
    errordlg('Number of channles is empty!');
    return;
end

if isempty(MEG.points)
    errordlg('Number of points is empty!');
    return;
end

if isempty(MEG.srate)
    warndlg('Sampling rate is empty!');
    MEG.srate = 250;
end

if isempty(MEG.labels)
    errordlg('There is no label!');
    return;
end

if isempty(MEG.data)
    errordlg('There is no data!');
    return;
end

if MEG.nbchan ~= length(MEG.labels) 
   errordlg('Number of labels is not right!'); 
   return;
end

sz = size(MEG.data);
if MEG.nbchan ~= sz(1) && MEG.nbchan ~= sz(2)
    errordlg('Data size is not right!'); 
    return;
end

if MEG.nbchan == sz(2)
    MEG.data = MEG.data';
    sz(2) = sz(1);
end

if MEG.points ~= sz(2)
    errordlg('Data size is not right!'); 
    return;
end

if ~isfield(MEG,'start') | isempty(MEG.start)
    MEG.start = 1;
end

if ~isfield(MEG,'end') | isempty(MEG.end)
    MEG.end = MEG.points;
end

if ~isfield(MEG,'dispchans') | isempty(MEG.dispchans)
    MEG.dispchans = MEG.nbchan;
end

if ~isfield(MEG,'vidx')
    MEG.vidx = 1:MEG.nbchan;
end

if ~isfield(MEG,'bad')
    MEG.bad = [];
end

if ~isfield(MEG, 'unit')
    MEG.unit = 'fT';
end

% check if locations and normals are available
if isfield(MEG,'locations')
    cstmlocations = MEG.locations;
else
    errordlg('Miss MEG sensor locations.');
    return;
end

if isfield(MEG,'normals')
    cstmnormals = MEG.normals;
else
    cstmnormals = [];
end

if isfield(MEG, 'marks') && length(MEG.marks) == 3
    % is not the exported one, need co-registration
    if ~isfield(MEG.locations, 'landmarks')
        if MEG.nbchan ~= length(MEG.locations)
            errordlg('The number of locations is not right!');
            return;
        end
        
        markedlocs = MEG.marks;
        MEG.locations = MEGcoRegistration(markedlocs,cstmlocations,cstmnormals);
    end
else
    errordlg('Miss landmarks for co-registration.');
    return;
end

vdata = MEG.data(MEG.vidx,:);
if ~isfield(MEG,'min') | isempty(MEG.min)
    MEG.min = min(min(vdata));
end

if ~isfield(MEG,'max') | isempty(MEG.max)
    MEG.max = max(max(vdata));
end

MEG.labeltype = [];

% ERF analysis
if isfield(MEG, 'event') && length(MEG.event) > 0    
    analysisevent = questdlg('Perform ERF analysis?','','Yes','Cancel','Cancel');
    if strcmp(analysisevent, 'Yes')
        MEG = erpanalysis(MEG);
    end
end
