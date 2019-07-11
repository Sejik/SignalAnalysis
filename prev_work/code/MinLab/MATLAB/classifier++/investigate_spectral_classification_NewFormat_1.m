%% initialize parameter		%-[
	% the experiment condition that is to be classified
	hEEG.Condi		=	{ 'TopDown', 'Intermediate', 'BottomUp', };
	%----------------------------------------------------------------------------
	hEEG.SmplRate	=	500;								% sampling rate
	fBin			=	1/2;
	hEEG.FreqBins	=	fBin;								% freq step

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 기본 구조는 밭 '전' 자의 가로와 세로에 각기 다른 주파수를 할당하고 조합함
%		┏┳┓
%		┣╋┫
%		┗┻┛
% 위 그림에 대해 아래와 같이 주파수를 배당함.
%
%%		5.5 6.5 7.5
%%		|	|	|
%% 5.0- ┏  ┳  ┓	R1
%% 6.0- ┣  ╋  ┫	R2
%% 7.0- ┗  ┻  ┛	R3
%%		C1	C2	C3
%
% 이를 기준으로 아래와 같이 구성되는 문자별로 주파수 조합(harmonic)이 결정됨
% tgr	R/C		char	R-freq	C-freq
% 1x1	R1C3	(┓)	5.0 Hz	7.5 Hz
% 1x2	R3C1	(┗)	7.0 Hz	5.5 Hz
% 1x3	R2C1	(┣)	6.0 Hz	5.5 Hz
% 1x4	R2C3	(┫)	6.0 Hz	7.5 Hz
% 1x5	R3C2	(┻)	7.0 Hz	6.5 Hz
% 1x6	R1C2	(┳)	5.0 Hz	6.5 Hz
%	-> tgr 1x. 에서 x == 1(top down), 2(intermediate), 3(bottom up)
	%----------------------------------------------------------------------------
	% COI == class of interest, ( == stimulus frequency)
		COIbase1st	=	{ [5] [7] [6] [6] [7] [5] };
		COIbase2nd	=	{ [7.5] [5.5] [5.5] [7.5] [6.5] [6.5] };
%		COIbase		=	{ [5 7.5] [5.5 7] [5.5 6] [7.5 6] [6.5 7] [6.5 5] };
		COIbase		=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIbase2nd);%결합
		COIbaseBT	=	{ [5] [6] [7] [5.5] [6.5] [7.5] };			% bottom up용
%		COIsum		=	{ [5+7.5] [7+5.5] [6+5.5] [6+7.5] [7+6.5] [5+6.5] };
		COIsum		=	cellfun(@(x,y)({ [x+y] }), COIbase1st, COIbase2nd);%덧셈
%		COIbs_sum	=	{ [5 7.5 5+7.5] [7 5.5 7+5.5] [6 5.5 6+5.5] ... %{base+%}
%						  [6 7.5 6+7.5] [7 6.5 7+6.5] [5 6.5 5+6.5] };	% harmon
%		COIBsSm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIsum);  % base+sum
		COIharm1st	=	cellfun(@(x)({ x*2 }), COIbase1st);				% harmon
		COIharm2nd	=	cellfun(@(x)({ x*2 }), COIbase2nd);				% harmon
%		COIharm		=	cellfun(@(x)({ x*2 }), COIbase);				% harmon
		COIharm		=	cellfun(@(x,y)({ [x y] }), COIharm1st, COIharm2nd);%결합
		COIharmBT	=	cellfun(@(x)({ x*2 }), COIbaseBT);				% harmon
		COIBsHm1st	=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIharm1st);%1st만
		COIBsHm2nd	=	cellfun(@(x,y)({ [x y] }), COIbase2nd, COIharm2nd);%2nd만
		COIBsHm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIharm); % base+harm
		COIBsHmBT	=	cellfun(@(x,y)({ [x y] }), COIbaseBT, COIharmBT);
		COIBsHmSm	=	cellfun(@(x,y,z)({ [x y z] }), COIbase, COIharm, COIsum);

	% 20160223A. CCA에서 bottom-up은 한번에 1개의 주파수(1st harmonic도 해당
	%	주파수만)만 줄 수 있음. 예를 들어, 'ㄱ' 에 대해 5Hz(그리고 10) 만 줄 것
	% 이와 같은 구조로 인해, top down, intermediate, bottom up 별로 COI를 각각
	%	구성해야 함.
	% COI는 각 셀당 자극 갯수만큼 요소를 가져야하고, 또한 실험조건별로 각각 구분.
	% 따라서 3차원 cell type 구성
