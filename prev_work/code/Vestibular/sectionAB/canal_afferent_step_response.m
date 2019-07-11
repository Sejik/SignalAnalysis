clear all

fs = 1000;
Ts = 1/fs;


% I. Define the Canal afferent paramters
g = 1; % gain
T1 = 5.7;% canals long time constant
T2 = 0.003;% canals short time constant
T = 0.015; % zero time constant


f = 0.5; % 여기 input을 0.5, 10, 20으로 하라고 합니다.

L = 100;
t = [1/fs:1/fs:L]';

% input = 10*sin (2*pi*f*t);

sim ('afferent_step_response',[Ts L]);
sim ('canal_dynamics');

figure, hold all, plot(t,input),plot(t,simout), title ('Canal Afferent Step Response')
legend ('input','output'),xlabel ('Time (sec)'), ylabel ('amplitude (deg/s)')

% Write the equivalent transfer function in Matlab to generate the bode
% plots.
Z = [];
P =[-1/T];
K = [g/T];
Ts = simoutTP;
LP = zpk(Z,P,K,'Ts',0);

% Use "bode" to plot the bode plots.
FMIN = 0.01; FRES =.01; FMAX = 100;
fVect = FMIN:FRES:FMAX;
wVect = fVect.*(2*pi);
mag = zeros(length(fVect),1);
ph = zeros(length(fVect),1);
w = zeros(length(fVect),1);
[mag(:),ph(:),w(:)] = bode(LP,wVect); 
figure;
subplot(2,1,1)
loglog(fVect,mag)
ylabel('Amplitude');title('Magnitude Response')
subplot(2,1,2)
semilogx(fVect,ph)
ylabel('Phase (deg)');title('Phase Response')
xlabel('Frequency (deg/sec)')
