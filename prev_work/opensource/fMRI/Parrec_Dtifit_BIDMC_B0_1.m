function Parrec_Dtifit(work,group)


% input
% -----
work.app.fsl.path = '/Applications/fsl/';
work.data.diffimg.path ='/Volumes/data/fsl_analysis/';
%
% group.name
% group.subj.name
% group.subj.round.name
% group.subj.round.run.name
% group.subj.round.run.nifti.name
% group.subj.round.run.nifti.b01
% group.subj.round.run.nifti.b02
% group.subj.round.run.nifti.b03
% group.subj.round.run.nifti.omit
% group.subj.round.run.nifti.gradienttable
% group.subj.round.run.bvecs.file
% group.subj.round.run.bvals.file


fslsetting_file = fullfile(work.app.fsl.path,'etc','fslconf','fsl');
fslbin_path = fullfile(work.app.fsl.path,'bin');

no_group = length(group);
for i_group = 1:no_group
    no_subj(i_group) = length(group(i_group).subj);
for i_subj = 1:no_subj(i_group)
    subj = group(i_group).subj(i_subj);
    no_round = length(group(i_group).subj(i_subj).round);
for i_round = 1:no_round
    round = group(i_group).subj(i_subj).round(i_round);
    no_run = length(group(i_group).subj(i_subj).round(i_round).run);
for i_run = 1:no_run
    run = group(i_group).subj(i_subj).round(i_round).run(i_run);

fprintf(1,'Now Begin ... %s\t%s\t%s\t%s\n',...
    group(i_group).name,subj.name,round.name,run.name);
dwi_path = fullfile(work.data.diffimg.path,...
    group(i_group).name,...
    subj.name,...
    round.name,...
    run.name);
cd(dwi_path);

% convert Raw data
dwiraw_name = 'dwi';
dwiraw_file = fullfile(dwi_path,dwiraw_name);
if ~exist(strcat(dwiraw_file,'.nii.gz'),'file')

if isfield(run,'nifti')
    nifti_name = run.nifti.name;
    nifti_file = fullfile(dwi_path,nifti_name);
    command = sprintf('sh -c ". %s; %s L10_NCS dwi_Vol_ -t"\n',...
        strcat(fslsetting_file,'.sh'),fullfile(fslbin_path,'fslsplit'));
        system(command);
    if isfield(run.nifti,'b01')
        b01_name = sprintf('dwi_Vol_%03.0f',run.nifti.b01);
        b01_file = fullfile(dwi_path,b01_name);
%    if isfield(run.nifti,'b02')
%        b02_name = sprintf('dwi_Vol_%03.0f',run.nifti.b02);
%        b02_file = fullfile(dwi_path,b01_name);
%    if isfield(run.nifti,'b03')
%        b03_name = sprintf('dwi_Vol_%03.0f',run.nifti.b03);
%        b03_file = fullfile(dwi_path,b01_name);
else
fprintf(1,'\nPreprocessing Skipped!\n'); 
end
   
%    end
%    end
    end
%    delete(fullfile(dwi_path,'dwi_Vol_0001.nii.gz'));
%    delete(fullfile(dwi_path,'dwi_Vol_0002.nii.gz'));
    command = sprintf('sh -c ". %s; %s -t dwi dwi_Vol_*.nii.gz"\n',...
        strcat(fslsetting_file,'.sh'),fullfile(fslbin_path,'fslmerge'));
    system(command);
    delete(fullfile(dwi_path,'dwi_Vol_*'));
end    
end

dwiraw_name = 'dwi';
dwiraw_file = fullfile(dwi_path,dwiraw_name);

if xor((exist(strcat(dwiraw_file,'.hdr'),'file') && exist(strcat(dwiraw_file,'.img'),'file')),...
	xor(exist(strcat(dwiraw_file,'.nii'),'file'),exist(strcat(dwiraw_file,'.nii.gz'),'file')))

% make preprocess path
dwipreprocess_path = fullfile(dwi_path,'fdt2_eddycorrect.brainextract');
if ~exist(dwipreprocess_path,'dir')
    mkdir(dwipreprocess_path);
end

% eddy current correct
eddycorrect_file = fullfile(dwipreprocess_path,'data');
if ~exist(strcat(eddycorrect_file,'.nii.gz'),'file')

