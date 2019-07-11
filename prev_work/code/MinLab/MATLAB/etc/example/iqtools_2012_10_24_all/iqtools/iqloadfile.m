function varargout = iqloadfile(varargin)
% IQLOADFILE MATLAB code for iqloadfile.fig
%      IQLOADFILE, by itself, creates a new IQLOADFILE or raises the existing
%      singleton*.
%
%      H = IQLOADFILE returns the handle to a new IQLOADFILE or the handle to
%      the existing singleton*.
%
%      IQLOADFILE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQLOADFILE.M with the given input arguments.
%
%      IQLOADFILE('Property','Value',...) creates a new IQLOADFILE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqloadfile_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqloadfile_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqloadfile

% Last Modified by GUIDE v2.5 21-Sep-2012 14:02:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqloadfile_OpeningFcn, ...
                   'gui_OutputFcn',  @iqloadfile_OutputFcn, ...
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


% --- Executes just before iqloadfile is made visible.
function iqloadfile_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqloadfile (see VARARGIN)

% Choose default command line output for iqloadfile
handles.output = hObject;
arbConfig = loadArbConfig();
if (arbConfig.maxSegmentNumber <= 1)
    set(handles.editSegment, 'Enable', 'off');
    set(handles.textSegment, 'Enable', 'off');
end
if (~isempty(strfind(arbConfig.model, 'DUC')))
    set(handles.popupmenuDownload, 'String', ['RF to channel 1+2'; 'RF to channel 1  '; 'RF to channel 2  ']);
end

% Update handles structure
guidata(hObject, handles);

set(handles.editSampleRate, 'String', sprintf('%g', arbConfig.defaultSampleRate));
set(handles.editSamplesName, 'Enable', 'off');
set(handles.editSamplePeriodName, 'Enable', 'off');
set(handles.editMarkerName, 'Enable', 'off');
set(handles.popupmenuType, 'Value', 2);
set(handles.popupmenuN5110A_M1, 'Value', 2);
set(handles.popupmenuN5110A_M2, 'Value', 3);
set(handles.popupmenuN5110A_M3, 'Value', 4);
set(handles.popupmenuN5110A_M4, 'Value', 5);
% change the width of the window
%pos = get(handles.figure1, 'Position');
%pos(3) = 60;
%set(handles.figure1, 'Position', pos);
% move the parameter panels on top of each other
%pos = get(handles.uipanelVarNames, 'Position');
%set(handles.uipanelCSV, 'Position', pos);
%set(handles.uipanelN5110A, 'Position', pos);
popupmenuType_Callback([], [], handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editFilename, 'TooltipString', sprintf([ ...
    'Enter the filename that you would like to download. You can use the\n' ...
    '"..." button on the right to open a file selection dialog.']));
set(handles.popupmenuType, 'TooltipString', sprintf([ ...
    'Select the type of input file to download. For "CSV", the file must contain\n' ...
    'one or two columns of data (separated by comma) that are loaded into channel 1\n' ...
    'resp. channel 2 of the AWG.\n\n' ...
    'For file type "MAT", the MATLAB file must contain at least one vector that\n' ...
    'contains the data. A real data vector will be loaded in channel 1, a complex\n' ...
    'vector will be loaded in both channels (real to channel 1, imaginary to channel 2\n' ...
    'Optionally the MATLAB file can contain another scalar variable that holds\n' ...
    'the sampling period. The names of these variable must be specified in the fields\n' ...
    'below.']));
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the sample rate at which the file has been captured. In case\n' ...
    'of MATLAB files, the sample rate can also be stored in the file.\n' ...
    'Note: Even if the waveform is up-converted, this field must contain\n' ...
    'the sample rate of the samples in the file.']));
set(handles.checkboxFromFile, 'TooltipString', sprintf([ ...
    'If the sample period is stored in a MATLAB file, check this checkbox;\n' ...
    'otherwise uncheck it and specify the sample rate in the "Sample Rate" field.']));
set(handles.checkboxResample, 'TooltipString', sprintf([ ...
    'If the sample rate of the file is too slow for the AWG, you can check this\n' ...
    'checkbox to perform re-sampling and convert the waveform to a higher \n' ...
    'sampling rate.']));
set(handles.popupmenuResampleMethod, 'TooltipString', sprintf([ ...
    'Defines the method used for re-sampling. Interpolation uses a low-pass\n' ...
    'filter, whereas FFT performs an FFT, adds zeros and performs in IFFT.\n' ...
    'Depending on the type of the signal one or the other method works better.\n' ...
    'In case of doubt, try it out...']));
