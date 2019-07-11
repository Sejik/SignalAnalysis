function varargout = multi_channel_sync_gui(varargin)
% MULTI_CHANNEL_SYNC_GUI MATLAB code for multi_channel_sync_gui.fig
%      MULTI_CHANNEL_SYNC_GUI, by itself, creates a new MULTI_CHANNEL_SYNC_GUI or raises the existing
%      singleton*.
%
%      H = MULTI_CHANNEL_SYNC_GUI returns the handle to a new MULTI_CHANNEL_SYNC_GUI or the handle to
%      the existing singleton*.
%
%      MULTI_CHANNEL_SYNC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTI_CHANNEL_SYNC_GUI.M with the given input arguments.
%
%      MULTI_CHANNEL_SYNC_GUI('Property','Value',...) creates a new MULTI_CHANNEL_SYNC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multi_channel_sync_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multi_channel_sync_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multi_channel_sync_gui

% Last Modified by GUIDE v2.5 24-Oct-2012 15:08:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multi_channel_sync_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @multi_channel_sync_gui_OutputFcn, ...
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


% --- Executes just before multi_channel_sync_gui is made visible.
function multi_channel_sync_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multi_channel_sync_gui (see VARARGIN)

% Choose default command line output for multi_channel_sync_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
if (~isempty(arbConfig))
    % VISA addresses of M8190A
    addr = arbConfig.visaAddr;
    set(handles.editVisaAddress1, 'String', addr);
    if (isfield(arbConfig, 'visaAddr2'))
        addr2 = arbConfig.visaAddr2;
    else
        % try to guess the address for the slave AWG
        addr2 = regexprep(addr, '::inst([0-9]*)', '::inst${num2str(str2double($1)+1)}');
        addr2 = regexprep(addr2, '::hislip([0-9]*)', '::hislip${num2str(str2double($1)+1)}');
        addr2 = regexprep(addr2, '::([0-9]*)::', '::${num2str(str2double($1)+1)}::');
    end
    set(handles.editVisaAddress2, 'String', addr2);
    % VISA address of scope
    if (isfield(arbConfig, 'visaAddrScope'))
        set(handles.editVisaAddressScope, 'String', arbConfig.visaAddrScope);
        set(handles.editVisaAddressScope, 'Enable', 'on');
    end
    % Mode
    if (isempty(strfind(arbConfig.model, 'bit')))
        errordlg({'Currently, only M8190A direct modes (12bit or 14bit) are' ...
            'implemented in this demo utility.' ...
            ' ' ...
            'Please use the "Configure Instrument Connection" utility' ...
            'to configure M8190A 12bit or 14bit mode under "Instrument model"'});
        close(handles.figure1);
        return;
    end
    arbModels = get(handles.popupmenuMode, 'String');
    idx = find(strcmp(arbModels, arbConfig.model));
    if (idx > 0)
        set(handles.popupmenuMode, 'Value', idx);
    end
    set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.maximumSampleRate'));
end
set(handles.popupmenuWaveform, 'Value', 3);
% UIWAIT makes multi_channel_sync_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = multi_channel_sync_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editVisaAddress1_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddress1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddress1 as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddress1 as a double
handles.connectionTest(1) = 0;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editVisaAddress1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddress1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestConnection1.
function pushbuttonTestConnection1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestConnection1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clear eventdata;
eventdata.awgNum = 1;
eventdata.editVisaAddress = handles.editVisaAddress1;
testConnection(hObject, eventdata, handles);


function editVisaAddress2_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddress2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddress2 as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddress2 as a double
handles.connectionTest(2) = 0;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editVisaAddress2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddress2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestConnection2.
function pushbuttonTestConnection2_Callback(hObject,eventdata, handles)
% hObject    handle to pushbuttonTestConnection2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clear eventdata;
eventdata.awgNum = 2;
eventdata.editVisaAddress = handles.editVisaAddress2;
result = testConnection(hObject, eventdata, handles);
if (result)
    data = load('arbConfig.mat');
    data.arbConfig.visaAddr2 = strtrim(get(handles.editVisaAddress2, 'String'));
    save('arbConfig.mat', '-struct', 'data');
end


function result = testConnection(hObject, eventdata, handles)
handles.connectionTest(eventdata.awgNum) = 0;
arb = makeArbConfig(handles, eventdata.awgNum);
if (iqoptcheck(arb, 'bit', 'SEQ'))
    set(hObject, 'Background', 'green');
    handles.connectionTest(eventdata.awgNum) = 1;
    result = 1;
