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
%20150710A. �׽�Ʈ�� ���ϸ� epock2tf()������ SPMD���� parfor�� ������ ����.
%����: ��Ȯ�� �м��� �� �ð��� �����µ�, �Ƹ��� SPMD���� ����� gather�ϴµ�
%		�ð� �� �߰� �޸� �Ҹ� �߻��ϱ� �������� ������.
%%%%%%%%%%%%%%%%%%%%%%%%

%�������: k�� ���� �Ҽ��� ��°�ڸ������� ����� ���
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

%EpChCombi	=   cell((length(nChn)-1)*length(nChn)/2,1);%��꿡 ���ϸ�, sigma k=1~n-1 ( K ) = n(n-1)/2
%EpChCombi	=   cell(nEpoch * nChn,1);				%loop*loop combination
%{
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% local �ӽ� ��������, ���Ŀ����� ���� ���� �ھ� ����
delete(gcp('nocreate'));

%matlabpool open 4;							% lagacy ���
%POOL		=	parpool('local');			% ���� �ӽ��� ���� core�� ����Ʈ ����
%----------
%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% �ű� profile �ۼ�
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% �ִ� 48 core ���.
	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!����: parent ���� ȣ�������� tic�� �����Ѵٴ� �����Ͽ�, toc ��� ��û��.
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
%%	���Ŀ��� ����!
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
%+%�� '+Unit :'�� spmd���� ��� �鿩���⿡ ���� ���� fprint�� ':'�� ��ġ ����.
%+
%+		if EPOchUSE(ep,ch)==0, continue; end;	%calc for only 1 field.
%+
%+		ts						=	squeeze(eEEG(:,ep,ch));	%time series
%+		[tf1,tfa1,tfc1]			=	tfmorlet_min(ts,fsamp,Freqs,m,ki);
%+		TF_Ep	(:,:,ep)		=	tfc1;	%parfor�� ������ ������ ���� ����
%+		TFpEp	(:,:,ep)		=	tf1;	%�ε��������� ���������� �ٸ��� ����!
%+		TF		(:,:,:,ch)		=	TF_Ep;
%+		TF_power(:,:,:,ch)		=	TFpEp;
%+	end	%-]

%===============================================================================
%%	���Ŀ��� ����!
	fprintf('Parallel: %s''s TF of Epoch:%3d, CHAN:%2d\n\n',	...
		WORKNAME, nEpoch, nChn);

%%1.	codistributed variable construction from clinet variable

%%2.	processing local part only. distributed part is touched by lab.
	parfor ch = 1:nChn,				%working local only
%�� '+Unit :'�� spmd���� ��� �鿩���⿡ ���� ���� fprint�� ':'�� ��ġ ����.
		fprintf('+Group: TF-an request %d/%d(%5.2f%%)\n', ch, nChn, ch/nChn*100);

%		if EPOCHUSE(ep,ch)==0, continue; end;	%calc for only 1 field.
		[TF_Ep,TFpEp] = epoch2tf_AmH_epoch(ch, eEEG,Freqs,fsamp,m,ki,EPOCHUSE);
		TF		(:,:,:,ch)		=	TF_Ep;
		TF_power(:,:,:,ch)		=	TFpEp;
	end

%===============================================================================
%%	�׷� ��, �� ��̸� ���� �������� ȣ������ ���� conversion�ؾ� ��.
%	cell������ ������ �����͵��� ���� 4D ��̿� �籸�� ����.
%	fprintf('Clean up: %s''s TF(Time, Freq) data\n',	WORKNAME);

%3.	composite�� client data�� ���� ���� : ��, ������ �͵� composite type ��!

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
%+%		for f=1:length(Freqs),					%���ļ��� ������ ��츸 ����
%+			TF      (:,:,ep,ch)	=	TF_EpCh(:,:,index2);	%single(f,1000) �迭
%+			TF_power(:,:,ep,ch)	=	TFpEpCh(:,:,index2);	%single ��
%+%		end;					%end for;
%+	end	%-]


%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function [TF_Ep,TFpEp]=epoch2tf_AmH_epoch(CH, eEEG,Freqs,fsamp,m,ki,EPOCHUSE) %-[
%this function process parallel operation for Epoch ONLY!!
[tlen,nEpoch,nChn]				=	size(eEEG);

%+Epoch							=	[1:nEpoch];		%epoch list
%TF_Ep		=	zeros(length(Freqs), tlen, nEpoch, 'single');	%EpChCombi���� �����Ͽ� �����ϴ� ����
%TFpEp		=	zeros(length(Freqs), tlen, nEpoch, 'single');	%! �ݵ�� PLS�� ��� ������ ��ġ�ؾ� �� !!!
TF_Ep		=	zeros(length(Freqs), tlen, nEpoch);	%EpChCombi���� �����Ͽ� �����ϴ� ����
TFpEp		=	zeros(length(Freqs), tlen, nEpoch);	%! �ݵ�� PLS�� ��� ������ ��ġ�ؾ� �� !!!

%===============================================================================
%%	���Ŀ��� ����!
%	fprintf('Parallel: TF of Epoch:%3d on CHAN:%2d\n\n',	nEpoch, CH);

%%1.	codistributed variable construction from clinet variable

%%2.	processing local part only. distributed part is touched by lab.
	parfor ep = 1:nEpoch,				%working local only
%�� '+Unit :'�� spmd���� ��� �鿩���⿡ ���� ���� fprint�� ':'�� ��ġ ����.
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

%	���� ����� ���İ������ ���ÿ� ��Ƽ� ���ϵǹǷ�, �翬�� ��̿� ��ܼ� ��.
%	����, composite type���� �����ǹǷ�, �̸� �ϳ��� array�� �����ؾ� ��.

%===============================================================================
%%	�׷� ��, �� ��̸� ���� �������� ȣ������ ���� conversion�ؾ� ��.
%	cell������ ������ �����͵��� ���� 4D ��̿� �籸�� ����.
%	fprintf('Clean up: TF(Time, Freq) of [Epoch]\n');

%%3.	composite�� client data�� ���� ���� : ��, ������ �͵� composite type ��!
%	for index = 1:size(LoPLV, 3)
%+	TF_Ep						=	gather(CoTF);	%codistributed -> client
%+	TFpEp						=	gather(CoTFp);	%codistributed -> client %-]

