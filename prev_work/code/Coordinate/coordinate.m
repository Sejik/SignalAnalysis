function varargout = coordinate(varargin)
% Designed by sejik Park with guide (MATLAB)
% e-mail: sejik6307@gmail.com

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @coordinate_OpeningFcn, ...
                   'gui_OutputFcn',  @coordinate_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before coordinate is made visible.
function coordinate_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for coordinate
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(hObject,'Toolbar','figure');
% set(hObject,'MenuBar','figure');
hToolbar = findall(hObject,'tag','FigureToolBar');
hButtons = findall(hToolbar);
set(hButtons,'Visible','off');
% sfhandle = findobj(hButtons,'tag','Standard.SaveFigure');
toolhandle = findobj(hButtons,'tag','FigureToolBar'); % FigureToolBar
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.DataCursor'); % DataCursor
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.Rotate'); % Rotate
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.ZoomOut'); % ZoomOut
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.ZoomIn'); % ZoomIn
set(toolhandle,'Visible','on');
toolhandle = findobj(hButtons,'tag','Exploration.Pan'); % Pan
set(toolhandle,'Visible','on');

% UIWAIT makes coordinate wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = coordinate_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in front_view_tag.
function front_view_tag_Callback(hObject, eventdata, handles)
% hObject    handle to front_view_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of front_view_tag


% --- Executes on button press in right_view_tag.
function right_view_tag_Callback(hObject, eventdata, handles)
% hObject    handle to right_view_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of right_view_tag


% --- Executes on button press in back_view_tag.
function back_view_tag_Callback(hObject, eventdata, handles)
% hObject    handle to back_view_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of back_view_tag


% --- Executes on button press in left_view_tag.
function left_view_tag_Callback(hObject, eventdata, handles)
% hObject    handle to left_view_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of left_view_tag



function right_posterior_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to right_posterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of right_posterior_text_tag as text
%        str2double(get(hObject,'String')) returns contents of right_posterior_text_tag as a double
hfig = gcf;
RP_data = str2double(get(hObject, 'String'));
Updata;


% --- Executes during object creation, after setting all properties.
function right_posterior_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to right_posterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function right_horizontal_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to right_horizontal_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of right_horizontal_text_tag as text
%        str2double(get(hObject,'String')) returns contents of right_horizontal_text_tag as a double
hfig = gcf;
RH_data = str2double(get(hObject, 'String'));
Updata;

% --- Executes during object creation, after setting all properties.
function right_horizontal_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to right_horizontal_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function right_anterior_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to right_anterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
RA_data = str2double(get(hObject, 'String'));
Updata;

% Hints: get(hObject,'String') returns contents of right_anterior_text_tag as text
%        str2double(get(hObject,'String')) returns contents of right_anterior_text_tag as a double


% --- Executes during object creation, after setting all properties.
function right_anterior_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to right_anterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function right_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to right_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of right_text_tag as text
%        str2double(get(hObject,'String')) returns contents of right_text_tag as a double


% --- Executes during object creation, after setting all properties.
function right_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to right_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function left_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to left_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of left_text_tag as text
%        str2double(get(hObject,'String')) returns contents of left_text_tag as a double


% --- Executes during object creation, after setting all properties.
function left_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to left_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function left_anterior_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to left_anterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
LA_data = str2double(get(hObject, 'String'));
Updata;

% Hints: get(hObject,'String') returns contents of left_anterior_text_tag as text
%        str2double(get(hObject,'String')) returns contents of left_anterior_text_tag as a double


% --- Executes during object creation, after setting all properties.
function left_anterior_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to left_anterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function left_horizontal_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to left_horizontal_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
LH_data = str2double(get(hObject, 'String'));
Updata;

% Hints: get(hObject,'String') returns contents of left_horizontal_text_tag as text
%        str2double(get(hObject,'String')) returns contents of left_horizontal_text_tag as a double


% --- Executes during object creation, after setting all properties.
function left_horizontal_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to left_horizontal_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function left_posterior_text_tag_Callback(hObject, eventdata, handles)
% hObject    handle to left_posterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hfig = gcf;
LP_data = str2double(get(hObject, 'String'));
Updata;

% Hints: get(hObject,'String') returns contents of left_posterior_text_tag as text
%        str2double(get(hObject,'String')) returns contents of left_posterior_text_tag as a double


% --- Executes during object creation, after setting all properties.

function Update()
hfig = gcf;
coordinate_figure = findobj(hfig, 'tag', 'coordinate_figure');






function left_posterior_text_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to left_posterior_text_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
