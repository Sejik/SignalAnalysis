function varargout = pop_dtf_computation(varargin)
% pop_dtf_computation - calculate the normalized Directed Transfer Function 
%                                       (DTF)/Adaptive Directed Transfer Function (ADTF) 
%                                       values for multichannel time series. 
%              
% The DTF/ADTF computation is based on a Multivariate Autoregressive Model 
% (MVAR)/adaptive MVAR model (MVAAR). 
%
% Useage: DTFV = pop_dtf_computation(data,srate)
%
% Input: data - is a 2D array for the time series values, where each 
%               row represents a time series. The number of rows equals 
%               the number of the time series, and the number of columns 
%               equals the number of points of each time series.
%        srate - is the sampling rate (e.g. 250 points/second) of the 
%                time series.
%
% Output: DTFV - is a structure for the calculated DTF/ADTF values. It has four 
%                fields. 
%               - DTFV.srate is the sampling rate of the time series.
%               - DTFV.frequency ([lowf highf]) is the user-defined 
%                 frequency range for the input time series.
%               - DTFV.dtfmatrixs is the array for the calculated DTF/ADTF values.
%
%                 For DTF, DTFV.dtfmatrixs is in the form DTFV.dtfmatrixs(i,j,k), 
%                 where i = the sink channel, j = the source channel, 
%                 k = the frequency index. DTFV.dtfmatrixs(:,:,k) represents
%                 the normalized DTF matrix for the frequency k+lowf-1.
%                 For example, the DTFV.dtfmatrixs(1,2,3) represents the
%                 normalized directed connectivity from the channel 2 to 
%                 the channel 1 for the frequency 3+lowf-1.
%
%                 For ADTF, DTFV.dtfmatrixs is in the form DTFV.dtfmatrixs(n,i,j,k), 
%                 where n = the time point, i = the sink channel, j = the source channel, 
%                 k = the frequency index. DTFV.dtfmatrixs(n,:,:,k) represents
%                 the normalized DTF matrix for the frequency k+lowf-1 at time point n.
%                 For example, the DTFV.dtfmatrixs(1,2,3,4) represents the
%                 normalized directed connectivity from the channel 3 to 
%                 the channel 2 for the frequency 4+lowf-1 at the time point 1.
%
%               - DTFV.isadtf indicates the type of the DTFV.dtfmatrixs,
%                 if DTFV.isadtf = 1, DTFV.dtfmatrixs is the array for ADTF values,
%                 if DTFV.isadtf = 0, DTFV.dtfmatrixs is the array for DTF values.
%
% ARfit Package:
% The ARfit package is used in DTF computation. 
% See below for detailed description of ARfit package:  
% A. Neumaier and T. Schneider, 2001: Estimation of parameters and eigenmodes of 
% multivariate autoregressive models. ACM Trans. Math. Softw., 27, 27?7.
% T. Schneider and A. Neumaier, 2001: Algorithm 808: ARfit-A Matlab package for the 
% estimation of parameters and eigenmodes of multivariate autoregressive models. 
% ACM Trans. Math. Softw., 27, 58?5.
% http://www.gps.caltech.edu/~tapio/arfit/
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
% Yakang Dai, 17-June-2010 15:23:30
% Set the diagonal elements to zeros, 
% and normalize the DTF/ADTF values
%
% Yakang Dai, 14-May-2010 14:42:30
% Add ADTF computation
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_dtf_computation_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_dtf_computation_OutputFcn, ...
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


% --- Executes just before pop_dtf_computation is made visible.
function pop_dtf_computation_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_dtf_computation (see VARARGIN)

% Choose default command line output for pop_dtf_computation
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_dtf_computation wait for user response (see UIRESUME)
% uiwait(handles.dtfcomputation);

if length(varargin) ~= 2
    errordlg('Input arguments mismatch!','Input error','modal');
    return;
end

TS.data = varargin{1};
TS.srate = varargin{2};

if isempty(TS.data)
    helpdlg('Input time series data is empty!');
    return;
end

if isempty(TS.srate) | TS.srate <= 0
    helpdlg('Please input sampling rate (points/second)!');
    return;
end

[TS.nbchan, TS.points] = size(TS.data);

startpoint = 1;
endpoint = 2000;
if endpoint > TS.points
    endpoint = TS.points;
end

