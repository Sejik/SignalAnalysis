function varargout = pop_sourceloc(varargin)
% pop_sourceloc - the GUI for computing cortical sources and creating ROIs.
%
% Usage: 
%            1. type 
%               >> pop_sourceloc(EEG)
%               or call pop_sourceloc(EEG) to start the popup GUI with EEG structure. 
%               The EEG structure should be pre-exported by the eegfc GUI 
%               or made by 
%               >> EEG = pop_txtreader  
%               or
%               >> EEG = pop_matreader
%               Please see the eConnectome Manual 
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable import EEG file formats (TXT and MAT).
%           
%            2. call pop_sourceloc(EEG) from the eegfc GUI ('Menu bar -> Inverse -> Source Imaging') 
%                if the EEG data is available in the eegfc GUI.
%
% Regularization Tools:
% The cortical source imaging methods implemented in the program are
% based on the Regularization Tools developed by P. C. Hansen. 
% See below for detailed description of the Regularization Tools: 
% P. C. Hansen, Regularization Tools Version 4.0 for Matlab 7.3, Numerical
% Algorithms, 46 (2007), pp. 189-194. 
% 'http://www2.imm.dtu.dk/~pch/Regutools/'
%
% Brain Model:
% The cortex model and BEM models used in the program are constructed based
% on the standard Montreal Neurological Institute (MNI) brain. 
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
% Yakang Dai, 15-June-2010 12:24:30
% Support source imaging with customized BEM model 
% and transfer matrix
%
% Yakang Dai, 24-May-2010 11:26:30
% Relocate datatip after selecting a ROI 
%
% Yakang Dai, 18-May-2010 17:32:30
% New functions: capture image, record and play movie
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_sourceloc_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_sourceloc_OutputFcn, ...
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


% --- Executes just before pop_sourceloc is made visible.
function pop_sourceloc_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_sourceloc (see VARARGIN)

% Choose default command line output for pop_sourceloc
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_sourceloc wait for user response (see UIRESUME)
% uiwait(handles.sourceloc);

len = length(varargin);

if len~=1
    errordlg('Input arguments mismatch!','Input error','modal');
    return;
end

EEG = varargin{1};
setappdata(hObject,'EEG',EEG);

set(hObject,'Toolbar','figure');
% set(hObject,'MenuBar','figure');
hToolbar = findall(hObject,'tag','FigureToolBar');
hButtons = findall(hToolbar);
set(hButtons,'Visible','off');
% sfhandle = findobj(hButtons,'tag','Standard.SaveFigure');
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
set(dcm_obj,'DisplayStyle','datatip','SnapToDataVertex','on','Enable','off');
setappdata(hObject,'datacursor',dcm_obj);

axcolor = get(hObject, 'color');
set(handles.tsaxes, 'color', axcolor);
set(handles.cortexaxes, 'color', axcolor);
set(handles.cortexaxes, 'DataAspectRatio',[1 1 1]);
set(handles.skinaxes, 'color', axcolor);
set(handles.skinaxes, 'DataAspectRatio',[1 1 1]);
axes(handles.skinaxes);
axis off;
axes(handles.cortexaxes);
axis off;


%% initialize time series
axes(handles.tsaxes);

% the limitation in the x axis
xlimit = EEG.points;    
xlabelstep = round(xlimit/10);
    
% x labels
xlabelpositions = [0:xlabelstep:xlimit];
xlabels = [0:xlabelstep:xlimit]./ EEG.srate;
xlabels = num2str(xlabels');
     
% y labels
nbvidx = length(EEG.vidx);
channelmaxs = max(EEG.data(EEG.vidx,:),[ ],2);
channelmins = min(EEG.data(EEG.vidx,:),[ ],2);    
spacing = mean(channelmaxs-channelmins);  
ylimit = (nbvidx+1)*spacing;
ylabelpositions = [0:spacing:nbvidx*spacing];    
YLabels = strvcat(EEG.labels(EEG.vidx)); 
YLabels = flipud(str2mat(YLabels,''));

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
for i = 1:nbvidx
	plot(EEG.data(EEG.vidx(nbvidx-i+1),:)+i*spacing,'color', tmpcolor, 'clipping','on');
end
%%

%% initialize skin and cortex
% get models
model.italyskin = load('italyskin.mat');
model.cutskin = load('cutskin.mat');
model.italyskinxy = load('italyskin-in-xy.mat');
model.italyskinxyz = load('italyskin-in-xyz.mat');
model.colinbemskin = load('colinbemskin.mat');
model.cortex = load('colincortex.mat');
model.bemcortex = load('colinbemcortex.mat');
model.neighbors = load('neighbors.mat');

transmatrix = load('LargeTransMatrix.mat'); % large transfer matrix for colin BEM skin and cortex 
k = cell2mat({EEG.locations(EEG.vidx).colinbemskinidx});
model.transmatrix = transmatrix.TransMatrix(k,:); % get transfer matrix for the electrodes
[model.U, model.s, model.V] = csvd(model.transmatrix);

% get electrode positions, labels and indices on the italyskin.
%=============================================
model.k = cell2mat({EEG.locations(EEG.vidx).italyskinidx});
model.electrodes.labels = EEG.labels(EEG.vidx);
model.electrodes.locations = model.italyskin.italyskin.Vertices(model.k,:);
model.X = model.italyskinxy.xy(model.k,1); % standard xy coordinates relative to electrodes on the skin
model.Y = model.italyskinxy.xy(model.k,2);   
zmin = min(model.italyskinxyz.xyz(model.k,3));
Z = model.italyskinxyz.xyz(:,3);
model.interpk = find(Z > zmin); % focus interpolated vertices
model.XI = model.italyskinxy.xy(model.interpk,1);
model.YI = model.italyskinxy.xy(model.interpk,2);
%=============================================

options.step = round(EEG.points/10);
if options.step <= 0
    options.step = 2;
end
options.vidx = EEG.vidx;
options.currentpoint = 1;
options.auto = 0;
options.method = 'mn';
options.lamda = 0;
options.autocorner = 1;
options.threshold = 0.0;
options.HWHM = 3;
options.startepoch = 1;
options.endepoch = EEG.points;
options.alpha = 1;
options.cutskin = 0;
options.labels = 0;
options.electrodes = 0;
options.sensorcaxis = 'local';
options.sensorminmax = [EEG.min, EEG.max];
options.sourcecaxis = 'local';
options.sourceminmax = [realmax, realmin];
options.usebem = 0;
options.currymatrix = 0;
movie.on = 0;
movie.sensorminmax = [realmax, realmin];
movie.sourceminmax = [realmax, realmin];

ROI.labels = {};
ROI.vertices = {};
ROI.centers = [];
ROI.current = [];
ROI.radius = [];
ROI.texthandles = [];
ROI.adjradius = 3;

axes(handles.skinaxes);
% axis vis3d;
hold on;
% modelhandles.italyskin = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'Vertices',model.italyskin.italyskin.Vertices,...
%      'LineStyle','none',...
%      'Faces',model.italyskin.italyskin.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',model.italyskin.italyskin.FaceVertexCData,...
%      'tag','skin');
modelhandles.italyskin = trisurf(model.italyskin.italyskin.Faces,... 
     model.italyskin.italyskin.Vertices(:,1), model.italyskin.italyskin.Vertices(:,2),model.italyskin.italyskin.Vertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',model.italyskin.italyskin.FaceVertexCData,...
     'tag','skin');

electrcolor = [0.0  1.0  1.0];
modelhandles.electrodes = plot3(model.electrodes.locations(:,1), ...
                                             model.electrodes.locations(:,2), ... 
                                             model.electrodes.locations(:,3), ... 
                                             'k.','LineWidth',4,'color', electrcolor);                                 
if options.electrodes
    set(modelhandles.electrodes,'visible','on');
else
    set(modelhandles.electrodes,'visible','off');
end

textcolor = [0.0 0.0 0.0];
locations = 1.05*model.electrodes.locations;
modelhandles.labels = text( locations(:,1), locations(:,2), locations(:,3), ... 
                                             upper(model.electrodes.labels),'FontSize',8 ,...
                                             'HorizontalAlignment','center', 'Color',textcolor);
if options.labels
    set(modelhandles.labels,'visible','on');
else
    set(modelhandles.labels,'visible','off');
end

lighting gouraud; % phong, gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);

axes(handles.cortexaxes);
% axis vis3d;
hold on;
% modelhandles.cutskin = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'Vertices',model.cutskin.cutskin.Vertices,...
%      'LineStyle','none',...
%      'Faces',model.cutskin.cutskin.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',model.cutskin.cutskin.FaceVertexCData,...
%      'tag','cotex','visible','off','FaceAlpha',options.alpha);

% modelhandles.cortex = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'Vertices',model.cortex.colincortex.Vertices,...
%      'LineStyle','none',...
%      'Faces',model.cortex.colincortex.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',model.cortex.colincortex.FaceVertexCData,...
%      'tag','cotex');
modelhandles.cortex = trisurf(model.cortex.colincortex.Faces,...
     model.cortex.colincortex.Vertices(:,1),model.cortex.colincortex.Vertices(:,2),model.cortex.colincortex.Vertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',model.cortex.colincortex.FaceVertexCData,...
     'tag','cotex');

 modelhandles.cutskin = trisurf(model.cutskin.cutskin.Faces,...
     model.cutskin.cutskin.Vertices(:,1), model.cutskin.cutskin.Vertices(:,2), model.cutskin.cutskin.Vertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'EdgeColor','none',...
     'FaceVertexCData',model.cutskin.cutskin.FaceVertexCData,...
     'tag','cotex','visible','off','FaceAlpha',options.alpha);
 
lighting phong; % phone, gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
%%

set(handles.texttotalpoints,'string',num2str(EEG.points));
set(handles.texttotaltime,'string',[num2str(EEG.points/EEG.srate) ' s']);
set(handles.textsensorchannels,'string',num2str(length(options.vidx)));
set(handles.textsourcechannels,'string',num2str(length(model.cortex.colincortex.Vertices)));
set(handles.editcurrentpoint,'string',num2str(options.currentpoint));
set(handles.editcurrenttime,'string',num2str(options.currentpoint/EEG.srate));

