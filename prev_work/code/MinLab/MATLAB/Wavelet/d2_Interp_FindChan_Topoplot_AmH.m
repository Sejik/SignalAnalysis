%% d2_Interp_FindChan_Topoplot_AmH.m %%
% version: 0.3
% 부가적인 코드
% Analyzer를 이용하지 않고 바로 최대 Peak값을 갖는 토포를 그리기 위한 용도
% 필요에 따라 channel interpolation 도 수행가능.

clear;
close all

%% setting %%
%path(['./EEGLAB_scripts-master:', pathdef]);		%<UserPath>에 있는 pathdef.m 을 실행하여 추가적인 path를 등록
path(pathdef);		%<UserPath>에 있는 pathdef.m 을 실행하여 추가적인 path를 등록

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
	tStep		=	2;								% 샘플링 간격: ms
	tRange		=	-500:2:1500-1;					% 시간 범위
% 구조의 변경이 절실하다. 아래와 같은 grouping 이 필요하다.
% file info group	:
% data set group	: subject 목록, trial 목록(서로 다른 유형의 trial 조합 포함)
% channel group		: 채널 loc 정보, 채널 목록, 안쓰는 채널, 잘못 측정된 채널
% time group		: 시작시간, 종료시간, time-window / 1 trial
% freq group		: 범위(수치), 주파수 이름
% TF group			: 시간주파수 분석 방법, SFFT, wavelet parameter
% statistics group	: 통계 분석 방법

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
%idxLiveCh		=	[1:16, 18:21, 23:32];		% EOG, NULL 배제한 구성
idxLiveCh		=	find( ~ismember(channame, removech));%live채널만:parm순서!
idxRemCh		=	find( ~ismember(removech, channame));%dead채널만:parm순서!
%{
ananame			=	{	'TFe_bl', 'TFi_bl'	};

%20151005A. 시간 범위 설정 기준
%1. max FreqVal: time windows 중 0~500ms 이내에서 최대 amp 가지는 주파수 찾기
%			-> fSmpl=500 <=> SpI(sample interval)=2ms 이며, 전체시간 -500~1500ms
%			-> Thus, tw index = 500/2 ~ 1000/2 = 251 ~ 501
%2. maximum : time windows 중 500~1000ms 이내에서 최대 amp 값 및 채널 찾기
%			-> fSmpl=500 <=> SpI(sample interval)=2ms 이며, 전체시간 -500~1500ms
%			-> Thus, tw index = 1000/2 ~ 1500/2 = 501 ~ 751
lTpWin4Sens		=	{	[251:501],	[251:501]	};
%timelist		=	cell(1,1);
%timelist{1,1}	=	[251:501];    % TFe_bl의 Timewindow. 0ms ~ 500ms
%timelist{2,1}	=	[51:201];     % TFi의 Timewindow. -400ms ~ -100ms
%timelist{3,1}	=	[51:201];     % TFi_bl의 Timewindow. -400ms ~ -100ms
lTpWin4Cogn		=	{	[501:751],	[501:751]	};
					% congnition time window : 500ms ~ 1000ms

%% 알파대역일 때만 TFi (not baseline correction) 에 의한 시각화 진행
if find(ismember(fName, 'alpha'))	% 알파인 경우, pre stimulus 도 처리해야 함
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
%lBadChan			=	{ 'P7', 'P4' };	%전체 data에 대해서 이 채널들 대상으로 interp
%lBadChan			=	{ 'P7' };	%전체 data에 대해서 이 채널들 대상으로 interp
%% cBanChan을 구성한다: 모든 subj에 대해 각각의 bad channel 정보를 구성함 -[
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
					};	% 기본 'P7' interp 해야 하고, 일부는 추가 채널 있음-]
%-]
%}
%subname			=	subname( idxInlier );					% 다시 추림

% reading data structure(from excel) is:
% ...