%	hEEG.COI		=	{ COI_topdown, COI_intermdt, COI_bottomup };
	hEEG.COI		=	{ COIBsHmSm, COIBsHmSm, COIBsHmBT };

	%----------------------------------------------------------------------------
	% BOI == band of interest
		%% 10:0.5:15 는 first harmonic && 가로와 세로의 주파수 합 포함!
		%% 다른 방법: 가로+세로 주파수 합 only , 그리고 곱 only
	if isfield(hEEG, 'COI')									% COI 존재->기반 구성
		%%[20160221A 참고] COI는 CCA를 위해 구성되는 것이기도 하며, 이 경우,
		% 각 marker에 대응하는 freq가 할당되므로, f 갯수와 marker 수가 일치한다.
		% -> 즉, sparse 주파수 분석만 가능
		% 이와 달리, LDA 계통은 여러 주파수 범위를 할당 할 수 있으므로,
		% - 그래서 어떤 주파수가 상관성 있는지 조사 가능 하다.
		% -> sparse 뿐만 아니라, whole 주파수 분석도 가능하다.
		%
		% 이런 이유로, COI와 대조를 위한 분석시, LDA도 sparse 분석만 가능함
		%	COI는 2D 구조의 cell 이므로, flatten 시켜야 함.
		hEEG.BOI	=	{ [5:fBin:13.5] };
	else
		BOIbase		=	[ 5:fBin:7.5 ];
		BOIsum		=	[ 5+7.5 5.5+7 5.5+6 7.5+6 6.5+7 6.5+5 ];
		BOIharmonic	=	[ BOIbase(1)*2:fBin:BOIbase(end)*2 ];
		BOIcombi	=	[ BOIbase*2 BOIsum ];
		BOIext		=	[ BOIbase BOIsum];
		BOImul		=	[ 5*7.5 5.5*7 5.5*6 7.5*6 6.5*7 6.5*5 ];
%		BOImul		=	[ 20 22 24 26 28 30 ];
%		hEEG.BOI	=	[ unique(BOIsum) unique(BOImul) ];
%		hEEG.BOI	=	{ [BOIbase] [unique(BOIsum)] [unique(BOImul)] };
%		hEEG.BOI	=	{ [BOIbase] [unique(BOIsum)] };
%		hEEG.BOI	=	{ [BOIbase] };
%		hEEG.BOI	=	{ [unique(BOIharmonic)] };
%		hEEG.BOI	=	{ [BOIbase] [unique(BOIcombi)] };
%		hEEG.BOI	=	{ [BOIbase] [unique(BOIext)] };
%		hEEG.BOI	=	{ [BOIbase] [unique(BOIsum)] [unique([BOIbase BOIsum])]};
		hEEG.BOI	=	{ [unique([BOIbase BOIsum])] [5:fBin:13.5] };
						% 3rd cell: 5 ~ 13.5Hz 가 최종체계 : 20160201A
	end
	%----------------------------------------------------------------------------
	hEEG.sBOI		=	{							...
'over stimulation frequencies',						...
'over sum combination of stimulation frequencies',	...
'over base+sum combination of stimulation frequencies',	...
						};		% BOI matched string
%'over first harmonics of stimulation frequencies',	...
%'over multiple combination of stimulation frequencies',	...
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	hEEG.FreqWindow	=	[2, 50];							% or [4, 30]
	hEEG.FreqWindow	=[min([4 cell2mat(hEEG.BOI)]), max([30 cell2mat(hEEG.BOI)])];
	%----------------------------------------------------------------------------
	hEEG.tInterval	=	[-2000, 5000];						% -2000~5000msec
	hEEG.TimeWindow	=	[0, 5000];			% 0~5000sec
	hEEG.OverlapWin	=	0;	% 200, 앞 신호와 뒷 신호 사이의 겹침 time point 범위
	%----------------------------------------------------------------------------
	hEEG.lFolds		=	{ [1:4] };							% 4 session cat
