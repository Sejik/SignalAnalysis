function varargout = iqpulse_gui(varargin)
% IQPULSE_GUI M-file for iqpulse_gui.fig
%      IQPULSE_GUI, by itself, creates a new IQPULSE_GUI or raises the existing
%      singleton*.
%
%      H = IQPULSE_GUI returns the handle to a new IQPULSE_GUI or the handle to
%      the existing singleton*.
%
%      IQPULSE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQPULSE_GUI.M with the given input arguments.
%
%      IQPULSE_GUI('Property','Value',...) creates a new IQPULSE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqpulse_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqpulse_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqpulse_gui

% Last Modified by GUIDE v2.5 29-Sep-2012 11:42:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqpulse_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqpulse_gui_OutputFcn, ...
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


% --- Executes just before iqpulse_gui is made visible.
function iqpulse_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqpulse_gui (see VARARGIN)

% Choose default command line output for iqpulse_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
switch arbConfig.model
    case '81180A'
        offset = 0;
        span = 2e9;
    case {'M8190A', 'M8190A_base', 'M8190A_14bit', 'M8190A_12bit', 'M8190A_prototype'}
        offset = 2e9;
        span = 2e9;
    case 'M933xA'
        offset = 0;
        span = 500e6;
    otherwise
        offset = 0;
        span = 100e6;
end
set(handles.popupmenuChirp, 'Value', 2);
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.editOffset, 'String', sprintf('%g', offset));
set(handles.editSpan, 'String', sprintf('%g', span));
if (isfield(arbConfig, 'defaultFc') && arbConfig.defaultFc ~= 0)
    set(handles.editOffset, 'String', sprintf('%g', 0));
end

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editFMFormula, 'TooltipString', sprintf([ ...
    'Enter a MATLAB expression with "x" as an independent variable.\n' ...
    'The expression will be evaluated with x set to a row-vector with\n' ...
    'values in the range [0...1). The expression should return a row-vector\n' ...
    'with the same length as x and values between -1 and 1 to indicate\n' ...
    'a frequency deviation from -span/2 to span/2. In case of multiple\n' ...
    'pulses, the variable "i" will contain the pulse number starting from 1.\n' ...
    'Example: cos(pi*(x-1)) will generate a cosine shaped FM pulse. If you\n' ...
    'want no FM modulation at all, put a zero in this field.']));
set(handles.editPMFormula, 'TooltipString', sprintf([ ...
    'Enter a MATLAB expression with "x" as an independent variable.\n' ...
    'The expression will be evaluated with x set to a row-vector with\n' ...
    'values in the range [0...1). The expression should return a row-vector\n' ...
    'with the same length as x and values representing the phase in radians.\n' ...
    'In case of multiple pulses, the variable "i" will contain the pulse\n' ...
    'number starting from 1. Example: floor(x*4)/4*pi generates a pulse with\n' ...
    'four 45 degree phase steps within the pulse.  If you want no PM modulation\n' ...
    'enter zero in this field.']));
set(handles.popupmenuShape, 'TooltipString', sprintf([ ...
    'Select the shape of the rising and falling edge of the pulse.\n' ...
    '"trapezodial" results in a linear increase/decrease of amplitude.\n' ...
    'With "raised cosine", the amplitude follows a cosine wave, which\n' ...
    'reduces the occupied bandwidth. "Zero signal during rise time"\n' ...
    'can be used to delay the pulse by a certain amount of time relative\n', ...
    'to the beginning of the waveform segment']));
set(handles.popupmenuChirp, 'TooltipString', sprintf([ ...
    'Select the type of modulation on the pulse (or IMOP).\n' ...
    'Increasing, decreasing and V-shape modulations are linear FM chirps.\n' ...
    'Barker-11 and -13 generate barker codes of the given length.\n' ...
    '"User defined" allows you to specify a MATLAB formula to describe the\n' ...
    'frequency modulation on the pulse.']));
