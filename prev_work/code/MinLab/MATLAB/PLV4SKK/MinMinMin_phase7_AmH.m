function [PLV,PLS]		=	MinMinMin_phase7_AmH(Freqs)
%%%%%%%%%%%%%%%%%%%%%%%%
%  [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER)
% Usage:
%	>> [PLV,PLS]=tf2coh([ch1, ch2], TFwow, K,ITER)
%	>> tf2coh(double(1x2) ch, complex(single(9x1000x372x30)) TFwow,
%					double(1x1) K, double(1x1) iter)
%
% Inputs:
%	ch : [ch1, ch2];
%   TFc1: time freqency complex map at channel 1 (freq x time points x epochs)
%   TFc2: time freqency complex map at channel 2 (freq x time points x epochs)
%   K : numer of average for surrogation [default:200]
%   ITER: number of surrogation [default:200]
% Outputs:
%   PLV: phase locking value
%	   [freq x time]
%   PLS: phase locking statistics
% 2007/10/04
% by Hae-Jeong Park, Yonsei Univ. MoNET
% email: hjpark0@gmail.com
% 2015/07/01
% by Ahn Min-Hee(AmH::tigoum), Korea Univ. Min-LAB
% email: tigoum@naver.com
%%%%%%%%%%%%%%%%%%%%%%%%

global		NUMWORKERS;
global		WORKNAME;
global		TF;			% int64 type	%parent가 생성한 TF를 workspace서 갖고 옴

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% local 머신 범위에서, 병렬연산을 위한 가용 코어 설정
delete(gcp('nocreate'));

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

%nChns		=	[1:size(TF,4)];	% 채널 수를 변경 할 수도 있음. 갯수를 확인하고 순서도 확인 할 것. 우선은 TF의 전체 채널을 조사
nChns		=	size(TF,4);		% 채널 수를 변경 할 수도 있음. 갯수를 확인하고 순서도 확인 할 것. 우선은 TF의 전체 채널을 조사
nTime		=	size(TF,2);		% TF의 사이즈? c_eegTF 참조 TF는 3차원 주파수 시간 에폭순 (wavelet; 위상을 알기 위해 구하는 것 복소수 형태로 바꾼다.) epochs: 컨디션 별로 trial을 본다. wavelet을 하기전 
%Freqs		=	[FR(1):1/2:FR(2)];		%Hz 0.5 단위로 본 것. 세타

sK			=	10;						%surrogation : K
sI			=	100;					%K에 대한 원형통계용 반복 횟수: iter
%AB=size(TF,3);
%CD=nChns;
% EPOCHUSE1=size(TF,3);
% EPOCHUSE1=ones(AB, CD);
%%%%%%%%%%%%%%%%%%%%%%%%
%  [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER), PLV가 구하는 것, PLS 0.05인가 같은 것을 구하는 것
% Usage:
%  >> [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER)
%
% Inputs:
%   TFc1: time freqency complex map at channel 1 (freq x time points x epochs)
%   TFc2: time freqency complex map at channel 2 (freq x time points x epochs)
%   K : numer of average for surrogation [default:200]
%   ITER: number of surrogation [default:200]
% Outputs:
%   PLV: phase locking value
%       [freq x time]
%   PLS: phase locking statistics
%
% eEEG=shiftdim(EEG.data, 1); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EEG.data(channels x timepoints x epochs) ~= eEEG(timepoint x epochs x channels)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TF: time frequency complex maps for each epoch [freq x time x epoch x chan]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nChTOT		=	(nChns-1)*nChns/2;				%총 비교할 채널 수

PLV			=	zeros(length(Freqs), nTime, nChns,nChns, 'single');
PLS			=	zeros(length(Freqs), nTime, nChns,nChns, 'single');

%TF			=	single(TF);

%===============================================================================
%%	병렬연산 개시! <- 단 tf2coh()에서 수행, 각 채널조합 연산 시점에서만 병렬화
	tic; fprintf('Parallel: %s''s COH of FREQ:%5.2f~%5.2f, CHAN:%d*%d\n\n',	...
		WORKNAME, Freqs(1), Freqs(end), nChns, nChns);

