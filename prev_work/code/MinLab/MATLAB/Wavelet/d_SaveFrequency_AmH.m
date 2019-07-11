%% SaveFrequency.m %%
% 부가적인 코드 입니다.
% Analyzer에서 주파수에 대한 topo를 구하기 위한 데이터를 추출하는 과정이 있는 코드로,
% 피험자의 각 조건에 대해 각 주파수 대역에서 가장 activation이 큰 주파수(Individual Frequency)를 찾고, 
% 모든 채널에서 그 주파수에서의 데이터만을 dat파일로 export하는 내용을 담고 있습니다.
% export된 데이터를 Analyzer로 다시 import하는 방법은 Word파일을 참고하시면 됩니다.
% 만약 주파수 topo를 matlab에서 그리시는게 편하시다면 이 코드를 분석에 쓰지 않으셔도 됩니다만 
% Individual Frequency를 찾는 부분은 참고하시기 바랍니다.

%% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
clear;
close all

%% Header %%
% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% channame: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% dataname, trialname: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% subname: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

%channame	=	{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6'};
%dataname	=	{'dislike'};
%trialname	=	{'Fav_USA'};
%subname	=	{'su102'};
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki	]	=	A_globals_AmH();

% SaveFrequency의 Header에 추가된 부분으로, eval함수를 돌릴 때 필요한 각 주파수대역의 정보를 입력해두었고,
% 현재 이 부분에서는 아직 관심을 갖고 있는 특정 채널이 정해지지 않았기 때문에, 17번과 22번 채널을 제외한 모든 채널을
% Individual Frequency를 찾기 위한 대상에 포함합니다.(chanlist)
%
% ananame은 wavelet결과로 나오게 된 주파수 데이터 3가지. 각각에 대해서 Individual Frequency를 구할 것
% 입니다.
%
% timelist는 Individual Frequency를 찾는 시간범위(timewindow)를 주파수 데이터 3가지에 따라 다르게
% 나누어 주기 위해 각각 따로 저장해준 것 입니다.(TFe는 자극 후, TFi/TFi_bl은 자극 전)
freqname		=	{'theta'};

%alpha			=	 8:1/2:13;
%beta			=	 13:1/2:30;
theta			=	 4:1/2:8;

chanlist		=	[1:16, 18:21, 23:32];
%chanlist		=	[1:11];			%관심 목록은 topo 검토 후 별도 결정 사항임

ananame			=	{	'TFe_bl', 'TFi', 'TFi_bl'	};
lTimeWin		=	{	[251:501],	[251:501],	[251:501]	};

%timelist		=	cell(1,1);
%timelist{1,1}	=	[251:501];    % TFe_bl의 Timewindow. 0ms ~ 500ms
%timelist{2,1}	=	[51:201];     % TFi의 Timewindow. -400ms ~ -100ms
%timelist{3,1}	=	[51:201];     % TFi_bl의 Timewindow. -400ms ~ -100ms


for ananumb				=	1:length(ananame)
	% ananame, 즉 주파수 데이터 타입에 따라 timewindow를 다르게 지정합니다.
	% 아래의 코드를 다른 for문 안으로 이동하고 ananumb를 그 for문에 맞는 숫자(ex: datanumb, trialnumb, freqnumb, ...)
	% 등으로 지정하면 주파수 데이터 타입이 아닌 실험 조건이나 주파수 영역에 따라 timewindow를 바꿀 수 있습니다.
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
			%grand average 를 구해야 하므로, individual 중 skip이 있으면 안됨!
			%check result file & skip analysis if aleady exists.
			fprintf('\nChecking: Analyzed result file: ''%s''... ', OUT_NAME);
			if exist(OUT_NAME, 'file') > 0					%exist !!
				fprintf('exist! & SKIP analyzing this\n');
				continue;									%skip
			else
				fprintf('NOT & Continue the Analyzing\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			AllTime		=		tic;		%데이터 preparing 시간을 계측한다.
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

% 현재 분석하려는 주파수 대역을 지정합니다.(alpha, beta, theta 중 하나)
% 우리가 분석하려는 주파수는 1Hz 부터 0.5단위로 50Hz 까지 이지만,
% Variable에는 그러한 정보 없이 1행, 2행, 3행, ... , 99행까지 저장되어 있으므로,
% 주파수값이 실제 Variable에서는 몇번째 행에 있는지 freqindex에 저장해줍니다.
% (주파수 데이터는 3차원 데이터이므로 엄밀히 따지면 '행'은 아니지만,
%	적당히 이해해 주시기 바랍니다.)
			eval(['freqband	=	' char(freqname{freqnumb}) ';']);
			%해석값은 'freqband = theta;' 이므로 위에서 정의한 theta 값이 저장됨
			freqindex	=	2*freqband-1;
			% ex)	freqband: 1Hz	=	freqindex: 1행 /
			%		freqband: 1.5Hz	=	freqindex: 2행 /
			%		freqband: 2 Hz	=	freqindex: 3행

			%% 데이터 로드
