function varargout = catv_gui(varargin)
% CATV_GUI MATLAB code for catv_gui.fig
%      CATV_GUI, by itself, creates a new CATV_GUI or raises the existing
%      singleton*.
%
%      H = CATV_GUI returns the handle to a new CATV_GUI or the handle to
%      the existing singleton*.
%
%      CATV_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CATV_GUI.M with the given input arguments.
%
%      CATV_GUI('Property','Value',...) creates a new CATV_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before catv_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to catv_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help catv_gui

% Last Modified by GUIDE v2.5 25-May-2012 17:36:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @catv_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @catv_gui_OutputFcn, ...
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


% --- Executes just before catv_gui is made visible.
function catv_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to catv_gui (see VARARGIN)

% Choose default command line output for catv_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(handles.popupmenuModType, 'Value', 8);
arbConfig = loadArbConfig();
if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.checkboxAutoSampleRate, 'TooltipString', sprintf([ ...
    'Use this checkbox to automatically select the sample rate of the M8190A.\n' ...
    'The sample rate will be selected to be an integer multiple of the symbol\n' ...
    'rate for digital modulations.']));
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.editFreqDigAbove, 'TooltipString', sprintf([ ...
    'Carriers below this frequency will be treated as analog TV channels and\n' ...
    'CW signals will be generated on those frequencies. Carriers above this \n' ...
    'frequency will be treated as digital channels and modulated signals are generated.']));
set(handles.popupmenuModType, 'TooltipString', sprintf([ ...
    'Select the modulation scheme for the digital modulation.\n' ...
    'QAMxxx is the typical modulation scheme for digital channels']));
set(handles.editNumSymbols, 'TooltipString', sprintf([ ...
    'The utility will generate the given number of random symbols.\n' ...
    'A larger number will give a more realistic spectral shape but\n' ...
    'will also increase computation time. It is recommended to\n' ...
    'start with a small number of symbols (e.g. 120) to limit computation time.\n' ...
    'Then gradually increase the number. Computation time can be reduced\n' ...
    'by using a number that is a multiple of the AWG''s segment granularity.']));
set(handles.popupmenuFilterType, 'TooltipString', sprintf([ ...
    'Select the pulse shaping filter that will be applied to the modulated\n' ...
    'baseband signal. Root raised cosine is the default and should normally\n' ...
    'be used except for experimental purposes.']));
set(handles.editDigitalAttenuation, 'TooltipString', sprintf([ ...
    'All digital carrier signals will be attenuated by this number of dB relative to\n' ...
    'the analog channels.\n']));
set(handles.editNotchCarrier, 'TooltipString', sprintf([ ...
    'This field contains a list of carrier numbers to be notched out starting with 1\n' ...
    'You can enter a list of numbers separated by spaces or a MATLAB expression that\n' ...
    'evaluates to a list of numbers (e.g.  start:spacing:stop).']));
set(handles.radiobuttonSameChan, 'TooltipString', sprintf([ ...
    'Select "same channel" to generate both the analog and digital signals on the\n' ...
    'same AWG channel. Select "different channels" to generate digital carriers on\n' ...
    'channel 1 and analog carriers on channel 2. You have to combine them externally\n' ...
    'in this case. When generating the signals on the same channel, the relative power\n' ...
    'can be controlled more precisely, but the dynamic range is slightly reduced.']));
set(handles.radiobuttonDiffChan, 'TooltipString', sprintf([ ...
    'Select "same channel" to generate both the analog and digital signals on the\n' ...
    'same AWG channel. Select "different channels" to generate digital carriers on\n' ...
    'channel 1 and analog carriers on channel 2. You have to combine them externally\n' ...
    'in this case. When generating the signals on the same channel, the relative power\n' ...
    'can be controlled more precisely, but the dynamic range is slightly reduced.']));
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
set(handles.editCarrier, 'TooltipString', sprintf([ ...
    'Enter the list of carrier frequencies in MHz - both digital and analog channels.\n' ...
    'You can enter a list of frequencies separated by spaces or use MATLAB expressions\n' ...
    'for lists of equally spaced carrier frequencies (e.g.  start:spacing:stop).']));
