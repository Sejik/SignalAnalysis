chns		=	[1:size(TF,4)];	% 채널 수를 변경 할 수도 있음. 갯수를 확인하고 순서도 확인 할 것. 우선은 TF의 전체 채널을 조사
tlen		=	size(TF,2);		% TF의 사이즈? c_eegTF 참조 TF는 3차원 주파수 시간 에폭순 (wavelet; 위상을 알기 위해 구하는 것 복소수 형태로 바꾼다.) epochs: 컨디션 별로 trial을 본다. wavelet을 하기전 
fRange		=	[FR(1):1/2:FR(2)];		%Hz 0.5 단위로 본 것. 세타

sK			=	10;						%surrogation : K
sI			=	100;					%K에 대한 원형통계용 반복 횟수: iter
%AB=size(TF,3);
%CD=length(chns);
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

PLV			=	zeros(length(fRange),tlen,length(chns),length(chns));
%PLVcell		=	cell(tlen,1);												% PLV의 time 차원만 별도 셀 구성
PLS			=	zeros(length(fRange),tlen,length(chns),length(chns));	% 틀을 만들어 주는 것
ChCombi		=   cell((length(chns)-1)*length(chns)/2,1);%계산에 의하면, sigma k=1~n-1 ( K ) = n(n-1)/2
PLVCh		=	zeros(length(fRange), tlen, length(ChCombi));	%ChCombi순서 대응하여 저장하는 구조
PLSCh		=	zeros(length(fRange), tlen, length(ChCombi));	%반드시 PLS 어레이 구성과 일치해야 함.
% TFS=zeros(length(fRange),tlen,size(EPOCHUSE1,1),length(chns),'single');
TF			=	single(TF);

%% local 머신 범위에서, 병렬연산을 위한 가용 코어 설정
delete(gcp('nocreate'));

%http://vtchl.illinois.edu/node/537
myCluster	=	parcluster('local');
myCluster.NumWorkers	=	40;				% 'Modified' property now TRUE
saveProfile(myCluster);						% 'local' profile now updated,
											% 'Modified' property now FALSE
POOL		=	parpool('local', 20);		% 최대 48 core 까지 고려.
%POOL		=	parpool('local');			% 현재 머신의 최대 core로 디폴트 설정됨.
%matlabpool open 4;
	fprintf('Pooling : the parallel worker''s setup completed. '); toc;
	%!주의: parent 에서 호출직전에 tic를 수행한다는 가정하에, toc 출력 요청함.

%%-------------------------------------------------------------------------------
	tic; fprintf('Standby : %s''s COH of Channel Combination:%d*%d\n',	...
		WORKNAME, length(chns), length(chns));

	index						=	1;				%ChCombi를 계수하기 위한 변수
	for ch1=1:length(chns)-1,
		for ch2=ch1+1:length(chns),
			ChCombi{index}		=	[ch1, ch2];		%채널의 조합을 구성하여 저장
			index				=	index + 1;		%다음 조합 저장 위치
		end
	end

%%	병렬연산 개시!
	fprintf('Parallel: %s''s COH of FREQ:%5.2f~%5.2f, CHAN:%d*%d\n',	...
		WORKNAME, fRange(1), fRange(end), length(chns), length(chns));

	parfor index = 1:length(ChCombi),				%working local only
		ch1					=	ChCombi{index}(1);
		ch2					=	ChCombi{index}(2);
	%위 '+Unit :'은 spmd의한 출력 들여쓰기에 맞춰 상위 fprint와 ':'의 일치 위함.
	fprintf('+Unit : COH %3dth/%d of FREQ:%5.2f~%5.2f, CHAN:%d~%d\n',	...
			index, length(ChCombi), fRange(1), fRange(end), ch1, ch2);

			%기존 tf2coh_min()과 파라미터 구조 다름
%		[plv, pls]			=	tf2coh_min2_AmH_mex(Local{index}, TF, sK, sI);
		[plv, pls]			=	tf2coh_min2_AmH(ChCombi{index}, TF, sK, sI);

%		for f=1:length(fRange),
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

		for f=1:length(fRange),
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
%%% fRange=1占쏙옙占싶곤옙 占싣댐옙 占쏙옙, 占쏙옙占쏙옙.
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
% 있다. figure: n= tril(m);contour(n');colorbar;
