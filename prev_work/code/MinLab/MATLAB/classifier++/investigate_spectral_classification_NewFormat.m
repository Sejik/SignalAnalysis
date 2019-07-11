function [ nProc ]	=	investigate_spectral_classification_NewFormat(	...
							hEEG, epos, verbose)
%% FFT & rLDA ��� classification�� ���� �� subject �� accuracy �� ������.
clearvars -except hEEG epos verbose
%close all

%--------------------------------------------------------------------------------
%% set some paramters

%--------------------------------------------------------------------------------
%sbj_list = 1:14; % list of subject indices

%--------------------------------------------------------------------------------
%% edited by tigoum
AllRun		=	tic;

%% 20160229A. ���� �������� ��ħ or �и� ��� ��� ����
if	~isfield(hEEG, 'CurFold'),	sFold	=	'';
else,							sFold	=	num2str(hEEG.CurFold);			end

%% 20160302A. ���� �����Ϳ� (crossvalidation)�� fold ������ �и� �õ�
if	isfield(hEEG, 'nFolds'),	nFolds	=	hEEG.nFolds;
else,							nFolds	=	max( cell2mat(hEEG.lFolds) );	end

%% the experiment cond that is to be classified
cond		=	hEEG.CurCond;
sbj_list	=	hEEG.Inlier;
%sbj_list	=	all_list(find(~ismember(all_list, exc_list)));	% only live
%--------------------------------------------------------------------------------

% the range of frequencies to be considered as features
%band = [4,30];										% 4Hz ~ 30Hz
n_subjects	=	length(sbj_list);
save_figs	=	1; % save figures or not

% HERE YOU HAVE TO SPECIFY A FOLDER WHERE TO SAVE THE OUTPUT PLOT
%fig_dir	=	'/home/sven/data/Results/SSVEP_MIN/figs/decoding_accuracy';
%fig_dir		=	[ hEEG.PATH '/Results/figs/decoding_accuracy'];
fig_dir		=	fullfile(hEEG.Dest, 'decoding_accuracy');
if save_figs && not(exist(fig_dir, 'dir')), mkdir(fig_dir); end

