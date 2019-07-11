%% wavelet_EXP.m %%
% Wavelet 코드. 실험에 따라 Header부분이 달라지므로, wavelet 코드를 각 실험별로 하나씩 만들어 두시는 게
% 좋습니다.
% 이 코드를 실행시키기 위해선 아래의 다른 m코드 들이 반드시 같은 폴더에 있어야 합니다.
%
% epoch2erp_min.m, epoch2tf_min.m, tf2tfi_min.m, tfmorlet_min.m,
% wmorlet_min.m, readKRISSMEG_sev.m, spss_min.m
%
% Wavelet을 돌리는 데이터는 Average 데이터가 아닌 전체 epoch이 있는 데이터이므로 이 코드에서는 전체 epoch
% 데이터만을 다룹니다.

%% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
clear;
close all;

%% setting %%
path(localpathdef);	%<UserPath>에 있는 localpathdef.m 실행, 추가적인 path를 등록

%% Header %%
global	DAT_NAME;
global	NUMWORKERS;
global	WORKNAME;
% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% channame: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% dataname, trialname: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% subname: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki	]	=	A_globals_AmH();
	Freqs					={	1:1/2:50	};		% 전 대역을 잡는다: step 0.5
	%Freqs, fName이 cell array 일 경우: float vector로 변경 필요
	if iscell(Freqs)
		Freqs				=	Freqs{1};					% 1st 데이터만 취함
		fName				=	fName{1};
	end
	if ~isfloat(Freqs)
		error('"Freqs" is not float data or vector\n');
	end

