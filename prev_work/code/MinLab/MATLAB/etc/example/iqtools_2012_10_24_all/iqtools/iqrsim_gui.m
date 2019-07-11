function varargout = iqrsim_gui(varargin)
% IQRSIM_GUI MATLAB code for iqrsim_gui.fig
%      IQRSIM_GUI, by itself, creates a new IQRSIM_GUI or raises the existing
%      singleton*.
%
%      H = IQRSIM_GUI returns the handle to a new IQRSIM_GUI or the handle to
%      the existing singleton*.
%
%      IQRSIM_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQRSIM_GUI.M with the given input arguments.
%
%      IQRSIM_GUI('Property','Value',...) creates a new IQRSIM_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqrsim_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqrsim_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqrsim_gui

% Last Modified by GUIDE v2.5 01-Aug-2012 17:26:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqrsim_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqrsim_gui_OutputFcn, ...
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


% --- Executes just before iqrsim_gui is made visible.
function iqrsim_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqrsim_gui (see VARARGIN)

% Choose default command line output for iqrsim_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
axes(handles.axes1);
title('target path');
axes(handles.axes2);
title('distance to receiver');
axes(handles.axes3);
title('pulse envelope');
axes(handles.axes4);
title('pulse on time');

arbConfig = loadArbConfig();
if (isempty(strfind(arbConfig.model, 'bit')))
    errordlg({'This utility currently only supports M8190A in 12 or 14 bit mode. ' ...
        'Please use the "Configure Instrument Connection" utility to select an' ...
        'appropriate instrument configuration.'});
    close(handles.figure1);
    return;
end
if (isfield(arbConfig, 'do_rst') && arbConfig.do_rst)
    errordlg({'Please turn off the "send *RST" checkbox in the' ...
        'IQTools "Configuration" window, then restart this utility.'});
    close(handles.figure1);
    return;
end

% UIWAIT makes iqrsim_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqrsim_gui_OutputFcn(hObject, eventdata, handles) 
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



function editPRI_Callback(hObject, eventdata, handles)
% hObject    handle to editPRI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPRI as text
%        str2double(get(hObject,'String')) returns contents of editPRI as a double


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



function editTT_Callback(hObject, eventdata, handles)
% hObject    handle to editTT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTT as text
%        str2double(get(hObject,'String')) returns contents of editTT as a double


% --- Executes during object creation, after setting all properties.
function editTT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTT (see GCBO)
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


% --- Executes on selection change in popupmenuModulation.
function popupmenuModulation_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuModulation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuModulation
contents = cellstr(get(hObject,'String'));
modType = contents{get(hObject,'Value')};
if (strcmp(modType, 'User defined'))
    set(handles.textPMFormula, 'Enable', 'on');
    set(handles.editPMFormula, 'Enable', 'on');
    set(handles.textFMFormula, 'Enable', 'on');
    set(handles.editFMFormula, 'Enable', 'on');
else
    set(handles.textPMFormula, 'Enable', 'off');
    set(handles.editPMFormula, 'Enable', 'off');
    set(handles.textFMFormula, 'Enable', 'off');
    set(handles.editFMFormula, 'Enable', 'off');
end


% --- Executes during object creation, after setting all properties.
function popupmenuModulation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
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



function editAmplitudeRatio_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitudeRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplitudeRatio as text
%        str2double(get(hObject,'String')) returns contents of editAmplitudeRatio as a double


% --- Executes during object creation, after setting all properties.
function editAmplitudeRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplitudeRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSpan_Callback(hObject, eventdata, handles)
% hObject    handle to editSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSpan as text
%        str2double(get(hObject,'String')) returns contents of editSpan as a double


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


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, 0);


function startSimulation(handles, download)
set(handles.textHelper1, 'Visible', 'off');
numSteps = evalin('base', ['[' get(handles.editNumSteps, 'String') ']']);
amplRatio = evalin('base', ['[' get(handles.editAmplitudeRatio, 'String') ']']);
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
pri = evalin('base', ['[' get(handles.editPRI, 'String') ']']);
pw = evalin('base', ['[' get(handles.editPW, 'String') ']']);
tt = evalin('base', ['[' get(handles.editTT, 'String') ']']);
shapeList = get(handles.popupmenuShape, 'String');
shapeIdx = get(handles.popupmenuShape, 'Value');
FMFormula = get(handles.editFMFormula, 'String');
PMFormula = get(handles.editPMFormula, 'String');
span_f = evalin('base', ['[' get(handles.editSpan, 'String') ']']);
offset_f = evalin('base', ['[' get(handles.editOffset, 'String') ']']);
modulationList = get(handles.popupmenuModulation, 'String');
modulationIdx = get(handles.popupmenuModulation, 'Value');
correction = get(handles.checkboxCorrection, 'Value');
movingPhase = get(handles.checkboxMovingPhase, 'Value');
extMovingPhase = get(handles.checkboxExtMovingPhase, 'Value');
extUp = get(handles.checkboxExtUpconversion, 'Value');
extLO = evalin('base', ['[' get(handles.editExtLO, 'String') ']']);
targetList = get(handles.popupmenuTargetSelection, 'String');
targetIdx = get(handles.popupmenuTargetSelection, 'Value');
targetPos = get(handles.uitableTargetPos, 'Data');
radarPos = get(handles.uitableRcvrPos, 'Data');
if (~extUp)
    extLO = 0;
    extMovingPhase = 0;
