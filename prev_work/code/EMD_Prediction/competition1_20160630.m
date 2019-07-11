%% BIOMAG 2016 Data analysis competition
% designed by Sejik Park, Korea Univ.
% e-mail: sejik6307@gmail.com

% Does pre-stimulus brain activity predict conscious awareness?
% Evaluation standard: R^2 (deviation) & novel (creative)

% related ocillation: posterior alpha
% data info
% datare, dataim, timevec
% trialinfo
% column 1: trial type (1=hit, 0=miss) 
% column 2: left-hand (1) or right-hand (2) stimulation 
% column 3: reaction time in seconds-after-stimulation onset (hist only) 
% column 4: trial onset time. You need this to create epochs, for example: 

clear; clc;

%% Parameter
% set path
megDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\BIOMAG\MEG'; % path of MEG data
visualizationDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\BIOMAG\Visualization'; visualization info
resultDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\BIOMAG\Result'; % save the result data
% parameter

%% initialize
cd(megDir);
eeg_files = dir('*.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name;
end

%% main
% read data
for dataNum = 1:length(eeg_info)
    cd(megDir);
    name = eeg_info{dataNum,1};
    eeg = load(name); % read file
end

%% Test
% hit 은 reaction time을 더해서 찾고, miss는 miss 끼리 (이유는 심리학 실험에서 찾기)

epochs = zeros(length(eeg.trialinfo)-1,1001,400); % trial * timepoint * channels
j = 1;
k = 1;
for triali=1:length(eeg.trialinfo)-1
    onset = dsearchn(eeg.timevec,eeg.trialinfo(triali,4));    
    epochs(triali,:,:) = eeg.datare(onset-500:onset+500,:);
    if eeg.trialinfo(triali,1) == 1
        hit_epochs(j,:,:) = eeg.datare(onset-500:onset+500,:);
        hit_RT(j) = eeg.trialinfo(triali,3);
        j = j + 1;
    else
        miss_epochs(k,:,:) = eeg.datare(onset-500:onset+500,:);
        k = k + 1;
    end
    
end



%% Visualization
cd (visualizationDir);
load visualization.mat
imagesc(brainimg), hold on
scatter(locs(:,1),locs(:,2),120,squeeze(mean(epochs(:,600,:),1)),'filled')

plot3DPatch(1:400,1,400,400,0,0)

















