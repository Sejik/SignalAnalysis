function varargout = iqseq_M8190A_gui(varargin)
% IQSEQ_M8190A_GUI MATLAB code for iqseq_M8190A_gui.fig
%      IQSEQ_M8190A_GUI, by itself, creates a new IQSEQ_M8190A_GUI or raises the existing
%      singleton*.
%
%      H = IQSEQ_M8190A_GUI returns the handle to a new IQSEQ_M8190A_GUI or the handle to
%      the existing singleton*.
%
%      IQSEQ_M8190A_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQSEQ_M8190A_GUI.M with the given input arguments.
%
%      IQSEQ_M8190A_GUI('Property','Value',...) creates a new IQSEQ_M8190A_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqseq_M8190A_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqseq_M8190A_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqseq_M8190A_gui

% Last Modified by GUIDE v2.5 09-Oct-2012 12:56:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqseq_M8190A_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqseq_M8190A_gui_OutputFcn, ...
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


% --- Executes just before iqseq_M8190A_gui is made visible.
function iqseq_M8190A_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqseq_M8190A_gui (see VARARGIN)

% Choose default command line output for iqseq_M8190A_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqseq_M8190A_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqseq_M8190A_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if hardware and options are available
if (~iqoptcheck([], 'M8190A', 'SEQ'))
    return;
end
hMsgBox = msgbox('Downloading Sequence. Please wait...', 'Please wait...', 'replace');
downloadToChannel = getDownloadToChannel(handles);
% load the amplitude table
amplitudeTable = get(handles.uitableAmplitude, 'Data');
if (size(amplitudeTable,1) > 0)
    atab = ones(1,size(amplitudeTable,1));
    for i=1:size(amplitudeTable,1)
        try
            atab(i) = evalin('base', ['[' amplitudeTable{i,2} ']']);
        catch ex
            errordlg({['Syntax error in amplitude table, row ' num2str(i-1) ':'] ...
                ex.message});
            break;
        end
    end
    iqseq('amplitudeTable', atab, 'downloadToChannel', downloadToChannel);
end
% load the frequency table
frequencyTable = get(handles.uitableFrequency, 'Data');
if (size(frequencyTable,1) > 0)
    ftab = 10e6 * ones(1,size(frequencyTable,1));
    for i=1:size(frequencyTable,1)
        try
            ftab(i) = evalin('base', ['[' frequencyTable{i,2} ']']);
        catch ex
            errordlg({['Syntax error in frequency table, row ' num2str(i-1) ':'] ...
                ex.message});
            break;
        end
    end
    iqseq('frequencyTable', ftab, 'downloadToChannel', downloadToChannel);
end
% load the action table
actionTable = cell2struct(get(handles.uitableAction, 'Data'), {'idx', 'new', 'act', 'param'}, 2);
iqseq('actionDeleteAll', [], 'downloadToChannel', downloadToChannel);
actCount = 0;
clear a;
if (size(actionTable,1) > 0)
    for i=1:size(actionTable,1)
        if (actionTable(i).new)
            actCount = actCount + 1;
            a(actCount) = iqseq('actionDefine', [], 'downloadToChannel', downloadToChannel);
        end
        switch(actionTable(i).act)
            case 'Phase Offset'; acode = 'POFFset';
            case 'Phase Bump'; acode = 'PBUMp';
            case 'Phase Reset'; acode = 'PRESet';
            case 'Carrier Frequency'; acode = 'CFRequency';
            case 'Amplitude Scale'; acode = 'AMPLitude';
            case 'Sweep Rate'; acode = 'SRATe';
            case 'Sweep Run'; acode = 'SRUN';
            case 'Sweep Hold'; acode = 'SHOLd';
            case 'Sweep Restart'; acode = 'SREStart';
            otherwise; error(['unknown action: ' actionTable(i).act]);
        end
        try
            param = eval(['[' actionTable(i).param ']']);
        catch ex
            errordlg({['Syntax error in action parameter, row ' num2str(i) ':'] ...
                ex.message});
        end
        iqseq('actionAppend', { a(actCount), acode, param }, 'downloadToChannel', downloadToChannel);
    end
end
% load the sequence table
sequenceTable = cell2struct(get(handles.uitableSeq, 'Data'), ...
    {'idx', 'segmentNumber', 'segmentLoops', 'segmentAdvance', 'markerEnable', 'sequenceInit', ...
     'sequenceLoops', 'sequenceAdvance', 'actionID', 'amplCmd', 'freqCmd'}, 2);
