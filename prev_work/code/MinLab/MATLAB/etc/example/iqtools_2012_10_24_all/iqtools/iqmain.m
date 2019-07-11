function varargout = iqmain(varargin)
% IQMAIN M-file for iqmain.fig
%      IQMAIN, by itself, creates a new IQMAIN or raises the existing
%      singleton*.
%
%      H = IQMAIN returns the handle to a new IQMAIN or the handle to
%      the existing singleton*.
%
%      IQMAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQMAIN.M with the given input arguments.
%
%      IQMAIN('Property','Value',...) creates a new IQMAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqmain_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqmain_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqmain

% Last Modified by GUIDE v2.5 31-Jul-2012 19:34:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqmain_OpeningFcn, ...
                   'gui_OutputFcn',  @iqmain_OutputFcn, ...
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


% --- Executes just before iqmain is made visible.
function iqmain_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmain (see VARARGIN)

% Choose default command line output for iqmain
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes iqmain wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqmain_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonSerial.
function pushbuttonSerial_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], [], []))
    iserial();
end

% --- Executes on button press in pushbuttonConfig.
function pushbuttonConfig_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqconfig();

% --- Executes on button press in pushbuttonTone.
function pushbuttonTone_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqtone();

% --- Executes on button press in pushbuttonMod.
function pushbuttonMod_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqmod();

% --- Executes on button press in pushbuttonPulse.
function pushbuttonPulse_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqpulse();

% --- Executes on button press in pushbuttonFsk.
function pushbuttonFsk_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFsk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqfsk();


% --- Executes on button press in pushbuttonLoadFile.
function pushbuttonLoadFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqloadfile();


% --- Executes on button press in pushbuttonOFDM.
function pushbuttonOFDM_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOFDM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqofdm();


% --- Executes on button press in pushbuttonPulseGen.
function pushbuttonPulseGen_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPulseGen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqpulsegen();


% --- Executes on button press in pushbuttonSequencer.
function pushbuttonSequencer_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSequencer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqseq();


% --- Executes on button press in pushbuttonCATV.
function pushbuttonCATV_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCATV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
catv_gui();


% --- Executes on button press in pushbuttonRadarDemo.
function pushbuttonRadarDemo_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRadarDemo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqrsim_gui();


% --- Executes on button press in pushbuttonSeqDemo1.
function pushbuttonSeqDemo1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSeqDemo1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
seqtest1_gui();


% --- Executes on button press in pushbuttonM8190ADemos.
function pushbuttonM8190ADemos_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonM8190ADemos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if iqmain.fig is opened directly, then handles is empty and we have to
% find a workaround to access the other GUI elements
figure = get(hObject, 'Parent');
ch = get(figure, 'Children');
uipanel = ch(find(strcmp(get(ch, 'Tag'), 'uipanelM8190A')));
pos = get(figure, 'Position');
if (pos(3) < 60)
    pos(3) = 94;
    set(figure, 'Position', pos);
    set(hObject, 'String', regexprep(get(hObject, 'String'), '>', '<'));
    set(uipanel, 'Visible', 'on');
else
    pos(3) = 49;
    set(figure, 'Position', pos);
    set(hObject, 'String', regexprep(get(hObject, 'String'), '<', '>'));
    set(uipanel, 'Visible', 'off');
end


% --- Executes on button press in pushbuttonMultiChannel.
function pushbuttonMultiChannel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMultiChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
multi_channel_sync_gui


% --- Executes on button press in pushbuttonDUCDemo.
function pushbuttonDUCDemo_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDUCDemo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
duc_ctrl();
