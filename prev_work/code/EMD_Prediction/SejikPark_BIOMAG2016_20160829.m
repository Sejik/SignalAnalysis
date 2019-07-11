%% BIOMAG 2016 conference
% Does pre-stimulus brain activity predict conscious awareness?
% designed by Sejik Park (Korea University Undergraduated)
% e-mail: sejik6307@gmail.com

% Submission info
% Included:
    % SejikPark_BIOMAG2016.pptx (method & result)
    % SejikPark_BIOMAG2016.m (commented)
% Submission deadline: 31st August
% Organizers (listed alphabetically):
    % Mike X Cohen: mikexcohen@gmail.com
    % Karim Jerbi: karim.jerbi@umontreal.ca 
    % Matias Palva: matias.palva@helsinki.fi

% Conference info: http://mikexcohen.com/biomag_data_competition.html
% find pre-stimulus info (predict behavioral, upcoming stimuli): posterior alhpa oscillation
% MEG study: somatosensory stimulation -> source reconstructed level (9 datasets: each 30 minutes)
% quantitative: variance (R2), perceptual accuracy (hits + correction rejection vs. false alarms + misses)
% qualitative: novel, creative (neurophysiologically interpretation)

% Data info
% column 1: trial type (1=hit, 0=miss) 
% column 2: left-hand (1) or right-hand (2) stimulation 
% column 3: reaction time in seconds-after-stimulation onset (hist only) 
% column 4: trial onset time. You need this to create epochs

% contents
% 0. load data
% 1. preprocessing
    % baseline correction -> artifact rejection by ICA & PCA
% 2. main
    % t-SNE
    % circle regression
% 3. save result
    % variance (R2), perceptual accuracy
    % (hits + correction rejection vs. false alarms + misses)

%% Before process
clear; clc;

%% Parameters
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\BIOMAG\Test';
stimulusBeforeEpochLength = 500;
stimulusAfterEpochLength = 0;
PVALrejectPercent = 0.8;

%% 0. load data
cd(rawDir);
meg_files = dir('*.mat');

for megFileNum = 1:length(meg_files)
    load(meg_files(megFileNum).name);
    megData(megFileNum).dataim = dataim;
    megData(megFileNum).datare = datare;
    megData(megFileNum).timevec = timevec;
    megData(megFileNum).trialinfo = trialinfo;
    epochs = zeros(length(trialinfo),stimulusBeforeEpochLength + stimulusAfterEpochLength + 1,400);
    for triali=1:length(trialinfo)
        onset = dsearchn(timevec,trialinfo(triali,4));
        if onset-stimulusBeforeEpochLength > 0 && onset+stimulusAfterEpochLength < length(datare)
            epochs(triali,:,:) = datare(onset-stimulusBeforeEpochLength:onset+stimulusAfterEpochLength,:);
        else
            megData(megFileNum).trialinfo(triali,:)= [];
        end        
    end
    megData(megFileNum).epochs = epochs;
end
clearvars -except megData stimulusBeforeEpochLength stimulusAfterEpochLength PVALrejectPercent

%% 1. Preprocessing
% baseline correction
for megFileNum = 1:length(megData)
    meanData = mean(megData(megFileNum).epochs(:,1:stimulusBeforeEpochLength,:),2);
    baseLineCorrectedData = megData(megFileNum).epochs - repmat(meanData,1,size(megData(megFileNum).epochs,2));
    megData(megFileNum).epochs = baseLineCorrectedData;
end
clearvars -except megData stimulusBeforeEpochLength stimulusAfterEpochLength PVALrejectPercent
    
% artifact rejection by EMD & pearson correlation
for megFileNum = 1:length(megData)
    for epochNum = 1:size(megData(megFileNum).epochs, 1)
        for channelNum = 1:size(megData(megFileNum).epochs, 3)
            emd{channelNum} = rParabEmd__L(megData(megFileNum).epochs(epochNum, :, channelNum), 50, 50, 1);
        end
        for emdNum = 1:length(emd)
            emdSize(emdNum) = size(emd{emdNum}, 2);
        end
        for corrNum = 1:min(emdSize)
            for emdNum = 1:length(emd)
                corrTemp(:, emdNum) = emd{emdNum}(:,corrNum);
            end
            [RHO, PVAL] = corr(corrTemp);
            corrPVAL(corrNum) = length(RHO(PVAL<0.05))/(size(RHO,1)*size(RHO,2));
        end
        highCorrArtifact = find((corrPVAL > PVALrejectPercent)==1);
        for emdNum = 1:length(emd)
            if length(highCorrArtifact) ~= 0
                for removeNum = length(highCorrArtifact):1
                    emd{emdNum}(:, highCorrArtifact(removeNum)) = [];
                end
            end         
        end
        for channelNum = 1:length(emd)
            emdSum(:,channelNum) = sum(emd{channelNum}, 2);
        end
        megData(megFileNum).lessArtifactEpochs(epochNum,:,:) = emdSum;
        clear emd emdSum
    end    
