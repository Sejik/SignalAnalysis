function [TF,TF_power] = epoch2tf_min_AmH(eEEG,Freqs,fsamp,m,ki,EPOCHUSE)	%-[
% function [TF]=epoch2tf_min(eEEG,Freqs,fsamp,m,ki,EPOCHUSE)
%%%%%%%%%%%%%%%%%%%%%%%%
%  TF=epoch2tf(eEEG,Freqs,m,ki) paralleler
% Usage:
%  >> TF=epoch2tf(eEEG,Freqs,fsamp,m,ki)
%
% Inputs:
%   eEEG: epoched EEG data (time points x epochs x channels)
%   FREQS: frequencies of interest
%   FSAMP: sampling frequency
%   M: Wavelet factor 
%   KI: size of wavelet waveform
% Outputs:
%   TF: time frequency complex maps for each epoch
%       [freq x time x epoch x chan]
% 2015/07/06
% by Ahn Min-Hee(AmH::tigoum), Korea Univ. Min-LAB
% email: tigoum@naver.com
%
%20150710A. 테스트에 의하면 epock2tf()에서는 SPMD보다 parfor가 월등히 빠름.
%이유: 정확한 분석을 할 시간은 없었는데, 아마도 SPMD에서 결과를 gather하는데
%		시간 및 추가 메모리 소모가 발생하기 때문으로 추정됨.
%%%%%%%%%%%%%%%%%%%%%%%%

%참고사항: k의 값에 소수점 두째자리까지만 사용할 경우
%example:
%k = 0.123456789;
%k = fix(k*10^2) / 10^2;

global		NUMWORKERS;
global		WORKNAME;

if nargin<2, Freqs			=	[];		end;
if nargin<3, fsamp			=	1000;	end;
if nargin<4, m				=	7;		end;
if nargin<5, ki				=	5;		end;
if nargin<6, EPOCHUSE		=	[];		end;

if isempty(Freqs),   Freqs	=	5:60;	end;			% frequency window level

[tlen,nEpoch,nChn]			=	size(eEEG);

TF			=	zeros(length(Freqs),tlen,nEpoch,nChn);	%double
TF_power	=	zeros(length(Freqs),tlen,nEpoch,nChn);
if isempty(EPOCHUSE), EPOCHUSE	=	ones(nEpoch,nChn);	end;	%fill to 1

%+for c=1:nChn,
%+    idx=[]; ridx=[];
%+    fprintf('ch:%d of %d...\n',c,nChn);
%+    for e=1:nEpoch,
%+        if EPOCHUSE(e,c)==0, continue; end;
%+        x=squeeze(eEEG(:,e,c));
%+        [tf1,tfa1,tfc1]=tfmorlet_min(x,fsamp,Freqs,m,ki);
%+        TF(:,:,e,c)=tfc1;
%+        TF_power(:,:,e,c)=tf1;
%+    end;
%+end;

%EpChCombi	=   cell((length(nChn)-1)*length(nChn)/2,1);%계산에 의하면, sigma k=1~n-1 ( K ) = n(n-1)/2
%EpChCombi	=   cell(nEpoch * nChn,1);				%loop*loop combination
%{
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
	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!주의: parent 에서 호출직전에 tic를 수행한다는 가정하에, toc 출력 요청함.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%}
%%-------------------------------------------------------------------------------
%for f=1:length(fRange),
%	Freqs=fRange(f);
%	TF=epoch2tf(eEEG,Freqs,fsamp,m,ki,EPOCHUSE1); %complex
%	TFS(f,:,:,:)=TF;
	tic; fprintf(['\nStandby : %s''s TF(Time, Freq) of Epoch*Ch Combination:' ...
				'%d*%d\n'],	WORKNAME, nEpoch, nChn);

%===============================================================================
%%	병렬연산 개시!
%+%%1.	codistributed variable construction from clinet variable	%-[
%+	index						=	1;
%+	for e=1:nEpoch,
%+		for c=1:nChn,
%+			EpChCombi{index}	=	[e, c];
%+			index				=	index + 1;
%+		end
%+	end
%+
%+%%2.	processing local part only. distributed part is touched by lab.
%+	parfor idx = 1:length(EpChCombi),	%working local only
%+		ep						=	EpChCombi{idx}(1);
%+		ch						=	EpChCombi{idx}(2);
%+
%+		fprintf('+Unit : TF-analysis %d/%d(%5.2f%%) of Ep*Ch:%d*%d\n',	...
%+				idx, length(EpChCombi), idx / length(EpChCombi) * 100,	idx,ch);
%+%위 '+Unit :'은 spmd의한 출력 들여쓰기에 맞춰 상위 fprint와 ':'의 일치 위함.
%+
%+		if EPOchUSE(ep,ch)==0, continue; end;	%calc for only 1 field.
%+
%+		ts						=	squeeze(eEEG(:,ep,ch));	%time series
%+		[tf1,tfa1,tfc1]			=	tfmorlet_min(ts,fsamp,Freqs,m,ki);
%+		TF_Ep	(:,:,ep)		=	tfc1;	%parfor가 변수의 유형을 결정 못함
%+		TFpEp	(:,:,ep)		=	tf1;	%인덱스변수가 루프변수와 다르기 때문!
%+		TF		(:,:,:,ch)		=	TF_Ep;
%+		TF_power(:,:,:,ch)		=	TFpEp;
%+	end	%-]

%===============================================================================
%%	병렬연산 개시!
	fprintf('Parallel: %s''s TF of Epoch:%3d, CHAN:%2d\n\n',	...
		WORKNAME, nEpoch, nChn);

%%1.	codistributed variable construction from clinet variable

%%2.	processing local part only. distributed part is touched by lab.
	parfor ch = 1:nChn,				%working local only
%위 '+Unit :'은 spmd의한 출력 들여쓰기에 맞춰 상위 fprint와 ':'의 일치 위함.
		fprintf('+Group: TF-an request %d/%d(%5.2f%%)\n', ch, nChn, ch/nChn*100);

%		if EPOCHUSE(ep,ch)==0, continue; end;	%calc for only 1 field.
		[TF_Ep,TFpEp] = epoch2tf_AmH_epoch(ch, eEEG,Freqs,fsamp,m,ki,EPOCHUSE);
		TF		(:,:,:,ch)		=	TF_Ep;
		TF_power(:,:,:,ch)		=	TFpEp;
	end

%===============================================================================
%%	그런 후, 이 어레이를 기존 버전과의 호관성을 위해 conversion해야 함.
%	cell단위로 저장한 데이터들을 기존 4D 어레이에 재구성 수행.
%	fprintf('Clean up: %s''s TF(Time, Freq) data\n',	WORKNAME);

%3.	composite을 client data로 갖고 오기 : 단, 가지고 와도 composite type 임!

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%matlabpool close;
%delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%+	for index2=1:length(EpChCombi),
%+			ep					=	EpChCombi{index2}(1);
%+			ch					=	EpChCombi{index2}(2);
%+	fprintf('Collapse: storing TF %d/%d(%5.2f%%) of Epoch:%3d, CHAN:%2d\n', ...
%+			index2, length(EpChCombi), index2 / length(EpChCombi) * 100, ep, ch);
%+
%+%		for f=1:length(Freqs),					%주파수별 유의한 경우만 저장
%+			TF      (:,:,ep,ch)	=	TF_EpCh(:,:,index2);	%single(f,1000) 배열
%+			TF_power(:,:,ep,ch)	=	TFpEpCh(:,:,index2);	%single 값
%+%		end;					%end for;
%+	end	%-]


