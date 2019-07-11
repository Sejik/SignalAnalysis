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
global		TF;			% int64 type	%parent�� ������ TF�� workspace�� ���� ��

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

	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	%20150709B. WOW ȣ��� ���ο��� �ڵ����� parpool ȣ��Ǵ� �̽�
	%����: WorkerObjWrapper()ȣ��� parpool �� open�Ǿ� ���� ������ ���ο��� �ڵ�
	%		���� ȣ���ϴ� ���� �߰ߵ�. �� ��� ������ handle(POOL)�� ���� ��
	%		����, ���� �ִ� CPU��(��: 20)�� �ƴ�, ���밡���� CPU��ŭ(��: 12)
	%		������ �Ҵ�� ���̾ �����̽��� �Բ� ���ߵ�.
	%�ع�: ������ parpool�� open �����ָ� WOW ���� ���� ����
%	TFwow				=	WorkerObjWrapper(TF);	%���� init���� pool ����!
	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!����: parent ���� ȣ�������� tic�� �����Ѵٴ� �����Ͽ�, toc ��� ��û��.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%nChns		=	[1:size(TF,4)];	% ä�� ���� ���� �� ���� ����. ������ Ȯ���ϰ� ������ Ȯ�� �� ��. �켱�� TF�� ��ü ä���� ����
nChns		=	size(TF,4);		% ä�� ���� ���� �� ���� ����. ������ Ȯ���ϰ� ������ Ȯ�� �� ��. �켱�� TF�� ��ü ä���� ����
nTime		=	size(TF,2);		% TF�� ������? c_eegTF ���� TF�� 3���� ���ļ� �ð� ������ (wavelet; ������ �˱� ���� ���ϴ� �� ���Ҽ� ���·� �ٲ۴�.) epochs: ����� ���� trial�� ����. wavelet�� �ϱ��� 
%Freqs		=	[FR(1):1/2:FR(2)];		%Hz 0.5 ������ �� ��. ��Ÿ

sK			=	10;						%surrogation : K
sI			=	100;					%K�� ���� �������� �ݺ� Ƚ��: iter
%AB=size(TF,3);
%CD=nChns;
% EPOCHUSE1=size(TF,3);
% EPOCHUSE1=ones(AB, CD);
%%%%%%%%%%%%%%%%%%%%%%%%
%  [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER), PLV�� ���ϴ� ��, PLS 0.05�ΰ� ���� ���� ���ϴ� ��
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

nChTOT		=	(nChns-1)*nChns/2;				%�� ���� ä�� ��

PLV			=	zeros(length(Freqs), nTime, nChns,nChns, 'single');
PLS			=	zeros(length(Freqs), nTime, nChns,nChns, 'single');

%TF			=	single(TF);

%===============================================================================
%%	���Ŀ��� ����! <- �� tf2coh()���� ����, �� ä������ ���� ���������� ����ȭ
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
			% K, ITER ���� ���� ������. �� ���� ��� ����.
			% surrogation(��ü ���, �̾� �� ��)�� �ϸ� ������ ����...
			% ���� ����� ���� �ִ�.

			for f		=	1:length(Freqs),
			% �����İ� MDCS�� �׽�Ʈ �غ���
			if pls(f,:) < 0.05,
%			if pls < 0.05,
 				PLV(f,:,ch1,ch2)=	plv(f,:);
 				PLV(f,:,ch2,ch1)=	plv(f,:);
 				PLS(f,:,ch1,ch2)=	pls(f,:);
 				PLS(f,:,ch2,ch1)=	pls(f,:);	% ���ݸ� ������ �Ǵµ� ��ü??
% �Ʒ� ������ �̷��� �׽�Ʈ �غ���. ������ �ȱ���.(�������� ȿ���� ���)
%				PLVsub{f,ch1,ch2}	=	plv;
%				PLSsub{f,ch1,ch2}	=	pls;
%				PLVsub{ch2}		=	plv(f,:);	% cell{}<-double(f, 1:1000) ����
%				PLSsub{ch2}		=	pls(f,:);	% ���ݸ� ������ �Ǵµ� ��ü??
			else
%				PLVsub{ch2}		=	zeros(1, nTime);	%dummy ������ ä��
%				PLSsub{ch2}		=	zeros(1, nTime);	%dummy ������ ä��
			end;					%end if ..

			end;					%end for f=..

		end;

