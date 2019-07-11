function [ nProc ]	=	viz_classifier_pattern_NewFormat( hEEG, epos, verbose )
%% This script computes and plots classifier patterns 
clearvars -except hEEG epos verbose
%close all

%--------------------------------------------------------------------------------
%% paramters

%--------------------------------------------------------------------------------
%% edited by tigoum
AllRun		=	tic;

% the experiment cond that is to be classified
cond		=	hEEG.CurCond;
sbj_list	=	hEEG.Inlier;
%sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live

%--------------------------------------------------------------------------------
% the range of frequencies to be considered as features
%band = [4,30];										% 4Hz ~ 30Hz
%band = [2,40];
n_subjects	=	length(sbj_list);

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir = '/home/sven/data/Results/SSVEP_MIN/figs/classifier_patterns';
%fig_dir = [ hEEG.PATH '/Results/figs/classifier_patterns' ];
fig_dir		=	fullfile(hEEG.Dest, 'classifier_patterns');

%% load the data
%{
epos = cell(1,n_subjects);
parfor sbj_idx=1:n_subjects
	fprintf('filtering subject %s\n', sbj_list{sbj_idx})

	% take only the scalp channels, remove EOG channels
%	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not','*EOG*','NULL*'});
	epos{sbj_idx}		=	proc_selectChannels(epos{sbj_idx}, hEEG.delCH);

	% high pass filter
	db_attenuation		=	30;
	hp_cutoff			=	1;
	[z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
	epos{sbj_idx}		=	proc_filt(epos{sbj_idx}, z,p,k);
end
%}
% ChSide 가 존재하면 제거해야 함.
eOrg		=	epos;
if any( ismember(eOrg{1}.clab, hEEG.ChSide) )				% EOG 추가 임.
%	SdPos	=	find( ismember(eOrg{1}.clab, hEEG.ChSide));
	ChPos	=	find(~ismember(eOrg{1}.clab, hEEG.ChSide));
	hEEG.nChannel		=	hEEG.nChannel - 1;				% 갱신, EOG 제거

%	eOrg	=	epos;
%	eSide	=	eOrg;

	parfor sj_ix=1:n_subjects
%	eSide{sj_ix}.clab	=	hEEG.ChSide;					% label 교정
%	eSide{sj_ix}.x		=	eOrg{sj_ix}.x(:,SdPos,:);		% EOG 데이터만

	epos{sj_ix}.clab	=	eOrg{sj_ix}.clab(ChPos);		% EOG 제거
	epos{sj_ix}.x		=	eOrg{sj_ix}.x(:,ChPos,:);		% EOG 제외 data
	end
end
	clear eOrg

mnt = mnt_setElectrodePositions(epos{1}.clab);
if hEEG.nChannel == 30
	grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'							...
					'F7,F3,Fz,F4,F8\n'									...
					'FC5,FC1,FC2,FC6\n'									...
					'T7,C3,Cz,C4,T8\n'									...
					'CP5,CP1,CP2,CP6\n'									...
					'P7,P3,Pz,P4,P8\n'									...
					'PO9,O1,Oz,O2,PO10'									...
					]);		% 기본: 30채널 중 2개는 Ref, EOG
elseif hEEG.nChannel == 31
	error('Please, remove EOG info., and set chan size to 30, then Rerun');
elseif hEEG.nChannel == 32
	grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'							...
					'F7,F3,Fz,F4,F8\n'									...
					'FC5,FC1,FCz,FC2,FC6\n'								...
					'T7,C3,Cz,C4,T8\n'									...
					'CP5,CP1,CPz,CP2,CP6\n'								...
					'P7,P3,Pz,P4,P8\n'									...
					'PO9,O1,Oz,O2,PO10'									...
					]);		% FCz, CPz 추가
elseif hEEG.nChannel == 63
	grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'							...
					'AF7,AF3,AF4,AF8\n'									...
					'F7,F5,F3,F1,Fz,F2,F4,F6,F8\n'						...
					'FT9,FT7,FC5,FC3,FC1,FCz,FC2,FC4,FC6,FT8,FT10\n'	...
					'T7,C5,C3,C1,Cz,C2,C4,C6,T8\n'						...
					'TP7,CP5,CP3,CP1,CPz,CP2,CP4,CP6,TP8\n'				...
					'P7,P5,P3,P1,Pz,P2,P4,P6,P8\n'						...
					'PO7,PO3,POz,PO4,PO8\n'								...
					'PO9,O1,Oz,O2,PO10'									...
					]);		% 기본: 64채널 중 1개는 EOG
