function [] = SJ_dtfMovie(param, result)
cd(param.outputDir);
param.movieThreshold = 9/10;

windowLength = ceil(param.windowLength*param.fs);
shiftLength = ceil(param.shiftLength*param.fs);

title0 = 'DTF';
for subjectGroupNum = 1:length(result.groupName)
    for conditionNum = 1:length(param.condition)
        for responseNum = 1:size(result.fileGroup, 3)
            for subConditionNum = 1:size(result.fileGroup, 5)
                currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                dtf{responseNum, subConditionNum} = result.sdtf(logical(currentFile), :, :, :, :);
                clear temp;
            end
        end
        
        title1 = strcat(title0, '_', result.groupName{subjectGroupNum}, '_', param.condition{conditionNum});
        for freqNum = 2:length(param.freqName)
            title2 = strcat(title1, '_', param.freqName{freqNum});
            minf = param.individualFreq{freqNum}(1) - param.interestFreq(1) + 1;
            maxf = param.individualFreq{freqNum}(2) - param.interestFreq(1) + 1;
            
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    writerObj{responseNum, subConditionNum} = VideoWriter(strcat(title2, '_', param.subCondition{subConditionNum}, '_', num2str(responseNum))); %#ok<TNMLP>
                    writerObj{responseNum, subConditionNum}.FrameRate = 20; % How many frames per second
                    open(writerObj{responseNum, subConditionNum});
                end
            end
            for dtfEpoch = 1:floor((param.epochLength - windowLength + 1)/shiftLength)
                for responseNum = 1:size(result.fileGroup, 3)
                    for subConditionNum = 1:size(result.fileGroup, 5)
                        dtfData = squeeze(mean(mean(dtf{responseNum, subConditionNum}(:, dtfEpoch, minf:maxf, :,:),1, 'omitnan'),3, 'omitnan'));
                        dtfData(isnan(dtfData)) = 0;
                        dtfPlot(param, dtfData, result.roi);
                        currentTime = round(((floor((dtfEpoch-1)*shiftLength + 1)+floor((dtfEpoch-1)*shiftLength + windowLength))/(param.fs*2))-param.zeroLatency,3);
                        title(strcat(num2str(currentTime), 'ms'));
                        frame = getframe(gcf); % 'gcf' can handle if you zoom in to take a movie.
                        close;
                        writeVideo(writerObj{responseNum, subConditionNum}, frame);
                    end
                end
            end
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    close(writerObj{responseNum, subConditionNum});
                end
            end
        end
        clear dtf;
    end
end
end

function [] = dtfPlot(param, dtfData, roiData)
load('basicCortex.mat');
options.type = 'ROI';
model.roilabels = roiData.labels;
model.roipos = roiData.centers;
options.isadtf = 0;
options.srate = param.fs;
model.cortex = cortex;
options.usebem = 0;
model.vertices = roiData.vertices;

nroi = length(model.roilabels);
dtf.rois = 1:nroi;

options.dtf = true;

rois = dtf.rois;
nroi = length(rois);
roilab = model.roilabels;
roipos = model.roipos;

cmap = ROIcolors(nroi);

ArrowSizeLimit = [1 5];
SphereSizeLimit = [5 10];

options.channels = 'all';

cortexFaceVertexCData = ones(20516, 3);

if isequal(options.type,'ROI')
    for i=1:nroi
        roi_vert_idx = model.vertices{i}{1};
        cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
    end
end

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
    A = text(lineend(1), lineend(2), lineend(3), char(roilab{i}), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 13);
    set(A, 'interpreter', 'none');
end

currentdtfmatrix = dtfData;
valmin = min(min(currentdtfmatrix));
valmax = max(max(currentdtfmatrix));
[row, col] = find(currentdtfmatrix==valmax, 1);
options.whichchannel = [row col];
options.displimits = [valmax*param.movieThreshold, 1.0];
opt = struct(  'Channels', options.channels,...
    'Whichchannel', options.whichchannel,...
    'ValLim', options.displimits,...
    'ArSzLt',ArrowSizeLimit,...
    'SpSzLt',SphereSizeLimit);

drawdtfconngraph(currentdtfmatrix,roipos,opt);

delete(findall(gcf,'Type','light'));
lightcolor = [0.6 0.6 0.6];
lighting phong; % gouraud
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
axis off;
hold off;

if param.axis == 1
    caxis([valmin, 1.0]);
    colorbar;
end
end