set(handles.dtftsstartpointtext,'string',['Start Point (>= ' num2str(startpoint) '):']);
set(handles.dtftsendpointtext,'string',['End Point (<= ' num2str(TS.points) '):']);
set(handles.dtftsstartpointedit,'string', num2str(startpoint));
set(handles.dtftsendpointedit,'string', num2str(endpoint));

deltaT = 1/TS.srate;
starttime = startpoint*deltaT;
endtime = endpoint*deltaT;
set(handles.dtftsstarttimetext,'string',['Start Time (>= ' num2str(starttime) ' s):']);
set(handles.dtftsendtimetext,'string',['End Time (<= ' num2str(TS.points*deltaT) ' s):']);
set(handles.dtftsstarttimeedit,'string', num2str(starttime));
set(handles.dtftsendtimeedit,'string', num2str(endtime));

maxf = num2str(round(TS.srate/2));
set(handles.dtfhighftext, 'string', ['High (<= ' maxf ' Hz):']);
output.dtfmatrixs = [];
output.frequency = [];
set(hObject, 'userdata', output);

axes(handles.dtforderaxes);
axcolor = get(hObject,'color');
set(handles.dtforderaxes,'color',axcolor);
xlabel('Order');

setappdata(hObject,'TS',TS);

options.siglevel = 0.05;
options.shufftimes = 1000;
setappdata(hObject,'options', options);

% UIWAIT makes pop_filter wait for user response (see UIRESUME)
uiwait(hObject);% To block OutputFcn so that let other callbacks to generate values.


% --- Outputs from this function are returned to the command line.
function varargout = pop_dtf_computation_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;
varargout{1} = get(hObject, 'userdata');
delete(hObject);


function dtflowfedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtflowfedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtflowfedit as text
%        str2double(get(hObject,'String')) returns contents of dtflowfedit
%        as a double

TS = getappdata(handles.dtfcomputation,'TS');

maxf = round(TS.srate/2);
lowf = str2num(get(hObject,'String'));
if isempty(lowf)
    warndlg('Input MUST be NUMERIC !');
    return;
end
lowf = round(lowf);
lowf = max(1,min(lowf, maxf));
set(handles.dtflowfedit,'string', num2str(lowf));


% --- Executes during object creation, after setting all properties.
function dtflowfedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtflowfedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtfhighfedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtfhighfedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtfhighfedit as text
%        str2double(get(hObject,'String')) returns contents of dtfhighfedit
%        as a double

TS = getappdata(handles.dtfcomputation,'TS');

maxf = round(TS.srate/2);
highf = str2num(get(hObject,'String'));
if isempty(highf)
    warndlg('Input MUST be NUMERIC !');
    return;
end
highf = round(highf);
highf = max(1,min(highf, maxf));
set(handles.dtfhighfedit,'string', num2str(highf));

% --- Executes during object creation, after setting all properties.
function dtfhighfedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtfhighfedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtftsstartpointedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtftsstartpointedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtftsstartpointedit as text
%        str2double(get(hObject,'String')) returns contents of dtftsstartpointedit as a double

TS = getappdata(handles.dtfcomputation,'TS');

deltaT = 1/TS.srate;
startpoint = str2num(get(hObject,'String'));
if isempty(startpoint)
    warndlg('Input MUST be NUMERIC !');
    return;
end
startpoint = round(startpoint);
startpoint = max(1,min(startpoint, TS.points));
starttime = deltaT * startpoint;
set(handles.dtftsstartpointedit,'string', num2str(startpoint));
set(handles.dtftsstarttimeedit,'string', num2str(starttime));


% --- Executes during object creation, after setting all properties.
function dtftsstartpointedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtftsstartpointedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtftsendpointedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtftsendpointedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtftsendpointedit as text
%        str2double(get(hObject,'String')) returns contents of
%        dtftsendpointedit as a double

TS = getappdata(handles.dtfcomputation,'TS');

deltaT = 1/TS.srate;
endpoint = str2num(get(hObject,'String'));
if isempty(endpoint)
    warndlg('Input MUST be NUMERIC !');
    return;
end
endpoint = round(endpoint);
endpoint = max(1,min(endpoint, TS.points));
endtime = deltaT * endpoint;
set(handles.dtftsendpointedit,'string', num2str(endpoint));
set(handles.dtftsendtimeedit,'string', num2str(endtime));