%%		PLVmid{f,ch1}			=	PLVsub;			% PLVsub{ch_dst} = (1,1:1000) ; timezone ���� ������array�� ���� ��������
%%		PLSmid{f,ch1}			=	PLSsub;			% timezone ���� ������array�� ���� ��������
	end;
%end;

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%	clear	TFwow;
%%matlabpool close;
delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%% 20150517A. ������ ������ ���� ������� �籸��
%-> �̷��� �ٽ� �õ��� ����. ������ ���� ���ص� ��.
%for f=1:length(Freqs),
%	for ch1=1:nChns-1, % channel combination ��ü ��
%		for ch2=ch1+1:nChns,
%			%���� ���� loop ������ ó���Ǿ�� ������,, parforƯ������ ����,
%			%ch1, ch2 ���տ��� (<-) ch2, ch1(�ռ� �����, �� index�� ch1 ��!)�� ������.
%%			PLV(f,:,ch1,ch2)	=	PLV(f,:,ch2,ch1);
%%			PLS(f,:,ch1,ch2)	=	PLS(f,:,ch2,ch1);	%���� ������ �̽�
%
%			PLV(f,:,ch1,ch2)	=	PLVmid{f,ch1}{ch2};	%double(1,1000) �迭
%			PLV(f,:,ch2,ch1)	=	PLVmid{f,ch1}{ch2};
%			PLS(f,:,ch1,ch2)	=	PLSmid{f,ch1}{ch2};	%double ��
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
global		TF;			% int64 type	%parent�� ������ TF�� workspace�� ���� ��

%AB=size(TF,3);
%CD=nChns;
% EPOCHUSE1=size(TF,3);
% EPOCHUSE1=ones(AB, CD);
%%%%%%%%%%%%%%%%%%%%%%%%
%  [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER), PLV�� ���ϴ� ��, PLS 0.05�ΰ� ���� ���� ���ϴ� ��
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

%% local �ӽ� ��������, ���Ŀ����� ���� ���� �ھ� ����
delete(gcp('nocreate'));

%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% �ű� profile �ۼ�
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% �ִ� 48 core ���.

	fprintf('Pooling : the parallel worker''s setup completed. '); toc;
	%!����: parent ���� ȣ�������� tic�� �����Ѵٴ� �����Ͽ�, toc ��� ��û��.

%%-------------------------------------------------------------------------------
nChns		=	size(TF,4);		% ä�� ���� ���� �� ���� ����. ������ Ȯ���ϰ� ������ Ȯ�� �� ��. �켱�� TF�� ��ü ä���� ����
nTime		=	size(TF,2);		% TF�� ������? c_eegTF ���� TF�� 3���� ���ļ� �ð� ������ (wavelet; ������ �˱� ���� ���ϴ� �� ���Ҽ� ���·� �ٲ۴�.) epochs: ����� ���� trial�� ����. wavelet�� �ϱ��� 
%Freqs		=	[FR(1):1/2:FR(2)];		%Hz 0.5 ������ �� ��. ��Ÿ

sK			=	10;						%surrogation : K
sI			=	100;					%K�� ���� �������� �ݺ� Ƚ��: iter

PLV			=	zeros(length(Freqs),nTime,nChns,nChns, 'single');
%PLVcell		=	cell(nTime,1);												% PLV�� time ������ ���� �� ����
PLS			=	zeros(length(Freqs),nTime,nChns,nChns, 'single');	% Ʋ�� ����� �ִ� ��
ChCombi		=   cell((nChns-1)*nChns/2,1);%��꿡 ���ϸ�, sigma k=1~n-1 ( K ) = n(n-1)/2
PLVCh		=	zeros(length(Freqs), nTime, length(ChCombi));	%ChCombi���� �����Ͽ� �����ϴ� ����
PLSCh		=	zeros(length(Freqs), nTime, length(ChCombi));	%�ݵ�� PLS ��� ������ ��ġ�ؾ� ��.

