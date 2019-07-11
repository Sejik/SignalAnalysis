function [mainFreq mainTime StrikeZone] =	...
							mLib_TFplot_AmH(Potn3D,	PlotFq,PlotTp,			...
													TopoFq,TopoTp, CED,		...
													Title,					...
													DispFq,DispTp,DispCh,	...
													DispBar, DispRatio)
	%% ��� ä���� �����͸� overlap �Ͽ� ������
	% [*Input Parameter]--------------------------------------------------
	% Potn3D	: freq * timepoint * ch �� 3���� ������
	% PlotFq	: TFplot�� ���ļ� ���� : Potn3D�� freq ������ ��ġ ���
	% PlotTp	: TFplot�� �ð� ���� : Potn3D�� timepoint ������ ��ġ ���
	% TopoFq	: topo�� ���ļ� ��� : ��� �� ��ŭ ������ ���õ�
	%	ex) NaN -> max �� �ڵ���� �� ǥ��
	%	ex) inf -> Z score ��� signif. �ڵ���� �� ǥ��
	% TopoTp: topo�� �ð� ��� : TopoFq �� ���� ��ġ �ʼ�
	%	ex) NaN -> max �� �ڵ���� �� ǥ��
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
%% examples: mLib_TFplot_AmH(Data3D,	[1:1/2:30],	[-500:2:1500-1],		...
%	[ 5 NaN NaN 6 inf inf 7 ],	[ -200 -100 NaN 100 200 inf 300 ],		...
%	'..../../32chan.ced',				...
%	'ESHL'								...
%	[ 5 30 ],	[ -300 800 ],	'Cz',	...
%	[-1.5 1.5],	0.9)

%% setting %%
%path(localpathdef);	%<UserPath>�� �ִ� localpathdef.m ����, �߰����� path�� ���

	%% 20151202A. �߰�: ���ļ� ������ ���� ��쿡�� ��ü ���ļ� �������� ���ù��
	% ERP �� ���, ���ļ� ������ ���� ������������ TF ���ø� ���� ��� �ʿ�
	if length(size(Potn3D))== 2 & size(Potn3D,1) > size(Potn3D,2) &		...
		size(Potn3D,1) == length(PlotTp)				% �׷� 2nd ������ ä��
		%% ���ļ� ������ �����Ƿ�, ���뿪�� ���� ���ļ� ������ Ȯ���ؾ� ��.
		fprintf('Warning : have not Frequency dimension in DATA array...\n');
%{
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Time-Frequency Analysis
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
		Potn3D_		=	zeros([size(Potn3D,1) size(Potn3D)]);	% tp ���� Ȯ��
%}
		fprintf('+ adds  : Freq-DIM. into DATA array by processing.\n');
	end

	if nargin < 6
		fprintf('\nError   : parameter missing.\n');
		return
	end

	if size(Potn3D,1) < length(PlotFq)					% index �ʰ� -> ��� ���
		fprintf('\nWarning : FREQ index(%d) too big than data(%d)\n\n',		...
				length(PlotFq), size(Potn3D,1));
	end

	if size(Potn3D,2) < length(PlotTp)					% index �ʰ� -> ��� ���
		fprintf('\nWarning : TIME index(%d) too big than data(%d)\n\n',		...
				length(PlotTp), size(Potn3D,2));
	end

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

	ixDispFq				=	[DispFq(1) : PlotFq(2)-PlotFq(1) : DispFq(2)];
	[ixFqStart ixFqFinish]	=	deal(	find(PlotFq == ixDispFq(1)),		...
										find(PlotFq == ixDispFq(end)) );
	ixFreq					=	PlotFq(ixFqStart:ixFqFinish);

	ixDispTp				=	[DispTp(1) : PlotTp(2)-PlotTp(1) : DispTp(2)];
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
		title	= sprintf('Condition(%s)''s TF plot(Ch:%s) & Topo', Title, sCh);
	else
		title		=	sprintf('TF plot(Ch:%s) & Topography', sCh);
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

