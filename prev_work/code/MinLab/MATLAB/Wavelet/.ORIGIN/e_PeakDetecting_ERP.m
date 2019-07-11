%% PeakDetecting_ERP.m %%
% ���� ������� Peak�� Amplitude�� Latency�� ã�� �ڵ��Դϴ�. 
% Header���� Timewindow, �����ִ� ä�θ� �������ָ� SPSS�� �ֱ� ������ ���̺� ���·� �����Ͱ� ����˴ϴ�.

%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clear;
close all

%% Header %%
% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% channame: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% dataname, trialname: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% subname: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'ExpectedTarget', 'UnexpectedNontarget'};
trialname={'Conv', 'Div'};
subname={'su0001', 'su0002', 'su0003'};

ananame={'ERP'};

% �Ʒ� �κп��� �ʿ��� �κ��� �����Ͻø� �˴ϴ�.
% ���⼭ �����Ͻ� ���� �ִٸ�, ������ ��� ���ļ� ������ ���� �� PeakDetecting �ڵ带 �ϳ��� ������ݴϴ�.
% ��, PeakDetecting_TFi.m, PeakDetecing_TFebl.m �̷� ������...
% �� ����� TFe_bl alpha �뿪������ �м� ä�ΰ� TFi alpha �뿪������ �м� ä�� ����� �޶��� �� �ְ�,
% ������ ���� �ϳ��� ���ؼ� �������� Timewindow �� �м� ä���� �̿��� ���� �ֱ� �����Դϴ�.
% �� ���� ��� �򰥸��� �ʰ� �ϱ� ���� ���� ����� ����� ��ȣ�ϰ� ��õ������, �ڵ� �ϳ��� �� ǥ���ϼŵ� �����մϴ�.
% �� �ڵ��� ���� TFe_bl �� PeakDetecting �ڵ�� �����ϰڽ��ϴ�.
%
% ��, ���� ���� �� ���迡 ���� ���� �м��� �� ���� �ƴϱ� ������, �Ʒ��� �м� Timewindow �� ä�ε��� ���� ���Ƿ� ������
% ���Դϴ�. ���÷μ��� Ȯ���Ͻð�, ���� �м� �ÿ��� �����Ͻñ� �ٶ��ϴ�.

%% �м� ���� %%
% 2013.3.5
% 
% TFe_bl alpha1 0-300ms     maximum      P4, P8, O2
% TFe_bl alpha2 700-1000ms  maximum      P3, Pz, P4, O1, Oz, O2
%  
% TFe_bl beta1 0-300ms     maximum      P3, Pz, P4, O1, Oz, O2
% TFe_bl beta2 700-1000ms  maximum      P3, Pz, P7, CP1, CP5
%  
% TFe_bl theta 0-500ms      minimum     P4, P8, O2

% alpha�� beta�� ��� �� ���ļ� �뿪���� �� ���� ����� �м��� �ϹǷ�, �Ʒ��� ���� alpha1, alpha2,
% beta1, beta2�� �и��Ͽ����ϴ�.
% freqname={'alpha1', 'alpha2', 'beta1', 'beta2', 'theta'};
% 
% % ���� freqname�� �ִ� ���ļ� �뿪 �� �˸´� ���ļ� �뿪�� �������ּž� �մϴ�.
% alpha1=8:1/2:13;
% alpha2=8:1/2:13;
% beta1=13:1/2:30;
% beta2=13:1/2:30;
% theta=4:1/2:8;
% 
% ananame={'TFe_bl','TFi', 'TFi_bl'};

% ���� �� �ڵ忡���� ���ļ� �뿪�� �м��� �ϴ� ���� ū Ʋ�Դϴ�.(alpha1, alpha2, beta1, ...) -> ���� �� �ڵ忡 ���� �޶��� �� ������ �� Header�κ��� ���������� ���ž� �մϴ�.
% ���ļ� �뿪�� ���� Timewindow�� �޶����� ���̶� �� �� ������, ������ ���� Timewindow, �� 5�� �������ݴϴ�.
timelist=cell(1,1);
timelist{1,1}=[401:501];    % ERP�� Timewindow. 300ms ~ 500ms

