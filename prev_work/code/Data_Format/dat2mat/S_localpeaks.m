% S_localpeaks ver 0.30
%% 데이터(vector,matrix,array:다차원)에 대해 최대 peaks를 조사하여 리턴
%
% [*Input Parameter]--------------------------------------------------
%	data: support size == vector(1D), matrix(2D), -> now, NOT array(3D more)
%	op	: 'max' | 'min' | 'minmax' | 'maxmin' -> minmax == maxmin
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% edited by tigoum
% v0.10, 20160601A : created by tigoum
% v0.20, 20160601B : skip the flat peak
% v0.30, 20160628  : bug 해결, line 80의 XiF -> NiF 교정
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ PK IX PROM ]	=	S_localpeaks(data, op)
	if ndims(data)==2 & any(size(data)==1),	nDim = 1;		% 한쪽 차원 길이==1
	else,									nDim = ndims(data); end
	if strcmp(regexp(op, 'max', 'match'), 'max'),	fgMax	=	true;
	else,											fgMax	=	false;	end
	if strcmp(regexp(op, 'min', 'match'), 'min'),	fgMin	=	true;
	else,											fgMin	=	false;	end

	[MX MN PROM, lLIM, uLIM]=	deal([], [], 0, -1.0e-10, +1.0e-10);	% default

	if nDim == 2											% 2D는 신경써야 함
		[Hei Wid]	=	size(data);							% size

		% 다음 local max 구하기
		if fgMax
		cent		=	FastPeakFind(data);					% peak find
		[XiT XiF]	=	deal(cent(1:2:end), cent(2:2:end));	% x, y 분리
		len			=	length(cent)/2;						% x or y 길이
		if len >= 2,										% 2개 이상 발견
%{
%			dist	=	arrayfun(@(x) sqrt( (Wid/2-XiT(x))^2 +			...
%											(Hei/2-XiF(x))^2 ), [1:length(XiT)]);
			% 가로 & 세로 에 대한 2D 거리 계산 방식
			Wide	=	max(Hei, Wid);						% 더 큰 것 기준
			% scaling 비율 조정 @ Wid : Wide = XiT : X2T
			X2T		=	arrayfun(@(x) Wide*XiT(x) / Wid, [1:len]);	% scaling
			X2F		=	arrayfun(@(x) Wide*XiF(x) / Hei, [1:len]);	% scaling
			dist	=	arrayfun(@(x) sqrt( (Wide/2-X2T(x))^2 +			...
											(Wide/2-X2F(x))^2 ), [1:len]);
%}
			% 세로 기준 1D 거리 계산 방식
			dist	=	arrayfun(@(x) abs(Hei/2 - XiF(x)), [1:len]); % 세로축
			[~, Xi]	=	min(dist);							% 중심에서 최단 거리
			[XiT XiF]=	deal(XiT(Xi), XiF(Xi));				% 단 한개 선택
		end
		MX			=	data(XiF, XiT);

		if isempty(MX)										% search gmax
		[gMx gIx]	=	max(data, [], 1);
		gEdg		=	find(gIx==1 | gIx==Hei);			% filter edge (경계)
		gMx(gEdg)	=	lLIM;								% set limit low
		[MX XiT]	=	max(gMx);
		if MX == lLIM,	[MX XiF]=	deal([]);				% 모두 경계인 경우
		else			XiF		=	gIx(XiT);	end
%		fprintf('global %d %d %d\n', MX, XiF, XiT);
		end % if isempty
		end	% if max

		% 다음 local min 구하기
		if fgMin
		cent		=	FastPeakFind(-data);				% peak find
		[NiT NiF]	=	deal(cent(1:2:end), cent(2:2:end));	% x, y 분리
		len			=	length(cent)/2;						% x or y 길이
		if len >= 2,										% 2개 이상 발견
%{
%			dist	=	arrayfun(@(x) sqrt( (Wid/2-NiT(x))^2 +			...
%											(Hei/2-NiF(x))^2 ), [1:length(NiT)]);
			% 가로 & 세로 에 대한 2D 거리 계산 방식
			Wide	=	max(Hei, Wid);						% 더 큰 것 기준
			% scaling 비율 조정 @ Wid : Wide = XiT : X2T
			N2T		=	arrayfun(@(x) Wide*NiT(x) / Wid, [1:len]);	% scaling
			N2F		=	arrayfun(@(x) Wide*NiF(x) / Hei, [1:len]);	% scaling
			dist	=	arrayfun(@(x) sqrt( (Wide/2-N2T(x))^2 +			...
											(Wide/2-N2F(x))^2 ), [1:len]);
%}
			% 세로 기준 1D 거리 계산 방식
			dist	=	arrayfun(@(x) abs(Hei/2 - NiF(x)), [1:len]); % 세로축
			[~, Ni]	=	min(dist);							% 중심에서 최단 거리
			[NiT NiF]=	deal(NiT(Ni), NiF(Ni));				% 단 한개 선택
		end
		MN			=	data(NiF, NiT);

		if isempty(MN)										% search gmin
		[gMn gIx]	=	min(data, [], 1);
		gEdg		=	find(gIx==1 | gIx==Hei);			% filter edge
		gMn(gEdg)	=	uLIM;								% set limit high
		[MN NiT]	=	min(gMn);
		if MN == uLIM,	[MN NiF]=	deal([]);				% 모두 경계인 경우
		else			NiF		=	gIx(NiT);	end
		end % if isempty
		end	% if min

		% 20160406A. ! |local max|(==local min/max) 없다면? |global max| 를 구함
