function [new_gamma2 options] = L_Elec2BAproc(EEG,hEEG, ROI, StartPoint,FinishPoint)

	% Default sampling rate is 400 Hz
	if nargin < 2, error('parameter not enough'); end
	if nargin < 3, ROI			=	load(fullfile(hEEG.RoiDir,hEEG.RoiName)); end
	if nargin < 4, StartPoint	=	1; end
	if nargin < 5, FinishPoint	=	size(EEG.data,2); end

%	sForm				=	[ '%' num2str(length( num2str(EEG.points) )) 'd' ];
%	sForm				=	[ '%' num2str( floor(log10(EEG.points))+1 ) 'd' ];
	sForm				=	S_form4len( EEG.points );
	DstDir				=	fullfile(hEEG.PATH, hEEG.DstDir);	% log 저장 위치
	stdout				=	1;

	%Multiply			=	1;
	%POOL				=	S06paraOpen_AmH(false, 4);	% 강제로 core 4개
	%POOL				=	S_paraOpen(true);			% 강제로 restart
	POOL				=	S_paraOpen();
	%NumWorkers			=	POOL.NumWorkers* Multiply;	% 병렬화 배수
	%NumWorkers			=	20* Multiply;				% 병렬화 배수

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
	DstDir				=	fullfile(hEEG.PATH, hEEG.DstDir);	% log 저장 위치
	stdout				=	1;

%	POOL				=	S_paraOpen(true);		% 강제로 restart
	POOL				=	S_paraOpen();			% 알아서 restart

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
	model.neighbors		=	load('neighbors.mat');		% 기 정의된 값

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

	%% 20160706C. EEG.data 에 대한 절대 index 방식 -> 상대 index 방식 계산 변경!
	% StartTp 는 사용자의 선택에 의해, 1 혹은 더 큰 값이 될 수 있다.
	% 그런데, 최종 출력이 담긴 array 는 index 1 부터 값을 담아도 된다.
	%% 따라서, loop 에 적용되는 중간 변수들이 index 가 1 부터 시작할 수 있도록
	% EEG.data 에서 실제 적용되는 범위만 추출하여 사용하자.
	nROI				=	length(ROI.labels);
	WorkTp				=	StartTp;				% 작업시작 epoch 지점
	nTP					=	FinishTp -StartTp +1;	% 처리할 총 tp 수
	% 기존 cell 방식 저장을 지양(parfor 내부에서 data alloc 하는 문제 해소)
	% 대신, 전체 데이터 블럭 사전 생성 후 처리, '1' 로 채우면 처리된 데이터와
	% 아직 안된 데이터 영역의 구분이 용이함.
	% -> sparse matrix 를 사용하는 방법도 고려
%	SrcROI				=	cell(1, nTP);			% compute ROI time series
%	SrcROI				=	ones(nROI, nTP);		% compute ROI time series
	% --------------------------------------------------
	%% 20160320A. 계산도중 병렬코어 중 stall 되는 core로 작업 hold 상태 유발
	%	원인: 불명, 아마도 60000개(PFC_64)에 달하는 epoch을 처리하는 과정
	%		에서 모종의 resource deadlock 발생 가능성 추측.
	%	대응: 수행과정의 매 10% 마다 checkpoint log 기록
	%		새로 실행시 log 기록에 의해 마지막 수행기록 시점을 load하여
	%		그 시점부터 재개(rollback) -> 매번 처음부터 다시시작 문제 대응
	if exist(fullfile(DstDir, [EEG.name '_cplog.mat']))% cplog존재!
		fprintf('[Detect]   : checkpoint log data ! & analyzing...\n');
		load(fullfile(DstDir, [EEG.name '_cplog']));
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), SrcROI)));
		
		% 읽었으면 조사해보자.
		if strcmp(sFILE,EEG.name) & nROI == length(ROI.labels) &			...
			nTP == FinishTp -StartTp +1 & length(SrcROI) == nTP &			...
			nCalcData == WorkEnd