else
    set(hObject, 'Background', 'red');
    handles.connectionTest(eventdata.awgNum) = 0;
    result = 0;
end
guidata(hObject, handles);


% --- Executes on button press in pushbuttonConnectionDiagram.
function pushbuttonConnectionDiagram_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConnectionDiagram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path = [fileparts(which('multi_channel_sync_gui.m')) '\M8190A_sync_example\M8190A_sync_setup.gif'];
try
    system(path);
catch ex
    errordlg(['Can''t display: ' path]);
end


% --- Executes on button press in pushbuttonManualDeskew.
function pushbuttonManualDeskew_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonManualDeskew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (~isfield(handles, 'connectionTest') || length(handles.connectionTest) < 2 || ~handles.connectionTest(1) || ~handles.connectionTest(2))
    errordlg({'Please enter the VISA addresses for the two M8190A modules' ...
        'and press the "Test Connection" buttons to verify the connectivity'});
    return;
end
hMsgBox = msgbox({'Downloading Calibration data to both AWG modules...' ...
    ' ' ...
    'Please observe the analog outputs (resp. marker outputs) of both' ...
    'modules on an oscilloscope and use the Soft Front Panel to de-skew' ...
    'the channels'}, 'replace');
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
slaveClkList = get(handles.popupmenuSlaveClk, 'String');
slaveClk = slaveClkList{get(handles.popupmenuSlaveClk, 'Value')};
useMarkers = get(handles.radiobuttonMarkersConnected, 'Value');
triggered = get(handles.radiobuttonTriggered, 'Value');
waveformID = get(handles.popupmenuWaveform, 'Value');
multi_channel_sync('cmd', 'manualDeskew', ...
    'sampleRate', sampleRate, 'slaveClk', slaveClk, 'useMarkers', useMarkers, ...
    'triggered', triggered, 'waveformID', waveformID, ...
    'arbConfig', {makeArbConfig(handles, 1) makeArbConfig(handles, 2)});
pause(2);
try
    close(hMsgBox);
catch
end
enableStartStop(handles);


function enableStartStop(handles)
set(handles.pushbuttonStart, 'Enable', 'on');
set(handles.pushbuttonStop, 'Enable', 'on');
set(handles.pushbuttonDownload, 'Enable', 'on');
set(handles.pushbuttonTrigger, 'Enable', 'on');
set(handles.textWaveform, 'Enable', 'on');
set(handles.popupmenuWaveform, 'Enable', 'on');
set(handles.radiobuttonTriggered, 'Enable', 'on');
set(handles.radiobuttonContinuous, 'Enable', 'on');


% --- Executes on button press in pushbuttonAutoDeskew.
function pushbuttonAutoDeskew_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAutoDeskew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (~isfield(handles, 'connectionTest') || length(handles.connectionTest) < 3 || ...
        ~handles.connectionTest(1) || ~handles.connectionTest(2) || ~handles.connectionTest(3))
    errordlg({'Please enter the VISA addresses for the two M8190A modules and the scope.' ...
        'Then press the "Test Connection" buttons to verify the connectivity'});
    return;
end
hMsgBox = msgbox({'Downloading Calibration data to both AWG modules...'}, 'replace');
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
clear scopeCfg;
scopeCfg.connectionType = 'visa';
scopeCfg.visaAddr = strtrim(get(handles.editVisaAddressScope, 'String'));
slaveClkList = get(handles.popupmenuSlaveClk, 'String');
slaveClk = slaveClkList{get(handles.popupmenuSlaveClk, 'Value')};
useMarkers = get(handles.radiobuttonMarkersConnected, 'Value');
triggered = get(handles.radiobuttonTriggered, 'Value');
waveformID = get(handles.popupmenuWaveform, 'Value');
multi_channel_sync('cmd', 'autoDeskew', ...
    'sampleRate', sampleRate, 'slaveClk', slaveClk, 'useMarkers', useMarkers, ...
    'triggered', triggered, 'waveformID', waveformID, ...
    'arbConfig', {makeArbConfig(handles, 1) makeArbConfig(handles, 2)}, ...
    'scopeConfig', scopeCfg);
try
    close(hMsgBox);
catch
end
enableStartStop(handles);


