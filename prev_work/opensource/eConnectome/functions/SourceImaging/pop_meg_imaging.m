function varargout = pop_meg_imaging(varargin)
% pop_meg_imaging - the GUI for cortical source imaging from MEG data.
%
% Usage: 
%            1. type 
%               >> pop_meg_imaging(MEG)
%               or call pop_meg_imaging(MEG) to start the popup GUI with
%               MEG structure. 
%               The MEG structure should be pre-exported by the megfc GUI 
%               or made by 
%               >> MEG = pop_meg_txtreader  
%               or
%               >> MEG = pop_meg_matreader
%               Please see the eConnectome Manual 
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable import MEG file formats (TXT and MAT).
%           
%            2. call pop_meg_imaging(MEG) from the megfc GUI ('Menu bar -> Inverse -> Source Imaging') 
%                if the MEG data is available in the megfc GUI.
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
% The cortex model used in the program are constructed based
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
% Yakang Dai, 24-Jan-2011 13:57:30
% Release Version 2.0 beta
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_meg_imaging_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_meg_imaging_OutputFcn, ...
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


% --- Executes just before pop_meg_imaging is made visible.
function pop_meg_imaging_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_meg_imaging (see VARARGIN)

% Choose default command line output for pop_meg_imaging
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_meg_imaging wait for user response (see UIRESUME)
% uiwait(handles.sourceloc);

len = length(varargin);

if len~=1
    errordlg('Input arguments mismatch!','Input error','modal');
    return;
end

MEG = varargin{1};
setappdata(hObject,'MEG',MEG);

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


%% initialize time series window
axes(handles.tsaxes);

% the limitation in the x axis
xlimit = MEG.points;    
xlabelstep = round(xlimit/10);
    
% x labels
xlabelpositions = [0:xlabelstep:xlimit];
xlabels = [0:xlabelstep:xlimit]./ MEG.srate;
xlabels = num2str(xlabels');
     
% y labels
nbvidx = length(MEG.vidx);
% fontsize = 1/nbvidx;
channelmaxs = max(MEG.data(MEG.vidx,:),[ ],2);
channelmins = min(MEG.data(MEG.vidx,:),[ ],2);    
spacing = mean(channelmaxs-channelmins);  
ylimit = (nbvidx+1)*spacing;
ylabelpositions = [0:spacing:nbvidx*spacing];    
YLabels = strvcat(MEG.labels(MEG.vidx)); 
YLabels = flipud(str2mat(YLabels,''));

axes(handles.tsaxes);     
set(handles.tsaxes,...
      'Xlim',[0 xlimit],...
      'xtick',xlabelpositions,...% where to display the labels.
      'XTickLabel', xlabels,...
      'Ylim',[0 ylimit],...
      'YTick',ylabelpositions,...
      'YTickLabel', YLabels); % the labels to be displayed
%       'YTickLabel', YLabels, 'FontUnits','normalized','FontSize',fontsize); % the labels to be displayed
cla;        
hold on;

tmpcolor = [ 0.0 0.0 1.0 ];
for i = 1:nbvidx
	plot(MEG.data(MEG.vidx(nbvidx-i+1),:)+i*spacing,'color', tmpcolor, 'clipping','on');
end
%%

%% initialize skin and cortex
% get models
model.italyskin = load('italyskin.mat');
model.cutskin = load('cutskin.mat');
model.cortex = load('colincortex.mat');
model.bemcortex = load('colinbemcortex.mat');
model.neighbors = load('neighbors.mat');
model.sphere = load('Sphere.mat');

% transform italyskin, colinbemcortex, spherical volume conductor
% model and MEG cap into the intermediate coordinate system based on the Nz, LPA and RPA.
model.CoR = load('CoR.mat');
num = length(model.italyskin.italyskin.Vertices); % italyskin
model.italyskin.interVertices = (model.italyskin.italyskin.Vertices+repmat(model.CoR.italyskin.translation,num,1))*model.CoR.italyskin.rotation;
num = length(model.bemcortex.colinbemcortex.Vertices); % colinbemcortex
model.bemcortex.interVertices = (model.bemcortex.colinbemcortex.Vertices+repmat(model.CoR.colinbemskin.translation,num,1))*model.CoR.colinbemskin.rotation;
len = length(model.bemcortex.colinbemcortex.Centers); % centers of colinbemcortex
model.bemcortex.interCenters = (model.bemcortex.colinbemcortex.Centers+repmat(model.CoR.colinbemskin.translation,len,1))*model.CoR.colinbemskin.rotation;
model.sphere.Center = (model.sphere.Center+model.CoR.colinbemskin.translation)*model.CoR.colinbemskin.rotation; % spherical volume conductor model

% len = length(MEG.locations.colinbrain);
% model.MEGcolinbrain = MEG.locations.colinbrain * inv(model.CoR.colinbemskin.rotation) - repmat(model.CoR.colinbemskin.translation,len,1);
    
model.k = MEG.vidx;% MEG cap
model.mag.labels = MEG.labels(model.k);
model.mag.locations.italybrain = MEG.locations.italybrain(model.k,:);
model.mag.locations.colinbrain = MEG.locations.colinbrain(model.k,:);
if isempty(MEG.locations.normals.colinbrain)
    model.mag.locations.normals = [];
else
    model.mag.locations.normals = MEG.locations.normals.colinbrain(model.k,:);
end
model.mag.locations.surf = MEG.locations.surf;
model.X = MEG.locations.surf.x(model.k,1); 
model.Y = MEG.locations.surf.y(model.k,1);   
model.XI = MEG.locations.surf.x(:,1); 
model.YI = MEG.locations.surf.y(:,1); 

% for decomposing of the transfer matrix 
model.transmatrix = [];
model.U = [];
model.s = [];
model.V = [];

% options for MEG source imaging and visualization
options.step = round(MEG.points/10);
if options.step <= 0
    options.step = 2;
end
options.vidx = MEG.vidx;
options.currentpoint = 1;
options.auto = 0;
options.method = 'mn';
options.lamda = 0;
options.autocorner = 1;
options.threshold = 0.0;
options.HWHM = 3;
options.startepoch = 1;
options.endepoch = MEG.points;
options.alpha = 1;
options.cutskin = 'off';
options.labels = 'off';
options.mags = 'off';
options.head = 'on';
options.map = 'on';
options.sensorcaxis = 'local';
options.sensorminmax = [MEG.min, MEG.max];
options.sourcecaxis = 'local';
options.sourceminmax = [realmax, realmin];
options.individual = 0;
options.currymatrix = 0;
movie.on = 0;
movie.sensorminmax = [realmax, realmin];
movie.sourceminmax = [realmax, realmin];

% cortical regions of interest
ROI.labels = {};
ROI.vertices = {};
ROI.centers = [];
ROI.current = [];
ROI.radius = [];
ROI.texthandles = [];
ROI.adjradius = 3;

