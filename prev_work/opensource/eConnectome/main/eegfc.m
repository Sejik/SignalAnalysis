function varargout = eegfc(varargin)
% eegfc - the main Graphical User Interface (GUI) environment 
%  for processing and imaging of cortical sources and brain functional connectivity from EEG
%
% Authors: 
%  Bin He, Yakang Dai, Lin Yang, and Han Yuan at the University of Minnesota, USA, 
%  with substantial contributions from Fabio Babiloni and Laura Astolfi 
%  at the University of Rome "La Sapienza", Italy, plus addition contributions 
%  from Christopher Wilke at the University of Minnesota, USA. 
% 
% Usage: 
%     1. type
%         >> eegfc
%        or call eegfc to start the popup GUI
%       
%     2. type 
%         >> eegfc(EEG)
%         or call eegfc(EEG) to start the popup GUI with EEG structure. 
%         The EEG structure should be pre-exported by the eegfc GUI 
%         or made by 
%         >> EEG = pop_txtreader  
%         or
%         >> EEG = pop_matreader
%         Please see the eConnectome Manual 
%         (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%         for details about the import EEG file formats (TXT and MAT) recognized by the software.
%           
%      3. call eegfc from the main econnectome GUI ('Menu bar -> EEG')
%
% Description:
%  eegfc is the main GUI for EEG functional connectivity. Multi-channel EEG 
% data can be imported for pre-processing and analyzing including ERP analysis, electrodes 
% co-registration, bad channel rejection, baseline correction, de-trending, and 
%  band-pass filtering and 60/50 Hz notch filtering. Potential and spectrum maps 
% over a generic realistic geometry scalp can be constructed and visualized. 
%  Time-frequency representations of time series can be calculated and visualized. 
% The Directed Transfer Function (DTF) and Adaptive DTF (ADTF) among all channels can be computed and 
% visualized over a spherical surface or a generic realistic geometry scalp, including 
% inflow, outflow, and connectivity patterns of all or selected channels over selected 
% frequency components. Cortical source distributions can also be estimated and 
% visualized. Finally functional connectivity patterns including inflow, outflow and 
% connectivity can be computed and visualized from the estimated cortical
% source 
% waveforms, based on Brodmann areas or user defined regions of interest.
%
% Reference for eConnectome (please cite): 
% B. He, Y. Dai, L. Astolfi, F. Babiloni, H. Yuan, L. Yang. 
% eConnectome: A MATLAB Toolbox for Mapping and Imaging of Brain Functional Connectivity. 
% Journal of Neuroscience Methods. 195:261-269, 2010
%
% Reference for eegfc() (please cite):
% F. Babiloni, F. Cincotti, C. Babiloni, F. Carducci, D. Mattia, L. Astolfi, A. Basilisco, P. M. Rossini, 
% L. Ding, Y. Ni, J. Cheng, K. Christine, J. Sweeney, B. He. Neuroimage. 2005 Jan 1;24(1):118-31. 
% Estimation of the cortical functional connectivity with the multimodal integration of high-resolution 
%  EEG and fMRI data by directed transfer function.
%
% Reference for ADTF function, (please cite) 
% C. Wilke, L. Ding, B. He, 
% Estimation of time-varying connectivity patterns through the use of an adaptive directed transfer function. 
% IEEE Trans Biomed Eng. 2008 Nov; 55(11):2557-64.
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
% New functions: scale waveforms, capture image, 
% record and play movie
%
% Yakang Dai, 03-May-2010 14:54:30
% Can use good channels only without interpolation
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ========================================== 

% --- Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @eegfc_OpeningFcn, ...
                   'gui_OutputFcn',  @eegfc_OutputFcn, ...
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
% --- End initialization code - DO NOT EDIT


% --- Executes just before eegfc is made visible.
function eegfc_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to eegfc (see VARARGIN)

% Choose default command line output for eegfc
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes eegfc wait for user response (see UIRESUME)
% uiwait(handles.mainGUI);

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

if length(varargin) > 1
    warndlg('Too many arguments inputed!');
end

bkgclr = get(handles.uipanelinfo,'backgroundcolor');
set(handles.listbox,'backgroundcolor',bkgclr);
set(hObject,'color',bkgclr);
axes(handles.mainaxes);
set(handles.mainaxes,'color',get(hObject,'color'));

EEG = [];
ALLEEG.total = 0;
CURRENT = 0;
ischanged = 0;
scale = 1;

if  length(varargin) == 1
    EEG = varargin{1};
    if ~isempty(EEG) && ~isempty(EEG.data)
        if ~isfield(EEG,'name')
            EEG.name = 'UnTitledEEG';
        end
        ALLEEG.eegdata(ALLEEG.total+1) = {EEG};
        ALLEEG.document(ALLEEG.total+1) = {EEG.name};
        ALLEEG.total = ALLEEG.total + 1;
        set(handles.listbox,'String',ALLEEG.document,'value',ALLEEG.total);
        CURRENT = ALLEEG.total;
        ischanged = 1;
    else
        EEG = [];
        errordlg('Input EEG data is empty!');
    end
end
setappdata(hObject,'EEG',EEG);
setappdata(hObject,'ALLEEG',ALLEEG);
setappdata(hObject,'CURRENT',CURRENT);
setappdata(hObject,'SCALE', scale);

setappdata(hObject, 'current',1);
initwindow;

% Plot the head
model.skin = load('italyskin.mat');
model.italyskinxy = load('italyskin-in-xy.mat');
model.italyskinxyz = load('italyskin-in-xyz.mat');
setappdata(hObject,'model',model);

options.electrode = 0;
options.label = 0;
if isempty(EEG)
    options.epochstart = 0;
    options.epochend = 0;
    starttime = 0;
    endtime = 0;
else
    options.epochstart = 1;
    options.epochend = EEG.points;
    starttime = options.epochstart / EEG.srate;
    endtime = options.epochend / EEG.srate;
end
options.caxis = 'local';
setappdata(hObject,'options',options);
set(handles.epochstart,'string',num2str(starttime));
set(handles.epochend,'string',num2str(endtime));

axes(handles.tstopoaxes);
set(handles.tstopoaxes, 'DataAspectRatio',[1 1 1]);
box off;
axis off;
% axis vis3d;
cla;
hold on;
drawhead;

setappdata(hObject,'ischanged',ischanged);

resolution = 50;
setappdata(hObject, 'resolution',resolution);

set(hObject,'windowbuttonmotionfcn', @mousemotionCallback);
set(hObject,'WindowButtonDownFcn', @mousebuttondownCallback); 
set(hObject,'WindowScrollWheelFcn', @mousescrollwheelCallback);

% --- Outputs from this function are returned to the command line.
function varargout = eegfc_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --------------------------------------------------------------------
function file_Callback(hObject, eventdata, handles)
% hObject    handle to file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function filter_Callback(hObject, eventdata, handles)
% hObject    handle to filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function import_Callback(hObject, eventdata, handles)
% hObject    handle to import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function source_Callback(hObject, eventdata, handles)
% hObject    handle to source (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function roi_Callback(hObject, eventdata, handles)
% hObject    handle to roi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function connectivity_Callback(hObject, eventdata, handles)
% hObject    handle to connectivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function topography_Callback(hObject, eventdata, handles)
% hObject    handle to topography (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes when user attempts to close MainGUI.
function MainGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to MainGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);

% --- Executes during object creation, after setting all properties.
function MainGUI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MainGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function editepochstart_Callback(hObject, eventdata, handles)
% hObject    handle to editepochstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editepochstart as text
%        str2double(get(hObject,'String')) returns contents of editepochstart as a double


% --- Executes during object creation, after setting all properties.
function editepochstart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editepochstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editepochend_Callback(hObject, eventdata, handles)
% hObject    handle to editepochend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editepochend as text
%        str2double(get(hObject,'String')) returns contents of editepochend as a double


% --- Executes during object creation, after setting all properties.
function editepochend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editepochend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonepoch.
function pushbuttonepoch_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonepoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function channelstodisplay_Callback(hObject, eventdata, handles)
% hObject    handle to channelstodisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of channelstodisplay as text
%        str2double(get(hObject,'String')) returns contents of channelstodisplay as a double


% --- Executes during object creation, after setting all properties.
function channelstodisplay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelstodisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in whichtimeleft.
function whichtimeleft_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
     

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

% the region for displaying
 xlow = axisdata.xlow - axisdata.xlabelstep;
 xhigh = axisdata.xhigh - axisdata.xlabelstep;

 % to the end of the eeg frames, do nothing
 if xhigh <=1
     msgbox('Reach the left end of the EEG data!','','help','modal');
     return;
 end

 if xlow <1 
     xlow = 1;
     xhigh = axisdata.xlimit;
 end 

axisdata.xlow = xlow;
axisdata.xhigh = xhigh;

set(handles.mainaxes, 'userdata',axisdata);
updatewindow;
     
% --- Executes on button press in whichtimelefter.
function whichtimelefter_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimelefter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

 axisdata = get(handles.mainaxes, 'userdata');

 xlow = axisdata.xlow - axisdata.xlimit;
 xhigh = axisdata.xhigh - axisdata.xlimit;

 % to the end of the eeg frames, do nothing
 if xhigh <=1
     msgbox('Reach the left end of the EEG data!','','help','modal');
     return;
 end

 if xlow <1 
     xlow = 1;
     xhigh = axisdata.xlimit;
 end

axisdata.xlow = xlow;
axisdata.xhigh = xhigh;

set(handles.mainaxes, 'userdata',axisdata);
updatewindow;

% --- Executes on button press in whichtimeright.
function whichtimeright_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
 
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

% the region for displaying
 xlow = axisdata.xlow + axisdata.xlabelstep;
 xhigh = axisdata.xhigh + axisdata.xlabelstep;

 % to the end of the eeg frames, do nothing
 if xlow >= EEG.points
     msgbox('Reach the right end of the EEG data!','','help','modal');
     return;
 end

 if xhigh > EEG.points 
     xhigh = EEG.points;
     xlow = EEG.points - axisdata.xlimit + 1;
 end

axisdata.xlow = xlow;
axisdata.xhigh = xhigh;

set(handles.mainaxes, 'userdata',axisdata);
updatewindow;     

% --- Executes on button press in whichtimerighter.
function whichtimerighter_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimerighter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
 
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

% the region for displaying
 xlow = axisdata.xlow + axisdata.xlimit;
 xhigh = axisdata.xhigh + axisdata.xlimit;

 % to the end of the eeg frames, do nothing
 if xlow >= EEG.points
     msgbox('Reach the right end of the EEG data!','','help','modal');
     return;
 end

 if xhigh > EEG.points 
     xhigh = EEG.points;
     xlow = EEG.points - axisdata.xlimit + 1;
 end

axisdata.xlow = xlow;
axisdata.xhigh = xhigh;

set(handles.mainaxes, 'userdata',axisdata);
updatewindow;     

% --- Executes on button press in whichchannelszoomin.
function whichchannelszoomin_Callback(hObject, eventdata, handles)
% hObject    handle to whichchannelszoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

if EEG.dispchans == 1
    msgbox('Reach the max zoom!','','help','modal');
    return;
end

if EEG.dispchans - 4 < 1
    EEG.dispchans = 1;
else
    EEG.dispchans = EEG.dispchans - 4;
end

EEG.end = EEG.start + EEG.dispchans - 1;
set(handles.channelstodisplay, 'string', num2str(EEG.dispchans));
setappdata(gcf,'EEG',EEG);

updatewindow;        

% --- Executes on button press in whichchannelszoomout.
function whichchannelszoomout_Callback(hObject, eventdata, handles)
% hObject    handle to whichchannelszoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
 
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

if EEG.dispchans == EEG.nbchan
    msgbox('Reach the min zoom!','','help','modal');
    return;
end

if EEG.dispchans + 4 > EEG.nbchan
    EEG.dispchans = EEG.nbchan;
else
    EEG.dispchans = EEG.dispchans + 4;
end

% if start is 1, then extend from 1,
% if start is more than 1, then extend from end.
if EEG.start == 1
    EEG.end = EEG.start + EEG.dispchans - 1;
else
    EEG.start = EEG.end - EEG.dispchans + 1;
end

set(handles.channelstodisplay, 'string', num2str(EEG.dispchans));
setappdata(gcf,'EEG',EEG);

updatewindow;     

% --- Executes on button press in whichtimeleftest.
function whichtimeleftest_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleftest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
    
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

axisdata.xlow = 1;
axisdata.xhigh = axisdata.xlimit;
set(handles.mainaxes, 'userdata',axisdata);
updatewindow;     

% --- Executes on button press in whichtimerightest.
function whichtimerightest_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimerightest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
    
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

axisdata.xhigh = EEG.points;
axisdata.xlow = EEG.points - axisdata.xlimit + 1;
set(handles.mainaxes, 'userdata',axisdata);
updatewindow;            

% --- Executes on button press in whichtimeleftauto.
function whichtimeleftauto_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleftauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
   
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

 xlow = axisdata.xlow - axisdata.xlabelstep;
 xhigh = axisdata.xhigh - axisdata.xlabelstep;

 % to the end of the eeg frames, do nothing
 if xhigh <=1
     msgbox('Reach the left end of the EEG data!','','help','modal');
     return;
 end

 if xlow <1 
     xlow = 1;
     xhigh = axisdata.xlimit;
 end

axisdata.xlow = xlow;
axisdata.xhigh = xhigh;
set(handles.mainaxes, 'userdata',axisdata);
updatewindow; 

 if xlow == 1 | axisdata.auto == 1
     axisdata.auto = 0;
     set(handles.mainaxes, 'userdata', axisdata);
     return;
 else
     pause(0.2);
     whichtimeleftauto_Callback(hObject, eventdata, handles);
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% --- Executes on button press in whichtimerightauto.
function whichtimerightauto_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimerightauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
    
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

 xlow = axisdata.xlow + axisdata.xlabelstep;
 xhigh = axisdata.xhigh + axisdata.xlabelstep;

 % to the end of the eeg frames, do nothing
 if xlow >= EEG.points
     msgbox('Reach the right end of the EEG data!','','help','modal');
     return;
 end

 if xhigh > EEG.points 
     xhigh = EEG.points;
     xlow = EEG.points - axisdata.xlimit + 1;
 end    

axisdata.xlow = xlow;
axisdata.xhigh = xhigh;
set(handles.mainaxes, 'userdata',axisdata);
updatewindow; 

 if xhigh == EEG.points | axisdata.auto == 1
     axisdata.auto = 0;
     set(handles.mainaxes, 'userdata', axisdata);
     return;
 else
     pause(0.2);
     whichtimerightauto_Callback(hObject, eventdata, handles);
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over whichtimeleftauto.
function whichtimeleftauto_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to whichtimeleftauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axisdata = get(handles.mainaxes, 'userdata');
axisdata.auto = 1;
set(handles.mainaxes, 'userdata', axisdata);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over whichtimerightauto.
function whichtimerightauto_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to whichtimerightauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axisdata = get(handles.mainaxes, 'userdata');
axisdata.auto = 1;
set(handles.mainaxes, 'userdata', axisdata);


% --- Executes on button press in whichchannelsup.
function whichchannelsup_Callback(hObject, eventdata, handles)
% hObject    handle to whichchannelsup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
    
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

if EEG.start == 1
    msgbox('Reach the first channel!','','help','modal');
    return;
end

if EEG.start - 4 < 1
    EEG.start = 1;
else
    EEG.start = EEG.start - 4;
end

EEG.end = EEG.start + EEG.dispchans - 1;

setappdata(gcf,'EEG',EEG);

updatewindow; 
 
% --- Executes on button press in whichchannelsdown.
function whichchannelsdown_Callback(hObject, eventdata, handles)
% hObject    handle to whichchannelsdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
    
if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

if EEG.end == EEG.nbchan
    msgbox('Reach the last channel!','','help','modal');
    return;
end

if EEG.end + 4 > EEG.nbchan
    EEG.end = EEG.nbchan;
else
    EEG.end = EEG.end + 4;
end

EEG.start = EEG.end - EEG.dispchans + 1;  

setappdata(gcf,'EEG',EEG);

updatewindow;  

function mousemotionCallback(src, evnt) 

hfig = gcf;

EEG = getappdata(hfig,'EEG');
scale = getappdata(hfig,'SCALE');

if isempty(EEG) | isempty(EEG.data)
	return;
end

mainaxes = findobj(hfig,'tag','mainaxes'); 
whattime = findobj(hfig,'tag','whattime');
whichpoint = findobj(hfig,'tag','whichpoint');
whichchannel = findobj(hfig,'tag','whichchannel');
whatvalue = findobj(hfig,'tag','whatvalue');

currentxlim = get(mainaxes, 'Xlim');
currentylim = get(mainaxes, 'Ylim');
mousepos = get(mainaxes, 'currentpoint');
if isempty(mousepos)
    return;
end

% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
 set(whattime, 'string', num2str(0));
 set(whichpoint, 'string', num2str(0));
 set(whichchannel, 'string', num2str(0));
 set(whatvalue, 'string', num2str(0));
 return;
end

axisdata = get(mainaxes, 'userdata');
currentpoint = round(mousepos(1,1) + axisdata.xlow-1);%find the nearest point.
if currentpoint < axisdata.xlow | currentpoint > axisdata.xhigh
 set(whattime, 'string', num2str(0));
 set(whichpoint, 'string', num2str(0));
 set(whichchannel, 'string', num2str(0));
 set(whatvalue, 'string', num2str(0));
 return;
end
currenttime = currentpoint / EEG.srate;

channelmaxs = max(EEG.data(EEG.start:EEG.end, axisdata.xlow:axisdata.xhigh)');
channelmins = min(EEG.data(EEG.start:EEG.end, axisdata.xlow:axisdata.xhigh)');
spacing = mean(channelmaxs-channelmins);
currentchannel = round( (currentylim(1,2) - mousepos(1,2) ) / spacing );%find the nearest channel.
currentchannel = currentchannel + EEG.start - 1;
if currentchannel < EEG.start | currentchannel > EEG.end
 set(whattime, 'string', num2str(0));
 set(whichpoint, 'string', num2str(0));
 set(whichchannel, 'string', num2str(0));
 set(whatvalue, 'string', num2str(0));
 return;
end

currentvalue = EEG.data(currentchannel, currentpoint);
set(whattime, 'string', [num2str(currenttime) ' s']);
set(whichpoint, 'string', num2str(currentpoint));
set( whichchannel, 'string', EEG.labels(currentchannel));
set(whatvalue, 'string', [num2str(currentvalue) ' ' EEG.unit]);

axes(mainaxes);
temppos = currentpoint - axisdata.xlow +1;
xpos = [temppos,  temppos];
ypos = [currentylim(1,1),  currentylim(1,2)];
tmpcolor = [ 0.0 1.0 0.0 ];

linehandle = findobj(hfig,'tag','linetag');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'linetag');
else
    set(linehandle,'xdata',xpos,'ydata',ypos);
    drawnow;
end

% the i th channel displayed
i = EEG.end - currentchannel + 1;
x = xpos(1);
currentvalue = currentvalue - mean(EEG.data(currentchannel,axisdata.xlow:axisdata.xhigh));
y = currentvalue*scale+i*spacing;
pointhandle = findobj(hfig,'tag','pointhandle');
if isempty(pointhandle)
    plot(x,y,'mo','MarkerFaceColor',[0.49,1.0,0.63],'MarkerSize',8,'EraseMode', 'xor','tag', 'pointhandle');
else
    set(pointhandle,'xdata',x,'ydata',y);
    drawnow;
end

function epochstart_Callback(hObject, eventdata, handles)
% hObject    handle to epochstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochstart as text
%        str2double(get(hObject,'String')) returns contents of epochstart as a double


% --- Executes during object creation, after setting all properties.
function epochstart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function epochend_Callback(hObject, eventdata, handles)
% hObject    handle to epochend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochend as text
%        str2double(get(hObject,'String')) returns contents of epochend as a double


% --- Executes during object creation, after setting all properties.
function epochend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in epochclip.
function epochclip_Callback(hObject, eventdata, handles)
% hObject    handle to epochclip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end 

clipevent = questdlg('To remove the epoch specified ?','','Yes','Cancel','Cancel');
if ~strcmp(clipevent, 'Yes')
    return;
end   

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),EEG.points);
endpoint = min(max(endpoint,1),EEG.points);

if startpoint > endpoint
    helpdlg('The epoch specification is not right!');
    return;
end

if endpoint == startpoint
    helpdlg('The epoch is too small, need 2 points at least!','','help','modal');
    return;
end

if startpoint == 1 && endpoint == EEG.points
    helpdlg('Please specify the epoch (NOT the whole EEG)!');
    return;
end

EEG.points = EEG.points - (endpoint - startpoint + 1);
EEG.data(:,startpoint:endpoint) = [];

% to smooth the joint points
r1 = 15;
r2 = 15;
if startpoint-1-r1 < 1
    r1 = startpoint-2;
end
if startpoint+r2 > EEG.points
    r2 = EEG.points-startpoint;
end
left = startpoint-1-r1;
right = startpoint+r2;
n = r1+r2+2;
y = zeros(1, n);
x = 1:n;
for i = 1:EEG.nbchan
    y(1:r1+1) = EEG.data(i,left:startpoint-1);
    y(r1+2:n) = EEG.data(i,startpoint:right);    
    p = polyfit(x,y,6);
    f = polyval(p,x); 
    EEG.data(i,left:startpoint-1) = f(1:r1+1);
    EEG.data(i,startpoint:right) = f(r1+2:n);
end

data1 = EEG.data(EEG.vidx,:);
EEG.min = min(min(data1));
EEG.max = max(max(data1));

ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

% add the new EEG data to the ALLEEG,
% and add the item into the document file. 
EEG.name = [EEG.name '_Epoch_Removed'];
ALLEEG.eegdata(ALLEEG.total+1) = {EEG};
ALLEEG.document(ALLEEG.total+1) = {EEG.name};
ALLEEG.total = ALLEEG.total + 1;
set(handles.listbox,'String',ALLEEG.document,'value',ALLEEG.total);
CURRENT = ALLEEG.total;

setappdata(gcf,'EEG',EEG);
setappdata(gcf,'ALLEEG',ALLEEG);
setappdata(gcf,'CURRENT',CURRENT);

initwindow;

% --------------------------------------------------------------------
function menu_filter_Callback(hObject, eventdata, handles)
% hObject    handle to menu_filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end    

% use uiwait and uiresume to get input parameters from the pop figure. 
data = pop_filter(EEG.data,EEG.srate);

if isempty(data)
    return;
end

EEG.data = data;
data1 = EEG.data(EEG.vidx,:);
EEG.min = min(min(data1));
EEG.max = max(max(data1));

% add the new EEG data to the ALLEEG,
% and add the item into the document file. 
EEG.name = [EEG.name '_Filtered'];
ALLEEG.eegdata(ALLEEG.total+1) = {EEG};
ALLEEG.document(ALLEEG.total+1) = {EEG.name};
ALLEEG.total = ALLEEG.total + 1;
set(handles.listbox,'String',ALLEEG.document,'value',ALLEEG.total);
CURRENT = ALLEEG.total;

setappdata(gcf,'EEG',EEG);
setappdata(gcf,'ALLEEG',ALLEEG);
setappdata(gcf,'CURRENT',CURRENT);

initwindow;

% --------------------------------------------------------------------
function dtf_Callback(hObject, eventdata, handles)
% hObject    handle to dtf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function topopsd_Callback(hObject, eventdata, handles)
% hObject    handle to topopsd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end  

pop_psd(EEG);


% --------------------------------------------------------------------
function ecog_Callback(hObject, eventdata, handles)
% hObject    handle to ecog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pop_cortex;


% --- Executes on selection change in listbox.
function listbox_Callback(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox

EEG = getappdata(gcf,'EEG');
ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

if CURRENT == 0;
    return;
end

selectype = get(handles.MainGUI,'SelectionType');
if strcmp(selectype,'normal')
    set(handles.listbox,'value',CURRENT);
    return;
end

listboxvalue = get(handles.listbox,'value');
if isequal(listboxvalue, CURRENT)
    return;
end

CURRENT = listboxvalue;
EEG = cell2mat(ALLEEG.eegdata(CURRENT));
setappdata(gcf,'EEG',EEG);
setappdata(gcf,'CURRENT',CURRENT);

initwindow;

setappdata(gcf,'ischanged',1);

axes(handles.tstopoaxes);
cla;
hold on;
drawhead;
hclrbar = get(handles.tstopoaxes,'userdata');
if ~isempty(hclrbar)
    delete(hclrbar);
    set(handles.tstopoaxes,'userdata',[]);
end
set(handles.textcurrentpoint,'string','');   

% --- Executes on key press with focus on listbox and no controls selected.
function listbox_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

if CURRENT == 0;
    return;
end

character = get(handles.MainGUI,'CurrentCharacter');
character = lower(character);
if strcmp(character,'d')
    deleteevent = questdlg('To delete the current EEG data ?','','Yes','Cancel','Cancel');
    if ~strcmp(deleteevent, 'Yes')
        return;
    end;
else
    return;
end

% to delete the current EEG data and rearrange the EEG data list.
i = CURRENT;
while i < ALLEEG.total - 1
    ALLEEG.eegdata(i) = ALLEEG.eegdata(i+1);
    ALLEEG.document(i) = ALLEEG.document(i+1);
    i = i+1;
end
ALLEEG.eegdata(i) = [];
ALLEEG.document(i) = [];
ALLEEG.total = ALLEEG.total - 1; % update the amount of the rest EEG data

CURRENT = ALLEEG.total;
listboxvalue = CURRENT;
if listboxvalue==0
    listboxvalue = 1;
end
set(handles.listbox,'String',ALLEEG.document,'value',listboxvalue);

drawnow;

if CURRENT == 0
    EEG = [];
else
    EEG = cell2mat(ALLEEG.eegdata(CURRENT));
end

setappdata(gcf,'EEG',EEG);
setappdata(gcf,'ALLEEG',ALLEEG);
setappdata(gcf,'CURRENT',CURRENT);

% if EEG is empty, clear the axis.
if isempty(EEG) | isempty(EEG.data)
    axes(handles.mainaxes);
    cla; 
    set(handles.channelstodisplay, 'string', num2str(0));     
else
    initwindow;
    setappdata(gcf,'ischanged',1);
end    

axes(handles.tstopoaxes);
cla;
hold on;
drawhead;
hclrbar = get(handles.tstopoaxes,'userdata');
if ~isempty(hclrbar)
    delete(hclrbar);
    set(handles.tstopoaxes,'userdata',[]);
end
set(handles.textcurrentpoint,'string','');   

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over listbox.
function listbox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
CURRENT = getappdata(gcf,'CURRENT');

if CURRENT == 0;
    helpdlg('Please import EEG data!');
    return;
end

pop_information(EEG);

%--------------------------------------------------------------------
function mousebuttondownCallback(src, evnt) 

hfig = gcf;
EEG = getappdata(hfig,'EEG');
        
mainaxes = findobj(hfig,'tag','mainaxes'); 
     
currentxlim = get(mainaxes, 'Xlim');
currentylim = get(mainaxes, 'Ylim');
mousepos = get(mainaxes, 'currentpoint');
     
% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
   mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
       return;
end

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

if ~isequal(EEG.type,'EEG')
    return;
end

linehandle = findobj(hfig,'tag','linetag');
if isempty(linehandle)
    return;
end
xpos = get(linehandle,'xdata');
axisdata = get(mainaxes, 'userdata');
currentpoint = xpos(1,1) + axisdata.xlow-1;    
currenttime = currentpoint / EEG.srate;
ypos = [currentylim(1,1),  currentylim(1,2)];

selectype = lower(get(hfig,'SelectionType'));

% 'normal': left click - select current point
if strcmp(selectype,'normal')
    textcurrentpoint = findobj(hfig,'tag','textcurrentpoint');
    set(textcurrentpoint,'string',['Time: ' num2str(currenttime) ' s']);
    setappdata(gcf,'current',currentpoint);

    tmpcolor = [0.0,0.0,0.0];
    linehandle = findobj(hfig,'tag','currentline');
    if isempty(linehandle)
        plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'currentline');
    else
       set(linehandle,'xdata',xpos,'ydata',ypos);
       drawnow;
    end
    
    % parameter setting
    tstopoaxes = findobj(hfig,'tag','tstopoaxes');
    set(hfig,'CurrentAxes',tstopoaxes);
    drawmap;
    drawnow expose;
    
    options = getappdata(hfig,'options');
    axisdata = get(mainaxes, 'userdata');
    axisdata.frame = max(options.epochstart,min(options.epochend,currentpoint));
    set(mainaxes, 'userdata',axisdata);
    return;
end

if strcmp(selectype,'alt')    
    popmenu_mainaxes = findobj(hfig,'tag','popmenu_mainaxes');
    position = get(hfig,'CurrentPoint');
    set(popmenu_mainaxes,'position',position);
    set(popmenu_mainaxes,'Visible','on');
    return;
end 

function mousescrollwheelCallback(src, evnt)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
        
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

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

if ~isequal(EEG.type,'EEG')
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
function spheremodel_Callback(hObject, eventdata, handles)
% hObject    handle to spheremodel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    pop_sphere;
else
    pop_sphere(EEG);
end

% --------------------------------------------------------------------
function realisticmodel_Callback(hObject, eventdata, handles)
% hObject    handle to realisticmodel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    pop_realisticscalp;
else
    pop_realisticscalp(EEG);
end


% --------------------------------------------------------------------
function localization_Callback(hObject, eventdata, handles)
% hObject    handle to localization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

pop_sourceloc(EEG);

% --------------------------------------------------------------------
% update the view window for the EEG data
function updatewindow()

EEG = getappdata(gcf,'EEG');
if isempty(EEG)
    return;
end

hfig= gcf;
mainaxes = findobj(hfig,'tag','mainaxes');

currentpoint = getappdata(hfig,'current');
options = getappdata(hfig,'options');
scale = getappdata(hfig,'SCALE');    

axisdata = get(mainaxes, 'userdata');
xlow = axisdata.xlow;
xhigh = axisdata.xhigh;
xlimit = axisdata.xlimit;
xlabelstep = axisdata.xlabelstep;
    
% x labels
xlabelpositions = [0:xlabelstep:xlimit];
xlabels = [xlow-1:xlabelstep:xhigh] ./ EEG.srate;
xlabels = num2str(xlabels');
     
% y labels
channelmaxs = max(EEG.data(EEG.start:EEG.end,xlow:xhigh)');
channelmins = min(EEG.data(EEG.start:EEG.end,xlow:xhigh)');    
spacing = mean(channelmaxs-channelmins);  
ylimit = (EEG.dispchans+1)*spacing;
ylabelpositions = [0:spacing:EEG.dispchans*spacing];    
YLabels = EEG.labels(EEG.start:EEG.end);
YLabels = strvcat(YLabels); 
YLabels = flipud(str2mat(YLabels,' '));

% mean values for the current window
% meandata = mean(EEG.data(EEG.start:EEG.end,xlow:xhigh)');

set(mainaxes,...
      'Xlim',[0 xlimit],...
      'xtick',xlabelpositions,...% where to display the labels.
      'Ylim',[0 ylimit],...
      'YTick',ylabelpositions,...
      'YTickLabel', YLabels,...
      'XTickLabel', xlabels); % the labels to be displayed
  
axes(mainaxes);     
cla;        
hold on;

badcolor = [1.0,0.0,0.0];
goodcolor = [0.0,0.0,1.0];
for i = 1:EEG.dispchans
    chan = EEG.end-i+1;
    isbad = find(EEG.bad==chan);
    if isbad
        tmpcolor = badcolor;
    else
        tmpcolor = goodcolor;
    end
    
    meandata = mean(EEG.data(chan,xlow:xhigh));
    data = EEG.data(chan,xlow:xhigh) - meandata;
    plot(scale*data+i*spacing,'color', tmpcolor, 'clipping','on');
    
    % plot(scale*EEG.data(chan,xlow:xhigh)+i*spacing,'color', tmpcolor, 'clipping','on');
end 

% draw existing lines
ypos = [0,ylimit];
if currentpoint>xlow && currentpoint<xhigh
    tmpcolor = [0.0 0.0 0.0];
    xpos = [currentpoint - xlow, currentpoint - xlow];
    linehandle = findobj(hfig,'tag','currentline');
    if isempty(linehandle)
        plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'currentline');
    else
       set(linehandle,'xdata',xpos,'ydata',ypos);
       drawnow;
    end
end
if options.epochstart>xlow && options.epochstart<xhigh
    tmpcolor = [0.0 0.0 1.0];
    xpos = [options.epochstart - xlow, options.epochstart - xlow];
    linehandle = findobj(hfig,'tag','leftline');
    if isempty(linehandle)
        plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'leftline');
    else
       set(linehandle,'xdata',xpos,'ydata',ypos);
       drawnow;
    end
end
if options.epochend>xlow && options.epochend<xhigh
    tmpcolor = [1.0 0.0 0.0];
    xpos = [options.epochend - xlow, options.epochend - xlow];
    linehandle = findobj(hfig,'tag','rightline');
    if isempty(linehandle)
        plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline');
    else
       set(linehandle,'xdata',xpos,'ydata',ypos);
       drawnow;
    end
end

% --------------------------------------------------------------------
% Map time series on the head
function drawmap()

hfig = gcf; 

EEG = getappdata(hfig,'EEG');
if isempty(EEG)
    return;
end

% if ~isempty(EEG.bad)
%     helpdlg('Please interpolate bad channels!');
%     return;
% end

% parameter setting
tstopoaxes = findobj(hfig,'tag','tstopoaxes');

model = getappdata(hfig,'model');
options = getappdata(hfig,'options');

ischanged = getappdata(hfig,'ischanged');

% remove electrodes that are not standard 10-20 ones,
% then get electrode positions, labels and indices on the italyskin.
if ischanged 
    model.k = cell2mat({EEG.locations(EEG.vidx).italyskinidx});
    model.electrodes.labels = EEG.labels(EEG.vidx);
    model.electrodes.locations = model.skin.italyskin.Vertices(model.k,:);
    
    model.X = model.italyskinxy.xy(model.k,1); % standard xy coordinates relative to electrodes on the skin
    model.Y = model.italyskinxy.xy(model.k,2);   
    zmin = min(model.italyskinxyz.xyz(model.k,3));
    Z = model.italyskinxyz.xyz(:,3);
    model.interpk = find(Z > zmin); % focus interpolated vertices

    model.XI = model.italyskinxy.xy(model.interpk,1);
    model.YI = model.italyskinxy.xy(model.interpk,2);
    setappdata(hfig,'model',model);
    
    ischanged = 0;
    setappdata(hfig,'ischanged',ischanged);
end

currentpoint = getappdata(hfig,'current');
if currentpoint<1 | currentpoint>EEG.points
    return;
end

values = EEG.data(EEG.vidx,currentpoint);
VI = griddata(model.X,model.Y,values,model.XI,model.YI,'v4');

if isequal(options.caxis, 'global')
    minV = EEG.min;
    maxV = EEG.max;
    absV = max(abs(minV), abs(maxV));
    minV = -absV;
    maxV = absV;
    k = find(VI<minV);
    VI(k) = minV;
    k = find(VI>maxV);
    VI(k) = maxV;    
else
    minV2 = min(values);
    maxV2 = max(values);
    k = find(VI<minV2);
    VI(k) = minV2;
    k = find(VI>maxV2);
    VI(k) = maxV2;    
        
    minV = min(VI);
    maxV = max(VI);
    absV = max(abs(minV), abs(maxV));
    minV = -absV;
    maxV = absV;
end

cmap = colormap;
len = length(cmap);
coef = (len-1)/(maxV - minV);
FaceVertexCData = model.skin.italyskin.FaceVertexCData;
FaceVertexCData(model.interpk,:) = cmap(round(coef*(VI-minV)+1),:);

% to display
axes(tstopoaxes);
cla;
hold on;

absV = max(abs(minV), abs(maxV));
caxis([-absV, absV]);
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
  
lighting phong; % phong, gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);

if options.electrode
    electrcolor = [0.0  1.0  1.0];
    plot3(model.electrodes.locations(:,1), ...
          model.electrodes.locations(:,2), ... 
          model.electrodes.locations(:,3), ... 
          'k.','LineWidth',4,'color', electrcolor);
end

if options.label
    textcolor = [0.0 0.0 0.0];
    locations = 1.05*model.electrodes.locations;
    text( locations(:,1), locations(:,2), locations(:,3), ... 
          upper(model.electrodes.labels),'FontSize',8 ,...
          'HorizontalAlignment','center', 'Color',textcolor);
end
      
hclrbar = colorbar('peer',tstopoaxes);
set(tstopoaxes,'userdata',hclrbar);

% --------------------------------------------------------------------
function drawhead()
hfig = gcf;
model = getappdata(hfig,'model');
patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
     'FaceLighting','phong',...
     'Vertices',model.skin.italyskin.Vertices,...
     'LineStyle','none',...
     'Faces',model.skin.italyskin.Faces,...
     'FaceColor','interp',...
     'FaceAlpha',1,...
     'EdgeColor','none',...
     'FaceVertexCData',model.skin.italyskin.FaceVertexCData,...
     'tag','skin');

% trisurf(model.skin.italyskin.Faces, ...
%      model.skin.italyskin.Vertices(:,1), model.skin.italyskin.Vertices(:,2), model.skin.italyskin.Vertices(:,3),...
%      'SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
%      'FaceLighting','phong',...
%      'LineStyle','none',...
%      'FaceColor','interp',...
%      'FaceAlpha',1,...
%      'EdgeColor','none',...
%      'FaceVertexCData',model.skin.italyskin.FaceVertexCData,...
%      'tag','skin');

lighting phong; % phong, gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);

