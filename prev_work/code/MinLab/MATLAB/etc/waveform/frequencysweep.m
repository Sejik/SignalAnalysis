clc;clear;close;

%FREQUENCYSWEEPTEK M-Code for communicating with an instrument. 
%  
%   This is the machine generated representation of an instrument control 
%   session using a device object. The instrument control session comprises  
%   all the steps you are likely to take when communicating with your  
%   instrument. These steps are:
%       
%       1. Create a device object   
%       2. Connect to the instrument 
%       3. Configure properties 
%       4. Invoke functions 
%       5. Disconnect from the instrument 
%  
%   To run the instrument control session, type the name of the M-file,
%   frequencysweepTek, at the MATLAB command prompt.
% 
%   The M-file, FREQUENCYSWEEPTEK.M must be on your MATLAB PATH. For additional information
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
%   prompt.
%
%   Example:
%       frequencysweepTek;
%
%   See also ICDEVICE.
%

%   Creation time: 09-Mar-2009 15:28:00 


% Create a VISA-USB object.
interfaceObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::2391::1031::MY44052879::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(interfaceObj)
    interfaceObj = visa('agilent', 'USB0::2391::1031::MY44052879::INSTR');
else
    fclose(interfaceObj);
    interfaceObj = interfaceObj(1);
end

% Create a device object. 
deviceObj = icdevice('agilent_33220a.mdd', interfaceObj);

% Connect device object to hardware.
connect(deviceObj);

time = 0:0.001:1; % Defi ne time vector to contain whole
%number of cycles of waveform
Amp1 = 0.2; % Amplitude for each component of waveform
Amp2 = 0.8;
Amp3 = 0.6;
frequency1 = 10; % Frequency for each component of waveform
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
legend('Component 1','Component 2','Component 3', ...
'Combination of components \newline with random noise')

% Configure property value(s).
invoke(deviceObj.Arbitrarywaveform,'SetData',wave);
invoke(deviceObj.Arbitrarywaveform,'CopyData','MATLABWFM1');
set(deviceObj.Output, 'Function','Agilent33220OutputFunctionUser');
set(deviceObj.Output, 'Frequency', 1);
set(deviceObj.OutputVoltage, 'Amplitude', 10);
set(deviceObj.Output,'State','on')

% Disconnect device object from hardware.
disconnect(deviceObj);

% Delete objects.
delete([deviceObj interfaceObj]);