function [new_gamma2 options] = L_Elec2BAproc(EEG,hEEG, ROI, StartPoint,FinishPoint)

	% Default sampling rate is 400 Hz
	if nargin < 2, error('parameter not enough'); end
	if nargin < 3, ROI			=	load(fullfile(hEEG.RoiDir,hEEG.RoiName)); end
	if nargin < 4, StartPoint	=	1; end
	if nargin < 5, FinishPoint	=	size(EEG.data,2); end

%	sForm				=	[ '%' num2str(length( num2str(EEG.points) )) 'd' ];
%	sForm				=	[ '%' num2str( floor(log10(EEG.points))+1 ) 'd' ];
	sForm				=	S_form4len( EEG.points );
	DstDir				=	fullfile(hEEG.PATH, hEEG.DstDir);	% log ���� ��ġ
	stdout				=	1;

	%Multiply			=	1;
	%POOL				=	S06paraOpen_AmH(false, 4);	% ������ core 4��
	%POOL				=	S_paraOpen(true);			% ������ restart
	POOL				=	S_paraOpen();
	%NumWorkers			=	POOL.NumWorkers* Multiply;	% ����ȭ ���
	%NumWorkers			=	20* Multiply;				% ����ȭ ���

	ts					=	EEG.data(:,1:2500)';	% tp x BA
	[fqLow fqHigh]		=	deal(hEEG.FreqWindow(1), hEEG.FreqWindow(2));
	p					=	1;
	eFS					=	EEG.srate;
	shufftimes			=	[];
	siglevel			=	[];

	% Number of shuffled datasets to create
	if isempty(shufftimes),	nSF		= 1000; else nSF	= shufftimes; end
	if isempty(siglevel),	tvalue	= 0.05; else tvalue	= siglevel; end

	% --------------------------------------------------
	sForm				=	[ '%' num2str( floor(log10(nSF))+1 ) 'd' ];
	DstDir				=	fullfile(hEEG.PATH, hEEG.DstDir);	% log ���� ��ġ
	stdout				=	1;

