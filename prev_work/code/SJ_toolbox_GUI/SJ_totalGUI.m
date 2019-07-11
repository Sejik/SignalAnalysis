function varargout = SJ_totalGUI(varargin)
% SJ_TOTALGUI MATLAB code for SJ_totalGUI.fig
%      SJ_TOTALGUI, by itself, creates a new SJ_TOTALGUI or raises the existing
%      singleton*.
%
%      H = SJ_TOTALGUI returns the handle to a new SJ_TOTALGUI or the handle to
%      the existing singleton*.
%
%      SJ_TOTALGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SJ_TOTALGUI.M with the given input arguments.
%
%      SJ_TOTALGUI('Property','Value',...) creates a new SJ_TOTALGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SJ_totalGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SJ_totalGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SJ_totalGUI

% Last Modified by GUIDE v2.5 11-Nov-2017 10:23:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SJ_totalGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SJ_totalGUI_OutputFcn, ...
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


% --- Executes just before SJ_totalGUI is made visible.
function SJ_totalGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SJ_totalGUI (see VARARGIN)

% Choose default command line output for SJ_totalGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SJ_totalGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SJ_totalGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in source_button.
function source_button_Callback(hObject, eventdata, handles)
% hObject    handle to source_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of source_button

% --- Executes on button press in ERP_button.
function ERP_button_Callback(hObject, eventdata, handles)
% hObject    handle to ERP_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ERP_button

% --- Executes on button press in FFT_button.
function FFT_button_Callback(hObject, eventdata, handles)
% hObject    handle to FFT_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FFT_button

% --- Executes on button press in questionnaire_button.
function questionnaire_button_Callback(hObject, eventdata, handles)
% hObject    handle to questionnaire_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of questionnaire_button

% --- Executes on button press in wavelet_button.
function wavelet_button_Callback(hObject, eventdata, handles)
% hObject    handle to wavelet_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of wavelet_button

% --- Executes on button press in waveletStatisticPlot_button.
function waveletStatisticPlot_button_Callback(hObject, eventdata, handles)
% hObject    handle to waveletStatisticPlot_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of waveletStatisticPlot_button


% --- Executes on button press in dipole_button.
function dipole_button_Callback(hObject, eventdata, handles)
% hObject    handle to dipole_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dipole_button

% --- Executes on button press in CFC_button.
function CFC_button_Callback(hObject, eventdata, handles)
% hObject    handle to CFC_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CFCa = get (hObject, 'Value');

% --- Executes on button press in DTF_button.
function DTF_button_Callback(hObject, eventdata, handles)
% hObject    handle to DTF_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DTF_button

% --- Executes on button press in grandDTFmovie_button.
function grandDTFmovie_button_Callback(hObject, eventdata, handles)
% hObject    handle to grandDTFmovie_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of grandDTFmovie_button

% --- Executes on button press in individualDTFmovie_button.
function individualDTFmovie_button_Callback(hObject, eventdata, handles)
% hObject    handle to individualDTFmovie_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of individualDTFmovie_button

% --- Executes on button press in statistic_button.
function statistic_button_Callback(hObject, eventdata, handles)
% hObject    handle to statistic_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of statistic_button

% --- Executes on button press in saveExcel_button.
function saveExcel_button_Callback(hObject, eventdata, handles)
% hObject    handle to saveExcel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveExcel_button

% --- Executes on button press in saveExcelAbstract_button.
function saveExcelAbstract_button_Callback(hObject, eventdata, handles)
% hObject    handle to saveExcelAbstract_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveExcelAbstract_button

% --- Executes on button press in picture_button.
function picture_button_Callback(hObject, eventdata, handles)
% hObject    handle to picture_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of picture_button

% --- Executes on button press in savePPT_button.
function savePPT_button_Callback(hObject, eventdata, handles)
% hObject    handle to savePPT_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of savePPT_button

% --- Executes on button press in saveResult_button.
function saveResult_button_Callback(hObject, eventdata, handles)
% hObject    handle to saveResult_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveResult_button

% --- Executes on button press in startAnalysis.
function startAnalysis_Callback(hObject, eventdata, handles)
% hObject    handle to startAnalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

addpath(genpath(handles.subFunctionDir.String));
addpath(genpath(handles.subDataDir.String));

global param;

param.source = handles.source_button.Value;

param.erp = handles.ERP_button.Value;
param.fft = handles.FFT_button.Value;
param.questionnaire = handles.questionnaire_button.Value;

param.wavelet = handles.wavelet_button.Value;
param.waveletStatisticPlot = handles.waveletStatisticPlot_button.Value;

param.dipole = handles.dipole_button.Value;
param.cfc = handles.CFC_button.Value;

param.dtf = handles.DTF_button.Value;
param.grandDTFmovie = handles.grandDTFmovie_button.Value;
param.individualDTFmovie = handles.individualDTFmovie_button.Value;

param.statistic = handles.statistic_button.Value;
param.saveExcel = handles.saveExcel_button.Value;
param.saveExcelAbstract = handles.saveExcelAbstract_button.Value;

param.savePPT = handles.savePPT_button.Value;
param.picture = handles.picture_button.Value;
param.saveResult = handles.saveResult_button.Value;

if param.dtf || param.grandDTFmovie || param.individualDTFmovie
    fprintf('Source Function Operated; because of DTF function');
    param.source = 1;
end