end
clearvars -except megData
%% 2. main
% tSNE
for megFileNum = 1:length(megData)
    for epochNum = 1:size(megData(megFileNum).lessArtifactEpochs, 1)
        currentData = megData(megFileNum).lessArtifactEpochs(epochNum, :, :);
        currentData = shiftdim(reshape(currentData, size(currentData,2), size(currentData,3)), 1);
        if currentData ~= 0
            train_X = tsne(currentData);
            megData(megFileNum).tsneData(epochNum,:,:) = train_X;
        end        
    end
end
clearvars -except megData
% align data
for megFileNum = 1:length(megData)
    for tsneNum = 1:size(megData(megFileNum).tsneData, 1)
        currentData(megFileNum, tsneNum, :, :) = megData(megFileNum).tsneData(tsneNum, :, :);
        currentLabel(megFileNum, tsneNum) = megData(megFileNum).trialinfo(tsneNum, 1);
    end
end
currentData = reshape(currentData, size(currentData,1)*size(currentData,2), size(currentData,3), size(currentData,4));
currentLabel = reshape(currentLabel, size(currentLabel,1)*size(currentLabel,2), size(currentLabel,3), size(currentLabel,4));
clearvars -except megData currentData currentLabel

%% 3. save result
% circle fit
correctXTotal = currentData((currentLabel(:,1) == 1),:,1);
correctYTotal = currentData((currentLabel(:,1) == 1),:,2);
incorrectXTotal = currentData((currentLabel(:,1) == 0),:,1);
incorrectYTotal = currentData((currentLabel(:,1) == 0),:,2);
for channelNum = 1:size(currentData,2)
    correctX = correctXTotal(:,channelNum);
    correctY = correctYTotal(:,channelNum);
    incorrectX = incorrectXTotal(:,channelNum);
    incorrectY = incorrectYTotal(:,channelNum);    
    
    correctCircleParameter = [correctX correctY ones(size(correctX))]\-(correctX.^2+correctY.^2);
    % correctCircleCenter = [-.5*correctCircleParameter(1), -.5*correctCircleParameter(2)];
    correctCircleRadius = sqrt((correctCircleParameter(1)^2+correctCircleParameter(2)^2)/4-correctCircleParameter(3));
    incorrectCircleParameter = [incorrectX incorrectY ones(size(incorrectX))]\-(incorrectX.^2+incorrectY.^2);
    % incorrectCircleCenter = [-.5*incorrectCircleParameter(1), -.5*incorrectCircleParameter(2)];
    incorrectCircleRadius = sqrt((incorrectCircleParameter(1)^2+incorrectCircleParameter(2)^2)/4-incorrectCircleParameter(3));
    
    hitCount = 0;
    correctRejectionCount = 0;
    falseAlarmCount = 0;
    missCount = 0;    
    for epochNum = 1:length(currentData)
        x = currentData(epochNum, channelNum, 1);
        y = currentData(epochNum, channelNum, 2);
        correctDistance(epochNum) = (x^2+y^2+correctCircleParameter(1)*x+correctCircleParameter(2)*y+correctCircleParameter(3))^2; % correct SE
        incorrectDistance(epochNum) = (x^2+y^2+incorrectCircleParameter(1)*x+incorrectCircleParameter(2)*y+incorrectCircleParameter(3))^2; % incorrect SE
        if (incorrectDistance(epochNum) >= correctDistance(epochNum))
            if (currentLabel(epochNum) == 1)
                hitCount = hitCount + 1;
            else
                missCount = missCount + 1;
            end
        else            
            if (currentLabel(epochNum) == 0)
                correctRejectionCount = correctRejectionCount + 1;
            else
                falseAlarmCount = falseAlarmCount + 1;
            end
        end
    end
    correctSSE = sum(correctDistance);
    correctSST = (correctCircleRadius^2)*length(currentData);
    correctR2(channelNum) = correctSSE/correctSST;
    incorrectSSE = sum(incorrectDistance);
    incorrectSST = (incorrectCircleRadius^2)*length(currentData);
    incorrectR2(channelNum) = incorrectSSE/incorrectSST;
    accuracy(channelNum) = (hitCount + correctRejectionCount) / ((hitCount + correctRejectionCount) + (missCount + falseAlarmCount));
end

% variance (R2), perceptual accuracy (hits + correction rejection vs. false alarms + misses)
result.accuracy = accuracy;
result.correctR2 = correctR2;
result.incorrectR2 = incorrectR2;
[result.maxAccuracy, result.maxAccuracyChannelNum] = max(accuracy);
result.maxCorrectR2 = correctR2(result.maxAccuracyChannelNum);
result.maxIncorrectR2 = incorrectR2(result.maxAccuracyChannelNum);
save('SejikPark_BIOMAG2016', 'megData', 'result', '-v7.3');
clearvars -except megData result currentLabel

figure;
hold;
scatter(currentData((currentLabel(:,1) == 1), result.maxAccuracyChannelNum,1), ... 
    currentData((currentLabel(:,1) == 1), result.maxAccuracyChannelNum,2), ...
    'MarkerFaceColor', [0 0 1]);
scatter(currentData((currentLabel(:,1) == 0), result.maxAccuracyChannelNum,1), ... 
    currentData((currentLabel(:,1) == 0), result.maxAccuracyChannelNum,2), ...
    'MarkerFaceColor', [1 0 0]);
saveas(gcf, 'SejikPark_BIOMAG2016.png');