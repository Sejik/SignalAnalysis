%% designed by Sejik Park
% e-mail: sejik6307@gmail.com

%% Start
clear all; clc; close all;
fprintf('%s: SJ_totalResult start\n', datestr(now));

%% basic set up
global param;
% result
param.source = 1;
param.erp = 0;
param.fft = 0;
param.wavelet = 0;
param.dipole = 0;
param.cfc = 0;
param.dtf = 0;
param.questionnaire = 0;
param.savePPT = 0;
param.statistic = 0;
param.saveExcel = 0;
param.grandDTFmovie = 1;
param.individualDTFmovie = 0;
param.saveResult = 0;
% function
param.cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
% parallel toolbox
param.parallel = 0;
param.workersNum = 3;
% input
param.datDir = 'C:\Users\win\Desktop\SJ_toolbox\input\dat';
param.subInputDir = 'C:\Users\win\Desktop\SJ_toolbox\input\subinput';
param.subjectGroupInfo = 'VR_subjectGroupInfo.xlsx';
param.condition{1} = 'All_forward';
param.condition{2} = 'All_forward';
param.conditionInfo{1, 1} = {'_'};
param.conditionInfo{1, 2} = {'_'};
param.conditionInfo{1, 3} = {'_'};
param.conditionInfo{2, 1} = {'_'};
param.conditionInfo{2, 2} = {'_'};
param.conditionInfo{2, 3} = {'_'};
param.fs = 256;
param.totalLength = 6.8;
param.epochLength = ceil(param.fs * param.totalLength);
param.zeroLatency = 1.0;
param.subCondition{1} = 'Acc';
param.subCondition{2} = 'Con';
param.subCondition{3} = 'Rest';
param.rawChannel = {'Fp1','Fp2','F7','F3','Fz', ...
                      'F4','F8','FC5','FC1','FC2', ...
                      'FC6','T7','C3','Cz','C4','T8', ...
                      'CP5','CP1','CP2','CP6','P7',...
                      'P3','Pz','P4','P8','PO9', ...
                      'O1','Oz','O2','PO10'};
param.channelGroup{1} = {'F3', 'Fz', 'F4'};
param.channelGroup{2} = {'C3', 'Cz', 'C4'};
param.channelGroup{3} = {'O1', 'Oz', 'O2'};
param.channelGroup{4} = {'P3', 'Pz', 'P4'};
param.channelGroup{5} = {'Pz', 'CP1', 'CP2'};
param.channelGroup{6} = {'Cz', 'FC1', 'FC2'};
param.channelGroup{7} = {'FC1', 'FC2', 'Cz', 'CP1', 'CP2'};
param.channelGroup{8} = {'Cz', 'CP1', 'CP2', 'Pz', 'P3', 'P4'};
param.channelGroupName{1} = 'frontal';
param.channelGroupName{2} = 'central';
param.channelGroupName{3} = 'parietal';
param.channelGroupName{4} = 'occipital';
% param.channelGroupName{5} = 'centro-parietal';
% param.channelGroupName{6} = 'fronto-central';
% param.channelGroupName{7} = 'fronto-centro-parietal';
% param.channelGroupName{8} = 'centro-parietal-2';
param.wholeChannel = [param.rawChannel, param.channelGroupName];
param.interestChannel = {'Fp1','Fp2','F7','F3','Fz', ...
                      'F4','F8','FC5','FC1','FC2', ...
                      'FC6','T7','C3','Cz','C4','T8', ...
                      'CP5','CP1','CP2','CP6','P7',...
                      'P3','Pz','P4','P8','PO9', ...
                      'O1','Oz','O2','PO10', ...
                      'frontal', 'central', 'parietal', 'occipital'}; %, ...
    %'centro-parietal', 'fronto-central', 'fronto-centro-parietal', 'centro-parietal-2'};
