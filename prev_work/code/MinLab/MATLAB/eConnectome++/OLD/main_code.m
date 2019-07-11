%% Econnectome
% designed by Sejik Park

%% set variable
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN\Econnectome'; 
roiDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN\ROI';
sourceDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN\Source';

startepoch = 100 % 1;
endepoch = 200 % EEG.points;

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
    EEG = matreader(name, pathstr); % read file
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
    SourceROI.Cortex = load('colincortex.mat');
    SourceROI.usebem = 0;
    pop_roits(SourceROI);
    
    sourcedata = SourceROI.data;
    srate = SourceROI.srate;
    points = length(sourcedata);
    len = length(sourcedata{1});
    % pop_roits, line 355
    
    
    
end