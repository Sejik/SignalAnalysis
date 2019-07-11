function [ ] = H03CCA_for_min( )
%% test for CCA

	verbose			=	1;

	%----------------------------------------------------------------------------
	%% COI == CCA freq. Of Interesting
	%% COI는 각 셀당 자극 갯수만큼 요소를 가져야함. 따라서 2차원 cell type 구성
	%% 아래의 3줄만 수정하면 됨. 이후는 자동으로 구성하는 코드.
	COIbase1st		=	{ [5]	[7]   [6]	[6]   [7]   [5] };		% top/inter용
	COIbase2nd		=	{ [7.5] [5.5] [5.5] [7.5] [6.5] [6.5] };	% top/inter용
	COIbaseBT		=	{ [5] [6] [7] [5.5] [6.5] [7.5] };			% bottom up용

%		COIbase		=	{ [5 7.5] [5.5 7] [5.5 6] [7.5 6] [6.5 7] [6.5 5] };
		COIbase		=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIbase2nd);%결합
%		COIsum		=	{ [5+7.5] [7+5.5] [6+5.5] [6+7.5] [7+6.5] [5+6.5] };
		COIsum		=	cellfun(@(x,y)({ [x+y] }), COIbase1st, COIbase2nd);%덧셈
%		COIbs_sum	=	{ [5 7.5 5+7.5] [7 5.5 7+5.5] [6 5.5 6+5.5] ... %{base+%}
%						  [6 7.5 6+7.5] [7 6.5 7+6.5] [5 6.5 5+6.5] };	% harmon
%		COIBsSm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIsum);  % base+sum
		COIharm1st	=	cellfun(@(x)({ x*2 }), COIbase1st);				% harmon
		COIharm2nd	=	cellfun(@(x)({ x*2 }), COIbase2nd);				% harmon
		COIharm		=	cellfun(@(x,y)({ [x y] }), COIharm1st, COIharm2nd);%결합
		COIharmBT	=	cellfun(@(x)({ x*2 }), COIbaseBT);				% harmon
		COIBsHm1st	=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIharm1st);%1st만
		COIBsHm2nd	=	cellfun(@(x,y)({ [x y] }), COIbase2nd, COIharm2nd);%2nd만
		COIBsHm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIharm); % base+harm
		COIBsHmBT	=	cellfun(@(x,y)({ [x y] }), COIbaseBT, COIharmBT);
		COIBsHmSm	=	cellfun(@(x,y,z)({ [x y z] }), COIbase, COIharm, COIsum);

	% COI는 각 셀당 자극 갯수만큼 요소를 가져야하고, 또한 실험조건별로 각각 구분.
	% 따라서 3차원 cell type 구성
	COILIST			=	{ COIBsHmSm, COIBsHmSm, COIBsHmBT };% top, int, bot 순서
	%----------------------------------------------------------------------------
	SmplRate		=	500;								% sampling rate
%	FreqWindow		=	[min([4 cell2mat(BOI)]), max([30 cell2mat(BOI)])];
	FreqWindow		=	[4, 30];
	TimeWindow		=	[0, 5000];			% 0~5000sec
