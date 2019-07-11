function varargout = pop_meg_psd(varargin)
% pop_meg_psd - visualize the spectrum map of the MEG over the cap model.
%
% Usage: 
%            1. type 
%               >> pop_meg_psd(MEG)
%               or call pop_meg_psd(MEG) to start the popup GUI with MEG structure. 
%               The MEG structure should be pre-exported by the megfc GUI 
%               or made by 
%               >> MEG = pop_meg_txtreader  
%               or
%               >> MEG = pop_meg_matreader
%               Please see the eConnectome Manual  
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable import MEG file formats (TXT and MAT).
%           
%            2. call pop_meg_psd(MEG) from the megfc GUI ('Menu bar -> Topography -> Power Spectra Density') 
%                to visualize the spectrum map of the current MEG.
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
% Yakang Dai, 01-Feb-2011 15:49:30
% Release Version 2.0 beta
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_meg_psd_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_meg_psd_OutputFcn, ...
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


%% =========================================================================
% --- Executes just before pop_meg_psd is made visible.
function pop_meg_psd_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_meg_psd (see VARARGIN)

% Choose default command line output for pop_meg_psd
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_meg_psd wait for user response (see UIRESUME)
% uiwait(handles.figure1);

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

MEG = ismeg(varargin{:});
if isempty(MEG)
    errordlg('The input is not a valid MEG!');
    return;
end

setappdata(hObject,'MEG',MEG);

axcolor = get(hObject, 'color');
axes(handles.psdaxes);
set(handles.psdaxes, 'color', axcolor);
axis on;
box on;
axes(handles.psdtopoaxes);
axis vis3d;
set(handles.psdtopoaxes, 'color', axcolor);
set(handles.psdtopoaxes, 'DataAspectRatio',[1 1 1]);
box off;
axis off;

