function varargout = iqmod_gui(varargin)
% IQMOD_GUI M-file for iqmod_gui.fig
%      IQMOD_GUI, by itself, creates a new IQMOD_GUI or raises the existing
%      singleton*.
%
%      H = IQMOD_GUI returns the handle to a new IQMOD_GUI or the handle to
%      the existing singleton*.
%
%      IQMOD_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQMOD_GUI.M with the given input arguments.
%
%      IQMOD_GUI('Property','Value',...) creates a new IQMOD_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqmod_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqmod_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqmod_gui

% Last Modified by GUIDE v2.5 22-Sep-2012 12:52:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqmod_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqmod_gui_OutputFcn, ...
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


% --- Executes just before iqmod_gui is made visible.
function iqmod_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmod_gui (see VARARGIN)

% Choose default command line output for iqmod_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
switch arbConfig.model
    case {'M8190A', 'M8190A_base', 'M8190A_14bit', 'M8190A_prototype'}
        oversampling = 8;
        offset = 2e9;
    case 'M8190A_12bit'
        oversampling = 12;
        offset = 2e9;
    otherwise
        oversampling = 4;
        offset = 0;
end
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.popupmenuModType, 'Value', 6);  % QAM16
set(handles.editOversampling, 'String', num2str(oversampling));
set(handles.editSymbolRate, 'String', sprintf('%g', arbConfig.defaultSampleRate / oversampling));
if (isfield(arbConfig, 'defaultFc') && arbConfig.defaultFc ~= 0)
    set(handles.editCarrierOffset, 'String', sprintf('%g', 0));
    set(handles.editFc, 'String', sprintf('%g', arbConfig.defaultFc));
else
    set(handles.editCarrierOffset, 'String', sprintf('%g', offset));
    set(handles.editFc, 'String', sprintf('%g', offset));
end
% update all the fields
checkfields([], 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.popupmenuModType, 'TooltipString', sprintf([ ...
    'Select the modulation scheme for the digital modulation.\n' ...
    'When using high symbol rates (> 1 GSym/s), start with a lower order\n' ...
    'modulation scheme (e.g. QPSK) and make sure it is decoded correctly\n' ...
    'and perform a magnitude/phase calibration using this scheme.\n' ...
    'Then switch to higher order modulation schemes.']));
set(handles.editNumSymbols, 'TooltipString', sprintf([ ...
    'The utility will generate the given number of random symbols.\n' ...
    'A larger number will give a more realistic spectral shape but\n' ...
    'will also increase computation time. Especially when using large\n' ...
    'oversampling factors (> 20), start with a small number of symbols\n' ...
    '(e.g. 20) to keep the computation time within reasonable limits.\n' ...
    'Then gradually increase the number. Computation time can be reduced\n' ...
    'by using a number that is a multiple of the AWG''s segment granularity.']));
set(handles.editOversampling, 'TooltipString', sprintf([ ...
    'This field defines the ratio of sampling rate vs. symbol rate.\n' ...
    'It must be an integer number. Normally it is not necessary to\n' ...
    'set this field since it will be automatically calculated based on\n' ...
    'sampling rate and symbol rate.']));
set(handles.popupmenuFilter, 'TooltipString', sprintf([ ...
    'Select the pulse shaping filter that will be applied to the modulated\n' ...
    'baseband signal. Root raised cosine is the default and should normally\n' ...
    'be used except for experimental purposes.']));
set(handles.pushbuttonCalibrate, 'TooltipString', sprintf([ ...
    'This button uses the VSA software to perform a magnitude and phase\n' ...
    'calibration. After pressing this button, the VSA software will be started\n' ...
    '(if it is not already running) and automatically configured the parameters\n' ...
    'in this utility. The equalizer in the VSA software is turned on and determines\n' ...
    'the frequency and phase response of the channel. After the equalizer has\n' ...
    'stabilized, you can press the OK button to generate a calibration file.\n' ...
    'Once the file has been created, pre-distortion is automatically applied\n' ...
    'to the original signal, the pre-distorted waveform is downloaded into the\n' ...
    'AWG and the equalizer in the VSA software is turned off.\n\n' ...
    'Please verify that you have the VSA calibration parameters (in particular\n' ...
    '"Fc" set to the correct value before starting the calibration process.']));
