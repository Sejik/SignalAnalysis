%% d2_Interp_FindChan_Topoplot_AmH.m %%
% version: 0.3
% �ΰ����� �ڵ�
% Analyzer�� �̿����� �ʰ� �ٷ� �ִ� Peak���� ���� ������ �׸��� ���� �뵵
% �ʿ信 ���� channel interpolation �� ���డ��.

clear;
close all

%% setting %%
%path(['./EEGLAB_scripts-master:', pathdef]);		%<UserPath>�� �ִ� pathdef.m �� �����Ͽ� �߰����� path�� ���
path(pathdef);		%<UserPath>�� �ִ� pathdef.m �� �����Ͽ� �߰����� path�� ���

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
	tStep		=	2;								% ���ø� ����: ms
	tRange		=	-500:2:1500-1;					% �ð� ����
% ������ ������ �����ϴ�. �Ʒ��� ���� grouping �� �ʿ��ϴ�.
% file info group	:
% data set group	: subject ���, trial ���(���� �ٸ� ������ trial ���� ����)
% channel group		: ä�� loc ����, ä�� ���, �Ⱦ��� ä��, �߸� ������ ä��
% time group		: ���۽ð�, ����ð�, time-window / 1 trial
% freq group		: ����(��ġ), ���ļ� �̸�
% TF group			: �ð����ļ� �м� ���, SFFT, wavelet parameter
% statistics group	: ��� �м� ���

%arrange : ( sub, data, trial, ch )
%lBadChan		=	cell( length(subname), length(dataname), length(trialname) );
%lBadChan{

%fName		=	{'theta', 'alpha', 'beta'};
%fName		=	{ fName };	% {'theta'};
%{
theta			=	4:1/2:8;
alpha			=	8:1/2:13;
beta			=	13:1/2:30;
gamma			=	30:1/2:50;
%}
%idxLiveCh		=	[1:16, 18:21, 23:32];		% EOG, NULL ������ ����
idxLiveCh		=	find( ~ismember(channame, removech));%liveä�θ�:parm����!
idxRemCh		=	find( ~ismember(removech, channame));%deadä�θ�:parm����!
%{
ananame			=	{	'TFe_bl', 'TFi_bl'	};

%20151005A. �ð� ���� ���� ����
%1. max FreqVal: time windows �� 0~500ms �̳����� �ִ� amp ������ ���ļ� ã��
%			-> fSmpl=500 <=> SpI(sample interval)=2ms �̸�, ��ü�ð� -500~1500ms
%			-> Thus, tw index = 500/2 ~ 1000/2 = 251 ~ 501
%2. maximum : time windows �� 500~1000ms �̳����� �ִ� amp �� �� ä�� ã��
%			-> fSmpl=500 <=> SpI(sample interval)=2ms �̸�, ��ü�ð� -500~1500ms
%			-> Thus, tw index = 1000/2 ~ 1500/2 = 501 ~ 751
lTpWin4Sens		=	{	[251:501],	[251:501]	};
%timelist		=	cell(1,1);
%timelist{1,1}	=	[251:501];    % TFe_bl�� Timewindow. 0ms ~ 500ms
%timelist{2,1}	=	[51:201];     % TFi�� Timewindow. -400ms ~ -100ms
%timelist{3,1}	=	[51:201];     % TFi_bl�� Timewindow. -400ms ~ -100ms
lTpWin4Cogn		=	{	[501:751],	[501:751]	};
					% congnition time window : 500ms ~ 1000ms

%% ���Ĵ뿪�� ���� TFi (not baseline correction) �� ���� �ð�ȭ ����
if find(ismember(fName, 'alpha'))	% ������ ���, pre stimulus �� ó���ؾ� ��
ananame{end+1}	=	'TFi_bl';
lTpWin4Sens{end+1}=	[51:201];
lTpWin4Cogn{end+1}=	[501:751];
end
%}
%% first, load some bad-ch info.
%{
% excel file structure is:	%-[
%A2:A7(col, vert)	= dataname x trialname combination (ex: Fav_USA, ...)
%B1:Z1(raw, hori)	= subject list (ex: su02, su04, ...)
%B2:Z7(25 x 6)		= ch enum for each indivisual
%lBadChan	=	xlsread('Subject list of lBadChanolation.xlsx', 'After_ERP', 'A1:Z7');
%lBadChan		=	xlsread('Subject list of interpolation.xls', 'Sheet1', 'A1:Z7');
%lBadChan			=	{ 'P7', 'P4' };	%��ü data�� ���ؼ� �� ä�ε� ������� interp
%lBadChan			=	{ 'P7' };	%��ü data�� ���ؼ� �� ä�ε� ������� interp
%% cBanChan�� �����Ѵ�: ��� subj�� ���� ������ bad channel ������ ������ -[
cBadChan		=	{													...
						'su02', { 'P7'			}	;					...
						'su04', { 'P7'			}	;					...
						'su06', { 'P7', 'P4'	}	;					...
						'su07', { 'P7', 'P4'	}	;					...
						'su08', { 'P7'			}	;					...
						'su09', { 'P7', 'P4'	}	;					...
						'su10', { 'P7'			}	;					...
						'su11', { 'P7'			}	;					...
						'su12', { 'P7'			}	;					...
						'su13', { 'P7', 'P4'	}	;					...
						'su14', { 'P7'			}	;					...
						'su15', { 'P7'			}	;					...
						'su16', { 'P7', 'PO9'	}	;					...
						'su17', { 'P7'			}	;					...
						'su18', { 'P7'			}	;					...
						'su19', { 'P7'			}	;					...
						'su20', { 'P7'			}	;					...
						'su21', { 'P7', 'PO10'	}	;					...
						'su22', { 'P7'			}	;					...
						'su24', { 'P7'			}	;					...
						'su25', { 'P7', 'O2'	}	;					...
						'su26', { 'P7', 'P3'	}	;					...
						'su27', { 'P7'			}	;					...
						'su28', { 'P7'			}	;					...
						'su29', { 'P7', 'F3'	}	;					...
					};	% �⺻ 'P7' interp �ؾ� �ϰ�, �Ϻδ� �߰� ä�� ����-]
%-]
%}
%subname			=	subname( idxInlier );					% �ٽ� �߸�

% reading data structure(from excel) is:
% ...

%{
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% local �ӽ� ��������, ���Ŀ����� ���� ���� �ھ� ����
tic;	delete(gcp('nocreate'));

%matlabpool open 4;							% lagacy ���
%POOL		=	parpool('local');			% ���� �ӽ��� ���� core�� ����Ʈ ����
%----------
%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% �ű� profile �ۼ�
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% �ִ� 48 core ���.
	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!����: parent ���� ȣ�������� tic�� �����Ѵٴ� �����Ͽ�, toc ��� ��û��.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%}

%{
%Topo�� ���� ä�� ��ġ �̹����� ������ �д�.	%-[
%	� ������������, topo �ۼ��ÿ� ���� ������ ǥ���ϵ��� �Ķ���͸� �ָ�,
%	map image�� ������� ���� ���·� ���� ������ �������� ������ �Ͼ.
%����, ������ ���� ���� �̹����� �غ��ؼ�, map image ���� ������ ��.
figure;
topoplot([], cedPATH, 'style','blank', 'electrodes','on');	%����������
colorbar;
topo_locs_cdata		=	print('-RGBImage');	close;		% �̹��� ������ ĸ��
[h, w, c]			=	size(topo_locs_cdata);
topo_locs_cdata(:,w- w/10*2.2:end,:)	=	255;		% ����22%:colorbar ����

figure;
topoplot([], cedPATH, 'style','blank', 'electrodes','labels');%�����̸���
colorbar;												%��Ȯ�� head��ġ ����
topo_labels_cdata	=	print('-RGBImage');	close;		% �̹��� ������ ĸ��
[h, w, c]			=	size(topo_labels_cdata);
topo_labels_cdata(:,w- w/10*2.2:end,:)	=	255;		% ����22%:colorbar ����
clear h w c;
%imwrite(topo_labels_cdata, OUT_JPEG);	%-]
%}
AllTime				=		tic;		%������ preparing �ð��� �����Ѵ�.
for freqnumb		=	1:length(fName)
	% ���� �м��Ϸ��� ���ļ� �뿪�� �����մϴ�.(alpha, beta, theta �� �ϳ�)
	% �츮�� �м��Ϸ��� ���ļ��� 1Hz ���� 0.5������ 50Hz ���� ������,
	% Variable���� �׷��� �������� 1��, 2��, 3��, ... , 99����� ����� �����Ƿ�,
	% ���ļ����� ���� Variable������ ���° �࿡ �ִ��� freqindex�� �������ݴϴ�.
	% (���ļ� �����ʹ� 3���� �������̹Ƿ� ������ ������ '��'�� �ƴ�����,
	%	������ ������ �ֽñ� �ٶ��ϴ�.)
%	eval(['freqband	=	' char(fName{freqnumb}) ';']);
	%�ؼ����� 'freqband = theta;' �̹Ƿ� ������ ������ theta ���� �����
	freqband		=	Freqs{freqnumb};
	freqindex		=	2*freqband-1;
	% ex)	freqband: 1Hz	=	freqindex: 1�� /
	%		freqband: 1.5Hz	=	freqindex: 2�� /
	%		freqband: 2 Hz	=	freqindex: 3��

	%% ���Ĵ뿪�� ���� TFi (not baseline correction) �� ���� �ð�ȭ ����
	%[251:501];    % TFe_bl�� Timewindow. 0ms ~ 500ms
	%[51:201];     % TFi�� Timewindow. -400ms ~ -100ms
	%[51:201];     % TFi_bl�� Timewindow. -400ms ~ -100ms
%	if find(ismember(fName, 'alpha'))	% ������ ���, pre stimulus ó���ؾ� ��
	if fName{freqnumb} == 'alpha'	% ������ ���, pre stimulus ó���ؾ� ��
		ananame		=	{	'TFe_bl', 'TFi'		};	% TFi�� bl ���� �� ��
		blERP_TpWin	=	[1:250];	% -500 ~ 0ms, (20151102A. ������ ����)
		lTpWin4Sens	=	{	[251:501],	[51:201]	};	%
		lTpWin4Cogn	=	{	[501:751],	[501:751]	};
						% congnition time window : 500ms ~ 1000ms
	else
		ananame		=	{	'TFe_bl', 'TFi_bl'	};
		blERP_TpWin	=	[1:250];	% -500 ~ 0ms, (20151102A. ������ ����)
		lTpWin4Sens	=	{	[251:501],	[251:501]	};
		lTpWin4Cogn	=	{	[501:751],	[501:751]	};
						% congnition time window : 500ms ~ 1000ms
	end

