chns=[1:32]; % ä�� ���� ���� �� ���� ����. ������ Ȯ���ϰ� ������ Ȯ�� �� �� 
freqrange=[13:1/2:30];   %Hz ��Ÿ �뿪�� �� ��, 0.5 ������ �� �� ���� 8-12
tlen=size(TF,2); % TF�� ������? c_eegTF ���� TF�� 3���� ���ļ� �ð� ������ (wavelet; ������ �˱� ���� ���ϴ� �� ���Ҽ� ���·� �ٲ۴�.) epochs: ����� ���� trial�� ����. wavelet�� �ϱ��� 
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

PLV=zeros(length(freqrange),tlen,length(chns),length(chns));
PLS=zeros(length(freqrange),tlen,length(chns),length(chns)); % Ʋ�� ����� �ִ� ��
% TFS=zeros(length(freqrange),tlen,size(EPOCHUSE1,1),length(chns),'single');
for f=1:length(freqrange),
    freqs=freqrange(f);
    % TF=epoch2tf(eEEG,freqs,fsamp,m,ki,EPOCHUSE1); %complex
    TF=single(TF);
%    TFS(f,:,:,:)=TF;   
    for ch1=1:length(chns), % channel combination ��ü ��
        fprintf('COH of FREQ:%f, CH1:%d..\n',freqrange(f),ch1);
        for ch2=ch1+1:length(chns),
            %eid=find(EPOCHUSE1(:,ch1)>0 & EPOCHUSE1(:,ch2)>0);
            [plv, pls]=tf2coh_min(TF(f,:,:,ch1),TF(f,:,:,ch2),10,100); % K, ITER ���� ���� ������ �� ���� ����� ����, surrogation(��ü ���, �̾� �� ��)�� �ϸ� ������ ����, ���� ����� ���� �ִ�.
            % �����İ� MDCS�� �׽�Ʈ �غ���
            if pls<0.05,
            PLV(f,:,ch1,ch2)=plv;
            PLV(f,:,ch2,ch1)=plv;
            PLS(f,:,ch1,ch2)=pls;
            PLS(f,:,ch2,ch1)=pls; % ���ݸ� ������ �ȴ� �� ��ü�� �ִ� �ǰ�??
            end;
        end;
    end;
end;

% [TFi,TFP,TFA]=tf2tfi_min(TFS,EPOCHUSE1);
% f=4; t=250:300; 
%%% freqrange=1���Ͱ� �ƴ� ��, ����.
%%% Timepoint ���� dominantTF�� ���� �� �پ����?TF �̹Ƿ� ó�� TF_origin ���� coh ���Ҷ��� �� strike zone�� timepoint�� �ٲ������?!!
f=((data(a,1)-13)*2+1); t=data(a,2)/0.002+250:data(a,3)/0.002+250; % strike zone, ���ļ��� ��Ҵµ�, maximum�� ���� ���� time window�� ������ ��, ��� �ʿ��� ���� �ƴ� ���
% ���ļ� ���� ���߾��µ�, ������ ��쿡�� 8-13, ��Ÿ 15-30, ��Ÿ 4-8, 0-700ms ��� ���� (maximum��
% ���������� ���� ������� ���Ѵ�.)
% pacelocking ���� �ִ밪�� �κ��� �ϴ� �� ��! % ������ ���߾� �ذ�. ���� frequency�� �ٲپ��ذ�. hz,
% �ð� ��, �� �� ������ �Ǿ� ���� wavelet�� ���� Pace locking�� ��
% ���� ���Ŀ� ���� �Ѵٸ�, ���͸��� �ϰ� eEEG �ϰ� ���Ŀ� ���� ������ �Ѵ�. �� �� �ٸ� �͵� �ݺ��ϴ� ������� �����Ѵ�.
% (�ʿ��� �κи� ��� �����ϴ� ���)
t=floor(t); %?�어?�인 data ?�에 timepoint �??�수?�이 ?�니?�서 바꿔
coh=squeeze(mean(PLV(f,t,:,:),2)); % coh should not be NaN, ���ļ��� ��������, �ð��� �����ϼ��� �ƴ� ����, ä��, ä��
% ������ũ �׸���, ���� ���ʹ� �׸� �׸��⸦ ���� coh��� ������ �����ϴ� ��
% ch17= EOG, ch22=NULL, ���� �κ��� ����.�ڿ��� ����
coh(22,:)=[];coh(17,:)=[];
coh(:,22)=[];coh(:,17)=[];

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