if isfield(hEEG, 'COI'), fgCOI = 1; else, fgCOI = 0; end	% must be exist!

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% band or FOI �� �������� �� �뿪���� ���� accuracy ����ؾ� �� ��Ȯ�� ����
%	��, window �߰�
eOrg		=	epos;										% ���� ���� !
fBin		=	hEEG.FreqBins;
AllFOI	=	{hEEG.FOI{:} hEEG.FreqWindow(1):hEEG.FreqBins:hEEG.FreqWindow(end)};
%AllFOI	=	table2cell(unique(cell2table(AllFOI')))';		% ��ұ��� ���� ����
AllFOI	=	cellfun(@(x) { num2str(x) }, AllFOI);			% ���ڿ� cell�� ��ȯ
AllFOI	=	unique(AllFOI);									% �ߺ�����
AllFOI	=	cellfun(@(x) { str2num(x) }, AllFOI);			% �ٽ� matrix ��ȯ
for B	=	1:length(AllFOI)
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

%% �Ķ���ͷ� ���� �����Ͱ� EOG�� ������ �������� ���, EOG �����͸� �и��ؼ�
%	������ ������ ��. ���� ���� �����Ϳ��� EOG�� ���� �� ��.
%if size(epos{1}.x,2) == hEEG.nChannel+length(hEEG.ChSide)	% EOG �߰� ��.
if length(find( ismember(eOrg{1}.clab, hEEG.ChSide) )) > 0	% EOG �߰� ��.
	SdPos	=	find( ismember(eOrg{1}.clab, hEEG.ChSide));
	ChPos	=	find(~ismember(eOrg{1}.clab, hEEG.ChSide));

%	eOrg	=	epos;
	eSide	=	eOrg;

	parfor sj_ix=1:n_subjects
	eSide{sj_ix}.clab	=	hEEG.ChSide;					% label ����
	eSide{sj_ix}.x		=	eOrg{sj_ix}.x(:,SdPos,:);		% EOG �����͸�

	epos{sj_ix}.clab	=	eOrg{sj_ix}.clab(ChPos);		% EOG ����
	epos{sj_ix}.x		=	eOrg{sj_ix}.x(:,ChPos,:);		% EOG ���� data
	end

%	clear eOrg
else														% EOG ���� ����!
	epos	=	eOrg;
	eSide	=	cell(size(eOrg));
end



%% compute canonical correlation analysis (CCA) accuracy
if fgCOI													% CCA �� data
fprintf('\n\n --- starting canonical correlation analysis ---\n\n')

%condtion�� ����, COI�� �����ؼ� �����ؾ� ��
nCondi		=	find(ismember(hEEG.Condi, cond));
loss_cca	=	zeros(1,n_subjects);

try, parfor sj_ix = 1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sj_ix, n_subjects)

	% CCA �� �����Ͽ� AllFOI{B} �� ���� ���ļ��� �����ϴ� ��Ī ���� �ľ�
%	[loss_cca, loss4Chan, corr4Chan] = H03CCA_AmH(epos{sj_ix},hEEG.COI{B});
	% classes �� �ִ밪�� marker �� ��ġ�� ������ ���� accuracy ���
%	[ loss_cca(sj_ix), ~, ~]	=	H03CCA_AmH(epos{sj_ix}.x,				...
%					epos{sj_ix}.fs, epos{sj_ix}.marker, hEEG.COI{B});
	[ loss_cca(sj_ix), ~, ~]	=	H_CCA(epos{sj_ix}.x,				...
					epos{sj_ix}.fs, epos{sj_ix}.marker, hEEG.COI{nCondi});

	fprintf(' -> loss CCA = %g\n', loss_cca(sj_ix))

end, catch	exception
	disp(exception.message)
	% disp(exception.message) == �ε����� ����� ������ �ʰ��մϴ�
	% �� ������ 20160221A �� ���õ� �����μ�, LDA�� ������� whole ���� freq��
	% �ٷ� ���, FOI ���� ����������, COI ���� �ش� �����Ͱ� ����ġ �ʰ� ��
	fgCOI	=	0;
	error(['Warning : processing impossible for continuously freq section ' ...
			'[%05.2f ~ %05.2f]\n' ], AllFOI{B}(1), AllFOI{B}(end));
end
end



%% compute spectral features

% Here the spectral features are computed. For each trial I compute the
% power spectrum in the specified frequency range. The power in each
% frequency bin will become a feature used for classification

fgUseFFT				=	true;
fgUsePWELCH				=	~fgUseFFT;

band					=	[ AllFOI{B}(1) AllFOI{B}(end) ];
fSmpl					=	epos{1}.fs;
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
eSd_spec				=	cell(1,n_subjects);
%fft_window	= hanning(2*fSmpl);
fft_window		=	hanning(fSmpl* (1/hEEG.FreqBins) ); %edited by tigoum

fprintf('\n\n --- computing spectal features ---\n\n')
for sj_ix=1:n_subjects			% 30 ä�� �̻󿡼� parfor ���� threshing �߻�!
	fprintf('processing sbj %02d/%02d: Loc(%s), Freq(%s)\n',		...
			sj_ix, n_subjects,	strjoin(epos{sj_ix}.clab, ','),		...
			strjoin(arrayfun(@(x)({ num2str(x) }), AllFOI{B}), ',') );
	% feature extraction: apply FFT
	% figure, plot(fft_window)

%	epo_spec{sj_ix}	=	proc_spectrum(epos{sj_ix}, band,				...
%								'Win', fft_window, 'Step', fSmpl*0.5);
%	epo_spec{sj_ix}	=	proc_spectrum(epos{sj_ix}, epos{sj_ix}.band, ...
if fgUseFFT
	epo_spec{sj_ix}	=	proc_spectrum(epos{sj_ix}, band,				...
					'Win', fft_window, 'Step', fSmpl*hEEG.FreqBins);

	% EOG ����
	if ~isempty(eSide{sj_ix})
	eSd_spec{sj_ix}	=	proc_spectrum(eSide{sj_ix}, band,				...
					'Win', fft_window, 'Step', fSmpl*hEEG.FreqBins);
	else
	eSd_spec{sj_ix}	=	[];
	end

elseif fgUsePWELCH		%-[
	%% proc_spectrum �� ���ο��� epo_spec �� member var �������ֹǷ� ���� �۾�
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
	for ch = 1 : size(epos{sj_ix}.x, 2)						% �� ch ���� ���
	for ep = 1 : size(epos{sj_ix}.x, 3)						% �� ep ���� ���
		[PSD2(:,ch,ep), fa]=	pwelch(epo(:,ch,ep), [], [], fSmpl*2, fSmpl);
	end
	end	%-]
%}
%%	epo_spec{sj_ix}	=	proc_pwelch(epos{sj_ix},[],[], fSmpl*2,fSmpl);
%%	[PSD(ch,fq), fa]	=	pwelch(epos{sj_ix}(tp,ch,ep),[],[], fSmpl*4,fSmpl);
	PSD = zeros(fSmpl/2 /fBin +1, size(epos{1}.x,2), size(epos{1}.x,3)); % f ����
	fa		=	zeros(fSmpl/2 /fBin +1);
	for ep = 1 : size(epos{sj_ix}.x, 3)						% �� ep ���� ���
		[PSD(:,:,ep), fa]=	pwelch(epos{sj_ix}.x(:,:,ep),[],[],fSmpl/fBin,fSmpl);
	end
%	if fa(2)-fa(1) ~= fBin
%		fprintf('\nWaring  : mismatch bin(%f) for frequency\n', fa(2)-fa(1));
%	end
	epo_spec{sj_ix}		=	epos{sj_ix};					% epo_spec ����
	epo_spec{sj_ix}.t	=	[band(1):fBin:band(2)];
	epo_spec{sj_ix}.x	=	PSD(ismember(fa, epo_spec{sj_ix}.t),:,:);
	epo_spec{sj_ix}.xUnit=	'Hz';
	epo_spec{sj_ix}.yUnit=	'dB';

	% EOG ����
	if ~isempty(eSide{sj_ix})
	PSD		=	zeros(fSmpl/2 /fBin +1,size(eSide{1}.x,2),size(eSide{1}.x,3));
	fa		=	zeros(fSmpl/2 /fBin +1);
	for ep = 1 : size(eSide{sj_ix}.x, 3)					% �� ep ���� ���
		[PSD(:,:,ep), fa]= pwelch(eSide{sj_ix}.x(:,:,ep),[],[],fSmpl/fBin,fSmpl);
	end
	eSd_spec{sj_ix}		=	eSide{sj_ix};					% epo_spec ����
	eSd_spec{sj_ix}.t	=	[band(1):fBin:band(2)];
	eSd_spec{sj_ix}.x	=	PSD(ismember(fa, eSd_spec{sj_ix}.t),:,:);
	eSd_spec{sj_ix}.xUnit=	'Hz';
	eSd_spec{sj_ix}.yUnit=	'dB';
	else
	eSd_spec{sj_ix}		=	[];
	end		%-]
end

	%---------------------------------------------------------------------------
	%% 20160202A. ���� [a b] ������ ��ü ���ļ� ������ ��� ������ ����
	% �׷���, ���� �� �Ϻ� ���ļ� ���и� ������ �� �ֵ��� ����
	if ~isequal(epo_spec{sj_ix}.t, AllFOI{B})	% ���� �� �Ϻ� ��� ���� ����
		[~, ix]		=	ismember(AllFOI{B}, epo_spec{sj_ix}.t);
		epo_spec{sj_ix}.x	=	epo_spec{sj_ix}.x(ix,:,:);

		fprintf('   + reprocessing freq. parts: [%s]\n',					...
			strjoin( arrayfun(@(x)({num2str(x)}), AllFOI{B}), ', ') );
	end

	% ������ EOG ����
	if ~isempty(eSd_spec{sj_ix}) & ~isequal(eSd_spec{sj_ix}.t, AllFOI{B})
		% ���� �� �Ϻ� ��� ���� ����
		[~, ix]		=	ismember(AllFOI{B}, eSd_spec{sj_ix}.t);
		eSd_spec{sj_ix}.x	=	eSd_spec{sj_ix}.x(ix,:,:);

		fprintf('   + reprocessing freq. parts: [%s]\n',					...
			strjoin( arrayfun(@(x)({num2str(x)}), AllFOI{B}), ', ') );
	end

	% Win == size(fft_window) == 1000
	% Step == fSmpl / 2 == epos{}.fs / 2 == 500 / 2 == 250
	% therefore, freq's bins = epos{}.fs / Win = 500 / 1000 = 1/2
%	[n_freq_bins, n_channels, n_epos] = size(epo_spec{sj_ix}.x);
%	n_classes = size(epo_spec{sj_ix}.y,1);

	% reshape the channel-wise spectra to obtain feature vectors
	fv{sj_ix}			=	proc_flaten(epo_spec{sj_ix});
	if ~isempty(eSd_spec{sj_ix})
	fS{sj_ix}			=	proc_flaten(eSd_spec{sj_ix});
	else
	fS{sj_ix}			=	[];
	end
end
	% parfor �� ������ų ���, ���ο��� �߻��ϴ� ������ scope�� ���� �Ҹ��
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{1}.x);
	n_classes			=	size(epo_spec{1}.y, 1);
	if n_classes == 2, n_classes = 1; end				% 2���� ���ʸ� �˸� ��
		% ����: y�� 2 x epoch �϶�, train_RLDAshrink()�� �ڵ����� class ������
		% 2->1 �� downgrade ��Ŵ. ����, ������� classifier �� 1 x epoch ��!
	freqs				=	epo_spec{1}.t;	% ���ļ� ����: time�� �ƴ�!