set(handles.popupmenuDownload, 'TooltipString', sprintf([ ...
    'Select into which AWG channels the data is loaded.\n' ...
    '"I+Q to channel 1+2" means that the I signal is loaded into channel 1\n' ...
    'and Q is loaded into channel 2. "I+Q in ch 2+1" means that the\n' ...
    'channels are swapped. With the other four options, only one\n' ...
    'part of the signal (I or Q) is loaded into ONE of the channels.\n' ...
    'In DUC modes, both I and Q will be used and you can choose whether\n' ...
    'the RF signal should be generated on Ch1, Ch2 or both.\n' ...
    'This can be used to load the same of different signals into the\n' ...
    'two channels of the AWG.']));
set(handles.editSegment, 'TooltipString', sprintf([ ...
    'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
    'If you download to segment #1, all other segments will be automatically\n' ...
    'deleted.']));
set(handles.checkboxCorrection, 'TooltipString', sprintf([ ...
    'Use this checkbox to pre-distort the signal using the previously established\n' ...
    'calibration values. Calibration can be performed using the multi-tone or\n' ...
    'digital modulation utilities.']));
set(handles.pushbuttonShowCorrection, 'TooltipString', sprintf([ ...
    'Use this button to visualize the frequency and phase response that has\n' ...
    'been captured using the "Calibrate" functionality in the multi-tone or\n' ...
    'digital modulation utility. In multi-tone, only magnitude corrections\n' ...
    'are captured whereas in digital modulation, both magnitude and phase\n' ...
    'response are calculated.']));
set(handles.editSpan, 'TooltipString', sprintf([ ...
    'Set the frequency span of the chirped signal.\n' ...
    'The frequency of the pulse will be in the range -span/2 to +span/2\n' ...
    'relative to the frequency offset. It is possible to specify a single\n' ...
    'or multiple frequency span values. In case of a list, multiple pulses\n' ...
    'will be generated; each with its own frequency span.']));
