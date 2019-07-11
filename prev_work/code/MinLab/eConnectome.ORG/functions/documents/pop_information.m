function varargout = pop_information(varargin)
% pop_information - display basic information of the EEG/ECoG/MEG data.
%
% Usage: 
%            1. texttype 
%               >> pop_information(ECOM)
%               or call pop_information(ECOM) to start the popup GUI with ECOM structure. 
%               The ECOM structure can be found in ecom_initialize.m
%               Please see the eConnectome Manual  
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable import ECOM structure.
%           
%            2. call pop_information(ECOM) from the eegfc/ecogfc/megfc GUI ('EEG/ECoG/MEG Data
%                panel -> right click the current EEG/ECoG/MEG') 
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
% Yakang Dai, 20-May-2010 15:36:30
% Release Version 2.0 beta 
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pop_information_OpeningFcn, ...
                   'gui_OutputFcn',  @pop_information_OutputFcn, ...
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


% --- Executes just before pop_information is made visible.
function pop_information_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pop_information (see VARARGIN)

% Choose default command line output for pop_information
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pop_information wait for user response (see UIRESUME)
% uiwait(handles.figure1);

len = length(varargin);
if len ~= 1
    return;
end

ECOM = varargin{1};

type = ECOM.type;
name = ECOM.name;
channum = ECOM.nbchan;
srate = ECOM.srate;
numpt = ECOM.points;
time = numpt / srate;

set(hObject, 'name', [type ' Information']);
set(handles.texttype, 'string', ['Information of Current ' type]);
set(handles.textname,'string',['Name: '  num2str(name)]);
set(handles.textchan,'string',['Channels: '  num2str(channum)]);
set(handles.textsrate,'string',['Sampling Rate: '  num2str(srate) ' points/s']);
set(handles.textpoint,'string',['Points: '  num2str(numpt)]);
set(handles.texttime,'string',['Time: '  num2str(time) ' s']);

% --- Outputs from this function are returned to the command line.
function varargout = pop_information_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
