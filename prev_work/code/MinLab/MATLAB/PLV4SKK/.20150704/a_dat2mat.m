
clear;
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname={'dislike', 'like'};
subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27', 'su28', 'su29'};

%% Subjects_All Epochs_bl
for subnumb= 1:length(subname)
    for datanumb= 1:length(dataname)
        for trialnumb=1:length(trialname)
        
            cd skk_dat;
            eval(['DataBuf = importdata(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '.dat'');']);
            cd ..;
            B=DataBuf.data;
            % B=shiftdim(B, 1);
            eEEG=reshape(B, 1000, [], 32); % eEEG(timepoint x epochs x channels)
            clear B DataBuf
            
            eEEG(:,:,17)=NaN;    % EOG
            eEEG(:,:,22)=NaN;    % NULL
            
            eval(['FILENAME=''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) ''';']);
            cd skk_mat;
            save(FILENAME, 'eEEG');
            cd ..
            clear eEEG
        end
    end
end

    cd svm(125);
    FILENAME2 = [char(subname{subnumb}) '_acc_125'];
    xlswrite(FILENAME2, acc);
    cd ..;