%===============================================================================
%for f=1:length(Freqs),
		ChCnt			=	1;
	for ch1				=	1:nChns-1,
fprintf('\nGroup : %s''s COH request for CH1(%d) <-> CH2(%d~%d)\n',			...
		WORKNAME, ch1, ch1+1, nChns);

		for ch2			=	ch1+1:nChns,
fprintf('+Unit : COH %d/%d(%5.2f%%) of FREQ:%5.2f~%5.2f, CHAN:%d~%d\n',		...
		ChCnt, nChTOT, ChCnt / nChTOT * 100,	Freqs(1), Freqs(end), ch1, ch2);
		ChCnt			=	ChCnt + 1;

%			[flen,nTime,numepoch,chs]=	size(TF(:,:,:,:));
%			numepoch	=	numepoch * nTime / 1000;
%			[plv, pls]	=	tf2coh_min4_AmH(TF(:,:,:,ch1), TF(:,:,:,ch2), sK,sI);
			[plv, pls]	=	tf2coh_min2pf_AmH(TF(:,:,:,ch1),TF(:,:,:,ch2),sK,sI);
			% K, ITER 위에 설명 써있음. 몇 개를 평균 낸다.
			% surrogation(전체 평균, 뽑아 낸 것)을 하면 좋은데 느림...
			% 원형 통계라는 것이 있다.

			for f		=	1:length(Freqs),
			% 슈퍼컴과 MDCS를 테스트 해보기
			if pls(f,:) < 0.05,
%			if pls < 0.05,
 				PLV(f,:,ch1,ch2)=	plv(f,:);
 				PLV(f,:,ch2,ch1)=	plv(f,:);
 				PLS(f,:,ch1,ch2)=	pls(f,:);
 				PLS(f,:,ch2,ch1)=	pls(f,:);	% 절반만 돌리면 되는데 전체??
% 아래 구문은 미래에 테스트 해보자. 지금은 안급함.(저장방식의 효율성 고려)
%				PLVsub{f,ch1,ch2}	=	plv;
%				PLSsub{f,ch1,ch2}	=	pls;
%				PLVsub{ch2}		=	plv(f,:);	% cell{}<-double(f, 1:1000) 저장
%				PLSsub{ch2}		=	pls(f,:);	% 절반만 돌리면 되는데 전체??
			else
%				PLVsub{ch2}		=	zeros(1, nTime);	%dummy 값으로 채움
%				PLSsub{ch2}		=	zeros(1, nTime);	%dummy 값으로 채움
			end;					%end if ..

			end;					%end for f=..

		end;

%%		PLVmid{f,ch1}			=	PLVsub;			% PLVsub{ch_dst} = (1,1:1000) ; timezone 기준 데이터array를 셀에 구분저장
%%		PLSmid{f,ch1}			=	PLSsub;			% timezone 기준 데이터array를 셀에 구분저장
	end;
%end;

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%	clear	TFwow;
%%matlabpool close;
delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%% 20150517A. 데이터 포맷을 종전 양식으로 재구성
%-> 미래에 다시 시도해 보자. 지금은 굳이 안해도 됨.
%for f=1:length(Freqs),
%	for ch1=1:nChns-1, % channel combination 전체 비교
%		for ch2=ch1+1:nChns,
%			%원래 위의 loop 내에서 처리되어야 하지만,, parfor특성으로 인해,
%			%ch1, ch2 조합에게 (<-) ch2, ch1(앞서 저장된, 끝 index가 ch1 임!)을 복제함.
%%			PLV(f,:,ch1,ch2)	=	PLV(f,:,ch2,ch1);
%%			PLS(f,:,ch1,ch2)	=	PLS(f,:,ch2,ch1);	%위와 동일한 이슈
%
%			PLV(f,:,ch1,ch2)	=	PLVmid{f,ch1}{ch2};	%double(1,1000) 배열
%			PLV(f,:,ch2,ch1)	=	PLVmid{f,ch1}{ch2};
%			PLS(f,:,ch1,ch2)	=	PLSmid{f,ch1}{ch2};	%double 값
% 			PLS(f,:,ch2,ch1)	=	PLSmid{f,ch1}{ch2};
%% 
%		end;
%	end;
%end;

