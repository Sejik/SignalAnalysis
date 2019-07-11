% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% download bbci
% go into folder where there is startup_bbci_toolbox
cd 'C:/Users/user/Desktop/Min_Lab/bbci_public-master/bbci_public-master';
% set directory
MyDataDir = 'C:/Users/user/Desktop/Min_Lab/bbci_public-master/data';
MyTempDir = 'C:/Users/user/Desktop/Min_Lab/bbci_public-master/tmp';
% download toolbox (setting toolbox)
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);

%% set parameters
rawDir = 'SSVEP'; % read input directory (.eeg)
band = [2,40]; % frequency band
ival_spec = [-500 1500];  % segmentation range

verbose = 1; 
save_figs = 1; % 1: save picture

fig_dir = 'C:/Users/user/Desktop/Min_Lab/bbci_public-master/picture'; % figure save directory

fig_dir = fullfile(fig_dir, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end

%% initialize (read file name)
cd(fullfile(MyDataDir, rawDir));
eeg_files = dir('*.eeg'); % read all eeg file in raw directory
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = strrep(eeg_files(eegFileNum).name, '.eeg', ''); % eeg
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);
epos = cell(1, n_subjects);

%% load data
for eegFileNum = 1:n_subjects
    file = fullfile(rawDir, eeg_info(eegFileNum));
    [cnt, vmrk, hdr] = file_readBV(file);

    mnt= mnt_setElectrodePositions(cnt.clab); % data structure defining the electrode layout

    % classDef = {2:27; vmrk.className(2:27)};
    % mrk = mrk_defineClasses(vmrk, classDef); % remove garbage marker
    classDef =  {11, 12, 13, 14, 15, 16 ; 'a', 'b', 'c', 'd', 'e', 'f'}; % topdown class reanalyze (make two group) '¤¡' or not
    mrk = mrk_defineClasses(vmrk, classDef);

    % channel
    cnt = proc_selectChannels(cnt, {'not', '*EOG*', 'NULL*'} );

    % high pass filter
    db_attenuation = 30;
    hp_cutoff = 1;
    [z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(cnt.fs/2), 'high');
    epos{eegFileNum} = proc_filt(cnt, z,p,k);
    
    % Artifact rejection based on variance criterion
    mrk = reject_varEventsAndChannels(epos{eegFileNum}, mrk, ival_spec, 'verbose', 1);

    % Segmentation
    epos{eegFileNum}= proc_segmentation(epos{eegFileNum}, mrk, ival_spec);
end
clear classDef cnt db_attenuation eeg_info eegFileNum file hdr hp_cutoff k p z ;

%% compute spectral features

sampling_freq = epos{1}.fs;
fv = cell(1,n_subjects);
epo_spec = cell(1,n_subjects);
fft_window = hanning(2*sampling_freq);