%	OverlapWin		=	0;	% 200, 앞 신호와 뒷 신호 사이의 겹침 time point 범위
	%----------------------------------------------------------------------------
	nFolds			=	4;									% 7 session
	nChannel		=	30;									% 살펴 볼 총 채널 수

	ChRemv			={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',							'PO10' };
				% O1, Oz, O2 계산 위해, 나머지 모두 제거(맨 처음에 꼭 'not' 달기)
	ChSide			=	{	'EOG'	};						% 부가적인 분석용
	%----------------------------------------------------------------------------
	PATH			=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_2';
	[Head, Common, lAllSubject] = S03sbjlist_AmH([PATH '/eEEG.Inlier/']);
	Head			=	Head;
	Allier			=	cellfun(@(x)({x{1}}), lAllSubject);	% 1st 요소만 추출
	Outlier			=	{ };	% { 'su0002', };
	Inlier			=	Allier(find(~ismember(Allier, Outlier)));
	%----------------------------------------------------------------------------
	Condi			=	{ 'TopDown', 'Intermediate', 'BottomUp', };

	%% 조건에 따라 CCA 분석 개시
for cond			=	1 : length(Condi)
	fprintf('COI for %s : -----\n', Condi{cond});
	cellfun(@(u,v)(fprintf('\t%d: %s\n', u, v)), arrayfun(@(x)({x}), [1:6]),...
	cellfun(@(x)({strjoin(arrayfun(@(y)({num2str(y)}),x),', ')}),COILIST{cond}));
	pause(1);												% 1초간 대기
	sCondi			=	Condi{cond};

	%% data의 loading & concatination
	epos			=	cell(1,length(Inlier));				% data 구성
	parfor ix 	= 1:length(Inlier)
		fprintf('loading subject %s\n', Inlier{ix})

		epos{ix}	=	load_Min_KU_data_new_format( PATH,					...
						Head,		Inlier{ix},		sCondi,					...
						nFolds,		FreqWindow,		TimeWindow,				...
						SmplRate,	nChannel,		verbose);

		% take only the scalp channels, remove EOG channels
		% 경우에 따라서는 EOG 포함하여 계산
		epos{ix}	=	proc_selectChannels(epos{ix}, ChRemv);

		% high pass filter
		db_attenuation	=	30;
		hp_cutoff	=	1;
		[z,p,k]	=	cheby2(4, db_attenuation, hp_cutoff/(epos{ix}.fs/2),'high');
		epos{ix}	=	proc_filt(epos{ix}, z,p,k);
	end

	%----------------------------------------------------------------------------
	% the experiment cond that is to be classified
	sbj_list	=	Inlier;
	n_subjects	=	length(sbj_list);
	save_figs	=	1; % save figures or not

	%% 파라미터로 받은 데이터가 EOG를 포함한 데이터인 경우, EOG 데이터만 분리해서
	%	별도로 구성해 둠. 물론 원본 데이터에서 EOG를 제외 할 것.
	if length(find( ismember(epos{1}.clab, ChSide) )) > 0	% EOG 추가 임.
		SdPos	=	find( ismember(epos{1}.clab, ChSide));
		ChPos	=	find(~ismember(epos{1}.clab, ChSide));

		eOrg	=	epos;
		eSide	=	eOrg;

		for sbj_idx=1:n_subjects
		eSide{sbj_idx}.clab	=	ChSide;						% label 교정
		eSide{sbj_idx}.x	=	epos{sbj_idx}.x(:,SdPos,:);	% EOG 데이터만

		epos{sbj_idx}.clab	=	eOrg{sbj_idx}.clab(ChPos);	% EOG 제거
		epos{sbj_idx}.x		=	eOrg{sbj_idx}.x(:,ChPos,:);	% EOG 제외 data
		end

		clear eOrg
	end

	%% compute canonical correlation analysis (CCA) accuracy
	fprintf('\n\n --- starting canonical correlation analysis ---\n\n')

	%condition에 따라, COI를 선택해서 수행해야 함
%	ixCond		=	find(ismember(Condi, cond));
%	loss_cca	=	zeros(1,n_subjects);

	for sbj_idx = 1:n_subjects
		fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)

%		[ loss_cca(sbj_idx), ~, ~]	=	H03CCA_AmH(epos{sbj_idx}.x,			...
%						epos{sbj_idx}.fs, epos{sbj_idx}.mrkseq, COI{ixCond});

%		fprintf(' -> loss CCA = %g\n', loss_cca(sbj_idx))
%	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	%% CCA 를 구동하여 AllBOI{B} 에 속한 주파수에 대응하는 매칭 정도 파악
	%% classes 의 최대값과 marker 의 일치성 수준을 토대로 accuracy 계산
	x				=	epos{sbj_idx}.x;
	fs				=	epos{sbj_idx}.fs;					% sampling rate
	MRKseq			=	epos{sbj_idx}.mrkseq;
	COI				=	COILIST{cond};
	
%function [ loss, loss4Chan, corr4Chan ] = H03CCA_AmH(x, fs, MRKseq, COI)
% 기능	: SSVEP, PFC 등을 위한 canonical corelation analysis 수행
% param	: x(tp x ch x ep), twin, marker_seq, cell(stim), cell(class of interest)
% return:	loss ( loss rate)
%			loss4Chan ( loss rate for each channel * epoch dimension )
%			corr4Chan ( class marker for each channel * epoch dimension )

	%% marker에 대응하는 주파수를 stimulus 로 구성하자.
	% eEEG(x) 구조: tp x ch x epoch
