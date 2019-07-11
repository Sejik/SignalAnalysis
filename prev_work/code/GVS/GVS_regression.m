% 전류: 1.5mA
% 시간: 0.5 2.0 0.5
% StartPoint, EndPoint, MaxRotationx1

current = 1.5;
risingTime = 0;
mainTime = 0.5;
fallingTime = 2.5;

StartPoint(1) = 0;
EndPoint(1) = 0;

for TimeLength = 2:length(TimeStemp)
    if (Rotationx(TimeLength) < 0) && (Rotationx(TimeLength-1) == 0)
        StartPoint(length(StartPoint)+1) = TimeLength;
    end
    if (Rotationx(TimeLength) == 0) && (Rotationx(TimeLength-1) < 0)
        EndPoint(length(EndPoint)+1) = TimeLength;
    end
end

MaxRotationx(1) = 0;
for findMax = 2:length(StartPoint)
    MaxRotationx(findMax) = 0;
    for maxNum = StartPoint(findMax):EndPoint(findMax)
        if MaxRotationx(findMax) > Rotationx(maxNum)
            MaxRotationx(findMax) = Rotationx(maxNum);
        end
    end
end


UpDown.current = current;
UpDown.risingTime = risingTime;
UpDown.mainTime = mainTime;
UpDown.fallingTime = fallingTime;
UpDown.StartPoint = StartPoint;
UpDown.EndPoint = EndPoint;
UpDown.Max = MaxRotationx;
% 가장 큰 자극을 얻는 것인가?

%fit
%f = fit (Cdate, pop, 'poly2);
%[curve2, gof2] = fit(cdate,pop, ft, 'problem',2)
%f=fit(cdate,pop,'poly3','Normalize','on','Robust','Bisquare')
%plot(f, cdate, pop)

