% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% set variable
rawDir = 'C:\Users\win\Desktop\Average_140_down sampling rate'; % read input directory (.dat)
econnectomDir = 'C:\Users\win\Desktop\2.raw2econnectome'; % save output directory (.mat)
samplingRate = 140; % the sampling rate
labelType = 'standard'; % 'standard' or 'customized', standard don't have 'EOG'

%% initialize (read file name)
cd(rawDir);
eeg_files = dir('*.dat'); % read all eeg file in raw directory (preprocessing in Brain Analzer)
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name; % dat
    eeg_info(eegFileNum, 2) = strrep(eeg_info(eegFileNum,1),'dat', 'mat'); % mat
end
clear eegFileNum eeg_files;

%% dat2mat prossessing (read info and make econnectom mat file)
for DataNum = 1:length(eeg_info)
    cd(rawDir);
    DatData = importdata(eeg_info{DataNum,1}); % get information in dat file
    EEG.name = eeg_info{DataNum,1}; % the name for the EEG data
    EEG.type = 'EEG'; % the type of data, 'EEG', 'ECOG' or 'MEG'
    EEG.nbchan = size(DatData.data, 2); % the number of channels
    EEG.points = size(DatData.data, 1); % the number of sampling points
    EEG.srate = samplingRate; % the sampling rate
    EEG.labeltype = labelType; % 'standard' or 'customized'
    EEG.labels = DatData.textdata'; % a cell array of channel labels
    EEG.data = shiftdim(DatData.data,1); % a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
    EEG.unit = 'uV'; % just anouncement
    clear DatData;
    cd(econnectomDir);
    save(eeg_info{DataNum,2},'EEG');
    clear EEG;  
end