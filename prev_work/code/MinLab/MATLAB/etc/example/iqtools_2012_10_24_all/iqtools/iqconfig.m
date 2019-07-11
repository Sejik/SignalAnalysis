function varargout = iqconfig(varargin)
% IQCONFIG M-file for iqconfig.fig
%      IQCONFIG, by itself, creates a new IQCONFIG or raises the existing
%      singleton*.
%
%      H = IQCONFIG returns the handle to a new IQCONFIG or the handle to
%      the existing singleton*.
%
%      IQCONFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQCONFIG.M with the given input arguments.
%
%      IQCONFIG('Property','Value',...) creates a new IQCONFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqconfig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqconfig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqconfig

% Last Modified by GUIDE v2.5 21-Jun-2012 14:43:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqconfig_OpeningFcn, ...
                   'gui_OutputFcn',  @iqconfig_OutputFcn, ...
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


% --- Executes just before iqconfig is made visible.
function iqconfig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqconfig (see VARARGIN)

% Choose default command line output for iqconfig
handles.output = hObject;
set(handles.popupmenuModel, 'Value', 2);    % if nothing found, choose M8190A_14bit

% Update handles structure
guidata(hObject, handles);

try
    load('arbConfig.mat');
    if (exist('arbConfig', 'var'))
        if (isfield(arbConfig, 'model'))
            arbModels = get(handles.popupmenuModel, 'String');
            if (~exist('iqdownload_AWG7xxx.m', 'file'))
                arbModels{9} = '';
                set(handles.popupmenuModel, 'String', arbModels);
            end
            idx = find(strcmp(arbModels, arbConfig.model));
            if (isempty(idx) && strcmp(arbConfig.model, 'M8190A'))
                idx = 2;  % special case: M8190A turns into M8190A_14bit
            end
            if (idx > 0)
                set(handles.popupmenuModel, 'Value', idx);
            end
        end
        if (isfield(arbConfig, 'connectionType'))
            connTypes = get(handles.popupmenuConnectionType, 'String');
            idx = find(strcmp(connTypes, arbConfig.connectionType));
            if (idx > 0)
                set(handles.popupmenuConnectionType, 'Value', idx);
            end
            popupmenuConnectionType_Callback([], [], handles);
        end
        if (isfield(arbConfig, 'visaAddr'))
            set(handles.editVisaAddr, 'String', arbConfig.visaAddr);
        end
        if (isfield(arbConfig, 'ip_address'))
            set(handles.editIPAddress, 'String', arbConfig.ip_address);
        end
        if (isfield(arbConfig, 'port'))
            set(handles.editPort, 'String', num2str(arbConfig.port));
        end
        if (isfield(arbConfig, 'skew'))
            set(handles.editSkew, 'String', num2str(arbConfig.skew));
            set(handles.editSkew, 'Enable', 'on');
            set(handles.checkboxSetSkew, 'Value', 1);
        else
            set(handles.editSkew, 'Enable', 'off');
            set(handles.checkboxSetSkew, 'Value', 0);
        end
        if (isfield(arbConfig, 'amplitude'))
            set(handles.editAmpl1, 'String', num2str(arbConfig.amplitude(1)));
            set(handles.editAmpl1, 'Enable', 'on');
            set(handles.editAmpl2, 'String', num2str(arbConfig.amplitude(2)));
            set(handles.editAmpl2, 'Enable', 'on');
            set(handles.checkboxSetAmpl, 'Value', 1);
        else
            set(handles.editAmpl1, 'Enable', 'off');
            set(handles.editAmpl2, 'Enable', 'off');
            set(handles.checkboxSetAmpl, 'Value', 0);
        end
        if (isfield(arbConfig, 'offset'))
            set(handles.editOffs1, 'String', num2str(arbConfig.offset(1)));
            set(handles.editOffs1, 'Enable', 'on');
            set(handles.editOffs2, 'String', num2str(arbConfig.offset(2)));
            set(handles.editOffs2, 'Enable', 'on');
            set(handles.checkboxSetOffs, 'Value', 1);
        else
            set(handles.editOffs1, 'Enable', 'off');
            set(handles.editOffs2, 'Enable', 'off');
            set(handles.checkboxSetOffs, 'Value', 0);
        end
        if (isfield(arbConfig, 'ampType'))
            ampTypes = get(handles.popupmenuAmpType, 'String');
            idx = find(strcmp(ampTypes, arbConfig.ampType));
            if (idx > 0)
                set(handles.popupmenuAmpType, 'Value', idx);
            end
            set(handles.checkboxSetAmpType, 'Value', 1);
            set(handles.popupmenuAmpType, 'Enable', 'on');
        else
            set(handles.checkboxSetAmpType, 'Value', 0);
        end
        set(handles.checkboxExtClk, 'Value', (isfield(arbConfig, 'extClk') && arbConfig.extClk));
        set(handles.checkboxRST, 'Value', (isfield(arbConfig, 'do_rst') && arbConfig.do_rst));
        set(handles.checkboxInterleaving, 'Value', (isfield(arbConfig, 'interleaving') && arbConfig.interleaving));
        if (isfield(arbConfig, 'defaultFc'))
            set(handles.editDefaultFc, 'String', sprintf('%g', arbConfig.defaultFc));
        end
        tooltips = 1;
        if (isfield(arbConfig, 'tooltips') && arbConfig.tooltips == 0)
            tooltips = 0;
        end
        set(handles.checkboxTooltips, 'Value', tooltips);
        if (isfield(arbConfig, 'amplitudeScaling'))
            set(handles.editAmplScale, 'String', sprintf('%g', arbConfig.amplitudeScaling));
        end
        if (isfield(arbConfig, 'carrierFrequency'))
            set(handles.editCarrierFreq, 'String', sprintf('%g', arbConfig.carrierFrequency));
            set(handles.checkboxSetCarrierFreq, 'Value', 1);
        else
            set(handles.checkboxSetCarrierFreq, 'Value', 0);
        end
        popupmenuModel_Callback([], [], handles);
        if (isfield(arbConfig, 'visaAddr2'))
            handles.visaAddr2 = arbConfig.visaAddr2;
        end
        if (isfield(arbConfig, 'visaAddrScope'))
            handles.visaAddrScope = arbConfig.visaAddrScope;
        end
        guidata(hObject, handles);
    end
    % spectrum analyzer
    if (exist('saConfig', 'var'))
        if (isfield(saConfig, 'connected'))
            set(handles.checkboxSAattached, 'Value', saConfig.connected);
        end
        checkboxSAattached_Callback([], [], handles);
        if (isfield(saConfig, 'connectionType'))
            connTypes = get(handles.popupmenuConnectionTypeSA, 'String');
            idx = find(strcmp(connTypes, saConfig.connectionType));
            if (idx > 0)
                set(handles.popupmenuConnectionTypeSA, 'Value', idx);
            end
        end
        if (isfield(saConfig, 'visaAddr'))
            set(handles.editVisaAddrSA, 'String', saConfig.visaAddr);
        end
        if (isfield(saConfig, 'ip_address'))
            set(handles.editIPAddressSA, 'String', saConfig.ip_address);
        end
        if (isfield(saConfig, 'port'))
            set(handles.editPortSA, 'String', num2str(saConfig.port));
        end
        if (isfield(saConfig, 'useListSweep') && saConfig.useListSweep ~= 0)
            set(handles.popupmenuSAAlgorithm, 'Value', 3);
        elseif (isfield(saConfig, 'useMarker') && saConfig.useMarker ~= 0)
            set(handles.popupmenuSAAlgorithm, 'Value', 2);
        else
            set(handles.popupmenuSAAlgorithm, 'Value', 1);
        end
    end
