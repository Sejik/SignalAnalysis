function [ Potential2D lGoodChan lBadChan lZvalue ]	=						...
			AmHlib_FindBad_ChInterp(Potn2D, tWin, SDthre)
	% Potn2D 구조: t x ch
	% tWin : time window
	% SDthre: threshold for SD

	% Potential2D : interpolation 처리 된 Potn2D
	% lGoodChan	: Z < 3SD 인 정상 채널
	% lBadChan	: Z > 3SD 인 비정상 채널
	% lZvalue	: Bad 채널별 Z 값
	% nTune		: Bad 채널 탐색 loop 횟수(Bad탐색 후 interp, -> 다시 반복)

	if nargin<2, tWin = 1:size(Potn2D,1); end		% set time windows

[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
	idxRemCh	=	find( ~ismember(removech, channame));%dead채널만:parm순서!

	%% 20151020A. 자동으로 bad chan을 판독하여 interp 수행하는 알고리즘 필요
	% bad chan의 판독: 특정 time win에서 다른 채널들과의 variation 차이 날때
	%	stats model: normal distribution <- std normal dist에 근접한 정도
	%										즉, MLE 를 구해봐야 할 듯?
	%	threshold: SD>3 일 때
	%	object: channel data of Potential_Indi(:, twin, all ch)
	%		따라서, 변수의 전체 주파수 및 t win 범위 내에서 채널들을 비교분석
	% 1. 전체 데이터에 대해서 normal distribution을 계산한다.
	% 2. 즉, 각 주파수 단위로 twin 내에서 모든 채널의 평균, SD 구한 후,
	% 3. Z = ( X-u ) / SD 를 통해, P(Z<-1.96 U 1.96>Z) (95%, p<0.05) 인
	%	max를 가지는 채널이 있는지 판정하자.
	% 4. P(Z<-1.96 U 1.96>Z) 이면 되므로, Z<-1.96 이거나 1.96<Z 인 Z면 됨
	%	즉, 채널 max 값이 X 이고, 이를 정규화 한 Z 의 크기를 판독하면 됨
	% 5. 만약 99% 추정을 한다면 P(Z<-2.575 U 2.575<Z) 를 판정하면 된다
	%	-> 90% 는 P(Z<-1.645 U 1.645<Z) 임.
	%	-> 교수님과 상의해 본 결과, 99% 가 맞고, 2.575 이지만, 보통은 3 씀
	% 6. bad ch가 발견되면, interp 한 후 다시 재판정 시도
	%	-> 더 이상 bad 가 없거든 loop 종료
		tic; nTune		=	1;							% calibration카운트
		lBadChan		=	[];
		lZvalue			=	[];
	while true											% bad ch 없을 때까지
		%% 먼저, bad 채널을 찾자 ------------------------------	%-[
		lBadPart		=	[];							% 빈 숫자 배열
		iBadCh			=	1;							% lBadPart의 인덱스

		[lmxCh imxCh]	=	max(Potn2D(tWin,:), [], 1);	% time
		lmxCh			=	squeeze(lmxCh)';			% 1D row 구성
		% time 구간에 대해 max 취했으므로, 남는 것은 1D의 채널별 값

		% 위 정보로 u, SD를 계산하자.
		MN_ch			=	mean(lmxCh);				% 채널별 max값의 평균
%		SD_ch			=	std(lmxCh) / sqrt(length(lmxCh)); % SD / sqrt(n)
		SD_ch			=	std(lmxCh);					% SD / sqrt(n)

		% 정규화 시작
		Z				=	( lmxCh - MN_ch ) / SD_ch;	% Z== array
		lBad			=	find( SDthre<abs(Z) );		% SD>3 급 요소만
		lBad			=	lBad(find(~ismember(lBad, idxRemCh)));	%live만
		lBnew			=	lBad(find(~ismember(lBad, lBadPart)))';	%신규만
		Zbad			=	Z(lBnew)';					% SD>3 급 Z 값만

%		if isempty(lBnew),	break;	end;				% 신규 bad idx 없음

		lBadPart		=	[ lBadPart lBnew ];			% 신규를 기존에 추가
		lZvalue			=	[ lZvalue Zbad ];			% bad의 Z 값 추가
%		unique(lBadPart);								% 중복제거	%-]
		%% 다음은 bad 채널 interpolation ------------------------------	%-[
%{
	% bad채널 수동입력 방식: seperated discription for each indivisual : %-[
	%	ex: { 'su02', { 'PO10', 'P7', ... } },
	BadIndex			=	find(ismember(cBadChan(:,1), subname{subnumb}));
							% subject 단위 find 므로, 반드시 1개의 값 or not
	sBadChan			=	cBadChan{BadIndex,2};			% 2nd 에 있는 값
%		if ~empty( lBadPart(s, d, t) ),	%if interpolation target exist.
%		if length( lBadPart ) ~= 0,	%if interpolation target exist.
	if BadIndex ~= 0 && ~isempty(sBadChan)	% subj 찾고, bad 도 있을 때만
%			[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % construct a eeglab dataset
%			[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEEG, EEG);
%			BadChan			=	find( ismember(channame, lBadPart) );	%idx확보
		fprintf('\nDetect  : interp channel(%s)\n', strjoin(sBadChan,', '));
		lBadPart		=	find(ismember(channame, sBadChan));	%idx로 변환

		EEG				=	eeg_emptyset();
		%20151005B.반드시 ced 에 항목이 빈 채널이 없도록 정확히 정보 구성!
		%이슈: 항목이 비어 있는 채널(EEG_32chan.ced의 EOG, NULL 등)이
		%		있을 경우, eeg_interp 가 오동작 혹은 오류를 유발함!
		%-> 그래서 반드시 cedPATH{2} 번을 사용할 것!!
%		EEG.chanlocs	=	'EEG_32chan.ced';
%		EEG.chanlocs	=	pop_chanedit(EEG.chanlocs, 'load',			...
%							{'EEG_32chan.ced', 'filetype', 'autodetect'});
%		EEG.chanlocs	=	readlocs('EEG_32chan.ced','filetype','chanedit');
		EEG.chanlocs	=	readlocs(cedPATH{2}, 'filetype','chanedit');
		EEG.nbchan		=	32;	%length(channame);
		EEG.trials		=	1;
		EEG.times		=	0:1:size(Potn2D,2);	%time 정보 설정
		EEG.pnts		=	EEG.times;						%point 도 같게.

		for f = 1 : size(Potn2D,1)%각 주파수별로 ch*t 데이터 interp
			%EEGlab dataset 구조 = ch * time -> 따라서 TF 데이터 구조 변경
%			EEG.data = double(shiftdim(squeeze(Potn2D(f,:,:)),1));
			EEG.data	=	squeeze(Potn2D(f,:,:));% time * ch
			EEG.data	=	double(shiftdim(EEG.data, 1));	% ch * time

%			method		=	'spacetime';	%griddata3 사용함->matlab제공 X
											%->별도 함수 %구성:griddata3ev
			method		=	'spherical';
			EEG			=	eeg_interp(EEG, lBadPart, method);

			Potn2D(f,:,:)	=	single(shiftdim(EEG.data, 1));
		end	%for
	end	%if	%-]
%}
		% Using above bad info, work the interp
		%	ex: lBadPart = [ 12, 25, ... ]
		if isempty(lBadPart),	break;	end;			% bad idx 값 없음
		fprintf('\nTuning  : Step(%d) Bad channel interpolation\n', nTune);

		% lBadPart에 값이 있으면 interp 수행
		sBadChan		=	channame( lBadPart );
		fprintf('Detect  : interp channel(%s)\n', strjoin(sBadChan,', '));

		EEG				=	eeg_emptyset();
		%20151005B.반드시 ced 에 항목이 빈 채널이 없도록 정확히 정보 구성!
		%이슈: 항목이 비어 있는 채널(EEG_32chan.ced의 EOG, NULL 등)이
		%		있을 경우, eeg_interp 가 오동작 혹은 오류를 유발함!
		EEG.chanlocs	=	readlocs(cedPATH{2}, 'filetype','chanedit');
		EEG.nbchan		=	32;	%length(channame);
		EEG.trials		=	1;
		EEG.times		=	0:1:size(Potn2D,2);			%time 정보 설정
		EEG.pnts		=	EEG.times;					%point 도 같게.

		%EEGlab dataset 구조 = ch * time -> 따라서 TF 데이터 구조 변경
%		EEG.data = double(shiftdim(squeeze(Potn2D(f,:,:)),1));
%		EEG.data		=	squeeze(Potn2D);				% time * ch
%		EEG.data		=	double(shiftdim(EEG.data, 1));	% ch * time
		EEG.data		=	double(shiftdim(Potn2D, 1));	% ch * time

%		method			=	'spacetime';	%griddata3 사용함->matlab제공 X
											%->별도 함수 %구성:griddata3ev
		method			=	'spherical';
		EEG				=	eeg_interp(EEG, lBadPart, method);

		Potn2D			=	single(shiftdim(EEG.data, 1));

		lBadChan		=	[ lBadChan lBadPart ];		% 모두 저장
		nTune			=	nTune + 1;					% 카운트 계수
	end	%while

	if ~isempty(lBadChan)
		fprintf('Tuning  : Finish. %d of Bad Ch(%s). during %d step.\n',...
		length(lBadChan), strjoin({channame{lBadChan}},', '), nTune-1); toc;
	end

		lGoodChan		=	1:length(channame);
		lGoodChan		=	lGoodChan(find(~ismember(lGoodChan, lBadChan)));

		Potential2D		=	Potn2D;

	return
