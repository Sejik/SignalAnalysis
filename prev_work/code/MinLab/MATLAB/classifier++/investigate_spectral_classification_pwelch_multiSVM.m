function [ nProc ]	=	investigate_spectral_classification_pwelch_multiSVM( ...
							hEEG, condi, epos, verbose)
%% pwelch & SVM기반 classification에 의한 각 subject 별 accuracy 를 산출함.
clearvars -except hEEG condi epos verbose
%close all

%--------------------------------------------------------------------------------
%% set some paramters

%--------------------------------------------------------------------------------
%sbj_list = 1:14; % list of subject indices

%--------------------------------------------------------------------------------
%% edited by tigoum
AllRun		=	tic;

%% 20160229A. 세션 데이터의 합침 or 분리 계산 방식 도입
if	~isfield(hEEG, 'CurFold'),	sFold	=	'';
else,							sFold	=	num2str(hEEG.CurFold);			end

%% 20160302A. 세션 데이터와 (crossvalidation)용 fold 갯수의 분리 시도
if	isfield(hEEG, 'nFolds'),	nFolds	=	hEEG.nFolds;
else,							nFolds	=	max( cell2mat(hEEG.lFolds) );	end

%% the experiment condi that is to be classified
sbj_list	=	hEEG.Inlier;
%sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live
%--------------------------------------------------------------------------------

% the range of frequencies to be considered as features
%band = [4,30];										% 4Hz ~ 30Hz
n_subjects	=	length(sbj_list);
save_figs	=	1; % save figures or not

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir	=	'/home/sven/data/Results/SSVEP_MIN/figs/decoding_accuracy';
fig_dir		=	[ hEEG.PATH '/Results/figs/decoding_accuracy'];
fig_dir		=	fullfile(fig_dir, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir')), mkdir(fig_dir); end

if isfield(hEEG, 'COI'), fgCOI = 1; else, fgCOI = 0; end	% must be exist!

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% band or BOI 를 기준으로 각 대역별로 별도 accuracy 계산해야 더 정확도 높음
%	단, window 추가
fBin					=	hEEG.FreqBins;
AllBOI	=	{hEEG.BOI{:} hEEG.FreqWindow(1):fBin:hEEG.FreqWindow(end)};
for B = 1:length(AllBOI)
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%% load the data
%{
%epos = cell(1,n_subjects);
parfor sj_ix=1:n_subjects
	fprintf('filtering subject %s\n', sbj_list{sj_ix})

	% take only the scalp channels, remove EOG channels
	epos{sj_ix}		=	proc_selectChannels(epos{sj_ix}, hEEG.delCH);

	% high pass filter
	db_attenuation		=	30;
	hp_cutoff			=	1;
	[z,p,k] = cheby2(4, db_attenuation, hp_cutoff/(epos{sj_ix}.fs/2), 'high');
	epos{sj_ix}		=	proc_filt(epos{sj_ix}, z,p,k);
end
%}

%% 파라미터로 받은 데이터가 EOG를 포함한 데이터인 경우, EOG 데이터만 분리해서
%	별도로 구성해 둠. 물론 원본 데이터에서 EOG를 제외 할 것.
%if size(epos{1}.x,2) == hEEG.nChannel+length(hEEG.ChSide)	% EOG 추가 임.
if length(find( ismember(epos{1}.clab, hEEG.ChSide) )) > 0	% EOG 추가 임.
	SdPos	=	find( ismember(epos{1}.clab, hEEG.ChSide));
	ChPos	=	find(~ismember(epos{1}.clab, hEEG.ChSide));

	eOrg	=	epos;
	eSide	=	eOrg;

	parfor sj_ix=1:n_subjects
	eSide{sj_ix}.clab	=	hEEG.ChSide;					% label 교정
	eSide{sj_ix}.x	=	epos{sj_ix}.x(:,SdPos,:);		% EOG 데이터만

	epos{sj_ix}.clab	=	eOrg{sj_ix}.clab(ChPos);		% EOG 제거
	epos{sj_ix}.x		=	eOrg{sj_ix}.x(:,ChPos,:);		% EOG 제외 data
	end

	clear eOrg
end



%% compute canonical correlation analysis (CCA) accuracy
if fgCOI													% CCA 용 data
fprintf('\n\n --- starting canonical correlation analysis ---\n\n')

%condition에 따라, COI를 선택해서 수행해야 함
nCondi		=	find(ismember(hEEG.Condi, condi));
loss_cca	=	zeros(1,n_subjects);

try, parfor sj_ix = 1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sj_ix, n_subjects)

	% CCA 를 구동하여 AllBOI{B} 에 속한 주파수에 대응하는 매칭 정도 파악
