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
% channel selection (4 centers) -> individual average FFT (5 center
% frequency) -> EMD -> t-SNE
% 3. save result
% variance (R2), perceptual accuracy
% (hits + correction rejection vs. false alarms + misses)

function SejikPark_BIOMAG2016()
% clear before processes
clear; clc; close;

%% basic set up
fprintf('%s: SejikPark_BIOMAG2016 start\n', datestr(now));
% directory
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\BIOMAG\Test';
% basis parameter
stimulusBeforeEpochLength = 500;
stimulusAfterEpochLength = 0;
PVALrejectPercent = 0.8;

%% 0. load data
fprintf('%s: loading MEG data start\n', datestr(now));
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
    fprintf('%5.2f %% done \n', (megFileNum/length(meg_files)));
end
clearvars -except megData stimulusBeforeEpochLength stimulusAfterEpochLength PVALrejectPercent
fprintf('%s: loading MEG data end\n', datestr(now));

%% 1. Preprocessing
fprintf('%s: preprocessing(baseline correction) start\n', datestr(now));
% baseline correction
for megFileNum = 1:length(megData)
    meanData = mean(megData(megFileNum).epochs(:,1:stimulusBeforeEpochLength,:),2);
    baseLineCorrectedData = megData(megFileNum).epochs - repmat(meanData,1,size(megData(megFileNum).epochs,2));
    megData(megFileNum).epochs = baseLineCorrectedData;
end
clearvars -except megData stimulusBeforeEpochLength stimulusAfterEpochLength PVALrejectPercent
fprintf('%s: preprocessing(baseline correction) end\n', datestr(now));

fprintf('%s: preprocessing(EMD-PC artifact rejection) start\n', datestr(now));
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
            for removeNum = length(highCorrArtifact):1
                emd{emdNum}(:, highCorrArtifact(removeNum)) = [];
            end
        end
        for channelNum = 1:length(emd)
            emdSum(:,channelNum) = sum(emd{channelNum}, 2);
        end
        megData(megFileNum).lessArtifactEpochs(epochNum,:,:) = emdSum;
        clear emd emdSum
        fprintf('Epoch: %5.2f %% done \n', (epochNum/length(megData)));        
    end
    fprintf('Subject: %5.2f %% done \n', (megFileNum/length(megData)));
end
fprintf('%s: preprocessing(EMD-PC artifact rejection) end\n', datestr(now));
clearvars -except megData
%% 2. main
fprintf('%s: main(tSNE) start\n', datestr(now));
% tSNE
for megFileNum = 1:length(megData)
    for epochNum = 1:size(megData(megFileNum).epochs, 1)
        currentData = megData(megFileNum).epochs(epochNum, :, :);
        currentData = shiftdim(reshape(currentData, size(currentData,2), size(currentData,3)), 1);
        if currentData ~= 0
            train_X = tsne(currentData);
            megData(megFileNum).tsne(epochNum,:,:) = train_X;
        end
    end
end
clearvars -except megData
fprintf('%s: main(tSNE) end\n', datestr(now));

fprintf('%s: main(mean algorithm) start\n', datestr(now));
% center position of tSNE
for megFileNum = 1:length(megData)
    for tsneNum = 1:size(megData(megFileNum).tsne, 1)
        currentData(megFileNum, tsneNum, :, :) = megData(megFileNum).tsne(tsneNum, :, :);
        currentLabel(megFileNum, tsneNum) = megData(megFileNum).trialinfo(tsneNum, 1);
    end
end
fprintf('%s: main(mean algorithm) end\n', datestr(now));

%% 3. save result
fprintf('%s: saving result start\n', datestr(now));
% average
% variance (R2), perceptual accuracy (hits + correction rejection vs. false alarms + misses)


% visualization
% load visualization.mat
% imagesc(brainimg), hold on
% scatter(locs(:,1),locs(:,2),120,squeeze(mean(epochs(:,600,:),1)),'filled')
%
% plot3DPatch(1:400,1,400,400,0,0)
fprintf('%s: saving result end\n', datestr(now));
fprintf('%s: SejikPark_BIOMAG2016 end\n', datestr(now));
end