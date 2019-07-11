function [ ] = C02response_AmH(MarkerDir,							...
							Marker4Stimuli, Marker4Response, SmplRate, SaveDir)
%%	[RT, SD, n, ER]	=	RT(MarkerPath, Marker4Stimuli, Marker4Response, SavePath)
%
%	MarkerDir		: 마커 보관소 -> '/home2/minlab/TIN/Raw Files'
%	Marker4Stimuli	: 자극 번호 -> [ 12 13 14 15 16 ]
%	Marker4Response	: 응답 구분(정답, 오답, 모름) -> [ 1 2 3]
%	SmplRate		: 샘플링 비율(1초당) -> 500
%	SaveDir			: 결과 txt 저장소 -> '/home2/minlab/TIN/RespAn'
%
%% Usage: C02response_AmH('/home2/minlab/TIN/Raw Files',			...
%%									[11 12 13 14 15], [1 2 3],				...
%%									500, '/home2/minlab/TIN/Response Analysis')
%
% Analyzer의 Vmrk 정보로 부터 subject의 Response에 의해 산출되는 핵심정보인
% RT==Reaction Time 과 Correct Rate 를 계산한다.

%function	[ eEEG RT fSmpl Labels Meta ]	=	mLib_ResponseAnalysis_AmH(hEEG)
%		[RT, SD, n]	=	RT(mrk, [101 1], [13 ...])

%%% 계산에 앞서!, 트리거 코드 중 비정상코드(시간적으로 불가능하게 마킹되는)를
% 필해 제거해야 함.
% 이때, PRT 포트에서 8bit 2진수로 코드값이 생성됨에 따른, 각 bit-field 별
% time overap 에 의해 발생가능한 조합인지와 같은 reasonable 한 경우로 한정!

%% ------------------------------------------------------------------------------
% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
%close -except Path4eeg, subj;
clearvars -except	MarkerDir Marker4Stimuli Marker4Response SmplRate SaveDir;
					%','로 구분하면 첫 ',' 뒤의 변수들은 모두 제거

%% setting %%
path(localpathdef);	%<UserPath>에 있는 pathdef.m 을 실행하여 추가적인 path를 등록

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
[mkStim	mkResp]	=	deal( Marker4Stimuli, Marker4Response );

Total			=	tic;		%전체 연산 시간

% MarkerDir 에 있는 모든 *.vmrk 에 대해, RT 와 ER 을 구한다.
lFile			=	ls([ MarkerDir '/' '*.vmrk' ], '-1'); % 파일 목록: '-1':unix
lFile			=	strsplit(lFile, '\n')';

for f = 1 : length(lFile)
	SRC_NAME	=	char(lFile(f));
	if isempty(SRC_NAME), continue;	end					% 빈 항목 건너뜀

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	AllTime		=	tic;		%데이터 preparing 시간을 계측한다.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s [VMRK] to Response on WORKSPACE.\n', SRC_NAME);
	%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%check & auto skip if not exist a 'dat file.
	fprintf('Checking: Source file: ''%s''... ', SRC_NAME);
	if exist(SRC_NAME, 'file') <= 0						%skip
		fprintf('not! & SKIP converting this\n\n');
		continue;										%exist !!
	else
		fprintf('EXIST & Continue the converting\n\n');
	end

%%-------------------------------------------------------------------------------
% Convert: VMRK@EEG -> Response
% -------------------------------------------------------------------------------
	% VMRK 파일을 파싱 한다.
	lTGR		=	bva_readmarker(SRC_NAME);
%	if iscell(lTGR), lTGR = cell2mat(lTGR); end			% 간혹 cell 로 리턴 옴
	if iscell(lTGR)		% vmrk 중간에서 new segment 마킹된 경우 cell로 분할되 옴
		lTGR = [ lTGR{:} ];								% 한개로 병합
	end			% 간혹 cell 로 리턴 옴 : 
	lTGR(find(isnan(lTGR))) = 0;						% 각 seg의 1st는 NaN

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%%% 계산에 앞서!, 트리거 코드 중 비정상코드(시간적으로 불가능하게 마킹되는)를
%% 필히 제거해야 함.
%% 이때, PRT 포트에서 8bit 2진수로 코드값이 생성됨에 따른, 각 bit-field 별
%% time overap 에 의해 발생가능한 조합인지와 같은 reasonable 한 경우로 한정!

	% 20151204A. 상기 비정상코드를 reasonable 한 상황하에서 판독해 낼 것.
	%	1. 시간적인 불가능성 고려할 것.
	%	2. bit-field 조합에서 판독할 것.
	% lTGR의 구조: (a,b) = ( marker, time )

	% 마커를 stim vs resp 의 조합으로 묶으면서, 시간적으로 불가능한 경우 조사
	% 이 조합은 인접한 두개의 marker 이며, stim은 2자리+, resp는 1 자리 임.
	if isnan(lTGR(1,1)), lTGR(1,1) = 0; end	% 첫번째 marker는 NaN 임!
