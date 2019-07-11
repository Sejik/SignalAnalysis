%% SaveFrequency.m %%
% �ΰ����� �ڵ� �Դϴ�.
% Analyzer���� ���ļ��� ���� topo�� ���ϱ� ���� �����͸� �����ϴ� ������ �ִ� �ڵ��,
% �������� �� ���ǿ� ���� �� ���ļ� �뿪���� ���� activation�� ū ���ļ�(Individual Frequency)�� ã��, 
% ��� ä�ο��� �� ���ļ������� �����͸��� dat���Ϸ� export�ϴ� ������ ��� �ֽ��ϴ�.
% export�� �����͸� Analyzer�� �ٽ� import�ϴ� ����� Word������ �����Ͻø� �˴ϴ�.
% ���� ���ļ� topo�� matlab���� �׸��ô°� ���Ͻôٸ� �� �ڵ带 �м��� ���� �����ŵ� �˴ϴٸ� 
% Individual Frequency�� ã�� �κ��� �����Ͻñ� �ٶ��ϴ�.

%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clear;
close all

%% Header %%
% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% channame: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% dataname, trialname: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% subname: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

%channame	=	{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6'};
%dataname	=	{'dislike'};
%trialname	=	{'Fav_USA'};
%subname	=	{'su102'};
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki	]	=	A_globals_AmH();

% SaveFrequency�� Header�� �߰��� �κ�����, eval�Լ��� ���� �� �ʿ��� �� ���ļ��뿪�� ������ �Է��صξ���,
% ���� �� �κп����� ���� ������ ���� �ִ� Ư�� ä���� �������� �ʾұ� ������, 17���� 22�� ä���� ������ ��� ä����
% Individual Frequency�� ã�� ���� ��� �����մϴ�.(chanlist)
%
% ananame�� wavelet����� ������ �� ���ļ� ������ 3����. ������ ���ؼ� Individual Frequency�� ���� ��
% �Դϴ�.
%
% timelist�� Individual Frequency�� ã�� �ð�����(timewindow)�� ���ļ� ������ 3������ ���� �ٸ���
% ������ �ֱ� ���� ���� ���� �������� �� �Դϴ�.(TFe�� �ڱ� ��, TFi/TFi_bl�� �ڱ� ��)
freqname		=	{'theta'};

%alpha			=	 8:1/2:13;
%beta			=	 13:1/2:30;
theta			=	 4:1/2:8;

chanlist		=	[1:16, 18:21, 23:32];
%chanlist		=	[1:11];			%���� ����� topo ���� �� ���� ���� ������

ananame			=	{	'TFe_bl', 'TFi', 'TFi_bl'	};
lTimeWin		=	{	[251:501],	[251:501],	[251:501]	};

%timelist		=	cell(1,1);
%timelist{1,1}	=	[251:501];    % TFe_bl�� Timewindow. 0ms ~ 500ms
%timelist{2,1}	=	[51:201];     % TFi�� Timewindow. -400ms ~ -100ms
%timelist{3,1}	=	[51:201];     % TFi_bl�� Timewindow. -400ms ~ -100ms


for ananumb				=	1:length(ananame)
	% ananame, �� ���ļ� ������ Ÿ�Կ� ���� timewindow�� �ٸ��� �����մϴ�.
	% �Ʒ��� �ڵ带 �ٸ� for�� ������ �̵��ϰ� ananumb�� �� for���� �´� ����(ex: datanumb, trialnumb, freqnumb, ...)
	% ������ �����ϸ� ���ļ� ������ Ÿ���� �ƴ� ���� �����̳� ���ļ� ������ ���� timewindow�� �ٲ� �� �ֽ��ϴ�.
%	timewindow			=	timelist{ananumb,1};
	timewindow			=	lTimeWin{ananumb};

	for datanumb		=	1:length(dataname)
	for trialnumb		=	1:length(trialname)

		%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		for freqnumb	=	1:length(freqname)
