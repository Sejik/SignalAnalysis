function EEG = pop_matreader()
% pop_matreader - read MAT file and return EEG structure
%
% Usage:         
%            1. type 
%               >> EEG = pop_matreader
%               or call EEG = pop_matreader to convert MAT file to EEG structure. 
%               Output: EEG - is the structure enclosing EEG data.
%               (1) For EEG recorded with standard labels, the recognizable MAT file format 
%               includes at least 8 fields: 
%               - EEG.name is the name for the EEG data.
%               - EEG.type is 'EEG'
%               - EEG.nbchan is the number of channels
%               - EEG.points is the number of sampling points
%               - EEG.srate is the sampling rate
%               - EEG.labeltype is 'standard'
%               - EEG.labels is a cell array of channel labels
%               - EEG.data is a 2D array ([m, n]) for EEG time series, 
%                 where m=nbchan and n=points.
%               (2) For EEG recorded with customized locations, the recognizable MAT file format 
%               includes at least 10 fields: 
%               - EEG.name is the name for the EEG data.
%               - EEG.type is 'EEG'
%               - EEG.nbchan is the number of channels
%               - EEG.points is the number of sampling points
%               - EEG.srate is the sampling rate
%               - EEG.labeltype is 'customized'
%               - EEG.labels is a cell array of channel labels
%               - EEG.data is a 2D array ([m, n]) for EEG time series, 
%                 where m=nbchan and n=points.
%               - EEG.locations has nbchan structures (the customized locations)
%                  - EEG.locations(i).X is the X element of the i-th location.
%                  - EEG.locations(i).Y is the Y element of the i-th location.
%                  - EEG.locations(i).Z is the Z element of the i-th location.
%               - EEG.marks is a 2D array ([m, n]) for landmark locations, where
%                  - EEG.marks(1,:) is the Nz location
%                  - EEG.marks(2,:) is the T9/LPA location
%                  - EEG.marks(3,:) is the T10/RPA location
%               (3) For ERP data, the EEG structure includes an extra field:
%               - EEG.event stores the information for events.  
%
%               Please see the eConnectome Manual 
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable MAT file format for EEG.
%
%            2. call EEG = pop_matreader from the eegfc GUI ('Menu bar -> File -> Import -> MAT File'). 
%               The imported EEG will be made the current EEG and mastered by the 
%               document manager of the eegfc GUI. 
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
% Yakang Dai, 20-Apr-2010 18:26:30
% Add ERP analysis function
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

[name pathstr]=uigetfile('*.mat', 'Select EEG File');
if name==0
    EEG = [];
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

eeg = load(Fullfilename);
if isempty(eeg)
    EEG = [];
    errordlg( ['Load ' Fullfilename ' error!'] );
    return;
end

names = fieldnames(eeg);
numfield = length(names);
if numfield ~= 1 
    EEG = [];
    errordlg('The input is not a valid EEG MAT File');
    return;
end

field = char(names);

reqfields = {'nbchan','points','srate','labeltype','labels','data'};
fields = isfield(eeg.(field),reqfields);
if ~all(fields)
    idx = find(fields==0);
    missed = strcat(reqfields(idx));
    errordlg(['Miss fields:' missed]);
end
    
EEG = eeg.(field);
if ~isfield(EEG,'name') | isempty(EEG.name)
    [pathstr, name, ext, versn] = fileparts(Fullfilename);
    EEG.name = name;
end

if ~isfield(EEG,'type') | isempty(EEG.type)
    EEG.type = 'EEG';
end

if isempty(EEG.nbchan)
    errordlg('Number of channles is empty!');
    return;
end

if isempty(EEG.points)
    errordlg('Number of points is empty!');
    return;
end

if isempty(EEG.srate)
    warndlg('Sampling rate is empty!');
    EEG.srate = 250;
end

if isempty(EEG.labeltype)
    errordlg('There is no label type!');
    return;
end

if isempty(EEG.labels)
    errordlg('There is no label!');
    return;
end

if isempty(EEG.data)
    errordlg('There is no data!');
    return;
end

if EEG.nbchan ~= length(EEG.labels) 
   errordlg('Number of labels is not right!'); 
   return;
end

sz = size(EEG.data);
if EEG.nbchan ~= sz(1) && EEG.nbchan ~= sz(2)
    errordlg('Data size is not roght!'); 
    return;
end

if EEG.nbchan == sz(2)
    EEG.data = EEG.data';
    sz(2) = sz(1);
end

if EEG.points ~= sz(2)
    errordlg('Data size is not right!'); 
    return;
end

if ~isfield(EEG,'start') | isempty(EEG.start)
    EEG.start = 1;
end

if ~isfield(EEG,'end') | isempty(EEG.end)
    EEG.end = EEG.points;
end

if ~isfield(EEG,'dispchans') | isempty(EEG.dispchans)
    EEG.dispchans = EEG.nbchan;
end

if ~isfield(EEG,'vidx')
    EEG.vidx = 1:EEG.nbchan;
end

if ~isfield(EEG,'bad')
    EEG.bad = [];
end

if ~isfield(EEG, 'unit')
    EEG.unit = 'uV';
end

if strcmp(EEG.labeltype, 'standard')% Generate standard label locations if the given labels are standard.
    if ~isfield(EEG,'locations')
        EEG.locations = stdLocations(EEG.labels);
        vidx = ~cellfun(@isempty, {EEG.locations(:).X});
        EEG.vidx = find(vidx==1);
    end
else % Read customized label locations if the given labels are not standard.
    if isfield(EEG,'locations') && length(EEG.locations) > 0
        if isfield(EEG.locations,'x')
            EEG.vidx = 1:EEG.nbchan; % has locations.
        else
            if isfield(EEG, 'marks') && length(EEG.marks) == 3
                if EEG.nbchan ~= length(EEG.locations)
                    errordlg('The number of locations is not right!');
                    return;
                end

                reqfields = {'X','Y','Z'};
                fields = isfield(EEG.locations,reqfields);
                if ~all(fields)
                    idx = find(fields==0);
                    missed = strcat(reqfields(idx));
                    errordlg(['Miss dimensions:' missed]);
                end
                cstmlocations(:,1) = cell2mat({EEG.locations(:).X});
                cstmlocations(:,2) = cell2mat({EEG.locations(:).Y});
                cstmlocations(:,3) = cell2mat({EEG.locations(:).Z});
                markedlocs = EEG.marks;

                EEG.locations = coRegistration(cstmlocations, markedlocs);
            else
                errordlg('Miss Marks for Location Co-registration.'); % customized labeltype with locations need marks for co-registration.
                return;
            end
        end
    else
        errordlg('Miss Customized-Channel-Locations information.'); % customized labeltype without locations not suported.
        return;
    end
end

vdata = EEG.data(EEG.vidx,:);
if ~isfield(EEG,'min') | isempty(EEG.min)
    EEG.min = min(min(vdata));
end

if ~isfield(EEG,'max') | isempty(EEG.max)
    EEG.max = max(max(vdata));
end

% ERP analysis
if isfield(EEG, 'event') && length(EEG.event) > 0    
    analysisevent = questdlg('Perform ERP analysis?','','Yes','Cancel','Cancel');
    if strcmp(analysisevent, 'Yes')
        EEG = erpanalysis(EEG);
    end
end