% draw italy skin, MEG cap, sensors and labels
axes(handles.skinaxes);
hold on;
modelhandles.italyskin = trisurf(model.italyskin.italyskin.Faces,... 
     model.italyskin.interVertices(:,1), model.italyskin.interVertices(:,2), model.italyskin.interVertices(:,3),...
     'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'LineStyle','none',...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',model.italyskin.italyskin.FaceVertexCData,...
     'visible', options.head);
lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);

% cap 
capcolor = [0.9, 0.85, 0.7];
modelhandles.map = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                                                 'FaceLighting','phong',...
                                                 'Vertices',MEG.locations.italybrain,...
                                                 'LineStyle','-',...
                                                 'Faces',MEG.locations.surf.tri,...
                                                 'FaceColor','flat',...
                                                 'FaceAlpha',1,...
                                                 'EdgeColor','k',...
                                                 'FaceVertexCData',capcolor,...
                                                 'Visible',options.map);
                                             
% sensors                                                 
magcolor = [0.0  1.0  1.0];
modelhandles.mags = plot3(model.mag.locations.italybrain(:,1), ...
                                             model.mag.locations.italybrain(:,2), ... 
                                             model.mag.locations.italybrain(:,3), ... 
                                             'k.','LineWidth',4,'color', magcolor, ...
                                             'visible', options.mags);                                 

% labels      
textcolor = [0.0 0.0 0.0];
locations = 1.05*model.mag.locations.italybrain;
modelhandles.labels = text( locations(:,1), locations(:,2), locations(:,3), ... 
                                             upper(model.mag.labels),'FontSize',8 ,...
                                             'HorizontalAlignment','center', 'Color',textcolor, ...
                                             'visible', options.labels);

 % draw colincortex and cutskin
axes(handles.cortexaxes);
hold on;
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
     'tag','cotex','visible',options.cutskin,'FaceAlpha',options.alpha);
 
% % cap 
% capcolor = [0.9, 0.85, 0.7];
% modelhandles.colinbrainmap = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%                                                  'FaceLighting','phong',...
%                                                  'Vertices',model.MEGcolinbrain,...
%                                                  'LineStyle','-',...
%                                                  'Faces',MEG.locations.surf.tri,...
%                                                  'FaceColor','flat',...
%                                                  'FaceAlpha',1,...
%                                                  'EdgeColor','k',...
%                                                  'FaceVertexCData',capcolor,...
%                                                  'Visible',options.map);
 
lighting phong; % phong
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
%%

set(handles.texttotalpoints,'string',num2str(MEG.points));
set(handles.texttotaltime,'string',[num2str(MEG.points/MEG.srate) ' s']);
set(handles.textsensorchannels,'string',num2str(length(options.vidx)));
set(handles.textsourcechannels,'string',num2str(length(model.cortex.colincortex.Vertices)));
set(handles.editcurrentpoint,'string',num2str(options.currentpoint));
set(handles.editcurrenttime,'string',num2str(options.currentpoint/MEG.srate));

setappdata(hObject,'Model',model);
setappdata(hObject,'options',options);
source.data = {};
setappdata(hObject,'source',source);
sensor.data = {};
setappdata(hObject,'sensor',sensor);
localized = zeros(MEG.points,1);
topomaped = localized;
setappdata(hObject,'localized',localized);
setappdata(hObject,'topomaped',topomaped);
setappdata(hObject, 'modelhandles',modelhandles);
setappdata(hObject,'ROI',ROI);
setappdata(hObject,'movie',movie);
setappdata(hObject,'BEM',[]);
setappdata(hObject,'SCALE',1);
setappdata(hObject,'SensorPower',[]);
setappdata(hObject,'SourcePower',[]);

set(hObject,'windowbuttonmotionfcn', @mousemotionCallback);
set(hObject,'WindowButtonDownFcn', @mousebuttondownCallback); 

% --- Outputs from this function are returned to the command line.
function varargout = pop_meg_imaging_OutputFcn(hObject, eventdata, handles) 
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');
options.currentpoint = options.currentpoint + 1;
if options.currentpoint > MEG.points
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');
options.currentpoint = options.currentpoint + options.step;
if options.currentpoint > MEG.points
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');
options.currentpoint = MEG.points;
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
    capV = sensor.data{i};
    sensorminmax(1) = min(min(capV),sensorminmax(1));
    sensorminmax(2) = max(max(capV),sensorminmax(2));
    
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
playmov(mov, 'Cortical Source Imaging Movie from MEG');

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
    helpdlg('Please perform source imaging for the epoch first!');
    return;
end
sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');
movie = getappdata(hfig,'movie');
sensorminmax = [realmax realmin];
sourceminmax = [realmax realmin];
for i = options.startepoch:options.endepoch
    capV = sensor.data{i};
    sensorminmax(1) = min(min(capV),sensorminmax(1));
    sensorminmax(2) = max(max(capV),sensorminmax(2));
    
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
playmov(mov, 'Cortical Source Imaging Movie from MEG');

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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');
sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');
localized = getappdata(hfig,'localized');
topomaped = getappdata(hfig,'topomaped');

if options.individual == 1 
    BEM = getappdata(hfig,'BEM');
    matrix = BEM.TransMatrix;
else
    matrix = model.transmatrix;
end

if isempty(matrix)
    helpdlg('There is no transfer matrix, please compute or load first!');
    return;
end

if options.startepoch > options.endepoch
    errordlg('The epoch specification is not right !');
    return;
end

ratio = 100 / (options.endepoch - options.startepoch);
for i = options.startepoch : options.endepoch
    
    magsV = MEG.data(options.vidx,i);
    
    % compute map for sensor space
    capV = griddata(model.X,model.Y,magsV,model.XI,model.YI,'v4');
    minV = min(magsV);
    maxV = max(magsV);
    k = find(capV<minV);
    capV(k) = minV;
    k = find(capV>maxV);
    capV(k) = maxV;        
    sensor.data(i) = {capV};

    % compute sources on cortex
    if isequal(options.method,'mn') % compute sources on cortex
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,magsV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,magsV,options.lamda);
    elseif isequal(options.method,'wmn')
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,magsV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,magsV,options.lamda);
        cortexVI = cortexVI ./ model.W';
    end
    
    if options.currymatrix == 1
        len = length(cortexVI);
        cortexVI(len+1:options.cortexnumverts) = 0;
    end
    
%     if ~options.fixed
%         p = size(cortexVI,1)/3; % number of dipoles
%         tempVI = zeros(p,1);
%         for j = 1:p
%             m = [-2:0] + 3*j;
%             tempVI(j,1) = model.bemcortex.dipole_dirs(j,:) * cortexVI(m,1);
%         end
%         cortexVI = tempVI;
%     end
    
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');
magsV = MEG.data(options.vidx,options.currentpoint);
localized = getappdata(hfig,'localized');
topomaped = getappdata(hfig,'topomaped');
movie = getappdata(hfig,'movie');

%% update the skin map
islocalized = localized(options.currentpoint);
istopomaped = topomaped(options.currentpoint);

sensor = getappdata(hfig,'sensor');

