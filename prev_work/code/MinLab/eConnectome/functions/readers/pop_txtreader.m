function EEG = pop_txtreader()
% pop_txtreader - read text file and return EEG structure
%
% Usage:         
%            1. type 
%               >> EEG = pop_txtreader
%               or call EEG = pop_txtreader to convert text file to EEG structure. 
%               Output: EEG - is the structure enclosing EEG data.
%               The recognizable text file format for EEG includes a '.txt'
%               head file and a '.dat' data file. The 'txt' stores information
%               including number of channels, sampling rate, number of sampling points, 
%               unit of measures, channel labels, label type and electrode
%               locations. The '.dat' file stores the time series data of the EEG.
%               Please see the eConnectome Manual 
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable text file format for EEG.
%
%            2. call EEG = pop_txtreader from the eegfc GUI ('Menu bar -> File -> Import -> TXT File'). 
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

[name pathstr]=uigetfile('*.txt', 'Select EEG File');
if name==0
    EEG = [];
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

fid = fopen(Fullfilename,'r');
if fid<0 
    EEG = [];
    errordlg( ['Can Not open ' Fullfilename] );
    return;
end

EEG = ecom_initialize;
[pathstr, name, ext, versn] = fileparts(Fullfilename);
EEG.name = name;

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
    EEG.nbchan = strread(char(info.nbchan));
else
    warndlg('Miss Number-of-Channels information.');
end

if isfield(info, 'srate') && length(info.srate) > 0
    EEG.srate = strread(char(info.srate));
else
    warndlg('Miss Sampling-Rate information.');
    EEG.srate = 250;
end

if isfield(info, 'points') && length(info.points) > 0
    EEG.points = strread(char(info.points));
else
    warndlg('Miss Number-of-Sampling-Points information.');
end

if isfield(info, 'labeltype') && length(info.labeltype) > 0
    EEG.labeltype = char(info.labeltype);
else
    warndlg('Miss Type-of-Labels information.');
    EEG.labeltype = 'standard';
end

if isfield(info, 'unit') && length(info.unit) > 0
    EEG.unit = char(info.unit);
else
    EEG.unit = 'uV';
end

% Get labels
if isfield(info, 'labels')  && length(info.labels) > 0
    if EEG.nbchan <= 0
        EEG.nbchan = length(info.labels);
    else
        if EEG.nbchan ~= length(info.labels)
                errordlg('The number of labels is not right!');
                return;
        end
    end
    EEG.labels = info.labels;
else
    errordlg('Miss Channel-Labels information.');
    return;
end

% Get locations
if strcmp(EEG.labeltype, 'standard') % Generate standard label locations if the given labels are standard.
    EEG.locations = stdLocations(EEG.labels);
    vidx = ~cellfun(@isempty, {EEG.locations(:).X});
    EEG.vidx = find(vidx==1);
else % Read customized label locations if the given labels are not standard.
    if isfield(info, 'locations') && length(info.locations) > 0
        if EEG.nbchan ~= length(info.locations)
            errordlg('The number of locations is not right!');
            return;
        end
        cstmlocations = str2num(strvcat(info.locations));
        
        if isfield(info, 'marks') && length(info.marks) == 3 % Transform customized locations to standard space with the marks.
            for i = 1:3
                [label  loc] = strread(char(info.marks(i)),'%s %s','delimiter', '=');
                stdlabels(i) = strtrim(label);
                markedlocs(i,:) = strread(char(loc));
            end
            EEG.locations = coRegistration(cstmlocations, markedlocs);
        else
            errordlg('Miss Marks information.'); % customized locations without marks not suported.
            return;
        end
        EEG.vidx = 1:EEG.nbchan;
    else       
        errordlg('Miss Customized-Channel-Locations information.'); % customized labeltype without locations not suported.
        return;
    end
end

EEG.bad = [];

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

% % read the file lines
% total = EEG.points+50;
% lines=cell(total,1);
% h = waitbar(0,'Reading the file, please wait...');
% ct = 0;
% while ~feof(fid)
%      ct = ct + 1; 
%      lines{ct} = fgetl(fid);
%      if ~mod(ct, 50)
%         waitbar(ct/total);
%      end
% end
% lines(ct+1:total) = [];
% fclose(fid);
% close(h);

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
    EEG.data = zeros(row, col);
    for i = 1:col
        EEG.data(:,i) = str2num(data.data{i})';
    end
    % EEG.data = str2num(strvcat(data.data))';
    sz = size(EEG.data);
    if sz(1) ~= EEG.nbchan | sz(2) ~= EEG.points
        errordlg('The size of the data is not right!');
        return;
    end
else
    errordlg('There is no data!');
    return;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isfield(EEG,'start') | isempty(EEG.start)
    EEG.start = 1;
end

if ~isfield(EEG,'end') | isempty(EEG.end)
    EEG.end = EEG.points;
end

if ~isfield(EEG,'dispchans') | isempty(EEG.dispchans)
    EEG.dispchans = EEG.nbchan;
end

vdata = EEG.data(EEG.vidx,:);
EEG.min = min(min(vdata));
EEG.max = max(max(vdata));

% ERP analysis
if isfield(info, 'eventnames') && length(info.eventnames) > 0 && isfield(info, 'eventtime') && length(info.eventtime) > 0
    eventnum = length(info.eventnames);
    if eventnum ~= length(info.eventtime)
        errordlg('The number of event names mismatch the number of event time records');
        return;
    end
    
    for i = 1:eventnum
        EEG.event(i).name = info.eventnames{i};
        EEG.event(i).time = str2num(info.eventtime{i});
    end
    
    analysisevent = questdlg('Perform ERP analysis?','','Yes','Cancel','Cancel');
    if strcmp(analysisevent, 'Yes')
        EEG = erpanalysis(EEG);
    end
end