param.fs = str2double(handles.datFrequency.String); % sampling rate for the collected EEG data
param.totalLength = str2double(handles.dat_totalLatency.String); % total length of EEG data as seconds
param.epochLength = ceil(param.fs * param.totalLength); % all data point seconds
param.zeroLatency = str2double(handles.dat_zeroLatency.String); % When is the zero latency (seconds)

param.cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));

param.inputDir = handles.inputDir.String;
param.datDir = fullfile(param.inputDir, handles.datDir.String);
param.excelDir = fullfile(param.inputDir, handles.excelDir.String);
param.resultDir = handles.resultDir.String;
param.statisticDir = fullfile(param.resultDir, handles.statisticDir.String);
param.plotDir = fullfile(param.resultDir, handles.plotDir.String);

param.lineWidth = 3;
param.color{1,1} = [255/255 32/255 32/255];
param.color{1,2} = [255/255 191/255 200/255];
param.color{2,1} = [54/255 54/255 54/255];
param.color{2,2} = [180/255 180/255 180/255];
param.color{3,1} = [76/255 165/255 76/255];
param.color{3,2} = [174/255 242/255 174/255];

param.chanExcel = handles.chanExcel.String;
param.questionnaireExcel = handles.questionnaireExcel.String;
param.conditionExcel = handles.conditionExcel.String;
param.groupExcel = handles.groupExcel.String;
param.latencyExcel = handles.latencyExcel.String;

% CFC
param.phaseBand = [str2double(handles.cfc_phase_low.String) str2double(handles.cfc_phase_high.String)];
param.amplitudeBand = [str2double(handles.cfc_amplitude_low.String) str2double(handles.cfc_amplitude_high.String)];
% DTF
param.axis = 0; % function unkown (preperation)
param.surrogateNum = str2double(handles.dtf_surrogateNum.String); % surrogate group number (comparison group)
param.threshold = str2double(handles.dtf_threshold.String); % direct transfer function

% statistic
% plot
param.lineWidth = 3; % line width (normal line: 3)
param.color{1,1} = [255/255 32/255 32/255]; % {subcondition, condition}: color by 255 RGB
param.color{1,2} = [255/255 191/255 200/255];
param.color{2,1} = [54/255 54/255 54/255];
param.color{2,2} = [180/255 180/255 180/255];
param.color{3,1} = [76/255 165/255 76/255];
param.color{3,2} = [174/255 242/255 174/255];
param.plotERPfilter = 20; % ERP filter plot for reducing noise to neat graph
param.averageDTF = 1; % grand average data + DTF plot=
% ppt
param.pptDir = param.plotDir; % ppt directory
param.clearppt = 'clear.pptx'; % primary ppt for saving ppt
param.picture = 'temp.png'; % temperer saving picture
param.outfileppt = 'VR.ppt'; % location to save VR ppt
% DTF moive
param.windowLength = str2double(handles.dtf_windowLength.String); % DTF windowLength to control movie
param.shiftLength = str2double(handles.dtf_shiftLength.String); % ShiftLength
param.movieThreshold = str2double(handles.dtf_movieThreshold.String); % Movie Threshold

%% Result list
global result; % saving result parameter

%% read excel
cd(param.excelDir);
[temp.num, temp.txt, temp.raw] = xlsread(param.chanExcel);
rawRow = find(cellfun(param.cellfind('rawChannel'), temp.txt(1,:)));
groupRow = find(cellfun(param.cellfind('channelGroup'), temp.txt(1,:)));
roiRow = find(cellfun(param.cellfind('ROI'), temp.txt(1,:)));
chanNum = temp.num(1,(rawRow+1));
chanGroupNum = temp.num(1,(groupRow+1));
chanGroupMaxNum = temp.num(1,(groupRow+3));
roiNum = temp.num(1,(roiRow+1));
param.rawChannel = temp.txt(2:(chanNum+1),(rawRow+1));
param.channelGroupName = temp.txt(2:(chanGroupNum+1),(groupRow+1));
if isfield(param, 'channelGroup')
    param = rmfield(param, 'channelGroup');
end
for chanGroupIdx = 1:chanGroupNum
    param.channelGroup{chanGroupIdx} = temp.txt((1+chanGroupIdx), (groupRow+2):(groupRow+chanGroupMaxNum+1));
end
param.wholeChannel = [param.rawChannel; param.channelGroupName];
param.interestChannel = param.channelGroupName;

param.roiRadius = temp.num(2, (roiRow+2));
temp.x = temp.num(2:(roiNum+1), (roiRow+3));
temp.y = temp.num(2:(roiNum+1), (roiRow+4));
temp.z = temp.num(2:(roiNum+1), (roiRow+5));
param.roi = [temp.x, temp.y, temp.z];
param.roiName = temp.txt(2:(roiNum+1),(roiRow+1));

[temp.num, temp.title, temp.raw] = xlsread(param.latencyExcel);
interestLatencyNum = size(temp.raw, 1) - 1;
param.interestLatencyName = temp.title(2:(interestLatencyNum+1), 2);
for latencyIdx = 1:interestLatencyNum
    param.interestLatency{latencyIdx}(1) = temp.num(latencyIdx,3);
    param.interestLatency{latencyIdx}(2) = temp.num(latencyIdx,4);
end