catch e
end

if (~exist('arbConfig', 'var') || ~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.popupmenuModel, 'TooltipString', sprintf([ ...
    'Select the instrument model. For M8190A, you have to select in which\n', ...
    'mode the AWG will operate because the maximum sample rate and segment\n', ...
    'granularity are different for each mode. The "DUC" (digital upconversion)\n' ...
    'modes require a separate software license']));
set(handles.popupmenuConnectionType, 'TooltipString', sprintf([ ...
    'Use ''visa'' for connections through the VISA library.\n'...
    'Use ''tcpip'' for direct socket connections.\n' ...
    'For the 81180A ''tcpip'' is recommended. For the M8190A,\n' ...
    'a ''visa'' connection using the hislip protocol is recommended']));
set(handles.editVisaAddr, 'TooltipString', sprintf([ ...
    'Enter the VISA address as given in the Agilent Connection Expert.\n' ...
    'Examples:  TCPIP0::134.40.175.228::inst0::INSTR\n' ...
    '           TCPIP0::localhost::hislip0::INSTR\n' ...
    '           GPIB0::18::INSTR\n' ...
    'Note, that the M8190A can ONLY be connected through TCPIP.\n' ...
    'Do NOT attempt to connect via the PXIxx:x:x address.']));
set(handles.editIPAddress, 'TooltipString', sprintf([ ...
    'Enter the numeric IP address or hostname. For connection to the same\n' ...
    'PC, use ''localhost'' or 127.0.0.1']));
