clear
close all

%% set [startup for bbci], appeced by tigoum
fullPATH		=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_2';
startup_bbci_toolbox('DataDir', fullPATH, 'TmpDir','/tmp/');

%% setting %%
%path(localpathdef);	% edited by tigoum

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
NUMWORKERS				=	20;				%'Modified' property now TRUE
%NUMWORKERS				=	feature('numcores');
%% local 머신 범위에서, 병렬연산을 위한 가용 코어 설정
tic;	delete(gcp('nocreate'));

%matlabpool open 4;							% lagacy 방식
%POOL		=	parpool('local');			% 현재 머신의 가용 core로 디폴트 설정
%----------
%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% 신규 profile 작성
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% 최대 48 core 고려.
	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!주의: parent 에서 호출직전에 tic를 수행한다는 가정하에, toc 출력 요청함.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%--------------------------------------------------------------------------------

%% show spectral patterns

%--------------------------------------------------------------------------------
%sbj_list = 1:14; % list of subject indices

% condition = 'bottom_up';
% condition = 'top_down';
% condition = 'intermediate';

%--------------------------------------------------------------------------------
%% edited by tigoum
all_list	=	1:28;								% list of subject indices
%exc_list	=	[ ];								% list for exclude
%exc_list	=	[ 1 2 7 10 16 17 ];					% list for exclude
%exc_list	=	[ 2 5 7 16 17 21 25 26 27 ];		% list for exclude
exc_list	=	[ 2 5 7 14 16 17 21 25 26 27 ];		% list for exclude
sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live

%lCondition = { 'top_down', 'intermediate', 'bottom_up', };
lCondition = { 'TopDown', 'Intermediate', 'BottomUp', };
for condi = 1 : length(lCondition)
	condition	=	lCondition{condi};
%--------------------------------------------------------------------------------


% the range of frequencies to be considered as features
%band = [2,40];

n_subjects = length(sbj_list);

verbose = 1; 
save_figs = 1; % save figures or not


% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir = '/home/sven/data/Results/SSVEP_MIN/figs/power_spectra';
fig_dir = [ fullPATH '/Results/figs/power_spectra'];

fig_dir = fullfile(fig_dir, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end


%% load the data

epos = cell(1,n_subjects);
parfor sbj_idx=1:n_subjects
	fprintf('loading subject %d\n', sbj_list(sbj_idx))
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
	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not','*EOG*','NULL*'});

	% high pass filter
	db_attenuation	=	30;
	hp_cutoff		=	1;
	[z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
	epos{sbj_idx} = proc_filt(epos{sbj_idx}, z,p,k);
end

mnt = mnt_setElectrodePositions(epos{1}.clab);
grd = sprintf([	'scale,Fp1,_,Fp2,legend\n'	...
				'F7,F3,Fz,F4,F8\n'			...
				'FC5,FC1,FCz,FC2,FC6\n'		...
				'T7,C3,Cz,C4,T8\n'			...
				'CP5,CP1,CPz,CP2,CP6\n'		...
				'P7,P3,Pz,P4,P8\n'			...
				'PO9,O1,Oz,O2,PO10'			...
				]);
mnt = mnt_setGrid(mnt, grd);


%% compute spectral features

band					=	epos{1}.band;
sampling_freq			=	epos{1}.fs;
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
fft_window				=	hanning(5*sampling_freq);

fprintf('\n\n --- computing spectal features ---\n\n')
parfor sbj_idx=1:n_subjects
fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
%	feature extraction: apply FFT
%	figure, plot(fft_window)

%	epo_spec{sbj_idx} = proc_spectrum(epos{sbj_idx}, band, 'Win', fft_window, 'Step', sampling_freq*0.5);
	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, epos{sbj_idx}.band, ...
					'Win', fft_window, 'Step', sampling_freq*epos{sbj_idx}.bin);

%	[n_freq_bins, n_channels, n_epos] = size(epo_spec{sbj_idx}.x);
%	n_classes = size(epo_spec{sbj_idx}.y,1);

%	reshape the channel-wise spectra to obtain feature vectors
	fv{sbj_idx} = proc_flaten(epo_spec{sbj_idx});
end
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{1}.x);
	n_classes			=	size(epo_spec{1}.y, 1);
	freqs				=	epo_spec{1}.t;				% 주파수 구간
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
end % for condi
