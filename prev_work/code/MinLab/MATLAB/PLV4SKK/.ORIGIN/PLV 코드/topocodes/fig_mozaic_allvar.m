load SKK_coh3;

%% FIGURE 1 [for cn01]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(cn01);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('cn01','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);



%% FIGURE 2 [for cn02]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(cn02);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('cn02','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIGURE 2.5 [for cn00 =cn01-cn02]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(cn00);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('cn00','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);

%% FIGURE 3 [for us01]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(us01);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('us01','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIGURE 4 [for us02]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(us02);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('us02','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIGURE 4.5 [for us00 = us01-us02]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(us00);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('us00','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);

%% FIGURE 5 [for rr01]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(rr01);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('rr01','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIGURE 6 [for rr02]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(rr02);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('rr02','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIGURE 7 [for rr00 =rr01-rr02]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(rr00);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('rr00','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIGURE 8 [for uscn =us00-cn00]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(uscn);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('us-cn','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;
caxis([-1.00 1.00]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-1.00:0.1:1.00, 'YTickLabel', {'-1.0','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-0.1', '0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


