% C_timtopo ver 0.51
%% TF ������ ��� TF plot ����
% [*Input Parameter]--------------------------------------------------
% Potn3D	: freq * timepoint * ch �� 3���� ������
% PlotFq	: plot�� ���ļ� ���� : Potn3D frequency���� ��ġ�ʿ�, %��:[1/4, 70]
% PlotTp:	: plot�� �ð�����(ms): Potn3D timepoint���� ��ġ�ʿ�, %��:[-500,1500]
% TopoFq	: topo�� ���ļ� ��� : ��� �� ��ŭ ������ ���õ�
%	ex) NaN -> max �� �ڵ���� �� ǥ��
%	ex) inf -> Z score ��� signif. �ڵ���� �� ǥ��
% TopoTp: topo�� �ð� ��� : TopoFq �� ���� ��ġ �ʼ�
%	ex) NaN -> |local max| �� �ڵ���� �� ǥ�� -> ������ |global max| Ž��
%	ex) inf -> Z score ��� signif. �ڵ���� �� ǥ��
%	ex) �ð�, ���ļ� �� �ϳ��� nan or inf ǥ�� ��,
%		���� �� ǥ��� �������� ������ �ڵ����
%			: tp:inf, freq:5 -> ���ļ� 5Hz ���������� Z ���ǹ�(or max)�� ����
% CED		: topo�� ���� CED ���� path
% Title		: text for display
% DispFq	: display�� ���ļ� ���� : ������ �� ���� plot ���� : [ 10, 30 ]
% DispTp	: display�� �ð� ��� : ������ �� ���� plot ���� : [ -500 1500 ]
% DispChi	: display�� ä�� : ��ȣ �ش� ä�θ� ����, (�⺻: 0==Allä�� ���)
% DispBar	: colorbar�� ��,�� scale ���� : ��: [-1.5 1.5], �⺻: autoscale
% DispRatio	:TF plot �� TOPO plot �� ũ�� ���� -> TF/TOPO -> 1>����(topoĿ��)
%
% [*Output Parameter]--------------------------------------------------
% mainFreq  : �ش� �������� �߽����ļ�: individual unique freqeuncy
% mainTime  : �ش� �������� maximum value �߻� �ð�
% StrikeZone: maximum value�� �߽����� high power�� ��ġ�� zone(l,b,r,t)
%
%% examples: E_tftopo(Data3D,	[1:1/2:30],	[-500:2:1500-1],		...
%	[ 5 NaN NaN 6 inf inf 7 ],	[ -200 -100 NaN 100 200 inf 300 ],		...
%	'..../../32chan.ced',				...
%	'ESHL'								...
%	[ 5 30 ],	[ -300 800 ],	'Cz',	...
%	[-1.5 1.5],	0.9)
%
% first created by tigoum 2015/12/02
% last  updated by tigoum 2016/05/12
% ver 0.51 : �Է� parameter�� PlotFq, PlotTp �� ����: vector -> interval ����

function [mainFreq mainTime StrikeZone] =	...
							E_tftopo(	Potn3D,	PlotFq,PlotTp,			...
										TopoFq,TopoTp, CED,		...
										Title,					...
										DispFq,DispTp,DispCh,	...
										DispBar, DispRatio)

	%% 20151202A. �߰�: ���ļ� ������ ���� ��쿡�� ��ü ���ļ� �������� ���ù��
	% ERP �� ���, ���ļ� ������ ���� ������������ TF ���ø� ���� ��� �ʿ�
%	if length(size(Potn3D))== 2 & size(Potn3D,1) > size(Potn3D,2) &		...
%		size(Potn3D,1) == length(PlotTp)				% �׷� 2nd ������ ä��
		%% ���ļ� ������ �����Ƿ�, ���뿪�� ���� ���ļ� ������ Ȯ���ؾ� ��.