set(handles.pushbuttonCalibrate, 'TooltipString', sprintf([ ...
    'This button uses the VSA software to perform a magnitude and phase\n' ...
    'calibration. After pressing this button, the VSA software will be started\n' ...
    '(if it is not already running) and automatically configured the parameters\n' ...
    'in this utility. The equalizer in the VSA software is turned on and determines\n' ...
    'the frequency and phase response of the channel. After the equalizer has\n' ...
    'stabilized, you can press the OK button to generate a calibration file.\n' ...
    'Once the file has been created, pre-distortion is automatically applied\n' ...
    'to the original signal, the pre-distorted waveform is downloaded into the\n' ...
    'AWG and the equalizer in the VSA software is turned off.\n\n' ...
    'Please verify that you have the VSA calibration parameters (in particular\n' ...
    '"Fc" set to the correct value before starting the calibration process.']));
set(handles.editFc, 'TooltipString', sprintf([ ...
    'Set the center frequency that is used by the VSA software during calibration.\n' ...
    'Whenever the Carrier Offset parameter is modified, it will be copied into\n' ...
    'this field, but it can be changed afterwards. This is necessary in those cases\n' ...
    'where the output of the AWG is not analyzed directly, but is up-converted using\n' ...
    'an external I/Q modulator or mixer.']));
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
set(handles.editCarrierSpacing, 'TooltipString', sprintf([ ...
    'Set the carrier spacing for multi-carrier signals.\n' ...
    'The carrier spacing must be larger than the symbol rate.\n' ...
    'Carrier frequencies start with "Carrier offset" and go up in\n' ...
    'steps of "Carrier Spacing".\n']));
set(handles.editCarrierOffset, 'TooltipString', sprintf([ ...
    'Set the carrier offset to 0 to generate a baseband I/Q signal.\n' ...
    'Set it to a value between zero and Fs/2 to perform digital upconversion\n' ...
    'to that center frequency. For a signal in the second Nyquist band,\n' ...
    'set the carrier offset to a value between Fs/2 and Fs. For multi-carrier\n' ...
    'signals, you can enter a list of frequencies or a single value that and\n' ...
    'defines the first (lowest) carrier offset.']));
set(handles.editMagnitudes, 'TooltipString', sprintf([ ...
    'Enter a list of magnitudes in dB. Each carrier will be assigned a\n' ...
    'magnitude from this list. If the list contains fewer values than\n' ...
    'carriers, the list will be used repeatedly.']));
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
end
% UIWAIT makes iqmod_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqmod_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



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



function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSamples as text
%        str2double(get(hObject,'String')) returns contents of editNumSamples as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 320 && value <= 64e6)
    oversampling = evalin('base',get(handles.editOversampling, 'String'));
    numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
    numSamples = evalin('base',get(handles.editNumSamples, 'String'));
    numSymbols = round(numSamples / oversampling);
    numSamples = numSymbols * oversampling;
    set(handles.editNumSymbols, 'String', num2str(numSymbols));
    set(handles.editNumSamples, 'String', num2str(numSamples));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editOversampling_Callback(hObject, eventdata, handles)
% hObject    handle to editOversampling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOversampling as text
%        str2double(get(hObject,'String')) returns contents of editOversampling as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 1 && value <= 100000 && (round(value) == value))
    symbolRate = evalin('base',get(handles.editSymbolRate, 'String'));
    numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
    oversampling = evalin('base',get(handles.editOversampling, 'String'));
    sampleRate = symbolRate * oversampling;
    set(handles.editSampleRate, 'String', sprintf('%g', sampleRate));
    numSamples = numSymbols * oversampling;
    set(handles.editNumSamples, 'String', num2str(numSamples));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editOversampling_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOversampling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editNumSymbols_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSymbols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSymbols as text
%        str2double(get(hObject,'String')) returns contents of editNumSymbols as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 2 && value <= 10e6)
    numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
    oversampling = evalin('base',get(handles.editOversampling, 'String'));
    numSamples = numSymbols * oversampling;
    set(handles.editNumSamples, 'String', num2str(numSamples));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumSymbols_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSymbols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editNumCarriers_Callback(hObject, eventdata, handles)
