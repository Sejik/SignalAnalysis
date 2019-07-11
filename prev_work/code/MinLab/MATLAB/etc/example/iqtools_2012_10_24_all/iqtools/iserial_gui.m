function varargout = iserial_gui(varargin)
% ISERIAL_GUI MATLAB code for iserial_gui.fig
%      ISERIAL_GUI, by itself, creates a new ISERIAL_GUI or raises the existing
%      singleton*.
%
%      H = ISERIAL_GUI returns the handle to a new ISERIAL_GUI or the handle to
%      the existing singleton*.
%
%      ISERIAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ISERIAL_GUI.M with the given input arguments.
%
%      ISERIAL_GUI('Property','Value',...) creates a new ISERIAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iserial_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iserial_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iserial_gui

% Last Modified by GUIDE v2.5 22-Sep-2012 09:24:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iserial_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iserial_gui_OutputFcn, ...
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


% --- Executes just before iserial_gui is made visible.
function iserial_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iserial_gui (see VARARGIN)

% Choose default command line output for iserial_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

set(handles.popupmenuDownload, 'Value', 3);
arbConfig = loadArbConfig();
switch arbConfig.model
    case '81180A'
        dataRate = 1e9;
        numBits = 128;
    case {'M8190A', 'M8190A_base', 'M8190A_14bit' }
        dataRate = 1e9;
        numBits = 192;
    case 'M8190A_12bit'
        dataRate = 3e9;
        numBits = 256;
    case 'M8190A_prototype'
        dataRate = 1e9;
        numBits = 200;
    case 'M933xA'
        dataRate = 250e6;
        numBits = 128;
    otherwise
        dataRate = 250e6;
        numBits = 128;
end
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.editDataRate, 'String', sprintf('%g', dataRate));
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.editNumBits, 'String', num2str(numBits));
if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editDataRate, 'TooltipString', sprintf([ ...
    'Enter the data rate for the signal in symbols per second.\n' ...
    'The utility will adjust the sample rate and oversampling to exactly match\n' ...
    'the specified data rate.']));
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'If you enter the sample rate manually, the data rate might not be exact.']));
set(handles.popupmenuDataType, 'TooltipString', sprintf([ ...
    'Select the format and type of data. ''Random'', ''Clock'' and ''PRBS'' \n' ...
    'generate binary data. ''PAMx'' and ''MLT-3'' generate multi-level signals']));
set(handles.editNumBits, 'TooltipString', sprintf([ ...
    'Enter the number of random bits to be generated. For User Defined data pattern.\n' ...
    'this field is ignored.']));
set(handles.editUserData, 'TooltipString', sprintf([ ...
    'Enter a user defined data pattern. The pattern can be a list of values separated by\n' ...
    'spaces or a MATLAB expression that evaluates to a vector. The values must be in the\n' ...
    '0 or 1 (for binary patterns). For multi-level patterns, values can be anywhere in the\n', ...
    'range 0...1.   Example: repmat([0 1],1,48)  will generate a 96 bit clock pattern.\n' ...
    '0 0 0 1 0 0 0 1 0 1 0 1 1 0 1 1 0 1 0 1  will generate the specified pattern.']));
set(handles.editTransitionTime, 'TooltipString', sprintf([ ...
    'Enter the transition time as portion of a UI. Although a zero transition time can be\n' ...
    'entered, the actual transition time will be limited by the hardware.  If you want to\n' ...
    'apply jitter or you have non-integer relationship between data rate and sample rate,\n' ...
    'you should choose the transition time big enough to contain at least two samples.']));
set(handles.editSJfreq, 'TooltipString', sprintf([ ...
    'Enter the frequency for sinusoidal jitter. Note that the smallest frequency for SJ\n' ...
    'is limited by the number of bits the oversampling rate because the utility must fit\n' ...
    'at least one full cycle of the jitter into the waveform']));
set(handles.editSJpp, 'TooltipString', sprintf([ ...
    'Enter the peak-to-peak deviation for sinusoidal jitter in portions of UI.\n' ...
    'Example: For a 1 Gb/s data rate, a 0.2 UI jitter will be 200ps (peak-to-peak)']));
set(handles.editRJpp, 'TooltipString', sprintf([ ...
    'Enter the peak-to-peak deviation for random jitter in portions of UI.\n' ...
    'RJ is simulated as a (near-)gaussian distribution with a maximum deviation\n' ...
    'of 6 sigma.']));
set(handles.editNoise, 'TooltipString', sprintf([ ...
    'Enter the amount of vertical noise that is added to waveform in the range 0 to 1.\n' ...
    'Zero means no noise, 1 means the same amplitude of noise as the signal itself.']));
set(handles.editISI, 'TooltipString', sprintf([ ...
    'Enter the amount of ISI in the range 0 to 1. Zero means no ISI at all, 1 is a\n' ...
    'completely distorted signal. The practial maximum is around 0.8.  ISI is modelled\n' ...
    'as a simple decay function (y=e^(-ax))']));
