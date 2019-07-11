function [tfpower,tfangle,tfcomplex]=tfmorlet_min(x,fs,freqs,M,KI,dispmode)
% function [tfpower,tfangle,tfcomplex]=tfmorlet_min(x,fs,freqs,M,KI,dispmode)
%%%%%%%%%%%%%%%%%%%%%%%%
%  [TFPOWER,TFANGLE,TFCOMPLEX]=tfmorlet(X,FS,FREQS,M,KI,dispmode)
%
%INPUT:
%   X: time series data
%   FS: sampling frequency
%   FREQS: frequencies of interest
%   M: Wavelet factor 
%   KI: size of wavelet waveform
%   DISPMODE: display
% OUPUT:
%   TF: power of time frequency
%   TFA: phase of time frequency 
% 2007/10/04 
% by Hae-Jeong Park, Yonsei Univ. MoNET 70년 7월 4일 생일
% email: hjpark0@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<4, M=[]; end;
if nargin<5, KI=[]; end;
if nargin<6, dispmode=0; end;

if isempty(M), M=7; end;
if isempty(KI), KI=5; end;

lx=length(x); t1=[1:lx]/fs;
tfpower=zeros(length(freqs),lx); tfangle=tfpower; tfcomplex=tfpower;

for i=1:length(freqs),
    f0=freqs(i);
    [w,t]=wmorlet_min(fs,f0,M,KI);
    sigmat=M/(2*pi*f0); % 이 부분 계산이 안 맞아서 계산 방법을 배운 후 정정
    
%     lw=length(w);
%     del=floor((lw-1)/2);    
    
    y=conv(x,w,'same')/fs;
    
%     y=y(del+1:del+lx);
    
    tfcomplex(i,:)=y;
    tfpower(i,:)=y.*conj(y);
    tfangle(i,:)=atan2(imag(y), real(y));
%     tfmin(i,:)=conv(x.^2,w,'same'); % in the original file, this line didn't exist.
%     tftallon(i,:)=(abs(y)).^2;
%% fieldtrip
%     yy = (2*abs(y)/fs).^2;
%     yyy = yy(ceil(length(w)/2):length(yy)-floor(length(w)/2));
end;

if dispmode,
    show(abs(tfpower),1,t1,freqs);
    set(gca,'YDir','normal');
end;