% output
param.outputDir = 'C:\Users\win\Desktop\SJ_toolbox\output';
% source
param.roiRadius = 10;
param.roi = [-44,-62,1;14,-80,27;20,-58,45;49,-35,18;31,1,58;-14,-81,22;-23,-56,44;-50,-38,18;-31,-3,57;45,-59,3];
param.roiName = {'MT_L','V6_R','VIP_R','PIVC_R','FEF_R','V6_L','VIP_L','PIVC_L','FEF_L','MT_R'};
% time
param.interestLatency{1} = [-1.0 0.0];
param.interestLatency{2} = [0.0 2.0];
param.interestLatency{3} = [0.0 5.8];
param.interestLatencyName{1} = 'pre';
param.interestLatencyName{2} = 'short_post';
param.interestLatencyName{3} = 'long_post';
% frequency
param.interestFreq = [1 50];
% erp
% fft
param.individualFreq{1} = [1 3]; % delta
param.individualFreq{2} = [4 7]; % theta
param.individualFreq{3} = [8 13]; % alpha
param.individualFreq{4} = [14 30]; % beta
param.individualFreq{5} = [30 50]; % gamma
param.individualFreq{6} = [1 50]; % whole
param.freqName{1} = 'delta';
param.freqName{2} = 'theta';
param.freqName{3} = 'alpha';
param.freqName{4} = 'beta';
param.freqName{5} = 'gamma';
param.freqName{6} = 'whole';
% wavelet
param.freqStep = 0.5;
param.freqs = param.interestFreq(1):param.freqStep:param.interestFreq(2);
% dipole
param.conditionVHDR = 'VR_su0001_Average_Acc.vhdr';
param.controlPoint{1} = [-52 -20 9]; % Left Primary Auditory
param.controlPoint{2} = [50 -21 7]; % Right Primary Auditory
% CFC
param.phaseBand = [4 7];
param.amplitudeBand = [30 50];
% DTF
param.axis = 0;
param.surrogateNum = 20;
param.threshold = 1/2;
% questionnaire
param.questionnaireInfo = 'VR_quistionnaire.xlsx';
% statistic
% plot
param.lineWidth = 3;
param.color{1,1} = [255/255 32/255 32/255];
param.color{1,2} = [255/255 191/255 200/255];
param.color{2,1} = [54/255 54/255 54/255];
param.color{2,2} = [180/255 180/255 180/255];
param.color{3,1} = [76/255 165/255 76/255];
param.color{3,2} = [174/255 242/255 174/255];
param.plotERPfilter = 20;
param.averageDTF = 1;
param.individualMoiveDTF = 0;
% ppt
param.pptDir = 'C:\Users\win\Desktop\SJ_toolbox\ppt';
param.clearppt = 'clear.pptx';
param.picture = 'temp.png';
param.outfileppt = 'VR.ppt';
% DTF moive
param.windowLength = 0.9;
param.shiftLength = 0.015;
param.movieThreshold = 9/10;
% autodatic path set up
param.subFunctionDir = 'C:\Users\win\Desktop\SJ_toolbox\subFunction';
param.subDataDir = 'C:\Users\win\Desktop\SJ_toolbox\subData';
addpath(genpath(param.subFunctionDir));
addpath(genpath(param.subDataDir));

%% Result list
global result;

%% Parallel toolbox
if param.parallel
    fprintf('%s: parallel toolbox\n', datestr(now));
    temp.myCluster = parcluster('local');
    temp.myCluster.NumWorkers = param.workersNum;
    saveProfile(temp.myCluster);
    param.POOL = parpool('local', param.workersNum);
    clearvars -except param result
end

%% read data
fprintf('%s: read data\n', datestr(now));
cd(param.datDir);
temp.subjectFiles = dir('*.dat');
for fileNum = 1:length(temp.subjectFiles)
    temp.inputFile{fileNum} = temp.subjectFiles(fileNum).name;
    temp.data = importdata(temp.inputFile{fileNum});
    result.fileName{fileNum} = temp.inputFile{fileNum};
    result.raw(fileNum, :, :) = shiftdim(temp.data.data,1);
