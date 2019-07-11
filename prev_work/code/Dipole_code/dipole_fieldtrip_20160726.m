mrifile = 'C:\Users\win\Desktop\Research\3. Analyze\Code\Dipole\dicom\00000113.dcm';

mri_orig = ft_read_mri(mrifile);

dataset = 'oddball1_mc_downsampled.fif';

grad    = ft_read_sens(dataset,'senstype','meg');
elec    = ft_read_sens(dataset,'senstype','eeg');
shape   = ft_read_headshape(dataset,'unit','cm');

figure;
ft_plot_headshape(shape);
ft_plot_sens(grad, 'style', '*b');
ft_plot_sens(elec, 'style', '*g');

view([1 0 0])
print -dpng natmeg_dip_geometry1.png

figure;
cfg = [];
ft_sourceplot(cfg, mri_orig);

save mri_orig mri_orig

cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'neuromag';
[mri_realigned1] = ft_volumerealign(cfg, mri_orig);

save mri_realigned1 mri_realigned1

cfg = [];
cfg.method = 'headshape';
cfg.headshape = shape;
cfg.coordsys = 'neuromag';
[mri_realigned2] = ft_volumerealign(cfg, mri_realigned1);

save mri_realigned2 mri_realigned2

cfg = [];
cfg.resolution = 1;
cfg.xrange = [-100 100];
cfg.yrange = [-110 140];
cfg.zrange = [-80 120];
mri_resliced = ft_volumereslice(cfg, mri_realigned2);

save mri_resliced mri_resliced

figure
ft_sourceplot([], mri_resliced);
print -dpng natmeg_dip_mri_resliced.png

% the low level plotting functions do not know how to deal with units,
% so make sure we have the MRI expressed in cm as well
mri_resliced_cm = ft_convert_units(mri_resliced, 'cm');

save mri_resliced_cm mri_resliced_cm

cfg           = [];
cfg.output    = {'brain', 'skull', 'scalp'};
mri_segmented = ft_volumesegment(cfg, mri_resliced);

% copy the anatomy into the segmented mri
mri_segmented.anatomy = mri_resliced.anatomy;

save mri_segmented mri_segmented

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
ft_plot_mesh(mesh_scalp, 'edgecolor', 'none', 'facecolor', 'skin')
material dull
camlight
lighting phong
print -dpng natmeg_dip_scalp.png

figure
ft_plot_mesh(highres_scalp, 'edgecolor', 'none', 'facecolor', 'skin')
material dull
camlight
lighting phong
print -dpng natmeg_dip_highres_scalp.png

cfg = [];
cfg.method = 'singleshell';
headmodel_meg = ft_prepare_headmodel(cfg, mesh_brain);

headmodel_meg = ft_convert_units(headmodel_meg,'cm');

save headmodel_meg headmodel_meg

figure;
hold on
ft_plot_headshape(shape);
ft_plot_sens(grad, 'style', 'ob');
ft_plot_sens(elec, 'style', 'og');
ft_plot_vol(headmodel_meg, 'facealpha', 0.5, 'edgecolor', 'none'); % "lighting phong" does not work with opacity
material dull
camlight

view([1 0 0]) 
print -dpng natmeg_dip_geometry2.png
%%
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
cfg.channel       = 'MEG';
cfg.precision     = 'single';

data_meg = ft_preprocessing(cfg);

save data_meg data_meg

cfg = [];
cfg.method = 'summary';
cfg.channel = 'MEG*1';
cfg.keepchannel = 'yes';
data_meg_clean1 = ft_rejectvisual(cfg, data_meg);

cfg.channel = {'MEG*2', 'MEG*3'};
data_meg_clean2 = ft_rejectvisual(cfg, data_meg_clean1);

save data_meg_clean2 data_meg_clean2

cfg = [];
timelock_all = ft_timelockanalysis(cfg, data_meg_clean2);

cfg.trials = find(data_meg_clean2.trialinfo==1);
timelock_std = ft_timelockanalysis(cfg, data_meg_clean2);

cfg.trials = find(data_meg_clean2.trialinfo==2);
timelock_dev = ft_timelockanalysis(cfg, data_meg_clean2);

cfg = [];
cfg.layout = 'neuromag306all.lay';
cfg.layout = 'neuromag306planar.lay';
cfg.layout = 'neuromag306mag.lay';
% cfg.channel = 'MEG*1';
% cfg.channel = {'MEG*2', 'MEG*3'};
ft_multiplotER(cfg, timelock_std, timelock_dev);

print -dpng natmeg_dip_meg_multiplot.png

cfg = [];
cfg.parameter = 'avg';
cfg.operation = 'x1 - x2';
timelock_dif = ft_math(cfg, timelock_dev, timelock_std);

