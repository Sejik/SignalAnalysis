%% Title: Does pre-stimulus brain activity predict conscious awareness? (BIOMAG 2016 conference)
% designed by Sejik Park (Korea University Undergraduated)
% e-mail: sejik6307@gmail.com
% included: SejikPark_BIOMAG2016.pptx (method & result) & SejikPark_BIOMAG2016.m (commented)
% Submission deadline: 31st August

% Conference info.: http://mikexcohen.com/biomag_data_competition.html
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
    % Filter -> Formula Evaluator -> OcularCorrection -> Segmentation -> baseline correction -> artifact rejection -> average
% 2. 
% 3. 

%%



    
% epochs = zeros(length(trialinfo),1001,400);
% for triali=1:length(trialinfo)
%     onset = dsearchn(timevec,trialinfo(triali,4));
%     epochs(triali,:,:) = datare(onset-500:onset+500,:);
% end
% 
% load visualization.mat
% imagesc(brainimg), hold on
% scatter(locs(:,1),locs(:,2),120,squeeze(mean(epochs(:,600,:),1)),'filled')
% 
% plot3DPatch(1:400,1,400,400,0,0)

