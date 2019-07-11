% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% set variable
RawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\GVS\excel\GVS_Dat\Result';
RegreesionDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\GVS\excel\GVS_Dat\Regression';

subname={'D2', 'linear', 'pitch', 'roll'};
dataname={'1', '2', '3', '4'};
trialname={'1','2', '3', '4'};

%% linear velocity
for subNum= 1:length(subname)
    cd(RawDir);
    for dataNum = 1:length(dataname)
        for trialNum=1:length(trialname)
            eval(['gradient = importdata(''' 'gradient_' char(subname{subNum}) '_' char(dataname{dataNum}) '_' char(trialname{trialNum}) '.mat'');']);
            eval(['velocityMax = importdata(''' 'velocityMax_' char(subname{subNum}) '_' char(dataname{dataNum}) '_' char(trialname{trialNum}) '.mat'');']);
            
            gradientX{dataNum, trialNum} = gradient{1};
            gradientY{dataNum, trialNum} = gradient{2};
            gradientZ{dataNum, trialNum} = gradient{3};
            velocityMaxX{dataNum, trialNum} = velocityMax{1};
            velocityMaxY{dataNum, trialNum} = velocityMax{2};
            velocityMaxZ{dataNum, trialNum} = velocityMax{3};
        end
    end
    
    
    cd(RegreesionDir);
    
    for dataNum = 1:length(dataname)
        for trialNum=1:length(trialname)
            totalGradientX(dataNum, trialNum) = mean(gradientX{dataNum, trialNum}(isfinite(gradientX{dataNum, trialNum})));
            totalGradientY(dataNum, trialNum) = mean(gradientY{dataNum, trialNum}(isfinite(gradientY{dataNum, trialNum})));
            totalGradientZ(dataNum, trialNum) = mean(gradientZ{dataNum, trialNum}(isfinite(gradientZ{dataNum, trialNum})));
            totalVelocityMaxX(dataNum, trialNum) = mean(velocityMaxX{dataNum, trialNum}(isfinite(velocityMaxX{dataNum, trialNum})));
            totalVelocityMaxY(dataNum, trialNum) = mean(velocityMaxY{dataNum, trialNum}(isfinite(velocityMaxY{dataNum, trialNum})));
            totalVelocityMaxZ(dataNum, trialNum) = mean(velocityMaxZ{dataNum, trialNum}(isfinite(velocityMaxZ{dataNum, trialNum})));
        end
    end
    
    current = [0.5 1 1.5 2];
    currentX = mean(totalGradientX,1);
    fcx = fit(current',currentX','power1');
	plot(fcx,current',currentX');
    saveas(gcf, char(strcat(subname(subNum),'_current_gradientX.png')));
    currentY = mean(totalGradientY,1);
    fcy = fit(current',currentY','power1');
	plot(fcy,current',currentY');
    saveas(gcf, char(strcat(subname(subNum),'_current_gradientY.png')));
    currentZ = mean(totalGradientZ,1);
    fcz = fit(current',currentZ','power1');
	plot(fcz,current',currentZ');
    saveas(gcf, char(strcat(subname(subNum),'_current_gradientZ.png')));
    
    time = [0.5; 1; 1.5; 2];
    timeX = mean(totalGradientX,2);
    ftx = fit(time,timeX,'power1');
	plot(ftx,time,timeX);
    saveas(gcf, char(strcat(subname(subNum),'_time_gradientX.png')));
    timeY = mean(totalGradientY,2);
    fty = fit(time,timeY,'power1');
	plot(fty,time,timeY);
    saveas(gcf, char(strcat(subname(subNum),'_time_gradientY.png')));
    timeZ = mean(totalGradientZ,2);
    ftz = fit(time,timeZ,'power1');
	plot(ftz,time,timeZ);
    saveas(gcf, char(strcat(subname(subNum),'_time_gradientZ.png')));
    
    current = [0.5 1 1.5 2];
    currentX = mean(totalVelocityMaxX,1);
    fcx = fit(current',currentX','power1');
	plot(fcx,current',currentX');
    saveas(gcf, char(strcat(subname(subNum),'_current_velocityX.png')));
    currentY = mean(totalVelocityMaxY,1);
    fcy = fit(current',currentY','power1');
	plot(fcy,current',currentY');
    saveas(gcf, char(strcat(subname(subNum),'_current_velocityY.png')));
    currentZ = mean(totalVelocityMaxZ,1);
    fcz = fit(current',currentZ','power1');
	plot(fcz,current',currentZ');
    saveas(gcf, char(strcat(subname(subNum),'_current_velocityZ.png')));
    
    time = [0.5; 1; 1.5; 2];
    timeX = mean(totalVelocityMaxX,2);
    ftx = fit(time,timeX,'power1');
	plot(ftx,time,timeX);
    saveas(gcf, char(strcat(subname(subNum),'_time_velocityX.png')));
    timeY = mean(totalVelocityMaxY,2);
    fty = fit(time,timeY,'power1');
	plot(fty,time,timeY);
    saveas(gcf, char(strcat(subname(subNum),'_time_velocityY.png')));
    timeZ = mean(totalVelocityMaxZ,2);
    ftz = fit(time,timeZ,'power1');
	plot(ftz,time,timeZ);
    saveas(gcf, char(strcat(subname(subNum),'_time_velocityZ.png')));
end