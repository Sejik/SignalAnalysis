nx=64;
ny=64;
dkx=1/(4*nx);
dky=1/(4*ny);

kx0=-round(nx/2 + 0.5)*dkx;
ky0=-round(ny/2 + 0.5)*dky;

idx=1;
kc=zeros(nx*ny,3);

%% EPI/GE stuff

for ky=0:(ny-1),
  for kx=0:(nx-1),
    if (mod(ky,2)==1),
      kc(idx,1)=(nx-1-kx)*dkx + kx0;   % EPI
%      kc(idx,1)=kx*dkx + kx0;  % standard GE
    else
      kc(idx,1)=kx*dkx + kx0;
    end
    kc(idx,2)=ky*dky + ky0;
    idx=idx+1;
  end
end
kc=kc.';
kepi=kc;

%%return;

%% Spiral EPI stuff

oversamp = 2;  % oversampling factor
kmax=max(nx*dkx/2,ny*dky/2);
nmax=max(nx,ny);
dtheta=2*pi/(2*nmax-1);
dr=kmax/(nx*ny)/oversamp;

kc=zeros(3,oversamp*nx*ny);
n=1:oversamp*(nx*ny);
kc(1,:)=n*dr.*cos(n*dtheta);  
kc(2,:)=n*dr.*sin(n*dtheta);


%%% make a signal to test this with (a box of size lx, ly)
lx = 80;
ly = 100;
sig=sinc(kc(1,:)*lx).*sinc(kc(2,:)*ly);
sig=[sig ; 0*sig];


%% show k-space trajectory of spiral vs standard epi 
plot(kepi(1,:),kepi(2,:),'-x')
hold on
plot(kc(1,:),kc(2,:),'ro-')