%{
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% local 머신 범위에서, 병렬연산을 위한 가용 코어 설정
tic;	delete(gcp('nocreate'));

%matlabpool open 4;							% lagacy 방식
%POOL		=	parpool('local');			% 현재 머신의 가용 core로 디폴트 설정
%----------
%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% 신규 profile 작성
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% 최대 48 core 고려.
	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!주의: parent 에서 호출직전에 tic를 수행한다는 가정하에, toc 출력 요청함.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%}

%{
%Topo를 위한 채널 배치 이미지를 구성해 둔다.	%-[
%	어떤 이유에서인지, topo 작성시에 전극 정보를 표기하도록 파라미터를 주면,
%	map image에 덮어쓰지는 듯한 형태로 전극 정보가 지워지는 현상이 일어남.
%따라서, 별도의 전극 정보 이미지를 준비해서, map image 위에 덮어쓰기로 함.
figure;
topoplot([], cedPATH, 'style','blank', 'electrodes','on');	%전극지점만
colorbar;
topo_locs_cdata		=	print('-RGBImage');	close;		% 이미지 데이터 캡쳐
[h, w, c]			=	size(topo_locs_cdata);
topo_locs_cdata(:,w- w/10*2.2:end,:)	=	255;		% 우측22%:colorbar 지움

figure;
topoplot([], cedPATH, 'style','blank', 'electrodes','labels');%전극이름만
colorbar;												%정확한 head위치 때문
topo_labels_cdata	=	print('-RGBImage');	close;		% 이미지 데이터 캡쳐
[h, w, c]			=	size(topo_labels_cdata);
topo_labels_cdata(:,w- w/10*2.2:end,:)	=	255;		% 우측22%:colorbar 지움
clear h w c;
%imwrite(topo_labels_cdata, OUT_JPEG);	%-]
%}
AllTime				=		tic;		%데이터 preparing 시간을 계측한다.
for freqnumb		=	1:length(fName)
	% 현재 분석하려는 주파수 대역을 지정합니다.(alpha, beta, theta 중 하나)
	% 우리가 분석하려는 주파수는 1Hz 부터 0.5단위로 50Hz 까지 이지만,
	% Variable에는 그러한 정보없이 1행, 2행, 3행, ... , 99행까지 저장되 있으므로,
	% 주파수값이 실제 Variable에서는 몇번째 행에 있는지 freqindex에 저장해줍니다.
	% (주파수 데이터는 3차원 데이터이므로 엄밀히 따지면 '행'은 아니지만,
	%	적당히 이해해 주시기 바랍니다.)
%	eval(['freqband	=	' char(fName{freqnumb}) ';']);
	%해석값은 'freqband = theta;' 이므로 위에서 정의한 theta 값이 저장됨
	freqband		=	Freqs{freqnumb};
	freqindex		=	2*freqband-1;
	% ex)	freqband: 1Hz	=	freqindex: 1행 /
	%		freqband: 1.5Hz	=	freqindex: 2행 /
	%		freqband: 2 Hz	=	freqindex: 3행

	%% 알파대역일 때만 TFi (not baseline correction) 에 의한 시각화 진행
	%[251:501];    % TFe_bl의 Timewindow. 0ms ~ 500ms
	%[51:201];     % TFi의 Timewindow. -400ms ~ -100ms
	%[51:201];     % TFi_bl의 Timewindow. -400ms ~ -100ms
%	if find(ismember(fName, 'alpha'))	% 알파인 경우, pre stimulus 처리해야 함
	if fName{freqnumb} == 'alpha'	% 알파인 경우, pre stimulus 처리해야 함
		ananame		=	{	'TFe_bl', 'TFi'		};	% TFi는 bl 하지 말 것
		blERP_TpWin	=	[1:250];	% -500 ~ 0ms, (20151102A. 교수님 지시)
		lTpWin4Sens	=	{	[251:501],	[51:201]	};	%
		lTpWin4Cogn	=	{	[501:751],	[501:751]	};
						% congnition time window : 500ms ~ 1000ms
	else
		ananame		=	{	'TFe_bl', 'TFi_bl'	};
		blERP_TpWin	=	[1:250];	% -500 ~ 0ms, (20151102A. 교수님 지시)
		lTpWin4Sens	=	{	[251:501],	[251:501]	};
		lTpWin4Cogn	=	{	[501:751],	[501:751]	};
						% congnition time window : 500ms ~ 1000ms
	end

