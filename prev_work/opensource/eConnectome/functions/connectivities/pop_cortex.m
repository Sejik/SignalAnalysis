function varargout = pop_cortex(varargin)
% pop_cortex - the GUI for visualizing functional connectivity over cortex model.
%
% Useage: 
%           1. type
%               >> pop_cortex
%               or call pop_cortex to start the popup GUI
%
%            2. type 
%               >> pop_cortex(DTF)
%               or call pop_cortex(DTF) to start the popup GUI with DTF structure. 
%               The DTF structure should be pre-exported by the pop_cortex GUI.
%               For ROI based cortical functional connectivity, the DTF structure
%               has 6 valid fields. 
%               - DTF.type is 'ROI' 
%               - DTF.labels is the array for ROI labels
%               - DTF.locations the array for ROI centers
%               - DTF.frequency ([lowf highf]) is the frequency range (see pop_dtf_computation)
%               - DTF.matrix is the 3D array for DTF matrix (see pop_dtf_computation)
%               - DTF.vertices is the cell array for ROI vertices
%
%               For ECoG functional connectivity, the DTF structure
%               has 5 valid fields. 
%               - DTF.type is 'Single Point'
%               - DTF.labels is the array for electrode labels
%               - DTF.locations the array for electrode locations
%               - DTF.frequency ([lowf highf]) is the frequency range (see pop_dtf_computation)
%               - DTF.matrix is the 3D array for DTF matrix (see pop_dtf_computation)
% 
%            3. call pop_cortex from the eegfc GUI ('Menu bar -> Connectivity -> Cortex')
%
%            4. call pop_cortex from the ecogfc GUI ('Menu bar -> Connectivity -> View')
%
% Reference for eegfc() (please cite):
% Babiloni F, Cincotti F, Babiloni C, Carducci F, Mattia D, Astolfi L, Basilisco A, Rossini PM, 
% Ding L, Ni Y, Cheng J, Christine K, Sweeney J, He B. Neuroimage. 2005 Jan 1;24(1):118-31. 
% Estimation of the cortical functional connectivity with the multimodal integration of high-resolution 
%  EEG and fMRI data by directed transfer function.
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
% Yakang Dai, 20-June-2010 10:45:30
% Add connectivity analysis with ADTF values 
%
% Yakang Dai, 18-June-2010 15:27:30
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
                   'gui_OpeningFcn', @pop_cortex_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_cortex_OutputFcn, ...
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


% --- Executes just before pop_cortex is made visible.
function pop_cortex_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_cortex (see VARARGIN)

% Choose default command line output for pop_cortex
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_cortex wait for user response (see UIRESUME)
% uiwait(handles.cortexdtfgui);

set(hObject,'Toolbar','figure');
% set(hObject,'MenuBar','figure');
set(handles.textvalue,'string','');

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

axcolor = get(hObject, 'color');
axes(handles.sceneaxes);
% axis vis3d;
set(handles.sceneaxes, 'color', axcolor);
set(handles.sceneaxes, 'DataAspectRatio',[1 1 1]);
box off;
axis off;
axes(handles.imageaxes);
set(handles.imageaxes, 'DataAspectRatio',[1 1 1]);
set(handles.imageaxes, 'color', axcolor);

%% set default options for displaying DTF graphics.
options.isskin = get(handles.checkboxskin, 'value');
options.iscortex = get(handles.checkboxcortex, 'value');
options.islabel = get(handles.checkboxlabels, 'value');

channels = {'all', 'single', 'none'};
channelvalues = [get(handles.radiobuttonall, 'value'), get(handles.radiobuttonsingle, 'value'), get(handles.radiobuttonnone, 'value')];
options.channels = strvcat( channels(channelvalues == 1) );
options.whichchannel = nan;

dispmodes = {'out2in', 'outflow', 'inflow'};
dispmodevalues = [get(handles.radiobuttonout2in, 'value'), get(handles.radiobuttonoutflow, 'value'), get(handles.radiobuttoninflow, 'value')];
options.dispmodes = strvcat( dispmodes(dispmodevalues == 1) );

options.type = 'ROI';
%%


%% draw the head model in  3D scene axes.
load('cutskin.mat');
model.skin = cutskin;
% load('colincortex.mat');
% model.cortex = colincortex;
scenecolorbar = 0;
setappdata(hObject,'scenecolorbar',scenecolorbar);

hasinput = length(varargin);
if hasinput 
    DTF = varargin{1};
    
    options.type = DTF.type;
    model.roilabels = DTF.labels;
    model.roipos = DTF.locations;
    options.isadtf = DTF.isadtf;
    options.srate = DTF.srate;
    frequency = DTF.frequency;
    
    if isfield(DTF,'cortex')
        model.cortex = DTF.cortex;
    else
        load('colincortex.mat');
        model.cortex = colincortex;
    end
    if isfield(DTF,'usebem')
        options.usebem = DTF.usebem;
    else
        options.usebem = 0;
    end
            
    if isequal(DTF.type,'ROI')
        model.vertices = DTF.vertices;
    elseif ~isequal(DTF.type,'Single Point')
        errordlg('The imported is not cortical DTF file!');
        return;
    end
    
    set(handles.textfrequency,'userdata', frequency);
    set(handles.cortexdtfgui, 'userdata', DTF.matrix);
    
    % set frequency slider
    currentf = frequency(1);
    set(handles.textfrequency,'string', ['Current Frequeny (' num2str(frequency(1)) ' ~ ' num2str(frequency(2)) '):']);
    set(handles.frequencyedit,'string', num2str(currentf));
    sliderstep = 1/(frequency(2)-frequency(1));
    set(handles.sliderfrequency,'min',frequency(1),'max',frequency(2),'sliderstep',[sliderstep sliderstep],'value',currentf);
    
    % set default frequency band
    set(handles.editbandmin,'string',num2str(frequency(1)));
    set(handles.editbandmax,'string',num2str(frequency(2)));
    
    nroi = length(model.roilabels);
    dtf.rois = 1:nroi;    
    
    % dtf.matrix is the current specific DTF matrix 
    if options.isadtf
        % set time slider
        num = size(DTF.matrix,1);
        sp = round(num/2);
        set(handles.text_time,'string', ['Current Time (' num2str(1/DTF.srate) ' ~ ' num2str(num/DTF.srate) ' s):']);
        set(handles.timeedit,'string', num2str(sp/DTF.srate));
        sliderstep = 1/(num-1);
        set(handles.slider_time,'min',1,'max',num,'sliderstep',[sliderstep sliderstep],'value',sp);
        options.points = num;
        
        dtf.matrix = squeeze(DTF.matrix(sp,:,:,1)); % The default is at the start frequency and the middle time point for ADTF
    else
        dtf.matrix = DTF.matrix(:,:,1);  % The default is at the start frequency for constant DTF  
        enable_time_options(false);
    end
    
    valmin = min(min(dtf.matrix));
    valmax = max(max(dtf.matrix));
    if isnan(valmin)
        valmin = 0.001;
    end
    if isnan(valmax)
        valmax = 1;
    end
    
    options.dtf = true;
else
    load('colincortex.mat');
    model.cortex = colincortex;
    load('ROI.mat');
    model.roilabels = ROI.labels;
    model.vertices = ROI.vertices;
    model.roipos = ROI.centers;
    
    % the default dtf matrix.
    nroi = length(model.roilabels);
    dtf.rois = 1:nroi;
    dtf.matrix = 0.5*ones(nroi, nroi);
    
    enable_time_options(false);
    options.dtf = false;
    options.isadtf = false;
    options.usebem = 0;
    valmin = 0.001;
    valmax = 1.0;
