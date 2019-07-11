% This script computes and plots classifier patterns 


%% paramters

sbj_list = 1:14; % subject의 번호를 sbj_list에 저장해주시면 됩니다.
condition = 'bottom_up'; % 'bottom_up'. 'top_down', 'intermediate'를 넣어주시면 됩니다.
band = [2,40]; % 분석하고자 하는 band 범위를 저장해주시면 됩니다.

n_subjects = length(sbj_list); % subject의 수를 받아와 for loop 에 이용합니다.

verbose = 1; 
save_figs = 1; % 1이면 그림을 저장합니다.



fig_dir = 'C:/Users/user/Desktop/Min_Lab/bbci_public-master'; % 그림을 어디다 저장할 지 정해줍니다.

fig_dir = fullfile(fig_dir, 'new_data_new_format'); % 저장을 하는 경우 폴더를 하나 새로 만들어서 그 안에 넣어줍니다.
if save_figs && not(exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end


%% load the data

epos = cell(1,n_subjects);
for sbj_idx=1:n_subjects
    fprintf('loading subject %d\n', sbj_list(sbj_idx))
    
    % 기존에 입력했던 condition에 맞게 분석을 하게 됩니다.
    switch condition
        case 'top_down'
            epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(... % 저한테 이부분이 없습니다. load_SSVEP_Min_KU_data_new_format
                sbj_list(sbj_idx), 'TopDown', verbose);
        case 'bottom_up'
            epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
                sbj_list(sbj_idx), 'BottomUp', verbose);
        case 'intermediate'
            epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
                sbj_list(sbj_idx), 'Intermediate', verbose);
        otherwise
            error('condition = %s is unknown!', condition)
    end
    
    % channel 중에서 EOG와 NULL을 제거해 줍니다.
    epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not', '*EOG*', 'NULL*'});
    
    % high pass filter
    db_attenuation = 30;
    hp_cutoff = 1;
    [z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
    epos{sbj_idx} = proc_filt(epos{sbj_idx}, z,p,k);
end

mnt = mnt_setElectrodePositions(epos{1}.clab);
grd= sprintf(['scale,Fp1,_,Fp2,legend\n' ...
              'F7,F3,Fz,F4,F8\n' ...
              'FC5,FC1,FCz,FC2,FC6\n' ...
              'T7,C3,Cz,C4,T8\n' ...
              'CP5,CP1,CPz,CP2,CP6\n' ...
              'P7,P3,Pz,P4,P8\n' ...
              'PO9,O1,Oz,O2,PO10' ...
              ]);
mnt= mnt_setGrid(mnt, grd);


%% compute spectral features

sampling_freq = epos{1}.fs;
fv = cell(1,n_subjects);
epo_spec = cell(1,n_subjects);
fft_window = hanning(2*sampling_freq);

fprintf('\n\n --- computing spectal features ---\n\n')
for sbj_idx=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, _subjects)
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
    y = y ./ repmat(std(y,[],2), [1, n_epos]);

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
    fname = sprintf('%s__classifier_pattern_avg_over_channels', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 35, 20)
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
    fname = sprintf('%s__classifier_pattern_avg_over_frequencies', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 15, 15)
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
