%% dipole fitting for sound N1 localization
% designed by Sejik Park (Korea University Undergraduated)

%% Parameter
% set path
template = 'D:\Research\3. Analyze\Code\Dipole_code\template';
mrifile = 'D:\Research\3. Analyze\Code\Dipole_code\single_subj_T1_1mm.nii';
electrodePosition = 'D:\Research\3. Analyze\Code\Dipole_code\template\10_20.txt';
dataset = 'D:\Research\3. Analyze\Code\Dipole_code\template\standard_skin_14038.vol';
result = 'D:\Research\3. Analyze\Code\Dipole_code\result';

%% Preprocessing
cd(template);
mri = ft_read_mri('Subject01.mri');
cfg           = [];
cfg.output    = {'brain','skull','scalp'};
segmentedmri  = ft_volumesegment(cfg, mri);
cfg=[];
cfg.tissue={'brain','skull','scalp'};
cfg.numvertices = [3000 2000 1000];
bnd=ft_prepare_mesh(cfg,segmentedmri);
% cfg        = [];
% cfg.method ='dipoli'; % You can also specify 'openmeeg', 'bemcp', or another method.
% vol        = ft_prepare_headmodel(cfg, bnd);

% template mri information from fieldtrip
mri_orig = ft_read_mri(mrifile);

% electrode position information from Brainvision Analyzer
elec = ft_read_sens(electrodePosition);
% chan position correction 
elec.chanpos = elec.chanpos * 1.4;
elec.elecpos = elec.elecpos * 1.4;

% template head shape information from fieldtrip
shape   = ft_read_headshape(dataset,'unit','cm');
% 'cm' to 'mm'
shape.pos = shape.pos * 10;
shape.unit = 'mm';

% plot MNI brain and electrode position
figure;
cd(result);
ft_plot_headshape(shape);
ft_plot_sens(elec, 'style', '*g');
view([1 0 0])
print -dpng MNIbrain_BAelectrode.png

% plot MNI brain data
figure;
cd(result);
cfg = [];
ft_sourceplot(cfg, mri_orig);
print -dpng MNIbrain_source.png

% volume align (realigned volume: how to select the right coordinate??)
cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'neuromag';
[mri_realigned1] = ft_volumerealign(cfg, mri_orig);

% volume align with head shape
cfg = [];
cfg.method = 'headshape';
cfg.headshape = shape;
cfg.coordsys = 'neuromag';
[mri_realigned2] = ft_volumerealign(cfg, mri_realigned1);

% mri volume slice
cfg = [];
cfg.resolution = 1;
cfg.xrange = [-100 100];
cfg.yrange = [-110 140];
cfg.zrange = [-80 120];
mri_resliced = ft_volumereslice(cfg, mri_realigned2);
figure;
cd(result);
ft_sourceplot([], mri_resliced);
print -dpng mri_recorrected.png

% mri volume segement
cfg           = [];
cfg.output    = {'brain', 'skull', 'scalp'};
mri_segmented = ft_volumesegment(cfg, mri_orig);

% copy the anatomy into the segmented mri
mri_segmented.anatomy = mri_resliced.anatomy;


figure;
cd(result);
cfg = [];
cfg.funparameter = 'brain';
ft_sourceplot(cfg, mri_segmented);
print -dpng natmeg_dip_segmented_brain.png

cfg.funparameter = 'skull';
ft_sourceplot(cfg, mri_segmented);
print -dpng natmeg_dip_segmented_skull.png

cfg.funparameter = 'scalp';
ft_sourceplot(cfg, mri_segmented);
print -dpng natmeg_dip_segmented_scalp.png

cfg = [];
cfg.method = 'projectmesh';
cfg.tissue = 'brain';
cfg.numvertices = 3000;
mesh_brain = ft_prepare_mesh(cfg, mri_segmented);

cfg = [];
cfg.method = 'projectmesh';
cfg.tissue = 'skull';
cfg.numvertices = 2000;
mesh_skull = ft_prepare_mesh(cfg, mri_segmented);

cfg = [];
cfg.method = 'projectmesh';
cfg.tissue = 'scalp';
cfg.numvertices = 1000;
mesh_scalp = ft_prepare_mesh(cfg, mri_segmented);

cfg = [];
cfg.method = 'isosurface';
cfg.tissue = 'scalp';
cfg.numvertices = 16000;
highres_scalp = ft_prepare_mesh(cfg, mri_segmented);

save mesh mesh_* highres_scalp