param.individualFreq{1} = [str2double(handles.freq_whole_low.String) str2double(handles.freq_whole_high.String)];
param.individualFreq{2} = [str2double(handles.freq_delta_low.String) str2double(handles.freq_delta_high.String)];
param.individualFreq{3} = [str2double(handles.freq_theta_low.String) str2double(handles.freq_theta_high.String)];
param.individualFreq{4} = [str2double(handles.freq_alpha_low.String) str2double(handles.freq_alpha_high.String)];
param.individualFreq{5} = [str2double(handles.freq_beta_low.String) str2double(handles.freq_beta_high.String)];
param.individualFreq{6} = [str2double(handles.freq_gamma_low.String) str2double(handles.freq_gamma_high.String)];
param.individualFreq{7} = [str2double(handles.freq_extra_low.String) str2double(handles.freq_extra_high.String)];

param.freqName{1} = 'whole';
param.freqName{2} = 'delta';
param.freqName{3} = 'theta';
param.freqName{4} = 'alpha';
param.freqName{5} = 'beta';
param.freqName{6} = 'gamma';
param.freqName{7} = 'extra';

param.freqStep = 0.5; % frequency step for wavelet Hz step
param.freqs = param.individualFreq{1}:param.freqStep:param.individualFreq{2}; % whole frequency region for Hz

if ~handles.freq_extra_button.Value
    param.individualFreq(7) = [];
    param.freqName(7) = [];
end
if ~handles.freq_gamma_button.Value
    param.individualFreq(6) = [];
    param.freqName(6) = [];
end
if ~handles.freq_beta_button.Value
    param.individualFreq(5) = [];
    param.freqName(5) = [];
end
if ~handles.freq_alpha_button.Value
    param.individualFreq(4) = [];
    param.freqName(4) = [];
end
if ~handles.freq_theta_button.Value
    param.individualFreq(3) = [];
    param.freqName(3) = [];
end
if ~handles.freq_delta_button.Value
    param.individualFreq(2) = [];
    param.freqName(2) = [];
end
if ~handles.freq_whole_button.Value
    param.individualFreq(1) = [];
    param.freqName(1) = [];
end

[temp.num, temp.title, temp.raw] = xlsread(param.conditionExcel);
conditionNum = temp.num(1,2);
subConditionNum = temp.num(1,4);
if isfield(param, 'conditionInfo')
    param = rmfield(param, 'conditionInfo');
end
for conditionIdx = 1:conditionNum
    param.condition{conditionIdx} = temp.title{conditionIdx+1,2};
    for subConditionIdx = 1:subConditionNum
        param.conditionInfo{conditionIdx, subConditionIdx} = temp.title{conditionIdx+1, subConditionIdx+2};
    end
end
for subConditionIdx = 1:subConditionNum
    param.subCondition{subConditionIdx} = temp.title{subConditionIdx+1, subConditionNum+4};
end

%% read data
fprintf('%s: read data\n', datestr(now));
cd(param.datDir);
temp.subjectFiles = dir('*.dat');
if isfield(result, 'raw')
    result = rmfield(result, 'raw'); 
end
for fileNum = 1:length(temp.subjectFiles)
    temp.inputFile{fileNum} = temp.subjectFiles(fileNum).name; % change structure format to temp cell structure
    temp.data = importdata(temp.inputFile{fileNum}); % reading 'dat' file
    result.fileName{fileNum} = temp.inputFile{fileNum}; % save the individual file name
    result.raw(fileNum, :, :) = shiftdim(temp.data.data,1); % save the individual eeg data
end
temp.raw = result.raw; % save result raw as a temporary raw data
for additionalChanNum = 1:length(param.channelGroup) % for loop for making channelGroup
    temp.currentNum = length(param.rawChannel) + additionalChanNum; % increase the channel num for additional channel group
    for groupChannelNum = 1:length(param.channelGroup{additionalChanNum}) % for loop for finding included channel
        groupChannel(groupChannelNum) = find(cellfun(param.cellfind(param.channelGroup{additionalChanNum}{groupChannelNum}), param.rawChannel)); % collect included channel for the channel group
    end
    result.raw(:, temp.currentNum, :) = squeeze(mean(result.raw(:, groupChannel, :),2)); % average the channels data for additional channel data
end
clearvars -except param result

%% read excel
cd(param.excelDir);
[temp.num,temp.title,~] = xlsread(param.groupExcel);
temp.title(1) = []; % remove first title name (remove folder name)
result.groupName = temp.title; % save the subjectGroup title as a result
for subjectNum = 1:length(temp.num) % for loop for the subjectGroup member
    if size(num2str(temp.num(subjectNum,1)), 2) == 1 % if loop for the name format as 4 digit format like 'su0001'
        temp.subjectName{subjectNum} = strcat('su0', num2str(temp.num(subjectNum,1)));
    else % if loop for the name format as 2 digit format like 'su01'
        temp.subjectName{subjectNum} = strcat('su', num2str(temp.num(subjectNum,1)));
    end
end
temp.num(:,1) = []; % remove first title
for subjectNum = 1:length(temp.subjectName) % for loop for the subject num
    for subjectGroupNum = 1:length(result.groupName) % for loop for the subject group num
        temp.responseList = temp.num(:,subjectGroupNum); % read the response list
        temp.responseList = unique(temp.responseList); % unique the response list
        temp.responseList(isnan(temp.responseList)) = []; % remove the empty response list
        for responseNum = 1:length(temp.responseList) % for loop for the response list
            if temp.responseList(responseNum) == temp.num(subjectNum, subjectGroupNum) % check and set the group information
                temp.groupSubject(subjectNum, subjectGroupNum, responseNum) = 1; % included
            else
                temp.groupSubject(subjectNum, subjectGroupNum, responseNum) = 0; % excluded
            end
        end
    end
