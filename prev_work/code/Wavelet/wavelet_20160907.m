%% Wavelet
% designed by Sejik Park (Korea University Undergraduated)

% Process
% 1. read preprocessed data (output of brainvision analyzer)
%   read format: '.dat'
%   individual average data
% 2. calculate wavelet (this code)
% 3. statistic analysis

% Parameter in Code
% cnt: time series data
% fs: sampling frequency
% freqs: interest freqeuncy
% m : wavelet factor, determine wavelet family, m >= 5
% ki: wavelet waveform size (envelop), ki >= 3
% w: weight
% t: time

% Result
% TFi: induced time-frequency
% TFe: evoked time-frequency

function wavelet()
% clear before processes
clear; clc; close;

%% basic set up
fprintf('%s: wavelet code is started.\n', datestr(now));
% directory
file.inputDir = 'C:\Users\win\Desktop\mat'; % input File directory
file.outputDir = 'C:\Users\win\Desktop\wavelet'; % output File directory
file.outputName = 'wavelet_'; % add outputName in front of input file name
% basic parameter
param.workersNum = 3; % number of CPU for parallel toolbox operation
param.freqStep = 0.5;
param.freqs = 1:param.freqStep:50;% wavelet frequency
param.individualFreq{1} = [0.1 3.5]; % delta
param.individualFreq{2} = [4 7.3]; % theta
param.individualFreq{3} = [8 13]; % alpha
param.individualFreq{4} = [14 30]; % beta
param.individualFreq{5} = [30 70]; % gamma
param.interestLatency{1} = [-0.500 0.000]; % pre-stimulus
param.interestLatency{2} = [0.000 1.000]; % post-stimulus
param.zeroLatency = 0.5;
param.m = 7; param.ki = 5; % wavelet parameter
param.fs = 1000;
param.epochLength = 1500;

%% basic process
% parallel tool box
fprintf('%s: setting parallel pool\n', datestr(now));
myCluster = parcluster('local');
myCluster.NumWorkers = param.workersNum;
saveProfile(myCluster);
param.POOL = parpool('local', param.workersNum);
fprintf('%s: parallel pool is ready.\n', datestr(now));
clearvars -except file param

%% read preprocessed data
fprintf('%s: checking input file\n', datestr(now));
cd(file.inputDir);
eeg_files = dir('*.dat');
for eegFileNum = 1:length(eeg_files)
    file.inputFile{eegFileNum} = eeg_files(eegFileNum).name;
    file.outputFile{eegFileNum} = strcat(file.outputName, strrep(file.inputFile{eegFileNum},'.dat', '.mat'));
end
cd(file.outputDir);
for eegFileNum = length(eeg_files):1
    if exist(file.outputFile{eegFileNum}, 'file') > 0
        fprintf('"%s" is already processed (skip).\n', file.outputFile{eegFileNum});
        file.inputFile{eegFileNum} = [];
        file.outputFile{eegFileNum} = [];
    end
end
file.inputFile = file.inputFile(~cellfun('isempty',file.inputFile));
file.outputFile = file.outputFile(~cellfun('isempty',file.inputFile));
fprintf('%s: input file is checked\n', datestr(now));
clearvars -except file param

%% Wavelet
for eegFileNum = 1:length(file.inputFile)
    fprintf('%s: %s is on working.\n', datestr(now), file.inputFile{eegFileNum});
    cd(file.inputDir);
    datData = importdata(file.inputFile{eegFileNum});
    cnt(:,1,:) = datData.data;
    cnt = reshape(cnt, param.epochLength, [], size(cnt,3));
    [TF, ~]=epoch2tf(cnt, param.freqs, param.fs, param.m, param.ki);
    [result.TFi,~, ~]=tf2tfi(TF);    
    result.TFe=zeros([length(param.freqs) size(cnt)]);
    for ch=1:size(cnt,2)
        [tf1,~,~]=tfmorlet(cnt(:,ch),size(cnt,1),param.freqs,param.m,param.ki);
        result.TFe(:,:,ch)=tf1;
    end
    for freqNum = 1:length(param.individualFreq)
        smallFreq = param.freqs > param.individualFreq{freqNum}(1);
        bigFreq = param.freqs < param.individualFreq{freqNum}(2);
        freqArea = find((smallFreq + bigFreq)==2);
        [~, I] = max(max(max(result.TFi(freqArea(1):freqArea(length(freqArea)),:,:),[],2),[],3));
        result.individualFreq(freqNum) = param.freqs(freqArea(1)+I-1);
        I = (param.freqs == result.individualFreq(freqNum));
        for latencyNum = 1:length(param.interestLatency)
            firstTime = ceil((param.interestLatency{latencyNum}(1)+param.zeroLatency) * param.fs + 1);
            lastTime = floor((param.interestLatency{latencyNum}(2)+param.zeroLatency) * param.fs);
            [amplitude, latency] = max(result.TFi(I,firstTime:lastTime,:), [], 2);
            result.individualFreqMaxAmplitude{freqNum}{latencyNum} = shiftdim(squeeze([amplitude, ((latency+firstTime-1) / param.fs -param.zeroLatency)]),1);
        end      
    end    
    cd(file.outputDir);
    save(file.outputFile{eegFileNum}, 'result');
    fprintf('%s: %s is made.\n', datestr(now), file.outputFile{eegFileNum});
    clearvars -except BTB file param eegFileNum
