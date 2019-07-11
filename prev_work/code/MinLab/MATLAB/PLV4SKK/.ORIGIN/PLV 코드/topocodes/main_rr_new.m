%% Data load
load_data; % location X,Y,Z
% load SKK_coh.mat
% load rr00 
rr00=rr01-rr02;

% max: 0.0397,min: -0.0261

createfigure(X,Y,Z,labels,rr00);

% colorbar;

% 
% for i = 1: length(X)
% %     text(X(i),Y(i),Z(i), num2str(Number(i)), 'FontSize', 12);
%      text(X(i),Y(i),Z(i),labels{i},'FontSize',12);
% end

for n = 1 : length(rr00)
    for m = n+1: length(rr00)-1
        % if ((0.03 <= rr00(m,n)) && (rr00(m,n) <= 0.04))|((-0.025 <= rr00(m,n)) && (rr00(m,n) <= -0.015))
        
            % if (0.03 <= rr00(m,n)) && (rr00(m,n) <= 0.04) % high
            if (-0.025 <= rr00(m,n)) && (rr00(m,n) <= -0.015) % low
            
            patch([X(m),X(n)],[Y(m),Y(n)],[Z(m),Z(n)],rr00(m,n)*[1 1],'edgecolor','flat','linewidth',5);
          % patch([X(m),X(n)],[Y(m),Y(n)],[Z(m),Z(n)],rr00(m,n)*[1 1],'edgecolor','flat','linewidth',BB(m.n));
          % 나중에 linewidth에도 함수를 넣을 수 있음: 예를 들어, BB(m,n) <-- 통계 p값
            title ('rr00-low','fontsize', 25);
       end
    end
end

% colorbar('YTick',-0.03:0.005:-0.015);
 
%  colorbar('YTick',-0.03:0.005:-0.015, 'YTickLabel',...
%     {'-0.03','-0.025',...
%      '-0.02','-0.015'});
 
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',15);
set(C, 'fontsize',12);

%% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1) initpos(2)+initpos(4)*0.05 initpos(3) initpos(4)*0.8]);


%% colorbar limits;
% caxis([0.03 0.04]);
caxis([-1 1]);

%% set YTicks:

% set(C, 'YTick',0.03:0.005:0.04, 'YTickLabel', {'0.030','0.035', '0.040'});
set(C, 'YTick',-0.0225:0.0025:-0.0175, 'YTickLabel', {'-0.0225','-0.0200', '-0.0175'});


