function varargout = displaymap(varargin)
% displaymap - display the ERD/ERS map
% 
% Usage: displaymap(ERDS, name);
%
% Input: ERDS - is a structure storing the ERD/ERS computed from valid epochs,
%                        see 'epochanalysis -> pb_erders_Callback' function
%           name - is the name for the figure of ERD/ERS mapping
%
% ERD/ERS from the Event Related EEG (or ECoG) recordings 
% can be mapped over the scalp model (or cortex model). 
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
% Yakang Dai, 10-Feb-2011 13:10:30
% Support MEG
%
% Yakang Dai, 08-Jul-2010 15:11:21
% Release Version 1.0
%
% ========================================== 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @displaymap_OpeningFcn, ...
                   'gui_OutputFcn',  @displaymap_OutputFcn, ...
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


% --- Executes just before displaymap is made visible.
function displaymap_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to displaymap (see VARARGIN)

% Choose default command line output for displaymap
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes displaymap wait for user response (see UIRESUME)
% uiwait(handles.figure1);

if isempty(varargin) | length(varargin)>2
    warndlg('Input arguments mismatch!');
    return;
end

ERDS = varargin{1};
if length(varargin) == 2
    name = varargin{2};
else
    name = 'Topographic Mapping';
end

if isempty(ERDS)
    warndlg('Input data is empty!'); 
    return;
end

if ERDS.points ~= 1
    warndlg('Input is not ERD/ERS data!');
    return;
end

setappdata(hObject,'ERDS',ERDS);
options.caxis = 'maxabs';
options.minmax = [0, 1];
options.labels = 0;
options.sensors = 0;
setappdata(hObject,'options',options);

set(hObject,'name', name);
axes(handles.mainaxes);
set(handles.mainaxes, 'DataAspectRatio',[1 1 1]);
set(handles.mainaxes, 'color',get(hObject,'color'));
box off;
axis off;
axis vis3d;

if isequal(upper(ERDS.type),'EEG')
    scalpmapping;
elseif isequal(upper(ERDS.type),'ECOG')
    cortexmapping;
elseif isequal(upper(ERDS.type),'MEG')
    capmapping;
end


% --- Outputs from this function are returned to the command line.
function varargout = displaymap_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --------------------------------------------------------------------
function scalpmapping()
hfig = gcf;
ERDS = getappdata(hfig,'ERDS');

% compute the map value
model.skin = load('italyskin.mat');
model.italyskinxy = load('italyskin-in-xy.mat');
model.italyskinxyz = load('italyskin-in-xyz.mat');
model.k = cell2mat({ERDS.locations(ERDS.vidx).italyskinidx});
model.sensors.labels = ERDS.labels(ERDS.vidx);
model.sensors.locations = model.skin.italyskin.Vertices(model.k,:);
model.X = model.italyskinxy.xy(model.k,1); % standard xy coordinates relative to sensors on the skin
model.Y = model.italyskinxy.xy(model.k,2);   
zmin = min(model.italyskinxyz.xyz(model.k,3));
Z = model.italyskinxyz.xyz(:,3);
model.interpk = find(Z > zmin); % focus interpolated vertices
model.XI = model.italyskinxy.xy(model.interpk,1);
model.YI = model.italyskinxy.xy(model.interpk,2);
model.VI = griddata(model.X,model.Y,ERDS.data(ERDS.vidx),model.XI,model.YI,'v4');
minV = min(ERDS.data(ERDS.vidx));
maxV = max(ERDS.data(ERDS.vidx));
k = find(model.VI<minV);
if ~isempty(k)
    model.VI(k) = minV;
end
k = find(model.VI>maxV);
if ~isempty(k)
    model.VI(k) = maxV;
end
setappdata(hfig,'model',model);
updatescalpmap;


% --------------------------------------------------------------------
function updatescalpmap()
hfig = gcf;
model = getappdata(hfig,'model');
options = getappdata(hfig, 'options');
mainaxes = findobj(hfig,'tag','mainaxes');

