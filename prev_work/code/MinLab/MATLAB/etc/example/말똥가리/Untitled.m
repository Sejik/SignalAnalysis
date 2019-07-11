%% Example application to generate an arbitrary waveform and download it to an Agilent Arbitrary Waveform Generator.
% Generate the arbitrary waveform in MATLAB
time = 0:0.001:1;  % De? ne time vector to contain whole number of cycles of waveform
Amp1 = 0.2;                                          % Amplitude for each component of waveform
Amp2 = 0.8;
Amp3 = 0.6;
frequency1 = 10;                                     % Frequency for each component of waveform
frequency2 = 14;                            
frequency3 = 18;                            
wave1 = Amp1*sin(2*pi*frequency1*time); % Waveform component 1
wave2 = Amp2*sin(2*pi*frequency2*time); % Waveform component 2
wave3 = Amp3*sin(2*pi*frequency3*time); % Waveform component 3
wave = wave1 + wave2 + wave3; % Some combination of individual waveforms
wave = wave + 0.3*rand(1,size(wave,2)); % Now add random noise into the signal
wave = (wave./max(wave))'; % Normalize so values are between -1 to + 1
% Visualize the signals 
plot(time,wave1,'m',time,wave2,'k',time,wave3,'r');
hold on; hw = plot(time,wave,'b'); set(hw,'Linewidth',2.5)
xlabel('Time (s)'); ylabel('Voltage (V)'); axis tight; 
legend('Component 1','Component 2','Component 3', 'Combination of components \newline with random noise')

% Connect to the Agilent 33220. Using the IVI driver, load the arbitrary waveform and enable it.
device = icdevice('Agilent33220.mdd','usb0::2391::1031::MY44052879::INSTR');
connect(device);
invoke(device.Arbitrarywaveform,'SetData',wave);
invoke(device.Arbitrarywaveform,'CopyData','MATLABWFM1');
set(device.Arbitrarywaveform,'User','MATLABWFM1');
set(device.Output, 'Function', 'Agilent33220OutputFunctionUser');
set(device.Output, 'Frequency', 1);
set(device.OutputVoltage, 'Amplitude', 10);
set(device.Output,'State','on')