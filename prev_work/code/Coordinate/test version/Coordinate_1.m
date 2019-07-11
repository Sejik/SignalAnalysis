%% Coordinate
% designed by sejik Park
% sejik6307@gmail.com

clear all;
clc;

%% Parameter (activation change)
left_excitation = 2;
right_excitation = 1;
sphere_radius = 0.2;

%% Parameter (basic)
O = [0 0 0]; % Zero point
LA = [-0.58930 0.78839 0.17655]; % Left anterior canal plane: -0.58930X +0.78839Y +0.17655Z
LH = [-0.322 -0.03837 0.94573]; % Left horizontal canal: -0.322X -0.03837Y +0.94573Z
LP = [-0.69432 -0.66693 -0.27042]; % Left posterior canal: -0.69432X -0.66693Y -0.27042Z
RA = [0.58930 0.78839 -0.17655]; % Right anterior canal: 0.58930X +0.78839Y -0.17655Z
RH = [0.322 -0.03837 -0.94573]; % Right horizontal canal : 0.322X -0.03837Y -0.94573Z
RP = [0.69432 -0.66693 0.27042]; % Right posterior canal: 0.69432X -0.66693X +0.27042Y

%% canal vector
figure;
hold on;
grid on;
view(3);
% Left canal = blue
arrow3(O, LA, 'b');
arrow3(O, LH, 'b');
arrow3(O, LP, 'b');
% Right canal = red
arrow3(O, RA, 'r');
arrow3(O, RH, 'r');
arrow3(O, RP, 'r');
% label
text(LA(1),LA(2),LA(3),'LA','fontsize', 8)
text(LH(1),LH(2),LH(3),'LH','fontsize', 8)
text(LP(1),LP(2),LP(3),'LP','fontsize', 8)
text(RA(1),RA(2),RA(3),'RA','fontsize', 8)
text(RH(1),RH(2),RH(3),'RH','fontsize', 8)
text(RP(1),RP(2),RP(3),'RP','fontsize', 8)

%% activation vector
L = left_excitation * (LA + LH + LP);
R = right_excitation * (RA + RH + RP);
T = L + R;
arrow3(O, L, '1.5b', 10, 10);
arrow3(O, R, '1.5r', 10, 10);
arrow3(O, T, '3g', 10, 10);
text(L(1)*1.1,L(2)*1.1,L(3)*1.1,'L','fontsize', 10, 'fontweight', 'bold','color','b');
text(R(1)*1.1,R(2)*1.1,R(3)*1.1,'R','fontsize', 10, 'fontweight', 'bold','color','r');
text(T(1)*1.1,T(2)*1.1,T(3)*1.1,'T','fontsize', 10, 'fontweight', 'bold','color','g');


%% sphere & grid
% sphere
[x,y,z] = sphere;
r = sphere_radius;
x  = r*x; y = r*y; z = r*z;
mesh(x,y,z);
% axis
temp = [LA; LH; LP; RA; RH; RP; L; R; T];
axis_length = max(max(abs(temp)));
axis([-axis_length, axis_length, -axis_length, axis_length, -axis_length, axis_length]);
% label
arrow3([0 0 -axis_length], [0 0 axis_length], 'k', 0, 0);
arrow3([0 -axis_length 0], [0 axis_length 0], 'k', 0, 0);
arrow3([-axis_length 0 0], [axis_length 0 0], 'k', 0, 0);
text(0*1.05, 0*1.05, axis_length*1.05,'z','fontsize', 10, 'fontweight', 'bold','color','k')
text(0*1.05, axis_length*1.05, 0*1.05,'y','fontsize', 10, 'fontweight', 'bold','color','k')
text(axis_length*1.05, 0*1.05, 0*1.05,'x','fontsize', 10, 'fontweight', 'bold','color','k')