%	POOL				=	S_paraOpen(true);		% ������ restart
	POOL				=	S_paraOpen();			% �˾Ƽ� restart

	% --------------------------------------------------
	% pop_sourceloc(EEG);
	fprintf('construct model for BEM / transfer eeg data to BEM matrix.\n'); %-[

	% basic varible
	model.italyskin		=	load('italyskin.mat');
	model.cutskin		=	load('cutskin.mat');
	model.italyskinxy	=	load('italyskin-in-xy.mat');
	model.italyskinxyz	=	load('italyskin-in-xyz.mat');
	model.colinbemskin	=	load('colinbemskin.mat');
	model.cortex		=	load('colincortex.mat');
	model.bemcortex		=	load('colinbemcortex.mat');
	model.neighbors		=	load('neighbors.mat');		% �� ���ǵ� ��

	transmatrix			=	load('LargeTransMatrix.mat'); % large transfer matrix for colin BEM skin and cortex 
	k					=	cell2mat({EEG.locations(EEG.vidx).colinbemskinidx});
	model.transmatrix	=	double(transmatrix.TransMatrix(k,:)); % get transfer matrix for the electrodes
	[model.U, model.s, model.V]	=	csvd(model.transmatrix);
	[model.U, model.s, model.V]	=	deal(double(model.U), double(model.s),	...
										double(model.V));

	% get electrode positions, labels and indices on the italyskin.
	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	model.k				=	cell2mat({EEG.locations(EEG.vidx).italyskinidx});
	model.electrodes.labels	=	EEG.labels(EEG.vidx);
	model.electrodes.locations= model.italyskin.italyskin.Vertices(model.k,:);
	model.X				=	model.italyskinxy.xy(model.k,1);
			% standard xy coordinates relative to electrodes on the skin
	model.Y				=	model.italyskinxy.xy(model.k,2);   
	zmin				=	min(model.italyskinxyz.xyz(model.k,3));
	Z					=	model.italyskinxyz.xyz(:,3);
	model.interpk		=	find(Z > zmin);		% focus interpolated vertices
	model.XI			=	model.italyskinxy.xy(model.interpk,1);
	model.YI			=	model.italyskinxy.xy(model.interpk,2);		%-]

	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	options.step			=	round(EEG.points/10);	% -[
	if options.step <= 0, options.step=	2; end
	options.vidx			=	EEG.vidx;
	options.currentpoint	=	1;
	options.auto			=	0;
	options.method			=	'mn';
	options.lamda			=	274.082947;
	options.autocorner		=	1;
	options.threshold		=	0.0;
	options.HWHM			=	3;
%	options.startepoch		=	156;					% startepoch;
%	options.endepoch		=	468;					% endepoch;
%	options.endepoch		=	156+10000;				% endepoch;
	options.startepoch		=	StartPoint;				% startepoch;
	options.endepoch		=	FinishPoint;			% endepoch;
	options.alpha			=	1;
	options.cutskin			=	0;
	options.labels			=	0;
	options.electrodes		=	0;
	options.sensorcaxis		=	'local';
	options.sensorminmax	=	[EEG.min, EEG.max];
	options.sourcecaxis		=	'local';
	options.sourceminmax	=	[realmax, realmin];
	options.usebem			=	0;
	options.currymatrix		=	0;						%-]

	% --------------------------------------------------
	[StartTp, FinishTp]	=	deal(options.startepoch, options.endepoch);
	fprintf('Localizing epoch [%d:%d] on [Electrode] to [Brodmann] level.\n', ...
			StartTp, FinishTp);

	%% 20160706C. EEG.data �� ���� ���� index ��� -> ��� index ��� ��� ����!
	% StartTp �� ������� ���ÿ� ����, 1 Ȥ�� �� ū ���� �� �� �ִ�.
	% �׷���, ���� ����� ��� array �� index 1 ���� ���� ��Ƶ� �ȴ�.
	%% ����, loop �� ����Ǵ� �߰� �������� index �� 1 ���� ������ �� �ֵ���
	% EEG.data ���� ���� ����Ǵ� ������ �����Ͽ� �������.
	nROI				=	length(ROI.labels);
	WorkTp				=	StartTp;				% �۾����� epoch ����
	nTP					=	FinishTp -StartTp +1;	% ó���� �� tp ��
	% ���� cell ��� ������ ����(parfor ���ο��� data alloc �ϴ� ���� �ؼ�)
	% ���, ��ü ������ ���� ���� ���� �� ó��, '1' �� ä��� ó���� �����Ϳ�
	% ���� �ȵ� ������ ������ ������ ������.
	% -> sparse matrix �� ����ϴ� ����� ����
%	SrcROI				=	cell(1, nTP);			% compute ROI time series
%	SrcROI				=	ones(nROI, nTP);		% compute ROI time series
	% --------------------------------------------------
	%% 20160320A. ��굵�� �����ھ� �� stall �Ǵ� core�� �۾� hold ���� ����
	%	����: �Ҹ�, �Ƹ��� 60000��(PFC_64)�� ���ϴ� epoch�� ó���ϴ� ����
	%		���� ������ resource deadlock �߻� ���ɼ� ����.
	%	����: ��������� �� 10% ���� checkpoint log ���
	%		���� ����� log ��Ͽ� ���� ������ ������ ������ load�Ͽ�
	%		�� �������� �簳(rollback) -> �Ź� ó������ �ٽý��� ���� ����
	if exist(fullfile(DstDir, [EEG.name '_cplog.mat']))% cplog����!
		fprintf('[Detect]   : checkpoint log data ! & analyzing...\n');
		load(fullfile(DstDir, [EEG.name '_cplog']));
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), SrcROI)));
		
		% �о����� �����غ���.
		if strcmp(sFILE,EEG.name) & nROI == length(ROI.labels) &			...
			nTP == FinishTp -StartTp +1 & length(SrcROI) == nTP &			...
			nCalcData == WorkEnd
