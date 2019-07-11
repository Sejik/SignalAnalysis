% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% set variable
rawDir = 'C:\Users\user\Desktop\data'; % where the folders of data

%% initialize (read file name)
cd(rawDir);
conditions = dir(); % get conditions by folder name
for conditionNum = 3:length(conditions) % 1: ".", 2: ".."
    cd(conditions(conditionNum).name);
    file = dir('*.csv');
    figure
    hold on;
    for fileNum = 1:length(file)
        data = importdata(file(fileNum).name);
        timeStempNum = 0;
        rotationXNum = 0;
        rotationYNum = 0;
        rotationZNum = 0;
        nameChecker = 1;
        columnInfo= char(data.textdata(1));
        if strcmp(columnInfo,'TimeStemp') == 0
            columnInfo = strsplit(columnInfo, ',');
        else
            columnInfo = data.textdata;
        end
        for nameCheckNum = 1:length(columnInfo)
            if strcmp(columnInfo(nameCheckNum), 'TimeStemp')
                timeStempNum = nameCheckNum;
            end
            if nameChecker
                if strcmp(columnInfo(nameCheckNum), 'Rotation(x)')
                    rotationXNum = nameCheckNum;
                end
                if strcmp(columnInfo(nameCheckNum), 'Rotation(y)')
                    rotationYNum = nameCheckNum;
                end
                if strcmp(columnInfo(nameCheckNum), 'Rotation(z)')
                    rotationZNum = nameCheckNum;
                end
            end
            if strcmp(columnInfo(nameCheckNum), '__Rotation(x)')
               rotationXNum = nameCheckNum;
               nameChecker = 0;
            end
            if strcmp(columnInfo(nameCheckNum), '__Rotation(y)')
               rotationYNum = nameCheckNum;
               nameChecker = 0;
            end
            if strcmp(columnInfo(nameCheckNum), '__Rotation(z)')
               rotationZNum = nameCheckNum;
               nameChecker = 0;
            end
        end
        timeStemp = data.data(1:end, timeStempNum); % 1: TimeStemp
        rotation_x = data.data(1:end, rotationXNum) - 360; % 8: Rotation(x)
        rotation_y = data.data(1:end, rotationYNum) - 360; % 9: Rotation(y)
        rotation_z = data.data(1:end, rotationZNum) - 360; % 10: Rotation(z)
        for dataCheckNum = 1:length(rotation_x)
            if rotation_x(dataCheckNum) < - 180
                rotation_x(dataCheckNum) = rotation_x(dataCheckNum) +360;
            end
        end
        for dataCheckNum = 1:length(rotation_y)
            if rotation_y(dataCheckNum) < - 180
                rotation_y(dataCheckNum) = rotation_y(dataCheckNum) +360;
            end
        end
        for dataCheckNum = 1:length(rotation_z)
            if rotation_z(dataCheckNum) < - 180
                rotation_z(dataCheckNum) = rotation_z(dataCheckNum) +360;
            end
        end
        rotation_x = rotation_x - rotation_x(1);
        rotation_y = rotation_y - rotation_y(1);
        rotation_z = rotation_z - rotation_z(1);
        if fileNum == 1
            average_x = rotation_x;
            average_y = rotation_y;
            average_z = rotation_z;
        else
            if length(average_x) > length(rotation_x)
                average_x = average_x(1:length(rotation_x))+ rotation_x;
                average_y = average_y(1:length(rotation_y)) + rotation_y;
                average_z = average_z(1:length(rotation_z)) + rotation_z;
            else
                average_x = average_x + rotation_x(1:length(average_x));
                average_y = average_y + rotation_y(1:length(average_y));
                average_z = average_z + rotation_z(1:length(average_z));
            end
        end
        plot (timeStemp, rotation_x, 'r-');
        plot (timeStemp, rotation_y, 'b-');
        plot (timeStemp, rotation_z, 'g-');
    end
    average_x = average_x / fileNum;
    average_y = average_y / fileNum;
    average_z = average_z / fileNum;
    if length(timeStemp) > length(average_x)
        plot (timeStemp(1:length(average_x)), average_x, 'r-', 'LineWidth', 3);
        plot (timeStemp(1:length(average_y)), average_y, 'b-', 'LineWidth', 3);
        plot (timeStemp(1:length(average_z)), average_z, 'g-', 'LineWidth', 3);
    else
        plot (timeStemp, average_x(1:length(timeStemp)), 'r-', 'LineWidth', 3);
        plot (timeStemp, average_y(1:length(timeStemp)), 'b-', 'LineWidth', 3);
        plot (timeStemp, average_z(1:length(timeStemp)), 'g-', 'LineWidth', 3);
    end
    xName = strcat(conditions(conditionNum).name, ' Rotation(x)');
    yName = strcat(conditions(conditionNum).name, ' Rotation(y)');
    zName = strcat(conditions(conditionNum).name, ' Rotation(z)');
    legend(xName, yName, zName);
    
    cd(rawDir);
    fname = sprintf(strcat(conditions(conditionNum).name, 'png'));
    saveas(gcf, fname, 'png');
end