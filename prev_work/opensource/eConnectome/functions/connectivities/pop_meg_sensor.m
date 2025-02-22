function varargout = pop_meg_sensor(varargin)
% pop_meg_sensor - the GUI for visualizing MEG functional connectivity over MEG cap.
%
% Useage: 
%           1. type
%               >> pop_meg_sensor
%               or call pop_meg_sensor to start the popup GUI
%
%            2. type 
%               >> pop_meg_sensor(MEG)
%               or call pop_meg_sensor(MEG) to start the popup GUI with MEG structure. 
%               The MEG structure should be pre-exported by the megfc GUI.
%               or made by 
%               >> MEG = pop_meg_txtreader  
%               or
%               >> MEG = pop_meg_matreader
%               Please see the eConnectome Manual  
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable import MEG file formats (TXT and MAT)
%
%            3. call pop_meg_sensor from the megfc GUI ('Menu bar -> Connectivity -> Sensor')
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
% Yakang Dai, 03-Feb-2011 22:57:40
% Release Version 2.0 beta
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_meg_sensor_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_meg_sensor_OutputFcn, ...
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


% --- Executes just before pop_meg_sensor is made visible.
function pop_meg_sensor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_meg_sensor (see VARARGIN)

% Choose default command line output for pop_meg_sensor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

MEG = ismeg(varargin{:});

setappdata(hObject,'MEG',MEG);

set(hObject,'Toolbar','figure');
hToolbar = findall(hObject,'tag','FigureToolBar');
hButtons = findall(hToolbar);
set(hButtons,'Visible','off');
% sfhandle = findobj(hButtons,'tag','Standard.SaveFigure');
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

set(handles.textvalue,'string','');

%% set default options for displaying DTF graphics.
options.isskin = get(handles.checkboxskin, 'value');
options.iscap = get(handles.checkboxcap, 'value');
options.issensor = get(handles.checkboxsensors, 'value');
options.islabel = get(handles.checkboxlabels, 'value');

channels = {'all', 'single', 'none'};
channelvalues = [get(handles.radiobuttonall, 'value'), get(handles.radiobuttonsingle, 'value'), get(handles.radiobuttonnone, 'value')];
options.channels = strvcat( channels(channelvalues == 1) );
options.whichchannel = nan;

dispmodes = {'out2in', 'outflow', 'inflow'};
dispmodevalues = [get(handles.radiobuttonout2in, 'value'), get(handles.radiobuttonoutflow, 'value'), get(handles.radiobuttoninflow, 'value')];
options.dispmodes = strvcat( dispmodes(dispmodevalues == 1) );

options.displimits = [0.001, 1.0];
set( handles.textmin, 'string', ['Min: '  num2str(options.displimits(1),'%6f')] );
set( handles.textmax, 'string', ['Max: '  num2str(options.displimits(2),'%6f')] );
set( handles.editmin, 'string', num2str(options.displimits(1),'%6f') );
set( handles.editmax, 'string', num2str(options.displimits(2),'%6f') );

options.dtf = false;
options.isadtf = 0;
set(handles.options,'userdata', options);
setappdata(hObject,'movie',0);
enable_time_options(false);
enable_band(false);

% get skin surface
skinFullFilename = 'italyskin.mat';
model.skin = load(skinFullFilename);
CoR = load('CoR.mat');
model.CoR = CoR.italyskin;
num = length(model.skin.italyskin.Vertices);
model.skin.italyskin.Vertices = (model.skin.italyskin.Vertices+repmat(model.CoR.translation,num,1))*model.CoR.rotation;
    
% get sensor labels and locations
if isempty(MEG)
    model.mags.labels = {};
    model.mags.locations = [];
else   
    model.k = MEG.vidx;
    model.mags.labels = MEG.labels(model.k);
    model.mags.locations = MEG.locations.italybrain(model.k,:);
    model.mags.cap.locations = MEG.locations.italybrain;
    model.mags.cap.tri = MEG.locations.surf.tri;
end

%% draw connectivity graphics
axes(handles.sceneaxes);
axcolor = get(hObject, 'color');
set(handles.sceneaxes, 'color', axcolor);
set(handles.sceneaxes, 'DataAspectRatio',[1 1 1]);
model.colorbar = 0;
set(handles.sceneaxes, 'userdata', model);
cla;
box off;
axis off;
hold on;

