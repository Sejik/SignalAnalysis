function varargout = megfc(varargin)
% megfc - the main module for brain functional connectivity analysis from MEG data
%
% Authors: 
%  Yakang Dai and Bin He at the University of Minnesota, USA, 
%  with substantial contributions from Fabio Babiloni and Laura Astolfi 
%  at the University of Rome "La Sapienza", Italy, plus additional contributions 
%  from Lin Yang, Yunfeng Lu and Huishi Zhang at the University of Minnesota, USA. 
% 
% Usage: 
%     1. type
%         >> megfc
%        or call megfc to start the popup GUI
%       
%     2. type 
%         >> megfc(MEG)
%         or call megfc(MEG) to start the popup GUI with MEG structure. 
%         The MEG structure should be pre-exported by the megfc GUI 
%         or made by 
%         >> MEG = pop_meg_txtreader  
%         or
%         >> MEG = pop_meg_matreader
%         Please see the eConnectome Manual 
%         (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%         for details about the import MEG file formats (TXT and MAT) recognized by the software.
%           
%      3. call megfc from the main econnectome GUI ('Menu bar -> MEG')
%
% Description:
% megfc is the main GUI for MEG connectivity analysis. Multi-channel MEG 
% data can be imported for pre-processing and analyzing including ERF analysis, 
% co-registration, bad channel rejection, baseline correction, de-trending, 
% band-pass filtering and 60/50 Hz notch filtering. Field and spectrum maps 
% over MEG sensor surface can be constructed and visualized. 
% Time-frequency representations of time series can be calculated and visualized. 
% The Directed Transfer Function (DTF) and Adaptive DTF (ADTF) among all channels can be computed and 
% visualized over the MEG sensor surface, including inflow, outflow, 
% and connectivity patterns of all or selected channels over selected frequency components. 
% Cortical source distributions can also be estimated and 
% visualized. Finally functional connectivity patterns including inflow, outflow and 
% connectivity can be computed and visualized from the estimated cortical
% source waveforms, based on Brodmann areas or user defined regions of interest.
%
% Reference for eConnectome (please cite): 
% B. He, Y. Dai, L. Astolfi, F. Babiloni, L. Yang, H. Yuan.
% eConnectome: A MATLAB toolbox for mapping and imaging of brain functional connectivity. 
% Journal of Neuroscience Methods. 195:261-269, 2011.
%
% Reference for megfc() (please cite):
% Y. Dai, B. He. 
% MEG-based Brain Functional Connectivity Analysis Using eConnectome. 
% Proc. of 8th International Symposium on Noninvasive Functional Source Imaging of the Brain and Heart and 
% the 8th International Conference on Bioelectromagnetism. 9-11, 2011.
%
% Y. Dai, W. Zhang, D. L. Dickens, B. He. 
% Source Connectivity Analysis from MEG and its Application to Epilepsy Patients. 
% Brain Topography. 25(2):157-166, 2012.
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
% Yakang Dai, 06-Jan-2011 15:18:40
% Release Version 2.0 beta
%
% ========================================== 

% --- Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @megfc_OpeningFcn, ...
                   'gui_OutputFcn',  @megfc_OutputFcn, ...
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


% --- Executes just before megfc is made visible.
function megfc_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to megfc (see VARARGIN)

% Choose default command line output for megfc
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes megfc wait for user response (see UIRESUME)
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
    warndlg('Too many arguments input!');
end

bkgclr = get(handles.uipanelinfo,'backgroundcolor');
set(handles.listbox,'backgroundcolor',bkgclr);
set(hObject,'color',bkgclr);
axes(handles.mainaxes);
set(handles.mainaxes,'color',get(hObject,'color'));

MEG = [];
ALLMEG.total = 0;
CURRENT = 0;
ischanged = 0;
scale = 1;

if  length(varargin) == 1
    MEG = varargin{1};
    if ~isempty(MEG) && ~isempty(MEG.data)
        if ~isfield(MEG,'name')
            MEG.name = 'UnTitledMEG';
        end
        ALLMEG.megdata(ALLMEG.total+1) = {MEG};
        ALLMEG.document(ALLMEG.total+1) = {MEG.name};
        ALLMEG.total = ALLMEG.total + 1;
        set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
        CURRENT = ALLMEG.total;
        ischanged = 1;
    else
        MEG = [];
        errordlg('Input MEG data is empty!');
    end
end
setappdata(hObject,'MEG',MEG);
setappdata(hObject,'ALLMEG',ALLMEG);
setappdata(hObject,'CURRENT',CURRENT);
setappdata(hObject,'SCALE', scale);

setappdata(hObject, 'current',1);
initwindow;

% Plot the head
model.skin = load('italyskin.mat');
CoR = load('CoR.mat');
model.CoR = CoR.italyskin;
num = length(model.skin.italyskin.Vertices);
model.skin.italyskin.Vertices = (model.skin.italyskin.Vertices+repmat(model.CoR.translation,num,1))*model.CoR.rotation;
setappdata(hObject,'model',model);

options.mag = 'off';
options.label = 'off';
options.map = 'on';
options.head = 'on';
options.handles.head = 0;
options.handles.mag = 0;
options.handles.label = 0;
options.handles.map = 0;
if isempty(MEG)
    options.epochstart = 0;
    options.epochend = 0;
    starttime = 0;
    endtime = 0;
else
    options.epochstart = 1;
    options.epochend = MEG.points;
    starttime = options.epochstart / MEG.srate;
    endtime = options.epochend / MEG.srate;
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
function varargout = megfc_OutputFcn(hObject, eventdata, handles) 
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
     

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

% the region for displaying
 xlow = axisdata.xlow - axisdata.xlabelstep;
 xhigh = axisdata.xhigh - axisdata.xlabelstep;

 % to the end of the meg frames, do nothing
 if xhigh <=1
     msgbox('Reach the left end of the MEG data!','','help','modal');
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

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

 axisdata = get(handles.mainaxes, 'userdata');

 xlow = axisdata.xlow - axisdata.xlimit;
 xhigh = axisdata.xhigh - axisdata.xlimit;

 % to the end of the MEG frames, do nothing
 if xhigh <=1
     msgbox('Reach the left end of the MEG data!','','help','modal');
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

MEG = getappdata(gcf,'MEG');
 
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

% the region for displaying
 xlow = axisdata.xlow + axisdata.xlabelstep;
 xhigh = axisdata.xhigh + axisdata.xlabelstep;

 % to the end of the MEG frames, do nothing
 if xlow >= MEG.points
     msgbox('Reach the right end of the MEG data!','','help','modal');
     return;
 end

 if xhigh > MEG.points 
     xhigh = MEG.points;
     xlow = MEG.points - axisdata.xlimit + 1;
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

MEG = getappdata(gcf,'MEG');
 
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

% the region for displaying
 xlow = axisdata.xlow + axisdata.xlimit;
 xhigh = axisdata.xhigh + axisdata.xlimit;

 % to the end of the MEG frames, do nothing
 if xlow >= MEG.points
     msgbox('Reach the right end of the MEG data!','','help','modal');
     return;
 end

 if xhigh > MEG.points 
     xhigh = MEG.points;
     xlow = MEG.points - axisdata.xlimit + 1;
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

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

if MEG.dispchans == 1
    msgbox('Reach the max zoom!','','help','modal');
    return;
end

if MEG.dispchans - 4 < 1
    MEG.dispchans = 1;
else
    MEG.dispchans = MEG.dispchans - 4;
end

MEG.end = MEG.start + MEG.dispchans - 1;
set(handles.channelstodisplay, 'string', num2str(MEG.dispchans));
setappdata(gcf,'MEG',MEG);

updatewindow;        

% --- Executes on button press in whichchannelszoomout.
function whichchannelszoomout_Callback(hObject, eventdata, handles)
% hObject    handle to whichchannelszoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');
 
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

if MEG.dispchans == MEG.nbchan
    msgbox('Reach the min zoom!','','help','modal');
    return;
end

if MEG.dispchans + 4 > MEG.nbchan
    MEG.dispchans = MEG.nbchan;
else
    MEG.dispchans = MEG.dispchans + 4;
end

% if start is 1, then extend from 1,
% if start is more than 1, then extend from end.
if MEG.start == 1
    MEG.end = MEG.start + MEG.dispchans - 1;
else
    MEG.start = MEG.end - MEG.dispchans + 1;
end

set(handles.channelstodisplay, 'string', num2str(MEG.dispchans));
setappdata(gcf,'MEG',MEG);

updatewindow;     

% --- Executes on button press in whichtimeleftest.
function whichtimeleftest_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleftest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');
    
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
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

MEG = getappdata(gcf,'MEG');
    
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

axisdata.xhigh = MEG.points;
axisdata.xlow = MEG.points - axisdata.xlimit + 1;
set(handles.mainaxes, 'userdata',axisdata);
updatewindow;            

% --- Executes on button press in whichtimeleftauto.
function whichtimeleftauto_Callback(hObject, eventdata, handles)
% hObject    handle to whichtimeleftauto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');
   
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

 xlow = axisdata.xlow - axisdata.xlabelstep;
 xhigh = axisdata.xhigh - axisdata.xlabelstep;

 % to the end of the MEG frames, do nothing
 if xhigh <=1
     msgbox('Reach the left end of the MEG data!','','help','modal');
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

MEG = getappdata(gcf,'MEG');
    
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

axisdata = get(handles.mainaxes, 'userdata');

 xlow = axisdata.xlow + axisdata.xlabelstep;
 xhigh = axisdata.xhigh + axisdata.xlabelstep;

 % to the end of the MEG frames, do nothing
 if xlow >= MEG.points
     msgbox('Reach the right end of the MEG data!','','help','modal');
     return;
 end

 if xhigh > MEG.points 
     xhigh = MEG.points;
     xlow = MEG.points - axisdata.xlimit + 1;
 end    

axisdata.xlow = xlow;
axisdata.xhigh = xhigh;
set(handles.mainaxes, 'userdata',axisdata);
updatewindow; 

 if xhigh == MEG.points | axisdata.auto == 1
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

MEG = getappdata(gcf,'MEG');
    
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

if MEG.start == 1
    msgbox('Reach the first channel!','','help','modal');
    return;
end

if MEG.start - 4 < 1
    MEG.start = 1;
else
    MEG.start = MEG.start - 4;
end

MEG.end = MEG.start + MEG.dispchans - 1;

setappdata(gcf,'MEG',MEG);

updatewindow; 
 
% --- Executes on button press in whichchannelsdown.
function whichchannelsdown_Callback(hObject, eventdata, handles)
% hObject    handle to whichchannelsdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');
    
if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

if MEG.end == MEG.nbchan
    msgbox('Reach the last channel!','','help','modal');
    return;
end

if MEG.end + 4 > MEG.nbchan
    MEG.end = MEG.nbchan;
else
    MEG.end = MEG.end + 4;
end

MEG.start = MEG.end - MEG.dispchans + 1;  

setappdata(gcf,'MEG',MEG);

updatewindow;  

function mousemotionCallback(src, evnt) 

hfig = gcf;

MEG = getappdata(hfig,'MEG');
scale = getappdata(hfig,'SCALE');

if isempty(MEG) | isempty(MEG.data)
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
currenttime = currentpoint / MEG.srate;

channelmaxs = max(MEG.data(MEG.start:MEG.end, axisdata.xlow:axisdata.xhigh)');
channelmins = min(MEG.data(MEG.start:MEG.end, axisdata.xlow:axisdata.xhigh)');
spacing = mean(channelmaxs-channelmins);
currentchannel = round( (currentylim(1,2) - mousepos(1,2) ) / spacing );%find the nearest channel.
currentchannel = currentchannel + MEG.start - 1;
if currentchannel < MEG.start | currentchannel > MEG.end
 set(whattime, 'string', num2str(0));
 set(whichpoint, 'string', num2str(0));
 set(whichchannel, 'string', num2str(0));
 set(whatvalue, 'string', num2str(0));
 return;
end

currentvalue = MEG.data(currentchannel, currentpoint);
set(whattime, 'string', [num2str(currenttime) ' s']);
set(whichpoint, 'string', num2str(currentpoint));
set( whichchannel, 'string', MEG.labels(currentchannel));
set(whatvalue, 'string', [num2str(currentvalue) ' ' MEG.unit]);

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
i = MEG.end - currentchannel + 1;
x = xpos(1);
currentvalue = currentvalue - mean(MEG.data(currentchannel,axisdata.xlow:axisdata.xhigh));
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

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end 

clipevent = questdlg('To remove the epoch specified ?','','Yes','Cancel','Cancel');
if ~strcmp(clipevent, 'Yes')
    return;
end   

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);

if startpoint > endpoint
    helpdlg('The epoch specification is not right!');
    return;
end

if endpoint == startpoint
    helpdlg('The epoch is too small, need 2 points at least!','','help','modal');
    return;
end

if startpoint == 1 && endpoint == MEG.points
    helpdlg('Please specify the epoch (NOT the whole MEG)!');
    return;
end

MEG.points = MEG.points - (endpoint - startpoint + 1);
MEG.data(:,startpoint:endpoint) = [];

% to smooth the joint points
r1 = 15;
r2 = 15;
if startpoint-1-r1 < 1
    r1 = startpoint-2;
end
if startpoint+r2 > MEG.points
    r2 = MEG.points-startpoint;
end
left = startpoint-1-r1;
right = startpoint+r2;
n = r1+r2+2;
y = zeros(1, n);
x = 1:n;
for i = 1:MEG.nbchan
    y(1:r1+1) = MEG.data(i,left:startpoint-1);
    y(r1+2:n) = MEG.data(i,startpoint:right);    
    p = polyfit(x,y,6);
    f = polyval(p,x); 
    MEG.data(i,left:startpoint-1) = f(1:r1+1);
    MEG.data(i,startpoint:right) = f(r1+2:n);
end

data1 = MEG.data(MEG.vidx,:);
MEG.min = min(min(data1));
MEG.max = max(max(data1));

ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

% add the new MEG data to the ALLMEG,
% and add the item into the document file. 
MEG.name = [MEG.name '_Epoch_Removed'];
ALLMEG.MEGdata(ALLMEG.total+1) = {MEG};
ALLMEG.document(ALLMEG.total+1) = {MEG.name};
ALLMEG.total = ALLMEG.total + 1;
set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
CURRENT = ALLMEG.total;

setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
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
function menu_filter_Callback(hObject, eventdata, handles)
% hObject    handle to menu_filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');
ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end    

% use uiwait and uiresume to get input parameters from the pop figure. 
data = pop_filter(MEG.data,MEG.srate);

if isempty(data)
    return;
end

MEG.data = data;
data1 = MEG.data(MEG.vidx,:);
MEG.min = min(min(data1));
MEG.max = max(max(data1));

% add the new MEG data to the ALLMEG,
% and add the item into the document file. 
MEG.name = [MEG.name '_Filtered'];
ALLMEG.MEGdata(ALLMEG.total+1) = {MEG};
ALLMEG.document(ALLMEG.total+1) = {MEG.name};
ALLMEG.total = ALLMEG.total + 1;
set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
CURRENT = ALLMEG.total;

setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
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
function menu_sensor_Callback(hObject, eventdata, handles)
% hObject    handle to menu_sensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    pop_meg_sensor;
else
    pop_meg_sensor(MEG);
end

% --------------------------------------------------------------------
function topopsd_Callback(hObject, eventdata, handles)
% hObject    handle to topopsd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end  

pop_meg_psd(MEG);


% --------------------------------------------------------------------
function menu_cortex_Callback(hObject, eventdata, handles)
% hObject    handle to menu_cortex (see GCBO)
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

MEG = getappdata(gcf,'MEG');
ALLMEG = getappdata(gcf,'ALLMEG');
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
MEG = cell2mat(ALLMEG.MEGdata(CURRENT));
setappdata(gcf,'MEG',MEG);
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

MEG = getappdata(gcf,'MEG');
ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

if CURRENT == 0;
    return;
end

character = get(handles.MainGUI,'CurrentCharacter');
character = lower(character);
if strcmp(character,'d')
    deleteevent = questdlg('To delete the current MEG data ?','','Yes','Cancel','Cancel');
    if ~strcmp(deleteevent, 'Yes')
        return;
    end;
else
    return;
end

% to delete the current MEG data and rearrange the MEG data list.
i = CURRENT;
while i < ALLMEG.total - 1
    ALLMEG.MEGdata(i) = ALLMEG.MEGdata(i+1);
    ALLMEG.document(i) = ALLMEG.document(i+1);
    i = i+1;
end
ALLMEG.MEGdata(i) = [];
ALLMEG.document(i) = [];
ALLMEG.total = ALLMEG.total - 1; % update the amount of the rest MEG data

CURRENT = ALLMEG.total;
listboxvalue = CURRENT;
if listboxvalue==0
    listboxvalue = 1;
end
set(handles.listbox,'String',ALLMEG.document,'value',listboxvalue);

drawnow;

if CURRENT == 0
    MEG = [];
else
    MEG = cell2mat(ALLMEG.MEGdata(CURRENT));
end

setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
setappdata(gcf,'CURRENT',CURRENT);

% if MEG is empty, clear the axis.
if isempty(MEG) | isempty(MEG.data)
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

MEG = getappdata(gcf,'MEG');
CURRENT = getappdata(gcf,'CURRENT');

if CURRENT == 0;
    helpdlg('Please import MEG data!');
    return;
end

pop_information(MEG);

%--------------------------------------------------------------------
function mousebuttondownCallback(src, evnt) 

hfig = gcf;
MEG = getappdata(hfig,'MEG');
        
mainaxes = findobj(hfig,'tag','mainaxes'); 
     
currentxlim = get(mainaxes, 'Xlim');
currentylim = get(mainaxes, 'Ylim');
mousepos = get(mainaxes, 'currentpoint');
     
% if the mouse is not in the viewing window, topography nothing.
if mousepos(1,1) < currentxlim(1,1) | mousepos(1,1) > currentxlim(1,2)  | ...
   mousepos(1,2) < currentylim(1,1) | mousepos(1,2) > currentylim(1,2) 
       return;
end

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

if ~isequal(MEG.type,'MEG')
    return;
end

linehandle = findobj(hfig,'tag','linetag');
if isempty(linehandle)
    return;
end
xpos = get(linehandle,'xdata');
axisdata = get(mainaxes, 'userdata');
currentpoint = xpos(1,1) + axisdata.xlow-1;    
currenttime = currentpoint / MEG.srate;
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
MEG = getappdata(hfig,'MEG');
        
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

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

if ~isequal(MEG.type,'MEG')
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
function menu_imaging_Callback(hObject, eventdata, handles)
% hObject    handle to menu_imaging (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

pop_meg_imaging(MEG);

% --------------------------------------------------------------------
% update the view window for the MEG data
function updatewindow()

MEG = getappdata(gcf,'MEG');
if isempty(MEG)
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
xlabels = [xlow-1:xlabelstep:xhigh] ./ MEG.srate;
xlabels = num2str(xlabels');
     
% y labels
channelmaxs = max(MEG.data(MEG.start:MEG.end,xlow:xhigh)');
channelmins = min(MEG.data(MEG.start:MEG.end,xlow:xhigh)');    
spacing = mean(channelmaxs-channelmins);  
ylimit = (MEG.dispchans+1)*spacing;
ylabelpositions = [0:spacing:MEG.dispchans*spacing];    
YLabels = MEG.labels(MEG.start:MEG.end);
YLabels = strvcat(YLabels); 
YLabels = flipud(str2mat(YLabels,' '));

% mean values for the current window
% meandata = mean(MEG.data(MEG.start:MEG.end,xlow:xhigh)');

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
for i = 1:MEG.dispchans
    chan = MEG.end-i+1;
    isbad = find(MEG.bad==chan);
    if isbad
        tmpcolor = badcolor;
    else
        tmpcolor = goodcolor;
    end
    
    meandata = mean(MEG.data(chan,xlow:xhigh));
    data = MEG.data(chan,xlow:xhigh) - meandata;
    plot(scale*data+i*spacing,'color', tmpcolor, 'clipping','on');
    
    % plot(scale*MEG.data(chan,xlow:xhigh)+i*spacing,'color', tmpcolor, 'clipping','on');
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
% Map time series on the MEG cap surface
function drawmap()

hfig = gcf; 

MEG = getappdata(hfig,'MEG');
if isempty(MEG)
    return;
end

% parameter setting
tstopoaxes = findobj(hfig,'tag','tstopoaxes');

model = getappdata(hfig,'model');
options = getappdata(hfig,'options');

ischanged = getappdata(hfig,'ischanged');

if ischanged 
    model.k = MEG.vidx;
    model.mag.labels = MEG.labels(model.k);
    model.mag.locations = MEG.locations.italybrain(model.k,:);
    
    model.X = MEG.locations.surf.x(model.k,1); 
    model.Y = MEG.locations.surf.y(model.k,1);   
   
    model.XI = MEG.locations.surf.x(:,1); 
    model.YI = MEG.locations.surf.y(:,1); 
    setappdata(hfig,'model',model);
end

currentpoint = getappdata(hfig,'current');
if currentpoint<1 | currentpoint>MEG.points
    return;
end

values = MEG.data(MEG.vidx,currentpoint);
VI = griddata(model.X, model.Y, values, model.XI, model.YI,'v4');

if isequal(options.caxis, 'global')
    minV = MEG.min;
    maxV = MEG.max;
else
    minV = min(values);
    maxV = max(values);
end
k = find(VI<minV);
VI(k) = minV;
k = find(VI>maxV);
VI(k) = maxV;    

% to display
axes(tstopoaxes);

% mapping
absV = max(abs(minV), abs(maxV));
caxis([-absV, absV]);

if ischanged
    cla;
    hold on;
    drawhead;
    options = getappdata(hfig,'options');

    % draw field map 
    options.handles.map = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                                                     'FaceLighting','phong',...
                                                     'Vertices',MEG.locations.italybrain,...
                                                     'LineStyle','none',...
                                                     'Faces',MEG.locations.surf.tri,...
                                                     'FaceColor','interp',...
                                                     'FaceAlpha',1,...
                                                     'EdgeColor','none',...
                                                     'FaceVertexCData',VI,...
                                                     'Visible',options.map);
    % test normals                          
%     len = length(MEG.locations.italybrain);
%     for i = 1:len
%         X1 = MEG.locations.italybrain(i,:);
%         X2 = MEG.locations.italybrain(i,:) + MEG.locations.normals.italybrain(i,:)*10;
%         plot3([X1(1), X2(1)], [X1(2), X2(2)], [X1(3), X2(3)]);
%     end
   
    % draw mags
    magcolor = [0.0  1.0  1.0];
    options.handles.mag = plot3(model.mag.locations(:,1), ...
                                                   model.mag.locations(:,2), ... 
                                                   model.mag.locations(:,3), ... 
                                                   'k.','LineWidth',4,'color', magcolor,...
                                                   'Visible',options.mag);
    % draw labels                                           
    textcolor = [0.0 0.0 0.0];
    locations = 1.05*model.mag.locations;
    options.handles.label =  text(locations(:,1), locations(:,2), locations(:,3), ... 
                                                   upper(model.mag.labels),'FontSize',8 ,...
                                                   'HorizontalAlignment','center', 'Color',textcolor,...
                                                   'Visible',options.label);             
    setappdata(hfig, 'options', options);                                           
else
    set(options.handles.map, 'FaceVertexCData', VI, 'Visible', options.map);
    set(options.handles.mag, 'Visible', options.mag);
    set(options.handles.label, 'Visible', options.label);
end
      
hclrbar = colorbar('peer',tstopoaxes);
set(tstopoaxes,'userdata',hclrbar);

if ischanged
    ischanged = 0;
    setappdata(hfig,'ischanged',ischanged);
end

% --------------------------------------------------------------------
function drawhead()
hfig = gcf;
model = getappdata(hfig,'model');
options = getappdata(hfig,'options');
options.handles.head = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                                                 'FaceLighting','phong',...
                                                 'Vertices',model.skin.italyskin.Vertices,...
                                                 'LineStyle','none',...
                                                 'Faces',model.skin.italyskin.Faces,...
                                                 'FaceColor','interp',...
                                                 'FaceAlpha',1,...
                                                 'EdgeColor','none',...
                                                 'FaceVertexCData',model.skin.italyskin.FaceVertexCData,...
                                                 'tag','skin',...
                                                 'visible',options.head);
lighting phong; % phong, gouraud
lightcolor = [0.5 0.5 0.5];
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);

setappdata(hfig, 'options', options);

% --------------------------------------------------------------------
function initwindow
MEG = getappdata(gcf,'MEG');
if isempty(MEG)
    return;
end

hfig = gcf; 
mainaxes = findobj(hfig, 'tag','mainaxes'); 
channelstodisplay = findobj(hfig, 'tag','channelstodisplay'); 

xlimit = 2000; % the topography limitation in the x axis.
if xlimit > MEG.points
   xlimit = MEG.points;
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
    
MEG.start = 1;
MEG.end = MEG.nbchan;
MEG.dispchans = MEG.nbchan;    
  
set(mainaxes, 'userdata', axisdata);
set(channelstodisplay, 'string', num2str(MEG.nbchan));
options = getappdata(gcf,'options');
options.epochstart = 1;
options.epochend = MEG.points;
setappdata(gcf,'options',options);
epochstart = findobj(hfig,'tag','epochstart');
epochend = findobj(hfig,'tag','epochend'); 
set(epochstart,'string',num2str(options.epochstart/MEG.srate));
set(epochend,'string',num2str(options.epochend/MEG.srate));

setappdata(hfig,'MEG',MEG);

updatewindow;

% --------------------------------------------------------------------
function txtreader_Callback(hObject, eventdata, handles)
% hObject    handle to txtreader (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');
ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

loadMEG = pop_meg_txtreader;
if isempty(loadMEG) | isempty(loadMEG.data)
    return;
end
MEG = loadMEG;

ALLMEG.MEGdata(ALLMEG.total+1) = {MEG};
ALLMEG.document(ALLMEG.total+1) = {MEG.name};
ALLMEG.total = ALLMEG.total + 1;
set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
CURRENT = ALLMEG.total;
    
setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
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
MEG = getappdata(gcf,'MEG');
ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

loadMEG = pop_meg_matreader;
if isempty(loadMEG) | isempty(loadMEG.data)
    return;
end
MEG = loadMEG;

ALLMEG.MEGdata(ALLMEG.total+1) = {MEG};
ALLMEG.document(ALLMEG.total+1) = {MEG.name};
ALLMEG.total = ALLMEG.total + 1;
set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
CURRENT = ALLMEG.total;
    
setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
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
function matwriter_Callback(hObject, eventdata, handles)
% hObject    handle to matwriter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end
    
[name, pathstr] = uiputfile('*.mat','Save Current MEG Data');
if name==0
    return;
end
addpath(pathstr);
Fullfilename=fullfile(pathstr,name);         
save(Fullfilename, 'MEG');

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

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end      

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);

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
     
if ischanged 
    model.k = MEG.vidx;
    model.mag.labels = MEG.labels(model.k);
    model.mag.locations = MEG.locations.italybrain(model.k,:);
    
    model.X = MEG.locations.surf.x(model.k,1); 
    model.Y = MEG.locations.surf.y(model.k,1);   
   
    model.XI = MEG.locations.surf.x(:,1); 
    model.YI = MEG.locations.surf.y(:,1); 
    setappdata(hfig,'model',model);
end

% if axisdata.frame>startpoint && axisdata.frame<endpoint
%     startpoint = axisdata.frame;
% end
startpoint = min(max(axisdata.frame,startpoint), endpoint);
linecolor = [0.0 0.0 0.0];
points = startpoint:3:endpoint;
numpnt = length(points);
if points(numpnt) ~= endpoint
    points(numpnt+1) = endpoint;
end

% The min and max values through the epoch.
data = MEG.data(MEG.vidx,startpoint:endpoint);
minV = min(min(data));
maxV = max(max(data));
absV = max(abs(minV), abs(maxV));
minV = -absV;
maxV = absV;

caxis([minV maxV]);
    
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
         playmov(mov, 'Field Mapping Movie of MEG Recordings');
         return;
    end
    
    values = MEG.data(MEG.vidx,i);
    VI = griddata(model.X,model.Y,values,model.XI,model.YI,'v4');

    k = find(VI<minV);
    VI(k) = minV;
    k = find(VI>maxV);
    VI(k) = maxV;    

    if ischanged
        cla;
        hold on;
        drawhead;
        options = getappdata(hfig,'options');

        % draw field map 
        options.handles.map = patch('SpecularStrength',0.2,'DiffuseStrength',0.8,'AmbientStrength',0.5,...
                                                         'FaceLighting','phong',...
                                                         'Vertices',MEG.locations.italybrain,...
                                                         'LineStyle','none',...
                                                         'Faces',MEG.locations.surf.tri,...
                                                         'FaceColor','interp',...
                                                         'FaceAlpha',1,...
                                                         'EdgeColor','none',...
                                                         'FaceVertexCData',VI,...
                                                         'Visible',options.map);

        % draw mags
        magcolor = [0.0  1.0  1.0];
        options.handles.mag = plot3(model.mag.locations(:,1), ...
                                                       model.mag.locations(:,2), ... 
                                                       model.mag.locations(:,3), ... 
                                                       'k.','LineWidth',4,'color', magcolor,...
                                                       'Visible',options.mag);
        % draw labels                                           
        textcolor = [0.0 0.0 0.0];
        locations = 1.05*model.mag.locations;
        options.handles.label =  text(locations(:,1), locations(:,2), locations(:,3), ... 
                                                       upper(model.mag.labels),'FontSize',8 ,...
                                                       'HorizontalAlignment','center', 'Color',textcolor,...
                                                       'Visible',options.label);             
        setappdata(hfig, 'options', options);        
        ischanged = 0;
        setappdata(hfig,'ischanged',ischanged);
    else
        options = getappdata(hfig,'options');
        set(options.handles.map, 'FaceVertexCData', VI, 'Visible', options.map);
        set(options.handles.mag, 'Visible', options.mag);
        set(options.handles.label, 'Visible', options.label);
    end

    hclrbar = colorbar('peer',tstopoaxes);
    set(tstopoaxes,'userdata',hclrbar);
    
    set(textcurrentpoint,'string',['Time: ' num2str(i/MEG.srate) ' s']);
    
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

playmov(mov, 'Field Mapping Movie of MEG Recordings');

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

MEG = getappdata(gcf,'MEG');
ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end      

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

starttime = startpoint / MEG.srate;
endtime = endpoint / MEG.srate;

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
startpoint = round(startend(1) * MEG.srate);
endpoint = round(startend(2) * MEG.srate);

startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

epochdata = MEG.data(:,startpoint:endpoint);
meandata = mean(epochdata,2);

MEG.data = MEG.data - repmat(meandata,1,MEG.points);
data = MEG.data(MEG.vidx,:);
MEG.min = min(min(data));
MEG.max = max(max(data));

% add the new MEG data to the ALLMEG,
% and add the item into the document file. 
MEG.name = [MEG.name '_Corrected'];
ALLMEG.MEGdata(ALLMEG.total+1) = {MEG};
ALLMEG.document(ALLMEG.total+1) = {MEG.name};
ALLMEG.total = ALLMEG.total + 1;
set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
CURRENT = ALLMEG.total;

setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
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
function menu_mags_Callback(hObject, eventdata, handles)
% hObject    handle to menu_mags (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

MEG = getappdata(gcf,'MEG');
 
if isempty(MEG) | isempty(MEG.data)
    return;
end  

hfig = gcf;
options = getappdata(hfig, 'options');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.mag = 'off';
else
    ischecked = 'on';
    options.mag = 'on';
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

MEG = getappdata(gcf,'MEG');
 
if isempty(MEG) | isempty(MEG.data)
    return;
end  

hfig = gcf;
options = getappdata(hfig, 'options');

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    options.label = 'off';
else
    ischecked = 'on';
    options.label = 'on';
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
    
MEG = getappdata(hfig,'MEG');
 
labels = lower(MEG.labels);
channelname = lower(get(handles.whichchannel,'string'));
idx1 = strmatch(channelname,labels,'exact');

idx2 = find(MEG.bad==idx1); % if it is a bad chnnel
idx3 = find(MEG.vidx==idx1);

if isempty(idx2) && isempty(idx3)
    helpdlg([upper(channelname) ' is an automatically processed channel !']);
    return;
end

if isempty(idx2) % is good channel, change to bad
    MEG.bad(length(MEG.bad)+1) = idx1;
    MEG.bad = sort(MEG.bad);
    MEG.vidx(idx3) = [];    % remove it from good channels
else % is bad channel, change to good
    MEG.bad(idx2) = [];
    MEG.vidx(length(MEG.vidx)+1) = idx1; % add it to good channels
    MEG.vidx = sort(MEG.vidx);      
end

setappdata(hfig,'ischanged',1);
setappdata(hfig,'MEG',MEG);

updatewindow;


% --------------------------------------------------------------------
function menu_timefrequency_Callback(hObject, eventdata, handles)
% hObject    handle to menu_timefrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hfig = gcf;
MEG = getappdata(hfig,'MEG');

labels = lower(MEG.labels);
channelname = lower(get(handles.whichchannel,'string'));
idx = strmatch(channelname,labels,'exact');

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

ts = MEG.data(idx,startpoint:endpoint);
srate = MEG.srate;
starttime = (startpoint - 1)/MEG.srate;
% pos1 = get(hfig,'CurrentPoint');
% pos2 = get(hfig,'position');
% pos = pos1 + pos2(1:2);
pos = [];

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

MEG = getappdata(gcf,'MEG');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end

clipevent = questdlg('To get the epoch specified ?','','Yes','Cancel','Cancel');
if ~strcmp(clipevent, 'Yes')
    return;
end   

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;

startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);

if startpoint > endpoint
    errordlg('The epoch specification is not right!');
    return;
end

if endpoint == startpoint
    msgbox('The epoch is too small, need 2 points at least!','','help','modal');
    return;
end

MEG.points = endpoint - startpoint + 1;
MEG.data = MEG.data(:,startpoint:endpoint);

data1 = MEG.data(MEG.vidx,:);
MEG.min = min(min(data1));
MEG.max = max(max(data1));

ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

% add the new MEG data to the ALLMEG,
% and add the item into the document file. 
MEG.name = [MEG.name '_Epoch_Gotten'];
ALLMEG.MEGdata(ALLMEG.total+1) = {MEG};
ALLMEG.document(ALLMEG.total+1) = {MEG.name};
ALLMEG.total = ALLMEG.total + 1;
set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
CURRENT = ALLMEG.total;

setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
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
function menu_interpbad_Callback(hObject, eventdata, handles)
% hObject    handle to menu_interpbad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
MEG = getappdata(hfig,'MEG');
if isempty(MEG.bad)
    helpdlg('There is no bad channel !');
    return;
end

model.mag.locations = MEG.locations.italybrain(MEG.vidx,:);

X(:,1) = MEG.locations.italybrain(MEG.vidx,1);
X(:,2) = MEG.locations.italybrain(MEG.vidx,2);
X(:,3) = MEG.locations.italybrain(MEG.vidx,3);

numbad = length(MEG.bad);
XI(:,1) = MEG.locations.italybrain(MEG.bad,1);
XI(:,2) = MEG.locations.italybrain(MEG.bad,2);
XI(:,3) = MEG.locations.italybrain(MEG.bad,3);

n = 4;
for k = 1:numbad
    idx = MEG.bad(k);
    dists = sqrt( (X(:,1)-XI(k,1)).^2 + (X(:,2)-XI(k,2)).^2 + (X(:,3)-XI(k,3)).^2);
    [dists,idxs] = sort(dists);
    idxs_N =  MEG.vidx(idxs(1:n));
    dists_N = (dists(1:n)).^2;
    coefs_N = 1 ./ dists_N;
    coefs_N = coefs_N / sum(coefs_N);
    
    MEG.data(idx,:) = coefs_N' * MEG.data(idxs_N,:);
end

MEG.vidx = sort([MEG.vidx, MEG.bad]);
MEG.bad = [];
data = MEG.data(MEG.vidx,:);
MEG.min = min(min(data));
MEG.max = max(max(data));
setappdata(hfig,'MEG',MEG);

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
MEG = getappdata(hfig,'MEG');
mainaxes = findobj(hfig,'tag','mainaxes');
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
axisdata = get(mainaxes, 'userdata');
currentpoint = xpos(1,1) + axisdata.xlow-1;     
currenttime = currentpoint / MEG.srate;
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
MEG = getappdata(hfig,'MEG');
mainaxes = findobj(hfig,'tag','mainaxes');
linehandle = findobj(hfig,'tag','linetag');
xpos =  get(linehandle,'xdata');
axisdata = get(mainaxes, 'userdata');
currentpoint = xpos(1,1) + axisdata.xlow-1;     
currenttime = currentpoint / MEG.srate;
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
% capobj(handles.tstopoaxes, 'Field Mapping Image of MEG');

% --------------------------------------------------------------------
function menu_playmov_Callback(hObject, eventdata, handles)
% hObject    handle to menu_playmov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
playmov([], 'Field Mapping Movie of MEG');



% % --------------------------------------------------------------------
% function menu_reference_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_reference (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% hfig = gcf;
% MEG = getappdata(hfig,'MEG');
% list = 1:MEG.nbchan;
% if ~isempty(MEG.bad)
%     list(MEG.bad) = [];
% end
% labels = MEG.labels(list);
% default = [];
% [sel,ok] = listdlg('ListString',labels,'Name','Re-reference Channels','InitialValue',default);
% if ok == 0 | isempty(sel)
%     return;
% end
% 
% selected = list(sel);
% ct = 0;
% h = waitbar(0,'Re-referencing, please wait...');
% for i = 1: MEG.points
%    reference = mean(MEG.data(selected,i));
%    MEG.data(:,i) = MEG.data(:,i) - reference;
%    ct = ct + 1; 
%    if ~mod(ct, 10)
%       waitbar(ct/MEG.points);
%    end
% end
% waitbar(1);
% close(h);
% 
% data = MEG.data(MEG.vidx,:);
% MEG.min = min(min(data));
% MEG.max = max(max(data));
% 
% setappdata(hfig,'MEG',MEG);
% updatewindow;



% --------------------------------------------------------------------
function menu_map_Callback(hObject, eventdata, handles)
% hObject    handle to menu_map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
MEG = getappdata(gcf,'MEG');
 
if isempty(MEG) | isempty(MEG.data)
    return;
end  

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

setappdata(hfig,'options',options);
set(hObject,'checked',ischecked);

tstopoaxes = findobj(hfig,'tag','tstopoaxes');
set(hfig,'CurrentAxes',tstopoaxes);
drawmap;
drawnow expose;  

% --------------------------------------------------------------------
function menu_head_Callback(hObject, eventdata, handles)
% hObject    handle to menu_head (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
MEG = getappdata(gcf,'MEG');
 
if isempty(MEG) | isempty(MEG.data)
    return;
end  

hfig = gcf;
options = getappdata(hfig, 'options');

tstopoaxes = findobj(hfig,'tag','tstopoaxes');
set(hfig,'CurrentAxes',tstopoaxes);

ischecked = lower(get(hObject,'checked'));
if isequal(ischecked,'on')
    ischecked = 'off';
    set(options.handles.head, 'Visible', 'off');
else
    ischecked = 'on';
    set(options.handles.head, 'Visible', 'on');
end
drawnow expose;  

set(hObject,'checked',ischecked);


% --------------------------------------------------------------------
function menu_GFP_Callback(hObject, eventdata, handles)
% hObject    handle to menu_GFP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
MEG = getappdata(hfig,'MEG');

options = getappdata(gcf,'options');
startpoint = options.epochstart;
endpoint = options.epochend;
startpoint = min(max(startpoint,1),MEG.points);
endpoint = min(max(endpoint,1),MEG.points);
if startpoint > endpoint
    return;
end

% compute GFP with valid channels
ts = MEG.data(MEG.vidx,startpoint:endpoint);
srate = MEG.srate;
starttime = (startpoint - 1)/MEG.srate;
% pos1 = get(hfig,'CurrentPoint');
% pos2 = get(hfig,'position');
% pos = pos1 + pos2(1:2);
pos = [];

% compute global field power for the selected epoch.
% ECOM_GFP(ts, srate, starttime, pos);
ECOM_Butterfly(ts, srate, starttime, pos);


% --------------------------------------------------------------------
function menu_COI_Callback(hObject, eventdata, handles)
% hObject    handle to menu_COI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;    
MEG = getappdata(hfig,'MEG');
vidx = sort([MEG.vidx, MEG.bad]); % automatically processed channels are excluded

default = [];
[sel,ok] = listdlg('ListString',MEG.labels(vidx),'Name','Interested Channels','InitialValue',default);
if ok == 0 | isempty(sel)
    return;
end

MEG.vidx = vidx(sel); % interested channels
MEG.bad = vidx; % the rest are considered as bad channels
MEG.bad(sel) = [];

setappdata(hfig,'ischanged',1);
setappdata(hfig,'MEG',MEG);

updatewindow;


% --------------------------------------------------------------------
function menu_FM_Callback(hObject, eventdata, handles)
% hObject    handle to menu_FM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capobj(handles.tstopoaxes, 'Field Mapping Image of MEG');

% --------------------------------------------------------------------
function menu_waveforms_Callback(hObject, eventdata, handles)
% hObject    handle to menu_waveforms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
capaxis(handles.mainaxes, 'MEG Waveforms', 0);


% --------------------------------------------------------------------
function menu_reference_Callback(hObject, eventdata, handles)
% hObject    handle to menu_reference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
MEG = getappdata(gcf,'MEG');
ALLMEG = getappdata(gcf,'ALLMEG');
CURRENT = getappdata(gcf,'CURRENT');

if isempty(MEG) | isempty(MEG.data)
    helpdlg('Please import MEG data!');
    return;
end    

% use uiwait and uiresume to get input parameters from the pop figure.
for i = 1:MEG.points
    avg = mean(MEG.data(MEG.vidx,i));
    MEG.data(MEG.vidx,i) = MEG.data(MEG.vidx,i) - avg;
end

data1 = MEG.data(MEG.vidx,:);
MEG.min = min(min(data1));
MEG.max = max(max(data1));

% add the new MEG data to the ALLMEG,
% and add the item into the document file. 
MEG.name = [MEG.name '_Re-referenced'];
ALLMEG.MEGdata(ALLMEG.total+1) = {MEG};
ALLMEG.document(ALLMEG.total+1) = {MEG.name};
ALLMEG.total = ALLMEG.total + 1;
set(handles.listbox,'String',ALLMEG.document,'value',ALLMEG.total);
CURRENT = ALLMEG.total;

setappdata(gcf,'MEG',MEG);
setappdata(gcf,'ALLMEG',ALLMEG);
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