end
for fileNum = 1:length(result.fileName) % for loop for the file num (all eeg data)
    for subjectNum = 1:size(temp.groupSubject, 1) % for loop for the group subject
        if strfind(result.fileName{fileNum}, temp.subjectName{subjectNum}) % check & get the right file eeg data
            temp.fileSubject(:, :) = squeeze(temp.groupSubject(subjectNum, :, :));
            break;
        elseif strfind(result.fileName{fileNum}, strrep(temp.subjectName{subjectNum}, 'su', 'su00'))
            temp.fileSubject(:, :) = squeeze(temp.groupSubject(subjectNum, :, :));
            break;
        else
            temp.fileSubject(:, :) = zeros(size(squeeze(temp.groupSubject(subjectNum, :, :))));
        end
    end
    for conditionNum1 = 1:size(param.conditionInfo, 1) % for loop for condition number
        for conditionNum2 = 1:size(param.conditionInfo, 2) % for loop for the subcondition number
            for conditionNum = 1:length(param.conditionInfo{conditionNum1, conditionNum2}) % for loop for the included subject
                if strfind(result.fileName{fileNum}, param.conditionInfo{conditionNum1, conditionNum2}(conditionNum)) % if loop for checking the condition
                    temp.fileCondition(conditionNum1, conditionNum2) = 1;
                    break;
                else
                    temp.fileCondition(conditionNum1, conditionNum2) = 0;
                end
            end
        end
    end    
    for subConditionNum = 1:length(param.subCondition) % for loop for the subCondition Num
        if strfind(result.fileName{fileNum}, param.subCondition{subConditionNum}) % if loop for checking the subCondition
            temp.fileSubCondition(subConditionNum) = 1;
        else
            temp.fileSubCondition(subConditionNum) = 0;
        end        
    end
    for subjectNum = 1:length(temp.fileSubject(:)) %
        for conditionNum = 1:length(temp.fileCondition(:))
            for subConditionNum = 1:length(temp.fileSubCondition(:))
                temp.productFileGroup(subjectNum, conditionNum, subConditionNum) = ...
                    temp.fileSubject(subjectNum) * temp.fileCondition(conditionNum) * temp.fileSubCondition(subConditionNum); % collect all the subject, condition, subcondition
            end
        end
    end
    temp.fileGroup(fileNum,:,:,:,:,:) = reshape(temp.productFileGroup, [size(temp.fileSubject), size(temp.fileCondition), size(temp.fileSubCondition)]); % reshape the temp.filesubject for making fileNum to the first dimension 
end
for subConditionNum = 1:size(temp.fileGroup, 5)
    result.fileGroup(:,:,:,:,subConditionNum) = ...
        squeeze(temp.fileGroup(:,:,:,:,subConditionNum,subConditionNum)); % squeeze information to reduce dimension
end
clearvars -except param result

%% source_button
if param.source
    fprintf('%s: Source\n', datestr(now));
    [A, B] = SJ_source(param, result.raw);
    if size(result.raw,3) == (size(B, 3) + 1)
        B(:,:,size(B,3)+1) = B(:,:,size(B,3));        
    end
    result.roi = A;
    result.raw(:, (length(param.wholeChannel)+(1:length(param.roi))), :) = B;
    param.wholeChannel = [param.rawChannel; param.channelGroupName; param.roiName];
end
clearvars -except param result