end
temp.raw = result.raw;
for additionalChanNum = 1:length(param.channelGroup)
    temp.currentNum = length(param.rawChannel) + additionalChanNum;
    for groupChannelNum = 1:length(param.channelGroup{additionalChanNum})
        groupChannel(groupChannelNum) = find(cellfun(param.cellfind(param.channelGroup{additionalChanNum}{groupChannelNum}), param.rawChannel));
    end
    result.raw(:, temp.currentNum, :) = squeeze(mean(result.raw(:, groupChannel, :),2));
end
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

%% Source
if param.source
    fprintf('%s: Source\n', datestr(now));
    [A, B] = SJ_source(param, result.raw);
    if size(result.raw,3) == (size(B, 3) + 1)
        B(:,:,size(B,3)+1) = B(:,:,size(B,3));        
    end
    result.roi = A;
    result.raw(:, (length(param.wholeChannel)+(1:length(param.roi))), :) = B;
    param.wholeChannel = [param.rawChannel, param.channelGroupName, param.roiName];
end
clearvars -except param result

%% ERP
if param.erp
    fprintf('%s: ERP\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        result.erp(:, :,interestLatencyNum) = ...
            mean(result.raw(:, :, temp.currentLatency(1):temp.currentLatency(2)), 3);
        clear temp;
    end
    clearvars -except param result
end

%% FFT
if param.fft
    fprintf('%s: FFT\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.fft(:,:,:,interestLatencyNum) = SJ_fft(param, result.raw(:, :, temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.fft = permute(temp.fft, [1 2 4 3]);
    result.fftIndividualFreq = SJ_individualFreq(param, result.fft);
    clearvars -except param result 
end

%% Wavelet
if param.wavelet
    fprintf('%s: Wavelet\n', datestr(now));
    result.wavelet = SJ_wavelet(param, result.raw);
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.waveletIndividualLatency(:,:,:,interestLatencyNum)= SJ_individualLatency(param, result.wavelet(:,:,temp.currentLatency(1):temp.currentLatency(2),:));
    end
     result.waveletIndividualLatency = permute(temp.waveletIndividualLatency, [1 2 4 3]);
    clearvars -except param result
end

%% Dipole
if param.dipole
    fprintf('%s: Dipole\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        [temp.dipole(:, :, :, interestLatencyNum), ...
                    result.dipoleDistance(:, interestLatencyNum)] = ...
                    SJ_dipoleFitting(param, temp, result.raw(:, 1:length(param.rawChannel), temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.dipole = permute(temp.dipole, [1 4 2 3]);
    clearvars -except param result
end

%% CFC
if param.cfc
    fprintf('%s: CFC\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.cfc(:, :, :, :, interestLatencyNum) = ...
            SJ_cfc(param, result.raw(:, :, temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.cfc = permute(temp.cfc, [1 2 5 3 4]);
    result.individualCFC = squeeze(max(max(result.cfc, [], 4), [], 5));
    clearvars -except param result
end

%% DTF
if param.dtf
    fprintf('%s: DTF\n', datestr(now));
    for interestLatencyNum = 1:length(param.interestLatency)
        temp.currentLatency = floor((param.interestLatency{interestLatencyNum} + param.zeroLatency) * param.fs);
        temp.currentLatency(1) = temp.currentLatency(1) + 1;
        temp.dtf(:, :, :, :, interestLatencyNum) = ...
            SJ_dtf(param, result.raw(:, (length(param.wholeChannel)-(length(param.roi)-1:-1:0)), temp.currentLatency(1):temp.currentLatency(2)));
    end
    result.dtf = permute(temp.dtf, [1 5 2 3 4]);
    result.individualDTF = SJ_individualDTF(param, result.dtf);
    clearvars -except param result
end

%% Questionnaire
if param.questionnaire
    fprintf('%s: Questionnaire\n', datestr(now));
    cd(param.subInputDir);
    [temp.num,temp.title,~] = xlsread(param.questionnaireInfo);
    temp.title(1) = [];
    result.questionnaireName = temp.title;
    for subjectNum = 1:length(temp.num)
        if size(num2str(temp.num(subjectNum,1)), 2) == 1
            temp.subjectName{subjectNum} = strcat('su0', num2str(temp.num(subjectNum,1)));
        else
            temp.subjectName{subjectNum} = strcat('su', num2str(temp.num(subjectNum,1)));
        end
    end
    temp.num(:,1) = [];
    for subjectNum = 1:length(temp.subjectName)
        for subjectGroupNum = 1:length(result.questionnaireName)
            temp.responseList = temp.num(:,subjectGroupNum);
            temp.responseList = unique(temp.responseList);
            temp.responseList(isnan(temp.responseList)) = [];
            result.questionnaireList{subjectGroupNum} = temp.responseList;
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
        for subConditionNum = 1:length(param.subCondition)
            if strfind(result.fileName{fileNum}, param.subCondition{subConditionNum})
                temp.fileSubCondition(subConditionNum) = 1;
            else
                temp.fileSubCondition(subConditionNum) = 0;
            end
        end
        for subjectNum = 1:length(temp.fileSubject(:))
            for subConditionNum = 1:length(temp.fileSubCondition(:))
                temp.productFileGroup(subjectNum, subConditionNum) = ...
                    temp.fileSubject(subjectNum) * temp.fileSubCondition(subConditionNum);
            end
        end
        result.questionnaire(fileNum,:,:,:) = reshape(temp.productFileGroup, [size(temp.fileSubject), size(temp.fileSubCondition)]);
    end
    clearvars -except param result
end

%% PPT (Plot)
if param.savePPT
    fprintf('%s: PPT (Plot)\n', datestr(now));
    cd(param.pptDir);
    param.clearppt = fullfile(param.pptDir, param.clearppt);
    param.picture = fullfile(param.pptDir, param.picture);
    param.outfileppt = fullfile(param.pptDir, param.outfileppt);
    SJ_plot(param, result);
    clearvars -except param result
end

%% Statistic
if param.statistic
    fprintf('%s: Statistic\n', datestr(now));
    result.statistic = SJ_statistic(result);
    clearvars -except param result
end

%% Excel (Statistic)
if param.saveExcel
    fprintf('%s: Excel (Statistic)\n', datestr(now));
    cd(param.outputDir);
    SJ_excel(param, result);
    clearvars -except param result
end

%% grand_sDTF
if param.grandDTFmovie
    fprintf('%s: grandDTFmoive\n', datestr(now));
    cd(param.outputDir);
    SJ_granddtfMovie(param, result);
    clearvars -except param result
end

%% individual_sDTF
if param.individualDTFmovie
    fprintf('%s: individualDTFmovie\n', datestr(now));
    windowLength = ceil(param.windowLength*param.fs);
    shiftLength = ceil(param.shiftLength*param.fs);
    for dtfEpoch = 1:floor((param.epochLength-windowLength + 1)/shiftLength)
        startPoint = floor((dtfEpoch-1)*shiftLength + 1);
        endPoint = floor((dtfEpoch-1)*shiftLength + windowLength);
        temp.sdtf(:, :, :, :, dtfEpoch) = ...
            SJ_dtf(param, result.raw(:,(length(param.wholeChannel)-(length(param.roi)-1:-1:0)),startPoint:endPoint));
    end
    result.sdtf = permute(temp.sdtf, [1 5 2 3 4]);
    clearvars -except param result
    fprintf('%s: sDTF_individualMoive\n', datestr(now));
    cd(param.outputDir);
    SJ_dtfMovie(param, result);
    clearvars -except param result
end

%% Result (Mat)
if param.saveResult
    fprintf('%s: Result\n', datestr(now));
    cd(param.outputDir);
    save('result.mat', 'param', 'result', '-v7.3');
    clearvars -except param result 
end

%% End
fprintf('%s: SJ_totalResult end\n', datestr(now));