%			length(find(cellfun(@(x)(~isempty(x)), SrcROI))) == work-StartTp+1	
			WorkTp		=	WorkEnd + StartTp;			% rollback & restart ����
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		elseif nCalcData ==		...		% ó������ ���ӵ� data�� �������
			length(find(cellfun(@(x)(~isempty(x)), SrcROI(1:nCalcData))))
			WorkTp		=	nCalcData + StartTp;
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		else
			fprintf('[Sorry]    : inconsist current metadata, so NEW Start\n');
		end
		clear sFILE;
	end

	if ~exist('SrcROI', 'var'), SrcROI = cell(1,nTP); end	% log ���и� �ű�
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706A. �������� cell �� ���� loop ��ü�� matrix ���� ��� ����
	%% version 3: �Ʒ� parfor�� (���� ���) 2�� loop ��� ����!
		ixRV			=	ROI.vertices;				% (n, 1) ����: col ����-[
		ixLen			=	cellfun(@length, ixRV)';	%% ���� ���� vector
		MX_RV			=	max(cellfun(@length, ixRV));
		ixRV			=	cellfun(@(x) {[x' zeros(1,MX_RV-length(x))]}, ixRV);
		ixRV			=	cell2mat(ixRV');			% col �迭ȭ�ؾ� ����ȯ
		ixZR			=	find(ixRV == 0);			% '0'��ġ Ȯ��(���� ��ó)
		ixRV(ixZR)		=	1;							% idx �Ƿ� �ּҰ��� 1

		%% model(������ ��)�� �ִ� neighbor�� index �� weight (��������)��
		% �����Ͽ� �������̷� ��ȯ���� -> matrix ������ ���� �����غ�
		% ���������̹Ƿ�, ���� �� �迭���� ���� tail part�� zero/one padding ����
		%
		% ��, model ���� �����ϴ� idx�� tikhonov()���� ȹ���� cortex source
		% ��ǥ���� ���� index �� ���ǹǷ�, 0 ���� index �� ���� �� �����Ƿ�
		% one padding�� �ؾ� �Ѵ�.
		%% �ݸ�, weight �� index �� �ƴϸ�, �ٷ� ����(matrix product)�� ����
		% �ǹǷ�, �� ������ ������, ������ ���Ե��� �ʵ��� 0 �� �����ؾ� ��.
		% ��, zero padding �ϸ� �ȴ�.
		%
		%% ����, �̷��� ���� index �� scalp �����Ϳ� ���� �������� fixed ��
		% �̹Ƿ�, ���� loop �ۿ��� �̸� ���صΰ� loop ���ο����� ��븸 ��!
		Weight			=	model.neighbors.neighbors.weight(ixRV);
		MXLEN			=	max(cellfun(@length, Weight(:)));	% only 1 max
		Weight			=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
		Weight			=	cell2mat(Weight);			% ����! -> roi_ix*vxl
		Weight			=	reshape(Weight, nROI, MXLEN, MX_RV);% roi * ix * vxl
		Weight			=	permute(Weight, [ 1 3 2 ]);			% roi * vxl * ix
		Weight			=	reshape(Weight, [], MXLEN);			% roi_vxl * ix
		Weight(ixZR,:)	=	0;							% set to '0' by ixRV
		Weight			=	reshape(Weight, nROI, MX_RV, []); % roi * vxl * ix

		ixMdl			=	model.neighbors.neighbors.idx(ixRV); % �������� cell
		MXLEN			=	max(cellfun(@length, ixMdl(:)));
		ixMdl			=	cellfun(@(x) {[x'  ones(1,MXLEN-length(x))]}, ixMdl);
		ixMdl			=	cell2mat(ixMdl);			% roi*vxl*ix->roi_ix*vxl
		ixMdl			=	reshape(ixMdl, nROI, MXLEN, MX_RV);	% roi * ix * vxl
		ixMdl			=	permute(ixMdl, [ 1 3 2 ]);			% roi * vxl * ix
		% the end of common code (fixed/non-vary index)	%-]
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706B. �Ʒ� parfor �� for ���� ���� ���� �Ը�!
	% ���� ����: EEG.data �� ���ؼ� ���ÿ� ���� ���μ����� ���� �Կ� ����
	% ��ȣ���� ��� ���� overhead ��!
	% ����, �����͸� tp ������ ��� �ɰ��� cell �� ��������.
%		electrodesV		=	EEG.data(options.vidx, ix +WorkStart -1); % ch x tp
	% ��, ���� ��꿡 ���� �����͸� �����ؼ� ��������: ch x tp(*ep) -> tp{ch}
%	cEEG				=	mat2cell(	EEG.data(:, StartTp:FinishTp),	...
%										size(EEG.data,1), ones(1,nTP) );
	cEEG				=	EEG.data(:, StartTp:FinishTp);
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	% Number of frequencies
	f					=	[fqLow:1:fqHigh];
	nFQ					=	length(f);

	% Number of channels in the time series
%	nROI					=	size(ts,2);				%% tp x BA
	nROI					=	nROI;					%% tp x BA

	sig_size			=	floor(tvalue * nSF)+1;
%	new_gamma			=	zeros(sig_size-1,nROI,nROI,nFQ);
	new_gamma			=	zeros(sig_size-1,nROI,nROI,nFQ);

	for		work		=	[WorkTp		: POOL.NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;		% ix �� 1���� �����ϰ�!
		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
		% �� ���, workend �� numworker�� ����� �ƴϸ�, ���� ���ڶ� �κ� ����

		% ���� ��� �ǵ� �� ���
		fprintf(stdout,['+ %s : COMPUTE time series for [' sForm ':' sForm ']'...
' / %d = %6.3f%%\r'], 'Surrogation', WorkStart, WorkEnd, nSF, WorkEnd/nSF*100);

%		ParBLK			=	[WorkStart : WorkEnd];	% blk idx for parallel
		ParBLK			=	[1 : WorkEnd-WorkStart+1];	% ����Ƚ���� �߿��� ��
		gamma2			=	zeros(length(ParBLK),nROI,nROI,nFQ);
		len				=	2500;
		cEEG			=	rand(nROI, len);
	parfor	ix			=	ParBLK
		% Generate a surrogate time series
%		newts			=	zeros(size(ts,1), nROI);	% pre allocation
		newts			=	zeros(len, nROI);	% pre allocation
		for jx=1:nROI
%			Y			=	fft(ts(:,jx));
			Y			=	fft(cEEG(jx,:)');
			Pyy			=	sqrt(Y.*conj(Y));
			Phyy		=	Y./Pyy;
			index		=	[1:size(ts,1)];
			index		=	surrogate(index);
			Y			=	Pyy.*Phyy(index);
			newts(:,jx)	=	real(ifft(Y));
		end

		% Compute the DTF value for each surrogate time series
		gamma2(ix,:,:,:)=	DTF4(newts, fqLow, fqHigh, p, eFS);
	end	% parfor concurrent
%________________________________________________________________________________
		%% 20160320A. �̽��� ���� ������ log ���� ���
		if nTP >= 1000 & mod( round(WorkEnd / nTP * 100, 2), hEEG.CPgap) == 0
		% epoch ���� 1000 �� �̻��� �� cp ��� ����: �Ҽ� 2�ڸ� ����: 5% Ȯ��
			if not(exist(DstDir, 'dir')), mkdir(DstDir); end	% ������ ����

			sFILE		=	EEG.name;
			save(fullfile(DstDir, [EEG.name '_cplog']),'sFILE', ...
				'nROI', 'nTP', 'WorkStart', 'WorkEnd', 'SrcROI');
			clear sFILE
		end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		% Save the surrogate DTF values
%{
		new_gamma(end+1:end+length(ParBLK),:,:,:)	=	gamma2;	% attach at tail

		% And, select top significant by ordering
		new_gamma						=	sort(new_gamma,'descend');

		% Remove non significant
		new_gamma(sig_size:end,:,:,:)	=	[];			% delete leasts data
%}
	end	% for work block
%end	% for single step

% take the surrogated DTF values at a certain signficance
%{
new_gamma2				=	zeros(nROI,nROI,nFQ);
for ix					=	1:nROI
	for jx				=	1:nROI
		for k			=	1:nFQ
			new_gamma2(ix,jx,k)		=	new_gamma(sig_size-1,ix,jx,k);
		end
	end
end
%}
new_gamma2				=	[];
options = [];
