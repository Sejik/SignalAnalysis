function varargout = epochanalysis(varargin)
% epochanalysis - analyze epochs extracted from event-related potential/field recordings
% 
% Usage: ECOM = epochanalysis(EPOCH);
%             or call epochanalysis(EPOCH) to start the popup window with EPOCH structure. 
%
% Input: EPOCH - is a structure storing the epochs extracted from event-related potential/field recordings.  
%
% Output: ECOM - is an EEG/ECoG/MEG structure storing the data generated by epoch analysis.
%
% Epoch analysis includes baseline correction, linear detrending, artifact rejection and averaging. 
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
% Yakang Dai, 08-Feb-2011 16:23:30
% Support MEG
%
% Yakang Dai, 06-Jul-2010 18:30:30
% Release Version 1.0
%
% ========================================== 


% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @epochanalysis_OpeningFcn, ...
                   'gui_OutputFcn',  @epochanalysis_OutputFcn, ...
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


% --- Executes just before epochanalysis is made visible.
function epochanalysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to epochanalysis (see VARARGIN)

% Choose default command line output for epochanalysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes epochanalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);
set(hObject,'Toolbar','none');
set(hObject,'Menubar','none');
axes(handles.mainaxes);
set(handles.mainaxes,'color',get(hObject,'color'));

if length(varargin) ~= 1
    warndlg('Input arguments mismatch!');
    return;
end

EPOCH = varargin{1};
if isempty(EPOCH)
    warndlg('Input EPOCH is empty!'); 
    return;
end

set(hObject,'name',['Epoch Analysis - ' EPOCH.event]);

nbtrials = EPOCH.nbtrials;

% set the slider for navigating the epochs
trials = [1, nbtrials];
currenttrial = 1;
sliderstep = 1/(trials(2)-trials(1));
set(handles.slider_trials,'min',trials(1),'max',trials(2),'sliderstep',[sliderstep sliderstep],'value',currenttrial);
    
set(handles.textTotal,'string', ['Total Epochs: ' num2str(nbtrials)]);
set(handles.textPresent,'string',['Present Epoch: ' num2str(currenttrial)]);
set(handles.textStatus,'string','Status: Kept');
setappdata(hObject,'EPOCH',EPOCH);
options.spacing = 1;
options.scale = 1;
options.kept = 1:EPOCH.nbtrials;
options.currentpoint = 1;
options.currentchannel = 1;
options.left = 1;
options.right = EPOCH.points;
setappdata(hObject,'options',options);
setappdata(hObject,'ECOM',[]);
updatewindow;

set(hObject,'WindowButtonDownFcn', @mousebuttondownCallback); 
set(hObject,'windowbuttonmotionfcn', @mousemotionCallback);
set(hObject,'WindowScrollWheelFcn', @mousescrollwheelCallback);

uiwait(hObject);% To block OutputFcn so that let other callbacks to generate values.


% --- Outputs from this function are returned to the command line.
function varargout = epochanalysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
varargout{1} = getappdata(hObject, 'ECOM');
delete(hObject);


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1


% --- Executes on slider movement.
function slider_trials_Callback(hObject, eventdata, handles)
% hObject    handle to slider_trials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
currenttrial = round(get(hObject,'value'));
set(handles.textPresent,'string',['Present Epoch: ' num2str(currenttrial)]);
hfig = gcf; 
options = getappdata(hfig,'options');
if options.kept(currenttrial)
    status = 'Status: Kept';
else
    status = 'Status: Rejected';
end
set(handles.textStatus,'string',status);
updatewindow;

% --- Executes during object creation, after setting all properties.
function slider_trials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_trials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pb_reject.
function pb_reject_Callback(hObject, eventdata, handles)
% hObject    handle to pb_reject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currenttrial = round(get(handles.slider_trials,'value'));
hfig = gcf; 
options = getappdata(hfig,'options');
options.kept(currenttrial) = 0;
status = 'Status: Rejected';
set(handles.textStatus,'string',status);
setappdata(hfig,'options',options);
updatewindow;

% --- Executes on button press in pb_keep.
function pb_keep_Callback(hObject, eventdata, handles)
% hObject    handle to pb_keep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currenttrial = round(get(handles.slider_trials,'value'));
hfig = gcf; 
options = getappdata(hfig,'options');
options.kept(currenttrial) = 1;
status = 'Status: Kept';
set(handles.textStatus,'string',status);
setappdata(hfig,'options',options);
updatewindow;