% ���������� ���ļ� �뿪�� ���� ���� ä���� �޶����� ���̶� �� �� ������, ������ ���� ä�� ���, �� 5�� �������ݴϴ�.
% �м��� ������ ä�ε��� Amplitude �� Latency ���� ���� �����Ͽ� ����� ���� ������� ����˴ϴ�.
chanlist=cell(1,1);
chanlist{1,1}=[19, 20, 25]; % ERP: CP1, CP2, Pz

% �� �ڵ�� TFe_bl �� ���� �м��� �����ϹǷ�, ananame�� ���ؼ��� for���� ������ �ʰ� ananumb=1 ��
% �����մϴ�. �� ���� TFi �� TFi_bl�� ���� �ڵ忡���� ananumb�� �׿� �˸°� 2 �� 3���� �����Ͻø� �˴ϴ�.

%% ���� �м� �ڵ�
for ananumb=1:length(ananame)
    % ���� ä�ΰ� timewindow�� ���ļ� �뿪�� ���� �ٲ�� �ǹǷ� chanlist�� timelist ���� integer��
    % freqnumb �Դϴ�.
    chancan=chanlist{ananumb,1};
    timewindow=timelist{ananumb,1};
%     eval(['freqband=' char(freqname{freqnumb}) ';']);
%     freqindex=2*freqband-1;
    
%     % Header�� �м� ������ �ٽ� Ȯ���� ���ø�, ���ļ� �뿪���� timewindow�� ���� ä�� �Ӹ��� �ƴ϶�
%     % maximum, minimum �� ���� �ִ� ���� Ȯ���� �� �ֽ��ϴ�.
%     % �̴� Positive Peak�� ã�� ������ Negative Peak�� ã�� �������� ��Ÿ����, �Ʒ� �ڵ忡�� �м���
%     % max�Լ��� �̿�����, min�Լ��� �̿����� calcname�� ������ �ݴϴ�.
%     % �̹��� ��� theta(freqnumb=5)�� ���� min �� �̿��ϰ� ������ ���� ��� max�� �̿��ϹǷ�, �Ʒ��� ����
%     % �ڵ带 �ۼ��մϴ�. ���� �� �κе� ���������� ����Ͻø� �˴ϴ�.
%     if freqnumb==5
%         calcname='min';
%     else
%         calcname='max';
%     end
    calcname='max';
    
