function varargout = pop_ecog_psd(varargin)
% pop_ecog_psd - visualize the spectrum map of the ECoG over the cortex model.
%
% Usage: 
%            1. type 
%               >> pop_ecog_psd(ECOG)
%               or call pop_ecog_psd(ECOG) to start the popup GUI with ECOG structure. 
%               The ECOG structure should be pre-exported by the ecogfc GUI
%           
%            2. call pop_ecog_psd(ECOG) from the ecogfc GUI ('Menu bar -> Topography -> Power Spectra Density') 
%                to visualize the spectrum map of the current ECOG.
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
% Yakang Dai, 20-June-2010 16:40:30
% Compute adequate frequency-PSD points in the 
% selected frequency band
%
% Yakang Dai, 15-May-2010 21:28:30
% Add capture image function
%
% Yakang Dai, 29-Mar-2010 17:45:30
% Release Version 1.0
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_ecog_psd_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_ecog_psd_OutputFcn, ...
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
% --- Executes just before pop_ecog_psd is made visible.
function pop_ecog_psd_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_ecog_psd (see VARARGIN)

% Choose default command line output for pop_ecog_psd
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_ecog_psd wait for user response (see UIRESUME)
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

ECOG = isecog(varargin{:});
if isempty(ECOG)
    errordlg('The input is not a valid ECOG!');
    return;
end

setappdata(hObject,'ECOG',ECOG);

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
prompt = {['Enter low frequency (>=' num2str(0) '):'], ['Enter high frequency (<=' num2str(ECOG.srate/2) '):']};
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

high = max(min(high,ECOG.srate/2),0);
low = max(min(low,ECOG.srate/2),0);

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
epochend = ECOG.points;
psd.spec = [];
psd.freqs = [];
toallocate = 1;

channum = length(ECOG.vidx);
for i = 1:channum
%     if ECOG.points < 9*256 
%         [psdspec, psd.freqs] =  pwelch(ECOG.data(ECOG.vidx(i),epochstart:epochend),[],[],[],ECOG.srate);
%     else
%         windowlength = 512;
%         overlaplength = 256;
%         fftlength = 512;       
%         [psdspec, psd.freqs] =  pwelch(ECOG.data(ECOG.vidx(i),epochstart:epochend),windowlength,overlaplength,fftlength,ECOG.srate);
%     end

    % make sure around 256 points are available in the selected frequency band.  
    fftlength = round(256*(ECOG.srate/2)/(high-low+1));
    [psdspec, psd.freqs] =  pwelch(ECOG.data(ECOG.vidx(i),epochstart:epochend),[],[],fftlength,ECOG.srate); 
    
    if toallocate == 1
        len = size(psdspec,1);
        psd.spec = zeros(channum,len);
        toallocate = 0;
    end
    psd.spec(i,:) = 10*log10(psdspec);
end
psd.labels = ECOG.labels(ECOG.vidx);

% % input frequency band
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% low = 0; 
% high = 80;
% prompt = {['Enter low frequency (>=' num2str(0) '):'], ['Enter high frequency (<=' num2str(ECOG.srate/2) '):']};
% dlg_title = 'Frequency band for Power Spectra Density';
% num_lines = 1;
% def = {num2str(low), num2str(high)};
% opt.Resize='on';
% answer = inputdlg(prompt,dlg_title,num_lines,def,opt);
% 
% if ~isempty(answer)
%     low = str2num(answer{1});
%     high = str2num(answer{2});
% end
% 
% if isempty(low) | isempty(high)
%     warndlg('Input must be numeric!');
%     return;
% end
% 
% high = max(min(high,ECOG.srate/2),0);
% low = max(min(low,ECOG.srate/2),0);
% 
% if low >= high
%     warndlg('Low must be < High!');
%     return;
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
% lineclr = [0.5, 0.5, 0.5];
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

%% Plot PSD on the cortex
map.electrodes = 0;
map.labels = 0;
map.surface = 1;
map.color = [0.6, 0.0, 0.0];
map.opacity = 1.0;
map.gmin = ylimit.min;
map.gmax = ylimit.max;
map.caxis = 'local';
map.values = psd.spec(:,1);
set(handles.psdtopoaxes, 'userdata', map);

% Cortex and brain model
load('colincortex.mat');
model.cortex = colincortex;
load('colinbrain.mat');
model.brain = colinbrain;
setappdata(hObject,'model',model);

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
vertices = model.brain.Vertices;
vertices = [vertices; model.brain.Centers];
[surflocs.X,surflocs.Y,surflocs.Z] = avgNeighbors(vertices,surflocs.X,surflocs.Y,surflocs.Z,surflocs.row,surflocs.column);
setappdata(gcf,'electrodelocs',electrodelocs);
setappdata(gcf,'surflocs',surflocs);

topomap;
%%

%% set callbacks
set(gcf,'windowbuttonmotionfcn', @mousemotionCallback);
set(gcf,'WindowButtonDownFcn', @mousedownCallback);
%%
%% ========================================================================