%%	hEEG.lFolds		=	{ [1 2] [3 4] };					% 4 session 2 cat
%	hEEG.lFolds		=	{ [1] [2] [3] [4] };				% 4 session each
%%	hEEG.lFolds		=	arrayfun(@(x)({ [x] }), [1:4]);		% 4 session each
	%% 20160302A. 새로운 시도를 위해 원래 측정된 fold data 갯수와
	%				분석 파라미터로서의 nfold 값을 분리하여 지정
	hEEG.nFolds		=	4;									% 4 session
%	hEEG.nFolds		=	10;									% 10 fold 로 조정
	%----------------------------------------------------------------------------
	hEEG.nChannel	=	30;									% 살펴 볼 총 채널 수
%{
	hEEG.ChRemv		=	{	'not',	'NULL*',	};			% 불필요 채널
	hEEG.ChRemv		=	{	'not',	'NULL*',	'*EOG*'	};	% 불필요 채널
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',			'O2',	'PO10' };
				% Oz 계산 위해, 나머지 모두 제거(맨 처음에 꼭 'not' 달기)
%}
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',							'PO10' };
				% O1, Oz, O2 계산 위해, 나머지 모두 제거(맨 처음에 꼭 'not' 달기)
	hEEG.ChSide		=	{	'EOG'	};						% 부가적인 분석용

	%----------------------------------------------------------------------------
	hEEG.PATH		=	'./';
	if exist([ hEEG.PATH '/eEEG' ])
		[lAllSbj, Head, Common, FileExt]=S04sbjlist_AmH([hEEG.PATH '/eEEG/']);
	else
		[lAllSbj, Head, Common, FileExt]=S03sbjlist_AmH([hEEG.PATH '/Export/' ]);
	end
	hEEG.Head		=	Head;
	hEEG.Allier		=	cellfun(@(x)({x{1}}), lAllSbj);	% 1st 요소만 추출
	hEEG.Outlier	=	{ };	% { 'su0002', };
	hEEG.Inlier		=	hEEG.Allier(find(~ismember(hEEG.Allier, hEEG.Outlier)));
%		Allier	: 모든 피험자 목록, ex:{ { 'su0001, 'su0001, 'su0001_1' },...}
%		Outlier	: 제외 목록, ex: { 'su0001', 'su0002', ... }
	%% parameter end -----	%-]

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% setting parallel environment
%path(localpathdef);	% startup_bbci_toolbox@startup.m 대응 path 재조정
verbose				=	1;

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% run accuracy
for condi			=	1 : length(hEEG.Condi)
	sCondi			=	hEEG.Condi{condi};

	% ___________________________________________________________________________
	%% 20160229A. 세션 데이터의 합침 or 분리 계산 방식 도입
for fold			=	hEEG.lFolds							% assign like foreach
	% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	if length(hEEG.lFolds) > 1,	hEEG.CurFold = fold{1}; end	% seperated only!

	% --------------------------------------------------
	epos			=	cell(1,length(hEEG.Inlier));		% data 구성
	for ix 	= 1:length(hEEG.Inlier)
		fprintf('loading subject %s\n', hEEG.Inlier{ix})

		epos{ix}	=	load_Min_KU_data_new_format( hEEG.PATH,				...
			hEEG.Head,			hEEG.Inlier{ix},	sCondi,		fold{1}, ...
			hEEG.FreqWindow,	hEEG.tInterval,		hEEG.TimeWindow,		...
			hEEG.nChannel,		verbose);

		% take only the scalp channels, remove EOG channels
		% 경우에 따라서는 EOG 포함하여 계산
		epos{ix}	=	proc_selectChannels(epos{ix}, hEEG.ChRemv);

		% high pass filter
		db_attenuation	=	30;
		hp_cutoff	=	1;
		[z,p,k]	=	cheby2(4, db_attenuation, hp_cutoff/(epos{ix}.fs/2),'high');
		epos{ix}	=	proc_filt(epos{ix}, z,p,k);
	end

	%% calculation for accuracy ----------------------------------------

%--------------------------------------------------------------------------------
AllRun		=	tic;

%% 20160229A. 세션 데이터의 합침 or 분리 계산 방식 도입
if	~isfield(hEEG, 'CurFold'),	sFold	=	'';
else,							sFold	=	num2str(hEEG.CurFold);			end

%% 20160302A. 세션 데이터와 (crossvalidation)용 fold 갯수의 분리 시도
if	isfield(hEEG, 'nFolds'),	nFolds	=	hEEG.nFolds;
else,							nFolds	=	max( cell2mat(hEEG.lFolds) );	end

