function [PLVsub, PLSsub] = cohcmp_ch2ch(TFsub, tlen, ch_src, start, finish)
%% Usage:
%	[PLV, PLS]=cohcmp_ch2ch(freq, time_len, ch1, start, finish)	%start와 finish는 채널 시작 & 끝 index
%
%% this function is maked for nested parfor operation.
%	thus, parent proc be constructed parfor loop, too.
%
%% Inputs:
%	TFsub	: sub_array(len(freq)==1, time, epoch, chs) by TF(4D)
%   time_len: time zone length on TF
%	ch_src	: 비교할 상태 채널
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
%Pls			=	zeros(tlen,finish);	% 틀을 만들어 주는 것
%PLVsub		=	cell(finish);		%셀 타입구성: plv배열==double(1, 1:1000) 저장
%PLSsub		=	cell(finish);		%이렇게 하면 len(chns)*len(chns) == 30 x 30 매트릭스가 생성...
PLVsub		=	cell(1,finish);		%셀 타입구성: plv배열==double(1, 1:1000) 저장
PLSsub		=	cell(1,finish);		%이유는 모르겠으나, 위와 같이하면 안되서, 1차원을 강제 구성

%% Main code
%parfor ch2=ch1+1:length(chns),
parfor ch_dst = start:finish,
%	fprintf('cohcmp CH1(%d) vs CH2[%d] of (%d:%d)\n', ch_src, ch_dst, start, finish);
	[plv, pls]			=	tf2coh_min(TFsub(:,:,:,ch_src), TFsub(:,:,:,ch_dst), 10, 100);	% K, ITER 위에 설명 써있음. 몇 개를 평균을 낸다, surrogation(전체 평균, 뽑아 낸 것)을 하면 좋은데 느림, 원형 통계라는 것이 있다.
	% 슈퍼컴과 MDCS를 테스트 해보기
	if pls < 0.05,
% %		PLV(:,ch_src)	=	plv;	% parfor 연산시, 이 코드와 다음줄 코드를 동시에
% 									% 쓰면 PLV를 output sliced variable 로 분류를 못한다며 에러 발생 됨.
% 									% 다음 줄만 쓰거나, 이 코드 라인만 쓰면 작동함! <why?>
% 		Plv(:,ch_dst)	=	plv;
% 
% %		PLS(:,ch_src)	=	pls;	% 위 코드 상황과 마찬가지..
% 		Pls(:,ch_dst)	=	pls;	% 절반만 돌리면 되는데 전체가 있는 건가??

		PLVsub{ch_dst}	=	plv;	%timezone 기준 데이터array를 하나의 단위로써 셀에 개별 저장
		PLSsub{ch_dst}	=	pls;	%timezone 기준 데이터array를 하나의 단위로써 셀에 개별 저장
	else
		PLVsub{ch_dst}	=	zeros(1, tlen);	%dummy 값으로 채움
		PLSsub{ch_dst}	=	0.0;			%dummy 값으로 채움
	end;

	plv					=	PLVsub{ch_dst};
	pls					=	PLSsub{ch_dst};
	save(['x:/PLV_theta' '/skk_phase30/' 'Phase_' 'Fav_USA_dislike_su14' '_ch' num2str(ch_src) '~ch' num2str(ch_dst) '_par.mat'], 'plv', 'pls', '-v7.3');
end;
