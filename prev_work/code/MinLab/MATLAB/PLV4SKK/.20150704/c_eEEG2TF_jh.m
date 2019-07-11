% please load eEEG for each experiment and condition:
clear;clc;

fsamp=500; % sampling point를 잡음
freqs=[4:1/2:8];  % 세타파를 잡는 다. step 0.5
chs=[1:32]; % 채널
m=7; ki=5; % wavelet 분석을 위한 default 값



%% Header: 전극의 순서, brain analyzer가 defualt가 4개, selchannel은 여기만 돌리는 것, dataname, trialname: 조명이랑 자극 색깔 %%
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'Fav_USA','Unfav_Paki','Neutral_Mexico'};
%dataname={'Unfav_Paki','Neutral_Mexico'};
trialname={'dislike','like'};
%trialname={'dislike'};
%subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27', 'su28', 'su29'};
subname={'su10', 'su19', 'su20'};
selchanname={'P3', 'Pz', 'P4'};

%%
for datanumb= 1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb= 1:length(subname)
            cd skk_eEEG;
            eval(['eEEG = importdata(''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
            cd ..;
            
            bl=zeros(size(eEEG,2)); % baseline을 만드는 것: 자극 전까지의 값들을 평균 내어서 baseline을 맞춰줌. correction을 한다. common reference 같은 방법이 있음.
            % 매 순간 모든 채널을 맞춰주는 것이 baseline. 알파파 분석 할 때에는 자극 전에도 baseline을
            % 맞추지 않는다. 뇌파 ERP 할 때에는 0.5-1.5 주파수 분석을 할 때에는 -0.5 (스미어링 등의 이유로
            % ) 사이를 잡아주는 것이 필요일정 시간 이전에 잡는 것. 시간, 에폰 , 채널, (나중에 주파수) -
            % 
            bl=single(bl); % single: 무언가 데이터를 가공하거나 빠르게 하는??

            blEEG=eEEG; % 뇌파를 분석 할 때 시간 축 분석 ERP, 주파수 분석 알파 베타 같은 것

            ERP=zeros(size(eEEG,1),length(chs));          %와꾸? matlab에서 계산 하기위해선 dimension을 만들어주는 것. 틀 만들어 주는 것    %eEEG는             %ERP 변수는 timepoint 와 channel 두가지로 표현됨. 
            % 에폭을 평균 내어서 2차원으로 줄어들은 것
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ERP 구하는 것
            for ii=1:length(chs);
                   ch=chs(ii);
                   bl(1,:)=squeeze(mean(eEEG([1:250],:,ch),1));            %자극제시 전 -500~0ms 로 baseline 을 설정함.
                   for yy=1:size(bl),                                      %설정한 baseline 으로 각 채널별로 빼주어 correction 함.
                       blEEG(:,yy,ch)=squeeze(eEEG(:,yy,ch))-bl(1,yy); %여기서 baseline correction을 해줌. squeeze는 차원의 개념이 줄어드는 single ton
                   end;
                   ERP(:,ch)=squeeze(mean(blEEG(:,:,ch),2)); %시간과 채널만 남음 (ERP 구함)
            end;
            
            %%%%%%%%%%% Time-Frequency Analysis : Total activity = TFi
           % frequency를 앞 쪽에 붙여줌
           % shift demension을 사용해서 순서를 바꿀 수 있다.
            TF_origin=epoch2tf_min(eEEG,freqs,fsamp,m,ki);                        %TF를 만듬 (total activity)
            TF=single(TF_origin); % f,t,e,c
            [TFi,TFP,TFA]=tf2tfi_min(TF); % iPA를 만들어 주는 것 induce로 total activity를 구할 수 있다.

            %%%%%%%%%%% Time-Frequency Analysis : Evoked activity = TFe_bl

            % evoked tf (without baseline_correction)
            TFe=zeros([length(freqs) size(ERP)]); % 시간 주파수 분석에서는 evoked와 induced를 중요하게 분석한다.
                for ch=1:size(ERP,2),
                    [tf1,tfa1,tfc1]=tfmorlet_min(ERP(:,ch),fsamp,freqs,m,ki); %Evoked activity 를 구하기 위해 각 채널 별 morlet wavelet 분석 실시.
                    TFe(:,:,ch)=tf1;
                end; % wavelet도 baseline correction이 필요하다. edge는 안쓰고 비껴서 쓰는 것

            % evoked tf (with baseline_correction)
            TF_bl=squeeze(mean(TFe(:,51:200,:),2));                        % wavelet 분석 후 -400~100ms 구간의 baseline으로 다시 correction 함.
            TFe_bl=TFe;
            fn=length(freqs);
            chn=size(TFe,3);
                for i=1:chn,
                    for f=1:fn,
                        TFe_bl(f,:,i)=TFe(f,:,i)-TF_bl(f,i);
                    end;
                end;
            
                
            cd skk_tf;
            FILENAME = ['TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ]; 
            save(FILENAME, 'TF_origin', 'ERP', 'TFi', 'TFe_bl', '-v7.3');	%v7.3옵션이 없으면 TF_origin 이 2G 크기 이상일 때 저장 실패함.
            cd ..;
            clear TF_origin ERP TFi TFP TFA TFe_bl;
        end
    end
end
