function TessMat = in_tess_mrimask(MriFile, isMni)
% IN_TESS_MRIMASK: Import an MRI as a mask or atlas, and tesselate the volumes in it
%
% USAGE:  TessMat = in_tess_mrimask(MriFile, isMni=0)
%         TessMat = in_tess_mrimask(sMri,    isMni=0)
%
% 

% @=============================================================================
% This function is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2016 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, 2012-2016

% Parse inputs
if (nargin < 2) || isempty(isMni)
    isMni = 0;
end

% Read MRI volume
if ischar(MriFile)
    if isMni
        sMri = in_mri(MriFile, 'ALL-MNI');
    else
        sMri = in_mri(MriFile, 'ALL');
    end
    if isempty(sMri)
        TessMat = [];
        return;
    end
    % Try to get volume labels for this atlas
    VolumeLabels = panel_scout('GetVolumeLabels', MriFile);
else
    sMri = MriFile;
    MriFile = [];
    VolumeLabels = [];
end
sMri.Cube = double(sMri.Cube);
% Get al the values in the MRI
allValues = unique(sMri.Cube);
% If values are not integers, it is not a mask or an atlas: it has to be binarized first
if any(allValues ~= round(allValues))
    % Warning: not a binary mask
    isConfirm = java_dialog('confirm', ['Warning: This is not a binary mask.' 10 'Try to import this MRI as a surface anyway?'], 'Import binary mask');
    if ~isConfirm
        TessMat = [];
        return;
    end
    % Analyze MRI histogram
    Histogram = mri_histogram(sMri.Cube);
    % Binarize based on background level
    sMri.Cube = (sMri.Cube > Histogram.bgLevel);
    allValues = [0,1];
end
% Display warning when no MNI transformation available
if isMni && (~isfield(sMri, 'NCS') || ~isfield(sMri.NCS, 'R') || isempty(sMri.NCS.R))
    isMni = 0;
    disp('Error: No MNI transformation available in this file.');
end
% Default labels for FreeSurfer ASEG.MGZ
if (length(allValues) > 10) && ~isempty(MriFile) && (~isempty(strfind(MriFile, 'aseg.mgz')) || ~isempty(strfind(MriFile, 'aseg.auto.mgz')) || ~isempty(strfind(MriFile, 'aseg.auto_noCCseg.mgz')))
    Labels = {...
       16,  'Brainstem'; ...
        8,  'Cerebellum L'; ...
       47,  'Cerebellum R'; ...
       26,  'Accumbens L'; ...
       58,  'Accumbens R'; ...
       18,  'Amygdala L'; ...
       54,  'Amygdala R'; ...
       11,  'Caudate L'; ...
       50,  'Caudate R'; ...
       17,  'Hippocampus L'; ...
       53,  'Hippocampus R'; ...
       13,  'Pallidum L'; ...
       52,  'Pallidum R'; ...
       12,  'Putamen L'; ...
       51,  'Putamen R'; ...
        9,  'Thalamus L'; ...
       10,  'Thalamus L'; ...
       48,  'Thalamus R'; ...
       49,  'Thalamus R'; ...
    };
    % Grouping the cerebellum white+cortex voxels
    sMri.Cube(sMri.Cube == 7) = 8;
    sMri.Cube(sMri.Cube == 46) = 47;
    % Keep only the labelled areas
    [allValues, I, J] = intersect([Labels{:,1}], allValues);
    Labels = Labels(I,:);
    % Get labelled values in alphabetical order 
    allValues = [Labels{:,1}];
    
% Labels available in an external file
elseif ~isempty(VolumeLabels)
    % Keep only the labelled areas
    [allValues, I, J] = intersect([VolumeLabels{:,1}], allValues);
    Labels = VolumeLabels(I,:);
    % Get labelled values in alphabetical order 
    allValues = [Labels{:,1}];
    
% No labels available
else
    % Skip the first value (background)
    allValues(1) = [];
    Labels = {};
end

