%% designed by Sejik Park
% e-mail: sejik6307@gmail.com

%% Start
clear all; clc; close all;
fprintf('%s: SJ_totalResult start\n', datestr(now));

%% basic set up
global param;
param.channels = 4;
param.startLatency = -1.0;
param.endLatency = 5.8;
param.samplingRate = 256;
param.latencyBand = param.startLatency:1/param.samplingRate:param.endLatency;
param.lowFreq = 1.5;
param.highFreq = 50;
param.freqStep = 133;
param.freqBand = param.lowFreq:((param.highFreq-param.lowFreq)/(param.freqStep-1)):param.highFreq;
% function
param.cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
% parallel Wavelet
param.parallel = 0;
param.workersNum = 3;
% input
param.datDir = '/Users/sejik/Desktop/SJ_Wavelet/input/dat';
param.subInputDir = '/Users/sejik/Desktop/SJ_Wavelet/input/subinput';
param.subjectGroupInfo = 'VR_subjectGroupInfo.xlsx';
param.condition{1} = 'whole';
param.condition{2} = 'whole';
param.conditionInfo{1, 1} = {'_'};
param.conditionInfo{1, 2} = {'_'};
param.conditionInfo{1, 3} = {'_'};
param.conditionInfo{1, 4} = {'_'};
param.conditionInfo{1, 5} = {'_'};
param.conditionInfo{2, 1} = {'_'};
param.conditionInfo{2, 2} = {'_'};
param.conditionInfo{2, 3} = {'_'};
param.conditionInfo{2, 4} = {'_'};
param.conditionInfo{2, 5} = {'_'};
param.subCondition{1} = '_Acc';
param.subCondition{2} = '_Con';
param.subCondition{3} = '_Rest';
param.subCondition{4} = '_RestafterAcc';
param.subCondition{5} = '_RestafterCon';
param.rawChannel = {'frontal', 'central', 'parietal', 'occipital'};
param.wholeChannel = param.rawChannel;
param.interestChannel = { 'frontal', 'central', 'parietal', 'occipital'};
% output
param.outputDir = '/Users/sejik/Desktop/SJ_Wavelet/output';
% time
param.interestLatency{1} = [-1.0 5.8];
% param.interestLatency{2} = [-1.0 5.8];
param.interestLatencyName{1} = 'wholeLatency';
% param.interestLatencyName{2} = 'wholeLatency';
% param.individualFreq{1} = [1 3]; % delta
param.individualFreq{1} = [4 7]; % theta
param.individualFreq{2} = [8 13]; % alpha
% param.individualFreq{4} = [14 30]; % beta
% param.individualFreq{5} = [30 50]; % gamma
% param.individualFreq{6} = [1 50]; % whole
% param.freqName{1} = 'delta';
param.freqName{1} = 'theta';
param.freqName{2} = 'alpha';
% param.freqName{4} = 'beta';
% param.freqName{5} = 'gamma';
% param.freqName{6} = 'whole';
param.shiftLength = 0.5;
% autodatic path set up
param.subFunctionDir = '/Users/sejik/Desktop/SJ_Wavelet/subFunction';
param.subDataDir = '/Users/sejik/Desktop/SJ_Wavelet/subData';
addpath(genpath(param.subFunctionDir));
addpath(genpath(param.subDataDir));

%% Result list
global result;

%% read data
fprintf('%s: read data\n', datestr(now));
cd(param.datDir);
temp.subjectFiles = dir('*.dat');
for fileNum = 1:length(temp.subjectFiles)
    temp.inputFile{fileNum} = temp.subjectFiles(fileNum).name;
    temp.data = importdata(temp.inputFile{fileNum});
    result.fileName{fileNum} = temp.inputFile{fileNum};
    temp.data = temp.data.data;
    temp.realData = temp.data(:,1:2:size(temp.data,2));
    temp.imageData = temp.data(:,2:2:size(temp.data,2));
    temp.complexData = temp.realData + 1i * temp.imageData;
    temp.arrangedData = reshape(temp.complexData, size(temp.complexData,1), param.freqStep, size(temp.complexData,2)/param.freqStep);
    result.wavelet(fileNum, :, :, :) = permute(temp.arrangedData, [3, 1, 2]);
