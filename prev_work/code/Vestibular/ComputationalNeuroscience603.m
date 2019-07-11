%% A. Semicircular canal mechanics
clear all % initialize program

% I. Define the simulink parameters
fs = 1000; % Sampling Frequency
Ts = 1/fs; % Sampling period
g = 1; % gain
T = 0.015; % time constant, Simulink tutorial and exercise.docx
T1 = 5.7; % Simulink tutorial and exercise.docx
T2 = 0.003; % Simulink tutorial and exercise.docx
fc = 1/(2*pi*T); % the corresponding cutoff frequency

% II. Designing the sine wave input
f1 = 0.5; % fundamental frequency of the first sine wave
f2 = 10; % fundamental frequency of the second sine wave 
f3 = 20; % fundamental frequency of the third sine wave 
L1 = 10/f1; % Simulation length = 10 periods of first frequency
L2 = 10/f1; % Simulation length = 10 periods of second frequency
L3 = 10/f1; % Simulation length = 10 periods of third frequency

% III-1. sequentially simulate canal_daynamics.mdl
f = f1; L = L1; % use (f1, L1) or (f2, L2) or (f3, L3)
t = [1/fs:1/fs:L]'; % Time vector sampled at Ts
input = 10*sin (2*pi*f.*t); % sine wave
sim ('canal_dynamics') % simoutCA, simoutTP

% III-2. Write the equivalent transfer function in Matlab
Ztp = [];
Ptp(1) = [-1/T1];
Ptp(2) = [-1/T2];
Ktp = [1/(T1*T2)];
TP = zpk(Ztp,Ptp,Ktp,'Ts',0); % Torsion pendulum Semicircular Canal dynamics; same as simoutTP
Zca(1) = [0];
Zca(2) = [-1/T];
Pca(1) =[-1/T1];
Pca(2) =[-1/T2];
Kca = [T/(T1*T2)];
CA = zpk(Zca,Pca,Kca,'Ts',0); % Canal afferents; same as simoutCA

% IV. generate the bode & plot
FMIN = 0.01; FRES =.01; FMAX = 100;
fVect = FMIN:FRES:FMAX;
wVect = fVect.*(2*pi);

magTP = zeros(length(fVect),1);
phTP = zeros(length(fVect),1);
wTP = zeros(length(fVect),1);
[magTP(:),phTP(:),wTP(:)] = bode(TP,wVect); % TP bode
figure;
subplot(2,1,1)
loglog(fVect,magTP)
ylabel('Amplitude');title('TP Magnitude Response')
subplot(2,1,2)
semilogx(fVect,phTP)
ylabel('Phase (deg)');title('TP Phase Response')
xlabel('Frequency (deg/sec)')

magCA = zeros(length(fVect),1);
phCA = zeros(length(fVect),1);
wCA = zeros(length(fVect),1);
[magCA(:),phCA(:),wCA(:)] = bode(CA,wVect); % CA bode
figure;
subplot(2,1,1)
loglog(fVect,magCA)
ylabel('Amplitude');title('CA Magnitude Response')
subplot(2,1,2)
semilogx(fVect,phCA)
ylabel('Phase (deg)');title('CA Phase Response')
xlabel('Frequency (deg/sec)')