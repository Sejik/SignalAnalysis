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
connectivity = 'C:\Users\win\Desktop\result';
% output
pngDir = 'C:\Users\win\Desktop\picture';
% threhold: range from (max+min)/2 * param.threshold to max
param.threshold = 1; % 2*8/9;
param.axis = 0;
% freq
param.individualFreq{1} = [1 3]; %delta
param.individualFreq{2} = [4 7]; % theta
param.individualFreq{3} = [8 13]; % alpha
param.individualFreq{4} = [14 30]; % beta
param.individualFreq{5} = [30 67]; % gamma
param.individualFreq{6} = [1 67]; % whole
param.freqName{1} = 'delta';
param.freqName{2} = 'theta';
param.freqName{3} = 'alpha';
param.freqName{4} = 'beta';
param.freqName{5} = 'gamma';
param.freqName{6} = 'whole';

%% initialize
% load raw data
cd(connectivity);
eeg_files = dir('*.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name;
end

%% main
for DataNum = 1:length(eeg_info)
    clearvars -except DataNum eeg_info connectivity pngDir param; clc; close;
    cd(connectivity);
    name = eeg_info{DataNum,1};
    EEG = load(name);
    DTF = EEG.DTF;
    
    load('cutskin.mat');
    options.type = DTF.type;
    model.roilabels = DTF.labels;
    model.roipos = DTF.locations;
    options.isadtf = DTF.isadtf;
    options.srate = DTF.srate;
    frequency = DTF.frequency;
    model.cortex = DTF.cortex;
    options.usebem = DTF.usebem;
    model.vertices = DTF.vertices;
    
    nroi = length(model.roilabels);
    dtf.rois = 1:nroi; 
    
    
    valmin = 0.001;
    valmax = 1;
    options.dtf = true;
    
    rois = dtf.rois;
    nroi = length(rois);
    roilab = model.roilabels;
    roipos = model.roipos;

    cmap = ROIcolors(nroi);
    
    ArrowSizeLimit = [1 5];
    SphereSizeLimit = [5 10];
    options.channels = 'all';
    adtfmatrixs = DTF.matrix;
        
    cortexFaceVertexCData = ones(20516, 3);
    
    if isequal(options.type,'ROI')
        for i=1:nroi
            roi_vert_idx = model.vertices{i};
            cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
        end
    end
    
    for freqNum = 1:length(param.individualFreq)
        for timeNum = 1:length(adtfmatrixs)
            dtfmatrixs = squeeze(adtfmatrixs(timeNum,:,:,:));
            
            % display the cortex with different ROIs having different colors.
            patch('SpecularStrength',0,'DiffuseStrength',0.8,...
                'FaceLighting','phong',...
                'Vertices',model.cortex.Vertices,...
                'LineStyle','none',...
                'Faces',model.cortex.Faces,...
                'FaceColor','interp',...
                'EdgeColor','none',...
                'FaceVertexCData',cortexFaceVertexCData);
            
            alpha(0.2);
            
            maxRoiPos = max(roipos);
            for i = 1:nroi
                linestart = roipos(i, :);
                lineend = [linestart(1)*1.1, linestart(2), maxRoiPos(3)*2];
                %plot3([linestart(1) lineend(1)], [linestart(2) lineend(2)], [linestart(3) lineend(3)],'LineWidth',2,'color', 'k');
                %lineend = lineend*1.1;
                A = text(lineend(1), lineend(2), lineend(3), char(roilab{i}), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontSize', 13);
                set(A, 'interpreter', 'none');
            end
            
            minf = param.individualFreq{freqNum}(1);
            maxf = param.individualFreq{freqNum}(2);
            tempmatrix = dtfmatrixs(:,:,minf:maxf);
            currentdtfmatrix = mean(tempmatrix,3);
            valmin = min(min(currentdtfmatrix));
            valmax = max(max(currentdtfmatrix));
            [row col] = find(currentdtfmatrix==valmax, 1);
            options.whichchannel = [row col];
            options.displimits = [(valmax+valmin)/2*param.threshold, 1.0];
            opt = struct(  'Channels', options.channels,...
                'Whichchannel', options.whichchannel,...
                'ValLim', options.displimits,...
                'ArSzLt',ArrowSizeLimit,...
                'SpSzLt',SphereSizeLimit);
            
            drawdtfconngraph(currentdtfmatrix,roipos,opt);
            
            lightcolor = [0.6 0.6 0.6];
            lighting phong; % gouraud
            h1 = light('Position',[0 0 1],'color',lightcolor);
            h2 = light('Position',[0 1 0],'color',lightcolor);
            h3 = light('Position',[0 -1 0],'color',lightcolor);
            axis off;
            hold off;
            
            if param.axis == 1
                caxis([valmin, 1.0]);
                colorbar;
            end
            mov(timeNum) = getframe;            
            close;
        end
        cd(pngDir);
        movie2avi(mov, strcat(param.freqName{freqNum}, '_', strrep(name, '.mat', '.avi')), 'compression','None','fps',30);
    end    
end