set(handles.editSamplesName, 'TooltipString', sprintf([ ...
    'Specify the name of the variable that is used in the MATLAB data file\n' ...
    'that holds the signal vector.']));
set(handles.editSamplePeriodName, 'TooltipString', sprintf([ ...
    'Specify the name of the variable that is used in the MATLAB data file\n' ...
    'that holds the sample period.']));
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
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The signal will be displayed both in the time- as well as frequency\n' ...
    'domain (spectrum). This function can be used even without any hardware\n' ...
    'connected.']));
set(handles.editSegment, 'TooltipString', sprintf([ ...
    'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
    'If you download to segment #1, all other segments will be automatically\n' ...
    'deleted.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
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
set(handles.popupmenuDataColumn, 'TooltipString', sprintf([ ...
    'Select if the file contains one or two data columns.\n' ...
    'In case of two columns, they will be loaded into channels 1 and 2\n' ...
    'or treated as I + Q components in DUC mode.\n']));
set(handles.popupmenuMarkerColumn, 'TooltipString', sprintf([ ...
    'Select which columns in the CSV file contain marker information\n' ...
    'and how it is encoded. The marker columns are always expected to\n' ...
    'follow the data columns.  If you select "encoded", then bits 0 and 1\n' ...
    'means sample and sync marker of channel 1, bits 2 and 3 are used to\n' ...
    'define sample & sync marker for channel 2. Otherwise, each column is\n' ...
    'expected to contain only the indicated marker (1 or 0)']));
end
% UIWAIT makes iqloadfile wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqloadfile_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilename as text
%        str2double(get(hObject,'String')) returns contents of editFilename as a double
filename = get(handles.editFilename, 'String');
try
    f = fopen(filename, 'r');
    fclose(f);
    type = get(handles.popupmenuType, 'Value');
    if (type == 3)  % N5110A .bin file
        % try to find associated .txt file and extract sample rate
        file2 = [filename '.txt'];
        try
            f = fopen(file2, 'r');
            a = fgetl(f);
            while (a ~= -1)
                if (~isempty(strfind(a, 'XDelta')))
                    sr = str2double(a(8:end));
                    set(handles.editSampleRate, 'String', sprintf('%g', sr));
                    break;
                end
                a = fgetl(f);
            end
            fclose(f);
        catch ex % ignore any errors
        end
    end
catch ex
    errordlg(sprintf('Can''t open %s', filename'));
end


% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuType.
function popupmenuType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuType
val = get(handles.popupmenuType, 'Value');
filename = get(handles.editFilename, 'String');
setNewFilename = (~isempty(strfind(filename, 'example.')));
switch (val)
    case 1 % csv
        set(handles.editSampleRate, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Value', 0);
        set(handles.editSamplesName, 'Enable', 'off');
        set(handles.editSamplePeriodName, 'Enable', 'off');
        set(handles.editMarkerName, 'Enable', 'off');
        set(handles.uipanelCSV, 'Visible', 'on');
        set(handles.uipanelVarNames, 'Visible', 'off');
        set(handles.uipanelN5110A, 'Visible', 'off');
        if (setNewFilename)
            set(handles.editFilename, 'String', 'iqtools/example.csv');
        end
    case 2 % mat
        set(handles.editSampleRate, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Value', 1);
        set(handles.editSamplesName, 'Enable', 'on');
        set(handles.editMarkerName, 'Enable', 'on');
        set(handles.uipanelCSV, 'Visible', 'off');
        set(handles.uipanelVarNames, 'Visible', 'on');
        set(handles.uipanelN5110A, 'Visible', 'off');
        if (get(handles.checkboxFromFile, 'Value'))
            set(handles.editSamplePeriodName, 'Enable', 'on');
        else
            set(handles.editSamplePeriodName, 'Enable', 'off');
        end
        if (setNewFilename)
            set(handles.editFilename, 'String', 'iqtools/example.mat');
        end
    case {3 4} % N5110A
        set(handles.editSampleRate, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Value', 0);
        set(handles.editSamplesName, 'Enable', 'off');
        set(handles.editSamplePeriodName, 'Enable', 'off');
        set(handles.editMarkerName, 'Enable', 'off');
        set(handles.uipanelVarNames, 'Visible', 'off');
        set(handles.uipanelCSV, 'Visible', 'off');
        set(handles.uipanelN5110A, 'Visible', 'on');
        if (setNewFilename)
            if (val == 3)
                set(handles.editFilename, 'String', 'iqtools/example.bin');
            else
                set(handles.editFilename, 'String', 'iqtools/example.data');
            end
        end
end


% --- Executes during object creation, after setting all properties.
function popupmenuType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function [iqdata fs marker] = readFile(handles)
iqdata = [];
fs = 0;
marker = [];
type = get(handles.popupmenuType, 'Value');
filename = get(handles.editFilename, 'String');
correction = get(handles.checkboxCorrection, 'Value');
fromFile = get(handles.checkboxFromFile, 'Value');
err = ['Error opening file: ' filename];
try
    switch (type)
        case 1   % csv
            err = 'CSV Format error';
            data = csvread(filename);
            dtype = get(handles.popupmenuDataColumn, 'Value');
            mtype = get(handles.popupmenuMarkerColumn, 'Value');
            err = 'CSV Format error (data columns)';
            if (dtype == 2)
                iqdata = complex(data(:,1), data(:,2));
                moffset = 3;
            else
                iqdata = data(:,1);
                moffset = 2;
            end
            err = 'CSV Format error (marker columns)';
            switch(mtype)
                case 1 % None
                    marker = [];
                case 2 % encoded
                    marker = data(:,moffset);
                case 3 % sample, sync
                    marker = bitor(double(data(:,moffset))~=0, bitshift(double(data(:,moffset+1)~=0),1));
                case 4 % sync, sample
                    marker = bitor(double(data(:,moffset+1))~=0, bitshift(double(data(:,moffset)~=0),1));
            end
            err = 'Invalid sample rate';
            if (fromFile)
                err = 'Must specify sample rate';
                error(err);
            end
            fs = evalin('base', get(handles.editSampleRate, 'String'));
        case 2   % mat
            data = load(filename);
            fields = fieldnames(data);
            err = 'Expected variables not found in mat file';
            if (length(fieldnames(data)) == 1)
                samplesName = fields{1};
                set(handles.editSamplesName, 'String', samplesName);
            elseif (length(fieldnames(data)) == 2)
                samplesName = fields{1};    % assume that samples are first
                periodName = fields{2};
                samples = eval(['data.' samplesName]);
                if (isscalar(samples))     % well, try the other way round
                    samplesName = fields{2};
                    periodName = fields{1};
                end
                set(handles.editSamplesName, 'String', samplesName);
                if (isscalar(eval(['data.' periodName])))
                    set(handles.editSamplePeriodName, 'String', periodName);
                end
            else
                samplesName = get(handles.editSamplesName, 'String');
            end
            err = sprintf('Variable name for samples (%s) not found in mat file', samplesName);
            iqdata = eval(['data.' samplesName]);
            if (fromFile)
                samplePeriodName = get(handles.editSamplePeriodName, 'String');
                err = sprintf('Variable name for sample period (%s) not found in mat file', samplePeriodName);
                fs = eval(['data.' samplePeriodName]);
                if (fs < 1)
                    fs = 1 / fs;    % can specify either sample rate or sample period
                end
                set(handles.editSampleRate, 'String', sprintf('%g', fs));
                editSampleRate_Callback(0, 0, handles);
            else
                err = sprintf('invalid sample rate (%s)', get(handles.editSampleRate, 'String'));
                fs = evalin('base', get(handles.editSampleRate, 'String'));
            end
            markerName = strtrim(get(handles.editMarkerName, 'String'));
            if (~strcmp(markerName, ''))
                err = sprintf('Variable name for Markers (%s) not found in mat file', markerName);
                marker = eval(['data.' markerName]);
            end
        case {3 4}  % N5110A format   I/Q interleaved with Markers in low order bits
            if (type == 3)
                byteOrder = 'ieee-le';
            else
                byteOrder = 'ieee-be';
            end
            f = fopen(filename, 'r', byteOrder);
            a = uint16(fread(f, inf, 'uint16'));
            fclose(f);
            err = 'File format error';
            m = [get(handles.popupmenuN5110A_M1, 'Value') ...
                 get(handles.popupmenuN5110A_M2, 'Value') ...
                 get(handles.popupmenuN5110A_M3, 'Value') ...
                 get(handles.popupmenuN5110A_M4, 'Value')];
            % markers are stored in the least significant 2 bits 
            mkr = bitand(a, 3);
            % remote markers from signal
            a = bitand(a, hex2dec('FFFC'));
            % convert into two's complement
            a = mod((int32(a) + 32768), 65536) - 32768;
            % separate I and Q into separate rows
            a = double(reshape(a, 2, length(a)/2)) / 32768;
            % separate marker 1&3 and 2&4 also into separate rows
            mkr = reshape(mkr, 2, length(mkr)/2);
            % combine all markers into a single vector with lower 4 bits
            % representing the markers
            mkr(1,:) = 4 * mkr(2,:) + mkr(1,:);
            % second column in no longer needed
            mkr(2,:) = [];
            % initialize the "final" marker vector
            marker = uint16(zeros(1, length(mkr)));
            % rearrange the marker bits according to user input
            for i=1:4
                if (m(i) >= 2)
                    marker = bitor(marker, bitshift(bitand(bitshift(mkr, -i+1), 1), m(i)-2));
                end
            end
            % create complex data from the two rows
            iqdata = complex(a(1,:), a(2,:));
            % determine the sample rate
            err = sprintf('invalid sample rate (%s)', get(handles.editSampleRate, 'String'));
            fs = evalin('base', get(handles.editSampleRate, 'String'));
            if (fs < 1)
                fs = 1 / fs;    % can specify either sample rate or sample period
            end
        otherwise
            error('unknown file format');
    end
catch e
    errordlg({err, e.message});
    iqdata = [];
    return;
end
iqdata = reshape(iqdata, length(iqdata), 1);
if (get(handles.checkboxResample, 'Value'))
    methodList = cellstr(get(handles.popupmenuResampleMethod,'String'));
    method = methodList{get(handles.popupmenuResampleMethod,'Value')};
    factor = evalin('base', get(handles.editResampleFactor,'String'));
    switch (method)
        case 'interpolate'; ipfct = @(data,r) interp(double(data), r);
        case 'fft'; ipfct = @(data,r) interpft(data, r * length(data));
        otherwise error('unknown method');
    end
    try
        iqdata = ipfct(iqdata, factor);
        fs = fs * factor;
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
end
if (get(handles.checkboxFreqShift, 'Value'))
    fc = evalin('base', get(handles.editFc,'String'));
    n = length(iqdata);
    iqdata = iqdata .* exp(j*2*pi*round(n*fc/fs)/n*(1:n)');
end
if (correction)
    iqdata = iqcorrection(iqdata, fs);
end

% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata fs marker] = readFile(handles);
if (~isempty(iqdata))
    iqplot(iqdata, fs, 'marker', marker);
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...');
[iqdata fs marker] = readFile(handles);
if (~isempty(iqdata))
    len = numel(iqdata);
    iqdata = reshape(iqdata, len, 1);
    marker = reshape(marker, numel(marker), 1);
    arbConfig = loadArbConfig();
    rept = lcm(len, arbConfig.segmentGranularity) / len;
    if (rept * len < arbConfig.minimumSegmentSize)
        rept = rept+1;
    end
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    downloadList = cellstr(get(handles.popupmenuDownload, 'String'));
    downloadToChannel = downloadList{get(handles.popupmenuDownload, 'Value')};
    iqdownload(repmat(iqdata, rept, 1), fs, 'downloadToChannel', downloadToChannel, ...
        'segmentNumber', segmentNum, 'marker', repmat(marker, rept, 1));
    assignin('base', 'iqdata', repmat(iqdata, rept, 1));
end
try close(hMsgBox); catch ex; end;

function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
arbConfig = loadArbConfig();
rs = get(handles.checkboxResample, 'Value');
if (isscalar(value) && rs || (value >= arbConfig.minimumSampleRate && value <= arbConfig.maximumSampleRate))
    set(handles.editSampleRate,'BackgroundColor','white');
else
    set(handles.editSampleRate,'BackgroundColor','red');
end
calcNewSampleRate(handles);

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


% --- Executes on button press in checkboxFromFile.
function checkboxFromFile_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFromFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxFromFile
val = get(handles.checkboxFromFile, 'Value');
onoff = {'on' 'off'};
set(handles.editSampleRate, 'Enable', onoff{val+1});
type = get(handles.popupmenuType,'Value');
if (type == 2) % mat
    if (val)
        set(handles.editSamplePeriodName, 'Enable', 'on');
    else
        set(handles.editSamplePeriodName, 'Enable', 'off');
    end
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection



function editSamplePeriodName_Callback(hObject, eventdata, handles)
% hObject    handle to editSamplePeriodName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSamplePeriodName as text
%        str2double(get(hObject,'String')) returns contents of editSamplePeriodName as a double


% --- Executes during object creation, after setting all properties.
function editSamplePeriodName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSamplePeriodName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSamplesName_Callback(hObject, eventdata, handles)
% hObject    handle to editSamplesName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSamplesName as text
%        str2double(get(hObject,'String')) returns contents of editSamplesName as a double


% --- Executes during object creation, after setting all properties.
function editSamplesName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSamplesName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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


% --- Executes on button press in checkboxResample.
function checkboxResample_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxResample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxResample
val = get(hObject,'Value');
if (val)
    set(handles.editResampleFactor, 'Enable', 'on');
    set(handles.popupmenuResampleMethod, 'Enable', 'on');
else
    set(handles.editResampleFactor, 'Enable', 'off');
    set(handles.popupmenuResampleMethod, 'Enable', 'off');
end
editSampleRate_Callback(0, 0, handles);
%calcNewSampleRate(handles);


function editResampleFactor_Callback(hObject, eventdata, handles)
% hObject    handle to editResampleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editResampleFactor as text
%        str2double(get(hObject,'String')) returns contents of editResampleFactor as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
if (isscalar(value) && value > 0 && value <= 10000)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end
calcNewSampleRate(handles);


function calcNewSampleRate(handles)
factor = evalin('base', get(handles.editResampleFactor,'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
newRate = sampleRate * factor;
set(handles.editNewSampleRate, 'String', sprintf('%g', newRate));
rs = get(handles.checkboxResample, 'Value');
arbConfig = loadArbConfig();
if (~rs || ...
    newRate >= arbConfig.minimumSampleRate && ...
    newRate <= arbConfig.maximumSampleRate)
    set(handles.editNewSampleRate,'BackgroundColor','white');
    set(handles.editNewSampleRate,'Enable','off');
else
    set(handles.editNewSampleRate,'Enable','on');
    set(handles.editNewSampleRate,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editResampleFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editResampleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNewSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editNewSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNewSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editNewSampleRate as a double


% --- Executes during object creation, after setting all properties.
function editNewSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNewSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuResampleMethod.
function popupmenuResampleMethod_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuResampleMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuResampleMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuResampleMethod


% --- Executes during object creation, after setting all properties.
function popupmenuResampleMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuResampleMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonFileName.
function pushbuttonFileName_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
type = get(handles.popupmenuType, 'Value');
types = {'.csv' '.mat' '.bin' '.data'};
try
[FileName,PathName] = uigetfile(types{type});
if(FileName~=0)
   FileName = strcat(PathName,FileName);
   set(handles.editFilename, 'String', FileName);
   editFilename_Callback([], eventdata, handles);
end   
catch ex
end



function editFc_Callback(hObject, eventdata, handles)
% hObject    handle to editFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFc as text
%        str2double(get(hObject,'String')) returns contents of editFc as a double


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


% --- Executes on button press in checkboxFreqShift.
function checkboxFreqShift_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFreqShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxFreqShift
val = get(hObject,'Value');
if (val)
    set(handles.editFc, 'Enable', 'on');
else
    set(handles.editFc, 'Enable', 'off');
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



function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSegment as text
%        str2double(get(hObject,'String')) returns contents of editSegment as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
arbConfig = loadArbConfig();
if (isscalar(value) && value >= 1 && value <= arbConfig.maxSegmentNumber)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


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



function editMarkerName_Callback(hObject, eventdata, handles)
% hObject    handle to editMarkerName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMarkerName as text
%        str2double(get(hObject,'String')) returns contents of editMarkerName as a double


% --- Executes during object creation, after setting all properties.
function editMarkerName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMarkerName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuMarkerColumn.
function popupmenuMarkerColumn_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMarkerColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMarkerColumn contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMarkerColumn


% --- Executes during object creation, after setting all properties.
function popupmenuMarkerColumn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMarkerColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M1.
function popupmenuN5110A_M1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M1


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M2.
function popupmenuN5110A_M2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M2


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M3.
function popupmenuN5110A_M3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M3


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M4.
function popupmenuN5110A_M4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M4


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDataColumn.
function popupmenuDataColumn_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDataColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDataColumn contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDataColumn


% --- Executes during object creation, after setting all properties.
function popupmenuDataColumn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDataColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
