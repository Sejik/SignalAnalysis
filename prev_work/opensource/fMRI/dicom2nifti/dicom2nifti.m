function dicom2nifti(dcmfile,elim_grad,elim_slc)
%
% dicom2nifti(dcmfile,elim_grad,elim_slc) converts data from DICOM to NIfTI
% and creates the gradient table for DTI files.
% 
% 
%USAGE
%-----
% >> dicom2nifti(dcmfile): DICOM to NIfTI conversion
% >> dicom2nifti(dcmfile,elim_grad): DICOM to NIfTI conversion, eliminating
%    some gradient directions
% >> dicom2nifti(dcmfile,elim_grad,elim_slc): DICOM to NIfTI conversion,
%    eliminating some gradient directions (if it does not apply, use elim_grad=[])
%    and some slices
% 
% 
%INPUT
%-----
% - DCMFILE  : DICOM file name or cell array of strings with the file names
% - ELIM_GRAD: 1xEG matrix with the gradient directions to be eliminated (e.g. 34)
% - ELIM_SLC : 1xES matrix with the slices to be eliminated
% 
% 
%OUTPUT
%------
% - DCMFILE.nii in the same folder as the DCMFILE
% - If it is a DTI image, inside the same folder as DCMFILE:
%   - DCMFILE-Bval.txt with the B-values
%   - DCMFILE-Bvec.txt with gradient directions (in DTI-Studio format)
%   - DCMFILE-Bvec-rot.txt with the orientation corrected gradient
%     directions
%   The output is the same as in
%   http://godzilla.kennedykrieger.org/~jfarrell/OTHERphilips/GUI.html, but
%   not the same as obtained from Chris Rorden's dcm2nii (01 April 2010)
% 
%   ATTENTION: X and Y gradient directions may need to be switched!
% 
% 
% Works with DICOM files from Philips Achieva 3T R2.6, with:
% - Slice orientation  : transverse
% - Patient position   : head first
% - Patient orientation: supine
% - Fold-over direction: AP
% - Fat shift direction: P
% - Gradient resolution: high (DTI)
% - Gradient overplus  : yes (DTI)
% - Sort images        : b=0 volume first (DTI)
% 
% 
% For a DTI file:
%  If the dimensions of the DICOM data are DX x DY x 1 x DZ*NGRAD, where
%  - DX   : dimension in the X direction (e.g. 256)
%  - DY   : dimension in the Y direction (e.g. 256)
%  - DZ   : dimension in the Z direction (e.g. 70)
%  - NGRAD: number of gradients, including b=0 (e.g. 34)
% the dimensions of the NIfTI file are DX x DY x (DZ-ELIM_SLC) x
% (NGRAD-ELIM_GRAD).
% 
% With "Gradient resolution = high" (32 gradients) and "overplus = yes",
% NGRAD=34 (1st image with b=0 and the 34th image with isotropic
% gradients). Normally, the last image is expendable, and ELIM_GRAD=34
% should be used.
% 
% 
% Requires the Image Processing Toolbox
% 
% 
% See also DTI_GRAD_TABLE
% 

% Guilherme Coco Beltramini (guicoco@gmail.dot.com)
% 2012-Sep-11, 01:37am


% Some useful fields that are in the Philips DICOM header
%==========================================================================
% >> dcmhdr = dicominfo(dcmfile); % takes a long time to run (~s or ~min
%                                   depending on the computer)
% 
% For Philps Achieva R2.6:
% 
% dcmfile dimensions:
%   dcmhdr.Width x dcmhdr.Height  x NumberOfSlices x TimesPerSlice  //or//
%   dcmhdr.Rows  x dcmhdr.Columns x NumberOfSlices x TimesPerSlice,
% where
%   NumberOfSlices = dcmhdr.Private_2001_1018 //or//
%     dcmhdr.Private_2001_105f.Item_1.Private_2001_102d
%   TimesPerSlice  = dcmhdr.NumberOfFrames / NumberOfSlices
% 
% TR = dcmhdr.Private_2005_1030/1000 //or//
%   dcmhdr.SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.RepetitionTime / 1000
% 
% Diffusion B value:
% dcmhdr.PerFrameFunctionalGroupsSequence.Item_XX.MRDiffusionSequence.Item_1.DiffusionBValue =
%   0    (1st acquisition of each slice [XX=1,1+(Ngrad+2),1+2(Ngrad+2)]),
%   1000 (all other acquisitions)
% 
% Diffusion directionality:
% dcmhdr.PerFrameFunctionalGroupsSequence.Item_XX.MRDiffusionSequence.Item_1.DiffusionDirectionality =
%   'NONE'        (XX=1,1+(Ngrad+2),1+2(Ngrad+2),...),
%   'ISOTROPIC'   (XX=Ngrad+2,2(Ngrad+2),...),
%   'DIRECTIONAL' (all other acquisitions)