for i=1:size(sequenceTable,1)
    switch(sequenceTable(i).amplCmd)
        case 'next'; sequenceTable(i).amplitudeNext = 1;
        case 'init'; sequenceTable(i).amplitudeInit = 1;
        otherwise; sequenceTable(i).amplitudeInit = 0; sequenceTable(i).amplitudeNext = 0;
    end
    switch(sequenceTable(i).freqCmd)
        case 'next'; sequenceTable(i).frequencyNext = 1;
        case 'init'; sequenceTable(i).frequencyInit = 1;
        otherwise; sequenceTable(i).frequencyInit = 0; sequenceTable(i).frequencyNext = 0;
    end
    if (sequenceTable(i).sequenceInit && i > 1)
        sequenceTable(i-1).sequenceEnd = 1;
    end
    if (strcmp(sequenceTable(i).sequenceAdvance, 'n.a.'))
        sequenceTable(i).sequenceAdvance = 'Auto';
    end
    switch(sequenceTable(i).actionID)
        case 'none'; sequenceTable(i).actionID = [];
        otherwise;
            try
                tmp = eval(sequenceTable(i).actionID);
                sequenceTable(i).actionID = tmp;
            catch ex
                errordlg({['Action ID ' sequenceTable(i).actionID ' not defined:'] ...
                 ex.message});
            end
    end
end
sequenceTable(size(sequenceTable,1)).sequenceEnd = 1;
sequenceTable(size(sequenceTable,1)).scenarioEnd = 1;
sequenceTable = rmfield(sequenceTable, {'idx', 'amplCmd', 'freqCmd'});
iqseq('define', sequenceTable, 'downloadToChannel', downloadToChannel, 'run', 0, 'keepOpen', 1);
iqseq('mode', 'STSCenario', 'downloadToChannel', downloadToChannel);
try
    close(hMsgBox);
catch e;
end;


% --- Executes on button press in pushbuttonInsertSeq.
function pushbuttonInsertSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, 'Seq', { 0, 1, 1, 'Auto', 1, 1, 1, 'Auto', 'none', 'none', 'none'});


function data = insertRow(handles, name, default)
eval(['global currentTableSelection' name]);
eval(['data = get(handles.uitable' name ', ''Data'');']);
eval(['if (exist(''currentTableSelection' name ''', ''var'') && length(currentTableSelection' name ') >= 2); row1 = currentTableSelection' name '(1); else; row1 = 1; end']);
row2 = size(data,1);
if (row1 > row2)
    row1 = row2;
end
% it seems that an assignment like this is not possible
% data{row1+1:row2+1,:} = data{row1:row2,:}
if (row2 < 1)    % empty
    for j=1:size(default,2)
        data{1,j} = default{j};
    end
else
    for i=row2:-1:row1
        for j=1:size(data,2)
            data{i+1,j} = data{i,j};
        end
    end
end
if (~strcmp(name, 'Action'))
    % set ID column
    for i = 1:size(data,1)
        data{i,1} = i - 1;
    end
    eval(['set(handles.uitable' name ', ''Data'', data);']);
end


% --- Executes on button press in pushbuttonDeleteSeq.
function pushbuttonDeleteSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, 'Seq', 1);


function newdata = deleteRow(handles, name, minimum)
eval(['global currentTableSelection' name]);
eval(['data = get(handles.uitable' name ', ''Data'');']);
eval(['if (exist(''currentTableSelection' name ''', ''var'') && length(currentTableSelection' name ') >= 2); row1 = currentTableSelection' name '(1); else; row1 = 1; end']);
row2 = size(data,1);
newdata = data;
if (row2 <= minimum)
    return;
end
if (row1 > row2)
    row1 = row2;
end
newdata = cell(row2-1,size(data,2));
% it seems that an assignment like this is not possible
% data{row1+1:row2+1,:} = data{row1:row2,:}
for i=1:row1-1
    for j=1:size(data,2)
        newdata{i,j} = data{i,j};
    end
end
for i=row1:row2-1
    for j=1:size(data,2)
        newdata{i,j} = data{i+1,j};
    end
end
if (~strcmp(name, 'Action'))
    % set ID column
    for i = 1:size(newdata,1)
        newdata{i,1} = i - 1;
    end
    if (strcmp(name, 'Seq'))
        checkSequenceTable(handles, newdata, 0);
    else
        eval(['set(handles.uitable' name ', ''Data'', newdata);']);
    end
end


% --- Executes on button press in pushbuttonListSegments.
function pushbuttonListSegments_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonListSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
downloadToChannel = getDownloadToChannel(handles);
iqseq('list', [], 'downloadToChannel', downloadToChannel);


% --- Executes on button press in pushbuttonDeleteAllSegments.
function pushbuttonDeleteAllSegments_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAllSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
downloadToChannel = getDownloadToChannel(handles);
iqseq('delete', [], 'downloadToChannel', downloadToChannel);


% --- Executes on button press in pushbuttonEvent.
function pushbuttonEvent_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('event');


% --- Executes on button press in pushbuttonTrigger.
function pushbuttonTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('trigger');


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


% --- Executes on button press in pushbuttonHelp.
function pushbuttonHelp_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({'Use this utility to create a sequence for the M8190A. The "Sequence Table"' ...
    'is used in all modes; the "Action Table", "Frequency Table" and "Amplitude' ...
    'Table" are only used in digital up-conversion modes.' ...
    ''});