cfg = [];
cfg.layout = 'neuromag306all.lay';
cfg.layout = 'neuromag306planar.lay';
cfg.layout = 'neuromag306mag.lay';
% cfg.channel = 'MEG*1';
% cfg.channel = {'MEG*2', 'MEG*3'};
ft_multiplotER(cfg, timelock_dif);

save timelock timelock*

cfg = [];
cfg.latency = [0.080 0.110];
cfg.numdipoles = 2;
cfg.symmetry = 'x';
cfg.grid.resolution = 1;
cfg.grid.unit = 'cm';
cfg.gridsearch = 'yes';
cfg.vol = headmodel_meg;
cfg.senstype = 'meg';
cfg.channel = {'MEG*2', 'MEG*3'};
source_planar = ft_dipolefitting(cfg, timelock_all);

cfg.channel = 'MEG*1';
source_mag = ft_dipolefitting(cfg, timelock_all);

cfg = [];
cfg.location = source_planar.dip.pos(1,:);
ft_sourceplot(cfg, mri_resliced_cm);

print -dpng natmeg_dip_planarortho.png

figure
hold on

ft_plot_dipole(source_mag.dip.pos(1,:), mean(source_mag.dip.mom(1:3,:),2), 'color', 'r')
ft_plot_dipole(source_mag.dip.pos(2,:), mean(source_mag.dip.mom(4:6,:),2), 'color', 'r')

ft_plot_dipole(source_planar.dip.pos(1,:), mean(source_planar.dip.mom(1:3,:),2), 'color', 'g')
ft_plot_dipole(source_planar.dip.pos(2,:), mean(source_planar.dip.mom(4:6,:),2), 'color', 'g')

pos = mean(source_mag.dip.pos,1);
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 1 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 0 1], 'resolution', 0.1)

ft_plot_crosshair(pos, 'color', [1 1 1]/2);

axis tight
axis off

view(12, -10)
print -dpng natmeg_dip_symx.png

cfg = [];
cfg.latency = [0.080 0.110];
cfg.numdipoles = 2;
cfg.symmetry = [];
cfg.gridsearch = 'no';
cfg.dip.pos = source_planar.dip.pos;
cfg.vol = headmodel_meg;
cfg.channel = {'MEG*2', 'MEG*3'};
cfg.senstype = 'meg';
source_planar_nosym = ft_dipolefitting(cfg, timelock_all);

%%
figure;
hold on

ft_plot_dipole(source_planar.dip.pos(1,:), mean(source_planar.dip.mom(1:3,:),2), 'color', 'g')
ft_plot_dipole(source_planar.dip.pos(2,:), mean(source_planar.dip.mom(4:6,:),2), 'color', 'g')

ft_plot_dipole(source_planar_nosym.dip.pos(1,:), mean(source_planar_nosym.dip.mom(1:3,:),2), 'color', 'm')
ft_plot_dipole(source_planar_nosym.dip.pos(2,:), mean(source_planar_nosym.dip.mom(4:6,:),2), 'color', 'm')

pos = mean(source_planar.dip.pos,1);
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 1 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 0 1], 'resolution', 0.1)

ft_plot_crosshair(pos, 'color', [1 1 1]/2);

axis tight
axis off

view(12, -10)
print -dpng natmeg_dip_nosym.png

cfg = [];
cfg.latency = 'all';
cfg.numdipoles = 2;
cfg.symmetry = [];
cfg.nonlinear = 'no';  % use a fixed position
cfg.gridsearch = 'no';
cfg.dip.pos = source_planar.dip.pos;
cfg.vol = headmodel_meg;
cfg.channel = {'MEG*2', 'MEG*3'};
cfg.senstype = 'meg';
source_all = ft_dipolefitting(cfg, timelock_all); % estimate the amplitude and orientation
source_std = ft_dipolefitting(cfg, timelock_std); % estimate the amplitude and orientation
source_dev = ft_dipolefitting(cfg, timelock_dev); % estimate the amplitude and orientation
source_dif = ft_dipolefitting(cfg, timelock_dif); % estimate the amplitude and orientation

figure
subplot(3,1,1); title('left: std & dev')
hold on
plot(source_std.time, source_std.dip.mom(1:3,:), '-')
legend({'x', 'y', 'z'});
plot(source_dev.time, source_dev.dip.mom(1:3,:), '.-')
axis([-0.1 0.4 -40e-3 40e-3])
grid on

subplot(3,1,2); title('right: std & dev')
hold on
plot(source_std.time, source_std.dip.mom(4:6,:), '-')
legend({'x', 'y', 'z'});
plot(source_dev.time, source_dev.dip.mom(4:6,:), '.-')
axis([-0.1 0.4 -40e-3 40e-3])
grid on

