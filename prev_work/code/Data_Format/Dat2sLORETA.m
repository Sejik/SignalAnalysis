% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% set variable
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\LORETA\RAW'; % read input directory (.dat)
rLORETADir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\LORETA\LORETA'; % save output directory (.txt)

%% initialize (read file name)
cd(rawDir);
eeg_files = dir('*.dat'); % read all eeg file in raw directory (preprocessing in Brain Analzer)
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name; % dat
    eeg_info(eegFileNum, 2) = strrep(eeg_info(eegFileNum,1),'dat', 'txt'); % txt
end
clear eegFileNum eeg_files;

%% dat2rLORETA prossessing
for DataNum = 1:length(eeg_info)
    cd(rawDir);
    DatData = importdata(eeg_info{DataNum,1}); % get information in dat file
    EEG = DatData.data;
    clear DatData;
    cd(rLORETADir);
    dlmwrite(eeg_info{DataNum,2}, EEG, 'delimiter','\t','newline','pc','precision',8);
    clear EEG;  
end