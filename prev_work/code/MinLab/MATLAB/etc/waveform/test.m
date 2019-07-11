clear all; close all;clc

%myFGen = fgen();

%availableResources = getResources(myFGen);

%availableResources = 'usb0::2391::1031::MY44052879::INSTR';

%myFGen.Resource = 'usb0::2391::1031::MY44052879::INSTR';
%%
interfaceObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::2391::1031::MY44052879::INSTR', 'Tag', '');

if isempty(interfaceObj)
    interfaceObj = visa('agilent', 'USB0::2391::1031::MY44052879::INSTR');
else
    fclose(interfaceObj);
   interfaceObj = interfaceObj(1);
end

myFGen = icdevice('agilent_33220a.mdd', interfaceObj);   

%connect(myFGen);

%selectChannel(myFGen, '1');

set(myFGen, 'Waveform', 'sin');

set(myFGen, 'Mode', 'continuous');

set(myFGen, 'OutputImpedance', 50);

set(myFGen, 'Frequency', 2500);

set(myFGen, 'Amplitude', 1.2);

set(myFGen, 'Offset', 0.4);

enableOutput(myFGen);

disableOutput(myFGen);

disconnect(myFGen);
delete myFgen;
clear myFgen;