%% ERP_button
if param.erp
    fprintf('%s: ERP\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        result.erp(:, :,interestLatencyNum) = ...
            mean(result.raw(:, :, temp.currentLatency(1):temp.currentLatency(2)), 3);
        clear temp;
    end
    clearvars -except param result
end

%% FFT_button
if param.fft
    fprintf('%s: FFT\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.fft(:,:,:,interestLatencyNum) = SJ_fft(param, result.raw(:, :, temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.fft = permute(temp.fft, [1 2 4 3]);
    result.fftIndividualFreq = SJ_individualFreq(param, result.fft);
    clearvars -except param result 
end

%% wavelet_button
if param.wavelet
    fprintf('%s: Wavelet\n', datestr(now));
    result.wavelet = SJ_wavelet(param, result.raw);
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.waveletIndividualLatency(:,:,:,interestLatencyNum)= SJ_individualLatency(param, result.wavelet(:,:,temp.currentLatency(1):temp.currentLatency(2),:));
    end
     result.waveletIndividualLatency = permute(temp.waveletIndividualLatency, [1 2 4 3]);
    clearvars -except param result
end

%% dipole_button
if param.dipole
    fprintf('%s: Dipole\n', datestr(now));
    
    param.conditionVHDR = 'VR_su0001_Average_Acc.vhdr';
    param.controlPoint{1} = [-52 -20 9];
    param.controlPoint{2} = [50 -21 7];
    
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        [temp.dipole(:, :, :, interestLatencyNum), ...
                    result.dipoleDistance(:, interestLatencyNum)] = ...
                    SJ_dipoleFitting(param, temp, result.raw(:, 1:length(param.rawChannel), temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.dipole = permute(temp.dipole, [1 4 2 3]);
    clearvars -except param result
end

%% CFC_button
if param.cfc
    fprintf('%s: CFC\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.cfc(:, :, :, :, interestLatencyNum) = ...
            SJ_cfc(param, result.raw(:, :, temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.cfc = permute(temp.cfc, [1 2 5 3 4]);
    result.individualCFC = squeeze(max(max(result.cfc, [], 4), [], 5));
    clearvars -except param result
end

%% DTF_button
if param.dtf
    fprintf('%s: DTF\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.dtf(:, :, :, :, interestLatencyNum) = ...
            SJ_dtf(param, result.raw(:, (length(param.wholeChannel)-(length(param.roi)-1:-1:0)), temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.dtf = permute(temp.dtf, [1 5 2 3 4]);
    result.individualDTF = SJ_individualDTF(param, result.dtf);
    clearvars -except param result
end

%% questionnaire_button
if param.questionnaire
    
cd(param.excelDir);
    fprintf('%s: Questionnaire\n', datestr(now));
    cd(param.subInputDir);
    [temp.num,temp.title,~] = xlsread(param.questionnaireExcel);
    temp.title(1) = [];
    result.questionnaireName = temp.title;
    for subjectNum = 1:length(temp.num)
        if size(num2str(temp.num(subjectNum,1)), 2) == 1
            temp.subjectName{subjectNum} = strcat('su0', num2str(temp.num(subjectNum,1)));
        else
            temp.subjectName{subjectNum} = strcat('su', num2str(temp.num(subjectNum,1)));
        end
    end
    temp.num(:,1) = [];
    result.subjectList = temp.subjectName;
    result.responseList = temp.num;
    for subjectNum = 1:length(temp.subjectName)
        for subjectGroupNum = 1:length(result.questionnaireName)
            temp.responseList = temp.num(:,subjectGroupNum);
            temp.responseList = unique(temp.responseList);
            temp.responseList(isnan(temp.responseList)) = [];
            result.questionnaireList{subjectGroupNum} = temp.responseList;
            for responseNum = 1:length(temp.responseList)
                if temp.responseList(responseNum) == temp.num(subjectNum, subjectGroupNum)
                    temp.groupSubject(subjectNum, subjectGroupNum, responseNum) = 1;
                else
                    temp.groupSubject(subjectNum, subjectGroupNum, responseNum) = 0;
                end
            end
        end
    end
    for fileNum = 1:length(result.fileName)
        for subjectNum = 1:size(temp.groupSubject, 1)
            if strfind(result.fileName{fileNum}, temp.subjectName{subjectNum})
                temp.fileSubject(:, :) = squeeze(temp.groupSubject(subjectNum, :, :));
                temp.currentName = temp.subjectName{subjectNum};
                break;
            elseif strfind(result.fileName{fileNum}, strrep(temp.subjectName{subjectNum}, 'su', 'su00'))
                temp.fileSubject(:, :) = squeeze(temp.groupSubject(subjectNum, :, :));
                temp.currentName = temp.subjectName{subjectNum};
                break;
            else
                temp.fileSubject(:, :) = zeros(size(squeeze(temp.groupSubject(subjectNum, :, :))));
            end
        end
        for subConditionNum = 1:length(param.subCondition)
            if strfind(result.fileName{fileNum}, param.subCondition{subConditionNum})
                temp.fileSubCondition(subConditionNum) = 1;
            else
                temp.fileSubCondition(subConditionNum) = 0;
            end
        end
        for subjectNum = 1:length(temp.fileSubject(:))
            for subConditionNum = 1:length(temp.fileSubCondition(:))
                temp.productFileGroup(subjectNum, subConditionNum) = ...
                    temp.fileSubject(subjectNum) * temp.fileSubCondition(subConditionNum);
            end
        end
        result.questionnaire(fileNum,:,:,:) = reshape(temp.productFileGroup, [size(temp.fileSubject), size(temp.fileSubCondition)]);
        result.subjectName{fileNum} = temp.currentName;
    end
    clearvars -except param result
end

%% PPT (Plot)
if param.savePPT
    fprintf('%s: PPT (Plot)\n', datestr(now));
    if param.picture
        cd(param.pptDir)
        SJ_picture(param, result);
    else
        cd(param.pptDir);
        param.clearppt = fullfile(param.pptDir, param.clearppt);
        param.picture = fullfile(param.pptDir, param.picture);
        param.outfileppt = fullfile(param.pptDir, param.outfileppt);
        SJ_plot(param, result);
    end
    clearvars -except param result
end

if param.waveletStatisticPlot
    fprintf('%s: waveletStatisticPlot\n', datestr(now));
    SJ_waveletStatisticPlot(param, result);
end

%% statistic_button
if param.statistic
    fprintf('%s: Statistic\n', datestr(now));
    result.statistic = SJ_statistic(result);
    clearvars -except param result
end

%% Excel (statistic_button)
if param.saveExcel
    fprintf('%s: Excel (Statistic)\n', datestr(now));
    cd(param.outputDir);
    SJ_excel(param, result);
    clearvars -except param result
end

%% Excel (Statistic_abstract)
if param.saveExcelAbstract
    % not ready to operate
    fprintf('%s: Excel (Statistic_abstract)\n', datestr(now));
    cd(param.outputDir);
    SJ_excelAbstract(param,result);
    clearvars -except param result
end

%% grand_sDTF
if param.grandDTFmovie
    fprintf('%s: grandDTFmoive\n', datestr(now));
    cd(param.outputDir);
    SJ_granddtfMovie(param, result);
    clearvars -except param result
end

%% individual_sDTF
if param.individualDTFmovie
    fprintf('%s: individualDTFmovie\n', datestr(now));
    windowLength = ceil(param.windowLength*param.fs);
    shiftLength = ceil(param.shiftLength*param.fs);
    lastEpoch = floor((param.epochLength-windowLength + 1)/shiftLength);
    for dtfEpoch = 1:lastEpoch
        fprintf('%s: %d/%d processing \n', datestr(now), dtfEpoch, lastEpoch);
        startPoint = floor((dtfEpoch-1)*shiftLength + 1);
        endPoint = floor((dtfEpoch-1)*shiftLength + windowLength);
        temp.sdtf(:, :, :, :, dtfEpoch) = ...
            SJ_dtf(param, result.raw(:,(length(param.wholeChannel)-(length(param.roi)-1:-1:0)),startPoint:endPoint));
    end
    result.sdtf = permute(temp.sdtf, [1 5 2 3 4]);
    clearvars -except param result
    fprintf('%s: sDTF_individualMoive\n', datestr(now));
    cd(param.plotDir);
    SJ_dtfMovie(param, result);
    clearvars -except param result
end

%% Result (Mat)
if param.saveResult
    fprintf('%s: Result\n', datestr(now));
    cd(param.outputDir);
    save('result.mat', 'param', 'result', '-v7.3');
    clearvars -except param result 
end

%% End
fprintf('%s: SJ_totalResult end\n', datestr(now));


% --- Executes on button press in saveParameter.
function saveParameter_Callback(hObject, eventdata, handles)
% hObject    handle to saveParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
parameterFileName = strcat('parameter_', datestr(now,'yymmddHHMM'));
save(parameterFileName, 'handles');


% --- Executes on button press in loadParameter.
function loadParameter_Callback(hObject, eventdata, handles)
% hObject    handle to loadParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
parameterFileName = strcat('parameter_', datestr(now,'yymmddHHMM'));
handles = load(parameterFileName, 'handles');

function inputDir_Callback(hObject, eventdata, handles)
% hObject    handle to inputDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of inputDir as text
%        str2double(get(hObject,'String')) returns contents of inputDir as a double


% --- Executes during object creation, after setting all properties.
function inputDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ConditionMenu.
function ConditionMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ConditionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ConditionMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ConditionMenu


% --- Executes during object creation, after setting all properties.
function ConditionMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ConditionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ConditionOption.
function ConditionOption_Callback(hObject, eventdata, handles)
% hObject    handle to ConditionOption (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function datFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to dat_frequency_title (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dat_frequency_title as text
%        str2double(get(hObject,'String')) returns contents of dat_frequency_title as a double

function datFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dat_frequency_title (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

% --- Executes during object creation, after setting all properties.
function dat_frequency_title_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dat_frequency_title (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dat_totalLatency_Callback(hObject, eventdata, handles)
% hObject    handle to dat_totalLatency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dat_totalLatency as text
%        str2double(get(hObject,'String')) returns contents of dat_totalLatency as a double


% --- Executes during object creation, after setting all properties.
function dat_totalLatency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dat_totalLatency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dat_zeroLatency_Callback(hObject, eventdata, handles)
% hObject    handle to dat_zeroLatency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dat_zeroLatency as text
%        str2double(get(hObject,'String')) returns contents of dat_zeroLatency as a double


% --- Executes during object creation, after setting all properties.
function dat_zeroLatency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dat_zeroLatency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function channelInformationFile_Callback(hObject, eventdata, handles)
% hObject    handle to channelInformationFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of channelInformationFile as text
%        str2double(get(hObject,'String')) returns contents of channelInformationFile as a double


% --- Executes during object creation, after setting all properties.
function channelInformationFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelInformationFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function conditionExcel_Callback(hObject, eventdata, handles)
% hObject    handle to conditionExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of conditionExcel as text
%        str2double(get(hObject,'String')) returns contents of conditionExcel as a double



% --- Executes during object creation, after setting all properties.
function conditionExcel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to conditionExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function subFunctionDir_Callback(hObject, eventdata, handles)
% hObject    handle to subFunctionDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subFunctionDir as text
%        str2double(get(hObject,'String')) returns contents of subFunctionDir as a double


% --- Executes during object creation, after setting all properties.
function subFunctionDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subFunctionDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function subDataDir_Callback(hObject, eventdata, handles)
% hObject    handle to subDataDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subDataDir as text
%        str2double(get(hObject,'String')) returns contents of subDataDir as a double

% --- Executes during object creation, after setting all properties.
function subDataDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subDataDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function resultDir_Callback(hObject, eventdata, handles)
% hObject    handle to resultDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of resultDir as text
%        str2double(get(hObject,'String')) returns contents of resultDir as a double


% --- Executes during object creation, after setting all properties.
function resultDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resultDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function datDir_Callback(hObject, eventdata, handles)
% hObject    handle to datDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of datDir as text
%        str2double(get(hObject,'String')) returns contents of datDir as a double


% --- Executes during object creation, after setting all properties.
function datDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function excelDir_Callback(hObject, eventdata, handles)
% hObject    handle to excelDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of excelDir as text
%        str2double(get(hObject,'String')) returns contents of excelDir as a double


% --- Executes during object creation, after setting all properties.
function excelDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to excelDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function statisticDir_Callback(hObject, eventdata, handles)
% hObject    handle to statisticDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of statisticDir as text
%        str2double(get(hObject,'String')) returns contents of statisticDir as a double


% --- Executes during object creation, after setting all properties.
function statisticDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to statisticDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plotDir_Callback(hObject, eventdata, handles)
% hObject    handle to plotDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plotDir as text
%        str2double(get(hObject,'String')) returns contents of plotDir as a double


% --- Executes during object creation, after setting all properties.
function plotDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function chanExcel_Callback(hObject, eventdata, handles)
% hObject    handle to chanExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of chanExcel as text
%        str2double(get(hObject,'String')) returns contents of chanExcel as a double


% --- Executes during object creation, after setting all properties.
function chanExcel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chanExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtf_surrogateNum_Callback(hObject, eventdata, handles)
% hObject    handle to dtf_surrogateNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtf_surrogateNum as text
%        str2double(get(hObject,'String')) returns contents of dtf_surrogateNum as a double


% --- Executes during object creation, after setting all properties.
function dtf_surrogateNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtf_surrogateNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtf_threshold_Callback(hObject, eventdata, handles)
% hObject    handle to dtf_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtf_threshold as text
%        str2double(get(hObject,'String')) returns contents of dtf_threshold as a double


% --- Executes during object creation, after setting all properties.
function dtf_threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtf_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtf_windowLength_Callback(hObject, eventdata, handles)
% hObject    handle to dtf_windowLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtf_windowLength as text
%        str2double(get(hObject,'String')) returns contents of dtf_windowLength as a double


% --- Executes during object creation, after setting all properties.
function dtf_windowLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtf_windowLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtf_shiftLength_Callback(hObject, eventdata, handles)
% hObject    handle to dtf_shiftLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtf_shiftLength as text
%        str2double(get(hObject,'String')) returns contents of dtf_shiftLength as a double


% --- Executes during object creation, after setting all properties.
function dtf_shiftLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtf_shiftLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtf_movieThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to dtf_movieThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtf_movieThreshold as text
%        str2double(get(hObject,'String')) returns contents of dtf_movieThreshold as a double

% --- Executes during object creation, after setting all properties.
function dtf_movieThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtf_movieThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cfc_phase_low_Callback(hObject, eventdata, handles)
% hObject    handle to cfc_phase_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cfc_phase_low as text
%        str2double(get(hObject,'String')) returns contents of cfc_phase_low as a double

% --- Executes during object creation, after setting all properties.
function cfc_phase_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cfc_phase_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cfc_phase_high_Callback(hObject, eventdata, handles)
% hObject    handle to cfc_phase_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cfc_phase_high as text
%        str2double(get(hObject,'String')) returns contents of cfc_phase_high as a double

% --- Executes during object creation, after setting all properties.
function cfc_phase_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cfc_phase_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cfc_amplitude_low_Callback(hObject, eventdata, handles)
% hObject    handle to cfc_amplitude_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cfc_amplitude_low as text
%        str2double(get(hObject,'String')) returns contents of cfc_amplitude_low as a double

% --- Executes during object creation, after setting all properties.
function cfc_amplitude_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cfc_amplitude_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cfc_amplitude_high_Callback(hObject, eventdata, handles)
% hObject    handle to cfc_amplitude_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cfc_amplitude_high as text
%        str2double(get(hObject,'String')) returns contents of cfc_amplitude_high as a double

% --- Executes during object creation, after setting all properties.
function cfc_amplitude_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cfc_amplitude_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in freq_delta_button.
function freq_delta_button_Callback(hObject, eventdata, handles)
% hObject    handle to freq_delta_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of freq_delta_button


% --- Executes on button press in freq_theta_button.
function freq_theta_button_Callback(hObject, eventdata, handles)
% hObject    handle to freq_theta_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of freq_theta_button


% --- Executes on button press in freq_alpha_button.
function freq_alpha_button_Callback(hObject, eventdata, handles)
% hObject    handle to freq_alpha_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of freq_alpha_button

% --- Executes on button press in freq_gamma_button.
function freq_gamma_button_Callback(hObject, eventdata, handles)
% hObject    handle to freq_gamma_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of freq_gamma_button


% --- Executes on button press in freq_beta_button.
function freq_beta_button_Callback(hObject, eventdata, handles)
% hObject    handle to freq_beta_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of freq_beta_button



function freq_delta_high_Callback(hObject, eventdata, handles)
% hObject    handle to freq_delta_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_delta_high as text
%        str2double(get(hObject,'String')) returns contents of freq_delta_high as a double

% --- Executes during object creation, after setting all properties.
function freq_delta_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_delta_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_theta_low_Callback(hObject, eventdata, handles)
% hObject    handle to freq_theta_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_theta_low as text
%        str2double(get(hObject,'String')) returns contents of freq_theta_low as a double

% --- Executes during object creation, after setting all properties.
function freq_theta_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_theta_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_theta_high_Callback(hObject, eventdata, handles)
% hObject    handle to freq_theta_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_theta_high as text
%        str2double(get(hObject,'String')) returns contents of freq_theta_high as a double

% --- Executes during object creation, after setting all properties.
function freq_theta_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_theta_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_alpha_low_Callback(hObject, eventdata, handles)
% hObject    handle to freq_alpha_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_alpha_low as text
%        str2double(get(hObject,'String')) returns contents of freq_alpha_low as a double

% --- Executes during object creation, after setting all properties.
function freq_alpha_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_alpha_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_alpha_high_Callback(hObject, eventdata, handles)
% hObject    handle to freq_alpha_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_alpha_high as text
%        str2double(get(hObject,'String')) returns contents of freq_alpha_high as a double

% --- Executes during object creation, after setting all properties.
function freq_alpha_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_alpha_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_beta_low_Callback(hObject, eventdata, handles)
% hObject    handle to freq_beta_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_beta_low as text
%        str2double(get(hObject,'String')) returns contents of freq_beta_low as a double

% --- Executes during object creation, after setting all properties.
function freq_beta_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_beta_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_beta_high_Callback(hObject, eventdata, handles)
% hObject    handle to freq_beta_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_beta_high as text
%        str2double(get(hObject,'String')) returns contents of freq_beta_high as a double

% --- Executes during object creation, after setting all properties.
function freq_beta_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_beta_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_gamma_low_Callback(hObject, eventdata, handles)
% hObject    handle to freq_gamma_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_gamma_low as text
%        str2double(get(hObject,'String')) returns contents of freq_gamma_low as a double

% --- Executes during object creation, after setting all properties.
function freq_gamma_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_gamma_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_gamma_high_Callback(hObject, eventdata, handles)
% hObject    handle to freq_gamma_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_gamma_high as text
%        str2double(get(hObject,'String')) returns contents of freq_gamma_high as a double

% --- Executes during object creation, after setting all properties.
function freq_gamma_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_gamma_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in freq_whole_button.
function freq_whole_button_Callback(hObject, eventdata, handles)
% hObject    handle to freq_whole_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of freq_whole_button

function freq_whole_low_Callback(hObject, eventdata, handles)
% hObject    handle to freq_whole_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_whole_low as text
%        str2double(get(hObject,'String')) returns contents of freq_whole_low as a double

% --- Executes during object creation, after setting all properties.
function freq_whole_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_whole_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_whole_high_Callback(hObject, eventdata, handles)
% hObject    handle to freq_whole_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_whole_high as text
%        str2double(get(hObject,'String')) returns contents of freq_whole_high as a double

% --- Executes during object creation, after setting all properties.
function freq_whole_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_whole_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_delta_low_Callback(hObject, eventdata, handles)
% hObject    handle to freq_delta_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_delta_low as text
%        str2double(get(hObject,'String')) returns contents of freq_delta_low as a double

% --- Executes during object creation, after setting all properties.
function freq_delta_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_delta_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function questionnaireExcel_Callback(hObject, eventdata, handles)
% hObject    handle to questionnaireExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of questionnaireExcel as text
%        str2double(get(hObject,'String')) returns contents of questionnaireExcel as a double

% --- Executes during object creation, after setting all properties.
function questionnaireExcel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to questionnaireExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in freq_extra_button.
function freq_extra_button_Callback(hObject, eventdata, handles)
% hObject    handle to freq_extra_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of freq_extra_button

function freq_extra_low_Callback(hObject, eventdata, handles)
% hObject    handle to freq_extra_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_extra_low as text
%        str2double(get(hObject,'String')) returns contents of freq_extra_low as a double

% --- Executes during object creation, after setting all properties.
function freq_extra_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_extra_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_extra_high_Callback(hObject, eventdata, handles)
% hObject    handle to freq_extra_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_extra_high as text
%        str2double(get(hObject,'String')) returns contents of freq_extra_high as a double

% --- Executes during object creation, after setting all properties.
function freq_extra_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_extra_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function latencyExcel_Callback(hObject, eventdata, handles)
% hObject    handle to latencyExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of latencyExcel as text
%        str2double(get(hObject,'String')) returns contents of latencyExcel as a double


% --- Executes during object creation, after setting all properties.
function latencyExcel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to latencyExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function groupExcel_Callback(hObject, eventdata, handles)
% hObject    handle to groupExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of groupExcel as text
%        str2double(get(hObject,'String')) returns contents of groupExcel as a double


% --- Executes during object creation, after setting all properties.
function groupExcel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to groupExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveParam.
function saveParam_Callback(hObject, eventdata, handles)
% hObject    handle to saveParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
save(handles.parameterFileName.String, 'handles');

% --- Executes on button press in loadParam.
function loadParam_Callback(hObject, eventdata, handles)
% hObject    handle to loadParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = load(handles.parameterFileName.String);


function parameterFileName_Callback(hObject, eventdata, handles)
% hObject    handle to parameterFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of parameterFileName as text
%        str2double(get(hObject,'String')) returns contents of parameterFileName as a double


% --- Executes during object creation, after setting all properties.
function parameterFileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to parameterFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtf_pictureResult_Callback(hObject, eventdata, handles)
% hObject    handle to dtf_pictureResult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtf_pictureResult as text
%        str2double(get(hObject,'String')) returns contents of dtf_pictureResult as a double


% --- Executes during object creation, after setting all properties.
function dtf_pictureResult_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtf_pictureResult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