set(handles.editTilt, 'TooltipString', sprintf([ ...
    'Enter the value in dB by which the highest carrier is amplified vs. the lowest\n' ...
    'carrier.  All the carriers in between will be attenuated proportional to their\n' ...
    'frequency']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The signal will be displayed both in the time- as well as frequency\n' ...
    'domain (spectrum). This function can be used even without any hardware\n' ...
    'connected.']));
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
    close(handles.figure1);
    return;
end
if (~strcmp(arbConfig.model, 'M8190A_12bit') && ~strcmp(arbConfig.model, 'M8190A_14bit'))
    errordlg({'Invalid AWG model selected. ' ...
        'Please use the "Configuration" utility and' ...
        'select M8190A_14bit or M8190A_12bit mode'});
    close(handles.figure1);
    return;
end

% UIWAIT makes catv_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = catv_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double


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



function editCarrier_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrier as text
%        str2double(get(hObject,'String')) returns contents of editCarrier as a double


% --- Executes during object creation, after setting all properties.
function editCarrier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAutoSampleRate.
function checkboxAutoSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
autoSampleRate = get(hObject,'Value');
if (autoSampleRate)
    set(handles.editSampleRate, 'Enable', 'off');
else
    set(handles.editSampleRate, 'Enable', 'on');
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqshowcorr();


function editFreqDigAbove_Callback(hObject, eventdata, handles)
% hObject    handle to editFreqDigAbove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreqDigAbove as text
%        str2double(get(hObject,'String')) returns contents of editFreqDigAbove as a double


% --- Executes during object creation, after setting all properties.
function editFreqDigAbove_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreqDigAbove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editTilt_Callback(hObject, eventdata, handles)
% hObject    handle to editTilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTilt as text
%        str2double(get(hObject,'String')) returns contents of editTilt as a double


% --- Executes during object creation, after setting all properties.
function editTilt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDigitalAttenuation_Callback(hObject, eventdata, handles)
% hObject    handle to editDigitalAttenuation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDigitalAttenuation as text
%        str2double(get(hObject,'String')) returns contents of editDigitalAttenuation as a double


% --- Executes during object creation, after setting all properties.
function editDigitalAttenuation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDigitalAttenuation (see GCBO)
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
[data sampleRate] = calc_signal(handles);
plotFct(handles.axesCh1, real(data), sampleRate, 1);
plotFct(handles.axesCh2, imag(data), sampleRate, 2);
set(handles.textPlaceHolder1, 'Visible', 'off');
set(handles.textPlaceHolder2, 'Visible', 'off');


function plotFct(ax, data, sampleRate, ch)
data = awgn(data, 300);
len = length(data);
faxis = linspace(sampleRate / -2, sampleRate / 2 - sampleRate / len, len);
magnitude = 20 * log10(abs(fftshift(fft(data/len))));
axes(ax);
plot(ax, faxis, magnitude, '.-');
xlabel('Frequency (Hz)');
ylabel(sprintf('dB (Ch%d)', ch));
xlim([0 1.1e9]);
ylim([-40 10]);
grid;


function [data sampleRate] = calc_signal(handles)
arbConfig = loadArbConfig();
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
carriers = 1e6.*evalin('base', ['[' get(handles.editCarrier, 'String') ']']);
notch = evalin('base', ['[' get(handles.editNotchCarrier, 'String') ']']);
freqDigAbove = 1e6.*evalin('base',get(handles.editFreqDigAbove, 'String'));
tilt = evalin('base',get(handles.editTilt, 'String'));
digWithMod = get(handles.checkboxDigMod, 'Value');
digitalOffset = evalin('base',get(handles.editDigitalAttenuation, 'String'));
symbolRate = 1e6.*evalin('base',get(handles.editSymbolRate, 'String'));
numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
modTypeList = get(handles.popupmenuModType, 'String');
modTypeIdx = get(handles.popupmenuModType, 'Value');
filterList = get(handles.popupmenuFilterType, 'String');
filterIdx = get(handles.popupmenuFilterType, 'Value');
filterNsym = evalin('base',get(handles.editFilterNSym, 'String'));
filterBeta = evalin('base',get(handles.editFilterBeta, 'String'));
correction = get(handles.checkboxCorrection, 'Value');
sameChannel = get(handles.radiobuttonSameChan, 'Value');
if (autoSamples)
    sampleRate = arbConfig.defaultSampleRate;
