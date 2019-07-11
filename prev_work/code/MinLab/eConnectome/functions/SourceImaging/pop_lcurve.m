function varargout = pop_lcurve(varargin)
% pop_lcurve - the GUI for displaying L-curve and setting regularization parameter.
%
% Usage:         
%            1. type 
%               >> result = pop_lcurve(regularization)
%               or call result = pop_lcurve(regularization) to start the popup GUI with regularization structure. 
%               Input: regularization - is a structure of 4 fields
%                         - regularization.method is the cortical source computation method,
%                           including 'mn' (minimum norm) and 'wmn' (weighted minimum norm).
%                         - regularization.autocorner is the sign of whether locating L-curve corner automatically (=1) 
%                           or not (=0).
%                         - regularization.lamda is the previous regularization parameter lamda.
%                         - regularization.U is the U of SVD compact form of the transfer matrix A (A * x = b). 
%                         - regularization.s is the s of SVD compact form of the transfer matrix A (A * x = b). 
%                         - regularization.b is the multi-channel sensor signal at a time point  (N*1 vector) . 
%               Output: result - is a structure of two fields
%                         - result.autocorner is the sign of whether locating L-curve corner automatically (=1) 
%                           or not (=0).
%                         - result.lamda is the new regularization parameter lamda.
%
%            2. call result = pop_lcurve(regularization) from the pop_sourceloc GUI ('Context Menus -> 
%               Localization -> Regularization'). 
%               Customized regularization parameter lamda set by the user in the pop_lcurve GUI
%               will be used in the pop_sourceloc GUI. 
%
% L-curve:
% The L-curve implemented in the program are based on the Regularization Tools developed by 
% P. C. Hansen. 
% See below for detailed description of the Regularization Tools: 
% P. C. Hansen, Regularization Tools Version 4.0 for Matlab 7.3, 
% Numerical Algorithms, 46 (2007), pp. 189-194. 
% http://www2.imm.dtu.dk/~pch/Regutools/
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
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_lcurve_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_lcurve_OutputFcn, ...
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


% --- Executes just before pop_lcurve is made visible.
function pop_lcurve_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_lcurve (see VARARGIN)

% Choose default command line output for pop_lcurve
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_lcurve wait for user response (see UIRESUME)
% uiwait(handles.figure1);

if length(varargin) ~= 1
    errordlg('Input arguments mismatch!','Input error','modal');
    return;
end

regularization = varargin{1};

% axes(handles.loglogaxes);
% if isequal(regularization.method,'mn')
%     lamda = l_curve(regularization.U,regularization.s,regularization.b,'tikh');
% elseif isequal(regularization.method,'wmn')
%     lamda = l_curve(regularization.U,regularization.s,regularization.b,'tikh');
% end

lamda = plot_lcurves(regularization, handles);

if regularization.autocorner
    set(handles.radiobutton_automatic,'value',1);
    set(handles.edit_customized,'string',num2str(lamda));
else
    set(handles.radiobutton_customized,'value',1);
    set(handles.edit_customized,'string',num2str(regularization.lamda));
end

% UIWAIT makes pop_filter wait for user response (see UIRESUME)
uiwait(hObject);% To block OutputFcn so that let other callbacks to generate values.

% --- Outputs from this function are returned to the command line.
function varargout = pop_lcurve_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Output values generated by callbacks
varargout{1} = get(hObject, 'userdata');
delete(hObject);

% --- Executes on button press in pushbutton_ok.
function pushbutton_ok_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

isautomatic = get(handles.radiobutton_automatic,'value');
if isautomatic
    output.autocorner = 1;
else
    output.autocorner = 0;
end

lamda = get(handles.edit_customized, 'string');
output.lamda = str2num(lamda);
set(gcf,'userdata',output);
uiresume(gcf);

function edit_customized_Callback(hObject, eventdata, handles)
% hObject    handle to edit_customized (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_customized as text
%        str2double(get(hObject,'String')) returns contents of edit_customized as a double


% --- Executes during object creation, after setting all properties.
function edit_customized_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_customized (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(gcf, 'userdata', []);
uiresume(gcf);


% --- Plot non-loglog and loglog L curves.
function lamda = plot_lcurves(regularization, handles)
tempfig = figure;
[lamda,rho,eta,reg_param] = l_curve(regularization.U,regularization.s,regularization.b,'tikh');
close(tempfig);
[reg_corner,rho_c,eta_c] = l_corner(rho,eta,reg_param,regularization.U,regularization.s,regularization.b,'tikh');

ps = size(regularization.s,2);
if (ps < 1 | ps > 2) 
    errordlg('Illegal value of ps');
end

set(gcf,'Toolbar','figure');

n = length(rho); 
step = round(n/10);

% plot non-loglog L-curve
axes(handles.nonloglogaxes);
box on;
cla;
plot(rho(2:end-1),eta(2:end-1),'-', rho(step:step:n),eta(step:step:n),'.'); % plot the curve and representative marks
ax = axis;
hold on;
for k = step:step:n
  text(rho(k),eta(k),num2str(reg_param(k))); % plot the relative regularization parameters 
end
plot([min(rho)/100, rho_c], [eta_c,eta_c],':r', [rho_c,rho_c],[min(eta)/100,eta_c],':r'); % plot the corner
axis(ax);
xlabel('residual norm || A x - b ||_2')
if (ps==1)
  ylabel('solution norm || x ||_2')
else
  ylabel('solution semi-norm || L x ||_2')
end
title(['Non-loglog Plot,', ' Automatic Corner at ', num2str(reg_corner)]);


% plot loglog L-curve
axes(handles.loglogaxes);
box on;
cla;
loglog(rho(2:end-1),eta(2:end-1),'-', rho(step:step:n),eta(step:step:n),'.'); % plot the curve and representative marks
ax = axis;
hold on;
for k = step:step:n
  text(rho(k),eta(k),num2str(reg_param(k))); % plot the relative regularization parameters 
end
loglog([min(rho)/100, rho_c], [eta_c,eta_c],':r', [rho_c,rho_c],[min(eta)/100,eta_c],':r'); % plot the corner
axis(ax);

xlabel('residual norm || A x - b ||_2')
if (ps==1)
  ylabel('solution norm || x ||_2')
else
  ylabel('solution semi-norm || L x ||_2')
end
title(['Loglog Plot, ', ' Automatic Corner at ', num2str(reg_corner)]);



