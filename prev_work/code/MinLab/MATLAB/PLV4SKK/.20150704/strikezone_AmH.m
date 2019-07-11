function [coh,f,t] = strikezone_tigoum(PLV, PLS) % PLV(4D)로부터 최대값 가지는 위치에 대응하는 coh 구하기

% [TFi,TFP,TFA]=tf2tfi_min(TFS,EPOCHUSE1);
% f=4; t=250:300; 
%%% freqrange=1占쏙옙占싶곤옙 占싣댐옙 占쏙옙, 占쏙옙占쏙옙.
%%% Timepoint 占쏙옙占쏙옙 dominantTF占쏙옙 占쏙옙占쏙옙 占쏙옙 占쌕억옙占쏙옙占?TF 占싱므뤄옙 처占쏙옙 TF_origin 占쏙옙占쏙옙 coh 占쏙옙占쌀띰옙占쏙옙 占쏙옙 strike zone占쏙옙 timepoint占쏙옙 占쌕뀐옙占쏙옙占쏙옙占?!!



%matlab은 default로 column단위(2D 매트릭스의 세로방향)으로 각 list의 max구함.
%따라서, 수직축(row)에 배열된 f에 속한 각 list별로 max를 구하기 위해서는,
%수평방향(row)으로 연산을 시켜야 함: help윈도우에서 "Maximum Value from Each Matrix Row" 참조.
%
%주의!!: PLV는 4D 배열이고, 구성은 (f, t, ch, ch) 인데, max 는 처음 값 즉, 매트릭스에서 열(세로방향)을
%대상으로 연산한다. 따라서, max(PLV) 하면, f를 기준으로 max를 계산하므로, 하나의 t에 대해 대응하는 f들을 계산함.
%다시 말하면:
%		f^
%		8|
%		7|
%		6|
%		5|
%		4|--------------------------->
%			2 3 4 5 6 7 8 9 10 11 12 t
%에서, t=2에 대응하는 f=4,5,6,7,8 에 속한 값들 중 max를 찾는다. 이것은 우리가 원하는 것과 반대이다.
%우리는 f=4에서 t=2,3,4,... 에 속한 값들 중 max를 찾고자 하기 때문이다.
%그러므로, max를 수행할 때, col이 아닌 row를 대상으로 계산시켜야 하며, max(PLV, [], 2)라고 2차원을 대상으로
%지목하면 된다.
%
%하지만!!
%실제로 PLV는 4D 이고, 2차원인 t 대상으로 연산을 시켜도 3,4차원이 아직 그대로 유지되고 있으므로, 올바른 max 값이 아닌
%배열이 발생된다. 따라서, 4차원부터 역으로 max를 반복실행 해야만, 최종적으로 f 에 대한 결과를 도출할 수 있다.
%이 말의 의미는, 가장 외곽에 놓인 배열, 즉 3, 4차원에 의한 2D 매트리스가 ch * ch 의 매트리스이고, 이 매트리스 중
%A. 4차원 상의 나열 값 중 max 값을 취하여 3차원 각 채널에 대응시키는 것이다.
%B. 그리고 이 3차원 상의 나열 값 중 max를 취해서 2차원 각 t에 대응시키는 것이다.
%C. 다음으로는 이 2차원 t 상의 나열 값중 max를 취해서 각 f에 대응시키고,
%D. 최종적으로 1차원 f 상의 나열 값중 max를 찾는 것이다. 즉, 최대값을 가지는 f 결정.

[M3, I3]	=	max(PLV, [], 4);	%ch2 를 대상으로 우선 최대값 추적
[M2, I2]	=	max(M3,  [], 3);	%다음은 ch1 을 대상으로..
[M1, I1]	=	max(M2,  [], 2);	%이젠 time zone 을 대상으로..
[fM, f ]	=	max(M1);			%f 에는 최대값 가지는 주파수의 "index"

%[tM, tI]	=	max(M2(f, :));		%최대 PLV 가진 주파수에 속한 time line 중 최대값 해당하는 time의 "index"
Ts			=	0.0;				%time window의 시작과 끝. (-0.5 ~ +1.5s) 중 ( 0 ~ 700ms)
Te			=	0.7;				%time window의 시작과 끝. (-0.5 ~ +1.5s) 중 ( 0 ~ 700ms)
%20150509A. 시간구간에서 최대값을 가지는 신호의 범위를 찾을 때. 최대/최소값의 크기 threshold 기준은 무엇?
%신호는 전체적인 추세로 보았을 때, 커다란 정현파의 모습을 할 것인데, 이때, 신호를 짜르기 위한 최소값 기준은?


%data(,) == 6개(국가 x trial)의 가로축(time) x 주파수축(freq) 정보 가진 2-D 배열
%a == 6개 case 중 특정반응신호 포함하는 strikezone 해당 case
%a == datanumb * trialnumb 
%a = ( datanumb * length(trialname) ) + trialnumb ; %6개 배열에서의 정확한 index를 계산하기 위한 공식
%data(a,1)=mxFreq; %freq. 중 peak 값
%data(a,2)=0.00; %ms 범위에서 다룰 것: time 중 start 시점
%data(a,3)=.700; %ms 범위에서 다룰 것: time 중 finish시점

%f=((data(a,1)-4)*2+1); t=data(a,2)/0.002+250:data(a,3)/0.002+250;
t			=	(Ts+0.5)/0.002:(Te+0.5)/0.002;		% t는 index이며, 범위는 250 ~ 600



% strike zone, 주파수는 잡았는데, maximum이 있을 만한 time window를 보여준 것, 어디가 필요한 지를 아는 방법
% 주파수 별로 정했었는데, 알파인 경우에는 8-13, 베타 15-30, 세타 4-8, 0-700ms 잡고 진행 (maximum인
% 지점에서의 값을 사람마다 구한다.)
% pacelocking 에서 최대값인 부분을 하는 것 占쏙옙! % 단위를 맞추어 준것. 실제 frequency로 바꾸어준것. hz,
% 시간 축, 끝 점 순서로 되어 있음 wavelet에 의한 Pace locking을 봄
% 만약 알파에 대해 한다면, 필터링을 하고 eEEG 하고 알파에 대해 진행을 한다. 그 후 다른 것도 반복하는 방식으로 진행한다.
% (필요한 부분만 끊어서 진행하는 방식)
t			=	floor(t); %?쎌뼱?ㅼ씤 data ?덉뿉 timepoint 媛??뺤닔?뺤씠 ?꾨땲?쇱꽌 諛붽퓭

coh			=	squeeze(mean(PLV(f,t,:,:),2));		% coh should not be NaN: 주파수 고정, 시간 대상 평균냄(시간짜부), 채널, 채널
f			=	(f-1)/2+4;							% PLV(f)에서 f=1일 때 실제로는 4Hz 부터 시작함: 따라서 환산필요.
t			=	(t-250)*0.002;						% 인덱스를 실제 시간범위로 환산
% 모자이크 그리기, 여기 부터는 그림 그리기를 위한 coh라는 파일을 저장하는 것

%단, 32개 채널 전체를 수행했을 경우에는, 더미채널을 제거해야 한다.
% ch17= EOG, ch22=NULL, 없는 부분을 날림. 뒤에서 부터 날려야 제대로 처리됨.
if length(coh(1,:)) >= 31,
	coh(22,:)=[];	coh(17,:)=[];	%1차원 제거
	coh(:,22)=[];	coh(:,17)=[];	%2차원 제거
end;

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