end
oversampling = floor(sampleRate / symbolRate);
sampleRate = symbolRate * oversampling;
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');
data = catv('symbolRate', symbolRate, 'oversampling', oversampling, ...
    'freqList', carriers, 'freqDigAbove', freqDigAbove, ...
    'dropList', notch, 'tilt', tilt, ...
    'numSymbols', numSymbols, 'modType', modTypeList{modTypeIdx}, ...
    'filterType', filterList{filterIdx}, ...
    'digOffset', digitalOffset, 'digWithMod', digWithMod, ...
    'filterNsym', filterNsym, 'filterBeta', filterBeta, ...
    'sameChannel', sameChannel, 'correction', correction);
try close(hMsgBox); catch ex; end
assignin('base', 'iqdata', data);
set(handles.editNumSamples, 'String', num2str(length(data)));


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'bit', []))
    [data sampleRate] = calc_signal(handles);
    plotFct(handles.axesCh1, real(data), sampleRate, 1);
    plotFct(handles.axesCh2, imag(data), sampleRate, 2);
    set(handles.textPlaceHolder1, 'Visible', 'off');
    set(handles.textPlaceHolder2, 'Visible', 'off');
    hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
    try
        iqdownload(data, sampleRate);
    catch ex;
        errordlg(ex.message);
    end
    try close(hMsgBox); catch ex; end
end


function editSymbolRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSymbolRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSymbolRate as text
%        str2double(get(hObject,'String')) returns contents of editSymbolRate as a double


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



function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSamples as text
%        str2double(get(hObject,'String')) returns contents of editNumSamples as a double


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



function editNumSymbols_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSymbols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSymbols as text
%        str2double(get(hObject,'String')) returns contents of editNumSymbols as a double


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


% --- Executes on selection change in popupmenuFilterType.
function popupmenuFilterType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuFilterType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuFilterType


% --- Executes during object creation, after setting all properties.
function popupmenuFilterType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFilterNSym_Callback(hObject, eventdata, handles)
% hObject    handle to editFilterNSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilterNSym as text
%        str2double(get(hObject,'String')) returns contents of editFilterNSym as a double


% --- Executes during object creation, after setting all properties.
function editFilterNSym_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilterNSym (see GCBO)
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


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on button press in checkboxDigMod.
function checkboxDigMod_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxDigMod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxDigMod


% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
% hObject    handle to menuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuPreset_Callback(hObject, eventdata, handles)
% hObject    handle to menuPreset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuPresetNTSC_Callback(hObject, eventdata, handles)
% hObject    handle to menuPresetNTSC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.editCarrier, 'String', '91.25:6:115.25 151.25:6:169.25 217.25:6:541.25 547.25:6:997.25');
set(handles.editFreqDigAbove, 'String', '547');
set(handles.editNotchCarrier, 'String', '');
set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.checkboxDigMod, 'Value', 1);
set(handles.editSymbolRate, 'String', '5');
set(handles.editNumSymbols, 'String', '120');
set(handles.popupmenuModType, 'Value', 8);
set(handles.popupmenuFilterType, 'Value', 1);
set(handles.editFilterNSym, 'String', '20');
set(handles.editFilterBeta, 'String', '0.12');
set(handles.editDigitalAttenuation, 'String', '6');
set(handles.checkboxCorrection, 'Value', 0);


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
    [Y sampleRate] = calc_signal(handles);
    XDelta = 1/sampleRate;
    XStart = 0;
    InputZoom = 1;
    try
        save(strcat(PathName,FileName), 'Y', 'XDelta', 'XStart', 'InputZoom');
    catch ex
        errordlg(ex.message);
    end
end   



function editNotchCarrier_Callback(hObject, eventdata, handles)
% hObject    handle to editNotchCarrier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNotchCarrier as text
%        str2double(get(hObject,'String')) returns contents of editNotchCarrier as a double


% --- Executes during object creation, after setting all properties.
function editNotchCarrier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNotchCarrier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
