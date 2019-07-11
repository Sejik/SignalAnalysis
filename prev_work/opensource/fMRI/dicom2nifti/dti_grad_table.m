function [bval,bvec,bvec_rot] = dti_grad_table(dcmhdr,Ngrad,corr_rot,out_folder)
% 
% [bval,bvec,bvec_rot] = dti_grad_table(dcmhdr,Ngrad,corr_rot,out_folder)
% 
% Generate the gradient table from a DTI DICOM file
% 
% 
%INPUT
%-----
% - DCMHDR     : DICOM header (obtained with "dicominfo")
% - NGRAD      : number of gradients used (e.g. 6, 15 or 32) plus any
%   extra gradients (e.g. 1 additional gradient when using gradient
%   overplus in Philips scanners)
% - CORR_ROT   : also generate rotated gradient directions (1 [yes] or 0 [no])
% - OUT_FOLDER : output folder (if OUT_FOLDER='', no output files will be
%   generated)
% 
% It is assumed that the first image has b=0.
% 
% 
%OUTPUT
%------
% - BVAL: (NGRAD+1)x1 matrix containing the B-values
% - BVEC: (NGRAD+1)x3 matrix containing the gradient directions (for each
%         row, Gx, Gy and Gz)
% - BVEC_ROT: (NGRAD+1)x3 matrix containing the rotated gradient directions
%   If CORR_ROT=0, BVEC_ROT=[]
% - If OUT_FOLDER is not an empty string, inside OUT_FOLDER:
%   - DCMFILE-Bval.txt with BVAL
%   - DCMFILE-Bvec.txt with BVEC
%   - DCMFILE-Bvec-rot.txt (if CORR_ROT=1) with BVEC_ROT,
%   where DCMFILE is the DICOM file name
%   For the BVECs, the output is to be used with DTI-Studio:
%   0: 0, 0, 0, B-value
%   1: Gx, Gy, Gz, B-value
%   ...
%   NGrad: Gx, Gy, Gz, B-value
% 
%   If Gx=Gy=Gz=100, the row is ignored in DTI-Studio.
% 
% 
% Works with DICOM files from Philips Achieva 3T R2.6, with:
% - Slice orientation  : transverse
% - Patient position   : head first
% - Patient orientation: supine
% - Fold-over direction: AP
% - Fat shift direction: P
% - Gradient overplus  : yes
% - Gradient resolution: high
% - Nr of b-factors    : 2
% - b-factor order     : ascending
% - Max b-factor       : 1000
% - Average high b     : no
% 
% Explanation:
% - gradient resolution = low (6 directions), medium (15) or high (32)
% - gradient overplus   = increased diffusion gradient performance, leading
%   to SNR increase. An isotropically diffusion weighted image is produced.
% - b-factor order      = A linear (ascending) order of b-factors from
%   b-factor zero to the "max b-factor" will be used, to get "nr of
%   b-factors" points (in each gradient direction)
% 
% 
% For other functions with the same purpose, see Jonathan Farrell's webpage
% http://godzilla.kennedykrieger.org/~jfarrell/software_web.htm.
% His online Java applet is very useful:
% http://godzilla.kennedykrieger.org/~jfarrell/OTHERphilips/GUI.html
% 
% 
% Requires the Image Processing Toolbox
% 
% 
% See also DICOM2NIFTI
% 

% Guilherme Coco Beltramini (guicoco@gmail.com)
% 2012-Sep-11, 09:28pm

NrB0 = 1; % number of gradients with b=0

% Correction method (ignored if CORR_ROT=0)
% - Method 1: reads 6 elements from the rotation matrix and fills the rest
%   using orthogonality
% - Method 2: reads the rotation angles and applies 3 successive rotations
% - Method 3: reads the whole rotation matrix from the header
% - The results are the same within a precision of ~10^(-7)
% - Preferentially use method 1 (3 is very similar), because results in a
%   "more orthogonal" matrix
corr_method = 1;


% Check input
%==========================================================================
if ~all(isfield(dcmhdr,{'PerFrameFunctionalGroupsSequence','Filename'})) || ...
        ( corr_method==2 && ~isfield(dcmhdr,'Private_2001_105f') ) || ...
        ( corr_method==3 && ~all(isfield(dcmhdr,{'Private_2001_1018','NumberOfFrames'})) )
    error('Invalid DICOM header')
end
if corr_rot~=0 && corr_rot~=1
    error('Invalid CORR_ROT option (choose 0 or 1)')
end
if corr_rot && corr_method~=1 && corr_method~=2 && corr_method~=3
    error('Invalid CORR_METHOD option (choose 1, 2 or 3)')
end


% Read DICOM header
%==========================================================================

% Initialize the variables
%-------------------------
Ngrad = Ngrad + NrB0;
bval  = nan(Ngrad,1);
bvec  = nan(Ngrad,3);

