function [cxy,pxy,pxx,pyy,f]=multitaper_cohere(x,y,nfft,fs,E,noverlap,dflag,n_tapers);

% multitaper estimate of cohere. 

if mod(nfft,2)==0
length_tapers=nfft/2+1;
else
    length_tapers=nfft/2;
end

cxy=zeros(length_tapers,1);
pxx=zeros(length_tapers,1);
pyy=zeros(length_tapers,1);
cxy1=zeros(length_tapers,1);
pxx1=zeros(length_tapers,1);
pyy1=zeros(length_tapers,1);
f=zeros(length_tapers,1);
x=x-mean(x);
y=y-mean(y);

for I=1:n_tapers
    [cxy1,f]=csd(x,y,nfft,fs,E(:,I),noverlap,dflag);
    cxy=cxy+cxy1;
    [pxx1,f]=psd(x,nfft,fs,E(:,I),noverlap,dflag);
    pxx=pxx+pxx1;
    [pyy1,f]=psd(y,nfft,fs,E(:,I),noverlap,dflag);
    pyy=pyy+pyy1;
end

cxy=cxy/n_tapers;
pxx=pxx/n_tapers;
%pxx=pxx;
pyy=pyy/n_tapers;

% compute the coherence
pxy=cxy;
cxy=abs(cxy).^2./pxx./pyy;


