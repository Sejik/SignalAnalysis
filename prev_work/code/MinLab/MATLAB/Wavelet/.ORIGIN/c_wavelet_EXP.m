%% wavelet_EXP.m %%
% Wavelet 코드. 실험에 따라 Header부분이 달라지므로, wavelet 코드를 각 실험별로 하나씩 만들어 두시는 게
% 좋습니다. 
% 이 코드를 실행시키기 위해선 아래의 다른 m코드 들이 반드시 같은 폴더에 있어야 합니다.
%
% epoch2erp_min.m, epoch2tf_min.m, tf2tfi_min.m, tfmorlet_min.m,
% wmorlet_min.m, readKRISSMEG_sev.m, spss_min.m
%
% Wavelet을 돌리는 데이터는 Average 데이터가 아닌 전체 epoch이 있는 데이터이므로 이 코드에서는 전체 epoch
% 데이터만을 다룹니다.

%% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
clear;
close all;

%% Header %%
% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% channame: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% dataname, trialname: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% subname: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'like', 'dislike'};
trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};
subname={'su02', 'su04'};

% Wavelet의 Header에 추가된 부분으로, 메모리 문제로 16채널씩 나눈 데이터로 wavelet을 돌리기 때문에 추가된
% 부분입니다. 만약 잘라진 데이터의 채널 수를 바꾸었다면 이 부분을 바꾸어 주면 됩니다.
chs=[1:16];

for datanumb=1:length(dataname)
    for trialnumb=1:length(trialname)
       
       %% eEEG1
        for subnumb=1:length(subname)
            eval(['load eEEG_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '_1.mat']);
            eEEG= eEEG1;
            clear eEEG1;
            
            % Butterworth Filtering 부분. 일반적으로 수정하실 부분은 없으나
            % fsamp가 Sampling Rate이므로 우리 기기로 측정한 데이터가 아닌 MEG 데이터 등의 경우
            % Sampling Rate가 달라지므로 수정해줘야 합니다.
            % SKK 실험 데이터 sampling rate : 500Khz
            fsamp=500;
            [bbb, aaa]=butter(1, [0.5/(1000/2) 30/(1000/2)],'bandpass');
            
            %%% 아래 부분은 원래부터 comment 처리 되어 있던 부분.. 그냥 지나치셔도 될 듯 합니다.%%%
            % baseline correction
            % for x=1:40,
            % channame(1,x)=cellstr(EEG.chanlocs(1,x).labels);
            % end;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % 1~50Hz 의 범위를 0.5Hz 단위로 분석할 것이므로 이를 지정해 줍니다.
            freqs=[1:1/2:50];
            
            % 수정할 부분없음.
            m=7; % m=7;
            ki=5;
            % bl=zeros(size(id'));bl=single(bl);
            blEEG=eEEG;
            ERP=zeros(size(eEEG,1),size(chs,2));
            ERP_filt=ERP;
            ERP_filt_bl=ERP;
            
            %%% header
            % Baseline Correction 의 Timewindow를 지정하는 부분.
            % 이 부분은 확인하셔야 됩니다.
            % ERP는 주로 -500 ~ -100ms, Frequency분석은 주로 -400 ~ -100ms 로 지정합니다.
            % 이후 저장할 때 까지 수정하실 부분 없습니다.            
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
            
            % 1~16번 채널 wavelet 돌린 데이터를 저장
            % 데이터는 4 종류로, ERP_filt_bl, TFi, TFe_bl, TFi_bl 입니다.
            % 이 중 실제 wavelet이 적용된 주파수 데이터는 TFi, TFe_bl, TFi_bl 이고
            % ERP_filt_bl 은 ERP 데이터 입니다.
            % 미팅 때도 간단히 말씀드렸던 것과 같이, 여기서의 ERP_filt_bl 데이터는 필터링이 한번 더 된
            % 데이터이므로 분석에는 쓰지 않고, analyzer에서 export한 Average 데이터로 분석하시면 됩니다.
            cd c;
            eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_1'';']);
            save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
            
            clearvars -except dataname datanumb subname subnumb chs trialname trialnumb
            cd ..;
            clc
            % 위의 'clearvars -except' 는, 이 코드에서 사용된 variable이 너무 많기 때문에 하나하나 다 써줄 수가 없어 데이터를 지울 때 지정된 variable을 제외하고 나머지
            % variable 들을 모두 clear 하라는 명령어 입니다.
        end
        
        %% eEEG2
        for subnumb=1:length(subname)
            eval(['load eEEG_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_2.mat']);
            eEEG=eEEG2;
            clear eEEG2
            
            % Butterworth Filtering 부분. 
            fsamp=500;
            [bbb, aaa]=butter(1, [0.5/(1000/2) 30/(1000/2)],'bandpass');
            
            %%% 아래 부분은 원래부터 comment 처리 되어 있던 부분.. 그냥 지나치셔도 될 듯 합니다.%%%
            % baseline correction
            % for x=1:40,
            % channame(1,x)=cellstr(EEG.chanlocs(1,x).labels);
            % end;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            % 1~50Hz 의 범위를 0.5Hz 단위로 분석할 것이므로 이를 지정해 줍니다.
            freqs=[1:1/2:50];
            
            % 수정할 부분없음.
            m=7; % m=7;
            ki=5;
            % bl=zeros(size(id'));bl=single(bl);
            blEEG=eEEG;
            ERP=zeros(size(eEEG,1),size(chs,2));
            ERP_filt=ERP;
            ERP_filt_bl=ERP;
            
            
            %%% header
            % Baseline Correction 의 Timewindow를 지정하는 부분.
            % 이 부분은 확인하셔야 됩니다.
            % ERP는 주로 -500 ~ -100ms, Frequency분석은 주로 -400 ~ -100ms 로 지정합니다.
            % 이후 저장할 때 까지 수정하실 부분 없습니다.    
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
            
            
            % 17~32번 채널 wavelet 돌린 데이터를 저장
            % 기타 내용은 윗 부분과 같습니다.
            cd c;
            eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb})  '_2'';']);
            save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
            clearvars -except dataname datanumb subname subnumb chs trialname trialnumb
            cd ..;
            clc
            
            %% Combine Result1 & Result2
            % wavelt 후 저장된 Result1, Result2 를 묶어 1~32 채널 온전한 데이터로 변환하는
            % 과정입니다.
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
            
            % 'Result_' 로 시작하는 mat파일로 저장
            cd result;
            eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) ''';']);
            save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
            clearvars -except dataname datanumb subname subnumb chs trialname trialnumb
            cd ..;
            clc
        end
    end
end