end
 
param.lowFreq = 1.5;
param.highFreq = 24.6477;
param.freqStep = 64;
param.freqBand = param.freqBand(1:64);
result.wavelet = result.wavelet(:,:,:,1:64);

% param.lowFreq = 3.3371;
% param.highFreq = 7.7462;
% param.freqStep = 13;
% param.freqBand = param.freqBand(6:18);
% result.wavelet = result.wavelet(:,:,:,6:18);

% param.lowFreq = 8.1136;
% param.highFreq = 14.7273;
% param.freqStep = 19;
% param.freqBand = param.freqBand(19:37);
% result.wavelet = result.wavelet(:,:,:,19:37);

clearvars -except param result

cd(param.subInputDir);
[temp.num,temp.title,~] = xlsread(param.subjectGroupInfo);
temp.title(1) = [];
result.groupName = temp.title;
for subjectNum = 1:length(temp.num)
    if size(num2str(temp.num(subjectNum,1)), 2) == 1
        temp.subjectName{subjectNum} = strcat('su0', num2str(temp.num(subjectNum,1)));
    else
        temp.subjectName{subjectNum} = strcat('su', num2str(temp.num(subjectNum,1)));
    end
end
temp.num(:,1) = [];
for subjectNum = 1:length(temp.subjectName)
    for subjectGroupNum = 1:length(result.groupName)
        temp.responseList = temp.num(:,subjectGroupNum);
        temp.responseList = unique(temp.responseList);
        temp.responseList(isnan(temp.responseList)) = [];
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
            break;
        elseif strfind(result.fileName{fileNum}, strrep(temp.subjectName{subjectNum}, 'su', 'su00'))
            temp.fileSubject(:, :) = squeeze(temp.groupSubject(subjectNum, :, :));
            break;
        else
            temp.fileSubject(:, :) = zeros(size(squeeze(temp.groupSubject(subjectNum, :, :))));
        end
    end
    for conditionNum1 = 1:size(param.conditionInfo, 1)
        for conditionNum2 = 1:size(param.conditionInfo, 2)
            for conditionNum = 1:length(param.conditionInfo{conditionNum1, conditionNum2})
                if strfind(result.fileName{fileNum}, param.conditionInfo{conditionNum1, conditionNum2}(conditionNum))
                    temp.fileCondition(conditionNum1, conditionNum2) = 1;
                    break;
                else
                    temp.fileCondition(conditionNum1, conditionNum2) = 0;
                end
            end
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
        for conditionNum = 1:length(temp.fileCondition(:))
            for subConditionNum = 1:length(temp.fileSubCondition(:))
                temp.productFileGroup(subjectNum, conditionNum, subConditionNum) = ...
                    temp.fileSubject(subjectNum) * temp.fileCondition(conditionNum) * temp.fileSubCondition(subConditionNum);
            end
        end
    end
    temp.fileGroup(fileNum,:,:,:,:,:) = reshape(temp.productFileGroup, [size(temp.fileSubject), size(temp.fileCondition), size(temp.fileSubCondition)]);
end
for subConditionNum = 1:size(temp.fileGroup, 5)
    result.fileGroup(:,:,:,:,subConditionNum) = ...
        squeeze(temp.fileGroup(:,:,:,:,subConditionNum,subConditionNum));
end
clearvars -except param result

