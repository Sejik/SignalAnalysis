t=1/500:1/500:800;
% noisy = randn(1, length(t))-1;

A=sin(6*2*pi*t)+sin(7*2*pi*t);
B=sin(16*2*pi*t)+sin(15*2*pi*t);
C=sin(16*2*pi*t)+sin(17*2*pi*t);
D=sin(6*2*pi*t)+sin(17*2*pi*t);
E=sin(19*2*pi*t)+sin(15*2*pi*t);
F=sin(19*2*pi*t)+sin(7*2*pi*t);

for mm=1:28,
    
AA(mm,:)=A+2*(randn(1, length(t))-1);
BB(mm,:)=B+2*(randn(1, length(t))-1);
CC(mm,:)=C+2*(randn(1, length(t))-1);
DD(mm,:)=D+2*(randn(1, length(t))-1);
EE(mm,:)=E+2*(randn(1, length(t))-1);
FF(mm,:)=F+2*(randn(1, length(t))-1);

end;

% 1	R1C3 (¦¯)	6 Hz	7 Hz
% 2	R3C1 (¦±)	16 Hz	15 Hz
% 3	R3C2 (¦µ)	16 Hz	17 Hz
% 4	R1C2 (¦³)	6 Hz	17 Hz
% 5	R2C1 (¤¿)	19 Hz	15 Hz
% 6	R2C3 (¤Ã)	19 Hz	7 Hz

EEG=[AA BB CC DD EE FF];

% figure(1); plot(t,A,'r');hold on; plot(t,B,'b');plot(t,C,'g');

%%
windowsize=500;
overlapsize=200;
signalsize=length(EEG);
ch=28;

num=floor((signalsize-windowsize)/overlapsize)+1;
wakku=zeros(ch, windowsize, num);

for i=1:num,  
    wakku(:,:,i)=EEG(:,i*200-199:500+200*(i-1));
end;

%reference
tt=1/500:1/500:1;

stimulus.xa(1,:) = sin(2*pi*6*tt);% figure(3);plot (t, stimulus.xa(1,:));
stimulus.xa(2,:) = cos(2*pi*6*tt);
stimulus.xa(3,:) = sin(2*pi*7*tt);
stimulus.xa(4,:) = cos(2*pi*7*tt);

stimulus.xb(1,:) = sin(2*pi*16*tt);
stimulus.xb(2,:) = cos(2*pi*16*tt);
stimulus.xb(3,:) = sin(2*pi*15*tt);
stimulus.xb(4,:) = cos(2*pi*15*tt);

stimulus.xc(1,:) = sin(2*pi*16*tt);
stimulus.xc(2,:) = cos(2*pi*16*tt);
stimulus.xc(3,:) = sin(2*pi*17*tt);
stimulus.xc(4,:) = cos(2*pi*17*tt);

stimulus.xd(1,:) = sin(2*pi*6*tt);
stimulus.xd(2,:) = cos(2*pi*6*tt);
stimulus.xd(3,:) = sin(2*pi*17*tt);
stimulus.xd(4,:) = cos(2*pi*17*tt);

stimulus.xe(1,:) = sin(2*pi*19*tt);
stimulus.xe(2,:) = cos(2*pi*19*tt);
stimulus.xe(3,:) = sin(2*pi*15*tt);
stimulus.xe(4,:) = cos(2*pi*15*tt);

stimulus.xf(1,:) = sin(2*pi*19*tt);
stimulus.xf(2,:) = cos(2*pi*19*tt);
stimulus.xf(3,:) = sin(2*pi*7*tt);
stimulus.xf(4,:) = cos(2*pi*7*tt);

%%

wakku2=shiftdim(wakku,1);
wakku3=permute(wakku2,[1 3 2]);
wakku4=reshape(wakku3, [500 335944]);

num28=28*num;
% 
% %CCA
for k=1:num28,

[ A1, B1, r_classic1(:,k), U1, V1 ] = canoncorr(wakku4(:,k), stimulus.xa(:,:)');
[ A2, B2, r_classic2(:,k), U2, V2 ] = canoncorr(wakku4(:,k), stimulus.xb(:,:)');
[ A3, B3, r_classic3(:,k), U3, V3 ] = canoncorr(wakku4(:,k), stimulus.xc(:,:)');
[ A4, B4, r_classic4(:,k), U4, V4 ] = canoncorr(wakku4(:,k), stimulus.xd(:,:)');
[ A5, B5, r_classic5(:,k), U5, V5 ] = canoncorr(wakku4(:,k), stimulus.xe(:,:)');
[ A6, B6, r_classic6(:,k), U6, V6 ] = canoncorr(wakku4(:,k), stimulus.xf(:,:)');

if k==20*11997||k==21*11997||k==22*11997||k==23*11997,
    if max([r_classic1(:,k) r_classic2(:,k) r_classic3(:,k) r_classic4(:,k) r_classic5(:,k) r_classic6(:,k)])==r_classic1(:,k),
         fprintf('A');
    end;
    
    if max([r_classic1(:,k) r_classic2(:,k) r_classic3(:,k) r_classic4(:,k) r_classic5(:,k) r_classic6(:,k)])==r_classic2(:,k),
         fprintf('B');
    end;
    
    if max([r_classic1(:,k) r_classic2(:,k) r_classic3(:,k) r_classic4(:,k) r_classic5(:,k) r_classic6(:,k)])==r_classic3(:,k),
         fprintf('C');
    end;   
    
     if max([r_classic1(:,k) r_classic2(:,k) r_classic3(:,k) r_classic4(:,k) r_classic5(:,k) r_classic6(:,k)])==r_classic4(:,k),
         fprintf('D');
    end;
    
    if max([r_classic1(:,k) r_classic2(:,k) r_classic3(:,k) r_classic4(:,k) r_classic5(:,k) r_classic6(:,k)])==r_classic5(:,k),
         fprintf('E');
    end;
    
    if max([r_classic1(:,k) r_classic2(:,k) r_classic3(:,k) r_classic4(:,k) r_classic5(:,k) r_classic6(:,k)])==r_classic6(:,k),
         fprintf('F');
    end;   
       
end;

end;