end

enable_band(false);

set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
options.displimits = [(valmax+valmin)/2, valmax];
options.minmax = [valmin, valmax];
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));
    
set(handles.options,'userdata', options);
setappdata(hObject,'movie',0);

% axes setting
axes(handles.sceneaxes);
set(handles.sceneaxes, 'userdata', model);
cla;
hold on;

displayDTFG(model, options, dtf);

% view([180 15]);
%%

%% Display the image for connectivity values
axes(handles.imageaxes);

xlabels = num2str(dtf.rois');
yLabels = flipud(num2str(dtf.rois'));

set(handles.imageaxes,'userdata',dtf,...
      'Xlim',[0 nroi+1],...
      'xtick',dtf.rois,...% where to display the labels.
      'Ylim',[0 nroi+1],...
      'YTick',dtf.rois,...
      'XTickLabel', xlabels,...% the labels to be displayed
      'YTickLabel', yLabels,...
      'TickLength',[.005 .005]);
if hasinput
    caxis([valmin, valmax]);
    colorbar;
end
cla;  
axis on;
hold on;

plotimage = flipud(dtf.matrix);
imgh = imagesc(plotimage,'tag','image');
xlabel('j','fontsize',10,'fontweight','b');
ylabel('i','fontsize',10,'fontweight','b');

for i=0:nroi
    lx = [0.5 nroi+0.5];
    ly = i+0.5;
    ly = [ly ly];
    plot(lx,ly,'k');
    plot(ly,lx,'k');
end
%%

%% set callbacks
set(gcf,'windowbuttonmotionfcn', @mousemotionCallback);
set(gcf,'WindowButtonDownFcn', @mousedownCallback);
%%

% --- Outputs from this function are returned to the command line.
function varargout = pop_cortex_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function loaddtfm_Callback(hObject, eventdata, handles)
% hObject    handle to loaddtfm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

matrix = get(handles.cortexdtfgui, 'userdata');
if ~isempty(matrix)    
    importevent = questdlg('Exist DTF/ADTF, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

%% Get DTF properties.
[matname matpath]=uigetfile('*.mat','Select Directed (Adaptive Directed) Transfer Function File');
if matname==0
    return;
end

addpath(matpath);
Fullfilename = fullfile(matpath,matname);
DTF = load(Fullfilename);

if ~isfield(DTF, 'DTF')
    errordlg('The imported is not DTF/ADTF file!');
    return;
end

options = get(handles.options,'userdata');
model = get(handles.sceneaxes,'userdata');
model.roilabels = DTF.DTF.labels;
model.roipos = DTF.DTF.locations;
frequency = DTF.DTF.frequency;

if isfield(DTF.DTF,'cortex')
    model.cortex = DTF.DTF.cortex;
else
    load('colincortex.mat');
    model.cortex = colincortex;
end
if isfield(DTF.DTF,'usebem')
    options.usebem = DTF.DTF.usebem;
else
    options.usebem = 0;
end

if isequal(DTF.DTF.type,'ROI')
    model.vertices = DTF.DTF.vertices;
elseif ~isequal(DTF.DTF.type,'Single Point')
    errordlg('The imported is not cortical DTF file!');
    return;
end
%%

%% update DTF matrix.
nroi = length(model.roilabels);
dtf = get(handles.imageaxes,'userdata');
dtf.rois = 1:nroi;
currentf = frequency(1);

if isfield(DTF.DTF,'isadtf') && DTF.DTF.isadtf
    % set time slider
    enable_time_options(true);
    num = size(DTF.DTF.matrix,1);
    sp = round(num/2);
    set(handles.text_time,'string', ['Current Time (' num2str(1/DTF.DTF.srate) ' ~ ' num2str(num/DTF.DTF.srate) ' s):']);
    set(handles.timeedit,'string', num2str(sp/DTF.DTF.srate));
    sliderstep = 1/(num-1);
    set(handles.slider_time,'min',1,'max',num,'sliderstep',[sliderstep sliderstep],'value',sp);
    options.points = num;
    options.isadtf = 1;
    options.srate = DTF.DTF.srate;
    
    dtf.matrix = squeeze(DTF.DTF.matrix(sp,:,:,1));
else
    dtf.matrix = DTF.DTF.matrix(:,:,1);
    enable_time_options(false);
    options.isadtf = 0;
    options.srate = 400;
end
enable_specific(true);
enable_band(false);
set(handles.pop_band,'value',1);

% set default frequency band
set(handles.editbandmin,'string',num2str(frequency(1)));
set(handles.editbandmax,'string',num2str(frequency(2)));

% set frequency slider
set(handles.textfrequency,'string', ['Current Frequeny (' num2str(frequency(1)) ' ~ ' num2str(frequency(2)) '):']);
set(handles.frequencyedit,'string', num2str(currentf));
sliderstep = 1/(frequency(2)-frequency(1));
set(handles.sliderfrequency,'min',frequency(1),'max',frequency(2),'sliderstep',[sliderstep sliderstep],'value',currentf);   
set(handles.textfrequency,'userdata', frequency);
%%


%% update options
valmin = min(min(dtf.matrix));
valmax = max(max(dtf.matrix));
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end
options.dtf = true;
options.type = DTF.DTF.type;
options.displimits = [(valmax+valmin)/2, valmax];
options.minmax = [valmin, valmax];
options.dispmodes = 'out2in';
set(handles.radiobuttonout2in,'value',true);
options.channels = 'all';
set(handles.radiobuttonall,'value',true);
set(handles.options, 'userdata',options);
    
set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));
    
set(handles.cortexdtfgui, 'userdata', DTF.DTF.matrix);
%%


%% display directed transfer function graphics.
axes(handles.sceneaxes);
cla;
hold on;

displayDTFG(model, options, dtf);
set(handles.sceneaxes,'userdata',model);
%%

%% display directed transfer function matrix.
axes(handles.imageaxes);

xlabelpositions = 1:nroi;
ylabelpositions = 1:nroi;
xlabels = num2str(dtf.rois');
yLabels = flipud(num2str(dtf.rois'));

set(handles.imageaxes,'userdata',dtf,...
      'Xlim',[0 nroi+1],...
      'xtick',xlabelpositions,...% where to display the labels.
      'Ylim',[0 nroi+1],...
      'YTick',ylabelpositions,...
      'XTickLabel', xlabels,...% the labels to be displayed
      'YTickLabel', yLabels,...
      'TickLength',[.005 .005]);
cla;
hold on;

plotimage = flipud(dtf.matrix);
imagesc(plotimage,'tag','image');
for i=0:nroi
    lx = [0.5 nroi+0.5];
    ly = i+0.5;
    ly = [ly ly];
    plot(lx,ly,'k');
    plot(ly,lx,'k');
end

caxis([valmin valmax]);
colorbar;
%%

% --------------------------------------------------------------------
function loadroits_Callback(hObject, eventdata, handles)
% hObject    handle to loadroits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% model = get(handles.sceneaxes,'userdata');
% frequency = get(handles.textfrequency,'userdata');

matrix = get(handles.cortexdtfgui, 'userdata');
if ~isempty(matrix)    
    importevent = questdlg('Exist DTF, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name, pathstr] = uigetfile('*.mat','Import ROI Time Series');
if name==0
    return;
end
addpath(pathstr);
Fullfilename = fullfile(pathstr,name);
ROITS = load(Fullfilename);

if ~isfield(ROITS,'ROITS')
    errordlg('Imported is not ROI Time Series!');
    return;
end

if isempty(ROITS.ROITS.data)
    errordlg('Imported ROI time series is empty!');
    return;
end

output = pop_dtf_computation(ROITS.ROITS.data, ROITS.ROITS.srate);

if isempty(output.dtfmatrixs)
    return;
end

options = get(handles.options,'userdata');
model = get(handles.sceneaxes, 'userdata');
model.roilabels = ROITS.ROITS.labels;
model.vertices = ROITS.ROITS.vertices;
model.roipos = ROITS.ROITS.centers;
frequency = output.frequency;
set(handles.textfrequency,'userdata', frequency);
set(handles.cortexdtfgui, 'userdata', output.dtfmatrixs);

currentf = frequency(1);
set(handles.textfrequency,'string', ['Current Frequeny (' num2str(frequency(1)) ' ~ ' num2str(frequency(2)) '):']);
set(handles.frequencyedit,'string', num2str(currentf));
sliderstep = 1/(frequency(2)-frequency(1));
set(handles.sliderfrequency,'min',frequency(1),'max',frequency(2),'sliderstep',[sliderstep sliderstep],'value',currentf);

dtf = get(handles.imageaxes,'userdata');
nroi = length(model.roilabels);
dtf.rois = 1:nroi;    

if output.isadtf 
    
    % set time slider
    enable_time_options(true);
    num = size(output.dtfmatrixs,1);
    sp = round(num/2);
    set(handles.text_time,'string', ['Current Time (' num2str(1/output.srate) ' ~ ' num2str(num/output.srate) ' s):']);
    set(handles.timeedit,'string', num2str(sp/output.srate));
    sliderstep = 1/(num-1);
    set(handles.slider_time,'min',1,'max',num,'sliderstep',[sliderstep sliderstep],'value',sp);
    options.points = num;
    
    dtf.matrix = squeeze(output.dtfmatrixs(sp,:,:,1));
else
    dtf.matrix = output.dtfmatrixs(:,:,1);
    enable_time_options(false);
end
enable_specific(true);
enable_band(false);
set(handles.pop_band,'value',1);

% set default frequency band
set(handles.editbandmin,'string',num2str(frequency(1)));
set(handles.editbandmax,'string',num2str(frequency(2)));

valmin = min(min(dtf.matrix));
valmax = max(max(dtf.matrix));
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end

if isfield(ROITS.ROITS,'cortex')
    model.cortex = ROITS.ROITS.cortex;
else
    load('colincortex.mat');
    model.cortex = colincortex;
end
if isfield(ROITS.ROITS,'usebem')
    options.usebem = ROITS.ROITS.usebem;
else
    options.usebem = 0;
end

options.dtf = true;
options.isadtf = output.isadtf;
options.srate = output.srate;
options.type = 'ROI';
options.minmax = [valmin, valmax];
options.displimits = [(valmax+valmin)/2, valmax];
options.dispmodes = 'out2in';
set(handles.radiobuttonout2in,'value',true);
options.channels = 'all';
set(handles.radiobuttonall,'value',true);
set(handles.options, 'userdata',options);

set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));
%%


%% display directed transfer function graphics.
axes(handles.sceneaxes);
cla;
hold on;

displayDTFG(model, options, dtf);
set(handles.sceneaxes,'userdata',model);
%%

%% display directed transfer function matrix.
axes(handles.imageaxes);

xlabelpositions = 1:nroi;
ylabelpositions = 1:nroi;
xlabels = num2str(dtf.rois');
yLabels = flipud(num2str(dtf.rois'));

set(handles.imageaxes,'userdata',dtf,...
      'Xlim',[0 nroi+1],...
      'xtick',xlabelpositions,...% where to display the labels.
      'Ylim',[0 nroi+1],...
      'YTick',ylabelpositions,...
      'XTickLabel', xlabels,...% the labels to be displayed
      'YTickLabel', yLabels,...
      'TickLength',[.005 .005]);
cla;
hold on;

plotimage = flipud(dtf.matrix);
imagesc(plotimage,'tag','image');
for i=0:nroi
    lx = [0.5 nroi+0.5];
    ly = i+0.5;
    ly = [ly ly];
    plot(lx,ly,'k');
    plot(ly,lx,'k');
end

caxis([valmin  valmax]);
colorbar;


%% Mouse motion callback function.
function mousemotionCallback(src, evnt) 
hfig = gcf;
imageaxes = findobj(hfig,'tag','imageaxes'); 
sceneaxes = findobj(hfig,'tag','sceneaxes');
textvalue = findobj(hfig,'tag','textvalue');
     
if isempty(imageaxes)
    return;
end

currentxlim = get(imageaxes, 'Xlim');
currentylim = get(imageaxes, 'Ylim');
imagexlim = [currentxlim(1,1)+0.5 currentxlim(1,2)-0.5];
imageylim = [currentylim(1,1)+0.5 currentylim(1,2)-0.5];
mousepos = get(imageaxes, 'currentpoint');
     
% if the mouse is not in the image region, display nothing.
if mousepos(1,1) < imagexlim(1,1) | mousepos(1,1) > imagexlim(1,2)  | ...
   mousepos(1,2) < imageylim(1,1) | mousepos(1,2) > imageylim(1,2)
   set(textvalue,'string','');
   return;
end

% display the value corresponding to the mouse position.
dtf = get(imageaxes,'userdata');
nroi = size(dtf.matrix,1);

idxx = ceil(mousepos(1,1)-imagexlim(1,1));
if idxx<1 | idxx>nroi
    return;
end

idxy = ceil(mousepos(1,2)-imageylim(1,1));
idxy = nroi-idxy +1;
if idxy<1 | idxy>nroi
    return;
end

% get the connectivity value.
convalue = dtf.matrix(idxy,idxx);

model = get(sceneaxes,'userdata');

% get the outflow roi and inflow roi
inputroi = model.roilabels{idxx};
outputroi = model.roilabels{idxy};

set(textvalue,'string',[inputroi ' --> ' outputroi ': ' num2str(convalue,'%6f')]);

%%

%% Mouse down callback function.
function mousedownCallback(src, evnt)
hfig = gcf;
imageaxes = findobj(hfig, 'tag','imageaxes'); 
sceneaxes = findobj(hfig, 'tag','sceneaxes');
optionshandle = findobj(hfig, 'tag','options');
textvalue = findobj(hfig,'tag','textvalue');

options = get(optionshandle,'userdata');

if ~options.dtf
    return;
end

if ~isequal(options.channels,'single')
    return;
end

currentxlim = get(imageaxes, 'Xlim');
currentylim = get(imageaxes, 'Ylim');
imagexlim = [currentxlim(1,1)+0.5 currentxlim(1,2)-0.5];
imageylim = [currentylim(1,1)+0.5 currentylim(1,2)-0.5];
mousepos = get(imageaxes, 'currentpoint');
     
% if the mouse is not in the image region, display nothing.
if mousepos(1,1) < imagexlim(1,1) | mousepos(1,1) > imagexlim(1,2)  | ...
   mousepos(1,2) < imageylim(1,1) | mousepos(1,2) > imageylim(1,2)
   return;
end

% display the value corresponding to the mouse position.
dtf = get(imageaxes,'userdata');
nroi = size(dtf.matrix,1);

idxx = ceil(mousepos(1,1)-imagexlim(1,1));
if idxx<1 | idxx>nroi
    return;
end

idxy = ceil(mousepos(1,2)-imageylim(1,1));
idxy = nroi-idxy +1;
if idxy<1 | idxy>nroi
    return;
end

model = get(sceneaxes,'userdata');

if isequal(options.dispmodes,'out2in')
    options.whichchannel = [idxy idxx];
elseif isequal(options.dispmodes,'outflow')
    options.whichchannel = idxx;
    outflow = sum(dtf.matrix(:,idxx))/(size(dtf.matrix,1)-1);
    inputroi = model.roilabels{idxx};
    set(textvalue,'string',[inputroi ' --> : ' num2str(outflow,'%6f')]);
else 
    options.whichchannel = idxy;
    inflow = sum(dtf.matrix(idxy,:))/(size(dtf.matrix,1)-1);
    outputroi = model.roilabels{idxy};
    set(textvalue,'string',[outputroi ' <-- : ' num2str(inflow,'%6f')]);
end

set(optionshandle, 'userdata', options);

% display DTF graphics.
axes(sceneaxes);
cla;
hold on;

displayDTFG(model, options, dtf);
%%


% --- Executes on button press in checkboxskin.
function checkboxskin_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxskin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxskin

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');
options.isskin = get(hObject,'value');
set(handles.options, 'userdata', options);

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in checkboxcortex.
function checkboxcortex_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxcortex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxcortex

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');
options.iscortex = get(hObject,'value');
set(handles.options, 'userdata', options);

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in checkboxlabels.
function checkboxlabels_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxlabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxlabels

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');
options.islabel = get(hObject,'value');
set(handles.options, 'userdata', options);

if options.dtf == false
    return;
end

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in pushbuttonupdate.
function pushbuttonupdate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonupdate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get options.
options = get(handles.options,'userdata');

if ~options.dtf
    return;
end

valmin = str2num( get(handles.editmin,'string') );
valmax = str2num( get(handles.editmax,'string') );

% if the limit was not changed
if abs(valmin-options.displimits(1))<1e-6 && abs(valmax-options.displimits(2))<1e-6
    return;
end

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% make sure the input limit is in the default limit.
if isequal(options.dispmodes,'out2in')
    defaultvalmin = min(min(dtf.matrix));
    defaultvalmax = max(max(dtf.matrix));
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(dtf.matrix,1)/(size(dtf.matrix,1)-1);
    defaultvalmax = max(outflows);
    defaultvalmin = min(outflows);
else
    inflows = sum(dtf.matrix,2)/(size(dtf.matrix,1)-1);
    defaultvalmax = max(inflows);
    defaultvalmin = min(inflows);
end

if isnan(defaultvalmin)
    defaultvalmin = 0.001;
end
if isnan(defaultvalmax)
    defaultvalmax = 1;
end
valmin = min(max(defaultvalmin, valmin), defaultvalmax);
valmax = min(max(defaultvalmin, valmax), defaultvalmax);

% update the limit
options.displimits = [valmin, valmax];
options.minmax = [valmin, valmax];
set(handles.options, 'userdata', options);

set( handles.editmin, 'string', num2str(options.displimits(1),'%6f') );
set( handles.editmax, 'string', num2str(options.displimits(2),'%6f') );

% get model
model = get(handles.sceneaxes,'userdata');

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in pushbuttondefault.
function pushbuttondefault_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttondefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');

if ~options.dtf
    return;
end

% get default min and max values.
if isequal(options.dispmodes,'out2in')
    valmin = min(min(dtf.matrix));
    valmax = max(max(dtf.matrix));
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(dtf.matrix,1)/(size(dtf.matrix,1)-1);
    valmax = max(outflows);
    valmin = min(outflows);
else
    inflows = sum(dtf.matrix,2)/(size(dtf.matrix,1)-1);
    valmax = max(inflows);
    valmin = min(inflows);
end

if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end

% update the limit
if isequal(options.dispmodes,'out2in')
    options.displimits = [(valmax+valmin)/2, valmax];
else
    options.displimits = [valmin, valmax];
end 

options.minmax = [valmin, valmax];
set(handles.options, 'userdata', options);

set( handles.editmin, 'string', num2str(options.displimits(1),'%6f') );
set( handles.editmax, 'string', num2str(options.displimits(2),'%6f') );

% get model
model = get(handles.sceneaxes,'userdata');

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in radiobuttonall.
function radiobuttonall_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonall

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');
if get(hObject,'value')
    options.channels = 'all';
end
set(handles.options, 'userdata', options);

if ~options.dtf
    return;
end

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in radiobuttonsingle.
function radiobuttonsingle_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonsingle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonsingle

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');

if get(hObject,'value')
    options.channels = 'single';   
    if isequal(options.dispmodes,'out2in')
        maxvalue = max(max(dtf.matrix));
        [row col] = find(dtf.matrix==maxvalue, 1);
        options.whichchannel = [row col];
    elseif isequal(options.dispmodes,'outflow')
        outflows = sum(dtf.matrix,1)/(size(dtf.matrix,1)-1);
        valmax = max(outflows);
        options.whichchannel = find(outflows==valmax, 1);
    else
        inflows = sum(dtf.matrix,2)/(size(dtf.matrix,1)-1);
        valmax = max(inflows);
        options.whichchannel = find(inflows==valmax, 1);        
    end
end
set(handles.options, 'userdata', options);

if ~options.dtf
    return;
end

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in radiobuttonnone.
function radiobuttonnone_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonnone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonnone

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');
if get(hObject,'value')
    options.channels = 'none';
end
set(handles.options, 'userdata', options);

if ~options.dtf
    return;
end

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

% --- Executes on button press in radiobuttonout2in.
function radiobuttonout2in_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonout2in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonout2in
% change options accordingly.

options = get(handles.options,'userdata');

if ~options.dtf
    return;
end

if ~get(hObject,'value')
    return;
end

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

options.dispmodes = 'out2in';

if isequal(options.channels,'single')   
    maxvalue = max(max(dtf.matrix));
    [row col] = find(dtf.matrix==maxvalue, 1);
    options.whichchannel = [row col];        
end

mat = dtf.matrix;
valmin = min(min(mat));
valmax = max(max(mat));
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end

options.minmax = [valmin, valmax];
options.displimits = [(valmax+valmin)/2, valmax];
set(handles.options, 'userdata',options);
set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);

set(handles.sceneaxes,'userdata',model);

% --- Executes on button press in radiobuttonoutflow.
function radiobuttonoutflow_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonoutflow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonoutflow

% change options accordingly.
options = get(handles.options,'userdata');

if ~options.dtf
    return;
end

if ~get(hObject,'value')
    return;
end

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

options.dispmodes = 'outflow';
outflows = sum(dtf.matrix,1)/(size(dtf.matrix,1)-1);
% outflows(~outflows) = nan;
valmax = max(outflows);
valmin = min(outflows);
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end
options.minmax = [valmin, valmax];
options.displimits = [valmin, valmax];
options.whichchannel = find(outflows==valmax, 1);
set(handles.options, 'userdata', options);

set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);
set(handles.sceneaxes,'userdata',model);

% --- Executes on button press in radiobuttoninflow.
function radiobuttoninflow_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttoninflow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttoninflow
% change options accordingly.
options = get(handles.options,'userdata');

if ~options.dtf
    return;
end

if ~get(hObject,'value')
    return;
end

% get model
model = get(handles.sceneaxes,'userdata');

% get dtf matrix and corresponding ROIs
dtf = get(handles.imageaxes,'userdata');

options.dispmodes = 'inflow';
inflows = sum(dtf.matrix,2)/(size(dtf.matrix,1)-1);
% inflows(~inflows) = nan;
valmax = max(inflows);
valmin = min(inflows);
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end
options.minmax = [valmin, valmax];
options.displimits = [valmin, valmax];
options.whichchannel = find(inflows==valmax, 1);
set(handles.options, 'userdata', options);

set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);
set(handles.sceneaxes,'userdata',model);

%% ========================================================================
%% The function for displaying the directed transfer function graphics.
function  displayDTFG(model, options, dtf)

% display the skin surface.
if options.isskin
    if options.usebem == 0
        patch('SpecularStrength',0,'DiffuseStrength',0.8,...
        'FaceLighting','phong',...
        'Vertices',model.skin.Vertices,...
        'LineStyle','none',...
        'Faces',model.skin.Faces,...
        'FaceColor','interp',...
        'EdgeColor','none',...
        'FaceVertexCData',model.skin.FaceVertexCData);
    end
end

% parameters for the display of cortex, labels, and dtf graphics. 
rois = dtf.rois;
nroi = length(rois);
roilab = model.roilabels;
roipos = model.roipos;

cmap = ROIcolors(nroi);
    
if options.iscortex
    % make different vertices in different cortex ROIs different colors (left and right are the same color)
    cortexFaceVertexCData = model.cortex.FaceVertexCData;
    
    if isequal(options.type,'ROI')
        for i=1:nroi
            roi_vert_idx = model.vertices{i};
            cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
        end
    end

    % display the cortex with different ROIs having different colors.
    patch('SpecularStrength',0,'DiffuseStrength',0.8,...
    'FaceLighting','phong',...
    'Vertices',model.cortex.Vertices,...
    'LineStyle','none',...
    'Faces',model.cortex.Faces,...
    'FaceColor','interp',...
    'EdgeColor','none',...
    'FaceVertexCData',cortexFaceVertexCData);
end

if options.islabel
    if isequal(options.channels,'single') 
        if isequal(options.dispmodes, 'out2in')
            rr = options.whichchannel(1);
            cc = options.whichchannel(2);
            
            linestart = roipos(rr, :);
            lineend = [linestart(1)*2.2, linestart(2)*1.2, linestart(3)*2.5];  
            plot3([linestart(1) lineend(1)], [linestart(2) lineend(2)], [linestart(3) lineend(3)],'LineWidth',1.2,'color', 'k');
            A = text(lineend(1), lineend(2), lineend(3), char(roilab{rr}), ... 
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 8);
            set(A, 'interpreter', 'none');
            
            linestart = roipos(cc, :);
            lineend = [linestart(1)*2.2, linestart(2)*1.2, linestart(3)*2.5];  
            plot3([linestart(1) lineend(1)], [linestart(2) lineend(2)], [linestart(3) lineend(3)],'LineWidth',1.2,'color', 'k');
            A = text(lineend(1), lineend(2), lineend(3), char(roilab{cc}), ... 
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 8);
            set(A, 'interpreter', 'none');            
        else
            i = options.whichchannel;
            
            linestart = roipos(i,:);
            lineend = [linestart(1)*2.2, linestart(2)*1.2, linestart(3)*2.5];  
            plot3([linestart(1) lineend(1)], [linestart(2) lineend(2)], [linestart(3) lineend(3)],'LineWidth',1.2,'color', 'k');
            A = text(lineend(1), lineend(2), lineend(3), char(roilab{i}), ... 
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 8);
            set(A, 'interpreter', 'none');
        end
    else
        for i = 1:nroi            
            linestart = roipos(i, :);
            lineend = [linestart(1)*2.2, linestart(2)*1.2, linestart(3)*2.5];  
            plot3([linestart(1) lineend(1)], [linestart(2) lineend(2)], [linestart(3) lineend(3)],'LineWidth',1.2,'color', 'k');
            A = text(lineend(1), lineend(2), lineend(3), char(roilab{i}), ... 
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 8);
            set(A, 'interpreter', 'none');
        end
    end
end

% axis manual;

if options.dtf      
    if isequal(options.type,'ROI')
        ArrowSizeLimit = [1 5];
        SphereSizeLimit = [5 10];
    else
        ArrowSizeLimit = [0.5  3.5];
        SphereSizeLimit = [3 8];
    end
    opt = struct(  'Channels', options.channels,...
                              'Whichchannel', options.whichchannel,...
                              'ValLim', options.displimits,...
                              'ArSzLt',ArrowSizeLimit,...
                              'SpSzLt',SphereSizeLimit);
                          
    if isequal(options.dispmodes, 'out2in')
        drawdtfconngraph(dtf.matrix,roipos,opt);
    elseif isequal(options.dispmodes, 'outflow')
        outflows = sum(dtf.matrix,1)/(size(dtf.matrix,1)-1);
        drawdtfflowgraph(outflows,roipos,opt);
    else % 'inflow
        inflows = sum(dtf.matrix,2)/(size(dtf.matrix,1)-1);
        drawdtfflowgraph(inflows,roipos,opt);
    end
end

%set(gcf,'renderer','zbuffer');
%set(gcf,'renderer','openGL');
lightcolor = [0.6 0.6 0.6];
lighting phong; % gouraud
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
%% ========================================================================

sceneaxes = findobj(gcf,'tag','sceneaxes');
scenecolorbar = getappdata(gcf,'scenecolorbar');
if scenecolorbar
    delete(scenecolorbar);
end

if isfield(options,'minmax')
    caxis(options.minmax);
    scenecolorbar = colorbar('peer',sceneaxes,'location','WestOutside');
    setappdata(gcf,'scenecolorbar',scenecolorbar);
end

drawnow;

% --- Executes on slider movement.
function sliderfrequency_Callback(hObject, eventdata, handles)
% hObject    handle to sliderfrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

options = get(handles.options,'userdata');
if ~options.dtf
    return;
end

currentf = round(get(hObject,'value'));
set(handles.frequencyedit,'string', num2str(currentf));
set(hObject,'value',currentf);
currentt = round(get(handles.slider_time,'value'));

% get model
model = get(handles.sceneaxes,'userdata');

frequency = get(handles.textfrequency,'userdata');
dtfmatrixs = get(handles.cortexdtfgui, 'userdata');
currentfidx = currentf-frequency(1)+1;

if options.isadtf
    currentdtfmatrix = squeeze(dtfmatrixs(currentt,:,:,currentfidx));
else
    currentdtfmatrix = dtfmatrixs(:,:,currentfidx);
end

dtf = get(handles.imageaxes,'userdata');
dtf.matrix = currentdtfmatrix;
set(handles.imageaxes, 'userdata', dtf);

if isequal(options.dispmodes,'out2in')
    valmin = min(min(currentdtfmatrix));
    valmax = max(max(currentdtfmatrix));
    [row col] = find(currentdtfmatrix==valmax, 1);
    options.whichchannel = [row col];
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(currentdtfmatrix,1)/(size(currentdtfmatrix,1)-1);
    valmax = max(outflows);
    valmin = min(outflows);
    options.whichchannel = find(outflows==valmax, 1);
else
    inflows = sum(currentdtfmatrix,2)/(size(currentdtfmatrix,1)-1);
    valmax = max(inflows);
    valmin = min(inflows);
    options.whichchannel = find(inflows==valmax, 1);
end

if isequal(options.dispmodes,'out2in')
    options.displimits = [(valmax+valmin)/2, valmax];
else
    options.displimits = [valmin, valmax];
end 

options.minmax = [valmin, valmax];
set(handles.options, 'userdata',options);
set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);
set(handles.sceneaxes,'userdata',model);

% display directed transfer function matrix.
axes(handles.imageaxes);
cla;  
box off;
axis on;
hold on;

plotimage = flipud(currentdtfmatrix);
imagesc(plotimage,'tag','dtfimage');

vnum = size(currentdtfmatrix,1);
for i=0:vnum
    lx = [0.5 vnum+0.5];
    ly = i+0.5;
    ly = [ly ly];
    plot(lx,ly,'k');
    plot(ly,lx,'k');
end

cmin = min(min(currentdtfmatrix));
cmax = max(max(currentdtfmatrix));
caxis([cmin cmax]);
colorbar;

% --- Executes during object creation, after setting all properties.
function sliderfrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderfrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function frequencyedit_Callback(hObject, eventdata, handles)
% hObject    handle to frequencyedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frequencyedit as text
%        str2double(get(hObject,'String')) returns contents of frequencyedit as a double


% --- Executes during object creation, after setting all properties.
function frequencyedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frequencyedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Untitled_2_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function menu_export_dtf_Callback(hObject, eventdata, handles)
% hObject    handle to menu_export_dtf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

options = get(handles.options,'userdata');
if options.dtf ~= true
    helpdlg('There is no DTF!');
    return;
end

[name, pathstr] = uiputfile('*.mat','Save DTF/ADTF Properties');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

model = get(handles.sceneaxes,'userdata');
frequency = get(handles.textfrequency,'userdata');
matrix = get(handles.cortexdtfgui, 'userdata');

% DTF properties
DTF.labels = model.roilabels;
DTF.locations = model.roipos;
DTF.frequency = frequency;
DTF.matrix = matrix;
DTF.type = options.type;
DTF.isadtf = options.isadtf;
DTF.srate = options.srate;

if isequal(options.type,'ROI')
    DTF.vertices = model.vertices;
end

save(Fullfilename, 'DTF');


% --------------------------------------------------------------------
function loadecog_Callback(hObject, eventdata, handles)
% hObject    handle to loadecog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

matrix = get(handles.cortexdtfgui, 'userdata');
if ~isempty(matrix)    
    importevent = questdlg('Exist DTF, import new one ?','','Yes','Cancel','Cancel');
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

output = pop_dtf_computation(ECOG.data, ECOG.srate);

if isempty(output.dtfmatrixs)
    return;
end

rois = 1:ECOG.nbchan;
labels = {};
locations = zeros(ECOG.nbchan,3);
for i = 1:ECOG.nbchan
    labels = [labels; ECOG.labels(i)];
    locations(i,1) = ECOG.locations(i).X;
    locations(i,2) = ECOG.locations(i).Y;
    locations(i,3) = ECOG.locations(i).Z;
end

options = get(handles.options,'userdata');
model = get(handles.sceneaxes,'userdata');

model.roilabels = labels;
model.roipos = locations;

% get current frequency and matrix
currentf = output.frequency(1);
dtf = get(handles.imageaxes,'userdata');
dtf.rois = rois;
if output.isadtf   
    % set time slider
    enable_time_options(true);
    num = size(output.dtfmatrixs,1);
    sp = round(num/2);
    set(handles.text_time,'string', ['Current Time (' num2str(1/output.srate) ' ~ ' num2str(num/output.srate) ' s):']);
    set(handles.timeedit,'string', num2str(sp/output.srate));
    sliderstep = 1/(num-1);
    set(handles.slider_time,'min',1,'max',num,'sliderstep',[sliderstep sliderstep],'value',sp);
    options.points = num;
    
    dtf.matrix = squeeze(output.dtfmatrixs(sp,:,:,1));
else
    dtf.matrix = output.dtfmatrixs(:,:,1);
    enable_time_options(false);
end
enable_specific(true);
enable_band(false);
set(handles.pop_band,'value',1);

% set default frequency band
set(handles.editbandmin,'string',num2str(output.frequency(1)));
set(handles.editbandmax,'string',num2str(output.frequency(2)));

% update frequency scope and current frequency
set(handles.textfrequency,'string', ['Current Frequeny (' num2str(output.frequency(1)) ' ~ ' num2str(output.frequency(2)) '):']);
set(handles.frequencyedit,'string', num2str(currentf));
sliderstep = 1/(output.frequency(2)-output.frequency(1));
set(handles.sliderfrequency,'min',output.frequency(1),'max',output.frequency(2),'sliderstep',[sliderstep sliderstep],'value',currentf);

set(handles.textfrequency,'userdata', output.frequency);
set(handles.cortexdtfgui, 'userdata', output.dtfmatrixs);

% update options
options.dtf = 1;
options.type = 'Single Point';
options.isadtf = output.isadtf;
options.srate = output.srate;
valmin = min(min(dtf.matrix));
valmax = max(max(dtf.matrix));
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end
options.minmax = [valmin, valmax];
options.displimits = [(valmax+valmin)/2, valmax];
options.dispmodes = 'out2in';
set(handles.radiobuttonout2in,'value',true);
options.channels = 'all';
set(handles.radiobuttonall,'value',true);
set(handles.options, 'userdata',options);

set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;

% display the DTF graphics
displayDTFG(model, options, dtf);
set(handles.sceneaxes,'userdata',model);

%% display directed transfer function matrix.
axes(handles.imageaxes);

xlabels = num2str(dtf.rois');
yLabels = flipud(num2str(dtf.rois'));
nroi = size(rois,2);
set(handles.imageaxes,'userdata',dtf,...
      'Xlim',[0 nroi+1],...
      'xtick',dtf.rois,...% where to display the labels.
      'Ylim',[0 nroi+1],...
      'YTick',dtf.rois,...
      'XTickLabel', xlabels,...% the labels to be displayed
      'YTickLabel', yLabels,...
      'TickLength',[.005 .005]);

cla;  
box off;
axis on;
hold on;

plotimage = flipud(dtf.matrix);
imagesc(plotimage,'tag','dtfimage');

for i=0:nroi
    lx = [0.5 nroi+0.5];
    ly = i+0.5;
    ly = [ly ly];
    plot(lx,ly,'k');
    plot(ly,lx,'k');
end

caxis([valmin valmax]);
colorbar;


% --- Executes on button press in pb_average.
function pb_average_Callback(hObject, eventdata, handles)
% hObject    handle to pb_average (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
options = get(handles.options,'userdata');
if ~options.dtf
    return;
end

currentt = round(get(handles.slider_time,'value'));
frequency = get(handles.textfrequency,'userdata');
% set(handles.frequencyedit,'string', [num2str(frequency(1)) '~' num2str(frequency(2))]);
minf = str2num(get(handles.editbandmin,'string'));
maxf = str2num(get(handles.editbandmax,'string'));
minf = min(max(minf,frequency(1)), frequency(2));
maxf = min(max(maxf,frequency(1)), frequency(2));
minf = minf-frequency(1)+1;
maxf = maxf-frequency(1)+1;

% get model
model = get(handles.sceneaxes,'userdata');
dtfmatrixs = get(handles.cortexdtfgui, 'userdata');

% compute integrated DTF/ADTF
if options.isadtf
    tempmatrix = squeeze(dtfmatrixs(currentt,:,:,minf:maxf));
else
    tempmatrix = dtfmatrixs(:,:,minf:maxf);
end
currentdtfmatrix = mean(tempmatrix,3);

dtf = get(handles.imageaxes,'userdata');
dtf.matrix = currentdtfmatrix;
set(handles.imageaxes, 'userdata', dtf);

if isequal(options.dispmodes,'out2in')
    valmin = min(min(currentdtfmatrix));
    valmax = max(max(currentdtfmatrix));
    [row col] = find(currentdtfmatrix==valmax, 1);
    options.whichchannel = [row col];
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(currentdtfmatrix,1)/(size(currentdtfmatrix,1)-1);
    valmax = max(outflows);
    valmin = min(outflows);
    options.whichchannel = find(outflows==valmax, 1);
else
    inflows = sum(currentdtfmatrix,2)/(size(currentdtfmatrix,1)-1);
    valmax = max(inflows);
    valmin = min(inflows);
    options.whichchannel = find(inflows==valmax, 1);
end

if isequal(options.dispmodes,'out2in')
    options.displimits = [(valmax+valmin)/2, valmax];
else
    options.displimits = [valmin, valmax];
end 

options.minmax = [valmin, valmax];
set(handles.options, 'userdata',options);
set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
axes(handles.sceneaxes);
cla;
hold on;
displayDTFG(model, options, dtf);
set(handles.sceneaxes,'userdata',model);

% display directed transfer function matrix.
axes(handles.imageaxes);
cla;  
box off;
axis on;
hold on;

plotimage = flipud(currentdtfmatrix);
imagesc(plotimage,'tag','dtfimage');

vnum = size(currentdtfmatrix,1);
for i=0:vnum
    lx = [0.5 vnum+0.5];
    ly = i+0.5;
    ly = [ly ly];
    plot(lx,ly,'k');
    plot(ly,lx,'k');
end

cmin = min(min(currentdtfmatrix));
cmax = max(max(currentdtfmatrix));
caxis([cmin cmax]);
colorbar;



% --------------------------------------------------------------------
function popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_graphics_Callback(hObject, eventdata, handles)
% hObject    handle to menu_graphics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.sceneaxes, 'Information Flow Graphics');

% --------------------------------------------------------------------
function Untitled_4_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_matrix_Callback(hObject, eventdata, handles)
% hObject    handle to menu_matrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capaxis(handles.imageaxes, 'Information Flow Image',1);


% --- Executes on slider movement.
function slider_time_Callback(hObject, eventdata, handles)
% hObject    handle to slider_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
options = get(handles.options,'userdata');
if ~options.dtf
    return;
end

currentt = round(get(hObject,'value'));
set(handles.timeedit,'string', num2str(currentt / options.srate));
set(hObject,'value',currentt);

rb_specific = get(handles.rb_specific,'Value');
if rb_specific
    sliderfrequency_Callback(handles.sliderfrequency,[],handles);
else
    pb_average_Callback(handles.pb_average,[],handles);
end

% --- Executes during object creation, after setting all properties.
function slider_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function timeedit_Callback(hObject, eventdata, handles)
% hObject    handle to timeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeedit as text
%        str2double(get(hObject,'String')) returns contents of timeedit as a double


% --- Executes during object creation, after setting all properties.
function timeedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_movie.
function pb_movie_Callback(hObject, eventdata, handles)
% hObject    handle to pb_movie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
options = get(handles.options,'userdata');
if ~options.dtf
    return;
end

hfig = gcf;
ismovie = 1;
setappdata(hfig,'movie',ismovie);
currentt = round(get(handles.slider_time,'value'));

t = 2;    
j = 0;
for i = currentt : t : options.points
    set(handles.slider_time,'value',i);
    slider_time_Callback(handles.slider_time, eventdata, handles);
    
    j = j+1;
    mov(j) = getframe(handles.sceneaxes); % get frames to generate movie file
    
    pause(0.01);
    ismovie = getappdata(hfig,'movie');
    if ~ismovie
        break;
    end
end
playmov(mov, 'Time-Varying Cortical Connectivity');

% --- Executes on button press in rb_band.
function rb_band_Callback(hObject, eventdata, handles)
% hObject    handle to rb_band (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_band
rb_band = get(hObject,'Value');
if ~rb_band
    return;
end

hfig = gcf;
rb_specific = findobj(hfig,'tag','rb_specific');
set(rb_specific,'Value',0);
enable_band(true);
enable_specific(false);

pop_band_Callback(handles.pop_band, [], handles);
pb_average_Callback(handles.pb_average, [], handles);

function editbandmax_Callback(hObject, eventdata, handles)
% hObject    handle to editbandmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editbandmax as text
%        str2double(get(hObject,'String')) returns contents of editbandmax as a double
frequency = get(handles.textfrequency,'userdata');
bandmax = str2num(get(hObject,'string'));
if isempty(bandmax)
    helpdlg('The input must be numerical');
    if ~isempty(frequency)
        set(hObject,'string',num2str(frequency(2)));
    else
        set(hObject,'string',num2str(1));
    end
    return;
end

% --- Executes during object creation, after setting all properties.
function editbandmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editbandmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editbandmin_Callback(hObject, eventdata, handles)
% hObject    handle to editbandmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editbandmin as text
%        str2double(get(hObject,'String')) returns contents of editbandmin as a double
frequency = get(handles.textfrequency,'userdata');
bandmin = str2num(get(hObject,'string'));
if isempty(bandmin)
    helpdlg('The input must be numerical');
    if ~isempty(frequency)
        set(hObject,'string',num2str(frequency(1)));
    else
        set(hObject,'string',num2str(0));
    end
    return;
end

% --- Executes during object creation, after setting all properties.
function editbandmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editbandmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_band.
function pop_band_Callback(hObject, eventdata, handles)
% hObject    handle to pop_band (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns pop_band contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_band
frequency = get(handles.textfrequency,'userdata');
if isempty(frequency)
    helpdlg('The frequency band is empty!');
    return;
end

% set frequency band
idx = get(hObject,'Value');
switch idx 
    case 1 
        minf = frequency(1);
        maxf = frequency(2);
    case 2 % delta band 1~4
        if frequency(1)>4 | frequency(2)<1
            helpdlg('Can NOT find DTF/ADTF values for the delta band 1~4 !');
            return;
        end
        minf = max(1, frequency(1));
        maxf = min(4, frequency(2));
    case 3 % theta band 4~7
        if frequency(1)>7 | frequency(2)<4
            helpdlg('Can NOT find DTF/ADTF values for the theta band 4~7 !');
            return;
        end
        minf = max(4, frequency(1));
        maxf = min(7, frequency(2));
    case 4 % alpha band 8~12
        if frequency(1)>12 | frequency(2)<8
            helpdlg('Can NOT find DTF/ADTF values for the alpha band 8~12 !');
            return;
        end
        minf = max(8, frequency(1));
        maxf = min(12, frequency(2));
    case 5 % beta band 12~30
        if frequency(1)>30 | frequency(2)<12
            helpdlg('Can NOT find DTF/ADTF values for the beta band 12~30 !');
            return;
        end
        minf = max(12, frequency(1));
        maxf = min(30, frequency(2));
    case 6 % gamma band 30~100
        if frequency(1)>100 | frequency(2)<30
            helpdlg('Can NOT find DTF/ADTF values for the gamma band 30~100 !');
            return;
        end
        minf = max(30, frequency(1));
        maxf = min(100, frequency(2));
end
set(handles.editbandmin,'string',num2str(minf));
set(handles.editbandmax,'string',num2str(maxf)); 

% --- Executes during object creation, after setting all properties.
function pop_band_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_band (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ---------------------------------------------------------------------------
function enable_time_options(enable)
hfig = gcf;
pb_movie = findobj(hfig,'Tag','pb_movie');
slider_time = findobj(hfig,'Tag','slider_time');
text_time = findobj(hfig,'Tag','text_time');
timeedit = findobj(hfig,'Tag','timeedit');
if enable
    set(pb_movie,'Enable','on');
    set(slider_time,'Enable','on');
    set(text_time,'Enable','on');
    set(timeedit,'Enable','on');
else
    set(pb_movie,'Enable','off');
    set(slider_time,'Enable','off');    
    set(text_time,'Enable','off');
    set(timeedit,'Enable','off');
end

function enable_specific(enable)
hfig = gcf;
rb_specific = findobj(hfig,'Tag','rb_specific');
sliderfrequency = findobj(hfig,'Tag','sliderfrequency');
textfrequency = findobj(hfig,'Tag','textfrequency');
frequencyedit = findobj(hfig,'Tag','frequencyedit');
if enable
    set(sliderfrequency,'Enable','on');
    set(textfrequency,'Enable','on');
    set(frequencyedit,'Enable','on');
    set(rb_specific,'value',1);
else
    set(sliderfrequency,'Enable','off');
    set(textfrequency,'Enable','off');    
    set(frequencyedit,'Enable','off');
    set(rb_specific,'value',0);
end

function enable_band(enable)
hfig = gcf;
rb_band = findobj(hfig,'Tag','rb_band');
pop_band = findobj(hfig,'Tag','pop_band');
textbandmin = findobj(hfig,'Tag','textbandmin');
editbandmin = findobj(hfig,'Tag','editbandmin');
textbandmax = findobj(hfig,'Tag','textbandmax');
editbandmax = findobj(hfig,'Tag','editbandmax');
pb_average = findobj(hfig,'Tag','pb_average');
if enable
    set(pop_band,'Enable','on');
    set(textbandmin,'Enable','on');
    set(editbandmin,'Enable','on');
    set(textbandmax,'Enable','on');
    set(editbandmax,'Enable','on');
    set(pb_average,'Enable','on');
    set(rb_band,'value',1);
else
    set(pop_band,'Enable','off');
    set(textbandmin,'Enable','off');    
    set(editbandmin,'Enable','off');
    set(textbandmax,'Enable','off');
    set(editbandmax,'Enable','off');
    set(pb_average,'Enable','off');
    set(rb_band,'value',0);
end


% --- Executes on button press in rb_specific.
function rb_specific_Callback(hObject, eventdata, handles)
% hObject    handle to rb_specific (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_specific
rb_specific = get(hObject,'Value');
if ~rb_specific
    return;
end

hfig = gcf;
rb_band = findobj(hfig,'tag','rb_band');
set(rb_band,'Value',0);
enable_specific(true);
enable_band(false);

sliderfrequency_Callback(handles.sliderfrequency, eventdata, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pb_movie.
function pb_movie_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pb_movie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
options = get(handles.options,'userdata');
if ~options.dtf
    return;
end

hfig = gcf;
ismovie = 0;
setappdata(hfig,'movie',ismovie);


% --- Executes during object creation, after setting all properties.
function text_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --------------------------------------------------------------------
function menu_outflow_Callback(hObject, eventdata, handles)
% hObject    handle to menu_outflow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
options = get(handles.options,'userdata');
if ~options.isadtf
    helpdlg('ADTF values are not available !');
    return;
end

dtfmatrixs = get(handles.cortexdtfgui, 'userdata');
frequency = get(handles.textfrequency,'userdata');
rb_specific = get(handles.rb_specific,'Value');
if rb_specific
    currentf = round(get(handles.sliderfrequency,'value'));
    TVFLOW.name = ['Time-Varying Outflows at the frequency ' num2str(currentf)];
    currentfidx = currentf-frequency(1)+1;
    tv_matrix = squeeze(dtfmatrixs(:,:,:,currentfidx));
else
    minf = str2num(get(handles.editbandmin,'string'));
    maxf = str2num(get(handles.editbandmax,'string'));
    minf = min(max(minf,frequency(1)), frequency(2));
    maxf = min(max(maxf,frequency(1)), frequency(2));
    TVFLOW.name = ['Time-Varying Outflows over the frequency band [' num2str(minf) '~' num2str(maxf) ']'];
    minf = minf-frequency(1)+1;
    maxf = maxf-frequency(1)+1;
    tempmatrix = dtfmatrixs(:,:,:,minf:maxf);
    tv_matrix = mean(tempmatrix,4);
end
adtf_outflows = squeeze( sum(tv_matrix,2)/(size(tv_matrix,2)-1) );

model = get(handles.sceneaxes,'userdata');

TVFLOW.labels = model.roilabels;
TVFLOW.flows = adtf_outflows;
TVFLOW.type = 'outflow';
TVFLOW.srate = options.srate;
tvflow(TVFLOW);

% --------------------------------------------------------------------
function Untitled_5_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_inflow_Callback(hObject, eventdata, handles)
% hObject    handle to menu_inflow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
options = get(handles.options,'userdata');
if ~options.isadtf
    helpdlg('ADTF values are not available !');
    return;
end

dtfmatrixs = get(handles.cortexdtfgui, 'userdata');
frequency = get(handles.textfrequency,'userdata');
rb_specific = get(handles.rb_specific,'Value');
if rb_specific
    currentf = round(get(handles.sliderfrequency,'value'));
    TVFLOW.name = ['Time-Varying Inflows at the frequency ' num2str(currentf)];
    currentfidx = currentf-frequency(1)+1;
    tv_matrix = squeeze(dtfmatrixs(:,:,:,currentfidx));
else
    minf = str2num(get(handles.editbandmin,'string'));
    maxf = str2num(get(handles.editbandmax,'string'));
    minf = min(max(minf,frequency(1)), frequency(2));
    maxf = min(max(maxf,frequency(1)), frequency(2));
    TVFLOW.name = ['Time-Varying Inflows over the frequency band [' num2str(minf) '~' num2str(maxf) ']'];
    minf = minf-frequency(1)+1;
    maxf = maxf-frequency(1)+1;
    tempmatrix = dtfmatrixs(:,:,:,minf:maxf);
    tv_matrix = mean(tempmatrix,4);
end
adtf_inflows = squeeze( sum(tv_matrix,3)/(size(tv_matrix,2)-1) );

model = get(handles.sceneaxes,'userdata');
TVFLOW.labels = model.roilabels;
TVFLOW.flows = adtf_inflows;
TVFLOW.type = 'inflow';
TVFLOW.srate = options.srate;
tvflow(TVFLOW);

