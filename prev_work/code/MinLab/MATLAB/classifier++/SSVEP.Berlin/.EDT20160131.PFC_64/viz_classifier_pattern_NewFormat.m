%% This script computes and plots classifier patterns 
clear
close all

%% set [startup for bbci], appeced by tigoum
%fullPATH	=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_2';
fullPATH	=	'/home/minlab/Projects/PFC_64/PFC_1';
%startup_bbci_toolbox('DataDir', fullPATH, 'TmpDir','/tmp/');

%% setting %%
%path(localpathdef);	% edited by tigoum
POOL		=	mLib_ParallelOpen_AmH();

%--------------------------------------------------------------------------------
%% paramters

%sbj_list = 1:14; % list of subject indices

% condition = 'bottom_up';
% condition = 'top_down';
% condition = 'intermediate';

%--------------------------------------------------------------------------------
%% edited by tigoum
AllRun					=	tic;

%all_list	=	1:33;								% list of subject indices
all_list	=	[ 1:9 30 ];								% list of subject indices
exc_list	=	[ ];								% list for exclude
%exc_list	=	[3,4,8,11,13];						% list of subject indices
%exc_list	=	[ 1 2 7 10 16 17 ];					% list for exclude
%exc_list	=	[ 2 5 7 16 17 21 25 26 27 ];		% list for exclude
%exc_list	=	[ 2 5 7 14 16 17 21 25 26 27 ];		% list for exclude
%exc_list	=	[ 2 5 7 9 14 15 16 17 21 25 26 27 28 ];	% list for exclude
%exc_list	=	[ 2 5 7 9 14 15 16 17 21 25 26 27 28 32 ];	% list for exclude
sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live

%removeCH	=	{	'not',	'NULL*',		...
%			'Fp1' 'Fp2' 'F7' 'F3' 'Fz' 'F4' 'F8' 'FC5' 'FC1' 'FC2' 'FC6' 'T7' ...
%			'C3' 'Cz' 'C4' 'T8'   'EOG'   'CP5' 'CP1' 'CP2' 'CP6'			...
%			'P7' 'P3' 'Pz' 'P4' 'P8' 'PO9' 'PO10'};
removeCH	=	{	'not',	'NULL*',	'*EOG*'	};

% the experiment condition that is to be classified
%lCondition = { 'TopDown', 'Intermediate', 'BottomUp', };
lCondition = { '', };
for condi = 1 : length(lCondition)
	condition	=	lCondition{condi};
%--------------------------------------------------------------------------------


% the range of frequencies to be considered as features
%band = [2,40];

n_subjects = length(sbj_list);

verbose = 1;

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir = '/home/sven/data/Results/SSVEP_MIN/figs/classifier_patterns';
fig_dir = [ fullPATH '/Results/figs/classifier_patterns' ];

%% load the data

epos = cell(1,n_subjects);
parfor sbj_idx=1:n_subjects
	fprintf('loading subject %d\n', sbj_list(sbj_idx));
%{
	switch condition
	case 'top_down'
			epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
			fullPATH, sbj_list(sbj_idx), 'TopDown', verbose);
	case 'bottom_up'
			epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
			fullPATH, sbj_list(sbj_idx), 'BottomUp', verbose);
	case 'intermediate'
			epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
			fullPATH, sbj_list(sbj_idx), 'Intermediate', verbose);
	otherwise
			error('condition = %s is unknown!', condition)
	end
%}
	epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
						fullPATH, sbj_list(sbj_idx), condition, verbose);

	% take only the scalp channels, remove EOG channels
%	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not','*EOG*','NULL*'});
	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, removeCH);

	% high pass filter
	db_attenuation = 30;
	hp_cutoff = 1;
	[z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
	epos{sbj_idx} = proc_filt(epos{sbj_idx}, z,p,k);
end

mnt = mnt_setElectrodePositions(epos{1}.clab);
%{
grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'	...
				'F7,F3,Fz,F4,F8\n'			...
				'FC5,FC1,FCz,FC2,FC6\n'		...
				'T7,C3,Cz,C4,T8\n'			...
				'CP5,CP1,CPz,CP2,CP6\n'		...
				'P7,P3,Pz,P4,P8\n'			...
				'PO9,O1,Oz,O2,PO10'			...
				]);
%}
grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'							...
				'AF7,AF3,AFz,AF4,AF8\n'								...
				'F7,F5,F3,F1,Fz,F2,F4,F6,F8\n'						...
				'FT9,FT7,FC5,FC3,FC1,FCz,FC2,FC4,FC6,FT8,FT10\n'	...
				'T7,C5,C3,C1,Cz,C2,C4,C6,T8\n'						...
				'TP9,TP7,CP5,CP3,CP1,CPz,CP2,CP4,CP6,TP8,TP10\n'	...
				'P7,P5,P3,P1,Pz,P2,P4,P6,P8\n'						...
				'PO7,PO3,POz,PO4,PO8\n'								...
				'PO9,O1,Oz,O2,PO10'									...
				]);

mnt = mnt_setGrid(mnt, grd);


%% compute spectral features