%% the experiment sCondi that is to be classified
sbj_list	=	hEEG.Inlier;
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
AllBOI	=	{hEEG.BOI{:} hEEG.FreqWindow(1):hEEG.FreqBins:hEEG.FreqWindow(end)};
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

%% 파라미터로 받은 데이터가 EOG를 포함한 데이터인 경우, EOG 데이터만 분리해서
%	별도로 구성해 둠. 물론 원본 데이터에서 EOG를 제외 할 것.
%if size(epos{1}.x,2) == hEEG.nChannel+length(hEEG.ChSide)	% EOG 추가 임.
if length(find( ismember(epos{1}.clab, hEEG.ChSide) )) > 0	% EOG 추가 임.
	SdPos	=	find( ismember(epos{1}.clab, hEEG.ChSide));
	ChPos	=	find(~ismember(epos{1}.clab, hEEG.ChSide));

	eOrg	=	epos;
	eSide	=	eOrg;

	for sbj_idx=1:n_subjects
	eSide{sbj_idx}.clab	=	hEEG.ChSide;					% label 교정
	eSide{sbj_idx}.x	=	epos{sbj_idx}.x(:,SdPos,:);		% EOG 데이터만

	epos{sbj_idx}.clab	=	eOrg{sbj_idx}.clab(ChPos);		% EOG 제거
	epos{sbj_idx}.x		=	eOrg{sbj_idx}.x(:,ChPos,:);		% EOG 제외 data
	end

	clear eOrg
end



%% compute canonical correlation analysis (CCA) accuracy
if fgCOI													% CCA 용 data
fprintf('\n\n --- starting canonical correlation analysis ---\n\n')

%condition에 따라, COI를 선택해서 수행해야 함
nCondi		=	find(ismember(hEEG.Condi, sCondi));
loss_cca	=	zeros(1,n_subjects);

try, for sbj_idx = 1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)

	% CCA 를 구동하여 AllBOI{B} 에 속한 주파수에 대응하는 매칭 정도 파악
	% classes 의 최대값과 marker 의 일치성 수준을 토대로 accuracy 계산
	[ loss_cca(sbj_idx), ~, ~]	=	H03CCA_AmH(epos{sbj_idx}.x,				...
					epos{sbj_idx}.fs, epos{sbj_idx}.marker, hEEG.COI{nCondi});

	fprintf(' -> loss CCA = %g\n', loss_cca(sbj_idx))

end, catch	exception
	disp(exception.message)
	% disp(exception.message) == 인덱스가 행렬의 차원을 초과합니다
	% 이 문제는 20160221A 와 관련된 것으로서, LDA를 대상으로 whole 범위 freq를
	% 다룰 경우, BOI 에는 존재하지만, COI 에는 해당 데이터가 존재치 않게 됨
	fgCOI	=	0;
	fprintf(['Warning : processing impossible for continuously freq section ' ...
			'[%05.2f ~ %05.2f]\n' ], AllBOI{B}(1), AllBOI{B}(end));
BREAK
end
end



%% compute spectral features

% Here the spectral features are computed. For each trial I compute the
% power spectrum in the specified frequency range. The power in each
% frequency bin will become a feature used for classification

fgUseFFT				=	true;
fgUsePWELCH				=	~fgUseFFT;

band					=	[ AllBOI{B}(1) AllBOI{B}(end) ];
sampling_freq			=	epos{1}.fs;
fv						=	cell(1,n_subjects);
epo_spec				=	cell(1,n_subjects);
eSd_spec				=	cell(1,n_subjects);
%fft_window	= hanning(2*sampling_freq);
fft_window		=	hanning(sampling_freq* (1/hEEG.FreqBins) ); %edited by tigoum

fprintf('\n\n --- computing spectal features ---\n\n')
for sbj_idx=1:n_subjects
	fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)
	% feature extraction: apply FFT
	% figure, plot(fft_window)

if fgUseFFT
	epo_spec{sbj_idx}	=	proc_spectrum(epos{sbj_idx}, band,				...
					'Win', fft_window, 'Step', sampling_freq*hEEG.FreqBins);

	% EOG 성분
	eSd_spec{sbj_idx}	=	proc_spectrum(eSide{sbj_idx}, band,				...
					'Win', fft_window, 'Step', sampling_freq*hEEG.FreqBins);
