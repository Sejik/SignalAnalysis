function varargout = pop_roits(varargin)
% pop_roits - the GUI for computing ROI time series.
%
% Usage: 
%            1. type 
%               >> pop_roits
%               or call pop_roits to start the popup GUI.
%               Default 26 ROIs will be used.
%               
%            2. type 
%               >> pop_roits(SourceROI)
%               or call pop_roits(SourceROI) to start the popup GUI with SourceROI structure. 
%               The SourceROI structure has 3 fields:
%               - SourceROI.data is the cortical source data. 
%               - SourceROI.srate is the sampling rate. 
%               - SourceROI.ROI is the structure for cortical ROIs. 
%                   SourceROI.ROI has 3 fields:
%                   - SourceROI.ROI.labels is the array for ROI labels. 
%                   - SourceROI.ROI.centers is the array for ROI centers. 
%                   - SourceROI.ROI.vertices is the cell array for ROI vertices. 
%               ROIs designated by SourceROI.ROI will be used.
%
%            3. call pop_roits(SourceROI) from the pop_sourceloc GUI ('Context Menus -> 
%               ROIs -> Compute ROI Time Series'). 
%               ROIs created in the pop_sourceloc GUI will be used. 
%               Default 26 ROIs will be used if no ROI is created. 
%
% Brain Model:
% The cortex model used in the program are constructed based on the 
% standard Montreal Neurological Institute (MNI) brain.
% See below for detailed description of MNI Brain model: 
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
% Yakang Dai, 16-June-2010 15:03:30
% Support individual head model
%
% Yakang Dai, 18-May-2010 20:36:30
% Add capture image function
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================


% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_roits_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_roits_OutputFcn, ...
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


% --- Executes just before pop_roits is made visible.
function pop_roits_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_roits (see VARARGIN)

% Choose default command line output for pop_roits
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_roits wait for user response (see UIRESUME)
% uiwait(handles.figure1);

len = length(varargin);

if len~=0 && len~= 1
    errordlg('Input arguments mismatch!','Input error','modal');
    return;
end

if len == 1
    SourceROI = varargin{1};
    sourcedata = SourceROI.data;
    srate = SourceROI.srate;
    model.cortex = SourceROI.Cortex;
%     if isfield(SourceROI, 'individual')
%         individual = SourceROI.individual;
%     else
%         individual = SourceROI.usebem;
%     end

    individual = SourceROI.usebem;
    
    if ~isempty(SourceROI.ROI)
        ROI = SourceROI.ROI;
    else
        % load standard head model and 26 default ROIs
        if individual == 1
            sourcedata = [];
            srate = [];
            load('colincortex.mat');
            model.cortex = colincortex;
            individual = 0;
        end
        ROIinf = load('ROI.mat');
        if isfield(ROIinf,'ROI')
            ROI = ROIinf.ROI;
        else
            errordlg('Missing the ROI Model!');
            return;
        end
    end    
else
    sourcedata = [];
    srate = [];
    ROIinf = load('ROI.mat');
    if isfield(ROIinf,'ROI')
        ROI = ROIinf.ROI;
    else
        errordlg('The ROI model is missed!');
        return;
    end
    load('colincortex.mat');
    model.cortex = colincortex;
    individual = 0;
end

set(hObject,'Toolbar','figure');
hToolbar = findall(hObject,'tag','FigureToolBar');
hButtons = findall(hToolbar);
set(hButtons,'Visible','off');
toolhandle = findobj(hButtons,'tag','FigureToolBar'); % FigureToolBar
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.Rotate'); % Rotate
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.ZoomOut'); % ZoomOut
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.ZoomIn'); % ZoomIn
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.Pan'); % Pan
set(toolhandle,'Visible','on');

axes(handles.cortexaxes);
axis vis3d;
set(handles.cortexaxes, 'DataAspectRatio',[1 1 1]);
set(handles.cortexaxes, 'color',get(hObject,'color'));
box off;
axis off;
cla;

axes(handles.tsaxes);
set(handles.tsaxes, 'color',get(hObject,'color'));
cla;

% parameters for the display of cortex, labels, and dtf graphics. 
nroi = length(ROI.labels);
cmap = colormap(lines(nroi));

ROI.selected = 1:nroi;
ROI.data = [];
    
% make different vertices in different cortex ROIs different colors
if individual == 1 
    len = length(model.cortex.Vertices);
    model.cortex.FaceVertexCData = repmat([0.6,0.6,0.6], len, 1); % for individual head model
end

cortexFaceVertexCData = model.cortex.FaceVertexCData;

for i=1:nroi
      roi_vert_idx = ROI.vertices{i};
      cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
end

axes(handles.cortexaxes);
hold on;
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.cortex.Vertices,...
     'LineStyle','none',...
     'Faces',model.cortex.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',cortexFaceVertexCData,...
     'tag','cotex');
 
