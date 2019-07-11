%% PeakDetecting.m %%
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
dataname={'like', 'dislike'};
trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};
subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27' , 'su28' , 'su29'};

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
% 2015.3.2
% 
% TFe_bl_alpha 0-500ms     maximum      P3, P4, P7, P8
% TFe_bl_beta 0-500ms     maximum      Pz, P3, P4
% TFe_bl_theta 0-500ms    maximum      P3, P4, P7, P8  

% TFi_alpha -400-100ms   maximum     P3, P4, P7, P8, O1, O2
% TFi_alpha -400-100ms  mean     P3, P4, P7, P8, O1, O2

% TFi_bl_beta   0~1000ms    min     P3, P4, P7, P8, O1, O2

freqname={'beta2'};

% ���� freqname�� �ִ� ���ļ� �뿪 �� �˸´� ���ļ� �뿪�� �������ּž� �մϴ�.
alpha1=8:1/2:13;
%alpha2=8:1/2:13;
beta1=13:1/2:30;
beta2=13:1/2:30;
theta=4:1/2:8;

ananame={'TFe_bl','TFi', 'TFi_bl'};

% ���� �� �ڵ忡���� ���ļ� �뿪�� �м��� �ϴ� ���� ū Ʋ�Դϴ�.(alpha1, alpha2, beta1, ...) -> ���� �� �ڵ忡 ���� �޶��� �� ������ �� Header�κ��� ���������� ���ž� �մϴ�.
% ���ļ� �뿪�� ���� Timewindow�� �޶����� ���̶� �� �� ������, ������ ���� Timewindow, �� 5�� �������ݴϴ�.
timelist=cell(1,1);
%timelist{1,1}=[251:501];    % alpha1�� Timewindow. 0ms ~ 500ms
%timelist{2,1}=[51:201];     % alpha2�� Timewindow. -400ms ~ -100ms
%timelist{2,1}=[251:501];    % beta1�� Timewindow. 0ms ~ 500ms
timelist{1,1}=[251:751];    % beta2�� Timewindow. 0ms ~ 1000ms
%timelist{3,1}=[251:501];    % theta�� Timewindow. 0ms ~ 500ms

% ���������� ���ļ� �뿪�� ���� ���� ä���� �޶����� ���̶� �� �� ������, ������ ���� ä�� ���, �� 5�� �������ݴϴ�.
% �м��� ������ ä�ε��� Amplitude �� Latency ���� ���� �����Ͽ� ����� ���� ������� ����˴ϴ�.
chanlist=cell(1,1);
%chanlist{1,1}=[23,24,26,27]; 
%chanlist{2,1}=[23,24,26,27,29,31]; 
%chanlist{2,1}=[24, 25, 26]; 
chanlist{1,1}=[23,24,26,27,29,31];
%chanlist{3,1}=[23,24,26,27]; 

% �� �ڵ�� TFe_bl �� ���� �м��� �����ϹǷ�, ananame�� ���ؼ��� for���� ������ �ʰ� ananumb=1 ��
% �����մϴ�. �� ���� TFi �� TFi_bl�� ���� �ڵ忡���� ananumb�� �׿� �˸°� 2 �� 3���� �����Ͻø� �˴ϴ�.
ananumb=3;