% not to interpolate sensor if it exists.
if ~istopomaped
    capV = griddata(model.X,model.Y,magsV,model.XI,model.YI,'v4');
    minV = min(magsV);
    maxV = max(magsV);
    k = find(capV<minV);
    capV(k) = minV;
    k = find(capV>maxV);
    capV(k) = maxV;        
    sensor.data(options.currentpoint) = {capV};
    setappdata(hfig,'sensor',sensor);
    topomaped(options.currentpoint) = 1;
    setappdata(hfig,'topomaped',topomaped);
end
capV = sensor.data{options.currentpoint};

if movie.on
    minV = movie.sensorminmax(1);
    maxV = movie.sensorminmax(2);
else
    if isequal(options.sensorcaxis, 'global')
        minV = options.sensorminmax(1);
        maxV = options.sensorminmax(2);
    else
        minV = min(capV);
        maxV = max(capV);
    end
end
absV = max(abs(minV), abs(maxV));
minV = -absV;
maxV = absV;    

axes(skinaxes);
caxis([minV maxV]);
modelhandles = getappdata(hfig,'modelhandles');
set(modelhandles.map, 'LineStyle','none', 'FaceColor','interp', 'FaceVertexCData', capV, 'Visible', options.map);                                          
colorbar;             

%% update the cortex map
source = getappdata(hfig,'source');

% not to localize source if it exists.
if ~islocalized
    if options.individual == 1 
        BEM = getappdata(hfig,'BEM');
        matrix = BEM.TransMatrix;
    else
        matrix = model.transmatrix;
    end

    if isempty(matrix)
        helpdlg('There is no transfer matrix, please compute or load first!');
        return;
    end
    if isequal(options.method,'mn') % compute sources on cortex
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,magsV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,magsV,options.lamda);
    elseif isequal(options.method,'wmn')
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,magsV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,magsV,options.lamda);
        cortexVI = cortexVI ./ model.W';
    end
    
    if options.currymatrix == 1
        len = length(cortexVI);
        cortexVI(len+1:options.cortexnumverts) = 0;
    end
    
%     if ~options.fixed
%         p = size(cortexVI,1)/3; % number of dipoles
%         tempVI = zeros(p,1);
%         for i = 1:p
%             m = [-2:0] + 3*i;
%             if model.bemcortex.dipole_dirs(i,:) * cortexVI(m,1) >= 0
%                 tempVI(i,1) = norm(cortexVI(m,1));
%             else
%                 tempVI(i,1) = - norm(cortexVI(m,1));
%             end
%         end
%         cortexVI = tempVI;
%     end
    
    % get smooth values on finer colin cortex
    len = length(model.neighbors.neighbors.idx);
    cortexV = zeros(len,1);
    for i = 1:len
%         idx = model.neighbors.neighbors.idx{i};
%         weight = model.neighbors.neighbors.weight{i};
%         num = length(idx);
%         rotateV = zeros(3,1);
%         for j = 1:num
%             m = [-2:0] + 3*idx(j);
%             rotateV = rotateV + weight(j)*cortexVI(m,1);
%         end
%         cortexV(i,:) = norm(rotateV);

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
else
    if isequal(options.sourcecaxis, 'global')
        minV2 = options.sourceminmax(1);
        maxV2 = options.sourceminmax(2);
    else
        minV2 = min(cortexV);
        maxV2 = max(cortexV);
    end
end
minV2 = 0;
coef = 1/(maxV2-minV2);
cortexV = (cortexV-minV2)*coef;
nzK = find(cortexV > options.threshold);
% minV2 = 0;
maxV2 = 1;

if options.individual == 1
    FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts, 1);
else
    FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
end

cmap = colormap;
len = length(cmap);
coef = (len-1)/(maxV2 - minV2);
FaceVertexCData(nzK,:) = cmap(round(coef*(cortexV(nzK)-minV2)+1),:);

axes(cortexaxes);
caxis([minV2 maxV2]);

set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);
% set(modelhandles.colinbrainmap, 'LineStyle','none', 'FaceColor','interp', 'FaceVertexCData', capV, 'Visible', options.map);  

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
set(editcurrenttime,'string',num2str(options.currentpoint/MEG.srate));
setappdata(hfig,'options',options);


function Updatecortex()
hfig = gcf;
cortexaxes = findobj(hfig,'tag','cortexaxes');
model = getappdata(hfig,'Model');
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');
magsV = MEG.data(options.vidx,options.currentpoint);
localized = getappdata(hfig,'localized');

source = getappdata(hfig,'source');

islocalized = localized(options.currentpoint);

% not to localize source if it exists.
if ~islocalized
    if isequal(options.method,'mn') % compute sources on cortex
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,magsV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,magsV,options.lamda);
    elseif isequal(options.method,'wmn')
        if options.autocorner
            tempf = figure;
            options.lamda = l_curve(model.U,model.s,magsV,'tikh');  
            close(tempf);
        end
        cortexVI = tikhonov(model.U,model.s,model.V,magsV,options.lamda);
        cortexVI = cortexVI ./ model.W';
    end
    
    if options.currymatrix == 1
        len = length(cortexVI);
        cortexVI(len+1:options.cortexnumverts) = 0;
    end
    
%     if ~options.fixed
%         p = size(cortexVI,1)/3; % number of dipoles
%         tempVI = zeros(p,1);
%         for i = 1:p
%             m = [-2:0] + 3*i;
%             tempVI(i,1) = model.bemcortex.dipole_dirs(i,:) * cortexVI(m,1);
%         end
%         cortexVI = tempVI;
%     end
    
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
else
    minV = min(cortexV);
    maxV = max(cortexV);
end
coef = 1/(maxV-minV);
cortexV = (cortexV-minV)*coef;
nzK = cortexV > options.threshold;
minV = 0;
maxV = 1;

if options.individual == 1
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

function editcurrentpoint_Callback(hObject, eventdata, handles)
% hObject    handle to editcurrentpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editcurrentpoint as text
%        str2double(get(hObject,'String')) returns contents of editcurrentpoint as a double

hfig = gcf;
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');

currentpoint = str2num(get(hObject,'String'));
if isempty(currentpoint)
    warndlg('Input MUST be NUMERIC !');
    set(hObject,'String',num2str(options.currentpoint));
    return;
end
currentpoint = round(currentpoint);
currentpoint = max(1,min(currentpoint, MEG.points));
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');

currenttime = str2num(get(hObject,'String'));
if isempty(currenttime)
    warndlg('Input MUST be NUMERIC !');
    set(hObject,'String',num2str(options.currentpoint/MEG.srate));
    return;
end
currentpoint = round(currenttime*MEG.srate);
currentpoint = max(1,min(currentpoint, MEG.points));
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
MEG = getappdata(hfig,'MEG');

ismatch = 1;
if sensordata.startepoch<1 | sensordata.startepoch>MEG.points | sensordata.endepoch<1 | sensordata.endepoch>MEG.points
    ismatch = 0;
end
    
