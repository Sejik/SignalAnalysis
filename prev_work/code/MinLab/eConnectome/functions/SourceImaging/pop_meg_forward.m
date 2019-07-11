function varargout = pop_meg_forward(varargin)
% pop_meg_forward - the GUI for selection of MEG forward options.
%
% Usage: 
%               >> forward_options = pop_meg_forward(info)
%               info.sensornorm - indicates if sensor norms are included
%               options.columnnorm - indicates if column normalization will be done 
%               options.rownorm - indicates if row normalization will be done
%               options.sensornorm - indicates if sensor norms will be used
%
% Program Author: Yakang Dai, University of Minnesota, USA
%
% User feedback welcome: e-mail: econnect@umn.edu
%

% License
% ==============================================================
% This program is part of the eConnectome.
% 
% Copyright (C) 2010 Regents of the University of Minnesota. All rights reserved.
% Correspondence: binhe@umn.edu
% Web: econnectome.umn.edu
%
% This program is free software for academic research: you can redistribute it and/or modify
% it for non-commercial uses, under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see http://www.gnu.org/copyleft/gpl.html.
%
% This program is for research purposes only. This program
% CAN NOT be used for commercial purposes. This program 
% SHOULD NOT be used for medical purposes. The authors 
% WILL NOT be responsible for using the program in medical
% conditions.
% ==========================================

% Revision Logs
% ==========================================
%
% Yakang Dai, 07-May-2011-2011 13:51:44
% Release Version 2.0 beta
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_meg_forward_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_meg_forward_OutputFcn, ...
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


% --- Executes just before pop_meg_forward is made visible.
function pop_meg_forward_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_meg_forward (see VARARGIN)

% Choose default command line output for pop_meg_forward
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_meg_forward wait for user response (see UIRESUME)
% uiwait(handles.figure1);

if length(varargin) ~= 1
    errordlg('Input arguments mismatch!','Input error','modal');
    return;
end

info = varargin{1};

options.columnnorm = 0;
options.rownorm = 0;
options.sensornorm = info.sensornorm;
set(handles.cb_row_norm,'value',options.rownorm);
set(handles.cb_sensor_norm,'value',options.sensornorm);
if ~options.sensornorm
    set(handles.cb_sensor_norm,'enable','off');
end
set(hObject,'userdata',options);

% UIWAIT makes pop_meg_forward wait for user response (see UIRESUME)
uiwait(hObject);% To block OutputFcn so that let other callbacks to generate values.

% --- Outputs from this function are returned to the command line.
function varargout = pop_meg_forward_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = get(hObject, 'userdata');
delete(hObject);


% --- Executes on button press in cb_row_norm.
function cb_row_norm_Callback(hObject, eventdata, handles)
% hObject    handle to cb_row_norm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_row_norm
hfig = gcf;
options = get(hfig, 'userdata');
options.rownorm = get(hObject,'value');
set(hfig,'userdata',options);

% --- Executes on button press in cb_sensor_norm.
function cb_sensor_norm_Callback(hObject, eventdata, handles)
% hObject    handle to cb_sensor_norm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_sensor_norm
hfig = gcf;
options = get(hfig, 'userdata');
options.sensornorm = get(hObject,'value');
set(hfig,'userdata',options);


% --- Executes on button press in pb_ok.
function pb_ok_Callback(hObject, eventdata, handles)
% hObject    handle to pb_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
uiresume(hfig);

% --- Executes on button press in pb_cancel.
function pb_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pb_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
set(hfig, 'userdata', []);
uiresume(hfig);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
hfig = gcf;
set(hfig, 'userdata', []);
uiresume(hfig);



% --- Executes on button press in cb_column_norm.
function cb_column_norm_Callback(hObject, eventdata, handles)
% hObject    handle to cb_column_norm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_column_norm
hfig = gcf;
options = get(hfig, 'userdata');
options.columnnorm = get(hObject,'value');
set(hfig,'userdata',options);