%	sigLen			=	size(x, 1)*size(x, 3);	% tp * epoch
	class			=	sort(unique(reshape(MRKseq, [1], [])));

	%% do check equality b/w # of class and # of COI
	if length(class) ~= length(COI)
		fprintf('Warning  : mismatch length b/w class(%d) & stimulus(%d)\n', ...
				length(class), length(COI));
	end

	%% reference 작성
	t				=	[1/fs : 1/fs : size(x,1)/fs];	% time series of 1 epoch
	wvPacket		=	zeros(length(class), 2*length(COI{1}), length(t));

	for c = 1 : length(class)							% class 수
	for f = 1 : length(COI{c})							% stim freq 수
		fprintf('Stimulus: freq(%5.2f) for %dth class & %dth stim\n',		...
				COI{c}(f), c, f);
		wvPacket(c,f*2-1,:) =	sin(2*pi * COI{c}(f) * t);
		wvPacket(c,f*2-0,:) =	cos(2*pi * COI{c}(f) * t);
	end
	end

	%% reshape proper structure for x data
	eEEG			=	reshape(x, [length(t)],[]);	% tp(1time) x alldata

	%% run CCA for all time
	% 전체 ch*ep(== whole tp) 구간에 대해 CCA를 수행한다.
	dataLen			=	size(x, 2) * size(x, 3);
	corr			=	zeros(length(class), dataLen);	%st x (ch*ep)
	for c = 1 : length(class)						% 각 class(자극)
		CCAdata		=	zeros(1, [ size(corr, 2) ]);		% 1D data
	parfor d = 1 : dataLen									% ch * ep수, 총data