for gg=1:Ngrad
    
    % b-value
    %--------
    eval(...
        sprintf('bval(%d)=dcmhdr.PerFrameFunctionalGroupsSequence.Item_%d.MRDiffusionSequence.Item_1.DiffusionBValue;',gg,gg))
    
    % Gradient directions (bvec)
    %--------------------------
    %if strcmpi('DIRECTIONAL',...
    %        eval(sprintf('dcmhdr.PerFrameFunctionalGroupsSequence.Item_%d.MRDiffusionSequence.Item_1.DiffusionDirectionality',gg)))
    try
        eval(sprintf('bvec(%d,:)=dcmhdr.PerFrameFunctionalGroupsSequence.Item_%d.MRDiffusionSequence.Item_1.DiffusionGradientDirectionSequence.Item_1.DiffusionGradientOrientation;',gg,gg))
    catch
        % field does not exist => nothing to do
    end
    
end
bvec(1:NrB0,:) = [0 0 0];


% Rotate the gradients
%==========================================================================
if corr_rot
    
    % Method 1
    %----------------------------------------------------------------------
    if corr_method==1
        orient = dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.PlaneOrientationSequence.Item_1.ImageOrientationPatient;
        % all planes have the same orientation
        
        rot = [orient(1) orient(4);
            orient(2) orient(5);
            orient(3) orient(6)];
        rot(:,3) = null(rot');
        if det(rot)<0, rot(:,3) = -rot(:,3); end
        
        
    % Method 2
    %----------------------------------------------------------------------
    elseif corr_method==2
        ap = dcmhdr.Private_2001_105f.Item_1.Private_2005_1071*pi/180;
        fh = dcmhdr.Private_2001_105f.Item_1.Private_2005_1072*pi/180;
        rl = dcmhdr.Private_2001_105f.Item_1.Private_2005_1073*pi/180;
        Trl = [1 0 0;
            0 cos(rl) -sin(rl);
            0 sin(rl) cos(rl)];
        Tap = [cos(ap) 0 sin(ap);
            0 1 0;
            -sin(ap) 0 cos(ap)];
        Tfh = [cos(fh) -sin(fh) 0;
            sin(fh) cos(fh) 0;
            0 0 1];
        rot = Trl*Tap*Tfh;
        
        
    % Method 3
    %----------------------------------------------------------------------
    elseif corr_method==3
        orient = dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.PlaneOrientationSequence.Item_1.ImageOrientationPatient;
        % all planes have the same orientation

        % Number of slices
        Nslices = double(dcmhdr.Private_2001_1018);
        %Nslices = dcmhdr.NumberOfFrames / Ngrad;

        posit = zeros(3,Nslices);
        count = 0;
        for ii=1:(dcmhdr.NumberOfFrames/Nslices):dcmhdr.NumberOfFrames
            count = count + 1;
            posit(:,count) = eval(sprintf('dcmhdr.PerFrameFunctionalGroupsSequence.Item_%d.PlanePositionSequence.Item_1.ImagePositionPatient;',ii));
        end
        posit = mean(diff(posit,1,2),2);

        rot = [orient(1) orient(4) posit(1)/norm(posit);
            orient(2) orient(5) posit(2)/norm(posit);
            orient(3) orient(6) posit(3)/norm(posit)];
    end
    
    % Make sure the rotation matrix is really orthogonal (using polar decomposition)
    [U,S,V] = svd(rot);
    rot     = U*V';
    
    bvec_rot = bvec*rot;
    
else % no gradient correction
    bvec_rot = [];
end


% Normalize the gradient vectors
%==========================================================================
tmp = sqrt(sum(bvec.*bvec,2));
tmp(tmp==0) = 1;
bvec = bvec./repmat(tmp,[1 3]);

if corr_rot
    tmp = sqrt(sum(bvec_rot.*bvec_rot,2));
    tmp(tmp==0) = 1;
    bvec_rot = bvec_rot./repmat(tmp,[1 3]);
end


% Output files
%==========================================================================
if ~isempty(out_folder)
    
    if exist(out_folder,'dir')~=7
        warning('Output folder does not exist')
        return
    end
    
    
    % Remove extension
    %-----------------
    tmp = find(dcmhdr.Filename=='.',1,'last');
    if isempty(tmp)
        fname = dcmhdr.Filename(1:end);
    else
        fname = dcmhdr.Filename(1:tmp-1);    
    end
    
    
    % B-value
    %--------
    dlmwrite(fullfile(out_folder,[fname '-Bval.txt']),bval,'newline','pc');
    
    
    % Gradient directions
    %----------------------------------------------------------------------
    
    % Replace NaN's with 100 (only when the Gx=Gy=Gz=NaN at the same time)
    %-----------------------
    tmp = sum(isnan(bvec),2)==3; % all NaN's in one row
    if any(tmp)
        tmp = repmat(tmp,1,3);
        bvec(tmp) = 100;
        if corr_rot
            bvec_rot(tmp) = 100;
        end
    end
    
    % Write file
    %-----------
    fid = fopen(fullfile(out_folder,[fname '-Bvec.txt']),'wt');
    for ii=1:Ngrad
        fprintf(fid,'%d: %.10f, %.10f, %.10f, %g\n',ii-1,bvec(ii,:),bval(ii,:));
    end
    fclose(fid);
    
    
    % Rotated directions
    %----------------------------------------------------------------------
    if corr_rot
        fid = fopen(fullfile(out_folder,[fname '-Bvec-rot.txt']),'wt');
        for ii=1:Ngrad
            fprintf(fid,'%d: %.10f, %.10f, %.10f, %g\n',ii-1,bvec_rot(ii,:),bval(ii,:));
        end
        fclose(fid);
    end
    
end