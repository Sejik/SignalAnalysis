function [] = SJ_significantRectangle(spX, spY, epX, epY, lineColor)
z = 10;
p1 = [spX, epY, z];
p2 = [spX, spY, z];
p3 = [epX, spY, z];
p4 = [epX, epY, z];
pts = [p1;p2;p3;p4;p1];
line(pts(:,1), pts(:,2),pts(:,3), 'Color', lineColor, 'LineWidth', 3);
end