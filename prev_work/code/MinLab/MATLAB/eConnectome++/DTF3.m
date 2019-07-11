% It is modified code by referenced eMVAR/fdMVAR.m : tigoum
%	이 코드의 알고리즘이 원래 eConnectome/ARfit의 DTF보다 비약적으로 더 빠름

%% FREQUENCY DOMAIN MVAR ANALYSIS
% REFERENCE: Luca Faes and Giandomenico Nollo (2011). Multivariate Frequency Domain Analysis of Causal Interactions in Physiological Time Series,
% Biomedical Engineering, Trends in Electronics, Communications and Software, Anthony N. Laskovski (Ed.), ISBN: 978-953-307-475-7, InTech,  
% Available from: http://www.intechopen.com/articles/show/title/multivariate-frequency-domain-analysis-of-causal-interactions-in-physiological-time-series 

%%% inputs: 
% Am=[A(1)...A(p)]: M*pM matrix of the MVAR model coefficients (strictly causal model)
% N= number of points for calculation of the spectral functions (nfft)
% fs= sampling frequency

%%% outputs:
% DTF= Directed Transfer Function (Eq. 11 but with sigma_i=sigma_j for each i,j)
% H= Tranfer Function Matrix (Eq. 6)
% f= frequency vector

function [gamma2, H,f] = DTF3_fdMVAR(ts,low_freq,high_freq,p,fs)
%{
if nargin<2, Su = eye(M,M); end; % if not specified, we assume uncorrelated noises with unit variance as inputs 
if nargin<3, N = 512; end;
if nargin<4, fs= 1; end;     
if all(size(N)==1),	 %if N is scalar
    f = (0:N-1)*(fs/(2*N)); % frequency axis
else            % if N is a vector, we assume that it is the vector of the frequencies
    f = N; N = length(N);
end;
%}
% The number of frequencies to compute the DTF over
f				=	[low_freq:high_freq];
N				=	length(f);

% The sampling period
dt				=	1/fs;

% Create the MVAR matrix for the time series
[w,Am]			=	arfit(ts,p,p);
M				=	size(Am,1); % Am has dim M*pM
%p = size(Am,2)/M; % p is the order of the MVAR model

%z = i*2*pi/fs;
z = i*2*pi/dt;

%% Initializations: spectral matrices have M rows, M columns and are calculated at each of the N frequencies
H=zeros(M,M,N); % Transfer Matrix
DTF=zeros(M,M,N); % directed transfer function - Defined as Kaminski 1991
deno=zeros(M,1); %denominator for DC (column!)

A = [eye(M) -Am]; % matrix from which M*M blocks are selected to calculate spectral functions

%% computation of spectral functions
for n=1:N, % at each frequency

	%%% Coefficient matrix in the frequency domain
	As = zeros(M,M); % matrix As(z)=I-sum(A(k))
	for k = 1:p+1,
		As = As + A(:,k*M+(1-M:0))*exp(-z*(k-1)*f(n));  %indicization (:,k*M+(1-M:0)) extracts the k-th M*M block from the matrix B (A(1) is in the second block, and so on)
	end;

	%%% Transfer matrix (after Eq. 6)
	H(:,:,n)  = inv(As);

	%%% denominators of DC, PDC, GPDC for each m=1,...,num. channels
	for m = 1:M,
		deno(m)=sqrt((abs(H(m,:,n)).^2) * ones(M,1)); % for the DTF - don't use covariance information
	end;

	%%% Directed Transfer Function (Eq. 11 without sigmas)
	gamma2(:,:,n) = H(:,:,n) ./ deno(:,ones(M,1));
end;

	gamma2			=	abs(gamma2.^2);					% complex -> real power