if options.isskin
    patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
             'FaceLighting','phong',...
             'Vertices',model.skin.italyskin.Vertices,...
             'LineStyle','none',...
             'Faces',model.skin.italyskin.Faces,...
             'FaceColor','interp',...
             'FaceAlpha',1,...
             'EdgeColor','none',...
             'FaceVertexCData',model.skin.italyskin.FaceVertexCData);
end

if ~isempty(MEG)
    if options.iscap % draw MEG cap
        capcolor = [0.9, 0.85, 0.7];
        patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                     'FaceLighting','phong',...
                     'Vertices',model.mags.cap.locations,...
                     'LineStyle','-',...
                     'Faces',model.mags.cap.tri,...
                     'FaceColor','flat',...
                     'FaceAlpha',1,...
                     'EdgeColor','k',...
                     'FaceVertexCData',capcolor);
    end
    
    if options.issensor % draw MEG sensors
        sensorcolor = [0.0  0.0  1.0];
        plot3(model.mags.locations(:,1), ...
                  model.mags.locations(:,2), ... 
                  model.mags.locations(:,3), ... 
                  'k.','LineWidth',4,'color', sensorcolor);
    end

    vnum = length(model.mags.labels);
    
    if options.islabel % draw MEG sensor labels
        locations = 1.05*model.mags.locations;
        text( locations(:,1), locations(:,2), locations(:,3), ... 
                char(upper(model.mags.labels)),'FontSize',8 ,...
                'HorizontalAlignment','center');
    end
else
    vnum = 10;
end

lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
%%

%% draw connectivity image
axes(handles.imageaxes);

