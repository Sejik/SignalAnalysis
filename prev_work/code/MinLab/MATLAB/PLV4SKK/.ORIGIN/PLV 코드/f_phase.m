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
			%단, 32개 채널 전체를 수행했을 경우에는, 더미채널을 제거해야 한다.
			% ch17= EOG, ch22=NULL, 없는 부분을 날림. 뒤에서 부터 날려야 제대로 처리됨.
			if size(TF,4) > 30,										%4차원(채널)의 수(더미채널 포함 32)
%				idx		=	find(strcmp(channame, 'EOG'), 1);		%더미채널 유형1 의 인덱스 찾기
%				TF(:,:,:,idx)=[];									%EOG와 타채널 간의 관계도 조사해 보자
				idx		=	find(strcmp(channame, 'NULL'), 1);		%더미채널 유형2 의 인덱스 찾기
				TF(:,:,:,idx)=[];
			end;

			MinMinMin_phase6();
			save(['Phase_' WORKNAME '.mat'], 'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
        end
    end
 end