%			GRD_NAME	=[	fullPATH '/skk_fan/' 'GrdAvgInL' '_'			...
			GRD_NAME	=[	fullPATH '/skk_fan/' 'GrandAvg' '_'			...
							char(ananame{ananumb})		'_'					...
							char(freqname{freqnumb})	'_'					...
							char(dataname{datanumb})	'_'					...
							char(trialname{trialnumb})	'.dat'];

		for subnumb		=	1:length(subname)
			WORKNAME	=[	char(subname{subnumb})		'_'					...
							char(dataname{datanumb})	'_'					...
							char(trialname{trialnumb})	];
			DAT_NAME	=[	fullPATH '/skk_tf/' 'ERP_Evk_Tot_'	WORKNAME '.mat'];
			OUT_NAME	=[	fullPATH '/skk_fan/'							...
							char(ananame{ananumb}) '_'						...
							char(freqname{freqnumb}) '_'		WORKNAME '.dat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%grand average �� ���ؾ� �ϹǷ�, individual �� skip�� ������ �ȵ�!
			%check result file & skip analysis if aleady exists.
			fprintf('\nChecking: Analyzed result file: ''%s''... ', OUT_NAME);
			if exist(OUT_NAME, 'file') > 0					%exist !!
				fprintf('exist! & SKIP analyzing this\n');
				continue;									%skip
			else
				fprintf('NOT & Continue the Analyzing\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			AllTime		=		tic;		%������ preparing �ð��� �����Ѵ�.
			fprintf('\n--------------------------------------------------\n');
			fprintf('Process : %s''s TF to DAT on Frequency.\n', WORKNAME);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%check & auto skip if not exist a 'dat file.
			fprintf('Checking: Source DAT file: ''%s''... ', DAT_NAME);
			if exist(DAT_NAME, 'file') <= 0					%skip
				fprintf('not! & SKIP converting this\n');
				continue;									%exist !!
			else
				fprintf('EXIST & Continue the converting\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ���� �м��Ϸ��� ���ļ� �뿪�� �����մϴ�.(alpha, beta, theta �� �ϳ�)
% �츮�� �м��Ϸ��� ���ļ��� 1Hz ���� 0.5������ 50Hz ���� ������,
% Variable���� �׷��� ���� ���� 1��, 2��, 3��, ... , 99����� ����Ǿ� �����Ƿ�,
% ���ļ����� ���� Variable������ ���° �࿡ �ִ��� freqindex�� �������ݴϴ�.
% (���ļ� �����ʹ� 3���� �������̹Ƿ� ������ ������ '��'�� �ƴ�����,
%	������ ������ �ֽñ� �ٶ��ϴ�.)
			eval(['freqband	=	' char(freqname{freqnumb}) ';']);
			%�ؼ����� 'freqband = theta;' �̹Ƿ� ������ ������ theta ���� �����
			freqindex	=	2*freqband-1;
			% ex)	freqband: 1Hz	=	freqindex: 1�� /
			%		freqband: 1.5Hz	=	freqindex: 2�� /
			%		freqband: 2 Hz	=	freqindex: 3��

			%% ������ �ε�
%			eval(['load(''Phase_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.mat'');']);
			load( DAT_NAME );

			%% Finding Maximum Frequency(Individual Frequency)
			% ���� �м��Ϸ��� ������ Ÿ��(TFe, TFi, TFi_bl �� �ϳ�)��
			% Potential_Buf�� ����.
			% �� �� �����ִ� ���ļ� ����, timewindow, ä�� ��Ͽ� �����մϴ�.
			eval(['Potential_Buf		=		'							...
					char(ananame{ananumb}) '(freqindex,timewindow,chanlist);']);

			% activation�� �ִ��� ���ļ�, �� Individual Freq ã�Ƽ�, freq�� ����.
			% freq�� ���� ���ļ� ��, freq_index�� �� ��.
			% �׷��Ƿ� ������ �ڵ忡�� �̿��ϴ� ���� freq_index ���Դϴ�.
			buf						=	max(Potential_Buf, [], 3);	%ä���� �ִ�
			bufbuf					=	max(buf, [], 2);			%time�� �ִ�
			[bufbufbuf buf3_idx]	=	max(bufbuf);				%freq�� �ִ�

			freq					=	freqband(buf3_idx);
			freq_index				=	freqindex(buf3_idx);
			fprintf('Finding Freq(%s) is %f Hz\n', WORKNAME, freq);

			%% Select Data For Frequency
			% Individual Frequency�� �����͸� �����Ͽ� potential_topo �� ����.
			eval(['potential_topo	=	double(squeeze('					...
								char(ananame{ananumb}) '(freq_index,:,:)));']);
			%potential_topo(timewin, chan) �� 2D ����

			% matlab���� ����ϴ� �����Ϳ����� 17���� 22�� ä���� ����
			% NaN���� ������ �־�������,
			% �׷��� �� ��� Analyzer������ ������ ���� ������
			% ���⼭�� 0���� �������ݴϴ�.
			% 20150912A. NaN �� *.dat�� ��½�, BrainAnalyzer�� ��������.
			% -> �׷���, EOG, NULL ä�ο��� �����Ͱ� ���ûӸ� �ƴ϶�,
			%		��ü ä���� ��ȣ�� ERP�� �ƴ� �ſ� �̻��� �������� �䵿ģ��
			potential_topo(:,[17 22])=	0;

			%% Save Data
			% potential_topo ��� variable�� ����� �����͸� dat���Ϸ� export.
			% ���⼭�� 'FrequencyData'��� ������ �ϳ� ���� ����� �ְ� �� �ȿ�
			% dat���ϵ��� �����Ͽ����ϴ�.
			% cd �� current directory�� �̵��ϴ� �Լ�. �� �̵��� �ϰ� ������
			% ���������� �ʱ� ������ ������ ���� ����� �����ž� �մϴ�.
			% ..�� ���� ������ �̵�(���⼭�� ����ġ��)
%			cd FrequencyData
%			fname	=	['SKK_Phase_' char(ananame{ananumb}) '_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.dat'];
%			save(fname, 'potential_topo', '-ascii');
			save(OUT_NAME, 'potential_topo', '-ascii');		%dat �������� ����
			MakeVHDR_AmH(OUT_NAME);							%����������� ����
%			cd ..

			% ��� ������ ������ dat������ ���������� �̿��ϴ� ���ϵ��� �ƴմϴ�.
			% ������ �� ���� �����͸��� ������ ���̱� �����Դϴ�.
			% �츮�� �м��� ���� ������ ã������ ���̹Ƿ�,
			% �Ʒ��� topo_list���ٰ� �� �����ڵ��� �����͸� ��� �����ϰ�,
			% �̸� Grand Average �� data�� topo�� �׷��� ������ Ȯ���� ���Դϴ�.
			% ������ �������� �����Ͱ� �ʿ��� ��쵵 �����Ƿ�
			% ������ ������ ���� �� �Դϴ�.
			topo_list(subnumb,:,:)	=	potential_topo;

			clear	Potential_Buf buf bufbuf bufbufbuf buf3_idx			...
					freq freq_index potential_topo

%--------------------------------------------------------------------------------
%{
			% EEGLAB-��� topo drawing�� �ϱ� ���� ���� ����	%-[
			% from % http://cognitrn.psych.indiana.edu/busey/temp/eeglabtutorial4.301/scripttut/script_tutorial.html
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;	% start EEGLAB under Matlab

% read in the dataset
EEG = pop_loadset( 'eeglab_data.set', '/usr/local/eeglab13_4_4b/sample_data/');
[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % copy it to ALLEEG

% edit the dataset event field
EEG = pop_editeventfield(EEG, 'indices','1:155', 'typeinfo','Type of the event');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); % copy changes to ALLEEG

% update the dataset comments field
EEG.comments = pop_comments('', '',	...
	strvcat('In this experiment, stimuli can appear at 5 locations   ',	...
			'One of them is marked by a green box   ', ...
			['If a square appears in this box, the subject must respond, '	...
			'otherwise he must ignore the stimulus.'], '  ', ...
			['These data contain responses to (non-target) circles appearing '...
			'in the attended box in the left visual field '] ));
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); % copy changes to ALLEEG

%EEG = eeg_checkset(EEG); or EEG = eeg_checkset(EEG, 'eventconsistency');

pop_eegplot(EEG, 1, 0, 1);	% pop up a scroll-win showing the component activat..

%EEG.chanlocs=pop_chanedit(EEG.chanlocs, { 'load', '/home/payton/ee114/chan32.locs'},{ 'convert',{ 'topo2sph', 'gui'}},{ 'convert',{ 'sph2cart', 'gui'}}); % read the channel location file and edit the channel location information
EEG.chanlocs	=pop_chanedit(EEG.chanlocs, 'load',	...
				{'/usr/local/eeglab13_4_4b/sample_data/eeglab_chan32.locs',	...
				'filetype', 'autodetect'});
%%from http://sccn.ucsd.edu/wiki/Chapter_02:_Writing_EEGLAB_Scripts
pop_topoplot(EEG, 1);					%topo �� drawing ��

figure; pop_spectopo(EEG, 0, [-1000  237288.3983], 'percent', 20,	...
					'freq',[10], 'icacomps',[1:0], 'electrodes','off'); 
% plot RMS power spectra of the ICA component activations; show a scalp map of
% total power at 10 Hz plus maps of the components contributing most power at
% the same frequency

%%Important note that functions called from the main EEGLAB interactive window
%display the name of the underlying pop_function in the window title bar. For
%instance, selecting File > Load an existing dataset to read an existing data
%set uses EEGLAB function "pop_loadset()".
%-]
%}
		end		%for subname

		% for���� ��� ���ұ� ������ Ư�� ���� ����, ���ļ� ������ ���� ���
		% �����ڵ��� �����Ͱ� topo_list�� ����Ǿ���, �̸� ��ճ��ϴ�.
		% �� �������� �����Ϳ����� 17���� 22�� ä���� ���� NaN���� ������
		% �־�������, �׷��� �� ��� Analyzer������ ������ ���� ������
		% ���⼭�� 0���� �������ݴϴ�.
try		%check a 'exception happen that not define the topo_list'
		topo_GrandAverage			=	squeeze(mean(topo_list));
		topo_GrandAverage(:,[17 22])=	0;
catch	exception	%if happen the exception, then skip all subject.
		continue
end		%try - catch

		% ���������� FrequencyData������ ����.
		% ���ϸ��� _GrandAverage_�� �����ϴ� ���� ���� ������ �����Ϳ� �ٸ��ϴ�.
		% ���⼭ export �Ǵ� dat������ analyzer���� �ҷ��鿩 topo�� �׷��� ���ø� �˴ϴ�.
%		cd FrequencyData
%		fname	=	['SKK_PLV_GrandAverage_' char(ananame{ananumb}) '_' char(freqname{freqnumb})  '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'];
%		save(fname, 'topo_GrandAverage', '-ascii');
		save(GRD_NAME, 'topo_GrandAverage', '-ascii');
		MakeVHDR_AmH(GRD_NAME);								%����������� ����
%		cd ..

		clear topo_GrandAverage topo_list

		end		%for freqnum
	end			%for trialname
	end			%for dataname
end				%for ananame

