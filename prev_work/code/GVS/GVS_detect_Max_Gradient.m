% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% set variable
RawDir = 'C:\Users\win\Desktop\GVS_Dat';
resultDir = 'C:\Users\win\Desktop\GVS_Dat\Result';

subname={'D2', 'linear', 'pitch', 'roll'};
dataname={'1', '2', '3', '4'};
trialname={'1','2', '3', '4'};

%% linear velocity
for subNum= 1:length(subname)
    cd(RawDir);
    cd(char(subname(subNum)));
    for dataNum = 1:length(dataname)
        for trialNum=1:length(trialname)
            eval(['rawdata = importdata(''' char(subname{subNum}) '_' char(dataname{dataNum}) '_' char(trialname{trialNum}) '.csv'');']);
            rawdata = abs(rawdata.data);
            
            velocityMax{1}(1) = 0; % X
            velocityMax{2}(1) = 0; % Y
            velocityMax{3}(1) = 0; % Z
            gradient{1}(1) = 0; % X
            gradient{2}(1) = 0; % Y
            gradient{3}(1) = 0; % Z
            
            if strcmp(subname(subNum),'D2') || strcmp(subname(subNum),'linear')
                % linear velocity
                velocity{1} = rawdata(1:end, 2); % X
                velocity{2} = rawdata(1:end, 3); % Y
                velocity{3} = rawdata(1:end, 4); % Z
                
                for velocityNum = 1:length(velocity)
                    StartPoint(1) = 0;
                    EndPoint(1) = 0;
                    
                    for timeNum = 2:length(velocity{velocityNum})
                        if ((velocity{velocityNum}(timeNum) > 0) && (velocity{velocityNum}(timeNum-1) == 0))
                            StartPoint(length(StartPoint)+1) = timeNum;
                        end
                        if ((velocity{velocityNum}(timeNum) == 0) && (velocity{velocityNum}(timeNum-1) > 0))
                            EndPoint(length(EndPoint)+1) = timeNum;
                        end
                    end
                    
                    for sectionNum = 2:length(StartPoint)
                        velocityMax{1}(sectionNum) = 0; % X
                        velocityMax{2}(sectionNum) = 0; % Y
                        velocityMax{3}(sectionNum) = 0; % Z
                        gradient{1}(sectionNum) = 0; % X
                        gradient{2}(sectionNum) = 0; % Y
                        gradient{3}(sectionNum) = 0; % Z
                        if sectionNum <= length(EndPoint)
                            for sectionTimeNum = StartPoint(sectionNum):EndPoint(sectionNum)
                                if velocityMax{velocityNum}(sectionNum) < velocity{velocityNum}(sectionTimeNum)
                                    velocityMax{velocityNum}(sectionNum) = velocity{velocityNum}(sectionTimeNum);
                                    gradient{velocityNum}(sectionNum) = velocity{velocityNum}(sectionTimeNum) / (sectionTimeNum-StartPoint(sectionNum));
                                end
                            end
                        end
                    end
                    
                    clear StartPoint EndPoint;
                end
            else
                % angular velocity
                velocity{1} = rawdata(1:end, 5); % X
                velocity{2} = rawdata(1:end, 6); % Y
                velocity{3} = rawdata(1:end, 7); % Z
                
                for velocityNum = 1:length(velocity)
                    StartPoint(1) = 0;
                    EndPoint(1) = 0;
                    
                    for timeNum = 2:length(velocity{velocityNum})
                        if ((velocity{velocityNum}(timeNum) > 0.2) && (velocity{velocityNum}(timeNum-1) < 0.2))
                            StartPoint(length(StartPoint)+1) = timeNum;
                        end
                        if ((velocity{velocityNum}(timeNum) < 0.2) && (velocity{velocityNum}(timeNum-1) > 0.2))
                            EndPoint(length(EndPoint)+1) = timeNum;
                        end
                    end
                    
                    for sectionNum = 2:length(StartPoint)
                        velocityMax{1}(sectionNum) = 0; % X
                        velocityMax{2}(sectionNum) = 0; % Y
                        velocityMax{3}(sectionNum) = 0; % Z
                        gradient{1}(sectionNum) = 0; % X
                        gradient{2}(sectionNum) = 0; % Y
                        gradient{3}(sectionNum) = 0; % Z
                        if sectionNum <= length(EndPoint)
                            for sectionTimeNum = StartPoint(sectionNum):EndPoint(sectionNum)
                                if velocityMax{velocityNum}(sectionNum) < velocity{velocityNum}(sectionTimeNum)
                                    velocityMax{velocityNum}(sectionNum) = velocity{velocityNum}(sectionTimeNum);
                                    gradient{velocityNum}(sectionNum) = velocity{velocityNum}(sectionTimeNum) / (sectionTimeNum-StartPoint(sectionNum));
                                end
                            end
                        end
                    end
                    
                    clear StartPoint EndPoint;
                end
            end
            
            % resultNum = subNum+dataNum+trialNum-2;
            result{subNum}{dataNum}{trialNum}{1} = subname(subNum);
            result{subNum}{dataNum}{trialNum}{2} = dataname(dataNum);
            result{subNum}{dataNum}{trialNum}{3} = trialname(trialNum);
            result{subNum}{dataNum}{trialNum}{4} = velocityMax;
            result{subNum}{dataNum}{trialNum}{5} = gradient;
            
            clear velocityMax gradient;
        end
    end
end

%% Save
cd(resultDir);
save('GVS_result.mat', 'result');