if sz ~= MEG.nbchan | ismatch==0
    errordlg('The imported is not the correct sensor data relative to the imported MEG!');
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

if options.individual == 0
    model = getappdata(hfig,'Model');
    len = length(model.cortex.colincortex.Vertices);
else
    BEM = getappdata(hfig,'BEM');
    len = length(BEM.Cortex.Vertices);
end

ismatch = 1;
MEG = getappdata(hfig,'MEG');
if sourcedata.startepoch<1 | sourcedata.startepoch>MEG.points | sourcedata.endepoch<1 | sourcedata.endepoch>MEG.points
    ismatch = 0;
end

if sz ~= len | ismatch==0
    errordlg('The imported source can NOT match the BEM model and MEG data!');
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');

sensordata = sensor.data(options.startepoch:options.endepoch);
srate = MEG.srate;
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig,'options');

sourcedata = source.data(options.startepoch:options.endepoch);
srate = MEG.srate;
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
    if options.individual == 1
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
datacursors = get(dcm_obj,'DataCursors');
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
if options.individual == 1
    BEM = getappdata(hfig,'BEM');
    if BEM.VertexBased == 1
        X = BEM.Cortex.Vertices;
    else
        X = BEM.Cortex.Centers; % Triangle Based
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

MEG = getappdata(hfig,'MEG');
cursorpoint = round(mousepos(1,1));%find the nearest point.
if cursorpoint < 1 | cursorpoint > MEG.points
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

MEG = getappdata(hfig,'MEG');
cursorpoint = round(mousepos(1,1));%find the nearest point.
if cursorpoint < 1 | cursorpoint > MEG.points
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
if options.individual == 1 
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
MEG = getappdata(hfig,'MEG');
options = getappdata(hfig, 'options');
model = getappdata(hfig,'Model');
regularization.U = model.U;
regularization.s = model.s;
regularization.b = MEG.data(options.vidx,options.currentpoint);
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

if options.individual == 1 
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

