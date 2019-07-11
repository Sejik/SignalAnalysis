function [ Potential2D lGoodChan lBadChan lZvalue ]	=						...
			AmHlib_FindBad_ChInterp(Potn2D, tWin, SDthre)
	% Potn2D ����: t x ch
	% tWin : time window
	% SDthre: threshold for SD

	% Potential2D : interpolation ó�� �� Potn2D
	% lGoodChan	: Z < 3SD �� ���� ä��
	% lBadChan	: Z > 3SD �� ������ ä��
	% lZvalue	: Bad ä�κ� Z ��
	% nTune		: Bad ä�� Ž�� loop Ƚ��(BadŽ�� �� interp, -> �ٽ� �ݺ�)

	if nargin<2, tWin = 1:size(Potn2D,1); end		% set time windows

[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
	idxRemCh	=	find( ~ismember(removech, channame));%deadä�θ�:parm����!

	%% 20151020A. �ڵ����� bad chan�� �ǵ��Ͽ� interp �����ϴ� �˰��� �ʿ�
	% bad chan�� �ǵ�: Ư�� time win���� �ٸ� ä�ε���� variation ���� ����
	%	stats model: normal distribution <- std normal dist�� ������ ����
	%										��, MLE �� ���غ��� �� ��?
	%	threshold: SD>3 �� ��
	%	object: channel data of Potential_Indi(:, twin, all ch)
	%		����, ������ ��ü ���ļ� �� t win ���� ������ ä�ε��� �񱳺м�
	% 1. ��ü �����Ϳ� ���ؼ� normal distribution�� ����Ѵ�.
	% 2. ��, �� ���ļ� ������ twin ������ ��� ä���� ���, SD ���� ��,
	% 3. Z = ( X-u ) / SD �� ����, P(Z<-1.96 U 1.96>Z) (95%, p<0.05) ��
	%	max�� ������ ä���� �ִ��� ��������.
	% 4. P(Z<-1.96 U 1.96>Z) �̸� �ǹǷ�, Z<-1.96 �̰ų� 1.96<Z �� Z�� ��
	%	��, ä�� max ���� X �̰�, �̸� ����ȭ �� Z �� ũ�⸦ �ǵ��ϸ� ��
	% 5. ���� 99% ������ �Ѵٸ� P(Z<-2.575 U 2.575<Z) �� �����ϸ� �ȴ�
	%	-> 90% �� P(Z<-1.645 U 1.645<Z) ��.
	%	-> �����԰� ������ �� ���, 99% �� �°�, 2.575 ������, ������ 3 ��
	% 6. bad ch�� �߰ߵǸ�, interp �� �� �ٽ� ������ �õ�
	%	-> �� �̻� bad �� ���ŵ� loop ����
		tic; nTune		=	1;							% calibrationī��Ʈ
		lBadChan		=	[];
		lZvalue			=	[];
	while true											% bad ch ���� ������
		%% ����, bad ä���� ã�� ------------------------------	%-[
		lBadPart		=	[];							% �� ���� �迭
		iBadCh			=	1;							% lBadPart�� �ε���

		[lmxCh imxCh]	=	max(Potn2D(tWin,:), [], 1);	% time
		lmxCh			=	squeeze(lmxCh)';			% 1D row ����
		% time ������ ���� max �������Ƿ�, ���� ���� 1D�� ä�κ� ��

		% �� ������ u, SD�� �������.
		MN_ch			=	mean(lmxCh);				% ä�κ� max���� ���
%		SD_ch			=	std(lmxCh) / sqrt(length(lmxCh)); % SD / sqrt(n)
		SD_ch			=	std(lmxCh);					% SD / sqrt(n)

		% ����ȭ ����
		Z				=	( lmxCh - MN_ch ) / SD_ch;	% Z== array
		lBad			=	find( SDthre<abs(Z) );		% SD>3 �� ��Ҹ�
		lBad			=	lBad(find(~ismember(lBad, idxRemCh)));	%live��
		lBnew			=	lBad(find(~ismember(lBad, lBadPart)))';	%�űԸ�
		Zbad			=	Z(lBnew)';					% SD>3 �� Z ����

%		if isempty(lBnew),	break;	end;				% �ű� bad idx ����

		lBadPart		=	[ lBadPart lBnew ];			% �űԸ� ������ �߰�
		lZvalue			=	[ lZvalue Zbad ];			% bad�� Z �� �߰�
%		unique(lBadPart);								% �ߺ�����	%-]
		%% ������ bad ä�� interpolation ------------------------------	%-[
%{
	% badä�� �����Է� ���: seperated discription for each indivisual : %-[
	%	ex: { 'su02', { 'PO10', 'P7', ... } },
	BadIndex			=	find(ismember(cBadChan(:,1), subname{subnumb}));
							% subject ���� find �Ƿ�, �ݵ�� 1���� �� or not
	sBadChan			=	cBadChan{BadIndex,2};			% 2nd �� �ִ� ��
%		if ~empty( lBadPart(s, d, t) ),	%if interpolation target exist.
%		if length( lBadPart ) ~= 0,	%if interpolation target exist.
	if BadIndex ~= 0 && ~isempty(sBadChan)	% subj ã��, bad �� ���� ����
%			[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % construct a eeglab dataset
%			[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEEG, EEG);
%			BadChan			=	find( ismember(channame, lBadPart) );	%idxȮ��
		fprintf('\nDetect  : interp channel(%s)\n', strjoin(sBadChan,', '));
		lBadPart		=	find(ismember(channame, sBadChan));	%idx�� ��ȯ

		EEG				=	eeg_emptyset();
		%20151005B.�ݵ�� ced �� �׸��� �� ä���� ������ ��Ȯ�� ���� ����!
		%�̽�: �׸��� ��� �ִ� ä��(EEG_32chan.ced�� EOG, NULL ��)��
		%		���� ���, eeg_interp �� ������ Ȥ�� ������ ������!
		%-> �׷��� �ݵ�� cedPATH{2} ���� ����� ��!!
%		EEG.chanlocs	=	'EEG_32chan.ced';
%		EEG.chanlocs	=	pop_chanedit(EEG.chanlocs, 'load',			...
%							{'EEG_32chan.ced', 'filetype', 'autodetect'});
%		EEG.chanlocs	=	readlocs('EEG_32chan.ced','filetype','chanedit');
		EEG.chanlocs	=	readlocs(cedPATH{2}, 'filetype','chanedit');
		EEG.nbchan		=	32;	%length(channame);
		EEG.trials		=	1;
		EEG.times		=	0:1:size(Potn2D,2);	%time ���� ����
		EEG.pnts		=	EEG.times;						%point �� ����.

		for f = 1 : size(Potn2D,1)%�� ���ļ����� ch*t ������ interp
			%EEGlab dataset ���� = ch * time -> ���� TF ������ ���� ����
%			EEG.data = double(shiftdim(squeeze(Potn2D(f,:,:)),1));
			EEG.data	=	squeeze(Potn2D(f,:,:));% time * ch
			EEG.data	=	double(shiftdim(EEG.data, 1));	% ch * time

%			method		=	'spacetime';	%griddata3 �����->matlab���� X
											%->���� �Լ� %����:griddata3ev
			method		=	'spherical';
			EEG			=	eeg_interp(EEG, lBadPart, method);

			Potn2D(f,:,:)	=	single(shiftdim(EEG.data, 1));
		end	%for
	end	%if	%-]
%}
		% Using above bad info, work the interp
		%	ex: lBadPart = [ 12, 25, ... ]
		if isempty(lBadPart),	break;	end;			% bad idx �� ����
		fprintf('\nTuning  : Step(%d) Bad channel interpolation\n', nTune);

		% lBadPart�� ���� ������ interp ����
		sBadChan		=	channame( lBadPart );
		fprintf('Detect  : interp channel(%s)\n', strjoin(sBadChan,', '));

		EEG				=	eeg_emptyset();
		%20151005B.�ݵ�� ced �� �׸��� �� ä���� ������ ��Ȯ�� ���� ����!
		%�̽�: �׸��� ��� �ִ� ä��(EEG_32chan.ced�� EOG, NULL ��)��
		%		���� ���, eeg_interp �� ������ Ȥ�� ������ ������!
		EEG.chanlocs	=	readlocs(cedPATH{2}, 'filetype','chanedit');
		EEG.nbchan		=	32;	%length(channame);
		EEG.trials		=	1;
		EEG.times		=	0:1:size(Potn2D,2);			%time ���� ����
		EEG.pnts		=	EEG.times;					%point �� ����.

		%EEGlab dataset ���� = ch * time -> ���� TF ������ ���� ����
%		EEG.data = double(shiftdim(squeeze(Potn2D(f,:,:)),1));
%		EEG.data		=	squeeze(Potn2D);				% time * ch
%		EEG.data		=	double(shiftdim(EEG.data, 1));	% ch * time
		EEG.data		=	double(shiftdim(Potn2D, 1));	% ch * time

%		method			=	'spacetime';	%griddata3 �����->matlab���� X
											%->���� �Լ� %����:griddata3ev
		method			=	'spherical';
		EEG				=	eeg_interp(EEG, lBadPart, method);

		Potn2D			=	single(shiftdim(EEG.data, 1));

		lBadChan		=	[ lBadChan lBadPart ];		% ��� ����
		nTune			=	nTune + 1;					% ī��Ʈ ���
	end	%while

	if ~isempty(lBadChan)
		fprintf('Tuning  : Finish. %d of Bad Ch(%s). during %d step.\n',...
		length(lBadChan), strjoin({channame{lBadChan}},', '), nTune-1); toc;
	end

		lGoodChan		=	1:length(channame);
		lGoodChan		=	lGoodChan(find(~ismember(lGoodChan, lBadChan)));

		Potential2D		=	Potn2D;

	return