%		[A, B, corr(c,d), U, V] = canoncorr(eEEG(:,d), wvPacket(c,:,:)');
%		wvUnit		=	squeeze(wvPacket(c,:,:));			% stim x tp(1time)
		[~,~,CCAdata(d),~,~] = canoncorr(eEEG(:,d), squeeze(wvPacket(c,:,:))');
	end
		corr(c,:)	=	CCAdata;
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% 이 시점에서, corr 에는 각 class(stimulus)별로 전체 ch*ep 구간 각 ix별
	% CCA 값이 준비되어 있다. 그런데, 실험 시점에서 보면, 각 ch(매 tp마다)에 대해
	% 단 하나의 stimulus가 주어진 것이기 때문에, 계산된 여러 class 중 하나만을
	% 결정해야 한다.
	% 1. 따라서, 최대값을 갖는 class를 선택하자.
	%	그리고, 이 때 선택된 class는 전체 매 ep ix 별로 다를 수 있다.
	%	왜냐하면, 매 ep ix 별로 실험시 다른 자극을 randome하게 주었기 때문이다.
	% 2. 단, 매 채널마다 다른 class가 나오는 것은 문제이므로, 매 ep ix에 대해
	%	채널 전체에 대해 최대빈도로 나오는 class를 최종 선택해야 한다.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% 채널 분리 위해 2D -> 3D
	mxClsf			=	reshape(corr, length(class),size(x,2),[]);

	%% investigate matching rate b/w each classes & marker
	% 1st: average all chan
	% 2nd: calc max for one of classes
	% 3rd: match classes vs marker

%	mxClsf			=	mxClsf(:,[20 21 22 23],:);			% 특정 채널만 선별

	%% 매 ep ix(tp 마다) 에 대한 채널별 최대값 CCA 계산
	% 현재시점 결과 : mxClsf 차원 : 6 x 30 x 240 -> 30 x 240
	[mxCCAch mxChIx]=	max(mxClsf, [], 1);					% class 차원 대상 max
	[mxCCAch mxChIx]=	deal(squeeze(mxCCAch), squeeze(mxChIx));	% 차원 감쇠
	% 이때, mxIx 에는 각 ch*ep ix 별로 최대값을 가지는 class 즉, marker가 잡힘!
	% ix 값이 1 ~ 6까지 배치될 텐데, 이것은 marker의 naming 순서와 일치함.
	corr4Chan		=	mxCCAch;

	%% ix 와 marker 간의 대조를 통한 hit 비율 계산
	mrkseq			=	mod(MRKseq, 10);						% 1자리만 추출
	mrkseqCh		=	repmat(mrkseq, [ size(mxChIx, 1) ], 1); %ch만큼 확장
	loss4Chan		=	mean(mxChIx(:) ~= mrkseqCh(:));		% 1D 차원 miss율
	fprintf('%s/%s have accuracy(chan) = ', Condi{cond}, Inlier{sbj_idx});
	fprintf('%f\n', 1 - loss4Chan);

	%% 이제 매 ep ix 별로 단일 class (채널 전체 단위의 최대값) 를 도출
	[mxCCA mxIx]	=	max(mxCCAch, [], 1);				% chan 차원 대상 max
	[mxCCA mxIx]	=	deal(squeeze(mxCCA), squeeze(mxIx));% 차원 감소
%	for x = 1:length(mxIx), mxIx2(x) = mxChIx(mxIx(x), x); end % ep별 mx ch의 cl
	mxIx			=	arrayfun(@(x,y)( mxChIx(x,y) ), mxIx, [1:length(mxIx)]);
	loss			=	mean(mxIx ~= mrkseq);				% 1D 차원 miss율
	fprintf('%s/%s have accuracy( all) = ', Condi{cond}, Inlier{sbj_idx});
	fprintf('%f\n\n', 1 - loss);

	end
end

	return

%--------------------------------------------------------------------------------

function epo = load_Min_KU_data_new_format(path, com, sbj, cond,			...
								n_blocks, fwin, twin, fs, nchan, verbose)	%-[
% Loads all trials of the requested condition (1, 2, or 3) of the data provided
% by Byoung-Kyong Min from Korea University (KU).

%% params

% HERE YOU HAVE TO SPECIFY THE FOLDER THAT CONTAINS THE SUBJECT DATA
%data_folder = '/home/sven/data/Data/BBCI_data/SSVEP_Min/SSVEP_NEW_Format/';
data_folder = [ path '/eEEG.Inlier/' ];

if nargin < 4,	verbose = 0; end
if ~isempty(com) & isempty(regexp(com,  '.*_$')), com =[ com   '_']; end % 끝'_'+
if ~isempty(cond)&isempty(regexp(cond,'.*_$')), cond=[cond '_']; end

%% load the data
epo = [];
for block_idx=1:n_blocks

    %% create the filename and load the data of the current block
%	file_name = sprintf('SSVEP_NEW_su%04d_%s_%d.mat', ...
%						sbj, cond, block_idx);
	file_name = sprintf('%s%s_%s%d.mat', com, sbj, cond, block_idx);
%	sbj_folder = sprintf('su%02d', sbj);

    if verbose
        fprintf('loading %s\n', file_name)
    end
%    dat = load(fullfile(data_folder, sbj_folder, file_name));
    dat = load(fullfile(data_folder, file_name));

    %% create class labels that match the BBCI toolbox format
    y = dat.eMRK;
    unique_markers = unique(y);
    n_classes = length(unique_markers);
    n_trials = length(y);
    labels = zeros(n_classes, n_trials);
    className = cell(1,n_classes);
    for c=1:n_classes
        labels(c, y==unique_markers(c) ) = 1;
        className{c} = sprintf('stimulus %d',c);
    end

    %% create the epoched data structure that matches the BBCI format
if nchan + 1 == 31					% 30 + EOG
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
elseif nchan + 1 == 64				% 63 + EOG
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',...
				'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6', ...
				'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1', ...
				'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5', ...
				'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' };
end

%--------------------------------------------------------------------------------
	epo_tmp				= [];
	epo_tmp.clab		= clab;
%	epo_tmp.band		= [4, 50];
%	epo_tmp.band		= [ 5, 7.5 ];	%[ 11.5, 13.5 ], [ 33, 45.5], [4, 50];
%	epo_tmp.band		= [ 11.5, 13.5 ];		%, [ 33, 45.5], [4, 50];
%	epo_tmp.band		= [ 33, 45.5];
	epo_tmp.band		= fwin;
	epo_tmp.fs			= fs;

	tidx				= [twin(1)*(fs/1000)+1:twin(2)*(fs/1000)];	%index구성
%	epo_tmp.t			= (1:2500)/500;
	epo_tmp.t			= tidx / fs;			% index 기준으로 샘플링 시간 구성
												% (1:2500)/500 , (1001:3000)/500;

%	epo_tmp.mrkseq		= dat.eMRK;				% eEEG의 epoch 수와 대응
	epo_tmp.className	= className;			% 자극 갯수
%	epo_tmp.x			= dat.eEEG;
	epo_tmp.x			= dat.eEEG(tidx,:,:);	% 유효data만 추출, tp x ch x ep
	epo_tmp.y			= labels;				% class * trial

	mrkseq				=	dat.eMRK;
	if isfield(epo, 'mrkseq')					% marker 도 append 해줘야 함
		mrkseq			=	[ epo.mrkseq mrkseq ];	% append
	end

	epo = proc_appendEpochs(epo, epo_tmp);
	epo.mrkseq			=	mrkseq;				% 추가 및 append 값 갱신
end

	return	%-]