if options.individual == 1 
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
function menu_mags_Callback(hObject, eventdata, handles)
% hObject    handle to menu_mags (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.mags = 'off';
else
    ischecked = 'on';
    options.mags = 'on';
end

setappdata(hfig, 'options', options);
set(hObject,'checked',ischecked);

modelhandles = getappdata(hfig, 'modelhandles');
axes(handles.skinaxes);
set(modelhandles.mags,'visible',options.mags);


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
if options.individual == 1
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
if options.individual == 1
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
if options.individual == 1
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
MEG = getappdata(hfig,'MEG');
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
if options.individual == 1
    BEM = getappdata(hfig,'BEM');
    SourceROI.Cortex = BEM.Cortex;
    SourceROI.usebem = 1;
else
    model = getappdata(hfig,'Model');
    SourceROI.Cortex = model.cortex.colincortex;
    SourceROI.usebem = 0;
end

SourceROI.data = source.data(options.startepoch:options.endepoch);
SourceROI.srate = MEG.srate;
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

MEG = getappdata(hfig,'MEG');
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

xpos = [MEG.points,  MEG.points];
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
capobj(handles.cortexaxes, 'Cortical Source Image from MEG');

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
capobj(handles.skinaxes, 'Field Mapping Image of MEG');

% --------------------------------------------------------------------
function menu_playmov_Callback(hObject, eventdata, handles)
% hObject    handle to menu_playmov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
playmov([], 'Cortical Source Imaging Movie from MEG');


% --------------------------------------------------------------------
function menu_import_bem_Callback(hObject, eventdata, handles)
% hObject    handle to menu_import_bem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
BEM = getappdata(hfig,'BEM');
if ~isempty(BEM)
    importevent = questdlg('Exist Individual BEM model, import new one ?','','Yes','Cancel','Cancel');
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
BEM = load(Fullfilename);
if ~isfield(BEM, 'BEM')
    errordlg('The imported is not BEM model!');
    return;
end

if ~isequal(lower(BEM.BEM.Unit),'mm')
    errordlg('The unit of the imported BEM model should be mm !');
    return;
end

MEG = getappdata(hfig,'MEG');
nbvidx = length(MEG.vidx);
nbelectro = size(BEM.BEM.TransMatrix,1);
if nbvidx ~= nbelectro
    helpdlg(['The number of rows of the input transfer matrix should be ' num2str(nbvidx) ' (valid channels) !']);
    return;
end

options = getappdata(hfig,'options'); % update options
options.individual = 1;

model = getappdata(hfig,'Model'); % update transfer matrix

if isequal(options.method,'wmn')
    matrix = BEM.BEM.TransMatrix;
    [m,n] = size(matrix);
    model.W = zeros(1,n);
    for i = 1:n
        model.W(i) = (norm(matrix(:,i)))^1;
        matrix(:,i) = matrix(:,i) / model.W(i);
    end
    [model.U, model.s, model.V] = csvd(matrix);
elseif isequal(options.method,'mn')
    [model.U, model.s, model.V] = csvd(BEM.BEM.TransMatrix);
end

% update BEM model
numface = length(BEM.BEM.Cortex.Faces);
numverts =  length(BEM.BEM.Cortex.Vertices);
n = size(BEM.BEM.TransMatrix,2);
if n == numverts
    BEM.BEM.VertexBased = 1; % vertex based transfer matrix
    options.currymatrix = 0;
elseif n == numface
    BEM.BEM.VertexBased = 0; % triangle based transfer matrix
    options.currymatrix = 0;
else
    options.currymatrix = 1; % vertex based transfer matrix from Curry
    BEM.BEM.VertexBased = 1;
end

BEM.BEM.Cortex.Centers = zeros(numface,3);
for i = 1:numface
    tri = BEM.BEM.Cortex.Vertices(BEM.BEM.Cortex.Faces(i,:),:);
    BEM.BEM.Cortex.Centers(i,:) = mean(tri);
end
options.cortexnumverts = numverts;

h = waitbar(0.5,'Loading the BEM model, please wait...');

% build gaussian table
radius = 3*options.HWHM;
sigma = options.HWHM / sqrt(2*log(2));
x = [0:0.1:radius]';
y = exp(-(x).^2/(2*sigma^2))/(sigma * sqrt(2*pi));
if BEM.BEM.VertexBased == 1
    X = BEM.BEM.Cortex.Vertices;
else
    X = BEM.BEM.Cortex.Centers;
end
XI = BEM.BEM.Cortex.Vertices;
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
%      'Vertices',BEM.BEM.Cortex.Vertices,...
%      'LineStyle','none',...
%      'Faces',BEM.BEM.Cortex.Faces,...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',FaceVertexCData,...
%      'tag','cotex');
modelhandles.cortex = trisurf(BEM.BEM.Cortex.Faces,...
     BEM.BEM.Cortex.Vertices(:,1),BEM.BEM.Cortex.Vertices(:,2),BEM.BEM.Cortex.Vertices(:,3),...
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
setappdata(hfig,'BEM',BEM.BEM);
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
if options.individual == 0 
    helpdlg('The current BEM model used is the standard one !');
    return;
end

options.individual = 0;

model = getappdata(hfig,'Model'); % update transfer matrix
if isempty(model.transmatrix)
    helpdlg('There is no transfer matrix in the standard BEM model, please compute transfer matrix first!');
    return;
end

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
if options.individual == 1 
    helpdlg('The current BEM model used is the individual one !');
    return;
end
options.individual = 1;

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
function menu_map_Callback(hObject, eventdata, handles)
% hObject    handle to menu_map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.map = 'off';
else
    ischecked = 'on';
    options.map = 'on';
end

setappdata(hfig, 'options', options);
set(hObject,'checked',ischecked);

modelhandles = getappdata(hfig, 'modelhandles');
axes(handles.skinaxes);
set(modelhandles.map,'visible',options.map);

% --------------------------------------------------------------------
function menu_head_Callback(hObject, eventdata, handles)
% hObject    handle to menu_head (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.head = 'off';
else
    ischecked = 'on';
    options.head = 'on';
end

setappdata(hfig, 'options', options);
set(hObject,'checked',ischecked);

modelhandles = getappdata(hfig, 'modelhandles');
axes(handles.skinaxes);
set(modelhandles.italyskin,'visible',options.head);


% --------------------------------------------------------------------
function menu_compute_transmatrix_Callback(hObject, eventdata, handles)
% hObject    handle to menu_compute_transmatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
model = getappdata(hfig, 'Model');
noNormal = isempty(model.mag.locations.normals);

% if noNormal
%     errordlg('Normals of the magnetometers are missing.');
%     return;
% end
% options = getappdata(hfig, 'options');
% comevent = questdlg('Fixed dipoles?','','Fixed','Rotating','Fixed');
% if strcmp(comevent, 'Fixed')
%     options.fixed = 1;
% elseif strcmp(comevent, 'Rotating')
%     options.fixed = 0;
% else
%     return;
% end
% setappdata(hfig,'options',options);

% if ~noNormal
%     comevent = questdlg('Include sensor normals?','','Yes','No','Yes');
%     if strcmp(comevent, 'Yes')
%         noNormal = 0;
%     elseif strcmp(comevent, 'No')
%         noNormal = 1;
%     else
%         return;
%     end
% end

info.sensornorm = ~noNormal;
forward_options = pop_meg_forward(info);
if isempty(forward_options)
    return;
end
noNormal = ~forward_options.sensornorm;

h = waitbar(0,'Calculating the transfer matrix, please wait...');

% lead field matrix initialization
N = length(model.mag.locations.colinbrain); % number of valid MEG sensors
M = length(model.bemcortex.colinbemcortex.Faces); % number of dipoles associated with cortical triangles
% model.transmatrix = zeros(N,M);

% dipole directions
dipole_dirs = zeros(M,3);
for i = 1:M
    idx = model.bemcortex.colinbemcortex.Faces(i,:); % i-th triangle
    edge1 = model.bemcortex.interVertices(idx(2),:) - model.bemcortex.interVertices(idx(1),:);
    edge2 = model.bemcortex.interVertices(idx(3),:) - model.bemcortex.interVertices(idx(1),:);
    edge1 = edge1/norm(edge1);
    edge2 = edge2/norm(edge2);
    dipole_dirs(i,:) = cross(edge1,edge2);
    dipole_dirs(i,:) = dipole_dirs(i,:)/norm(dipole_dirs(i,:));
end
model.bemcortex.dipole_dirs = dipole_dirs;

ct = 0;
total = M;
step = ceil(M/10);

sphereCenter = model.sphere.Center;  

% % compute spherical model based on sensor positions
% sphere_model = getsphere(model.mag.locations.colinbrain);
% sphereCenter = sphere_model.Center;

% compute lead field/transfer matrix, fixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model.transmatrix = zeros(N,M);
for i = 1:M
    r0 = model.bemcortex.interCenters(i,:)-sphereCenter; % dipole location (center of triangle) in the sphere coordinate system
    Q = dipole_dirs(i,:); % direction of the unit dipole
    for j = 1:N
        r = model.mag.locations.colinbrain(j,:)-sphereCenter; % MEG sensor location in the sphere coordinate system
        a = r-r0;
        ad = norm(a);
        rd = norm(r);
        F = ad*(rd*ad+rd*rd-dot(r0,r));
        p = dot(a,r)/ad;
        K = ad*ad/rd+p+2*ad+2*rd; 
        L = ad+2*rd+p;
        dF = K*r-L*r0;
        alpha = cross(Q,r0);
        belta = 1/(F^2);
        LF = belta*(F*alpha-dot(alpha,r)*dF);
        
        if noNormal
            model.transmatrix(j,i) = norm(LF); % without sensor normal
        else
            model.transmatrix(j,i) = dot(LF, model.mag.locations.normals(j,:)); % with sensor normal           
        end
        
    end
    ct = ct + 1; 
    if ~mod(ct, step)
       waitbar(ct/total);
    end
end
% model.transmatrix = model.transmatrix * 1e-7;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% % compute lead field/transfer matrix
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% options.fixed = 1;
% if options.fixed 
%     model.transmatrix = zeros(N,M);
% else
%     model.transmatrix = zeros(N,M*3);
% end
% 
% r0 = model.bemcortex.interCenters-repmat(sphereCenter,M,1); % dipole location (center of triangle) in the sphere coordinate system
% r = model.mag.locations.colinbrain-repmat(sphereCenter,N,1); % MEG sensor location in the sphere coordinate system
% rd = zeros(N,1);
% for j = 1:N
%     rd(j) = norm(r(j,:));
% end
% Id = eye(3,3);
% for i = 1:M  % dipoles   
%     Cr0 = [0,           -r0(i,3),        r0(i,2); 
%                r0(i,3),         0,          -r0(i,1);
%                -r0(i,2),    r0(i,1),        0];          
%     if ~options.fixed 
%         m = 3*i-2 : 3*i;
%     end
%     for j = 1:N  % sensors
%         a = r(j,:)-r0(i,:);
%         ad = norm(a);
%         F = ad*(rd(j)*(ad+rd(j))-dot(r0(i,:),r(j,:)));
%         p = dot(a,r(j,:))/ad;
%         K = ad*ad/rd(j)+p+2*ad+2*rd(j);
%         L = ad+2*rd(j)+p;
%         dF = K*r(j,:)-L*r0(i,:);
%         
%         Kij = (dF' * r(j,:) - F * Id)*Cr0/(F^2);
%         
%         Gij = model.mag.locations.normals(j,:) * Kij;
%         
%         if options.fixed 
%             model.transmatrix(j,i) = Gij * (dipole_dirs(i,:))'; % fixed dipoles
%         else
%             model.transmatrix(j,m) = Gij; % rotating dipoles    
%         end
%         
% %         % rotating dipoles       
% %         model.transmatrix(j,m) = Gij;        
% %         % fixed dipoles
% %         model.transmatrix(j,i) = Gij * (dipole_dirs(i,:))';
% 
%     end
%     ct = ct + 1; 
%     if ~mod(ct, step)
%        waitbar(ct/total);
%     end
% end
% model.transmatrix = model.transmatrix * 1e-7;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options = getappdata(hfig, 'options');
if options.individual == 0 
    
    % row equilibration
    if forward_options.rownorm
        [m,n] = size(model.transmatrix);
        for i = 1:m
            norm_row = (norm(model.transmatrix(i,:)));
            model.transmatrix(i,:) = model.transmatrix(i,:) / norm_row;
        end
    end
    
    % column equilibration
    if forward_options.columnnorm
        [m,n] = size(model.transmatrix);
        for i = 1:n
            norm_column = norm(model.transmatrix(:,i));
            model.transmatrix(:,i) = model.transmatrix(:,i) / norm_column;
        end
    end
        
    if isequal(options.method,'wmn')
        [m,n] = size(model.transmatrix);
        model.W = zeros(1,n);
        for i = 1:n
            model.W(i) = (norm(model.transmatrix(:,i)))^1;
            matrix(:,i) = model.transmatrix(:,i) / model.W(i);
        end
        [model.U, model.s, model.V] = csvd(matrix);
    elseif isequal(options.method,'mn')
        [model.U, model.s, model.V] = csvd(model.transmatrix);
    end
end

setappdata(hfig, 'Model', model);
close(h);

% --------------------------------------------------------------------
function Untitled_21_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_import_transmatrix_Callback(hObject, eventdata, handles)
% hObject    handle to menu_import_transmatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[name pathstr] = uigetfile('*.mat','Import Transfer Matrix');
if name==0
    return;
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

transmatrix = load(Fullfilename);

if ~isfield(transmatrix, 'transmatrix')
    errordlg('The imported is not transfer matrix!');
    return;
end

hfig = gcf;
model = getappdata(hfig, 'Model');
N = length(model.mag.locations.colinbrain); % number of valid MEG sensors
M = length(model.bemcortex.colinbemcortex.Faces); % number of dipoles associated with cortical triangles
[Nt, Mt] = size(transmatrix.transmatrix); 
if N~=Nt | M~=Mt 
    errordlg('The imported transfer matrix does not match the MEG data!');
    return;
end

options = getappdata(hfig, 'options');
if options.individual == 0 
    model.transmatrix = transmatrix.transmatrix;
    if isequal(options.method,'wmn')
        [m,n] = size(model.transmatrix);
        model.W = zeros(1,n);
        for i = 1:n
            model.W(i) = (norm(model.transmatrix(:,i)))^1;
            matrix(:,i) = model.transmatrix(:,i) / model.W(i);
        end
        [model.U, model.s, model.V] = csvd(matrix);
    elseif isequal(options.method,'mn')
        [model.U, model.s, model.V] = csvd(model.transmatrix);
    end
else
    warndlg('Do not import transfer matrix for individual BEM model!');
    return;
end

setappdata(hfig, 'Model',model);
helpdlg('The transfer matrix was imported successfully!');

% --------------------------------------------------------------------
function menu_export_transmatrix_Callback(hObject, eventdata, handles)
% hObject    handle to menu_export_transmatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[name, pathstr] = uiputfile('*.mat','Export Transfer Matrix');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);
hfig = gcf;
model = getappdata(hfig, 'Model');
transmatrix = model.transmatrix;
save(Fullfilename, 'transmatrix');


% % --------------------------------------------------------------------
% function menu_GFP_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_GFP (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% hfig = gcf;
% MEG = getappdata(hfig,'MEG');
% 
% options = getappdata(gcf,'options');
% startpoint = options.startepoch;
% endpoint = options.endepoch;
% 
% startpoint = min(max(startpoint,1),MEG.points);
% endpoint = min(max(endpoint,1),MEG.points);
% 
% if startpoint > endpoint
%     errordlg('The epoch specification is not right!');
%     return;
% end
% 
% ts = MEG.data(MEG.vidx,startpoint:endpoint);
% srate = MEG.srate;
% starttime = (startpoint - 1)/MEG.srate;
% pos1 = get(hfig,'CurrentPoint');
% pos2 = get(hfig,'position');
% pos = pos1 + pos2(1:2);
% 
% % compute global field power for the selected epoch.
% ECOM_GFP(ts, srate, starttime, pos);



% --------------------------------------------------------------------
function menu_waveforms_Callback(hObject, eventdata, handles)
% hObject    handle to menu_waveforms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capaxis(handles.tsaxes, 'MEG Waveforms', 0);


% --------------------------------------------------------------------
function Untitled_22_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_epoch_Callback(hObject, eventdata, handles)
% hObject    handle to menu_epoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
skinaxes = findobj(hfig,'tag','skinaxes');
cortexaxes = findobj(hfig,'tag','cortexaxes');
model = getappdata(hfig,'Model');

if options.startepoch > options.endepoch
    errordlg('The epoch specification is not right !');
    return;
end

localized = getappdata(hfig,'localized');
islocalized = localized(options.startepoch:options.endepoch);
if ~all(islocalized)
    helpdlg('Please perform source imaging for the epoch first!');
    return;
end
sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');

threshold = 0.5;
prompt = {'Power threshold (0~1), default is:'};
dlg_title = 'Input Power threshold';
num_lines = 1;
def = {num2str(threshold)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);
if isempty(answer)
    return;
end
threshold = str2num(answer{1});
if isempty(threshold)
    helpdlg('There is no threshold!');
    return;
end

% compute power integration
[m1,n1] = size(sensor.data{options.startepoch});
capV = zeros(m1,n1);
[m2,n2] = size(source.data{options.startepoch});
cortexV = zeros(m2,n2);
for i = options.startepoch:options.endepoch
    abs_capV = abs(sensor.data{i});
    min_abs_capV = min(abs_capV);
    max_abs_capV = max(abs_capV);
    hw = min_abs_capV + (max_abs_capV-min_abs_capV)*threshold;
    idx = find(abs_capV>=hw); % powers under the threshold are considered as noises
    capV(idx) = capV(idx) + (abs_capV(idx)).^2;

    abs_cortexV = abs(source.data{i});
    min_abs_cortexV = min(abs_cortexV);
    max_abs_cortexV = max(abs_cortexV);
    hw = min_abs_cortexV+(max_abs_cortexV-min_abs_cortexV)*threshold;
    idx = find(abs_cortexV>=hw); % powers under the threshold are considered as noises
    cortexV(idx) = cortexV(idx) + (abs_cortexV(idx)).^2;
end
num = options.endepoch-options.startepoch+1;
capV = capV/num;
cortexV = cortexV/num;

setappdata(hfig,'SensorPower',capV);
setappdata(hfig,'SourcePower',cortexV);

% mincapV = min(capV);
mincapV = 0;
maxcapV = max(capV);
capV = (capV-mincapV)/(maxcapV-mincapV);

% mincortexV = min(cortexV);
mincortexV = 0;
maxcortexV = max(cortexV);
cortexV = (cortexV-mincortexV)/(maxcortexV-mincortexV);

% update cap map
axes(skinaxes);
caxis([0 1]);
modelhandles = getappdata(hfig,'modelhandles');
set(modelhandles.map, 'LineStyle','none', 'FaceColor','interp', 'FaceVertexCData', capV, 'Visible', options.map);                                          
colorbar;

% update source map
if options.individual == 1
    FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts, 1);
else
    FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
end

nzK = find(cortexV >= options.threshold);
cmap = colormap;
len = length(cmap);
coef = (len-1);
FaceVertexCData(nzK,:) = cmap(round(coef*cortexV(nzK)+1),:);

axes(cortexaxes);
caxis([0 1]);
set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);

% --------------------------------------------------------------------
function menu_sample_Callback(hObject, eventdata, handles)
% hObject    handle to menu_sample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
skinaxes = findobj(hfig,'tag','skinaxes');
cortexaxes = findobj(hfig,'tag','cortexaxes');
model = getappdata(hfig,'Model');

prompt = {'Time of samples:'};
dlg_title = 'Input the time of samples';
num_lines = 1;
def = {num2str(options.currentpoint)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);
if isempty(answer)
    return;
end

points = str2num(answer{1});
if isempty(points)
    helpdlg('There is no samplel!');
    return;
end

sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');

threshold = 0.5;
prompt = {'Power threshold (0~1), default is:'};
dlg_title = 'Input Power threshold';
num_lines = 1;
def = {num2str(threshold)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);
if isempty(answer)
    return;
end
threshold = str2num(answer{1});
if isempty(threshold)
    helpdlg('There is no threshold!');
    return;
end

% compute power integration
[m1,n1] = size(sensor.data{points(1)});
capV = zeros(m1,n1);
[m2,n2] = size(source.data{points(1)});
cortexV = zeros(m2,n2);
num = length(points);
for i = 1:num
    abs_capV = abs(sensor.data{points(i)});
    min_abs_capV = min(abs_capV);
    max_abs_capV = max(abs_capV);
    hw = min_abs_capV+(max_abs_capV-min_abs_capV)*threshold;
    idx = find(abs_capV>=hw); % powers under threshold are considered as noises
    capV(idx) = capV(idx) + (abs_capV(idx)).^2;

    abs_cortexV = abs(source.data{points(i)});
    min_abs_cortexV = min(abs_cortexV);
    max_abs_cortexV = max(abs_cortexV);
    hw = min_abs_cortexV+(max_abs_cortexV-min_abs_cortexV)*threshold;
    idx = find(abs_cortexV>=hw); % powers under %50 are considered as noises
    cortexV(idx) = cortexV(idx) + (abs_cortexV(idx)).^2;
end
capV = capV/num;
cortexV = cortexV/num;

setappdata(hfig,'SensorPower',capV);
setappdata(hfig,'SourcePower',cortexV);

mincapV = min(capV);
maxcapV = max(capV);
capV = (capV-mincapV)/(maxcapV-mincapV);

mincortexV = min(cortexV);
maxcortexV = max(cortexV);
cortexV = (cortexV-mincortexV)/(maxcortexV-mincortexV);

% update cap map
axes(skinaxes);
caxis([0 1]);
modelhandles = getappdata(hfig,'modelhandles');
set(modelhandles.map, 'LineStyle','none', 'FaceColor','interp', 'FaceVertexCData', capV, 'Visible', options.map);                                          
colorbar;

% update source map
if options.individual == 1
    FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts, 1);