% --- Executes on button press in pb_auto.
function pb_auto_Callback(hObject, eventdata, handles)
% hObject    handle to pb_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf; 
EPOCH = getappdata(hfig,'EPOCH');
unit = EPOCH.unit;
line1 = ['Enter the minimal allowed amplitude (' num2str(unit) ')'];
line2 = ['Enter the maximal allowed amplitude (' num2str(unit) ')'];
prompt = {line1, line2};
dlg_title = 'Correct with minimal and maximal allowed amplitude';
num_lines = 1;
def = {'-30','30'};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

minV = str2num(answer{1});
maxV = str2num(answer{2});

options = getappdata(hfig,'options');
if isempty(minV) | isempty(maxV)
    warndlg('Input must be numeric!');
    return;
end
for i = 1:EPOCH.nbtrials
    data = EPOCH.data{i};
    maxdata = max(max(data));
    mindata = min(min(data));
    if mindata<minV | maxdata>maxV
        options.kept(i) = 0;
    else
        options.kept(i) = 1;
    end
end
setappdata(hfig,'options',options);
updatewindow;


% --- Executes on button press in pb_avg.
function pb_avg_Callback(hObject, eventdata, handles)
% hObject    handle to pb_avg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf; 
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
data = zeros(EPOCH.nbchan,EPOCH.points);
total = 0;
for i = 1:EPOCH.nbtrials
    if options.kept(i)
        total = total+1;
        data = data+EPOCH.data{i};
    end
end
data = data / total;

% build averaged ERP/ERF
ECOM = ecom_initialize;
ECOM.name = EPOCH.name;
ECOM.type = EPOCH.type;
ECOM.nbchan = EPOCH.nbchan;
ECOM.points = EPOCH.points;
ECOM.unit = EPOCH.unit;
ECOM.srate = EPOCH.srate;
ECOM.labeltype = EPOCH.labeltype;
ECOM.labels = EPOCH.labels;
ECOM.locations  = EPOCH.locations;
ECOM.data = data;
ECOM.vidx = EPOCH.vidx;
ECOM.event = EPOCH.event;
ECOM.min = min(min(ECOM.data));
ECOM.max = max(max(ECOM.data));
if isequal(upper(EPOCH.type),'ECOG')
    ECOM.size = EPOCH.size;
end
setappdata(hfig,'ECOM',ECOM);
pb_avgerp_Callback;


% --- Executes on button press in pb_avgerp.
function pb_avgerp_Callback(hObject, eventdata, handles)
% hObject    handle to pb_avgerp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
ECOM = getappdata(hfig,'ECOM');
if isempty(ECOM)
    helpdlg('There is no averaged ERP/ERF!');
    return;
end

hfignew = figure('name',['Averaged ERP/ERF - ' ECOM.name],'NumberTitle','off');
haxes = axes;
set(haxes,'color',get(hfignew,'color'));

xlimit = ECOM.points;                  
xlabelstep = round(xlimit/10);% only display 10 labels in x axis.

EPOCH = getappdata(hfig,'EPOCH');