%% Plot
fprintf('%s: plot\n', datestr(now));
cd(param.outputDir);
title0 = 'Wavelet';
scrsz = get(groot,'ScreenSize');
for subjectGroupNum = 1:2 %length(result.groupName)
    for conditionNum = 1:1
        for subConditionNum = 1:size(result.fileGroup, 5)
            for responseNum = 1:size(result.fileGroup, 3)
                currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                wavelet{responseNum} = result.wavelet(logical(currentFile),:,:,:);
            end
            
            % figure('Position', [1 scrsz(4) scrsz(3) scrsz(4)]);
            title00 = strcat(title0, '_', result.groupName{subjectGroupNum}, '_', param.condition{conditionNum}, param.subCondition{subConditionNum});
            title3 = strcat(title00, '.png');
            title1 = strcat(title00, '_1.png');
            title2 = strcat(title00, '_2.png');
            
            for interestChanNum = 1:length(param.interestChannel)
                for responseNum = 1:1
                    currentPosition = interestChanNum;
                    notAveragedData1 = permute(squeeze(abs(wavelet{responseNum}(:, interestChanNum, :, :)).^2), [1 3 2]);
                    notAveragedData2 = permute(squeeze(abs(wavelet{responseNum+1}(:, interestChanNum, :, :)).^2), [1 3 2]);
                    notAveragedData1(isnan(notAveragedData1)) = 0;
                    notAveragedData2(isnan(notAveragedData2)) = 0;
                    cfs1 = squeeze(mean(notAveragedData1,1,'omitnan'));
                    cfs2 = squeeze(mean(notAveragedData2,1,'omitnan'));
                    cfs = cfs2 - cfs1;
                    time = param.latencyBand;
                    freq = param.freqBand';
                    
                    args1 = {time,freq,cfs1};
                    figure(1);
                    subplot(length(param.interestChannel), 1, currentPosition);
                    surf(args1{:},'edgecolor','none');
                    view(0,90);
                    axis tight;
                    shading interp;
                    colormap(jet);
                    h = colorbar;
                    set(gca, 'CLim', [0 4.5]);
                    if interestChanNum == length(param.interestChannel)
                        saveas(gcf, title1);
                    end
                    
                    args1 = {time,freq,cfs2};
                    figure(2);
                    subplot(length(param.interestChannel), 1, currentPosition);
                    surf(args1{:},'edgecolor','none');
                    view(0,90);
                    axis tight;
                    shading interp;
                    colormap(jet);
                    h = colorbar;
                    set(gca, 'CLim', [0 4.5]);
                    if interestChanNum == length(param.interestChannel)
                        saveas(gcf, title2);
                    end
                    
                    args = {time,freq,cfs};
                    figure(3);
                    subplot(length(param.interestChannel), 1, currentPosition);
                    surf(args{:},'edgecolor','none');
                    view(0,90);
                    axis tight;
                    shading interp;
                    colormap(jet);
                    h = colorbar;
                    % h.Label.String = 'Power';
                    % xlabel('Time');
                    % ylabel('Hz');
                    set(gca, 'CLim', [-4.5 4.5]);
                    hold on;
                    for latencyNum = 1:floor((param.endLatency-param.startLatency)/param.shiftLength)
                        for freqNum = 1:length(param.individualFreq)
                            startTime = param.startLatency + param.shiftLength * (latencyNum-1);
                            endTime = param.startLatency + param.shiftLength * latencyNum;
                            interestTime = boolean((param.latencyBand>=startTime) .* (param.latencyBand<=endTime));
                            
                            startFreq = param.individualFreq{freqNum}(1);
                            endFreq = param.individualFreq{freqNum}(2);
                            interestFreq = boolean((param.freqBand>=startFreq) .* (param.freqBand<=endFreq));
                            
                            statisticData1 = squeeze(mean(max(notAveragedData1(:,interestFreq,interestTime), [], 2),3));
                            statisticData2 = squeeze(mean(max(notAveragedData2(:,interestFreq,interestTime), [], 2),3));
                            p = ranksum(statisticData1, statisticData2);
                            if p <= 0.05
                                lineColor = 'y';
                                if p <= 0.01
                                    lineColor = 'r';
                                end
                                spX = param.latencyBand(find(interestTime, 1, 'first'));
                                spY = param.freqBand(find(interestFreq, 1, 'first'));
                                epX = param.latencyBand(find(interestTime, 1, 'last'));
                                epY = param.freqBand(find(interestFreq, 1, 'last'));
                                SJ_significantRectangle(spX, spY, epX, epY, lineColor);
                            end
                        end
                    end
                    if interestChanNum == length(param.interestChannel)
                        saveas(gcf, title3);
                    end
                end
            end
        end
    end
end