%	[loss_cca, loss4Chan, corr4Chan] = H03CCA_AmH(epos{sj_ix},hEEG.COI{B});
	% classes 의 최대값과 marker 의 일치성 수준을 토대로 accuracy 계산
%	[ loss_cca(sj_ix), ~, ~]	=	H03CCA_AmH(epos{sj_ix}.x,				...
%					epos{sj_ix}.fs, epos{sj_ix}.marker, hEEG.COI{B});
	[ loss_cca(sj_ix), ~, ~]	=	H03CCA_AmH(epos{sj_ix}.x,				...
					epos{sj_ix}.fs, epos{sj_ix}.marker, hEEG.COI{nCondi});

	fprintf(' -> loss CCA = %g\n', loss_cca(sj_ix))

end, catch	exception
	disp(exception.message)
	% disp(exception.message) == 인덱스가 행렬의 차원을 초과합니다
	% 이 문제는 20160221A 와 관련된 것으로서, LDA를 대상으로 whole 범위 freq를
	% 다룰 경우, BOI 에는 존재하지만, COI 에는 해당 데이터가 존재치 않게 됨
	fprintf(['Warning : processing impossible for continuously freq section ' ...
			'[%05.2f ~ %05.2f]\n' ], AllBOI{B}(1), AllBOI{B}(end));
	fgCOI	=	0;
BREAK
end
end



%% compute spectral features

% Here the spectral features are computed. For each trial I compute the
% power spectrum in the specified frequency range. The power in each
% frequency bin will become a feature used for classification

band					=	[ AllBOI{B}(1) AllBOI{B}(end) ];
fSmpl					=	epos{1}.fs;
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
%fft_window				=	hanning(2*fSmpl);
%fft_window				=	hanning(fSmpl* (1/fBin) ); %edited by tigoum

fprintf('\n\n --- computing spectal features ---\n\n')
parfor sj_ix=1:n_subjects
	fprintf('processing sbj %02d/%02d\n', sj_ix, n_subjects)
	% feature extraction: apply FFT
	% figure, plot(fft_window)

