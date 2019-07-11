% please load eEEG for each experiment and condition:
clear;clc;

%% setting %%
path(pathdef);		%<UserPath>에 있는 pathdef.m 을 실행하여 추가적인 path를 등록

%% Header %%
global	DAT_NAME;
global	NUMWORKERS;
global	WORKNAME;
global	TF;					%Time&Freq axis data = freq x time array

%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki	]	=	A_globals_AmH();

%data=[length(dataname)*length(trialname):3];  %[datanumb * trialnumb] * [f, t_start, t_fin]
%Freqs		=[	4:1/2:8		];		% 세타파를 잡는 다. step 0.5
%m	=7; ki	=	 5;					% wavelet 분석을 위한 default 값
%CUATION!: epoch size mismatch for TF_USA_dislike_su20.mat(377 epoch)
%	so, tf2coh_min2_AmH_mex() do not cover this. because loop val is constant.
%CUATION!: file is damaged for
%	TF_Unfav_Paki_dislike_su19.mat
%	Neutral_Mexico_dislike_su25.mat

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% local 머신 범위에서, 병렬연산을 위한 가용 코어 설정
tic; delete(gcp('nocreate'));

%matlabpool open 4;							% lagacy 방식
%POOL		=	parpool('local');			% 현재 머신의 가용 core로 디폴트 설정
%----------
%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% 신규 profile 작성
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% 최대 48 core 고려.

	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	%20150709B. WOW 호출시 내부에서 자동으로 parpool 호출되는 이슈
	%현상: WorkerObjWrapper()호출시 parpool 이 open되어 있지 않으면 내부에서 자동
	%		으로 호출하는 동작 발견됨. 이 경우 문제는 handle(POOL)을 얻을 수
	%		없고, 또한 최대 CPU수(예: 20)가 아닌, 가용가능한 CPU만큼(예: 12)
	%		정도가 할당될 뿐이어서 성능이슈도 함께 유발됨.
	%해법: 사전에 parpool로 open 시켜주면 WOW 내부 구동 없음
%	TFwow				=	WorkerObjWrapper(TF);	%내부 init에서 pool 생성!
	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!주의: parent 에서 호출직전에 tic를 수행한다는 가정하에, toc 출력 요청함.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%%-------------------------------------------------------------------------------
% Analysis PLV using TF data
% -------------------------------------------------------------------------------
%data=load('inputusa1.txt');
%a=1;
for datanumb			=	1:length(dataname)
	for trialnumb		=	1:length(trialname)
		for subnumb		=	1:length(subname)
			%			cd skk_tf;
			%편의를 위해 파일명을 구성해 둠
			WORKNAME	=[	char(subname{subnumb})		'_'					...
							Regulation					'_'					...
							char(dataname{datanumb})	'_'					...
							char(trialname{trialnumb})	];
