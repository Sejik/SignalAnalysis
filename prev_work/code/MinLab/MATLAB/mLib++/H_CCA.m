function [ loss, loss4Chan, corr4Chan ] = H03CCA_AmH(x, fs, MRKseq, COI)
% ���	: SSVEP, PFC ���� ���� canonical corelation analysis ����
% param	: x(tp x ch x ep), twin, marker_seq, cell(stim), cell(class of interest)
% return:	loss ( loss rate)
%			loss4Chan ( loss rate for each channel * epoch dimension )
%			corr4Chan ( class marker for each channel * epoch dimension )

	%% marker�� �����ϴ� ���ļ��� stimulus �� ��������.
	% eEEG(x) ����: tp x ch x epoch
%	sigLen			=	size(x, 1)*size(x, 3);	% tp * epoch
	class			=	sort(unique(reshape(MRKseq, [1], [])));

	%% do check equality b/w # of class and # of COI
	if length(class) ~= length(COI)
		fprintf('Warning  : mismatch length b/w class(%d) & stimulus(%d)\n', ...
				length(class), length(COI));
	end

	%% reference �ۼ�
%	t				=	[1/EPOS.fs : 1/EPOS.fs : 1];	% �ð� ���� ����
%	t				=	EPOS.t;
	t				=	[1/fs : 1/fs : size(x,1)/fs];	% time series of 1 epoch
	wvPacket		=	zeros(length(class), 2*length(COI{1}), length(t));

	for c = 1 : length(class)							% class ��
	for f = 1 : length(COI{c})							% stim freq ��
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
	% ��ü ch*ep(== whole tp) ������ ���� CCA�� �����Ѵ�.
	dataLen			=	size(x, 2) * size(x, 3);
	corr			=	zeros(length(class), dataLen);	%st x (ch*ep)
%	for d = 1 : dataLen										% ch * ep��, ��data
	for c = 1 : length(class)						% �� class(�ڱ�)
		CCAdata		=	zeros(1, [ size(corr, 2) ]);		% 1D data
	parfor d = 1 : dataLen									% ch * ep��, ��data
%		[A, B, corr(c,d), U, V] = canoncorr(eEEG(:,d), wvPacket(c,:,:)');
%		wvUnit		=	squeeze(wvPacket(c,:,:));			% stim x tp(1time)
		[~,~,CCAdata(d),~,~] = canoncorr(eEEG(:,d), squeeze(wvPacket(c,:,:))');
	end
		corr(c,:)	=	CCAdata;
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% �� ��������, corr ���� �� class(stimulus)���� ��ü ch*ep ���� �� ix��
	% CCA ���� �غ�Ǿ� �ִ�. �׷���, ���� �������� ����, �� ch(�� tp����)�� ����
	% �� �ϳ��� stimulus�� �־��� ���̱� ������, ���� ���� class �� �ϳ�����
	% �����ؾ� �Ѵ�.
	% 1. ����, �ִ밪�� ���� class�� ��������.
	%	�׸���, �� �� ���õ� class�� ��ü �� ep ix ���� �ٸ� �� �ִ�.
	%	�ֳ��ϸ�, �� ep ix ���� ����� �ٸ� �ڱ��� randome�ϰ� �־��� �����̴�.
	% 2. ��, �� ä�θ��� �ٸ� class�� ������ ���� �����̹Ƿ�, �� ep ix�� ����
	%	ä�� ��ü�� ���� �ִ�󵵷� ������ class�� ���� �����ؾ� �Ѵ�.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% ä�� �и� ���� 2D -> 3D
	mxClsf			=	reshape(corr, length(class),size(x,2),[]);

	%% investigate matching rate b/w each classes & marker
	% 1st: average all chan
	% 2nd: calc max for one of classes
	% 3rd: match classes vs marker

%	mxClsf			=	mxClsf(:,[20 21 22 23],:);			% Ư�� ä�θ� ����

	%% �� ep ix(tp ����) �� ���� ä�κ� �ִ밪 CCA ���
	% ������� ��� : mxClsf ���� : 6 x 30 x 240 -> 30 x 240
	[mxCCAch mxChIx]=	max(mxClsf, [], 1);					% class ���� ��� max
	[mxCCAch mxChIx]=	deal(squeeze(mxCCAch), squeeze(mxChIx));	% ���� ����
	% ���� 2D �� �ƴ�, 1D �� �ٸ� squeeze ����� 1 x 240 �� �ƴ� 240 x 1 ��.
	% ��, ������ 240 �� ��������, matlab ������ ���� �� matrix ������ 240 x 1
	% ����, 1 x 240 ���·� ���� �ʿ�.
	if size(mxCCAch,2) == 1,	mxCCAch	= shiftdim(mxCCAch,1);	end
	if size(mxChIx, 2) == 1,	mxChIx	= shiftdim(mxChIx, 1);	end
	% �̶�, mxIx ���� �� ch*ep ix ���� �ִ밪�� ������ class ��, marker�� ����!
	% ix ���� 1 ~ 6���� ��ġ�� �ٵ�, �̰��� marker�� naming ������ ��ġ��.
	corr4Chan		=	mxCCAch;

	%% ix �� marker ���� ������ ���� hit ���� ���
	mrkseq			=	mod(MRKseq, 10);						% 1�ڸ��� ����
	mrkseqCh		=	repmat(mrkseq, [ size(mxChIx, 1) ], 1); %ch��ŭ Ȯ��
	loss4Chan		=	mean(mxChIx(:) ~= mrkseqCh(:));		% 1D ���� miss��

	%% ���� �� ep ix ���� ���� class (ä�� ��ü ������ �ִ밪) �� ����
	[mxCCA mxIx]	=	max(mxCCAch, [], 1);				% chan ���� ��� max
	[mxCCA mxIx]	=	deal(squeeze(mxCCA), squeeze(mxIx));% ���� ����
%	for x = 1:length(mxIx), mxIx2(x) = mxChIx(mxIx(x), x); end % ep�� mx ch�� cl
	mxIx			=	arrayfun(@(x,y)( mxChIx(x,y) ), mxIx, [1:length(mxIx)]);
	loss			=	mean(mxIx ~= mrkseq);				% 1D ���� miss��

	return

