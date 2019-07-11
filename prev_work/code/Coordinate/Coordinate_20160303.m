%% Coordinate
% designed by sejik Park
% sejik6307@gmail.com

clear all;
clc;
% 표에다가 GUI 넣기
% 
%% Parameter (activation change: 1 is basic)
LA_excitation = 1;
LH_excitation = 1;
LP_excitation = 1;
RA_excitation = 1;
RH_excitation = 1;
RP_excitation = 1;

left_excitation = 1;
right_excitation = 1;
sphere_radius = 0;
plane_on = 0; % 0 is off, 1 is on

right_excitation = -1 * right_excitation; % 이 것 없애고, RA RH RP 수정 (이 그대로인 코드 와 다른 흥분 하는 방향으로 통일한 코드 작성할 것, 오른쪽을 수정)
% pitch roll 구현 가능, 
%% Parameter (basic)
O = [0 0 0]; % Zero point
LA = [-0.58930 +0.78839 -0.17655]; % Left anterior canal plane: -0.58930X +0.78839Y -0.17655Z
LH = [-0.32269 -0.03837 +0.94573]; % Left horizontal canal: -0.32269X -0.03837Y +0.94573Z
LP = [-0.69432 -0.66693 -0.27042]; % Left posterior canal: -0.69432X -0.66693Y -0.27042Z
RA = [-0.58930 -0.78839 -0.17655]; % Right anterior canal: -0.58930X -0.78839Y -0.17655Z
RH = [-0.32269 +0.03837 +0.94573]; % Right horizontal canal : -0.32269X +0.03837Y -0.94573Z
RP = [-0.69432 +0.66693 -0.27042]; % Right posterior canal: -0.69432X +0.66693Y -0.27042Z

figure;
hold on;
grid on;
view(3);
% Left canal = blue
arrow3(O, LA, 'b--');
arrow3(O, LH, 'b--');
arrow3(O, LP, 'b--');
% Right canal = red
arrow3(O, RA, 'r--');
arrow3(O, RH, 'r--');
arrow3(O, RP, 'r--');

%% canal vector
LA = LA_excitation * LA;
LH = LH_excitation * LH;
LP = LP_excitation * LP;
RA = RA_excitation * RA;
RH = RH_excitation * RH;
RP = RP_excitation * RP;
% Left canal = blue
if sum(ne(LA,O))
    arrow3(O, LA, 'b');    
end
if sum(ne(LH,O))
    arrow3(O, LH, 'b');
end
if sum(ne(LP,O))
    arrow3(O, LP, 'b');
end
% Right canal = red
if sum(ne(RA,O))
    arrow3(O, RA, 'r');
end
if sum(ne(RH,O))
    arrow3(O, RH, 'r');
end
if sum(ne(RP,O))
    arrow3(O, RP, 'r');
end
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
if sum(ne(L,O))
    arrow3(O, L, '1.5b', 10, 10);    
end
if sum(ne(R,O))
    arrow3(O, R, '1.5r', 10, 10);    
end
if sum(ne(T,O))
    arrow3(O, T, '3g', 10, 10);
end
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

% can plane
if plane_on
    points=[1000*O' 1000*L' 1000*R'];
    fill3(points(1,:), points(2,:), points(3,:), 'y');
    points=[-1000*O' -1000*L' -1000*R'];
    fill3(points(1,:), points(2,:), points(3,:), 'y');  
end

arrow3(O, [0 1 0]);
