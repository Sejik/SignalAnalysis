function [new_gamma2]	=	DTFsigvalues(ts, fqLow, fqHigh, p, fs, shufftimes, siglevel)
% DTFsigvalues - compute statistical significance values for relative DTF values
%
% Input:	ts - the time series where each column is the temporal data from a single trial.
%			fqLow - the lowest frequency to perform DTF analysis.
%			fqHigh - the highest frequency to perform DTF analysis.
%			p - the order of the model.
%			fs - the sampling rate of the data.
%			siglevel - the significance level, default is 0.05.
%			shufftimes - the shuffling times, default is 1000.
%			handle - the handle of the uicontrol for displaying computation
%                         progress, the progress will be displayed in the command window 
%                         of MATLAB if handle				=	[]. 
%
% Output:	new_gamma2 - the significant points from the surrogate DTF analysis
%
% Description: This function generates surrogate datasets by phase shifting
%              the original time series and then performs DTF analysis on
%              these new time series for statistical testing. The output is
%              in the form gamma2_sig(a,b,c) where a = the sink channel,
%              b = the source channel, and c = the frequency index.
%
% Program Author: Christopher Wilke, University of Minnesota, USA
%
% User feedback welcome: e-mail: econnect@umn.edu
%

% License
% ==============================================================
% This program is part of the eConnectome.
% 
% Copyright (C) 2010 Regents of the University of Minnesota. All rights reserved.
% Correspondence: binhe@umn.edu
% Web: econnectome.umn.edu
%
% This program is free software for academic research: you can redistribute it and/or modify
% it for non-commercial uses, under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see http://www.gnu.org/copyleft/gpl.html.
%
% This program is for research purposes only. This program
% CAN NOT be used for commercial purposes. This program 
% SHOULD NOT be used for medical purposes. The authors 
% WILL NOT be responsible for using the program in medical
% conditions.
% ==========================================

% Revision Logs
% ==========================================
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================


% Default sampling rate is 400 Hz
if nargin < 5, fs		=	400; end

% Number of shuffled datasets to create
if isempty(shufftimes),	nSF		= 1000; else nSF	= shufftimes; end
if isempty(siglevel),	tvalue	= 0.05; else tvalue	= siglevel; end

% Number of frequencies
f						=	[fqLow:1:fqHigh];
nFQ						=	length(f);

% Number of channels in the time series
nCh						=	size(ts,2);				%% tp x BA

%POOL					=	S_paraOpen(true);		% 강제로 restart
POOL					=	S_paraOpen();			% 알아서 restart

% Number of surrogate datasets to generate
%for ix = 1:nSF				% single step
	% Display the progress of the function on a uicontrol
%	rate				=	round(100 * ix / nSF);
%	progress			=	['Completing ' num2str(rate) '%'];

	% --------------------------------------------------
	sForm				=	[ '%' num2str( floor(log10(nSF))+1 ) 'd' ];
	stdout				=	1;

%	[StartSf, FinishSf]	=	deal(1, size(ts,1));
	[StartSf, FinishSf]	=	deal(1, nSF);
	fprintf('Surrogating [%d:%d] on [Epoch/Brodmann] level.\n', ...
			StartSf, FinishSf);

	WorkSf				=	StartSf;				% 작업시작 epoch 지점
%	nROI				=	length(labels);
%	nSF					=	FinishSf -StartSf +1;
%	SrcROI				=	cell(1, nSF);			% compute ROI time series
	NumWorkers			=	nSF / 10;

	SigLen				=	floor(tvalue * nSF)+1;
	%new_gamma			=	zeros(SigLen-1,nCh,nCh,nFQ);
	new_gamma			=	zeros(SigLen-1 +NumWorkers, nCh, nCh, nFQ);

%	gamma2				=	zeros(nSF,nCh,nCh,nFQ);
%	for		work		=	[WorkSf		: POOL.NumWorkers	: FinishSf]
%		WorkStart		=	work -StartSf +1;		% ix 가 1부터 시작하게!
%		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishSf) -StartSf +1;
	for		work		=	[WorkSf		: NumWorkers	: FinishSf]
		WorkStart		=	work -StartSf +1;		% ix 가 1부터 시작하게!
		WorkEnd			=	min(work+NumWorkers-1, FinishSf) -StartSf +1;
		% 이 경우, workend 가 numworker의 배수가 아니면, 끝에 모자란 부분 감안

		% 진행 경과 판독 및 출력
		fprintf(stdout,['+ %s : COMPUTE time series for [' sForm ':' sForm ']'...
' / %d = %6.3f%%\r'], 'Surrogation', WorkStart, WorkEnd, nSF, WorkEnd/nSF*100);

%		ParBLK			=	[WorkStart : WorkEnd];	% blk idx for parallel
		ParBLK			=	[1 : WorkEnd-WorkStart+1];	% 수행횟수가 중요할 뿐
		gamma2			=	zeros(length(ParBLK),nCh,nCh,nFQ);
	parfor	ix			=	ParBLK
		% Generate a surrogate time series
%{
		newts			=	zeros(size(ts,1), nCh);	% pre allocation
		for jx=1:nCh
			Y			=	fft(ts(:,jx));
			Pyy			=	sqrt(Y.*conj(Y));
			Phyy		=	Y./Pyy;
			index		=	[1:size(ts,1)];
			index		=	surrogate(index);
			Y			=	Pyy.*Phyy(index);
			newts(:,jx)	=	real(ifft(Y));
		end
%}
		Y				=	fft(ts);				% 1000 x 30
		Yp				=	sqrt( Y .* conj(Y) );
		Yph				=	Y ./ Yp;
		% 각 ch 단위로 tp 범위를 randperm 하는 것(위 loop 방식) 이 아니라
		% 2D 의 각 위치(1D에 대응)에 대한 indexing을 해야 올바른 randperm 이 됨
		index			=	randperm(numel(Yph));	% 통짜배기 2D surrogate
		index			=	reshape(index, size(Yph,1), []);
%		index			=	reshape([1:numel(Yph)], size(Yph,1), []);
		Y				=	Yp .* Yph(index);
		newts			=	real(ifft(Y));

		% Compute the DTF value for each surrogate time series
		gamma2(ix,:,:,:)=	DTF4(newts, fqLow, fqHigh, p, fs);
	end	% parfor concurrent

		% Save the surrogate DTF values
		new_gamma(SigLen:SigLen+length(ParBLK)-1,:,:,:)	=	gamma2;	% attach
		new_gamma(SigLen+length(ParBLK):end,:,:,:)		=	0;		% clear

		% And, select top significant by ordering
		new_gamma					=	sort(new_gamma,'descend');

		% Remove non significant
%		new_gamma(SigLen:end,:,:,:)	=	[];			% delete leasts data
%		new_gamma(SigLen:end,:,:,:)	=	0;			% clear
	end	% for work block

%end	% for single step

% take the surrogated DTF values at a certain signficance
%{
new_gamma2				=	zeros(nCh,nCh,nFQ);
for ix					=	1:nCh
	for jx				=	1:nCh
		for k			=	1:nFQ
			new_gamma2(ix,jx,k)		=	new_gamma(SigLen-1,ix,jx,k);
		end
	end
end
%}
%new_gamma2				=	squeeze(new_gamma(end,:,:,:));
%new_gamma				=	sort(gamma2, 'descend');
new_gamma2				=	squeeze(new_gamma(SigLen-1,:,:,:));