for subjectGroupNum = 3
    for conditionNum = 1:1
        for subConditionNum = 1:size(result.fileGroup, 5)
            for responseNum = 1:1
                currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                wavelet = result.wavelet(logical(currentFile),:,:,:);
            end
            
            % figure('Position', [1 scrsz(4) scrsz(3) scrsz(4)]);
            title00 = strcat(title0, '_', result.groupName{subjectGroupNum}, '_', param.condition{conditionNum}, param.subCondition{subConditionNum});
            title1 = strcat(title00, '.png');
            
            for interestChanNum = 1:length(param.interestChannel)
                for responseNum = 1:1
                    currentPosition = interestChanNum;
                    notAveragedData1 = permute(squeeze(abs(wavelet(:, interestChanNum, :, :)).^2), [1 3 2]);
                    notAveragedData1(isnan(notAveragedData1)) = 0;
                    cfs1 = squeeze(mean(notAveragedData1,1,'omitnan'));
                    time = param.latencyBand;
                    freq = param.freqBand';
                    
                    args1 = {time,freq,cfs1};
                    figure(1);
                    subplot(length(param.interestChannel), 1, currentPosition);
                    surf(args1{:},'edgecolor','none');
                    view(0,90);
                    axis tight;
                    shading interp;
                    colormap(jet);
                    h = colorbar;
                    set(gca, 'CLim', [0 4.5]);
                    if interestChanNum == length(param.interestChannel)
                        saveas(gcf, title1);
                    end
                end
            end
        end
    end
end
clear wavelet;