fprintf('[*] frequency bin is %f\n', freqs(2)-freqs(1)); % added by tigoum
%fprintf('[*] frequency bin is %f\n', hEEG.FreqBins); % added by tigoum
fprintf('done\n')



%% get crossvalidation performance

% Here I do the crossvalidation to determine how well the classifier can
% discriminate between the classes. 
fprintf('\n\n --- starting crossvalidation ---\n\n')
fprintf('\n+ Info: %d Folds-Data, %d force-Folds, %f Trial(%d)/force-Folds\n',...
 length(cell2mat(hEEG.fFolds)), nFolds, size(fv{1}.x,2)/nFolds, size(fv{1}.x,2));
%n_folds	= % 4 folds because there were 4 blocks in the experiment. Since
				% the trials are in chronological order, this crossvalidation
				% corresponds to leave-one-block-out crossvalidation
loss_all	=	zeros(1,n_subjects);
%loss_all_shuffled = zeros(1,n_subjects);
loss_sfl	=	zeros(1,n_subjects);
loss_side	=	zeros(1,n_subjects);
loss_svm	=	zeros(1,n_subjects);

%%c_out		=	zeros(n_classes, n_epos, n_subjects);
parfor sj_ix = 1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sj_ix, n_subjects)

	fv_sbj			=	fv{sj_ix};
	%% apply crossvalidation using a regularized LDA classifer (see the
	% function train_RLDA_shrink.m) and chronological crossvalidation
