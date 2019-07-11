
% contourf(us-cn)
load SKK_coh2;
%% FIGURE 1
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
caxis([-0.16 0.16]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-0.16:0.02:0.16, 'YTickLabel', {'-0.16','-0.14','-0.12','-0.10','-0.08','-0.06','-0.04','-0.02', '0.00','0.02','0.04','0.06','0.08','0.10','0.12','0.14','0.16'});

% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIGURE 2
% contourf(r01-r02)
figure2 = figure;
set(figure2, 'Position', [50 50 1100 950]);

BB=tril(rr00);
contourf(BB);

% axis xy;
set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('r01-r02','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
D = colorbar;
set(get(D,'XLabel'),'String','PLV', 'fontsize',12);
set(D, 'fontsize',11);
% axis xy;
caxis([-0.12 0.12]);
set(D, 'YTick',-0.12:0.02:0.12, 'YTickLabel', {'-0.12','-0.10','-0.08','-0.06','-0.04','-0.02','0','0.02','0.04','0.06','0.08','0.10','0.12'});

% colorbar positioning;
initpos = get(D,'Position');
set(D, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIUGURE 3

% us00-cn00
figure3 = figure;
set(figure3, 'Position', [50 50 1100 950])

CC=tril(uscn);
imagesc(CC);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('us-cn','fontsize', 17);
grid on;

colorbar;
E = colorbar;
set(get(E,'XLabel'),'String','PLV', 'fontsize',12);
set(E, 'fontsize',11);
% axis xy;
% caxis([-0.025 0.025]);
caxis([-0.035 0.035]);
set(E, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});

% colorbar positioning;
initpos = get(E,'Position');
set(E, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);


%% FIUGURE 4

% r01-f02
figure4 = figure;
set(figure4, 'Position', [50 50 1100 950])

DD=tril(rr00);
imagesc(DD);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('r01-r02','fontsize', 17);
grid on;

colorbar;
F = colorbar;
set(get(F,'XLabel'),'String','PLV', 'fontsize',12);
set(F, 'fontsize',11);
% axis xy;
% caxis([-0.025 0.025]);
caxis([-0.035 0.035]);
set(F, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});

% colorbar positioning;
initpos = get(F,'Position');
set(F, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);