elseif fgUsePWELCH		%-[
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
	PSD		=	zeros(fSmpl/2 /fBin +1,size(eSide{1}.x,2),size(eSide{1}.x,3));
	fa		=	zeros(fSmpl/2 /fBin +1);
	for ep = 1 : size(eSide{sj_ix}.x, 3)					% 각 ep 단위 계산
		[PSD(:,:,ep), fa]= pwelch(eSide{sj_ix}.x(:,:,ep),[],[],fSmpl/fBin,fSmpl);
	end
	eSd_spec{sj_ix}		=	eSide{sj_ix};					% epo_spec 생성
	eSd_spec{sj_ix}.t	=	[band(1):fBin:band(2)];
	eSd_spec{sj_ix}.x	=	PSD(ismember(fa, eSd_spec{sj_ix}.t),:,:);
	eSd_spec{sj_ix}.xUnit=	'Hz';
	eSd_spec{sj_ix}.yUnit=	'dB';	%-]
end

	%---------------------------------------------------------------------------
	%% 20160202A. 기존 [a b] 구간의 전체 주파수 성분을 모두 조사방식 변경
	% 그래서, 구간 중 일부 주파수 성분만 조사할 수 있도록 변경
	if ~isequal(epo_spec{sbj_idx}.t, AllBOI{B})	% 구간 중 일부 요소 제외 형태
		[~, ix]		=	ismember(AllBOI{B}, epo_spec{sbj_idx}.t);
		epo_spec{sbj_idx}.x	=	epo_spec{sbj_idx}.x(ix,:,:);

		fprintf('   + reprocessing freq. parts: [%s]\n',					...
			strjoin( arrayfun(@(x)({num2str(x)}), AllBOI{B}), ', ') );
	end

	% 다음은 EOG 성분
	if ~isequal(eSd_spec{sbj_idx}.t, AllBOI{B})	% 구간 중 일부 요소 제외 형태
		[~, ix]		=	ismember(AllBOI{B}, eSd_spec{sbj_idx}.t);
		eSd_spec{sbj_idx}.x	=	eSd_spec{sbj_idx}.x(ix,:,:);

		fprintf('   + reprocessing freq. parts: [%s]\n',					...
			strjoin( arrayfun(@(x)({num2str(x)}), AllBOI{B}), ', ') );
	end

	% reshape the channel-wise spectra to obtain feature vectors
	fv{sbj_idx}			=	proc_flaten(epo_spec{sbj_idx});
	fS{sbj_idx}			=	proc_flaten(eSd_spec{sbj_idx});
end
    [n_freq_bins, n_channels, n_epos] = size(epo_spec{1}.x);
	n_classes			=	size(epo_spec{1}.y, 1);
	if n_classes == 2, n_classes = 1; end	% 자유도 고려, 2개면 한쪽만 알면 됨
	freqs				=	epo_spec{1}.t;	% 주파수 구간: time이 아님!
fprintf('[*] frequency bin is %f\n', freqs(2)-freqs(1)); % added by tigoum
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
loss_svm	=	zeros(1,n_subjects);

%%c_out		=	zeros(n_classes, n_epos, n_subjects);
for sbj_idx = 1:n_subjects
    fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)

	fv_sbj			=	fv{sbj_idx};
	% apply crossvalidation using a regularized LDA classifer (see the
	% function train_RLDA_shrink.m) and chronological crossvalidation
	[loss_all(sbj_idx), ~, cout_tmp]	=	crossvalidation(fv_sbj, ...
						@train_RLDAshrink, ...
						'SampleFcn', {@sample_chronKFold, nFolds});
