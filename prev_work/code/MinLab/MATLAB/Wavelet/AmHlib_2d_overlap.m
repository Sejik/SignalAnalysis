function [ ] = AmHlib_2d_overlap(Potn2D, tRng,tWin, MaxFq,MaxTp,MaxCh, JPG)
	%% ��� ä���� �����͸� overlap �Ͽ� ������
	% Potn2D : timepoint * ch �� 2���� ������
	% tRng=[start:step:end] : ���۽��� ~ ������ ����
	% tWin=[x1:step:x2] : time window
	% MaxTp : Potn2D(?,:) ���� MaxTp timpoint ��ġ�� �ִ밪 ����
	% MaxCh : Potn2D(:,?) ���� MaxCh ��ġ�� �ִ밪 ����
	% JPG : ������ �̹����� ���� �̸�

if isnumeric(MaxFq)									%���ļ� ������ ���ڿ��� ��ȯ
	sMaxFq		=	sprintf('%4.1f Hz', MaxFq);
elseif isstr(MaxFq)
	sMaxFq		=	MaxFq;
else
	sMaxFq		=	'Unknown';
	fprintf('\nWarning : did not specified the frequency info.');
end

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	liveChIdx			=	find( ~ismember(channame, removech) );	%aliveä�θ�

	MaxValue			=	Potn2D(MaxTp, MaxCh);
	mxChName			=	channame{MaxCh};

	selchan				=	channame;
	selchan{MaxCh}		=	[ '*' mxChName ];			% Max Ch�� '*' ǥ��
	selchan				=	selchan(liveChIdx);			% EOG, NULL ����

	%% drawing 2D graph for signal T * ch : checking for noise or spike
%	tStep				=	length(tRng) / size(Potn2D,1);	%�ð� ���� ���
	tStep				=	tRng(2)-tRng(1);			%�ð� ����
	% 2D Plot
	figure,
	plot(tRng, Potn2D(:,liveChIdx)); hold on;			% EOG, NULL ����
	YLim				=	get(gca, 'YLim');
%	if tWin ~= 0										% 0 �̸� time win ǥ�� X
	rectangle('EdgeColor','r', 'LineWidth',2,							...
		'Position',[tWin(1),YLim(1),tWin(end)-tWin(1),YLim(2)-YLim(1)]); hold on;
%	end
	legend(selchan, 'Location','eastoutside', 'Orientation','vertical');
	xlabel('t(ms)');		ylabel(sprintf('%d of ch', length(selchan)));
	title(sprintf('Max Value: %f, Freq: %s, Time: %d ms, Ch: %s',			...
			MaxValue, sMaxFq, MaxTp *tStep +tRng(1), mxChName));
%	ylim([-0.1 1.2]);
	grid on;

	% �ִ밪 ��ġ�� marker ǥ��
	plot(MaxTp *tStep +tRng(1), MaxValue, 'ro','MarkerSize',10,'LineWidth',1);

	%% saving 2D to jpeg ------------------------------
	fprintf('\nWrites  : Graph to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