setappdata(hObject,'Model',model);
setappdata(hObject,'options',options);
source.data = {};
setappdata(hObject,'source',source);
sensor.data = {};
setappdata(hObject,'sensor',sensor);
localized = zeros(EEG.points,1);
topomaped = localized;
setappdata(hObject,'localized',localized);
setappdata(hObject,'topomaped',topomaped);
setappdata(hObject, 'modelhandles',modelhandles);
setappdata(hObject,'ROI',ROI);
setappdata(hObject,'movie',movie);
setappdata(hObject,'BEM',[]);

set(hObject,'windowbuttonmotionfcn', @mousemotionCallback);
set(hObject,'WindowButtonDownFcn', @mousebuttondownCallback); 

% --- Outputs from this function are returned to the command line.
function varargout = pop_sourceloc_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in whichtimeleft.
function whichtimeleft_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.currentpoint = options.currentpoint - 1;
if options.currentpoint < 1
    return;
end
setappdata(hfig,'options',options);
Update;

% --- Executes on button press in whichtimelefter.
function whichtimelefter_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimelefter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.currentpoint = options.currentpoint - options.step;
if options.currentpoint < 1
    return;
end
setappdata(hfig,'options',options);
Update;

% --- Executes on button press in whichtimeright.
function whichtimeright_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');
options.currentpoint = options.currentpoint + 1;
if options.currentpoint > EEG.points
    return;
end
setappdata(hfig,'options',options);
Update;

% --- Executes on button press in whichtimerighter.
function whichtimerighter_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimerighter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');
options.currentpoint = options.currentpoint + options.step;
if options.currentpoint > EEG.points
    return;
end
setappdata(hfig,'options',options);
Update;

% --- Executes on button press in whichtimeleftest.
function whichtimeleftest_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleftest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.currentpoint = 1;
setappdata(hfig,'options',options);
Update;

% --- Executes on button press in whichtimerightest.
function whichtimerightest_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimerightest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');
options.currentpoint = EEG.points;
setappdata(hfig,'options',options);
Update;

% --- Executes on button press in whichtimeleftauto.
function whichtimeleftauto_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleftauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');

if options.startepoch > options.endepoch
    errordlg('The epoch specification is not right !');
    return;
end

step = 2;
endepoch = min(max(options.currentpoint,options.startepoch), options.endepoch);
startepoch = options.startepoch;
epoch = endepoch:-step:startepoch;
if epoch(length(epoch)) ~= startepoch
    epoch(length(epoch)+1) = startepoch;
end

% for movie minmax
localized = getappdata(hfig,'localized');
islocalized = localized(epoch);
if ~all(islocalized)
    helpdlg('Please perform source imaging for the epoch first!');
    return;
end
sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');
movie = getappdata(hfig,'movie');
sensorminmax = [realmax realmin];
sourceminmax = [realmax realmin];
for i = options.startepoch:options.endepoch
    scalpV = sensor.data{i};
    sensorminmax(1) = min(min(scalpV),sensorminmax(1));
    sensorminmax(2) = max(max(scalpV),sensorminmax(2));
    
    abscortexV = abs(source.data{i});
    sourceminmax(1) = min(min(abscortexV),sourceminmax(1));
    sourceminmax(2) = max(max(abscortexV),sourceminmax(2));
end
movie.on = 1;
movie.sensorminmax = sensorminmax;
movie.sourceminmax = sourceminmax;
setappdata(hfig,'movie',movie);

% movie
j = 0;
for i = epoch
    options = getappdata(hfig,'options');
    if options.auto ~= 1
        options.currentpoint = i;
        setappdata(hfig,'options',options);
        Update;
        pause(0.3);
        
        j = j+1;
        movsource(j) = getframe(handles.cortexaxes); % get frames to generate movie file
        movsensor(j) = getframe(handles.skinaxes); % get frames to generate movie file
    else
        options.auto = 0;
        setappdata(hfig,'options',options);
        break;
%         movie.on = 0;
%         setappdata(hfig,'movie',movie);  
%         return;       
    end
end
movie.on = 0;
setappdata(hfig,'movie',movie);

% Merge sensor and source frames
szsource = size(movsource(1).cdata);
szsensor = size(movsensor(1).cdata);
szrow = max(szsensor(1),szsource(1));
szcolumn = szsensor(2)+szsource(2);
sensorstart = max(1, round((szrow-szsensor(1))/2));
sensorend = sensorstart+szsensor(1)-1;
sourcestart = max(1, round((szrow-szsource(1))/2));
sourceend = sourcestart+szsource(1)-1;

axcolor = uint8(round(255 * get(hfig, 'color')));
frame = zeros(szrow,szcolumn,3,'uint8');
for i = 1:szrow
    for j = 1:szcolumn
        frame(i,j,:) = axcolor;
    end
end

num = length(movsource);
for i = 1:num
    mov(i).colormap = [];
    mov(i).cdata = frame;
    mov(i).cdata(sensorstart:sensorend,1:szsensor(2),:) = movsensor(i).cdata;
    mov(i).cdata(sourcestart:sourceend,szsensor(2)+1:szsensor(2)+szsource(2),:) = movsource(i).cdata;
end

% play the merged movie.
playmov(mov, 'Cortical Source Imaging Movie from Scalp EEG');

% --- Executes on button press in whichtimerightauto.
function whichtimerightauto_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimerightauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');

if options.startepoch > options.endepoch
    errordlg('The epoch specification is not right !');
    return;
end

step = 2;
startepoch = min(max(options.currentpoint,options.startepoch), options.endepoch);
endepoch = options.endepoch;
epoch = startepoch:step:endepoch;
if epoch(length(epoch)) ~= endepoch
    epoch(length(epoch)+1) = endepoch;
end

% for movie minmax
localized = getappdata(hfig,'localized');
islocalized = localized(epoch);
if ~all(islocalized)
    helpdlg('Please perform imaging for the epoch first!');
    return;
end
sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');
movie = getappdata(hfig,'movie');
sensorminmax = [realmax realmin];
sourceminmax = [realmax realmin];
for i = options.startepoch:options.endepoch
    scalpV = sensor.data{i};
    sensorminmax(1) = min(min(scalpV),sensorminmax(1));
    sensorminmax(2) = max(max(scalpV),sensorminmax(2));
    
    abscortexV = abs(source.data{i});
    sourceminmax(1) = min(min(abscortexV),sourceminmax(1));
    sourceminmax(2) = max(max(abscortexV),sourceminmax(2));
end
movie.on = 1;
movie.sensorminmax = sensorminmax;
movie.sourceminmax = sourceminmax;
setappdata(hfig,'movie',movie);

% movie
j = 0;
for i = epoch
    options = getappdata(hfig,'options');
    if options.auto ~= 1
        options.currentpoint = i;
        setappdata(hfig,'options',options);
        Update;
        pause(0.3);
        
        j = j+1;
        movsource(j) = getframe(handles.cortexaxes); % get source space frames
        movsensor(j) = getframe(handles.skinaxes); % get sensor space  frames
    else
        options.auto = 0;
        setappdata(hfig,'options',options);
        break;
%         movie.on = 0;
%         setappdata(hfig,'movie',movie);
%         return;       
    end
end
movie.on = 0;
setappdata(hfig,'movie',movie);

% Merge sensor and source frames
szsource = size(movsource(1).cdata);
szsensor = size(movsensor(1).cdata);
szrow = max(szsensor(1),szsource(1));
szcolumn = szsensor(2)+szsource(2);
sensorstart = max(1, round((szrow-szsensor(1))/2));
sensorend = sensorstart+szsensor(1)-1;
sourcestart = max(1, round((szrow-szsource(1))/2));
sourceend = sourcestart+szsource(1)-1;

axcolor = uint8(round(255 * get(hfig, 'color')));
frame = zeros(szrow,szcolumn,3,'uint8');
for i = 1:szrow
    for j = 1:szcolumn
        frame(i,j,:) = axcolor;
    end
end

num = length(movsource);
for i = 1:num
    mov(i).colormap = [];
    mov(i).cdata = frame;
    mov(i).cdata(sensorstart:sensorend,1:szsensor(2),:) = movsensor(i).cdata;
    mov(i).cdata(sourcestart:sourceend,szsensor(2)+1:szsensor(2)+szsource(2),:) = movsource(i).cdata;
end

% play the merged movie.
playmov(mov, 'Cortical Source Imaging Movie from Scalp EEG');

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over whichtimeleftauto.
function whichtimeleftauto_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to whichtimeleftauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.auto = 1;
setappdata(hfig,'options',options);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over whichtimerightauto.
function whichtimerightauto_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to whichtimerightauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.auto = 1;
setappdata(hfig,'options',options);


% --- Executes on button press in pushbuttonloc.
function pushbuttonloc_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonloc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

locevent = questdlg('Compute sources for all points in the epoch? It may take minutes!','','Yes','Cancel','Cancel');
if ~strcmp(locevent, 'Yes')
    return;
end
pause(0.1);

hfig = gcf;
model = getappdata(hfig,'Model');
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');
sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');
localized = getappdata(hfig,'localized');
topomaped = getappdata(hfig,'topomaped');

if options.startepoch > options.endepoch
    errordlg('The epoch specification is not right !');
    return;
end

ratio = 100 / (options.endepoch - options.startepoch);
for i = options.startepoch : options.endepoch
    
    electrodesV = EEG.data(options.vidx,i);
    
    % compute map for sensor space
    sensor.data(i) = {griddata(model.X,model.Y,electrodesV,model.XI,model.YI,'v4')};

    % compute sources on cortex
    if isequal(options.method,'mn') % compute sources on cortex
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
    elseif isequal(options.method,'wmn')
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
        cortexVI = cortexVI ./ model.W';
    end
    
    if options.currymatrix == 1
        len = length(cortexVI);
        cortexVI(len+1:options.cortexnumverts) = 0;
    end
    
    % get smooth values on finer colin cortex
    len = length(model.neighbors.neighbors.idx);
    for j = 1:len
        values = cortexVI(model.neighbors.neighbors.idx{j}); 
        weight = model.neighbors.neighbors.weight{j};
        cortexV(j,:) =  sum(weight .* values);
    end
    source.data(i) = {cortexV};
    
    % update absolute min and max values
    abscortexV = abs(cortexV);
    dmin = min(abscortexV);
    dmax = max(abscortexV);
    if dmin < options.sourceminmax(1)
        options.sourceminmax(1) = dmin;
    end
    if dmax > options.sourceminmax(2)
        options.sourceminmax(2) = dmax;
    end        
    
    percent = round((i-options.startepoch)*ratio);
    progress = ['Localizing ' num2str(percent) '%'];
    set(handles.waitbartext,'string',progress);
    drawnow;