% x labels
% xlabelpositions = [0:xlabelstep:xlimit];
xlabelpositions = [1:xlabelstep:xlimit];
xlabels = (xlabelpositions-EPOCH.origin) ./ ECOM.srate;
xlabels = num2str(xlabels');
     
% y labels
channelmaxs = max(ECOM.data');
channelmins = min(ECOM.data');
spacing = mean(channelmaxs-channelmins);  
ylimit = (ECOM.nbchan+1)*spacing;
ylabelpositions = [0:spacing:ECOM.nbchan*spacing];    
YLabels = ECOM.labels;
YLabels = strvcat(YLabels); 
YLabels = flipud(str2mat(YLabels,' '));

set(haxes,...
      'Xlim',[0 xlimit],...
      'xtick',xlabelpositions,...% where to display the labels.
      'Ylim',[0 ylimit],...
      'YTick',ylabelpositions,...
      'YTickLabel', YLabels,...
      'XTickLabel', xlabels); % the labels to be displayed
  
axes(haxes);     
xlabel('Second');
cla;        
hold on;

tmpcolor = [0.0,0.0,1.0];
for i = 1:ECOM.nbchan
    chan = ECOM.nbchan-i+1;
    plot(ECOM.data(chan,:)+i*spacing,'color', tmpcolor, 'clipping','on');
end

% draw the line indicating the stimulation time
xpos = [EPOCH.origin, EPOCH.origin];
ypos = [0, ylimit];
plot(xpos, ypos, '--', 'EraseMode', 'xor', 'color', [0,0,0]);
text(double(xpos(2)), double(ypos(2)),EPOCH.event, 'HorizontalAlignment','center','VerticalAlignment','bottom','Color',[0 0 0],'FontWeight','bold','FontSize',12);

axis on;
box on;

% --- Executes on button press in pb_ok.
function pb_ok_Callback(hObject, eventdata, handles)
% hObject    handle to pb_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(gcf);

% --- Executes on button press in pb_cancel.
function pb_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pb_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
setappdata(hfig,'ECOM',[]);
uiresume(hfig);


% --------------------------------------------------------------------
function updatewindow()
hfig = gcf; 
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
if isempty(EPOCH)
    return;
end

mainaxes = findobj(hfig, 'tag','mainaxes'); 
slider_trials = findobj(hfig,'tag','slider_trials');
if isempty(mainaxes)
    return;
end

xlimit = EPOCH.points;               
xlabelstep = round(xlimit/10);% only display 10 labels in x axis.

% x labels
% xlabelpositions = [0:xlabelstep:xlimit];
xlabelpositions = [1:xlabelstep:xlimit];
xlabels = (xlabelpositions-EPOCH.origin) ./ EPOCH.srate;
xlabels = num2str(xlabels');
     
currenttrial = round(get(slider_trials,'value'));
set(slider_trials,'value',currenttrial);
data = EPOCH.data{currenttrial};

% y labels
channelmaxs = max(data');
channelmins = min(data');
spacing = mean(channelmaxs-channelmins);  
ylimit = (EPOCH.nbchan+1)*spacing;
ylabelpositions = [0:spacing:EPOCH.nbchan*spacing];    
YLabels = EPOCH.labels;
YLabels = strvcat(YLabels); 
YLabels = flipud(str2mat(YLabels,' '));

set(mainaxes,...
      'Xlim',[0 xlimit],...
      'xtick',xlabelpositions,...% where to display the labels.
      'Ylim',[0 ylimit],...
      'YTick',ylabelpositions,...
      'YTickLabel', YLabels,...
      'XTickLabel', xlabels); % the labels to be displayed
  
axes(mainaxes);     
xlabel('Second');
cla;        
hold on;

if options.kept(currenttrial)
    tmpcolor = [0.0,0.0,1.0];
else
    tmpcolor = [0.8,0.0,0.0];
end

data = EPOCH.data{currenttrial};
for i = 1:EPOCH.nbchan
    chan = EPOCH.nbchan-i+1;
    
    meandata = mean(data(chan,:));
    displaydata = data(chan,:) - meandata;
    plot(options.scale*displaydata+i*spacing,'color', tmpcolor, 'clipping','on');    
    
    % plot(options.scale*data(chan,:)+i*spacing,'color', tmpcolor, 'clipping','on');
end 

% draw the line indicating the stimulation time
xpos = [EPOCH.origin, EPOCH.origin];
ypos = [0, ylimit];
plot(xpos, ypos, '--', 'EraseMode', 'xor', 'color', [0,0,0]);
% label the text for the stimulation time
text(double(xpos(2)), double(ypos(2)),EPOCH.event, 'HorizontalAlignment','center','VerticalAlignment','bottom','Color',[0 0 0],'FontWeight','bold','FontSize',12);

% draw the left and right lines
xpos = [options.left, options.left]; % left line
leftline = findobj(hfig,'tag','leftline');
if isempty(leftline)
    plot(xpos, ypos, '--', 'EraseMode', 'xor', 'color', [0,0,1],'tag','leftline');
else
    set(leftline,'xdata',xpos,'ydata',ypos);
end
xpos = [options.right, options.right]; % right line
rightline = findobj(hfig,'tag','rightline');
if isempty(rightline)
    plot(xpos, ypos, '--', 'EraseMode', 'xor', 'color', [1,0,0],'tag','rightline');
else
    set(rightline,'xdata',xpos,'ydata',ypos);
end

options.spacing = spacing;
setappdata(hfig,'options',options);


%--------------------------------------------------------------------------
function mousemotionCallback(src, evnt) 
hfig = gcf;
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
mainaxes = findobj(hfig,'tag','mainaxes'); 
textChannel = findobj(hfig,'tag','textChannel');
textTime = findobj(hfig,'tag','textTime');
textValue = findobj(hfig,'tag','textValue');
slider_trials = findobj(hfig,'tag','slider_trials');
if isempty(mainaxes) | isempty(EPOCH) | isempty(options)
    return;
end

currentxlim = get(mainaxes, 'Xlim');
currentylim = get(mainaxes, 'Ylim');
mousepos = get(mainaxes, 'currentpoint');

% if the mouse is not in the viewing window.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
     return;
end

currenttrial = get(slider_trials,'value');
data = EPOCH.data{currenttrial};

currentpoint = round(mousepos(1,1));
currentpoint = max(1,min(currentpoint,EPOCH.points));

% update the channel information
currenttime = (currentpoint-EPOCH.origin) / EPOCH.srate;
currentchannel = round( (currentylim(1,2) - mousepos(1,2) ) / options.spacing);%find the nearest channel.
if currentchannel < 1 | currentchannel > EPOCH.nbchan
     return;
end
currentvalue = data(currentchannel, currentpoint);
set(textChannel,'string', ['Channel: ' EPOCH.labels{currentchannel}]);
set(textTime,'string', ['Time: ' num2str(currenttime) ' s']);
set(textValue,'string', ['Value: ' num2str(currentvalue) ' ' EPOCH.unit]);

% update the pointer
i = EPOCH.nbchan - currentchannel + 1;
x = currentpoint;
currentvalue = currentvalue - mean(data(currentchannel,:));
y = currentvalue*options.scale+i*options.spacing;
pointhandle = findobj(hfig,'tag','pointhandle');
if isempty(pointhandle)
    plot(x,y,'mo','MarkerFaceColor',[0.49,1.0,0.63],'MarkerSize',8,'EraseMode', 'xor','tag', 'pointhandle');
else
    set(pointhandle,'xdata',x,'ydata',y);
    drawnow;
end


%--------------------------------------------------------------------
function mousescrollwheelCallback(src, evnt)
hfig = gcf;
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
        
mainaxes = findobj(hfig,'tag','mainaxes'); 
if isempty(mainaxes)
    return;
end
     
currentxlim = get(mainaxes, 'Xlim');
currentylim = get(mainaxes, 'Ylim');
mousepos = get(mainaxes, 'currentpoint');
     
% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
   mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
       return;
end

if isempty(EPOCH) | isempty(EPOCH.data)
    return;
end

if evnt.VerticalScrollCount < 0 
    options.scale = options.scale + 0.25;
elseif evnt.VerticalScrollCount > 0
    options.scale = options.scale - 0.25;
    if options.scale < 0
        return;
    end
end
setappdata(hfig,'options',options);
updatewindow;    
   

% --------------------------------------------------------------------
function mousebuttondownCallback(src, evnt)
hfig = gcf;
mainaxes = findobj(hfig,'tag','mainaxes'); 
if isempty(mainaxes)
    return;
end

currentxlim = get(mainaxes, 'Xlim');
currentylim = get(mainaxes, 'Ylim');
mousepos = get(mainaxes, 'currentpoint');
     
% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
   mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
       return;
end

EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
currentpoint = round(mousepos(1,1));
currentpoint = max(1,min(currentpoint,EPOCH.points));
options.currentpoint = currentpoint;
options.currentchannel = round( (currentylim(1,2) - mousepos(1,2) ) / options.spacing);%find the nearest channel.
setappdata(hfig,'options',options);

selectype = lower(get(hfig,'SelectionType'));

% 'alt': right click - show the popup menu
if strcmp(selectype,'alt')    
    popmenu_mainaxes = findobj(hfig,'tag','popmenu_mainaxes');
    position = get(hfig,'CurrentPoint');
    set(popmenu_mainaxes,'position',position);
    set(popmenu_mainaxes,'Visible','on');
    return;
end 


% --------------------------------------------------------------------
function menu_start_Callback(hObject, eventdata, handles)
% hObject    handle to menu_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
mainaxes = findobj(hfig,'tag','mainaxes'); 
if isempty(mainaxes)
    return;
end
ypos = get(mainaxes, 'Ylim');

options = getappdata(hfig,'options');
options.left = options.currentpoint;

% xpos = [options.left, options.left];
% leftline = findobj(hfig,'tag','leftline');
% if isempty(leftline)
%     plot(xpos, ypos, '--', 'EraseMode', 'xor', 'color', [0,0,1],'tag','leftline');
% else
%     set(leftline,'xdata',xpos,'ydata',ypos);
%     drawnow;
% end

setappdata(hfig,'options',options);
updatewindow;

% --------------------------------------------------------------------
function menu_end_Callback(hObject, eventdata, handles)
% hObject    handle to menu_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
mainaxes = findobj(hfig,'tag','mainaxes'); 
if isempty(mainaxes)
    return;
end
ypos = get(mainaxes, 'Ylim');

options = getappdata(hfig,'options');
options.right = options.currentpoint;

% xpos = [options.right, options.right];
% rightline = findobj(hfig,'tag','rightline');
% if isempty(rightline)
%     plot(xpos, ypos, '--', 'EraseMode', 'xor', 'color', [1,0,0],'tag','rightline');
% else
%     set(rightline,'xdata',xpos,'ydata',ypos);
%     drawnow;
% end

setappdata(hfig,'options',options);
updatewindow;


% --------------------------------------------------------------------
function menu_baseline_Callback(hObject, eventdata, handles)
% hObject    handle to menu_baseline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
ct = 0;
h = waitbar(0,'Correcting Baseline, please wait...');
for i = 1:EPOCH.nbtrials
    data = EPOCH.data{i};
    base = mean(data(:,options.left:options.right),2);
    for j = 1:EPOCH.nbchan
        data(j,:) = data(j,:)-base(j);
    end
    EPOCH.data{i}=data;
    ct = ct + 1; 
    if ~mod(ct, 10)
       waitbar(ct/EPOCH.nbtrials);
    end
end
close(h);
setappdata(hfig,'EPOCH',EPOCH);
updatewindow;


% --------------------------------------------------------------------
function menu_detrend_Callback(hObject, eventdata, handles)
% hObject    handle to menu_detrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
ct = 0;
h = waitbar(0,'Linear Detrending, please wait...');
xa = 1:EPOCH.points;
for i = 1:EPOCH.nbtrials
    data = EPOCH.data{i};
    
    for j = 1:EPOCH.nbchan
        % data(j,options.left:options.right) = detrend(data(j,options.left:options.right));
        x = options.left:options.right;
        y = data(j,options.left:options.right);
        p = polyfit(x,y,1);
        data(j,:) = data(j,:) - polyval(p,xa);
    end
    EPOCH.data{i}=data;
    ct = ct + 1; 
    if ~mod(ct, 10)
       waitbar(ct/EPOCH.nbtrials);
    end
end
close(h);
setappdata(hfig,'EPOCH',EPOCH);
updatewindow;


% --------------------------------------------------------------------
function popmenu_mainaxes_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu_mainaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_default_Callback(hObject, eventdata, handles)
% hObject    handle to menu_default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
options.left = 1;
options.right = EPOCH.points;
setappdata(hfig,'options',options);
updatewindow;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
setappdata(hObject, 'ECOM', []);
uiresume(hObject);
% delete(hObject);


% --- Executes on button press in pb_erders.
function pb_erders_Callback(hObject, eventdata, handles)
% hObject    handle to pb_erders (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf; 
EPOCH = getappdata(hfig,'EPOCH');

% get parameters
line1 = 'Enter baseline time interval, begin end (s):';
line2 = 'Enter task time interval, begin end (s):';
line3 = 'Enter frequency time interval, low high (Hz):';
prompt = {line1, line2, line3};
dlg_title = 'Time-frequency Intervals for ERD/ERS';
num_lines = 1;
baseline = ([1, EPOCH.origin]-EPOCH.origin) / EPOCH.srate;
task = ([EPOCH.origin, EPOCH.points]-EPOCH.origin) / EPOCH.srate;
frequency = [8,12];
def = {num2str(baseline), num2str(task), num2str(frequency)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end
baseline = str2num(answer{1});
task = str2num(answer{2});
frequency = str2num(answer{3});
if isempty(baseline) | isempty(task) | isempty(frequency)
    return;
end

% frequency interval
if length(frequency) ~= 2
    return;
else
    frequency = round(frequency);
    if frequency(2)<=frequency(1) | frequency(1)<1
        return;
    end
        frequency(1) = max(min(frequency(1), round(EPOCH.srate/2)), 1);
        frequency(2) = max(min(frequency(2), round(EPOCH.srate/2)), 1);
end
freqVec = frequency(1) : frequency(2);

% baseline interval
baseline = round(baseline*EPOCH.srate+EPOCH.origin);
if length(baseline) == 1
    basepoint = max(min(baseline, EPOCH.points), 1);
elseif length(baseline) == 2
    if baseline(2) <= baseline(1)
        return;
    end
    baseline(1) =  max(min(baseline(1), EPOCH.points), 1);
    baseline(2) =  max(min(baseline(2), EPOCH.points), 1);
    basepoint = baseline(1):baseline(2); % point in ts
else
    return;
end
    
% task interval
task = round(task*EPOCH.srate+EPOCH.origin);
if length(task) == 1
    taskpoint = max(min(task, EPOCH.points), 1);
elseif length(task) == 2
    if task(2) <= task(1)
        return;
    end
    task(1) =  max(min(task(1), EPOCH.points), 1);
    task(2) =  max(min(task(2), EPOCH.points), 1);
    taskpoint = task(1):task(2); % point in ts
else
    return;
end

% compute ERD/ERS
options = getappdata(hfig,'options');
ptask = zeros(EPOCH.nbchan,1);
pbase = zeros(EPOCH.nbchan,1);
total = 0;
ct = 0;
h = waitbar(0,'ERD/ERS Computation, please wait...');
for i = 1:EPOCH.nbtrials
    if options.kept(i)
        total = total+1;
        data = EPOCH.data{i};
        
        for j = 1:EPOCH.nbchan
            ts = data(j,:);
            TFR = morletTFR(ts,freqVec,EPOCH.srate,7); 
            ptask(j) = ptask(j)+ mean(mean(TFR(:,taskpoint)));
            pbase(j) = pbase(j) + mean(mean(TFR(:,basepoint)));        
        end
    end
    ct = ct + 1; 
    if ~mod(ct, 5)
       waitbar(ct/EPOCH.nbtrials);
    end
end
waitbar(1);
close(h);
ptask = ptask/total;
pbase = pbase/total;
ErdErs = (ptask - pbase) ./ pbase;

% newfig = figure('name','ERD/ERS Mapping');

ERDS = ecom_initialize;
ERDS.name = EPOCH.name;
ERDS.type = EPOCH.type;
ERDS.nbchan = EPOCH.nbchan;
ERDS.labeltype = EPOCH.labeltype;
ERDS.labels = EPOCH.labels;
ERDS.locations  = EPOCH.locations;
ERDS.data = ErdErs;
ERDS.points = 1;
ERDS.vidx = EPOCH.vidx;
if isequal(upper(EPOCH.type),'ECOG')
    ERDS.size = EPOCH.size;
end
displaymap(ERDS,'ERD/ERS Mapping');


% --------------------------------------------------------------------
function menu_tf_Callback(hObject, eventdata, handles)
% hObject    handle to menu_tf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EPOCH = getappdata(hfig,'EPOCH');
options = getappdata(hfig,'options');
slider_trials = findobj(hfig,'tag','slider_trials');
     
currenttrial = round(get(slider_trials,'value'));
set(slider_trials,'value',currenttrial);
data = EPOCH.data{currenttrial};
ts = data(options.currentchannel,:);
channelname = EPOCH.labels{options.currentchannel};

starttime = (1-EPOCH.origin)/EPOCH.srate;
pos1 = get(hfig,'CurrentPoint');
pos2 = get(hfig,'position');
pos = pos1 + pos2(1:2);

% compute and visualize time-frequency
time_frequency(ts, EPOCH.srate, starttime, pos, channelname);