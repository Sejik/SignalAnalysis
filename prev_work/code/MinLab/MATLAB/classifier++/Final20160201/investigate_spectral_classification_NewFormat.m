function [ nProc ]	=	investigate_spectral_classification_NewFormat(	...
							hEEG, condi, epos, verbose)
%% classification에 의한 각 subject 별 accuracy 를 산출함.
clearvars -except hEEG condi epos verbose
%close all

%--------------------------------------------------------------------------------
%% set some paramters

%--------------------------------------------------------------------------------
%sbj_list = 1:14; % list of subject indices

%--------------------------------------------------------------------------------
%% edited by tigoum
AllRun		=	tic;

% the experiment condi that is to be classified
sbj_list	=	hEEG.Inlier;
%sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live
%--------------------------------------------------------------------------------

% the range of frequencies to be considered as features
%band = [4,30];										% 4Hz ~ 30Hz
n_subjects	=	length(sbj_list);
save_figs	=	1; % save figures or not

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir = '/home/sven/data/Results/SSVEP_MIN/figs/decoding_accuracy';
fig_dir = [ hEEG.PATH '/Results/figs/decoding_accuracy'];
fig_dir = fullfile(fig_dir, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir')), mkdir(fig_dir); end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% band or BOI 를 기준으로 각 대역별로 별도 accuracy 계산해야 더 정확도 높음
AllBOI	=	{ hEEG.BOI{:} hEEG.FreqWindow };					% window 추가
for B = 1:length(AllBOI)
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%% load the data
%{
%epos = cell(1,n_subjects);
parfor sbj_idx=1:n_subjects
	fprintf('filtering subject %s\n', sbj_list{sbj_idx})

	% take only the scalp channels, remove EOG channels
	epos{sbj_idx}		=	proc_selectChannels(epos{sbj_idx}, hEEG.delCH);

	% high pass filter
	db_attenuation		=	30;
	hp_cutoff			=	1;
	[z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sbj_idx}.fs/2), 'high');
	epos{sbj_idx}		=	proc_filt(epos{sbj_idx}, z,p,k);
end
%}

%% compute spectral features

% Here the spectral features are computed. For each trial I compute the
% power spectrum in the specified frequency range. The power in each
% frequency bin will become a feature used for classification

band					=	[ AllBOI{B}(1) AllBOI{B}(end) ];
sampling_freq			=	epos{1}.fs;
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
%fft_window	= hanning(2*sampling_freq);
fft_window		=	hanning(sampling_freq* (1/hEEG.FreqBins) ); %edited by tigoum

fprintf('\n\n --- computing spectal features ---\n\n')
for sbj_idx=1:n_subjects
	fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
	% feature extraction: apply FFT
	% figure, plot(fft_window)

%	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, band,				...
%								'Win', fft_window, 'Step', sampling_freq*0.5);
%	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, epos{sbj_idx}.band, ...
	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, band,				...
					'Win', fft_window, 'Step', sampling_freq*hEEG.FreqBins);

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
	freqs				=	epo_spec{1}.t;	% 주파수 구간: time이 아님!
fprintf('[*] frequency bin is %f\n', freqs(2)-freqs(1)); % added by tigoum
%fprintf('[*] frequency bin is %f\n', hEEG.FreqBins); % added by tigoum
fprintf('done\n')



%% get crossvalidation performance

% Here I do the crossvalidation to determine how well the classifier can
% discriminate between the classes. 

fprintf('\n\n --- starting crossvalidation ---\n\n')

%n_folds	= % 4 folds because there were 4 blocks in the experiment. Since
				% the trials are in chronological order, this crossvalidation
				% corresponds to leave-one-block-out crossvalidation
loss_all	=	zeros(1,n_subjects);
%loss_all_shuffled = zeros(1,n_subjects);
loss_sfl	=	zeros(1,n_subjects);

c_out		=	zeros(n_classes, n_epos, n_subjects);
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
						'SampleFcn', {@sample_chronKFold, hEEG.nFolds});
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
						'SampleFcn', {@sample_chronKFold, hEEG.nFolds});
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
title({'decoding accuracy',												...
		sprintf('[%0.1f~%0.1f]', AllBOI{B}(1), AllBOI{B}(end) ),	...
		sprintf(' for condition "%s"', strrep(condi,'_','-'))	})
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
%sbj_label	=	arrayfun(@(x)({ num2str(x) }), sbj_list);	% ex) '1' '2' ..
sbj_label	=	cellfun(@(x)({ regexprep(x, 'su0*', '') }), sbj_list); %ex)'1'..
sbj_label{end+1}	=	'avg';
set(gca, 'xtickLabel', sbj_label)
%--------------------------------------------------------------------------------
ylim([0,105])

if save_figs
    fname	=	sprintf('[%04.1f~%04.1f]_%s__decoding_accuracy',			...
					AllBOI{B}(1), AllBOI{B}(end), condi);
	fname	=	regexprep(fname, '[.]', ',');		% convert '.' -> ','
    my_save_fig(gcf, fullfile(fig_dir, fname), 15, 10)
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
end % for b
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%delete(POOL);

toc(AllRun);

nProc	=	n_subjects;
return
