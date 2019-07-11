%% Coordinate
% designed by sejik Park
% sejik6307@gmail.com

clear all;
clc;
clf;

%% Plot plane
O = [0 0 0];
L = [-1 -1 0];
R = [1 1 0];
LA = [-0.58930 0.78839 0.17655]; % Left Anterior canal plane: -0.58930X+0.78839Y+ 0.17655Z
LH = [-0.322 -0.03837 0.94573]; % Left Horizontal canal: -0.322X-0.03837Y+0.94573Z
LP = [-0.69432 -0.66693 -0.27042]; % Left Posterior canal: -0.69432X-0.66693Y-0.27042Z
RA = [0.58930 0.78839 -0.17655]; % Right anterior canal: 0.58930X+0.78839Y- 0.17655Z
RH = [0.322 -0.03837 -0.94573]; % Right horizontal canal : 0.322X-0.03837Y-0.94573Z
RP = [0.69432 -0.66693 0.27042]; % Right posterior canal: 0.69432X-0.66693X+0.27042Y
%% 
figure;
hold on;
grid on;
view(3);
arrow3(O, LA);
arrow3(O, LH);
arrow3(O, LP);
arrow3(O, RA);
arrow3(O, RH);
arrow3(O, RP);
xlabel('X axis: forsional SPV: CW <-> CCW');
ylabel('Y axis: vertical SPV: up <-> down');
zlabel('Z axis: horizontal SPV: right <-> left');
[x,y,z] = sphere;
r = 0.2;
x  = r*x; y = r*y; z = r*z;
mesh(x,y,z);
axis([-1, 1, -1, 1, -1, 1]);

%%
figure;
hold on;
grid on;
view(3);
arrow3(L, L + LA);
arrow3(L, L + LH);
arrow3(L, L + LP);
arrow3(R, R + RA);
arrow3(R, R + RH);
arrow3(R, R + RP);
xlabel('X axis: forsional SPV: CW <-> CCW');
ylabel('Y axis: vertical SPV: up <-> down');
zlabel('Z axis: horizontal SPV: right <-> left');
[x1,y1,z1] = sphere;
r = 0.2;
x1  = r*x1 + L(1); y1 = r*y1 + L(2); z1 = r*z1 + L(3);
mesh(x1,y1,z1);
[x2,y2,z2] = sphere;
x2  = r*x2 + R(1); y2 = r*y2 + R(2); z2 = r*z2 + R(3);
mesh(x2,y2,z2);
axis([-2, 2, -2, 2, -2, 2]);
