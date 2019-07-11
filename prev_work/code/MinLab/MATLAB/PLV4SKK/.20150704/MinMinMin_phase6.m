chns		=	[1:size(TF,4)];	% 채널 수를 변경 할 수도 있음. 갯수를 확인하고 순서도 확인 할 것. 우선은 TF의 전체 채널을 조사
tlen		=	size(TF,2);		% TF의 사이즈? c_eegTF 참조 TF는 3차원 주파수 시간 에폭순 (wavelet; 위상을 알기 위해 구하는 것 복소수 형태로 바꾼다.) epochs: 컨디션 별로 trial을 본다. wavelet을 하기전 
freqrange	=	[FR(1):1/2:FR(2)];		%Hz 0.5 단위로 본 것. 세타
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

PLV			=	zeros(length(freqrange),tlen,length(chns),length(chns));
PLS			=	zeros(length(freqrange),tlen,length(chns),length(chns)); % 틀을 만들어 주는 것
PLVmid		=	cell(length(freqrange), length(chns));	%셀 타입구성: ch2 * plv셀 저장
PLSmid		=	cell(length(freqrange), length(chns));
%PLVsub		=	cell(length(chns));						%셀 타입구성: plv배열==double(1, 1:1000) 저장
%PLSsub		=	cell(length(chns));						%이렇게 하면 len(chns)*len(chns) == 30 x 30 매트릭스가 생성...
PLVsub		=	cell(1,length(chns));					%셀 타입구성: plv배열==double(1, 1:1000) 저장
PLSsub		=	cell(1,length(chns));					%이유는 모르겠으나, 위와 같이하면 안되서, 1차원을 강제 구성
% TFS=zeros(length(freqrange),tlen,size(EPOCHUSE1,1),length(chns),'single');
TF			=	single(TF);

for f=1:length(freqrange),
%	freqs=freqrange(f);
%	TF=epoch2tf(eEEG,freqs,fsamp,m,ki,EPOCHUSE1); %complex
%	TFS(f,:,:,:)=TF;   
	for ch1=1:length(chns)-1, % channel combination 전체 비교
		fprintf('%s''s COH of FREQ:%f, | CH1(%d) vs CH2[%d:%d] |\n', WORKNAME, freqrange(f), ch1, ch1+1, length(chns));

		for ch2=ch1+1:length(chns),
			%eid=find(EPOCHUSE1(:,ch1)>0 & EPOCHUSE1(:,ch2)>0);
			[plv, pls]			=	tf2coh_min(TF(f,:,:,ch1), TF(f,:,:,ch2), 10, 100);	% K, ITER 위에 설명 써있음. 몇 개를 평균을 낸다, surrogation(전체 평균, 뽑아 낸 것)을 하면 좋은데 느림, 원형 통계라는 것이 있다.
			% 슈퍼컴과 MDCS를 테스트 해보기
			if pls < 0.05,
 				PLV(f,:,ch1,ch2)=	plv;
 				PLV(f,:,ch2,ch1)=	plv;
 				PLS(f,:,ch1,ch2)=	pls;
 				PLS(f,:,ch2,ch1)=	pls;	% 절반만 돌리면 되는데 전체가 있는 건가??
% 아래 구문은 미래에 테스트 해보자. 지금은 안급함.(저장방식의 효율성 고려)
%				PLVsub{f,ch1,ch2}	=	plv;
%				PLSsub{f,ch1,ch2}	=	pls;
%%				PLVsub{ch2}		=	plv;	% cell{} <- double(1, 1:1000) 저장
%%				PLSsub{ch2}		=	pls;	% 절반만 돌리면 되는데 전체가 있는 건가??
			else
%%				PLVsub{ch2}		=	zeros(1, tlen);	%dummy 값으로 채움
%%				PLSsub{ch2}		=	0.0;			%dummy 값으로 채움
			end;
%%			plv					=	PLVsub{ch2};
%%			pls					=	PLSsub{ch2};
%			save(['x:/PLV_theta' '/skk_phase30/' 'Phase_' 'Fav_USA_dislike_su14' '_ch' num2str(ch1) '~ch' num2str(ch2) '_seq.mat'], 'plv', 'pls', '-v7.3');

