%% DTF4 ver 0.10
%
% DTF by using FREQUENCY DOMAIN MVAR ANALYSIS
% -----
% It is modified code by referenced eMVAR/fdMVAR.m : tigoum
%	이 코드의 알고리즘이 원래 eConnectome/ARfit의 DTF보다 비약적으로 더 빠름
%	Inspired by DTF(by fgMVAR) & multinv(by Xiaodong Qi)]

%%% inputs:
%	Am=[A(1)...A(Order)]: M*pM matrix (2D) of the MVAR model coefficients
%						(strictly causal model)
%	fqLow		: the lowest frequency bound to compute the DTF
%	fqHigh		: the highest frequency bound to compute the DTF
%	Order				: the order of the MVAR model
%	fs				: the sampling frequency 

%%% outputs:
% DTF= Directed Transfer Function (Eq. 11 but with sigma_i=sigma_j for each i,j)
%	H				: Tranfer Function Matrix (Eq. 6)
%	f				: frequency vector

% License
% ==============================================================
% This program is part of the mLib by minlab tools.
% 
% Copyright (C) 2015 MinLAB. of the University of Korea. All rights reserved.
% Correspondence: tigoum@korea.ac.kr
% Web: mindbrain.korea.ac.kr
%
% ==============================================================================
% Revision Logs
% ------------------------------------------------------
% Program Editor, not Author: Ahn Min-Hee @ tigoum, University of Korean, KOREA
% User feedback welcome: e-mail::tigoum@korea.ac.kr
% ......................................................
% first created at 2016/06/25
% last  updated at 2016/06/26
% ......................................................
% Release Version 0.10 beta
% Ver 0.10 : 기존 DTF, DTF2, DTF3 를 비약적 개선하여 성능을 극대화 함
% ==============================================================================

function [gamma2, H,f] = DTF4_fdMVAR_multinv(ts, fqLow, fqHigh, Order, fs)

	if nargin < 5, fs		= 500; end
	if nargin < 4, Order	= 1; end
	if nargin < 3, fqHigh	= 30; end
	if nargin < 2, fqLow	= 1; end
	
% The number of frequencies to compute the DTF over
	f			=	[fqLow:fqHigh];

% Create the MVAR matrix for the time series
	[~, Am]		=	arfit(ts,Order,Order);
	M			=	size(Am,1);						% Am has dim M*pM

%% Initializations: spectral matrices have M rows, M columns and are calculated
%	at each of the N frequencies

%% matrix from which M*M blocks are selected to calculate spectral functions
	A			=	reshape([eye(M) -Am], M, M, []);% 2D -> 3D
	A			=	repmat(A, 1,1,1, length(f));	% M x M x Order x len(f)

%% computation of spectral functions
	%%% Coefficient matrix in the frequency domain
	% indicization (:,k*M+(1-M:0)) extracts the k-th M*M block from the matrix B
	%	(A(1) is in the second block, and so on)
%	z			=	pi*(1/fs)*2i;
%	w			=	[];
%	w(1,1,:,:)	=	exp(-z* [0:Order]'*f);			% gen odr'*f = odr by f : 2D
	w(1,1,:,:)	=	exp(-pi*1/fs*2i* [0:Order]'*f);	% gen odr'*f = odr by f : 2D
	w			=	repmat(w, M, M, 1, 1);			% extend, 4D: ch*ch * odr * f

	%%% Transfer matrix (after Eq. 6)
	H			=	multinv( squeeze(sum(A .* w, 3)) );		% reduced by Order
	% Inverse each 2D slice of an array (M) with arbitrary dimensions

	%%% denominators of DC, PDC, GPDC for each m=1,...,num. channels
	deno		=	sqrt( sum(abs(H).^2, 2) );		% calc 3D->2D: ch x ch(1) x f
	% for the DTF - don't use covariance information

%% Directed Transfer Function (Eq. 11 without sigmas)
	%	& conv complex -> real power
	gamma2		=	abs( (H ./ repmat(deno, 1,M,1)) .^2 );	% return 3D