ticks = 1:vnum;
xlabels = num2str(ticks');
yLabels = flipud(num2str(ticks'));

set(handles.imageaxes, 'DataAspectRatio',[1 1 1]);
set(handles.imageaxes, 'color', axcolor);
set(handles.imageaxes,...
      'Xlim',[0 vnum+1],...
      'xtick',ticks,...% where to display the labels.
      'Ylim',[0 vnum+1],...
      'YTick',ticks,...
      'XTickLabel', xlabels,...% the labels to be displayed
      'YTickLabel', yLabels,...
      'TickLength',[.005 .005]);
cla;  
box off;
axis on;
hold on;

matrix = zeros(vnum,vnum);
plotimage = flipud(matrix);
imagesc(plotimage,'tag','dtfimage');
xlabel('j','fontsize',10,'fontweight','b');
ylabel('i','fontsize',10,'fontweight','b');
set(handles.imageaxes, 'userdata', matrix);

for i=0:vnum
    lx = [0.5 vnum+0.5];
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
function varargout = pop_meg_sensor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function sliderfrequency_Callback(hObject, eventdata, handles)
% hObject    handle to sliderfrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

currentf = round(get(hObject,'value'));
set(handles.frequencyedit,'string', num2str(currentf));
set(hObject,'value',currentf);
currentt = round(get(handles.slider_time,'value'));

options = get(handles.options,'userdata');
if ~options.dtf
    return;
end

frequency = get(handles.textfrequency,'userdata');
dtfmatrixs = get(gcf, 'userdata');
currentfidx = currentf-frequency(1)+1;

if options.isadtf
    currentdtfmatrix = squeeze(dtfmatrixs(currentt,:,:,currentfidx));
else
    currentdtfmatrix = dtfmatrixs(:,:,currentfidx);
end

set(handles.imageaxes, 'userdata', currentdtfmatrix);

if isequal(options.dispmodes,'out2in')
    valmin = min(min(currentdtfmatrix));
    valmax = max(max(currentdtfmatrix));
    [row col] = find(currentdtfmatrix==valmax, 1);
    options.whichchannel = [row col];
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(currentdtfmatrix,1)/(size(currentdtfmatrix,2)-1);
    valmax = max(outflows);
    valmin = min(outflows);
    options.whichchannel = find(outflows==valmax, 1);
else
    inflows = sum(currentdtfmatrix,2)/(size(currentdtfmatrix,2)-1);
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

displayDTFG(options);


% display directed transfer function matrix.
axes(handles.imageaxes);
cla;  
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



function editmax_Callback(hObject, eventdata, handles)
% hObject    handle to editmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editmax as text
%        str2double(get(hObject,'String')) returns contents of editmax as a double


% --- Executes during object creation, after setting all properties.
function editmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editmin_Callback(hObject, eventdata, handles)
% hObject    handle to editmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editmin as text
%        str2double(get(hObject,'String')) returns contents of editmin as a double


% --- Executes during object creation, after setting all properties.
function editmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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

% get dtf matrix
currentdtfmatrix = get(handles.imageaxes, 'userdata');

% make sure the input limit is in the default limit.
if isequal(options.dispmodes,'out2in')
    defaultvalmin = min(min(currentdtfmatrix));
    defaultvalmax = max(max(currentdtfmatrix));
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(currentdtfmatrix,1)/(size(currentdtfmatrix,2)-1);
    defaultvalmax = max(outflows);
    defaultvalmin = min(outflows);
else
    inflows = sum(currentdtfmatrix,2)/(size(currentdtfmatrix,2)-1);
    inflows(~inflows) = nan;
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
options.displimits = [valmin valmax];
set(handles.options, 'userdata', options);

set( handles.editmin, 'string', num2str(options.displimits(1),'%6f') );
set( handles.editmax, 'string', num2str(options.displimits(2),'%6f') );

displayDTFG(options);

% --- Executes on button press in pushbuttondefault.
function pushbuttondefault_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttondefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get dtf matrix
currentdtfmatrix = get(handles.imageaxes, 'userdata');

% change options accordingly.
options = get(handles.options,'userdata');

if ~options.dtf
    return;
end

% get default min and max values.
valmin = 0.0;
valmax = 1.0;

if isequal(options.dispmodes,'out2in')
    valmin = min(min(currentdtfmatrix));
    valmax = max(max(currentdtfmatrix));
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(currentdtfmatrix,1)/(size(currentdtfmatrix,2)-1);
    valmax = max(outflows);
    valmin = min(outflows);
else
    inflows = sum(currentdtfmatrix,2)/(size(currentdtfmatrix,2)-1);
    inflows(~inflows) = nan;
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

displayDTFG(options);

% --- Executes on button press in checkboxskin.
function checkboxskin_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxskin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxskin

% change options accordingly.
options = get(handles.options,'userdata');
options.isskin = get(hObject,'value');
set(handles.options, 'userdata', options);
displayDTFG(options);

% --- Executes on button press in checkboxsensors.
function checkboxsensors_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxsensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxsensors

% change options accordingly.
options = get(handles.options,'userdata');
options.issensor = get(hObject,'value');
set(handles.options, 'userdata', options);
displayDTFG(options);

% --- Executes on button press in checkboxlabels.
function checkboxlabels_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxlabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxlabels

% change options accordingly.
options = get(handles.options,'userdata');
options.islabel = get(hObject,'value');
set(handles.options, 'userdata', options);

displayDTFG(options);

% --------------------------------------------------------------------
function menuDTF_Callback(hObject, eventdata, handles)
% hObject    handle to menuDTF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menucomputation_Callback(hObject, eventdata, handles)
% hObject    handle to menucomputation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

options = get(handles.options,'userdata');
if options.dtf    
    importevent = questdlg('Exist DTF, compute new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

% get dtf matrices at different frequencies.
MEG = getappdata(gcf,'MEG');
if isempty(MEG)
    helpdlg('There is no MEG data!');
    return;
end

data = MEG.data(MEG.vidx,:);

output = pop_dtf_computation(data, MEG.srate);

if isempty(output.dtfmatrixs)
    return;
end

% get current frequency and matrix
currentf = output.frequency(1);

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
    
    currentdtfmatrix = squeeze(output.dtfmatrixs(sp,:,:,1));
else
    currentdtfmatrix = output.dtfmatrixs(:,:,1);
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
set(gcf, 'userdata', output.dtfmatrixs);
set(handles.imageaxes, 'userdata', currentdtfmatrix);

% update options
options.dtf = 1;
options.isadtf = output.isadtf;
options.srate = output.srate;
valmin = min(min(currentdtfmatrix));
valmax = max(max(currentdtfmatrix));
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end
options.minmax = [valmin, valmax];
options.displimits = [(valmin+valmax)/2, valmax];
options.dispmodes = 'out2in';
set(handles.radiobuttonout2in,'value',true);
options.channels = 'all';
set(handles.radiobuttonall,'value',true);
set(handles.options, 'userdata',options);

set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display the DTF graphics
displayDTFG(options);

% display directed transfer function matrix.
axes(handles.imageaxes);

cla;  
box off;
axis on;
hold on;

plotimage = flipud(currentdtfmatrix);
imagesc(plotimage,'tag','dtfimage');

vnum = length(currentdtfmatrix);
for i=0:vnum
    lx = [0.5 vnum+0.5];
    ly = i+0.5;
    ly = [ly ly];
    plot(lx,ly,'k');
    plot(ly,lx,'k');
end

caxis([valmin valmax]);
colorbar;

%% Update the display of the DTF graphics.
function  displayDTFG(options)

hfig = gcf;

% parameters for the display of head, labels, and dtf graphics. 
sceneaxes = findobj(hfig,'tag','sceneaxes'); 
if isempty(sceneaxes)
    return;
end
model = get(sceneaxes, 'userdata');

axes(sceneaxes);
cla;
hold on;

if options.isskin % draw the skin model
     patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                'FaceLighting','phong',...
                'Vertices',model.skin.italyskin.Vertices,...
                'LineStyle','none',...
                'Faces',model.skin.italyskin.Faces,...
                'FaceColor','interp',...
                'FaceAlpha',1,...
                'EdgeColor','none',...
                'FaceVertexCData',model.skin.italyskin.FaceVertexCData);
end

% draw MEG cap
if options.iscap
    capcolor = [0.9, 0.85, 0.7];
    patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                 'FaceLighting','phong',...
                 'Vertices',model.mags.cap.locations,...
                 'LineStyle','none',...
                 'Faces',model.mags.cap.tri,...
                 'FaceColor','flat',...
                 'FaceAlpha',1,...
                 'FaceVertexCData',capcolor);
end

% draw magnetometers
if options.issensor
    sensorcolor = [0.0  0.0  1.0];
    plot3(model.mags.locations(:,1), ...
            model.mags.locations(:,2), ... 
            model.mags.locations(:,3), ... 
            'k.','LineWidth',4,'color', sensorcolor);
end

% draw labels
if options.islabel
    labelscale = 1.05;
    if isequal(options.channels,'single') 
        if isequal(options.dispmodes, 'out2in')
            rr = options.whichchannel(1);
            cc = options.whichchannel(2);
            
            % the first location
            location = labelscale*model.mags.locations(rr,:);
            text( location(1), location(2), location(3), ... 
                    char(upper(model.mags.labels{rr})),'FontSize',8 ,...
                    'HorizontalAlignment','center');
                
            % the second location
            location = labelscale*model.mags.locations(cc,:);
            text( location(1), location(2), location(3), ... 
                    char(upper(model.mags.labels{cc})),'FontSize',8 ,...
                    'HorizontalAlignment','center');     
        else
            i = options.whichchannel;
            location = labelscale*model.mags.locations(i,:);
            text( location(1), location(2), location(3), ... 
                    char(upper(model.mags.labels{i})),'FontSize',8 ,...
                    'HorizontalAlignment','center');        
        end
    else
            locations = labelscale*model.mags.locations;
            text( locations(:,1), locations(:,2), locations(:,3), ... 
                    char(upper(model.mags.labels)),'FontSize',8 ,...
                    'HorizontalAlignment','center');        
    end
end

% draw connectivity patterns
if options.dtf      
    imageaxes = findobj(hfig, 'tag','imageaxes');
    currentdtfmatrix = get(imageaxes, 'userdata');
    roipos = model.mags.locations;

    ArrowSizeLimit = [1 5];
    SphereSizeLimit = [5 12];
    opt = struct('Channels', options.channels,...
                              'Whichchannel', options.whichchannel,...
                              'ValLim', options.displimits,...
                              'ArSzLt',ArrowSizeLimit,...
                              'SpSzLt',SphereSizeLimit);
                          
    if isequal(options.dispmodes, 'out2in')
        drawdtfconngraph(currentdtfmatrix,roipos,opt);
    elseif isequal(options.dispmodes, 'outflow')
        outflows = sum(currentdtfmatrix,1)/(size(currentdtfmatrix,2)-1);
        drawdtfflowgraph(outflows,roipos,opt);
    else % inflow
        inflows = sum(currentdtfmatrix,2)/(size(currentdtfmatrix,2)-1);
        drawdtfflowgraph(inflows,roipos,opt);
    end
end

lighting phong;
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
%%

% model = get(sceneaxes,'userdata');
if model.colorbar
    delete(model.colorbar);
end

if isfield(options,'minmax')
    caxis(options.minmax);
    model.colorbar = colorbar('peer',sceneaxes,'location','WestOutside');
    set(sceneaxes,'userdata',model);
end

drawnow;


function mousemotionCallback(src, evnt) 

hfig = gcf;
sceneaxes = findobj(hfig,'tag','sceneaxes'); 
imageaxes = findobj(hfig,'tag','imageaxes'); 
optionshandle = findobj(hfig,'tag','options');
textvalue = findobj(hfig,'tag','textvalue');
if isempty(imageaxes) | isempty(textvalue)
    return;
end
 
options =get(optionshandle,'userdata');
if ~options.dtf
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
matrix = get(imageaxes,'userdata');
vnum = size(matrix,1);

idxx = ceil(mousepos(1,1)-imagexlim(1,1));
if idxx<1 | idxx>vnum
    return;
end

idxy = ceil(mousepos(1,2)-imageylim(1,1));
idxy = vnum-idxy +1;
if idxy<1 | idxy>vnum
    return;
end

% get the connectivity value.
convalue = matrix(idxy,idxx);

model = get(sceneaxes,'userdata');

% get the outflow roi and inflow roi
inputroi = model.mags.labels{idxx};
outputroi = model.mags.labels{idxy};

set(textvalue,'string',[inputroi ' --> ' outputroi ': ' num2str(convalue,'%6f')]);



function mousedownCallback(src, evnt)

hfig = gcf;
imageaxes = findobj(hfig,'tag','imageaxes'); 
sceneaxes = findobj(hfig,'tag','sceneaxes');
optionshandle = findobj(hfig,'tag','options');
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
% display the value corresponding to the mouse position.
matrix = get(imageaxes,'userdata');
vnum = size(matrix,1);

idxx = ceil(mousepos(1,1)-imagexlim(1,1));
if idxx<1 | idxx>vnum
    return;
end

idxy = ceil(mousepos(1,2)-imageylim(1,1));
idxy = vnum-idxy +1;
if idxy<1 | idxy>vnum
    return;
end

model = get(sceneaxes,'userdata');

if isequal(options.dispmodes,'out2in')
    options.whichchannel = [idxy idxx];
elseif isequal(options.dispmodes,'outflow')
    options.whichchannel = idxx;
    outflow = sum(matrix(:,idxx))/(size(matrix,2)-1);
    inputs = model.mags.labels{idxx};
    set(textvalue,'string',[inputs ' --> : ' num2str(outflow,'%6f')]);
else 
    options.whichchannel = idxy;
    inflow = sum(matrix(idxy,:))/(size(matrix,2)-1);
    outputs = model.mags.labels{idxy};
    set(textvalue,'string',[outputs ' <-- : ' num2str(inflow,'%6f')]);
end

set(optionshandle, 'userdata', options);

displayDTFG(options);


% --- Executes on button press in radiobuttonall.
function radiobuttonall_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonall

% change options accordingly.
options = get(handles.options,'userdata');
if get(hObject,'value')
    options.channels = 'all';
end
set(handles.options, 'userdata', options);

if ~options.dtf
    return;
end

displayDTFG(options);


% --- Executes on button press in radiobuttonsingle.
function radiobuttonsingle_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonsingle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonsingle

% get dtf matrix
matrix = get(handles.imageaxes,'userdata');

% change options accordingly.
options = get(handles.options,'userdata');

if get(hObject,'value')
    options.channels = 'single';   
    if isequal(options.dispmodes,'out2in')
        maxvalue = max(max(matrix));
        [row col] = find(matrix==maxvalue, 1);
        options.whichchannel = [row col];
    elseif isequal(options.dispmodes,'outflow')
        outflows = sum(matrix,1)/(size(matrix,2)-1);
        valmax = max(outflows);
        options.whichchannel = find(outflows==valmax, 1);
    else
        inflows = sum(matrix,2)/(size(matrix,2)-1);
        valmax = max(inflows);
        options.whichchannel = find(inflows==valmax, 1);        
    end
end
set(handles.options, 'userdata', options);

if ~options.dtf
    return;
end

displayDTFG(options);


% --- Executes on button press in radiobuttonnone.
function radiobuttonnone_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonnone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonnone

% change options accordingly.
options = get(handles.options,'userdata');
if get(hObject,'value')
    options.channels = 'none';
end
set(handles.options, 'userdata', options);

if ~options.dtf
    return;
end

displayDTFG(options);

% --- Executes on button press in radiobuttonout2in.
function radiobuttonout2in_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonout2in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonout2in

options = get(handles.options,'userdata');

if ~options.dtf
    return;
end

if ~get(hObject,'value')
    return;
end

% get dtf matrix
matrix = get(handles.imageaxes,'userdata');

options.dispmodes = 'out2in';

if isequal(options.channels,'single')   
    maxvalue = max(max(matrix));
    [row col] = find(matrix==maxvalue, 1);
    options.whichchannel = [row col];        
end

mat = matrix;
% mat(~mat)=nan;
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

[row col] = find(mat==valmax, 1);
options.whichchannel = [row col];

set(handles.options, 'userdata',options);
set(handles.textmin, 'string', ['Min: '  num2str(valmin,'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(valmax,'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
displayDTFG(options);


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

% get dtf matrix
matrix = get(handles.imageaxes,'userdata');

options.dispmodes = 'outflow';
outflows = sum(matrix,1)/(size(matrix,2)-1);
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
options.displimits = [valmin valmax];
options.whichchannel = find(outflows==valmax, 1);
set(handles.options, 'userdata', options);

set(handles.textmin, 'string', ['Min: '  num2str(options.displimits(1),'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(options.displimits(2),'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
displayDTFG(options);

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

% get dtf matrix
matrix = get(handles.imageaxes,'userdata');

options.dispmodes = 'inflow';
inflows = sum(matrix,2)/(size(matrix,2)-1);
valmax = max(inflows);
valmin = min(inflows);
if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
end
options.minmax = [valmin, valmax];
options.displimits = [valmin valmax];
options.whichchannel = find(inflows==valmax, 1);
set(handles.options, 'userdata', options);

set(handles.textmin, 'string', ['Min: '  num2str(options.displimits(1),'%6f')] );
set(handles.textmax, 'string', ['Max: '  num2str(options.displimits(2),'%6f')] );
set(handles.editmin, 'string', num2str(options.displimits(1),'%6f'));
set(handles.editmax, 'string', num2str(options.displimits(2),'%6f'));

% display DTF graphics.
displayDTFG(options);


% --------------------------------------------------------------------
function menu_Callback(hObject, eventdata, handles)
% hObject    handle to menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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

[name, pathstr] = uiputfile('*.mat','Save DTF Properties');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

frequency = get(handles.textfrequency,'userdata');
matrix = get(gcf,'userdata');

model = get(handles.sceneaxes, 'userdata');

% DTF properties
DTF.labels = model.mags.labels;
DTF.locations = model.mags.locations;
DTF.frequency = frequency;
DTF.matrix = matrix;
DTF.type = 'Cap';
DTF.isadtf = options.isadtf;
DTF.srate = options.srate;
DTF.cap = model.mags.cap;

save(Fullfilename, 'DTF');

% --------------------------------------------------------------------
function menu_import_dtf_Callback(hObject, eventdata, handles)
% hObject    handle to menu_import_dtf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

options = get(handles.options,'userdata');
if options.dtf    
    importevent = questdlg('Exist DTF, import new one ?','','Yes','Cancel','Cancel');
    if ~strcmp(importevent, 'Yes')
        return;
    end
end

%% Get DTF properties.
[matname matpath]=uigetfile('*.mat','Select Directed Transfer Function File');
if matname==0
    return;
end

addpath(matpath);
Fullfilename = fullfile(matpath,matname);
DTF = load(Fullfilename);

if ~isfield(DTF, 'DTF')
    errordlg('The imported is not DTF file!');
    return;
end

if ~isequal(DTF.DTF.type,'Cap')
    errordlg('The imported is not a DTF file for MEG cap model!');
    return;
end

model = get(handles.sceneaxes,'userdata');
model.mags.labels = DTF.DTF.labels;
model.mags.locations = DTF.DTF.locations;
model.mags.cap = DTF.DTF.cap;
frequency = DTF.DTF.frequency;
%%

% get current frequency and matrix
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
    
    currentdtfmatrix = squeeze(DTF.DTF.matrix(sp,:,:,1));
else
    currentdtfmatrix = DTF.DTF.matrix(:,:,1);
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

% update frequency scope and current frequency
set(handles.textfrequency,'string', ['Current Frequeny (' num2str(frequency(1)) ' ~ ' num2str(frequency(2)) '):']);
set(handles.frequencyedit,'string', num2str(currentf));
sliderstep = 1/(frequency(2)-frequency(1));
set(handles.sliderfrequency,'min',frequency(1),'max',frequency(2),'sliderstep',[sliderstep sliderstep],'value',currentf);

set(handles.textfrequency,'userdata', frequency);
set(gcf, 'userdata', DTF.DTF.matrix);
set(handles.imageaxes, 'userdata', currentdtfmatrix);
set(handles.sceneaxes,'userdata',model);

% update options
options.dtf = 1;

valmin = min(min(currentdtfmatrix));
valmax = max(max(currentdtfmatrix));
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

% display the DTF graphics
displayDTFG(options);


%% display directed transfer function matrix.
vnum = length(model.mags.labels);
ticks = 1:vnum;
xlabels = num2str(ticks');
yLabels = flipud(num2str(ticks'));

axes(handles.imageaxes);
cla;  
hold on;
set(handles.imageaxes,...
      'Xlim',[0 vnum+1],...
      'xtick',ticks,...% where to display the labels.
      'Ylim',[0 vnum+1],...
      'YTick',ticks,...
      'XTickLabel', xlabels,...% the labels to be displayed
      'YTickLabel', yLabels,...
      'TickLength',[.005 .005]);
  
plotimage = flipud(currentdtfmatrix);
imagesc(plotimage,'tag','dtfimage');
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

dtfmatrixs = get(gcf, 'userdata');

% compute integrated DTF/ADTF
if options.isadtf
    tempmatrix = squeeze(dtfmatrixs(currentt,:,:,minf:maxf));
else
    tempmatrix = dtfmatrixs(:,:,minf:maxf);
end
currentdtfmatrix = mean(tempmatrix,3);
set(handles.imageaxes, 'userdata', currentdtfmatrix);

if isequal(options.dispmodes,'out2in')
    valmin = min(min(currentdtfmatrix));
    valmax = max(max(currentdtfmatrix));
    [row col] = find(currentdtfmatrix==valmax, 1);
    options.whichchannel = [row col];
elseif isequal(options.dispmodes,'outflow')
    outflows = sum(currentdtfmatrix,1)/(size(currentdtfmatrix,2)-1);
    valmax = max(outflows);
    valmin = min(outflows);
    options.whichchannel = find(outflows==valmax, 1);
else
    inflows = sum(currentdtfmatrix,2)/(size(currentdtfmatrix,2)-1);
    valmax = max(inflows);
    valmin = min(inflows);
    options.whichchannel = find(inflows==valmax, 1);
end

if isnan(valmin)
    valmin = 0.001;
end
if isnan(valmax)
    valmax = 1;
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

displayDTFG(options);


% display directed transfer function matrix.
axes(handles.imageaxes);
cla;  
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


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



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


% --------------------------------------------------------------------
function menu_tv_Callback(hObject, eventdata, handles)
% hObject    handle to menu_tv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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

dtfmatrixs = get(gcf, 'userdata');
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

TVFLOW.labels = model.mags.labels;
TVFLOW.flows = adtf_outflows;
TVFLOW.type = 'outflow';
TVFLOW.srate = options.srate;
tvflow(TVFLOW);

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

dtfmatrixs = get(gcf, 'userdata');
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
TVFLOW.labels = model.mags.labels;
TVFLOW.flows = adtf_inflows;
TVFLOW.type = 'inflow';
TVFLOW.srate = options.srate;
tvflow(TVFLOW);


% --- Executes on button press in checkboxcap.
function checkboxcap_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxcap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxcap
options = get(handles.options,'userdata');
options.iscap = get(hObject,'value');
set(handles.options, 'userdata', options);
displayDTFG(options);