TessMat = repmat(struct('Comment', [], 'Vertices', [], 'Faces', []), [1, 0]);
% Generate a tesselation for all the others
for i = 1:length(allValues)
    % Display progress bar
    if (length(allValues) > 1)
        bst_progress('text', sprintf('Importing atlas surface #%d/%d...', i, length(allValues)));
    end

    % Get the binary mask of the current region
    mask = (sMri.Cube == allValues(i));
    % Fill small holes
    mask = mri_dilate(mask, 1);
    mask = mask & ~mri_dilate(~mask, 1);
    % Close the volumes by setting to zero all the edges
    mask([1,end],:,:) = 0;
    mask(:,[1,end],:) = 0;
    mask(:,:,[1,end]) = 0;
    % Empty mask: skip
    if ~any(mask(:))
        continue;
    end
    
    % Comment field
    if ~isempty(Labels)
        Comment = Labels{i,2};
    elseif (length(allValues) > 1)
        Comment = sprintf('%d', allValues(i));
    elseif ~isempty(MriFile)
        [fPath, fBase, fExt] = bst_fileparts(MriFile);
        Comment = fBase;
    else
        Comment = 'mask';
    end
    
    % Add new tesselation
    iTess = [];
    % If importing an atlas in MNI coordinates
    if isMni
        % Get the coordinates of all the points in the mask
        Pvox = [];
        iMask = find(mask);
        [Pvox(:,1),Pvox(:,2),Pvox(:,3)] = ind2sub(size(mask), iMask);
        % Convert to MNI coordinates
        Pmni = cs_convert(sMri, 'voxel', 'mni', Pvox);
        % Find left and right areas
        iL = find(Pmni(:,1) < 0);
        iR = find(Pmni(:,1) >= 0);
        % If this is a bilateral region: split in two
        if ~isempty(iL) && ~isempty(iR) && (length(iL) / length(iR) < 1.6) && (length(iL) / length(iR) > 0.4)
            % Create two separate masks
            maskL = mask;
            maskR = mask;
            maskL(iMask(iR)) = 0;
            maskR(iMask(iL)) = 0;
            % Tesselate left
            [Vertices, Faces] = TesselateMask(sMri, maskL, isMni);
            if ~isempty(Vertices)
                iTess = length(TessMat) + 1;
                TessMat(iTess).Comment  = [Comment, ' L'];
                TessMat(iTess).Vertices = Vertices;
                TessMat(iTess).Faces    = Faces;
            end
            % Tesselate right
            [Vertices, Faces] = TesselateMask(sMri, maskR, isMni);
            if ~isempty(Vertices)
                iTess = length(TessMat) + 1;
                TessMat(iTess).Comment  = [Comment, ' R'];
                TessMat(iTess).Vertices = Vertices;
                TessMat(iTess).Faces    = Faces;
            end
        end
    end
    
    % If tesselation was not already added
    if isempty(iTess)
        % Tesselate surface
        [Vertices,Faces] = TesselateMask(sMri, mask, isMni);
        % Create new entry
        if ~isempty(Vertices)
            iTess = length(TessMat) + 1;
            TessMat(iTess).Comment  = Comment;
            TessMat(iTess).Vertices = Vertices;
            TessMat(iTess).Faces    = Faces;
        end
    end
end
end



%% ===== FINALIZE SURFACE =====
function [Vertices, Faces] = TesselateMask(sMri, mask, isMni)
    % Create an isosurface
    [Faces, Vertices] = isosurface(mask, 0.5);
    % Convert to Brainstorm format
    Vertices = Vertices(:, [2 1 3]);
    Faces    = Faces(:, [2 1 3]);
    % Convert coordinates
    if isMni
        % Convert from voxels to MNI space
        Vertices = cs_convert(sMri, 'voxel', 'mni', Vertices);
    else
        % Convert from voxels to MRI (in meters)
        Vertices = cs_convert(sMri, 'voxel', 'mri', Vertices);
    end

    % Remove small objects
    [Vertices, Faces] = tess_remove_small(Vertices, Faces);
    % Compute vertex-vertex connectivity
    VertConn = tess_vertconn(Vertices, Faces);
    % Smooth surface
    Vertices = tess_smooth(Vertices, 1, 2, VertConn, 0);
    % Enlarge a bit
    VertNormals = tess_normals(Vertices, Faces, VertConn);
    Vertices = Vertices + 0.0002 * VertNormals;
end



