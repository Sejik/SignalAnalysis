function [ AllCondition ] = S_condComb( lCondition )
%% lCondition에 담긴 각 condition의 모든 경우의 조합을 1D vector로 구성한다.

	%% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
%clearvars -except lCondition;
%close all;

	%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@

	%%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	%% recursive 연산을 개시!
	% Recusivie 에서는 아래의 일을 수행함.
	% 1. 다중 조건의 모든 조합 구성
	% 2. 조합된 각 경우에 대해, indivisual(subject별) 단위 연산 호출
	% 3. 모든 subject에 대한 호출이 완료 후, grand 연산 호출
	AllCondition	=	combi_Recursive(lCondition, length(lCondition), {});
	%%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	return;

%%-------------------------------------------------------------------------------
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%-------------------------------------------------------------------------------
function [ CondCombi ] = combi_Recursive(list, level, tag)
% level: # of condition, ex) == 4 -> call order: 4, 3, 2, 1(leaf)
% tag  : ID array(or string) at each loop, ex) { '4', '3', '2', '1' }

	if level >= 1										% leaf아님: call반복
		CondCombi		=	{};

		Cond			=	list{level};
%		for c = 1 : length(Cond)
%			tag{level}	=	Cond{c};					% 한 단계 하부로
		for c = Cond									% == foreach
			tag{level}	=	c{1};						% 한 단계 하부로
			CondCombi{end+1}	=	combi_Recursive(list, level-1, tag);
		end

		% recursive return 으로 인해, 리턴값이 nested cell 구조화 되기 때문에
		% 리턴되기 전에 flatten 해야만, root까지 단일 cell 구조가 유지
		CondCombi		=	table2array(cell2table(CondCombi));	% cell flat

	else												% level == 0
		%% leaf 도착: 이제부터는 실제 processing을 수행한다.
		CondCombi		=	strjoin(tag, '');			% 단일 문자열로!

	end

	return;

%%-------------------------------------------------------------------------------
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%-------------------------------------------------------------------------------