else
    FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
end

nzK = find(cortexV >= options.threshold);
cmap = colormap;
len = length(cmap);
coef = (len-1);
FaceVertexCData(nzK,:) = cmap(round(coef*cortexV(nzK)+1),:);

axes(cortexaxes);
caxis([0 1]);
set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);



% --------------------------------------------------------------------
function menu_export_power_Callback(hObject, eventdata, handles)
% hObject    handle to menu_export_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
sensor = getappdata(hfig,'SensorPower');
source = getappdata(hfig,'SourcePower');

if isempty(sensor) | isempty(source)
    helpdlg('There is no integrated power!');
    return;
end

MEG = getappdata(hfig,'MEG');

[name, pathstr] = uiputfile('*.mat','Export integrated power.', [MEG.name '.mat']);
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);
type = 'MEG';
save(Fullfilename, 'type', 'sensor', 'source');

% --------------------------------------------------------------------
function menu_import_power_Callback(hObject, eventdata, handles)
% hObject    handle to menu_import_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[names pathstr] = uigetfile('*.mat','Import the integrated power files','MultiSelect','on');
if ~iscell(names) & names == 0
    return;
end

addpath(pathstr);

if ~iscell(names)
    Fullfilename = fullfile(pathstr,names);
    power = load(Fullfilename);

    reqfields = {'type','sensor','source'};
    fields = isfield(power,reqfields);
    if ~all(fields)
        helpdlg('It is not a MEG integrated power file!');
        return;
    end

    if ~isequal(upper(power.type),'MEG')
        helpdlg('It is not a MEG integrated power file!');
        return;
    end
    
    sensor = power.sensor;
    source = power.source;
