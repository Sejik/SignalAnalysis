%% wavelet_EXP.m %%
% Wavelet �ڵ�. ���迡 ���� Header�κ��� �޶����Ƿ�, wavelet �ڵ带 �� ���躰�� �ϳ��� ����� �νô� ��
% �����ϴ�. 
% �� �ڵ带 �����Ű�� ���ؼ� �Ʒ��� �ٸ� m�ڵ� ���� �ݵ�� ���� ������ �־�� �մϴ�.
%
% epoch2erp_min.m, epoch2tf_min.m, tf2tfi_min.m, tfmorlet_min.m,
% wmorlet_min.m, readKRISSMEG_sev.m, spss_min.m
%
% Wavelet�� ������ �����ʹ� Average �����Ͱ� �ƴ� ��ü epoch�� �ִ� �������̹Ƿ� �� �ڵ忡���� ��ü epoch
% �����͸��� �ٷ�ϴ�.

%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clear;
close all;

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
subname={'su02', 'su04'};

% Wavelet�� Header�� �߰��� �κ�����, �޸� ������ 16ä�ξ� ���� �����ͷ� wavelet�� ������ ������ �߰���
% �κ��Դϴ�. ���� �߶��� �������� ä�� ���� �ٲپ��ٸ� �� �κ��� �ٲپ� �ָ� �˴ϴ�.
chs=[1:16];