% --------------------------------------------------------------------
function initwindow
EEG = getappdata(gcf,'EEG');
if isempty(EEG)
    return;
end

hfig = gcf; 
mainaxes = findobj(hfig, 'tag','mainaxes'); 
channelstodisplay = findobj(hfig, 'tag','channelstodisplay'); 

xlimit = 2000; % the topography limitation in the x axis.
if xlimit > EEG.points
   xlimit = EEG.points;
end               
    
axisdata.xlow = 1;
axisdata.xhigh = xlimit;
axisdata.auto = 0;
axisdata.frame = 1;
axisdata.xlimit = xlimit;
xlabelstep = round(xlimit/10);% only display 10 labels in x axis.
if xlabelstep == 0
    xlabelstep = 1;
end
axisdata.xlabelstep = xlabelstep;
    
EEG.start = 1;
EEG.end = EEG.nbchan;
EEG.dispchans = EEG.nbchan;    
  
set(mainaxes, 'userdata', axisdata);
set(channelstodisplay, 'string', num2str(EEG.nbchan));
options = getappdata(gcf,'options');
options.epochstart = 1;
options.epochend = EEG.points;
setappdata(gcf,'options',options);
epochstart = findobj(hfig,'tag','epochstart');
epochend = findobj(hfig,'tag','epochend'); 
set(epochstart,'string',num2str(options.epochstart/EEG.srate));
set(epochend,'string',num2str(options.epochend/EEG.srate));

