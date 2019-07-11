%% Raw2eEEG.m %%
% �ռ� �ڵ忡�� ����� �����͵��� wavelet�� ����ϱ� ���� ä�� 16�� �� �ΰ��� ���Ϸ� ������ ����.
% ���� �ڵ�� ���ļ� �ٽ� �ۼ��ϼŵ� �����մϴ�.

% Wavelet�� ������ �����ʹ� Average �����Ͱ� �ƴ� ��ü epoch�� �ִ� �������̹Ƿ� �� �ڵ忡���� ��ü epoch
% �����͸��� �ٷ�ϴ�.

%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clear;
close all;

%% Header %%
% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% channame: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% dataname, trialname: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% subname: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'like', 'dislike'};
trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};
subname={'su02', 'su04'};

for datanumb=1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb=1:length(subname)
            
            % mat���Ϸ� ����� Raw������ load
            cd save;
            eval(['load(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb})  '.mat'');']);
            cd ..;
            % 1~16�� ä���� �����ʹ� eEEG1 ����, 17~32�� ä���� �����ʹ� eEEG2 �� ����.
            eEEG1= eEEG(:,:,1:16);
            eEEG2= eEEG(:,:,17:32);
            
            % eEEG, eEEG1, eEEG2 �����͵��� ���� ����. Wavelet���� ������ ���̴� �����ʹ� eEEG1��
            % eEEG2 �Դϴ�.
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