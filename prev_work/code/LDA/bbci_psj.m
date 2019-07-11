%% download bbci
% go into folder where there is startup_bbci_toolbox
cd 'C:/Users/user/Desktop/Min_Lab/bbci_public-master/bbci_public-master';
% set directory
MyDataDir = 'C:/Users/user/Desktop/Min_Lab/bbci_public-master/data';
MyTempDir = 'C:/Users/user/Desktop/Min_Lab/bbci_public-master/tmp';
% download toolbox (setting toolbox)
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);

%% Load data
file = 'SSVEP/SSVEP_NEW_su0001';
[cnt,vmrk, hdr] = file_readBV(file);

mnt= mnt_setElectrodePositions(cnt.clab); % data structure defining the electrode layout

% classDef = {2:27; vmrk.className(2:27)};
% mrk = mrk_defineClasses(vmrk, classDef); % remove garbage marker
classDef =  {15, 16:20 ; 'target', 'nontarget'}; % topdown class reanalyze (make two group) '¤¡' or not
mrk = mrk_defineClasses(vmrk, classDef);

%% artifact rejection & Segmentation & FFT
ival_spec = [-500 1500];  % segmentation range

% Artifact rejection based on variance criterion
mrk = reject_varEventsAndChannels(cnt, mrk, ival_spec, 'visualize',1, 'verbose', 1);

% Segmentation
spec= proc_segmentation(cnt, mrk, ival_spec);

% FFT
winlen= cnt.fs;
spec= proc_spectrum(spec, [5 40], kaiser(winlen*2,2)); % 0.5 step by winlen*2

%% caculate rLDA & get filter and pattern
trials = reshape (spec.x, 71*32, 80);
model = train_LDA(trials, spec.y);
w = model.w;

a = (w'*cov(trials'))';

filter = reshape(w, 71, 32);
pattern = reshape(a, 71, 32);

%% figure
% first channel pattern
figure;
hold on
plot(zscore(filter(1,:)), 'r')
plot(zscore(pattern(1,:)), 'g')
legend('filter', 'pattern')