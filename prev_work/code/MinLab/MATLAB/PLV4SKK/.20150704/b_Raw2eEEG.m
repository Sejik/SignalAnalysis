% 이건 아마 2차원 일 것이다??? brain vision에서 받은 것을 matlab으로 바꾸어줌
% eEEG를 나눈 것은 메모리의 문제로 인해서
clear;
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={ 'Neutral_Mexico' };
trialname={ 'like'};
subname={'su02','su04','su07','su08','su09','su10','su12','su14','su16'};

chs=[1:16];


for datanumb=1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb=1:length(subname)
            
            cd skk_mat;
            eval(['load(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb})  '.mat'');']);
            cd ..;
            
            eEEG1= eEEG(:,:,1:16);
            eEEG2= eEEG(:,:,17:32);
            
            cd skk_eEEG;
            eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ''';']);
            save(FILENAME, 'eEEG');
            
            
            eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_1'';']);
            save(FILENAME, 'eEEG1');
            
            
            eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_2'';']);
            save(FILENAME, 'eEEG2');
            cd ..;
            clear eEEG eEEG1 eEEG2
        end
    end
end