% input frequency band
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
low = 0; 
high = 80;
prompt = {['Enter low frequency (>=' num2str(0) '):'], ['Enter high frequency (<=' num2str(MEG.srate/2) '):']};
dlg_title = 'Frequency band for Power Spectra Density';
num_lines = 1;
def = {num2str(low), num2str(high)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if ~isempty(answer)
    low = str2num(answer{1});
    high = str2num(answer{2});
end

if isempty(low) | isempty(high)
    warndlg('Input must be numeric!');
    return;
end

high = max(min(high,MEG.srate/2),0);
low = max(min(low,MEG.srate/2),0);

if low >= high
    warndlg('Low must be < High!');
    return;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot the Power Spectra Density. 
axes(handles.psdaxes);
xlabel('Frequency (Hz)');
ylabel('PSD (dB/Hz)');

epochstart = 1;
epochend = MEG.points;
psd.spec = [];
psd.freqs = [];
toallocate = 1;

channum = length(MEG.vidx);
for i = 1:channum   
    % compute around 256 points in the selected frequency band.  
    fftlength = round(256*(MEG.srate/2)/(high-low+1));
    [psdspec, psd.freqs] =  pwelch(MEG.data(MEG.vidx(i),epochstart:epochend),[],[],fftlength,MEG.srate);   
    
    if toallocate == 1
        len = size(psdspec,1);
        psd.spec = zeros(channum,len);
        toallocate = 0;
    end
    psd.spec(i,:) = 10*log10(psdspec);
end
psd.labels = MEG.labels(MEG.vidx);

% get the spectra in the given frequency band 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = find(psd.freqs>=low);
if isempty(idx)
    warndlg('Input low frequency is too high!');
    return;    
else
    low_idx = idx(1);
end

idx = find(psd.freqs<=high);
if isempty(idx)
    warndlg('Input high frequency is too low!');
    return;    
else
    high_idx = idx(length(idx));
end

psd.freqs = psd.freqs(low_idx:high_idx);
psd.spec = psd.spec(:,low_idx:high_idx);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% display the PSD
ylimit.max = max(max(psd.spec));
ylimit.min = min(min(psd.spec));
xlimit.max = max(psd.freqs);
xlimit.min = min(psd.freqs);

set(handles.psdaxes, 'userdata', psd,...% store the data here
      'Xlim',[xlimit.min  xlimit.max],...
      'Ylim',[ylimit.min  ylimit.max]);
cla;
hold on;

lineclr = [0.5, 0.8, 0.5];
for i = 1: channum
    plot(psd.freqs,psd.spec(i,:), 'color', lineclr,'LineWidth',1);
end

lineclr = [0.0, 0.0, 1.0];
i = 1;
plot(psd.freqs,psd.spec(i,:), 'color', lineclr,'LineWidth',2);
j = round(length(psd.freqs)/2);
x = psd.freqs(j);
y = psd.spec(i, j);
text(x,y,char(psd.labels(i)),'VerticalAlignment', 'bottom','FontSize',18,'color',lineclr);      
setappdata(hObject,'currentchannel',i);
%%

%% Plot PSD over the MEG cap
map.mag = 'off';
map.label = 'off';
map.map = 'on';
map.head = 'on';
map.handles.head = 0;
map.handles.mag = 0;
map.handles.label = 0;
map.handles.map = 0;
map.initialize = 1;
map.clrlimitauto = 1;
map.cmin = 0;
map.cmax = 1;
map.gmin = ylimit.min;
map.gmax = ylimit.max;
map.caxis = 'local';
map.values = psd.spec(:,1);
set(handles.psdtopoaxes, 'userdata', map);

% the head model
model.skin = load('italyskin.mat');
CoR = load('CoR.mat');
model.CoR = CoR.italyskin;
num = length(model.skin.italyskin.Vertices);
model.skin.italyskin.Vertices = (model.skin.italyskin.Vertices+repmat(model.CoR.translation,num,1))*model.CoR.rotation;

model.k = MEG.vidx;
model.mag.labels = MEG.labels(model.k);
model.mag.locations = MEG.locations.italybrain(model.k,:);
model.X = MEG.locations.surf.x(model.k,1); 
model.Y = MEG.locations.surf.y(model.k,1);   
model.XI = MEG.locations.surf.x(:,1); 
model.YI = MEG.locations.surf.y(:,1); 
setappdata(hObject,'model',model);

setappdata(hObject,'MEG',MEG);

topomap;
%%

%% set callbacks
set(gcf,'windowbuttonmotionfcn', @mousemotionCallback);
set(gcf,'WindowButtonDownFcn', @mousedownCallback);
%%
%% ========================================================================


%% ========================================================================
%% --- Outputs from this function are returned to the command line.
function varargout = pop_meg_psd_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
%%
%% ========================================================================


%% ========================================================================
%% Mouse motion callback function.
function mousemotionCallback(src, evnt) 

hfig = gcf;

% mouse motion in psdaxes.
psdaxes = findobj(hfig,'tag','psdaxes'); 
     
currentxlim = get(psdaxes, 'Xlim');
currentylim = get(psdaxes, 'Ylim');
mousepos = get(psdaxes, 'currentpoint');
if isempty(mousepos)
    return;
end
     
% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) >= currentxlim(1,1) && mousepos(1,1) <= currentxlim(1,2)  && ...
   mousepos(1,2) >= currentylim(1,1) && mousepos(1,2) <= currentylim(1,2) 

    % update the line position.
    psd = get(psdaxes, 'userdata');
    len = size(psd.freqs,1);
    spacing = (currentxlim(1,2)-currentxlim(1,1))/(len-1);
    idx = round( (mousepos(1,1)-currentxlim(1,1))/spacing )+1;
    if idx<1
        idx = 1;
    elseif idx > len
        idx = len;
    end

    axes(psdaxes);
    xpos = ([psd.freqs(idx),  psd.freqs(idx)]);
    ypos = [currentylim(1,1),  currentylim(1,2)];
    tmpcolor = [ 0.0 1.0 0.0 ];
    textcolor = [ 0.0 0.0 0.0 ];

    psdlinehandle = findobj(hfig,'tag','psdlinetag');
    if isempty(psdlinehandle)
        plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'psdlinetag');
    else
        set(psdlinehandle,'xdata',xpos,'ydata',ypos);
        drawnow;
    end

    frequency = psd.freqs(idx);
    currentchannel = getappdata(hfig,'currentchannel');
    psdspec = psd.spec(currentchannel,idx);

    psdtexthandle = findobj(hfig,'tag','psdtexttag');
    if isempty(psdtexthandle)
        text(mousepos(1,1)+spacing, mousepos(1,2)+spacing, ['(' num2str(frequency) ' Hz, ', num2str(psdspec),' dB/Hz)'], 'color', textcolor, 'clipping','off','EraseMode', 'xor', 'tag', 'psdtexttag');
    else
        set(psdtexthandle,'Position', [mousepos(1,1)+spacing  mousepos(1,2)+spacing],'string', ['(' num2str(frequency) ' Hz, ', num2str(psdspec),' dB/Hz)']);
        drawnow;
    end

    return;