%			eval(['load(''Phase_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.mat'');']);
			load( DAT_NAME );

			%% Finding Maximum Frequency(Individual Frequency)
			% 지금 분석하려는 데이터 타입(TFe, TFi, TFi_bl 중 하나)를
			% Potential_Buf로 지정.
			% 이 때 관심있는 주파수 영역, timewindow, 채널 목록에 한정합니다.
			eval(['Potential_Buf		=		'							...
					char(ananame{ananumb}) '(freqindex,timewindow,chanlist);']);

			% activation이 최대인 주파수, 즉 Individual Freq 찾아서, freq로 저장.
			% freq는 실제 주파수 값, freq_index는 행 값.
			% 그러므로 실제로 코드에서 이용하는 값은 freq_index 값입니다.
			buf						=	max(Potential_Buf, [], 3);	%채널중 최대
			bufbuf					=	max(buf, [], 2);			%time중 최대
			[bufbufbuf buf3_idx]	=	max(bufbuf);				%freq중 최대

			freq					=	freqband(buf3_idx);
			freq_index				=	freqindex(buf3_idx);
			fprintf('Finding Freq(%s) is %f Hz\n', WORKNAME, freq);

			%% Select Data For Frequency
			% Individual Frequency의 데이터만 추출하여 potential_topo 에 저장.
			eval(['potential_topo	=	double(squeeze('					...
								char(ananame{ananumb}) '(freq_index,:,:)));']);
			%potential_topo(timewin, chan) 의 2D 구성

			% matlab에서 사용하는 데이터에서는 17번과 22번 채널의 값을
			% NaN으로 지정해 주었었지만,
			% 그렇게 할 경우 Analyzer에서는 에러가 나기 때문에
			% 여기서는 0으로 지정해줍니다.
			% 20150912A. NaN 을 *.dat에 출력시, BrainAnalyzer는 오동작함.
			% -> 그래서, EOG, NULL 채널에도 데이터가 나올뿐만 아니라,
			%		전체 채널의 신호가 ERP가 아닌 매우 이상한 파형으로 요동친다
			potential_topo(:,[17 22])=	0;

			%% Save Data
			% potential_topo 라는 variable로 저장된 데이터를 dat파일로 export.
			% 여기서는 'FrequencyData'라는 폴더를 하나 새로 만들어 주고 그 안에
			% dat파일들을 저장하였습니다.
			% cd 는 current directory를 이동하는 함수. 즉 이동만 하고 폴더를
			% 생성하지는 않기 때문에 폴더는 직접 만들어 놓으셔야 합니다.
			% ..의 이전 폴더로 이동(여기서는 원위치로)
%			cd FrequencyData
%			fname	=	['SKK_Phase_' char(ananame{ananumb}) '_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.dat'];
%			save(fname, 'potential_topo', '-ascii');
			save(OUT_NAME, 'potential_topo', '-ascii');		%dat 형식으로 저장
			MakeVHDR_AmH(OUT_NAME);							%헤더정보파일 생성
%			cd ..

			% 사실 위에서 저장한 dat파일은 직접적으로 이용하는 파일들은 아닙니다.
			% 피험자 한 명의 데이터만을 저장한 것이기 때문입니다.
			% 우리는 분석을 위한 경향을 찾으려는 것이므로,
			% 아래의 topo_list에다가 각 피험자들의 데이터를 모두 저장하고,
			% 이를 Grand Average 한 data를 topo로 그려서 경향을 확인할 것입니다.
			% 하지만 개개인의 데이터가 필요한 경우도 있으므로
			% 위에서 저장해 놓은 것 입니다.
			topo_list(subnumb,:,:)	=	potential_topo;

			clear	Potential_Buf buf bufbuf bufbufbuf buf3_idx			...
					freq freq_index potential_topo

%--------------------------------------------------------------------------------
%{
			% EEGLAB-기반 topo drawing을 하기 위한 기초 구성	%-[
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
pop_topoplot(EEG, 1);					%topo 를 drawing 함

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

		% for문을 모두 돌았기 때문에 특정 실험 조건, 주파수 영역에 대한 모든
		% 피험자들의 데이터가 topo_list에 저장되었고, 이를 평균냅니다.
		% 그 전까지의 데이터에서는 17번과 22번 채널의 값을 NaN으로 지정해
		% 주었었지만, 그렇게 할 경우 Analyzer에서는 에러가 나기 때문에
		% 여기서는 0으로 지정해줍니다.
try		%check a 'exception happen that not define the topo_list'
		topo_GrandAverage			=	squeeze(mean(topo_list));
		topo_GrandAverage(:,[17 22])=	0;
catch	exception	%if happen the exception, then skip all subject.
		continue
end		%try - catch

		% 마찬가지로 FrequencyData폴더에 저장.
		% 파일명이 _GrandAverage_로 시작하는 것이 위의 개개인 데이터와 다릅니다.
		% 여기서 export 되는 dat파일을 analyzer에서 불러들여 topo를 그려서 보시면 됩니다.
%		cd FrequencyData
%		fname	=	['SKK_PLV_GrandAverage_' char(ananame{ananumb}) '_' char(freqname{freqnumb})  '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'];
%		save(fname, 'topo_GrandAverage', '-ascii');
		save(GRD_NAME, 'topo_GrandAverage', '-ascii');
		MakeVHDR_AmH(GRD_NAME);								%헤더정보파일 생성
%		cd ..

		clear topo_GrandAverage topo_list

		end		%for freqnum
	end			%for trialname
	end			%for dataname
end				%for ananame

