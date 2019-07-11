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

lowf = dtflowfedit;
highf = dtfhighfedit;
lowf = round(lowf);
highf = round(highf);

output.isadtf = 0;
output.srate = TS.srate;
output.frequency = [lowf highf];
output.dtfmatrixs = DTF(ts,lowf,highf,optimalorder,TS.srate);

sig_dtfmatrix = DTFsigvalues_auto(ts, lowf, highf, optimalorder, TS.srate, 1000, 0.05);    % calculate surrogated DTF values
output.dtfmatrixs = DTFsigtest(output.dtfmatrixs, sig_dtfmatrix);        % get the new DTF value after statistical analysis

[n, m]  = size(ts);     
ne = n-optimalorder;
npmax = m*optimalorder+1; 

% Set the diagonal elements to zeros, and normalize the DTF/ADTF values.
if output.isadtf
    for i = 1:m
        output.dtfmatrixs(:,i,i,:) = 0;
    end
    scale = max(max(max(max(output.dtfmatrixs))));
else
    for i = 1:m
        output.dtfmatrixs(i,i,:) = 0;
    end
    scale = max(max(max(output.dtfmatrixs)));
end
if scale == 0
    scale = 1;
end
output.dtfmatrixs = output.dtfmatrixs / scale;

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

    output.isadtf = 0;
    output.srate = srate;
    output.frequency = [lowf highf];
    output.dtfmatrixs = DTF(ts,lowf,highf,optimalorder,TS.srate);
    sig_dtfmatrix = DTFsigvalues_auto(ts, lowf, highf, optimalorder, TS.srate, 1000, 0.05);    % calculate surrogated DTF values
    output.dtfmatrixs = DTFsigtest(output.dtfmatrixs, sig_dtfmatrix);        % get the new DTF value after statistical analysis
    
% Set the diagonal elements to zeros, and normalize the DTF/ADTF values.
if output.isadtf
    for i = 1:m
        output.dtfmatrixs(:,i,i,:) = 0;
    end
    scale = max(max(max(max(output.dtfmatrixs))));
else
    for i = 1:m
        output.dtfmatrixs(i,i,:) = 0;
    end
    scale = max(max(max(output.dtfmatrixs)));
end
if scale == 0
    scale = 1;
end
output.dtfmatrixs = output.dtfmatrixs / scale;