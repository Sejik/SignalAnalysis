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
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\Source\dipole'; % read input directory (.dat)
resultDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\Source\result'; % save output directory (.mat)

%% initialize (read file name)
cd(rawDir);
eeg_files = dir('*.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
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
    [M,I] = max(currydip(7,:,:));
    max_location = currydip(1:3,:,I); % max location
    mean_location = mean(currydip(1:3,:,:) .* repmat(currydip(7,:,:),3,1),3);
    normalize = sqrt(mean((mean_location./max_location).^2));
    mean_location = mean_location/normalize;
    
    result{dataNum, 1} = eeg_info{dataNum};
    result{dataNum, 2} = max_location(1);
    result{dataNum, 3} = max_location(2);
    result{dataNum, 4} = max_location(3);
    result{dataNum, 5} = mean_location(1);
    result{dataNum, 6} = mean_location(2);
    result{dataNum, 7} = mean_location(3);
end    

cd(resultDir);
save('result.mat', 'result');