chns		=	[1:size(TF,4)];	% ä�� ���� ���� �� ���� ����. ������ Ȯ���ϰ� ������ Ȯ�� �� ��. �켱�� TF�� ��ü ä���� ����
tlen		=	size(TF,2);		% TF�� ������? c_eegTF ���� TF�� 3���� ���ļ� �ð� ������ (wavelet; ������ �˱� ���� ���ϴ� �� ���Ҽ� ���·� �ٲ۴�.) epochs: ����� ���� trial�� ����. wavelet�� �ϱ��� 
fRange		=	[FR(1):1/2:FR(2)];		%Hz 0.5 ������ �� ��. ��Ÿ

sK			=	10;						%surrogation : K
sI			=	100;					%K�� ���� �������� �ݺ� Ƚ��: iter
%AB=size(TF,3);
%CD=length(chns);
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

PLV			=	zeros(length(fRange),tlen,length(chns),length(chns));
%PLVcell		=	cell(tlen,1);												% PLV�� time ������ ���� �� ����
PLS			=	zeros(length(fRange),tlen,length(chns),length(chns));	% Ʋ�� ����� �ִ� ��
ChCombi		=   cell((length(chns)-1)*length(chns)/2,1);%��꿡 ���ϸ�, sigma k=1~n-1 ( K ) = n(n-1)/2
PLVCh		=	zeros(length(fRange), tlen, length(ChCombi));	%ChCombi���� �����Ͽ� �����ϴ� ����
PLSCh		=	zeros(length(fRange), tlen, length(ChCombi));	%�ݵ�� PLS ��� ������ ��ġ�ؾ� ��.
% TFS=zeros(length(fRange),tlen,size(EPOCHUSE1,1),length(chns),'single');
TF			=	single(TF);

%% local �ӽ� ��������, ���Ŀ����� ���� ���� �ھ� ����
delete(gcp('nocreate'));

%http://vtchl.illinois.edu/node/537
myCluster	=	parcluster('local');
myCluster.NumWorkers	=	40;				% 'Modified' property now TRUE
saveProfile(myCluster);						% 'local' profile now updated,
											% 'Modified' property now FALSE
POOL		=	parpool('local', 20);		% �ִ� 48 core ���� ���.
%POOL		=	parpool('local');			% ���� �ӽ��� �ִ� core�� ����Ʈ ������.
%matlabpool open 4;
	fprintf('Pooling : the parallel worker''s setup completed. '); toc;
	%!����: parent ���� ȣ�������� tic�� �����Ѵٴ� �����Ͽ�, toc ��� ��û��.

%%-------------------------------------------------------------------------------
	tic; fprintf('Standby : %s''s COH of Channel Combination:%d*%d\n',	...
		WORKNAME, length(chns), length(chns));

	index						=	1;				%ChCombi�� ����ϱ� ���� ����
	for ch1=1:length(chns)-1,
		for ch2=ch1+1:length(chns),
			ChCombi{index}		=	[ch1, ch2];		%ä���� ������ �����Ͽ� ����
			index				=	index + 1;		%���� ���� ���� ��ġ
		end
	end

%%	���Ŀ��� ����!
	fprintf('Parallel: %s''s COH of FREQ:%5.2f~%5.2f, CHAN:%d*%d\n',	...
		WORKNAME, fRange(1), fRange(end), length(chns), length(chns));

	parfor index = 1:length(ChCombi),				%working local only
		ch1					=	ChCombi{index}(1);
		ch2					=	ChCombi{index}(2);
	%�� '+Unit :'�� spmd���� ��� �鿩���⿡ ���� ���� fprint�� ':'�� ��ġ ����.
	fprintf('+Unit : COH %3dth/%d of FREQ:%5.2f~%5.2f, CHAN:%d~%d\n',	...
			index, length(ChCombi), fRange(1), fRange(end), ch1, ch2);

			%���� tf2coh_min()�� �Ķ���� ���� �ٸ�
%		[plv, pls]			=	tf2coh_min2_AmH_mex(Local{index}, TF, sK, sI);
		[plv, pls]			=	tf2coh_min2_AmH(ChCombi{index}, TF, sK, sI);

%		for f=1:length(fRange),
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

		for f=1:length(fRange),
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
%%% fRange=1���Ͱ� �ƴ� ��, ����.
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
% �ִ�. figure: n= tril(m);contour(n');colorbar;
