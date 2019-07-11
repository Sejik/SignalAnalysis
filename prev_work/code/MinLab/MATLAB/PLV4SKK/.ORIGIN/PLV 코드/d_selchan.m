%% Header %%
clear;clc;

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'B', 'G', 'R', 'W'};
trialname={'B', 'G', 'R', 'W'};
subname={'su0001', 'su0002', 'su0003', 'su0004', 'su0005', 'su0006', 'su0007', 'su0009', 'su0010', 'su0011', 'su0013', 'su0017', 'su0018'};
selchanname={'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

for datanumb= 1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb= 1:length(subname)
             load(['TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat']);
             TFii = TFi(:,:,[24,25,26,29,30,31]);
             for selchannum= 1:length(selchanname)
                TFs = TFii(:,:,selchannum);
                FILENAME = ['TFs_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_' char(selchanname{selchannum})]; 
                save(FILENAME, 'TFs', '-v7.3')
             end
        end
    end
end