end
set(handles.waitbartext,'string','Done');

localized(options.startepoch : options.endepoch) = 1;
topomaped(options.startepoch : options.endepoch) = 1;    
setappdata(hfig,'sensor',sensor);
setappdata(hfig,'source',source);
options.currentpoint = options.startepoch;
setappdata(hfig,'options',options);
setappdata(hfig,'localized',localized);
setappdata(hfig,'topomaped',topomaped);
figure(hfig);

Update;

% Update maps for the sensor and source spaces 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Update()

hfig = gcf;
skinaxes = findobj(hfig,'tag','skinaxes');
cortexaxes = findobj(hfig,'tag','cortexaxes');
tsaxes = findobj(hfig,'tag','tsaxes');
editcurrentpoint = findobj(hfig,'tag','editcurrentpoint');
editcurrenttime = findobj(hfig,'tag','editcurrenttime');
model = getappdata(hfig,'Model');
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');
electrodesV = EEG.data(options.vidx,options.currentpoint);
localized = getappdata(hfig,'localized');
topomaped = getappdata(hfig,'topomaped');
movie = getappdata(hfig,'movie');

% % dipole test
% electrodesV = zeros(length(electrodesV),1);
% electrodesV(8) = 1;

%% update the skin map
islocalized = localized(options.currentpoint);
istopomaped = topomaped(options.currentpoint);

sensor = getappdata(hfig,'sensor');

% not to interpolate sensor if it exists.
if ~istopomaped
    sensor.data(options.currentpoint) = {griddata(model.X,model.Y,electrodesV,model.XI,model.YI,'v4')};
    setappdata(hfig,'sensor',sensor);
    topomaped(options.currentpoint) = 1;
    setappdata(hfig,'topomaped',topomaped);
end
skinV = sensor.data{options.currentpoint};

if movie.on
    minV1 = movie.sensorminmax(1);
    maxV1 = movie.sensorminmax(2);
    absV = max(abs(minV1), abs(maxV1));
    minV1 = -absV;
    maxV1 = absV;    
    k = find(skinV<minV1);
    skinV(k) = minV1;
    k = find(skinV>maxV1);
    skinV(k) = maxV1;    
else
    if isequal(options.sensorcaxis, 'global')
        minV1 = options.sensorminmax(1);
        maxV1 = options.sensorminmax(2);
        absV = max(abs(minV1), abs(maxV1));
        minV1 = -absV;
        maxV1 = absV;    
        k = find(skinV<minV1);
        skinV(k) = minV1;
        k = find(skinV>maxV1);
        skinV(k) = maxV1;    
    else
        minV2 = min(electrodesV);
        maxV2 = max(electrodesV);
        k = find(skinV<minV2);
        skinV(k) = minV2;
        k = find(skinV>maxV2);
        skinV(k) = maxV2;    
        
        minV1 = min(skinV);
        maxV1 = max(skinV);
        absV = max(abs(minV1), abs(maxV1));
        minV1 = -absV;
        maxV1 = absV;    
    end
end

cmap = colormap;
len = length(cmap);
coef = (len-1)/(maxV1 - minV1);
FaceVertexCData = model.italyskin.italyskin.FaceVertexCData;
FaceVertexCData(model.interpk,:) = cmap(round(coef*(skinV-minV1)+1),:);

modelhandles = getappdata(hfig, 'modelhandles');

axes(skinaxes);
caxis([minV1 maxV1]);
set(modelhandles.italyskin,'FaceVertexCData',FaceVertexCData);

colorbar;

%% update the cortex map
source = getappdata(hfig,'source');

% not to localize source if it exists.
if ~islocalized
    if isequal(options.method,'mn') % compute sources on cortex
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
    elseif isequal(options.method,'wmn')
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
        cortexVI = cortexVI ./ model.W';
    end

    if options.currymatrix == 1
        len = length(cortexVI);
        cortexVI(len+1:options.cortexnumverts) = 0;
    end
    
    % get smooth values on finer colin cortex
    len = length(model.neighbors.neighbors.idx);
    for i = 1:len
        values = cortexVI(model.neighbors.neighbors.idx{i}); 
        weight = model.neighbors.neighbors.weight{i};
        cortexV(i,:) =  sum(weight .* values);
    end
    source.data(options.currentpoint) = {cortexV};
    setappdata(hfig,'source',source);
 
    % update absolute min and max values
    abscortexV = abs(cortexV);
    dmin = min(abscortexV);
    dmax = max(abscortexV);
    if dmin < options.sourceminmax(1)
        options.sourceminmax(1) = dmin;
    end
    if dmax > options.sourceminmax(2)
        options.sourceminmax(2) = dmax;
    end    
    
    localized(options.currentpoint) = 1;
    setappdata(hfig,'localized',localized);
end
cortexV = source.data{options.currentpoint};

% post processing
cortexV = abs(cortexV);

if movie.on
    minV2 = movie.sourceminmax(1);
    maxV2 = movie.sourceminmax(2);
    coef = 1/(maxV2-minV2);
    cortexV = (cortexV-minV2)*coef;
    nzK = cortexV > options.threshold;
    minV2 = 0;
    maxV2 = 1;
else
    if isequal(options.sourcecaxis, 'global')
        minV2 = options.sourceminmax(1);
        maxV2 = options.sourceminmax(2);
        coef = 1/(maxV2-minV2);
        cortexV = (cortexV-minV2)*coef;
        nzK = cortexV > options.threshold;
        minV2 = 0;
        maxV2 = 1;
    else
        minV2 = min(cortexV);
        maxV2 = max(cortexV);
        coef = 1/(maxV2-minV2);
        cortexV = (cortexV-minV2)*coef;
        nzK = cortexV > options.threshold;
        minV2 = min(cortexV);
        maxV2 = max(cortexV);    
    end
end

if options.usebem == 1
    FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts, 1);
else
    FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
end

len = length(cmap);
coef = (len-1)/(maxV2 - minV2);
FaceVertexCData(nzK,:) = cmap(round(coef*(cortexV(nzK)-minV2)+1),:);

axes(cortexaxes);
caxis([minV2 maxV2]);

set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);

colorbar;

% update the time series axis
axes(tsaxes);
currentylim = get(tsaxes, 'Ylim');
xpos = [options.currentpoint,  options.currentpoint];
ypos = [currentylim(1,1),  currentylim(1,2)];
tmpcolor = [ 0.0 0.0 0.0 ];
linehandle = findobj(hfig, 'tag','currentline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor,'clipping','on','EraseMode', 'xor', 'tag', 'currentline');
else
    set(linehandle,'xdata',xpos,'ydata',ypos);
end

set(editcurrentpoint,'string',num2str(options.currentpoint));
set(editcurrenttime,'string',num2str(options.currentpoint/EEG.srate));
setappdata(hfig,'options',options);


function Updatecortex()
hfig = gcf;
cortexaxes = findobj(hfig,'tag','cortexaxes');
model = getappdata(hfig,'Model');
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');
electrodesV = EEG.data(options.vidx,options.currentpoint);
localized = getappdata(hfig,'localized');

source = getappdata(hfig,'source');

islocalized = localized(options.currentpoint);

% not to localize source if it exists.
if ~islocalized
    if isequal(options.method,'mn') % compute sources on cortex
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
    elseif isequal(options.method,'wmn')
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
        cortexVI = cortexVI ./ model.W';
    end
    
    if options.currymatrix == 1
        len = length(cortexVI);
        cortexVI(len+1:options.cortexnumverts) = 0;
    end
    
    % get smooth values on finer colin cortex
    len = length(model.neighbors.neighbors.idx);
    for i = 1:len
        values = cortexVI(model.neighbors.neighbors.idx{i}); 
        weight = model.neighbors.neighbors.weight{i};
        cortexV(i,:) =  sum(weight .* values);
    end
    source.data(options.currentpoint) = {cortexV};
    setappdata(hfig,'source',source);

    % update absolute min and max values
    abscortexV = abs(cortexV);
    dmin = min(abscortexV);
    dmax = max(abscortexV);
    if dmin < options.sourceminmax(1)
        options.sourceminmax(1) = dmin;
    end
    if dmax > options.sourceminmax(2)
        options.sourceminmax(2) = dmax;
    end   
    
    localized(options.currentpoint) = 1;
    setappdata(hfig,'localized',localized);
end
cortexV = source.data{options.currentpoint};

% post processing
cortexV = abs(cortexV);

if isequal(options.sourcecaxis, 'global')
    minV = options.sourceminmax(1);
    maxV = options.sourceminmax(2);
    coef = 1/(maxV-minV);
    cortexV = (cortexV-minV)*coef;
    nzK = cortexV > options.threshold;
    minV = 0;
    maxV = 1;
else
    minV = min(cortexV);
    maxV = max(cortexV);
    coef = 1/(maxV-minV);
    cortexV = (cortexV-minV)*coef;
    nzK = cortexV > options.threshold;
    minV = min(cortexV);
    maxV = max(cortexV);    
end

if options.usebem == 1
    FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts, 1);
else
    FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
end

cmap = colormap;
len = length(cmap);
coef = (len-1)/(maxV - minV);
FaceVertexCData(nzK,:) = cmap(round(coef*(cortexV(nzK)-minV)+1),:);

axes(cortexaxes);
modelhandles = getappdata(hfig, 'modelhandles');
set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);
caxis([minV maxV]);
colorbar;

