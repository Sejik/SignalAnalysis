% please load eEEG for each experiment and condition:
clear;clc;

fsamp=500; % sampling point�� ����
freqs=[4:1/2:8];  % ��Ÿ�ĸ� ��� ��. step 0.5
chs=[1:32]; % ä��
m=7; ki=5; % wavelet �м��� ���� default ��



%% Header: ������ ����, brain analyzer�� defualt�� 4��, selchannel�� ���⸸ ������ ��, dataname, trialname: �����̶� �ڱ� ���� %%
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
            
            bl=zeros(size(eEEG,2)); % baseline�� ����� ��: �ڱ� �������� ������ ��� ��� baseline�� ������. correction�� �Ѵ�. common reference ���� ����� ����.
            % �� ���� ��� ä���� �����ִ� ���� baseline. ������ �м� �� ������ �ڱ� ������ baseline��
            % ������ �ʴ´�. ���� ERP �� ������ 0.5-1.5 ���ļ� �м��� �� ������ -0.5 (���̾ ���� ������
            % ) ���̸� ����ִ� ���� �ʿ����� �ð� ������ ��� ��. �ð�, ���� , ä��, (���߿� ���ļ�) -
            % 
            bl=single(bl); % single: ���� �����͸� �����ϰų� ������ �ϴ�??

            blEEG=eEEG; % ���ĸ� �м� �� �� �ð� �� �м� ERP, ���ļ� �м� ���� ��Ÿ ���� ��

            ERP=zeros(size(eEEG,1),length(chs));          %�Ͳ�? matlab���� ��� �ϱ����ؼ� dimension�� ������ִ� ��. Ʋ ����� �ִ� ��    %eEEG��             %ERP ������ timepoint �� channel �ΰ����� ǥ����. 
            % ������ ��� ��� 2�������� �پ���� ��
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ERP ���ϴ� ��
            for ii=1:length(chs);
                   ch=chs(ii);
                   bl(1,:)=squeeze(mean(eEEG([1:250],:,ch),1));            %�ڱ����� �� -500~0ms �� baseline �� ������.
                   for yy=1:size(bl),                                      %������ baseline ���� �� ä�κ��� ���־� correction ��.
                       blEEG(:,yy,ch)=squeeze(eEEG(:,yy,ch))-bl(1,yy); %���⼭ baseline correction�� ����. squeeze�� ������ ������ �پ��� single ton
                   end;
                   ERP(:,ch)=squeeze(mean(blEEG(:,:,ch),2)); %�ð��� ä�θ� ���� (ERP ����)
            end;
            
            %%%%%%%%%%% Time-Frequency Analysis : Total activity = TFi
           % frequency�� �� �ʿ� �ٿ���
           % shift demension�� ����ؼ� ������ �ٲ� �� �ִ�.
            TF_origin=epoch2tf_min(eEEG,freqs,fsamp,m,ki);                        %TF�� ���� (total activity)
            TF=single(TF_origin); % f,t,e,c
            [TFi,TFP,TFA]=tf2tfi_min(TF); % iPA�� ����� �ִ� �� induce�� total activity�� ���� �� �ִ�.

            %%%%%%%%%%% Time-Frequency Analysis : Evoked activity = TFe_bl

            % evoked tf (without baseline_correction)
            TFe=zeros([length(freqs) size(ERP)]); % �ð� ���ļ� �м������� evoked�� induced�� �߿��ϰ� �м��Ѵ�.
                for ch=1:size(ERP,2),
                    [tf1,tfa1,tfc1]=tfmorlet_min(ERP(:,ch),fsamp,freqs,m,ki); %Evoked activity �� ���ϱ� ���� �� ä�� �� morlet wavelet �м� �ǽ�.
                    TFe(:,:,ch)=tf1;
                end; % wavelet�� baseline correction�� �ʿ��ϴ�. edge�� �Ⱦ��� �񲸼� ���� ��

            % evoked tf (with baseline_correction)
            TF_bl=squeeze(mean(TFe(:,51:200,:),2));                        % wavelet �м� �� -400~100ms ������ baseline���� �ٽ� correction ��.
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
            save(FILENAME, 'TF_origin', 'ERP', 'TFi', 'TFe_bl', '-v7.3');	%v7.3�ɼ��� ������ TF_origin �� 2G ũ�� �̻��� �� ���� ������.
            cd ..;
            clear TF_origin ERP TFi TFP TFA TFe_bl;
        end
    end
end