elseif hEEG.nChannel == 64
	grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'							...
					'AF7,AF3,AFz,AF4,AF8\n'								...
					'F7,F5,F3,F1,Fz,F2,F4,F6,F8\n'						...
					'FT9,FT7,FC5,FC3,FC1,FCz,FC2,FC4,FC6,FT8,FT10\n'	...
					'T7,C5,C3,C1,Cz,C2,C4,C6,T8\n'						...
					'TP7,CP5,CP3,CP1,CPz,CP2,CP4,CP6,TP8\n'				...
					'P7,P5,P3,P1,Pz,P2,P4,P6,P8\n'						...
					'PO7,PO3,POz,PO4,PO8\n'								...
					'PO9,O1,Oz,O2,PO10'									...
					]);		% AFz 추가
elseif hEEG.nChannel == 66
	grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'							...
					'AF7,AF3,AFz,AF4,AF8\n'								...
					'F7,F5,F3,F1,Fz,F2,F4,F6,F8\n'						...
					'FT9,FT7,FC5,FC3,FC1,FCz,FC2,FC4,FC6,FT8,FT10\n'	...
					'T7,C5,C3,C1,Cz,C2,C4,C6,T8\n'						...
					'TP9,TP7,CP5,CP3,CP1,CPz,CP2,CP4,CP6,TP8,TP10\n'	...
					'P7,P5,P3,P1,Pz,P2,P4,P6,P8\n'						...
					'PO7,PO3,POz,PO4,PO8\n'								...
					'PO9,O1,Oz,O2,PO10'									...
					]);		% TP9, TP10 추가
elseif hEEG.nChannel == 100	% BA 구성
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
end
mnt = mnt_setGrid(mnt, grd);


%% compute spectral features
%epos{20}.x(1), epos{20}.x(end)
%size(epos{20}.x)
%BREAK
%band					=	epos{1}.band;				% 4, 30
sampling_freq			=	epos{1}.fs;					% 500
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
%fft_window = hanning(2*sampling_freq);
fft_window	=	hanning(sampling_freq* (1/hEEG.FreqBins) );%bin==1/2,edited by tg

fprintf('\n\n --- computing spectal features ---\n\n')
parfor sbj_idx=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
    % feature extraction: apply FFT
    % figure, plot(fft_window)

%	epo_spec{sbj_idx} = proc_spectrum(epos{sbj_idx}, band, 'Win', fft_window, 'Step', sampling_freq*0.5);
	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, epos{sbj_idx}.band, ...
					'Win', fft_window, 'Step', sampling_freq*hEEG.FreqBins);

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
	if n_classes == 2, n_classes = 1; end				% 2개면 한쪽만 알면 됨
		% 이유: y가 2 x epoch 일때, train_RLDAshrink()가 자동으로 class 차원을
		% 2->1 로 downgrade 시킴. 따라서, 결과값인 classifier 도 1 x epoch 됨!
	freqs				=	epo_spec{1}.t;				% proc_()결과 중 freq구간