% get the scope for colorbar
if isequal(options.caxis, 'maxabs')
    absVI = max(abs(model.VI));
    minV = -absVI;
    maxV = absVI;
elseif isequal(options.caxis, 'minmax')
    minV = min(model.VI);
    maxV = max(model.VI);
end

% generate the map color
cmap = colormap;
len = length(cmap);
FaceVertexCData = model.skin.italyskin.FaceVertexCData;
coef = (len-1)/(maxV - minV);
FaceVertexCData(model.interpk,:) = cmap(round(coef*(model.VI-minV)+1),:);
options.minmax = [minV  maxV];
setappdata(hfig, 'options', options);

% to display the map
axes(mainaxes);
cla;
hold on;
caxis([minV  maxV]);
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.skin.italyskin.Vertices,...
     'LineStyle','none',...
     'Faces',model.skin.italyskin.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
      'FaceVertexCData',FaceVertexCData,...
      'tag','skin');
lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
colorbar;

% display sensors
if options.sensors
    sensorcolor = [0.0  1.0  1.0];
    plot3(model.sensors.locations(:,1), ...
          model.sensors.locations(:,2), ... 
          model.sensors.locations(:,3), ... 
          'k.','LineWidth',4,'color', sensorcolor);
end

% display labels
if options.labels
    vnum = length(model.sensors.labels);
    textcolor = [0.0 0.0 0.0];
    for i = 1:vnum
        location = 1.05*model.sensors.locations(i,:);
        text( location(1), location(2), location(3), ... 
              upper(model.sensors.labels{i}),'FontSize',8 ,...
              'HorizontalAlignment','center', 'Color',textcolor);
    end
end


% --------------------------------------------------------------------
function cortexmapping()
hfig = gcf;
ERDS = getappdata(hfig,'ERDS');

% compute the map value
load('colincortex.mat');
model.cortex = colincortex;
load('colinbrain.mat');
model.brain = colinbrain;
electrodelocs.row = ERDS.size(1);
electrodelocs.column = ERDS.size(2);
electrodelocs.X = zeros(electrodelocs.row, electrodelocs.column);
electrodelocs.Y = electrodelocs.X;
electrodelocs.Z = electrodelocs.X;
k = 0;
for j = 1:electrodelocs.column
    for i = 1:electrodelocs.row
        k = k+1;
        electrodelocs.X(i,j) = ERDS.locations(k).X;
        electrodelocs.Y(i,j) = ERDS.locations(k).Y;
        electrodelocs.Z(i,j) = ERDS.locations(k).Z;
    end
end
[surflocs, electrodelocs] = getsurflocs(electrodelocs);
vertices = model.brain.Vertices;
vertices = [vertices; model.brain.Centers];
[surflocs.X,surflocs.Y,surflocs.Z] = avgNeighbors(vertices,surflocs.X,surflocs.Y,surflocs.Z,surflocs.row,surflocs.column);
y = electrodelocs.rowindex;
x = electrodelocs.columnindex;
[X,Y] = meshgrid(x,y);
values = zeros(ERDS.nbchan,1);
values(ERDS.vidx) = ERDS.data(ERDS.vidx);
values(ERDS.bad) = min(values(ERDS.vidx));
V = reshape(values,electrodelocs.row,electrodelocs.column);
yi = [1:surflocs.row];
xi = [1:surflocs.column];
[XI,YI] = meshgrid(xi,yi);
VI = interp2(X,Y,V,XI,YI);
model.VI = VI;        

minV = min(ERDS.data(ERDS.vidx));
maxV = max(ERDS.data(ERDS.vidx));
k = find(model.VI<minV);
if ~isempty(k)
    model.VI(k) = minV;
end
k = find(model.VI>maxV);
if ~isempty(k)
    model.VI(k) = maxV;
end

model.electrodelocs = electrodelocs;
model.surflocs = surflocs;        
setappdata(hfig,'model',model);