set(handles.editOffset, 'TooltipString', sprintf([ ...
    'Set the frequency offset to 0 to generate a baseband I/Q signal.\n' ...
    'Set it to a value greater than zero to perform digital upconversion\n' ...
    'to that center frequency. (Depending on the selection in "Download",\n' ...
    'the output signal will be available on channel 1 or 2 or both.\n' ...
    'It is possible to specify a single or multiple frequency offset values.\n' ...
    'In case of a list, multiple pulses will be generated; each with its own\n' ...
    'offset.']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The signal will be displayed both in the time- as well as frequency\n' ...
    'domain (spectrum). This function can be used even without any hardware\n' ...
    'connected.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
set(handles.pushbuttonShowVSA, 'TooltipString', sprintf([ ...
    'Use this button to calculate and visualize the signal using the VSA software.\n' ...
    'If the VSA software is not already running, it will be started. The utility will\n' ...
    'automatically configure the VSA software for the parameters of the generated signal.\n' ...
    'VSA versions 14.0 and 14.2 are supported.']));
set(handles.pushbuttonVSAHW, 'TooltipString', sprintf([ ...
    'Use this button to configure the VSA software to show your generated pulse.\n' ...
    'The external upconversion frequency (from "Instrument Configuration") is taken\n' ...
    'into account.']));
end
% UIWAIT makes iqpulse_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqpulse_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



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



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double
checkfields([], 0, handles);


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



function editPRI_Callback(hObject, eventdata, handles)
% hObject    handle to editPRI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPRI as text
%        str2double(get(hObject,'String')) returns contents of editPRI as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && min(value) >= 1e-12 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPRI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPRI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPW_Callback(hObject, eventdata, handles)
% hObject    handle to editPW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPW as text
%        str2double(get(hObject,'String')) returns contents of editPW as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && min(value) >= 1e-12 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editRise_Callback(hObject, eventdata, handles)
% hObject    handle to editRise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRise as text
%        str2double(get(hObject,'String')) returns contents of editRise as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editRise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editFall_Callback(hObject, eventdata, handles)
% hObject    handle to editFall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFall as text
%        str2double(get(hObject,'String')) returns contents of editFall as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFall_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuShape.
function popupmenuShape_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuShape contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuShape


% --- Executes during object creation, after setting all properties.
function popupmenuShape_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuChirp.
function popupmenuChirp_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuChirp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuChirp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuChirp
contents = cellstr(get(hObject,'String'));
modType = contents{get(hObject,'Value')};
if (strcmpi(modType, 'User defined'))
    set(handles.textPMFormula, 'Enable', 'on');
    set(handles.editPMFormula, 'Enable', 'on');
    set(handles.textFMFormula, 'Enable', 'on');
    set(handles.editFMFormula, 'Enable', 'on');
    set(handles.editInitialPhase, 'Visible', 'off');
    set(handles.textInitialPhase, 'Visible', 'off');
    set(handles.textInitialPhaseStar, 'Visible', 'off');
    set(handles.textPMFormula, 'Visible', 'on');
    set(handles.editPMFormula, 'Visible', 'on');
else
    set(handles.textPMFormula, 'Enable', 'off');
    set(handles.editPMFormula, 'Enable', 'off');
    set(handles.textFMFormula, 'Enable', 'off');
    set(handles.editFMFormula, 'Enable', 'off');
    set(handles.editInitialPhase, 'Visible', 'on');
    set(handles.textInitialPhase, 'Visible', 'on');
    set(handles.textInitialPhaseStar, 'Visible', 'on');
    set(handles.textPMFormula, 'Visible', 'off');
    set(handles.editPMFormula, 'Visible', 'off');
end
if (strcmpi(modType, 'None') || strncmpi(modType, 'Barker', 6))
    set(handles.textSpan, 'Enable', 'off');
    set(handles.editSpan, 'Enable', 'off');
else
    set(handles.textSpan, 'Enable', 'on');
    set(handles.editSpan, 'Enable', 'on');
end


% --- Executes during object creation, after setting all properties.
function popupmenuChirp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuChirp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, ~, sampleRate] = calculate_pulse(handles);
iqplot(iqdata, sampleRate, 'spectrogram');

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(~, ~, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
[iqdata, marker, sampleRate] = calculate_pulse(handles);
downloadList = cellstr(get(handles.popupmenuDownload,'String'));
downloadToChannel = downloadList{get(handles.popupmenuDownload,'Value')};
segmentNum = evalin('base', get(handles.editSegment, 'String'));
%iqdownload(iqdata, sampleRate);
iqdownload(iqdata, sampleRate, 'downloadToChannel', downloadToChannel, ...
    'segmentNumber', segmentNum, 'marker', marker);
try close(hMsgBox); catch ex; end;


function editSpan_Callback(hObject, eventdata, handles)
% hObject    handle to editSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSpan as text
%        str2double(get(hObject,'String')) returns contents of editSpan as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && min(value) >= 0 && max(value) <= 12e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSpan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editOffset_Callback(hObject, eventdata, handles)
% hObject    handle to editOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOffset as text
%        str2double(get(hObject,'String')) returns contents of editOffset as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && min(value) >= -12e9 && max(value) <= 12e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editOffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection


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


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqshowcorr();


function editAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplitude as text
%        str2double(get(hObject,'String')) returns contents of editAmplitude as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --------------------------------------------------------------------
function Preset_Callback(hObject, eventdata, handles)
% hObject    handle to Preset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Single_Callback(hObject, eventdata, handles)
% hObject    handle to Single (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.editOffset, 'String', sprintf('%g', arbConfig.defaultSampleRate / 4));
set(handles.editSpan, 'String', sprintf('%g', arbConfig.defaultSampleRate / 4));
set(handles.editPW, 'String', '2e-6');
set(handles.editPRI, 'String', '4e-6');
set(handles.editRise, 'String', '10e-9');
set(handles.editFall, 'String', '10e-9');
set(handles.editAmplitude, 'String', '0');
set(handles.popupmenuShape, 'Value', 1);
set(handles.popupmenuChirp, 'Value', 2);
popupmenuChirp_Callback(handles.popupmenuChirp, eventdata, handles);


% --------------------------------------------------------------------
function MultiAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to MultiAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.editOffset, 'String', sprintf('%g', arbConfig.defaultSampleRate / 4));
set(handles.editSpan, 'String', sprintf('%g', arbConfig.defaultSampleRate / 4));
set(handles.editPW, 'String', '2e-6');
set(handles.editPRI, 'String', '4e-6');
set(handles.editRise, 'String', '10e-9');
set(handles.editFall, 'String', '10e-9');
set(handles.editAmplitude, 'String', '20*cos(2*pi*(0:0.1:0.9))');
set(handles.popupmenuShape, 'Value', 1);
set(handles.popupmenuChirp, 'Value', 2);
popupmenuChirp_Callback(handles.popupmenuChirp, eventdata, handles);


% --------------------------------------------------------------------
function MultipleParam_Callback(hObject, eventdata, handles)
% hObject    handle to MultipleParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.editOffset, 'String', sprintf('%g,%g,%g,%g', [2 3 4 5] * arbConfig.defaultSampleRate / 16));
set(handles.editSpan, 'String', sprintf('%g', arbConfig.defaultSampleRate / 16));
set(handles.editPW, 'String', '1e-6*[1,2,3,4]');
set(handles.editPRI, 'String', '5e-6');
set(handles.editRise, 'String', '10e-9');
set(handles.editFall, 'String', '10e-9');
set(handles.editAmplitude, 'String', '-15,-10,-5,0');
set(handles.popupmenuShape, 'Value', 1);
set(handles.popupmenuChirp, 'Value', 2);
popupmenuChirp_Callback(handles.popupmenuChirp, eventdata, handles);


