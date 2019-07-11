function [PLVsub, PLSsub] = cohcmp_ch2ch(TFsub, tlen, ch_src, start, finish)
%% Usage:
%	[PLV, PLS]=cohcmp_ch2ch(freq, time_len, ch1, start, finish)	%start�� finish�� ä�� ���� & �� index
%
%% this function is maked for nested parfor operation.
%	thus, parent proc be constructed parfor loop, too.
%
%% Inputs:
%	TFsub	: sub_array(len(freq)==1, time, epoch, chs) by TF(4D)
%   time_len: time zone length on TF
%	ch_src	: ���� ���� ä��
%   start	: comparision start of channel index
%   finish	: the end of channel index
% Outputs:
%	PLV		: plv data series, timezone * chns
%	PLS		: pls data series...
%
% 2015/05/14
% by TiGoum(Ahn MIN-hee), MIN-Lab, Korea Univ.
% email: tigoum@naver.com

%% variables definitions
%global TF;
%global PLV;
%global PLS;
%Plv			=	zeros(tlen,finish);	% timezone * all(ch_dst)
%Pls			=	zeros(tlen,finish);	% Ʋ�� ����� �ִ� ��
%PLVsub		=	cell(finish);		%�� Ÿ�Ա���: plv�迭==double(1, 1:1000) ����
%PLSsub		=	cell(finish);		%�̷��� �ϸ� len(chns)*len(chns) == 30 x 30 ��Ʈ������ ����...
PLVsub		=	cell(1,finish);		%�� Ÿ�Ա���: plv�迭==double(1, 1:1000) ����
PLSsub		=	cell(1,finish);		%������ �𸣰�����, ���� �����ϸ� �ȵǼ�, 1������ ���� ����

%% Main code
%parfor ch2=ch1+1:length(chns),
parfor ch_dst = start:finish,
%	fprintf('cohcmp CH1(%d) vs CH2[%d] of (%d:%d)\n', ch_src, ch_dst, start, finish);
	[plv, pls]			=	tf2coh_min(TFsub(:,:,:,ch_src), TFsub(:,:,:,ch_dst), 10, 100);	% K, ITER ���� ���� ������. �� ���� ����� ����, surrogation(��ü ���, �̾� �� ��)�� �ϸ� ������ ����, ���� ����� ���� �ִ�.
	% �����İ� MDCS�� �׽�Ʈ �غ���
	if pls < 0.05,
% %		PLV(:,ch_src)	=	plv;	% parfor �����, �� �ڵ�� ������ �ڵ带 ���ÿ�
% 									% ���� PLV�� output sliced variable �� �з��� ���Ѵٸ� ���� �߻� ��.
% 									% ���� �ٸ� ���ų�, �� �ڵ� ���θ� ���� �۵���! <why?>
% 		Plv(:,ch_dst)	=	plv;
% 
% %		PLS(:,ch_src)	=	pls;	% �� �ڵ� ��Ȳ�� ��������..
% 		Pls(:,ch_dst)	=	pls;	% ���ݸ� ������ �Ǵµ� ��ü�� �ִ� �ǰ�??

		PLVsub{ch_dst}	=	plv;	%timezone ���� ������array�� �ϳ��� �����ν� ���� ���� ����
		PLSsub{ch_dst}	=	pls;	%timezone ���� ������array�� �ϳ��� �����ν� ���� ���� ����
	else
		PLVsub{ch_dst}	=	zeros(1, tlen);	%dummy ������ ä��
		PLSsub{ch_dst}	=	0.0;			%dummy ������ ä��
	end;

	plv					=	PLVsub{ch_dst};
	pls					=	PLSsub{ch_dst};
	save(['x:/PLV_theta' '/skk_phase30/' 'Phase_' 'Fav_USA_dislike_su14' '_ch' num2str(ch_src) '~ch' num2str(ch_dst) '_par.mat'], 'plv', 'pls', '-v7.3');
end;