if length(dir(dwipreprocess_path)) > 2
    delete(fullfile(dwipreprocess_path,'*'))
end
command = sprintf('sh -c ". %s; %s %s %s 0"\n',...
	strcat(fslsetting_file,'.sh'),fullfile(fslbin_path,'eddy_correct'),...
    dwiraw_file,eddycorrect_file);
system(command);

fprintf(1,'\nEddy Current Corrected!\n');
else
fprintf(1,'\nEddy Current Correction Skipped!\n'); 
end

% extract brain
seg_file = fullfile(dwipreprocess_path,'brain');
mask_file = fullfile(dwipreprocess_path,'nodif_brain_mask');
if ~exist(strcat(mask_file,'.nii.gz'),'file')
command = sprintf('sh -c ". %s; %s %s %s -F -f 0.3 -g 0"\n',...
	strcat(fslsetting_file,'.sh'),fullfile(fslbin_path,'bet'),...
    eddycorrect_file,seg_file);
system(command);
movefile(strcat(seg_file,'_mask.nii.gz'),strcat(mask_file,'.nii.gz'));

fprintf(1,'\nBrain Extracted!\n');
else
fprintf(1,'\nBrain Extraction Skipped!\n');
end

bvecs_name = 'bvecs';
run.bvecs.file = fullfile(dwi_path,bvecs_name);
bvals_name = 'bvals';
run.bvals.file = fullfile(dwi_path,bvals_name);

[bvecs_path,bvecs_name] = fileparts(run.bvecs.file);
bvecs_file = fullfile(dwipreprocess_path,bvecs_name);
if ~exist(bvecs_file,'file')
    copyfile(run.bvecs.file,bvecs_file);
end
[bvals_path,bvals_name] = fileparts(run.bvals.file);
bvals_file = fullfile(dwipreprocess_path,bvals_name);
if ~exist(bvals_file,'file')
    copyfile(run.bvals.file,bvals_file);
end

 
% make dtifit path
dtifit_path = fullfile(dwi_path,'fdt2_eddycorrect.brainextract.ditfit');
if ~exist(dtifit_path,'dir')
    mkdir(dtifit_path);
end

% fit diffusion tensor model
dtifit_file = fullfile(dtifit_path,'dti');
if ~CheckDTIFitOutput(dtifit_file)

if length(dir(dtifit_path)) > 2
    delete(fullfile(dtifit_path,'*'))
end
command = sprintf('sh -c ". %s; %s --data=%s --out=%s --mask=%s --bvecs=%s --bvals=%s"\n',...
	strcat(fslsetting_file,'.sh'),fullfile(fslbin_path,'dtifit'),...
    eddycorrect_file,dtifit_file,mask_file,bvecs_file,bvals_file);
system(command);

fprintf(1,'\nDiffusion Tensor Model Fitted!\n');
else
fprintf(1,'\nDiffusion Tensor Model Fitting Skipped!\n');
end

fprintf(1,'\n%s\t%s\t%s\t%s\tDone!\n',...
    group(i_group).name,subj.name,round.name,run.name);
else
fprintf(2,'\n%s\t%s\t%s\t%s\tOmitted!\n',...
    group(i_group).name,subj.name,round.name,run.name);

end
end
end
end

fprintf(1,'\nCompleted!\n');



% subfunction CheckDTIFitOutput
function dtifitdone = CheckDTIFitOutput(dtifit_file)

check = zeros(1,9);
check(1) = exist(strcat(dtifit_file,'_V1.nii.gz'),'file');
check(2) = exist(strcat(dtifit_file,'_V2.nii.gz'),'file');
check(3) = exist(strcat(dtifit_file,'_V3.nii.gz'),'file');
check(4) = exist(strcat(dtifit_file,'_L1.nii.gz'),'file');
check(5) = exist(strcat(dtifit_file,'_L2.nii.gz'),'file');
check(6) = exist(strcat(dtifit_file,'_L3.nii.gz'),'file');
check(7) = exist(strcat(dtifit_file,'_MD.nii.gz'),'file');
check(8) = exist(strcat(dtifit_file,'_FA.nii.gz'),'file');
check(9) = exist(strcat(dtifit_file,'_S0.nii.gz'),'file');


dtifitdone = all(check);