lighting phong; % gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);

linestart = ROI.centers;
lineend(:,1) = ROI.centers(:,1)*2.2;
lineend(:,2) = ROI.centers(:,2)*1.2;
lineend(:,3) = ROI.centers(:,3)*2.5;
for i = 1:nroi
    plot3([linestart(i,1) lineend(i,1)], [linestart(i,2) lineend(i,2)], [linestart(i,3) lineend(i,3)],'LineWidth',1.2,'color', 'k');
    if lineend(i,1) < 0
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','right','VerticalAlignment','bottom ','Interpreter','none');
    else
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','left','VerticalAlignment','bottom ','Interpreter','none');
    end
end

setappdata(hObject,'model',model);
setappdata(hObject,'sourcedata',sourcedata);
setappdata(hObject,'srate',srate);
setappdata(hObject,'ROI',ROI);
setappdata(hObject,'individual',individual);

set(gcf,'windowbuttonmotionfcn', @mousemotionCallback);

% --- Outputs from this function are returned to the command line.
function varargout = pop_roits_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function menu_select_roi_Callback(hObject, eventdata, handles)
% hObject    handle to menu_select_roi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ROI = getappdata(hfig,'ROI');
default = [];
[sel,ok] = listdlg('ListString',ROI.labels,'Name','ROI Selection','InitialValue',default);
if ok == 0 | isempty(sel)
    return;
end
ROI.selected = sel;

model = getappdata(hfig,'model');

% parameters for the display of cortex, labels, and dtf graphics. 
nroi = length(sel);
cmap = colormap(lines(nroi));
    
cortexFaceVertexCData = model.cortex.FaceVertexCData;

for i=1:nroi
      roi_vert_idx = ROI.vertices{sel(i)};
      cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
end

axes(handles.cortexaxes);
cla;
hold on;
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.cortex.Vertices,...
     'LineStyle','none',...
     'Faces',model.cortex.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',cortexFaceVertexCData,...
     'tag','cotex');
 
lighting phong; % gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);

linestart = ROI.centers(sel,:);
lineend(:,1) = linestart(:,1)*2.2;
lineend(:,2) = linestart(:,2)*1.2;
lineend(:,3) = linestart(:,3)*2.5;
labels = ROI.labels(sel);
for i = 1:nroi
    plot3([linestart(i,1) lineend(i,1)], [linestart(i,2) lineend(i,2)], [linestart(i,3) lineend(i,3)],'LineWidth',1.2,'color', 'k');
    if lineend(i,1) < 0
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','right','VerticalAlignment','bottom ','Interpreter','none');
    else
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','left','VerticalAlignment','bottom ','Interpreter','none');
    end
end

setappdata(hfig,'ROI',ROI);

% --------------------------------------------------------------------
function menu_compute_roits_Callback(hObject, eventdata, handles)
% hObject    handle to menu_compute_roits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;

sourcedata = getappdata(hfig,'sourcedata');
srate = getappdata(hfig,'srate');
if isempty(sourcedata) | isempty(srate)
    helpdlg('Please import source data!');
    return;
end

points = length(sourcedata);
len = length(sourcedata{1});
model = getappdata(hfig,'model');
num_verts = length(model.cortex.Vertices);
if len ~= num_verts
    helpdlg('Imported source data is not right!');
    return;
end

ROI = getappdata(hfig,'ROI');
if isempty(ROI)
    helpdlg('There is no ROI, please import ROIs !');
    return;
end
sel = ROI.selected;
nroi = length(sel);

% compute ROI time series.
roidata = zeros(nroi,points);
for i = 1:nroi
    roi_vert_idx = ROI.vertices{sel(i)};
    for j = 1:points
        currentdata = sourcedata{j};
        roidata(i,j) = mean(currentdata(roi_vert_idx));
    end