if nargin<3
    elim_slc = [];
end
if nargin<2
    elim_grad = [];
end
if ~iscellstr(dcmfile)
    if ischar(dcmfile)
        dcmfile = {dcmfile};
    else
        error('Invalid file name')
    end
end

tmp = clock;
disp('-------------------------------------------------------------------')
fprintf('(%.2d:%.2d:%02.0f) Running %s.m...\n',...
    tmp(4),tmp(5),tmp(6),mfilename)


num_dcmfiles = length(dcmfile);

for ff=1:num_dcmfiles % loop for all the files

fprintf('- File %d/%d:\n',ff,num_dcmfiles)


% Read DICOM file
%==========================================================================
fprintf('  Reading DICOM data...')
data = dicomread(dcmfile{ff});
data = squeeze(data); % Philips R2.6: 3rd dimension is useless
fprintf(' Done!\n')


% Read the DICOM header
%==========================================================================
fprintf('  Reading DICOM header...')
dcmhdr    = dicominfo(dcmfile{ff});
Nslices   = dcmhdr.Private_2001_1018;
Ngrad     = dcmhdr.NumberOfFrames / Nslices;
TR        = dcmhdr.SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.RepetitionTime / 1000;
voxel_sz  = [dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
    dcmhdr.SpacingBetweenSlices];
% dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.SliceThickness
scl_slope = dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.PixelValueTransformationSequence.Item_1.RescaleSlope;
% also in dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.RescaleSlope
scl_inter = dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.PixelValueTransformationSequence.Item_1.RescaleIntercept;
% also in dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.RescaleIntercept
fprintf(' Done!\n')


% Reshape the data
%==========================================================================
fprintf('  Creating NIfTI image...')
% X x Y x Z x G
% DX x DY x 1 x DZ*NGRAD --> DX x DY x DZ x NGRAD

slc = 1:Nslices;
slc(elim_slc) = [];

grad = 1:Ngrad;
grad(elim_grad) = [];

tmp = zeros(size(data,1),size(data,2),Nslices,Ngrad,'uint16');
for gg=grad
    for ss=slc
        tmp(:,:,ss,gg) = data(:,:,gg+(ss-1)*Ngrad);
    end
end

% ~30x slower than the above:
% for ss=1:Nslices
%     tmp(:,:,ss,1:Ngrad) = data(:,:,((ss-1)*Ngrad+1):(ss*Ngrad));
% end

% Eliminate slices and gradients
%--------------------------------------------------------------------------
tmp(:,:,elim_slc,:)  = [];
tmp(:,:,:,elim_grad) = [];
data = permute(tmp,[2 1 3 4]);
data = flipdim(data,1);
data = flipdim(data,2);


% File name
%==========================================================================
[fpath,fname] = fileparts(dcmfile{ff}); % exclude file extension if there is one
if isempty(fpath)
    fpath = pwd;
end
fname = [fname '.nii'];


% Get the orientation matrix
%==========================================================================

% Plane orientation (all planes have the same orientation)
orient = dcmhdr.PerFrameFunctionalGroupsSequence.Item_1.PlaneOrientationSequence.Item_1.ImageOrientationPatient;

% Rotation matrix
rot = [orient(1) orient(4);
    orient(2) orient(5);
    -orient(3) -orient(6)];