%% ========================================================================
%% --- Outputs from this function are returned to the command line.
function varargout = pop_ecog_psd_OutputFcn(hObject, eventdata, handles) 
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
    xpos = [psd.freqs(idx),  psd.freqs(idx)];
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
psdtopoaxes = findobj(hfig,'tag','psdtopoaxes');
psdaxes = findobj(hfig,'tag','psdaxes');
map = get(psdtopoaxes, 'userdata');
model = getappdata(hfig,'model');
ECOG = getappdata(hfig,'ECOG');

if map.surface
    if ~isempty(ECOG.data)
        electrodelocs = getappdata(hfig,'electrodelocs');
        surflocs = getappdata(hfig,'surflocs');
        y = electrodelocs.rowindex;
        x = electrodelocs.columnindex;
        [X,Y] = meshgrid(x,y);
        values = zeros(ECOG.nbchan,1);
        values(ECOG.vidx) = map.values;
        values(ECOG.bad) = min(values(ECOG.vidx));
        V = reshape(values,electrodelocs.row,electrodelocs.column);
        yi = [1:surflocs.row];
        xi = [1:surflocs.column];
        [XI,YI] = meshgrid(xi,yi);
        VI = interp2(X,Y,V,XI,YI);
    else
        surflocs = getappdata(hfig,'surflocs');
    end
end

axes(psdtopoaxes);
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
if map.surface
    if ~isempty(ECOG.data)
        if isequal(map.caxis, 'global')
            minV = map.gmin;
            maxV = map.gmax;
        else
            minV = min(min(VI));
            maxV = max(max(VI));
        end
        caxis([minV, maxV]);
        surface(surflocs.X,surflocs.Y,surflocs.Z,VI,...
            'SpecularStrength',0.2,'DiffuseStrength',0.8,...
            'FaceLighting','phong','FaceColor','interp',...
            'EdgeColor','none','FaceAlpha',map.opacity);
        colorbar;
    else
        surface(surflocs.X,surflocs.Y,surflocs.Z,'EdgeColor','none','FaceColor','b','FaceAlpha',map.opacity );
    end
end

k = length(ECOG.vidx);

% draw electrodes
if map.electrodes
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
        surf(hx3dp, hy3dp, hz3dp,'EdgeColor', 'none','FaceColor',map.color);
    end
end

% draw labels
if map.labels
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
axes(psdaxes);
%% ========================================================================

% --------------------------------------------------------------------
function popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function menu_electrodes_Callback(hObject, eventdata, handles)
% hObject    handle to menu_electrodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
map = get(handles.psdtopoaxes, 'userdata');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    map.electrodes = 0;
else
    ischecked = 'on';
    map.electrodes = 1;
end

set(handles.psdtopoaxes, 'userdata', map);
set(hObject,'checked',ischecked);
topomap;

% --------------------------------------------------------------------
function menu_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
map = get(handles.psdtopoaxes, 'userdata');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    map.labels = 0;
else
    ischecked = 'on';
    map.labels = 1;
end

set(handles.psdtopoaxes, 'userdata', map);
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
map = get(handles.psdtopoaxes, 'userdata');
map.caxis = 'global';
set(handles.psdtopoaxes,'userdata',map);

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
map = get(handles.psdtopoaxes, 'userdata');
map.caxis = 'local';
set(handles.psdtopoaxes,'userdata',map);

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
function menu_changecolor_Callback(hObject, eventdata, handles)
% hObject    handle to menu_changecolor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
map = get(handles.psdtopoaxes, 'userdata');
prompt = {'Enter electrode color (RGB), current is:'};
dlg_title = 'Input color for electrodes';
num_lines = 1;
def = {num2str(map.color)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

map.color = str2num(cell2mat(answer));

if isempty(map.color)
    warndlg('Input must be numeric!');
    return;
end

if length(map.color)~=3
    warndlg('Please input RGB values!');
    return;
end

map.color = max(0.0, min(1.0, map.color));

set(handles.psdtopoaxes, 'userdata',map);
topomap;

% --------------------------------------------------------------------
function menu_changealpha_Callback(hObject, eventdata, handles)
% hObject    handle to menu_changealpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
map = get(handles.psdtopoaxes, 'userdata');
prompt = {'Enter transparency value (0~1), current is:'};
dlg_title = 'Input transparency for surface';
num_lines = 1;
def = {num2str(map.opacity)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

map.opacity = str2num(cell2mat(answer));

if isempty(map.opacity)
    warndlg('Input must be numeric!');
    return;
end

if length(map.opacity)~=1
    warndlg('Please input single value!');
    return;
end

map.opacity = max(0.0, min(1.0, map.opacity));

set(handles.psdtopoaxes, 'userdata',map);
topomap;


% --------------------------------------------------------------------
function menu_surface_Callback(hObject, eventdata, handles)
% hObject    handle to menu_surface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
map = get(handles.psdtopoaxes, 'userdata');
ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    map.surface = 0;
else
    ischecked = 'on';
    map.surface = 1;
end

set(handles.psdtopoaxes, 'userdata',map);
set(hObject,'checked',ischecked);
topomap;



% --------------------------------------------------------------------
function menu_capimg_Callback(hObject, eventdata, handles)
% hObject    handle to menu_capimg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.psdtopoaxes, 'Spectrum Mapping Image of Cortical ECoG');