% hObject    handle to editNumCarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumCarriers as text
%        str2double(get(hObject,'String')) returns contents of editNumCarriers as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 1 && value <= 1000)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumCarriers_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumCarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editParam2_Callback(hObject, eventdata, handles)
% hObject    handle to editParam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editParam2 as text
%        str2double(get(hObject,'String')) returns contents of editParam2 as a double


% --- Executes during object creation, after setting all properties.
function editParam2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editParam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuModType.
function popupmenuModType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuModType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuModType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuModType


% --- Executes during object creation, after setting all properties.
function popupmenuModType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuModType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCarrierOffset_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrierOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrierOffset as text
%        str2double(get(hObject,'String')) returns contents of editCarrierOffset as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
arbConfig = loadArbConfig();
if (isvector(value) && ~isempty(value) ...
        && isempty(find(abs(value) < -1*arbConfig.maximumSampleRate)) ...
        && isempty(find(abs(value) > arbConfig.maximumSampleRate)))
    if (length(value) > 1)
        set(handles.checkboxMulti, 'Value', 1);
        set(handles.checkboxMulti, 'Enable', 'off');
        set(handles.textMultiCarrier, 'Enable', 'off');
        set(handles.editNumCarriers, 'String', sprintf('%d', length(value)));
    else
        set(handles.checkboxMulti, 'Value', 0);
        set(handles.checkboxMulti, 'Enable', 'on');
        set(handles.textMultiCarrier, 'Enable', 'on');
    end
    if (isfield(arbConfig, 'defaultFc'))
        set(handles.editFc, 'String', sprintf('%g', arbConfig.defaultFc + value(1)));
    else
        set(handles.editFc, 'String', sprintf('%g', value(1)));
    end
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end
checkboxMulti_Callback(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editCarrierOffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrierOffset (see GCBO)
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

[iqdata sampleRate oversampling] = calcModIQ(handles);
%iqplot(iqdata, sampleRate, 'constellation');
iqplot(iqdata, sampleRate);
% eyediagram(iqdata, 2*oversampling);

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata sampleRate oversampling] = calcModIQ(handles);
downloadList = cellstr(get(handles.popupmenuDownload,'String'));
downloadToChannel = downloadList{get(handles.popupmenuDownload,'Value')};
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
ch = get(hMsgBox, 'Children');
set(ch(2), 'String', 'Close');
segmentNum = evalin('base', get(handles.editSegment, 'String'));
iqdownload(iqdata, sampleRate, 'downloadToChannel', downloadToChannel, ...
    'segmentNumber', segmentNum);
try close(hMsgBox); catch ex; end
set(handles.pushbuttonCalibrate, 'Enable', 'on');
set(handles.editFc, 'Enable', 'on');
set(handles.textFc, 'Enable', 'on');
set(handles.editFilterLength, 'Enable', 'on');
set(handles.textFilterLength, 'Enable', 'on');
set(handles.editConvergence, 'Enable', 'on');
set(handles.textConvergence, 'Enable', 'on');
set(handles.editResultLength, 'Enable', 'on');
set(handles.textResultLength, 'Enable', 'on');


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqshowcorr();


function editCarrierSpacing_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrierSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrierSpacing as text
%        str2double(get(hObject,'String')) returns contents of editCarrierSpacing as a double
checkCarrierSpacingSymbolRate(handles);


function checkCarrierSpacingSymbolRate(handles)
carrierSpacing = [];
csValid = false;
symbolRate = [];
srValid = false;
ofValid = false;
offset = 0;
numCarrier = 1;
arbConfig = loadArbConfig();
try
    carrierSpacing = evalin('base', get(handles.editCarrierSpacing, 'String'));
catch ex
end
try
    symbolRate = evalin('base', get(handles.editSymbolRate, 'String'));
catch ex
end
try
    offset = evalin('base', ['[' get(handles.editCarrierOffset, 'String') ']']);
catch ex
end
try
    numCarrier = evalin('base', get(handles.editNumCarriers, 'String'));
catch ex
end
multi = get(handles.checkboxMulti, 'Value');

if (isscalar(carrierSpacing) && carrierSpacing >= 0 && carrierSpacing <= arbConfig.maximumSampleRate)
    csValid = true;