%	[loss_all(sj_ix), ~, cout_tmp]	=	crossvalidation(fv{sj_ix}, ...
%								@train_RLDAshrink, ...
%								'SampleFcn', {@sample_KFold, n_folds});
	% change to RANDOMLY(==@sample_KFold)
	%	to % CHRONOLOGICAL(==@sample_chronKFold)
%	[loss_all(sj_ix), ~, cout_tmp]	=	crossvalidation(fv_sbj, ...
%						@train_RLDAshrink, ...
%						'SampleFcn', {@sample_chronKFold, hEEG.nFolds});
	[loss_all(sj_ix), ~, cout_tmp]	=	crossvalidation(fv_sbj, ...
						@train_RLDAshrink, ...
						'SampleFcn', {@sample_chronKFold, nFolds});
%		whos cout_tmp
%	Name          Size               Bytes  Class     Attributes
%	cout_tmp      6x1x240            11520  double    
%%	c_out(:,:,sj_ix)					=	squeeze(cout_tmp);
	fprintf(' -> loss LDA = %g\n', loss_all(sj_ix))

	%% repeat the crossvalidation with the same parameters but shuffle the
	% labels of the trials. This way we get an estimate of the chance level.
	fv_sbj.y		=	fv_sbj.y(:,randperm(n_epos));