else
    num = length(names);
    for k = 1:num
        Fullfilename = fullfile(pathstr,names{k});
        power = load(Fullfilename);

        reqfields = {'type','sensor','source'};
        fields = isfield(power,reqfields);
        if ~all(fields)
            helpdlg([names{k} ' is not a MEG integrated power file!']);
            return;
        end

        if ~isequal(upper(power.type),'MEG')
            helpdlg([names{k} ' is not a MEG integrated power file!']);
            return;
        end

        if k == 1
            sensor = power.sensor;
            source = power.source;
        else
            sensor = sensor + power.sensor;
            source = source + power.source;
        end
    end
end

% display the power map
hfig = gcf;
options = getappdata(hfig,'options');
skinaxes = findobj(hfig,'tag','skinaxes');
cortexaxes = findobj(hfig,'tag','cortexaxes');
model = getappdata(hfig,'Model');

mincapV = min(sensor);
maxcapV = max(sensor);
capV = (sensor-mincapV)/(maxcapV-mincapV);

mincortexV = min(source);
maxcortexV = max(source);
cortexV = (source-mincortexV)/(maxcortexV-mincortexV);

% update cap map
axes(skinaxes);
caxis([0 1]);
modelhandles = getappdata(hfig,'modelhandles');
set(modelhandles.map, 'LineStyle','none', 'FaceColor','interp', 'FaceVertexCData', capV, 'Visible', options.map);                                          
colorbar;

% update source map
if options.individual == 1
    FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts, 1);
else
    FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
end

nzK = find(cortexV >= options.threshold);
cmap = colormap;
len = length(cmap);
coef = (len-1);
FaceVertexCData(nzK,:) = cmap(round(coef*cortexV(nzK)+1),:);

axes(cortexaxes);
caxis([0 1]);
set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);

setappdata(hfig,'SensorPower',power.sensor);
setappdata(hfig,'SourcePower',power.source);


