function [ DiffCnt ] = PLVcmp_tigoum(plv_src, plv_dst)
%% Usage:
%	[Diff Count]=plvcmp(src, dst)	% 두 개의 plv 파일에 대한 비교
%
%% this function comapre between src & dst on PLV arrays.
%
%% Inputs:
%	plv_src	: fullpath for plv data file
%	plv_dst	: fullpath for plv data file
% Outputs:
%	count	: count for diffrence between src vs dst
%
% 2015/05/17
% by TiGoum(Ahn MIN-hee), MIN-Lab, Korea Univ.
% email: tigoum@naver.com

%% variables definitions
%Plv			=	zeros(tlen,finish);	% timezone * all(ch_dst)
%Pls			=	zeros(tlen,finish);	% 틀을 만들어 주는 것
%% please load eEEG for each experiment and condition:
%clear;clc;


%% Header %%
fullPATH	=	'x:\PLV_theta';
%channame	={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
%dataname	={'Fav_USA'};%, 'Neutral_Mexico', 'Unfav_Paki'};
%trialname	={'dislike'};%, 'like'};
%subname		={'su09'};
%selchanname	={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
%data=[length(dataname)*length(trialname):3];  %[datanumb * trialnumb] * [f, t_start, t_fin]
%FR			=	[4.0, 8.0];												%주파수 시작, 끝

%SRC			=	[ PLV, PLS, channame, selchanname ];
%DST			=	[ PLV, PLS, channame, selchanname ];

%%
			%편의를 위해 파일명을 구성해 둠
%	WORK_SRC	=	[ char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ];
%	WORK_DST	=	[ char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ];
%	eval(['load(''' fullPATH '\skk_phase31\' 'Phase_' WORKNAME '.mat'',''channame'',''selchanname'',''PLV'',''PLS'',''-mat'');']);
	eval(['load(''' plv_src ''',''channame'',''selchanname'',''PLV'',''PLS'',''-mat'');']);
	SRC_PLV		=	PLV;			% memorying for source
	SRC_PLS		=	PLS;
			
	eval(['load(''' plv_dst ''',''channame'',''selchanname'',''PLV'',''PLS'',''-mat'');']);
	DST_PLV		=	PLV;			% memorying for destination
	DST_PLS		=	PLS;

%	MinMinMin_phase7();
	DiffCnt			=	plvcmp_main(SRC_PLV, DST_PLV);

	%전체 데이터 말고, PLV, PLS 만 저장
%	save([fullPATH '\skk_phase31\' 'Phase_' WORKNAME '.mat'], 'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');

end		%plvcmp function's end

function [cnt] = plvcmp_main(SRC_PLV, DST_PLV)
%% Usage: 
%
%% code
	cnt		=	0;
	for f=1:size(SRC_PLV, 1),
		for ch1=1:size(SRC_PLV, 4)-1, % channel combination 전체 비교
%			fprintf('%s''s COH of FREQ:%f, | CH1(%d) vs CH2[%d:%d] |\n', WORKNAME, freqrange(f), ch1, ch1+1, length(chns));

			for ch2=ch1+1:size(SRC_PLV, 4),
				if SRC_PLV(f,:,ch1,ch2) ~= DST_PLV(f,:,ch1,ch2),
					cnt		=	cnt + 1;
					fprintf('PLV-Diff found at [ FreqIdx(%d), Chan1(%d), Chan2(%d) : (%f != %f) ]\n', f, ch1, ch2, SRC_PLV(f,1,ch1,ch2), DST_PLV(f,1,ch1,ch2) );
				end;
			end;
		end;
	end;

end		% plvcmp_main function's end.