end
%% ========================================================================

%% ========================================================================
%% Mouse down callback function.
function mousedownCallback(src, evnt)
      
hfig = gcf;
     
psdaxes = findobj(hfig,'tag','psdaxes'); 
psdlinetag = findobj(hfig,'tag','psdlinetag');
psdtopoaxes = findobj(hfig,'tag','psdtopoaxes'); 
     
currentxlim = get(psdaxes, 'Xlim');
currentylim = get(psdaxes, 'Ylim');
mousepos = get(psdaxes, 'currentpoint');
     
if isempty(mousepos)
    return;
end

% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
   mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
      return;
end
 
xpos =  get(psdlinetag,'xdata');
ypos = [currentylim(1,1),  currentylim(1,2)];

selectype = lower(get(hfig,'SelectionType'));

% 'alt': right click - select epoch
if strcmp(selectype,'alt')    
    popmenu_psdaxes = findobj(hfig,'tag','popmenu_psdaxes');
    position = get(hfig,'CurrentPoint');
    set(popmenu_psdaxes,'position',position);
    set(popmenu_psdaxes,'Visible','on');
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
    
psd = get(psdaxes, 'userdata');
idx = find(psd.freqs == xpos(1,1));
      
len = size(psd.freqs,1);
if idx<1
    idx = 1;
elseif idx > len
    idx = len;
end

map = get(psdtopoaxes,'userdata');
map.values = psd.spec(:,idx);
map.clrlimitauto = 1;
set(psdtopoaxes, 'userdata', map);
topomap;


%% The function for topographical mapping.
function topomap()

hfig = gcf;
textminpsd = findobj(hfig,'tag','textminpsd');
textmaxpsd = findobj(hfig,'tag','textmaxpsd');
minpsd = findobj(hfig,'tag','minpsd');
maxpsd = findobj(hfig,'tag','maxpsd');
psdtopoaxes = findobj(hfig,'tag','psdtopoaxes');
map = get(psdtopoaxes, 'userdata');
model = getappdata(hfig,'model');
MEG = getappdata(hfig,'MEG');

VI = griddata(model.X,model.Y,map.values,model.XI,model.YI,'v4');

mincurrentV = min(VI);
maxcurrentV = max(VI);

if isequal(map.caxis, 'global')
    minV = map.gmin;
    maxV = map.gmax;
    k = find(VI<minV);
    VI(k) = minV;
    k = find(VI>maxV);
    VI(k) = maxV;    
else
    minV = mincurrentV;
    maxV = maxcurrentV;
end

axes(psdtopoaxes);

if map.clrlimitauto
    caxis([minV  maxV]);
    map.cmin = mincurrentV;
    map.cmax = maxcurrentV;
    set(psdtopoaxes, 'userdata', map);
else
    caxis([map.cmin  map.cmax]);
end