end

xlimit = points;
xlabelstep = round(xlimit/10);
    
% x labels
xlabelpositions = [0:xlabelstep:xlimit];
xlabels = [0:xlabelstep:xlimit];
xlabels = xlabels / srate;
xlabels = num2str(xlabels');
     
% y labels
channelmaxs = max(roidata,[ ],2);
channelmins = min(roidata,[ ],2);    
spacing = mean(channelmaxs-channelmins);  
ylimit = (nroi+1)*spacing;
ylabelpositions = [0:spacing:nroi*spacing];    
YLabels = ROI.labels(sel);
YLabels = strvcat(YLabels); 
YLabels = flipud(str2mat(YLabels,' '));

% mean values for the current window
meandata = mean(roidata,2);

axes(handles.tsaxes);     
set(handles.tsaxes,...
      'Xlim',[0 xlimit],...
      'xtick',xlabelpositions,...% where to display the labels.
      'XTickLabel', xlabels,...
      'Ylim',[0 ylimit],...
      'YTick',ylabelpositions,...
      'YTickLabel', YLabels); % the labels to be displayed
cla;        
hold on;

tmpcolor = [ 0.0 0.0 1.0 ];
for i = 1:nroi
    plot(roidata(nroi-i+1,:) - meandata(nroi-i+1)+i*spacing, 'color', tmpcolor, 'clipping', 'on');
end 

ROI.data = roidata;
setappdata(hfig,'ROI',ROI);

% --------------------------------------------------------------------
function menu_compute_roicon_Callback(hObject, eventdata, handles)
% hObject    handle to menu_compute_roicon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ROI = getappdata(hfig,'ROI');
srate = getappdata(hfig,'srate');
if isempty(ROI.data)
    helpdlg('Please compute ROI time series!');
    return;
end

output = pop_dtf_computation(ROI.data, srate);

if isempty(output.dtfmatrixs)
    return;
end

DTF.labels = ROI.labels(ROI.selected);
DTF.vertices = ROI.vertices(ROI.selected);
DTF.locations = ROI.centers(ROI.selected,:);
DTF.frequency = output.frequency;
DTF.matrix = output.dtfmatrixs;
DTF.isadtf = output.isadtf;
DTF.srate = output.srate;
DTF.type = 'ROI';
model = getappdata(hfig,'model');
DTF.cortex = model.cortex;
DTF.usebem = getappdata(hfig,'individual');
pop_cortex(DTF);

% --------------------------------------------------------------------
function menu_export_roits_Callback(hObject, eventdata, handles)
% hObject    handle to menu_export_roits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ROI = getappdata(hfig,'ROI');
srate = getappdata(hfig,'srate');
if isempty(ROI.data)
    helpdlg('Please compute ROI time series!');
    return;
end

[name, pathstr] = uiputfile('*.mat','Save ROI Time Series');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);
ROITS.labels = ROI.labels(ROI.selected);
ROITS.vertices = ROI.vertices(ROI.selected);
ROITS.centers = ROI.centers(ROI.selected,:);
ROITS.data = ROI.data;
ROITS.srate = srate;
model = getappdata(hfig,'model');
ROITS.cortex = model.cortex;
ROITS.individual = getappdata(hfig,'individual');
save(Fullfilename, 'ROITS');

% --------------------------------------------------------------------
function popmenu_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function mousemotionCallback(src, evnt) 

hfig = gcf;
ROI = getappdata(hfig,'ROI');
if isempty(ROI) | ~isfield(ROI,'data')
    return;
else
    if isempty(ROI.data)
        return;
    end
end

srate = getappdata(hfig,'srate');
tsaxes = findobj(hfig,'tag','tsaxes'); 

currentxlim = get(tsaxes, 'Xlim');
currentylim = get(tsaxes, 'Ylim');
mousepos = get(tsaxes, 'currentpoint');

% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
    return;
end

points = size(ROI.data, 2);
currentpoint = round(mousepos(1,1));%find the nearest point.
if currentpoint < 1 | currentpoint > points
    return;
end
currenttime = currentpoint / srate;