%%-------------------------------------------------------------------------------
	tic; fprintf('Standby : %s''s COH of Channel Combination:%d*%d\n',	...
		WORKNAME, nChns, nChns);

	index						=	1;				%ChCombi�� ����ϱ� ���� ����
	for ch1=1:nChns-1,
		for ch2=ch1+1:nChns,
			ChCombi{index}		=	[ch1, ch2];		%ä���� ������ �����Ͽ� ����
			index				=	index + 1;		%���� ���� ���� ��ġ
		end
	end

%%	���Ŀ��� ����!
	fprintf('Parallel: %s''s COH of FREQ:%5.2f~%5.2f, CHAN:%d*%d\n',	...
		WORKNAME, Freqs(1), Freqs(end), nChns, nChns);

	parfor index = 1:length(ChCombi),				%working local only
		ch1					=	ChCombi{index}(1);
		ch2					=	ChCombi{index}(2);
	%�� '+Unit :'�� spmd���� ��� �鿩���⿡ ���� ���� fprint�� ':'�� ��ġ ����.
	fprintf('+Unit : COH %3dth/%d of FREQ:%5.2f~%5.2f, CHAN:%d~%d\n',	...
			index, length(ChCombi), Freqs(1), Freqs(end), ch1, ch2);

			%���� tf2coh_min()�� �Ķ���� ���� �ٸ�
%		[plv, pls]			=	tf2coh_min2_AmH_mex(Local{index}, TF, sK, sI);
		[plv, pls]			=	tf2coh_min2_AmH(ChCombi{index}, TF, sK, sI);