% drawnow expose;

function editcurrentpoint_Callback(hObject, eventdata, handles)
% hObject    handle to editcurrentpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editcurrentpoint as text
%        str2double(get(hObject,'String')) returns contents of editcurrentpoint as a double

hfig = gcf;
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');

currentpoint = str2num(get(hObject,'String'));
if isempty(currentpoint)
    warndlg('Input MUST be NUMERIC !');
    set(hObject,'String',num2str(options.currentpoint));
    return;
end
currentpoint = round(currentpoint);
currentpoint = max(1,min(currentpoint, EEG.points));
options.currentpoint = currentpoint;
setappdata(hfig,'options',options);
Update;

% --- Executes during object creation, after setting all properties.
function editcurrentpoint_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editcurrentpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editcurrenttime_Callback(hObject, eventdata, handles)
% hObject    handle to editcurrenttime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editcurrenttime as text
%        str2double(get(hObject,'String')) returns contents of editcurrenttime as a double

hfig = gcf;
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');

currenttime = str2num(get(hObject,'String'));
if isempty(currenttime)
    warndlg('Input MUST be NUMERIC !');
    set(hObject,'String',num2str(options.currentpoint/EEG.srate));
    return;
end
currentpoint = round(currenttime*EEG.srate);
currentpoint = max(1,min(currentpoint, EEG.points));
options.currentpoint = currentpoint;
setappdata(hfig,'options',options);
Update;

% --- Executes during object creation, after setting all properties.
function editcurrenttime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editcurrenttime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function importsensordata_Callback(hObject, eventdata, handles)
% hObject    handle to importsensordata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
sensor = getappdata(hfig,'sensor');

