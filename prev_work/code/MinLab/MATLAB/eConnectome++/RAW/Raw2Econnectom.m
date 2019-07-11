% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% set variable
rawDir = 'C:\Users\Insoo\Desktop\SKK_3\GRD'; % read input directory (.dat)
econnectomDir = 'C:\Users\Insoo\Desktop\SKK_3\GRD\econnectome'; % save output directory (.mat)
samplingRate = 1000; % the sampling rate
labelType = 'standard'; % 'standard' or 'customized', standard don't have 'EOG'

% verbose = 1; 
% % save_figs = 1; % 1: save result picture
% % fig_dir = 'C:/Users/user/Desktop/Min_Lab/bbci_public-master'; % where to save picture
% 
% fig_dir = fullfile(fig_dir, 'new_data_new_format'); % make a new folder for save picture
% if save_figs && not(exist(fig_dir, 'dir'))
%     mkdir(fig_dir);
% end

%% initialize (read file name)
% cd(rawDir);
eeg_files = dir('*.mat'); % read all eeg file in raw directory (preprocessing in Brain Analzer)
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name; % dat
    eeg_info(eegFileNum, 2) = strrep(eeg_info(eegFileNum,1),'mat', 'mat'); % mat
end
clear eegFileNum eeg_files;

%% dat2mat prossessing (read info and make econnectom mat file)
for DataNum = 1:length(eeg_info)
%     cd(rawDir);
    DatData = importdata(eeg_info{DataNum,1}); % get information in dat file
    EEG.name = eeg_info{DataNum,1}; % the name for the EEG data
    EEG.type = 'EEG'; % the type of data, 'EEG', 'ECOG' or 'MEG'
    EEG.nbchan = size(DatData.ERP_F__L, 2); % the number of channels
    EEG.points = size(DatData.ERP_F__L, ); % the number of sampling points
    EEG.srate = samplingRate; % the sampling rate
    EEG.labeltype = labelType; % 'standard' or 'customized'
    EEG.labels = DatData.labels'; % a cell array of channel labels
    EEG.data = DatData.data'; % a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
    EEG.unit = 'uV'; % just anouncement
    clear DatData;
%     cd(econnectomDir);
    save(eeg_info{DataNum,2},'EEG');
    clear EEG;  
end