for ananumb			=	1:length(ananame)
% ananame, �� ���ļ� ������ Ÿ�Կ� ���� tpwin4sen�� �ٸ��� �����մϴ�.
% �Ʒ��� �ڵ带 �ٸ� for�� ������ �̵��ϰ� ananumb�� �� for���� �´� ����(ex: datanumb, trialnumb, freqnumb, ...)
% ������ �����ϸ� ���ļ� ������ Ÿ���� �ƴ� ���� �����̳� ���ļ� ������ ���� tpwin4sen�� �ٲ� �� �ֽ��ϴ�.

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ݵ�� �м��� ������ ����� ��. (��: ���ļ� : ���Ĵ뿪 ��)
fprintf(['@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n'															...
'The processing parameters have:\n'											...
'\tANAdomain: [%s]\n'														...
'\tFrequency: %4.2f ~ %4.2f ; step(%4.2f)\n'								...
'\tChannel  : total n(%d) ; REAL n(%d)\n'									...
'\tSubject  : n(%d)\n'														...
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n']																	...
,	ananame{ananumb}, Freqs{freqnumb}(1), Freqs{freqnumb}(end),				...
	(Freqs{freqnumb}(end)-Freqs{freqnumb}(1))/(length(Freqs{freqnumb})-1),	...
	length(channame), length(channame)-length(removech),					...
	length(subname)	);
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	tpwin4sen		=	lTpWin4Sens{ananumb};				% timepoint(arr idx)
	tWin4SENS		=[tpwin4sen(1)-1:1:tpwin4sen(end)-1]*tStep+tRange(1);	%�ð�
%	tpwin4cog		=	lTpWin4Cogn{ananumb};
%	tWin4COGN		=[tpwin4cog(1)-1:1:tpwin4cog(end)-1]*tStep+tRange(1);	%�ð�

	tWend			=	tWin4SENS(end);
	if tWend < 0, 			tWend	=	abs(tWend);		end		% absulte
	if 1000 < tRange(end),	tWend	=	1000;		% 1s
	else					tWend	=	tRange(end);	end
	tWin4ERP		=	0 : tStep : tWend;				clear tWend;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SDthre			=	3;								% SD > 3
	nCond			=	1;								% �� ���� case

	for datanumb	=	1:length(dataname)
	for trialnumb	=	1:length(trialname)

		SubPATH		=	[ '_WaveLET_' char(fName{freqnumb}) ];
		GERP_IMAG	=[	fullPATH SubPATH '/ERP_Grd'  '_AllBand_'			...
						char(dataname{datanumb})	''						...
						char(trialname{trialnumb})	]; % ERP_Grd_Fav_like

		DOMAINNAME	=[	char(ananame{ananumb})		'_'						...
						char(fName{freqnumb})		];
		GRDWNAME	=[	DOMAINNAME					'_'						...
						char(dataname{datanumb})	''						...
						char(trialname{trialnumb})	];
		GRD_NAME	=[	fullPATH SubPATH '/GrandAvg' '_'	GRDWNAME '.dat'];
		GRD_IMAG	=[	fullPATH SubPATH '/topo_Grd' '_'	GRDWNAME	];
		G2D_IMAG	=[	fullPATH SubPATH '/gp2d_Grd' '_'	GRDWNAME	];

		GrdTime		=		tic;		%������ preparing �ð��� �����Ѵ�.

		xlsMaxData				=	{;};
		xlsMaxData{1,1}			=	'Subject';
		xlsMaxData{1,2}			=	'Max Value';
		xlsMaxData{1,3}			=	'Max Frequency(Hz)';
		xlsMaxData{1,4}			=	'Max Time(ms)';
		xlsMaxData{1,5}			=	'Max Channel';
		xlsMaxData{1,6}			=	'Interp Ch.';

	for subnumb		=	1:length(subname)
		xlsMaxData(subnumb+2,:)	=	{ '' };				% �ʱ�ȭ

		%���Ǹ� ���� ���ϸ��� ������ ��
		WORKNAME	=[	char(subname{subnumb})		'_'						...
						char(dataname{datanumb})	''						...
						char(trialname{trialnumb})	];
		ERP_IMAG	=[	fullPATH SubPATH '/ERP_Indi' '_AllBand_'	WORKNAME ];
						% ERP_Indi_su02_Fav_like

		SRC_NAME	=[	fullPATH '_tf' '/ERP_Evk_Tot_'	WORKNAME '.mat'];
		OUT_NAME	=[	fullPATH SubPATH			'/'					...
						char(ananame{ananumb})		'_'						...
						char(fName{freqnumb})		'_'		WORKNAME '.dat'];
		OUT_IMAG	=[	fullPATH SubPATH '/topo_Indi' '_'				...
						DOMAINNAME					'_'		WORKNAME	];
		O2D_IMAG	=[	fullPATH SubPATH '/gp2d_Indi' '_'				...
						DOMAINNAME					'_'		WORKNAME	];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%grand average �� ���ؾ� �ϹǷ�, individual �� skip�� ������ �ȵ�!
		%check result file & skip analysis if aleady exists.
		fprintf('\n--------------------------------------------------\n');
		fprintf('\nChecking: Analyzed result file: ''%s''... ', OUT_NAME);
		if exist(OUT_NAME, 'file') > 0					%exist !!
			fprintf('exist! & SKIP analyzing this\n');
			continue;									%skip
		else
			fprintf('NOT & Continue the Analyzing\n');
		end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		SubTime		=		tic;		%������ preparing �ð��� �����Ѵ�.
		fprintf('Process : %s''s TF to TOPO on Frequency.\n', WORKNAME);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%check & auto skip if not exist a 'dat file.
		%20151030A. ����� �������� ������ ����, �����Ͱ� �߻� �Ұ� ����
		%����: ���� ���ǿ� ���� Ʈ���Ű� ���� ���,
		%	Ư�� segment �� �߻����� ���� �� �ִ�.
		%	��: Unfav_like ���� �������� ���� ������ ��ǰ�� ������ ����
		%		������, �������� ���� �� �־ Ʈ���Ű� �߻����� �ʰ� ��.
		%ó��: ����, DAT�� ���� ��쿡 ��� �ϰ�, �̿� �����ϴ� ��ġ�ʿ�
		%	-> ��ü sub ���� n ���� �ϳ� �پ��� ���� ������ ó�� �ʿ�
		fprintf('Checking: Source MAT file: ''%s''... ', SRC_NAME);
		if exist(SRC_NAME, 'file') <= 0					%skip
			fprintf('not! & SKIP converting this\n');
			fprintf(['WANRNING: %s is not found. It maybe be correct..\n' ...
				'\tBut recommanded to double checking. please.\n'], SRC_NAME);
			continue;									%exist !!
		else
			fprintf('EXIST & Continue the converting\n');
		end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		%% ������ �ε�
%		eval(['DataBuf = importdata(''Phase_' char(ananame{ananumb}) '_' char(fName{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'');']);
		load( SRC_NAME );
		% ���� �м��Ϸ��� data(TFe, TFi, TFi_bl �� �ϳ�)�� Potential_Indi�� ����
		eval(['Potential_Indi= ' char(ananame{ananumb}) '(freqindex,:,:);']);

%		Potential_Indi(:,:,[17 22])	=	0;		%�ʱ���� �����ؾ� interp ����X!
%		Potential_Indi2	=	Potential_Indi;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
		for f = 1 : size(Potential_Indi,1)		%�� ���ļ����� ch*t ������ ���
			[ Potn2D lGoodChan lBadChan lZvalue ] = AmHlib_FindBad_ChInterp( ...
				squeeze(Potential_Indi(f,:,:)), tpwin4sen, SDthre);	% t x ch

			for b	= 1 : length(lBadChan)	% Bad ä���� �߰�: ���� ����
				fprintf('Ch.Info.: Bad Ch %s(Z=%f) on Freq(%4.1fHz)\n',		...
						channame{lBadChan(b)}, lZvalue(b), freqband(f));
			end	%for

			Potential_Indi2(f,:,:)	=	Potn2D;
		end
%}
		lBadChan		=	[];
		Potential_Indi2	=	Potential_Indi;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dataname x trialname x subname �� ���� ERP �� �׷����� �׸���.
		%	�̶�, ERP�� ��� ���ļ� ������ �� �����ϴ� ������ ������ �����Ƿ�,
		%	������ �ִ� freq, ana �� ���� �ݺ��� �ʿ䰡 ����.
		%	����, f=1, a=1 �� ��쿡�� �׷����� �׸��� �ȴ�.
	if freqnumb == 1 && ananumb == 1
		% ERP_filt_bl �� 0.5 ~ 30 Hz �� ���͸� �Ǿ� ����
		% ERP ���� bad chan �� �����ϰ�����, �ϴ��� �����ϰ� ��ü�� ó������.
%{
		[ ERP_Interp lGoodChan lBadChan lZvalue ] = AmHlib_FindBad_ChInterp( ...
			ERP_filt_bl, tpwin4sen, SDthre);	% t x ch

		for b	= 1 : length(lBadChan)	% Bad ä���� �߰�: ���� ����
			fprintf('Ch.Info.: Bad Ch %s(Z=%f)\n',							...
					channame{lBadChan(b)}, lZvalue(b));
		end	%for
%}
		%% drawing ERP 2D for signal T * ch : checking for noise or spike
		AmHlib_ERP_overlap(ERP_filt_bl, tRange, tWin4ERP, [ERP_IMAG '.jpg']);
%		AmHlib_ERP_overlap(ERP_Interp, tRange, tWin4ERP, [ERP_IMAG '.jpg']);

		%% collecting ERP for grand ------------------------------
		ERP_List(subnumb,:,:)	=	ERP_filt_bl;		% t * ch
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% Finding Maximum Frequency at range for sensory (ex: 0 ~ 500ms) -------
		% ���� �м��Ϸ��� ������ Ÿ��(TFe, TFi, TFi_bl �� �ϳ�)��
		% Potential_Indi�� ����.
		% �� �� �����ִ� ���ļ� ����, tpwin4sen, ä�� ��Ͽ� �����մϴ�.
		Potential_Indi3		=	Potential_Indi2(:, tpwin4sen, idxLiveCh);

		% activation�� �ִ��� ���ļ�, �� Individual Freq ã�Ƽ�, FreqVal�� ����.
		% FreqVal�� ���� ���ļ� ��, FreqIdx�� �� ��.
		% �׷��Ƿ� ������ �ڵ忡�� �̿��ϴ� ���� FreqIdx ���Դϴ�.
		[lMaxVal4Ch MaxChan]=	max(Potential_Indi3, [], 3);	%ä���� �ִ�
		[lMaxVal4Tp MaxTmPt]=	max(lMaxVal4Ch, [], 2);		%time�� �ִ�
		[MaxValue   MaxFreq]=	max(lMaxVal4Tp);			%FreqVal�� �ִ�

		MaxTmPt				=	MaxTmPt(MaxFreq);			%�� �Ѱ��� time pt
		MaxChan				=	MaxChan(MaxFreq, MaxTmPt);	%�� �Ѱ��� ä��
		MaxChan				=	idxLiveCh(MaxChan);			%���� ä�� ��ȣ

		MaxTpoint			=	MaxTmPt + tpwin4sen(1) -1 ;	%���� ����: index
		MaxTime				=	MaxTpoint *tStep +tRange(1);	%ms�� ��ȯ

		FreqVal				=	freqband(MaxFreq);
		FreqIdx				=	freqindex(MaxFreq);			%Ư�� ���ļ� idx
		FreqRel				=	FreqIdx -freqindex(1) +1;	%��� ���ļ� idx

		%20151013A. ������ max()�δ� �������� ���� ���� ����.
		%	3���� ���ӵ� �� a,b,c�� ���Ͽ� a<b && b<c �� ���, b�� ������.

		%% ������ ������ ������ ���� ------------------------------
		xlsMaxData{subnumb+2,1}	=	char(subname{subnumb});
		xlsMaxData{subnumb+2,2}	=	num2str(MaxValue);
		xlsMaxData{subnumb+2,3}	=	num2str(FreqVal);
		xlsMaxData{subnumb+2,4}	=	num2str(MaxTime);
		xlsMaxData{subnumb+2,5}	=	channame{MaxChan};
		xlsMaxData{subnumb+2,6}	=	strjoin({channame{lBadChan}},', ');

		%%print out fined FreqVal info to screen.
		fprintf(['\nFinding %s''s Maximum(%7.5f) at '						...
				'Frequency(%4.2fHz), TimePoint(%dms), Channel(%s)\n'],		...
				WORKNAME, MaxValue, FreqVal, MaxTime, channame{MaxChan});

		% Select Data For Frequency:
		% Individual Frequency�� �����͸� �����Ͽ� Potential_Indi_Freq �� ����.
%		eval(['Potential_Indi_Freq	=	double(squeeze('					...
%							char(ananame{ananumb}) '(FreqIdx,:,:)));']);
		%% 20151008. Potential_Indi2�� ���� interpolation ���� -> ���⼭ ���� ��
		Potential_Indi_Freq	=	double(squeeze(Potential_Indi2(FreqRel,:,:)));
		%Potential_Indi_Freq(timewin, chan)�� 2D ���� <- specific FreqVal confirm

		% matlab���� ����ϴ� �����Ϳ����� 17���� 22�� ä���� ����
		% NaN���� ������ �־�������, �� ��� Analyzer������ ������ ���� ������
		% ���⼭�� 0���� ����.
		% 20150912A. NaN �� *.dat�� ��½�, BrainAnalyzer�� ��������.
		% -> �׷���, EOG, NULL ä�ο��� �����Ͱ� ���ûӸ� �ƴ϶�,
		%		��ü ä���� ��ȣ�� ERP�� �ƴ� �ſ� �̻��� �������� �䵿ģ��
%		Potential_Indi_Freq(:,[17 22])=	0;

		%% Save Data
		save(OUT_NAME, 'Potential_Indi_Freq', '-ascii');	%dat �������� ����
		MakeVHDR_AmH(OUT_NAME, tStep*1000, channame);		%����������� ����

%{
		%% finding peak amp at range for cognition (ex: 500ms~1000ms) ----------[
		Potential_Indi4		=	Potential_Indi_Freq(tpwin4cog,:);

		[lMaxVal  lMaxTp]	=	max(Potential_Indi4);		% max for all time
		[MaxValue MaxChan]	=	max(lMaxVal);				% for chan of time

%		MaxValue			=	buf2;
%		MaxChan				=	buf2_idx;
		MaxTpoint			=	lMaxTp(MaxChan) + tpwin4cog(1) -1 ;

		%%print out fined FreqVal info to screen.
		fprintf('Finding Max(%5.2f) is %d[ms] at Ch[%s]\n',					...
								MaxValue, MaxTpoint, channame{MaxChan});%-]
%}
%		Potential_TOPO		=	Potential_Indi_Freq(MaxTpoint, :); %Ư��Tp*AllCh

		%% drawing topo ploting ------------------------------
		fprintf('\nDrawing : for Indivisual topoplot');
		AmHlib_topoplot_alone(	Potential_Indi_Freq,	tRange, tWin4SENS,	...
								FreqVal, MaxTpoint, MaxChan, [OUT_IMAG '.jpg']);
%{
		topo_main_cdata		=	print('-RGBImage');	close;	%���� topo ĸ�� -[

		%% image synthesis processing -----------------------
		imshow(topo_main_cdata);
		hold on;
		hCdata				=	imshow(topo_locs_cdata);	% topo�� ���� �׸���
		AlphaData			=	topo_locs_cdata < 200;		% ���(���)���� ū��
		set(hCdata, 'AlphaData', AlphaData(:,:,1));			% ���� ����
		hold on;
		hCdata				=	imshow(topo_labels_cdata);	% topo�� ���� �׸���
		AlphaData			=	topo_labels_cdata < 200;	% ���(���)���� ū��
		set(hCdata, 'AlphaData', AlphaData(:,:,1));			% ���� ���� -]
%}

		%% drawing 2D graph for signal T * ch : checking for noise or spike
		AmHlib_2d_overlap(		Potential_Indi_Freq,	tRange, tWin4SENS,	...
								FreqVal, MaxTpoint, MaxChan, [O2D_IMAG '.jpg'])

		%% collecting topo for grand ------------------------------
		% ��� ������ ������ dat������ ���������� �̿��ϴ� ���ϵ��� �ƴմϴ�.
		% ������ �� ���� �����͸��� ������ ���̱� �����Դϴ�.
		% �츮�� �м��� ���� ������ ã������ ���̹Ƿ�,
		% �Ʒ��� Potential_List���ٰ� �� �����ڵ��� �����͸� ��� �����ϰ�,
		% �̸� Grand Average �� data�� topo�� �׷��� ������ Ȯ���� ���Դϴ�.
		% ������ �������� �����Ͱ� �ʿ��� ��쵵 �����Ƿ�
		% ������ ������ ���� �� �Դϴ�.
		Potential_List(subnumb,:,:)	=	Potential_Indi_Freq;

		toc(SubTime);		%for subject
	end;	% subject

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% calculating & saving grand to jpeg============================================
try		%check a 'exception happen that not define the Potential_List'
		Potential_List;		% ������ exception ����
catch	exception	%if happen the exception, then skip all subject.
		fprintf('\nGrand of %s has been some error, then SKIP\n', GRDWNAME);
		toc(GrdTime);		%for subject
		continue
end		%try - catch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% 20151020B. �ڵ����� outlier�� �ǵ��ϴ� �˰��� ���
		% �ٸ� subject�� ����, amp range�� ū ���� ���̴� ��� ���� �ؾ� ��.
		%	stats model: normal distribution
		%	threshold: SD>3 �� ��
		%	object: channel data of Potential_List(indi, twin, all ch)
		%		����, ������ ��ü ���ļ� �� t win ���� ������ ä�ε��� �񱳺м�
		% 1. ��ü �����Ϳ� ���ؼ� normal distribution�� ����Ѵ�.
		% 2. ��, �� ���ļ� ������ twin ������ ��� ä���� ���, SD ���� ��,
		% 3. Z = (X-u) / (SD/sqrt(n))�� ����, P(Z<-1.96 U 1.96>Z) (95%, p<0.05)��
		%	max�� ������ ä���� �ִ��� ��������.
		% 4. P(Z<-1.96 U 1.96>Z) �̸� �ǹǷ�, Z<-1.96 �̰ų� 1.96<Z �� Z�� ��
		%	��, ä�� max ���� X �̰�, �̸� ����ȭ �� Z �� ũ�⸦ �ǵ��ϸ� ��
		% 5. ���� 99% ������ �Ѵٸ� P(Z<-2.575 U 2.575<Z) �� �����ϸ� �ȴ�
		%	-> 90% �� P(Z<-1.645 U 1.645<Z) ��.
		%	-> �����԰� ������ �� ���, 99% �� �°�, 2.575 ������, ������ 3 ��
		% 6. bad ch�� �߰ߵǸ�, ������ �� ������ indi �׷����� �ٽ� ������ �õ�
		%	-> �� �̻� bad �� ���ŵ� loop ����
		% 7. bad ch�� �߰ߵǸ�, ������ excel�� ǥ���� ��

			% ���� ����� array�� �� indivisual�� max ����� ����Ǿ� ����
%{
			xlsMaxData{subnumb+2,1}	=	char(subname{subnumb});
			xlsMaxData{subnumb+2,2}	=	MaxValue;
			xlsMaxData{subnumb+2,3}	=	FreqVal;
			xlsMaxData{subnumb+2,4}	=	MaxTime;
			xlsMaxData{subnumb+2,5}	=	channame{MaxChan};
%}
			tic; lMaxVal	=	xlsMaxData(3:end, 2)';		% max arr, row
			lMaxVal			=	str2double(lMaxVal);		% ���ڷ� ��ȯ
			lOutlier		=	[];
			nTune			=	1;							% calibrationī��Ʈ
		while true											% bad ch ���� ������
			fprintf('\nTuning  : Step(%d) Outlier searching\n', nTune);
			%% outlier ���� max�� ������ indivisual �� ã�� ---------------	%-[

			% �� ������ u, SD�� �������.
			MN_ch			=	mean(lMaxVal);				% ä�κ� max���� ���
%			SD_ch			=	std(lMaxVal) / sqrt(size(lMaxVal));% SD / sqrt(n)
			SD_ch			=	std(lMaxVal);				% SD / sqrt(n)

			% ����ȭ ����
			Z				=	( lMaxVal - MN_ch ) / SD_ch;% Z �� array
			lOut			=	find( SDthre<abs(Z) );		% SD>3 �� ��Ҹ�
			lNew			=	lOut(find(~ismember(lOut, lOutlier))); %�űԸ�
			Zout			=	Z(lNew);					% SD>3 �� Z ����

			if isempty(lNew),	break;	end;				% �ű� out idx ����

			% Ž���� �ű� outlier �����Ƿ� ��ó
%			fprintf('Verify  : Outlier(%s)\n', strjoin({subname{lOut}}, ', '));
			for o = 1 : length(lNew)
				fprintf('Verify  : Outlier %s(Z=%f)\n',subname{lNew(o)},Zout(o));
			end	%for

			lOutlier		=	[ lOutlier lNew ];			% ���� �Ͱ� ��ħ
%			lInlier			=	lInlier( find(~ismember(lInlier,lOutlier)) );
%			lMaxVal			=	lMaxVal( lInlier );			% ���� �ִ밪 �� %-]

			nTune			=	nTune + 1;
		end	%while
			fprintf('Tuning  : Finish. %d of Outlier(%s). during %d step.\n',...
			length(lOutlier), strjoin({subname{lOutlier}},', '), nTune); toc;

		lInlier				=	1:size(Potential_List,1);
		lInlier				=	lInlier( find(~ismember(lInlier,lOutlier)) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dataname x trialname x subname �� ���� ERP �� �׷����� �׸���.
		%	�̶�, ERP�� ��� ���ļ� ������ �� �����ϴ� ������ ������ �����Ƿ�,
		%	������ �ִ� freq, ana �� ���� �ݺ��� �ʿ䰡 ����.
		%	����, f=1, a=1 �� ��쿡�� �׷����� �׸��� �ȴ�.
	if freqnumb == 1 && ananumb == 1
		% ERP_filt_bl �� 0.5 ~ 30 Hz �� ���͸� �Ǿ� ����
		% ERP ���� outlier �� �����ϰ�����, �ϴ��� �����ϰ� ��ü�� ó������.

		% ERP�� ���� ����� �������Ƿ�, �ٽ� BL �� ��.
		ERP_GA				=	squeeze(mean(ERP_List));	% t * 32
		ERP_GA_bl			=	ERP_GA										...
				- repmat(mean(ERP_GA([blERP_TpWin],:)), [size(ERP_GA,1),1]);

		%% drawing ERP 2D for signal T * ch : checking for noise or spike
		AmHlib_ERP_overlap(ERP_GA_bl, tRange, tWin4ERP, [GERP_IMAG '.jpg']);
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% for���� ��� ���ұ� ������ Ư�� ���� ����, ���ļ� ������ ���� ���
		% �����ڵ��� �����Ͱ� Potential ������ ����Ǿ���, �̸� ���  ���� ��.
		% �� �������� �����Ϳ����� 17���� 22�� ä���� ���� NaN���� ������
		% �־�������, �׷��� �� ��� Analyzer������ ������ ���� ������
		% ���⼭�� 0���� ���� �ؾ� ��!
		Potential_List		=	Potential_List(lInlier, :, :); % ���� �߸�
		Potential_GrdAvg	=	squeeze(mean(Potential_List));% t * 32
%		Potential_GrdAvg(:,[17 22])=	0;
		save(GRD_NAME, 'Potential_GrdAvg', '-ascii');
		MakeVHDR_AmH(GRD_NAME, tStep*1000, channame);		%����������� ����

		% activation�� �ִ��� tp, �� GrandAverage Time Point ã�Ƽ� ����.
		[lMaxVal4Ch MaxChan]=	max(Potential_GrdAvg(tpwin4sen,:),[],2);%ä���ִ�
		[MaxValue   MaxTmPt]=	max(lMaxVal4Ch);			%time�� �ִ�
		MaxChan				=	MaxChan(MaxTmPt);			%�� �Ѱ��� ä��
		MaxTpoint			=	MaxTmPt + tpwin4sen(1) -1 ;	%���� ����
		MaxTime				=	MaxTpoint *tStep +tRange(1);	%ms�� ��ȯ

		%% ������ ������ ������ ���� ------------------------------
		xlsMaxData{2,1}		=	'Grand Average';
		xlsMaxData{2,2}		=	num2str(MaxValue);
		xlsMaxData{2,3}		=	num2str(FreqVal);
		xlsMaxData{2,4}		=	num2str(MaxTime);
		xlsMaxData{2,5}		=	channame{MaxChan};
		if lOutlier, 			% outlier�� ������ ����,
			xlsMaxData{2,6}	=	subname{lOutlier};
		else
			xlsMaxData{2,6}	=	'';
		end

		%%print out fined FreqVal info to screen.
		fprintf(['Finding %s''s Grand Average Maximum(%7.5f) at '			...
				'Frequency(%s), TimePoint(%dms), Channel(%s)\n'],			...
		WORKNAME, MaxValue, fName{freqnumb}, MaxTime, channame{MaxChan});

		% Select Data For Frequency:
%		Potential_GA_TOPO	=	double(squeeze(Potential_GrdAvg(MaxTpoint, :)));
		%(timewin, chan)�� 2D ���� <- specific FreqVal confirm
%		Potential_GA_TOPO(:,[17 22])=	0;

		%% drawing topo ploting ------------------------------
		fprintf('\nDrawing : for Grand Average topoplot');
		AmHlib_topoplot_alone(	Potential_GrdAvg,	tRange, tWin4SENS,		...
						fName{freqnumb}, MaxTpoint, MaxChan, [GRD_IMAG '.jpg']);

		%% drawing 2D graph for signal T * ch : checking for noise or spike
		AmHlib_2d_overlap(		Potential_GrdAvg,	tRange, tWin4SENS,		...
						fName{freqnumb}, MaxTpoint, MaxChan, [G2D_IMAG '.jpg']);

		%% �α������� ���� -> �⺻���� ó�� ������ ����ؼ� �̽� �ľ� ����
%{
		%% unix������ actxserver�� ����� �� ��� ���� excel OLE�� �������� -[
		% ���ϹǷ�, matlab ���������� switching �Ͽ� dlmwrite�� �����ϴµ�
		% �� ��쿡 param�� ��� �����ʹ� '������ type' �̾�� ��!
		% ����, xlsMaxData �� 2:4 �� ����� ���ڸ� ���ڿ��� ��ȯ �ʿ���!
		% 2���� ��ȯ����� ����.
		%	-> arrayfun(@num2str, [xlsMaxData{17,2:4}], 'unif', 0)
		%	-> cellfun(@(x)({num2str(x)}),{xlsMaxData{17,2:4}})
 		% �� �Լ����� �Ķ���Ͱ� array �� ���, iteratoró�� ������.
 		% �� �� cellfun�� �̿��ϱ�� ����.
		num					=	2:4;
		sh					=	shiftdim(xlsMaxData, 1);	% sub*data->d*sub
		sh(num,2:end)		=	reshape(cellfun(@(x)({num2str(x)}),			...
											{sh{num,2:end}}), length(num), []);
		xlsMaxData			=	shiftdim(sh, 1);	%-]

%		xlswrite('d2_evk_tot.xls', xlsMaxData, GRDWNAME);	%Ư�� ��Ʈ�� ����
		XLS					=	fopen(['d2_evk_tot_' GRDWNAME '.txt'], 'w');
		for l = 1 : size(xlsMaxData,1)
			fprintf(XLS, '%s\n', strjoin(xlsMaxData(l, :), '\t'));
		end
		fclose(XLS);
%}
		xlsAllMax{nCond,1}	=	GRDWNAME;
		xlsAllMax{nCond,2}	=	xlsMaxData;		clear				xlsMaxData;
		nCond				=	nCond + 1;

		toc(GrdTime);		%for subject
	end	%trial
	end	%data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% writing statistics info for excel:
	% �ۼ����: �ϳ��� tab�� �Ʒ��� ���� condition�� ��� ������.
% ��: Fav_Like Fav_Dislike Neutral_Like Neutral_Dislike Unfav_Like Unfav_Dislike
%{
	xlsMaxData		=	{;};
	xlsMaxData{1,1}	=	'Subject';
	xlsMaxData{1,2}	=	'Max Value';
	xlsMaxData{1,3}	=	'Max Frequency(Hz)';
	xlsMaxData{1,4}	=	'Max Time(ms)';
	xlsMaxData{1,5}	=	'Max Channel';
	xlsMaxData{1,6}	=	'Interp Ch.';
%}
	XLS	=	fopen([fullPATH SubPATH '/d2_' char(ananame{ananumb}) '.txt'], 'w');
%	xlsAllMax{2:end,2}{:,1}	=	[];							%1��° sub�̸��� ����
	for n = 2 : size(xlsAllMax,1)
		xlsMaxData			=	xlsAllMax{n, 2};
		xlsMaxData(:,1)		=	[];							%1��° sub�̸��� ����
		xlsAllMax{n, 2}		=	xlsMaxData;
	end;

	% ���� ������ ����ؾ� �ϹǷ�, �ϳ��� ���ο� ���� ��� �׸��� �����ؼ� ����
	for n = 1 : size(xlsAllMax,1)				%���ڿ� �߰��� �ִ� ������ ����
		% cond �̸����� �������� �����Ѵ�.
%		xlsAllMax{n, 1}	=	regexprep(xlsAllMax{n, 1}, '_[^_]+_([^_]+)$', '_$1');
		% �׸��� ����Ѵ�. line ����
		fprintf(XLS, '%s', xlsAllMax{n, 1});				% condition ǥ��
		fprintf(XLS, repmat(sprintf('\t'), 1, size(xlsAllMax{n,2},2)) ); %����
	end
		fprintf(XLS, '\n');

	% ���� subject ������ ���� ����
	%20151030A. ����� �������� ������ ����, �����Ͱ� �߻� �Ұ� ����
	%����: ���� ���ǿ� ���� Ʈ���Ű� ���� ���
	%�ع�: 
	for s = 1 : size(xlsAllMax{n, 2},1)
		for n = 1 : size(xlsAllMax,1)			%���ڿ� �߰��� �ִ� ������ ����
			xlsMaxData		=	xlsAllMax{n, 2};
			fprintf(XLS, '%s\t', strjoin(xlsMaxData(s,:), '\t'));
		end
		fprintf(XLS, '\n');
	end
	fclose(XLS);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% writing VBA for powerpoint:
	% 1. ERP ����
if freqnumb == 1 && ananumb == 1	% �� ó������ �ۼ�
	AmHlib_OleAutomation_PPT_GenVBAcode( SubPATH,							...
				'GenPPTslide_ERP', 'AllBand', '', '', 'ERP_Grd', 'ERP_Indi');
				% ���ϸ�: ERP_Grd_AllBand_Fav_like
				% ERP_Indi_AllBand_su02_Fav_like
end
	% 2. EVK, TOT
	AmHlib_OleAutomation_PPT_GenVBAcode( SubPATH,							...
				[ 'GenPPTslide_' char(ananame{ananumb}) ],					...
				DOMAINNAME, 'topo_Grd', 'topo_Indi', 'gp2d_Grd', 'gp2d_Indi');
				% topo_Grd_TFe_bl_theta_Fav_like
				% gp2d_Grd_TFe_bl_theta_Fav_like
				% topo_Indi_TFe_bl_theta_su02_Fav_like

end;	% for ana
end;	% for freq
toc(AllTime);


%{
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%matlabpool close;
delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%}