%		for f=1:length(Freqs),
%			if pls(f,:) < 0.05,					%each ch & f, but [all time]
%			PLVCh(:,:,index)	=	plv(:,:);	%single(1,1000) �迭
%			LoPLV(f,:,index)	=	plv(f,:);
%			PLSCh(:,:,index)	=	pls(:,:);	%double ��
%			LoPLS(f,:,index)	=	pls(f,:);
%			end
%		end
		%for f=1 �� if pls( < 0.05 �� �ϰԵǸ� ��������� PLV Ȥ�� PLVCh��
		%������ parfor �� �Ǵ����� ���ϸ� ������ �߻���Ų��.
		%�̴�, plv, pls�� PLV, PLSCh�� �ε��� ����(f, time ��)�� ����������
		%indexing �ϱ� ������ PLVCh�� �ϳ��� �����μ� �ǵ����� ���ϰ�,
		%���� ������ ��޵Ǹ鼭 parfor�� ȥ���� �޴� ������ ����.
		%����, parfor ���ο��� ����ó���ϴ� for �� ����ϴ� �͵� ������ ��.
		%����, parfor ���ο����� for �� for ������ ���� �ε����� ���� ����.
		%�������� �׳� array�� �ٷ� �����ϰ�, ���� �ε��̰� �ǵ��� ������ �� ��
		PLVCh(:,:,index)	=	plv(:,:);	%single(1,1000) �迭
		PLSCh(:,:,index)	=	pls(:,:);	%double ��
	end		%end parfor

%%
%matlabpool close;
delete(POOL);
%%

%%	cell������ ������ �����͵��� ���� 4D ��̿� �籸�� ����.
	fprintf('Clean up: %s''s COH(PLV, PLS) data\n',	WORKNAME);
	for index2=1:length(ChCombi),	%--[
			ch1					=	ChCombi{index2}(1);
			ch2					=	ChCombi{index2}(2);

		for f=1:length(Freqs),
			if PLSCh(f,:,index2) < 0.05,		%each ch & f, but [all time]
%			PLV(f,:,ch1,ch2)	=	PLVCh(f,:,index2);	%single(1,1000) �迭
%			PLV(f,:,ch2,ch1)	=	PLVCh(f,:,index2);	%single(1,1000) �迭
%			PLS(f,:,ch1,ch2)	=	PLSCh(f,:,index2);	%single ��
%			PLS(f,:,ch2,ch1)	=	PLSCh(f,:,index2);	%single ��
			PLV(f,:,ch1,ch2)	=	PLVCh(f,:,index2);	%single(1,1000) �迭
			PLV(f,:,ch2,ch1)	=	PLVCh(f,:,index2);	%single(1,1000) �迭
			PLS(f,:,ch1,ch2)	=	PLSCh(f,:,index2);	%single ��
			PLS(f,:,ch2,ch1)	=	PLSCh(f,:,index2);	%single ��
			end;					%end if ..
		end;					%end for;
	end;	%-]

% [TFi,TFP,TFA]=tf2tfi_min(TFS,EPOCHUSE1);
% f=4; t=250:300; 
%%% Freqs=1���Ͱ� �ƴ� ��, ����.
%%% Timepoint ���� dominantTF�� ���� �� �پ����?TF �̹Ƿ� ó�� TF_origin ���� coh ���Ҷ��� �� strike zone�� timepoint�� �ٲ������?!!

%data(,) == 6��(���� x trial)�� ������(time) x ���ļ���(freq) ���� ���� 2-D �迭
%a == 6�� case �� Ư��������ȣ �����ϴ� strikezone �ش� case
%a == datanumb * trialnumb 
%a = ( datanumb * length(trialname) ) + trialnumb ; %6�� �迭������ ��Ȯ�� index�� ����ϱ� ���� ����
%data(a,1)=mxFreq; %freq. �� peak ��
%data(a,2)=0.00; %ms �������� �ٷ� ��: time �� start ����
%data(a,3)=.700; %ms �������� �ٷ� ��: time �� finish����

%f=((data(a,1)-4)*2+1); t=data(a,2)/0.002+250:data(a,3)/0.002+250;

% strike zone, ���ļ��� ��Ҵµ�, maximum�� ���� ���� time window�� ������ ��, ��� �ʿ��� ���� �ƴ� ���
% ���ļ� ���� ���߾��µ�, ������ ��쿡�� 8-13, ��Ÿ 15-30, ��Ÿ 4-8, 0-700ms ��� ���� (maximum��
% ���������� ���� ������� ���Ѵ�.)
% pacelocking ���� �ִ밪�� �κ��� �ϴ� �� ��! % ������ ���߾� �ذ�. ���� frequency�� �ٲپ��ذ�. hz,
% �ð� ��, �� �� ������ �Ǿ� ���� wavelet�� ���� Pace locking�� ��
% ���� ���Ŀ� ���� �Ѵٸ�, ���͸��� �ϰ� eEEG �ϰ� ���Ŀ� ���� ������ �Ѵ�. �� �� �ٸ� �͵� �ݺ��ϴ� ������� �����Ѵ�.
% (�ʿ��� �κи� ��� �����ϴ� ���)
%t=floor(t); %?�어?�인 data ?�에 timepoint �??�수?�이 ?�니?�서 바꿔

%coh=squeeze(mean(PLV(f,t,:,:),2)); % coh should not be NaN, ���ļ��� ��������, �ð��� �����ϼ��� �ƴ� ����, ä��, ä��
% ������ũ �׸���, ���� ���ʹ� �׸� �׸��⸦ ���� coh��� ������ �����ϴ� ��
% ch17= EOG, ch22=NULL, ���� �κ��� ����.�ڿ��� ����
%coh(22,:)=[];coh(17,:)=[];
%coh(:,22)=[];coh(:,17)=[];

% thr=0.9; %�׸��� �׸��� �ǵ�, �������� plotcloh �׷���. �� �κ� ������ ����� �׸� (0.9�̻��� ����
% �����ش�.) PLV ���� ū ��
% 
% figure;
% topoplot([],'EEG_30chan.ced','electrodes','labels'); colorbar; %EEGLAB��
% ��Ƽ� ���� ���Ѽ� �����ϴ� �� (topoplot�� ������ ����ϴ� ��. EEG_30chan.ced �����ǿ� ���� ���ϵ� �־��
% �Ѵ�.) electrode ��ġ�� ������, �̸��� ��ɵǵ��� �ϴ� function. colorbar�� �Ӹ� ���� �׸��� ��
% plotcoh_jh('EEG_30chan.ced',coh,thr); % �Ӹ��� �׷��ִ� ��. ������ũ�� matlab ����� ���,
% thr�� ������ ���� �� �ִ�.
% �÷��� ������ �����ϸ� �׷��� �׸� �� �ִ�. help plot �ؼ� �׿� ���� ������ ���� Contour plots
% graphics, �� ���� �׸��� �����ϱ�, contourf�� �׸���, colorbar�� �׸� �׸���, tril�� ���� ���� ��
% �ִ�. figure: n= tril(m);contour(n');colorbar;	%-]
