stimulus_a=[1/500:1/500:6250/500];
s1=length(stimulus_a);
stimulus_t=ones(s1,32);
for i=1:32
stimulus_t(:,i)=stimulus_a;
end;
data=kEEG;

%reference
stimulus.xa(1,:) = sin(2*pi*6*stimulus_t);
stimulus.xa(2,:) = cos(2*pi*6*stimulus_t);

stimulus.xb(1,:) = sin(2*pi*7*stimulus_t);
stimulus.xb(2,:) = cos(2*pi*7*stimulus_t);

stimulus.xc(1,:) = sin(2*pi*15*stimulus_t);
stimulus.xc(2,:) = cos(2*pi*15*stimulus_t);

stimulus.xd(1,:) = sin(2*pi*16*stimulus_t);
stimulus.xd(2,:) = cos(2*pi*16*stimulus_t);

stimulus.xe(1,:) = sin(2*pi*17*stimulus_t);
stimulus.xe(2,:) = cos(2*pi*17*stimulus_t);

stimulus.xf(1,:) = sin(2*pi*19*stimulus_t);
stimulus.xf(2,:) = cos(2*pi*19*stimulus_t);


%CCA
[ A, B, r_classic(class,:), U, V ] = canoncorr(data, stimulus.xa(1,:));
% [ A2, B2, r_classic2(class,:), U2, V2 ] = canoncorr(data, stimulus.x2);
% [ A3, B3, r_classic3(class,:), U3, V3 ] = canoncorr(data, stimulus.x3);
% [ A4, B4, r_classic4(class,:), U4, V4 ] = canoncorr(data, stimulus.x4);
% [ A5, B5, r_classic5(class,:), U5, V5 ] = canoncorr(data, stimulus.x5);
% [ A6, B6, r_classic6(class,:), U6, V6 ] = canoncorr(data, stimulus.x6);