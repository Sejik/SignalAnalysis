%% dipole simulation
% designed by Sejik Park (Korea University Undergraduated)
% using fieldtrip toolbox

%%
clc; clear;

%% Parameter
filename = 'pTIN_su0001.vhdr';

%% Read file
% read file
cfg = [];
cfg.dataset = filename;
data_raw = ft_preprocessing(cfg);

% read VEOG
cfg = [];
cfg.dataset = filename;
cfg.channel    = {'Fp1', 'EOG'};
cfg.reref      = 'yes';
cfg.refchannel = 'EOG';
data_veog      = ft_preprocessing(cfg);

data_veog.label{1} = 'VEOG';
cfg = [];
cfg.channel = 'VEOG';
data_veog   = ft_preprocessing(cfg, data_veog);

% read HEOG
cfg = [];
cfg.dataset = filename;
cfg.channel = {'F7', 'F8'};
cfg.reref = 'yes';
cfg.refchannel = 'F8';
data_heog = ft_preprocessing(cfg);

data_heog.label{1} = 'HEOG';
cfg = [];
cfg.channel = 'HEOG';
data_heog   = ft_preprocessing(cfg, data_heog);

% EEG referenced with VEOG & HEOG
cfg = [];
data_eeg = ft_appenddata(cfg, data_raw, data_veog, data_heog);

% remove null
cfg = [];
chanindx = find(strcmp(data_eeg.label, 'Null'));
cfg.channel = [1:(chanindx-1) (chanindx+1):length(data_eeg.label)];
data_eeg = ft_preprocessing(cfg, data_eeg);

clearvars -except filename data_eeg

%% Segmentation
% read current event type
cfg = [];
cfg.dataset = filename;
cfg.trialdef.eventtype  = '?';
cfg = ft_definetrial(cfg);
% select event type
cfg.trialdef.eventtype = '?';
cfg.trialdef.prestim = 0.5;
cfg.trialdef.poststim = 1.5;
cfg = ft_definetrial(cfg);
% preprocessing
data_raw = ft_preprocessing(cfg);

% trigger based segmentation
cfg = [];
cfg.dataset = filename;
cfg.trialdef.pre = 500;
cfg.trialdef.post = 1000;
cfg.targetAns = 'S 12';
cfg.correctAns = 'S 62;';
cfg.correctRTmax = 1500;
cfg.trialfun = 'ft_trialfun_BA';
cfg  = ft_definetrial(cfg);
data = ft_preprocessing(cfg);

%% Frequency analysis
cfg              = [];
cfg.output       = 'pow';
cfg.channel      = 'Fp1';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 2:2:30;                         % analysis 2 to 30 Hz in steps of 2 Hz 
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
cfg.toi          = -0.5:0.05:1.5;                  % time window "slides" from -0.5 to 1.5 sec in steps of 0.05 sec (50 ms)
freq = ft_freqanalysis(cfg, data_raw);

%% Source model 
mrifile = 'subjectK.mri';
mri = ft_read_mri(mrifile);

cfg = [];
cfg.wrtie = 'no';
[segmentedmri] = ft_volumesegment(cfg, mri);

cfg = [];
cfg.method = 'singleshell';
headmodel = ft_prepare_headmodel(cfg, segmentedmri);

cfg = [];
cfg.grad = freqPost.grad;
cfg.headmodel = headmodel;
cfg.reducerank = 2;
cfg.channel = {'MEG', '-MLP31', '-MLO12'};
cfg.grid.resolution = 1;
cfg.grid.unit = 'cm';
[grid] = ft_prepare_leadfield(cfg);

cfg = [];
cfg.method = 'dics';
cfg.frequency = 18;
cfg.grid = grid;
cfg.headmodel = headmodel;
cfg.dics.projectnoise = 'yes';
cfg.dics.lambda = 0;
sourcePost_nocon = ft_sourceanalysis(cfg, freq);

mri = ft_read_mri('Subject01.mri');
mri = ft_volumerslice([], mri);

cfg = [];
cfg.downsample = 2;
cfg.parameter = 'avg.pow';
sourcePostInt_nocon = ft_sourceinterpolate(cfg, sourcePost_nocon, mri);

cfg = [];
cfg.method = 'slice';
cfg.funparameter = 'avg.pow';
figure
ft_sourceplot(cfg, sourcePostInt_nocon);