%	epo_spec{sj_ix}	=	proc_spectrum(epos{sj_ix}, band,				...
%								'Win', fft_window, 'Step', fSmpl*0.5);
%	epo_spec{sj_ix}	=	proc_spectrum(epos{sj_ix}, epos{sj_ix}.band, ...
%	epo_spec{sj_ix}	=	proc_spectrum(epos{sj_ix}, band,				...
%					'Win', fft_window, 'Step', fSmpl*fBin);
	%% proc_spectrum 은 내부에서 epo_spec 의 member var 설정해주므로 대응 작업
%{
	[Pxx,F]		=	pwelch(X,WINDOW,NOVERLAP,NFFT,Fs) returns a PSD computed %-[
		as a function of physical frequency. Fs is the sampling frequency
		specified in hertz. If Fs is empty, it defaults to 1 Hz.

		F is the vector of frequencies (in hertz) at which the PSD is estimated.
		For real signals, F spans the interval [0,Fs/2] when NFFT is even
		and [0,Fs/2) when NFFT is odd.
		For complex signals, F always spans the interval [0,Fs).

		tigoum: Thus, NFFT is frequency bins == fs / NFFT

	 [Pxx,F]	=	pwelch(X,WINDOW,NOVERLAP,F,Fs) computes the two-sided PSD at
		the frequencies contained in the vector F.  F must have at least two
		elements and be expressed in hertz.

		x - vector | matrix; Input signal,
		specified as a row or column vector, or as a matrix.
		If x is a matrix, then its columns are treated as independent channels.

		f - vector: Cyclical frequencies,
		specified as a row or column vector with at least 2 elements.
		The frequencies are in cycles per unit time.
		The unit time is specified by the sampling frequency, fs.
		If fs has units of samples/second, then f has units of Hz.

		Example: fs = 1000; f= [100 200]

	% ex code:
	for ch = 1 : size(epos{sj_ix}.x, 2)						% 각 ch 단위 계산
	for ep = 1 : size(epos{sj_ix}.x, 3)						% 각 ep 단위 계산
		[PSD2(:,ch,ep), fa]=	pwelch(epo(:,ch,ep), [], [], fSmpl*2, fSmpl);
	end
	end	%-]
%}
%%	epo_spec{sj_ix}	=	proc_pwelch(epos{sj_ix},[],[], fSmpl*2,fSmpl);
%%	[PSD(ch,fq), fa]	=	pwelch(epos{sj_ix}(tp,ch,ep),[],[], fSmpl*4,fSmpl);
	PSD = zeros(fSmpl/2 /fBin +1, size(epos{1}.x,2), size(epos{1}.x,3)); % f 범위
	fa		=	zeros(fSmpl/2 /fBin +1);
	for ep = 1 : size(epos{sj_ix}.x, 3)						% 각 ep 단위 계산
		[PSD(:,:,ep), fa]=	pwelch(epos{sj_ix}.x(:,:,ep),[],[],fSmpl/fBin,fSmpl);
	end
%	if fa(2)-fa(1) ~= fBin
%		fprintf('\nWaring  : mismatch bin(%f) for frequency\n', fa(2)-fa(1));
%	end
	epo_spec{sj_ix}		=	epos{sj_ix};					% epo_spec 생성
	epo_spec{sj_ix}.t	=	[band(1):fBin:band(2)];
	epo_spec{sj_ix}.x	=	PSD(ismember(fa, epo_spec{sj_ix}.t),:,:);
	epo_spec{sj_ix}.xUnit=	'Hz';
	epo_spec{sj_ix}.yUnit=	'dB';

	% EOG 성분
%	eSd_spec{sj_ix}	=	proc_spectrum(eSide{sj_ix}, band,				...
%					'Win', fft_window, 'Step', fSmpl*fBin);
	PSD		=	zeros(fSmpl/2 /fBin +1,size(eSide{1}.x,2),size(eSide{1}.x,3));
	fa		=	zeros(fSmpl/2 /fBin +1);
	for ep = 1 : size(eSide{sj_ix}.x, 3)					% 각 ep 단위 계산
		[PSD(:,:,ep), fa]= pwelch(eSide{sj_ix}.x(:,:,ep),[],[],fSmpl/fBin,fSmpl);
	end
	eSd_spec{sj_ix}		=	eSide{sj_ix};					% epo_spec 생성
	eSd_spec{sj_ix}.t	=	[band(1):fBin:band(2)];
	eSd_spec{sj_ix}.x	=	PSD(ismember(fa, eSd_spec{sj_ix}.t),:,:);
	eSd_spec{sj_ix}.xUnit=	'Hz';
	eSd_spec{sj_ix}.yUnit=	'dB';

	%---------------------------------------------------------------------------
	%% 20160202A. 기존 [a b] 구간의 전체 주파수 성분을 모두 조사방식 변경
	% 그래서, 구간 중 일부 주파수 성분만 조사할 수 있도록 변경
	if ~isequal(epo_spec{sj_ix}.t, AllBOI{B})	% 구간 중 일부 요소 제외 형태
		[~, ix]		=	ismember(AllBOI{B}, epo_spec{sj_ix}.t);
		epo_spec{sj_ix}.x	=	epo_spec{sj_ix}.x(ix,:,:);

		fprintf('   + reprocessing freq. parts: [%s]\n',					...
			strjoin( arrayfun(@(x)({num2str(x)}), AllBOI{B}), ', ') );
	end

	% 다음은 EOG 성분
	if ~isequal(eSd_spec{sj_ix}.t, AllBOI{B})	% 구간 중 일부 요소 제외 형태
		[~, ix]		=	ismember(AllBOI{B}, eSd_spec{sj_ix}.t);
		eSd_spec{sj_ix}.x	=	eSd_spec{sj_ix}.x(ix,:,:);

		fprintf('   + reprocessing freq. parts: [%s]\n',					...
			strjoin( arrayfun(@(x)({num2str(x)}), AllBOI{B}), ', ') );
	end

	% Win == size(fft_window) == 1000
	% Step == fSmpl / 2 == epos{}.fs / 2 == 500 / 2 == 250
	% therefore, freq's bins = epos{}.fs / Win = 500 / 1000 = 1/2
%	[n_freq_bins, n_channels, n_epos] = size(epo_spec{sj_ix}.x);
%	n_classes = size(epo_spec{sj_ix}.y,1);

	% reshape the channel-wise spectra to obtain feature vectors
	fv{sj_ix}			=	proc_flaten(epo_spec{sj_ix});
	fS{sj_ix}			=	proc_flaten(eSd_spec{sj_ix});
end
	% parfor 로 구동시킬 경우, 내부에서 발생하는 변수는 scope에 의해 소멸됨
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{1}.x);
	n_classes			=	size(epo_spec{1}.y, 1);
	if n_classes == 2, n_classes = 1; end	% 자유도 고려, 2개면 한쪽만 알면 됨
	freqs				=	epo_spec{1}.t;	% 주파수 구간: time이 아님!
