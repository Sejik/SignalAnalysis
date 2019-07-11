% S_importDat ver 0.2
% - Loading Experimental Info in VMRK file
%
% Usage: [VMRK] = S_importVHDR(fullPATH, marker_length)
%	MarkerLength = 1, 2, 3 자리 명시
%	-> ex) 'S112' -> 3, 'S12' -> 2
%
% first created by tigoum 2016/01/01
% last  updated by tigoum 2016/01/10

function	[ VMRK ] = S_importVMRK(fullPATH, MarkerLength)	%-[

	% MarkerLength = 1, 2, 3 자리 명시
	if nargin < 2, MarkerLength = 3; end					% 없으면 3자리로

%{
	Vmrk 데이터 구조	%-[
1:Brain Vision Data Exchange Marker File, Version 2.0
2:; Data created from history path: SSVEP_NEW_su0001_01/Raw Data/Edit Markers Dummy/Condi_BottomUp
3:; The channel numbers are related to the channels in the exported file.
4:
5:[Common Infos]
6:Codepage=UTF-8
7:DataFile=SSVEP_NEW_su0001_01_Condi_BottomUp.dat
8:
9:[Marker Infos]
10:; Each entry: Mk<Marker number>=<Type>,<Description>,<Position in data points>,
11:; <Size in data points>, <Channel number (0 = marker is related to all channels)>,
12:; <Date (YYYYMMDDhhmmssuuuuuu)>, Visible
13:; Fields are delimited by commas, some fields may be omitted (empty).
14:; Commas in type or description text are coded as "\1".
15:Mk1=New Segment,,1,1,0,20151015193407859401
16:Mk2=Time 0,,1,1,0
17:Mk3=Stimulus,S131,1,1,0
18:Mk4=New Segment,,2501,1,0,20151015193414943401
19:Mk5=Stimulus,S131,2501,1,0
20:Mk6=Time 0,,2501,1,0
21:Mk7=New Segment,,5001,1,0,20151015193422025401
22:Mk8=Time 0,,5001,1,0
23:Mk9=Stimulus,S132,5001,1,0
24:Mk10=Stimulus,S132,7501,1,0
25:Mk11=Time 0,,7501,1,0
26:Mk12=New Segment,,7501,1,0,20151015193429241401
27:Mk13=Time 0,,10001,1,0
28:Mk14=New Segment,,10001,1,0,20151015193436475401
29:Mk15=Stimulus,S133,10001,1,0
30:Mk16=Time 0,,12501,1,0
31:Mk17=New Segment,,12501,1,0,20151015193443809401
32:Mk18=Stimulus,S133,12501,1,0
33:
34:[Marker User Infos]
35:; Each entry: Prop<Number>=Mk<Marker number>,<Type>,<Name>,<Value>,<Value2>,...,<ValueN>
36:; Property number must be unique. Types can be int, single, string, bool, byte, double, uint
37:; or arrays of those, indicated int-array etc
38:; Array types have more than one value, number of values determines size of array.
39:; Fields are delimited by commas, commas in strings are written \1
40:; Properties are assigned to markers using their marker number.	%-]
%}

	fVmrk		=	regexprep(fullPATH, '.[A-Za-z]*$', '.vmrk');
	eval(['Fp	=	fopen(''' fVmrk ''',''r'');']);
	if Fp < 0, ChanList = []; SDP = 0; fSmpl = 0; return; end
	lVmrk		=	textscan(Fp, '%s', 'delimiter', '');	% cell array
	%white-space를 문자열의 일부로 인식하도록 delimiter  설정함
	fclose(Fp);
%	lVmrk		=	fgetl(Fp);

	% 라인 단위로 분리 한 후, 아래와 같이 각 라인별 탐색하여:
	% Mk25=Stimulus,S133,10001,1,0
	% 인 경우에만 각 토큰을 분리, 추출해서 trigger code와 time point를 확보.
	lVmrk		=	char(lVmrk{1});							% 2D: line x string

	% first, read the 'Time 0' mk. It is important base for valid marker
	% 20160305A. append the checking for TIME mark
		TIME	=	[];
		ixMrk	=	1;
	for m = 1 : size(lVmrk, 1)
		if ~strncmp(lVmrk(m, :), 'Mk', 2),	continue; end;	% Mk 로 시작할 것

		Mrk		=	strsplit(lVmrk(m,:),	'=');			% 토큰분리
		Mrk		=	strsplit(char(Mrk(2)),	',');			% 다시 분리

		if ~strcmp(Mrk(1), 'Time 0'),		continue; end;	% Time 0 mark 인가?

%		TIME(ixMrk)	=	str2num(Mrk{3});					% time point
		%% CAUTION: 'Time 0,,1001,1,0' -> (split) -> 'Time 0' '1001' '1' '0'
		%% ',,' is removed!
		TIME(ixMrk)	=	str2num(Mrk{2});					% time point

		ixMrk	=	ixMrk + 1;
	end

	% second, collect vaild marker to consist with TIME{}
		VMRK	=	{;};
		ixMrk	=	1;
	for m = 1 : size(lVmrk, 1)
		if ~strncmp(lVmrk(m, :), 'Mk', 2),	continue; end;	% Mk 로 시작할 것

		Mrk		=	strsplit(lVmrk(m,:),	'=');			% 토큰분리
		Mrk		=	strsplit(char(Mrk(2)),	',');			% 다시 분리

		if ~strcmp(Mrk(1), 'Stimulus'),		continue; end;	% stimulus 인가?

		% 자릿수가 일치하는 trigger 코드만 추출
%		if str2num(Mrk{2}(2:end)) < eval( [ '1e+' num2str(MarkerLength-1) ] )
		if length(num2str(str2num(Mrk{2}(2:end)))) ~= MarkerLength, continue; end

		% recording when time point consist with TIME{}
		TP			=	str2num(Mrk{3});					% TP point
		if ~ismember(TIME, TP),				continue; end	% not match !

		VMRK{ixMrk,1}	=	Mrk{2}(1);						% 'S' or 'R'
		VMRK{ixMrk,2}	=	str2num(Mrk{2}(2:end));			% trigger code
		VMRK{ixMrk,3}	=	TP;								% TP point

		ixMrk	=	ixMrk + 1;

	end	%for

%	clear			lVmrk Fp SpI	%-]

