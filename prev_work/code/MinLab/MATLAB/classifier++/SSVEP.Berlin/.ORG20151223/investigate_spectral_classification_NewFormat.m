
%% set some paramters

sbj_list = 1:14; % list of subject indices

% the experiment condition that is to be classified
condition = 'bottom_up';
% condition = 'top_down';
% condition = 'intermediate';


% the range of frequencies to be considered as features
band = [4,30];


n_subjects = length(sbj_list);

verbose = 1; 
save_figs = 1; % save figures or not

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
fig_dir = '/home/sven/data/Results/SSVEP_MIN/figs/decoding_accuracy';

fig_dir = fullfile(fig_dir, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end

%% load the data

epos = cell(1,n_subjects);
for sbj_idx=1:n_subjects
    fprintf('loading subject %d\n', sbj_list(sbj_idx))
    
    
    switch condition
        case 'top_down'
                    epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
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
    
    % take only the scalp channels, remove EOG channels
    epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not', '*EOG*', 'NULL*'});
    
    % high pass filter
    db_attenuation = 30;
    hp_cutoff = 1;
    [z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
    epos{sbj_idx} = proc_filt(epos{sbj_idx}, z,p,k);
end

%% compute spectral features

% Here the spectral features are computed. For each trial I compute the
% power spectrum in the specified frequency range. The power in each
% frequency bin will become a feature used for classification

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
end
freqs = epo_spec{sbj_idx}.t;
fprintf('done\n')


%% get crossvalidation performance

% Here I do the crossvalidation to determine how well the classifier can
% discriminate between the classes. 

fprintf('\n\n --- starting crossvalidation ---\n\n')

loss_all = zeros(1,n_subjects);
loss_all_shuffled = zeros(1,n_subjects);

n_folds = 4; % 4 folds because there were 4 blocks in the experiment. Since
            % the trials are in chronological order, this crossvalidation
            % corresponds to leave-one-block-out crossvalidation

c_out = zeros(n_classes, n_epos, n_subjects);
for sbj_idx=1:n_subjects
    
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
    
    % apply crossvalidation using a regularized LDA classifer (see the
    % function train_RLDA_shrink.m) and chronological crossvalidation
    [loss_all(sbj_idx), ~, cout_tmp] = crossvalidation(fv{sbj_idx}, @train_RLDAshrink, ...
        'SampleFcn', {@sample_KFold, n_folds});
    c_out(:,:,sbj_idx) = squeeze(cout_tmp);
    fprintf(' -> loss LDA = %g\n', loss_all(sbj_idx))
    
    % repeat the crossvalidation with the same parameters but shuffle the
    % labels of the trials. This way we get an estimate of the chance
    % level. 
    fv_tmp = fv{sbj_idx};
    fv_tmp.y = fv_tmp.y(:,randperm(n_epos));
    loss_all_shuffled(sbj_idx) = crossvalidation(fv_tmp, @train_RLDAshrink, ...
        'SampleFcn', {@sample_KFold, n_folds});
    fprintf(' -> loss LDA (shuffled labels) = %g\n', loss_all_shuffled(sbj_idx))
    
end

% turn loss into accuracy
accuracy = 1 - loss_all;
fprintf('accuracies averaged across subjects:\n')
mean(accuracy, 2);

fprintf('accuracies (shuffled labels), averaged across subjects:\n')
accuracy_shuffled = 1 - loss_all_shuffled;
mean(accuracy_shuffled, 2);



%% visualize classification performance


acc = [accuracy; accuracy_shuffled]';
labels = {'rLDA', 'rLDA (shuffled labels)'};

figure
bar(100*[acc; mean(acc,1)])
hold on
legend(labels, 'location', 'best')
title({'decoding accuracy', sprintf(' for condition "%s"', strrep(condition,'_','-'))})
xlabel('subjects')
ylabel('decoding accuracy in %')
set(gca, 'xtick', 1:n_subjects+1)
tmp = get(gca, 'xtickLabel');
tmp{end} = 'avg';
set(gca, 'xtickLabel', tmp)
ylim([0,105])


if save_figs
    fname = sprintf('%s__decoding_accuracy', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 15, 10)
end