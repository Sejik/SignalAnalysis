%%

%% set some paramters

% % sbj_list = 1:14; % list of subject indices
% sbj_list = [1,3,4];
%sbj_list = [1,3,4,6,8,10:13,16:26];
sbj_list = [1:20];

% the experiment condition that is to be classified
%condition = 'intermediate';
%condition = 'top_down';
%condition = 'bottom_up';
lCondition	=	{ 'BottomUp', 'Intermediate', 'TopDown' };

% the range of frequencies to be considered as features
% band = [4,30];
band = [5, 13.5];

% channels used for classification
%clab_clf = {'O1','Oz','O2'};
clab_clf = {	'not',	'NULL*',	'*EOG*'	};	% remove chan.

n_subjects = length(sbj_list);

verbose = 1; 
save_figs = 1; % save figures or not

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
PATH = '/home/minlab/Projects/SSVEP_NEW/SSVEP_2';
%fig_dir = '/data/Results/SSVEP_MIN/figs/decoding_accuracy';
fig_dir = 'Results';

fig_dir = fullfile(PATH, fig_dir, 'decoding_accuracy2');
if save_figs && not(exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end

POOL				=	S_paraOpen();

%% load the data
for condition = lCondition					% loop for each condition
	condition = char(condition);			% conv char

epos = cell(1,n_subjects);
parfor sbj_idx=1:n_subjects
    fprintf('loading subject %d\n', sbj_list(sbj_idx))
%{
    switch condition
        case 'top_down'
                    epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
                        PATH, sbj_list(sbj_idx), 'TopDown', verbose);
        case 'bottom_up'
                    epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
                        PATH, sbj_list(sbj_idx), 'BottomUp', verbose);
        case 'intermediate'
                    epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
                        PATH, sbj_list(sbj_idx), 'Intermediate', verbose);
        otherwise
            error('condition = %s is unknown!', condition)
    end
%}
	epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
						PATH, sbj_list(sbj_idx), condition, verbose);

	% take only the scalp channels, remove EOG channels
	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not', '*EOG*','NULL*'});

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
parfor sbj_idx=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
    % feature extraction: apply FFT
    % figure, plot(fft_window)
    
    epo_spec{sbj_idx} = proc_spectrum(epos{sbj_idx}, band, 'Win', fft_window, 'Step', sampling_freq*0.5);
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{sbj_idx}.x);
    n_classes = size(epo_spec{sbj_idx}.y,1);
    
    % get the spectra of a subset of channels only
    tmp = proc_selectChannels(epo_spec{sbj_idx}, clab_clf);
    % reshape the channel-wise spectra to obtain feature vectors
    fv{sbj_idx} = proc_flaten(tmp);
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
parfor sbj_idx=1:n_subjects
    
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
    
    % apply crossvalidation using a regularized LDA classifer (see the
    % function train_RLDA_shrink.m) and chronological crossvalidation
%    [loss_all(sbj_idx), ~, cout_tmp] = crossvalidation(fv{sbj_idx}, @train_RLDAshrink, ...
%        'SampleFcn', {@sample_KFold, n_folds});
	[loss_all(sbj_idx), ~, cout_tmp] = crossvalidation(fv{sbj_idx},		...
						@train_RLDAshrink, ...
						'SampleFcn', {@sample_chronKFold, n_folds});
    c_out(:,:,sbj_idx) = squeeze(cout_tmp);
    fprintf(' -> loss LDA = %g\n', loss_all(sbj_idx))
    
    % repeat the crossvalidation with the same parameters but shuffle the
    % labels of the trials. This way we get an estimate of the chance level.
    fv_tmp = fv{sbj_idx};
    fv_tmp.y = fv_tmp.y(:,randperm(n_epos));
%    loss_all_shuffled(sbj_idx) = crossvalidation(fv_tmp, @train_RLDAshrink, ...
%        'SampleFcn', {@sample_KFold, n_folds});
	loss_all_shuffled(sbj_idx) = crossvalidation(fv_tmp, @train_RLDAshrink, ...
						'SampleFcn', {@sample_chronKFold, n_folds});
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

