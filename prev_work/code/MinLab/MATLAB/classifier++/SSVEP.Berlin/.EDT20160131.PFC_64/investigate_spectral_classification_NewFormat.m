%% classification에 의한 각 subject 별 accuracy 를 산출함.
clear
close all

%% set [startup for bbci], appended by tigoum
%fullPATH	=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_2';
fullPATH	=	'/home/minlab/Projects/PFC_64/PFC_1';
%startup_bbci_toolbox('DataDir', fullPATH, 'TmpDir','/tmp/');

%% setting %%
%path(localpathdef);	% startup_bbci_toolbox@startup.m 대응 path 재조정
POOL		=	mLib_ParallelOpen_AmH();

%--------------------------------------------------------------------------------

%% set some paramters

%--------------------------------------------------------------------------------
%sbj_list = 1:14; % list of subject indices

% the experiment condition that is to be classified
% condition = 'bottom_up';
% condition = 'top_down';
% condition = 'intermediate';

%--------------------------------------------------------------------------------
%% edited by tigoum
AllRun					=	tic;

%all_list	=	1:19; %1:33;						% list of subject indices
all_list	=	[ 1:9 30 ];							% list of subject indices
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
%lCondition = { 'top_down', 'intermediate', 'bottom_up', };
lCondition = { '', };
for condi = 1 : length(lCondition)
	condition	=	lCondition{condi};
sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live
%--------------------------------------------------------------------------------

% the range of frequencies to be considered as features
%band = [4,30];										% 4Hz ~ 30Hz

n_subjects = length(sbj_list);

verbose = 1; 
save_figs = 1; % save figures or not

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir = '/home/sven/data/Results/SSVEP_MIN/figs/decoding_accuracy';
fig_dir = [ fullPATH '/Results/figs/decoding_accuracy'];
fig_dir = fullfile(fig_dir, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir')), mkdir(fig_dir); end


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
%	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, {'not','*EOG*','NULL*'});
	epos{sbj_idx} = proc_selectChannels(epos{sbj_idx}, removeCH);

	% high pass filter
	db_attenuation	=	30;
	hp_cutoff		=	1;
	[z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
	epos{sbj_idx} = proc_filt(epos{sbj_idx}, z,p,k);
end

%% compute spectral features

% Here the spectral features are computed. For each trial I compute the
% power spectrum in the specified frequency range. The power in each
% frequency bin will become a feature used for classification

sampling_freq			=	epos{1}.fs;
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
%fft_window = hanning(2*sampling_freq);
fft_window = hanning(sampling_freq* (1/epos{1}.bin) ); % edited by tigoum

fprintf('\n\n --- computing spectal features ---\n\n')
parfor sbj_idx=1:n_subjects
	fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
	% feature extraction: apply FFT
	% figure, plot(fft_window)

%	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, band,				...
%								'Win', fft_window, 'Step', sampling_freq*0.5);
	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, epos{sbj_idx}.band, ...
					'Win', fft_window, 'Step', sampling_freq*epos{sbj_idx}.bin);

	% Win == size(fft_window) == 1000
	% Step == sampling_freq / 2 == epos{}.fs / 2 == 500 / 2 == 250
	% therefore, freq's bins = epos{}.fs / Win = 500 / 1000 = 1/2
%	[n_freq_bins, n_channels, n_epos] = size(epo_spec{sbj_idx}.x);
%	n_classes = size(epo_spec{sbj_idx}.y,1);

	% reshape the channel-wise spectra to obtain feature vectors
	fv{sbj_idx}			=	proc_flaten(epo_spec{sbj_idx});
end
	% parfor 로 구동시킬 경우, 내부에서 발생하는 변수는 scope에 의해 소멸됨
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{1}.x);
	n_classes			=	size(epo_spec{1}.y, 1);
	if n_classes == 2, n_classes = 1; end	% 자유도 고려, 2개면 한쪽만 알면 됨
	freqs				=	epo_spec{1}.t;

fprintf('[*] frequency bin is %f\n', freqs(2)-freqs(1)); % added by tigoum
fprintf('done\n')



%% get crossvalidation performance

% Here I do the crossvalidation to determine how well the classifier can
% discriminate between the classes. 

fprintf('\n\n --- starting crossvalidation ---\n\n')

%n_folds		= 4; % 4 folds because there were 4 blocks in the experiment. Since
				% the trials are in chronological order, this crossvalidation
				% corresponds to leave-one-block-out crossvalidation
n_folds		= 7; % 7 folds because there were 4 blocks in the experiment. Since
				% the trials are in chronological order, this crossvalidation
				% corresponds to leave-one-block-out crossvalidation
loss_all	= zeros(1,n_subjects);
%loss_all_shuffled = zeros(1,n_subjects);
loss_sfl	= zeros(1,n_subjects);

c_out		= zeros(n_classes, n_epos, n_subjects);
parfor sbj_idx = 1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)

	fv_sbj			=	fv{sbj_idx};
	% apply crossvalidation using a regularized LDA classifer (see the
	% function train_RLDA_shrink.m) and chronological crossvalidation