%		fprintf('Warning : have not Frequency dimension in DATA array...\n');
%{
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Time-Frequency Analysis	%-[
		tStep		=	PlotTp(2)-PlotTp(1);
		fSmpl		=	1000/tStep;
%		fprintf('Engagement: Time-Frequency Analysis');
		Potn3D_		=	zeros([length(PlotFq) size(Potn3D)]);	%f x t x ch
		for ch		=	1:size(Potn3D,2),				%loop the all-ch
%			[tf1,tfa1,tfc1]		=	tfmorlet_min(ERP(:,ch),fSmpl,Freqs,m,ki);
			tfPw	=	tfmorlet_min_AmH(Potn3D(:,ch), fSmpl, PlotFq, 7, 5);
			Potn3D_(:,:,ch)	=	tfPw;					%power�� ����
		end
%		Potn3Dx	= arrayfun(@(x)( tfmorlet_min_AmH(x,fSmpl,PlotFq,7,5) ),
%		Potn3D(:,:))

		Potn3D		=	Potn3D_;	clear Potn3D_;
%}
%{
%		Potn3D		=	repmat(Potn3D, [1 1 length(PlotFq)]);	% t x ch x f
%		Potn3D		=	shiftdim(Potn3D,2);						% f x t x ch
%}
%{
		Potn3D_		=	zeros([size(Potn3D,1) size(Potn3D)]);	% tp ���� Ȯ��
		for tp = 1 : size(Potn3D,1)
			Potn3D_(tp,tp,:) = Potn3D(tp,:);
		end
		Potn3D		=	Potn3D_;	clear Potn3D_;
		PlotFq		=	PlotTp;							% �ð��ุ ������
		TopoFq		=	TopoTp;							% �ð��ุ ������
		DispFq		=	DispTp;							% �ð��ุ ������
%}
%{
		tStep		=	PlotTp(2)-PlotTp(1);
		fSmpl		=	1000/tStep;						% Sampling frequency
		sigLen		=	length(PlotTp) * tStep;			% Length of signal
		n			=	2^nextpow2(sigLen);
		dim			=	1;								% ���ι���(ä��->����)
		Y			=	fft(X,n,dim);
		F			=	abs(Y);
		Potn3D_		=	zeros([size(Potn3D,1) size(Potn3D)]);	% tp ���� Ȯ��%-]
%}
%		fprintf('+ adds  : Freq-DIM. into DATA array by processing.\n');
%	end
	% 20160512B. ����� time series �����Ϳ��� freq ������ ���� ����, ���� ó��
	if length(size(Potn3D)) < 3,error('Detect  : data require 3 dimension.');end
	if nargin < 6,				error('Error   : parameter missing.'); end

	%% 20160512A. PlotFq, PlotTp ǥ�� ����� ���濡 ���� data�� size �� �Ұ�
%{
	if size(Potn3D,1) < length(PlotFq)					% index �ʰ� -> ��� ���
		fprintf('\nWarning : FREQ index(%d) too big than data(%d)\n\n',		...
				length(PlotFq), size(Potn3D,1));
	end
	if size(Potn3D,2) < length(PlotTp)					% index �ʰ� -> ��� ���
		fprintf('\nWarning : TIME index(%d) too big than data(%d)\n\n',		...
				length(PlotTp), size(Potn3D,2));
	end
%}
	if length(PlotFq)~=2, error('Detect  : PlotFq require interval(2 val).');end
	if length(PlotTp)~=2, error('Detect  : PlotTp require interval(2 val).');end
	if length(TopoFq) ~= length(TopoTp)					% ���� ����ġ -> ���
		fprintf('\nWarning : differ a numbers of Topo(F:%d,T:%d)\n\n',		...
				length(TopoFq), length(TopoTp));
	end

	if nargin <12,	DispRatio=	1.0;	end
	if nargin <11,	DispBar	=	[ nan nan ];	end
	if nargin <10,	DispCh	=	0;	end
	if nargin < 9 | DispTp==0,	DispTp	=	[ PlotTp(1) PlotTp(end) ];	end
	if nargin < 8 | DispFq==0,	DispFq	=	[ PlotFq(1) PlotFq(end) ];	end
	if nargin < 7,	Title	=	'';	end

	% --------------------------------------------------
	% �ڵ� eBIN ���
	% PlotFq �� ���� ��谪 ���� �߻� : 20160324A. ����
	% 1/4 ~ 70 �� Hz�� �����ϴµ�, ���� �����ʹ� 280�� ���,
	% bin�� 1/4 �� �Ǿ�� ��. ���� eBIN�� �Ҽ���~��������� ���� �پ�.
	% �����: start ~ end ���̿� �����ϴ� �������� ���� ���� ���
	%	-> ��: [1/4:?:70] ���� 280�� �����Ͱ� �����ϸ�, �� ���� ���� ���� 279
	%	-> ����, ������ ũ�� = gap / n(gap) = (70-1/4) / (280-1)
	%
	% Potn3D	: freq * timepoint * ch �� 3���� ������
	nFq				=	size(Potn3D, 1);
	eBIN			=	(PlotFq(2) - PlotFq(1)) / (nFq - 1);
