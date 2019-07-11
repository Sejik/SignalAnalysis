function [w,t]=wmorlet_min(fs,f0,m,ki)
%WMORLET  Calculate the Morlet Wavelet.
%       [w,t]=wmorlet(fs,f0,m,ki)
%       input:
%           fs: sampling frequency
%           f0: frequency of interest
%           m:  wavelet factor  [m] that determines wavelet family 
%               m=f0/sigmaf = f0*(2*pi*sigmat)
%           ki: size of envelop k * sigmat
%       output:
%           w: weight function
%           t: time info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [1] C. Tallon-Baudry, O. Bertrand, F. Peronnet and J. Pernier, 1998.
% Induced \gamma-Band Activity during the Delay of a Visual Short-term
% memory Task in Humans. The Journal of Neuroscience (18): 4244-4254.
%         by PHJ, 3/15/2001

if nargin<3,
    m=7;
end;
if m<5;
    fprintf('Too low m');
end;
if nargin<4              % Default timing [-6 sec. to 6 sec.]
	ki=5;
end
if ki<3
	fprintf('WARNING: Small time interval. Wavelet ends may be too abrupt.\n');
end
	
sigmat=m/(2*pi*f0);

% t = [0:1/fs:ki*sigmat];
% t = [-t(end:-1:2) t];    
t=-3.5*sigmat:1/fs:3.5*sigmat;

%A = 1/sqrt(2*pi*sigmat^2);
A=1/sqrt(sigmat*sqrt(pi)); % Morlet wavelet normalizatio factor
B=sqrt(2/pi)/sigmat; % Gabor normalization factor

w=A*exp(-t.^2/(2*sigmat^2)).*exp(i*2*pi*f0.*t);
%  w=A*w;
% HJ Park: w=2*w./sum(abs(w)); %norm(w);
%w   = w./(sqrt(0.5*sum(real(w).^2 + imag(w).^2))); %by spm5

%%
% function M = waveletfam(foi,Fs,width)
% dt = 1/Fs;
% for k=1:length(foi)
%   sf = foi(k)/width;
%   st = 1/(2*pi*sf);
%   toi=-3.5*st:dt:3.5*st;
%   A = 1/sqrt(st*sqrt(pi));
%   M{k}= A*exp(-toi.^2/(2*st^2)).*exp(i*2*pi*foi(k).*toi);
end
%%

% if 0,
%     plot(real(w));
%     pause(0.1);
% end;