updatecortexmap;


% --------------------------------------------------------------------
function updatecortexmap()
hfig = gcf;
model = getappdata(hfig,'model');
options = getappdata(hfig, 'options');
ERDS = getappdata(hfig,'ERDS');
mainaxes = findobj(hfig,'tag','mainaxes');

% get the scope for colorbar
if isequal(options.caxis, 'maxabs')
    absVI = max(max(abs(model.VI)));
    minV = -absVI;
    maxV = absVI;
elseif isequal(options.caxis, 'minmax')
    minV = min(min(model.VI));
    maxV = max(max(model.VI));
end
options.minmax = [minV  maxV];
setappdata(hfig, 'options', options);

% to display the map
axes(mainaxes);
cla;
hold on;
caxis([minV maxV]);
patch('SpecularStrength',0,'DiffuseStrength',0.8,...
'FaceLighting','phong',...
'Vertices',model.cortex.Vertices,...
'LineStyle','-',...
'Faces',model.cortex.Faces,...
'FaceColor','interp',...
'EdgeColor','none',...
'FaceVertexCData',model.cortex.FaceVertexCData);
lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
surface(model.surflocs.X,model.surflocs.Y,model.surflocs.Z,model.VI,...
    'SpecularStrength',0.2,'DiffuseStrength',0.8,...
    'FaceLighting','phong','FaceColor','interp',...
    'EdgeColor','none');
colorbar;

k = length(ERDS.vidx);

% display sensors
if options.sensors
    siz = 2;
    [hx3d, hy3d, hz3d] = sphere(50);
    hx3d = hx3d * siz;
    hy3d = hy3d * siz;
    hz3d = hz3d * siz;
    for i = 1:k
        j = ERDS.vidx(i);
        location = [ERDS.locations(j).X,ERDS.locations(j).Y,ERDS.locations(j).Z];
        hx3dp = hx3d + location(1);
        hy3dp = hy3d + location(2);
        hz3dp = hz3d + location(3);
        surf(hx3dp, hy3dp, hz3dp,'EdgeColor', 'none','FaceColor',[0.5, 0.0, 0.0]);
    end
end

% display labels
if options.labels
    for i = 1:k
        j = ERDS.vidx(i);
        location = [ERDS.locations(j).X,ERDS.locations(j).Y,ERDS.locations(j).Z];
        label = char(ERDS.labels(j));
        textlocation = location*1.1;
        text(textlocation(1), textlocation(2), textlocation(3),label,'FontSize',10,'FontWeight','bold','HorizontalAlignment','center','color','k');
    end
end

% --------------------------------------------------------------------
function capmapping()
hfig = gcf;
ERDS = getappdata(hfig,'ERDS');

% compute the map value
model.skin = load('italyskin.mat');
CoR = load('CoR.mat');
model.CoR = CoR.italyskin;
num = length(model.skin.italyskin.Vertices);
model.skin.italyskin.Vertices = (model.skin.italyskin.Vertices+repmat(model.CoR.translation,num,1))*model.CoR.rotation;

model.k = ERDS.vidx;
model.sensors.labels = ERDS.labels(model.k);
model.sensors.locations = ERDS.locations.italybrain(model.k,:);
X = ERDS.locations.surf.x(model.k,1); 
Y = ERDS.locations.surf.y(model.k,1);   
XI = ERDS.locations.surf.x(:,1); 
YI = ERDS.locations.surf.y(:,1); 
V = ERDS.data(ERDS.vidx);
model.VI = griddata(X,Y,V,XI,YI,'v4');
minV = min(V);
maxV = max(V);
k = find(model.VI<minV);
if ~isempty(k)
    model.VI(k) = minV;
end
k = find(model.VI>maxV);
if ~isempty(k)
    model.VI(k) = maxV;
end
setappdata(hfig,'model',model);
updatecapmap;


