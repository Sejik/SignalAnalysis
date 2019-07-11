chns		=	[1:size(TF,4)];	% ä�� ���� ���� �� ���� ����. ������ Ȯ���ϰ� ������ Ȯ�� �� ��. �켱�� TF�� ��ü ä���� ����
tlen		=	size(TF,2);		% TF�� ������? c_eegTF ���� TF�� 3���� ���ļ� �ð� ������ (wavelet; ������ �˱� ���� ���ϴ� �� ���Ҽ� ���·� �ٲ۴�.) epochs: ����� ���� trial�� ����. wavelet�� �ϱ��� 
freqrange	=	[FR(1):1/2:FR(2)];		%Hz 0.5 ������ �� ��. ��Ÿ
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

PLV			=	zeros(length(freqrange),tlen,length(chns),length(chns));
PLS			=	zeros(length(freqrange),tlen,length(chns),length(chns)); % Ʋ�� ����� �ִ� ��
PLVmid		=	cell(length(freqrange), length(chns));	%�� Ÿ�Ա���: ch2 * plv�� ����
PLSmid		=	cell(length(freqrange), length(chns));
%PLVsub		=	cell(length(chns));						%�� Ÿ�Ա���: plv�迭==double(1, 1:1000) ����
%PLSsub		=	cell(length(chns));						%�̷��� �ϸ� len(chns)*len(chns) == 30 x 30 ��Ʈ������ ����...
PLVsub		=	cell(1,length(chns));					%�� Ÿ�Ա���: plv�迭==double(1, 1:1000) ����
PLSsub		=	cell(1,length(chns));					%������ �𸣰�����, ���� �����ϸ� �ȵǼ�, 1������ ���� ����
% TFS=zeros(length(freqrange),tlen,size(EPOCHUSE1,1),length(chns),'single');
TF			=	single(TF);

for f=1:length(freqrange),
%	freqs=freqrange(f);
%	TF=epoch2tf(eEEG,freqs,fsamp,m,ki,EPOCHUSE1); %complex
%	TFS(f,:,:,:)=TF;   
	for ch1=1:length(chns)-1, % channel combination ��ü ��
		fprintf('%s''s COH of FREQ:%f, | CH1(%d) vs CH2[%d:%d] |\n', WORKNAME, freqrange(f), ch1, ch1+1, length(chns));

		for ch2=ch1+1:length(chns),
			%eid=find(EPOCHUSE1(:,ch1)>0 & EPOCHUSE1(:,ch2)>0);
			[plv, pls]			=	tf2coh_min(TF(f,:,:,ch1), TF(f,:,:,ch2), 10, 100);	% K, ITER ���� ���� ������. �� ���� ����� ����, surrogation(��ü ���, �̾� �� ��)�� �ϸ� ������ ����, ���� ����� ���� �ִ�.
			% �����İ� MDCS�� �׽�Ʈ �غ���
			if pls < 0.05,
 				PLV(f,:,ch1,ch2)=	plv;
 				PLV(f,:,ch2,ch1)=	plv;
 				PLS(f,:,ch1,ch2)=	pls;
 				PLS(f,:,ch2,ch1)=	pls;	% ���ݸ� ������ �Ǵµ� ��ü�� �ִ� �ǰ�??
% �Ʒ� ������ �̷��� �׽�Ʈ �غ���. ������ �ȱ���.(�������� ȿ���� ���)
%				PLVsub{f,ch1,ch2}	=	plv;
%				PLSsub{f,ch1,ch2}	=	pls;
%%				PLVsub{ch2}		=	plv;	% cell{} <- double(1, 1:1000) ����
%%				PLSsub{ch2}		=	pls;	% ���ݸ� ������ �Ǵµ� ��ü�� �ִ� �ǰ�??
			else
%%				PLVsub{ch2}		=	zeros(1, tlen);	%dummy ������ ä��
%%				PLSsub{ch2}		=	0.0;			%dummy ������ ä��
			end;
%%			plv					=	PLVsub{ch2};
%%			pls					=	PLSsub{ch2};
%			save(['x:/PLV_theta' '/skk_phase30/' 'Phase_' 'Fav_USA_dislike_su14' '_ch' num2str(ch1) '~ch' num2str(ch2) '_seq.mat'], 'plv', 'pls', '-v7.3');

