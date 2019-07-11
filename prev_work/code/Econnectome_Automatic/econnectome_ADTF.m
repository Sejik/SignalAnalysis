%% Econnectome Automatic
% modify econnectome by Sejik Park (Korea University Undergraduated)
% E-mail: sejik6307@gmail.com

% Procedure
% 1. import EEG
% 2. Source Image Time
% 3. Compute ROI time serires
% 4. Imaging Connectivity

%% set path
% input
datDir = 'C:\Users\win\Desktop\2.raw2econnectome';
roiDir = 'C:\Users\win\Desktop\ROI';
% output
connectivity = 'C:\Users\win\Desktop\result';

warning off;
%% set parameter (number of timepoints should bigger than 20 * number of ROIs)
% source image time
startEpoch = 71; % first point = 1;
endEpoch = 558; % end point = EEG.points;
% ROI time series
ROIfileName = 'ROI_Total.mat';
% DTF/ADTF, connectivity calculation
startPoint = 1;
endPoint = 488;
lowFrequency = 4;
highFrequency = 70;

%% initialize
% load raw data
cd(datDir);
eeg_files = dir('*.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name;
end
% load ROI data
cd(roiDir);
load(ROIfileName);

%% main
for DataNum = 1:length(eeg_info)
    cd(datDir);
    name = eeg_info{DataNum,1};
    EEG = matreader(name, datDir); % read file
    
    % eegfc(EEG); % pop UI: showing EEG data UI
    % pop_sourceloc(EEG); % pop UI: showing source localization UI
    % basic variable
    model.italyskin = load('italyskin.mat');
    model.cutskin = load('cutskin.mat');
    model.italyskinxy = load('italyskin-in-xy.mat');
    model.italyskinxyz = load('italyskin-in-xyz.mat');
    model.colinbemskin = load('colinbemskin.mat');
    model.cortex = load('colincortex.mat');
    model.bemcortex = load('colinbemcortex.mat');
    model.neighbors = load('neighbors.mat');
    transmatrix = load('LargeTransMatrix.mat');
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
    options.startepoch = startEpoch;
    options.endepoch = endEpoch;
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
    % source localization calculation
    ratio = 100 / (options.endepoch - options.startepoch);
    for i = options.startepoch : options.endepoch
        electrodesV = EEG.data(options.vidx,i);
        sensor.data(i) = {griddata(model.X,model.Y,electrodesV,model.XI,model.YI,'v4')};
        if isequal(options.method,'mn')
            if options.autocorner
                tempf = figure;
                options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');
                close(tempf);
            end
            cortexVI = tikhonov(model.U,model.s,model.V,electrodesV,options.lamda);
        elseif isequal(options.method,'wmn')
            if options.autocorner
                tempf = figure;
                options.lamda = l_curve(model.U,model.s,electrodesV,'tikh');
                close(tempf);
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
    % making source object
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
    
    % pop_roits(SourceROI); % pop ROI Time series: showing ROI time series calculation UI
    % basic variable
    sourcedata = SourceROI.data;
    srate = SourceROI.srate;
    points = length(sourcedata);
    len = length(sourcedata{1});
    model.cortex = model.cortex.colincortex;
    num_verts = length(model.cortex.Vertices);
    ROI = SourceROI.ROI;
    nroi = length(ROI.labels);
    sel = 1:nroi;
    ROI.selected = sel;
    % compute ROI time series.
    roiData = zeros(nroi,points);
    for i = 1:nroi
        roi_vert_idx = ROI.vertices{sel(i)};
        for j = 1:points
            currentdata = sourcedata{j};
            if length(currentdata) == 0
                roiData(i,j) = 0;
            else
                roiData(i,j) = mean(currentdata(roi_vert_idx));
            end
        end
    end
    
    % Imaging Connectivity
    % basic variable
    tot_range = [lowFrequency:highFrequency];
    nfre = length(tot_range);
    ts = roiData(:,startPoint:endPoint)';
    nchan = size(ts,2);    
    % optimal order calculation
    fpe_error = [];
    sbc_error = [];
    j = 1;
    for i = 1:20
        [w,A,C,SBC,FPE] = arfit(ts,i,i);
        fpe_error(j) = real(FPE);
        sbc_error(j) = SBC;
        j = j+1;
    end
    minsbc = min(sbc_error);
    sbc_optorder = find(sbc_error == minsbc,1);
    optimalorder = sbc_optorder;
    % compute DTF    
    dt = 1/srate;
    A = matrix_former(ts, optimalorder);
    total = size(A,1);
    thr = round(0.1*total);
    for i = 1:total
        gamma2 = DTFvalue(A{i}, lowFrequency, highFrequency, srate);
        dtfmatrixs(i,:,:,:) = gamma2;
    end
    pvalue = 0.05;
    nreps = 20;
    nsample = size(ts,1);
    nfreq = highFrequency - lowFrequency + 1;
    sig_size = floor(pvalue *nreps) + 1;
    new_gamma2 = zeros(sig_size-1, nsample, nchan, nchan, nfreq);
    for i=1:nreps
        for j=1:nchan
            Y = fft(ts(:,j));
            Pyy = sqrt(Y.*conj(Y));
            Phyy = Y./Pyy;
            index = 1:size(ts,1);
            index = surrogate(index);
            Y = Pyy.*Phyy(index);
            newts(:,j) = real(ifft(Y));
        end
        gamma2_set = ADTF(newts, lowFrequency, highFrequency, optimalorder, srate);
        new_gamma2(sig_size,:,:,:,:) = gamma2_set;
        new_gamma2 = sort(new_gamma2, 'descend');
        new_gamma2(sig_size,:,:,:,:) = [];
    end
    sig_dtfmatrix = squeeze(new_gamma2(sig_size-1,:,:,:,:));
    dtfmatrixs = ADTFsigtest(dtfmatrixs, sig_dtfmatrix);
    % output
    % basic variable
    DTF.labels = ROI.labels(ROI.selected);
    DTF.vertices = ROI.vertices(ROI.selected);
    DTF.locations = ROI.centers(ROI.selected,:);
    DTF.frequency = [lowFrequency highFrequency];
    DTF.matrix = dtfmatrixs;
    DTF.isadtf = 1;
    DTF.srate = srate;
    DTF.type = 'ROI';
    DTF.cortex = model.cortex;
    DTF.usebem = options.usebem;
    % pop_cortex(DTF); % show the result
    % save output
    cd(connectivity);
    save(name, 'DTF');
end