for datanumb=1:length(dataname)
    for trialnumb=1:length(trialname)
       
       %% eEEG1
        for subnumb=1:length(subname)
            eval(['load eEEG_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '_1.mat']);
            eEEG= eEEG1;
            clear eEEG1;
            
            % Butterworth Filtering �κ�. �Ϲ������� �����Ͻ� �κ��� ������
            % fsamp�� Sampling Rate�̹Ƿ� �츮 ���� ������ �����Ͱ� �ƴ� MEG ������ ���� ���
            % Sampling Rate�� �޶����Ƿ� ��������� �մϴ�.
            % SKK ���� ������ sampling rate : 500Khz
            fsamp=500;
            [bbb, aaa]=butter(1, [0.5/(1000/2) 30/(1000/2)],'bandpass');
            
            %%% �Ʒ� �κ��� �������� comment ó�� �Ǿ� �ִ� �κ�.. �׳� ����ġ�ŵ� �� �� �մϴ�.%%%
            % baseline correction
            % for x=1:40,
            % channame(1,x)=cellstr(EEG.chanlocs(1,x).labels);
            % end;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % 1~50Hz �� ������ 0.5Hz ������ �м��� ���̹Ƿ� �̸� ������ �ݴϴ�.
            freqs=[1:1/2:50];
            
            % ������ �κо���.
            m=7; % m=7;
            ki=5;
            % bl=zeros(size(id'));bl=single(bl);
            blEEG=eEEG;
            ERP=zeros(size(eEEG,1),size(chs,2));
            ERP_filt=ERP;
            ERP_filt_bl=ERP;
            
            %%% header
            % Baseline Correction �� Timewindow�� �����ϴ� �κ�.
            % �� �κ��� Ȯ���ϼž� �˴ϴ�.
            % ERP�� �ַ� -500 ~ -100ms, Frequency�м��� �ַ� -400 ~ -100ms �� �����մϴ�.
            % ���� ������ �� ���� �����Ͻ� �κ� �����ϴ�.            
            ERP_bltimewin=[1:200];
            TF_bltimewin=[51:200];  % -400~-100ms
            %%%%%%%%%%%%%%%%%%%%%%%%%% ERP analysis
            for ii=1:length(chs);
                ch=chs(ii);
                
                bl(1,:)=squeeze(mean(eEEG([ERP_bltimewin],:,ch),1));
                for yy=1:size(bl),
                    blEEG(:,yy,ch)=squeeze(eEEG(:,yy,ch))-bl(1,yy);
                end;
                
                ERP(:,ch)=squeeze(mean(blEEG(:,:,ch),2));
                ERP_filt(:,ch)=filtfilt(bbb,aaa,ERP(:,ch));
                ERP_filt_bl(:,ch)=ERP_filt(:,ch)-mean(ERP_filt([ERP_bltimewin],ch));
            end;
            
            %%%%%%%%%%% Time-Frequency Analysis
            
            [TF, TF_power]=epoch2tf_min(eEEG,freqs,fsamp,m,ki);
            TF=single(TF);
            [TFi,TFP,TFA]=tf2tfi_min(TF);
            
            % evoked tf (without baseline_correction)
            TFe=zeros([length(freqs) size(ERP)]);
            for ch=1:size(ERP,2),
                [tf1,tfa1,tfc1]=tfmorlet_min(ERP(:,ch),fsamp,freqs,m,ki);
                TFe(:,:,ch)=tf1;
                %                 fnout=['su' num2str2(su) '_cond' num2str(cond) '_trg' num2str(n) '_' channame{1,ch} '.mat'];
                %                 save(fnout,'TFe');
            end;
            
            %%%%%%%%
            %%%%%%%%
            % evoked tf (with baseline_correction)
            TFes_bl=squeeze(mean(TFe(:,TF_bltimewin,:),2));
            TFe_bl=TFe;
            fn=length(freqs);
            chn=size(TFe,3);
            for i=1:chn,
                for f=1:fn,
                    TFe_bl(f,:,i)=TFe(f,:,i)-TFes_bl(f,i);
                end;
            end;
            
            % total tf (with baseline_correction: except alpha band)
            TFis_bl=squeeze(mean(TFi(:,TF_bltimewin,:),2));
            TFi_bl=TFi;
            fn=length(freqs);
            chn=size(TFi,3);
            for i=1:chn,
                for f=1:fn,
                    TFi_bl(f,:,i)=TFi(f,:,i)-TFis_bl(f,i);
                end;
            end;
            %%%%%%%%
            %%%%%%%%
            
            % 1~16�� ä�� wavelet ���� �����͸� ����
            % �����ʹ� 4 ������, ERP_filt_bl, TFi, TFe_bl, TFi_bl �Դϴ�.
            % �� �� ���� wavelet�� ����� ���ļ� �����ʹ� TFi, TFe_bl, TFi_bl �̰�
            % ERP_filt_bl �� ERP ������ �Դϴ�.
            % ���� ���� ������ ������ȴ� �Ͱ� ����, ���⼭�� ERP_filt_bl �����ʹ� ���͸��� �ѹ� �� ��
            % �������̹Ƿ� �м����� ���� �ʰ�, analyzer���� export�� Average �����ͷ� �м��Ͻø� �˴ϴ�.
            cd c;
            eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_1'';']);
            save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
            
            clearvars -except dataname datanumb subname subnumb chs trialname trialnumb
            cd ..;
            clc
            % ���� 'clearvars -except' ��, �� �ڵ忡�� ���� variable�� �ʹ� ���� ������ �ϳ��ϳ� �� ���� ���� ���� �����͸� ���� �� ������ variable�� �����ϰ� ������
            % variable ���� ��� clear �϶�� ��ɾ� �Դϴ�.
        end
        
        %% eEEG2
        for subnumb=1:length(subname)
            eval(['load eEEG_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_2.mat']);
            eEEG=eEEG2;
            clear eEEG2
            
            % Butterworth Filtering �κ�. 
            fsamp=500;
            [bbb, aaa]=butter(1, [0.5/(1000/2) 30/(1000/2)],'bandpass');
            
            %%% �Ʒ� �κ��� �������� comment ó�� �Ǿ� �ִ� �κ�.. �׳� ����ġ�ŵ� �� �� �մϴ�.%%%
            % baseline correction
            % for x=1:40,
            % channame(1,x)=cellstr(EEG.chanlocs(1,x).labels);
            % end;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            % 1~50Hz �� ������ 0.5Hz ������ �м��� ���̹Ƿ� �̸� ������ �ݴϴ�.
            freqs=[1:1/2:50];
            
            % ������ �κо���.
            m=7; % m=7;
            ki=5;
            % bl=zeros(size(id'));bl=single(bl);
            blEEG=eEEG;
            ERP=zeros(size(eEEG,1),size(chs,2));
            ERP_filt=ERP;
            ERP_filt_bl=ERP;
            
            
            %%% header
            % Baseline Correction �� Timewindow�� �����ϴ� �κ�.
            % �� �κ��� Ȯ���ϼž� �˴ϴ�.
            % ERP�� �ַ� -500 ~ -100ms, Frequency�м��� �ַ� -400 ~ -100ms �� �����մϴ�.
            % ���� ������ �� ���� �����Ͻ� �κ� �����ϴ�.    
            ERP_bltimewin=[1:200];
            TF_bltimewin=[51:200];
            %%%%%%%%%%%%%%%%%%%%%%%%%% ERP analysis
            for ii=1:length(chs);
                ch=chs(ii);
                
                bl(1,:)=squeeze(mean(eEEG([ERP_bltimewin],:,ch),1));
                for yy=1:size(bl),
                    blEEG(:,yy,ch)=squeeze(eEEG(:,yy,ch))-bl(1,yy);
                end;
                
                ERP(:,ch)=squeeze(mean(blEEG(:,:,ch),2));
                ERP_filt(:,ch)=filtfilt(bbb,aaa,ERP(:,ch));
                ERP_filt_bl(:,ch)=ERP_filt(:,ch)-mean(ERP_filt([ERP_bltimewin],ch));
            end;
            
            %%%%%%%%%%% Time-Frequency Analysis
            
            [TF, TF_power]=epoch2tf_min(eEEG,freqs,fsamp,m,ki);
            TF=single(TF);
            [TFi,TFP,TFA]=tf2tfi_min(TF);
            
            % evoked tf (without baseline_correction)
            TFe=zeros([length(freqs) size(ERP)]);
            for ch=1:size(ERP,2),
                [tf1,tfa1,tfc1]=tfmorlet_min(ERP(:,ch),fsamp,freqs,m,ki);
                TFe(:,:,ch)=tf1;
                %                 fnout=['su' num2str2(su) '_cond' num2str(cond) '_trg' num2str(n) '_' channame{1,ch} '.mat'];
                %                 save(fnout,'TFe');
            end;
            
            
            %%%%%%%%
            %%%%%%%%
            % evoked tf (with baseline_correction)
            TFes_bl=squeeze(mean(TFe(:,TF_bltimewin,:),2));
            TFe_bl=TFe;
            fn=length(freqs);
            chn=size(TFe,3);
            for i=1:chn,
                for f=1:fn,
                    TFe_bl(f,:,i)=TFe(f,:,i)-TFes_bl(f,i);
                end;
            end;
            
            % total tf (with baseline_correction: except alpha band)
            TFis_bl=squeeze(mean(TFi(:,TF_bltimewin,:),2));
            TFi_bl=TFi;
            fn=length(freqs);
            chn=size(TFi,3);
            for i=1:chn,
                for f=1:fn,
                    TFi_bl(f,:,i)=TFi(f,:,i)-TFis_bl(f,i);
                end;
            end;
            %%%%%%%%
            %%%%%%%%
            
            
            % 17~32�� ä�� wavelet ���� �����͸� ����
            % ��Ÿ ������ �� �κа� �����ϴ�.
            cd c;
            eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_2'';']);
            save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
            clearvars -except dataname datanumb subname subnumb chs trialname trialnumb
            cd ..;
            clc
            
            %% Combine Result1 & Result2
            % wavelt �� ����� Result1, Result2 �� ���� 1~32 ä�� ������ �����ͷ� ��ȯ�ϴ�
            % �����Դϴ�.
            cd c;
            eval(['load Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_1.mat']);
            cd ..;
            
            ERP_filt_bl1=ERP_filt_bl;
            TFe_bl1=TFe_bl;
            TFi1=TFi;
            TFi_bl1=TFi_bl;
            
            clear ERP_filt_bl TFe_bl TFi TFi_bl
            
            cd c;
            eval(['load Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_2.mat']);
            cd ..;
            ERP_filt_bl2=ERP_filt_bl;
            TFe_bl2=TFe_bl;
            TFi2=TFi;
            TFi_bl2=TFi_bl;
            
            clear ERP_filt_bl TFe_bl TFi TFi_bl
            
            ERP_filt_bl=[ERP_filt_bl1, ERP_filt_bl2];
            
            TFe_bl=TFe_bl1;
            TFi= TFi1;
            TFi_bl= TFi_bl1;
            
            for k=1:16;
                TFi(:,:,16+k)=TFi2(:,:,k);
                TFi_bl(:,:,16+k)=TFi_bl2(:,:,k);
                TFe_bl(:,:,16+k)=TFe_bl2(:,:,k);
            end
            
            % 'Result_' �� �����ϴ� mat���Ϸ� ����
            cd result;
            eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) ''';']);
            save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
            clearvars -except dataname datanumb subname subnumb chs trialname trialnumb
            cd ..;
            clc
        end
    end
end