%     %%% ���� ������ ������ Header. ���� �� �м��� ���� ������� ������ �ֽø� �˴ϴ�.
%     %%% �Ʒ��� �̾����� �κе� �ణ�� ������ �ʿ��ϰ����� �ַ� load �� save ���� �κ��̸� ���� �м��� ����Ǵ� �ڵ尡
%     %%% ��κ��Դϴ�.
        
    
    for trialnumb= 1:length(trialname)
        for datanumb= 1:length(dataname)
            for subnumb= 1:length(subname)
                % ������ �ε�
                eval(['load(''exp_new_' char(subname{subnumb}) '_Average_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.mat'');']);
               
                
                %% Finding Maximum Frequency(Individual Frequency)
                % ���� �м��Ϸ��� ������ Ÿ��(TFe, TFi, TFi_bl �� �ϳ�)��
                % Potential_Buf�� ����.
                % �� �� �����ִ� ���ļ� ����, timewindow, ä�� ��Ͽ� �����մϴ�.
                
                Potential_Buf= ERP_bl(timewindow,chancan);
                
                % SaveFrequency���� Individual Frequency�� ã�� ����� ���� �ϳ�, Max��
                % �� ���� �ְ� Min �� �� ���� �����Ƿ� eval�Լ��� calcname�� ���˴ϴ�.
                
                eval(['[buf1 buf2] = ' calcname '(Potential_Buf);']);
                
                
                
                %% Find Peak and Save
                % calcname�� ���� Positive Ȥ�� Negative Peak�� ã���ϴ�.
                % �Ʒ� �ڵ�� calname�� max �� �� �����δ� ������ �����ϴ�.
                % [peakBuf_list_max peak_list_time]= max(potential_topo(timewindow,:),[],1);
                

                % ����� �� ä�ε��� ���� ��ճ��ϴ�.
                peak_mean= mean(buf1);
                peak_time= mean(buf2);
                peak_time= peak_time + timewindow(1) -1;    % ����� peak_time�� �츮�� ������ timewindow�� �������� �� ��° ������ ����Ʈ���� ����� ���̹Ƿ�, ��ü �����͸� �������δ� �� ��° ������ ����Ʈ���� �ٽ� �����մϴ�.
                                                            % ���⼭ �����Ͻ� ����,���������� ����Ǵ� Latency ���� ������ ����Ʈ ��� ��, �� ������ �ð�(ms)�� �ƴϱ� ������, SPSS�� �ֱ� ���� ����� �ٽ� ���ְų�, �ð����� ��ȯ���ִ� �ڵ带 �����ž� �մϴ�.
                                                            % ex) peak_time_ms = peak_time*2 - 502;
                
                Peak_list(subnumb,1)= peak_mean;
                Peak_list(subnumb,2)= peak_time;
                % Peak_list(subnumb,3)= peak_time_ms;   % �ð�(ms)������ ��ȯ�� Latency �����.
                
                clear ERP_filt_bl TFe_bl TFi MaxTime MaxValue Max_All Max_Chan Max_Peak list1 list2 peakBuf_list peakBuf_list_max peak_mean peak_time Potential_Buf potential_topo
                close all
                
            end
            % ���Ǻ� ������ �������� �����͸� �����մϴ�.
            % ���������, ���������� ����ϴ� ���̺��� �ƴմϴ�.
            eval(['FILENAME=''exp_new_PlotPeak_' char(ananame{ananumb}) '_MaximumPeakAveraged_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) ''';']);
            save(FILENAME, 'Peak_list');
            clear Peak_list
            
        end
    end
end


 %% SPSS ���̺� ����
 % ���� ��� ������ ���̺��� �����ϴ� �κ��Դϴ�.
 % ���⼭ ������ ����� SPSS �����ų�, �����Բ� excel�� �����帮�� �˴ϴ�.
for ananumb=1:length(ananame)
    i=1;
    for trialnumb=1:length(trialname)
        for datanumb=1:length(dataname)
            eval(['load(''exp_new_PlotPeak_' char(ananame{ananumb}) '_MaximumPeakAveraged_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.mat'');']);
            Peak_Total(:,i)=Peak_list(:,1);
            Time_Total(:,i)=Peak_list(:,2);
            % ���� Time_Total�� Ÿ������Ʈ �� ������Դϴ�. �ð�(ms)������ �����Ͻ÷��� 152���� Peak_list(subnumb,3) �κ��� Ȱ��ȭ�� ��, ����(179��)�� �ڸ�Ʈ ó���Ͻð�, �Ʒ���(180��)�� �߰� �Ͻø� �˴ϴ�.
            % Time_Total(:,i)=Peak_list(:,3);
            i=i+1;
        end
    end
    
    % Time_Total�� Datapoint, TimeReal_Total�� ���� Latency�� �Դϴ�.
    % Sampling Rate�� Start Point�� ���� ������ �����ϼž� �մϴ�.
    TimeReal_Total=Time_Total*2-502;
    
    % ���� ��� ����
    % �����͸��� TotalPeak�� �����մϴ�.
    eval(['FILENAME=''exp_new_TotalPeak_' char(ananame{ananumb}) '_MaximumPeakAveraged' ''';']);
    save(FILENAME, 'Peak_Total', 'Time_Total', 'TimeReal_Total');
    clear Peak_Total Time_Total TimeReal_Total
end