% --- Executes when entered data in editable cell(s) in uitableAction.
function uitableAction_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableAction (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableAction, 'Data');
checkActionTable(handles, data, 1);


function checkActionTable(handles, data, showError)
% Check all the "new" fields and assign action IDs
% Update the Act.ID column choices in the sequence table
idx = 0;
cfmt = {'none'};
if (size(data,1) >= 1 && ~data{1,2})
    if (showError)
        errordlg({'The first entry in the action table must be a new action'});
    end
    data{1,2} = true;
end
for i = 1:size(data,1)
    if (data{i,2})
        idx = idx + 1;
        data{i,1} = sprintf('  a(%d)', idx);
        cfmt{idx+1} = sprintf('a(%d)', idx);
    else
        data{i,1} = '';
    end
    % remove parameters for sweep run and sweep hold
    if (strcmp(data{i,3}, 'Sweep Run') || ...
        strcmp(data{i,3}, 'Sweep Hold'))
        data{i,4} = [];
    elseif (isempty(data{i,4}))
        data{i,4} = '0';
    end
end
set(handles.uitableAction, 'Data', data);
% update the Action ID column
seqTab = handles.uitableSeq;
fmt = get(seqTab, 'ColumnFormat');
fmt{9} = cfmt;
set(seqTab, 'ColumnFormat', fmt);


% --- Executes when selected cell(s) is changed in uitableSeq.
function uitableSeq_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableSeq (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionSeq;
if (~isempty(eventdata.Indices))
    currentTableSelectionSeq = eventdata.Indices;
end


% --- Executes on button press in pushbuttonInsertAction.
function pushbuttonInsertAction_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = insertRow(handles, 'Action', {'  a(1)' true 'Phase Offset' '0'});
checkActionTable(handles, data, 0);


% --- Executes on button press in pushbuttonDeleteAction.
function pushbuttonDeleteAction_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = deleteRow(handles, 'Action', 0);
checkActionTable(handles, data, 0);


% --- Executes on button press in pushbuttonInsertFreq.
function pushbuttonInsertFreq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, 'Frequency', { 0, '100e6' });


% --- Executes on button press in pushbuttonDeleteFreq.
function pushbuttonDeleteFreq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, 'Frequency', 0);


% --- Executes on button press in pushbuttonInsertAmpl.
function pushbuttonInsertAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, 'Amplitude', { 0, '1' });


% --- Executes on button press in pushbuttonDeleteAmpl.
function pushbuttonDeleteAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, 'Amplitude', 0);


% --- Executes when selected cell(s) is changed in uitableAction.
function uitableAction_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableAction (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionAction;
if (~isempty(eventdata.Indices))
    currentTableSelectionAction = eventdata.Indices;
end


% --- Executes when selected cell(s) is changed in uitableFrequency.
function uitableFrequency_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableFrequency (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionFrequency;
if (~isempty(eventdata.Indices))
    currentTableSelectionFrequency = eventdata.Indices;
end


% --- Executes when selected cell(s) is changed in uitableAmplitude.
function uitableAmplitude_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableAmplitude (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionAmplitude;
if (~isempty(eventdata.Indices))
    currentTableSelectionAmplitude = eventdata.Indices;
end


% --- Executes when entered data in editable cell(s) in uitableSeq.
function uitableSeq_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableSeq (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableSeq, 'Data');
checkSequenceTable(handles, data, 1);


function checkSequenceTable(handles, data, showError)
% Check the consistency of the sequence table.
% Modify the Seq.Loops and Seq.Adv. fields to depending on the state of the
% "new Seq" checkbox. SeqLoops and SeqAdv are only relevant in the first
% entry of a sequence
if (~data{1,6})
    if (showError)
        errordlg({'The first entry in the sequence table must be a start of a new sequence.'});
    end
    data{1,6} = true;
end
for i=1:size(data,1)
    if (data{i,6})
        if (strcmp(data{i,8}, 'n.a.'))
            data{i,8} = 'Auto';
        end
        if (isempty(data{i,7}) || strcmp(data{i,7}, ''))
            data{i,7} = 1;
        end
    else
        data{i,8} = 'n.a.';
        data{i,7} = [];
    end
    if (~strcmp(data{i,9}, 'none'))
        data{i,3} = [];
    elseif (isempty(data{i,3}) || strcmp(data{i,3}, ''))
        data{i,3} = 1;
    end
end
set(handles.uitableSeq, 'Data', data);


function downloadToChannel = getDownloadToChannel(handles)
downloadList = cellstr(get(handles.popupmenuDownload, 'String'));
downloadToChannel = downloadList{get(handles.popupmenuDownload, 'Value')};
switch downloadToChannel
    case 'Channel 1'
        downloadToChannel = 'I to channel 1';
    case 'Channel 2'
        downloadToChannel = 'I to channel 2';
    case 'Channel 1+2'
        downloadToChannel = 'I+Q to channel 1+2';
end


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