%{
	Rm4Over		=	zeros(0);				% bit-field overalp 문제 %-[
	Rm4Time		=	zeros(0);				% 시차 오류
	for m = 2 : size(lTGR, 2)-1				% 맨 처음은 NaN !
	if 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9	% stim 2자리+, resp 1자리
		if lTGR(2,m+1) - lTGR(2,m) <= 10	% 시차가 10ms 이내?
		% -----
		if bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) %bit필드 overlap 현상
			Rm4Over(end+1)	=	m;			% 제거할 인덱스
		elseif 10 <= lTGR(1,m-1)			% overlap없고, 그 앞도 stim 경우
			Rm4Time(end+1)	=	m;			% 제거할 인덱스
		else								% overlap 아니고, 앞도 stim X ?
			error('Error');
		end

%			else								% 시차정상인 경우
%				lTGR(:,n+0)	=	lTGR(:,m-0);
%				lTGR(:,n+1)	=	lTGR(:,m+1);
		end

	end	% if stim ~ resp 자릿수
	end	% for	%-]
%}
	% detection 함수 정의
	fEpoch		=	@(m) ( 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9 ); % stim~resp
	fNarrow		=	@(m) ( lTGR(2,m+1) - lTGR(2,m) <= 10 );	% 시차 10ms 이내
	fOverlap	=	@(m) ( bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) );
	fContStim	=	@(m) ( 10 <= lTGR(1,m-1) & 10 <= lTGR(1,m) ); % 연속stim

	m			=	2:size(lTGR, 2)-1;					% 마커 의 범위

	Rm4Over		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fOverlap(x) ), m);
	Rm4Over		=	find(Rm4Over)+1;					% m == 2 부터 시작

	Rm4Time		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fContStim(x) ), m);
	Rm4Time		=	find(Rm4Time)+1;					% m == 2 부터 시작
	Rm4Time		=	find(~ismember(Rm4Over, Rm4Time));	% 중복 제거

	if length(Rm4Over) > 1
		fprintf(['Detect  : & remove the #%d of MARKERs for '				...
				'bit-field overaping.\n'],	length(Rm4Over));
	end
	if length(Rm4Time) > 1
		fprintf(['Detect  : & remove the #%d of MARKERs for '				...
				'too short timing.\n'],		length(Rm4Time));
	end
	fprintf('\n');

	lTgr		=	lTGR;
	lTgr(:,[ Rm4Over Rm4Time ] )	=	[];				% 비정상 마커 제거

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	% lTgr이 정리되었으므로, stim ~ resp 마커 조합을 구체적으로 찾아낸다.
for s = 1 : length(mkStim)
	S			=	mkStim(s);							% 각 stim 별 resp와 조합
	R			=	mkResp(1);							% correct answer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% SRC_NAME에서 OUT_NAME에 쓸 정보를 추출한다.
	OUT_NAME	=	strsplit(SRC_NAME, '/');
	OUT_BASE	=	regexprep(char(OUT_NAME(end)), '.[A-Za-z]*$', '');
	% 최종 출력 파일명 구성
%	OUT_NAME	=[	SaveDir '/' OUT_BASE '_'								...
%						num2str(mkStim(1)) '_' num2str(mkResp(1)) '.txt'	];
%	OUT_NAME	=[	SaveDir '/' OUT_BASE '_' num2str(S) '_' num2str(R) '.txt' ];
	OUT_NAME	=[	SaveDir '/' OUT_BASE '_' num2str(S) '.txt' ];

	%check result file & skip analysis if aleady exists.
	fprintf('\nChecking: Analyzed result file: ''%s''...', OUT_NAME);
	if exist(OUT_NAME, 'file') > 0						%exist !!
		fprintf('exist! & SKIP analyzing this\n');
		continue;										%exist !!
	else
		fprintf('NOT & Continue the Analyzing\n');
	end

