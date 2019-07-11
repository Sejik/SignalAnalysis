function MEG = pop_meg_txtreader()
% pop_meg_txtreader - read text file and return MEG structure
%
% Usage:         
%            1. type 
%               >> MEG = pop_meg_txtreader
%               or call MEG = pop_txtreader to convert text file to MEG structure. 
%               Output: MEG - is the structure enclosing MEG data.
%               The recognizable text file format for MEG includes a '.txt'
%               head file and a '.dat' data file. The 'txt' stores information
%               including number of channels, sampling rate, number of sampling points, 
%               unit of measures, channel labels and sensor
%               locations. The '.dat' file stores the time series data of the MEG.
%               Please see the eConnectome Manual 
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable text file format for MEG.
%
%            2. call MEG = pop_meg_txtreader from the megfc GUI ('Menu bar -> File -> Import -> TXT File'). 
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
% Yakang Dai, 06-Jan-2011 17:01:40
% Release Version 2.0 beta
%
% ==========================================

[name pathstr]=uigetfile('*.txt', 'Select MEG File');
if name==0
    MEG = [];
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

fid = fopen(Fullfilename,'r');
if fid<0 
    MEG = [];
    errordlg( ['Can Not open ' Fullfilename] );
    return;
end

MEG = ecom_initialize;
MEG.type        =  'MEG';
[pathstr, name, ext, versn] = fileparts(Fullfilename);
MEG.name = name;

% read the file lines
lines={};
while ~feof(fid)
     lines = [lines; {fgetl(fid)}];
end
fclose(fid);

% remove the leading and trailing white-space characters of each line.
lines = strtrim(lines);

% remove comments and empty lines
lines(strmatch('%', lines)) = [];
lines = lines(~cellfun(@isempty, lines) == true);

fields = strmatch('[', lines);
numfields = length(fields);
fields(numfields+1) = length(lines) + 1;

for i = 1:numfields
    fieldname = lines(fields(i));
    fieldname = strread(char(fieldname), '[%s', 'delimiter', ']');
    fieldname = lower(fieldname);
    info.(char(fieldname)) = lines( fields(i)+1 : fields(i+1)-1 );
end

if isfield(info, 'nbchan') && length(info.nbchan) > 0
    MEG.nbchan = strread(char(info.nbchan));
else
    warndlg('Miss Number-of-Channels information.');
end

if isfield(info, 'srate') && length(info.srate) > 0
    MEG.srate = strread(char(info.srate));
else
    warndlg('Miss Sampling-Rate information.');
    MEG.srate = 250;
end

if isfield(info, 'points') && length(info.points) > 0
    MEG.points = strread(char(info.points));
else
    warndlg('Miss Number-of-Sampling-Points information.');
end

if isfield(info, 'unit') && length(info.unit) > 0
    MEG.unit = char(info.unit);
else
    MEG.unit = 'fT';
end

% Get labels
if isfield(info, 'labels')  && length(info.labels) > 0
    if MEG.nbchan <= 0
        MEG.nbchan = length(info.labels);
    else
        if MEG.nbchan ~= length(info.labels)
                errordlg('The number of labels is not right!');
                return;
        end
    end
    MEG.labels = info.labels;
else
    errordlg('Miss Channel-Labels information.');
    return;
end

% check if locations and normals are available
if isfield(info,'locations')
    if MEG.nbchan ~= length(info.locations)
        errordlg('The number of locations/normals is not right!');
        return;
    end
    cstmlocations = str2num(strvcat(info.locations));
else
    errordlg('Miss MEG sensor locations.'); % customized labeltype without locations not suported.
    return;
end

if isfield(info,'normals')
    if MEG.nbchan ~= length(info.normals)
        errordlg('The number of locations/normals is not right!');
        return;
    end
    cstmnormals = str2num(strvcat(info.normals));
    MEG.normals = cstmnormals;
else
    cstmnormals = [];
end

if isfield(info, 'marks') && length(info.marks) == 3
    for i = 1:3
        [label  loc] = strread(char(info.marks(i)),'%s %s','delimiter', '=');
        markedlocs(i,:) = strread(char(loc));
    end
    MEG.locations = MEGcoRegistration(markedlocs, cstmlocations, cstmnormals);
    MEG.marks = markedlocs;
else
    errordlg('Miss landmarks.');
    return;
end
MEG.vidx = 1:MEG.nbchan;
MEG.bad = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get data
name = [name '.dat'];
Fullfilename=fullfile(pathstr,name);
fid = fopen(Fullfilename,'r');
if fid<0 
    errordlg( ['Can Not open ' Fullfilename] );
    return;
end

h = waitbar(0.5,'Reading the file, please wait...');
C_text = textscan(fid, '%s', 'delimiter', '\n');
lines = C_text{1};
fclose(fid);
close(h);

% remove the leading and trailing white-space characters of each line.
lines = strtrim(lines);

% remove comments and empty lines
lines(strmatch('%', lines)) = [];
lines = lines(~cellfun(@isempty, lines) == true);

fields = strmatch('[', lines);
numfields = length(fields);
fields(numfields+1) = length(lines) + 1;
for i = 1:numfields
    fieldname = lines(fields(i));
    fieldname = strread(char(fieldname), '[%s', 'delimiter', ']');
    fieldname = lower(fieldname);
    data.(char(fieldname)) = lines( fields(i)+1 : fields(i+1)-1 );
end

col = length(data.data);
if isfield(data, 'data') && col > 0
    row = length(str2num(data.data{1}));
    MEG.data = zeros(row, col);
    for i = 1:col
        MEG.data(:,i) = str2num(data.data{i})';
    end
    sz = size(MEG.data);
    if sz(1) ~= MEG.nbchan | sz(2) ~= MEG.points
        errordlg('The size of the data is not right!');
        return;
    end
else
    errordlg('There is no data!');
    return;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isfield(MEG,'start') | isempty(MEG.start)
    MEG.start = 1;
end

if ~isfield(MEG,'end') | isempty(MEG.end)
    MEG.end = MEG.points;
end

if ~isfield(MEG,'dispchans') | isempty(MEG.dispchans)
    MEG.dispchans = MEG.nbchan;
end

vdata = MEG.data(MEG.vidx,:);
MEG.min = min(min(vdata));
MEG.max = max(max(vdata));

MEG.labeltype = [];

% ERP analysis
if isfield(info, 'eventnames') && length(info.eventnames) > 0 && isfield(info, 'eventtime') && length(info.eventtime) > 0
    eventnum = length(info.eventnames);
    if eventnum ~= length(info.eventtime)
        errordlg('The number of event names mismatch the number of event time records');
        return;
    end
    
    for i = 1:eventnum
        MEG.event(i).name = info.eventnames{i};
        MEG.event(i).time = str2num(info.eventtime{i});
    end
    
    analysisevent = questdlg('Perform ERF analysis?','','Yes','Cancel','Cancel');
    if strcmp(analysisevent, 'Yes')
        MEG = erpanalysis(MEG);
    end
end

