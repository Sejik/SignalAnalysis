function output = dtf_computation(TS,	startpoint, endpoint,			...
										dtflowfedit, dtfhighfedit,		...
										optimalorder)

% get time series
startpoint			=	round(startpoint);
endpoint			=	round(endpoint);
startpoint			=	max(1,min(startpoint, TS.points));
endpoint			=	max(1,min(endpoint, TS.points));
if startpoint > endpoint
    tmp				=	endpoint;
    endpoint		=	startpoint;
    startpoint		=	tmp;
end
%% NOTE, very important for the dim's structure changing
ts					=	TS.data(:,startpoint:endpoint)';	%% BA x tp -> tp x BA

% get frequency scope
lowf				=	dtflowfedit;
highf				=	dtfhighfedit;
lowf				=	round(lowf);
highf				=	round(highf);
maxf				=	TS.srate/2;
lowf				=	max(1,min(lowf, maxf));
highf				=	max(1,min(highf, maxf));
if lowf >= highf, error('Low frequency must be lower than high frequency!'); end

% get optimal order specified that refered from pdfplotorder.
[n, m]				=	size(ts);							% n==tp, m==BA
[minorder maxorder]	=	deal(1, 20);						% default range
%minorder			=	min(max(round(minorder),1), 20);
%maxorder			=	min(max(round(maxorder),1), 20);
%if minorder > maxorder, [minorder maxorder] = deal(maxorder, minorder); end

[fpeERR, sbcERR]	=	deal([], []);
for ix = minorder:maxorder									% find max opti-order
	ne				=	n-ix;
	npmax			=	m*ix+1;
	if ne <= npmax, break; end

	[w,A,C,SBC,FPE]	=	arfit(ts,ix,ix);
	fpeERR(ix)		=	FPE;
	sbcERR(ix)		=	SBC;
end
if ix <= 1, error('Time series too short or orders [1] is too high!'); end

% calc for optimal orders
%maxfpe				=	max(fpeERR);
%maxsbc				=	max(sbcERR);
%fpe_optorder		=	find(fpeERR == min(fpeERR),1);
sbc_optorder		=	find(sbcERR == min(sbcERR),1);
optimalorder		=	sbc_optorder;	% set suggested optimal order automa..ly

% check optimal order
if optimalorder < 1, error('Order CAN NOT be lower than 1!'); end

optimalorder		=	round(optimalorder);
optimalorder		=	max(1,min(optimalorder, 20));

ne					=	n-optimalorder;
npmax				=	m*optimalorder+1; 
if ne<=npmax, error('Time series too short and results may not be precise'); end

% compute the DTF/ADTF values
output.isadtf		=	0;
output.srate		=	TS.srate;
output.frequency	=	[lowf highf];
%output.dtfmatrixs	=	DTF(ts,lowf,highf,optimalorder,TS.srate);
output.dtfmatrixs	=	DTF4(ts,lowf,highf,optimalorder,TS.srate);

shufftimes			=	1000;
siglevel			=	0.05;
%sig_dtfmatrix		=	DTFsigvalues(ts,lowf,highf,optimalorder,TS.srate,shufftimes,siglevel);
sig_dtfmatrix		=	DTFsigvalPar(ts,lowf,highf,optimalorder,TS.srate,[],[]);
						% calculate surrogated DTF values
%output.dtfmatrixs	=	DTFsigtest(output.dtfmatrixs, sig_dtfmatrix);
output.dtfmatrixs	=	DTFsigtest2(output.dtfmatrixs, sig_dtfmatrix);
						% get the new DTF value after statistical analysis

% Set the diagonal elements to zeros, and normalize the DTF/ADTF values.
if output.isadtf
	for i			=	1:m, output.dtfmatrixs(:,i,i,:) = 0; end
%	output.dtfmatrixs(:,1:m,1:m,:)	=	0;
%	scale			=	max(max(max(max(output.dtfmatrixs))));
%	scale			=	max(output.dtfmatrixs(:));
else
	%% remove for diagonal index : It is already processed at DTFsigtest2()
%	for i			=	1:m, output.dtfmatrixs(i,i,:) = 0; end
%	output.dtfmatrixs(1:m,1:m,:)	=	0;
%	scale			=	max(max(max(output.dtfmatrixs)));
end
scale				=	max(output.dtfmatrixs(:));
if scale == 0, scale=	1; end

output.dtfmatrixs	=	output.dtfmatrixs / scale;