for ananumb			=	1:length(ananame)
% ananame, 즉 주파수 데이터 타입에 따라 tpwin4sen를 다르게 지정합니다.
% 아래의 코드를 다른 for문 안으로 이동하고 ananumb를 그 for문에 맞는 숫자(ex: datanumb, trialnumb, freqnumb, ...)
% 등으로 지정하면 주파수 데이터 타입이 아닌 실험 조건이나 주파수 영역에 따라 tpwin4sen를 바꿀 수 있습니다.

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%반드시 분석의 범위를 명시할 것. (예: 주파수 : 알파대역 등)
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
	tWin4SENS		=[tpwin4sen(1)-1:1:tpwin4sen(end)-1]*tStep+tRange(1);	%시간
%	tpwin4cog		=	lTpWin4Cogn{ananumb};
%	tWin4COGN		=[tpwin4cog(1)-1:1:tpwin4cog(end)-1]*tStep+tRange(1);	%시간

	tWend			=	tWin4SENS(end);
	if tWend < 0, 			tWend	=	abs(tWend);		end		% absulte
	if 1000 < tRange(end),	tWend	=	1000;		% 1s
	else					tWend	=	tRange(end);	end
	tWin4ERP		=	0 : tStep : tWend;				clear tWend;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SDthre			=	3;								% SD > 3
	nCond			=	1;								% 각 실험 case

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

		GrdTime		=		tic;		%데이터 preparing 시간을 계측한다.

		xlsMaxData				=	{;};
		xlsMaxData{1,1}			=	'Subject';
		xlsMaxData{1,2}			=	'Max Value';
		xlsMaxData{1,3}			=	'Max Frequency(Hz)';
		xlsMaxData{1,4}			=	'Max Time(ms)';
		xlsMaxData{1,5}			=	'Max Channel';
		xlsMaxData{1,6}			=	'Interp Ch.';

	for subnumb		=	1:length(subname)
		xlsMaxData(subnumb+2,:)	=	{ '' };				% 초기화

		%편의를 위해 파일명을 구성해 둠
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
		%grand average 를 구해야 하므로, individual 중 skip이 있으면 안됨!
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

		SubTime		=		tic;		%데이터 preparing 시간을 계측한다.
		fprintf('Process : %s''s TF to TOPO on Frequency.\n', WORKNAME);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%check & auto skip if not exist a 'dat file.
		%20151030A. 실험시 피험자의 반응에 따라서, 데이터가 발생 불가 가능
		%원인: 실험 조건에 따라 트리거가 없는 경우,
		%	특정 segment 가 발생하지 않을 수 있다.
		%	예: Unfav_like 에서 인지도가 없는 국가의 제품이 마음에 들지
		%		않으면, 반응하지 않을 수 있어서 트리거가 발생하지 않게 됨.
		%처리: 따라서, DAT가 없는 경우에 경고를 하고, 이에 대응하는 조치필요
		%	-> 전체 sub 에서 n 수가 하나 줄어드는 것을 감안한 처리 필요
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

		%% 데이터 로드
