%% Header %%
clear;clc;

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'Neutral_Mexico'};
trialname={'dislike'};
subname={'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27', 'su28', 'su29'};
selchanname={'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P8','PO9'};

for datanumb= 1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb= 1:length(subname)
            
             cd skk_tf;
             load(['TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat']);
             cd ..;
             TFii = TFi(:,:,[11,12,13,14,15,16,18,19,20,21,23,27,28]);
             for selchannum= 1:length(selchanname)
                TFs = TFii(:,:,selchannum);
                cd skk_ch;
                FILENAME = ['TFs_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_' char(selchanname{selchannum})]; 
                save(FILENAME, 'TFs', '-v7.3')
                cd ..;
             end
        end
    end
end