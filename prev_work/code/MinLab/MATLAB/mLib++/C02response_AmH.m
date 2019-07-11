function [ ] = C02response_AmH(MarkerDir,							...
							Marker4Stimuli, Marker4Response, SmplRate, SaveDir)
%%	[RT, SD, n, ER]	=	RT(MarkerPath, Marker4Stimuli, Marker4Response, SavePath)
%
%	MarkerDir		: ��Ŀ ������ -> '/home2/minlab/TIN/Raw Files'
%	Marker4Stimuli	: �ڱ� ��ȣ -> [ 12 13 14 15 16 ]
%	Marker4Response	: ���� ����(����, ����, ��) -> [ 1 2 3]
%	SmplRate		: ���ø� ����(1�ʴ�) -> 500
%	SaveDir			: ��� txt ����� -> '/home2/minlab/TIN/RespAn'
%
%% Usage: C02response_AmH('/home2/minlab/TIN/Raw Files',			...
%%									[11 12 13 14 15], [1 2 3],				...
%%									500, '/home2/minlab/TIN/Response Analysis')
%
% Analyzer�� Vmrk ������ ���� subject�� Response�� ���� ����Ǵ� �ٽ�������
% RT==Reaction Time �� Correct Rate �� ����Ѵ�.

%function	[ eEEG RT fSmpl Labels Meta ]	=	mLib_ResponseAnalysis_AmH(hEEG)
%		[RT, SD, n]	=	RT(mrk, [101 1], [13 ...])

%%% ��꿡 �ռ�!, Ʈ���� �ڵ� �� �������ڵ�(�ð������� �Ұ����ϰ� ��ŷ�Ǵ�)��
% ���� �����ؾ� ��.
% �̶�, PRT ��Ʈ���� 8bit 2������ �ڵ尪�� �����ʿ� ����, �� bit-field ��
% time overap �� ���� �߻������� ���������� ���� reasonable �� ���� ����!

%% ------------------------------------------------------------------------------
% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
%close -except Path4eeg, subj;
clearvars -except	MarkerDir Marker4Stimuli Marker4Response SmplRate SaveDir;
					%','�� �����ϸ� ù ',' ���� �������� ��� ����

%% setting %%
path(localpathdef);	%<UserPath>�� �ִ� pathdef.m �� �����Ͽ� �߰����� path�� ���

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
[mkStim	mkResp]	=	deal( Marker4Stimuli, Marker4Response );

Total			=	tic;		%��ü ���� �ð�

% MarkerDir �� �ִ� ��� *.vmrk �� ����, RT �� ER �� ���Ѵ�.
lFile			=	ls([ MarkerDir '/' '*.vmrk' ], '-1'); % ���� ���: '-1':unix
lFile			=	strsplit(lFile, '\n')';

for f = 1 : length(lFile)
	SRC_NAME	=	char(lFile(f));
	if isempty(SRC_NAME), continue;	end					% �� �׸� �ǳʶ�

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	AllTime		=	tic;		%������ preparing �ð��� �����Ѵ�.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s [VMRK] to Response on WORKSPACE.\n', SRC_NAME);
	%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.

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
	% VMRK ������ �Ľ� �Ѵ�.
	lTGR		=	bva_readmarker(SRC_NAME);
%	if iscell(lTGR), lTGR = cell2mat(lTGR); end			% ��Ȥ cell �� ���� ��
	if iscell(lTGR)		% vmrk �߰����� new segment ��ŷ�� ��� cell�� ���ҵ� ��
		lTGR = [ lTGR{:} ];								% �Ѱ��� ����
	end			% ��Ȥ cell �� ���� �� : 
	lTGR(find(isnan(lTGR))) = 0;						% �� seg�� 1st�� NaN

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%%% ��꿡 �ռ�!, Ʈ���� �ڵ� �� �������ڵ�(�ð������� �Ұ����ϰ� ��ŷ�Ǵ�)��
%% ���� �����ؾ� ��.
%% �̶�, PRT ��Ʈ���� 8bit 2������ �ڵ尪�� �����ʿ� ����, �� bit-field ��
%% time overap �� ���� �߻������� ���������� ���� reasonable �� ���� ����!

	% 20151204A. ��� �������ڵ带 reasonable �� ��Ȳ�Ͽ��� �ǵ��� �� ��.
	%	1. �ð����� �Ұ��ɼ� ����� ��.
	%	2. bit-field ���տ��� �ǵ��� ��.
	% lTGR�� ����: (a,b) = ( marker, time )

	% ��Ŀ�� stim vs resp �� �������� �����鼭, �ð������� �Ұ����� ��� ����
	% �� ������ ������ �ΰ��� marker �̸�, stim�� 2�ڸ�+, resp�� 1 �ڸ� ��.
	if isnan(lTGR(1,1)), lTGR(1,1) = 0; end	% ù��° marker�� NaN ��!
%{
	Rm4Over		=	zeros(0);				% bit-field overalp ���� %-[
	Rm4Time		=	zeros(0);				% ���� ����
	for m = 2 : size(lTGR, 2)-1				% �� ó���� NaN !
	if 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9	% stim 2�ڸ�+, resp 1�ڸ�
		if lTGR(2,m+1) - lTGR(2,m) <= 10	% ������ 10ms �̳�?
		% -----
		if bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) %bit�ʵ� overlap ����
			Rm4Over(end+1)	=	m;			% ������ �ε���
		elseif 10 <= lTGR(1,m-1)			% overlap����, �� �յ� stim ���
			Rm4Time(end+1)	=	m;			% ������ �ε���
		else								% overlap �ƴϰ�, �յ� stim X ?
			error('Error');
		end

%			else								% ���������� ���
%				lTGR(:,n+0)	=	lTGR(:,m-0);
%				lTGR(:,n+1)	=	lTGR(:,m+1);
		end

	end	% if stim ~ resp �ڸ���
	end	% for	%-]
