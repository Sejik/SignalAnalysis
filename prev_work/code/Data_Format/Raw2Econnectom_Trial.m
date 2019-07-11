%% Econnectome_Automatic
% designed by Sejik Park
% E-maill: sejik6307@gmail.com

% 1. read EEG file by bbci tool (change into Econnectome tool)
% 2. Analyze (Econnectome connectivity than LDA tool )
% 3. Result

clear all;
clc;

%% Variable (change it only)
% 1. read EEG file by bbci tool (change into Econnectome tool)
% bbci
bbciDir = 'C:\Users\win\Desktop\Research\3. Analyze\Tool\bbci_public-master\bbci_public-master';
MyDataDir = 'C:\Users\win\Desktop\Research\3. Analyze\Tool\bbci_public-master\data';
DetailDir = 'TIN'; % read input directory (.eeg)
MyTempDir = 'C:\Users\win\Desktop\Research\3. Analyze\Tool\bbci_public-master\tmp';

band = [2,40]; % frequency band
ival_spec = [-500 1500]; % segmentation range


%% 1. read EEG file by bbci tool (change into Econnectome tool)
% using bbci to read .eeg file
cd(bbciDir);
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);

cd(fullfile(MyDataDir, DetailDir));
eeg_files = dir('*.eeg'); % read all eeg file in raw directory
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = strrep(eeg_files(eegFileNum).name, '.eeg', ''); % eeg
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);
epos = cell(1, n_subjects);

for eegFileNum = 1:n_subjects
    cd(fullfile(MyDataDir, DetailDir));
    file = fullfile(DetailDir, eeg_info(eegFileNum));
    [cnt, vmrk, hdr] = file_readBV(file);
    
   
    samplingRate = 1000; % the sampling rate
    labelType = 'standard'; % 'standard' or 'customized', standard don't have 'EOG'
    
    S11 = vmrk.y(4,1:end) .* vmrk.time(1:end);
    S12 = vmrk.y(5,1:end) .* vmrk.time(1:end);
    S21 = vmrk.y(6,1:end) .* vmrk.time(1:end);
    S22 = vmrk.y(7,1:end) .* vmrk.time(1:end);
    
    S11(S11 == 0) = [];
    S12(S12 == 0) = [];
    S21(S21 == 0) = [];
    S22(S22 == 0) = [];
    
    %-500-1500
    for S11_temp = 1:length(S11)
        startpoint = S11(S11_temp) - 500;
        endpoint = S11(S11_temp) + 1500;
        DatData.data = cnt.x(startpoint:endpoint,:); % get information in dat file
        DatData.textdata = cnt.clab;
        EEG.name = eeg_info{eegFileNum}; % the name for the EEG data
        EEG.type = 'EEG'; % the type of data, 'EEG', 'ECOG' or 'MEG'
        EEG.nbchan = size(DatData.data, 2); % the number of channels
        EEG.points = size(DatData.data, 1); % the number of sampling points
        EEG.srate = samplingRate; % the sampling rate
        EEG.labeltype = labelType; % 'standard' or 'customized'
        EEG.labels = shiftdim(DatData.textdata,1); % a cell array of channel labels
        EEG.data = shiftdim(DatData.data,1); % a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
        EEG.unit = 'uV'; % just anouncement
        clear DatData;
        filename = strcat(char(eeg_info{eegFileNum}), '_S11_');
        filename = strcat(filename, int2str(S11_temp));
        cd(MyTempDir);
        save(filename,'EEG');
        clear EEG;
    end
    for S12_temp = 1:length(S12)
        startpoint = S12(S12_temp) - 500;
        endpoint = S12(S12_temp) + 1500;
        DatData.data = cnt.x(startpoint:endpoint,:); % get information in dat file
        DatData.textdata = cnt.clab;
        EEG.name = eeg_info{eegFileNum,1}; % the name for the EEG data
        EEG.type = 'EEG'; % the type of data, 'EEG', 'ECOG' or 'MEG'
        EEG.nbchan = size(DatData.data, 2); % the number of channels
        EEG.points = size(DatData.data, 1); % the number of sampling points
        EEG.srate = samplingRate; % the sampling rate
        EEG.labeltype = labelType; % 'standard' or 'customized'
        EEG.labels = shiftdim(DatData.textdata,1); % a cell array of channel labels
        EEG.data = shiftdim(DatData.data,1); % a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
        EEG.unit = 'uV'; % just anouncement
        clear DatData;
        filename = strcat(char(eeg_info{eegFileNum}), '_S12_');
        filename = strcat(filename, int2str(S12_temp));
        cd(MyTempDir);
        save(filename,'EEG');
        clear EEG;
    end
    for S21_temp = 1:length(S21)
        startpoint = S21(S21_temp) - 500;
        endpoint = S21(S21_temp) + 1500;
        DatData.data = cnt.x(startpoint:endpoint,:); % get information in dat file
        DatData.textdata = cnt.clab;
        EEG.name = eeg_info{eegFileNum,1}; % the name for the EEG data
        EEG.type = 'EEG'; % the type of data, 'EEG', 'ECOG' or 'MEG'
        EEG.nbchan = size(DatData.data, 2); % the number of channels
        EEG.points = size(DatData.data, 1); % the number of sampling points
        EEG.srate = samplingRate; % the sampling rate
        EEG.labeltype = labelType; % 'standard' or 'customized'
        EEG.labels = shiftdim(DatData.textdata,1); % a cell array of channel labels
        EEG.data = shiftdim(DatData.data,1); % a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
        EEG.unit = 'uV'; % just anouncement
        clear DatData;
        filename = strcat(char(eeg_info{eegFileNum}), '_S21_');
        filename = strcat(filename, int2str(S21_temp));
        cd(MyTempDir);
        save(filename,'EEG');
        clear EEG;
        clear EEG;
    end
    for S22_temp = 1:length(S22)
        startpoint = S22(S22_temp) - 500;
        endpoint = S22(S22_temp) + 1500;
        DatData.data = cnt.x(startpoint:endpoint,:); % get information in dat file
        DatData.textdata = cnt.clab;
        EEG.name = eeg_info{eegFileNum,1}; % the name for the EEG data
        EEG.type = 'EEG'; % the type of data, 'EEG', 'ECOG' or 'MEG'
        EEG.nbchan = size(DatData.data, 2); % the number of channels
        EEG.points = size(DatData.data, 1); % the number of sampling points
        EEG.srate = samplingRate; % the sampling rate
        EEG.labeltype = labelType; % 'standard' or 'customized'
        EEG.labels = shiftdim(DatData.textdata,1); % a cell array of channel labels
        EEG.data = shiftdim(DatData.data,1); % a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
        EEG.unit = 'uV'; % just anouncement
        clear DatData;
        filename = strcat(char(eeg_info{eegFileNum}), '_S22_');
        filename = strcat(filename, int2str(S22_temp));
        cd(MyTempDir);
        save(filename,'EEG');
        clear EEG;
    end
end