%	loss_sfl(sj_ix)					=		...
%		crossvalidation(fv_tmp,		@train_RLDAshrink,	...
%									'SampleFcn', {@sample_KFold, n_folds});
	loss_sfl(sj_ix)					=		...
		crossvalidation(fv_sbj,			@train_RLDAshrink,	...
						'SampleFcn', {@sample_chronKFold, nFolds});
	fprintf(' -> loss LDA (shuffled labels) = %g\n', loss_sfl(sj_ix))

	%% processing the EOG(+ other side) channel data alone.
	if ~isempty(fS{sj_ix})
	loss_side(sj_ix)					=		...
		crossvalidation(fS{sj_ix},	@train_RLDAshrink,	...
						'SampleFcn', {@sample_chronKFold, nFolds});
	fprintf(' -> loss Side-Ch (%s) = %g\n', strjoin(hEEG.ChSide, ', '), ...
													loss_side(sj_ix));
	else
	loss_side(sj_ix)					=	1;		% ���� ����
	end

	%% processing the multi class SVM ----------------------------------------
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
	% 6���� bitmap ����(0 or 1) label�� class ����(1:6) label�� ��ȯ
	% ! �Ʒ� find ���� �ݵ�� row ���� ���ϱ� ���� ���ϰ��� 2�� ������ �ޱ�!
	[labels, ~]		=	find(fv{sj_ix}.y);				% a one on bitmap
