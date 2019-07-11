%% SaveFrequency.m %%
% �ΰ����� �ڵ� �Դϴ�.
% Analyzer���� ���ļ��� ���� topo�� ���ϱ� ���� �����͸� �����ϴ� ������ �ִ� �ڵ��,
% �������� �� ���ǿ� ���� �� ���ļ� �뿪���� ���� activation�� ū ���ļ�(Individual Frequency)�� ã��, 
% ��� ä�ο��� �� ���ļ������� �����͸��� dat���Ϸ� export�ϴ� ������ ��� �ֽ��ϴ�.
% export�� �����͸� Analyzer�� �ٽ� import�ϴ� ����� Word������ �����Ͻø� �˴ϴ�.
% ���� ���ļ� topo�� matlab���� �׸��ô°� ���Ͻôٸ� �� �ڵ带 �м��� ���� �����ŵ� �˴ϴٸ� 
% Individual Frequency�� ã�� �κ��� �����Ͻñ� �ٶ��ϴ�.

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

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6'};
dataname={'dislike'};
trialname={'Fav_USA'};
subname={'su102'};

% SaveFrequency�� Header�� �߰��� �κ�����, eval�Լ��� ���� �� �ʿ��� �� ���ļ��뿪�� ������ �Է��صξ���,
% ���� �� �κп����� ���� ������ ���� �ִ� Ư�� ä���� �������� �ʾұ� ������, 17���� 22�� ä���� ������ ��� ä����
% Individual Frequency�� ã�� ���� ��� �����մϴ�.(chanlist)
%
% ananame�� wavelet����� ������ �� ���ļ� ������ 3����. ������ ���ؼ� Individual Frequency�� ���� ��
% �Դϴ�.
%
% timelist�� Individual Frequency�� ã�� �ð�����(timewindow)�� ���ļ� ������ 3������ ���� �ٸ���
% ������ �ֱ� ���� ���� ���� �������� �� �Դϴ�.(TFe�� �ڱ� ��, TFi/TFi_bl�� �ڱ� ��)
freqname={'theta'};

%alpha = 8:1/2:13;
%beta  = 13:1/2:30;
theta = 4:1/2:8;

%chanlist=[1:16, 18:21, 23:32];
chanlist=[1:11];

ananame={'TFe_bl'};


timelist=cell(1,1);
timelist{1,1}=[251:501];    % TFe_bl�� Timewindow. 0ms ~ 500ms
%timelist{2,1}=[51:201];     % TFi�� Timewindow. -400ms ~ -100ms
%timelist{3,1}=[51:201];     % TFi_bl�� Timewindow. -400ms ~ -100ms


