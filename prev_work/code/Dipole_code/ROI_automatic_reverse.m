%% Econnectome ROI automatic reverse

model.cortex = load('colincortex.mat');
XI = model.cortex.colincortex.Vertices;

for num1 = 1:size(sourcedata,2)
    [M1,I1] = max(abs(sourcedata{1})');
    [M2,I2] = min((sourcedata{1})');
    
    maxAbsAmplitude{num1} = XI(I1,:);
    maxMinusAmplitude{num1} = XI(I2,:);
end

cd('C:\Users\win\Desktop\MNIdata');
save('GRD_22_Filters_CNV_22_64', 'maxAbsAmplitude', 'maxMinusAmplitude');

clear;
clc;