% --------------------------------------------------------------------
function UserDefinedModulation_Callback(hObject, eventdata, handles)
% hObject    handle to UserDefinedModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.editOffset, 'String', sprintf('%g', arbConfig.defaultSampleRate / 4));
set(handles.editSpan, 'String', sprintf('%g', arbConfig.defaultSampleRate / 4));
set(handles.editPW, 'String', '2e-6');
set(handles.editPRI, 'String', '4e-6');
set(handles.editRise, 'String', '10e-9');
set(handles.editFall, 'String', '10e-9');
set(handles.editAmplitude, 'String', '0');
set(handles.popupmenuShape, 'Value', 1);
set(handles.popupmenuChirp, 'Value', 8);
popupmenuChirp_Callback(handles.popupmenuChirp, eventdata, handles);
set(handles.editFMFormula, 'String', 'sin(2*pi*x)');
set(handles.editPMFormula, 'String', '0');


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



function editPMFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editPMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPMFormula as text
%        str2double(get(hObject,'String')) returns contents of editPMFormula as a double
value = [];
try
    eval(['fct=@(x,i) ' get(hObject, 'String') ';']);
    value = fct(linspace(0,1,10),1);
    if (~isvector(value))
        error('expression must return a vector with at most (length(x)) elements');
    end
catch ex
    msgbox(ex.message);