%	freqs = epo_spec{sbj_idx}.t;
fprintf('[*] frequency bin is %f\n', freqs(2)-freqs(1)); % added by tigoum
fprintf('done\n')

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% normalize features, compute linear classifier and classifier pattern
%--------------------------------------------------------------------------------
fprintf('\n\n --- computing classifier patterns ---\n\n')
patterns_cov			=	zeros(n_subjects, n_freq_bins,n_channels,n_classes);
patterns_corr			=	zeros(n_subjects, n_freq_bins,n_channels,n_classes);
patterns_corr_max_y		=	zeros(n_subjects, n_freq_bins,n_channels		);
parfor n				=	1:n_subjects
	fprintf('processing sbj %02d/%02d\n', n, n_subjects)

	% normalize features
	fv{n}.x				=	zscore(fv{n}.x')';
	% train classifier
	classifier			=	train_RLDAshrink(fv{n}.x, fv{n}.y);
	% get classifier output
	y					=	classifier.w' * fv{n}.x;
	y					=	y ./ repmat(std(y,[],2), [1, n_epos]);

	% compute pattern via covariance of classifier output with features
	a_cov				=	fv{n}.x * y';
	a_cov				=	reshape(a_cov, [n_freq_bins, n_channels, n_classes]);
	patterns_cov(n, :,:,:)		=	a_cov;			% fBins x ch x class

	% compute pattern via correlation of classifier output with features
	a_corr				=	zeros(n_freq_bins*n_channels, n_classes);
	for c_idx			=	1:n_classes
		R				=	corrcoef([y(c_idx,:)',fv{n}.x']);
		a_corr(:,c_idx)			=	R(1,2:end)';
	end
	a_corr				=	reshape(a_corr,[n_freq_bins, n_channels, n_classes]);
	patterns_corr(n, :,:,:)		=	a_corr;			% fBins x ch x class

	% compute pattern via correlation of classifier output with features
	% SSVEP_NEW: have 6 labels, then it treats 6 classes
	% size(max(y)') = 240 1
	% size(fv{n}.x')= 240 1590
	% PFC_64: have 2 classes, then 
	if n_classes==1, y=repmat(y, n_classes+1, 1); end % for: max 시 trial 수 유지
	R					=	corrcoef([max(y)',fv{n}.x']);
	a_corr_max_y		=	R(1,2:end)';
	a_corr_max_y		=	reshape(a_corr_max_y, [n_freq_bins, n_channels]);
	patterns_corr_max_y(n, :,:)	=	a_corr_max_y;	% fBins x ch

	%% plot patterns, indivisual over frequencies ( not channels )
%{
	viz_classifier_pattern_NewFormat_plot(fig_dir,							...
							sprintf('sbj%04d', sbj_list(n)),	cond,	...
							freqs, band, fv{n}.className, mnt,				...
							a_cov, a_corr, a_corr_max_y);
%}
	% topo 에서 좀 더 유용한 정보를 도출하기 위해, 데이터를 추가 가공한다.
	if isfield(hEEG, 'SpinOff') & ~isempty(hEEG.SpinOff)
	for s = 1 : length(hEEG.SpinOff)				% 적용할 spinoff 함수 갯수
		spinoff			=	hEEG.SpinOff{s};

		a_cov_spo		=	spinoff(a_cov);
		a_corr_spo		=	spinoff(a_corr);

		viz_classifier_pattern_NewFormat_plot(fig_dir, sbj_list{n}, cond,...
			freqs, epos{n}.band, hEEG.FreqBins, hEEG.FOI, hEEG.sFOI,		...
			fv{n}.className, mnt,	a_cov_spo, a_corr_spo, a_corr_max_y);
	end

	else	% 기본 구성
		viz_classifier_pattern_NewFormat_plot(fig_dir, sbj_list{n}, cond,...
			freqs, epos{n}.band, hEEG.FreqBins, hEEG.FOI, hEEG.sFOI,		...
			fv{n}.className, mnt,	a_cov, a_corr, a_corr_max_y);
	end
end
fprintf('done\n\n\n')

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% average patterns over subjects

ptrn_cov_avg		=	squeeze(mean(patterns_cov,1));
ptrn_corr_avg		=	squeeze(mean(patterns_corr,1));
ptrn_corr_max_y_avg	=	squeeze(mean(patterns_corr_max_y,1));

%% plot patterns, averaged over channels & frequencies
	if isfield(hEEG, 'SpinOff') & ~isempty(hEEG.SpinOff)
	for s = 1 : length(hEEG.SpinOff)				% 적용할 spinoff 함수 갯수
		spinoff			=	hEEG.SpinOff{s};

		ptrn_cov_spo	=	spinoff(ptrn_cov_avg);
		ptrn_corr_spo	=	spinoff(ptrn_corr_avg);

	viz_classifier_pattern_NewFormat_plot(fig_dir,	'GrandAverage',	cond,	...
		freqs, epos{1}.band, hEEG.FreqBins, hEEG.FOI, hEEG.sFOI,			...
		fv{1}.className, mnt,				...
		ptrn_cov_spo,	ptrn_corr_spo,	ptrn_corr_max_y_avg,				...
		patterns_cov,	patterns_corr,	patterns_corr_max_y	);	% se 용 all data
	end

	else	% 기본 구성
	viz_classifier_pattern_NewFormat_plot(fig_dir,	'GrandAverage',	cond,	...
		freqs, epos{1}.band, hEEG.FreqBins, hEEG.FOI, hEEG.sFOI,			...
		fv{1}.className, mnt,				...
		ptrn_cov_avg,	ptrn_corr_avg,	ptrn_corr_max_y_avg,				...
		patterns_cov,	patterns_corr,	patterns_corr_max_y	);	% se 용 all data
	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%delete(POOL);

toc(AllRun);

nProc	=	n_subjects;
return