figure
ft_plot_mesh(mesh_brain, 'edgecolor', 'none', 'facecolor', 'r')
ft_plot_mesh(mesh_skull, 'edgecolor', 'none', 'facecolor', 'g')
ft_plot_mesh(mesh_scalp, 'edgecolor', 'none', 'facecolor', 'b')
alpha 0.3
view(132, 14)

print -dpng natmeg_dip_meshorig.png

mesh_scalp_infl = mesh_scalp;
mesh_scalp_infl.pos = 1.10 * mesh_scalp_infl.pos;

figure
ft_plot_mesh(mesh_brain, 'edgecolor', 'none', 'facecolor', 'r')
ft_plot_mesh(mesh_skull, 'edgecolor', 'none', 'facecolor', 'g')
ft_plot_mesh(mesh_scalp_infl, 'edgecolor', 'none', 'facecolor', 'b')
alpha 0.3
view(132, 14)

print -dpng natmeg_dip_meshinfl.png

binary_brain = mri_segmented.brain;
binary_skull = mri_segmented.skull | binary_brain;
binary_scalp = mri_segmented.scalp | binary_brain | binary_skull;

close all

figure(1)
tmp = binary_scalp + binary_skull + binary_brain;
imagesc(squeeze(tmp(:,:,100)));
print -dpng natmeg_dip_segorg.png

binary_scalp = imdilate(binary_scalp, strel_bol(1));

figure(2)
tmp = binary_scalp + binary_skull + binary_brain;
imagesc(squeeze(tmp(:,:,100)));
print -dpng natmeg_dip_segdil1.png

binary_scalp = imdilate(binary_scalp, strel_bol(1));

figure(3)
tmp = binary_scalp + binary_skull + binary_brain;
imagesc(squeeze(tmp(:,:,100)));
print -dpng natmeg_dip_segdil2.png
%%
binary_scalp = mri_segmented.scalp + binary_skull;

binary_skull = binary_skull & imerode(binary_scalp, strel_bol(2)); % fully contained inside eroded scalp
binary_brain = binary_brain & imerode(binary_skull, strel_bol(2)); % fully contained inside eroded skull

figure(4)
tmp = binary_scalp + binary_skull + binary_brain;
imagesc(squeeze(tmp(:,:,100)));
print -dpng natmeg_dip_segbool.png

mri_segmented2 = mri_segmented;
% insert the updated binary volumes, taking out the center part for skull and scalp
mri_segmented2.brain    = binary_brain;
mri_segmented2.skull    = binary_skull & ~binary_brain;
mri_segmented2.scalp    = binary_scalp & ~binary_brain & ~binary_skull;
mri_segmented2.combined = binary_scalp + binary_skull + binary_brain; % only for plotting

save mri_segmented2 mri_segmented2

cfg = [];
cfg.funparameter = 'combined';
cfg.funcolormap = 'jet';
ft_sourceplot(cfg, mri_segmented2);

mri_segmented2 = rmfield(mri_segmented2, 'combined');

cfg = [];
cfg.method = 'projectmesh';
cfg.tissue = 'brain';
cfg.numvertices = 3000;
mesh_eeg(1) = ft_prepare_mesh(cfg, mri_segmented2);

cfg.tissue = 'skull';
cfg.numvertices = 2000;
mesh_eeg(2) = ft_prepare_mesh(cfg, mri_segmented2);

cfg.tissue = 'scalp';
cfg.numvertices = 1000;
mesh_eeg(3) = ft_prepare_mesh(cfg, mri_segmented2);

figure
ft_plot_mesh(mesh_eeg(1), 'edgecolor', 'none', 'facecolor', 'r')
ft_plot_mesh(mesh_eeg(2), 'edgecolor', 'none', 'facecolor', 'g')
ft_plot_mesh(mesh_eeg(3), 'edgecolor', 'none', 'facecolor', 'b')
alpha 0.3

save mesh_eeg mesh_eeg

cfg = [];
cfg.method = 'bemcp';
cfg.conductivity = [1 1/20 1].*0.33; % brain, skull, scalp
headmodel_eeg = ft_prepare_headmodel(cfg, mesh_eeg);

save headmodel_eeg headmodel_eeg

cfg = [];
cfg.dataset = dataset;
cfg.trialdef.prestim        = 0.2;
cfg.trialdef.poststim       = 0.4;
cfg.trialdef.rsp_triggers   = [256 4096];
cfg.trialdef.stim_triggers  = [1 2];
cfg.trialfun                = 'trialfun_oddball_stimlocked';