if ~isempty(sensor.data)    
    importevent = questdlg('Exist sensor data, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr] = uigetfile('*.mat','Select Sensor Data File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

sensordata = load(Fullfilename);

if ~isfield(sensordata, 'sensordata')
    errordlg('The imported is not sensor data!');
    return;
end

sz = length(sensordata.sensordata{1});
model = getappdata(hfig,'Model');
len = length(model.interpk);

EEG = getappdata(hfig,'EEG');
ismatch = 1;
if sensordata.startepoch<1 | sensordata.startepoch>EEG.points | sensordata.endepoch<1 | sensordata.endepoch>EEG.points
    ismatch = 0;
end
    
if sz ~= len | ismatch==0
    errordlg('The imported is not the correct sensor data relative to the imported EEG!');
    return;
end

sensor.data = {};
sensor.data(sensordata.startepoch:sensordata.endepoch) = sensordata.sensordata;
setappdata(hfig, 'sensor',sensor);
options = getappdata(hfig,'options');
options.startepoch = sensordata.startepoch;
options.endepoch = sensordata.endepoch;
setappdata(hfig,'options',options);
topomaped = getappdata(hfig,'topomaped');
topomaped(sensordata.startepoch:sensordata.endepoch) = 1;
setappdata(hfig,'topomaped',topomaped);

helpdlg('Import sensor data successfully !');

% --------------------------------------------------------------------
function importsourcedata_Callback(hObject, eventdata, handles)
% hObject    handle to importsourcedata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
source = getappdata(hfig,'source');
options = getappdata(hfig,'options');

if ~isempty(source.data)    
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

sourcedata = load(Fullfilename);

if ~isfield(sourcedata, 'sourcedata')
    errordlg('The imported is not source data!');
    return;
end

sz = length(sourcedata.sourcedata{1});

if options.usebem == 0
    model = getappdata(hfig,'Model');
    len = length(model.cortex.colincortex.Vertices);
else
    BEM = getappdata(hfig,'BEM');
    len = length(BEM.Cortex.Vertices);
end

ismatch = 1;
EEG = getappdata(hfig,'EEG');
if sourcedata.startepoch<1 | sourcedata.startepoch>EEG.points | sourcedata.endepoch<1 | sourcedata.endepoch>EEG.points
    ismatch = 0;
end

if sz ~= len | ismatch==0
    errordlg('The imported source can NOT match the BEM model and EEG data!');
    return;
end

source.data = {};
source.data(sourcedata.startepoch:sourcedata.endepoch) = sourcedata.sourcedata;
setappdata(hfig, 'source',source);
options.startepoch = sourcedata.startepoch;
options.endepoch = sourcedata.endepoch;

if isequal(options.sourcecaxis, 'global')    
    pnts = length(sourcedata.sourcedata);
    for i = 1:pnts
        currentdata = abs(sourcedata.sourcedata{i});
        minV = min(currentdata);
        maxV = max(currentdata);
        options.sourceminmax(1) = min(options.sourceminmax(1), minV);
        options.sourceminmax(2) = max(options.sourceminmax(2), maxV);
    end
end

setappdata(hfig,'options',options);
localized = getappdata(hfig,'localized');
localized(sourcedata.startepoch:sourcedata.endepoch) = 1;
setappdata(hfig,'localized',localized);

drawepoch;

helpdlg('Import source data successfully !');

% --------------------------------------------------------------------
function exportsensordata_Callback(hObject, eventdata, handles)
% hObject    handle to exportsensordata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[name, pathstr] = uiputfile('*.mat','Save Sensor Data');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

hfig = gcf;
sensor = getappdata(hfig,'sensor');
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');

sensordata = sensor.data(options.startepoch:options.endepoch);
srate = EEG.srate;
startepoch = options.startepoch;
endepoch = options.endepoch;
save(Fullfilename, 'sensordata','srate','startepoch','endepoch');

% --------------------------------------------------------------------
function exportsourcedata_Callback(hObject, eventdata, handles)
% hObject    handle to exportsourcedata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[name, pathstr] = uiputfile('*.mat','Save Source Data');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

hfig = gcf;
source = getappdata(hfig,'source');
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');

sourcedata = source.data(options.startepoch:options.endepoch);
srate = EEG.srate;
startepoch = options.startepoch;
endepoch = options.endepoch;
save(Fullfilename, 'sourcedata','srate','startepoch','endepoch');

function txt = myupdatefcn(empt,event_obj)

% findobj will get nothing when the user move the tip
pos = get(event_obj,'Position');
whichmodel = get(event_obj,'Target');

whichaxes = get(whichmodel,'Parent');
hfig = get(whichaxes,'Parent');
tag = get(hfig,'tag');
isfigh = strcmp(tag,'sourceloc');
if ~isfigh
    txt = {['x=' num2str(pos(1))] ['y=' num2str(pos(2))] ['z=' num2str(pos(3))]};
    return;
end

tag = get(whichmodel,'tag');
isskin = strcmp(tag,'skin');

options = getappdata(hfig,'options');
model = getappdata(hfig,'Model');

val = [];
if isskin
    sensor = getappdata(hfig,'sensor');
    k = dsearchn(model.italyskin.italyskin.Vertices,pos);
    k = find(model.interpk == k);
    if ~isempty(sensor.data) 
        if ~isempty(k)
            currentsensor = sensor.data{options.currentpoint};
            val = currentsensor(k);
        end
    end
else
    source = getappdata(hfig,'source');
    if options.usebem == 1
        BEM = getappdata(hfig,'BEM');
        k = dsearchn(BEM.Cortex.Vertices, pos);
    else
        k = dsearchn(model.cortex.colincortex.Vertices,pos);
    end
    if ~isempty(source.data) 
        currentsource = source.data{options.currentpoint};
        val = currentsource(k);
    end
end

dcm_obj = getappdata(hfig,'datacursor'); 
datacursors = 1; %get(dcm_obj,'DataCursors');	% tigoum: µ¿ÀÛ ¸ØÃã->¹«Á¶°Ç Âü
num = length(datacursors);
if num == 0 % when rotate
   txt = [];
else
   if isempty(val)
      txt = {['x=' num2str(pos(1))] ['y=' num2str(pos(2))] ['z=' num2str(pos(3))]};
   else
      txt = {num2str(val)};
   end
end

% --------------------------------------------------------------------
function menu_popup_Callback(hObject, eventdata, handles)
% hObject    handle to menu_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_smooth_Callback(hObject, eventdata, handles)
% hObject    handle to menu_smooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
options = getappdata(hfig,'options');
prompt = {'Gaussian HWHM (>=3):'};
dlg_title = 'Smooth parameters';
num_lines = 1;
def = {num2str(options.HWHM)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

hwhm = str2num(cell2mat(answer));

if isempty(hwhm)
    warndlg('Input must be numeric!');
    return;
end

if hwhm < 3
    warndlg('Input must >= 3!');
    return;
end

if options.HWHM == hwhm
    localized = getappdata(hfig,'localized');
    localized(options.currentpoint) = 0;
    setappdata(hfig,'localized',localized);
    Updatecortex;
    return;
end

options.HWHM = hwhm;
radius = 3*options.HWHM;
sigma = options.HWHM / sqrt(2*log(2));

% build gaussian table
x = [0:0.1:radius]';
y = exp(-(x).^2/(2*sigma^2))/(sigma * sqrt(2*pi));

model = getappdata(hfig,'Model');
if options.usebem == 1
    BEM = getappdata(hfig,'BEM');
    if BEM.VertexBased == 1
        X = BEM.Cortex.Vertices;
    else
        X = BEM.Cortex.Centers;
    end
    XI = BEM.Cortex.Vertices;
else
    X = model.bemcortex.colinbemcortex.Centers;
    XI = model.cortex.colincortex.Vertices;
end

num = length(XI);
for i = 1:num
    all_dist = sqrt( (X(:,1)-XI(i,1)).^2 + (X(:,2)-XI(i,2)).^2 + (X(:,3)-XI(i,3)).^2 );
    local_index = find(all_dist < radius-0.5);
    model.neighbors.neighbors.idx(i) = {local_index};
    local_dist = all_dist(local_index);
    model.neighbors.neighbors.dis(i) = {local_dist};
    weight = y(round(local_dist*10)+1);
    model.neighbors.neighbors.weight(i) = {weight/sum(weight)};
end

setappdata(hfig,'options',options);
setappdata(hfig,'Model',model);
localized = getappdata(hfig,'localized');
localized(:) = 0;
setappdata(hfig,'localized',localized);

Updatecortex;

function mousemotionCallback(src, evnt) 
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
currentxlim = get(tsaxes, 'Xlim');
currentylim = get(tsaxes, 'Ylim');
mousepos = get(tsaxes, 'currentpoint');

if isempty(mousepos)
    return;
end

% if the mouse is not in the viewing window, do nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
% rotate3d on;
    return;
end

EEG = getappdata(hfig,'EEG');
cursorpoint = round(mousepos(1,1));%find the nearest point.
if cursorpoint < 1 | cursorpoint > EEG.points
    return;
end

% rotate3d off;

axes(tsaxes);
xpos = [cursorpoint,  cursorpoint];
ypos = [currentylim(1,1),  currentylim(1,2)];
tmpcolor = [ 0.0 1.0 0.0 ];

linehandle = findobj(hfig, 'tag','linetag');
if isempty(linehandle)
    linehandle = plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'linetag');
else
    set(linehandle,'xdata',xpos,'ydata',ypos);
    drawnow;
end

function mousebuttondownCallback(src, evnt) 
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
currentxlim = get(tsaxes, 'Xlim');
currentylim = get(tsaxes, 'Ylim');
mousepos = get(tsaxes, 'currentpoint');

% if the mouse is not in the viewing window, do nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
    return;
end

EEG = getappdata(hfig,'EEG');
cursorpoint = round(mousepos(1,1));%find the nearest point.
if cursorpoint < 1 | cursorpoint > EEG.points
    return;
end
xpos = [cursorpoint,  cursorpoint];
ypos = [currentylim(1,1),  currentylim(1,2)];

selectype = lower(get(hfig,'SelectionType'));

% 'alt': right click - select epoch
if strcmp(selectype,'alt')    
    popmenu_tsaxes = findobj(hfig,'tag','popmenu_tsaxes');
    position = get(hfig,'CurrentPoint');
    set(popmenu_tsaxes,'position',position);
    set(popmenu_tsaxes,'Visible','on');
    return;
end

% 'normal': left click
if ~strcmp(selectype,'normal')
    return;
end
tmpcolor = [0.0,0.0,0.0];
linehandle = findobj(hfig,'tag','currentline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'currentline');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end 
options = getappdata(hfig,'options');
options.currentpoint = xpos(1,1);   
setappdata(hfig,'options',options);   
Update;    

%--------------------------------------------------------------------------
function VI = smooth(V, neighbors)
len = length(neighbors.neighbors.idx);
for i = 1:len
    values = V(neighbors.neighbors.idx{i}); 
    weight = neighbors.neighbors.weight{i};
    VI(i,:) =  sum(weight .* values);
end

%--------------------------------------------------------------------------
function [Vnew, minV, maxV, nzK] = normalize_clip(V, cliprate)
Vnew = abs(V);
minV = min(Vnew);
maxV = max(Vnew);
coef = 1/(maxV-minV);
Vnew = (Vnew-minV)*coef;
num = Vnew < cliprate;
k = find(num==1);
Vnew(k) = 0.0;

nzK = find(num==0);
VI = Vnew(nzK);
minV = min(VI);
maxV = max(VI);

% --------------------------------------------------------------------
function menu_method_Callback(hObject, eventdata, handles)
% hObject    handle to menu_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_mn_Callback(hObject, eventdata, handles)
% hObject    handle to menu_mn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% ischecked = lower(get(hObject,'checked'));
% if isequal(ischecked,'on')
%     return;
% end

hfig = gcf;
options = getappdata(hfig, 'options');
options.method = 'mn';
localized = getappdata(hfig,'localized');
% localized(options.currentpoint) = 0;
localized(:) = 0;
setappdata(hfig,'options',options);
setappdata(hfig, 'localized', localized);
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

model = getappdata(hfig,'Model');
if options.usebem == 1 
    BEM = getappdata(hfig,'BEM');
    matrix = BEM.TransMatrix;
else
    matrix = model.transmatrix;
end
[model.U, model.s, model.V] = csvd(matrix);
setappdata(hfig,'Model',model);

Updatecortex;

% --------------------------------------------------------------------
function menu_regularization_Callback(hObject, eventdata, handles)
% hObject    handle to menu_regularization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
options = getappdata(hfig, 'options');
model = getappdata(hfig,'Model');
regularization.U = model.U;
regularization.s = model.s;
regularization.b = EEG.data(options.vidx,options.currentpoint);
regularization.autocorner = options.autocorner;
regularization.lamda = options.lamda;
regularization.method = options.method;

result = pop_lcurve(regularization);
if isempty(result)
    return;
end

if isequal(result.autocorner,1)
    if options.autocorner == 1
        return;
    else
        options.autocorner = 1;
    end
else
    if options.autocorner == 0
        if options.lamda == result.lamda
            return;
        else
            options.lamda = result.lamda;
        end
    else
        options.autocorner = 0;
        options.lamda = result.lamda;
    end
end
setappdata(hfig, 'options',options);

localized = getappdata(hfig,'localized');
localized(options.currentpoint) = 0;
setappdata(hfig,'localized',localized);

Updatecortex;

% --------------------------------------------------------------------
function menu_wmn_Callback(hObject, eventdata, handles)
% hObject    handle to menu_wmn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% ischecked = lower(get(hObject,'checked'));
% if isequal(ischecked,'on')
%     return;
% end

hfig = gcf;
options = getappdata(hfig, 'options');
options.method = 'wmn';
setappdata(hfig,'options',options);

localized = getappdata(hfig,'localized');
% localized(options.currentpoint) = 0;
localized(:) = 0;
setappdata(hfig, 'localized', localized);

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

model = getappdata(hfig,'Model');

if options.usebem == 1 
    BEM = getappdata(hfig,'BEM');
    matrix = BEM.TransMatrix;
else
    matrix = model.transmatrix;
end

[m,n] = size(matrix);
model.W = zeros(1,n);
for i = 1:n
    model.W(i) = (norm(matrix(:,i)))^1;
    matrix(:,i) = matrix(:,i) / model.W(i);
end
[model.U, model.s, model.V] = csvd(matrix);
setappdata(hfig,'Model',model);

Updatecortex;

function drawepoch()
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
currentylim = get(tsaxes, 'Ylim');
ypos = [currentylim(1,1),  currentylim(1,2)];

options = getappdata(hfig,'options');
xpos = [options.startepoch,  options.startepoch];
tmpcolor = [0.0, 0.0, 1.0];
linehandle = findobj(hfig,'tag','leftline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end 

xpos = [options.endepoch,  options.endepoch];
tmpcolor = [1.0,0.0,0.0];
linehandle = findobj(hfig,'tag','rightline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end 


% --------------------------------------------------------------------
function menu_visible_Callback(hObject, eventdata, handles)
% hObject    handle to menu_visible (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.cutskin = 0;
else
    ischecked = 'on';
    options.cutskin = 1;
end

setappdata(hfig, 'options', options);
set(hObject,'checked',ischecked);

modelhandles = getappdata(hfig, 'modelhandles');

if options.usebem == 1 
    helpdlg('There is no cutskin for individual BEM model!');
    set(hObject,'checked','off');
    return;
end
    
axes(handles.cortexaxes);
if options.cutskin
    set(modelhandles.cutskin,'visible','on');
else
    set(modelhandles.cutskin,'visible','off');
end

% --------------------------------------------------------------------
function menu_cutskin_Callback(hObject, eventdata, handles)
% hObject    handle to menu_cutskin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_alpha_Callback(hObject, eventdata, handles)
% hObject    handle to menu_alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
options = getappdata(hfig, 'options');

if ~options.cutskin
    helpdlg('The cutskin is invisible, alpha will NOT change!');
    return;
end

prompt = {'Enter alpha value (0~1), current is:'};
dlg_title = 'Input alpha for the cutskin';
num_lines = 1;
def = {num2str(options.alpha)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

options.alpha = str2num(cell2mat(answer));

if isempty(options.alpha)
    warndlg('Input must be numeric!');
    return;
end

if length(options.alpha)~=1
    warndlg('Please input single value!');
    return;
end

options.alpha = max(0.0, min(1.0, options.alpha));

setappdata(hfig, 'options', options);

modelhandles = getappdata(hfig, 'modelhandles');
axes(handles.cortexaxes);

set(modelhandles.cutskin,'FaceAlpha',options.alpha);

% --------------------------------------------------------------------
function menu_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.labels = 0;
else
    ischecked = 'on';
    options.labels = 1;
end

setappdata(hfig, 'options', options);
set(hObject,'checked',ischecked);

modelhandles = getappdata(hfig, 'modelhandles');
axes(handles.skinaxes);
if options.labels
    set(modelhandles.labels,'visible','on');
else
    set(modelhandles.labels,'visible','off');
end

% --------------------------------------------------------------------
function menu_electrodes_Callback(hObject, eventdata, handles)
% hObject    handle to menu_electrodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.electrodes = 0;
else
    ischecked = 'on';
    options.electrodes = 1;
end

setappdata(hfig, 'options', options);
set(hObject,'checked',ischecked);

modelhandles = getappdata(hfig, 'modelhandles');
axes(handles.skinaxes);
if options.electrodes
    set(modelhandles.electrodes,'visible','on');
else
    set(modelhandles.electrodes,'visible','off');
end


% --------------------------------------------------------------------
function menu_clip_Callback(hObject, eventdata, handles)
% hObject    handle to menu_clip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');

prompt = {'Enter threshold (0~1), current is:'};
dlg_title = 'Input threshold to invisualize partial source';
num_lines = 1;
def = {num2str(options.threshold)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

options.threshold = str2num(cell2mat(answer));

if isempty(options.threshold)
    warndlg('Input must be numeric!');
    return;
end

if length(options.threshold)~=1
    warndlg('Please input single value!');
    return;
end

options.threshold = max(0.0, min(1.0, options.threshold));

setappdata(hfig, 'options', options);
Updatecortex;


% --------------------------------------------------------------------
function menu_newroi_Callback(hObject, eventdata, handles)
% hObject    handle to menu_newroi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
hMode = getuimode(hfig,'Exploration.Datacursor');
hTool = hMode.ModeStateData.DataCursorTool;
datainfo = getCursorInfo(hTool);
posnum = length(datainfo);

if posnum < 1
    helpdlg('Please edit a ROI center!');
    return;
end

if posnum > 1
    helpdlg('Please build ROIs one by one!') ;
    return;
end
center = datainfo.Position;

ROI = getappdata(hfig,'ROI');
idx = length(ROI.labels)+1;
label = num2str(idx);
radius = 10;

prompt = {'ROI name, default is:', 'ROI radius, default is:'};
dlg_title = 'Input ROI label and radius';
num_lines = 1;
def = {label, num2str(radius)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

label = answer(1);
if isempty(label)
    helpdlg('There is no ROI label!');
    return;
end

radius = str2num(answer{2});
if isempty(radius)
    helpdlg('There is no radius!');
    return;
end

ROI.current = idx;
ROI.labels(idx) = label;
ROI.centers(idx,:) = center;
ROI.radius(idx) = radius;

model = getappdata(hfig,'Model');
options = getappdata(hfig,'options');
if options.usebem == 1
    BEM = getappdata(hfig,'BEM');
    XI = BEM.Cortex.Vertices;
else
    XI = model.cortex.colincortex.Vertices;
end
dists = sqrt( (XI(:,1)-center(1)).^2 + (XI(:,2)-center(2)).^2 + (XI(:,3)-center(3)).^2 );
vidx = find(dists<radius);
ROI.vertices(idx) = {vidx};

Updatecortex;

modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = get(modelhandles.cortex,'FaceVertexCData');

cmap = lines(idx);
for i = 1:idx
    vidx = ROI.vertices{i};
    FaceVertexCData(vidx,:) = repmat(cmap(i,:),length(vidx),1);
end

set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);
if ROI.texthandles
    delete(ROI.texthandles);
end
textcolor = [1.0 1.0 1.0];
locations = 1.05*ROI.centers;
ROI.texthandles = text( locations(:,1), locations(:,2), locations(:,3), ... 
                        upper(ROI.labels),'FontSize',8 ,...
                        'HorizontalAlignment','center', 'Color',textcolor);
setappdata(hfig,'ROI',ROI);

% --------------------------------------------------------------------
function menu_modifyradius_Callback(hObject, eventdata, handles)
% hObject    handle to menu_modifyradius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
hMode = getuimode(hfig,'Exploration.Datacursor');
hTool = hMode.ModeStateData.DataCursorTool;
datainfo = getCursorInfo(hTool);
posnum = length(datainfo);

if posnum < 1
    helpdlg('Please edit a ROI center!');
    return;
end

if posnum > 1
    helpdlg('Please modify ROIs one by one!') ;
    return;
end
center = datainfo.Position;

ROI = getappdata(hfig,'ROI');
if isempty(ROI.current)
    helpdlg('There is no ROI!');
    return;
end

radius = ROI.radius(ROI.current);

prompt = {'ROI radius, default is:'};
dlg_title = 'Input ROI radius';
num_lines = 1;
def = {num2str(radius)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

radius = str2num(answer{1});
if isempty(radius)
    helpdlg('There is no radius!');
    return;
end

ROI.centers(ROI.current,:) = center;
ROI.radius(ROI.current) = radius;

model = getappdata(hfig,'Model');
options = getappdata(hfig,'options');
if options.usebem == 1
    BEM = getappdata(hfig,'BEM');
    XI = BEM.Cortex.Vertices;
else
    XI = model.cortex.colincortex.Vertices;
end
dists = sqrt( (XI(:,1)-center(1)).^2 + (XI(:,2)-center(2)).^2 + (XI(:,3)-center(3)).^2 );
vidx = find(dists<radius);
ROI.vertices(ROI.current) = {vidx};

Updatecortex;

modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = get(modelhandles.cortex,'FaceVertexCData');

len = length(ROI.labels);
cmap = lines(len);
for i = 1:len
    vidx = ROI.vertices{i};
    FaceVertexCData(vidx,:) = repmat(cmap(i,:),length(vidx),1);
end

set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);
if ROI.texthandles
    delete(ROI.texthandles);
end
textcolor = [1.0 1.0 1.0];
locations = 1.05*ROI.centers;
ROI.texthandles = text( locations(:,1), locations(:,2), locations(:,3), ... 
                        upper(ROI.labels),'FontSize',8 ,...
                        'HorizontalAlignment','center', 'Color',textcolor);
setappdata(hfig,'ROI',ROI);

% --------------------------------------------------------------------
function menu_selectroi_Callback(hObject, eventdata, handles)
% hObject    handle to menu_selectroi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;

ROI = getappdata(hfig,'ROI');
len = length(ROI.labels);
if len<1
    helpdlg('There is no ROI!');
    return;
end

default = [];
[sel,ok] = listdlg('ListString',ROI.labels,'Name','ROI Selection','InitialValue',default,'SelectionMode','single');
if ok == 0 | isempty(sel)
    return;
end

if length(sel) ~= 1
    helpdlg('Please select only one ROI!');
    return;
end

ROI.current = sel;

Updatecortex;

modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = get(modelhandles.cortex,'FaceVertexCData');

len = length(ROI.labels);
cmap = lines(len);
for i = 1:len
    vidx = ROI.vertices{i};
    FaceVertexCData(vidx,:) = repmat(cmap(i,:),length(vidx),1);
end

set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);
if ROI.texthandles
    delete(ROI.texthandles);
end
textcolor = [1.0 1.0 1.0];
locations = 1.05*ROI.centers;
ROI.texthandles = text( locations(:,1), locations(:,2), locations(:,3), ... 
                        upper(ROI.labels),'FontSize',8 ,...
                        'HorizontalAlignment','center', 'Color',textcolor);
setappdata(hfig,'ROI',ROI);

dcm_obj = getappdata(hfig,'datacursor'); % get data cursor manager
datacursors = get(dcm_obj,'DataCursors'); % get data cursor
num = length(datacursors);
if num>1
    return;
end

center = ROI.centers(ROI.current,:);

% set data cursor and data tip location
set(get(datacursors,'DataCursor'),'TargetPoint',center);
set(datacursors,'Position',center);
updateDataCursors(dcm_obj);
drawnow;

% --------------------------------------------------------------------
function menu_deleteroi_Callback(hObject, eventdata, handles)
% hObject    handle to menu_deleteroi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ROI = getappdata(hfig,'ROI');

len = length(ROI.labels);
if len<1
    helpdlg('There is no ROI!');
    return;
end
    
default = [];
[sel,ok] = listdlg('ListString',ROI.labels,'Name','ROI Selection','InitialValue',default);
if ok == 0 | isempty(sel)
    return;
end

ROI.labels(sel) = [];
ROI.centers(sel,:) = [];
ROI.radius(sel) = [];
ROI.vertices(sel) = [];
ROI.current = length(ROI.labels);
Updatecortex;

if ROI.current<1
    if ROI.texthandles
        delete(ROI.texthandles);
        ROI.texthandles = [];
    end    
    setappdata(hfig,'ROI',ROI);
    return;
else
    modelhandles = getappdata(hfig, 'modelhandles');
    FaceVertexCData = get(modelhandles.cortex,'FaceVertexCData');
    cmap = lines(ROI.current);
    for i = 1:ROI.current
        vidx = ROI.vertices{i};
        FaceVertexCData(vidx,:) = repmat(cmap(i,:),length(vidx),1);
    end
    set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);

    if ROI.texthandles
        delete(ROI.texthandles);
    end
    textcolor = [1.0 1.0 1.0];
    locations = 1.05*ROI.centers;
    ROI.texthandles = text( locations(:,1), locations(:,2), locations(:,3), ... 
                            upper(ROI.labels),'FontSize',8 ,...
                            'HorizontalAlignment','center', 'Color',textcolor);
    setappdata(hfig,'ROI',ROI);
end

% --------------------------------------------------------------------
function menu_showrois_Callback(hObject, eventdata, handles)
% hObject    handle to menu_showrois (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ROI = getappdata(hfig,'ROI');
len = length(ROI.labels);
if len<1
    helpdlg('There is no ROI!');
    return;
end

Updatecortex;

modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = get(modelhandles.cortex,'FaceVertexCData');

cmap = lines(len);
for i = 1:len
    vidx = ROI.vertices{i};
    FaceVertexCData(vidx,:) = repmat(cmap(i,:),length(vidx),1);
end
set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);

if ROI.texthandles
    delete(ROI.texthandles);
end

textcolor = [1.0 1.0 1.0];
locations = 1.05*ROI.centers;
ROI.texthandles = text( locations(:,1), locations(:,2), locations(:,3), ... 
                        upper(ROI.labels),'FontSize',8 ,...
                        'HorizontalAlignment','center', 'Color',textcolor);
                    
setappdata(hfig,'ROI',ROI);                     


% --------------------------------------------------------------------
function Untitled_4_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_modifylabel_Callback(hObject, eventdata, handles)
% hObject    handle to menu_modifylabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;

ROI = getappdata(hfig,'ROI');
if isempty(ROI.current)
    helpdlg('There is no ROI!');
    return;
end

label = ROI.labels{ROI.current};

prompt = {'ROI label, current is:'};
dlg_title = 'Input ROI label';
num_lines = 1;
def = {label};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

label = answer;
if isempty(label)
    helpdlg('There is no ROI label!');
    return;
end

ROI.labels(ROI.current) = label;

Updatecortex;

modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = get(modelhandles.cortex,'FaceVertexCData');

len = length(ROI.labels);
cmap = lines(len);
for i = 1:len
    vidx = ROI.vertices{i};
    FaceVertexCData(vidx,:) = repmat(cmap(i,:),length(vidx),1);
end

set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);
if ROI.texthandles
    delete(ROI.texthandles);
end
textcolor = [1.0 1.0 1.0];
locations = 1.05*ROI.centers;
ROI.texthandles = text( locations(:,1), locations(:,2), locations(:,3), ... 
                        upper(ROI.labels),'FontSize',8 ,...
                        'HorizontalAlignment','center', 'Color',textcolor);
setappdata(hfig,'ROI',ROI);



% --------------------------------------------------------------------
function menu_saverois_Callback(hObject, eventdata, handles)
% hObject    handle to menu_saverois (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;

ROI = getappdata(hfig,'ROI');
len = length(ROI.labels);
if len<1
    helpdlg('There is no ROI!');
    return;
end

[name, pathstr] = uiputfile('*.mat','Save Source Data');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

labels = ROI.labels;
centers = ROI.centers;
vertices = ROI.vertices;

options = getappdata(hfig,'options');
if options.usebem == 1
    BEM = getappdata(hfig,'BEM');
    cortex = BEM.Cortex;
else
    model = getappdata(hfig,'Model');
    cortex = model.cortex.colincortex;
end
numv = length(cortex.Vertices);

save(Fullfilename, 'labels','centers','vertices','numv');

% --------------------------------------------------------------------
function menu_roits_Callback(hObject, eventdata, handles)
% hObject    handle to menu_roits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
source = getappdata(hfig,'source');
if ~isfield(source,'data')
    helpdlg('Please localize sources!');
    return;
end

localized = getappdata(hfig,'localized');
options = getappdata(hfig,'options');
if ~all(localized(options.startepoch:options.endepoch))
    % helpdlg('Please localize Not all sources in the epoch are localized!');
    pop_roits;
    return;
end

ROI = getappdata(hfig,'ROI');
if options.usebem == 1
    BEM = getappdata(hfig,'BEM');
    SourceROI.Cortex = BEM.Cortex;
    SourceROI.usebem = 1;
else
    model = getappdata(hfig,'Model');
    SourceROI.Cortex = model.cortex.colincortex;
    SourceROI.usebem = 0;
end

SourceROI.data = source.data(options.startepoch:options.endepoch);
SourceROI.srate = EEG.srate;
len = length(ROI.labels);
if len < 1
    SourceROI.ROI = [];
else
    SourceROI.ROI.labels = ROI.labels;
    SourceROI.ROI.centers = ROI.centers;
    SourceROI.ROI.vertices = ROI.vertices;
end

pop_roits(SourceROI); % use localized source data in the epoch to compute ROI time series and connectivity.

% --------------------------------------------------------------------
function Untitled_13_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_14_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_11_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_12_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_15_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function popmenu_tsaxes_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu_tsaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_epochstart_Callback(hObject, eventdata, handles)
% hObject    handle to menu_epochstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes');
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
currentylim = get(tsaxes, 'Ylim');
ypos = [currentylim(1,1),  currentylim(1,2)];
    
tmpcolor = [0.0,0.0,1.0];
linehandle = findobj(hfig,'tag','leftline');
if isempty(linehandle)
   plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end

options = getappdata(hfig,'options');
options.startepoch = xpos(1,1);
setappdata(hfig,'options',options);

% --------------------------------------------------------------------
function menu_epochend_Callback(hObject, eventdata, handles)
% hObject    handle to menu_epochend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes');
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
currentylim = get(tsaxes, 'Ylim');
ypos = [currentylim(1,1),  currentylim(1,2)];
    
tmpcolor = [1.0,0.0,0.0];
linehandle = findobj(hfig,'tag','rightline');
if isempty(linehandle)
   plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end

options = getappdata(hfig,'options');
options.endepoch = xpos(1,1);
setappdata(hfig,'options',options);


% --------------------------------------------------------------------
function menu_defaultepoch_Callback(hObject, eventdata, handles)
% hObject    handle to menu_defaultepoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
tsaxes = findobj(hfig,'tag','tsaxes'); 
axes(tsaxes);
currentylim = get(tsaxes, 'Ylim');
ypos = [currentylim(1,1),  currentylim(1,2)];

EEG = getappdata(hfig,'EEG');
options = getappdata(hfig,'options');

xpos = [1,  1];
tmpcolor = [0.0, 0.0, 1.0];
linehandle = findobj(hfig,'tag','leftline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end 
options.startepoch = xpos(1,1);

xpos = [EEG.points,  EEG.points];
tmpcolor = [1.0,0.0,0.0];
linehandle = findobj(hfig,'tag','rightline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end 

options.endepoch = xpos(1,1);
setappdata(hfig,'options',options);


% --------------------------------------------------------------------
function menu_sourceg_Callback(hObject, eventdata, handles)
% hObject    handle to menu_sourceg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.sourcecaxis = 'global';

source = getappdata(hfig,'source');
len = length(source.data);
for i = 1:len
    currentsource = abs(source.data{i});
    if ~isempty(currentsource)
        minV= min(currentsource);
        maxV= max(currentsource);
        options.sourceminmax(1) = min(options.sourceminmax(1), minV);
        options.sourceminmax(2) = max(options.sourceminmax(2), maxV);
    end
end

setappdata(hfig,'options',options);

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
Updatecortex;

% --------------------------------------------------------------------
function Untitled_16_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_sourcel_Callback(hObject, eventdata, handles)
% hObject    handle to menu_sourcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.sourcecaxis = 'local';
setappdata(hfig,'options',options);

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
Updatecortex;

% --------------------------------------------------------------------
function menu_sensorg_Callback(hObject, eventdata, handles)
% hObject    handle to menu_sensorg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.sensorcaxis = 'global';
setappdata(hfig,'options',options);

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
Update;

% --------------------------------------------------------------------
function Untitled_19_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_sensorl_Callback(hObject, eventdata, handles)
% hObject    handle to menu_sensorl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.sensorcaxis = 'local';
setappdata(hfig,'options',options);

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
Update;



% --------------------------------------------------------------------
function menu_capsource_Callback(hObject, eventdata, handles)
% hObject    handle to menu_capsource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.cortexaxes, 'Cortical Source Image from Scalp EEG');

% --------------------------------------------------------------------
function Untitled_20_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_capsensor_Callback(hObject, eventdata, handles)
% hObject    handle to menu_capsensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.skinaxes, 'Potential Mapping Image of Scalp EEG');

% --------------------------------------------------------------------
function menu_playmov_Callback(hObject, eventdata, handles)
% hObject    handle to menu_playmov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
playmov([], 'Cortical Source Imaging Movie from Scalp EEG');


% --------------------------------------------------------------------
function menu_importbem_Callback(hObject, eventdata, handles)
% hObject    handle to menu_importbem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
BEM = getappdata(hfig,'BEM');
if ~isempty(BEM)
    importevent = questdlg('Exist customized BEM model, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

[name pathstr] = uigetfile('*.mat','Select BEM Model File');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);
bem = load(Fullfilename);
if ~isfield(bem, 'BEM')
    errordlg('The imported is not BEM model!');
    return;
end

if ~isequal(lower(bem.BEM.Unit),'mm')
    errordlg('The unit of the imported BEM model should be mm !');
    return;
end

EEG = getappdata(hfig,'EEG');
nbvidx = length(EEG.vidx);
nbelectro = size(bem.BEM.TransMatrix,1);
if nbvidx ~= nbelectro
    helpdlg(['The number of rows of the input transfer matrix should be ' num2str(nbvidx) ' (valid channels) !']);
    return;
end

options = getappdata(hfig,'options'); % update options
options.usebem = 1;

model = getappdata(hfig,'Model'); % update transfer matrix

if isequal(options.method,'wmn')
    matrix = bem.BEM.TransMatrix;
    [m,n] = size(matrix);
    model.W = zeros(1,n);
    for i = 1:n
        model.W(i) = (norm(matrix(:,i)))^1;
        matrix(:,i) = matrix(:,i) / model.W(i);
    end
    [model.U, model.s, model.V] = csvd(matrix);
elseif isequal(options.method,'mn')
    [model.U, model.s, model.V] = csvd(bem.BEM.TransMatrix);
end

% update BEM model
numface = length(bem.BEM.Cortex.Faces);
numverts = length(bem.BEM.Cortex.Vertices);
n = size(bem.BEM.TransMatrix,2);
if n == numverts
    bem.BEM.VertexBased = 1; % vertex based transfer matrix
    options.currymatrix = 0;
elseif n == numface
    bem.BEM.VertexBased = 0; % triangle based transfer matrix
    options.currymatrix = 0;
else
    options.currymatrix = 1; % vertex based transfer matrix from Curry
    bem.BEM.VertexBased = 1;
end

bem.BEM.Cortex.Centers = zeros(numface,3);
for i = 1:numface
    tri = bem.BEM.Cortex.Vertices(bem.BEM.Cortex.Faces(i,:),:);
    bem.BEM.Cortex.Centers(i,:) = mean(tri);
end
options.cortexnumverts = numverts;

h = waitbar(0.5,'Loading the BEM model, please wait...');

% build gaussian table
radius = 3*options.HWHM;
sigma = options.HWHM / sqrt(2*log(2));
x = [0:0.1:radius]';
y = exp(-(x).^2/(2*sigma^2))/(sigma * sqrt(2*pi));
if bem.BEM.VertexBased == 1
    X = bem.BEM.Cortex.Vertices;
else
    X = bem.BEM.Cortex.Centers;
end
XI = bem.BEM.Cortex.Vertices;
model.neighbors.neighbors.idx = {};
model.neighbors.neighbors.dis = {};
model.neighbors.neighbors.weight = {};
for i = 1:numverts
    all_dist = sqrt( (X(:,1)-XI(i,1)).^2 + (X(:,2)-XI(i,2)).^2 + (X(:,3)-XI(i,3)).^2 );
    local_index = find(all_dist < radius-0.5);
    model.neighbors.neighbors.idx(i) = {local_index};
    local_dist = all_dist(local_index);
    model.neighbors.neighbors.dis(i) = {local_dist};
    weight = y(round(local_dist*10)+1);
    model.neighbors.neighbors.weight(i) = {weight/sum(weight)};
end

% update cortex display
cortexaxes = findobj(hfig,'tag','cortexaxes');
axes(cortexaxes);
cla;
modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = repmat([0.6,0.6,0.6], numverts,1);
% modelhandles.cortex = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'Vertices',bem.BEM.Cortex.Vertices,...
%      'LineStyle','none',...
%      'Faces',bem.BEM.Cortex.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',FaceVertexCData,...
%      'tag','cotex');
modelhandles.cortex = trisurf(bem.BEM.Cortex.Faces,...
     bem.BEM.Cortex.Vertices(:,1),bem.BEM.Cortex.Vertices(:,2),bem.BEM.Cortex.Vertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',FaceVertexCData,...
     'tag','cotex');
lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
setappdata(hfig, 'modelhandles',modelhandles);

% update others
localized = getappdata(hfig,'localized');
localized(:) = 0;
setappdata(hfig,'localized',localized);
setappdata(hfig,'Model',model);
setappdata(hfig,'options',options);
setappdata(hfig,'BEM',bem.BEM);
source = getappdata(hfig,'source');
source.data = {};
setappdata(hfig,'source',source);

ROI = getappdata(hfig,'ROI');
ROI.labels = {};
ROI.vertices = {};
ROI.centers = [];
ROI.current = [];
ROI.radius = [];
ROI.texthandles = [];
ROI.adjradius = 3;
setappdata(hfig,'ROI',ROI);

close(h);
Updatecortex;

set(handles.menu_cutskin,'visible','off');
menu_bemstandard = findobj(hfig,'tag','menu_bemstandard');
menu_bemindividual = findobj(hfig,'tag','menu_bemindividual');
set(menu_bemstandard, 'checked', 'off');
set(menu_bemindividual, 'checked', 'on');

% --------------------------------------------------------------------
function menu_bem_Callback(hObject, eventdata, handles)
% hObject    handle to menu_bem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_bemstandard_Callback(hObject, eventdata, handles)
% hObject    handle to menu_bemstandard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options'); % update options
if options.usebem == 0 
    helpdlg('The current BEM model used is the standard one !');
    return;
end

options.usebem = 0;

model = getappdata(hfig,'Model'); % update transfer matrix

if isequal(options.method,'wmn')
    matrix = model.transmatrix;
    [m,n] = size(matrix);
    model.W = zeros(1,n);
    for i = 1:n
        model.W(i) = (norm(matrix(:,i)))^1;
        matrix(:,i) = matrix(:,i) / model.W(i);
    end
    [model.U, model.s, model.V] = csvd(matrix);
elseif isequal(options.method,'mn')
    [model.U, model.s, model.V] = csvd(model.transmatrix);
end

h = waitbar(0.5,'Loading the standard BEM model, please wait...');

% build gaussian table
radius = 3*options.HWHM;
sigma = options.HWHM / sqrt(2*log(2));
x = [0:0.1:radius]';
y = exp(-(x).^2/(2*sigma^2))/(sigma * sqrt(2*pi));
X = model.bemcortex.colinbemcortex.Centers;
XI = model.cortex.colincortex.Vertices;
model.neighbors.neighbors.idx = {};
model.neighbors.neighbors.dis = {};
model.neighbors.neighbors.weight = {};
numverts = length(XI);
for i = 1:numverts
    all_dist = sqrt( (X(:,1)-XI(i,1)).^2 + (X(:,2)-XI(i,2)).^2 + (X(:,3)-XI(i,3)).^2 );
    local_index = find(all_dist < radius-0.5);
    model.neighbors.neighbors.idx(i) = {local_index};
    local_dist = all_dist(local_index);
    model.neighbors.neighbors.dis(i) = {local_dist};
    weight = y(round(local_dist*10)+1);
    model.neighbors.neighbors.weight(i) = {weight/sum(weight)};
end

% update cortex display
cortexaxes = findobj(hfig,'tag','cortexaxes');
axes(cortexaxes);
cla;
hold on;
modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
% modelhandles.cortex = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'Vertices',model.cortex.colincortex.Vertices,...
%      'LineStyle','none',...
%      'Faces',model.cortex.colincortex.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',FaceVertexCData,...
%      'tag','cotex');
modelhandles.cortex = trisurf(model.cortex.colincortex.Faces,...
     model.cortex.colincortex.Vertices(:,1),model.cortex.colincortex.Vertices(:,2),model.cortex.colincortex.Vertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',FaceVertexCData,...
     'tag','cotex');
lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);

if options.cutskin
    visible = 'on';
else
    visible = 'off';
end

% modelhandles.cutskin = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'Vertices',model.cutskin.cutskin.Vertices,...
%      'LineStyle','none',...
%      'Faces',model.cutskin.cutskin.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',model.cutskin.cutskin.FaceVertexCData,...
%      'tag','cotex','visible',visible,'FaceAlpha',options.alpha);
 modelhandles.cutskin = trisurf(model.cutskin.cutskin.Faces,...
     model.cutskin.cutskin.Vertices(:,1), model.cutskin.cutskin.Vertices(:,2), model.cutskin.cutskin.Vertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'EdgeColor','none',...
     'FaceVertexCData',model.cutskin.cutskin.FaceVertexCData,...
     'tag','cotex','visible','off','FaceAlpha',options.alpha);
 
setappdata(hfig, 'modelhandles',modelhandles);

% update others
localized = getappdata(hfig,'localized');
localized(:) = 0;
setappdata(hfig,'localized',localized);
setappdata(hfig,'Model',model);
setappdata(hfig,'options',options);
source = getappdata(hfig,'source');
source.data = {};
setappdata(hfig,'source',source);

ROI = getappdata(hfig,'ROI');
ROI.labels = {};
ROI.vertices = {};
ROI.centers = [];
ROI.current = [];
ROI.radius = [];
ROI.texthandles = [];
ROI.adjradius = 3;
setappdata(hfig,'ROI',ROI);

close(h);
Updatecortex;

set(handles.menu_cutskin,'visible','on');

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

% --------------------------------------------------------------------
function menu_bemindividual_Callback(hObject, eventdata, handles)
% hObject    handle to menu_bemindividual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;

BEM = getappdata(hfig,'BEM');
if isempty(BEM)
    helpdlg('There is no individual BEM model !');
    return;
end
options = getappdata(hfig,'options'); % update options
if options.usebem == 1 
    helpdlg('The current BEM model used is the individual one !');
    return;
end
options.usebem = 1;

model = getappdata(hfig,'Model'); % update transfer matrix

if isequal(options.method,'wmn')
    matrix = BEM.TransMatrix;
    [m,n] = size(matrix);
    model.W = zeros(1,n);
    for i = 1:n
        model.W(i) = (norm(matrix(:,i)))^1;
        matrix(:,i) = matrix(:,i) / model.W(i);
    end
    [model.U, model.s, model.V] = csvd(matrix);
elseif isequal(options.method,'mn')
    [model.U, model.s, model.V] = csvd(BEM.TransMatrix);
end

h = waitbar(0.5,'Loading the individual BEM model, please wait...');

% build gaussian table
radius = 3*options.HWHM;
sigma = options.HWHM / sqrt(2*log(2));
x = [0:0.1:radius]';
y = exp(-(x).^2/(2*sigma^2))/(sigma * sqrt(2*pi));
if BEM.VertexBased == 1
    X = BEM.Cortex.Vertices;
else
    X = BEM.Cortex.Centers;
end
XI = BEM.Cortex.Vertices;
model.neighbors.neighbors.idx = {};
model.neighbors.neighbors.dis = {};
model.neighbors.neighbors.weight = {};
for i = 1:options.cortexnumverts
    all_dist = sqrt( (X(:,1)-XI(i,1)).^2 + (X(:,2)-XI(i,2)).^2 + (X(:,3)-XI(i,3)).^2 );
    local_index = find(all_dist < radius-0.5);
    model.neighbors.neighbors.idx(i) = {local_index};
    local_dist = all_dist(local_index);
    model.neighbors.neighbors.dis(i) = {local_dist};
    weight = y(round(local_dist*10)+1);
    model.neighbors.neighbors.weight(i) = {weight/sum(weight)};
end

% update cortex display
cortexaxes = findobj(hfig,'tag','cortexaxes');
axes(cortexaxes);
cla;
modelhandles = getappdata(hfig, 'modelhandles');
FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts,1);
% modelhandles.cortex = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'Vertices',BEM.Cortex.Vertices,...
%      'LineStyle','none',...
%      'Faces',BEM.Cortex.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',FaceVertexCData,...
%      'tag','cotex');
modelhandles.cortex = trisurf(BEM.Cortex.Faces,...
     BEM.Cortex.Vertices(:,1),BEM.Cortex.Vertices(:,2),BEM.Cortex.Vertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',FaceVertexCData,...
     'tag','cotex');
lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
setappdata(hfig, 'modelhandles',modelhandles);

% update others
localized = getappdata(hfig,'localized');
localized(:) = 0;
setappdata(hfig,'localized',localized);
setappdata(hfig,'Model',model);
setappdata(hfig,'options',options);
source = getappdata(hfig,'source');
source.data = {};
setappdata(hfig,'source',source);

ROI = getappdata(hfig,'ROI');
ROI.labels = {};
ROI.vertices = {};
ROI.centers = [];
ROI.current = [];
ROI.radius = [];
ROI.texthandles = [];
ROI.adjradius = 3;
setappdata(hfig,'ROI',ROI);

close(h);
Updatecortex;

set(handles.menu_cutskin,'visible','off');

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


% --------------------------------------------------------------------
function menu_GFP_Callback(hObject, eventdata, handles)
% hObject    handle to menu_GFP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');

options = getappdata(gcf,'options');
startpoint = options.startepoch;
endpoint = options.endepoch;
startpoint = min(max(startpoint,1),EEG.points);
endpoint = min(max(endpoint,1),EEG.points);
if startpoint > endpoint
    return;
end

% compute GFP with valid channels
ts = EEG.data(EEG.vidx,startpoint:endpoint);
srate = EEG.srate;
starttime = (startpoint - 1)/EEG.srate;
pos = [];

% compute global field power for the selected epoch.
ECOM_Butterfly(ts, srate, starttime, pos);


% --------------------------------------------------------------------
function menu_waveforms_Callback(hObject, eventdata, handles)
% hObject    handle to menu_waveforms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capaxis(handles.tsaxes, 'Scalp EEG Waveforms',0);