%			WORKNAME	=[	char(dataname{datanumb})	'_'	...
%							char(trialname{trialnumb})	'_'	...
%							char(subname{subnumb})		];
			DAT_NAME	=[	fullPATH '/skk_dat/' 'skk_' WORKNAME '.dat'	];
			OUT_NAME	=[ fullPATH '/skk_PLV_' fName '/Phase_' WORKNAME '.mat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%check result file & skip analysis if aleady exists.
			fprintf('\nChecking: Analyzed result file: ''%s''... ', OUT_NAME);
			if exist(OUT_NAME, 'file') > 0					%exist !!
				fprintf('exist! & SKIP analyzing this\n');
				continue;									%skip
			else
				fprintf('NOT & Continue the Analyzing\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			tic;					%데이터 preparing 시간을 계측한다.
			fprintf('Convert : %s''s DAT to TF data on WORKSPACE.\n',WORKNAME);
			%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.

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

%%-------------------------------------------------------------------------------
% Convert: DAT -> eEEG...mat
% -------------------------------------------------------------------------------
			[nChan,lChan,SDP,fSmpl]=load_ExpInfo_AmH([fullPATH '/skk_dat/skk_']);
			% nChan : 채널 갯수
			% lChan : 채널 목록

			%% Subjects_All Epochs_bl
%			cd skk_dat;
%			eval(['DataBuf = importdata(''' fullPATH '/skk_dat/skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '.dat'');']);
%			eval(['DataBuf	=	importdata(''' fullPATH		...
%									'/skk_dat/skk_' DAT_NAME '.dat'');']);
			eval(['DataBuf	=	importdata(''' DAT_NAME ''');']);
			%*.dat 파일의 첫 줄에 저장된 채널 순서를 확인해 보아야 함!

%			cd ..;
%			B			=	DataBuf.data;
%			B			=	shiftdim(B, 1);
%			eEEG		=	reshape(B, 1000, [], 32);
%			eEEG		=	reshape(DataBuf.data, 1000, [], 32);
			eEEG		=	reshape(DataBuf.data, SDP, [], nChan);
			% eEEG(timepoint * epochs * ch)

%			clear B DataBuf
			clear DataBuf

			eEEG(:,:,17)=	NaN;	% EOG
			eEEG(:,:,22)=	NaN;	% NULL

%			eval(['FILENAME=''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) ''';']);
%			eval(['FILENAME	=	''/skk_data/skk_' DAT_NAME ''';']);	%기본:*.mat
%			cd skk_mat;
%			save(FILENAME, 'eEEG');	% eEEG 어레이를 저장함.
%			cd ..
%%			save([fullPATH '/skk_data/skk_' DAT_NAME], 'eEEG');	% eEEG array 저장
%%			clear eEEG

%%-------------------------------------------------------------------------------
% Convert: eEEG...mat -> partitioning	%-[
% -------------------------------------------------------------------------------
%			cd skk_mat;
%			eval(['load(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb})  '.mat'');']);
%			cd ..;

%+			eEEG1= eEEG(:,:,1:16);	% EOG 이후 제거한 eEEG array 구성: 전반부
%+			eEEG2= eEEG(:,:,17:32);	% EOG 이후 추출한 eEEG array 구성: 후반부
%+
%+			cd skk_eEEG;
%+			eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ''';']);
%+			save(FILENAME, 'eEEG');
%+
%+
%+			eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_1'';']);
%+			save(FILENAME, 'eEEG1');
%+
%+
%+			eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_2'';']);
%+			save(FILENAME, 'eEEG2');
%+			cd ..;
%+			clear eEEG eEEG1 eEEG2	%-]

%%-------------------------------------------------------------------------------
% Convert: eEEG...mat -> TF
% -------------------------------------------------------------------------------
%fsamp		=	 500;				% sampling point를 잡음
%m	=7; ki	=	 5;					% wavelet 분석을 위한 default 값
%			cd skk_eEEG;
%			eval(['eEEG = importdata(''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
%			cd ..;

%+			% ERP 분석	%-[
%+			chs			=	 [1:32];			% 채널
%+			blEEG		=	eEEG;	%시간축 분석 ERP, freq 분석 알파 베타 같은 것
%+			bl			=	zeros(size(eEEG,2),'single');%=timepoint * epoch * ch
%+			% baseline을 만드는 것: 자극 전까지의 값들을 평균 내어서 baseline을
%+			% 맞춰줌. correction을 한다. common reference 같은 방법이 있음.
%+			% 매 순간 모든 채널을 맞춰주는 것이 baseline.
%+			% 알파파 분석 할 때에는 자극 전에도 baseline을 맞추지 않는다.
%+			% 뇌파 ERP 할 때에는 0.5-1.5 주파수 분석을 할 때에는
%+			% -0.5 (스미어링 등의 이유로) 사이를 잡아주는 것이 필요
%+			% 일정 시간 이전에 잡는 것. 시간, 에폰 , 채널, (나중에 주파수)
%+%			bl			=	single(bl); % single: 무언가 data 가공 or 빠르게??
%+
%+			ERP			=	zeros(size(eEEG,1),length(chs));
%+			% 와꾸? matlab에서 계산 하기위해선 dimension을 만들어주는 것.
%+			% 틀 만들어 주는 것
%+			% ERP 변수는 timepoint 와 channel 두가지로 표현됨.
%+			% 에폭을 평균 내어서 2차원으로 줄어들은 것
%+			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%+			% ERP 구하는 것
%+			for ii		=	1:length(chs);
%+				ch					=	chs(ii);
%+				bl(1,:)				=	squeeze(mean(eEEG([1:250],:,ch),1));
%+				%자극제시 전 -500~0ms 로 baseline 을 설정함.
%+
%+				%설정한 baseline 으로 각 채널별로 빼주어 correction 함.
%+				for yy	=	1:size(bl),
%+					blEEG(:,yy,ch)	=	squeeze(eEEG(:,yy,ch))-bl(1,yy);
%+					%여기서 baseline correction을 해줌.
%+					%squeeze는 차원의 개념이 줄어드는 single ton
%+				end;
%+
%+				ERP(:,ch)			=	squeeze(mean(blEEG(:,:,ch),2));
%+				%시간과 채널만 남음 (ERP 구함)
%+			end;	%-]

			%%%%%%%%%%% Time-Frequency Analysis : Total activity = TFi
			% frequency를 앞 쪽에 붙여줌
			% shift demension을 사용해서 순서를 바꿀 수 있다.
%+			TF_origin	=	epoch2tf_min(eEEG,Freqs,fsamp,m,ki);
%+			TF_origin	=	epoch2tf_min_AmH(eEEG,Freqs,fsamp,m,ki);
			%TF를 만듬 (total activity)
%+			tic; TF		=	single(TF_origin);	% 4D array : f,t,e,c
%			tic; TF		=	single( epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki) );
			tic; TF		=	epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki);
			TF			=	single(TF);			%TF_power까지 single 처리 필요x

%+			%%%%%%%%%%% Time-Frequency Analysis : Evoked activity = TFe_bl %-[
%+			[TFi,TFP,TFA]=	tf2tfi_min(TF);		% iPA를 만들어 주는 것
%+										% induce로 total activity 구할 수 있다.
%+
%+			% evoked tf (without baseline_correction)
%+			TFe			=	zeros([length(Freqs) size(ERP)]);
%+			% 시간 주파수 분석에서는 evoked와 induced를 중요하게 분석한다.
%+			for ch		=	1:size(ERP,2),
%+				[tf1,tfa1,tfc1]	=	tfmorlet_min(ERP(:,ch),fSmpl,Freqs,m,ki);
%+				%Evoked activity 구하기 위해 각 채널 별 morlet wavelet 분석 실시.
%+
%+				TFe(:,:,ch)		=	tf1;
%+			end; %wavelet도 baseline correction필요. edge는 안쓰고 비껴서 쓰는 것
%+
%+			% evoked tf (with baseline_correction)
%+			TF_bl		=	squeeze(mean(TFe(:,51:200,:),2));
%+			% wavelet 분석 후 -400~100ms 구간의 baseline으로 다시 correction 함.
%+			TFe_bl		=	TFe;
%+			fn			=	length(Freqs);
%+			chn			=	size(TFe,3);
%+			for i		=	1:chn,
%+				for f	=	1:fn,
%+					TFe_bl(f,:,i)	=	TFe(f,:,i)-TF_bl(f,i);
%+				end;
%+			end;
%+
%+			cd skk_tf;
%+			FILENAME = [fullPATH '/skk_tf/TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_x' ]; 
%+			save(FILENAME, 'TF_origin', 'ERP', 'TFi', 'TFe_bl', '-v7.3');	%v7.3옵션이 없으면 TF_origin 이 2G 크기 이상일 때 저장 실패함.
%+			cd ..;
%+			clear TF_origin ERP TFi TFP TFA TFe_bl;
%+%			clearvars -except dataname datanumb trialname trialnumb subname subnumb chs
%+%			clc		%-]
			toc;							%작업 종료시간 출력
%%-------------------------------------------------------------------------------
% Convert: eEEG...mat -> TF
% -------------------------------------------------------------------------------
%+			fprintf('Loading : %s''s TF data to WORKSPACE. ',	WORKNAME);	%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.
%			eval(['load(''TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
%			eval(['load(''TF_' WORKPATH '.mat'');']);
%+			eval(['load(''' fullPATH '/skk_tf/' 'TF_' WORKNAME '.mat'',''TF_origin'',''-mat'');']);

%			cd ..;
%+			TF			=	TF_origin;
%+			clear TF_origin;				% TF_origin은 이제 필요없으니 삭제
%			TF(:,:,:,length(channame)+1:size(TF,4))=	[];	%20150516A. 실험 위해, 최소 채널만 남김
%+			toc;							%작업 종료시간 출력

%% 20150517B. TF 데이터에 대한 기본적인 처리/점검 기능이 필요함.	%-[
			%단, 32개 채널 전체를 수행했을 경우에는, 더미채널을 제거해야 한다.
			% ch17= EOG, ch22=NULL, 없는 부분을 날림. 뒤에서 부터 날려야 제대로 처리됨. ->
			% 20150517C. 이젠 이 제약은 없어졌음. 앞에서부터 순서대로 제거 가능
			tic; fprintf('\nFinding : & remove a dummy channels on TF array. ');
			selchanname	=	channame;
			for f=1:length(removech)		%제거할 채널을 대상으로 검색
				ch1		=	find(strcmp(selchanname, removech(f)), 1);	%더미채널의 인덱스 찾기
				if ~isempty(ch1) && size(TF,4)==length(selchanname),
					TF(:,:,:,ch1)	=	[];	%EOG와 타채널 간의 관계도 조사해 보자
					selchanname(ch1)=	[];	%해당 채널도 제거
				end							%따라서, TF와 chan 간 index 동일 유지
			end
			toc;							%작업 종료시간 출력	%-]

			%TF 데이터 중 NaN 인 것이 있으면, 해당 값을 가진 채널과의 비교에서
			%매번 엉뚱한 값을 생성하여, 종전 분석과의 불일치를 유발함.
			%따라서, 이 값을 가진 채널이 있다면, Notify 해야 함!!
			%TF 규모가 광범위 해서 , 시간이 소요 될 수 있다. 
			tic; fprintf('Search  : a NaN value on TF array\n');
			flagNaN		=	0;
%			for f=1:size(TF,1)	for t=1:size(TF,2)	for epoch=1:size(TF,3)	for ch=1:size(TF,4)
			for f=1:size(TF,1)	for ch=1:size(TF,4)
				if any(any(any(any(isnan(TF(f,:,:,ch)))))),	%4D 이므로 any*4 해야 스칼라 값 됨
					flagNaN	=	1;
%					fprintf('Notify: TF havs a undefined values at [FreqIdx(%d), TimeZone(%d), Epoch(%d), Ch(%d)]\n', f, t, epoch, ch);
					fprintf(['Notify: TF has a undefined values at ' ...
							'[FreqIdx(%d), Ch(%d)]\n'], f, ch);
				end
			end
			end
			if flagNaN,		%NaN 값 발견!
				fprintf('Press CTRL+C to stop or AnyKey to continue\n');
				pause;
			end
			fprintf('Search  : completed. ');	toc;		%작업 종료시간 출력

%%-------------------------------------------------------------------------------
%% 분석 개시: parallel call to tf2coh_min by SPMD
% -------------------------------------------------------------------------------
%			TFwow			=	WorkerObjWrapper(TF);		%워커용 wrapper
			tic; [PLV, PLS]	=	MinMinMin_phase6A_AmH(Freqs);
%			tic; [PLV, PLS]	=	MinMinMin_phase8_AmH(TF, Freqs);
%			tic; [PLV, PLS]	=	MinMinMin_phase8_AmH(Freqs);
%			cd skk_phase;
			fprintf('Analysis: completed. ');	toc;		%작업 종료 시간 출력

			fprintf('Storing : PLV & PLS data@COH(Phase) to %s\n\n', OUT_NAME);
%			FILENAME = ['Phase_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb})]; 
%			FILENAME = ['Phase_' WORKPATH ]; 
%			save(FILENAME,'-v7.3')
%			cd ..;
%			cd 'x:\SKK_theta_anterior_only\skk_coh';			%coh데이터를 저장할 랩_백업_서버 상의 path
			%전체 데이터 말고, PLV, PLS 만 저장
%			save([fullPATH '/skk_phase30/' 'Phase_' WORKNAME '.mat'], ...
%				'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
			save(OUT_NAME, 'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
		end
	end
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%	clear	TFwow;
%%matlabpool close;
delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

quit