% --------------------------------------------------------------------
function updatecapmap()
hfig = gcf;
model = getappdata(hfig,'model');
options = getappdata(hfig, 'options');
ERDS = getappdata(hfig,'ERDS');
mainaxes = findobj(hfig,'tag','mainaxes');

% get the scope for colorbar
if isequal(options.caxis, 'maxabs')
    absVI = max(abs(model.VI));
    minV = -absVI;
    maxV = absVI;
elseif isequal(options.caxis, 'minmax')
    minV = min(model.VI);
    maxV = max(model.VI);
end
options.minmax = [minV  maxV];
setappdata(hfig, 'options', options);

% draw skin
axes(mainaxes);
cla;
hold on;
caxis([minV maxV]);
patch('SpecularStrength',0,'DiffuseStrength',0.8,...
            'FaceLighting','phong',...
            'Vertices',model.skin.italyskin.Vertices,...
            'LineStyle','-',...
            'Faces',model.skin.italyskin.Faces,...
            'FaceColor','interp',...
            'EdgeColor','none',...
            'FaceVertexCData',model.skin.italyskin.FaceVertexCData);

% draw cap map
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
             'FaceLighting','phong',...
             'Vertices',ERDS.locations.italybrain,...
             'LineStyle','none',...
             'Faces',ERDS.locations.surf.tri,...
             'FaceColor','interp',...
             'FaceAlpha',1,...
             'EdgeColor','none',...
             'FaceVertexCData',model.VI);
                                                 
colorbar;

k = length(ERDS.vidx);

% display sensors
if options.sensors
    sensorcolor = [0.0  1.0  1.0];
    plot3(model.sensors.locations(:,1), ...
              model.sensors.locations(:,2), ... 
              model.sensors.locations(:,3), ... 
              'k.','LineWidth',4,'color', sensorcolor);
end

% display labels
if options.labels
    textcolor = [0.0 0.0 0.0];
    locations = 1.05*model.sensors.locations;
    text( locations(:,1), locations(:,2), locations(:,3), ... 
              upper(model.sensors.labels),'FontSize',8 ,...
              'HorizontalAlignment','center', 'Color',textcolor);
end

lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);

% --------------------------------------------------------------------
function updatemap()
hfig = gcf;
ERDS = getappdata(hfig,'ERDS');
if isequal(upper(ERDS.type),'EEG')
    updatescalpmap;
elseif isequal(upper(ERDS.type),'ECOG')
    updatecortexmap;
elseif isequal(upper(ERDS.type),'MEG')
    updatecapmap;
end


% --------------------------------------------------------------------
function popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_maxabs_Callback(hObject, eventdata, handles)
% hObject    handle to menu_maxabs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
options.caxis = 'maxabs';
setappdata(hfig, 'options', options);
set(hObject,'checked','on');
set(handles.menu_minmax,'checked','off');
updatemap;


% --------------------------------------------------------------------
function Untitled_2_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_minmax_Callback(hObject, eventdata, handles)
% hObject    handle to menu_minmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
options.caxis = 'minmax';
setappdata(hfig, 'options', options);
set(hObject,'checked','on');
set(handles.menu_maxabs,'checked','off');
updatemap;


% --------------------------------------------------------------------
function menu_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = get(hObject,'checked');
if isequal(ischecked,'off')
    ischecked = 'on';
    options.labels = 1;
else
    ischecked = 'off';
    options.labels = 0;
end
set(hObject,'checked',ischecked);
setappdata(hfig, 'options', options);
updatemap;
    
    
% --------------------------------------------------------------------
function menu_sensors_Callback(hObject, eventdata, handles)
% hObject    handle to menu_sensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig, 'options');
ischecked = get(hObject,'checked');
if isequal(ischecked,'off')
    ischecked = 'on';
    options.sensors = 1;
else
    ischecked = 'off';
    options.sensors = 0;
end
set(hObject,'checked',ischecked);
setappdata(hfig, 'options', options);
updatemap;