set(handles.editSegment, 'TooltipString', sprintf([ ...
    'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
    'If you download to segment #1, all other segments will be automatically\n' ...
    'deleted.']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The plot will show the downloaded waveform along with the (mathematical) jitter analysis']));
set(handles.popupmenuDownload, 'TooltipString', sprintf([ ...
    'Select into which AWG channels the data is loaded.\n' ...
    'For 1+2, the identical data will be downloaded to both channels']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
end
arbConfig = loadArbConfig();
if (~exist('arbConfig', 'var') || isempty(arbConfig))
    errordlg({'No instrument connection configured. ' ...
        'Please use the "Configuration" utility to' ...
        'configure the instrument connection'});
    close(handles.iqtool);
    return;
end
if (~isempty(strfind(arbConfig.model, 'DUC')))
    errordlg({'Can not work in DUC mode. ' ...
        'Please use the "Configuration" utility' ...
        'and select a non-DUC mode'});
    close(handles.iqtool);
    return;
end
% UIWAIT makes iserial_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iserial_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;


function editDataRate_Callback(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDataRate as text
%        str2double(get(hObject,'String')) returns contents of editDataRate as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 1e3 && value <= 8e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDataRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
checkfields(hObject, 0, handles);

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



function editNumBits_Callback(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumBits as text
%        str2double(get(hObject,'String')) returns contents of editNumBits as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 2 && value <= 10e6)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumBits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSJpp as text
%        str2double(get(hObject,'String')) returns contents of editSJpp as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editUserData_Callback(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editUserData as text
%        str2double(get(hObject,'String')) returns contents of editUserData as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && length(value) >= 2 && length(value) <= 10e6)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editUserData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDataType.
function popupmenuDataType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDataType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDataType
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
if (strcmp(dataType, 'User defined'))
    set(handles.editNumBits, 'Enable', 'Off');
    set(handles.editUserData, 'Enable', 'On');
else
    set(handles.editNumBits, 'Enable', 'On');
    set(handles.editUserData, 'Enable', 'Off');
end
switch dataType
    case 'PRBS7'
        set(handles.editNumBits, 'String', '2^7 - 1');
    case 'PRBS9'
        set(handles.editNumBits, 'String', '2^9 - 1');
    case 'PRBS11'
        set(handles.editNumBits, 'String', '2^11 - 1');
    case 'PRBS15'
        set(handles.editNumBits, 'String', '2^15 - 1');
    otherwise
end


% --- Executes during object creation, after setting all properties.
function popupmenuDataType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAutoSampleRate.
function checkboxAutoSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxAutoSampleRate
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
if (autoSamples)
    set(handles.editSampleRate, 'Enable', 'off');
else
    set(handles.editSampleRate, 'Enable', 'on');
end



function editNoise_Callback(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNoise as text
%        str2double(get(hObject,'String')) returns contents of editNoise as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderNoise, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[s, fs, dataRate] = calc_serial(handles);
isplot(s, fs, dataRate);

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
downloadList = cellstr(get(handles.popupmenuDownload,'String'));
downloadToChannel = downloadList{get(handles.popupmenuDownload,'Value')};
switch downloadToChannel
    case 'Data to Ch1'
        downloadToChannel = 'I to channel 1';
    case 'Data to Ch2'
        downloadToChannel = 'I to channel 2';
    case 'Data to Ch1+Ch2'
        downloadToChannel = 'I+Q to channel 1+2';
end
[s, fs, dataRate] = calc_serial(handles);
segmentNum = evalin('base', get(handles.editSegment, 'String'));
iqdownload(complex(s, s), fs, 'downloadToChannel', downloadToChannel, ...
    'segmentNumber', segmentNum);
close(hMsgBox);


function editRJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRJpp as text
%        str2double(get(hObject,'String')) returns contents of editRJpp as a double


% --- Executes during object creation, after setting all properties.
function editRJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editISI_Callback(hObject, eventdata, handles)
% hObject    handle to editISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editISI as text
%        str2double(get(hObject,'String')) returns contents of editISI as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderISI, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editISI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSJfreq_Callback(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSJfreq as text
%        str2double(get(hObject,'String')) returns contents of editSJfreq as a double


% --- Executes during object creation, after setting all properties.
function editSJfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editTransitionTime_Callback(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTransitionTime as text
%        str2double(get(hObject,'String')) returns contents of editTransitionTime as a double


% --- Executes during object creation, after setting all properties.
function editTransitionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderNoise_Callback(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editNoise, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function sliderISI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function sliderISI_Callback(hObject, eventdata, handles)
% hObject    handle to sliderISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
value = get(hObject, 'Value');
set(handles.editISI, 'String', sprintf('%.2g', value));


% --- Executes on selection change in popupmenuDownload.
function popupmenuDownload_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDownload contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDownload


% --- Executes during object creation, after setting all properties.
function popupmenuDownload_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplitude as text
%        str2double(get(hObject,'String')) returns contents of editAmplitude as a double


% --- Executes during object creation, after setting all properties.
function editAmplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSegment as text
%        str2double(get(hObject,'String')) returns contents of editSegment as a double
checkfields(hObject, 0, handles);


% --- Executes during object creation, after setting all properties.
function editSegment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --------------------------------------------------------------------
function preset_Callback(hObject, eventdata, handles)
% hObject    handle to preset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function clock_8gbps_Callback(hObject, eventdata, handles)
% hObject    handle to clock_8gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '8e9');
set(handles.editSampleRate, 'String', '8e9');
set(handles.checkboxAutoSampleRate, 'Value', 0);
set(handles.popupmenuDataType, 'Value', 2);
set(handles.editNumBits, 'String', '192');
set(handles.editTransitionTime, 'String', '0');
set(handles.editSJfreq, 'String', '0');
set(handles.editSJpp, 'String', '0');
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
set(handles.sliderNoise, 'Value', 0);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);


% --------------------------------------------------------------------
function mlt3_125mbps_Callback(hObject, eventdata, handles)
% hObject    handle to mlt3_125mbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '125e6');
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.popupmenuDataType, 'Value', 3);
set(handles.editNumBits, 'String', '192');
set(handles.editTransitionTime, 'String', '0.3');
set(handles.editSJfreq, 'String', '0');
set(handles.editSJpp, 'String', '0');
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
set(handles.sliderNoise, 'Value', 0);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);


% --------------------------------------------------------------------
function random_1gbps_Callback(hObject, eventdata, handles)
% hObject    handle to random_1gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '1e9');
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.popupmenuDataType, 'Value', 1);
set(handles.editNumBits, 'String', '192');
set(handles.editTransitionTime, 'String', '0.3');
set(handles.editSJfreq, 'String', '10e6');
set(handles.editSJpp, 'String', '0.3');
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
set(handles.sliderNoise, 'Value', 0);
set(handles.editISI, 'String', '0.7');
set(handles.sliderISI, 'Value', 0.7);


function [s, fs, dataRate] = calc_serial(handles)
dataRate = evalin('base', get(handles.editDataRate, 'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
autoSampleRate = get(handles.checkboxAutoSampleRate, 'Value');
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
numBits = evalin('base', get(handles.editNumBits, 'String'));
userData = evalin('base', ['[' get(handles.editUserData, 'String') ']']);
tTime = evalin('base', get(handles.editTransitionTime, 'String'));
SJfreq = evalin('base', get(handles.editSJfreq, 'String'));
SJpp = evalin('base', get(handles.editSJpp, 'String'));
RJpp = evalin('base', get(handles.editRJpp, 'String'));
noise = evalin('base', get(handles.editNoise, 'String'));
isi = evalin('base', get(handles.editISI, 'String'));
amplitude = evalin('base', get(handles.editAmplitude, 'String'));
if (autoSampleRate)
    sampleRate = 0;
end
if (strcmp(dataType, 'User defined'))
    data = userData;
else
    data = dataType;
end

[s, fs] = iserial('dataRate', dataRate, 'sampleRate', sampleRate, ...
    'numBits', numBits, 'data', data, 'SJfreq', SJfreq, 'SJpp', SJpp, ...
    'RJpp', RJpp, 'noise', noise, 'isi', isi, 'transitionTime', tTime, ...
    'amplitude', amplitude);
set(handles.editSampleRate, 'String', sprintf('%g', fs));
assignin('base', 'signal', s);
assignin('base', 'sampleRate', fs);
assignin('base', 'dataRate', dataRate);


% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
% hObject    handle to menuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuLoadSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuLoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uigetfile('.fig');
if(FileName~=0)
    try
        cf = gcf;
        hgload(strcat(PathName,FileName));
        close(cf);
    catch ex
        errordlg(ex.message);
    end
end   

% --------------------------------------------------------------------
function menuSaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uiputfile('.fig');
if(FileName~=0)
    hgsave(strcat(PathName,FileName));
end   


% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[data, sampleRate, dataRate] = calc_serial(handles);
[FileName,PathName] = uiputfile('.mat');
if (FileName~=0)
    save(strcat(PathName, FileName), 'data', 'sampleRate', 'dataRate');
end


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
arbConfig = loadArbConfig();

% --- generic checks
if (arbConfig.maxSegmentNumber <= 1)
    set(handles.editSegment, 'Enable', 'off');
    set(handles.textSegment, 'Enable', 'off');
else
    set(handles.editSegment, 'Enable', 'on');
    set(handles.textSegment, 'Enable', 'on');
end
% --- editSampleRate
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= arbConfig.minimumSampleRate && value <= arbConfig.maximumSampleRate)
    set(handles.editSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editSampleRate, 'BackgroundColor', 'red');
    result = 0;
end
% --- editSegment
value = -1;
try
    value = evalin('base', get(handles.editSegment, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= 1 && value <= arbConfig.maxSegmentNumber)
    set(handles.editSegment,'BackgroundColor','white');
else
    set(handles.editSegment,'BackgroundColor','red');
    result = 0;
end
