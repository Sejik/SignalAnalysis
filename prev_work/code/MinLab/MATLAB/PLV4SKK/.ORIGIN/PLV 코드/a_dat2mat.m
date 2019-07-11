%% dat 파일을 mat 파일로 바꾸어 주는 파일입니다.

%% 사용하고자 하는 channel을 선택하고 (channel), 파일 이름에 맞게 dataname, trialname, subname을 설정해 줍니다.
clear;
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname={'dislike', 'like'};
subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27', 'su28', 'su29'};

%% Subjects_All Epochs_bl
%% for문을 통해 각각의 파일을 받아올 수 있게 합니다.
for subnumb= 1:length(subname)
    for datanumb= 1:length(dataname)
        for trialnumb=1:length(trialname)
        
            cd skk_dat;
            eval(['DataBuf = importdata(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '.dat'');']);
            % data를 파일에서 받아옵니다.
            cd ..;
            B=DataBuf.data;
            % B=shiftdim(B, 1); %행렬을 옮겨주는 것인데, 지금은 사용을 안합니다.
            eEEG=reshape(B, 1000, [], 32); % eEEG(timepoint x epochs x channels), 모양을 잡아줍니다. (선언을 합니다.)
            clear B DataBuf
            
            eEEG(:,:,17)=NaN;    % EOG, 17번째 채널이 EOG 입니다. channame 참조, 데이터 값을 없애줍니다.
            eEEG(:,:,22)=NaN;    % NULL 22번째 채널이 NULL 입니다.
            
            eval(['FILENAME=''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) ''';']);
            cd skk_mat;
            save(FILENAME, 'eEEG'); % 값들을 mat 파일로 저장을 해줍니다.
            cd ..
            clear eEEG
        end
    end
end

    cd svm(125);
    FILENAME2 = [char(subname{subnumb}) '_acc_125'];
    xlswrite(FILENAME2, acc);
    cd ..;