%%			중간 데이터 저장
%%				save([fullPATH '\skk_phase31\' 'Phase_' WORKNAME '_seq_f' num2str(freqrange(f)) '_ch' num2str(ch1) '~ch' num2str(ch2) '.mat'], 'channame', 'selchanname', 'plv', 'pls', '-v7.3');

		end;

%%		PLVmid{f,ch1}			=	PLVsub;			% PLVsub{ch_dst} = (1,1:1000) ; timezone 기준 데이터array를 셀에 구분저장
%%		PLSmid{f,ch1}			=	PLSsub;			% timezone 기준 데이터array를 셀에 구분저장
		
% 		for ch2=ch1+1:length(chns),
% 			if	(PLV(f,:,ch1,ch2)	~=	PLVmid{f,ch1}{ch2}) | ...	%double(1,1000) 배열
% 				(PLS(f,:,ch1,ch2)	~=	PLSmid{f,ch1}{ch2}),		%double 값
% 				fprintf('PLV-Diff(NOM) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch1,ch2), PLVmid{f,ch1}{ch2}(1) );
% 			end
% 
% 			if 	(PLV(f,:,ch2,ch1)	~=	PLVmid{f,ch1}{ch2}) | ...
% 				(PLS(f,:,ch2,ch1)	~=	PLSmid{f,ch1}{ch2}),
% 				fprintf('PLV-Diff(INV) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch2,ch1), PLVmid{f,ch1}{ch2}(1) );
% 			end
% 		end
	end;
	
%%		중간 데이터 저장
%				PLVf			=	PLV(f,:,:,:);
%				PLSf			=	PLS(f,:,:,:);
%				save([fullPATH '\skk_phase31\' 'Phase_' WORKNAME '_seq_f' num2str(freqrange(f)) '.mat'], 'channame', 'selchanname', 'PLVf', 'PLSf', '-v7.3');

end;

%% 20150517A. 데이터 포맷을 종전 양식으로 재구성
%-> 미래에 다시 시도해 보자. 지금은 굳이 안해도 됨.
%PLVre		=	zeros(length(freqrange),tlen,length(chns),length(chns));	%PLV의 reconstruction 버전
%PLSre		=	zeros(length(freqrange),tlen,length(chns),length(chns));
%for f=1:length(freqrange),
%	for ch1=1:length(chns)-1, % channel combination 전체 비교
%		for ch2=ch1+1:length(chns),
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
%% 			% 어레이가 생성되는 시점에서 즉시 대조 -> 이후에 전체 작업 후 대조 추가 수행
%% 			if	(PLV(f,:,ch1,ch2)	~=	PLVre(f,:,ch1,ch2)) | ...	%double(1,1000) 배열
%% 				(PLS(f,:,ch1,ch2)	~=	PLSre(f,:,ch1,ch2)),		%double 값
%% 				fprintf('PLV-Diff(NOM) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch1,ch2), PLVre(f,1,ch1,ch2) );
%% 			end
%% 			if 	(PLV(f,:,ch2,ch1)	~=	PLVre(f,:,ch2,ch1)) | ...
%% 				(PLS(f,:,ch2,ch1)	~=	PLSre(f,:,ch2,ch1)),
%% 				fprintf('PLV-Diff(INV) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch2,ch1), PLVre(f,1,ch2,ch1) );
%% 			end
%		end;
%	end;
%end;
% for f=1:length(freqrange),				% 전체 array 작성 후 all 비교 수행: 위의 중간과정 비교와 달리 overwrite 여부 검토
% 	for ch1=1:length(chns)-1,			% channel combination 전체 비교
% 		for ch2=ch1+1:length(chns),
% 			if	(PLV(f,:,ch1,ch2)	~=	PLVre(f,:,ch1,ch2)) | ...	%double(1,1000) 배열
% 				(PLS(f,:,ch1,ch2)	~=	PLSre(f,:,ch1,ch2)),		%double 값
% 				fprintf('PLV-Diff(NOM) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch1,ch2), PLVre(f,1,ch1,ch2) );
% 			end
% 			if 	(PLV(f,:,ch2,ch1)	~=	PLVre(f,:,ch2,ch1)) | ...
% 				(PLS(f,:,ch2,ch1)	~=	PLSre(f,:,ch2,ch1)),
% 				fprintf('PLV-Diff(INV) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch2,ch1), PLVre(f,1,ch2,ch1) );
% 			end
% 		end;
% 	end;
% end;

%%
% [TFi,TFP,TFA]=tf2tfi_min(TFS,EPOCHUSE1);
% f=4; t=250:300; 
%%% freqrange=1占쏙옙占싶곤옙 占싣댐옙 占쏙옙, 占쏙옙占쏙옙.
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