nroi = length(ROI.selected);
channelmaxs = max(ROI.data,[ ],2);
channelmins = min(ROI.data,[ ],2);
spacing = mean(channelmaxs-channelmins);
currentchannel = round( (currentylim(1,2) - mousepos(1,2) ) / spacing );%find the nearest channel.
if currentchannel < 1 | currentchannel > nroi
    return;
end

currentlabel = char(ROI.labels(ROI.selected(currentchannel)));

currentvalue = ROI.data(currentchannel, currentpoint);

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

textroi = findobj(hfig,'tag','textroi'); 
textpoint = findobj(hfig,'tag','textpoint'); 
texttime = findobj(hfig,'tag','texttime'); 
textvalue = findobj(hfig,'tag','textvalue'); 

set(textroi,'string', ['ROI: ' currentlabel]);
set(textpoint,'string', ['Point: ' num2str(currentpoint)]);
set(texttime,'string', ['Time: ' num2str(currenttime) ' s']);
set(textvalue,'string', ['Value: '  num2str(currentvalue)]);


% --------------------------------------------------------------------
function menu_import_source_Callback(hObject, eventdata, handles)
% hObject    handle to menu_import_source (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
sourcedata = getappdata(hfig,'sourcedata');
if ~isempty(sourcedata)    
    importevent = questdlg('Exist source data, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr] = uigetfile('*.mat','Select Source Data File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

source = load(Fullfilename);

if ~isfield(source, 'sourcedata')
    errordlg('The imported is not source data!');
    return;
end

if isempty(source.sourcedata)
    errordlg('The imported source data is empty!');
    return;
end

model = getappdata(hfig,'model');
numverts = length(model.cortex.Vertices);
data = source.sourcedata{1};
len = length(data);
if numverts ~= len
    errordlg('The imported is not the correct source data!');
    return;
end
sourcedata = source.sourcedata;

if ~isfield(source, 'srate') | isempty(source.srate)
    srate = 250;
else
    srate = source.srate;
end

setappdata(hfig, 'sourcedata',sourcedata);
setappdata(hfig, 'srate',srate);
helpdlg('Source data is imported successfully!');


% --------------------------------------------------------------------
function menu_timefrequency_Callback(hObject, eventdata, handles)
% hObject    handle to menu_timefrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ROI = getappdata(hfig,'ROI');
srate = getappdata(hfig,'srate');

ts = ROI.data;
if isempty(ts)
    helpdlg('There is no ROI time series!');
    return;
end

starttime = 0;
pos1 = get(hfig,'CurrentPoint');
pos2 = get(hfig,'position');
% pos = pos1 + pos2(1:2);
pos = pos1;

% compute and visualize time-frequency
time_frequency(ts, srate, starttime, pos, 'Average Time Frequency');

% --------------------------------------------------------------------
function menu_filtering_Callback(hObject, eventdata, handles)
% hObject    handle to menu_filtering (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
ROI = getappdata(hfig,'ROI');
srate = getappdata(hfig,'srate');
if isempty(ROI.data)
    helpdlg('There is no ROI time series!');
    return;
end

% use uiwait and uiresume to get input parameters from the pop figure. 
roidata = pop_filter(ROI.data,srate);

if isempty(roidata)
    return;
end

ROI.data = roidata;
setappdata(hfig,'ROI',ROI);

[nroi, points] = size(roidata);
sel = ROI.selected;

xlimit = points;
xlabelstep = round(xlimit/10);
    
% x labels
xlabelpositions = [0:xlabelstep:xlimit];
xlabels = [0:xlabelstep:xlimit];
xlabels = xlabels / srate;
xlabels = num2str(xlabels');
     
% y labels
channelmaxs = max(roidata,[ ],2);
channelmins = min(roidata,[ ],2);    
spacing = mean(channelmaxs-channelmins);  
ylimit = (nroi+1)*spacing;
ylabelpositions = [0:spacing:nroi*spacing];    
YLabels = ROI.labels(sel);
YLabels = strvcat(YLabels); 
YLabels = flipud(str2mat(YLabels,' '));

% mean values for the current window
meandata = mean(roidata,2);

axes(handles.tsaxes);     
set(handles.tsaxes,...
      'Xlim',[0 xlimit],...
      'xtick',xlabelpositions,...% where to display the labels.
      'XTickLabel', xlabels,...
      'Ylim',[0 ylimit],...
      'YTick',ylabelpositions,...
      'YTickLabel', YLabels); % the labels to be displayed
cla;        
hold on;

tmpcolor = [ 0.0 0.0 1.0 ];
for i = 1:nroi
    plot(roidata(nroi-i+1,:) - meandata(nroi-i+1)+i*spacing, 'color', tmpcolor, 'clipping', 'on');
end 


% --------------------------------------------------------------------
function menu_importroi_Callback(hObject, eventdata, handles)
% hObject    handle to menu_importroi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ROI = getappdata(hfig,'ROI');
if ~isempty(ROI)    
    importevent = questdlg('Exist ROIs, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr] = uigetfile('*.mat','Select ROI File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

ROIinf = load(Fullfilename);

if ~isfield(ROIinf, 'labels')
    errordlg('The imported is not ROIs!');
    return;
end

if isempty(ROIinf.labels)
    errordlg('The imported ROIs is empty!');
    return;
end

model = getappdata(hfig,'model');
numv = length(model.cortex.Vertices);
if isfield(ROIinf,'numv') && ROIinf.numv ~= numv
    helpdlg('The input ROIs can not match the cortex model');
    return;
end

ROI.labels = ROIinf.labels;
ROI.centers = ROIinf.centers;
ROI.vertices = ROIinf.vertices;

% parameters for the display of cortex, labels, and dtf graphics. 
nroi = length(ROI.labels);
cmap = colormap(lines(nroi));

ROI.selected = 1:nroi;
ROI.data = [];
    
model = getappdata(hfig,'model');

% make different vertices in different cortex ROIs different colors
cortexFaceVertexCData = model.cortex.FaceVertexCData;
for i=1:nroi
      roi_vert_idx = ROI.vertices{i};
      cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
end

axes(handles.cortexaxes);
cla;
hold on;
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.cortex.Vertices,...
     'LineStyle','none',...
     'Faces',model.cortex.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',cortexFaceVertexCData,...
     'tag','cotex');
 
lighting phong; % gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);

linestart = ROI.centers;
lineend(:,1) = ROI.centers(:,1)*2.2;
lineend(:,2) = ROI.centers(:,2)*1.2;
lineend(:,3) = ROI.centers(:,3)*2.5;
for i = 1:nroi
    plot3([linestart(i,1) lineend(i,1)], [linestart(i,2) lineend(i,2)], [linestart(i,3) lineend(i,3)],'LineWidth',1.2,'color', 'k');
    if lineend(i,1) < 0
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','right','VerticalAlignment','bottom ','Interpreter','none');
    else
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','left','VerticalAlignment','bottom ','Interpreter','none');
    end
end

setappdata(hfig,'ROI',ROI);


% --------------------------------------------------------------------
function menu_defaultrois_Callback(hObject, eventdata, handles)
% hObject    handle to menu_defaultrois (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
individual = getappdata(hfig,'individual');
if individual == 1
    helpdlg('No default ROI for individual head model !');
    return;
end

ROIinf = load('ROI.mat');
if isfield(ROIinf,'ROI')
    ROI = ROIinf.ROI;
else
    errordlg('Missing the ROI Model!');
    return;
end

% parameters for the display of cortex, labels, and dtf graphics. 
nroi = length(ROI.labels);
cmap = colormap(lines(nroi));

ROI.selected = 1:nroi;
ROI.data = [];
    
model = getappdata(hfig,'model');

% make different vertices in different cortex ROIs different colors
cortexFaceVertexCData = model.cortex.FaceVertexCData;
for i=1:nroi
      roi_vert_idx = ROI.vertices{i};
      cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
end

axes(handles.cortexaxes);
cla;
hold on;
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.cortex.Vertices,...
     'LineStyle','none',...
     'Faces',model.cortex.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',cortexFaceVertexCData,...
     'tag','cotex');
 
lighting phong; % gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);

linestart = ROI.centers;
lineend(:,1) = ROI.centers(:,1)*2.2;
lineend(:,2) = ROI.centers(:,2)*1.2;
lineend(:,3) = ROI.centers(:,3)*2.5;
for i = 1:nroi
    plot3([linestart(i,1) lineend(i,1)], [linestart(i,2) lineend(i,2)], [linestart(i,3) lineend(i,3)],'LineWidth',1.2,'color', 'k');
    if lineend(i,1) < 0
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','right','VerticalAlignment','bottom ','Interpreter','none');
    else
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','left','VerticalAlignment','bottom ','Interpreter','none');
    end
end

setappdata(hfig,'ROI',ROI);


% --------------------------------------------------------------------
function menu_capimg_Callback(hObject, eventdata, handles)
% hObject    handle to menu_capimg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.cortexaxes, 'Cortical ROIs');


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_customized_Callback(hObject, eventdata, handles)
% hObject    handle to menu_customized (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
individual = getappdata(hfig,'individual');

if individual == 1
    importevent = questdlg('Exist individual head model, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr] = uigetfile('*.mat','Select head Model File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);
head = load(Fullfilename);

if isfield(head, 'BEM')
    if ~isequal(lower(head.BEM.Unit),'mm')
        errordlg('The unit of the imported head model should be mm !');
        return;
    end
    model = getappdata(hfig,'model');
    model.cortex = head.BEM.Cortex;
elseif isfield(head, 'Sphere')
    if ~isequal(lower(head.Sphere.Unit),'mm')
        errordlg('The unit of the imported head model should be mm !');
        return;
    end
    model = getappdata(hfig,'model');
    model.cortex = head.Sphere.Cortex;
else
    errordlg('The imported is not head model for EEG/MEG!');
    return;
end

len = length(model.cortex.Vertices);
model.cortex.FaceVertexCData = repmat([0.6,0.6,0.6], len, 1);

axes(handles.cortexaxes);
cla;
hold on;
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.cortex.Vertices,...
     'LineStyle','none',...
     'Faces',model.cortex.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',model.cortex.FaceVertexCData,...
     'tag','cotex');
lighting phong; % gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);

