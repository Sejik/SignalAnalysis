%% Result2Econnectome %%
% 최종 결과(또는 과정) 파일을 Econnectome 형식으로 변환시키는 코드
% 2016/01/15 by Kim Insoo

%% 코드를 시작하기 전에 메모리를 비우는 작업
clear all;
close all;
clc;

%% Header
%channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
% channame(채널이름)은 각각의 분석 상황에 맞게 변형시켜줘야 합니다.(SKK 실험의 경우 EOG와 Null이 제거된 30채널)
% 또한 채널의 순서는 반드시 맞춰줘야 함

%dataname={'like', 'dislike'};

%trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};

%subname={'su02', 'su04'};

%% 원본 데이터 Load

load('Com____L.mat');


%% Connectome type EEG Structure 선언

EEG.data = shiftdim(EVK____L(28,:,:));        % eeg data(chan x data)
EEG.data = shiftdim(EEG.data,1);
EEG.type = 'EEG';       % data type(변경 X)
EEG.nbchan = 30;        % Number of eeg channel
EEG.points = 1000;          % eeg data의 data 크기와 동일(수치가 아닌 크기임을 주의)
EEG.srate = 500;              % sampling rate
EEG.labeltype = 'standard';     % channel location 10-10, 10-20의 경우 'standard'고정 이외의 경우 'custom' 표기
EEG.labels = {'Fp1';'Fp2';'F7';'F3';'Fz';'F4';'F8';'FC5';'FC1';'FC2';'FC6';'T7';'C3';'Cz';'C4';'T8';'CP5';'CP1';'CP2';'CP6';'P7';'P3';'Pz';'P4';'P8';'PO9';'O1';'Oz';'O2';'PO10'};
% channel name(기존에 사용하던 행 기준 인력이 아닌 열 기준 입력)
% 실험 별 조건에 맞게 변경해야 함을 유의
EEG.unit = 'uv';        % data의 단위

%%
save('COM_L_EVK.mat', 'EEG');

