function [tfpower,tfangle,tfcomplex]=tfmorlet_min_AmH(x,fs,freqs,M,KI,dispmode)
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
% by Hae-Jeong Park, Yonsei Univ. MoNET
% email: hjpark0@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<4, M=[]; end;
if nargin<5, KI=[]; end;
if nargin<6, dispmode=0; end;

if isempty(M), M=7; end;
if isempty(KI), KI=5; end;

if ~freqs, fprintf('\n[tfmorlet_min_AmH]: WARNING: Freqs. must be not 0.\n'); end

lx=length(x);
tfpower=zeros(length(freqs),lx); tfangle=tfpower; tfcomplex=tfpower;

for i=1:length(freqs),
	f0	=	freqs(i);
%	[w,t]=wmorlet_min(fs,f0,M,KI);		%return: wieght vector & time vector
	w	=	wmorlet_min_AmH(fs,f0,M,KI);	%return: wieght vector & time vector
%	w	=	mf_cmorlet(f0,fs,6,1,0.21);
%	sigmat=M/(2*pi*f0);					%wmorlet_min()에서 이미 계산됨

%	[psi,t]=cmorwavf(LU,LB,N,FB,FC);
%	[psi,t]=cmorwavf(-7,7,500,1.5,f0);
%	complex morlet wavelet
%	Calling Sequence
%	[PSI,X]= cmorwavf(LB,UB,N,FB,FC)
%	Parameters
%	LB : low bound
%	UB : upper bound
%	N  : number of data points
%	FB : positive bandwidth parameter
%	FC : wavelet center frequency
%	PSI: wavelet
%	X  : time grid
%	Description
%	cmorwavf is an utility to get complex morlet wavelet waveform.
%	Examples
%	[PSI,X]=cmorwavf(-8,8,1000,1.5,1);

%	lw=length(w);
%	del=floor((lw-1)/2);

	y	=	conv(x,w,'same')/fs;		%convolution:'same' mean indentical shape
%	y	=	conv_srz(x',w) / fs;		%more faster
%	fprintf('x=%d, w=%d, y-1=%d,', length(x), length(w), length(y));
%	y	=	y( [1:length(x)] + (length(w)-1)/2 );	%time win 조정
%	y	=	y( [1:length(x)] );
%	fprintf('y=%d \n', length(y));

%	y=y(del+1:del+lx);

	tfcomplex(i,:)=y;
	tfpower(i,:)=y.*conj(y);
	tfangle(i,:)=atan2(imag(y), real(y));
%	 tfmin(i,:)=conv(x.^2,w,'same'); % in the original file, this line didn't exist.
%	 tftallon(i,:)=(abs(y)).^2;
%% fieldtrip
%	 yy = (2*abs(y)/fs).^2;
%	 yyy = yy(ceil(length(w)/2):length(yy)-floor(length(w)/2));
end;

if dispmode,
	t1	=	[1:lx]/fs;
	show(abs(tfpower),1,t1,freqs);
	set(gca,'YDir','normal');
end;