% --- Executes during object creation, after setting all properties.
function dtftsendpointedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtftsendpointedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtftsstarttimeedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtftsstarttimeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtftsstarttimeedit as text
%        str2double(get(hObject,'String')) returns contents of
%        dtftsstarttimeedit as a double

TS = getappdata(handles.dtfcomputation,'TS');

srate = TS.srate;
deltaT = 1/srate;
starttime = str2num(get(hObject,'String'));
if isempty(starttime)
    warndlg('Input MUST be NUMERIC !');
    return;
end
startpoint = round(starttime*srate);
startpoint = max(1,min(startpoint, TS.points));
starttime = deltaT * startpoint;
set(handles.dtftsstartpointedit,'string', num2str(startpoint));
set(handles.dtftsstarttimeedit,'string', num2str(starttime));

% --- Executes during object creation, after setting all properties.
function dtftsstarttimeedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtftsstarttimeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtftsendtimeedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtftsendtimeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtftsendtimeedit as text
%        str2double(get(hObject,'String')) returns contents of dtftsendtimeedit as a double

TS = getappdata(handles.dtfcomputation,'TS');

srate = TS.srate;
deltaT = 1/srate;
endtime = str2num(get(hObject,'String'));
if isempty(endtime)
    warndlg('Input MUST be NUMERIC !');
    return;
end
endpoint = round(endtime*srate);
endpoint = max(1,min(endpoint, TS.points));
endtime = deltaT * endpoint;
set(handles.dtftsendpointedit,'string', num2str(endpoint));
set(handles.dtftsendtimeedit,'string', num2str(endtime));

% --- Executes during object creation, after setting all properties.
function dtftsendtimeedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtftsendtimeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtforderedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtforderedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtforderedit as text
%        str2double(get(hObject,'String')) returns contents of dtforderedit as a double


% --- Executes during object creation, after setting all properties.
function dtforderedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtforderedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in dodtfcomputation.
function dodtfcomputation_Callback(hObject, eventdata, handles)
% hObject    handle to dodtfcomputation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

TS = getappdata(handles.dtfcomputation,'TS');

% get time series
startpoint = str2num(get(handles.dtftsstartpointedit,'string'));
endpoint = str2num(get(handles.dtftsendpointedit,'string'));
if isempty(startpoint)|isempty(endpoint)
    warndlg('Input Points MUST be NUMERIC !');
    return;
end
startpoint = round(startpoint);
endpoint = round(endpoint);
startpoint = max(1,min(startpoint, TS.points));
endpoint = max(1,min(endpoint, TS.points));
if startpoint > endpoint
    tmp = endpoint;
    endpoint = startpoint;
    startpoint = tmp;
end
ts = TS.data(:,startpoint:endpoint)';

% get frequency scope
lowf = str2num(get(handles.dtflowfedit,'string'));
highf = str2num(get(handles.dtfhighfedit,'string'));
if isempty(lowf)|isempty(highf)
    warndlg('Input Frequencies MUST be NUMERIC !');
    return;
end
lowf = round(lowf);
highf = round(highf);
maxf = TS.srate/2;
lowf = max(1,min(lowf, maxf));
highf = max(1,min(highf, maxf));
if lowf >= highf
    warndlg('Low frequency must be lower than high frequency!');
    return;
end

% get optimal order specified
optimalorder = str2num(get(handles.dtforderedit,'string'));
if isempty(optimalorder)
    warndlg('Input Order MUST be NUMERIC !');
    return;
end
if optimalorder < 1
    warndlg('Order CAN NOT be lower than 1!');
    return;
end

optimalorder = round(optimalorder);
optimalorder = max(1,min(optimalorder, 20));

[n, m]  = size(ts);     
ne = n-optimalorder;
npmax = m*optimalorder+1; 
if (ne <= npmax)
    continueevent = questdlg('Time series too short and results may not be precise, CONTINUE ?','','Yes','Cancel','Cancel');
    pause(0.1);
    if ~strcmp(continueevent,'Yes')
        return;
    end
end

