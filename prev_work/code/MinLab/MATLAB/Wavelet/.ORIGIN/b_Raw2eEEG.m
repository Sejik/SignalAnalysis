%% Raw2eEEG.m %%
% 앞선 코드에서 저장된 데이터들을 wavelet에 사용하기 위해 채널 16개 씩 두개의 파일로 나누는 과정.
% 앞의 코드와 합쳐서 다시 작성하셔도 무방합니다.

% Wavelet을 돌리는 데이터는 Average 데이터가 아닌 전체 epoch이 있는 데이터이므로 이 코드에서는 전체 epoch
% 데이터만을 다룹니다.

%% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
clear;
close all;

%% Header %%
% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% channame: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% dataname, trialname: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% subname: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'like', 'dislike'};
trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};
subname={'su02', 'su04'};

for datanumb=1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb=1:length(subname)
            
            % mat파일로 저장된 Raw파일을 load
            cd save;
            eval(['load(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb})  '.mat'');']);
            cd ..;
            % 1~16번 채널의 데이터는 eEEG1 으로, 17~32번 채널의 데이터는 eEEG2 로 저장.
            eEEG1= eEEG(:,:,1:16);
            eEEG2= eEEG(:,:,17:32);
            
            % eEEG, eEEG1, eEEG2 데이터들을 각각 저장. Wavelet에서 실제로 쓰이는 데이터는 eEEG1과
            % eEEG2 입니다.
            cd b;
            eval(['FILENAME=''eEEG_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) ''';']);
            save(FILENAME, 'eEEG');
                        
            eval(['FILENAME=''eEEG_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '_1'';']);
            save(FILENAME, 'eEEG1');
                        
            eval(['FILENAME=''eEEG_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '_2'';']);
            save(FILENAME, 'eEEG2');
            
            clear eEEG eEEG1 eEEG2
            cd ..;
        end
    end
end