%% ���� �м� �ڵ�
for freqnumb=1:length(freqname)
    % ���� ä�ΰ� timewindow�� ���ļ� �뿪�� ���� �ٲ�� �ǹǷ� chanlist�� timelist ���� integer��
    % freqnumb �Դϴ�.
    chancan=chanlist{freqnumb,1};
    timewindow=timelist{freqnumb,1};
    eval(['freqband=' char(freqname{freqnumb}) ';']);
    freqindex=2*freqband-1;
    
    % Header�� �м� ������ �ٽ� Ȯ���� ���ø�, ���ļ� �뿪���� timewindow�� ���� ä�� �Ӹ��� �ƴ϶�
    % maximum, minimum �� ���� �ִ� ���� Ȯ���� �� �ֽ��ϴ�.
    % �̴� Positive Peak�� ã�� ������ Negative Peak�� ã�� �������� ��Ÿ����, �Ʒ� �ڵ忡�� �м���
    % max�Լ��� �̿�����, min�Լ��� �̿����� calcname�� ������ �ݴϴ�.
    % �̹��� ��� theta(freqnumb=5)�� ���� min �� �̿��ϰ� ������ ���� ��� max�� �̿��ϹǷ�, �Ʒ��� ����
    % �ڵ带 �ۼ��մϴ�. ���� �� �κе� ���������� ����Ͻø� �˴ϴ�.
    if freqnumb==5
        calcname='min';
    else
        calcname='min';
    end
    %%% ���� ������ ������ Header. ���� �� �м��� ���� ������� ������ �ֽø� �˴ϴ�.
    %%% �Ʒ��� �̾����� �κе� �ణ�� ������ �ʿ��ϰ����� �ַ� load �� save ���� �κ��̸� ���� �м��� ����Ǵ� �ڵ尡
    %%% ��κ��Դϴ�.
        
    
    for trialnumb= 1:length(trialname)
        for datanumb= 1:length(dataname)
            for subnumb= 1:length(subname)
                % ������ �ε�
                eval(['load(''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.mat'');']);
                
                
                %% Finding Maximum Frequency(Individual Frequency)
                % ���� �м��Ϸ��� ������ Ÿ��(TFe, TFi, TFi_bl �� �ϳ�)��
                % Potential_Buf�� ����.
                % �� �� �����ִ� ���ļ� ����, timewindow, ä�� ��Ͽ� �����մϴ�.
                eval(['Potential_Buf=' char(ananame{ananumb}) '(freqindex,timewindow,chancan);']);
                
                % SaveFrequency���� Individual Frequency�� ã�� ����� ���� �ϳ�, Max��
                % �� ���� �ְ� Min �� �� ���� �����Ƿ� eval�Լ��� calcname�� ���˴ϴ�.
                eval(['buf= ' calcname '(Potential_Buf, [], 3);']);
                eval(['bufbuf= ' calcname '(buf, [], 2);']);
                eval(['[bufbufbuf1 bufbufbuf2]= ' calcname '(bufbuf);']);

                % Individual Frequency ����.
                % freq�� ���� ���ļ� ��, freq_index�� �� ��.
                % �׷��Ƿ� ������ �ڵ忡�� �̿��ϴ� ���� freq_index ���Դϴ�.
                freq=freqband(bufbufbuf2);
                freq_index=freqindex(bufbufbuf2);
                
                
                %% Select Data by Individual Frequency and Channels of Interest
                % Individual Frequency �� ���� ä�ο� ���� �����͸� �����Ͽ� potential_topo �� ����.
                eval(['potential_topo=double(squeeze(' char(ananame{ananumb}) '(freq_index,:,chancan)));']);
                
                
                %% Find Peak and Save
                % calcname�� ���� Positive Ȥ�� Negative Peak�� ã���ϴ�.
                % �Ʒ� �ڵ�� calname�� max �� �� �����δ� ������ �����ϴ�.
                % [peakBuf_list_max peak_list_time]= max(potential_topo(timewindow,:),[],1);
                eval(['[peakBuf_list_max peak_list_time]= ' calcname '(potential_topo(timewindow,:),[],1);']);

                % ����� �� ä�ε��� ���� ��ճ��ϴ�.
                peak_mean= mean(peakBuf_list_max);
                peak_time= mean(peak_list_time);
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
            eval(['FILENAME=''skk_PlotPeak_' char(ananame{ananumb}) '_MinimumPeakAveraged_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) ''';']);
            cd Peak;
            save(FILENAME, 'Peak_list');
            cd ..;
            clear Peak_list
            
        end
    end
end


 %% SPSS ���̺� ����
 % ���� ��� ������ ���̺��� �����ϴ� �κ��Դϴ�.
 % ���⼭ ������ ����� SPSS �����ų�, �����Բ� excel�� �����帮�� �˴ϴ�.
for freqnumb=1:length(freqname)
    i=1;
    for trialnumb=1:length(trialname)
        for datanumb=1:length(dataname)
            
            cd Peak;
            eval(['load(''skk_PlotPeak_' char(ananame{ananumb}) '_MinimumPeakAveraged_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.mat'');']);
            cd ..;
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
    eval(['FILENAME=''skk_TotalPeak_' char(ananame{ananumb}) '_MinimumPeakAveraged_' char(freqname{freqnumb}) ''';']);
    cd Peak_total
    save(FILENAME, 'Peak_Total', 'Time_Total', 'TimeReal_Total');
    cd ..;
    clear Peak_Total Time_Total TimeReal_Total
end