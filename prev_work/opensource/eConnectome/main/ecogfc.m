function varargout = ecogfc(varargin)
% ecogfc- the main Graphical User Interface (GUI) environment 
%  for mapping and imaging of cortical functional connectivity from ECoG
%
% Authors: 
%  Bin He, Yakang Dai, Lin Yang, and Han Yuan at the University of Minnesota, USA, 
%  with substantial contributions from Fabio Babiloni and Laura Astolfi 
%  at the University of Rome "La Sapienza", Italy, plus addition contributions 
%  from Christopher Wilke at the University of Minnesota, USA. 
% 
% Usage: 
%     1. type
%         >> ecogfc
%         to start the popup GUI
%           
%     2. call ecogfc from the main econnectome GUI ('Menu bar -> ECoG')
%
% Description:
%  ecogfc is the main GUI for ECoG functional connectivity analysis. Electrode locations 
% over the brain model can be constructed manually or generated automatically with four 
% counterclockwise corners edited and, a map surface through the electrodes over the 
% brain model can be generated automatically. Multi-channel ECoG time series corresponding 
% to the electrodes can then be imported and, after pre-processing, the cortical potential can 
% be visualized over the map surface and, cortical functional connectivity can be estimated 
% from ECoGs using the DTF method and visualized over the cortex model.
%
% Reference for eConnectome (please cite): 
% B. He, Y. Dai, L. Astolfi, F. Babiloni, H. Yuan, L. Yang. 
% eConnectome: A MATLAB Toolbox for Mapping and Imaging of Brain Functional Connectivity. 
% Journal of Neuroscience Methods. 195:261-269, 2011.
%
% Reference for ecogfc() (please cite):
% C. Wilke, W. van Drongelen, M. Kohrman, B. He. 
% Neocortical seizure foci localization by means of a directed transfer function method. 
% Epilepsia. 51(4):564-72, 2010.
%
% Reference for ADTF function, (please cite) 
% C. Wilke, L. Ding, B. He, 
% Estimation of time-varying connectivity patterns through the use of an adaptive directed transfer function. 
% IEEE Trans Biomed Eng. 2008 Nov; 55(11):2557-64.
%
% Data Format:
% To be imported in the ecogfc GUI, recorded ECoG data must be converted to a recognizable 
% format. The format includes two text files. One is '.hdr' head file and the other is '.ecog' file 
% used to store the time series data of the ECoG. Please see the eConnectome Manual 
% (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%  for details about the import ECoG file format.
%
% Brain Model:
% The cortex models used in the program are constructed based on the standard Montreal Neurological Institute 
% (MNI) brain. See below for detailed description of MNI Brain model: 
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
% Yakang Dai, 18-May-2010 15:27:30
% New functions: scale waveforms and capture image
%
% Yakang Dai, 03-May-2010 15:24:30
% Can use good channels only without interpolation
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ========================================== 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ecogfc_OpeningFcn, ...
                   'gui_OutputFcn',  @ecogfc_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ecogfc is made visible.
function ecogfc_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ecogfc (see VARARGIN)

% Choose default command line output for ecogfc
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ecogfc wait for user response (see UIRESUME)
% uiwait(handles.figureloadecog);

set(hObject,'Toolbar','figure');

hToolbar = findall(hObject,'tag','FigureToolBar');
hButtons = findall(hToolbar);
set(hButtons,'Visible','off');
toolhandle = findobj(hButtons,'tag','FigureToolBar'); % FigureToolBar
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.DataCursor'); % DataCursor
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.Rotate'); % Rotate
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.ZoomOut'); % ZoomOut
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.ZoomIn'); % ZoomIn
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.Pan'); % Pan
set(toolhandle,'Visible','on');

dcm_obj = datacursormode;
set(dcm_obj,'UpdateFcn',@myupdatefcn);
set(dcm_obj,'DisplayStyle','datatip','SnapToDataVertex','off','Enable','off');
setappdata(hObject,'dcm_obj',dcm_obj);

%% draw the head model in  3D scene axes.
load('colincortex.mat');
model.cortex = colincortex;
load('colinbrain.mat');
model.brain = colinbrain;

options.epochstart = 1;
options.epochend = 1;
setappdata(hObject,'options',options);

currentpoint = 1;
setappdata(hObject,'current',currentpoint);

display.electrodes = 1;
display.labels = 1;
display.surface = 1;
display.color = [0.6, 0.0, 0.0];
display.alpha = 1.0;
display.caxis = 'local';
setappdata(hObject,'display',display);

% axes setting
axes(handles.sceneaxes);
axis vis3d;
axcolor = get(hObject, 'color');
set(handles.sceneaxes, 'color', axcolor);
set(handles.tsaxes, 'color', axcolor);
set(handles.sceneaxes, 'DataAspectRatio',[1 1 1]);
set(handles.sceneaxes, 'userdata', model);

cla;
box off;
axis off;
hold on;

% display the cortex with different ROIs having different colors.
patch('SpecularStrength',0,'DiffuseStrength',0.8,...
'FaceLighting','phong',...
'Vertices',model.cortex.Vertices,...
'LineStyle','-',...
'Faces',model.cortex.Faces,...
'FaceColor','interp',...
'EdgeColor','none',...
'FaceVertexCData',model.cortex.FaceVertexCData);

lighting phong; %phong, gouraud
light('Position',[0 0 1],'color',[.9 .9 .9]);
light('Position',[0 -.5 -1],'color',[.9 .9 .9]);

ECOG = ecom_initialize();
ECOG.type = 'ECOG';
set(hObject, 'userdata',ECOG);

scale = 1;
setappdata(hObject,'SCALE',scale);

set(gcf,'windowbuttonmotionfcn', @mousemotionCallback);
set(gcf,'WindowButtonDownFcn', @mousebuttondownCallback); 
set(hObject,'WindowScrollWheelFcn', @mousescrollwheelCallback);

% --- Outputs from this function are returned to the command line.
function varargout = ecogfc_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --------------------------------------------------------------------
function importecogdata_Callback(hObject, eventdata, handles)
% hObject    handle to importecogdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ECOG = get(handles.figureloadecog,'userdata');
if isempty(ECOG.locations)
    helpdlg('Please build up ECOG locations!');
    return;
end
    
if ~isempty(ECOG.data)
    importevent = questdlg('Exist ECOG data, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr]=uigetfile('*.hdr','Select ECoG Head File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

fid = fopen(Fullfilename,'r','ieee-le');
if fid<0 
    errordlg( ['Can Not open ' Fullfilename] );
end

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

ECOG = get(handles.figureloadecog,'userdata');

% get lines for channels, points, etc.
lines = lower(lines);
channels_line = lines(strmatch('channels', lines)+1);
ECOG.nbchan = str2num(strvcat(channels_line));

points_line = lines(strmatch('points', lines)+1);
ECOG.points = str2num(strvcat(points_line));

srate_line = lines(strmatch('srate', lines)+1);
ECOG.srate = str2num(strvcat(srate_line));

unit_line = lines(strmatch('unit', lines)+1);
ECOG.unit = char(unit_line);

label_line_idx = strmatch('labels', lines);
eventnames_line_idx = strmatch('eventnames', lines);
eventtime_line_idx = strmatch('eventtime', lines);
if isempty(label_line_idx)
    if ~isempty(ECOG.labels)
        ECOG.labels = {};
    end
    for i = 1:ECOG.nbchan
        ECOG.labels(i) = {num2str(i)};
    end
else
    if isempty(eventnames_line_idx) && isempty(eventtime_line_idx)
        labels = lines(label_line_idx+1:length(lines));
    elseif ~isempty(eventnames_line_idx) && ~isempty(eventtime_line_idx)
        labels = lines(label_line_idx+1:eventnames_line_idx-1);
    else
        errordlg('Miss event names or time!');
        return;
    end
    
    if length(labels) ~= ECOG.nbchan
        errordlg(['The number of labels should be ' num2str(ECOG.nbchan) '!']);
        return;
    end

    ECOG.labels = upper(labels);
end

% test if it's erp data
iserp = 0;
if ~isempty(eventnames_line_idx) && ~isempty(eventtime_line_idx)
    numevent = eventtime_line_idx-eventnames_line_idx-1;
    numtime = length(lines) - eventtime_line_idx;
    if numevent~=numtime | numevent<1 | numtime<1
        errordlg('The number of event names mismatch the number of event time records');
        return;
    end
    
    eventnames = lines(eventnames_line_idx+1:eventtime_line_idx-1);
    eventtime = lines(eventtime_line_idx+1:length(lines));
    for i = 1:numevent
        ECOG.event(i).name = eventnames{i};
        ECOG.event(i).time = str2num(eventtime{i});
    end
    iserp = 1;
end   

% read ECOG data
[pathstr, name, ext, versn] = fileparts(Fullfilename);
ECOG.name = name;
addpath(pathstr);
name = [name '.ecog'];
Fullfilename=fullfile(pathstr,name);

fid = fopen(Fullfilename,'r','ieee-le');
if fid<0 
    errordlg( ['Can Not open ' Fullfilename] );
end

h = waitbar(0.5,'Reading the file, please wait...');
C_text = textscan(fid, '%s', 'delimiter', '\n');
lines = C_text{1};
fclose(fid);
close(h);

% % read the file lines
% h = waitbar(0,'Reading the file, please wait...');
% total = ECOG.points;
% ct = 0;
% lines={};
% while ~feof(fid)
%      lines = [lines; {fgetl(fid)}];
%      ct = ct + 1; 
%      if ~mod(ct, 50)
%         waitbar(ct/total);
%      end
% end
% fclose(fid);
% close(h);

% remove the leading and trailing white-space characters of each line.
lines = strtrim(lines);

% remove comments and empty lines
lines(strmatch('%', lines)) = [];
lines = lines(~cellfun(@isempty, lines) == true);

% get lines for channels, points, etc.
lines = lower(lines);

lineslen = length(lines);
if lineslen ~= ECOG.points+1
    errordlg(['The number of ECOG data points should be ' num2str(ECOG.points) '!']);
    return;
end
dataidx = strmatch('data', lines);
data_lines = lines(dataidx+1:dataidx+ECOG.points);
ECOG.data = ( str2num(strvcat(data_lines)) )';

datachan = size(ECOG.data,1);
if datachan ~= ECOG.nbchan
    errordlg(['The number of ECOG data channels should be ' num2str(ECOG.nbchan) '!']);
    ECOG.data = [];
    return;
end

len = length(ECOG.locations);
if len ~= ECOG.nbchan
    errordlg(['The number of channels should be ' num2str(len) '!']);
    return;
end

ECOG.bad = [];
ECOG.vidx = 1:ECOG.nbchan;
ECOG.min = min(min(ECOG.data));
ECOG.max = max(max(ECOG.data));

% ERP analysis
if iserp
    analysisevent = questdlg('Perform ERP analysis?','','Yes','Cancel','Cancel');
    if strcmp(analysisevent, 'Yes')
        sz = ECOG.size;
        ECOG = erpanalysis(ECOG);
        if isempty(ECOG)
            return;
        end
        ECOG.size = sz;
    end
end

set(handles.figureloadecog,'userdata',ECOG);

options = getappdata(handles.figureloadecog,'options');
options.epochstart = 1;
options.epochend = ECOG.points;
setappdata(handles.figureloadecog,'options',options);

updatewindow;

% --------------------------------------------------------------------
function importpos_Callback(hObject, eventdata, handles)
% hObject    handle to importpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ECOG = get(handles.figureloadecog,'userdata');
if ~isempty(ECOG.locations)
    importevent = questdlg('Exist ECOG locations, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr]=uigetfile('*.loc','Select ECOG Location File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

fid = fopen(Fullfilename,'r','ieee-le');
if fid<0 
    errordlg( ['Can Not open ' Fullfilename] );
end

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

% get lines for channels, points, etc.
lines = lower(lines);
lineslen = length(lines);
if ~isempty(ECOG.data) % have read ECOG data
    if lineslen ~= ECOG.nbchan+3
        errordlg('File format is not right, please check!');
        return;
    end
end

sizeidx = strmatch('size', lines);
size_lines = lines(sizeidx+1);
ECOG.size = str2num(strvcat(size_lines)) ;

locationsidx = strmatch('locations', lines);
locations_lines = lines(locationsidx+1:lineslen);
locations = str2num(strvcat(locations_lines));

posdimen = size(locations);
if posdimen(2) ~= 3
    errordlg('The number of ECOG position dimension should be 3!');
    return;
end

num = ECOG.size(1)*ECOG.size(2);
if num ~= posdimen(1)
    errordlg(['The number of ECOG positions should be ' num2str(num) '!']);
    return;
end

for i = 1:num
    ECOG.locations(i).X = locations(i,1);
    ECOG.locations(i).Y = locations(i,2);
    ECOG.locations(i).Z = locations(i,3);
end
ECOG.vidx = 1:num;
set(handles.figureloadecog,'userdata',ECOG);

% locations of the ECOG electrodes
electrodelocs.row = ECOG.size(1);
electrodelocs.column = ECOG.size(2);
electrodelocs.X = zeros(electrodelocs.row, electrodelocs.column);
electrodelocs.Y = electrodelocs.X;
electrodelocs.Z = electrodelocs.X;
k = 0;
for j = 1:electrodelocs.column
    for i = 1:electrodelocs.row
        k = k+1;
        electrodelocs.X(i,j) = ECOG.locations(k).X;
        electrodelocs.Y(i,j) = ECOG.locations(k).Y;
        electrodelocs.Z(i,j) = ECOG.locations(k).Z;
    end
end

[surflocs, electrodelocs] = getsurflocs(electrodelocs);

model = get(handles.sceneaxes, 'userdata');
vertices = model.brain.Vertices;
vertices = [vertices; model.brain.Centers];
[surflocs.X,surflocs.Y,surflocs.Z] = avgNeighbors(vertices,surflocs.X,surflocs.Y,surflocs.Z,surflocs.row,surflocs.column);

setappdata(gcf,'electrodelocs',electrodelocs);
setappdata(gcf,'surflocs',surflocs);

updatemap;

% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_showlabels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_showlabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
display = getappdata(hfig,'display');
ECOG = get(hfig,'userdata');
if isempty(ECOG.locations)
    return;
end

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    display.labels = 0;
else
    ischecked = 'on';
    display.labels = 1;
end

setappdata(hfig,'display',display);
set(hObject,'checked',ischecked);
updatemap;

% --------------------------------------------------------------------
function exportpos_Callback(hObject, eventdata, handles)
% hObject    handle to exportpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)      

ECOG = get(handles.figureloadecog,'userdata');
if isempty(ECOG.locations)
    warndlg('There is no ECOG location!');
    return;
end

[name pathstr]=uiputfile('*.loc','Save ECOG Location File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

fid = fopen(Fullfilename,'wt','ieee-le');
if fid<0 
    errordlg( ['Can Not open ' Fullfilename] );
end

fprintf(fid, 'Size = \r\n');
fprintf(fid, '%f  \t %f \r\n\n',ECOG.size);

fprintf(fid, 'Locations = \r\n');
num = length(ECOG.locations);
for i = 1:num
    fprintf(fid, '%f \t%f \t %f \n', [ECOG.locations(i).X, ECOG.locations(i).Y, ECOG.locations(i).Z]);
end
fclose(fid);

% --------------------------------------------------------------------
function Untitled_5_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function txt = myupdatefcn(empt,event_obj)

% findobj will get nothing when the user move the tip
pos = get(event_obj,'Position');
whichmodel = get(event_obj,'Target');

whichaxes = get(whichmodel,'Parent');
hfig = get(whichaxes,'Parent');
tag = get(hfig,'tag');
isfigh = strcmp(tag,'figureloadecog');
if ~isfigh
    txt = {['x=' num2str(pos(1))] ['y=' num2str(pos(2))] ['z=' num2str(pos(3))]};
    return;
end

dcm_obj = getappdata(hfig,'dcm_obj'); 
datacursors = get(dcm_obj,'DataCursors');
num = length(datacursors);

currentdatacursor = get(dcm_obj,'CurrentDataCursor');
hTextbox = get(currentdatacursor,'TextBoxHandle');

userdata = get(hTextbox,'UserData');
if isempty(userdata)
    if num == 0
        txt = [];
    else
        txt = num2str(num);
    end
    set(hTextbox,'UserData',1);
else
    txt = [];
end

% % --- Executes when user attempts to close figureloadecog.
% function figureloadecog_CloseRequestFcn(hObject, eventdata, handles)
% % hObject    handle to figureloadecog (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: delete(hObject) closes the figure
% delete(hObject);

% --------------------------------------------------------------------
function menu_clear_locs_Callback(hObject, eventdata, handles)
% hObject    handle to menu_clear_locs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMode = getuimode(gcf,'Exploration.Datacursor');
hTool = hMode.ModeStateData.DataCursorTool;
datainfo = getCursorInfo(hTool);
posnum = length(datainfo);

ECOG = get(handles.figureloadecog,'userdata');

if isempty(ECOG.locations) && posnum == 0
    return;
end

model = get(handles.sceneaxes, 'userdata');
axes(handles.sceneaxes);
cla;
hold on;

% display the cortex with different ROIs having different colors.
patch('SpecularStrength',0,'DiffuseStrength',0.8,...
'FaceLighting','phong',...
'Vertices',model.cortex.Vertices,...
'LineStyle','-',...
'Faces',model.cortex.Faces,...
'FaceColor','interp',...
'EdgeColor','none',...
'FaceVertexCData',model.cortex.FaceVertexCData);

% lighting gouraud; %phong, gouraud
light('Position',[0 0 1],'color',[.9 .9 .9]);
light('Position',[0 -.5 -1],'color',[.9 .9 .9]);

hclrbar = getappdata(handles.figureloadecog,'colorbar');
if ~isempty(hclrbar)
    delete(hclrbar);
    hclrbar = [];
    setappdata(handles.figureloadecog,'colorbar',hclrbar);
end

ECOG.locations = [];
set(handles.figureloadecog,'userdata',ECOG);

% --------------------------------------------------------------------
function menu_generate_locs_Callback(hObject, eventdata, handles)
% hObject    handle to menu_generate_locs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMode = getuimode(gcf,'Exploration.Datacursor');
hTool = hMode.ModeStateData.DataCursorTool;
datainfo = getCursorInfo(hTool);
posnum = length(datainfo);

if posnum ~= 4
    helpdlg('Please specify four corners (counter-clockwise)!');
    return;
end

for i = 1:posnum
    j = posnum - i + 1;
    locations(i,:) = datainfo(j).Position;
end

gridsize = getgridsize;
if isempty(gridsize)
    return;
end

electrodelocs.row = gridsize(1);
electrodelocs.column = gridsize(2);
[electrodelocs.X, electrodelocs.Y, electrodelocs.Z] = submesh(locations,electrodelocs.row,electrodelocs.column);

model = get(handles.sceneaxes, 'userdata');

% find points over the cortex
vertices = model.brain.Vertices;
vertices = [vertices; model.brain.Centers];
[electrodelocs.X, electrodelocs.Y, electrodelocs.Z] = avgNeighbors(vertices, electrodelocs.X, electrodelocs.Y, electrodelocs.Z,... 
                                                                   electrodelocs.row, electrodelocs.column);

[electrodelocs.X, electrodelocs.Y, electrodelocs.Z] = smoothlocs(electrodelocs.X,electrodelocs.Y,electrodelocs.Z,... 
                                                                 electrodelocs.row,electrodelocs.column);                                                               

% locations of the ECOG electrodes
ECOG = get(handles.figureloadecog,'userdata');
ECOG.size = [electrodelocs.row,electrodelocs.column];
k = 0;
for j = 1:electrodelocs.column
    for i = 1:electrodelocs.row
        k = k+1;
        ECOG.locations(k).X = electrodelocs.X(i,j);
        ECOG.locations(k).Y = electrodelocs.Y(i,j);
        ECOG.locations(k).Z = electrodelocs.Z(i,j);
    end
end
ECOG.vidx = 1 : electrodelocs.row*electrodelocs.column;
set(handles.figureloadecog,'userdata',ECOG);

[surflocs, electrodelocs] = getsurflocs(electrodelocs);

[surflocs.X,surflocs.Y,surflocs.Z] = avgNeighbors(vertices,surflocs.X,surflocs.Y,surflocs.Z,surflocs.row,surflocs.column);

setappdata(gcf,'electrodelocs',electrodelocs);
setappdata(gcf,'surflocs',surflocs);

updatemap;

% --------------------------------------------------------------------
function popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function updatewindow()

hfig = gcf;
ECOG = get(hfig,'userdata');
if isempty(ECOG.data)
    helpdlg('Please import ECOG data!');
    return;
end

scale = getappdata(hfig,'SCALE');

xlimit = ECOG.points;
xlabelstep = round(xlimit/10);
    
% x labels
xlabelpositions = [0:xlabelstep:xlimit];
xlabels = [0:xlabelstep:xlimit]/ECOG.srate;
xlabels = num2str(xlabels');
     
% y labels
channelmaxs = max(ECOG.data,[ ],2);
channelmins = min(ECOG.data,[ ],2);    
spacing = mean(channelmaxs-channelmins);  
ylimit = (ECOG.nbchan+1)*spacing;
ylabelpositions = [0:spacing:ECOG.nbchan*spacing];    
YLabels = ECOG.labels;
YLabels = strvcat(YLabels); 
YLabels = flipud(str2mat(YLabels,' '));

tsaxes = findobj(hfig,'tag','tsaxes');
axes(tsaxes);     
set(tsaxes,...
      'Xlim',[0 xlimit],...
      'xtick',xlabelpositions,...% where to display the labels.
      'XTickLabel', xlabels,...
      'Ylim',[0 ylimit],...
      'YTick',ylabelpositions,...
      'YTickLabel', YLabels); % the labels to be displayed
cla;        
hold on;

badcolor = [1.0,0.0,0.0];
goodcolor = [0.0,0.0,1.0];
for i = 1:ECOG.nbchan
    chan = ECOG.nbchan-i+1;
    isbad = find(ECOG.bad==chan);
    if isbad
        tmpcolor = badcolor;
    else
        tmpcolor = goodcolor;
    end
    
    meandata = mean(ECOG.data(chan,:));
    data = ECOG.data(chan,:) - meandata;
    plot(scale*data+i*spacing,'color', tmpcolor, 'clipping','on');
    
    % plot(scale*ECOG.data(chan,:) +i*spacing, 'color', tmpcolor, 'clipping', 'on');
end 

options = getappdata(hfig,'options');
ypos = [0, ylimit];
xpos = [options.epochstart, options.epochstart];
tmpcolor = [0.0,0.0,1.0];
linehandle = findobj(hfig,'tag','leftline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end
    
xpos = [options.epochend, options.epochend];
tmpcolor = [1.0,0.0,0.0];
linehandle = findobj(hfig,'tag','rightline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end


function mousemotionCallback(src, evnt) 

hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
currentxlim = get(tsaxes, 'Xlim');
currentylim = get(tsaxes, 'Ylim');
mousepos = get(tsaxes, 'currentpoint');

if isempty(mousepos)
    return;
end

% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
    return;
end

ECOG = get(hfig,'userdata');
if isempty(ECOG.data)
    return;
end

currentpoint = round(mousepos(1,1));%find the nearest point.
if currentpoint < 1 | currentpoint > ECOG.points
    return;
end
currenttime = currentpoint / ECOG.srate;

channelmaxs = max(ECOG.data,[ ],2);
channelmins = min(ECOG.data,[ ],2);
spacing = mean(channelmaxs-channelmins);
currentchannel = round( (currentylim(1,2) - mousepos(1,2) ) / spacing );%find the nearest channel.
if currentchannel < 1 | currentchannel > ECOG.nbchan
    return;
end

currentlabel = char(ECOG.labels(currentchannel));

currentvalue = ECOG.data(currentchannel, currentpoint);

axes(tsaxes);
xpos = [currentpoint,  currentpoint];
ypos = [currentylim(1,1),  currentylim(1,2)];
tmpcolor = [ 0.0 1.0 0.0 ];

linehandle = findobj(hfig,'tag','linetag');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'linetag');
else
    set(linehandle,'xdata',xpos,'ydata',ypos);
    drawnow;
end

scale = getappdata(hfig,'SCALE');

% the i th channel displayed
i = ECOG.nbchan - currentchannel + 1;
x = xpos(1);
currentvalue = currentvalue - mean(ECOG.data(currentchannel,:));
y = scale*currentvalue+i*spacing;
pointhandle = findobj(hfig,'tag','pointhandle');
if isempty(pointhandle)
    plot(x,y,'mo','MarkerFaceColor',[0.49,1.0,0.63],'MarkerSize',8,'EraseMode', 'xor','tag', 'pointhandle');
else
    set(pointhandle,'xdata',x,'ydata',y);
    drawnow;
end

textlabel = findobj(hfig,'tag','textlabel'); 
textpoint = findobj(hfig,'tag','textpoint'); 
texttime = findobj(hfig,'tag','texttime'); 
textvalue = findobj(hfig,'tag','textvalue'); 

set(textlabel,'string', ['Label: ' currentlabel]);
set(textpoint,'string', ['Point: ' num2str(currentpoint)]);
set(texttime,'string', ['Time: ' num2str(currenttime) ' s']);
set(textvalue,'string', ['Value: '  num2str(currentvalue) ' ' ECOG.unit]);

function mousebuttondownCallback(src, evnt) 
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
currentxlim = get(tsaxes, 'Xlim');
currentylim = get(tsaxes, 'Ylim');
mousepos = get(tsaxes, 'currentpoint');
     
% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
   mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
       return;
end

ECOG = get(hfig,'userdata');
if isempty(ECOG.data)
    return;
end
if isempty(ECOG.locations)
    warndlg('There is no ECOG location!');
    return;
end

linehandle = findobj(hfig,'tag','linetag');
if isempty(linehandle)
    return;
end
xpos =  get(linehandle,'xdata');
ypos = [currentylim(1,1),  currentylim(1,2)];
currentpoint = xpos(1,1);

selectype = get(hfig,'SelectionType');

% 'normal': left click
if strcmp(selectype,'normal')
    tmpcolor = [0.0,0.0,0.0];
    linehandle = findobj(hfig,'tag','currentline');
    if isempty(linehandle)
        plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'currentline');
    else
       set(linehandle,'xdata',xpos,'ydata',ypos);
       drawnow;
    end
    
    setappdata(hfig,'current',currentpoint);
    
    set(hfig,'CurrentAxes',tsaxes);
    updatemap;
    drawnow expose;    
    return;
    
    tmpcolor = [0.0,0.0,1.0];
    linehandle = findobj(hfig,'tag','leftline');
    if isempty(linehandle)
        plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
    else
       set(linehandle,'xdata',xpos,'ydata',ypos);
       drawnow;
    end
   
    options = getappdata(hfig,'options');
    options.epochstart = currentpoint;
    setappdata(hfig,'options',options);
    setappdata(hfig,'current',currentpoint);
    
    set(hfig,'CurrentAxes',tsaxes);
    updatemap;
    drawnow expose;    
    return;
end

% 'alt': select epoch
if strcmp(selectype,'alt')    
    popmenu_tsaxes = findobj(hfig, 'tag','popmenu_tsaxes');
    position = get(hfig,'CurrentPoint');
    set(popmenu_tsaxes,'position',position);
    set(popmenu_tsaxes,'Visible','on');
    set(hfig,'Visible','on');
    return;
end 

%--------------------------------------------------------------------------
function mousescrollwheelCallback(src, evnt)
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
currentxlim = get(tsaxes, 'Xlim');
currentylim = get(tsaxes, 'Ylim');
mousepos = get(tsaxes, 'currentpoint');
     
% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
   mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
       return;
end
     
ECOG = get(hfig,'userdata');
if isempty(ECOG.data)
    return;
end
if isempty(ECOG.locations)
    warndlg('There is no ECOG location!');
    return;
end

scale = getappdata(hfig,'SCALE');
if evnt.VerticalScrollCount < 0 
    scale = scale + 0.25;
elseif evnt.VerticalScrollCount > 0
    scale = scale - 0.25;
    if scale < 0
        return;
    end
end
setappdata(hfig,'SCALE',scale);
updatewindow;

% --------------------------------------------------------------------
function menu_use_edited_locs_Callback(hObject, eventdata, handles)
% hObject    handle to menu_use_edited_locs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMode = getuimode(gcf,'Exploration.Datacursor');
hTool = hMode.ModeStateData.DataCursorTool;
datainfo = getCursorInfo(hTool);
posnum = length(datainfo);

if posnum == 0
    warndlg('Please edit electrode locations!');
    return;
end

% if posnum < 9
%     warndlg('Number of electrodes must be larger than 9!');
%     return;
% end

hfig = gcf;
ECOG = get(hfig,'userdata');
if ~isempty(ECOG.data)
    if ECOG.nbchan ~= posnum
        errordlg(['The number of electrode locations edited should be ' num2str(ECOG.nbchan) '!']);
        return;
    end
end

for i = 1:posnum
    j = posnum - i + 1;
    locations(i,:) = datainfo(j).Position;
end

gridsize = getgridsize;
if isempty(gridsize)
    return;
end

electrodelocs.row = gridsize(1);
electrodelocs.column = gridsize(2);
electrodelocs.X = zeros(electrodelocs.row,electrodelocs.column);
electrodelocs.Y = electrodelocs.X;
electrodelocs.Z = electrodelocs.X;
for j = 1:electrodelocs.column
    for i = 1:electrodelocs.row
        idx = (j-1)*electrodelocs.row + i;
        electrodelocs.X(i,j) = locations(idx,1);
        electrodelocs.Y(i,j) = locations(idx,2);
        electrodelocs.Z(i,j) = locations(idx,3);
    end
end

model = get(handles.sceneaxes, 'userdata');

% find points over the cortex
vertices = model.brain.Vertices;
vertices = [vertices; model.brain.Centers];
[electrodelocs.X, electrodelocs.Y, electrodelocs.Z] = avgNeighbors(vertices, electrodelocs.X, electrodelocs.Y, electrodelocs.Z,... 
                                                                   electrodelocs.row, electrodelocs.column);

[electrodelocs.X, electrodelocs.Y, electrodelocs.Z] = smoothlocs(electrodelocs.X,electrodelocs.Y,electrodelocs.Z,... 
                                                                 electrodelocs.row,electrodelocs.column);                                                               

% locations of the ECOG electrodes
ECOG.size = [electrodelocs.row,electrodelocs.column];
k = 0;
for j = 1:electrodelocs.column
    for i = 1:electrodelocs.row
        k = k+1;
        ECOG.locations(k).X = electrodelocs.X(i,j);
        ECOG.locations(k).Y = electrodelocs.Y(i,j);
        ECOG.locations(k).Z = electrodelocs.Z(i,j);
    end
end
ECOG.vidx = 1 : electrodelocs.row*electrodelocs.column;
set(handles.figureloadecog,'userdata',ECOG);

[surflocs, electrodelocs] = getsurflocs(electrodelocs);

[surflocs.X,surflocs.Y,surflocs.Z] = avgNeighbors(vertices,surflocs.X,surflocs.Y,surflocs.Z,surflocs.row,surflocs.column);

setappdata(gcf,'electrodelocs',electrodelocs);
setappdata(gcf,'surflocs',surflocs);

updatemap;

% --------------------------------------------------------------------
function exportecog_Callback(hObject, eventdata, handles)
% hObject    handle to exportecog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ECOG = get(handles.figureloadecog,'userdata');
if isempty(ECOG.data)
    errordlg('There is no ECOG data!');
    return;
end    
    
if isempty(ECOG.locations)
    errordlg('There is no ECOG location!');
    return;
end

len = length(ECOG.locations);
if len ~= ECOG.nbchan
    errordlg('ECOG locations and data do not match!');
    return;
end

[name pathstr]=uiputfile('*.mat','Save ECOG File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

save(Fullfilename, 'ECOG');


% --------------------------------------------------------------------
function importecog_Callback(hObject, eventdata, handles)
% hObject    handle to importecog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ECOG = get(handles.figureloadecog,'userdata');
    
if ~isempty(ECOG.data) | ~isempty(ECOG.locations)
    importevent = questdlg('Exist ECOG, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr]=uigetfile('*.mat','Select ECOG File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

ecogdata = load(Fullfilename);
if ~isfield(ecogdata,'ECOG')
    errordlg('The imported is not ECOG structure!');
    return;
end

ECOG = ecogdata.ECOG;

% ERP analysis
if isfield(ECOG, 'event') && length(ECOG.event) > 0    
    analysisevent = questdlg('Perform ERP analysis?','','Yes','Cancel','Cancel');
    if strcmp(analysisevent, 'Yes')
        sz = ECOG.size;
        ECOG = erpanalysis(ECOG);
        if isempty(ECOG)
            return;
        end
        ECOG.size = sz;
    end
end

set(handles.figureloadecog,'userdata',ECOG);
options = getappdata(handles.figureloadecog,'options');
options.epochstart = 1;
options.epochend = ECOG.points;
setappdata(handles.figureloadecog,'options',options);

% locations of the ECOG electrodes
electrodelocs.row = ECOG.size(1);
electrodelocs.column = ECOG.size(2);
electrodelocs.X = zeros(electrodelocs.row, electrodelocs.column);
electrodelocs.Y = electrodelocs.X;
electrodelocs.Z = electrodelocs.X;
k = 0;
for j = 1:electrodelocs.column
    for i = 1:electrodelocs.row
        k = k+1;
        electrodelocs.X(i,j) = ECOG.locations(k).X;
        electrodelocs.Y(i,j) = ECOG.locations(k).Y;
        electrodelocs.Z(i,j) = ECOG.locations(k).Z;
    end
end

[surflocs, electrodelocs] = getsurflocs(electrodelocs);

model = get(handles.sceneaxes, 'userdata');
vertices = model.brain.Vertices;
vertices = [vertices; model.brain.Centers];
[surflocs.X,surflocs.Y,surflocs.Z] = avgNeighbors(vertices,surflocs.X,surflocs.Y,surflocs.Z,surflocs.row,surflocs.column);

setappdata(gcf,'electrodelocs',electrodelocs);
setappdata(gcf,'surflocs',surflocs);

updatemap;

% to update window
updatewindow;

% function [X,Y,Z] = submesh(locations,row,column)
% X = zeros(row,column);
% Y = X;
% Z = X;
% 
% % left top
% X(1,1) = locations(1,1);
% Y(1,1) = locations(1,2);
% Z(1,1) = locations(1,3);
% 
% % left bottom
% X(row,1) = locations(2,1);
% Y(row,1) = locations(2,2);
% Z(row,1) = locations(2,3);
% 
% % right bottom
% X(row,column) = locations(3,1);
% Y(row,column) = locations(3,2);
% Z(row,column) = locations(3,3);
% 
% % right top
% X(1,column) = locations(4,1);
% Y(1,column) = locations(4,2);
% Z(1,column) = locations(4,3);
% 
% % generate first and last columns
% j = 1;
% interval = (locations(2,:)-locations(1,:))/(row-1);
% for i = 2:row-1
%     pos = locations(1,:)+(i-1)*interval;
%     X(i,j) = pos(1);
%     Y(i,j) = pos(2);
%     Z(i,j) = pos(3);
% end
% j = column;
% interval = (locations(3,:)-locations(4,:))/(row-1);
% for i = 2:row-1
%     pos = locations(4,:)+(i-1)*interval;
%     X(i,j) = pos(1);
%     Y(i,j) = pos(2);
%     Z(i,j) = pos(3);
% end
% 
% % generate each rows
% for i = 1:row
%     interval = ([X(i,column),Y(i,column),Z(i,column)]-[X(i,1),Y(i,1),Z(i,1)]) / (column-1);
%     for j = 2:column-1
%         pos = [X(i,1),Y(i,1),Z(i,1)] + (j-1)*interval;
%         X(i,j) = pos(1);
%         Y(i,j) = pos(2);
%         Z(i,j) = pos(3);
%     end
% end

% function [X,Y,Z] = avgNeighbors(vertices,X,Y,Z,row,column)
% n = 20;
% for j = 1:column
%     for i = 1:row
%         location = [X(i,j),Y(i,j),Z(i,j)];
%         
%         % use the average location of neighboring vertices 
%         dists = sqrt( (vertices(:,1)-location(1)).^2 + (vertices(:,2)-location(2)).^2 + (vertices(:,3)-location(3)).^2 );
%         [dists,idx] = sort(dists);
%         pos = mean(vertices(idx(1:n),:));
%         X(i,j) = pos(1);
%         Y(i,j) = pos(2);
%         Z(i,j) = pos(3);
%     end
% end

function [X, Y, Z] = smoothlocs(X,Y,Z,row,column)    
Xp = X;
Yp = Y;
Zp = Z;

% first and last columns
for j = [1,column]
    for i = 2:row-1
        pos1 = [Xp(i-1,j),Yp(i-1,j),Zp(i-1,j)];
        pos2 = [Xp(i+1,j),Yp(i+1,j),Zp(i+1,j)];
        pos = (pos1+pos2)/2;
        dir = pos/norm(pos);
        len = norm([Xp(i,j),Yp(i,j),Zp(i,j)]);
        newpos = dir * len;
        X(i,j) = newpos(1);
        Y(i,j) = newpos(2);
        Z(i,j) = newpos(3);
    end
end

% first and last rows
for i = [1,row]
    for j = 2:column-1
        pos1 = [Xp(i,j-1),Yp(i,j-1),Zp(i,j-1)];
        pos2 = [Xp(i,j+1),Yp(i,j+1),Zp(i,j+1)];
        pos = (pos1+pos2)/2;
        dir = pos/norm(pos);
        len = norm([Xp(i,j),Yp(i,j),Zp(i,j)]);
        newpos = dir * len;
        X(i,j) = newpos(1);
        Y(i,j) = newpos(2);
        Z(i,j) = newpos(3);
    end
end

% inner points
for i = 2:row-1
    for j = 2:column-1
        pos1 = [Xp(i,j-1),Yp(i,j-1),Zp(i,j-1)];
        pos2 = [Xp(i,j+1),Yp(i,j+1),Zp(i,j+1)];
        pos3 = [Xp(i-1,j),Yp(i-1,j),Zp(i-1,j)];
        pos4 = [Xp(i+1,j),Yp(i+1,j),Zp(i+1,j)];        
        pos = (pos1+pos2+pos3+pos4)/4;
        dir = pos/norm(pos);
        len = norm([Xp(i,j),Yp(i,j),Zp(i,j)]);
        newpos = dir * len;
        X(i,j) = newpos(1);
        Y(i,j) = newpos(2);
        Z(i,j) = newpos(3);
    end
end


function gridsize = getgridsize()
prompt = {'Enter grid size (rows columns), current is:'};
dlg_title = 'Input grid size for generating locations';
num_lines = 1;
def = {num2str([3 3])};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    gridsize = [];
    return;
end

gridsize = str2num(cell2mat(answer));

if isempty(gridsize)
    warndlg('Input must be numeric!');
    gridsize = [];
    return;
end

if length(gridsize)~=2
    warndlg('Please input the row size and column size!');
    gridsize = [];
    return;
end

% if gridsize(1)<3 | gridsize(2)<3
%     warndlg('Row size and column size must be larger than 2!');
%     gridsize = [];
%     return;
% end

% % generate surflocs with electrodelocs
% function [surflocs, electrodelocs] = getsurflocs(electrodelocs)
% subsize = [5,5];
% surflocs.row = (subsize(1)-1)*(electrodelocs.row-1)+1;
% surflocs.column = (subsize(2)-1)*(electrodelocs.column-1)+1;
% surflocs.X = zeros(surflocs.row,surflocs.column);
% surflocs.Y = surflocs.X;
% surflocs.Z = surflocs.X;
% 
% % indices in surflocs for electrodes
% electrodelocs.rowindex = ([1:electrodelocs.row]-1)*(subsize(1)-1)+1;
% electrodelocs.columnindex = ([1:electrodelocs.column]-1)*(subsize(2)-1)+1;
% 
% for j = 1:electrodelocs.column-1
%     for i = 1:electrodelocs.row-1
%         locations(1,:) = [electrodelocs.X(i,j), electrodelocs.Y(i,j), electrodelocs.Z(i,j)];
%         locations(2,:) = [electrodelocs.X(i+1,j), electrodelocs.Y(i+1,j), electrodelocs.Z(i+1,j)];
%         locations(3,:) = [electrodelocs.X(i+1,j+1), electrodelocs.Y(i+1,j+1), electrodelocs.Z(i+1,j+1)];
%         locations(4,:) = [electrodelocs.X(i,j+1), electrodelocs.Y(i,j+1), electrodelocs.Z(i,j+1)];
%         [subX,subY,subZ] = submesh(locations,subsize(1),subsize(2));
%         ip = electrodelocs.rowindex(i);
%         jp = electrodelocs.columnindex(j);
%         ip1 = ip+subsize(1)-1;
%         jp1 = jp+subsize(2)-1;
%         surflocs.X(ip:ip1,jp:jp1) = subX;
%         surflocs.Y(ip:ip1,jp:jp1) = subY; 
%         surflocs.Z(ip:ip1,jp:jp1) = subZ;
%     end
% end

%--------------------------------------------------------------------------
function updatemap()
hfig =gcf;
sceneaxes = findobj(hfig,'tag','sceneaxes'); 
tsaxes = findobj(hfig,'tag','tsaxes'); 

display = getappdata(hfig,'display');
model = get(sceneaxes, 'userdata');
ECOG = get(hfig,'userdata');

if display.surface
    if ~isempty(ECOG.data)
        currentpoint = getappdata(hfig,'current');
        electrV = ECOG.data(:,currentpoint);
        electrV(ECOG.bad) = min(electrV(ECOG.vidx));
        electrodelocs = getappdata(hfig,'electrodelocs');
        surflocs = getappdata(hfig,'surflocs');
        y = electrodelocs.rowindex;
        x = electrodelocs.columnindex;
        [X,Y] = meshgrid(x,y);
        V = reshape(electrV,electrodelocs.row,electrodelocs.column);
        yi = [1:surflocs.row];
        xi = [1:surflocs.column];
        [XI,YI] = meshgrid(xi,yi);
        VI = interp2(X,Y,V,XI,YI);
    else
        surflocs = getappdata(hfig,'surflocs');
    end
end

axes(sceneaxes);
cla;
hold on;

% display the cortex.
patch('SpecularStrength',0,'DiffuseStrength',0.8,...
'FaceLighting','phong',...
'Vertices',model.cortex.Vertices,...
'LineStyle','-',...
'Faces',model.cortex.Faces,...
'FaceColor','interp',...
'EdgeColor','none',...
'FaceVertexCData',model.cortex.FaceVertexCData);

% draw ECOG covered surface
if display.surface
    if ~isempty(ECOG.data)
        hclrbar = getappdata(hfig,'colorbar');
        if ~isempty(hclrbar)
            delete(hclrbar);
        end
        
        if isequal(display.caxis, 'global')
            minV = ECOG.min;
            maxV = ECOG.max;
        else
            minV = min(min(VI));
            maxV = max(max(VI));
        end
%         absV = max(abs(minV), abs(maxV));
%         minV = -absV;
%         maxV = absV;
            
        caxis([minV, maxV]);
        surface(surflocs.X,surflocs.Y,surflocs.Z,VI,...
            'SpecularStrength',0.2,'DiffuseStrength',0.8,...
            'FaceLighting','phong','FaceColor','interp',...
            'EdgeColor','none','FaceAlpha',display.alpha);
        hclrbar = colorbar('peer',sceneaxes,'location', 'WestOutside');
        setappdata(hfig,'colorbar',hclrbar);
    else
        surface(surflocs.X,surflocs.Y,surflocs.Z,'EdgeColor','none','FaceColor','b','FaceAlpha',display.alpha );
    end
end

k = length(ECOG.vidx);

% draw electrodes
if display.electrodes
    siz = 2;
    [hx3d, hy3d, hz3d] = sphere(50);
    hx3d = hx3d * siz;
    hy3d = hy3d * siz;
    hz3d = hz3d * siz;
    for i = 1:k
        j = ECOG.vidx(i);
        location = [ECOG.locations(j).X,ECOG.locations(j).Y,ECOG.locations(j).Z];
        hx3dp = hx3d + location(1);
        hy3dp = hy3d + location(2);
        hz3dp = hz3d + location(3);
        surf(hx3dp, hy3dp, hz3dp,'EdgeColor', 'none','FaceColor',display.color);
    end
end

% draw labels
if display.labels
    for i = 1:k
        j = ECOG.vidx(i);
        location = [ECOG.locations(j).X,ECOG.locations(j).Y,ECOG.locations(j).Z];
        if ~isempty(ECOG.data)
            label = char(ECOG.labels(j));
        else
            label = num2str(i);
        end
        textlocation = location*1.1;
        text(textlocation(1), textlocation(2), textlocation(3),label,'FontSize',10,'FontWeight','bold','HorizontalAlignment','center','color','k');
    end
end
    
lighting phong; % phong, gouraud
light('Position',[0 0 1],'color',[.9 .9 .9]);
light('Position',[0 -.5 -1],'color',[.9 .9 .9]);

drawnow expose;
axes(tsaxes);

% --------------------------------------------------------------------
function menu_showelectrodes_Callback(hObject, eventdata, handles)
% hObject    handle to menu_showelectrodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
display = getappdata(hfig,'display');
ECOG = get(hfig,'userdata');
if isempty(ECOG.locations)
    return;
end

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    display.electrodes = 0;
else
    ischecked = 'on';
    display.electrodes = 1;
end

setappdata(hfig,'display',display);
set(hObject,'checked',ischecked);
updatemap;

% --------------------------------------------------------------------
function menu_showsurface_Callback(hObject, eventdata, handles)
% hObject    handle to menu_showsurface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
display = getappdata(hfig,'display');
ECOG = get(hfig,'userdata');
if isempty(ECOG.locations)
    return;
end

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    display.surface = 0;
else
    ischecked = 'on';
    display.surface = 1;
end

setappdata(hfig,'display',display);
set(hObject,'checked',ischecked);
updatemap;


% --------------------------------------------------------------------
function popmenu_tsaxes_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu_tsaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function munu_bad_Callback(hObject, eventdata, handles)
% hObject    handle to munu_bad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ECOG = get(hfig,'userdata');
labels = lower(ECOG.labels);
channelname = lower(get(handles.textlabel,'string'));
channelname = strtok(channelname, 'label: ');
idx1 = strmatch(channelname,labels,'exact');

idx2 = find(ECOG.bad==idx1); % if it is a bad chnnel
if isempty(idx2) % good channel, change to bad
    ECOG.bad(length(ECOG.bad)+1) = idx1;
    ECOG.bad = sort(ECOG.bad);
    idx2 = find(ECOG.vidx==idx1); % remove it from good channels
    ECOG.vidx(idx2) = [];    
else % bad channel, change to good
    ECOG.bad(idx2) = [];
    ECOG.vidx(length(ECOG.vidx)+1) = idx1; % add it to good channels
    ECOG.vidx = sort(ECOG.vidx);      
end
set(hfig,'userdata',ECOG);
updatewindow;

% --------------------------------------------------------------------
function menu_timefrequency_Callback(hObject, eventdata, handles)
% hObject    handle to menu_timefrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ECOG = get(hfig,'userdata');
labels = lower(ECOG.labels);
channelname = lower(get(handles.textlabel,'string'));
channelname = strtok(channelname, 'label: ');
idx = strmatch(channelname,labels,'exact');

options = getappdata(hfig,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),ECOG.points);
endpoint = min(max(endpoint,1),ECOG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

ts = ECOG.data(idx,startpoint:endpoint);
srate = ECOG.srate;
starttime = (startpoint - 1)/ECOG.srate;
pos = get(hfig,'CurrentPoint');

% compute and visualize time-frequency
time_frequency(ts, srate, starttime, pos, channelname);

% --------------------------------------------------------------------
function menu_interp_bad_chan_Callback(hObject, eventdata, handles)
% hObject    handle to menu_interp_bad_chan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ECOG = get(hfig,'userdata');
if isempty(ECOG.bad)
    warndlg('There is no bad channel !');
    return;
end
distrib = reshape([1:ECOG.nbchan],ECOG.size);

numvidx = length(ECOG.vidx);
X = zeros(numvidx,2);
for k = 1:numvidx
    idx = ECOG.vidx(k);
    [X(k,1), X(k,2)] = find(distrib==idx);
end

numbad = length(ECOG.bad);
XI = zeros(numbad,2);
n = 4;
for k = 1:numbad
    idx = ECOG.bad(k);
    [XI(k,1), XI(k,2)] = find(distrib==idx);
    
    dists = sqrt( (X(:,1)-XI(k,1)).^2 + (X(:,2)-XI(k,2)).^2);
    [dists,idxs] = sort(dists);
    idxs_N =  ECOG.vidx(idxs(1:n));
    dists_N = (dists(1:n)).^2;
    coefs_N = 1 ./ dists_N;
    coefs_N = coefs_N / sum(coefs_N);
    
    ECOG.data(idx,:) = coefs_N' * ECOG.data(idxs_N,:);
end

ECOG.vidx = 1:ECOG.nbchan;
ECOG.bad = [];
ECOG.min = min(min(ECOG.data));
ECOG.max = max(max(ECOG.data));

set(hfig,'userdata',ECOG);
updatewindow;

% --------------------------------------------------------------------
function menu_preprocessing_Callback(hObject, eventdata, handles)
% hObject    handle to menu_preprocessing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function menu_baseline_Callback(hObject, eventdata, handles)
% hObject    handle to menu_baseline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ECOG = get(hfig,'userdata');

if isempty(ECOG) | isempty(ECOG.data)
    helpdlg('No ECOG data!');
    return;
end    

options = getappdata(hfig,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),ECOG.points);
endpoint = min(max(endpoint,1),ECOG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

starttime = startpoint / ECOG.srate;
endtime = endpoint / ECOG.srate;

prompt = {'Enter the start and end time (s), current is:'};
dlg_title = 'Input epoch for baseline correction';
num_lines = 1;
def = {num2str([starttime  endtime])};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

startend = str2num(cell2mat(answer));

if isempty(startend)
    warndlg('Input must be numeric!');
    return;
end

if length(startend)~=2
    warndlg('Please input the start and end time!');
    return;
end

% reconfirm
startpoint = round(startend(1) * ECOG.srate);
endpoint = round(startend(2) * ECOG.srate);

startpoint = min(max(startpoint,1),ECOG.points);
endpoint = min(max(endpoint,1),ECOG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not roght!');
    return;
end

epochdata = ECOG.data(:,startpoint:endpoint);
meandata = mean(epochdata,2);

ECOG.data = ECOG.data - repmat(meandata,1,ECOG.points);
data1 = ECOG.data(ECOG.vidx,:);
ECOG.min = min(min(data1));
ECOG.max = max(max(data1));
set(hfig,'userdata',ECOG);
updatewindow;

% --------------------------------------------------------------------
function menu_filter_Callback(hObject, eventdata, handles)
% hObject    handle to menu_filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ECOG = get(hfig,'userdata');

if isempty(ECOG) | isempty(ECOG.data)
    helpdlg('No ECOG data!');
    return;
end    

% use uiwait and uiresume to get input parameters from the pop figure. 
data = pop_filter(ECOG.data, ECOG.srate);

if isempty(data)
    return;
end

ECOG.data = data;
data1 = ECOG.data(ECOG.vidx,:);
ECOG.min = min(min(data1));
ECOG.max = max(max(data1));
set(hfig,'userdata',ECOG);
updatewindow;


% --------------------------------------------------------------------
function menu_changealpha_Callback(hObject, eventdata, handles)
% hObject    handle to menu_changealpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig =gcf;
display = getappdata(hfig,'display');
ECOG = get(hfig,'userdata');
if isempty(ECOG.locations)
    return;
end

prompt = {'Enter transparency value (0~1), current is:'};
dlg_title = 'Input transparency for surface';
num_lines = 1;
def = {num2str(display.alpha)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

display.alpha = str2num(cell2mat(answer));

if isempty(display.alpha)
    warndlg('Input must be numeric!');
    return;
end

if length(display.alpha)~=1
    warndlg('Please input single value!');
    return;
end

display.alpha = max(0.0, min(1.0, display.alpha));

setappdata(hfig,'display',display);
updatemap;


% --------------------------------------------------------------------
function menu_connectivities_Callback(hObject, eventdata, handles)
% hObject    handle to menu_connectivities (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_dtfcomputation_Callback(hObject, eventdata, handles)
% hObject    handle to menu_dtfcomputation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ECOG = get(hfig,'userdata');
options = getappdata(hfig,'options');
if isempty(ECOG.data) | isempty(ECOG.locations)
    helpdlg('There is no complete ECOG data!');
    return;
end
ECOG.data = ECOG.data(ECOG.vidx,options.epochstart:options.epochend);

output = pop_dtf_computation(ECOG.data, ECOG.srate);

if isempty(output.dtfmatrixs)
    return;
end
% dtfmatrixs = zeros(ECOG.nbchan,ECOG.nbchan,size(output.dtfmatrixs,3));
% dtfmatrixs(ECOG.vidx,ECOG.vidx,:) = output.dtfmatrixs;

% labels = {};
% centers = zeros(ECOG.nbchan,3);
% for i = 1:ECOG.nbchan
%     labels = [labels; ECOG.labels(i)];
%     centers(i,1) = ECOG.locations(i).X;
%     centers(i,2) = ECOG.locations(i).Y;
%     centers(i,3) = ECOG.locations(i).Z;
% end
% 
% DTF.labels = labels;
% DTF.vertices = [];
% DTF.locations = centers;
% DTF.frequency = output.frequency;
% DTF.matrix = output.dtfmatrixs;
% DTF.type = 'Single Point';

labels = {};
good_chans = length(ECOG.vidx);
centers = zeros(good_chans,3);
for i = 1:good_chans
    labels = [labels; num2str(i)];
    centers(i,1) = ECOG.locations( ECOG.vidx(i) ).X;
    centers(i,2) = ECOG.locations( ECOG.vidx(i) ).Y;
    centers(i,3) = ECOG.locations( ECOG.vidx(i) ).Z;
end

DTF.labels = labels;
DTF.vertices = [];
DTF.locations = centers;
DTF.isadtf = output.isadtf;
DTF.srate = output.srate;
DTF.frequency = output.frequency;
DTF.matrix = output.dtfmatrixs;
DTF.type = 'Single Point';

pop_cortex(DTF);

% --------------------------------------------------------------------
function menu_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pop_cortex;


% --------------------------------------------------------------------
function menu_changecolor_Callback(hObject, eventdata, handles)
% hObject    handle to menu_changecolor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig =gcf;
display = getappdata(hfig,'display');
ECOG = get(hfig,'userdata');
if isempty(ECOG.locations)
    return;
end

prompt = {'Enter electrode color (RGB), current is:'};
dlg_title = 'Input color for electrodes';
num_lines = 1;
def = {num2str(display.color)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

display.color = str2num(cell2mat(answer));

if isempty(display.color)
    warndlg('Input must be numeric!');
    return;
end

if length(display.color)~=3
    warndlg('Please input RGB values!');
    return;
end

display.color = max(0.0, min(1.0, display.color));

setappdata(hfig,'display',display);
updatemap;


% --------------------------------------------------------------------
function menu_global_Callback(hObject, eventdata, handles)
% hObject    handle to menu_global (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ECOG = get(hfig,'userdata');
if isempty(ECOG.data)
    return;
end
display = getappdata(hfig,'display');
display.caxis = 'global';
setappdata(hfig,'display',display);

parent = get(hObject,'parent');
children = get(parent,'children');
num = length(children);
for i = 1:num
    ischecked = lower(get(children(i),'checked'));
    if isequal(ischecked,'on')
        set(children(i), 'checked', 'off');
    end
end
set(hObject, 'checked', 'on');
updatemap;

% --------------------------------------------------------------------
function Untitled_6_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_local_Callback(hObject, eventdata, handles)
% hObject    handle to menu_local (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ECOG = get(hfig,'userdata');
if isempty(ECOG.data)
    return;
end
display = getappdata(hfig,'display');
display.caxis = 'local';
setappdata(hfig,'display',display);

parent = get(hObject,'parent');
children = get(parent,'children');
num = length(children);
for i = 1:num
    ischecked = lower(get(children(i),'checked'));
    if isequal(ischecked,'on')
        set(children(i), 'checked', 'off');
    end
end
set(hObject, 'checked', 'on');
updatemap;



% --------------------------------------------------------------------
function menu_epochstart_Callback(hObject, eventdata, handles)
% hObject    handle to menu_epochstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
axes(tsaxes);
currentylim = get(tsaxes, 'Ylim');
tmpcolor = [0.0,0.0,1.0];
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
ypos = [currentylim(1,1),  currentylim(1,2)];
linehandle = findobj(hfig,'tag','leftline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end

options = getappdata(hfig,'options');
options.epochstart = xpos(1,1);
setappdata(hfig,'options',options);

% --------------------------------------------------------------------
function menu_epochend_Callback(hObject, eventdata, handles)
% hObject    handle to menu_epochend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
axes(tsaxes);
currentylim = get(tsaxes, 'Ylim');
tmpcolor = [0.0,0.0,1.0];
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
ypos = [currentylim(1,1),  currentylim(1,2)];
linehandle = findobj(hfig,'tag','rightline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end

options = getappdata(hfig,'options');
options.epochend = xpos(1,1);
setappdata(hfig,'options',options);

% --------------------------------------------------------------------
function menu_defaultepoch_Callback(hObject, eventdata, handles)
% hObject    handle to menu_defaultepoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ECOG = get(handles.figureloadecog,'userdata');
if isempty(ECOG.data)
    return;
end
options = getappdata(handles.figureloadecog,'options');
options.epochstart = 1;
options.epochend = ECOG.points;
setappdata(handles.figureloadecog,'options',options);

axes(handles.tsaxes);     
currentylim = get(handles.tsaxes, 'Ylim');
ypos = [currentylim(1,1),  currentylim(1,2)];
xpos = [options.epochstart, options.epochstart];
tmpcolor = [0.0,0.0,1.0];
linehandle = findobj(handles.figureloadecog,'tag','leftline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end
    
xpos = [options.epochend, options.epochend];
tmpcolor = [1.0,0.0,0.0];
linehandle = findobj(handles.figureloadecog,'tag','rightline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end


% --------------------------------------------------------------------
function Untitled_8_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_9_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_psd_Callback(hObject, eventdata, handles)
% hObject    handle to menu_psd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ECOG = get(handles.figureloadecog,'userdata');
if isempty(ECOG.data)
    return;
end
pop_ecog_psd(ECOG);

% --- Executes on selection change in ecog_listbox.
function ecog_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to ecog_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns ecog_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ecog_listbox


% --- Executes during object creation, after setting all properties.
function ecog_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ecog_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_capimg_Callback(hObject, eventdata, handles)
% hObject    handle to menu_capimg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% capobj(handles.sceneaxes, 'Potential Mapping Image of Cortical ECoG');



% --------------------------------------------------------------------
function menu_PM_Callback(hObject, eventdata, handles)
% hObject    handle to menu_PM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.sceneaxes, 'Potential Mapping Image of Cortical ECoG');

% --------------------------------------------------------------------
function menu_waveforms_Callback(hObject, eventdata, handles)
% hObject    handle to menu_waveforms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capaxis(handles.tsaxes, 'ECoG Waveforms',0);


% --------------------------------------------------------------------
function menu_GFP_Callback(hObject, eventdata, handles)
% hObject    handle to menu_GFP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ECOG = get(hfig,'userdata');
options = getappdata(hfig,'options');

startpoint = options.epochstart;
endpoint = options.epochend;
startpoint = min(max(startpoint,1),ECOG.points);
endpoint = min(max(endpoint,1),ECOG.points);
if startpoint > endpoint
    return;
end

% compute GFP with valid channels
ts = ECOG.data(ECOG.vidx,startpoint:endpoint);
srate = ECOG.srate;
starttime = (startpoint - 1)/ECOG.srate;
pos = [];

% compute global field power for the selected epoch.
ECOM_Butterfly(ts, srate, starttime, pos);



% --------------------------------------------------------------------
function menu_COI_Callback(hObject, eventdata, handles)
% hObject    handle to menu_COI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;    
ECOG = get(hfig,'userdata');
vidx = sort([ECOG.vidx, ECOG.bad]); % automatically processed channels are excluded

default = [];
[sel,ok] = listdlg('ListString',ECOG.labels(vidx),'Name','Interested Channels','InitialValue',default);
if ok == 0 | isempty(sel)
    return;
end

ECOG.vidx = vidx(sel); % interested channels
ECOG.bad = vidx; % the rest are considered as bad channels
ECOG.bad(sel) = [];

set(hfig,'userdata',ECOG);

updatewindow;

