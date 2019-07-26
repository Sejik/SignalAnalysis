% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% set variable
roiDir		= 'ROI_each';
groupDir	= 'ROI_group';

%% initialize (read file name)
cd(roiDir);
eeg_files = dir('*.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name; % mat
end
clear eegFileNum eeg_files;

%% dat2mat prossessing (read info and make econnectom mat file)
for DataNum = 1:length(eeg_info)
    load(eeg_info{DataNum, 1});
    ROI.labels{DataNum} = labels{1}; 
    ROI.vertices{DataNum} = vertices{1};
    ROI.numv = 20516;
    ROI.centers(DataNum, 1:3) = centers;
end
cd('..');

labels = ROI.labels;
vertices = ROI.vertices;
numv = ROI.numv;
centers = ROI.centers;

%% Save
%cd(groupDir);
save(fullfile(groupDir, 'ROI_group.mat'), 'labels', 'vertices', 'numv', 'centers');