%		if isempty(MX) & isempty(MN)
%		if fgMax, MX=	max(data(:)); end					% global max
%		if fgMin, MN=	min(data(:)); end					% global min
%		PROM		=	0;									% gl: PROMinance 없음
%		end

		% local mx, mn 중 빈 것이 있으면 반대쪽 값 채택 고려
		if		fgMax & isempty(MN),	[ixF ixT PK]=deal(XiF,XiT,MX);%MxMn | Mx
		elseif	fgMin & isempty(MX),	[ixF ixT PK]=deal(NiF,NiT,MN);%MxMn | Mn
		elseif fgMax&fgMin&MX>=abs(MN),	[ixF ixT PK]=deal(XiF,XiT,MX);
		else,							[ixF ixT PK]=deal(NiF,NiT,MN); end%절대값

%		[ixF ixT]	=	ind2sub(size(data), find(data == PK));
		IX			=	[ ixF ixT ];

	elseif nDim == 1										% 1D 는 간단함
		if fgMax, MX=	max( findpeaks( data)); end			% local max
		if fgMin, MN=	min(-findpeaks(-data)); end			% local min

		% 20160406A. ! |local max|(==local min/max) 없다면? |global max| 를 구함
%		if isempty(MX) & isempty(MN)
%		if fgMax, MX=	max(data(:)); end					% global max
%		if fgMin, MN=	min(data(:)); end					% global min
%		PROM		=	0;									% gl: PROMinance 없음
%		end
		if fgMax & isempty(MX)										% search gmax
		[MX gIx]	=	max(data);
		if 1 < gIx & gIx < length(data), MX = []; end
		end % if isempty

		if fgMin & isempty(MN)										% search gmin
		[MN gIx]	=	min(data);
		if 1 < gIx & gIx < length(data), MN = []; end
		end % if isempty

		% local mx, mn 중 빈 것이 있으면 반대쪽 값 채택 고려
		if		fgMax & isempty(MN), PK = MX;				% MaxMin or Max
		elseif	fgMin & isempty(MX), PK = MN;				% MaxMin or Min
		elseif	fgMax & fgMin & MX>=abs(MN), PK=MX; else, PK=MN; end % 절대값

		if ~isempty(PK), IX = find(data == PK); else, IX = []; end
%{
		% FastPeakFind() 를 이용한 1D 데이터 추적 코드: 결과는 실패	%-[
		Hei			=	length(data);						% size

		% 다음 local max 구하기
		if fgMax
		cent		=	FastPeakFind(data);					% peak find
		[XiT XiF]	=	deal(cent(1:2:end), cent(2:2:end));	% x, y 분리
		len			=	length(cent)/2;						% x or y 길이
		if len >= 2,										% 2개 이상 발견
			% 세로 기준 1D 거리 계산 방식
			dist	=	arrayfun(@(x) abs(Hei/2 - XiF(x)), [1:len]); % 세로축
			[~, Xi]	=	min(dist);							% 중심에서 최단 거리
			[XiT XiF]=	deal(XiT(Xi), XiF(Xi));				% 단 한개 선택
		end
		MX			=	data(XiF, XiT);
		end	% if max

		% 다음 local min 구하기
		if fgMin
		cent		=	FastPeakFind(-data);				% peak find
		[NiT NiF]	=	deal(cent(1:2:end), cent(2:2:end));	% x, y 분리
		len			=	length(cent)/2;						% x or y 길이
		if len >= 2,										% 2개 이상 발견
			% 세로 기준 1D 거리 계산 방식
			dist	=	arrayfun(@(x) abs(Hei/2 - XiF(x)), [1:len]); % 세로축
			[~, Ni]	=	min(dist);							% 중심에서 최단 거리
			[NiT NiF]=	deal(NiT(Ni), NiF(Ni));				% 단 한개 선택
		end
		MN			=	data(NiF, NiT);
		end	% if max

		% local mx, mn 중 빈 것이 있으면 반대쪽 값 채택 고려
		if		fgMax & isempty(MN),	[ixT PK]=deal(XiT,MX);%MxMn | Mx
		elseif	fgMin & isempty(MX),	[ixT PK]=deal(NiT,MN);%MxMn | Mn
		elseif fgMax&fgMin&MX>=abs(MN),	[ixT PK]=deal(XiT,MX);
		else,							[ixT PK]=deal(NiT,MN); end%절대값

%		[ixF ixT]	=	ind2sub(size(data), find(data == PK));
		IX			=	[ ixF ixT ];	%-]
%}	
	else													% 3D 은 고민해 보자
		error('tftopo not support 3 or more dimension data for localmaxima');
	end