% compute the DTF/ADTF values
options = getappdata(handles.dtfcomputation,'options');
rb_dtf = get(handles.rb_dtf,'value');
if rb_dtf
    output.isadtf = 0;
    output.srate = TS.srate;
    output.frequency = [lowf highf];
    output.dtfmatrixs = DTF(ts,lowf,highf,optimalorder,TS.srate);

    sigtest = get(handles.sursig,'value');
    if sigtest
        sig_dtfmatrix = DTFsigvalues(ts, lowf, highf, optimalorder, TS.srate, options.shufftimes, options.siglevel, handles.completetext);    % calculate surrogated DTF values
        output.dtfmatrixs = DTFsigtest(output.dtfmatrixs, sig_dtfmatrix);        % get the new DTF value after statistical analysis
    end
else
    output.isadtf = 1;
    output.srate = TS.srate;
    output.frequency = [lowf highf];
    output.dtfmatrixs = ADTF(ts,lowf,highf,optimalorder,TS.srate);    
    
    sigtest = get(handles.sursig,'value');
    if sigtest
        sig_dtfmatrix = ADTFsigvalues(ts, lowf, highf, optimalorder, TS.srate, options.shufftimes, options.siglevel, handles.completetext);    % calculate surrogated ADTF values
        output.dtfmatrixs = ADTFsigtest(output.dtfmatrixs, sig_dtfmatrix);        % get the new ADTF value after statistical analysis
    end
end

% Set the diagonal elements to zeros, and normalize the DTF/ADTF values.
if output.isadtf
    for i = 1:m
        output.dtfmatrixs(:,i,i,:) = 0;
    end
    scale = max(max(max(max(output.dtfmatrixs))));
else
    for i = 1:m
        output.dtfmatrixs(i,i,:) = 0;
    end
    scale = max(max(max(output.dtfmatrixs)));
end
if scale == 0
    scale = 1;
end
output.dtfmatrixs = output.dtfmatrixs / scale;

set(handles.dtfcomputation, 'userdata', output);
uiresume(handles.dtfcomputation);

% --- Executes on button press in undodtfcomputation.
function undodtfcomputation_Callback(hObject, eventdata, handles)
% hObject    handle to undodtfcomputation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

output.frequency = [];
output.dtfmatrixs = []; 
set(handles.dtfcomputation, 'userdata', output);
uiresume(handles.dtfcomputation);


function dtfminorderedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtfminorderedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtfminorderedit as text
%        str2double(get(hObject,'String')) returns contents of dtfminorderedit as a double


% --- Executes during object creation, after setting all properties.
function dtfminorderedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtfminorderedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtfmaxorderedit_Callback(hObject, eventdata, handles)
% hObject    handle to dtfmaxorderedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtfmaxorderedit as text
%        str2double(get(hObject,'String')) returns contents of dtfmaxorderedit as a double


% --- Executes during object creation, after setting all properties.
function dtfmaxorderedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtfmaxorderedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pdfplotorder.
function pdfplotorder_Callback(hObject, eventdata, handles)
% hObject    handle to pdfplotorder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

TS = getappdata(handles.dtfcomputation,'TS');

minorder = str2num(get(handles.dtfminorderedit,'string'));
maxorder = str2num(get(handles.dtfmaxorderedit,'string'));
if isempty(minorder)|isempty(maxorder)
    warndlg('Input Orders MUST be NUMERIC !');
    return;
end

minorder = round(minorder);
maxorder = round(maxorder);

minorder = min(max(minorder,1),20);
maxorder = min(max(maxorder,1),20);

if minorder > maxorder
    order = maxorder;
    maxorder = minorder;
    minorder = order;
end

set(handles.dtfminorderedit,'string',minorder);
set(handles.dtfmaxorderedit,'string',maxorder);

startpoint = str2num(get(handles.dtftsstartpointedit,'string'));
endpoint = str2num(get(handles.dtftsendpointedit,'string'));
if isempty(startpoint)|isempty(endpoint)
    warndlg('Input Points MUST be NUMERIC !');
    return;
end
startpoint = min(TS.points,max(startpoint,1));
endpoint = min(TS.points,max(endpoint,1));

ts = TS.data(:,startpoint:endpoint)';

[n, m]   = size(ts);     

fpe_error = [];
sbc_error = [];
j = 1;
for i = minorder:maxorder
    ne = n-i;
    npmax = m*i+1; 
    if (ne <= npmax)
        warndlg(['Time series too short or orders (should < ' num2str(i) ') too high!']);
        return;
    end

    [w,A,C,SBC,FPE] = arfit(ts,i,i);
    fpe_error(j) = real(FPE);
    sbc_error(j) = SBC;
    j = j+1;
end

