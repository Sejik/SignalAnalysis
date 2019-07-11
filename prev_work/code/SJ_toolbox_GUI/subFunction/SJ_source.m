function [roiResult, sourceResult] = SJ_source(param, data)
cortex = load('colincortex.mat');
XI = cortex.colincortex.Vertices;
neighbors = load('neighbors.mat');
idx = neighbors.neighbors.idx;
model_weight = neighbors.neighbors.weight;
transmatrix = load('LargeTransMatrix.mat');
transmatrix = transmatrix.TransMatrix;
locations = stdLocations(param.rawChannel');
k = cell2mat({locations.colinbemskinidx});
currentTransmatrix = transmatrix(k,:);
[U, s, V] = csvd(currentTransmatrix);

labels = cell(1, length(param.roi));
centers = zeros(length(param.roi),3);
vertices = cell(1, length(param.roi));
for roiNum = 1:length(param.roi)
    labels{roiNum} = param.roiName{roiNum};
    centers(roiNum,1:3) = param.roi(roiNum,:);    
    dists = sqrt( (XI(:,1)-centers(roiNum, 1)).^2 + ...
        (XI(:,2)-centers(roiNum, 2)).^2 + (XI(:,3)-centers(roiNum, 3)).^2 );
    vidx = find(dists<param.roiRadius);
    vertices{roiNum} = vidx;
end
roiResult.labels = labels;
roiResult.centers = centers;
roiResult.vertices = vertices;

nroi = length(labels);
points = param.epochLength;
nfile = size(data,1);
sourceResult = zeros(nfile, nroi, points); 
for fileNum = 1:size(data, 1)
    fprintf('%s: %d/%d processing \n', datestr(now), fileNum, size(data,1));
    currentData = squeeze(data(fileNum, 1:length(param.rawChannel), :));
    sourcedata = cell(1,points);
    for i = 1 : param.epochLength
        electrodesV = currentData(:,i);
        lamda = l_curve(U,s,electrodesV,'tikh');
        cortexVI = tikhonov(U,s,V,electrodesV,lamda);
        cortexV = weightedSum(idx, cortexVI, model_weight);
        sourcedata{i} = cortexV;
    end
    % compute ROI time series.
    roiData = zeros(nroi,points);
    for i = 1:nroi
        roi_vert_idx = vertices{i};
        for j = 1:points
            currentdata = sourcedata{j};
            if isempty(currentdata)
                roiData(i,j) = 0;
            else
                roiData(i,j) = mean(currentdata(roi_vert_idx));
            end
        end
    end
    sourceResult(fileNum, :, :) = roiData;
end
end

function [cortexV] = weightedSum(idx, cortexVI, model_weight)
    for j = 1:length(idx)
        values = cortexVI(idx{j});
        weight = model_weight{j};
        cortexV(j,:) =  sum(weight .* values);
    end
end