setappdata(hfig,'EEG',EEG);

updatewindow;

% --------------------------------------------------------------------
function txtreader_Callback(hObject, eventdata, handles)
% hObject    handle to txtreader (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

loadeeg = pop_txtreader;
if isempty(loadeeg) | isempty(loadeeg.data)
    return;
end
EEG = loadeeg;

ALLEEG.eegdata(ALLEEG.total+1) = {EEG};
ALLEEG.document(ALLEEG.total+1) = {EEG.name};
ALLEEG.total = ALLEEG.total + 1;
set(handles.listbox,'String',ALLEEG.document,'value',ALLEEG.total);
CURRENT = ALLEEG.total;
    
setappdata(gcf,'EEG',EEG);
setappdata(gcf,'ALLEEG',ALLEEG);
setappdata(gcf,'CURRENT',CURRENT);

initwindow;

setappdata(gcf,'ischanged',1);

axes(handles.tstopoaxes);
cla;
hold on;
drawhead;
hclrbar = get(handles.tstopoaxes,'userdata');
if ~isempty(hclrbar)
    delete(hclrbar);
    set(handles.tstopoaxes,'userdata',[]);
end
set(handles.textcurrentpoint,'string','');  


% --------------------------------------------------------------------
function matreader_Callback(hObject, eventdata, handles)
% hObject    handle to matreader (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = getappdata(gcf,'EEG');
ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

loadeeg = pop_matreader;
if isempty(loadeeg) | isempty(loadeeg.data)
    return;
end
EEG = loadeeg;

ALLEEG.eegdata(ALLEEG.total+1) = {EEG};
ALLEEG.document(ALLEEG.total+1) = {EEG.name};
ALLEEG.total = ALLEEG.total + 1;
set(handles.listbox,'String',ALLEEG.document,'value',ALLEEG.total);
CURRENT = ALLEEG.total;
    
setappdata(gcf,'EEG',EEG);
setappdata(gcf,'ALLEEG',ALLEEG);
setappdata(gcf,'CURRENT',CURRENT);

initwindow;

setappdata(gcf,'ischanged',1);

axes(handles.tstopoaxes);
cla;
hold on;
drawhead;
hclrbar = get(handles.tstopoaxes,'userdata');
if ~isempty(hclrbar)
    delete(hclrbar);
    set(handles.tstopoaxes,'userdata',[]);
end
set(handles.textcurrentpoint,'string','');  

% --------------------------------------------------------------------
function txtwriter_Callback(hObject, eventdata, handles)
% hObject    handle to txtwriter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function matwriter_Callback(hObject, eventdata, handles)
% hObject    handle to matwriter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end
    
[name, pathstr] = uiputfile('*.mat','Save Current EEG Data');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);         
save(Fullfilename, 'EEG');

function [xint, yint, zint] = invdis2d(x2d,y2d,values,xgrid,ygrid)
[xint,yint] = meshgrid(xgrid,ygrid);
deltax = abs(xgrid(2) - xgrid(1));
deltay = abs(ygrid(2) - ygrid(1));
delta = [deltax deltay];
newdim = size(xint);
zint = zeros(newdim);
olddim = length(x2d);
oldpos(:,1) = x2d;
oldpos(:,2) = y2d;
for i = 1:newdim(1)
    for j = 1:newdim(2)
        newpos = [xint(i,j), yint(i,j)];
        for k = 1:olddim
            disv = oldpos(k,:) - newpos;
            disv = disv./delta; % constrained to pixels
            dis = sqrt(disv*disv');
            coef(k) = exp(-dis/2);
        end
          sumd = sum(coef);
          zint(i,j) = coef*values/sumd;
    end
end


% --- Executes on button press in pushbuttontopomap.
function pushbuttontopomap_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttontopomap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end      

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),EEG.points);
endpoint = min(max(endpoint,1),EEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end
    
hfig = gcf; 

mainaxes = findobj(hfig,'tag','mainaxes'); 
tstopoaxes = findobj(hfig,'tag','tstopoaxes');
textcurrentpoint = findobj(hfig,'tag','textcurrentpoint');
model = getappdata(hfig,'model');
ischanged = getappdata(hfig,'ischanged');

currentylim = get(mainaxes, 'Ylim');
axisdata = get(mainaxes, 'userdata');
ypos = [currentylim(1,1),  currentylim(1,2)];
     
% remove electrodes that are not standard 10-20 ones,
% then get electrode positions, labels and indices on the italyskin.
if ischanged 
    model.k = cell2mat({EEG.locations(EEG.vidx).italyskinidx});
    model.electrodes.labels = EEG.labels(EEG.vidx);
    model.electrodes.locations = model.skin.italyskin.Vertices(model.k,:);
    
    model.X = model.italyskinxy.xy(model.k,1); % standard xy coordinates relative to electrodes on the skin
    model.Y = model.italyskinxy.xy(model.k,2);   
    zmin = min(model.italyskinxyz.xyz(model.k,3));
    Z = model.italyskinxyz.xyz(:,3);
    model.interpk = find(Z > zmin); % focus interpolated vertices

    model.XI = model.italyskinxy.xy(model.interpk,1);
    model.YI = model.italyskinxy.xy(model.interpk,2);
    setappdata(hfig,'model',model);
    ischanged = 0;
    setappdata(hfig,'ischanged',ischanged);
end

% if axisdata.frame>startpoint && axisdata.frame<endpoint
%     startpoint = axisdata.frame;
% end
startpoint = min(max(axisdata.frame,startpoint), endpoint);

cmap = colormap;
len = length(cmap);
electrcolor = [0.0  1.0  1.0];
lightcolor = [0.5 0.5 0.5];
textcolor = [0.0 0.0 0.0];
linecolor = [0.0 0.0 0.0];
points = startpoint:3:endpoint;
numpnt = length(points);
if points(numpnt) ~= endpoint
    points(numpnt+1) = endpoint;
end

% The min and max values through the epoch.
data = EEG.data(EEG.vidx,startpoint:endpoint);
minV = min(min(data));
maxV = max(max(data));
absV = max(abs(minV), abs(maxV));
minV = -absV;
maxV = absV;
    
j = 0;
for i = points
    axisdata = get(mainaxes, 'userdata');
    if axisdata.auto == 1
         axisdata.auto = 0;
         axisdata.frame = i;
         set(mainaxes, 'userdata', axisdata);
         if isempty(mov)
             mov = [];
         end
         playmov(mov, 'Potential Mapping Movie of Scalp EEG');
         return;
    end
    
    values = EEG.data(EEG.vidx,i);
    VI = griddata(model.X,model.Y,values,model.XI,model.YI,'v4');

    k = find(VI<minV);
    VI(k) = minV;
    k = find(VI>maxV);
    VI(k) = maxV;    

    coef = (len-1)/(maxV - minV);
    FaceVertexCData = model.skin.italyskin.FaceVertexCData;
    FaceVertexCData(model.interpk,:) = cmap(round(coef*(VI-minV)+1),:);

    % to display
    set(hfig,'CurrentAxes',tstopoaxes);
    cla;
    hold on;

    caxis([minV maxV]);
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

    lighting phong; % phong, gouraud
    light('Position',[0 0 1],'color',lightcolor);
    light('Position',[0 1 0],'color',lightcolor);
    light('Position',[0 -1 0],'color',lightcolor);
    
    if options.electrode
        plot3(model.electrodes.locations(:,1), ...
              model.electrodes.locations(:,2), ... 
              model.electrodes.locations(:,3), ... 
              'k.','LineWidth',4,'color', electrcolor);
    end

    if options.label
        locations = 1.05*model.electrodes.locations;
        text( locations(:,1), locations(:,2), locations(:,3), ... 
        upper(model.electrodes.labels),'FontSize',8 ,...
        'HorizontalAlignment','center', 'Color',textcolor);
    end

    hclrbar = colorbar('peer',tstopoaxes);
    set(tstopoaxes,'userdata',hclrbar);
    
    set(textcurrentpoint,'string',['Time: ' num2str(i/EEG.srate) ' s']);
    
    axes(mainaxes);
    temppos = i - axisdata.xlow +1;
    xpos = [temppos,  temppos];
    linehandle = findobj(hfig,'tag','currentline');
    if isempty(linehandle)
        plot(xpos, ypos, 'color', linecolor, 'clipping','on','EraseMode', 'xor', 'tag', 'currentline');
    else
       set(linehandle,'xdata',xpos,'ydata',ypos);
    end
    drawnow; 
    setappdata(gcf, 'current',i);
    
    j = j+1;
    mov(j) = getframe(tstopoaxes); % get frames to generate movie file
end

axisdata.frame = 1;
set(mainaxes, 'userdata', axisdata);

playmov(mov, 'Potential Mapping Movie of Scalp EEG');

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbuttontopomap.
function pushbuttontopomap_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttontopomap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axisdata = get(handles.mainaxes, 'userdata');
axisdata.auto = 1;
set(handles.mainaxes, 'userdata', axisdata);

% --------------------------------------------------------------------
function menu_baseline_Callback(hObject, eventdata, handles)
% hObject    handle to menu_baseline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end      

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),EEG.points);
endpoint = min(max(endpoint,1),EEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

starttime = startpoint / EEG.srate;
endtime = endpoint / EEG.srate;

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
startpoint = round(startend(1) * EEG.srate);
endpoint = round(startend(2) * EEG.srate);

startpoint = min(max(startpoint,1),EEG.points);
endpoint = min(max(endpoint,1),EEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

epochdata = EEG.data(:,startpoint:endpoint);
meandata = mean(epochdata,2);

EEG.data = EEG.data - repmat(meandata,1,EEG.points);
data = EEG.data(EEG.vidx,:);
EEG.min = min(min(data));
EEG.max = max(max(data));

% add the new EEG data to the ALLEEG,
% and add the item into the document file. 
EEG.name = [EEG.name '_Corrected'];
ALLEEG.eegdata(ALLEEG.total+1) = {EEG};
ALLEEG.document(ALLEEG.total+1) = {EEG.name};
ALLEEG.total = ALLEEG.total + 1;
set(handles.listbox,'String',ALLEEG.document,'value',ALLEEG.total);
CURRENT = ALLEEG.total;

setappdata(gcf,'EEG',EEG);
setappdata(gcf,'ALLEEG',ALLEEG);
setappdata(gcf,'CURRENT',CURRENT);

initwindow;

% --------------------------------------------------------------------
function menu_electrodes_Callback(hObject, eventdata, handles)
% hObject    handle to menu_electrodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
 
if isempty(EEG) | isempty(EEG.data)
    return;
end  

hfig = gcf;
options = getappdata(hfig, 'options');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.electrode = 0;
else
    ischecked = 'on';
    options.electrode = 1;
end

setappdata(hfig,'options',options);
set(hObject,'checked',ischecked);

tstopoaxes = findobj(hfig,'tag','tstopoaxes');
set(hfig,'CurrentAxes',tstopoaxes);
drawmap;
drawnow expose;    

% --------------------------------------------------------------------
function menu_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');
 
if isempty(EEG) | isempty(EEG.data)
    return;
end  

hfig = gcf;
options = getappdata(hfig, 'options');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.label = 0;
else
    ischecked = 'on';
    options.label = 1;
end

setappdata(hfig,'options',options);
set(hObject,'checked',ischecked);

tstopoaxes = findobj(hfig,'tag','tstopoaxes');
set(hfig,'CurrentAxes',tstopoaxes);
drawmap;
drawnow expose;  

% --------------------------------------------------------------------
function popmenu_tstopoaxes_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu_tstopoaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_badchannel_Callback(hObject, eventdata, handles)
% hObject    handle to menu_badchannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
    
EEG = getappdata(hfig,'EEG');
 
labels = lower(EEG.labels);
channelname = lower(get(handles.whichchannel,'string'));
idx1 = strmatch(channelname,labels,'exact');

idx2 = find(EEG.bad==idx1); % if it is a bad chnnel
idx3 = find(EEG.vidx==idx1);

if isempty(idx2) && isempty(idx3)
    helpdlg([upper(channelname) ' is an automatically processed channel !']);
    return;
end

if isempty(idx2) % is good channel, change to bad
    EEG.bad(length(EEG.bad)+1) = idx1;
    EEG.bad = sort(EEG.bad);
    EEG.vidx(idx3) = [];    % remove it from good channels
else % is bad channel, change to good
    EEG.bad(idx2) = [];
    EEG.vidx(length(EEG.vidx)+1) = idx1; % add it to good channels
    EEG.vidx = sort(EEG.vidx);      
end

setappdata(hfig,'ischanged',1);
setappdata(hfig,'EEG',EEG);

updatewindow;

% --------------------------------------------------------------------
function menu_timefrequency_Callback(hObject, eventdata, handles)
% hObject    handle to menu_timefrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
EEG = getappdata(hfig,'EEG');

labels = lower(EEG.labels);
channelname = lower(get(handles.whichchannel,'string'));
idx = strmatch(channelname,labels,'exact');

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),EEG.points);
endpoint = min(max(endpoint,1),EEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

ts = EEG.data(idx,startpoint:endpoint);
srate = EEG.srate;
starttime = (startpoint - 1)/EEG.srate;
pos1 = get(hfig,'CurrentPoint');
pos2 = get(hfig,'position');
pos = pos1 + pos2(1:2);

% compute and visualize time-frequency
time_frequency(ts, srate, starttime, pos, channelname);

% --------------------------------------------------------------------
function popmenu_mainaxes_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu_mainaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over epochclip.
function epochclip_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to epochclip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = getappdata(gcf,'EEG');

if isempty(EEG) | isempty(EEG.data)
    helpdlg('Please import EEG data!');
    return;
end

clipevent = questdlg('To get the epoch specified ?','','Yes','Cancel','Cancel');
if ~strcmp(clipevent, 'Yes')
    return;
end   

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),EEG.points);
endpoint = min(max(endpoint,1),EEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

if endpoint == startpoint
    msgbox('The epoch is too small, need 2 points at least!','','help','modal');
    return;
end

EEG.points = endpoint - startpoint + 1;
EEG.data = EEG.data(:,startpoint:endpoint);

data1 = EEG.data(EEG.vidx,:);
EEG.min = min(min(data1));
EEG.max = max(max(data1));

ALLEEG = getappdata(gcf,'ALLEEG');
CURRENT = getappdata(gcf,'CURRENT');

% add the new EEG data to the ALLEEG,
% and add the item into the document file. 
EEG.name = [EEG.name '_Epoch_Gotten'];
ALLEEG.eegdata(ALLEEG.total+1) = {EEG};
ALLEEG.document(ALLEEG.total+1) = {EEG.name};
ALLEEG.total = ALLEEG.total + 1;
set(handles.listbox,'String',ALLEEG.document,'value',ALLEEG.total);
CURRENT = ALLEEG.total;

setappdata(gcf,'EEG',EEG);
setappdata(gcf,'ALLEEG',ALLEEG);
setappdata(gcf,'CURRENT',CURRENT);

initwindow;


% --------------------------------------------------------------------
function menu_interpbad_Callback(hObject, eventdata, handles)
% hObject    handle to menu_interpbad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
if isempty(EEG.bad)
    helpdlg('There is no bad channel !');
    return;
end

X(:,1) = cell2mat({EEG.locations(EEG.vidx).X});
X(:,2) = cell2mat({EEG.locations(EEG.vidx).Y});
X(:,3) = cell2mat({EEG.locations(EEG.vidx).Z});

numbad = length(EEG.bad);
XI(:,1) = cell2mat({EEG.locations(EEG.bad).X});
XI(:,2) = cell2mat({EEG.locations(EEG.bad).Y});
XI(:,3) = cell2mat({EEG.locations(EEG.bad).Z});

n = 4;
for k = 1:numbad
    idx = EEG.bad(k);
    dists = sqrt( (X(:,1)-XI(k,1)).^2 + (X(:,2)-XI(k,2)).^2 + (X(:,3)-XI(k,3)).^2);
    [dists,idxs] = sort(dists);
    idxs_N =  EEG.vidx(idxs(1:n));
    dists_N = (dists(1:n)).^2;
    coefs_N = 1 ./ dists_N;
    coefs_N = coefs_N / sum(coefs_N);
    
    EEG.data(idx,:) = coefs_N' * EEG.data(idxs_N,:);
end

EEG.vidx = sort([EEG.vidx, EEG.bad]);
EEG.bad = [];
data = EEG.data(EEG.vidx,:);
EEG.min = min(min(data));
EEG.max = max(max(data));
setappdata(hfig,'EEG',EEG);
setappdata(hfig,'ischanged',1);

updatewindow;

% --------------------------------------------------------------------
function menu_global_Callback(hObject, eventdata, handles)
% hObject    handle to menu_global (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.caxis = 'global';
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
drawmap;

% --------------------------------------------------------------------
function menu_local_Callback(hObject, eventdata, handles)
% hObject    handle to menu_local (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
options = getappdata(hfig,'options');
options.caxis = 'local';
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
drawmap;

% --------------------------------------------------------------------
function Untitled_2_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_leftepoch_Callback(hObject, eventdata, handles)
% hObject    handle to menu_leftepoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
mainaxes = findobj(hfig,'tag','mainaxes');
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
axisdata = get(mainaxes, 'userdata');
currentpoint = xpos(1,1) + axisdata.xlow-1;     
currenttime = currentpoint / EEG.srate;
currentylim = get(mainaxes, 'Ylim');
ypos = [currentylim(1,1),  currentylim(1,2)];

epochstart = findobj(hfig,'tag','epochstart');
set(epochstart,'string',num2str(currenttime));
axisdata.frame = 1;
set(mainaxes,'userdata',axisdata);

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

% --------------------------------------------------------------------
function menu_rightepoch_Callback(hObject, eventdata, handles)
% hObject    handle to menu_rightepoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');
mainaxes = findobj(hfig,'tag','mainaxes');
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
axisdata = get(mainaxes, 'userdata');
currentpoint = xpos(1,1) + axisdata.xlow-1;     
currenttime = currentpoint / EEG.srate;
currentylim = get(mainaxes, 'Ylim');
ypos = [currentylim(1,1),  currentylim(1,2)];

epochend = findobj(hfig,'tag','epochend');
set(epochend,'string',num2str(currenttime));
axisdata.frame = 1;
set(mainaxes,'userdata',axisdata);

tmpcolor = [1.0,0.0,0.0];
linehandle = findobj(hfig,'tag','rightline');
if isempty(linehandle)
   plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'rightline','LineStyle','--');
else
   set(linehandle,'xdata',xpos,'ydata',ypos);
   drawnow;
end

options = getappdata(hfig,'options');
options.epochend = currentpoint;
setappdata(hfig,'options',options);

% --------------------------------------------------------------------
function menu_capimg_Callback(hObject, eventdata, handles)
% hObject    handle to menu_capimg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% capobj(handles.tstopoaxes, 'Potential Mapping Image of Scalp EEG');

% --------------------------------------------------------------------
function menu_playmov_Callback(hObject, eventdata, handles)
% hObject    handle to menu_playmov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
playmov([], 'Potential Mapping Movie of Scalp EEG');



% % --------------------------------------------------------------------
% function menu_reference_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_reference (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% hfig = gcf;
% EEG = getappdata(hfig,'EEG');
% list = 1:EEG.nbchan;
% if ~isempty(EEG.bad)
%     list(EEG.bad) = [];
% end
% labels = EEG.labels(list);
% default = [];
% [sel,ok] = listdlg('ListString',labels,'Name','Re-reference Channels','InitialValue',default);
% if ok == 0 | isempty(sel)
%     return;
% end
% 
% selected = list(sel);
% ct = 0;
% h = waitbar(0,'Re-referencing, please wait...');
% for i = 1: EEG.points
%    reference = mean(EEG.data(selected,i));
%    EEG.data(:,i) = EEG.data(:,i) - reference;
%    ct = ct + 1; 
%    if ~mod(ct, 10)
%       waitbar(ct/EEG.points);
%    end
% end
% waitbar(1);
% close(h);
% 
% data = EEG.data(EEG.vidx,:);
% EEG.min = min(min(data));
% EEG.max = max(max(data));
% 
% setappdata(hfig,'EEG',EEG);
% updatewindow;


% --------------------------------------------------------------------
function menu_GFP_Callback(hObject, eventdata, handles)
% hObject    handle to menu_GFP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
EEG = getappdata(hfig,'EEG');

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;
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
function menu_PM_Callback(hObject, eventdata, handles)
% hObject    handle to menu_PM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.tstopoaxes, 'Potential Mapping Image of Scalp EEG');

% --------------------------------------------------------------------
function menu_waveforms_Callback(hObject, eventdata, handles)
% hObject    handle to menu_waveforms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capaxis(handles.mainaxes, 'Scalp EEG Waveforms', 0);


% --------------------------------------------------------------------
function menu_COI_Callback(hObject, eventdata, handles)
% hObject    handle to menu_COI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;    
EEG = getappdata(hfig,'EEG');
vidx = sort([EEG.vidx, EEG.bad]); % automatically processed channels are excluded

default = [];
[sel,ok] = listdlg('ListString',EEG.labels(vidx),'Name','Interested Channels','InitialValue',default);
if ok == 0 | isempty(sel)
    return;
end

EEG.vidx = vidx(sel); % interested channels
EEG.bad = vidx; % the rest are considered as bad channels
EEG.bad(sel) = [];

setappdata(hfig,'ischanged',1);
setappdata(hfig,'EEG',EEG);

updatewindow;

