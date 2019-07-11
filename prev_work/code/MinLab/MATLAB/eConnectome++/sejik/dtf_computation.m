function output = dtf_computation(TS, startpoint, endpoint, dtflowfedit, dtfhighfedit, optimalorder, srate)

% get time series
startpoint = round(startpoint);
endpoint = round(endpoint);
startpoint = max(1,min(startpoint, TS.points));
endpoint = max(1,min(endpoint, TS.points));
if startpoint > endpoint
    tmp = endpoint;
    endpoint = startpoint;
    startpoint = tmp;
end
ts = TS.data(:,startpoint:endpoint)';

% get frequency scope
lowf = dtflowfedit;
highf = dtfhighfedit;
lowf = round(lowf);
highf = round(highf);
maxf = TS.srate/2;
lowf = max(1,min(lowf, maxf));
highf = max(1,min(highf, maxf));
if lowf >= highf, error('Low frequency must be lower than high frequency!'); end

% get optimal order specified
if optimalorder < 1, error('Order CAN NOT be lower than 1!'); end

optimalorder = round(optimalorder);
optimalorder = max(1,min(optimalorder, 20));

[n, m] = size(ts);
ne = n-optimalorder;
npmax = m*optimalorder+1; 
if ne<=npmax, error('Time series too short and results may not be precise'); end

% compute the DTF/ADTF values
output.isadtf = 0;
output.srate = TS.srate;
output.frequency = [lowf highf];
output.dtfmatrixs = DTF(ts,lowf,highf,optimalorder,TS.srate);

shufftimes	=	1000;
siglevel	=	0.05;
sig_dtfmatrix = DTFsigvalues(ts, lowf, highf, optimalorder, TS.srate, [], []);    % calculate surrogated DTF values
output.dtfmatrixs = DTFsigtest(output.dtfmatrixs, sig_dtfmatrix);        % get the new DTF value after statistical analysis

% Set the diagonal elements to zeros, and normalize the DTF/ADTF values.
if output.isadtf
%	for i = 1:m, output.dtfmatrixs(:,i,i,:) = 0; end
	output.dtfmatrixs(:,1:m,1:m,:) = 0;
%	scale = max(max(max(max(output.dtfmatrixs))));
	scale = max(output.dtfmatrixs(:));
else
%	for i = 1:m, output.dtfmatrixs(i,i,:) = 0; end
	output.dtfmatrixs(1:m,1:m,:) = 0;
%	scale = max(max(max(output.dtfmatrixs)));
	scale = max(output.dtfmatrixs(:));
end
if scale == 0, scale = 1; end

output.dtfmatrixs = output.dtfmatrixs / scale;

