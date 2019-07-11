function plotcoh_jh(loc_file,cmat,thr,cmap) % 머리 그림 모자이크 그림 그리기, mathworks에서 만들어준것

if nargin<3,
    thr=[];
end;
if nargin<4, cmap=jet(4); end;
if isempty(thr), thr=min(cmat(:))-1; end;


mn=min(cmat(:));
mx=max(cmat(:));
c=cmat(:);                                      % Set colormap
minmax=[min(c) max(c)];
yy=linspace(minmax(1),minmax(2),size(cmap,1));  % Generate range of color indices that map to cmap
cm = spline(yy,cmap',c');                       % Find interpolated colorvalue
cm(cm>1)=1;                                     % Sometimes iterpolation gives values that are out of [0,1] range...
cm(cm<0)=0;
col=cm;     
col=reshape(col,[3 size(cmat)]);      
maxlab=size(cmat,1);

hold on;

%%%
%[tmpeloc labels Th Rd indices] = readlocs( loc_file,'filetype','ced');
[tmpeloc labels Th Rd indices] = readlocs(loc_file);

Th = pi/180*Th;    
squeezefac = 0.85; %rmax/plotrad;
[x,y]     = pol2cart(Th,Rd); 

x    = x*squeezefac;    
y    = y*squeezefac;   
ELECTRODE_HEIGHT=2.1;
EMARKER='.'; ECOLOR=[0 0 0];EMARKERSIZE=20;EMARKERLINEWIDTH=1;
%%%

for ii=1:maxlab,
    for jj=ii+1:maxlab,
        if cmat(ii,jj)<thr, continue; end;
        w=cmat(ii,jj)/cmat(ii,jj)*2.5;        %준혁: line의 굵기조절 (2.5로 통일함)
        wc=squeeze(col(:,ii,jj));
        if w<=0, w=0.1; end;
        hi=line([y(ii) y(jj)],[x(ii) x(jj)],[ELECTRODE_HEIGHT ELECTRODE_HEIGHT]);
        set(hi,'LineWidth',w,'color',wc);
    end;
end;

hp2 = plot3(y,x,ones(size(x))*ELECTRODE_HEIGHT,...
        EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);

hold off;

% r = corrcoef
% CA=zeros(32);
%  
% for ii=1:i(end)
% jj=j(ii);
% CA(ii,jj)=r(ii,jj); 
% end;
% plotcoh_min('EEG_32chan.ced', CA, 0.01)