cfg = ft_definetrial(cfg);

cfg.continuous    = 'yes';
cfg.hpfilter      = 'no';
cfg.detrend       = 'no';
cfg.demean        = 'yes';
cfg.baselinewindow = [-inf 0];
cfg.dftfilter     = 'yes';
cfg.dftfreq       = [50 100];
cfg.lpfilter      = 'yes';
cfg.lpfreq        = 120;
cfg.channel       = 'EEG';
cfg.precision     = 'single';

data_eeg = ft_preprocessing(cfg);

save data_eeg data_eeg

cfg = [];
cfg.method = 'summary';
cfg.keepchannel = 'no';
cfg.preproc.reref = 'yes';
cfg.preproc.refchannel = 'all';
data_eeg_clean = ft_rejectvisual(cfg, data_eeg);

cfg = [];
cfg.reref = 'yes';
cfg.refchannel = 'all';
data_eeg_reref = ft_preprocessing(cfg, data_eeg_clean);

save data_eeg_reref data_eeg_reref

cfg = [];
timelock_eeg_all = ft_timelockanalysis(cfg, data_eeg_reref);

cfg.trials = find(data_eeg_reref.trialinfo==1);
timelock_eeg_std = ft_timelockanalysis(cfg, data_eeg_reref);

cfg.trials = find(data_eeg_reref.trialinfo==2);
timelock_eeg_dev = ft_timelockanalysis(cfg, data_eeg_reref);

cfg = [];
cfg.layout = 'neuromag306eeg1005_natmeg.lay';
ft_multiplotER(cfg, timelock_eeg_std, timelock_eeg_dev);

print -dpng natmeg_dip_meg_multiplot.png

cfg = [];
cfg.parameter = 'avg';
cfg.operation = 'x1 - x2';
timelock_eeg_dif = ft_math(cfg, timelock_eeg_dev, timelock_eeg_std);

cfg = [];
cfg.layout = 'neuromag306eeg1005_natmeg.lay';
ft_multiplotER(cfg, timelock_eeg_dif);

cfg = [];
cfg.latency = [0.080 0.110];
cfg.numdipoles = 2;
cfg.symmetry = 'x';
cfg.grid.resolution = 1;
cfg.grid.unit = 'cm';
cfg.gridsearch = 'yes';
cfg.vol = headmodel_eeg;
cfg.senstype = 'eeg'; 
cfg.channel = 'all';
source_eeg = ft_dipolefitting(cfg, timelock_eeg_all);

cfg = [];
cfg.location = source_eeg.dip.pos(1,:);
ft_sourceplot(cfg, mri_resliced_cm);

figure

ft_plot_dipole(source_eeg.dip.pos(1,:), mean(source_eeg.dip.mom(1:3,:),2), 'color', 'b')
ft_plot_dipole(source_eeg.dip.pos(2,:), mean(source_eeg.dip.mom(4:6,:),2), 'color', 'b')

axis tight
axis off


cfg = [];
cfg.latency = [0.080 0.110];
cfg.numdipoles = 2;
cfg.dip.pos = source_eeg.dip.pos;
cfg.gridsearch = 'no';
cfg.nonlinear = 'yes';
cfg.vol = headmodel_eeg;
cfg.senstype = 'eeg'; 
cfg.channel = 'all';
source_eeg2 = ft_dipolefitting(cfg, timelock_eeg_all);

pos = mean(source_eeg.dip.pos,1);
% pos = source_eeg.dip.pos(1,:); % use another crossection for the MRI

ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.1)

ft_plot_dipole(source_eeg.dip.pos(1,:), mean(source_eeg.dip.mom(1:3,:),2), 'color', 'b')
ft_plot_dipole(source_eeg.dip.pos(2,:), mean(source_eeg.dip.mom(4:6,:),2), 'color', 'b')

ft_plot_dipole(source_eeg2.dip.pos(1,:), mean(source_eeg2.dip.mom(1:3,:),2), 'color', 'm')
ft_plot_dipole(source_eeg2.dip.pos(2,:), mean(source_eeg2.dip.mom(4:6,:),2), 'color', 'm')

pos = mean(source_eeg.dip.pos,1);
% pos = source_eeg.dip.pos(1,:); % alternative crossection for the MRI

ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 1 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 0 1], 'resolution', 0.1)

ft_plot_crosshair(pos, 'color', [1 1 1]/2);

axis tight
axis off