%	[loss_all(sbj_idx), ~, cout_tmp]	=	crossvalidation(fv{sbj_idx}, ...
%								@train_RLDAshrink, ...
%								'SampleFcn', {@sample_KFold, n_folds});
	% change to RANDOMLY(==@sample_KFold)
	%	to % CHRONOLOGICAL(==@sample_chronKFold)
	[loss_all(sbj_idx), ~, cout_tmp]	=	crossvalidation(fv_sbj, ...
									@train_RLDAshrink, ...
									'SampleFcn', {@sample_chronKFold, n_folds});
%		whos cout_tmp
%	Name          Size               Bytes  Class     Attributes
%	cout_tmp      6x1x240            11520  double    
	c_out(:,:,sbj_idx)					=	squeeze(cout_tmp);
	fprintf(' -> loss LDA = %g\n', loss_all(sbj_idx))

	% repeat the crossvalidation with the same parameters but shuffle the
	% labels of the trials. This way we get an estimate of the chance level.
	fv_sbj.y		=	fv_sbj.y(:,randperm(n_epos));
%	loss_sfl(sbj_idx)					=		...
%		crossvalidation(fv_tmp,		@train_RLDAshrink,	...
%									'SampleFcn', {@sample_KFold, n_folds});
	loss_sfl(sbj_idx)					=		...
		crossvalidation(fv_sbj,		@train_RLDAshrink,	...
									'SampleFcn', {@sample_chronKFold, n_folds});
	fprintf(' -> loss LDA (shuffled labels) = %g\n', loss_sfl(sbj_idx))
end

% turn loss into accuracy
accuracy = 1 - loss_all;
fprintf('accuracies averaged across subjects:\n')
mean(accuracy, 2);

fprintf('accuracies (shuffled labels), averaged across subjects:\n')
accuracy_shuffled = 1 - loss_sfl;
mean(accuracy_shuffled, 2);



%% visualize classification performance
acc			=	[accuracy; accuracy_shuffled]';
labels		=	{'rLDA', 'rLDA (shuffled labels)'};

figure
h			=	bar(100*[acc; mean(acc,1)]);	% 핸들 2개 : rLDAx & shuffle
hold on
legend(labels, 'location', 'best')
title({'decoding accuracy', sprintf(' for condition "%s"', strrep(condition,'_','-'))})
xlabel('subjects')
ylabel('decoding accuracy in %')
set(gca, 'xtick', 1:n_subjects+1)
%sbj_label	=	get(gca, 'xtickLabel');
%--------------------------------------------------------------------------------
%% display a number over bar graph
%{
for idx = 1 : length(h)							% rLDA 와 shuffled 모두 출력 %-[
	idx
	x_loc		=	get(h(idx), 'XData')
	y_height	=	get(h(idx), 'YData')

	% 수치 출력 방향: 수평
%	arrayfun(@(x,y) text(x-0.7,y+1.5, sprintf('%.3f', y),					...
%							'FontSize',7, 'Color','b'),		x_loc, y_height);

	% 수치 출력 방향: 수직(rotate)
	arrayfun(@(x,y) text(x, y, sprintf('%.3f',y),	'Parent',h(idx),		...
			'FontSize',7,	'Color','b',	'Rotation',90,					...
			'HorizontalAlignment','left', 'VerticalAlignment','middle' ),	...
					x_loc, y_height);
%	if u want to remove the YTick(the points on the y axis)
%	set(p, 'YTick', nan);
end	%-]
%}
yb			=	cat(1, h.YData);			% vector 들을 하나로 연결
xb			=	bsxfun(@plus, h(1).XData, [h.XOffset]');	%x bar별 중간위치
%xb			=	xb + (h(1).BarWidth*h(1).XOffset./((Y<100)+2))'; % non rotate
hold on;
for a = 1:size(yb,2)
	for b = 1:length(yb(:,1))
%		text(xb(b, a),yb(b, a), cellstr(num2str(yb(b, a))),					...
		text(xb(b, a),yb(b, a)+0.2, sprintf('%.3f',yb(b, a)),				...
			'FontSize',7,	'Color','K',	'Rotation', 90,					...
			'HorizontalAlignment','left', 'VerticalAlignment','middle');
	end
end

%--------------------------------------------------------------------------------
sbj_label	=	arrayfun(@(x)({ num2str(x) }), sbj_list);	% ex) '1' '2' ..
sbj_label{end+1}	=	'avg';
set(gca, 'xtickLabel', sbj_label)
%--------------------------------------------------------------------------------
ylim([0,105])

if save_figs
    fname = sprintf('%s__decoding_accuracy', condition);
    my_save_fig(gcf, fullfile(fig_dir, fname), 15, 10)
end

%--------------------------------------------------------------------------------
end % for condi

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
delete(POOL);

toc(AllRun);