end

fprintf('%s: wavelet code end.\n', datestr(now));
delete(param.POOL);
end

function [TF,TF_power] = epoch2tf(cnt,freqs,fsamp,m,ki,EPOCHUSE)
%% basic set up
if nargin<2, freqs = 5:60; end
if nargin<3, fsamp = 1000; end
if nargin<4, m = 7;	end
if nargin<5, ki = 5; end
if nargin<6, EPOCHUSE = []; end
[tlen,nEpoch,nChn] = size(cnt);
TF			=	zeros(length(freqs), tlen, nEpoch, nChn);
TF_power	=	zeros(length(freqs), tlen, nEpoch, nChn);
if isempty(EPOCHUSE), EPOCHUSE	=	ones(nEpoch,nChn);	end;

%% TF calculation
for ch = 1:nChn
    fprintf('TF calculation %5.2f %% done.\n', (ch/nChn*100));
    [TF_Ep,TFpEp] = epoch2tf_parfor(ch,cnt,freqs,fsamp,m,ki,EPOCHUSE);
    TF		(:,:,:,ch)		=	TF_Ep;
    TF_power(:,:,:,ch)		=	TFpEp;
end
end

function [TF_Ep,TFpEp]=epoch2tf_parfor(ch,cnt,freqs,fsamp,m,ki,EPOCHUSE)
%% basic set up
[tlen,nEpoch,~] = size(cnt);
TF_Ep = zeros(length(freqs), tlen, nEpoch);
TFpEp = zeros(length(freqs), tlen, nEpoch);

%% morlet calculation
parfor ep = 1:nEpoch,
    if EPOCHUSE(ep,ch)==0, continue; end;
    ts = squeeze(cnt(:,ep,ch));
    [tf1,~,tfc1] = tfmorlet(ts,fsamp,freqs,m,ki);
    TF_Ep(:,:,ep) = tfc1;
    TFpEp(:,:,ep) = tf1;
end
end

function [TFi,TFP,TFA]=tf2tfi(TF,EPOCHUSE)
%% basic set up
if nargin<2, EPOCHUSE=[]; end;

%% TFi calculation
TFP=TF.*conj(TF);
TFA=atan2(imag(TF),real(TF));
TFi=squeeze(sum(TFP,3));
if isempty(EPOCHUSE),
    nch=size(TF,4);
    nuse=size(TF,3)*ones(1,nch);
else
    nuse=sum(EPOCHUSE);
end
for i=1:size(TFi,3),
    TFi(:,:,i)=TFi(:,:,i)/nuse(i);
end
end

function [tfpower,tfangle,tfcomplex]=tfmorlet(ts,fs,freqs,m,ki)
%% basic set up
if nargin<3, freqs = 5:60; end
if nargin<4, m=7; end
if nargin<5, ki=5; end

%% TF morlet calculation
lx=length(ts);
tfpower=zeros(length(freqs),lx);
tfangle=tfpower;
tfcomplex=tfpower;
for i=1:length(freqs)
    f0	=	freqs(i);
    w	=	wmorlet(fs,f0,m,ki);
    y	=	conv(ts,w,'same')/fs;
    tfcomplex(i,:)=y;
    tfpower(i,:)=y.*conj(y);
    tfangle(i,:)=atan2(imag(y), real(y));
end
end

function [w,t]=wmorlet(fs,f0,m,ki)
%% basic set up
if nargin<3,	m	=	7; end;
if nargin<4,	ki	=	5; end

%% wmorlet calculation
SD_t	=	m/(2*pi*f0);
ts		=	1/fs;
t		=	0:ts:(ki*SD_t);
t		=	[-t(end:-1:2) t];
A		=	1/sqrt(SD_t*sqrt(pi));
w		=	A .* exp(-t.^2 /(2*SD_t.^2)) .* exp(1i*2*pi*f0 .* t);
end