fprintf('[*] frequency bin is %f\n', freqs(2)-freqs(1)); % added by tigoum
%fprintf('[*] frequency bin is %f\n', fBin); % added by tigoum
fprintf('done\n')



%% get crossvalidation performance

% Here I do the crossvalidation to determine how well the classifier can
% discriminate between the classes. 

fprintf('\n\n --- starting crossvalidation ---\n\n')
fprintf('\n+ Info: %d Folds-Data, %d force-Folds, %f Trial(%d)/force-Folds\n',...
 length(cell2mat(hEEG.lFolds)), nFolds, size(fv{1}.x,2)/nFolds, size(fv{1}.x,2));
%n_folds	= % 4 folds because there were 4 blocks in the experiment. Since
				% the trials are in chronological order, this crossvalidation
				% corresponds to leave-one-block-out crossvalidation
loss_all	=	zeros(1,n_subjects);
%loss_all_shuffled = zeros(1,n_subjects);
loss_sfl	=	zeros(1,n_subjects);
loss_side	=	zeros(1,n_subjects);
fgUseLDA	=	0;
fgUseSVM	=	1;

%%c_out		=	zeros(n_classes, n_epos, n_subjects);
for sj_ix = 1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sj_ix, n_subjects)

	fv_sbj			=	fv{sj_ix};
if fgUseLDA
	% apply crossvalidation using a regularized LDA classifer (see the
	% function train_RLDA_shrink.m) and chronological crossvalidation
%	[loss_all(sj_ix), ~, cout_tmp]	=	crossvalidation(fv{sj_ix}, ...
%								@train_RLDAshrink, ...
%								'SampleFcn', {@sample_KFold, n_folds});
	% change to RANDOMLY(==@sample_KFold)
	[loss_all(sj_ix), ~, cout_tmp]	=	crossvalidation(fv_sbj, ...
						@train_RLDAshrink, ...
						'SampleFcn', {@sample_chronKFold, nFolds});
elseif fgUseSVM
%{
	%% Train [ one-against-all ] models: approach 1	%-[
model			= cell(numLabels,1);
for k=1:numLabels
	model{k} = libsvmtrain(double(trainLabel==k), trainData, '-c 1 -g 0.2 -b 1');
end

%# Get probability estimates of test instances using each model
prob			= zeros(numTest,numLabels);
for k=1:numLabels
	[~,~,p]		= svmpredict(double(testLabel==k), testData, model{k}, '-b 1');
	prob(:,k)	= p{k}(:,model{k}.Label==1);	% Probability of class==k
end

% Predict the class with the highest probability
[~,pred]		= max(prob,[],2);
acc				= sum(pred == testLabel) ./ numel(testLabel);	% Accuracy
C				= confusionmat(testLabel, pred); % Confusion matrix	%-]
%}
	%% Train [ one-against-all ] models: approach 2
	% how to fold making for fv_sbj.{x,y} ?
	% 4 fold case: fore part 3 fold to be set train data, last part to test.