%참고: adjacent matrix :
%			http://www.mathworks.com/matlabcentral/newsreader/view_thread/331717

%--------------------------------------------------------------------------------
try		% The requested trigger was not Found -> 대응 수행
	RT			=	bva_rt(lTgr, S, R, SmplRate);		% reaction time
	if isempty(RT)
		fprintf('Notify  : not found the Reaction Time & SKIP\n');
		continue										% RT==0:  no more work!
	end
	%catch	exception
	%	if strcmp(exception.identifier,		...
	%		'MATLAB:catenate:dimentionMismatch'),	???;	end
%--------------------------------------------------------------------------------
catch	exception	% The requested trigger was not Found
%	RT			=	zeros(1,0);							% pair 를 못 찾음
		fprintf('Notify  : not found the Reaction Time & SKIP\n');
		continue										% RT==0:  no more work!
end			% try - catch
%--------------------------------------------------------------------------------

	SD			=	std(RT);							% 표준편차
%	if isnan(SD), SD = 0; end							% RT=[] 이면 SD=NaN
%	n			=	length(RT);

	% --------------------------------------------------
	if length(mkResp) == 1								% correct 만 파라미터 옴
		% correct answer가 아닌 resp 코드를 다 찾음(maybe: incor + miss)
		lMkXResp=	find(lTgr(1,:) <= 9 & lTgr(1,:) ~= R);	% 틀림|miss
		lMkXResp=	lTgr(1, lMkXResp);		%  마커 번호
%		InCr	=	bva_rt(lTgr, mkStim, mkInCr, SmplRate);	% reaction time
%		Miss	=	bva_rt(lTgr, mkStim, mkMiss, SmplRate);	% reaction time
try		% The requested trigger was not Found -> 대응 수행
		XRT		=	arrayfun(@(r)({bva_rt(lTgr, S, r, SmplRate)}), lMkXResp);
catch	exception	% The requested trigger was not Found
		XRT		=	zeros(1,0);							% 빈 행렬
end
		XRT		=	cell2mat(XRT);
	else
try		% The requested trigger was not Found -> 대응 수행
		XRT		=	bva_rt(lTgr, S, mkResp(2), SmplRate);		% reaction time
catch	exception	% The requested trigger was not Found
		XRT		=	zeros(1,0);
end
		% -----
try		% The requested trigger was not Found -> 대응 수행
		MRT		=	bva_rt(lTgr, S, mkResp(3), SmplRate);		% reaction time
catch	exception	% The requested trigger was not Found
		MRT		=	zeros(1,0);
end
		XRT		=	[ XRT MRT ];						% 하나로 합침
	end
	% --------------------------------------------------
%	ER			=	ErrRt(lTgr, [101 1], [2,3,...]); % [ ]속: % incor, miss
	% 공식: correct / (correct + incorrect + missing )
	%		correct: [ 101 1 ]
	%		incor  : [ 101 2 ]
	%		missing: [ 101 3 ]
	nRT			=	length(RT);
	AC			=	nRT / (nRT + length(XRT));
%	if isnan(AC), AC = 0; end							% AC=NaN

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	% RT, ER 을 구했으므로, 일정한 양식으로 출력하자.
	fprintf(['Results : %s''s Reaction Time(s:%d vs r:%d) = #%d\n',		...
			'& Accuracy Rate = %.2f\n'], OUT_BASE, S, R, nRT, AC);
%		for r = 1 : length(RT), fprintf('%3dth Trial''s RT = %4d\n',r,RT(r)); end

	if ~isempty(SaveDir)
		XLS			=	fopen(OUT_NAME, 'w');			% txt 로 출력

			fprintf(XLS, 'AVG\t%8.3f\n',	mean(RT));	% 평균
			fprintf(XLS, 'SD\t%8.3f\n',		SD);		% 표준편차
			fprintf(XLS, 'n\t%8.3f\n',		nRT);		% 갯수
			fprintf(XLS, 'AC\t%8.3f\n\n',	AC);		% 정확도

			fprintf(XLS, '# each Reaction Time lists -----\n');
		for r = 1 : length(RT)
			fprintf(XLS, '%4dth\t%d\n', r, RT(r));		% 각 RT 값 목록
		end
		fclose(XLS);
	end

end % for stim
end	% for file

fprintf('\nFinished: total time is ');	toc(Total);		%전체 연산 시간