%		eval(['DataBuf = importdata(''Phase_' char(ananame{ananumb}) '_' char(fName{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'');']);
		load( SRC_NAME );
		% 지금 분석하려는 data(TFe, TFi, TFi_bl 중 하나)를 Potential_Indi로 지정
		eval(['Potential_Indi= ' char(ananame{ananumb}) '(freqindex,:,:);']);

%		Potential_Indi(:,:,[17 22])	=	0;		%초기부터 제거해야 interp 문제X!
%		Potential_Indi2	=	Potential_Indi;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
		for f = 1 : size(Potential_Indi,1)		%각 주파수별로 ch*t 데이터 통계
			[ Potn2D lGoodChan lBadChan lZvalue ] = AmHlib_FindBad_ChInterp( ...
				squeeze(Potential_Indi(f,:,:)), tpwin4sen, SDthre);	% t x ch

			for b	= 1 : length(lBadChan)	% Bad 채널이 발견: 정보 제공
				fprintf('Ch.Info.: Bad Ch %s(Z=%f) on Freq(%4.1fHz)\n',		...
						channame{lBadChan(b)}, lZvalue(b), freqband(f));
			end	%for

			Potential_Indi2(f,:,:)	=	Potn2D;
		end
%}
		lBadChan		=	[];
		Potential_Indi2	=	Potential_Indi;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dataname x trialname x subname 에 대해 ERP 의 그래프를 그리자.
		%	이때, ERP는 모든 주파수 범위를 다 포함하는 정보를 가지고 있으므로,
		%	상위에 있는 freq, ana 값 마다 반복할 필요가 없다.
		%	따라서, f=1, a=1 일 경우에만 그래프를 그리면 된다.
	if freqnumb == 1 && ananumb == 1
		% ERP_filt_bl 은 0.5 ~ 30 Hz 로 필터링 되어 있음
		% ERP 에도 bad chan 이 가능하겠으나, 일단은 무시하고 전체를 처리하자.
%{
		[ ERP_Interp lGoodChan lBadChan lZvalue ] = AmHlib_FindBad_ChInterp( ...
			ERP_filt_bl, tpwin4sen, SDthre);	% t x ch

		for b	= 1 : length(lBadChan)	% Bad 채널이 발견: 정보 제공
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
		% 지금 분석하려는 데이터 타입(TFe, TFi, TFi_bl 중 하나)를
		% Potential_Indi로 지정.
		% 이 때 관심있는 주파수 영역, tpwin4sen, 채널 목록에 한정합니다.
		Potential_Indi3		=	Potential_Indi2(:, tpwin4sen, idxLiveCh);

		% activation이 최대인 주파수, 즉 Individual Freq 찾아서, FreqVal로 저장.
		% FreqVal는 실제 주파수 값, FreqIdx는 행 값.
		% 그러므로 실제로 코드에서 이용하는 값은 FreqIdx 값입니다.
		[lMaxVal4Ch MaxChan]=	max(Potential_Indi3, [], 3);	%채널중 최대
		[lMaxVal4Tp MaxTmPt]=	max(lMaxVal4Ch, [], 2);		%time중 최대
		[MaxValue   MaxFreq]=	max(lMaxVal4Tp);			%FreqVal중 최대

		MaxTmPt				=	MaxTmPt(MaxFreq);			%단 한개의 time pt
		MaxChan				=	MaxChan(MaxFreq, MaxTmPt);	%단 한개의 채널
		MaxChan				=	idxLiveCh(MaxChan);			%실제 채널 번호

		MaxTpoint			=	MaxTmPt + tpwin4sen(1) -1 ;	%최종 시점: index
		MaxTime				=	MaxTpoint *tStep +tRange(1);	%ms로 변환

		FreqVal				=	freqband(MaxFreq);
		FreqIdx				=	freqindex(MaxFreq);			%특정 주파수 idx
		FreqRel				=	FreqIdx -freqindex(1) +1;	%상대 주파수 idx

		%20151013A. 하지만 max()로는 꼭지점을 구할 수는 없음.
		%	3개의 연속된 점 a,b,c를 취하여 a<b && b<c 인 경우, b가 꼭지점.

		%% 엑셀에 저장할 데이터 구성 ------------------------------
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
		% Individual Frequency의 데이터만 추출하여 Potential_Indi_Freq 에 저장.
%		eval(['Potential_Indi_Freq	=	double(squeeze('					...
%							char(ananame{ananumb}) '(FreqIdx,:,:)));']);
		%% 20151008. Potential_Indi2에 대해 interpolation 했음 -> 여기서 취할 것
		Potential_Indi_Freq	=	double(squeeze(Potential_Indi2(FreqRel,:,:)));
		%Potential_Indi_Freq(timewin, chan)의 2D 구성 <- specific FreqVal confirm

		% matlab에서 사용하는 데이터에서는 17번과 22번 채널의 값을
		% NaN으로 지정해 주었었지만, 이 경우 Analyzer에서는 에러가 나기 때문에
		% 여기서는 0으로 설정.
		% 20150912A. NaN 을 *.dat에 출력시, BrainAnalyzer는 오동작함.
		% -> 그래서, EOG, NULL 채널에도 데이터가 나올뿐만 아니라,
		%		전체 채널의 신호가 ERP가 아닌 매우 이상한 파형으로 요동친다
%		Potential_Indi_Freq(:,[17 22])=	0;

		%% Save Data
		save(OUT_NAME, 'Potential_Indi_Freq', '-ascii');	%dat 형식으로 저장
		MakeVHDR_AmH(OUT_NAME, tStep*1000, channame);		%헤더정보파일 생성

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
%		Potential_TOPO		=	Potential_Indi_Freq(MaxTpoint, :); %특정Tp*AllCh

		%% drawing topo ploting ------------------------------
		fprintf('\nDrawing : for Indivisual topoplot');
		AmHlib_topoplot_alone(	Potential_Indi_Freq,	tRange, tWin4SENS,	...
								FreqVal, MaxTpoint, MaxChan, [OUT_IMAG '.jpg']);
%{
		topo_main_cdata		=	print('-RGBImage');	close;	%메인 topo 캡쳐 -[

		%% image synthesis processing -----------------------
		imshow(topo_main_cdata);
		hold on;
		hCdata				=	imshow(topo_locs_cdata);	% topo에 겹쳐 그리기
		AlphaData			=	topo_locs_cdata < 200;		% 배경(백색)보다 큰것
		set(hCdata, 'AlphaData', AlphaData(:,:,1));			% 배경색 제거
		hold on;
		hCdata				=	imshow(topo_labels_cdata);	% topo에 겹쳐 그리기
		AlphaData			=	topo_labels_cdata < 200;	% 배경(백색)보다 큰것
		set(hCdata, 'AlphaData', AlphaData(:,:,1));			% 배경색 제거 -]
%}

		%% drawing 2D graph for signal T * ch : checking for noise or spike
		AmHlib_2d_overlap(		Potential_Indi_Freq,	tRange, tWin4SENS,	...
								FreqVal, MaxTpoint, MaxChan, [O2D_IMAG '.jpg'])

		%% collecting topo for grand ------------------------------
		% 사실 위에서 저장한 dat파일은 직접적으로 이용하는 파일들은 아닙니다.
		% 피험자 한 명의 데이터만을 저장한 것이기 때문입니다.
		% 우리는 분석을 위한 경향을 찾으려는 것이므로,
		% 아래의 Potential_List에다가 각 피험자들의 데이터를 모두 저장하고,
		% 이를 Grand Average 한 data를 topo로 그려서 경향을 확인할 것입니다.
		% 하지만 개개인의 데이터가 필요한 경우도 있으므로
		% 위에서 저장해 놓은 것 입니다.
		Potential_List(subnumb,:,:)	=	Potential_Indi_Freq;

		toc(SubTime);		%for subject
	end;	% subject

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% calculating & saving grand to jpeg============================================
try		%check a 'exception happen that not define the Potential_List'
		Potential_List;		% 없으면 exception 터짐
catch	exception	%if happen the exception, then skip all subject.
		fprintf('\nGrand of %s has been some error, then SKIP\n', GRDWNAME);
		toc(GrdTime);		%for subject
		continue
end		%try - catch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% 20151020B. 자동으로 outlier를 판독하는 알고리즘 요망
		% 다른 subject에 비해, amp range가 큰 편차 보이는 경우 제외 해야 함.
		%	stats model: normal distribution
		%	threshold: SD>3 일 때
		%	object: channel data of Potential_List(indi, twin, all ch)
		%		따라서, 변수의 전체 주파수 및 t win 범위 내에서 채널들을 비교분석
		% 1. 전체 데이터에 대해서 normal distribution을 계산한다.
		% 2. 즉, 각 주파수 단위로 twin 내에서 모든 채널의 평균, SD 구한 후,
		% 3. Z = (X-u) / (SD/sqrt(n))를 통해, P(Z<-1.96 U 1.96>Z) (95%, p<0.05)인
		%	max를 가지는 채널이 있는지 판정하자.
		% 4. P(Z<-1.96 U 1.96>Z) 이면 되므로, Z<-1.96 이거나 1.96<Z 인 Z면 됨
		%	즉, 채널 max 값이 X 이고, 이를 정규화 한 Z 의 크기를 판독하면 됨
		% 5. 만약 99% 추정을 한다면 P(Z<-2.575 U 2.575<Z) 를 판정하면 된다
		%	-> 90% 는 P(Z<-1.645 U 1.645<Z) 임.
		%	-> 교수님과 상의해 본 결과, 99% 가 맞고, 2.575 이지만, 보통은 3 씀
		% 6. bad ch가 발견되면, 제거한 후 나머지 indi 그룹으로 다시 재판정 시도
		%	-> 더 이상 bad 가 없거든 loop 종료
		% 7. bad ch가 발견되면, 정보를 excel에 표기할 것

			% 엑셀 저장용 array에 각 indivisual의 max 결과가 저장되어 있음
%{
			xlsMaxData{subnumb+2,1}	=	char(subname{subnumb});
			xlsMaxData{subnumb+2,2}	=	MaxValue;
			xlsMaxData{subnumb+2,3}	=	FreqVal;
			xlsMaxData{subnumb+2,4}	=	MaxTime;
			xlsMaxData{subnumb+2,5}	=	channame{MaxChan};
%}
			tic; lMaxVal	=	xlsMaxData(3:end, 2)';		% max arr, row
			lMaxVal			=	str2double(lMaxVal);		% 숫자로 변환
			lOutlier		=	[];
			nTune			=	1;							% calibration카운트
		while true											% bad ch 없을 때까지
			fprintf('\nTuning  : Step(%d) Outlier searching\n', nTune);
			%% outlier 수준 max값 가지는 indivisual 을 찾자 ---------------	%-[

			% 위 정보로 u, SD를 계산하자.
			MN_ch			=	mean(lMaxVal);				% 채널별 max값의 평균
%			SD_ch			=	std(lMaxVal) / sqrt(size(lMaxVal));% SD / sqrt(n)
			SD_ch			=	std(lMaxVal);				% SD / sqrt(n)

			% 정규화 시작
			Z				=	( lMaxVal - MN_ch ) / SD_ch;% Z 도 array
			lOut			=	find( SDthre<abs(Z) );		% SD>3 급 요소만
			lNew			=	lOut(find(~ismember(lOut, lOutlier))); %신규만
			Zout			=	Z(lNew);					% SD>3 급 Z 값만

			if isempty(lNew),	break;	end;				% 신규 out idx 없음

			% 탐지된 신규 outlier 있으므로 조처
%			fprintf('Verify  : Outlier(%s)\n', strjoin({subname{lOut}}, ', '));
			for o = 1 : length(lNew)
				fprintf('Verify  : Outlier %s(Z=%f)\n',subname{lNew(o)},Zout(o));
			end	%for

			lOutlier		=	[ lOutlier lNew ];			% 종전 것과 합침
%			lInlier			=	lInlier( find(~ismember(lInlier,lOutlier)) );
%			lMaxVal			=	lMaxVal( lInlier );			% 정상 최대값 만 %-]

			nTune			=	nTune + 1;
		end	%while
			fprintf('Tuning  : Finish. %d of Outlier(%s). during %d step.\n',...
			length(lOutlier), strjoin({subname{lOutlier}},', '), nTune); toc;

		lInlier				=	1:size(Potential_List,1);
		lInlier				=	lInlier( find(~ismember(lInlier,lOutlier)) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dataname x trialname x subname 에 대해 ERP 의 그래프를 그리자.
		%	이때, ERP는 모든 주파수 범위를 다 포함하는 정보를 가지고 있으므로,
		%	상위에 있는 freq, ana 값 마다 반복할 필요가 없다.
		%	따라서, f=1, a=1 일 경우에만 그래프를 그리면 된다.
	if freqnumb == 1 && ananumb == 1
		% ERP_filt_bl 은 0.5 ~ 30 Hz 로 필터링 되어 있음
		% ERP 에도 outlier 가 가능하겠으나, 일단은 무시하고 전체를 처리하자.

		% ERP에 대해 평균을 구했으므로, 다시 BL 할 것.
		ERP_GA				=	squeeze(mean(ERP_List));	% t * 32
		ERP_GA_bl			=	ERP_GA										...
				- repmat(mean(ERP_GA([blERP_TpWin],:)), [size(ERP_GA,1),1]);

		%% drawing ERP 2D for signal T * ch : checking for noise or spike
		AmHlib_ERP_overlap(ERP_GA_bl, tRange, tWin4ERP, [GERP_IMAG '.jpg']);
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% for문을 모두 돌았기 때문에 특정 실험 조건, 주파수 영역에 대한 모든
		% 피험자들의 데이터가 Potential 변수에 저장되었고, 이를 평균  내야 함.
		% 그 전까지의 데이터에서는 17번과 22번 채널의 값을 NaN으로 지정해
		% 주었었지만, 그렇게 할 경우 Analyzer에서는 에러가 나기 때문에
		% 여기서는 0으로 변경 해야 함!
		Potential_List		=	Potential_List(lInlier, :, :); % 정상만 추림
		Potential_GrdAvg	=	squeeze(mean(Potential_List));% t * 32
%		Potential_GrdAvg(:,[17 22])=	0;
		save(GRD_NAME, 'Potential_GrdAvg', '-ascii');
		MakeVHDR_AmH(GRD_NAME, tStep*1000, channame);		%헤더정보파일 생성

		% activation이 최대인 tp, 즉 GrandAverage Time Point 찾아서 저장.
		[lMaxVal4Ch MaxChan]=	max(Potential_GrdAvg(tpwin4sen,:),[],2);%채널최대
		[MaxValue   MaxTmPt]=	max(lMaxVal4Ch);			%time중 최대
		MaxChan				=	MaxChan(MaxTmPt);			%단 한개의 채널
		MaxTpoint			=	MaxTmPt + tpwin4sen(1) -1 ;	%최종 시점
		MaxTime				=	MaxTpoint *tStep +tRange(1);	%ms로 변환

		%% 엑셀에 저장할 데이터 구성 ------------------------------
		xlsMaxData{2,1}		=	'Grand Average';
		xlsMaxData{2,2}		=	num2str(MaxValue);
		xlsMaxData{2,3}		=	num2str(FreqVal);
		xlsMaxData{2,4}		=	num2str(MaxTime);
		xlsMaxData{2,5}		=	channame{MaxChan};
		if lOutlier, 			% outlier가 존재할 때만,
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
		%(timewin, chan)의 2D 구성 <- specific FreqVal confirm
%		Potential_GA_TOPO(:,[17 22])=	0;

		%% drawing topo ploting ------------------------------
		fprintf('\nDrawing : for Grand Average topoplot');
		AmHlib_topoplot_alone(	Potential_GrdAvg,	tRange, tWin4SENS,		...
						fName{freqnumb}, MaxTpoint, MaxChan, [GRD_IMAG '.jpg']);

		%% drawing 2D graph for signal T * ch : checking for noise or spike
		AmHlib_2d_overlap(		Potential_GrdAvg,	tRange, tWin4SENS,		...
						fName{freqnumb}, MaxTpoint, MaxChan, [G2D_IMAG '.jpg']);

		%% 로그정보의 저장 -> 기본적인 처리 과정을 요약해서 이슈 파악 용이
%{
		%% unix에서는 actxserver를 사용할 수 없어서 직접 excel OLE를 구동하지 -[
		% 못하므로, matlab 내부적으로 switching 하여 dlmwrite를 구동하는데
		% 이 경우에 param의 모든 데이터는 '동일한 type' 이어야 함!
		% 따라서, xlsMaxData 중 2:4 에 저장된 숫자를 문자열로 변환 필요함!
		% 2가지 변환방식이 있음.
		%	-> arrayfun(@num2str, [xlsMaxData{17,2:4}], 'unif', 0)
		%	-> cellfun(@(x)({num2str(x)}),{xlsMaxData{17,2:4}})
 		% 이 함수들은 파라미터가 array 인 경우, iterator처럼 동작함.
 		% 이 중 cellfun을 이용하기로 하자.
		num					=	2:4;
		sh					=	shiftdim(xlsMaxData, 1);	% sub*data->d*sub
		sh(num,2:end)		=	reshape(cellfun(@(x)({num2str(x)}),			...
											{sh{num,2:end}}), length(num), []);
		xlsMaxData			=	shiftdim(sh, 1);	%-]

%		xlswrite('d2_evk_tot.xls', xlsMaxData, GRDWNAME);	%특정 시트에 저장
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
	% 작성방법: 하나의 tab에 아래의 실험 condition을 모두 기재함.
% 예: Fav_Like Fav_Dislike Neutral_Like Neutral_Dislike Unfav_Like Unfav_Dislike
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
%	xlsAllMax{2:end,2}{:,1}	=	[];							%1번째 sub이름만 남김
	for n = 2 : size(xlsAllMax,1)
		xlsMaxData			=	xlsAllMax{n, 2};
		xlsMaxData(:,1)		=	[];							%1번째 sub이름만 남김
		xlsAllMax{n, 2}		=	xlsMaxData;
	end;

	% 라인 단위로 출력해야 하므로, 하나의 라인에 나올 모든 항목을 나열해서 구성
	for n = 1 : size(xlsAllMax,1)				%문자열 중간에 있는 국가명만 제거
		% cond 이름에서 국가명은 제거한다.
%		xlsAllMax{n, 1}	=	regexprep(xlsAllMax{n, 1}, '_[^_]+_([^_]+)$', '_$1');
		% 그리고 출력한다. line 단위
		fprintf(XLS, '%s', xlsAllMax{n, 1});				% condition 표시
		fprintf(XLS, repmat(sprintf('\t'), 1, size(xlsAllMax{n,2},2)) ); %공백
	end
		fprintf(XLS, '\n');

	% 이제 subject 단위로 라인 구성
	%20151030A. 실험시 피험자의 반응에 따라서, 데이터가 발생 불가 가능
	%원인: 실험 조건에 따라 트리거가 없는 경우
	%해법: 
	for s = 1 : size(xlsAllMax{n, 2},1)
		for n = 1 : size(xlsAllMax,1)			%문자열 중간에 있는 국가명만 제거
			xlsMaxData		=	xlsAllMax{n, 2};
			fprintf(XLS, '%s\t', strjoin(xlsMaxData(s,:), '\t'));
		end
		fprintf(XLS, '\n');
	end
	fclose(XLS);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% writing VBA for powerpoint:
	% 1. ERP 먼저
if freqnumb == 1 && ananumb == 1	% 맨 처음에만 작성
	AmHlib_OleAutomation_PPT_GenVBAcode( SubPATH,							...
				'GenPPTslide_ERP', 'AllBand', '', '', 'ERP_Grd', 'ERP_Indi');
				% 파일명: ERP_Grd_AllBand_Fav_like
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
