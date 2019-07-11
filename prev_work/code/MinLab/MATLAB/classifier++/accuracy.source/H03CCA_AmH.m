function [ loss, loss4Chan, corr4Chan ] = H03CCA_AmH(x, fs, MRKseq, COI)
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
%	t				=	[1/EPOS.fs : 1/EPOS.fs : 1];	% 시간 구간 구성
%	t				=	EPOS.t;
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
	% wish structure if 3D: epoch length(1 time) x ch x trial size
	% wish structure if 2D: epoch length(1 time) x ( ch * trial size )
%	eEEG			=	shiftdim(x, 1);
%	eEEG			=	permute(eEEG, [1 3 2]);
%	eEEG			=	reshape(eEEG, [length(t)], []);
	eEEG			=	reshape(x, [length(t)],[]);	% tp(1time) x alldata

	%% run CCA for all time
	% 전체 ch*ep(== whole tp) 구간에 대해 CCA를 수행한다.
	dataLen			=	size(x, 2) * size(x, 3);
	corr			=	zeros(length(class), dataLen);	%st x (ch*ep)
%	for d = 1 : dataLen										% ch * ep수, 총data
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
	% 만약 2D 가 아닌, 1D 로 줄면 squeeze 결과가 1 x 240 이 아닌 240 x 1 됨.
	% 즉, 원래는 240 만 나오지만, matlab 데이터 구조 상 matrix 형태인 240 x 1
	% 따라서, 1 x 240 형태로 변경 필요.
	if size(mxCCAch,2) == 1,	mxCCAch	= shiftdim(mxCCAch,1);	end
	if size(mxChIx, 2) == 1,	mxChIx	= shiftdim(mxChIx, 1);	end
	% 이때, mxIx 에는 각 ch*ep ix 별로 최대값을 가지는 class 즉, marker가 잡힘!
	% ix 값이 1 ~ 6까지 배치될 텐데, 이것은 marker의 naming 순서와 일치함.
	corr4Chan		=	mxCCAch;

	%% ix 와 marker 간의 대조를 통한 hit 비율 계산
	mrkseq			=	mod(MRKseq, 10);						% 1자리만 추출
	mrkseqCh		=	repmat(mrkseq, [ size(mxChIx, 1) ], 1); %ch만큼 확장
	loss4Chan		=	mean(mxChIx(:) ~= mrkseqCh(:));		% 1D 차원 miss율

	%% 이제 매 ep ix 별로 단일 class (채널 전체 단위의 최대값) 를 도출
	[mxCCA mxIx]	=	max(mxCCAch, [], 1);				% chan 차원 대상 max
	[mxCCA mxIx]	=	deal(squeeze(mxCCA), squeeze(mxIx));% 차원 감소
%	for x = 1:length(mxIx), mxIx2(x) = mxChIx(mxIx(x), x); end % ep별 mx ch의 cl
	mxIx			=	arrayfun(@(x,y)( mxChIx(x,y) ), mxIx, [1:length(mxIx)]);
	loss			=	mean(mxIx ~= mrkseq);				% 1D 차원 miss율

	return