subplot(3,1,3); title('dif = dev - std')
hold on
plot(source_dif.time, source_dif.dip.mom(1:3,:), '-');
legend({'x', 'y', 'z'});
plot(source_dif.time, source_dif.dip.mom(4:6,:), '-');
axis([-0.1 0.4 -40e-3 40e-3])
grid on

print -dpng natmeg_dip_timeseries.png

cfg = [];
cfg.numdipoles = 2;
cfg.symmetry = 'x';
cfg.gridsearch = 'no';
cfg.dip.pos = source_planar.dip.pos;
cfg.vol = headmodel_meg;
cfg.channel = {'MEG*2', 'MEG*3'};
cfg.senstype = 'meg';
cfg.latency = [0.080 0.100];
source_all = ft_dipolefitting(cfg, timelock_all);
source_std = ft_dipolefitting(cfg, timelock_std);
source_dev = ft_dipolefitting(cfg, timelock_dev);

cfg.latency = [0.150 0.180];
source_dif = ft_dipolefitting(cfg, timelock_dif);

figure
hold on

ft_plot_dipole(source_all.dip.pos(1,:), mean(source_all.dip.mom(1:3,:),2), 'color', 'r')
ft_plot_dipole(source_all.dip.pos(2,:), mean(source_all.dip.mom(4:6,:),2), 'color', 'r')

ft_plot_dipole(source_std.dip.pos(1,:), mean(source_std.dip.mom(1:3,:),2), 'color', 'g')
ft_plot_dipole(source_std.dip.pos(2,:), mean(source_std.dip.mom(4:6,:),2), 'color', 'g')

ft_plot_dipole(source_dev.dip.pos(1,:), mean(source_dev.dip.mom(1:3,:),2), 'color', 'b')
ft_plot_dipole(source_dev.dip.pos(2,:), mean(source_dev.dip.mom(4:6,:),2), 'color', 'b')

ft_plot_dipole(source_dif.dip.pos(1,:), mean(source_dif.dip.mom(1:3,:),2), 'color', 'y')
ft_plot_dipole(source_dif.dip.pos(2,:), mean(source_dif.dip.mom(4:6,:),2), 'color', 'y')

pos = mean(source_std.dip.pos,1);
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 1 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 0 1], 'resolution', 0.1)

ft_plot_crosshair(pos, 'color', [1 1 1]/2);
axis tight
axis off

print -dpng natmeg_dip_sourcedif.png

fg = [];
cfg.model = 'moving'; % default is rotating
cfg.latency = [0.070 0.140];
cfg.numdipoles = 2;
cfg.gridsearch = 'no';
cfg.dip.pos = source_planar.dip.pos;
cfg.vol = headmodel_meg;
cfg.channel = {'MEG*2', 'MEG*3'};
cfg.senstype = 'meg';
source = ft_dipolefitting(cfg, timelock_std);

% copy the time-varying position of the two dipoles into a single matrix for convenience.
for i=1:numel(source.dip)
  pos1(i,:) = source.dip(i).pos(1,:);
  pos2(i,:) = source.dip(i).pos(2,:);
end

figure
hold on

plot3(pos1(:,1), pos1(:,2), pos1(:,3), 'r.')
plot3(pos2(:,1), pos2(:,2), pos2(:,3), 'g.')

pos = (mean(pos1, 1) + mean(pos2, 1))/2;

ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 1 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 0 1], 'resolution', 0.1)

ft_plot_crosshair(pos, 'color', [1 1 1]/2);

axis tight
axis off

print -dpng natmeg_dip_moving.png

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

ft_pllot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 1 0], 'resolution', 0.1)
ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [0 0 1], 'resolution', 0.1)

ft_plot_crosshair(pos, 'color', [1 1 1]/2);

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

figureot_dipole(source_mag.dip.pos(1,:), mean(source_mag.dip.mom(1:3,:),2), 'color', 'r')
ft_plot_dipole(source_mag.dip.pos(2,:), mean(source_mag.dip.mom(4:6,:),2), 'color', 'r')

ft_plot_dipole(source_planar.dip.pos(1,:), mean(source_planar.dip.mom(1:3,:),2), 'color', 'g')
ft_plot_dipole(source_planar.dip.pos(2,:), mean(source_planar.dip.mom(4:6,:),2), 'color', 'g')

pos = mean(source_eeg.dip.pos,1);
% pos = source_eeg.dip.pos(1,:); % use another crossection for the MRI

ft_plot_slice(mri_resliced_cm.anatomy, 'transform', mri_resliced_cm.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.1)
ft_p

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