%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function [TF_Ep,TFpEp]=epoch2tf_AmH_epoch(CH, eEEG,Freqs,fsamp,m,ki,EPOCHUSE) %-[
%this function process parallel operation for Epoch ONLY!!
[tlen,nEpoch,nChn]				=	size(eEEG);

%+Epoch							=	[1:nEpoch];		%epoch list
%TF_Ep		=	zeros(length(Freqs), tlen, nEpoch, 'single');	%EpChCombi순서 대응하여 저장하는 구조
%TFpEp		=	zeros(length(Freqs), tlen, nEpoch, 'single');	%! 반드시 PLS의 어레이 구조와 일치해야 함 !!!
TF_Ep		=	zeros(length(Freqs), tlen, nEpoch);	%EpChCombi순서 대응하여 저장하는 구조
TFpEp		=	zeros(length(Freqs), tlen, nEpoch);	%! 반드시 PLS의 어레이 구조와 일치해야 함 !!!

%===============================================================================
%%	병렬연산 개시!
%	fprintf('Parallel: TF of Epoch:%3d on CHAN:%2d\n\n',	nEpoch, CH);

%%1.	codistributed variable construction from clinet variable

%%2.	processing local part only. distributed part is touched by lab.
	parfor ep = 1:nEpoch,				%working local only
%위 '+Unit :'은 spmd의한 출력 들여쓰기에 맞춰 상위 fprint와 ':'의 일치 위함.
%		fprintf('+Unit : TF-analysis %d/%d(%5.2f%%) of Ep*Ch:%d*%d\n',	...
%				ep, nEpoch, ep / nEpoch * 100,	ep,CH);

		if EPOCHUSE(ep,CH)==0, continue; end;	%calc for only 1 field.
%		[plv, pls]				=	tf2coh_min2_mIn(Local{index}, TF, sK, sI);
		ts						=	squeeze(eEEG(:,ep,CH));	%time series
		[tf1,tfa1,tfc1]			=	tfmorlet_min(ts,fsamp,Freqs,m,ki);
		TF_Ep(:,:,ep)			=	tfc1;
		TFpEp(:,:,ep)			=	tf1;
	end

%%3.	local -> codist conversion

%	수행 결과는 병렬결과들을 동시에 담아서 리턴되므로, 당연히 어레이에 담겨서 옴.
%	또한, composite type으로 구성되므로, 이를 하나의 array로 구성해야 함.

%===============================================================================
%%	그런 후, 이 어레이를 기존 버전과의 호관성을 위해 conversion해야 함.
%	cell단위로 저장한 데이터들을 기존 4D 어레이에 재구성 수행.
%	fprintf('Clean up: TF(Time, Freq) of [Epoch]\n');

%%3.	composite을 client data로 갖고 오기 : 단, 가지고 와도 composite type 임!
%	for index = 1:size(LoPLV, 3)
%+	TF_Ep						=	gather(CoTF);	%codistributed -> client
%+	TFpEp						=	gather(CoTFp);	%codistributed -> client %-]

