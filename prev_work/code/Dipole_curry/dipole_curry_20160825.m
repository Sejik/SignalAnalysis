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
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\Dipole\TIN'; % read input directory (.dat)
resultDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\Dipole'; % save output directory (.mat)

left = [-41.3 5.7 53.6];
right = [40.5 3.6 58.3];

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
    
    result.left(1:3) = currydip(1:3,1,1);
    result.left(4) = currydip(7,1,1);
    result.right(1:3) = currydip(1:3,1,1);  
    result.right(4) = currydip(7,1,1);  
    
    left_x = (currydip(1,1,1)-left(1))^2;
    left_y = (currydip(2,1,1)-left(2))^2;
    left_z = (currydip(3,1,1)-left(3))^2;
    current_left_distance = sqrt(left_x + left_y + left_z);
    
    right_x = (currydip(1,1,1)-right(1))^2;
    right_y = (currydip(2,1,1)-right(2))^2;
    right_z = (currydip(3,1,1)-right(3))^2;
    current_right_distance = sqrt(right_x + right_y + right_z);
    
    for dipoleNum = 2:size(currydip,2)
        left_x = (currydip(1,dipoleNum,1)-left(1))^2;
        left_y = (currydip(2,dipoleNum,1)-left(2))^2;
        left_z = (currydip(3,dipoleNum,1)-left(3))^2;
        left_distance = sqrt(left_x + left_y + left_z);
        % find left nearest dipole fitting
        if current_left_distance > left_distance
            result.left(1:3) = currydip(1:3,dipoleNum,1);
            result.left(4) = currydip(7,dipoleNum,1);
            current_left_distance = left_distance;
        end
        
        right_x = (currydip(1,dipoleNum,1)-right(1))^2;
        right_y = (currydip(2,dipoleNum,1)-right(2))^2;
        right_z = (currydip(3,dipoleNum,1)-right(3))^2;
        right_distance = sqrt(right_x + right_y + right_z);
        % find right nearest dipole fitting
        if current_right_distance > right_distance
            result.right(1:3) = currydip(1:3,dipoleNum,1);
            result.right(4) = currydip(7,dipoleNum,1);
            current_right_distance = right_distance;
        end        
    end
    
    cd(resultDir);
    save(strcat('TIN_', eeg_info{dataNum}), 'result');
end