function [PLV,PLS]		=	MinMinMin_phase7x_AmH(Freqs)		%-[
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%

global		NUMWORKERS;
global		WORKNAME;
global		TF;			% int64 type	%parent가 생성한 TF를 workspace서 갖고 옴

%AB=size(TF,3);
%CD=nChns;
% EPOCHUSE1=size(TF,3);
% EPOCHUSE1=ones(AB, CD);
%%%%%%%%%%%%%%%%%%%%%%%%
%  [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER), PLV가 구하는 것, PLS 0.05인가 같은 것을 구하는 것
% Usage:
%  >> [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER)
%
% Inputs:
%   TFc1: time freqency complex map at channel 1 (freq x time points x epochs)
%   TFc2: time freqency complex map at channel 2 (freq x time points x epochs)
%   K : numer of average for surrogation [default:200]
%   ITER: number of surrogation [default:200]
% Outputs:
%   PLV: phase locking value
%       [freq x time]
%   PLS: phase locking statistics
%
% eEEG=shiftdim(EEG.data, 1); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EEG.data(channels x timepoints x epochs), but eEEG(timepoint x epochs x channels)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TF: time frequency complex maps for each epoch [freq x time x epoch x chan]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% local 머신 범위에서, 병렬연산을 위한 가용 코어 설정
delete(gcp('nocreate'));

%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% 신규 profile 작성
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% 최대 48 core 고려.

	fprintf('Pooling : the parallel worker''s setup completed. '); toc;
	%!주의: parent 에서 호출직전에 tic를 수행한다는 가정하에, toc 출력 요청함.

%%-------------------------------------------------------------------------------
nChns		=	size(TF,4);		% 채널 수를 변경 할 수도 있음. 갯수를 확인하고 순서도 확인 할 것. 우선은 TF의 전체 채널을 조사
nTime		=	size(TF,2);		% TF의 사이즈? c_eegTF 참조 TF는 3차원 주파수 시간 에폭순 (wavelet; 위상을 알기 위해 구하는 것 복소수 형태로 바꾼다.) epochs: 컨디션 별로 trial을 본다. wavelet을 하기전 
%Freqs		=	[FR(1):1/2:FR(2)];		%Hz 0.5 단위로 본 것. 세타

sK			=	10;						%surrogation : K
sI			=	100;					%K에 대한 원형통계용 반복 횟수: iter

PLV			=	zeros(length(Freqs),nTime,nChns,nChns, 'single');
%PLVcell		=	cell(nTime,1);												% PLV의 time 차원만 별도 셀 구성
PLS			=	zeros(length(Freqs),nTime,nChns,nChns, 'single');	% 틀을 만들어 주는 것
ChCombi		=   cell((nChns-1)*nChns/2,1);%계산에 의하면, sigma k=1~n-1 ( K ) = n(n-1)/2
PLVCh		=	zeros(length(Freqs), nTime, length(ChCombi));	%ChCombi순서 대응하여 저장하는 구조
PLSCh		=	zeros(length(Freqs), nTime, length(ChCombi));	%반드시 PLS 어레이 구성과 일치해야 함.

%%-------------------------------------------------------------------------------
	tic; fprintf('Standby : %s''s COH of Channel Combination:%d*%d\n',	...
		WORKNAME, nChns, nChns);

	index						=	1;				%ChCombi를 계수하기 위한 변수
	for ch1=1:nChns-1,
		for ch2=ch1+1:nChns,
			ChCombi{index}		=	[ch1, ch2];		%채널의 조합을 구성하여 저장
			index				=	index + 1;		%다음 조합 저장 위치
		end
	end

%%	병렬연산 개시!
	fprintf('Parallel: %s''s COH of FREQ:%5.2f~%5.2f, CHAN:%d*%d\n',	...
		WORKNAME, Freqs(1), Freqs(end), nChns, nChns);

	parfor index = 1:length(ChCombi),				%working local only
		ch1					=	ChCombi{index}(1);
		ch2					=	ChCombi{index}(2);
	%위 '+Unit :'은 spmd의한 출력 들여쓰기에 맞춰 상위 fprint와 ':'의 일치 위함.
	fprintf('+Unit : COH %3dth/%d of FREQ:%5.2f~%5.2f, CHAN:%d~%d\n',	...
			index, length(ChCombi), Freqs(1), Freqs(end), ch1, ch2);

			%기존 tf2coh_min()과 파라미터 구조 다름
%		[plv, pls]			=	tf2coh_min2_AmH_mex(Local{index}, TF, sK, sI);
		[plv, pls]			=	tf2coh_min2_AmH(ChCombi{index}, TF, sK, sI);

%		for f=1:length(Freqs),
%			if pls(f,:) < 0.05,					%each ch & f, but [all time]
%			PLVCh(:,:,index)	=	plv(:,:);	%single(1,1000) 배열
%			LoPLV(f,:,index)	=	plv(f,:);
%			PLSCh(:,:,index)	=	pls(:,:);	%double 값
%			LoPLS(f,:,index)	=	pls(f,:);
%			end
%		end
		%for f=1 와 if pls( < 0.05 를 하게되면 저장공간인 PLV 혹은 PLVCh의
		%유형을 parfor 가 판단하지 못하며 에러를 발생시킨다.
		%이는, plv, pls와 PLV, PLSCh의 인덱스 성분(f, time 등)을 개별적으로
		%indexing 하기 때문에 PLVCh를 하나의 변수로서 판독하지 못하고,
		%개별 변수로 취급되면서 parfor가 혼란을 겪는 것으로 보임.
		%또한, parfor 내부에서 순차처리하는 for 를 사용하는 것도 요인인 듯.
		%따라서, parfor 내부에서는 for 나 for 변수에 의한 인덱싱을 하지 말자.
		%연산결과는 그냥 array에 바로 저장하고, 개별 인덱싱과 판독은 별도로 할 것
		PLVCh(:,:,index)	=	plv(:,:);	%single(1,1000) 배열
		PLSCh(:,:,index)	=	pls(:,:);	%double 값
	end		%end parfor

%%
%matlabpool close;
delete(POOL);
%%

%%	cell단위로 저장한 데이터들을 기존 4D 어레이에 재구성 수행.
	fprintf('Clean up: %s''s COH(PLV, PLS) data\n',	WORKNAME);
	for index2=1:length(ChCombi),	%--[
			ch1					=	ChCombi{index2}(1);
			ch2					=	ChCombi{index2}(2);

		for f=1:length(Freqs),
			if PLSCh(f,:,index2) < 0.05,		%each ch & f, but [all time]
%			PLV(f,:,ch1,ch2)	=	PLVCh(f,:,index2);	%single(1,1000) 배열
%			PLV(f,:,ch2,ch1)	=	PLVCh(f,:,index2);	%single(1,1000) 배열
%			PLS(f,:,ch1,ch2)	=	PLSCh(f,:,index2);	%single 값
%			PLS(f,:,ch2,ch1)	=	PLSCh(f,:,index2);	%single 값
			PLV(f,:,ch1,ch2)	=	PLVCh(f,:,index2);	%single(1,1000) 배열
			PLV(f,:,ch2,ch1)	=	PLVCh(f,:,index2);	%single(1,1000) 배열
			PLS(f,:,ch1,ch2)	=	PLSCh(f,:,index2);	%single 값
			PLS(f,:,ch2,ch1)	=	PLSCh(f,:,index2);	%single 값
			end;					%end if ..
		end;					%end for;
	end;	%-]

% [TFi,TFP,TFA]=tf2tfi_min(TFS,EPOCHUSE1);
% f=4; t=250:300; 
%%% Freqs=1占쏙옙占싶곤옙 占싣댐옙 占쏙옙, 占쏙옙占쏙옙.
%%% Timepoint 占쏙옙占쏙옙 dominantTF占쏙옙 占쏙옙占쏙옙 占쏙옙 占쌕억옙占쏙옙占?TF 占싱므뤄옙 처占쏙옙 TF_origin 占쏙옙占쏙옙 coh 占쏙옙占쌀띰옙占쏙옙 占쏙옙 strike zone占쏙옙 timepoint占쏙옙 占쌕뀐옙占쏙옙占쏙옙占?!!

%data(,) == 6개(국가 x trial)의 가로축(time) x 주파수축(freq) 정보 가진 2-D 배열
%a == 6개 case 중 특정반응신호 포함하는 strikezone 해당 case
%a == datanumb * trialnumb 
%a = ( datanumb * length(trialname) ) + trialnumb ; %6개 배열에서의 정확한 index를 계산하기 위한 공식
%data(a,1)=mxFreq; %freq. 중 peak 값
%data(a,2)=0.00; %ms 범위에서 다룰 것: time 중 start 시점
%data(a,3)=.700; %ms 범위에서 다룰 것: time 중 finish시점

%f=((data(a,1)-4)*2+1); t=data(a,2)/0.002+250:data(a,3)/0.002+250;

% strike zone, 주파수는 잡았는데, maximum이 있을 만한 time window를 보여준 것, 어디가 필요한 지를 아는 방법
% 주파수 별로 정했었는데, 알파인 경우에는 8-13, 베타 15-30, 세타 4-8, 0-700ms 잡고 진행 (maximum인
% 지점에서의 값을 사람마다 구한다.)
% pacelocking 에서 최대값인 부분을 하는 것 占쏙옙! % 단위를 맞추어 준것. 실제 frequency로 바꾸어준것. hz,
% 시간 축, 끝 점 순서로 되어 있음 wavelet에 의한 Pace locking을 봄
% 만약 알파에 대해 한다면, 필터링을 하고 eEEG 하고 알파에 대해 진행을 한다. 그 후 다른 것도 반복하는 방식으로 진행한다.
% (필요한 부분만 끊어서 진행하는 방식)
%t=floor(t); %?쎌뼱?ㅼ씤 data ?덉뿉 timepoint 媛??뺤닔?뺤씠 ?꾨땲?쇱꽌 諛붽퓭

%coh=squeeze(mean(PLV(f,t,:,:),2)); % coh should not be NaN, 주파수가 정해지고, 시간은 범위일수도 아닐 수도, 채널, 채널
% 모자이크 그리기, 여기 부터는 그림 그리기를 위한 coh라는 파일을 저장하는 것
% ch17= EOG, ch22=NULL, 없는 부분을 날림.뒤에서 붙터
%coh(22,:)=[];coh(17,:)=[];
%coh(:,22)=[];coh(:,17)=[];

% thr=0.9; %그림을 그리는 건데, 마지막에 plotcloh 그려라. 이 부분 밑으로 살려서 그림 (0.9이상인 값만
% 보여준다.) PLV 값이 큰 것
% 
% figure;
% topoplot([],'EEG_30chan.ced','electrodes','labels'); colorbar; %EEGLAB을
% 깔아서 연결 시켜서 진행하는 것 (topoplot을 빌려서 사용하는 것. EEG_30chan.ced 포지션에 대한 파일도 있어야
% 한다.) electrode 위치가 찍히고, 이름이 명령되도록 하는 function. colorbar는 머리 옆에 그리는 것
% plotcoh_jh('EEG_30chan.ced',coh,thr); % 머리를 그려주는 것. 모자이크는 matlab 기능을 사용,
% thr의 범위를 구할 수 있다.
% 플롯을 눌러서 진행하면 그래프 그릴 수 있다. help plot 해서 그에 대한 내용을 보면 Contour plots
% graphics, 반 없이 그리고 진행하기, contourf로 그리기, colorbar로 그림 그리기, tril로 반을 날릴 수
% 있다. figure: n= tril(m);contour(n');colorbar;	%-]
