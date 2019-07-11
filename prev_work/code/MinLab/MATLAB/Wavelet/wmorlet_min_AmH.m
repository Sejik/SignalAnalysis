function [w,t]=wmorlet_min_AmH(fs,f0,m,ki)
%WMORLET  Calculate the Morlet Wavelet.
%       [w,t]=wmorlet(fs,f0,m,ki)
%       input:
%           fs: sampling frequency
%           f0: frequency of interest
%           m:  wavelet factor  [m] that determines wavelet family
%               m=f0/SD_t = f0*(2*pi*SD_t)
%           ki: size of envelop k * SD_t
%       output:
%           w: weight function
%           t: time info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [1] C. Tallon-Baudry, O. Bertrand, F. Peronnet and J. Pernier, 1998.
% Induced \gamma-Band Activity during the Delay of a Visual Short-term
% memory Task in Humans. The Journal of Neuroscience (18): 4244-4254.
%         by PHJ, 3/15/2001

if nargin<3,	m	=	7; end;
if m<5,			fprintf('Too low m'); end;
if nargin<4,	ki	=	5; end	% Default timing [-6 sec. to 6 sec.]
if ki<3,		fprintf(['WARNING: Small time interval. '					...
						'Wavelet ends may be too abrupt.\n']); end

%SD_t	=	2 * SD_f / pi;			% original equation
SD_t	=	m/(2*pi*f0);

%t = [0:1/fs:ki*SD_t];
%t = [-t(end:-1:2) t];
%t		=	-3.5*SD_t : 1/fs : 3.5*SD_t;	% range vector
ts		=	1/fs; %sample period, second
t		=	[0:ts:ki*SD_t]; % half length of wavelet used for analysis.  more long, more precisely, but slower, 5 is used here
t		=	[-t(end:-1:2) t]; %whole length, plus negative part

% Morlet wavelet with normalization factor by A
%A		=	1/sqrt(2*pi*SD_t^2);		%A1= 0.3581(cond: fs,f0,m = 500,1,7)
A		=	1/sqrt(SD_t*sqrt(pi));		%A2= 0.7116(cond: same)
%B		=	sqrt(2/pi)/SD_t;			% Gabor normalization factor == 2* A1
%w		=	A*exp(-t.^2/(2*SD_t^2)).*exp(i*2*pi*f0.*t)
w		=	A .* exp(-t.^2 /(2*SD_t.^2)) .* exp(i*2*pi*f0 .* t);	%vector

% Morlet wavelet with normalization factor by spm5
%w		=	exp(-t.^2 / (2*SD_t^2)) .* exp(1i*2*pi*f0 * t);
%w		=	w./(sqrt(0.5*sum( real(w).^2 + imag(w).^2 )));	%norm by spm5
%  w=A*w;
% HJ Park: w=2*w./sum(abs(w)); %norm(w);
%w   = w./(sqrt(0.5*sum(real(w).^2 + imag(w).^2))); %by spm5

%w		=	SD_t/sqrt(pi) * exp(-SD_t^2 * t.^2) .* exp(i*2*pi*f0 .* t);
			%it is refered from the book : vibration-based condition

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