fprintf('\n\n --- computing spectal features ---\n\n')
for sbj_idx=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
    % feature extraction: apply FFT
    % figure, plot(fft_window)
    
    epo_spec{sbj_idx} = proc_spectrum(epos{sbj_idx}, band, 'Win', fft_window, 'Step', sampling_freq*0.5);
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{sbj_idx}.x);
    n_classes = size(epo_spec{sbj_idx}.y,1);
    % reshape the channel-wise spectra to obtain feature vectors
    fv{sbj_idx} = proc_flaten(epo_spec{sbj_idx});

    % high pass filter the features
    hp_cutoff = 1 / 5;
    [b,a_corr] = butter(3, hp_cutoff, 'high');
    fv{sbj_idx}.x = filtfilt(b,a_corr,fv{sbj_idx}.x')';

end
freqs = epo_spec{sbj_idx}.t;
fprintf('done\n')

%% normalize features, compute linear classifier and classifier pattern

fprintf('\n\n --- computing classifier patterns ---\n\n')
patterns_cov = zeros(n_freq_bins, n_channels, n_classes, n_subjects);
patterns_corr = zeros(n_freq_bins, n_channels, n_classes, n_subjects);
patterns_corr_max_y = zeros(n_freq_bins, n_channels, n_subjects);
for n=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', n, n_subjects)
    
    % normalize features
    fv{n}.x = zscore(fv{n}.x')';
    % train classifier
    classifier = train_RLDAshrink(fv{n}.x, fv{n}.y);
    % get classifier output
    y = classifier.w' * fv{n}.x;
    y = y ./ repmat(std(y,[],2), [1, size(y,2)]);

    % compute pattern via covariance of classifier output with features
    a_cov = fv{n}.x * y';
    a_cov = reshape(a_cov, [n_freq_bins, n_channels, n_classes]);
    patterns_cov(:,:,:,n) = a_cov;
    
    % compute pattern via correlation of classifier output with features
    a_corr = zeros(n_freq_bins*n_channels, n_classes);
    for c_idx=1:n_classes
        R = corrcoef([y(c_idx,:)',fv{n}.x']);
        a_corr(:,c_idx) = R(1,2:end)';
    end
    a_corr = reshape(a_corr, [n_freq_bins, n_channels, n_classes]);
    patterns_corr(:,:,:,n) = a_corr;
    
    % compute pattern via correlation of classifier output with features
    R = corrcoef([max(y)',fv{n}.x']);
    a_corr_max_y = R(1,2:end)';
    a_corr_max_y = reshape(a_corr_max_y, [n_freq_bins, n_channels]);
    patterns_corr_max_y(:,:,n) = a_corr_max_y;
end
fprintf('done\n')


%% average patterns over subjects

patterns_cov_avg = squeeze(mean(patterns_cov,4));
patterns_corr_avg = squeeze(mean(patterns_corr,4));
patterns_corr_max_y_avg = squeeze(mean(patterns_corr_max_y,3));

%% plot patterns, averaged over channels

figure
rows = 2;
cols = 3;

pat = patterns_corr_avg;
% pat = patterns_cov_avg;

subplot(rows,cols,1:3)
bar(freqs, (squeeze(mean(pat,2))))
xlim(band)
legend(fv{1}.className)
xlabel('frequency [Hz]')
title({'classifier pattern, averaged across channels,', 'over full frequency spectrum'})

subplot(rows,cols, cols + 1)
[~,f_idx] = ismember( 5:0.5:7.5, freqs);
bar(freqs(f_idx), (squeeze(mean(pat(f_idx,:,:), 2))))
xlim(freqs(f_idx([1,end])) + 0.5*[-1,1])
xlabel('frequency [Hz]')
title({'classifier pattern,','over stimulation frequencies'})

subplot(rows,cols, cols + (2:3))
[~,f_idx] = ismember( 10:15, freqs);
bar(freqs(f_idx), (squeeze(mean(pat(f_idx,:,:), 2))))
xlim(freqs(f_idx([1,end])) + 0.5*[-1,1])
xlabel('frequency [Hz]')
title({'classifier pattern,','over first harmonics of stimulation frequencies'})

if save_figs
    fname = sprintf('classifier_pattern_avg_over_channels.png');
    saveas(gcf, fullfile(fig_dir, fname), 'png');
end

%% plot scalp maps, averaged over frequencies and classes

sc_opt = [];
sc_opt.ScalePos = 'none';
sc_opt.Contour = 0;

% CHOOSE THE FREQUENCIES OVER WHICH TO AVERAGE HERE
band_of_interest = [5:0.5:7.5 10:15]; % stim-frequencies and first harmonics
% band_of_interest = [5:0.5:7.5]; % only stim-frequencies
% band_of_interest = [10:15]; % only first harmonics
[~,f_idx] = ismember(band_of_interest, freqs);

pat = patterns_corr_avg;
% pat = patterns_cov_avg;

pat = max(pat, [], 3);

sc_opt = [];
% sc_opt.ScalePos = 'none';
sc_opt.Contour = 0;

figure
m = pat;
m = mean(m(f_idx, :, :),1); % average over frequency bins
m = mean(m,3); % average over classes
m = squeeze(m);
plot_scalp(mnt, m, sc_opt)
colormap jet
title('classifier pattern')

if save_figs
    fname = sprintf('classifier_pattern_avg_over_frequencies');
    saveas(gcf, fullfile(fig_dir, fname), 'png');
end

% figure
% rows = 1;
% cols = n_classes;
% for c_idx=1:n_classes
%     subplot(rows,cols,c_idx)
%     m = squeeze(mean(pat(f_idx, :, c_idx),1));
%     plot_scalp(mnt, m, sc_opt)
%     colormap jet
% end