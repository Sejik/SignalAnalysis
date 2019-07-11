function [ ] = AmHlib_ERP_overlap(Potn2D, tRng, tWin, JPG)
	%% ��� ä���� �����͸� overlap �Ͽ� ������
	% Potn2D : timepoint * ch �� 2���� ������
	% tRng=[start:step:end] : ���۽��� ~ ������ ����
	% tWin=[x1:step:x2] : time window
	% MaxTp : Potn2D(?,:) ���� MaxTp timpoint ��ġ�� �ִ밪 ����
	% MaxCh : Potn2D(:,?) ���� MaxCh ��ġ�� �ִ밪 ����
	% JPG : ������ �̹����� ���� �̸�

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	% ���� �������� ���� ������ channame ������ ��ġ�ؾ� ��!
	if size(Potn2D,2) ~= length(channame)
%		liveChIdx		=	find( ~ismember(channame, removech) );	%aliveä�θ�
%		Live2D			=	Potn2D(:, liveChIdx);
%		selchan			=	channame( liveChIdx );
		Error;
	end
	Live2D				=	Potn2D;
	selchan				=	channame;

%	tStep				=	length(tRng) / size(Live2D,1);	%�ð� ���� ���
	tStep				=	tRng(2)-tRng(1);			%�ð� ����

	% time 0 ���� �������� window�� �����ؾ� ��.
%	t0Idx				=	find(0 <= tRng);			% ���� array index�� ����
	tWidx				=	find(ismember(tRng, tWin));	% window
%	t0Rng				=	tRng( t0Idx );				% ���� time ���� ȹ��
%	tWrng				=	tRng( tWidx );				% ���� time ���� ȹ��

	%% potential ���� { positive, negative } peak �� ��� ���ؾ� �Ѵ�.
	% Ư���� ����, 2D ������ ( ���� peak �� single vector ���� ����) �󿡼�
	%	peak �� ã�ƾ� �ϸ�, ����, ä�� ������ �ϳ��� merge �ؾ� �ϴµ�,
	%	�̷��� merge �� �����Ϳ����� peak �� �ݵ�� �ִ밪�� �����ִ� �ϳ��� ä��
	%	�� �ּҰ��� �����ִ� �ϳ��� ä�ο� ���ؼ��� ���� ���ؾ� ��!
	%	���� ���, �� ä���� ����� peak �� �����ִ���, ��ü������ �� ū ����
	%	������ �� �ϳ��� ä�ο� ���ؼ��� peak �� Ž���Ǿ�� ��.
	%���: ä�κ��� peak �� ��� ���Ѵ���, �ִ밪�� ä�ΰ� �ּҰ��� ä����
	%	ã�Ƽ�, �� �� ä�ο� ���ؼ��� peak�� image�� ǥ��
	%����: -> ��� findpeaks �� ���� ����� �����ϳ�, max (== positive) ���⸸
	%	������ �ֹǷ�, min ������ �������� ������ �����Ϳ� ���� max �� ���� ��
	%	�ٽ� �����Ͽ� �ľ��ؾ� ��.
	%	-> ��쿡 ����, �� ä�ο��� min, max �� �� ���� ���� ������ ����.

	% ���� �� ä�κ� max peak �� ����
	% ��!, �ݵ�� time 0 ���ĺ��� �����ؾ� ��.
	for ch = 1 : size(Live2D, 2)						% length of ch
		[pks, locs]		=	findpeaks(Live2D(tWidx,ch), 1/tStep);%Live2D����:t*ch
		lMxPks{ch}		=	pks';						% ä�� �� peak: ��->��
		mxPeak(ch)		=	max(pks);					% �ִ밪��
		lMxLocs{ch}		=	locs;						% ä�� �� pk ��ġ ����
	end
%	[mxPeak, ixPeak]	=	max(lMxPks, [], 2);			% ä�� �� �ִ밪
	[mxPkCh, ixPkCh]	=	max(mxPeak);				% ä�� �� �ִ밪

	% �̾� �� ä�κ� min peak �� ����
	for ch = 1 : size(Live2D, 2)						% length of ch
		[pks, locs]		=	findpeaks(-1*Live2D(tWidx,ch), 1/tStep);% amp reverse
		lMnPks{ch}		=	-1*pks';					% ä�� �� min �� ����
		mnPeak(ch)		=	min(-1*pks);				% �ּҰ���
		lMnLocs{ch}		=	locs;						% ch �� min pk ��ġ ����
	end
