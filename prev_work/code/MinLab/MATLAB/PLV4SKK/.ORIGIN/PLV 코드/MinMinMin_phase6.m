chns=[1:32]; % 채널 수를 변경 할 수도 있음. 갯수를 확인하고 순서도 확인 할 것 
freqrange=[13:1/2:30];   %Hz 베타 대역을 본 것, 0.5 단위로 본 것 알파 8-12
tlen=size(TF,2); % TF의 사이즈? c_eegTF 참조 TF는 3차원 주파수 시간 에폭순 (wavelet; 위상을 알기 위해 구하는 것 복소수 형태로 바꾼다.) epochs: 컨디션 별로 trial을 본다. wavelet을 하기전 
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

PLV=zeros(length(freqrange),tlen,length(chns),length(chns));
PLS=zeros(length(freqrange),tlen,length(chns),length(chns)); % 틀을 만들어 주는 것
% TFS=zeros(length(freqrange),tlen,size(EPOCHUSE1,1),length(chns),'single');
for f=1:length(freqrange),
    freqs=freqrange(f);
    % TF=epoch2tf(eEEG,freqs,fsamp,m,ki,EPOCHUSE1); %complex
    TF=single(TF);
%    TFS(f,:,:,:)=TF;   
    for ch1=1:length(chns), % channel combination 전체 비교
        fprintf('COH of FREQ:%f, CH1:%d..\n',freqrange(f),ch1);
        for ch2=ch1+1:length(chns),
            %eid=find(EPOCHUSE1(:,ch1)>0 & EPOCHUSE1(:,ch2)>0);
            [plv, pls]=tf2coh_min(TF(f,:,:,ch1),TF(f,:,:,ch2),10,100); % K, ITER 위에 설명 써있음 몇 개를 평균을 낸다, surrogation(전체 평균, 뽑아 낸 것)을 하면 좋은데 느림, 원형 통계라는 것이 있다.
            % 슈퍼컴과 MDCS를 테스트 해보기
            if pls<0.05,
            PLV(f,:,ch1,ch2)=plv;
            PLV(f,:,ch2,ch1)=plv;
            PLS(f,:,ch1,ch2)=pls;
            PLS(f,:,ch2,ch1)=pls; % 절반만 돌리면 된느 데 전체가 있는 건가??
            end;
        end;
    end;
end;

% [TFi,TFP,TFA]=tf2tfi_min(TFS,EPOCHUSE1);
% f=4; t=250:300; 
%%% freqrange=1占쏙옙占싶곤옙 占싣댐옙 占쏙옙, 占쏙옙占쏙옙.
%%% Timepoint 占쏙옙占쏙옙 dominantTF占쏙옙 占쏙옙占쏙옙 占쏙옙 占쌕억옙占쏙옙占?TF 占싱므뤄옙 처占쏙옙 TF_origin 占쏙옙占쏙옙 coh 占쏙옙占쌀띰옙占쏙옙 占쏙옙 strike zone占쏙옙 timepoint占쏙옙 占쌕뀐옙占쏙옙占쏙옙占?!!
f=((data(a,1)-13)*2+1); t=data(a,2)/0.002+250:data(a,3)/0.002+250; % strike zone, 주파수는 잡았는데, maximum이 있을 만한 time window를 보여준 것, 어디가 필요한 지를 아는 방법
% 주파수 별로 정했었는데, 알파인 경우에는 8-13, 베타 15-30, 세타 4-8, 0-700ms 잡고 진행 (maximum인
% 지점에서의 값을 사람마다 구한다.)
% pacelocking 에서 최대값인 부분을 하는 것 占쏙옙! % 단위를 맞추어 준것. 실제 frequency로 바꾸어준것. hz,
% 시간 축, 끝 점 순서로 되어 있음 wavelet에 의한 Pace locking을 봄
% 만약 알파에 대해 한다면, 필터링을 하고 eEEG 하고 알파에 대해 진행을 한다. 그 후 다른 것도 반복하는 방식으로 진행한다.
% (필요한 부분만 끊어서 진행하는 방식)
t=floor(t); %?쎌뼱?ㅼ씤 data ?덉뿉 timepoint 媛??뺤닔?뺤씠 ?꾨땲?쇱꽌 諛붽퓭
coh=squeeze(mean(PLV(f,t,:,:),2)); % coh should not be NaN, 주파수가 정해지고, 시간은 범위일수도 아닐 수도, 채널, 채널
% 모자이크 그리기, 여기 부터는 그림 그리기를 위한 coh라는 파일을 저장하는 것
% ch17= EOG, ch22=NULL, 없는 부분을 날림.뒤에서 붙터
coh(22,:)=[];coh(17,:)=[];
coh(:,22)=[];coh(:,17)=[];

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