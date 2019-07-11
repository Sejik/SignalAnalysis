

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Data load
createfigure(X,Y,Z,labels,coh_GWclothes);

A=coh_GWclothes;

for n = 1 : length(A)
    for m = n+1: length(A)-1
            if (-0.12<= A(m,n)) && (A(m,n) <= -0.055) || (0.055<= A(m,n)) && (A(m,n) <= 0.12)  % low
           
            patch([X(m),X(n)],[Y(m),Y(n)],[Z(m),Z(n)],A(m,n)*[1 1],'edgecolor','flat','linewidth',5);
          % patch([X(m),X(n)],[Y(m),Y(n)],[Z(m),Z(n)],rr00(m,n)*[1 1],'edgecolor','flat','linewidth',BB(m.n));
          % 나중에 linewidth에도 함수를 넣을 수 있음: 예를 들어, BB(m,n) <-- 통계 p값
            title ('coh GWclothes','fontsize', 25);
       end
    end
end
 
C = colorbar;
set(get(C,'XLabel'),'String','PLV', 'fontsize',15);
set(C, 'fontsize',12);

%% colorbar positioning;
initpos = get(C,'Position');
set(C, 'Position',[initpos(1) initpos(2)+initpos(4)*0.05 initpos(3) initpos(4)*0.8]);

%% colorbar limits;
caxis([-0.1 0.1]);