band					=	epos{1}.band;				% 4, 30
sampling_freq			=	epos{1}.fs;					% 500
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
%fft_window = hanning(2*sampling_freq);
fft_window = hanning(sampling_freq* (1/epos{1}.bin) );	% bin==1/2, edited by tg

fprintf('\n\n --- computing spectal features ---\n\n')
parfor sbj_idx=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
    % feature extraction: apply FFT
    % figure, plot(fft_window)
    
%	epo_spec{sbj_idx} = proc_spectrum(epos{sbj_idx}, band, 'Win', fft_window, 'Step', sampling_freq*0.5);
	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, epos{sbj_idx}.band, ...
					'Win', fft_window, 'Step', sampling_freq*epos{sbj_idx}.bin);

%	[n_freq_bins, n_channels, n_epos] = size(epo_spec{sbj_idx}.x);
%	n_classes = size(epo_spec{sbj_idx}.y,1);

    % reshape the channel-wise spectra to obtain feature vectors
    fv{sbj_idx}			=	proc_flaten(epo_spec{sbj_idx});

    % high pass filter the features
    hp_cutoff			=	1;	% / 5;
    [b,a_corr]			=	butter(3, hp_cutoff/(sampling_freq/2), 'high');
    fv{sbj_idx}.x		=	filtfilt(b,a_corr,fv{sbj_idx}.x')';

end
	% parfor 로 구동시킬 경우, 내부에서 발생하는 변수는 scope에 의해 소멸됨
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{1}.x);
	n_classes			=	size(epo_spec{1}.y, 1);
	if n_classes == 2, n_classes = 1; end	% 자유도 고려, 2개면 한쪽만 알면 됨
	freqs				=	epo_spec{1}.t;				% 주파수 구간
%	freqs = epo_spec{sbj_idx}.t;
fprintf('[*] frequency bin is %f\n', freqs(2)-freqs(1)); % added by tigoum
fprintf('done\n')

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% normalize features, compute linear classifier and classifier pattern
%--------------------------------------------------------------------------------
fprintf('\n\n --- computing classifier patterns ---\n\n')
patterns_cov		=	zeros(n_freq_bins, n_channels, n_classes, n_subjects);
patterns_corr		=	zeros(n_freq_bins, n_channels, n_classes, n_subjects);
patterns_corr_max_y	=	zeros(n_freq_bins, n_channels, n_subjects);
parfor n			=	1:n_subjects
	fprintf('processing sbj %02d/%02d\n', n, n_subjects)

	% normalize features
	fv{n}.x			=	zscore(fv{n}.x')';
	% train classifier
	classifier		=	train_RLDAshrink(fv{n}.x, fv{n}.y);
	% get classifier output
	y				=	classifier.w' * fv{n}.x;
	y				=	y ./ repmat(std(y,[],2), [1, n_epos]);

	% compute pattern via covariance of classifier output with features
	a_cov			=	fv{n}.x * y';
	a_cov			=	reshape(a_cov, [n_freq_bins, n_channels, n_classes]);
	patterns_cov(:,:,:,n)		=	a_cov;

	% compute pattern via correlation of classifier output with features
	a_corr			=	zeros(n_freq_bins*n_channels, n_classes);
	for c_idx		=	1:n_classes
		R			=	corrcoef([y(c_idx,:)',fv{n}.x']);
		a_corr(:,c_idx)			=	R(1,2:end)';
	end
	a_corr			=	reshape(a_corr, [n_freq_bins, n_channels, n_classes]);
	patterns_corr(:,:,:,n)		=	a_corr;

	% compute pattern via correlation of classifier output with features
	% SSVEP_NEW: have 6 labels, then it treats 6 classes
	% size(max(y)') = 240 1
	% size(fv{n}.x')= 240 1590
	% PFC_64: have 2 classes, then 
	if n_classes==1, y=repmat(y, n_classes+1, 1); end % for: max 시 trial 수 유지
	R				=	corrcoef([max(y)',fv{n}.x']);
	a_corr_max_y	=	R(1,2:end)';
	a_corr_max_y	=	reshape(a_corr_max_y, [n_freq_bins, n_channels]);
	patterns_corr_max_y(:,:,n)	=	a_corr_max_y;

	%% plot patterns, indivisual over frequencies ( not channels )
	viz_classifier_pattern_NewFormat_plot(fig_dir,							...
							sprintf('sbj%04d', sbj_list(n)),	condition,	...
							freqs, band, fv{n}.className, mnt,				...
							a_cov, a_corr, a_corr_max_y);

end
fprintf('done\n\n\n')
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%% average patterns over subjects

patterns_cov_avg		=	squeeze(mean(patterns_cov,4));
patterns_corr_avg		=	squeeze(mean(patterns_corr,4));
patterns_corr_max_y_avg	=	squeeze(mean(patterns_corr_max_y,3));

%% plot patterns, averaged over channels & frequencies
viz_classifier_pattern_NewFormat_plot(fig_dir,	'GrandAverage',	condition,	...
							freqs,	band,	fv{1}.className,	mnt,		...
							patterns_cov_avg,								...
							patterns_corr_avg,								...
							patterns_corr_max_y_avg);

%--------------------------------------------------------------------------------
end % for condi

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%delete(POOL);

toc(AllRun);