%{
	BlkSize			=	size(fv_sbj.x,2)/nFolds;
	trainData		=	fv_sbj.x(:, 1:BlkSize *(nFolds-1))';
	testData		=	fv_sbj.x(:, BlkSize *(nFolds-1)+1:BlkSize *nFolds)';
	trainLabel		=	fv_sbj.y(:, 1:BlkSize *(nFolds-1))';
	testLabel		=	fv_sbj.y(:, BlkSize *(nFolds-1)+1:BlkSize *nFolds)';
%}
	[labels, ~]		=	find(fv_sbj.y);						% a one on bitmap
%	labels			=	labels';							% vector
	%----------
	%% for crossvailidation
	acc(sj_ix)		=	libsvmtrain(labels, fv_sbj.x', '-t 0 -c 1 -v 9');
	loss_all(sj_ix)	=	1 - max(acc(sj_ix)) / 100;
end
%		whos cout_tmp
%	Name          Size               Bytes  Class     Attributes
%	cout_tmp      6x1x240            11520  double    
%	c_out(:,:,sj_ix)					=	squeeze(cout_tmp);
	fprintf(' -> loss LDA = %g\n', loss_all(sj_ix))

	%% repeat the crossvalidation with the same parameters but shuffle the
	% labels of the trials. This way we get an estimate of the chance level.
	fv_sbj.y		=	fv_sbj.y(:,randperm(n_epos));
if fgUseLDA
%	loss_sfl(sj_ix)					=		...
%		crossvalidation(fv_tmp,		@train_RLDAshrink,	...
%									'SampleFcn', {@sample_KFold, n_folds});
	loss_sfl(sj_ix)					=		...
		crossvalidation(fv_sbj,			@train_RLDAshrink,	...
						'SampleFcn', {@sample_chronKFold, nFolds});
elseif fgUseSVM
	%% Train [ one-against-all ] models: approach 2
	% how to fold making for fv_sbj.{x,y} ?
	% 4 fold case: fore part 3 fold to be set train data, last part to test.
%{
	BlkSize			=	size(fv_sbj.x,2)/nFolds;
	trainData		=	fv_sbj.x(:, 1:BlkSize *(nFolds-1))';
	testData		=	fv_sbj.x(:, BlkSize *(nFolds-1)+1:BlkSize *nFolds)';
	trainLabel		=	fv_sbj.y(:, 1:BlkSize *(nFolds-1))';
	testLabel		=	fv_sbj.y(:, BlkSize *(nFolds-1)+1:BlkSize *nFolds)';
%}
	[labels, ~]		=	find(fv_sbj.y);						% a one on bitmap
	%----------
	%% for crossvailidation
	acc(sj_ix)		=	libsvmtrain(labels, fv_sbj.x', '-t 0 -c 1 -v 9');
	loss_sfl(sj_ix)	=	1 - max(acc(sj_ix)) / 100;
end
	fprintf(' -> loss LDA (shuffled labels) = %g\n', loss_sfl(sj_ix))

	%% processing the EOG(+ other side) channel data alone.
	loss_side(sj_ix)					=		...
		crossvalidation(fS{sj_ix},	@train_RLDAshrink,	...
						'SampleFcn', {@sample_chronKFold, nFolds});
	fprintf(' -> loss Side-Ch (%s) = %g\n', strjoin(hEEG.ChSide, ', '), ...
													loss_side(sj_ix));
end



% turn loss into accuracy
if fgCOI
	accuracy_cca	=	1 - loss_cca;
	fprintf('accuracies CCA averaged across subjects:\n')
%	mean(accuracy_cca, 2);
end

accuracy			=	1 - loss_all;
fprintf('accuracies LDA averaged across subjects:\n')
%mean(accuracy, 2);

fprintf('accuracies LDA (shuffled labels), averaged across subjects:\n')
accuracy_shuffled	=	1 - loss_sfl;
%mean(accuracy_shuffled, 2);

fprintf('accuracies (side chan), averaged across subjects:\n')
accuracy_side		=	1 - loss_side;
%mean(accuracy_side, 2);



%% visualize classification performance
if fgCOI
	acc		=	[accuracy; accuracy_shuffled; accuracy_side; accuracy_cca]';
	labels	=	{'rLDA', 'rLDA(shuffled)', hEEG.ChSide{1}, 'CCA'};
else
	acc		=	[accuracy; accuracy_shuffled; accuracy_side]';
	labels	=	{'rLDA', 'rLDA(shuffled)', hEEG.ChSide{1}};
end

figure
h			=	bar(100*[acc; mean(acc,1)]);	% 핸들 2개 : rLDAx & shuffle
hold on
%legend(labels, 'location', 'best')
%legend(labels, 'location', 'bestoutside')
hLgn = legend(labels, 'location', 'southoutside', 'orientation', 'horizontal');
%{
hAnno	=	get(hLgn,	'Annotation');
hLgnEnt	=	get(hAnno,	'LegendInformation');
hIcon	=	get(hLgnEnt,'IconDisplayStyle');
hChild	= get(hIcon,'Children') % Get the legend contents
set(hc(3),'Rotation',90); % Relocate and rotate text
set(hc(2),'Xdata',[0.5 0.5],'YData',[0.1 0.5]); % rotate the line
set(hc(1),'XData',0.5,'YData',0.3); % Rotate the Marker
%}
%% 구간이 whole 인지, sparse 인지 구분해야 함.
if isequal(AllBOI{B}, [AllBOI{B}(1): fBin :AllBOI{B}(end)])	% 등간격
	gapFreq	=	sprintf('[%04.1f~%04.1f]', AllBOI{B}(1), AllBOI{B}(end) );
else
	gapFreq	=	sprintf('[%04.1f,Sparse,%04.1f]', AllBOI{B}(1), AllBOI{B}(end) );
end
title({'decoding accuracy',													...
		gapFreq,															...
		sprintf(' for condition "%s" %s', strrep(condi,'_','-'), sFold)	})
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
yb			=	cat(1, h.YData);						% vector 들을 하나로 연결
xb			=	bsxfun(@plus, h(1).XData, [h.XOffset]');	%x bar별 중간위치
%xb			=	xb + (h(1).BarWidth*h(1).XOffset./((Y<100)+2))'; % non rotate
hold on;
for a = 1:size(yb,2)										% # of subject
	for b = 1:length(yb(:,1))								% # of bar / sbj
%		text(xb(b, a),yb(b, a), cellstr(num2str(yb(b, a))),					...
		text(xb(b, a),yb(b, a)+0.2, sprintf('%.3f',yb(b, a)),				...
			'FontSize',4,	'Color','K',	'Rotation', 90,					...
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
%	[rLDA Shuffle EOG]	=	deal(yb(1,:), yb(2,:), yb(3,:));
%	[ p table ]			=	anova_rm({ rLDA Shuffle EOG }, 'off'); %must disp off

	%% output text table for statistical analysis
	dat		=	arrayfun(@(x)({ sprintf('%f', x) }), yb )';	% transpose
	dat		=	cat(1, labels, dat);						% cat to 1 cell
	lSbj	=	{ 'subject' sbj_list{:} 'average' };
	txt		=	cellfun(@(x,y)( {strjoin({x y{:}}, '\t')} ),	lSbj,	...
				arrayfun(@(x)( { dat(x,:) } ), [1:size(dat, 1)]) );

    fname	=	sprintf('%s%s%s__decoding_accuracy', gapFreq, condi, sFold);
	fname	=	regexprep(fname, '[.]', ',');		% convert '.' -> ','
	fp		=	fopen([ fullfile(fig_dir, fname) '.txt'], 'w');
	cellfun(@(x)( fprintf(fp, '%s\n', char(x)) ), txt);
	fclose(fp);

	%% output pdf for topo
%	fname	=	sprintf('[%04.1f~%04.1f]_%s__decoding_accuracy',			...
%					AllBOI{B}(1), AllBOI{B}(end), condi);
%	fname	=	regexprep(fname, '[.]', ',');		% convert '.' -> ','
    my_save_fig(gcf, fullfile(fig_dir, fname), 15, 10)
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
end % for b
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%delete(POOL);

toc(AllRun);

nProc	=	n_subjects;
return