%	[mnPeak, inPeak]	=	min(lMnPks, [], 2);			% ä�� �� �ּҰ�
	[mnPkCh, inPkCh]	=	min(mnPeak);				% ä�� �� �ּҰ�

	% ����, 2D plot�� �ۼ�����.
	mnChName			=	selchan{inPkCh};			% max �� min �� ��ĥ����
	selchan{inPkCh}		=	[ '-' mnChName ];			% Min Ch�� '-' ǥ��
	mxChName			=	selchan{ixPkCh};
	selchan{ixPkCh}		=	[ '+' mxChName ];			% Max Ch�� '+' ǥ��
	others				=	find(~ismember(selchan, selchan([inPkCh ixPkCh])));

%	linetype			=	cell(1,length(selchan));	% row type ����
%	linetype(:)			=	{ ':' };					% �� ��ü �ʱ�ȭ: ����

	%% drawing 2D graph for signal T * ch : checking for noise or spike
	% 2D Plot
	figure,
%	plot(tRng, Live2D(:,others), ':'); hold on;		% max, min �̿�: ����
%	plot(tRng, Live2D(:,[inPkCh ixPkCh]), '-'); hold on;% max, min �� �Ǽ�
%	plot(tRng, Live2D, linetype); hold on;			% �������� �� ��� ����Ʈ
	lPlt				=	plot(tRng, Live2D, ':'); hold on;%�� plot ���� handle
	lPlt(inPkCh).LineWidth	=	2;							% �� ����
	lPlt(ixPkCh).LineWidth	=	2;							% �� ����
	lPlt(inPkCh).Color		=	'cyan';						% negative �� û��
	lPlt(ixPkCh).Color		=	'magenta';					% positive �� ����
	lPlt(inPkCh).LineStyle	=	'-.';						% negative �� �Ǽ�
	lPlt(ixPkCh).LineStyle	=	'-';						% positive �� ����

	% �ִ밪 ��ġ�� marker ǥ��
	plot(lMxLocs{ixPkCh}, lMxPks{ixPkCh}, 'rv','MarkerSize',5,'LineWidth',1);
%	for n = 1 : length(lMxLocs{ixPkCh})					% negative peak ǥ��
%		text(lMxLocs{ixPkCh}(n), lMxPks{ixPkCh}(n), sprintf('n%d', n));
%	end
	pkname	=	arrayfun(@(x)({sprintf('p%d',x)}), [1:length(lMxPks{ixPkCh})]);
	text(lMxLocs{ixPkCh}+.0, lMxPks{ixPkCh}+.2, pkname);

	% �ּҰ� ��ġ�� marker ǥ��
	plot(lMnLocs{inPkCh}, lMnPks{inPkCh}, 'b^','MarkerSize',5,'LineWidth',1);
%	for p = 1 : length(lMnLocs{inPkCh})					% positive peak ǥ��
%		text(lMnLocs{inPkCh}(p), lMnPks{inPkCh}(p), sprintf('p%d', p));
%	end
	pkname	=	arrayfun(@(x)({sprintf('n%d',x)}), [1:length(lMnPks{inPkCh})]);
	text(lMnLocs{inPkCh}+.0, lMnPks{inPkCh}-.2, pkname);

%	set(gca, 'Ydir', 'rev');							% Y���� ���� ���� ����
	YLim			=	get(gca, 'YLim');
	YMax			=	max(abs(YLim));					% Y�� min/max�� �����ִ�
	ylim([ -YMax YMax ]);								% ���� gadient ����
	if tWin ~= 0										% 0 �̸� time win ǥ�� X
		rectangle('EdgeColor','r', 'LineWidth',2,							...
		'Position',[tWin(1),YLim(1),tWin(end)-tWin(1),YLim(2)-YLim(1)]); hold on;
	end
	legend(selchan, 'Location','eastoutside', 'Orientation','vertical');
	xlabel('t(ms)'); ylabel(sprintf('%d chs, Potential(uV)', length(selchan)));
	title(sprintf('Max: %.3fuV/%s, Min: %.3fuV/%s',							...
max(cell2mat(lMxPks)), selchan{ixPkCh}, min(cell2mat(lMnPks)), selchan{inPkCh}));
%	ylim([-0.1 1.2]);
	grid on;

	%% saving 2D to jpeg ------------------------------
	fprintf('\nWrites  : Graph to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