for ananumb=1:length(ananame)
    % ananame, �� ���ļ� ������ Ÿ�Կ� ���� timewindow�� �ٸ��� �����մϴ�.
    % �Ʒ��� �ڵ带 �ٸ� for�� ������ �̵��ϰ� ananumb�� �� for���� �´� ����(ex: datanumb, trialnumb, freqnumb, ...)
    % ������ �����ϸ� ���ļ� ������ Ÿ���� �ƴ� ���� �����̳� ���ļ� ������ ���� timewindow�� �ٲ� �� �ֽ��ϴ�.
    timewindow=timelist{ananumb,1};
    
    for datanumb=1:length(dataname)
        for trialnumb=1:length(trialname)
            
            for freqnumb=1:length(freqname)
                % ���� �м��Ϸ��� ���ļ� �뿪�� �����մϴ�.(alpha, beta, theta �� �ϳ�)
                % �츮�� �м��Ϸ��� ���ļ��� 1Hz ���� 0.5������ 50Hz ���� ������,
                % Variable���� �׷��� ���� ���� 1��, 2��, 3��, ... , 99����� ����Ǿ� �����Ƿ�,
                % ���ļ����� ���� Variable������ ���° �࿡ �ִ��� freqindex�� �������ݴϴ�.
                % (���ļ� �����ʹ� 3���� �������̹Ƿ� ������ ������ '��'�� �ƴ�����, ������ ������ �ֽñ� �ٶ��ϴ�.)
                eval(['freqband=' char(freqname{freqnumb}) ';']);
                freqindex=2*freqband-1; % ex) freqband: 1Hz = freqindex: 1�� / freqband: 1.5 Hz = freqindex: 2�� / freqband: 2 Hz = freqindex: 3��
                
                for subnumb=1:length(subname)
                    %% ������ �ε�
                    eval(['load(''Phase_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.mat'');']);
                    
                    
                    %% Finding Maximum Frequency(Individual Frequency)
                    % ���� �м��Ϸ��� ������ Ÿ��(TFe, TFi, TFi_bl �� �ϳ�)��
                    % Potential_Buf�� ����.
                    % �� �� �����ִ� ���ļ� ����, timewindow, ä�� ��Ͽ� �����մϴ�.
                    eval(['Potential_Buf=' char(ananame{ananumb}) '(freqindex,timewindow,chanlist);']);
                    
                    % activation�� ���� ū ���ļ�, �� Individual Frequency�� ã�Ƽ�, freq�� ����.
                    % freq�� ���� ���ļ� ��, freq_index�� �� ��.
                    % �׷��Ƿ� ������ �ڵ忡�� �̿��ϴ� ���� freq_index ���Դϴ�.
                    buf=max(Potential_Buf, [], 3);
                    bufbuf=max(buf, [], 2);
                    [bufbufbuf1 bufbufbuf2] =max(bufbuf);
                    
                    
                                        
                    freq=freqband(bufbufbuf2);
                    freq_index=freqindex(bufbufbuf2);
                    
                    
                    %% Select Data For Frequency
                    % Individual Frequency�� �����͸� �����Ͽ� potential_topo �� ����.
                    eval(['potential_topo=double(squeeze(' char(ananame{ananumb}) '(freq_index,:,:)));']);
                    
                    
                    %% Save Data
                    % potential_topo ��� variable�� ����� �����͸� dat���Ϸ� export.
                    % ���⼭�� 'FrequencyData'��� ������ �ϳ� ���� ����� �ְ� �� �ȿ� dat���ϵ���
                    % �����Ͽ����ϴ�.
                    % cd �� current directory�� �̵��ϴ� �Լ�. �� �̵��� �ϰ� ������ ����������
                    % �ʱ� ������ ������ ���� ����� �����ž� �մϴ�.
                    % ..�� ���� ������ �̵�(���⼭�� ����ġ��)
                    cd FrequencyData
                    
                    fname=['SKK_Phase_' char(ananame{ananumb}) '_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.dat'];
                    save(fname, 'potential_topo', '-ascii');
                    
                    cd ..
                    
                    % ��� ������ ������ dat������ ���������� �̿��ϴ� ���ϵ��� �ƴմϴ�. ������ �� ���� �����͸���
                    % ������ ���̱� �����Դϴ�.
                    % �츮�� �м��� ���� ������ ã������ ���̹Ƿ�, �Ʒ��� topo_list���ٰ� �� �����ڵ���
                    % �����͸� ��� �����ϰ�, �̸� Grand Average �� �����͸� topo�� �׷��� ������
                    % Ȯ���� ���Դϴ�.
                    % ������ �������� �����Ͱ� �ʿ��� ��쵵 �����Ƿ� ������ ������ ���� �� �Դϴ�.
                    topo_list(subnumb,:,:)=potential_topo;
                    
                    clear Potential_Buf buf bufbuf bufbufbuf1 bufbufbuf2 freq freq_index potential_topo
                    
                end
                % for���� ��� ���ұ� ������ Ư�� ���� ����, ���ļ� ������ ���� ��� �����ڵ��� �����Ͱ�
                % topo_list�� ����Ǿ���, �̸� ��ճ��ϴ�. 
                % �� �������� �����Ϳ����� 17���� 22�� ä���� ���� NaN���� �������־�������, �׷��� �� ���
                % Analyzer������ ������ ���� ������ ���⼭�� 0���� �������ݴϴ�.
                topo_GrandAverage=squeeze(mean(topo_list));
                topo_GrandAverage(:,[17 22])=0;
                
                % ���������� FrequencyData������ ����.
                % ���ϸ��� _GrandAverage_�� �����ϴ� ���� ���� ������ �����Ϳ� �ٸ��ϴ�.
                % ���⼭ export �Ǵ� dat������ analyzer���� �ҷ��鿩 topo�� �׷��� ���ø� �˴ϴ�.
                cd FrequencyData
                
                fname=['SKK_PLV_GrandAverage_' char(ananame{ananumb}) '_' char(freqname{freqnumb})  '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'];
                save(fname, 'topo_GrandAverage', '-ascii');
                
                cd ..
                
                clear topo_GrandAverage topo_list
                
            end
        end
    end
end
