function [ AllCondition ] = S_condComb( lCondition )
%% lCondition�� ��� �� condition�� ��� ����� ������ 1D vector�� �����Ѵ�.

	%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
%clearvars -except lCondition;
%close all;

	%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@

	%%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	%% recursive ������ ����!
	% Recusivie ������ �Ʒ��� ���� ������.
	% 1. ���� ������ ��� ���� ����
	% 2. ���յ� �� ��쿡 ����, indivisual(subject��) ���� ���� ȣ��
	% 3. ��� subject�� ���� ȣ���� �Ϸ� ��, grand ���� ȣ��
	AllCondition	=	combi_Recursive(lCondition, length(lCondition), {});
	%%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	return;

%%-------------------------------------------------------------------------------
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%-------------------------------------------------------------------------------
function [ CondCombi ] = combi_Recursive(list, level, tag)
% level: # of condition, ex) == 4 -> call order: 4, 3, 2, 1(leaf)
% tag  : ID array(or string) at each loop, ex) { '4', '3', '2', '1' }

	if level >= 1										% leaf�ƴ�: call�ݺ�
		CondCombi		=	{};

		Cond			=	list{level};
%		for c = 1 : length(Cond)
%			tag{level}	=	Cond{c};					% �� �ܰ� �Ϻη�
		for c = Cond									% == foreach
			tag{level}	=	c{1};						% �� �ܰ� �Ϻη�
			CondCombi{end+1}	=	combi_Recursive(list, level-1, tag);
		end

		% recursive return ���� ����, ���ϰ��� nested cell ����ȭ �Ǳ� ������
		% ���ϵǱ� ���� flatten �ؾ߸�, root���� ���� cell ������ ����
		CondCombi		=	table2array(cell2table(CondCombi));	% cell flat

	else												% level == 0
		%% leaf ����: �������ʹ� ���� processing�� �����Ѵ�.
		CondCombi		=	strjoin(tag, '');			% ���� ���ڿ���!

	end

	return;

%%-------------------------------------------------------------------------------
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%-------------------------------------------------------------------------------