end
if (isvector(value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end



function editFMFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editFMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFMFormula as text
%        str2double(get(hObject,'String')) returns contents of editFMFormula as a double
value = [];
try
    eval(['fct=@(x,i) ' get(hObject, 'String') ';']);
    value = fct(linspace(0,1,10),1);
    if (~isvector(value))
        error('expression must return a vector with at most (length(x)) elements');
    end
catch ex
    msgbox(ex.message);
end
if (isvector(value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFMFormula_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editPMFormula_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPMFormula (see GCBO)
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



function editInitialPhase_Callback(hObject, eventdata, handles)
% hObject    handle to editInitialPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editInitialPhase as text
%        str2double(get(hObject,'String')) returns contents of editInitialPhase as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editInitialPhase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editInitialPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editInitialDelay_Callback(hObject, eventdata, handles)
% hObject    handle to editInitialDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editInitialDelay as text
%        str2double(get(hObject,'String')) returns contents of editInitialDelay as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editInitialDelay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editInitialDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonShowVSA.
function pushbuttonShowVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, marker, sampleRate] = calculate_pulse(handles);
pri = evalin('base', ['[' get(handles.editPRI, 'String') ']']);
pw = evalin('base', ['[' get(handles.editPW, 'String') ']']);
riseTime = evalin('base', ['[' get(handles.editRise, 'String') ']']);
fallTime = evalin('base', ['[' get(handles.editFall, 'String') ']']);
amplitude = evalin('base', ['[' get(handles.editAmplitude, 'String') ']']);
span_f = evalin('base', ['[' get(handles.editSpan, 'String') ']']);
offset_f = evalin('base', ['[' get(handles.editOffset, 'String') ']']);
numPulse = max([length(pri), length(pw), length(riseTime), length(fallTime), length(amplitude), ...
    length(span_f), length(offset_f)]);
pri = fixlength(pri, numPulse);

trigLevel = 10e-3;
trigDelay = -0.5 * min(pw);
trigHoldoff = 0.5 * max(pw);
if (numPulse > 1)
    tlen = sum(pri(1:end-1)) + pw(end) - 2*trigDelay;
else
    tlen = pw * 2;
end
fc = (min(offset_f) + max(offset_f)) / 2;
span = (max(offset_f) + max(span_f)/2 - min(offset_f) + min(span_f)/2) * 1.2;
if (span < 100e6)
    span = 100e6;
end
vsaApp = vsafunc([], 'open');
if (~isempty(vsaApp))
    hMsgBox = msgbox('Configuring VSA software. Please wait...', 'Please wait...', 'replace');
    vsafunc(vsaApp, 'preset');
    vsafunc(vsaApp, 'load', iqdata, sampleRate);
    vsafunc(vsaApp, 'freq', fc, span, 102401, Agilent.SA.Vsa.WindowType.Uniform, 0, tlen);
    vsafunc(vsaApp, 'start', 1);
    vsafunc(vsaApp, 'trace', 4, 'Chirp');
    vsafunc(vsaApp, 'trigger', 'Channel', trigLevel, trigDelay, trigHoldoff);
    pause(1);
    vsafunc(vsaApp, 'autoscale');
    try
        close(hMsgBox);
    catch ex
    end
end

function x = fixlength(x, len)
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);



% --- Executes on button press in pushbuttonVSAHW.
function pushbuttonVSAHW_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonVSAHW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, marker, sampleRate] = calculate_pulse(handles);
pri = evalin('base', ['[' get(handles.editPRI, 'String') ']']);
pw = evalin('base', ['[' get(handles.editPW, 'String') ']']);
riseTime = evalin('base', ['[' get(handles.editRise, 'String') ']']);
fallTime = evalin('base', ['[' get(handles.editFall, 'String') ']']);
amplitude = evalin('base', ['[' get(handles.editAmplitude, 'String') ']']);
span_f = evalin('base', ['[' get(handles.editSpan, 'String') ']']);
offset_f = evalin('base', ['[' get(handles.editOffset, 'String') ']']);
numPulse = max([length(pri), length(pw), length(riseTime), length(fallTime), length(amplitude), ...
    length(span_f), length(offset_f)]);
pri = fixlength(pri, numPulse);

if (numPulse > 1)
    tlen = sum(pri) * 1.1;
else
    tlen = pw * 2;
end
fc = (min(offset_f) + max(offset_f)) / 2;
span = (max(offset_f) + max(span_f)/2 - min(offset_f) + min(span_f)/2) * 1.2;
if (span < 100e6)
    span = 100e6;
end
vsaApp = vsafunc([], 'open');
if (~isempty(vsaApp))
    hMsgBox = msgbox('Configuring VSA software. Please wait...', 'Please wait...', 'replace');
    vsafunc(vsaApp, 'preset');
    vsafunc(vsaApp, 'fromHW');
    arbConfig = loadArbConfig();
    vsafunc(vsaApp, 'input', arbConfig.defaultFc + fc);
    vsafunc(vsaApp, 'freq', arbConfig.defaultFc + fc, span, 51201, Agilent.SA.Vsa.WindowType.Uniform, 0, tlen);
    vsafunc(vsaApp, 'trace', 4, 'Chirp');
    vsafunc(vsaApp, 'start', 1);
    vsafunc(vsaApp, 'trigger', 'Channel', 100e-3, -0.5 * min(pw), 1.05 * max(pw));
% autorange does not work reliably for pulsed signals...
    vsafunc(vsaApp, 'autorange', 0.4);
    vsafunc(vsaApp, 'autoscale');
    try
        close(hMsgBox);
    catch ex;
    end
end


function [iqdata, marker, sampleRate] = calculate_pulse(handles)
% handles    structure with handles and user data (see GUIDATA)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
pri = evalin('base', ['[' get(handles.editPRI, 'String') ']']);
pw = evalin('base', ['[' get(handles.editPW, 'String') ']']);
riseTime = evalin('base', ['[' get(handles.editRise, 'String') ']']);
fallTime = evalin('base', ['[' get(handles.editFall, 'String') ']']);
delay = evalin('base', ['[' get(handles.editInitialDelay, 'String') ']']);
phase = evalin('base', ['[' get(handles.editInitialPhase, 'String') ']']);
shapeList = get(handles.popupmenuShape, 'String');
shapeIdx = get(handles.popupmenuShape, 'Value');
FMFormula = get(handles.editFMFormula, 'String');
PMFormula = get(handles.editPMFormula, 'String');
amplitude = evalin('base', ['[' get(handles.editAmplitude, 'String') ']']);
span_f = evalin('base', ['[' get(handles.editSpan, 'String') ']']);
offset_f = evalin('base', ['[' get(handles.editOffset, 'String') ']']);
chirpList = get(handles.popupmenuChirp, 'String');
chirpIdx = get(handles.popupmenuChirp, 'Value');
correctFlag = get(handles.checkboxCorrection, 'Value');

correction = [];
if (correctFlag)
    try
        load('ampCorr.mat');
        correction = ampCorr;
    catch ex
        warndlg('No correction file available. Please use iqtone to create it', 'Warning', 'modal');
    end
end
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');
%try
[iqdata marker] = iqpulse(...
    'PRI', pri, 'PW', pw, 'riseTime', riseTime, 'fallTime', fallTime, ...
    'pulseShape', shapeList{shapeIdx}, 'span', span_f, 'offset', offset_f, ...
    'amplitude', amplitude, 'fmFormula', FMFormula, 'pmFormula', PMFormula, ...
    'chirpType', chirpList{chirpIdx}, 'sampleRate', sampleRate, ...
    'correction', correction, 'delay', delay, 'phase', phase);
%catch ex
%    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
%    iqdata = [];
%    marker = [];
%end
try close(hMsgBox); catch ex; end
assignin('base', 'iqdata', iqdata);


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


function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uiputfile('.mat');
if(FileName~=0)
    [Y, marker, sampleRate] = calculate_pulse(handles);
    XDelta = 1/sampleRate;
    XStart = 0;
    InputZoom = 1;
    try
        save(strcat(PathName,FileName), 'Y', 'XDelta', 'XStart', 'InputZoom');
    catch ex
        errordlg(ex.message);
    end
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
oldDls = get(handles.popupmenuDownload, 'String');
if (~isempty(strfind(arbConfig.model, 'DUC')))
    newDls = {'RF to channel 1+2'; 'RF to channel 1'; 'RF to channel 2'};
else
    newDls = {'I+Q to channel 1+2'; 'I+Q to channel 2+1'; 'I to channel 1'; ...
    'I to channel 2'; 'Q to channel 1'; 'Q to channel 2'};
end
if (length(oldDls) ~= length(newDls) || ~isempty(find(~strcmp(oldDls, newDls), 1)))
    set(handles.popupmenuDownload, 'Value', 1);
    set(handles.popupmenuDownload, 'String', newDls);
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
