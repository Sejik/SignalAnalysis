function [TF,TF_power]=epoch2tf_min(eEEG,freqs,fsamp,m,ki,EPOCHUSE)
% function [TF]=epoch2tf_min(eEEG,freqs,fsamp,m,ki,EPOCHUSE)
%%%%%%%%%%%%%%%%%%%%%%%%
%  TF=epoch2tf(eEEG,freqs,m,ki)
% Usage:
%  >> TF=epoch2tf(eEEG,freqs,fsamp,m,ki)
%
% Inputs:
%   eEEG: epoched EEG data (time points x epochs x channels)
%   FREQS: frequencies of interest
%   FSAMP: sampling frequency
%   M: Wavelet factor 
%   KI: size of wavelet waveform
% Outputs:
%   TF: time frequency complex maps for each epoch
%       [freq x time x epoch x chan]
% 2007/10/04 
% by Hae-Jeong Park, Yonsei Univ. MoNET
% email: hjpark0@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%


if nargin<2, freqs=[]; end;
if nargin<3, fsamp=1000; end;
if nargin<4, m=7; end;
if nargin<5, ki=5; end;
if nargin<6, EPOCHUSE=[]; end;

if isempty(freqs),   freqs=5:60; end;                       % frequency window level

[tlen,numepoch,chn]=size(eEEG);

TF=zeros(length(freqs),tlen,numepoch,chn);  
if isempty(EPOCHUSE), EPOCHUSE=ones(numepoch,chn);end;

for c=1:chn,
    idx=[]; ridx=[];
    fprintf('ch:%d of %d...\n',c,chn);
    for e=1:numepoch,
        if EPOCHUSE(e,c)==0, continue; end;        
        x=squeeze(eEEG(:,e,c));
        [tf1,tfa1,tfc1]=tfmorlet_min(x,fsamp,freqs,m,ki);
        TF(:,:,e,c)=tfc1;
        TF_power(:,:,e,c)=tf1;
    end;
end;

