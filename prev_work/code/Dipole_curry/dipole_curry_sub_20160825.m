%% Dipole_curry_20160806
% designed by Sejik Park (Korea University Undergraduated)
% e-mail: sejik6307@gmail.com
% dipole result from curry
% rearrange data by finding maximum current dipole & weighted sum position
% also, calculate the Uclidean distance

%% clear before data
clear all;
clc;

%% set variable
pTIN = {'02', '04', '06', '08', '10', '11', '17', '01', '03', '07', '09', '14', '18', '25'};
TIN = {};
currentCondition = '11*';

rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\Dipole\dipole\11';
resultDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\Dipole\dipole';

%% initialize (read file name)

for dataNum = 1:length(pTIN)
    current = strcat('pTIN_', pTIN{dataNum}, '_', currentCondition);    
    cd(rawDir);
    data_files = dir(current);
    eeg_info{dataNum} = data_files.name;
end
current_length = length(pTIN);
for dataNum = 1:length(TIN)
    current = strcat('TIN_', TIN{dataNum}, '_', currentCondition);    
    cd(rawDir);
    data_files = dir(current);
    eeg_info{dataNum+current_length} = data_files.name;
end
clear eegFileNum eeg_files;

%% dat2mat prossessing (read info and make econnectom mat file)
% currydip(1:3,:,sample) contains locations
% currydip(4:6,:,sample) contains orientations
% currydip(7,:,sample) contains strengths
% currydip(8:19,:,sample) contains ellipsoids
% currydev contains deviations
for dataNum = 1:length(eeg_info)
    cd(rawDir);
    load(eeg_info{dataNum});
    
    left(dataNum,:) = result.left;
    right(dataNum,:) = result.right;
end


cd(resultDir);
save('Group11_1', 'left', 'right');

%%
% load('Group11_2.mat');
% left11 = left; right11 = right;
% load('Group12_2.mat');
% left12 = left; right12 = right;
% group1_left1(:,1:3) = (left11(:,1:3)-left12(:,1:3)).^2;
% group1_left1(:,4) = left11(:,4) + left12(:,4);
% group1_right1 = right11(:,1:3)-right12(:,1:3);
% group1_right1(:,1:3) = (right11(:,1:3)-right12(:,1:3)).^2;
% group1_right1(:,4) = right11(:,4) + right12(:,4);
% left = sum(group1_left1(:,1:3),2);
% right = sum(group1_right1(:,1:3),2);