%% compute classifier pattern

chan_cov = zeros(n_channels, n_freq_bins, n_subjects);
chan_corr = zeros(n_channels, n_freq_bins, n_subjects);
parfor sbj_idx=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
    
    % get the classifier signal from this subject 
    c_out_i = c_out(:,:,sbj_idx);
    c_out_i = max(c_out_i, [], 1);
    
    % compute correlation and covariance between time-course of the
    % classifier signal and the time-courses of the spectral features 
    epo_spec_i = epo_spec{sbj_idx};
    for n=1:n_channels
        chan_feats = squeeze(epo_spec_i.x(:,n,:));
        R = cov([c_out_i', chan_feats']);
        chan_cov(n,:,sbj_idx) = R(1,2:end);
        R = corrcoef([c_out_i', chan_feats']);
        chan_corr(n,:,sbj_idx) = R(1,2:end);
    end
end

%% plot scalp maps
mnt = mnt_setElectrodePositions(epo_spec{1}.clab);

% average patterns across frequency bins and subjects to plot scalp plots
cov_map = mean(mean(chan_cov,2),3);
corr_map = mean(mean(chan_corr,2),3);

sc_opt = [];
sc_opt.ExtrapolateToZero = 0;
sc_opt.Contour = 0;

sc_opt.CLim = 45*[-1,1];				% fixed, added by tigoum
figure
plot_scalp(mnt, cov_map, sc_opt)
colormap jet
if save_figs
    fname = sprintf('%s__clf_pattern_cov_map', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 20, 20)
end

%sc_opt.CLim = .35*[-1,1];
sc_opt.CLim = 'sym';					% min~max, added by tigoum
figure
plot_scalp(mnt, corr_map, sc_opt)
colormap jet

if save_figs
    fname = sprintf('%s__clf_pattern_corr_map', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 20, 20)
end

end	% for cond

%%-------------------------------------------------------------------------------
%{
Dear Byoung-Kyong,
 
please find my comments to the manuscript attached. I have used the version
that Klaus modified as a starting point and focused on the Methods part. 
 
Personally, I think it is inconsistent to report a classification accuracy
that is based on 3 channels and then plot a pattern that is based on a
classifier that used all channels. Thus, I propose a compromise that is in
accordance with the filter/pattern idea: we use the output from the 3-channel
classifier and compute the pattern based as the covariance between it and the
features of all channels. This gives a pattern that has all channel in it but
is based on the the output of the 3-channel classifier. Thus we can keep your
modifications of the features which led to better performance. 
 
I have explained our reasoning in the manuscript. The basic idea of the
pattern computation is to find out how the informative signal is encoded in
the features. In the Haufe et al. paper, we always assumed that all available
features are used in the classifier. Because of this assumption, the
covariance between features and classifier output leads to the equation with
the covariance matrix, i.e. A = Cov(W*X, X) = C*W. In our case, the number of
features we use for the pattern is not the same as the number of features we
use for the classifier but the general idea is the same.
 
I have attached a modified version of the script that computes the classifier
based on your  changes (i.e. only channels O1,O2, Oz and frequencies 5 to
13.5). In the last cell of the script, the pattern is computed for all
features (i.e. all channels, freqs 5 to 13.5) and then averaged over
frequencies and subjects. I have also attached the resulting maps. 
 
In the Haufe paper we discuss computing the pattern based on correlation or
covariance. Base approaches are valid but give slightly different results due
to the normalization in the correlation. The script computes patterns based on
both. I leave it to you to decide which version you want to use. Personally, I
would suggest the correlation based version, since we are comparing across
conditions, which might be more convincing with the normalization. But it's
your call. 
Keep in mind, however, that the text describing the patterns must now be
adapted. I have highlighted it in the Results section. 
 
Cheers,
Sven
%}