% initialize the mapping
if map.initialize == 1
    cla;
    hold on;

    map.handles.head = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                                                     'FaceLighting','phong',...
                                                     'Vertices',model.skin.italyskin.Vertices,...
                                                     'LineStyle','none',...
                                                     'Faces',model.skin.italyskin.Faces,...
                                                     'FaceColor','interp',...
                                                     'FaceAlpha',1,...
                                                     'EdgeColor','none',...
                                                      'FaceVertexCData',model.skin.italyskin.FaceVertexCData,...
                                                      'Visible',map.head);
    lighting phong;
    lightcolor = [0.5 0.5 0.5];
    light('Position',[0 0 1],'color',lightcolor);
    light('Position',[0 1 0],'color',lightcolor);
    light('Position',[0 -1 0],'color',lightcolor);

    map.handles.map = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                                                     'FaceLighting','phong',...
                                                     'Vertices',MEG.locations.italybrain,...
                                                     'LineStyle','none',...
                                                     'Faces',MEG.locations.surf.tri,...
                                                     'FaceColor','interp',...
                                                     'FaceAlpha',1,...
                                                     'EdgeColor','none',...
                                                     'FaceVertexCData',VI,...
                                                     'Visible',map.map);

    magcolor = [0.0  1.0  1.0];
    map.handles.mag = plot3(model.mag.locations(:,1), ...
                                                  model.mag.locations(:,2), ... 
                                                  model.mag.locations(:,3), ... 
                                                  'k.','LineWidth',4,'color', magcolor,...
                                                  'Visible',map.mag);

    textcolor = [0.0 0.0 0.0];
    locations = 1.05*model.mag.locations;
    map.handles.label = text( locations(:,1), locations(:,2), locations(:,3), ... 
                                                  upper(model.mag.labels),'FontSize',8 ,...
                                                  'HorizontalAlignment','center', 'Color',textcolor,...
                                                  'Visible',map.label);
     
     map.initialize = 0;
     set(psdtopoaxes, 'userdata', map);
else
    set(map.handles.head, 'Visible', map.head);
    set(map.handles.map, 'FaceVertexCData', VI, 'Visible', map.map);
    set(map.handles.mag, 'Visible', map.mag);
    set(map.handles.label, 'Visible', map.label);    
end

colorbar('peer',psdtopoaxes);

% update PSD-Color Mapping Limits
set(textminpsd, 'string', ['Min PSD (>= ' num2str(mincurrentV) ' dB/Hz)']);
set(textmaxpsd, 'string', ['Max PSD (<= ' num2str(maxcurrentV) ' dB/Hz)']);
set(minpsd, 'string', num2str(map.cmin));
set(maxpsd, 'string', num2str(map.cmax));

drawnow;
%% ========================================================================


function maxpsd_Callback(hObject, eventdata, handles)
% hObject    handle to maxpsd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxpsd as text
%        str2double(get(hObject,'String')) returns contents of maxpsd as a double


% --- Executes during object creation, after setting all properties.
function maxpsd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxpsd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minpsd_Callback(hObject, eventdata, handles)
% hObject    handle to minpsd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minpsd as text
%        str2double(get(hObject,'String')) returns contents of minpsd as a double


% --- Executes during object creation, after setting all properties.
function minpsd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minpsd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in updatemap.
function updatemap_Callback(hObject, eventdata, handles)
% hObject    handle to updatemap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

actualmin = get(handles.textminpsd, 'string');
actualmax = get(handles.textmaxpsd, 'string');
actualmin = strtok(actualmin, ['Min PSD (>= '  ' dB/Hz)']);
actualmax = strtok(actualmax, ['Max PSD (<=  '  ' dB/Hz)']);
actualminvalue = str2num(actualmin);
actualmaxvalue = str2num(actualmax);

setmin = get(handles.minpsd, 'string');
setmax = get(handles.maxpsd, 'string');
[setminvalue status1] = str2num(setmin);
[setmaxvalue status2] = str2num(setmax);
if status1 == 0 | status2==0
    errordlg('Input number is invalid, please Do Not input letters!', 'Input error', 'modal');
    return;
end

setminvalue = max(actualminvalue, min(actualmaxvalue, setminvalue));
setmaxvalue = max(actualminvalue, min(actualmaxvalue, setmaxvalue));

if setminvalue > setmaxvalue
    tmpvalue = setminvalue;
    setminvalue = setmaxvalue;
    setmaxvalue = tmpvalue;
end

if setminvalue == setmaxvalue
    errordlg('Input number is invalid, please input a range!', 'Input error', 'modal');
    return;
end