end
if (isscalar(symbolRate) && symbolRate <= arbConfig.maximumSampleRate)
    srValid = true;
end
if (isvector(offset) && ~isempty(offset) ...
        && isempty(find(abs(offset) > arbConfig.maximumSampleRate)))
    ofValid = true;
end
if (csValid && srValid && length(offset) > 1 && symbolRate > min(diff(sort(offset))))
    ofValid = false;
    srValid = false;
end
if (csValid && srValid && length(offset) <= 1 && multi && carrierSpacing < symbolRate)
    csValid = false;
    srValid = false;
end
if (csValid)
    set(handles.editCarrierSpacing,'BackgroundColor','white');
else
    set(handles.editCarrierSpacing,'BackgroundColor','red');
end
if (srValid)
    set(handles.editSymbolRate,'BackgroundColor','white');
else
    set(handles.editSymbolRate,'BackgroundColor','red');
end
if (ofValid)
    set(handles.editCarrierOffset,'BackgroundColor','white');
else
    set(handles.editCarrierOffset,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editCarrierSpacing_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrierSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAutoSamples.
function checkboxAutoSamples_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAutoSamples
autoSamples = get(hObject,'Value');
if (autoSamples)
    set(handles.editNumSamples, 'Enable', 'off');
else
    set(handles.editNumSamples, 'Enable', 'on');
end;


% --- Executes on selection change in popupmenuFilter.
function popupmenuFilter_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuFilter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuFilter


% --- Executes during object creation, after setting all properties.
function popupmenuFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editSymbolRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSymbolRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSymbolRate as text
%        str2double(get(hObject,'String')) returns contents of editSymbolRate as a double
checkfields(hObject, 0, handles);

% --- Executes during object creation, after setting all properties.
function editSymbolRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSymbolRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMagnitudes_Callback(hObject, eventdata, handles)
% hObject    handle to editMagnitudes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMagnitudes as text
%        str2double(get(hObject,'String')) returns contents of editMagnitudes as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && length(value) >= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editMagnitudes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMagnitudes (see GCBO)
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
correction = get(handles.checkboxCorrection,'Value');
if (correction)
    set(handles.pushbuttonCalibrate, 'String', 'Re-calibrate');
else
    set(handles.pushbuttonCalibrate, 'String', 'Calibrate (VSA)');
end;




function editFilterNsym_Callback(hObject, eventdata, handles)
% hObject    handle to editFilterNsym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilterNsym as text
%        str2double(get(hObject,'String')) returns contents of editFilterNsym as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 1 && value <= 5000)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFilterNsym_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilterNsym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFilterBeta_Callback(hObject, eventdata, handles)
% hObject    handle to editFilterBeta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilterBeta as text
%        str2double(get(hObject,'String')) returns contents of editFilterBeta as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFilterBeta_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilterBeta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxMulti.
function checkboxMulti_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxMulti (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxMulti
multiCarrier = get(handles.checkboxMulti,'Value');
offset = evalin('base', ['[' get(handles.editCarrierOffset, 'String') ']']);
if (multiCarrier)
    if (length(offset) > 1)
        set(handles.editNumCarriers, 'Enable', 'off');
        set(handles.editCarrierSpacing, 'Enable', 'off');
    else
        set(handles.editNumCarriers, 'Enable', 'on');
        set(handles.editCarrierSpacing, 'Enable', 'on');
    end
    set(handles.editMagnitudes, 'Enable', 'on');
else
    set(handles.editNumCarriers, 'Enable', 'off');
    set(handles.editCarrierSpacing, 'Enable', 'off');
    set(handles.editMagnitudes, 'Enable', 'off');
end;
checkCarrierSpacingSymbolRate(handles);



function editFc_Callback(hObject, eventdata, handles)
% hObject    handle to editFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFc as text
%        str2double(get(hObject,'String')) returns contents of editFc as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
% allow positive and negative Fc, negative ones indicate that
% the spectrum is inverted
if (isscalar(value) && value >= -50e9 && value <= 50e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editFilterLength_Callback(hObject, eventdata, handles)
% hObject    handle to editFilterLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilterLength as text
%        str2double(get(hObject,'String')) returns contents of editFilterLength as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 1 && value <= 99 && (round(value) == value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFilterLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilterLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editResultLength_Callback(hObject, eventdata, handles)
% hObject    handle to editResultLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editResultLength as text
%        str2double(get(hObject,'String')) returns contents of editResultLength as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 1 && value <= 10000 && (round(value) == value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editResultLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editResultLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editConvergence_Callback(hObject, eventdata, handles)
% hObject    handle to editConvergence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editConvergence as text
%        str2double(get(hObject,'String')) returns contents of editConvergence as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value > 0 && value <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
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


% --- Executes during object creation, after setting all properties.
function editConvergence_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editConvergence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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


% --- Executes on button press in pushbuttonShowVSA.
function pushbuttonShowVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fc = evalin('base', ['[' get(handles.editCarrierOffset, 'String') ']']);
fc = fc(1);
symbolRate = evalin('base',get(handles.editSymbolRate, 'String'));
modTypeList = get(handles.popupmenuModType, 'String');
modTypeIdx = get(handles.popupmenuModType, 'Value');
filterList = get(handles.popupmenuFilter, 'String');
filterIdx = get(handles.popupmenuFilter, 'Value');
filterBeta = evalin('base',get(handles.editFilterBeta, 'String'));
resultLength = evalin('base', get(handles.editResultLength, 'String'));
filterLength = evalin('base', get(handles.editFilterLength, 'String'));
convergence = evalin('base', get(handles.editConvergence, 'String'));

[iqdata sampleRate oversampling] = calcModIQ(handles);
vsaApp = vsafunc([], 'open');
if (~isempty(vsaApp))
    hMsgBox = msgbox('Configuring VSA software. Please wait...');
    vsafunc(vsaApp, 'preset');
    vsafunc(vsaApp, 'load', iqdata, sampleRate);
    vsafunc(vsaApp, 'DigDemod', modTypeList{modTypeIdx}, symbolRate, filterList{filterIdx}, filterBeta, resultLength);
    vsafunc(vsaApp, 'equalizer', false, filterLength, convergence);
    vsafunc(vsaApp, 'freq', fc, symbolRate * 1.6, 51201, Agilent.SA.Vsa.WindowType.FlatTop, 3);
    vsafunc(vsaApp, 'trace', 4, 'DigDemod');
    vsafunc(vsaApp, 'start', 1);
    vsafunc(vsaApp, 'autoscale');
    try
        close(hMsgBox);
    catch
    end
end


% --- Executes on button press in pushbuttonCalibrate.
function pushbuttonCalibrate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCalibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
symbolRate = evalin('base',get(handles.editSymbolRate, 'String'));
modTypeList = get(handles.popupmenuModType, 'String');
modTypeIdx = get(handles.popupmenuModType, 'Value');
filterList = get(handles.popupmenuFilter, 'String');
filterIdx = get(handles.popupmenuFilter, 'Value');
filterBeta = evalin('base',get(handles.editFilterBeta, 'String'));
carrierOffset = evalin('base',get(handles.editCarrierOffset, 'String'));
fc = evalin('base',get(handles.editFc, 'String'));
filterLength = evalin('base', get(handles.editFilterLength, 'String'));
convergence = evalin('base', get(handles.editConvergence, 'String'));
resultLength = evalin('base', get(handles.editResultLength, 'String'));
multiCarrier = get(handles.checkboxMulti, 'Value');
recal = get(handles.checkboxCorrection, 'Value');
if (multiCarrier)
    errordlg('VSA Calibration is only possible with single carrier', 'Error');
    return;
end
arbConfig = loadArbConfig();
interleaving = isfield(arbConfig, 'interleaving') && arbConfig.interleaving;
pushbuttonDownload_Callback(hObject, eventdata, handles);
result = iqvsacal('symbolRate', symbolRate, ...
    'modType', modTypeList{modTypeIdx}, ...
    'filterType', filterList{filterIdx}, ...
    'filterBeta', filterBeta, ...
    'carrierOffset', carrierOffset, ...
    'fc', fc, ...
    'filterLength', filterLength, ...
    'convergence', convergence, ...
    'resultLength', resultLength, ...
    'recalibrate', recal, ...
    'interleaving', interleaving);
if (result == 0)
    set(handles.checkboxCorrection, 'Value', 1);
    checkboxCorrection_Callback(hObject, eventdata, handles);
    pushbuttonDownload_Callback(hObject, eventdata, handles);
    try
        close(10);
    catch
    end
end

% --------------------------------------------------------------------
function menuPreset_Callback(hObject, eventdata, handles)
% hObject    handle to menuPreset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_QAM16_1GSym_Callback(hObject, eventdata, handles)
% hObject    handle to menu_QAM16_1GSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
symbolRate = 1e9;
overSampling = floor(arbConfig.maximumSampleRate / symbolRate);
sampleRate = symbolRate * overSampling;
if (overSampling < 1)
    errordlg('symbol rate too high for this instrument');
    return;
end
set(handles.editSymbolRate, 'String', sprintf('%g', symbolRate));
set(handles.editOversampling, 'String', sprintf('%g', overSampling));
set(handles.editSampleRate, 'String', sprintf('%g', sampleRate));
set(handles.popupmenuModType, 'Value', 6);  % QAM16
set(handles.popupmenuFilter, 'Value', 1); % RRC
set(handles.editFilterNsym, 'String', '20');
set(handles.editFilterBeta, 'String', '0.35');
set(handles.editCarrierOffset, 'String', '2e9');
set(handles.editFc, 'String', '2e9');
set(handles.checkboxMulti, 'Value', 0);
editSymbolRate_Callback(hObject, eventdata, handles);
checkboxMulti_Callback(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menu_QAM16_1_76GSym_Callback(hObject, eventdata, handles)
% hObject    handle to menu_QAM16_1_76GSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
symbolRate = 1.76e9;
overSampling = floor(arbConfig.maximumSampleRate / symbolRate);
sampleRate = symbolRate * overSampling;
if (overSampling < 1)
    errordlg('symbol rate too high for this instrument');
    return;
end
fc = 2e9;
set(handles.editSymbolRate, 'String', sprintf('%g', symbolRate));
set(handles.editOversampling, 'String', sprintf('%g', overSampling));
set(handles.editSampleRate, 'String', sprintf('%g', sampleRate));
set(handles.popupmenuModType, 'Value', 6);  % QAM16
set(handles.popupmenuFilter, 'Value', 1); % RRC
set(handles.editFilterNsym, 'String', '20');
set(handles.editFilterBeta, 'String', '0.35');
set(handles.editCarrierOffset, 'String', sprintf('%g', fc));
set(handles.editFc, 'String', sprintf('%g', fc + arbConfig.defaultFc));
set(handles.checkboxMulti, 'Value', 0);
editSymbolRate_Callback(hObject, eventdata, handles);
checkboxMulti_Callback(hObject, eventdata, handles);


% --------------------------------------------------------------------
function MultiCarrier_Callback(hObject, eventdata, handles)
% hObject    handle to MultiCarrier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
symbolRate = 6e6;
carrierSpacing = 8e6;
overSampling = floor(arbConfig.maximumSampleRate / symbolRate);
sampleRate = symbolRate * overSampling;
if (overSampling < 1)
    errordlg('symbol rate too high for this instrument');
    return;
end
fc = 100e6;
set(handles.editSymbolRate, 'String', sprintf('%g', symbolRate));
set(handles.editOversampling, 'String', sprintf('%g', overSampling));
set(handles.editSampleRate, 'String', sprintf('%g', sampleRate));
set(handles.editNumSymbols, 'String', sprintf('%g', 192));
set(handles.popupmenuModType, 'Value', 6);  % QAM16
set(handles.popupmenuFilter, 'Value', 1); % RRC
set(handles.editFilterNsym, 'String', '20');
set(handles.editFilterBeta, 'String', '0.35');
set(handles.editCarrierOffset, 'String', sprintf('%g', fc));
set(handles.editFc, 'String', sprintf('%g', fc + arbConfig.defaultFc));
set(handles.checkboxMulti, 'Value', 1);
set(handles.editCarrierSpacing, 'String', sprintf('%g', carrierSpacing));
set(handles.editNumCarriers, 'String', '50');
set(handles.editMagnitudes, 'String', '0 0 0 0 0 -300');
editSymbolRate_Callback(hObject, eventdata, handles);
checkboxMulti_Callback(hObject, eventdata, handles);



function [iqdata sampleRate oversampling] = calcModIQ(handles)
% handles    structure with handles and user data (see GUIDATA)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
autoSamples = get(handles.checkboxAutoSamples, 'Value');
numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
modTypeList = get(handles.popupmenuModType, 'String');
modTypeIdx = get(handles.popupmenuModType, 'Value');
oversampling = evalin('base',get(handles.editOversampling, 'String'));
filterList = get(handles.popupmenuFilter, 'String');
filterIdx = get(handles.popupmenuFilter, 'Value');
filterNsym = evalin('base',get(handles.editFilterNsym, 'String'));
filterBeta = evalin('base',get(handles.editFilterBeta, 'String'));
numCarriers = evalin('base',get(handles.editNumCarriers, 'String'));
carrierSpacing = evalin('base',get(handles.editCarrierSpacing, 'String'));
carrierOffset = evalin('base', ['[' get(handles.editCarrierOffset, 'String') ']']);
magnitudes = evalin('base', ['[' get(handles.editMagnitudes, 'String') ']']);
correction = get(handles.checkboxCorrection, 'Value');
multiCarrier = get(handles.checkboxMulti, 'Value');
if (multiCarrier && length(carrierOffset) == 1)
    carrierOffset = carrierOffset:carrierSpacing:(carrierOffset + (numCarriers - 1) * carrierSpacing + 0.01);
end

if (autoSamples)
    numSamples = 0;
end
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...');
iqdata = iqmod('sampleRate', sampleRate, ...
    'numSymbols', numSymbols, ...
    'modType', modTypeList{modTypeIdx}, ...
    'oversampling', oversampling, ...
    'filterType', filterList{filterIdx}, ...
    'filterNsym', filterNsym, ...
    'filterBeta', filterBeta, ...
    'carrierOffset', carrierOffset, ...
    'magnitude', magnitudes, ...
    'correction', correction);
try close(hMsgBox); catch ex; end
assignin('base', 'iqdata', iqdata);
set(handles.editNumSamples, 'String', sprintf('%d', length(iqdata)));


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
[FileName,PathName] = uiputfile('.mat');
if(FileName~=0)
    [Y sampleRate oversampling] = calcModIQ(handles);
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
value = [];
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= arbConfig.minimumSampleRate && value <= arbConfig.maximumSampleRate)
    sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
    symbolRate = evalin('base',get(handles.editSymbolRate, 'String'));
    oversampling = evalin('base',get(handles.editOversampling, 'String'));
    numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
    oversampling = floor(sampleRate / symbolRate);
    sampleRate = symbolRate * oversampling;
    set(handles.editSampleRate, 'String', sprintf('%g', sampleRate));
    set(handles.editOversampling, 'String', num2str(oversampling));
    numSamples = numSymbols * oversampling;
    numSamples = lcm(numSamples, arbConfig.segmentGranularity);
    set(handles.editNumSamples, 'String', num2str(numSamples));
    set(handles.editSampleRate,'BackgroundColor','white');
else
    set(handles.editSampleRate,'BackgroundColor','red');
end
% --- editSymbolRate
value = [];
try
    value = evalin('base', get(handles.editSymbolRate, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 1e3 && value <= 12e9)
    sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
    symbolRate = evalin('base',get(handles.editSymbolRate, 'String'));
    oversampling = evalin('base',get(handles.editOversampling, 'String'));
    numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
    numSamples = evalin('base',get(handles.editNumSamples, 'String'));
    % re-calculate oversampling & sampleRate
    oversampling = floor(sampleRate / symbolRate);
    if (oversampling < 1)
        oversampling = 1;
    end
    sampleRate = symbolRate * oversampling;
    set(handles.editOversampling, 'String', num2str(oversampling));
    set(handles.editSampleRate, 'String', sprintf('%g', sampleRate));
    numSamples = numSymbols * oversampling;
    numSamples = lcm(numSamples, arbConfig.segmentGranularity);
    set(handles.editNumSamples, 'String', num2str(numSamples));
end
checkCarrierSpacingSymbolRate(handles);
% --- editSegment
value = [];
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
