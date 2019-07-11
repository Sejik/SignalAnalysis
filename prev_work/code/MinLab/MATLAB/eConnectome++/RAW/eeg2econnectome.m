%% Result2Econnectome %%
% ���� ���(�Ǵ� ����) ������ Econnectome �������� ��ȯ��Ű�� �ڵ�
% 2016/01/15 by Kim Insoo

%% �ڵ带 �����ϱ� ���� �޸𸮸� ���� �۾�
clear all;
close all;
clc;

%% Header
%channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
% channame(ä���̸�)�� ������ �м� ��Ȳ�� �°� ����������� �մϴ�.(SKK ������ ��� EOG�� Null�� ���ŵ� 30ä��)
% ���� ä���� ������ �ݵ�� ������� ��

%dataname={'like', 'dislike'};

%trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};

%subname={'su02', 'su04'};

%% ���� ������ Load

load('Com____L.mat');


%% Connectome type EEG Structure ����

EEG.name = 'Com____L.mat'; % the name for the EEG data
EEG.data = shiftdim(EVK____L(28,:,:));        % eeg data(chan x data)
EEG.data = shiftdim(EEG.data,1);
EEG.type = 'EEG';       % data type(���� X)
EEG.nbchan = 30;        % Number of eeg channel
EEG.points = 1000;          % eeg data�� data ũ��� ����(��ġ�� �ƴ� ũ������ ����)
EEG.srate = 500;              % sampling rate
EEG.labeltype = 'standard';     % channel location 10-10, 10-20�� ��� 'standard'���� �̿��� ��� 'custom' ǥ��
EEG.labels = {'Fp1';'Fp2';'F7';'F3';'Fz';'F4';'F8';'FC5';'FC1';'FC2';'FC6';'T7';'C3';'Cz';'C4';'T8';'CP5';'CP1';'CP2';'CP6';'P7';'P3';'Pz';'P4';'P8';'PO9';'O1';'Oz';'O2';'PO10'};
% channel name(������ ����ϴ� �� ���� �η��� �ƴ� �� ���� �Է�)
% ���� �� ���ǿ� �°� �����ؾ� ���� ����
EEG.unit = 'uv';        % data�� ����

%%
save('COM_L_EVK.mat', 'EEG');