MinEpoch					=	20;					% 처리가능 최소 epoch 하한선

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%반드시 분석의 범위를 명시할 것. (예: 주파수 : 알파대역 등)
fprintf(['@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n'															...
'The processing parameters has:\n'											...
'\tFrequency: %4.2f ~ %4.2f ; step(%4.2f)\n'								...
'\tChannel  : total n(%d) ; REAL n(%d)\n'									...
'\tSubject  : n(%d)\n'														...
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n']																	...
,	Freqs(1), Freqs(end), (Freqs(end)-Freqs(1))/(length(Freqs)-1),			...
	length(channame), length(channame)-length(removech),					...
	length(subname)	);
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

Total		=	tic;		%전체 연산 시간
for datanumb=1:length(dataname)
	for trialnumb=1:length(trialname)
		for subnumb=1:length(subname)

% Wavelet의 Header에 추가된 부분으로, 메모리 문제로 16채널씩 나눈 데이터로
%	wavelet을 돌리기 때문에 추가된 부분입니다.
%	만약 잘라진 데이터의 채널 수를 바꾸었다면 이 부분을 바꾸어 주면 됩니다.
			%편의를 위해 파일명을 구성해 둠
			WORKNAME	=[	char(subname{subnumb})		'_'					...
							Regulation					'_'					...
							char(dataname{datanumb})	''					...
							char(trialname{trialnumb})	];
			WORKDEST	=[	char(subname{subnumb})		'_'					...
							char(dataname{datanumb})	''					...
							char(trialname{trialnumb})	];
			DAT_NAME	=[	fullPATH '_dat/' 'skk_' WORKNAME '.dat'	];
			OUT_NAME	=[	fullPATH '_tf/' 'ERP_Evk_Tot_' WORKDEST '.mat' ];

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

			AllTime		=	tic;		%데이터 preparing 시간을 계측한다.
			fprintf('--------------------------------------------------\n');
			fprintf('Convert : %s''s DAT to TF data on WORKSPACE.\n', WORKNAME);
			%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.

%%-------------------------------------------------------------------------------
% Convert: DAT -> eEEG...mat
% -------------------------------------------------------------------------------
			%check & auto skip if not exist a 'dat file.
			%20151030A. 실험시 피험자의 반응에 따라서, 데이터가 발생 불가 가능
			%원인: 실험 조건에 따라 트리거가 없는 경우,
			%	특정 segment 가 발생하지 않을 수 있다.
			%	예: Unfav_like 에서 인지도가 없는 국가의 제품이 마음에 들지
			%		않으면, 반응하지 않을 수 있어서 트리거가 발생하지 않게 됨.
			%처리: 따라서, DAT가 없는 경우에 경고를 하고, 이에 대응하는 조치필요
			%	-> 전체 sub 에서 n 수가 하나 줄어드는 것을 감안한 처리 필요
			fprintf('Checking: Source DAT file: ''%s''... ', DAT_NAME);
			if exist(DAT_NAME, 'file') <= 0					%skip
				fprintf('not! & SKIP converting this\n');
				fprintf(['WANRNING: %s is not found. It maybe be correct..\n' ...
				'\tBut recommanded to double checking. please.\n'], DAT_NAME);
				continue;									%exist !!
			else
				fprintf('EXIST & Continue the converting\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%% 20151120A. 헤더 정보는 src file 체크 후 읽는 것이 옳음!!
			[lChan,SDP,fSmpl]	=	load_ExpInfo_AmH(DAT_NAME);
			MxChn		=	length(lChan);			% MxChn : 채널 갯수
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			%% Subjects_All Epochs_bl
%			cd skk_dat;
%			eval(['BAdat = importdata(''' fullPATH '/skk_dat/skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '.dat'');']);
%			eval(['BAdat	=	importdata(''' fullPATH		...
%									'/skk_dat/skk_' DAT_NAME '.dat'');']);
			eval(['BAdat	=	importdata(''' DAT_NAME ''');']);
%			cd ..;
			if isstruct(BAdat)							%dat파일 첫줄:ch정보
%				B		=	BAdat.data;
%				B		=	shiftdim(B, 1);
%				eEEGa	=	reshape(B, 1000, [], 32);
%				eEEGa	=	reshape(BAdat.data, 1000, [], 32);
				fprintf('Detected: [struct] type for .DAT\n');
				BAdat	=	BAdat.data;
			elseif isnumeric(BAdat)						%첫줄에 ch 정보 X
				fprintf('Detected: [numeric] type for .DAT\n');
				BAdat	=	BAdat;
			else
				fprintf('Warning : unkown the .DAT type\n');
				BAdat	=	double(BAdat);
			end

%			eEEGa		=	reshape(BAdat, SDP, [], MxChn); % t * ep * ch
			if		size(BAdat,2) == MxChn
				fprintf('Detected: MULTIPLEXED orientation for .DAT\n');
				eEEGa	=	reshape(BAdat, SDP, [], MxChn);	%% time * ep * ch

			elseif	size(BAdat,1) == MxChn
				fprintf('Detected: VECTORIZED orientation for .DAT\n');
				eEEGa	=	reshape(BAdat, MxChn, SDP, []);	%% ch * time * ep
				eEEGa	=	shiftdim(eEEGa, 1);				% tm x ep x ch
			end
			% eEEGa(timepoint * epochs * ch)
%			clear B BAdat
			clear BAdat

%%-------------------------------------------------------------------------------
			if size(eEEGa,2) < MinEpoch,	continue;	end	 % trial 수 부족하면
%			eEEGa(:,:,17)=	NaN;	% EOG
%			eEEGa(:,:,22)=	NaN;	% NULL
%%			eEEGa(:,:,[17 22])	=	0;	% EOG, NULL

%			liveChIdx	=	find( ~ismember(channame, removech) );	% live만
			liveChIdx	=	find( ismember(lChan, channame) );	% live만
			if MxChn > length(liveChIdx)					% 채널 수 안 맞음
%				channame=	channame( [ liveChIdx ] );		% 살아있는 채널만
				lChan	=	channame;						% 살아있는 채널만
				eEEGa	=	eEEGa(:,:, [ liveChIdx ]);		% live 채널만 추출
				MxChn	=	size(eEEGa,3);					% 채널수도 조정
			end
%%-------------------------------------------------------------------------------

%			eval(['load eEEG_' char(trialname{trialnumb}) '_'			...
%				char(dataname{datanumb}) '_' char(subname{subnumb}) '.mat']);
%			eEEGa= eEEG1;
%			clear eEEG1;

			% Butterworth Filtering 부분. 일반적으로 수정하실 부분은 없으나
			% fSmpl가 Sampling Rate이므로 우리 기기로 측정한 데이터가 아닌 MEG 데이터 등의 경우
			% Sampling Rate가 달라지므로 수정해줘야 합니다.
			% SKK 실험 데이터 sampling rate : 500Khz
%			fSmpl		=	500;
			[bbb, aaa]	=	butter(1, [0.5 30]/(fSmpl/2),'bandpass');

%%%아래 부분은 원래 comment 처리 되어 있던 부분.. 그냥 지나치셔도 될 듯 합니다%%%
			% baseline correction
			% for x=1:40,
			% channame(1,x)=cellstr(EEG.chanlocs(1,x).labels);
			% end;
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			% 1~50Hz 의 범위를 0.5Hz 단위로 분석할 것이므로 이를 지정해 줍니다.
%			Freqs		=	[1:1/2:50];

			% 수정할 부분없음.
%			m			=	7;	ki	=	5;

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
			CPB			=	1;	%ch per blk(parallel size)
								%전체채널의 분할처리 크기:기본 1개 블럭(all 처리)
			lERP		=	cell(1, CPB);	%ERP_filt_bl
			lTFe		=	cell(1, CPB);	%TFe_bl ; 자극전 , _bl(Baseline corr)
			lTFi		=	cell(1, CPB);	%TFi	; 자극후
			lTFib		=	cell(1, CPB);	%TFi_bl	; 자극후

while true
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%			lChns		={	[1:16], [17:32]	};	%채널 분할
			lChns		=	cell(1, CPB);		%한번에 수행할 채널 list 구성
			for CH = 1 : CPB,	lChns{CH}=[MxChn/CPB*(CH-1)+1:MxChn/CPB*CH]; end
%--------------------------------------------------------------------------------
			for CH = 1 : CPB %mem제약(64G로도 모자람)으로 채널 분할
fprintf('\nParts   : (%d/%d) of eEEG data Let''s GO!\n', CH, CPB);

			chs			=	cell2mat( lChns(CH) );

			% 1~16번 채널 데이터는 eEEG1으로, 17~32번 채널 데이터는 eEEG2로 저장.
%			eEEG1		=	eEEG(:,:,1:16);
%			eEEG2		=	eEEG(:,:,17:32);
%			eEEG		=	eEEGa(:,:,chs);
			eEEG		=	eEEGa(:,:, MxChn/CPB*(CH-1)+1:MxChn/CPB*CH);
%			eEEG		=	eEEGa(:,:, 1:MxChn/CPB);	%blk 처음 것
%			eEEGa		=	eEEGa(:,:, MxChn/CPB+1:end);%나머지를 shift
			%메모리 소모를 최소화 하기 위해, eEEGa 데이터를 copy 대신 move 시킴

			%%% header
			% Baseline Correction 의 Timewindow를 지정하는 부분.
			% 이 부분은 확인하셔야 됩니다.
			% ERP는 주로 -500 ~ -100ms,
			% Frequency분석은 주로 -400 ~ -100ms 로 지정합니다.
%			ERP_blTimWin=[1:200];	% -500 ~ -100ms, (fSmpl==500, thus 2ms 간격)
			ERP_blTimWin=[1:250];	% -500 ~ 0ms, (20151102A. 교수님 지시)
			TF_blTimWin	=[51:200];  % -400 ~ -100ms

			% 이후 저장할 때 까지 수정하실 부분 없습니다.
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ERP analysis
tic;	fprintf('Engagement: ERP Analysis');
%{
			% bl=zeros(size(id'));bl=single(bl);	%-[
			blEEG		=	eEEG;
			ERP			=	zeros(size(eEEG,1), size(chs,2));
			ERP_filt	=	ERP;
			ERP_filt_bl	=	ERP;

%			for ii		=	1:length(chs)
			for ch		=	1:length(chs)	%chs()엔 채널번호, eEEG는 1부터 시작
%				ch		=	chs(ii);		%따라서, chs(1)==17==eEEG(1)

%				bl(1,:)	=	squeeze(mean(eEEG([ERP_blTimWin],:,ch),1));
%???????????????????????????????????????????????????????????????????????????????
%				for yy	=	1:size(bl),
%20150806A. yy==1 만 loop 후 종료 결함 탐지!!!
%현상: 위 코드를 보면:
%		size(bl) == [1 epoch] 이므로
%		번역된 코드: for yy = 1:1, 을 수행하게 됨!!
%여파: 이후 loop에서 ERP 계산에 오류값 반영됨.
%		다음 단계에서 evoked, total power의 계산에 ERP 오류값이 반영됨.
%		결국 전체 wavelet 분석 결과가 오류화!!
%해법: size(bl,2)로 명시하면 됨.
%???????????????????????????????????????????????????????????????????????????????
%				for yy	=	1:size(bl,2),	%epoch iter 위해서 정확 크기 참조!
%					blEEG(:,yy,ch)	=	squeeze(eEEG(:,yy,ch)) - bl(1,yy);
%				end;
				bl=repmat(mean(eEEG([ERP_blTimWin],:,ch),1),[size(eEEG,1),1,1]);
				blEEG(:,:,ch)	=	eEEG(:,:,ch) - bl(:,:,1);	%matrix로 가속화

				ERP(:,ch)		= squeeze(mean(blEEG(:,:,ch),2)); %t*ep -> t * ch
				ERP_filt(:,ch)	=	filtfilt(bbb,aaa,ERP(:,ch));
				ERP_filt_bl(:,ch)=	ERP_filt(:,ch)						...
										-mean(ERP_filt([ERP_blTimWin],ch));
			end;	toc;	%-]
%}
%			bl	=	repmat(mean(eEEG([ERP_blTimWin],:,:)), [size(eEEG,1),1,1]);
%			blEEG		=	eEEG - bl;						%matrix로 가속화
			blEEG=eEEG-repmat(mean(eEEG([ERP_blTimWin],:,:)),[size(eEEG,1),1,1]);

			ERP			=	squeeze(mean(blEEG(:,:,:), 2));	%t*ep -> t * ch
%[bbb, aaa]	=	butter(1, [0.5 30]/(fSmpl/2),'bandpass');
			ERP_filt	=	filtfilt(bbb, aaa, ERP);
			ERP_filt_bl	=	ERP_filt										...
				- repmat(mean(ERP_filt([ERP_blTimWin],:)),[size(ERP_filt,1),1]);
			toc;

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Time-Frequency Analysis
tic;	fprintf('Engagement: Time-Frequency Analysis');
			% evoked tf (without baseline_correction)
			TFe			=	zeros([length(Freqs) size(ERP)]);	%f x t x ch
			for ch		=	1:size(ERP,2),						%loop the all-ch
%				[tf1,tfa1,tfc1]		=	tfmorlet_min(ERP(:,ch),fSmpl,Freqs,m,ki);
				tf1			=	tfmorlet_min_AmH(ERP(:,ch),fSmpl,Freqs,m,ki);
				TFe(:,:,ch)	=	tf1;							%power만 추출
%				fnout=['su' num2str2(su) '_cond' num2str(cond) '_trg' num2str(n) '_' channame{1,ch} '.mat'];
%				save(fnout,'TFe');
			end;	toc;

			%%%%%%%%
			%%%%%%%%
tic;	fprintf('Engagement: Evoked TF with Baseline correction');
			% evoked tf (with baseline_correction)
%			TFes_bl		=	squeeze(mean(TFe(:,TF_blTimWin,:),2));	% -> f * ch
%			TFe_bl		=	TFe;								% f * t * ep
%			for ii		=	1:size(TFe,3),						% all ch
%				for f	=	1:length(Freqs),
%					TFe_bl(f,:,ii)	=	TFe(f,:,ii)-TFes_bl(f,ii);	%shift
%				end;
%			end;	toc;
%tic;	fprintf('Comparison: Evoked TF with Baseline correction');
			%% 테스트 결과, 위 for / for 방식은 10.3608초 걸리고,
			%% 아래 matrix 연산은 0.08723초 걸림: 118배 차이
			TFes_bl = repmat(mean(TFe(:,TF_blTimWin,:),2), [1,size(TFe,2),1]);
			% mean()으로 f x 1 x ch -> t 만 n배 확장 : f x t x ch (원래 % 크기화)
			TFe_bl		=	TFe - TFes_bl; toc;	% 100배+ 차이	% signal shift

tic; fprintf('Engagement: Total TF with BaselineCorrection,except alpha band\n');
			% total tf (with baseline_correction: except alpha band)
%			[TF, TF_power]=epoch2tf_min(eEEG,Freqs,fSmpl,m,ki);
%			TF=single(TF);									%complex만 사용
%			TF			=	single( epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki) );
			TF			=	epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki);
			TF			=	single(TF);		%TF만 single화 처리가 더 속도 빠름
%			[TFi,TFP,TFA]=	tf2tfi_min(TF);
			TFi			=	tf2tfi_min(TF);

%			TFis_bl		=	squeeze(mean(TFi(:,TF_blTimWin,:),2));
%			TFi_bl		=	TFi;
%			for ii		=	1:size(TFi,3),
%				for f	=	1:length(Freqs),
%					TFi_bl(f,:,ii)	=	TFi(f,:,ii)-TFis_bl(f,ii);
%				end;
%			end;	toc;
			TFis_bl = repmat(mean(TFi(:,TF_blTimWin,:),2), [1,size(TFe,2),1]);
			TFi_bl		=	TFi - TFis_bl; toc;					%signal shift
			%%%%%%%%
			%%%%%%%%

			%----------
			%채널분리형 데이터를 별도 저장 -> 이후 결과들을 하나로 통합 후 저장
			lERP{CH}	=	ERP_filt_bl;
			lTFe{CH}	=	TFe_bl;
			lTFi{CH}	=	TFi;
			lTFib{CH}	=	TFi_bl;
			end				%for CH = 1 :
			%----------
			break;							%처리과정 정상적임. while() 탈출!

try		%메모리 부족 등 자원 한계로 처리 불가 예외 발생 시, 대응 수행
%--------------------------------------------------------------------------------
%catch	exception
%	if strcmp(exception.identifier,		...
%		'MATLAB:catenate:dimentionMismatch'),	???;	end
catch	exception	%병렬 연산 실패일 것이므로 (차후 에러msg 분석도 시도할 것)
					%연산 채널 수를 더 세분화 해서 수행하도록 변경
			if CPB < MxChn					%CPB가 최대수 보다 적을 경우
%				fprintf('\nFailure!  : %s\n', exception.message);
				disp(exception.message);
				fprintf('\n\nRegulating: CH-partition %d->%d\n', CPB, CPB*2);
				CPB		=	CPB * 2;		%2배로 블럭 수 증가
%				continue;					%현재 루프(CPB)를 다시 시작
			else							%채널1개 단위(사실상 순차) 도달
				fprintf('\nAbort     : the Analysis by resource lack.(PAUSE)\n');
				toc(AllTime);	quit;
			end
end			% try - catch
end			% while
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%--------------------------------------------------------------------------------
			%이제 통합
			ERP_filt_bl	=	[ lERP{:} ];			%통합 완료
			TFe_bl		=	lTFe{1};				%1st 배열 뽑은 후 like strcat
			TFi			=	lTFi{1};
			TFi_bl		=	lTFib{1};

			ChNext		=	length(lChns{1})+1;		%다음 작업할 채널 index
			for CH		=	2 : CPB
			for k		=	1 : length(lChns{CH})	%분할 영역의 길이 맞춰 동작
			TFe_bl	(:,:,ChNext)	=	lTFe{CH}	(:,:,k);
			TFi		(:,:,ChNext)	=	lTFi{CH}	(:,:,k);
			TFi_bl	(:,:,ChNext)	=	lTFib{CH}	(:,:,k);
			ChNext		=	ChNext + 1;				%작업한 만큼 채널수 증가
			end
			end				%for integrated loop

%--------------------------------------------------------------------------------
			% 1~32번 채널 wavelet 돌린 데이터를 저장
			% 데이터는 4 종류로, ERP_filt_bl, TFi, TFe_bl, TFi_bl 입니다.
			% 이 중 실제 wavelet이 적용된 주파수 데이터는 TFi, TFe_bl, TFi_bl 이고
			% ERP_filt_bl 은 ERP 데이터 입니다.
			% 미팅 때도 간단히 말씀드렸던 것과 같이, 여기서의 ERP_filt_bl 데이터는 필터링이 한번 더 된
			% 데이터이므로 분석에는 쓰지 않고, analyzer에서 export한 Average 데이터로 분석하시면 됩니다.

			% 'Result_' 로 시작하는 mat파일로 저장
%			cd result;
%			eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) ''';']);
%			save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
%			save([fullPATH '/skk_tf/' 'ERP_Evk_Tot_' WORKDEST '.mat'],		...
%							'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
			save(OUT_NAME,	'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');

			fprintf('\nComplete: %s''s processing :: ',WORKNAME);	toc(AllTime);

			clearvars -except	fullPATH	Regulation						...
								dataname	datanumb	subname		subnumb	...
								trialname	trialnumb	channame	removech ...
								Freqs		m			ki					...
								lChns		MxChn		CPB			Total	...
								NUMWORKERS	DAT_NAME	WORKNAME	WORKDEST ...
								POOL		MinEpoch						...
%			cd ..;
%			clc
			% 위의 'clearvars -except' 는, 이 코드에서 사용된 variable이 너무 많기 때문에 하나하나 다 써줄 수가 없어 데이터를 지울 때 지정된 variable을 제외하고 나머지
			% variable 들을 모두 clear 하라는 명령어 입니다.
		end
	end
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%	clear	TFwow;
%%matlabpool close;
delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

fprintf('\nFinished: total time is ');	toc(Total);