%			length(find(cellfun(@(x)(~isempty(x)), SrcROI))) == work-StartTp+1	
			WorkTp		=	WorkEnd + StartTp;			% rollback & restart 시점
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		elseif nCalcData ==		...		% 처음부터 연속된 data면 살려보자
			length(find(cellfun(@(x)(~isempty(x)), SrcROI(1:nCalcData))))
			WorkTp		=	nCalcData + StartTp;
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		else
			fprintf('[Sorry]    : inconsist current metadata, so NEW Start\n');
		end
		clear sFILE;
	end

	if ~exist('SrcROI', 'var'), SrcROI = cell(1,nTP); end	% log 실패면 신규
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706A. 가변길이 cell 에 대한 loop 대체용 matrix 연산 방법 개발
	%% version 3: 아래 parfor의 (기존 방식) 2중 loop 모두 제거!
		ixRV			=	ROI.vertices;				% (n, 1) 구조: col 방향-[
		ixLen			=	cellfun(@length, ixRV)';	%% 개별 길이 vector
		MX_RV			=	max(cellfun(@length, ixRV));
		ixRV			=	cellfun(@(x) {[x' zeros(1,MX_RV-length(x))]}, ixRV);
		ixRV			=	cell2mat(ixRV');			% col 배열화해야 정상변환
		ixZR			=	find(ixRV == 0);			% '0'위치 확보(나중 조처)
		ixRV(ixZR)		=	1;							% idx 므로 최소값은 1

		%% model(기정의 값)에 있는 neighbor의 index 와 weight (가변길이)를
		% 추출하여 고정길이로 변환하자 -> matrix 연산을 위한 사전준비
		% 가변길이이므로, 가장 긴 배열길이 맞춰 tail part는 zero/one padding 하자
		%
		% 단, model 에서 추출하는 idx는 tikhonov()에서 획득한 cortex source
		% 좌표값에 대한 index 로 사용되므로, 0 값이 index 로 쓰일 수 없으므로
		% one padding을 해야 한다.
		%% 반면, weight 는 index 가 아니며, 바로 연산(matrix product)에 적용
		% 되므로, 각 성분의 곱셈시, 값으로 포함되지 않도록 0 을 설정해야 함.
		% 즉, zero padding 하면 된다.
		%
		%% 또한, 이렇게 구한 index 는 scalp 데이터에 대해 독립적인 fixed 값
		% 이므로, 연산 loop 밖에서 미리 구해두고 loop 내부에서는 사용만 함!
		Weight			=	model.neighbors.neighbors.weight(ixRV);
		MXLEN			=	max(cellfun(@length, Weight(:)));	% only 1 max
		Weight			=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
		Weight			=	cell2mat(Weight);			% 주의! -> roi_ix*vxl
		Weight			=	reshape(Weight, nROI, MXLEN, MX_RV);% roi * ix * vxl
		Weight			=	permute(Weight, [ 1 3 2 ]);			% roi * vxl * ix
		Weight			=	reshape(Weight, [], MXLEN);			% roi_vxl * ix
		Weight(ixZR,:)	=	0;							% set to '0' by ixRV
		Weight			=	reshape(Weight, nROI, MX_RV, []); % roi * vxl * ix

		ixMdl			=	model.neighbors.neighbors.idx(ixRV); % 가변길이 cell
		MXLEN			=	max(cellfun(@length, ixMdl(:)));
		ixMdl			=	cellfun(@(x) {[x'  ones(1,MXLEN-length(x))]}, ixMdl);
		ixMdl			=	cell2mat(ixMdl);			% roi*vxl*ix->roi_ix*vxl
		ixMdl			=	reshape(ixMdl, nROI, MXLEN, MX_RV);	% roi * ix * vxl
		ixMdl			=	permute(ixMdl, [ 1 3 2 ]);			% roi * vxl * ix
		% the end of common code (fixed/non-vary index)	%-]
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706B. 아래 parfor 가 for 보다 느린 이유 규명!
	% 단일 변수: EEG.data 에 대해서 동시에 여러 프로세스가 접근 함에 따른
	% 상호배제 제어에 의한 overhead 임!
	% 따라서, 데이터를 tp 단위로 모두 쪼개어 cell 에 저장하자.
%		electrodesV		=	EEG.data(options.vidx, ix +WorkStart -1); % ch x tp
	% 단, 실제 계산에 사용될 데이터만 추출해서 적용하자: ch x tp(*ep) -> tp{ch}
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
		WorkStart		=	work -StartTp +1;		% ix 가 1부터 시작하게!
		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
		% 이 경우, workend 가 numworker의 배수가 아니면, 끝에 모자란 부분 감안

		% 진행 경과 판독 및 출력
		fprintf(stdout,['+ %s : COMPUTE time series for [' sForm ':' sForm ']'...
' / %d = %6.3f%%\r'], 'Surrogation', WorkStart, WorkEnd, nSF, WorkEnd/nSF*100);

%		ParBLK			=	[WorkStart : WorkEnd];	% blk idx for parallel
		ParBLK			=	[1 : WorkEnd-WorkStart+1];	% 수행횟수가 중요할 뿐
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
		%% 20160320A. 이슈에 의해 구성된 log 저장 기능
		if nTP >= 1000 & mod( round(WorkEnd / nTP * 100, 2), hEEG.CPgap) == 0
		% epoch 수가 1000 개 이상일 때 cp 기능 수행: 소수 2자리 버림: 5% 확정
			if not(exist(DstDir, 'dir')), mkdir(DstDir); end	% 없으면 생성

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