% % --------------------------------------------------------------------
% function menu_simulation_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_simulation (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% hfig = gcf;
% model = getappdata(hfig, 'Model');
% MEG = getappdata(hfig, 'MEG');
% 
% if isempty(model.transmatrix)
%     helpdlg('There is no transfer matrix, please compute transfer matrix first!');
%     return;
% end
% 
% GetTriangleIdx;
% 
% [name pathstr] = uigetfile('*.mat','Import simulated cortical sources');
% if name == 0
%     return;
% end
% 
% load('TriIdx.mat');
% idx = tri_idx;
% 
% addpath(pathstr);
% Fullfilename = fullfile(pathstr,name);
% SC = load(Fullfilename);
% if ~isfield(SC,'ts')
%     helpdlg('It is not a simulated cortical source file!');
%     return;
% end
% 
% N = length(model.mag.locations.colinbrain); % number of valid MEG sensors
% M = length(model.bemcortex.colinbemcortex.Faces); % number of dipoles associated with cortical triangles
% pnts = length(SC.ts);
% 
% source = zeros(M,1);
% sensors = zeros(N,pnts);
% 
% SNR = 0;
% pnts = length(SC.ts);
% for i = 1:pnts
% 	source(idx,1) = SC.ts(i,:);
%     b = model.transmatrix*source;
%     signal=std(b);
%     noise = SNR*signal*randn(size(b));
%     sensors(:,i) = b + noise;
% end
% sensors = sensors';
% 
% [name, pathstr] = uiputfile('*.mat','Export simulated field.');
% if name==0
%     return;
% end
% addpath(pathstr);
% Fullfilename=fullfile(pathstr,name);
% save(Fullfilename,'sensors');


% --------------------------------------------------------------------
function menu_clear_Callback(hObject, eventdata, handles)
% hObject    handle to menu_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
source = getappdata(hfig,'source');
options = getappdata(hfig,'options');

if ~isempty(source.data)    
    clearevent = questdlg('Clear reconstructed sources ?','','Yes','Cancel','Cancel');
    if ~strcmp(clearevent, 'Yes')
        return;
    end
end

source.data = {};
setappdata(hfig, 'source',source);

options.sourceminmax = [realmax, realmin];

setappdata(hfig,'options',options);
localized = getappdata(hfig,'localized');
localized(:) = 0;
setappdata(hfig,'localized',localized);

helpdlg('Reconstructed sources are cleared successfully !');



% --------------------------------------------------------------------
function menu_butterfly_Callback(hObject, eventdata, handles)
% hObject    handle to menu_butterfly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
MEG = getappdata(hfig,'MEG');

options = getappdata(gcf,'options');
startpoint = options.startepoch;
endpoint = options.endepoch;

startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

ts = MEG.data(MEG.vidx,startpoint:endpoint);
srate = MEG.srate;
starttime = (startpoint - 1)/MEG.srate;
pos1 = get(hfig,'CurrentPoint');
pos2 = get(hfig,'position');
pos = pos1 + pos2(1:2);

% compute butterfly and global field power for the selected epoch.
ECOM_Butterfly(ts, srate, starttime, pos);



% --------------------------------------------------------------------
function menu_maxpower_Callback(hObject, eventdata, handles)
% hObject    handle to menu_maxpower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');

if options.startepoch > options.endepoch
    errordlg('The epoch specification is not right !');
    return;
end

localized = getappdata(hfig,'localized');
islocalized = localized(options.startepoch:options.endepoch);
if ~all(islocalized)
    helpdlg('Please perform source imaging for the epoch first!');
    return;
end

source = getappdata(hfig,'source');

len = length(source.data{options.startepoch});
powerV = zeros(len,1);
num = 0;
for i = options.startepoch:options.endepoch
    num = num + 1;
    abs_cortexV = abs(source.data{i});
    powerV(num,1) = max(abs_cortexV);
end
[maxPower, idx] = max(powerV);
idx = options.startepoch+idx-1;

options.currentpoint = idx;
setappdata(hfig,'options',options);
Update;


% --------------------------------------------------------------------
function menu_max_tr_Callback(hObject, eventdata, handles)
% hObject    handle to menu_max_tr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
skinaxes = findobj(hfig,'tag','skinaxes');
cortexaxes = findobj(hfig,'tag','cortexaxes');
model = getappdata(hfig,'Model');

if options.startepoch > options.endepoch
    errordlg('The epoch specification is not right !');
    return;
end

localized = getappdata(hfig,'localized');
islocalized = localized(options.startepoch:options.endepoch);
if ~all(islocalized)
    helpdlg('Please perform source imaging for the epoch first!');
    return;
end
sensor = getappdata(hfig,'sensor');
source = getappdata(hfig,'source');

threshold = 1;
prompt = {'Power threshold (0~1), default is:'};
dlg_title = 'Input Power threshold';
num_lines = 1;
def = {num2str(threshold)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);
if isempty(answer)
    return;
end
threshold = str2num(answer{1});
if isempty(threshold)
    helpdlg('There is no threshold!');
    return;
end

% compute power integration
[m1,n1] = size(sensor.data{options.startepoch});
capV = zeros(m1,n1);
[m2,n2] = size(source.data{options.startepoch});
cortexV = zeros(m2,n2);
for i = options.startepoch:options.endepoch
    abs_capV = abs(sensor.data{i});
    min_abs_capV = min(abs_capV);
    max_abs_capV = max(abs_capV);
    hw = min_abs_capV+(max_abs_capV-min_abs_capV)*threshold;
    idx = find(abs_capV>=hw); % powers under threshold are considered as noises
    capV(idx) = 1;

    abs_cortexV = abs(source.data{i});
    min_abs_cortexV = min(abs_cortexV);
    max_abs_cortexV = max(abs_cortexV);
    hw = min_abs_cortexV+(max_abs_cortexV-min_abs_cortexV)*threshold;
    idx = find(abs_cortexV>=hw); % powers under threshold are considered as noises
    cortexV(idx) = 1;
end

mincapV = 0;
maxcapV = max(capV);
capV = (capV-mincapV)/(maxcapV-mincapV);

mincortexV = 0;
maxcortexV = max(cortexV);
cortexV = (cortexV-mincortexV)/(maxcortexV-mincortexV);

% update cap map
axes(skinaxes);
caxis([0 1]);
modelhandles = getappdata(hfig,'modelhandles');
set(modelhandles.map, 'LineStyle','none', 'FaceColor','interp', 'FaceVertexCData', capV, 'Visible', options.map);                                          
colorbar;

% update source map
if options.individual == 1
    FaceVertexCData = repmat([0.6,0.6,0.6], options.cortexnumverts, 1);
else
    FaceVertexCData = model.cortex.colincortex.FaceVertexCData;
end

nzK = find(cortexV >= 0.5);
FaceVertexCData(nzK,:) = repmat([1,0,0],length(nzK),1);

axes(cortexaxes);
set(modelhandles.cortex,'FaceVertexCData',FaceVertexCData);