set(handles.editPort, 'TooltipString', sprintf([ ...
    'Specify the IP Port number for tcpip connection. Usually this is 5025.']));
set(handles.checkboxSetSkew, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the skew between I and Q\n' ...
    '(i.e. channel 1 and channel 2). If unchecked, the skew will remain unchanged']));
set(handles.editSkew, 'TooltipString', sprintf([ ...
    'Enter the skew between I and Q (i.e. channel 1 and 2) in units of seconds.\n' ...
    'Positive values will delay ch1 vs. ch2, negative values do the opposite.\n' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxSetAmpl, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the amplitude.\n' ...
    'If unchecked, the previously configured amplitude will remain unchanged']));
set(handles.editAmpl1, 'TooltipString', sprintf([ ...
    'Enter the amplitude for channel 1 (or I) in Volts.' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.editAmpl2, 'TooltipString', sprintf([ ...
    'Enter the amplitude for channel 2 (or Q) in Volts.' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxSetOffs, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the common mode offset.\n' ...
    'If unchecked, the previously configured offset will remain unchanged']));
set(handles.editOffs1, 'TooltipString', sprintf([ ...
    'Enter the common mode offset for channel 1 (or I) in Volts.' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.editOffs2, 'TooltipString', sprintf([ ...
    'Enter the common mode offset for channel 2 (or Q) in Volts.' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxSetAmpType, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the amplifier type.' ...
    'If unchecked, the previously configured amplifier type will remain unchanged.']));
set(handles.popupmenuAmpType, 'TooltipString', sprintf([ ...
    'Select the type of output amplifier you want to use. ''DAC'' is the direct output\n'...
    'from the DAC, which typically has the best signal performance, but limited\n' ...
    'amplitude/offset range. Note, that only some AWGs have switchable amplifiers:\n' ...
    '81180A, M8190A_12bit and M8190A_14bit']));
set(handles.checkboxExtClk, 'TooltipString', sprintf([ ...
    'Check this box if you want to use the external sample clock input of the AWG.\n' ...
    'Make sure that you have connected a clock signal to the external input before\n' ...
    'turning this function on. Also, make sure that you specify the external clock\n' ...
    'frequency in the ''sample rate'' field of the waveform utilities.\n' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxRST, 'TooltipString', sprintf([ ...
    'Check this box if you want to reset the AWG prior to downloading a new waveform.']));
set(handles.popupmenuConnectionTypeSA, 'TooltipString', sprintf([ ...
    'Use ''visa'' for connections through the VISA library.\n'...
    'Use ''tcpip'' for direct socket connections.\n' ...
    'For the 81180A ''tcpip'' is recommended.']));
set(handles.checkboxSAattached, 'TooltipString', sprintf([ ...
    'Check this box if you have a spectrum analyzer (PSA, MXA, PXA) connected\n' ...
    'and would like to use it for amplitude flatness correction']));
set(handles.editVisaAddrSA, 'TooltipString', sprintf([ ...
    'Enter the VISA address of the SA as given in the Agilent Connection Expert.\n' ...
    'Examples:  TCPIP0::134.40.175.228::inst0::INSTR\n' ...
    '           GPIB0::18::INSTR']));
set(handles.editIPAddressSA, 'TooltipString', sprintf([ ...
    'Enter the numeric IP address or hostname. For connection to the same\n' ...
    'PC, use ''localhost'' or 127.0.0.1']));
set(handles.editPortSA, 'TooltipString', sprintf([ ...
    'Specify the IP Port number for tcpip connection. Usually this is 5025.']));
set(handles.popupmenuSAAlgorithm, 'TooltipString', sprintf([ ...
    'Select the algorithm to use for amplitude correction on the SA.\n'...
    '''Zero span'' is the preferred method. It works reliable and is\n' ...
    'the most accurate. ''List sweep'' is only possible with MXA and PXA.\n' ...
    'It works a little faster than zero span, but is not as accurate.\n' ...
    '''Marker'' only works reliable if the resolution BW on the SA is set\n' ...
    'wide enough. It is not recommended in the general case.']));
set(handles.checkboxTooltips, 'TooltipString', sprintf([ ...
    'Enable/disable tooltips throughout the ''iqtools''.']));
set(handles.editDefaultFc, 'TooltipString', sprintf([ ...
    'If you are using the AWG with external upconversion, enter the\n' ...
    'LO frequency here. This value will be used in the multi-tone and\n' ...
    'digital modulation scripts to set the default center frequency.']));
set(handles.editAmplScale, 'TooltipString', sprintf([ ...
    'Set this to 1 to use the DAC to full scale. Values less than 1\n' ...
    'cause the waveform to be scaled to the given ratio and use less\n' ...
    'than the full scale DAC.']));
set(handles.checkboxInterleaving, 'TooltipString', sprintf([ ...
    'Check this checkbox to distribute even and odd samples to both\n' ...
    'channels. This can be used to virtually double the sample rate\n' ...
    'of the AWG. You have to manually adjust the delay of channel 2\n' ...
    'to one half of a sample period.']));
end

% UIWAIT makes iqconfig wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqconfig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editIPAddress_Callback(hObject, eventdata, handles)
% hObject    handle to editIPAddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editIPAddress as text
%        str2double(get(hObject,'String')) returns contents of editIPAddress as a double


% --- Executes during object creation, after setting all properties.
function editIPAddress_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIPAddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPort_Callback(hObject, eventdata, handles)
% hObject    handle to editPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPort as text
%        str2double(get(hObject,'String')) returns contents of editPort as a double


% --- Executes during object creation, after setting all properties.
function editPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkew_Callback(hObject, eventdata, handles)
% hObject    handle to editSkew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkew as text
%        str2double(get(hObject,'String')) returns contents of editSkew as a double
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function editSkew_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmpl1_Callback(hObject, eventdata, handles)
% hObject    handle to editAmpl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmpl1 as text
%        str2double(get(hObject,'String')) returns contents of editAmpl1 as a double
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function editAmpl1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmpl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmpl2_Callback(hObject, eventdata, handles)
% hObject    handle to editAmpl2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmpl2 as text
%        str2double(get(hObject,'String')) returns contents of editAmpl2 as a double
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function editAmpl2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmpl2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function editOffs1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOffs1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuConnectionType.
function popupmenuConnectionType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuConnectionType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuConnectionType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuConnectionType
connTypes = cellstr(get(handles.popupmenuConnectionType, 'String'));
connType = connTypes{get(handles.popupmenuConnectionType, 'Value')};
switch (connType)
    case 'tcpip'
        set(handles.editVisaAddr, 'Enable', 'off');
        set(handles.editIPAddress, 'Enable', 'on');
        set(handles.editPort, 'Enable', 'on');
    case 'visa'
        set(handles.editVisaAddr, 'Enable', 'on');
        set(handles.editIPAddress, 'Enable', 'off');
        set(handles.editPort, 'Enable', 'off');
end


% --- Executes during object creation, after setting all properties.
function popupmenuConnectionType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuConnectionType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSetSkew.
function checkboxSetSkew_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetSkew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetSkew
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.editSkew, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in checkboxSetAmpl.
function checkboxSetAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetAmpl
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.editAmpl1, 'Enable', onoff{val+1});
set(handles.editAmpl2, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in checkboxSetAmpType.
function checkboxSetAmpType_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetAmpType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetAmpType
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.popupmenuAmpType, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkVisaAddr(handles);
saveConfig(handles);
close(handles.output);


% --- Executes on selection change in popupmenuAmpType.
function popupmenuAmpType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuAmpType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuAmpType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuAmpType
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuAmpType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAmpType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function saveConfig(handles)
% retrieve all the field values and write arbConfig.mat
clear arbConfig;
arbModels = cellstr(get(handles.popupmenuModel, 'String'));
arbModel = arbModels{get(handles.popupmenuModel, 'Value')};
arbConfig.model = arbModel;
connTypes = cellstr(get(handles.popupmenuConnectionType, 'String'));
connType = connTypes{get(handles.popupmenuConnectionType, 'Value')};
arbConfig.connectionType = connType;
arbConfig.visaAddr = strtrim(get(handles.editVisaAddr, 'String'));
arbConfig.ip_address = get(handles.editIPAddress, 'String');
arbConfig.port = evalin('base', get(handles.editPort, 'String'));
arbConfig.defaultFc = evalin('base', get(handles.editDefaultFc, 'String'));
arbConfig.tooltips = get(handles.checkboxTooltips, 'Value');
arbConfig.amplitudeScaling = evalin('base', get(handles.editAmplScale, 'String'));
if (get(handles.checkboxSetCarrierFreq, 'Value'))
    arbConfig.carrierFrequency = evalin('base', get(handles.editCarrierFreq, 'String'));
end
if (get(handles.checkboxSetSkew, 'Value'))
    arbConfig.skew = evalin('base', get(handles.editSkew, 'String'));
end
if (get(handles.checkboxSetAmpl, 'Value'))
    ampl1 = evalin('base', get(handles.editAmpl1, 'String'));
    ampl2 = evalin('base', get(handles.editAmpl2, 'String'));
    arbConfig.amplitude = [ampl1 ampl2];
end
if (get(handles.checkboxSetOffs, 'Value'))
    offs1 = evalin('base', get(handles.editOffs1, 'String'));
    offs2 = evalin('base', get(handles.editOffs2, 'String'));
    arbConfig.offset = [offs1 offs2];
end
if (get(handles.checkboxSetAmpType, 'Value'))
    ampTypes = cellstr(get(handles.popupmenuAmpType, 'String'));
    ampType = ampTypes{get(handles.popupmenuAmpType, 'Value')};
    arbConfig.ampType = ampType;
end
if (get(handles.checkboxRST, 'Value'))
    arbConfig.do_rst = true;
end
if (get(handles.checkboxExtClk, 'Value'))
    arbConfig.extClk = true;
end
if (get(handles.checkboxInterleaving, 'Value'))
    arbConfig.interleaving = true;
end
if (isfield(handles, 'visaAddr2'))
    arbConfig.visaAddr2 = handles.visaAddr2;
end
if (isfield(handles, 'visaAddrScope'))
    arbConfig.visaAddrScope = handles.visaAddrScope;
end
% spectrum analyzer connections
clear saConfig;
saConfig.connected = get(handles.checkboxSAattached, 'Value');
connTypesSA = cellstr(get(handles.popupmenuConnectionTypeSA, 'String'));
connTypeSA = connTypesSA{get(handles.popupmenuConnectionTypeSA, 'Value')};
saConfig.connectionType = connTypeSA;
saConfig.visaAddr = get(handles.editVisaAddrSA, 'String');
saConfig.ip_address = get(handles.editIPAddressSA, 'String');
saConfig.port = evalin('base', get(handles.editPortSA, 'String'));
saAlgoIdx = get(handles.popupmenuSAAlgorithm, 'Value');
switch (saAlgoIdx)
    case 1 % zero span
        saConfig.useListSweep = 0;
        saConfig.useMarker = 0;
    case 2 % marker
        saConfig.useListSweep = 0;
        saConfig.useMarker = 1;
    case 3 % list sweep
        saConfig.useListSweep = 1;
        saConfig.useMarker = 0;
end
save('arbConfig', 'arbConfig', 'saConfig');
%
% Notify all open iqtool utilities that arbConfig has changed 
% Figure windows are recognized by their "iqtool" tag
try
    TempHide = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');
    figs = findobj(0, 'Type', 'figure', 'Tag', 'iqtool');
    set(0, 'ShowHiddenHandles', TempHide);
    for i = 1:length(figs)
        fig = figs(i);
        [path file ext] = fileparts(get(fig, 'Filename'));
        handles = guihandles(fig);
        feval(file, 'checkfields', fig, 'red', handles);
    end
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end


% --- Executes on button press in checkboxExtClk.
function checkboxExtClk_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxExtClk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxExtClk
paramChangedNote(handles);


function editVisaAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddr as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddr as a double
checkVisaAddr(handles);


% --- Executes during object creation, after setting all properties.
function editVisaAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in checkboxSAattached.
function checkboxSAattached_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSAattached (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxSAattached
saConnected = get(handles.checkboxSAattached, 'Value');
if (~saConnected)
    set(handles.popupmenuConnectionTypeSA, 'Enable', 'Off');
    set(handles.editVisaAddrSA, 'Enable', 'Off');
    set(handles.editIPAddressSA, 'Enable', 'Off');
    set(handles.editPortSA, 'Enable', 'Off');
    set(handles.popupmenuSAAlgorithm, 'Enable', 'Off');
else
    set(handles.popupmenuConnectionTypeSA, 'Enable', 'On');
    set(handles.popupmenuSAAlgorithm, 'Enable', 'On');
    popupmenuConnectionTypeSA_Callback(hObject, eventdata, handles);
end


function editVisaAddrSA_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrSA as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrSA as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrSA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuConnectionTypeSA.
function popupmenuConnectionTypeSA_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuConnectionTypeSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuConnectionTypeSA contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuConnectionTypeSA

% tcpip is very slow on the PXA
if (get(handles.popupmenuConnectionTypeSA, 'Value') == 1)
    warndlg('tcpip does not work reliably with the spectrum analyzer - please use visa');
end

contents = cellstr(get(handles.popupmenuConnectionTypeSA,'String'));
switch(contents{get(handles.popupmenuConnectionTypeSA, 'Value')})
    case 'tcpip'
        set(handles.editVisaAddrSA, 'Enable', 'off');
        set(handles.editIPAddressSA, 'Enable', 'on');
        set(handles.editPortSA, 'Enable', 'on');
    case 'visa'
        set(handles.editVisaAddrSA, 'Enable', 'on');
%        set(handles.editVisaAddrSA, 'String', ['TCPIP0::' get(handles.editIPAddressSA, 'String') '::inst0::INSTR']);
        set(handles.editIPAddressSA, 'Enable', 'off');
        set(handles.editPortSA, 'Enable', 'off');
end


% --- Executes during object creation, after setting all properties.
function popupmenuConnectionTypeSA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuConnectionTypeSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'Value', 2);  % select VISA as a default



function editIPAddressSA_Callback(hObject, eventdata, handles)
% hObject    handle to editIPAddressSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editIPAddressSA as text
%        str2double(get(hObject,'String')) returns contents of editIPAddressSA as a double


% --- Executes during object creation, after setting all properties.
function editIPAddressSA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIPAddressSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPortSA_Callback(hObject, eventdata, handles)
% hObject    handle to editPortSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPortSA as text
%        str2double(get(hObject,'String')) returns contents of editPortSA as a double


% --- Executes during object creation, after setting all properties.
function editPortSA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPortSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in popupmenuSAAlgorithm.
function popupmenuSAAlgorithm_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSAAlgorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of popupmenuSAAlgorithm


% --- Executes on selection change in popupmenuModel.
function popupmenuModel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuModel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuModel
arbModels = cellstr(get(handles.popupmenuModel, 'String'));
arbModel = arbModels{get(handles.popupmenuModel, 'Value')};
if (~isempty(strfind(arbModel, 'DUC')))
    set(handles.textCarrierFreq, 'Enable', 'on');
    set(handles.checkboxSetCarrierFreq, 'Enable', 'on');
    checkboxSetCarrierFreq_Callback(hObject, eventdata, handles);
else
    set(handles.textCarrierFreq, 'Enable', 'off');
    set(handles.editCarrierFreq, 'Enable', 'off');
    set(handles.checkboxSetCarrierFreq, 'Enable', 'off');
end
checkVisaAddr(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuModel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonApply.
function pushbuttonApply_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonApply (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveConfig(handles);
if (get(handles.checkboxExtClk, 'Value') == 1)
    errordlg(['Can''t apply settings to hardware with external clock turned on. ' ...
              'Please press "OK" and re-download your waveform']);
else
    iqdownload([], 0);
end



function editOffs1_Callback(hObject, eventdata, handles)
% hObject    handle to editOffs1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOffs1 as text
%        str2double(get(hObject,'String')) returns contents of editOffs1 as a double
paramChangedNote(handles);



function editOffs2_Callback(hObject, eventdata, handles)
% hObject    handle to editOffs2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOffs2 as text
%        str2double(get(hObject,'String')) returns contents of editOffs2 as a double
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function editOffs2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOffs2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSetOffs.
function checkboxSetOffs_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetOffs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetOffs
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.editOffs1, 'Enable', onoff{val+1});
set(handles.editOffs2, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in checkboxRST.
function checkboxRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxRST
paramChangedNote(handles);


function editDefaultFc_Callback(hObject, eventdata, handles)
% hObject    handle to editDefaultFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDefaultFc as text
%        str2double(get(hObject,'String')) returns contents of editDefaultFc as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value <= 1e11 && value >= 0)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDefaultFc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDefaultFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxTooltips.
function checkboxTooltips_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTooltips (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTooltips



function editAmplScale_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplScale as text
%        str2double(get(hObject,'String')) returns contents of editAmplScale as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value <= 1 && value >= 0)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function editAmplScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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


% --- Executes on button press in checkboxInterleaving.
function checkboxInterleaving_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxInterleaving (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxInterleaving
if (get(hObject,'Value'))
    msgbox({'Please use the GUI or Soft Front Panel of the AWG to adjust' ...
            'channel 2 to be delayed by 1/2 sample period with respect to' ...
            'channel 1. An easy way to check the correct delay is to generate' ...
            'a multitone signal with tones between DC and fs/4, observe the' ...
            'signal on a spectrum analyzer and adjust the channel 2 delay' ...
            'until the images in the second Nyquist band are minimial.'}, 'Note');
end



function editCarrierFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrierFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrierFreq as text
%        str2double(get(hObject,'String')) returns contents of editCarrierFreq as a double
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function editCarrierFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrierFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSetCarrierFreq.
function checkboxSetCarrierFreq_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetCarrierFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxSetCarrierFreq
val = get(handles.checkboxSetCarrierFreq, 'Value');
onoff = {'off' 'on'};
set(handles.editCarrierFreq, 'Enable', onoff{val+1});
%paramChangedNote(handles);


function paramChangedNote(handles)
% at least one parameter has changed --> notify user that the change will
% only be sent to hardware on the next waveform download
set(handles.textNote, 'Background', 'yellow');


function checkVisaAddr(handles)
visaAddr = upper(strtrim(get(handles.editVisaAddr, 'String')));
connTypes = cellstr(get(handles.popupmenuConnectionType, 'String'));
connType = connTypes{get(handles.popupmenuConnectionType, 'Value')};
arbModels = cellstr(get(handles.popupmenuModel, 'String'));
arbModel = arbModels{get(handles.popupmenuModel, 'Value')};
if (~isempty(strfind(arbModel, 'M8190')) && ...
    strcmpi(connType, 'visa') && ...
    isempty(strfind(visaAddr, 'TCPIP')))
    msgbox({'You selected the M8190A, but the Visa address that you specified' ...
            'does not start with TCPIP. Please use one of the visa addresses' ...
            'shown in the M8190A firmware window that starts with TCPIP...'}, 'replace');
end