set(handles.minpsd, 'string',num2str(setminvalue));
set(handles.maxpsd, 'string',num2str(setmaxvalue));
map = get(handles.psdtopoaxes, 'userdata');
map.clrlimitauto = 0;
map.cmin = setminvalue;
map.cmax = setmaxvalue;
set(handles.psdtopoaxes, 'userdata', map);

axes(handles.psdtopoaxes);
topomap;
drawnow expose;

% --------------------------------------------------------------------
function popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function menu_mags_Callback(hObject, eventdata, handles)
% hObject    handle to menu_mags (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
psdtopoaxes = findobj('tag','psdtopoaxes'); 
map = get(psdtopoaxes, 'userdata');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    map.mag = 'off';
else
    ischecked = 'on';
    map.mag = 'on';
end

set(psdtopoaxes, 'userdata', map);
set(hObject,'checked',ischecked);
topomap;

% --------------------------------------------------------------------
function menu_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
psdtopoaxes = findobj('tag','psdtopoaxes'); 
map = get(psdtopoaxes, 'userdata');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    map.label = 'off';
else
    ischecked = 'on';
    map.label = 'on';
end

set(psdtopoaxes, 'userdata', map);
set(hObject,'checked',ischecked);
topomap;

function selectchannel()

hfig = gcf;
psdaxes = findobj(hfig, 'tag', 'psdaxes');
psd = get(psdaxes, 'userdata');

default = [];
[sel,ok] = listdlg('ListString',psd.labels,'Name','Channel Selection','InitialValue',default,'SelectionMode','single');
if ok == 0 | isempty(sel)
    return;
end

if length(sel) ~= 1
    helpdlg('Please select only one channel!');
    return;
end

leftline = findobj(hfig, 'tag', 'leftline');
if leftline
    leftline_xpos = get(leftline,'xdata');
    leftline_ypos = get(leftline,'ydata');    
end
rightline = findobj(hfig, 'tag', 'rightline');
if rightline 
    rightline_xpos = get(rightline,'xdata');
    rightline_ypos = get(rightline,'ydata');    
end
currentline = findobj(hfig, 'tag', 'currentline');
if currentline 
    currentline_xpos = get(currentline,'xdata');
    currentline_ypos = get(currentline,'ydata');    
end

axes(psdaxes);
cla;
hold on;

lineclr = [0.5, 0.8, 0.5];
% lineclr = [0.5, 0.5, 0.5];
dispnum = length(psd.labels);
for i = 1: dispnum
    plot(psd.freqs,psd.spec(i,:), 'color', lineclr,'LineWidth',1);
end

lineclr = [0.0, 0.0, 1.0];
i = sel(1);
plot(psd.freqs,psd.spec(i,:), 'color', lineclr,'LineWidth',2);
j = round(length(psd.freqs)/2);
x = psd.freqs(j);
y = psd.spec(i, j);
text(x,y,char(psd.labels(i)),'VerticalAlignment', 'bottom','FontSize',18,'color',lineclr);  
setappdata(hfig,'currentchannel',i);

leftcolor = [1.0 0.0 0.0];
rightcolor = [0.0 0.0 1.0];
currentcolor = [0.0 0.0 0.0];
if leftline
    plot(leftline_xpos, leftline_ypos, 'color', leftcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
end
if rightline
    plot(rightline_xpos, rightline_ypos, 'color', rightcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
end
if currentline
    plot(currentline_xpos, currentline_ypos, 'color', currentcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'currentline');
end

% --------------------------------------------------------------------
function menu_global_Callback(hObject, eventdata, handles)
% hObject    handle to menu_global (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
psdtopoaxes = findobj(hfig,'tag','psdtopoaxes');
map = get(psdtopoaxes, 'userdata');
map.caxis = 'global';
set(psdtopoaxes,'userdata',map);

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
topomap;

% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_local_Callback(hObject, eventdata, handles)
% hObject    handle to menu_local (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
psdtopoaxes = findobj(hfig,'tag','psdtopoaxes');
map = get(psdtopoaxes, 'userdata');
map.caxis = 'local';
set(psdtopoaxes,'userdata',map);

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
topomap;

% --------------------------------------------------------------------
function menu_select_Callback(hObject, eventdata, handles)
% hObject    handle to menu_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selectchannel;

% --------------------------------------------------------------------
function menu_bandmap_Callback(hObject, eventdata, handles)
% hObject    handle to menu_bandmap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;    
psdaxes = findobj(hfig,'tag','psdaxes'); 
psdtopoaxes = findobj(hfig,'tag','psdtopoaxes'); 
psd = get(psdaxes, 'userdata');
currentxlim = get(psdaxes, 'Xlim');

leftline = findobj(hfig,'tag','leftline');
rightline = findobj(hfig,'tag','rightline');
len = size(psd.freqs,1);
    
if isempty(leftline) | isempty(rightline)
    frequency = pop_band;
else 
    leftxpos =  get(leftline,'xdata');
    idx = find(psd.freqs == leftxpos(1,1));    
    idx = max(1, min(len,idx));
    leftf = psd.freqs(idx);
    
    rightxpos =  get(rightline,'xdata');
    idx = find(psd.freqs == rightxpos(1,1));    
    idx = max(1, min(len,idx));
    rightf = psd.freqs(idx);
    
    if leftf > rightf
        % helpdlg('The frequency epoch is not right (low > high)!');
        frequency = pop_band;
    else
        frequency = pop_band([leftf,rightf]);
    end
end

if isempty(frequency)
    return;
end

spacing = (currentxlim(1,2)-currentxlim(1,1))/(len-1);
idxl = round( (frequency(1)-currentxlim(1,1))/spacing )+1;
idxl = max(1,min(len,idxl));

idxr = round( (frequency(2)-currentxlim(1,1))/spacing )+1;
idxr = max(1,min(len,idxr));

map = get(psdtopoaxes,'userdata');
map.values = mean(psd.spec(:,idxl:idxr), 2);
map.clrlimitauto = 1;
set(psdtopoaxes, 'userdata', map);
topomap;


% --------------------------------------------------------------------
function popmenu_psdaxes_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu_psdaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_epochstart_Callback(hObject, eventdata, handles)
% hObject    handle to menu_epochstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;     
psdaxes = findobj(hfig,'tag','psdaxes'); 
psdlinetag = findobj(hfig,'tag','psdlinetag');    
currentylim = get(psdaxes, 'Ylim');
xpos =  get(psdlinetag,'xdata');
ypos = [currentylim(1,1),  currentylim(1,2)];

tmpcolor = [0.0,0.0,1.0];
linehandle = findobj(hfig,'tag','leftline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end

% --------------------------------------------------------------------
function menu_epochend_Callback(hObject, eventdata, handles)
% hObject    handle to menu_epochend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;     
psdaxes = findobj(hfig,'tag','psdaxes'); 
psdlinetag = findobj(hfig,'tag','psdlinetag');    
currentylim = get(psdaxes, 'Ylim');
xpos =  get(psdlinetag,'xdata');
ypos = [currentylim(1,1),  currentylim(1,2)];

tmpcolor = [1.0,0.0,0.0];
linehandle = findobj(hfig,'tag','rightline');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end

% --------------------------------------------------------------------
function menu_capimg_Callback(hObject, eventdata, handles)
% hObject    handle to menu_capimg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.psdtopoaxes, 'Spectrum Mapping Image of MEG');


% --------------------------------------------------------------------
function menu_head_Callback(hObject, eventdata, handles)
% hObject    handle to menu_head (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
psdtopoaxes = findobj('tag','psdtopoaxes'); 
map = get(psdtopoaxes, 'userdata');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    map.head = 'off';
else
    ischecked = 'on';
    map.head = 'on';
end

set(psdtopoaxes, 'userdata', map);
set(hObject,'checked',ischecked);
topomap;

% --------------------------------------------------------------------
function menu_map_Callback(hObject, eventdata, handles)
% hObject    handle to menu_map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
psdtopoaxes = findobj('tag','psdtopoaxes'); 
map = get(psdtopoaxes, 'userdata');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    map.map = 'off';
else
    ischecked = 'on';
    map.map = 'on';
end

set(psdtopoaxes, 'userdata', map);
set(hObject,'checked',ischecked);
topomap;

