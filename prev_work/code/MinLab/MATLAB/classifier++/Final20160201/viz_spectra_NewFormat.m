function [ nProc ]	=	viz_spectra_NewFormat(	...
							hEEG, condition, epos, verbose)
clearvars -except hEEG condition epos verbose
%close all

%--------------------------------------------------------------------------------
%% show spectral patterns

%--------------------------------------------------------------------------------
%% edited by tigoum
AllRun		=	tic;

% the experiment condition that is to be classified
sbj_list	=	hEEG.Inlier;
%sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live

%--------------------------------------------------------------------------------
% the range of frequencies to be considered as features
%band = [2,40];
n_subjects	=	length(sbj_list);
save_figs	=	1; % save figures or not


% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir = '/home/sven/data/Results/SSVEP_MIN/figs/power_spectra';
fig_dir = [ hEEG.PATH '/Results/figs/power_spectra'];

fig_dir = fullfile(fig_dir, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end


%% load the data
%{
epos = cell(1,n_subjects);
parfor sbj_idx=1:n_subjects
	fprintf('loading subject %d\n', sbj_list(sbj_idx))

	epos{sbj_idx} = load_SSVEP_Min_KU_data_new_format(...
						fullPATH, sbj_list(sbj_idx), condition, verbose);

	% take only the scalp channels, remove EOG channels
	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not','*EOG*','NULL*'});

	% high pass filter
	db_attenuation	=	30;
	hp_cutoff		=	1;
	[z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
	epos{sbj_idx}	=	proc_filt(epos{sbj_idx}, z,p,k);
end
%}
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
end
mnt = mnt_setGrid(mnt, grd);


%% compute spectral features

%band					=	epos{1}.band;
sampling_freq			=	epos{1}.fs;
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
%fft_window				=	hanning(5*sampling_freq);	% size() == 2500 1
fft_window		=	hanning(sampling_freq* (1/hEEG.FreqBins) ); %edited by tigoum

fprintf('\n\n --- computing spectal features ---\n\n')
for sbj_idx=1:n_subjects
	fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
%	feature extraction: apply FFT
%	figure, plot(fft_window)

%	epo_spec{sbj_idx} = proc_spectrum(epos{sbj_idx}, band, 'Win', fft_window, 'Step', sampling_freq*0.5);
	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, epos{sbj_idx}.band, ...
					'Win',fft_window, 'Step',sampling_freq*hEEG.FreqBins);

%	[n_freq_bins, n_channels, n_epos] = size(epo_spec{sbj_idx}.x);
%	n_classes = size(epo_spec{sbj_idx}.y,1);

%	reshape the channel-wise spectra to obtain feature vectors
	fv{sbj_idx}			=	proc_flaten(epo_spec{sbj_idx});
end
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{1}.x);
	n_classes			=	size(epo_spec{1}.y, 1);
	if n_classes == 2, n_classes = 1; end	% 자유도 고려, 2개면 한쪽만 알면 됨
%	freqs				=	epo_spec{1}.t;				% 주파수 구간
%	freqs = epo_spec{sbj_idx}.t;
fprintf('done\n')

%% compute discriminability for each feature

fprintf('\n\n --- computing featurewise discriminability ---\n\n')
scores = cell(size(fv));
parfor n=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', n, n_subjects)
    scores{n} = proc_rSquare(proc_normalize(fv{n}), 'policy', 'each-against-rest');
    
    scores{n}.x = reshape(scores{n}.x, [n_freq_bins, n_channels, n_classes]);
end
score_ga = proc_grandAverage(scores);
fprintf('done\n')


%% average spectra over trials
epo_spec_avg = epo_spec;
fprintf('\n\n --- averaging across trials---\n\n')
parfor n=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', n, n_subjects)
    epo_spec_avg{n} = proc_average(epo_spec{n}, 'Stats', 1);
end
epo_spec_ga = proc_grandAverage(epo_spec_avg, 'Stats', 1);

fprintf('done\n')


%% plot spectra

epo_spec_avg = epo_spec;
parfor n=1:n_subjects
    fprintf('processing sbj %02d/%02d\n', n, n_subjects)
    epo_spec_avg{n} = proc_average(epo_spec{n}, 'Stats', 1);
    figure
    grid_plot(epo_spec_avg{n}, mnt ...defopt_erps);%, 'colorOrder',colOrder);
        ,'ScaleHPos', 'left' ...
        ,'ShrinkAxes', [0.9 0.8] ...
    );
    if save_figs
        fname = sprintf('%s__sbj_%02d__power_spectrum', condition, n);
        if not(exist(fullfile(fig_dir, 'individual_subjects'), 'dir'))
            mkdir(fullfile(fig_dir, 'individual_subjects'));
        end
        my_save_fig(gcf, fullfile(fig_dir, 'individual_subjects', fname), 35, 20)
    end
end
fprintf('done\n')

%% plot grand average spectra

figure
grid_plot(epo_spec_ga, mnt ...
    ,'ScaleHPos', 'left' ...
    ,'ShrinkAxes', [0.9 0.8] ...
    );
if save_figs
    fname = sprintf('%s__grand_average__power_spectrum', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 35, 20)
end

%% plot grand average discriminability

figure
grid_plot(score_ga, mnt ...
    ,'ScaleHPos', 'left' ...
    ,'ShrinkAxes', [0.9 0.8] ...
    );
if save_figs
    fname = sprintf('%s__grand_average__discriminability', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 35, 20)
end

%--------------------------------------------------------------------------------
toc(AllRun);

nProc	=	n_subjects;
return