end

try
iqrsim('axes', [handles.axes1 handles.axes2 handles.axes3 handles.axes4], ...
    'msgbox', true, 'download', download, 'numSteps', numSteps, ...
    'PRI', pri, 'PW', pw, 'tt', tt, ...
    'pulseShape', shapeList{shapeIdx}, 'span', span_f, 'offset', offset_f, ...
    'amplRatio', amplRatio, 'fmFormula', FMFormula, 'pmFormula', PMFormula, ...
    'modulationType', modulationList{modulationIdx}, 'sampleRate', sampleRate, ...
    'movingPhase', movingPhase, 'extMovingPhase', extMovingPhase, 'extLO', extLO, ...
    'correction', correction, 'targetSelection', targetList{targetIdx}, ...
    'targetPos', targetPos, 'radarPos', radarPos);
catch ex
    [path name ext] = fileparts(ex.stack(1).file);
    errordlg(['Unexpected error in ' name ext ...
        ', line ' num2str(ex.stack(1).line) ': ' ex.message]);
end

% --- Executes on selection change in popupmenuTargetSelection.
function popupmenuTargetSelection_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTargetSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuTargetSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuTargetSelection


% --- Executes during object creation, after setting all properties.
function popupmenuTargetSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTargetSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonCorrection.
function pushbuttonCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function editNumSteps_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSteps as text
%        str2double(get(hObject,'String')) returns contents of editNumSteps as a double


% --- Executes during object creation, after setting all properties.
function editNumSteps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFMFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editFMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFMFormula as text
%        str2double(get(hObject,'String')) returns contents of editFMFormula as a double


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



function editExtLO_Callback(hObject, eventdata, handles)
% hObject    handle to editExtLO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editExtLO as text
%        str2double(get(hObject,'String')) returns contents of editExtLO as a double


% --- Executes during object creation, after setting all properties.
function editExtLO_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editExtLO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxMovingPhase.
function checkboxMovingPhase_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxMovingPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxMovingPhase


% --- Executes on button press in checkboxExtMovingPhase.
function checkboxExtMovingPhase_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxExtMovingPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxExtMovingPhase


% --- Executes on button press in checkboxExtUpconversion.
function checkboxExtUpconversion_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxExtUpconversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxExtUpconversion
extup = get(hObject,'Value') + 1;
onoff = { 'off' 'on' };
set(handles.textExtLO, 'Enable', onoff{extup});
set(handles.editExtLO, 'Enable', onoff{extup});
set(handles.textExtMovingPhase, 'Enable', onoff{extup});
set(handles.checkboxExtMovingPhase, 'Enable', onoff{extup});


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'bit', 'SEQ'))
    startSimulation(handles, 1);
end


% --- Executes on button press in pushbuttonVSA.
function pushbuttonVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function editDoppler_Callback(hObject, eventdata, handles)
% hObject    handle to editDoppler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDoppler as text
%        str2double(get(hObject,'String')) returns contents of editDoppler as a double


% --- Executes during object creation, after setting all properties.
function editDoppler_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDoppler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonRcvrMore.
function pushbuttonRcvrMore_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRcvrMore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableRcvrPos, 'Data');
data(end+1,:) = -1 * data(end,:);
set(handles.uitableRcvrPos, 'Data', data);
if (size(data,1) > 1)
    set(handles.pushbuttonRcvrLess, 'Enable', 'on');
    set(handles.pushbuttonRcvrMore, 'Enable', 'off');
end


% --- Executes on button press in pushbuttonRcvrLess.
function pushbuttonRcvrLess_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRcvrLess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableRcvrPos, 'Data');
data(end,:) = [];
set(handles.uitableRcvrPos, 'Data', data);
if (size(data,1) <= 1)
    set(handles.pushbuttonRcvrLess, 'Enable', 'off');
    set(handles.pushbuttonRcvrMore, 'Enable', 'on');
end


% --- Executes on button press in pushbuttonTargetMore.
function pushbuttonTargetMore_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTargetMore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableTargetPos, 'Data');
data(end+1,:) = data(end,:);
data(end,:) = data(end,:) + 1;  % use different values to avoid errors
set(handles.uitableTargetPos, 'Data', data);
if (size(data,1) > 2)
    set(handles.pushbuttonTargetLess, 'Enable', 'on');
end


% --- Executes on button press in pushbuttonTargetLess.
function pushbuttonTargetLess_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTargetLess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableTargetPos, 'Data');
data(end,:) = [];
set(handles.uitableTargetPos, 'Data', data);
if (size(data,1) <= 2)
    set(handles.pushbuttonTargetLess, 'Enable', 'off');
end


% --- Executes when entered data in editable cell(s) in uitableTargetPos.
function uitableTargetPos_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableTargetPos (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