function editVisaAddressScope_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddressScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddressScope as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddressScope as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddressScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddressScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestConnectionScope.
function pushbuttonTestConnectionScope_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestConnectionScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scopeCfg.connectionType = 'visa';
scopeCfg.visaAddr = get(handles.editVisaAddressScope, 'String');
found = 0;
f = iqopen(scopeCfg);
if (~isempty(f))
    res = query(f, '*IDN?');
    if (~isempty(strfind(res, 'Agilent Technologies,DSO')) || ~isempty(strfind(res, 'Agilent Technologies,DSA')))
        found = 1;
    end
    fclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
    handles.connectionTest(3) = 1;
    % if connection check is successful, store the scope address in
    % arbConfig, so that it comes up as a default next time
    data = load('arbConfig.mat');
    data.arbConfig.visaAddrScope = strtrim(get(handles.editVisaAddressScope, 'String'));
    save('arbConfig.mat', '-struct', 'data');
else
    set(hObject, 'Background', 'red');
    handles.connectionTest(3) = 0;
end
guidata(hObject, handles);


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenuWaveform.
function popupmenuWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuWaveform contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuWaveform


% --- Executes during object creation, after setting all properties.
function popupmenuWaveform_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonStart.
function pushbuttonStart_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
slaveClkList = get(handles.popupmenuSlaveClk, 'String');
slaveClk = slaveClkList{get(handles.popupmenuSlaveClk, 'Value')};
useMarkers = get(handles.radiobuttonMarkersConnected, 'Value');
triggered = get(handles.radiobuttonTriggered, 'Value');
waveformID = get(handles.popupmenuWaveform, 'Value');
if (isfield(handles, 'connectionTest') && length(handles.connectionTest) >= 3 && handles.connectionTest(3))
    scopeCfg = makeArbConfig(handles, 3);
else
    scopeCfg = [];
end
multi_channel_sync('cmd', 'start', ...
    'sampleRate', sampleRate, 'slaveClk', slaveClk, 'useMarkers', useMarkers, ...
    'triggered', triggered, 'waveformID', waveformID, ...
    'scopeConfig', scopeCfg, ...
    'arbConfig', {makeArbConfig(handles, 1) makeArbConfig(handles, 2)});



% --- Executes on button press in pushbuttonStop.
function pushbuttonStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
multi_channel_sync('cmd', 'stop', ...
    'arbConfig', {makeArbConfig(handles, 1) makeArbConfig(handles, 2)});


% --- Executes on button press in pushbuttonTrigger.
function pushbuttonTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('trigger', [], 'arbConfig', makeArbConfig(handles, 1));


% --- Executes on selection change in popupmenuMode.
function popupmenuMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMode


% --- Executes during object creation, after setting all properties.
function popupmenuMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
arbConfig = makeArbConfig(handles, 1);
if (isscalar(value) && value >= arbConfig.minimumSampleRate && value <= arbConfig.maximumSampleRate)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function cfg = makeArbConfig(handles, awgNum)
modeList = cellstr(get(handles.popupmenuMode, 'String'));
mode = modeList{get(handles.popupmenuMode, 'Value')};
clear cfg;
cfg.model = mode;
cfg.connectionType = 'visa';
switch (awgNum)
    case 1
        cfg.visaAddr = get(handles.editVisaAddress1, 'String');
        cfg = loadArbConfig(cfg);
    case 2
        cfg.visaAddr = get(handles.editVisaAddress2, 'String');
        cfg = loadArbConfig(cfg);
    case 3
        cfg.visaAddr = get(handles.editVisaAddressScope, 'String');
end


% --- Executes on selection change in popupmenuSlaveClk.
function popupmenuSlaveClk_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSlaveClk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSlaveClk contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSlaveClk


% --- Executes during object creation, after setting all properties.
function popupmenuSlaveClk_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSlaveClk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM1C1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM1C1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM1C1 as a double


% --- Executes during object creation, after setting all properties.
function editSkewM1C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM1C2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM1C2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM1C2 as a double


% --- Executes during object creation, after setting all properties.
function editSkewM1C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM2C1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM2C1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM2C1 as a double


% --- Executes during object creation, after setting all properties.
function editSkewM2C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM2C2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM2C2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM2C2 as a double


% --- Executes during object creation, after setting all properties.
function editSkewM2C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSkewM1C1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderSkewM1C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM1C2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderSkewM1C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM2C1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderSkewM2C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM2C2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderSkewM2C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