%}
	% detection �Լ� ����
	fEpoch		=	@(m) ( 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9 ); % stim~resp
	fNarrow		=	@(m) ( lTGR(2,m+1) - lTGR(2,m) <= 10 );	% ���� 10ms �̳�
	fOverlap	=	@(m) ( bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) );
	fContStim	=	@(m) ( 10 <= lTGR(1,m-1) & 10 <= lTGR(1,m) ); % ����stim

	m			=	2:size(lTGR, 2)-1;					% ��Ŀ �� ����

	Rm4Over		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fOverlap(x) ), m);
	Rm4Over		=	find(Rm4Over)+1;					% m == 2 ���� ����

	Rm4Time		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fContStim(x) ), m);
	Rm4Time		=	find(Rm4Time)+1;					% m == 2 ���� ����
	Rm4Time		=	find(~ismember(Rm4Over, Rm4Time));	% �ߺ� ����

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
	lTgr(:,[ Rm4Over Rm4Time ] )	=	[];				% ������ ��Ŀ ����

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	% lTgr�� �����Ǿ����Ƿ�, stim ~ resp ��Ŀ ������ ��ü������ ã�Ƴ���.
for s = 1 : length(mkStim)
	S			=	mkStim(s);							% �� stim �� resp�� ����
	R			=	mkResp(1);							% correct answer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% SRC_NAME���� OUT_NAME�� �� ������ �����Ѵ�.
	OUT_NAME	=	strsplit(SRC_NAME, '/');
	OUT_BASE	=	regexprep(char(OUT_NAME(end)), '.[A-Za-z]*$', '');
	% ���� ��� ���ϸ� ����
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

%����: adjacent matrix :
%			http://www.mathworks.com/matlabcentral/newsreader/view_thread/331717

%--------------------------------------------------------------------------------
try		% The requested trigger was not Found -> ���� ����
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
%	RT			=	zeros(1,0);							% pair �� �� ã��
		fprintf('Notify  : not found the Reaction Time & SKIP\n');
		continue										% RT==0:  no more work!
end			% try - catch
%--------------------------------------------------------------------------------

	SD			=	std(RT);							% ǥ������
%	if isnan(SD), SD = 0; end							% RT=[] �̸� SD=NaN
%	n			=	length(RT);

	% --------------------------------------------------
	if length(mkResp) == 1								% correct �� �Ķ���� ��
		% correct answer�� �ƴ� resp �ڵ带 �� ã��(maybe: incor + miss)
		lMkXResp=	find(lTgr(1,:) <= 9 & lTgr(1,:) ~= R);	% Ʋ��|miss
		lMkXResp=	lTgr(1, lMkXResp);		%  ��Ŀ ��ȣ
%		InCr	=	bva_rt(lTgr, mkStim, mkInCr, SmplRate);	% reaction time
%		Miss	=	bva_rt(lTgr, mkStim, mkMiss, SmplRate);	% reaction time
try		% The requested trigger was not Found -> ���� ����
		XRT		=	arrayfun(@(r)({bva_rt(lTgr, S, r, SmplRate)}), lMkXResp);
catch	exception	% The requested trigger was not Found
		XRT		=	zeros(1,0);							% �� ���
end
		XRT		=	cell2mat(XRT);
	else
try		% The requested trigger was not Found -> ���� ����
		XRT		=	bva_rt(lTgr, S, mkResp(2), SmplRate);		% reaction time
catch	exception	% The requested trigger was not Found
		XRT		=	zeros(1,0);
end
		% -----
try		% The requested trigger was not Found -> ���� ����
		MRT		=	bva_rt(lTgr, S, mkResp(3), SmplRate);		% reaction time
catch	exception	% The requested trigger was not Found
		MRT		=	zeros(1,0);
end
		XRT		=	[ XRT MRT ];						% �ϳ��� ��ħ
	end
	% --------------------------------------------------
%	ER			=	ErrRt(lTgr, [101 1], [2,3,...]); % [ ]��: % incor, miss
	% ����: correct / (correct + incorrect + missing )
	%		correct: [ 101 1 ]
	%		incor  : [ 101 2 ]
	%		missing: [ 101 3 ]
	nRT			=	length(RT);
	AC			=	nRT / (nRT + length(XRT));
%	if isnan(AC), AC = 0; end							% AC=NaN

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	% RT, ER �� �������Ƿ�, ������ ������� �������.
	fprintf(['Results : %s''s Reaction Time(s:%d vs r:%d) = #%d\n',		...
			'& Accuracy Rate = %.2f\n'], OUT_BASE, S, R, nRT, AC);
%		for r = 1 : length(RT), fprintf('%3dth Trial''s RT = %4d\n',r,RT(r)); end

	if ~isempty(SaveDir)
		XLS			=	fopen(OUT_NAME, 'w');			% txt �� ���

			fprintf(XLS, 'AVG\t%8.3f\n',	mean(RT));	% ���
			fprintf(XLS, 'SD\t%8.3f\n',		SD);		% ǥ������
			fprintf(XLS, 'n\t%8.3f\n',		nRT);		% ����
			fprintf(XLS, 'AC\t%8.3f\n\n',	AC);		% ��Ȯ��

			fprintf(XLS, '# each Reaction Time lists -----\n');
		for r = 1 : length(RT)
			fprintf(XLS, '%4dth\t%d\n', r, RT(r));		% �� RT �� ���
		end
		fclose(XLS);
	end

end % for stim
end	% for file

fprintf('\nFinished: total time is ');	toc(Total);		%��ü ���� �ð�

