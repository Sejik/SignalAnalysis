%% Wavelet_statistics
% designed by Sejik Park (Korea University Undergraduated)

% Process
% 1. read preprocessed data (output of brainvision analyzer)
%   read format: '.mat'
%   individual average data
% 2. calculate wavelet (this code)
% 3. statistic analysis

function wavele_statistics()
% clear before processes
clear; clc; close;

%% basic set up
fprintf('%s: wavelet code is started.\n', datestr(now));
% directory
file.inputDir1 = 'C:\Users\win\Desktop\wavelet\re'; % input File directory 1
file.inputDir2 = 'C:\Users\win\Desktop\wavelet\res'; % input File directory 2
file.outputDir = 'C:\Users\win\Desktop\statistic'; % output File directory
file.outputName = 'wavelet_statistics'; % add outputName in front of input file name

%% read preprocessed data
fprintf('%s: checking input file\n', datestr(now));
cd(file.inputDir1);
eeg_files1 = dir('*.mat');
for eegFileNum = 1:length(eeg_files1)
    file.inputFile1{eegFileNum} = eeg_files1(eegFileNum).name;
end
cd(file.inputDir2);
eeg_files2 = dir('*.mat');
for eegFileNum = 1:length(eeg_files2)
    file.inputFile2{eegFileNum} = eeg_files2(eegFileNum).name;
end

%% Wavelet statistics
for eegFileNum = 1:length(file.inputFile1)
    fprintf('%s: %s is on working.\n', datestr(now), file.inputDir1);
    cd(file.inputDir1);
    result = importdata(file.inputFile1{eegFileNum});
    group1{eegFileNum} = result.individualFreqMaxAmplitude;
    clearvars -except group1 group2 eegFileNum file
end
for eegFileNum = 1:length(file.inputFile2)
    fprintf('%s: %s is on working.\n', datestr(now), file.inputDir1);
    cd(file.inputDir2);
    result = importdata(file.inputFile2{eegFileNum});
    group2{eegFileNum} = result.individualFreqMaxAmplitude;
    clearvars -except group1 group2 eegFileNum file
end

for subjectNum = 1:length(group1)
    for frequencyNum = 1:length(group1{subjectNum})
        for latencyNum = 1:length(group1{subjectNum}{frequencyNum})
            for channelNum = 1:length(group1{subjectNum}{latencyNum})
                amplitudeTotal1(subjectNum, frequencyNum, latencyNum, channelNum) = group1{subjectNum}{frequencyNum}{latencyNum}(channelNum,1);
                latencyTotal1(subjectNum, frequencyNum, latencyNum, channelNum) = group1{subjectNum}{frequencyNum}{latencyNum}(channelNum, 2);
            end
        end
    end
end

for subjectNum = 1:length(group2)
    for frequencyNum = 1:length(group2{subjectNum})
        for latencyNum = 1:length(group2{subjectNum}{frequencyNum})
            for channelNum = 1:length(group2{subjectNum}{latencyNum})
                amplitudeTotal2(subjectNum, frequencyNum, latencyNum, channelNum) = group2{subjectNum}{frequencyNum}{latencyNum}(channelNum,1);
                latencyTotal2(subjectNum, frequencyNum, latencyNum, channelNum) = group2{subjectNum}{frequencyNum}{latencyNum}(channelNum, 2);
            end
        end
    end
end

for frequencyNum = 1:length(group2{subjectNum})
    for latencyNum = 1:length(group2{subjectNum}{frequencyNum})
        for channelNum = 1:length(group2{subjectNum}{frequencyNum}{latencyNum})            
            [h, p] = ttest(amplitudeTotal1(:, frequencyNum, latencyNum,channelNum), amplitudeTotal2(:,frequencyNum, latencyNum, channelNum));
            statistic.amplitude(frequencyNum, latencyNum, channelNum) = p;
            [h, p] = ttest(latencyTotal1(:,frequencyNum, latencyNum,channelNum), latencyTotal2(:,frequencyNum, latencyNum, channelNum));
            statistic.latency(frequencyNum, latencyNum, channelNum) = p;
        end
    end
end

cd(file.outputDir);
save(file.outputName, 'statistic');
end