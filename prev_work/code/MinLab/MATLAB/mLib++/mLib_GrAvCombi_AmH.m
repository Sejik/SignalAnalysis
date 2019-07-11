%% 기 연산된 grand avg 에 대해 복잡한 조건의 combination 별 재-avg 수행
%% 따라서, 반드시 GrandAvg...m 을 먼저 수행하여 grand average 결과가 있어야 함

function [ ] = mLib_GrAvCombi_AmH(LoadPath, cCondiCombi,		SavePath)
% LoadPath		: 기 계산된 grand average .mat 이 담긴 folder
% cCondiCombi	: 재계산할 조건의 조합
%				ex) 'F__L' 과 같이 합칠 조건은 '_'으로 표기
%				ex) { 'FSH_', 'MA__' }
% SavePath		: 저장할 장소

clearvars -except LoadPath cCondiCombi SavePath
%clear;
%close all;

%% setting %%
%path(localpathdef);	%<UserPath>에 있는 localpathdef.m 실행, 추가적인 path를 등록
% FSHL
% If there is no node, it should work.

% 여러 조건조합이 요구될 수 있으므로, param의 type을 판독해야 함.
if ~iscell(cCondiCombi)
	cCondiCombi			=	{ cCondiCombi };
end

% load path 에 있는 모든 data를 읽기 위해, 우선 condition 별 파일명 확보
fName			=	ls([ LoadPath '/*_*.mat' ]);	% 하나의 문자열로 올라옴
fName			=	regexprep(fName, '[ ]+', '\n');	% 공백분리 항목을 라인구분
fName			=	strsplit(fName, '\n');			% 파일별로 분리
%fName			=	dir([ LoadPath '/*_*.mat' ]);	% 하나의 문자열로 올라옴
%fName			=	struct2cell(fName);
%fName			=	fName(1, :);					% 파일이름만

Total			=	tic;		%전체 연산 시간
% ===============================================================================
for c = 1 : length(cCondiCombi)
	sCondi		=	cCondiCombi{c};					% 전체 조건 중 현재 조건

	% scondi 에 해당하는 파일목록만 추출
%	rCondi		=	regexprep(sCondi, '[_]', '.');	% '_' -> '.' 으로 변경
	rCondi		=	regexprep(sCondi, '[_]', '[^_]');% '_' -> '[^_]'(_ 안됨) 변경
	ix			=	regexp(fName, ['.*_' rCondi '[.]mat'], 'match'); % match 여부
	ix			=	cellfun(@(x)( ~isempty(x) ), ix);	% 각 셀별로 비었는지
	ix			=	find( ix );						% 내용이 있는 것의 index 만
	GetName		=	fName( ix );					% 해당 파일명 확보

	if isempty(GetName)
		error('No File : exist for condition [%s] & SKIP this.\n', sCondi);
		return %continue
	end

	%% --------------------------------------------------
	fprintf('\nProcess : a data averaging for condition [%s]\n', sCondi);

AllTime			=	tic;		%조건별 해당 전체 파일 연산 시간
% ===============================================================================
for f = 1 : length(GetName)
	load( GetName{f} );								% 파일 읽기
	fprintf('Loading : file from %s\n', GetName{f});	% notify file name

	% 참고: 읽어온 데이터 변수명에는 조건이 포함된 형태임.
	% ex) ERP_ESHL
	%% 그런데, sCondi 에는 'F..L' 과 같은 pattern 이므로 변수명으로 호출불가!
	%% 따라서, whos sCondi 하여 변수명 확보
	eval( [ 'VAR = whos(''-regexp'', ''[A-Z]{3}_' rCondi ''');' ] ); % 모두 수집
	VAR				=	struct2cell(VAR);			% 구조변경
	vName			=	VAR(1, :);					% 변수명만 추출
	vSize			=	VAR(2, :);					% 크기만 추출

	if size(vName) ~= 4								% 변수가 4개보다 적거나 많음
		error('Warning : abnormal # of variables: %s\n', strjoin(vName,', '));
	end

% ===============================================================================
for v = 1 : length(vName)
	InVar			=	vName(v);					% 입력변수
	OtVar			=	regexprep(InVar,'^([A-Z]{3})_.*',['$1_' sCondi]);%out변수
	[InVar OtVar]	=	deal( char(InVar), char(OtVar) );

	nDim			=	length( size( vSize(v) ) );	% 변수의 차원 갯수

	% 파일들에 있는 각 변수를 다 합산할 목적 변수가 없으면 초기화
	% 목적변수는 각 파일 단위로 저장해야 하므로, 필히 1차원을 더 추가 해야 함
	if ~exist(OtVar), eval( [ OtVar ' = zeros([ 0 size(' InVar ') ]);' ] ); end

%	eval( [ OtVar	'	=	' OtVar '+' InVar ';' ] );	% 덧셈 수행
	eval( [ OtVar	'(end+1,:)	=	' InVar '(:);' ] );	% 1D 규격으로 저장
	eval( [ 'clear ' InVar ] );						% remove conditioned var

end	% for var
	clear VAR vName vSize InVar nDim				% garbage 제거 위해 삭제

end % for file
	clear GetName

% ===============================================================================
	% 조건 조합에 해당하는 모든 파일들의 변수를 합산하였으므로, 이제 평균 내자
%	VAR				=	whos('-regexp', '^[A-Z]{3}_[A-Z_]+$');	% 모두 수집
	VAR				=	whos('-regexp', ['^[A-Z]{3}_' sCondi '$']);	% 모두 수집
	if isempty(VAR)									% 비상!! 아무것도 못찾음!!
	fprintf('\nWarning!: not found the Variables on workspace.\n\n');	% notify
	end
	% -----
	VAR				=	struct2cell(VAR);			% 구조변경
	vName			=	VAR(1, :);					% 변수명만 추출
for v = 1 : length(vName)
	InVar			=	char(vName(v));				% 입력변수

%	eval( [ InVar	'	=	' InVar ' / length(GetName);' ] );	% 평균 계산
	eval( [ InVar	'	=	squeeze(mean(' InVar ', 1));' ] );	% 평균 계산
end	% for var

% ===============================================================================
	% 이제 저장소에 저장
%	ssCondi			=	regexprep(sCondi, '[.]', '-');	% 파일이름 적합 변경

	fprintf('Storing : file to %s\n', [SavePath '_' sCondi '.mat' ]);	% notify
	eval( [ 'save '	SavePath '_' sCondi '.mat'	' ' strjoin(vName,' ') ';'] );
	eval( [ 'clear VAR'							' ' strjoin(vName,' ') ';'] );
	fprintf('Complete: works of [%s] condition ', sCondi);	toc(AllTime);

end	% for condi
fprintf('\nFinished: total time is ');	toc(Total);

