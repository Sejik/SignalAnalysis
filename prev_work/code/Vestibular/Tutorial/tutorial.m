clear all

fs = 1000; % Sampling Frequency
Ts = 1/fs; % Sampling period

% Define the simulink parameters
g = 1; % gain
T= 0.016; % time constant;

% Write the equivalent transfer function in Matlab to generate the bode
% plots.
Z = [];
P =[-1/T];
K = [g/T];
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