xpos = minorder:maxorder;

axes(handles.dtforderaxes);
set(handles.dtforderaxes,'xtick',xpos);
cla;
hold on;

% plot SBC and FPE curve
sbccolor = [1 0 0];
fpecolor = [0 0 1];
plot(xpos, sbc_error, 'color', sbccolor, 'LineWidth', 2, 'DisplayName','SBC');
plot(xpos, fpe_error, 'color', fpecolor, 'LineWidth', 2, 'DisplayName','FPE');
legend(handles.dtforderaxes,'Location','NorthEast');

% plot lines for optimal orders
minsbc = min(sbc_error);
minfpe = min(fpe_error);
sbc_optorder = find(sbc_error == minsbc,1);
fpe_optorder = find(fpe_error == minfpe,1);
maxsbc = max(sbc_error);
maxfpe = max(fpe_error);
plot([sbc_optorder sbc_optorder],[minsbc maxsbc],'--k');
plot([fpe_optorder fpe_optorder],[minfpe maxfpe],'--k');

% plot the arrows
textposx = mean([sbc_optorder fpe_optorder]);
textposy = mean([minsbc maxsbc minfpe maxfpe]);
lowoptorder = min(sbc_optorder,fpe_optorder);
highoptorder = max(sbc_optorder,fpe_optorder);
text(lowoptorder,textposy,'\rightarrow','HorizontalAlignment','right');
text(highoptorder,textposy,'\leftarrow','HorizontalAlignment','left');
%text(textposx,textposy,'Optimal','HorizontalAlignment','center');
set(handles.dtforderedit,'string',num2str(sbc_optorder)); % set suggested optimal order automactically.

% --- Executes when user attempts to close dtfcomputation.
function dtfcomputation_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to dtfcomputation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
% delete(hObject);

output.frequency = [];
output.dtfmatrixs = [];
set(hObject, 'userdata', output);
uiresume(hObject);


% --- Executes on key press with focus on dtftsstartpointedit and none of its controls.
function dtftsstartpointedit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to dtftsstartpointedit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in dtfdelta.
function dtfdelta_Callback(hObject, eventdata, handles)
% hObject    handle to dtfdelta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dtfdelta

set(handles.dtflowfedit, 'string', '1');
set(handles.dtfhighfedit, 'string', '4');


% --- Executes on button press in dtftheta.
function dtftheta_Callback(hObject, eventdata, handles)
% hObject    handle to dtftheta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dtftheta

set(handles.dtflowfedit, 'string', '4');
set(handles.dtfhighfedit, 'string', '7');


% --- Executes on button press in dtfalpha.
function dtfalpha_Callback(hObject, eventdata, handles)
% hObject    handle to dtfalpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dtfalpha

set(handles.dtflowfedit, 'string', '8');
set(handles.dtfhighfedit, 'string', '12');


% --- Executes on button press in dtfbeta.
function dtfbeta_Callback(hObject, eventdata, handles)
% hObject    handle to dtfbeta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dtfbeta

set(handles.dtflowfedit, 'string', '12');
set(handles.dtfhighfedit, 'string', '30');



% --- Executes on button press in dtfgamma.
function dtfgamma_Callback(hObject, eventdata, handles)
% hObject    handle to dtfgamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dtfgamma

set(handles.dtflowfedit, 'string', '30');
set(handles.dtfhighfedit, 'string', '100');


% --- Executes on button press in radiobutton6.
function radiobutton6_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton6


% --- Executes on button press in sursig.
function sursig_Callback(hObject, eventdata, handles)
% hObject    handle to sursig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of sursig

hfig = gcf;
options = getappdata(hfig,'options');

prompt = {'Shuffling Times:', 'Significance Level:'};
dlg_title = 'Input significance test parameters!';
num_lines = 1;
def = {num2str(options.shufftimes), num2str(options.siglevel)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if isempty(answer)
    return;
end

options.shufftimes = str2num(answer{1});
if isempty(options.shufftimes)
    helpdlg('There is no shuffling times!');
    return;
end

options.siglevel = str2num(answer{2});
if isempty(options.siglevel)
    helpdlg('There is no significance level!');
    return;
end

setappdata(hfig,'options', options);


% --- Executes on button press in zerosig.
function zerosig_Callback(hObject, eventdata, handles)
% hObject    handle to zerosig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of zerosig