rot(:,3) = null(rot');
qfactor  = 1;
if det(rot)<0
    rot(:,3) = -rot(:,3);
    %qfactor  = -1;
end
% explanation for why it is done this way at:
% http://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/quatern.html

% Make sure it is really orthogonal (using polar decomposition)
[U,S,V] = svd(rot);
rot     = U*V';

% Choose the origin as the center of the matrix
origin = round([size(data,1) ; size(data,2) ; size(data,3)]/2);

% Orientation matrix
mat = [ [rot ; [0 0 0]] [-rot*(origin.*voxel_sz) ; 1]] .* ...
    [voxel_sz' 1; voxel_sz' 1; voxel_sz' 1; 0 0 0 1];
% origin: O=mat\[0 0 0 1]'; O=O(1:3);
% same as: O=inv(mat); O=O(1:3,4);


% Create NIfTI file
%==========================================================================

% Using "SPM8" (http://www.fil.ion.ucl.ac.uk/spm/)
%-------------------------------------------------
% nii = nifti; % NIfTI object (mat, mat0, descrip)
% nii.dat = file_array(fullfile(fpath,fname),...
%     [size(data,1) size(data,2) Nslices-length(elim_slc) Ngrad-length(elim_grad)],...
%     'INT16-LE',352,scl_slope,scl_inter,'rw');
% nii.mat            = mat;
% nii.mat_intent     = 'Scanner';
% nii.mat0           = mat;
% nii.mat0_intent    = nii.mat_intent;
% nii.timing.toffset = 0;
% nii.timing.tspace  = TR;
% nii.descrip        = ['converted from DICOM using ' mfilename];
% create(nii)
% nii.dat(:,:,:,:) = data;

% Using the "Tools for NIfTI and ANALYZE image", by Jimmy Shen
%--------------------------------------------------------------
% Necessary functions: make_nii, save_nii, save_nii_ext, save_nii_hdr,
% verify_nii_ext
nii = make_nii(data,voxel_sz',origin,4,['converted from DICOM using ' mfilename]);
nii.hdr.dime.pixdim(1)  = qfactor;
nii.hdr.dime.pixdim(5)  = TR;
nii.hdr.dime.vox_offset = 352;
nii.hdr.dime.scl_slope  = scl_slope;
nii.hdr.dime.scl_inter  = scl_inter;
nii.hdr.dime.xyzt_units = 10; % mm and s

% Rotation matrix in quaternion representation. Based on:
% - http://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/quatern.html
% - mat44_to_quatern()
nii.hdr.hist.qform_code = 1;
nii.hdr.hist.sform_code = 1;
quatern_a = 1 + sum(diag(rot));
if quatern_a > .5
    quatern_a = .5 * sqrt(quatern_a); % not stored
    quatern_b = .25*(rot(3,2)-rot(2,3))/quatern_a;
    quatern_c = .25*(rot(1,3)-rot(3,1))/quatern_a;
    quatern_d = .25*(rot(2,1)-rot(1,2))/quatern_a;
else
    xd = 1 + rot(1,1) - rot(2,2) - rot(3,3);
    yd = 1 + rot(2,2) - rot(1,1) - rot(3,3);
    zd = 1 + rot(3,3) - rot(1,1) - rot(2,2);
    if xd > 1
        quatern_b = .5 * sqrt(xd);
        quatern_c = .25 * (rot(1,2)+rot(2,1)) / quatern_b;
        quatern_d = .25 * (rot(1,3)+rot(3,1)) / quatern_b;
        quatern_a = .25 * (rot(3,2)-rot(2,3)) / quatern_b;
    elseif yd > 1
        quatern_c = .5 * sqrt(yd);
        quatern_b = .25 * (rot(1,2)+rot(2,1)) / quatern_c;
        quatern_d = .25 * (rot(2,3)+rot(3,2)) / quatern_c;
        quatern_a = .25 * (rot(1,3)-rot(3,1)) / quatern_c;
    else
        quatern_d = .5 * sqrt(zd);
        quatern_b = .25 * (rot(1,3)+rot(3,1)) / quatern_d;
        quatern_c = .25 * (rot(2,3)+rot(3,2)) / quatern_d;
        quatern_a = .25 * (rot(2,1)-rot(1,2)) / quatern_d;
    end
    if quatern_a < 0
        %quatern_a = -quatern_a;
        quatern_b = -quatern_b;
        quatern_c = -quatern_c;
        quatern_d = -quatern_d;
    end
end
nii.hdr.hist.quatern_b = quatern_b;
nii.hdr.hist.quatern_c = quatern_c;
nii.hdr.hist.quatern_d = quatern_d;


nii.hdr.hist.qoffset_x = sum(mat(1,1:3),2) + mat(1,4);
nii.hdr.hist.qoffset_y = sum(mat(2,1:3),2) + mat(2,4);
nii.hdr.hist.qoffset_z = sum(mat(3,1:3),2) + mat(3,4);
nii.hdr.hist.srow_x    = [mat(1,1:3) nii.hdr.hist.qoffset_x];
nii.hdr.hist.srow_y    = [mat(2,1:3) nii.hdr.hist.qoffset_y];
nii.hdr.hist.srow_z    = [mat(3,1:3) nii.hdr.hist.qoffset_z];
nii.hdr.hist.magic     = 'n+1';
save_nii(nii,fullfile(fpath,fname))

fprintf(' Done!\n')
%fprintf('  %s was created in %s\n',fname,fpath)


% Get gradient table
%==========================================================================
if Ngrad - length(elim_grad) - 1 > 0
    fprintf('  Generating gradient table...')
    dti_grad_table(dcmhdr,Ngrad-length(elim_grad)-1,1,fpath);
    % b=0 => 1 extra gradient in the beggining)
    fprintf(' Done!\n')
    %fprintf('  Gradient tables were saved in %s\n',fpath)
    %fprintf('  ATTENTION: X and Y gradient directions may need to be switched!\n')
end


end


tmp = clock;
fprintf('(%.2d:%.2d:%02.0f) %s.m done!\n',...
    tmp(4),tmp(5),tmp(6),mfilename)
disp('-------------------------------------------------------------------')