setappdata(hfig,'model',model);
setappdata(hfig,'individual',1);
setappdata(hfig,'ROI',[]);
setappdata(hfig,'sourcedata',[]);
axes(handles.tsaxes); 
cla;

% --------------------------------------------------------------------
function menu_standard_Callback(hObject, eventdata, handles)
% hObject    handle to menu_standard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
individual = getappdata(hfig,'individual');
if individual == 0
    helpdlg('The model used is the standard one !');
    return;
end
model = getappdata(hfig,'model');
load('colincortex.mat');
model.cortex = colincortex;

setappdata(hfig,'model',model);
setappdata(hfig,'individual',0);
setappdata(hfig,'sourcedata',[]);
ROIinf = load('ROI.mat');
if isfield(ROIinf,'ROI')
    ROI = ROIinf.ROI;
    axes(handles.tsaxes); 
    cla;
else
    errordlg('Missing the ROI Model!');
    setappdata(hfig, 'ROI', []);
    axes(handles.tsaxes); 
    cla;
    return;
end

nroi = length(ROI.labels);
cmap = colormap(lines(nroi));
ROI.selected = 1:nroi;
ROI.data = [];
setappdata(hfig, 'ROI', ROI);

cortexFaceVertexCData = model.cortex.FaceVertexCData;
for i=1:nroi
      roi_vert_idx = ROI.vertices{i};
      cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
end
axes(handles.cortexaxes);
cla;
hold on;
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.cortex.Vertices,...
     'LineStyle','none',...
     'Faces',model.cortex.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',cortexFaceVertexCData,...
     'tag','cotex');
 
lighting phong; % gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);

linestart = ROI.centers;
lineend(:,1) = ROI.centers(:,1)*2.2;
lineend(:,2) = ROI.centers(:,2)*1.2;
lineend(:,3) = ROI.centers(:,3)*2.5;
for i = 1:nroi
    plot3([linestart(i,1) lineend(i,1)], [linestart(i,2) lineend(i,2)], [linestart(i,3) lineend(i,3)],'LineWidth',1.2,'color', 'k');
    if lineend(i,1) < 0
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','right','VerticalAlignment','bottom ','Interpreter','none');
    else
        text( lineend(i,1), lineend(i,2), lineend(i,3), char(ROI.labels{i}),'FontSize',8 ,...
          'HorizontalAlignment','left','VerticalAlignment','bottom ','Interpreter','none');
    end
end
