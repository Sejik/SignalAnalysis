
clear;
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname={'dislike', 'like'};
subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27', 'su28', 'su29'};

%% Subjects_All Epochs_bl
for subnumb= 1:length(subname)
    for datanumb= 1:length(dataname)
       for trialnumb=1:length(trialname)
            %%% 아래의 'eval' 함수가 매우 중요합니다. %%%
            % 피험자나 실험 조건 등을 바꾸면서 계속 같은 코드를 적용하고 싶을 때 사용하는 함수입니다.
            % for문 안에서 정해진 상수나 variable 을 사용할 경우에는 일반적인 코드, 예를 들어
            %
            % ex1) A=1+1;
            % ex2) A=max(B);
            %
            % 위와 같이 그냥 for문 안에 넣어서 사용하셔도 되지만, for문이 돌 때 마다 다른 값을 불러들이거나 다른
            % 값을 사용할 경우에는 코드에 달라지는 부분들을 지정해주셔야 합니다.
            %
            % 예를 들어서, comment 바로 아래 코드에 있는 eval 함수의 괄호 안에 들어가 있는 코드는 실제로는
            % DataBuf = importdata(''exp_su00XX_BaselineCorrection_trialname하나_dataname하나.dat'');
            % 입니다. '.dat'파일은 matlab에서 일반적인 'load'함수로는 불러올 수 없기 때문에
            % 'importdata' 라는 함수를 쓴 것 입니다.
            % 우리는 항상 같은 dat파일을 불러들이는 것이 아니라 각각의 피험자 및 실험 조건(trialname, dataname)이
            % 다른 dat파일을 불러들이는 것이기 때문에, for문이 돌면서 다른 subname, trialname,
            % dataname 등을 불러 들이도록 eval 함수로 지정해놓은 것입니다.
            % 코드를 간단히 하는데 굉장히 중요한 함수이고 제가 만든 코드에도 많이 쓰이는 함수 이므로, 어떻게 적용되는
            % 것인지 확실하게 알아두는 것이 좋을 것 같습니다. 자세한 설명은 help 나 google 등을 이용해보시면
            % 좋을 것 같습니다.
            
            % dat파일을 import해서 DataBuf에 저장.
            eval(['DataBuf = importdata(''EXP_NEW_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'');']);
            % DataBuf중 data라는 부분을 B로 다시 저장.
            B=DataBuf.data;
            
            % Wavelet을 사용할 때 데이터 타입은 항상 (timepoint x epochs x channels) 의
            % 형태가 되어야 합니다. 현재 B에 저장되어 있는 데이터 타입은 (전체 데이터 x channels) 이나
            % (channels x 전체 데이터) 의 형태입니다. 이를 우리가 사용하는 형태로 잘라주기 위해 아래의 reshape 라는
            % 함수를 사용합니다. 만약 현재 B의 형태가 (전체 데이터 x channels) 라면 바로 reshape를
            % 해주면 되지만, (channels x 전체 데이터) 의 형태라면 위치를 역전시켜야 하므로 아래 코드를
            % 추가하시면 됩니다. 분석하실 때 항상 확인하셔야할 부분입니다.
            
            % B=shiftdim(B, 1);
            
            eEEG=reshape(B, 1050, [], 32); % eEEG(timepoint x epochs x channels). 
            clear B DataBuf
            % 데이터가 뒤섞이는 것을 방지하고 메모리 용량을 비우기 위해서, 이미 사용이 끝난 variable들은 clear
            % 로 지워주는 것이 좋습니다. 
            
            eEEG(:,:,17)=NaN;    % EOG는 분석에 사용하지 않기 때문에 Not a Number로 지정.
            eEEG(:,:,22)=NaN;    % NULL도 마찬가지.
            
            % 위에서 처리한 eEEG를 mat파일로 저장.
            eval(['FILENAME=''exp_new_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) ''';']);
            save(FILENAME, 'eEEG');
            clear eEEG
        end
    end
end