%	labels			=	labels';							% vector
	%% for crossvailidation
	acc	=	libsvmtrain(labels, fv_sbj.x', ['-t 0 -c 1 -v ' num2str(nFolds)]);
	loss_svm(sj_ix)=	1 - max(acc) / 100;
	fprintf(' -> loss SVM = %g\n', loss_svm(sj_ix))
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

fprintf('accuracies SVM averaged across subjects:\n')
accuracy_svm		=	1 - loss_svm;



%% visualize classification performance
if fgCOI
%	acc		=	[accuracy; accuracy_shuffled; accuracy_side; accuracy_cca;	...
%				accuracy_svm ]';
%	labels	=	{'rLDA', 'rLDA(shuffled)', hEEG.ChSide{1}, 'CCA',			...
%				'SVM'};
%	lColor	=	[	[1 0 0]; [0 0 1]; [0 176/256 80/256];					...
%					[128/256 100/256 162/256]; [1 1 0] ];	% 5�� ����
	acc		=	[accuracy; accuracy_shuffled; accuracy_side; accuracy_cca; ]';
	labels	=	{'rLDA', 'rLDA(shuffled)', hEEG.ChSide{1}, 'CCA',};
	lColor	=	[	[1 0 0]; [0 0 1]; [0 176/256 80/256];					...
					[128/256 100/256 162/256] ];			% 4�� ����
else
	acc		=	[accuracy; accuracy_shuffled; accuracy_side;				...
				accuracy_svm ]';							% 20 x 4 ����
	labels	=	{'rLDA', 'rLDA(shuffled)', hEEG.ChSide{1},					...
				'SVM'};
	lColor	=	[	[1 0 0]; [0 0 1]; [0 176/256 80/256];					...
					[128/256 100/256 162/256] ];			% 4�� ����
end

FontSize	=	8;
figure('Position',[0 0 1024 576]);

h			=	bar(100*[acc; mean(acc,1)]);		% �ڵ� 2�� : rLDAx & shuffle
hold on
for ix = 1:size(acc,2), h(ix).FaceColor=lColor(ix,:); end	% ���� ����

%legend(labels, 'location', 'best')
%legend(labels, 'location', 'bestoutside')
hLgn = legend(labels, 'location','southoutside', 'orientation','horizontal', ...
					'fontsize',FontSize);
%{
hAnno	=	get(hLgn,	'Annotation');
hLgnEnt	=	get(hAnno,	'LegendInformation');
hIcon	=	get(hLgnEnt,'IconDisplayStyle');
hChild	= get(hIcon,'Children') % Get the legend contents
set(hc(3),'Rotation',90); % Relocate and rotate text
set(hc(2),'Xdata',[0.5 0.5],'YData',[0.1 0.5]); % rotate the line
set(hc(1),'XData',0.5,'YData',0.3); % Rotate the Marker
%}
%% ������ whole ����, sparse ���� �����ؾ� ��.
if isequal(AllFOI{B}, [AllFOI{B}(1): hEEG.FreqBins :AllFOI{B}(end)])	% ���
	gapFreq	=	sprintf('[%04.1f~%04.1f]', AllFOI{B}(1), AllFOI{B}(end) );
else
	gapFreq	=	sprintf('[%04.1f,Sparse,%04.1f]', AllFOI{B}(1), AllFOI{B}(end) );
end
title({['decoding accuracy: ' gapFreq 'Hz'],								...
		sprintf(' for condtion "%s" [fold: %s]', strrep(cond,'_','-'), sFold) })
xlabel('Participants')
ylabel(sprintf('Decoding accuracy (%%: %d-class)', n_classes))
set(gca, 'xTick',1:n_subjects+1)
set(gca, 'TickDir','Out', 'TickLength',[0 0])	% tick ��輱�� �۹���, ���� ����
set(gca, 'yGrid','on');
%sbj_label	=	get(gca, 'xtickLabel');
%sbj_label	=	arrayfun(@(x)({ num2str(x) }), sbj_list);	% ex) '1' '2' ..
sbj_label	=	cellfun(@(x)({ regexprep(x, 'su0*', '') }), sbj_list); %ex)'1'..
sbj_label{end+1}	=	'Average';
set(gca, 'xtickLabel', sbj_label)
set(gca, 'FontName','Arial', 'FontSize',FontSize);
set(gca, 'LooseInset', get(gca, 'TightInset'));
xlim([0, length(sbj_label)+1]);
ylim([0,100])
%--------------------------------------------------------------------------------
%% display standard error on bar graph
yb			=	cat(1, h.YData);					% vector ���� �ϳ��� ����
xb			=	bsxfun(@plus, h(1).XData, [h.XOffset]');	%x bar�� �߰���ġ
				% ����, xb(b, s) ����, b == bar/sbj, s == sbj
se			=	100 * std(acc) ./ sqrt(n_subjects-1);% 100 ȯ��, 20x4 -> 4
W			=	(xb(2,end)-xb(1,end))/2 * 0.8;		% ���� bar �� width/2
for s		=	size(yb,2)							% # of subject
for b		=	1 : length(yb(:,1))					% bar / sbj
%	errorbar(xb(b,end), yb(b,end), se(b), 'ko');
%	plot([xb(b,s) xb(b,s)],			[yb(b,s)-se(b) yb(b,s)+se(b)],	...
%		'-k', 'LineWidth',2);						% ���μ�
%	plot([xb(b,s)-xW xb(b,s)+xW],	[yb(b,s)-se(b) yb(b,s)-se(b)],	...
%		'-k', 'LineWidth',2);						% �Ʒ� ���μ�
%	plot([xb(b,s)-xW xb(b,s)+xW],	[yb(b,s)+se(b) yb(b,s)+se(b)],	...
%		'-k', 'LineWidth',2);						% �� ���μ�
	plot([xb(b,s)-W xb(b,s)+W],[yb(b,s)+se(b) yb(b,s)+se(b)],'-k');%^����
	plot([xb(b,s)	xb(b,s)],  [yb(b,s)-se(b) yb(b,s)+se(b)],'-k');%|����
	plot([xb(b,s)-W xb(b,s)+W],[yb(b,s)-se(b) yb(b,s)-se(b)],'-k');%_����
end	%for b
end	%for s
%	e		=	[zeros(n_subjects, size(acc,2)); std(acc) ./ sqrt(n_subjects-1)];
%	[hBar hErr]=	barwitherr(e, 100*[acc; mean(acc,1)]);
%h			=	errorbar(ones(size(acc)), 100*[acc; mean(acc,1)], -e, e, 'k');
%h.LineStyle	=	'-';
%h.LineWidth	=	2;
%h.Color		=	'k';
%h.AlignVertexCenters	=	'on';		% �Ų����� ���μ��� ���μ�
%errorbar_tick(h, .5, 2);
%[b,e] = errorbarbar(x,y,e); % where x is center location of the group of bars
%--------------------------------------------------------------------------------
%% display a number over bar graph
%{
for idx = 1 : length(h)							% rLDA �� shuffled ��� ��� %-[
	idx
	x_loc		=	get(h(idx), 'XData')
	y_height	=	get(h(idx), 'YData')

	% ��ġ ��� ����: ����
%	arrayfun(@(x,y) text(x-0.7,y+1.5, sprintf('%.3f', y),					...
%							'FontSize',7, 'Color','b'),		x_loc, y_height);

	% ��ġ ��� ����: ����(rotate)
	arrayfun(@(x,y) text(x, y, sprintf('%.3f',y),	'Parent',h(idx),		...
			'FontSize',7,	'Color','b',	'Rotation',90,					...
			'HorizontalAlignment','left', 'VerticalAlignment','middle' ),	...
					x_loc, y_height);
%	if u want to remove the YTick(the points on the y axis)
%	set(p, 'YTick', nan);
end	%-]
%}
%{
yb			=	cat(1, h.YData);						% vector ���� �ϳ��� ����
xb			=	bsxfun(@plus, h(1).XData, [h.XOffset]');	%x bar�� �߰���ġ
%xb			=	xb + (h(1).BarWidth*h(1).XOffset./((Y<100)+2))'; % non rotate
hold on;
for s = 1:size(yb,2)										% # of subject
	for b = 1:length(yb(:,1))								% # of bar / sbj
%		if b==1, fonts=FontSize; else fonts=6; end			% LDA �� ����
		text(xb(b, s),yb(b, s)+0.75, sprintf('%.3f',yb(b, s)),				...
			'FontName','Arial', 'FontSize',6, 'Color','K', 'Rotation', 90,...
			'HorizontalAlignment','left', 'VerticalAlignment','middle');
	end
end
%}

%--------------------------------------------------------------------------------
if save_figs
%	[rLDA Shuffle EOG]	=	deal(yb(1,:), yb(2,:), yb(3,:));
%	[ p table ]			=	anova_rm({ rLDA Shuffle EOG }, 'off'); %must disp off

	%% output text table for statistical analysis
	dat		=	arrayfun(@(x)({ sprintf('%f', x) }), yb )';	% transpose
	dat		=	cat(1, labels, dat);						% cat to 1 cell
	lSbj	=	{ 'subject' sbj_list{:} 'average' };
	txt		=	cellfun(@(x,y)( {strjoin({x y{:}}, '\t')} ),	lSbj,	...
				arrayfun(@(x)( { dat(x,:) } ), [1:size(dat, 1)]) );

    fname	=	sprintf('%s%s%s__decoding_accuracy', gapFreq, cond, sFold);
	fname	=	regexprep(fname, '[.]', ',');		% convert '.' -> ','
	fp		=	fopen([ fullfile(fig_dir, fname) '.txt'], 'w');
	cellfun(@(x)( fprintf(fp, '%s\n', char(x)) ), txt);
	fclose(fp);

	%% output pdf for topo
%	fname	=	sprintf('[%04.1f~%04.1f]_%s__decoding_accuracy',			...
%					AllFOI{B}(1), AllFOI{B}(end), cond);
%	fname	=	regexprep(fname, '[.]', ',');		% convert '.' -> ','
    my_save_fig(gcf, fullfile(fig_dir, fname), 27, 15)
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
end % for b
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%delete(POOL);

toc(AllRun);

nProc	=	n_subjects;
return
