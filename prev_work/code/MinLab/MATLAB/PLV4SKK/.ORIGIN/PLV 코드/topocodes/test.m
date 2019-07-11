
%% FIGURE [for rr00 =rr01-rr02]
figure1 = figure;
set(figure1, 'Position', [50 50 1100 950]);

AA=tril(rr00);
contourf(AA);

set(gca,'XTick',[1:30],'fontsize',10);
set(gca,'XTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
set(gca,'YTick',[1:30], 'fontsize',10);
set(gca,'YTickLabel',{'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1', 'FC2', 'FC6','T7','C3','Cz','C4','T8','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2', 'PO10'});
title('r01-r02','fontsize', 17);
set(gca,'YDir','reverse');
grid on;

colorbar;
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',12);
set(C, 'fontsize',11);
% axis xy;

caxis([-0.1 0.1]);
% set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
set(C, 'YTick',-0.1:0.02:0.1, 'YTickLabel', {'-0.10','-0.08','-0.06','-0.04','-0.02', '0.00','0.02','0.04','0.06','0.08','0.10'});
% 
% caxis([-0.24 0.24]);
% % set(C, 'YTick',-0.035:0.005:0.035, 'YTickLabel', {'-0.035','-0.030','-0.025','-0.020','-0.015','-0.010','-0.005','0','0.005','0.010','0.015','0.020','0.025','0.030','0.035'});
% set(C, 'YTick',-0.24:0.02:0.24, 'YTickLabel', {'-0.24','-0.22','-0.20','-0.18','-0.16','-0.14','-0.12','-0.10','-0.08','-0.06','-0.04','-0.02', '0.00','0.02','0.04','0.06','0.08','0.10','0.12','0.14','0.16','0.18','0.20','0.22','0.24'});



% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1)+initpos(3)*3 initpos(2) initpos(3) initpos(4)]);