%	if int32(eBIN)~=eBIN, error('ERROR   : eBIN(%f) value not integer',eBIN); end
	PlotFq			=	[ PlotFq(1) : eBIN : PlotFq(2)-0 ];	% conv to vector
	%
%	ixDispFq				=	[DispFq(1) : PlotFq(2)-PlotFq(1) : DispFq(2)];
	ixDispFq				=	[DispFq(1) : eBIN : DispFq(2)];
	[ixFqStart ixFqFinish]	=	deal(	find(PlotFq == ixDispFq(1)),		...
										find(PlotFq == ixDispFq(end)) );
	ixFreq					=	PlotFq(ixFqStart:ixFqFinish);

	% --------------------------------------------------
	% �ڵ� eFS ���
	% Potn2D array element's length ���� ���� ū ���� tp ��.
	% PlotTp �� ���� ��谪 ���� �߻� : 20160324A. ����
	% -500 ~ 1500 �� �ð��� �����ϴµ�, ���� �����ʹ� 1000�� ���,
	% [-500 , 1500) �� ��. ����, eFS ���� �������� �ƴ��� ���� �ʿ�
	%
	% Potn3D	: freq * timepoint * ch �� 3���� ������
	nTp				=	size(Potn3D, 2);
	eFS				=	1000 * nTp / (PlotTp(2) - PlotTp(1)); %PlotTp==ms
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	PlotTp			=	[ PlotTp(1) : 1000/eFS : PlotTp(2)-1 ];	% conv to vector
	%
%	ixDispTp				=	[DispTp(1) : PlotTp(2)-PlotTp(1) : DispTp(2)];
	ixDispTp				=	[DispTp(1) : 1000/eFS : DispTp(2)];
	[ixTpStart ixTpFinish]	=	deal(	find(PlotTp == ixDispTp(1)),		...
										find(PlotTp == ixDispTp(end)) );
	ixTime					=	PlotTp(ixTpStart:ixTpFinish);

	Potn3D			=	Potn3D(ixFqStart:ixFqFinish, ixTpStart:ixTpFinish, :);

%	FreqCutoff		=	30;								% display ���� ��輱
%	tStep			=	PlotTp(2) - PlotTp(1);	%�ð� ����

	%% drawing 3D graph for TFc data
	[ChanNum ChanName]	=	mLib_load_CED_AmH(CED);		% CED ���� chan ��� ����
	if isnumeric(DispCh)								% index���ڸ� ���ڿ� Ȯ��
		if DispCh == 0, sCh	=	'RMS of All';
		else,			sCh	=	[char(ChanName{DispCh}) '(' int2str(DispCh) ')'];
		end
	else												% ���ڸ� index���� Ȯ��
		sCh			=	DispCh;
		DispCh		=	find(strcmp(ChanName, sCh));
	end
	if ~isempty(Title)
		title	= sprintf('[%s]''s TF (Ch:%s) & Topo', Title, sCh);
	else
		title		=	sprintf('TF (Ch:%s) & Topo', sCh);
	end

	figure,
%	tftopo(Potn3D, PlotTp, PlotFq, 'timefreqs',[ TopoTp ; TopoFq ]',		...
%			'mode','ave', 'chanlocs',CED, 'title',title);
	tftopo(Potn3D, ixTime, ixFreq, 'timefreqs',[ TopoTp ; TopoFq ]',		...
			'mode','ave', 'chanlocs',CED, 'title',title,					...
			'showchan',DispCh, 'limits',[nan nan nan nan DispBar],			...
			'tradeoff',DispRatio );

	print('-djpeg', [Title '_' sCh '.jpg']);

	return
%end function

