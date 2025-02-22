% B_Eeg2Mat v0.10
%%	변환기: brain vision recoder (*.eeg) to mat format
% 
%------------------------------------------------------
% first created at 2016/06/18
% last  updated at 2016/06/21
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.10 : 가장 기본 뼈대 작성
%------------------------------------------------------

% header
PATH			=	'New';
%lRead			=	{ 'su01', };
lRead			=	arrayfun(@(x) {sprintf('su%02d',x)}, [1:6]);
nClass			=	6;
nEpoch			=	4 * 10;

%% defined only 20160621/Forensic_Min3.mxs on NeuroRT
ChRange			=	[... % BA : L,	BA : R		%<- included the number of voxel
					[	9	46	];	[	9	48	];	...
					[	24	26	];	[	24	27	];	...
					[	27	1	];	[	27	1	];	...
					[	29	7	];	[	29	8	];	...
					[	40	74	];	[	40	71	];	...
					[	41	7	];	[	41	3	];	...
					];
ChIX			=	arrayfun(@(x)sum(ChRange(1:x, 2)), [1:length(ChRange)]);%나열

% procedure
for sbj			=	lRead
	for cl		=	1:nClass
		Name	=	[PATH '/' char(sbj) '_class' num2str(cl)];

		fName	=	[Name '.vmrk'];
		eMRK	=	bva_readmarker(fName);
		eMRK	=	eMRK( :, mod(eMRK(1,:),10)==cl);		% filter for marker

		fName	=	[Name '.vhdr'];
		[eFS eCHN meta]	=	bva_readheader(fName);
		eEEG			=	bva_loadeeg(fName);
		% dim: 338x100000
		%	338 == voxel of ROIs
		%	100000 == 2500 x 40 == data point x epoch

		%% spliting voxel 나열을 각 BA가 포함하는 voxel 크기별로 분리
%{
		eBA		=	arrayfun(@(x,y) {eEEG([x+1:y],:)},				...   % go 1
									[0 ChIX([1:end-1])], ChIX([1:end]) ); % go 0
		eBA		=	cellfun(@(x) {mean(x, 1)}, eBA);
		eBA		=	cell2mat(eBA');
		eEG		=	reshape(eBA, length(ChRange), [], nEpoch);
%}
		eBA		=	arrayfun(@(x,y) {mean(eEEG([x+1:y],:),1)},		...   % go 1
									[0 ChIX([1:end-1])], ChIX([1:end]) ); % go 0
		eEEG	=	reshape(cell2mat(eBA'), length(ChRange), [], nEpoch);
%		isequal(eEEG, eEG)
		eCHN	=	arrayfun(@(x,y) {sprintf('BA%02d %s',x,char(y))},		...
						ChRange(:,1)', repmat({'L','R'}, 1, length(ChRange)/2) );

		oName	=	[Name '.mat'];
		save(oName, 'eEEG', 'eMRK', 'eCHN', 'eFS', '-v7.3');
	end	% for class
end		% for sbj