%%	c_out(:,:,sbj_idx)					=	squeeze(cout_tmp);
	fprintf(' -> loss LDA = %g\n', loss_all(sbj_idx))

	%% repeat the crossvalidation with the same parameters but shuffle the
	% labels of the trials. This way we get an estimate of the chance level.
	fv_sbj.y		=	fv_sbj.y(:,randperm(n_epos));
	loss_sfl(sbj_idx)					=		...
		crossvalidation(fv_sbj,			@train_RLDAshrink,	...
						'SampleFcn', {@sample_chronKFold, nFolds});
	fprintf(' -> loss LDA (shuffled labels) = %g\n', loss_sfl(sbj_idx))

	%% processing the EOG(+ other side) channel data alone.
	loss_side(sbj_idx)					=		...
		crossvalidation(fS{sbj_idx},	@train_RLDAshrink,	...
						'SampleFcn', {@sample_chronKFold, nFolds});
	fprintf(' -> loss Side-Ch (%s) = %g\n', strjoin(hEEG.ChSide, ', '), ...
													loss_side(sbj_idx));

	%% processing the multi class SVM ----------------------------------------
	%% Train [ one-against-all ] models: approach 2
	% how to fold making for fv_sbj.{x,y} ?
	% 4 fold case: fore part 3 fold to be set train data, last part to test.

	% 6개의 bitmap 형식(0 or 1) label을 class 형식(1:6) label로 변환
	% ! 아래 find 사용시 반드시 row 값만 취하기 위해 리턴값을 2개 변수로 받기!
	[labels, ~]		=	find(fv{sbj_idx}.y);				% a one on bitmap
%	labels			=	labels';							% vector
	%% for crossvailidation
	acc	=	libsvmtrain(labels, fv_sbj.x', ['-t 0 -c 1 -v ' num2str(nFolds)]);
	loss_svm(sbj_idx)=	1 - max(acc) / 100;
	fprintf(' -> loss SVM = %g\n', loss_svm(sbj_idx))
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
	acc		=	[accuracy; accuracy_shuffled; accuracy_side; accuracy_cca;	...
				accuracy_svm ]';
	labels	=	{'rLDA', 'rLDA(shuffled)', hEEG.ChSide{1}, 'CCA',			...
				'SVM'};
else
	acc		=	[accuracy; accuracy_shuffled; accuracy_side;				...
				accuracy_svm ]';
	labels	=	{'rLDA', 'rLDA(shuffled)', hEEG.ChSide{1},					...
				'SVM'};
end

figure
h			=	bar(100*[acc; mean(acc,1)]);	% 핸들 2개 : rLDAx & shuffle
hold on
hLgn = legend(labels, 'location', 'southoutside', 'orientation', 'horizontal');

%% 구간이 whole 인지, sparse 인지 구분해야 함.
if isequal(AllBOI{B}, [AllBOI{B}(1): hEEG.FreqBins :AllBOI{B}(end)])	% 등간격
	gapFreq	=	sprintf('[%04.1f~%04.1f]', AllBOI{B}(1), AllBOI{B}(end) );
else
	gapFreq	=	sprintf('[%04.1f,Sparse,%04.1f]', AllBOI{B}(1), AllBOI{B}(end) );
end
title({'decoding accuracy',													...
		gapFreq,															...
		sprintf(' for condition "%s" %s', strrep(sCondi,'_','-'), sFold)	})
xlabel('subjects')
ylabel('decoding accuracy in %')
set(gca, 'xtick', 1:n_subjects+1)
%--------------------------------------------------------------------------------
%% display a number over bar graph
yb			=	cat(1, h.YData);						% vector 들을 하나로 연결
xb			=	bsxfun(@plus, h(1).XData, [h.XOffset]');	%x bar별 중간위치
hold on;
for a = 1:size(yb,2)										% # of subject
	for b = 1:length(yb(:,1))								% # of bar / sbj
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
	%% output text table for statistical analysis
	dat		=	arrayfun(@(x)({ sprintf('%f', x) }), yb )';	% transpose
	dat		=	cat(1, labels, dat);						% cat to 1 cell
	lSbj	=	{ 'subject' sbj_list{:} 'average' };
	txt		=	cellfun(@(x,y)( {strjoin({x y{:}}, '\t')} ),	lSbj,	...
				arrayfun(@(x)( { dat(x,:) } ), [1:size(dat, 1)]) );

    fname	=	sprintf('%s%s%s__decoding_accuracy', gapFreq, sCondi, sFold);
	fname	=	regexprep(fname, '[.]', ',');		% convert '.' -> ','
	fp		=	fopen([ fullfile(fig_dir, fname) '.txt'], 'w');
	cellfun(@(x)( fprintf(fp, '%s\n', char(x)) ), txt);
	fclose(fp);

	%% output pdf for topo
    my_save_fig(gcf, fullfile(fig_dir, fname), 15, 10)
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
end % for b
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

toc(AllRun);

end		% for fd
end		% for cond
