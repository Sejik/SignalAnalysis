function [roiResult, sourceResult] = SJ_source(param, data)
model.italyskin = load('italyskin.mat');
model.cutskin = load('cutskin.mat');
model.italyskinxy = load('italyskin-in-xy.mat');
model.italyskinxyz = load('italyskin-in-xyz.mat');
model.colinbemskin = load('colinbemskin.mat');
model.cortex = load('colincortex.mat');
XI = model.cortex.colincortex.Vertices;
model.bemcortex = load('colinbemcortex.mat');
model.neighbors = load('neighbors.mat');
transmatrix = load('LargeTransMatrix.mat');

for roiNum = 1:length(param.roi)
    labels{roiNum} = param.roiName{roiNum};
    centers(roiNum,1:3) = param.roi(roiNum,:);    
    dists = sqrt( (XI(:,1)-centers(roiNum, 1)).^2 + ...
        (XI(:,2)-centers(roiNum, 2)).^2 + (XI(:,3)-centers(roiNum, 3)).^2 );
    vidx = find(dists<param.roiRadius);
    vertices{roiNum} = {vidx};
end
roiResult.labels = labels;
roiResult.centers = centers;
roiResult.vertices = vertices;

for fileNum = 1:size(data, 1)
    currentData = squeeze(data(fileNum, 1:length(param.rawChannel), :));
    EEG.name = 'currentData';
    EEG.type = 'EEG';
    EEG.nbchan = size(currentData, 1);
    EEG.points = size(currentData, 2);
    EEG.srate = param.fs;
    EEG.labeltype = 'standard';
    EEG.labels = param.rawChannel';
    EEG.data = currentData;
    EEG.unit = 'uV'; % just anouncement
    EEG.vidx = 1:EEG.nbchan;
    EEG.locations = stdLocations(EEG.labels);    
    vdata = EEG.data(EEG.vidx,:);
    EEG.min = min(min(vdata));
    EEG.max = max(max(vdata));
    k = cell2mat({EEG.locations(EEG.vidx).colinbemskinidx});
    model.transmatrix = transmatrix.TransMatrix(k,:);
    [model.U, model.s, model.V] = csvd(model.transmatrix);
    model.k = cell2mat({EEG.locations(EEG.vidx).italyskinidx});
    model.electrodes.labels = EEG.labels(EEG.vidx);
    model.electrodes.locations = model.italyskin.italyskin.Vertices(model.k,:);
    model.X = model.italyskinxy.xy(model.k,1);
    model.Y = model.italyskinxy.xy(model.k,2);
    zmin = min(model.italyskinxyz.xyz(model.k,3));
    Z = model.italyskinxyz.xyz(:,3);
    model.interpk = find(Z > zmin);
    model.XI = model.italyskinxy.xy(model.interpk,1);
    model.YI = model.italyskinxy.xy(model.interpk,2);
    options.step = round(EEG.points/10);
    if options.step <= 0
        options.step = 2;
    end
    options.vidx = EEG.vidx;
    options.currentpoint = 1;
    options.auto = 0;
    options.method = 'mn';
    options.lamda = 0;
    options.autocorner = 1;
    options.threshold = 0.0;
    options.HWHM = 3;
    options.startepoch = 1;
    options.endepoch = param.epochLength;
    options.alpha = 1;
    options.cutskin = 0;
    options.labels = 0;
    options.electrodes = 0;
    options.sensorcaxis = 'local';
    options.sensorminmax = [EEG.min, EEG.max];
    options.sourcecaxis = 'local';
    options.sourceminmax = [realmax, realmin];
    options.usebem = 0;
    options.currymatrix = 0;
    for i = options.startepoch : options.endepoch
        electrodesV = EEG.data(options.vidx,i);
        if isequal(options.method,'mn')
            if options.autocorner
                options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');
            end
            cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
        elseif isequal(options.method,'wmn')
            if options.autocorner
                options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');
            end
            cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
            cortexVI = cortexVI ./ model.W';
        end
        if options.currymatrix == 1
            len = length(cortexVI);
            cortexVI(len+1:options.cortexnumverts) = 0;
        end
        len = length(model.neighbors.neighbors.idx);
        for j = 1:len
            values = cortexVI(model.neighbors.neighbors.idx{j});
            weight = model.neighbors.neighbors.weight{j};
            cortexV(j,:) =  sum(weight .* values);
        end
        source.data(i+1-options.startepoch) = {cortexV};
    end    
    SourceROI.data = source.data;
    SourceROI.srate = EEG.srate;
    SourceROI.ROI.labels = labels;
    SourceROI.ROI.centers = centers;
    SourceROI.ROI.vertices = vertices;
    load('colincortex.mat');
    SourceROI.Cortex.Vertices = colincortex.Vertices;
    SourceROI.Cortex.Faces= colincortex.Faces;
    SourceROI.Cortex.FaceVertexCData = colincortex.FaceVertexCData;
    SourceROI.usebem = 0;
    sourcedata = SourceROI.data;
    points = length(sourcedata);
    model.cortex = colincortex;
    ROI = SourceROI.ROI;
    nroi = length(ROI.labels);
    sel = 1:nroi;
    ROI.selected = sel;
    % compute ROI time series.
    roiData = zeros(nroi,points);
    for i = 1:nroi
        roi_vert_idx = ROI.vertices{sel(i)}{1};
        for j = 1:points
            currentdata = sourcedata{j};
            if isempty(currentdata)
                roiData(i,j) = 0;
            else
                roiData(i,j) = mean(currentdata(roi_vert_idx));
            end
        end
    end
    sourceResult(fileNum,:, :) = roiData;
end
end