%%
fprintf('%s: plot\n', datestr(now));
cd(param.outputDir);
title0 = 'Wavelet';
scrsz = get(groot,'ScreenSize');
for subjectGroupNum = 1:2 %length(result.groupName)
    for conditionNum = 1:1
        for responseNum = 1:size(result.fileGroup, 3)
            for subConditionNum = 1:size(result.fileGroup, 5)
                currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                wavelet{subConditionNum} = result.wavelet(logical(currentFile),:,:,:);
            end
            
            % figure('Position', [1 scrsz(4) scrsz(3) scrsz(4)]);
            title00 = strcat(title0, '_', result.groupName{subjectGroupNum}, '_', param.condition{conditionNum}, num2str(responseNum));
            
            for interestChanNum = 1:length(param.interestChannel)
                for subConditionNum = 1:2
                    title3 = strcat(title00, param.subCondition{subConditionNum}, '-',param.subCondition{subConditionNum+3}, '.png');
                    currentPosition = interestChanNum;
                    notAveragedData1 = permute(squeeze(abs(wavelet{subConditionNum}(:, interestChanNum, :, :)).^2), [1 3 2]);
                    notAveragedData2 = permute(squeeze(abs(wavelet{subConditionNum+3}(:, interestChanNum, :, :)).^2), [1 3 2]);
                    notAveragedData1(isnan(notAveragedData1)) = 0;
                    notAveragedData2(isnan(notAveragedData2)) = 0;
                    cfs1 = squeeze(mean(notAveragedData1,1,'omitnan'));
                    cfs2 = squeeze(mean(notAveragedData2,1,'omitnan'));
                    cfs = cfs1 - cfs2;
                    time = param.latencyBand;
                    freq = param.freqBand';
                    
                    args = {time,freq,cfs};
                    figure(3);
                    subplot(length(param.interestChannel), 1, currentPosition);
                    surf(args{:},'edgecolor','none');
                    view(0,90);
                    axis tight;
                    shading interp;
                    colormap(jet);
                    h = colorbar;
                    % h.Label.String = 'Power';
                    % xlabel('Time');
                    % ylabel('Hz');
                    set(gca, 'CLim', [-4.5 4.5]);
                    hold on;
                    for latencyNum = 1:floor((param.endLatency-param.startLatency)/param.shiftLength)
                        for freqNum = 1:length(param.individualFreq)
                            startTime = param.startLatency + param.shiftLength * (latencyNum-1);
                            endTime = param.startLatency + param.shiftLength * latencyNum;
                            interestTime = boolean((param.latencyBand>=startTime) .* (param.latencyBand<=endTime));
                            
                            startFreq = param.individualFreq{freqNum}(1);
                            endFreq = param.individualFreq{freqNum}(2);
                            interestFreq = boolean((param.freqBand>=startFreq) .* (param.freqBand<=endFreq));
                            
                            statisticData1 = squeeze(mean(max(notAveragedData1(:,interestFreq,interestTime), [], 2),3));
                            statisticData2 = squeeze(mean(max(notAveragedData2(:,interestFreq,interestTime), [], 2),3));
                            p = ranksum(statisticData1, statisticData2);
                            if p <= 0.05
                                lineColor = 'y';
                                if p <= 0.01
                                    lineColor = 'r';
                                end
                                spX = param.latencyBand(find(interestTime, 1, 'first'));
                                spY = param.freqBand(find(interestFreq, 1, 'first'));
                                epX = param.latencyBand(find(interestTime, 1, 'last'));
                                epY = param.freqBand(find(interestFreq, 1, 'last'));
                                SJ_significantRectangle(spX, spY, epX, epY, lineColor);
                            end
                        end
                    end
                    if interestChanNum == length(param.interestChannel)
                        saveas(gcf, title3);
                    end
                end
            end
            close all;
            
            for interestChanNum = 1:length(param.interestChannel)
                for subConditionNum = 1:1
                    title3 = strcat(title00, param.subCondition{subConditionNum}, '-',param.subCondition{subConditionNum+1}, '.png');
                    currentPosition = interestChanNum;
                    notAveragedData1 = permute(squeeze(abs(wavelet{subConditionNum}(:, interestChanNum, :, :)).^2), [1 3 2]);
                    notAveragedData2 = permute(squeeze(abs(wavelet{subConditionNum+1}(:, interestChanNum, :, :)).^2), [1 3 2]);
                    notAveragedData1(isnan(notAveragedData1)) = 0;
                    notAveragedData2(isnan(notAveragedData2)) = 0;
                    cfs1 = squeeze(mean(notAveragedData1,1,'omitnan'));
                    cfs2 = squeeze(mean(notAveragedData2,1,'omitnan'));
                    cfs = cfs1 - cfs2;
                    time = param.latencyBand;
                    freq = param.freqBand';
                    
                    args = {time,freq,cfs};
                    figure(3);
                    subplot(length(param.interestChannel), 1, currentPosition);
                    surf(args{:},'edgecolor','none');
                    view(0,90);
                    axis tight;
                    shading interp;
                    colormap(jet);
                    h = colorbar;
                    % h.Label.String = 'Power';
                    % xlabel('Time');
                    % ylabel('Hz');
                    set(gca, 'CLim', [-4.5 4.5]);
                    hold on;
                    for latencyNum = 1:floor((param.endLatency-param.startLatency)/param.shiftLength)
                        for freqNum = 1:length(param.individualFreq)
                            startTime = param.startLatency + param.shiftLength * (latencyNum-1);
                            endTime = param.startLatency + param.shiftLength * latencyNum;
                            interestTime = boolean((param.latencyBand>=startTime) .* (param.latencyBand<=endTime));
                            
                            startFreq = param.individualFreq{freqNum}(1);
                            endFreq = param.individualFreq{freqNum}(2);
                            interestFreq = boolean((param.freqBand>=startFreq) .* (param.freqBand<=endFreq));
                            
                            statisticData1 = squeeze(mean(max(notAveragedData1(:,interestFreq,interestTime), [], 2),3));
                            statisticData2 = squeeze(mean(max(notAveragedData2(:,interestFreq,interestTime), [], 2),3));
                            p = ranksum(statisticData1, statisticData2);
                            if p <= 0.05
                                lineColor = 'y';
                                if p <= 0.01
                                    lineColor = 'r';
                                end
                                spX = param.latencyBand(find(interestTime, 1, 'first'));
                                spY = param.freqBand(find(interestFreq, 1, 'first'));
                                epX = param.latencyBand(find(interestTime, 1, 'last'));
                                epY = param.freqBand(find(interestFreq, 1, 'last'));
                                SJ_significantRectangle(spX, spY, epX, epY, lineColor);
                            end
                        end
                    end
                    if interestChanNum == length(param.interestChannel)
                        saveas(gcf, title3);
                    end
                end
            end
        end
    end
end

%% End
close all;
fprintf('%s: SJ_totalResult end\n', datestr(now));