%%			�߰� ������ ����
%%				save([fullPATH '\skk_phase31\' 'Phase_' WORKNAME '_seq_f' num2str(freqrange(f)) '_ch' num2str(ch1) '~ch' num2str(ch2) '.mat'], 'channame', 'selchanname', 'plv', 'pls', '-v7.3');

		end;

%%		PLVmid{f,ch1}			=	PLVsub;			% PLVsub{ch_dst} = (1,1:1000) ; timezone ���� ������array�� ���� ��������
%%		PLSmid{f,ch1}			=	PLSsub;			% timezone ���� ������array�� ���� ��������
		
% 		for ch2=ch1+1:length(chns),
% 			if	(PLV(f,:,ch1,ch2)	~=	PLVmid{f,ch1}{ch2}) | ...	%double(1,1000) �迭
% 				(PLS(f,:,ch1,ch2)	~=	PLSmid{f,ch1}{ch2}),		%double ��
% 				fprintf('PLV-Diff(NOM) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch1,ch2), PLVmid{f,ch1}{ch2}(1) );
% 			end
% 
% 			if 	(PLV(f,:,ch2,ch1)	~=	PLVmid{f,ch1}{ch2}) | ...
% 				(PLS(f,:,ch2,ch1)	~=	PLSmid{f,ch1}{ch2}),
% 				fprintf('PLV-Diff(INV) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch2,ch1), PLVmid{f,ch1}{ch2}(1) );
% 			end
% 		end
	end;
	
%%		�߰� ������ ����
%				PLVf			=	PLV(f,:,:,:);
%				PLSf			=	PLS(f,:,:,:);
%				save([fullPATH '\skk_phase31\' 'Phase_' WORKNAME '_seq_f' num2str(freqrange(f)) '.mat'], 'channame', 'selchanname', 'PLVf', 'PLSf', '-v7.3');

end;

%% 20150517A. ������ ������ ���� ������� �籸��
%-> �̷��� �ٽ� �õ��� ����. ������ ���� ���ص� ��.
%PLVre		=	zeros(length(freqrange),tlen,length(chns),length(chns));	%PLV�� reconstruction ����
%PLSre		=	zeros(length(freqrange),tlen,length(chns),length(chns));
%for f=1:length(freqrange),
%	for ch1=1:length(chns)-1, % channel combination ��ü ��
%		for ch2=ch1+1:length(chns),
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
%% 			% ��̰� �����Ǵ� �������� ��� ���� -> ���Ŀ� ��ü �۾� �� ���� �߰� ����
%% 			if	(PLV(f,:,ch1,ch2)	~=	PLVre(f,:,ch1,ch2)) | ...	%double(1,1000) �迭
%% 				(PLS(f,:,ch1,ch2)	~=	PLSre(f,:,ch1,ch2)),		%double ��
%% 				fprintf('PLV-Diff(NOM) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch1,ch2), PLVre(f,1,ch1,ch2) );
%% 			end
%% 			if 	(PLV(f,:,ch2,ch1)	~=	PLVre(f,:,ch2,ch1)) | ...
%% 				(PLS(f,:,ch2,ch1)	~=	PLSre(f,:,ch2,ch1)),
%% 				fprintf('PLV-Diff(INV) found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, PLV(f,1,ch2,ch1), PLVre(f,1,ch2,ch1) );
%% 			end
%		end;
%	end;
%end;
% for f=1:length(freqrange),				% ��ü array �ۼ� �� all �� ����: ���� �߰����� �񱳿� �޸� overwrite ���� ����
% 	for ch1=1:length(chns)-1,			% channel combination ��ü ��
% 		for ch2=ch1+1:length(chns),
% 			if	(PLV(f,:,ch1,ch2)	~=	PLVre(f,:,ch1,ch2)) | ...	%double(1,1000) �迭
% 				(PLS(f,:,ch1,ch2)	~=	PLSre(f,:,ch1,ch2)),		%double ��
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
%%% freqrange=1���Ͱ� �ƴ� ��, ����.
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
