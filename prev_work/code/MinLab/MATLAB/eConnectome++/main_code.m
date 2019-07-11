%% Econnectome
% designed by Sejik Park

%% set variable
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN\Econnectome'; 
roiDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN\ROI';
sourceDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN\Source';

startepoch = 100; % 1;
endepoch = 200; % EEG.points;

%% initialize
cd(rawDir);
eeg_files = dir('*.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name;
end

cd(roiDir);
load('NewROI.mat');

%% main
for DataNum = 1:length(eeg_info)
    cd(rawDir);
    pathstr = rawDir;
    name = eeg_info{DataNum,1};
    EEG = pop_matreader(name, pathstr); % read file
    % eegfc(EEG);
    % pop_sourceloc(EEG);
    
    % basic varible
    model.italyskin = load('italyskin.mat');
    model.cutskin = load('cutskin.mat');
    model.italyskinxy = load('italyskin-in-xy.mat');
    model.italyskinxyz = load('italyskin-in-xyz.mat');
    model.colinbemskin = load('colinbemskin.mat');
    model.cortex = load('colincortex.mat');
    model.bemcortex = load('colinbemcortex.mat');
    model.neighbors = load('neighbors.mat');

    transmatrix = load('LargeTransMatrix.mat'); % large transfer matrix for colin BEM skin and cortex 
    k = cell2mat({EEG.locations(EEG.vidx).colinbemskinidx});
    model.transmatrix = transmatrix.TransMatrix(k,:); % get transfer matrix for the electrodes
    [model.U, model.s, model.V] = csvd(model.transmatrix);

    % get electrode positions, labels and indices on the italyskin.
    %=============================================
    model.k = cell2mat({EEG.locations(EEG.vidx).italyskinidx});
    model.electrodes.labels = EEG.labels(EEG.vidx);
    model.electrodes.locations = model.italyskin.italyskin.Vertices(model.k,:);
    model.X = model.italyskinxy.xy(model.k,1); % standard xy coordinates relative to electrodes on the skin
    model.Y = model.italyskinxy.xy(model.k,2);   
    zmin = min(model.italyskinxyz.xyz(model.k,3));
    Z = model.italyskinxyz.xyz(:,3);
    model.interpk = find(Z > zmin); % focus interpolated vertices
    model.XI = model.italyskinxy.xy(model.interpk,1);
    model.YI = model.italyskinxy.xy(model.interpk,2);
    %=============================================

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
    options.startepoch = startepoch;
    options.endepoch = endepoch;
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
    

    ratio = 100 / (options.endepoch - options.startepoch);
    for i = options.startepoch : options.endepoch
    
        electrodesV = EEG.data(options.vidx,i);
    
        % compute map for sensor space
        sensor.data(i) = {griddata(model.X,model.Y,electrodesV,model.XI,model.YI,'v4')};

        % compute sources on cortex
        if isequal(options.method,'mn') % compute sources on cortex
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
    
        % get smooth values on finer colin cortex
        len = length(model.neighbors.neighbors.idx);
        for j = 1:len
            values = cortexVI(model.neighbors.neighbors.idx{j}); 
            weight = model.neighbors.neighbors.weight{j};
            cortexV(j,:) =  sum(weight .* values);
        end
        source.data(i) = {cortexV};
    
        % update absolute min and max values
        abscortexV = abs(cortexV);
        dmin = min(abscortexV);
        dmax = max(abscortexV);
        if dmin < options.sourceminmax(1)
            options.sourceminmax(1) = dmin;
        end
        if dmax > options.sourceminmax(2)
            options.sourceminmax(2) = dmax;
        end        
    
        percent = round((i-options.startepoch)*ratio);
        progress = ['Localizing ' num2str(percent) '%'];
        drawnow;
    end
    
    SourceROI.data = source.data; % critical source data
    SourceROI.srate = EEG.srate; % sampling rate
    SourceROI.ROI.labels = labels; % array for ROI
    SourceROI.ROI.centers = centers; % array for ROI
    SourceROI.ROI.vertices = vertices; % array for ROI
    load('colincortex.mat');
    SourceROI.Cortex.Vertices = colincortex.Vertices;
    SourceROI.Cortex.Faces= colincortex.Faces;
    SourceROI.Cortex.FaceVertexCData = colincortex.FaceVertexCData;
    SourceROI.usebem = 0;
    
    % pop_roits(SourceROI);
    
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
    roidata = zeros(nroi,points);
    for i = 1:nroi
        roi_vert_idx = ROI.vertices{sel(i)};
        for j = 1:points
            currentdata = sourcedata{j};
            if length(currentdata) == 0
                roidata(i,j) = 0;
            else
                roidata(i,j) = mean(currentdata(roi_vert_idx));
            end
        end
    end

    xlimit = points;
    xlabelstep = round(xlimit/10);
    
    % x labels
    xlabelpositions = [0:xlabelstep:xlimit];
    xlabels = [0:xlabelstep:xlimit];
    xlabels = xlabels / srate;
    xlabels = num2str(xlabels');
     
    % y labels
    channelmaxs = max(roidata,[ ],2);
    channelmins = min(roidata,[ ],2);    
    spacing = mean(channelmaxs-channelmins);  
    ylimit = (nroi+1)*spacing;
    ylabelpositions = [0:spacing:nroi*spacing];    
    YLabels = ROI.labels(sel);
    YLabels = strvcat(YLabels); 
    YLabels = flipud(str2mat(YLabels,' '));

    % mean values for the current window
    meandata = mean(roidata,2);

    ROI.data = roidata;
    
    % output = pop_dtf_computation(ROI.data, srate);
    TS.data = ROI.data;
    TS.srate = srate;
    [TS.nbchan, TS.points] = size(TS.data);
    
    startpoint = 1;
    endpoint = 2000;
    if endpoint > TS.points
        endpoint = TS.points;
    end
    
    deltaT = 1/TS.srate;
    starttime = startpoint*deltaT;
    endtime = endpoint*deltaT;
    
    maxf = num2str(round(TS.srate/2));
    options.siglevel = 0.05;
    options.shufftimes = 1000;
    
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
    
    % frequecny limit
    lowf = 1;
    highf = 100;
    
    lowf = round(lowf);
    highf = round(highf);
    maxf = TS.srate/2;
    lowf = max(1,min(lowf, maxf));
    highf = max(1,min(highf, maxf));
    
    optimalorder = 4;
    optimalorder = round(optimalorder);
    optimalorder = max(1,min(optimalorder, 20));
    
    [n, m]  = size(ts); 
    
    options.shufftimes = 1000;
    options.siglevel = 0.05;
    
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
end
