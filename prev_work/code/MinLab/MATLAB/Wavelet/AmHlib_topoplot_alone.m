%function [ ]	=	AmHlib_topoplot_pairs(Potn1D, MaxVal, MaxTp, MaxCh, JPG)
function [] = AmHlib_topoplot_alone(Potn2D, tRng,tWin, MaxFq,MaxTp,MaxCh, JPG)
	%% ���� ä�� ������ �������� ǥ���� ��
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

%% 20151025A. �켱 ced ������ ä�μ��� Potn2D �� ä�μ��� ��ġ�ϴ��� ����
	% ced ������ �о ����� �ľ�����.
	fCED		=	fopen(cedPATH{1}, 'r');
%	fprintf('Generating VHDR file to %s\n', fvhdr);

	lCED		=	textscan(fCED, '%s', 'delimiter', '');	%cell array
	fclose(fCED);
	nLine		=	size(lCED{1},1);						%��ü ���� ��
	lLine		=	strsplit(lCED{1}{nLine}, '\t');			%������ ���� �и�
	nChan		=	str2double(lLine(1));					%ä�� �� �ִ밪

	if nLine-1 ~= size(Potn2D, 2)
		fprintf('\nErrors  : # of Ch. loss for CED(%d) : Data(%d)\n',		...
				nLine-1, size(Potn2D, 2));
	elseif nChan ~= size(Potn2D, 2)
		fprintf('\nErrors  : Ch. ID mismatch for CED(%d) : Data(%d)\n',		...
				nChan, size(Potn2D, 2));
	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	livechIDX			=	find( ~ismember(channame, removech) );	%aliveä�θ�

	MaxValue			=	Potn2D(MaxTp, MaxCh);

	%% drawing topo ploting ------------------------------
	tStep				=	tRng(2)-tRng(1);			%�ð� ����
	% TopoPlot	%���� ced�� 1��°(NULL, EOG ä�� ��ġ������ �����Ǿ� ����)
	figure,
	[attr, data]		=	topoplot(Potn2D(MaxTp,:),	cedPATH{1},			...
					'style','map', 'electrodes','on');%,'chaninfo',EEG.chaninfo);

	eval([	'title(sprintf('''												...
				'Max Value: %f, Freq: %s, Time: %d ms, Ch: %s'', '	...
				'MaxValue, sMaxFq, MaxTp *tStep +tRng(1), channame{MaxCh}));' ]);
%	caxis([-MaxMax, MaxMax]);
	colorbar;	%('FontSize', 30);

	%% saving topo to jpeg ------------------------------
	fprintf('\nWrites  : TOPO to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
