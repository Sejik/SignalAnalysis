% please load eEEG for each experiment and condition:
clear;clc;


%% Header %%
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname={'dislike', 'like'};
subname={'su04'};
selchanname={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};

%%
%data=load('inputusa1.txt');
for datanumb= 1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb= 1:length(subname)
             eval(['load(''TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
             TF=TF_origin;
             MinMinMin_phase6();
			%��, 32�� ä�� ��ü�� �������� ��쿡��, ����ä���� �����ؾ� �Ѵ�.
			% ch17= EOG, ch22=NULL, ���� �κ��� ����. �ڿ��� ���� ������ ����� ó����.
			if size(TF,4) > 30,										%4����(ä��)�� ��(����ä�� ���� 32)
%				idx		=	find(strcmp(channame, 'EOG'), 1);		%����ä�� ����1 �� �ε��� ã��
%				TF(:,:,:,idx)=[];									%EOG�� Ÿä�� ���� ���赵 ������ ����
				idx		=	find(strcmp(channame, 'NULL'), 1);		%����ä�� ����2 �� �ε��� ã��
				TF(:,:,:,idx)=[];
			end;

			MinMinMin_phase6();
			save(['Phase_' WORKNAME '.mat'], 'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
        end
    end
 end
