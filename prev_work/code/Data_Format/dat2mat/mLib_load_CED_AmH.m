%function [ ch_num ] = ChConv_Name2Number(channame, CED)
function [ number labels ]	=	mLib_load_CED_AmH(CED);	% CED ���� chan ��� ����
% Number	labels	type	theta	radius	X	Y	Z	sph_theta	sph_phi	sph_radius	urchan	ref	datachan	
%% CED ������ �о ä�������� ������.
	% CED	: topo�� ���� CED ���� path, [ ������ | ����� | ���ϸ� only ]
	%		ex) ���ϸ� ǥ��� Ž������: ./ , ~minlab/Tools/MATLAB/

	%% Loading Experimental Info in VHDR file
		%�׷��� [Common Infos]�� nCH, SpI, SDP ���� ��
		%SpI : ���ø� ����(sampling rate�� ����), �ð������� uS
		%SDP : epocking�� data��	= �ð�����/SpI(���� ��ġ ���)
		%EpTm: epocking�� �ð�����	= SDP * SpI(������ġ���)
		%Smpl: ���ø���				= 1 / SpI
%	fVhdr		=	regexprep(fullPATH, '.[A-Za-z]*$', '.vhdr');
	eval(['Fp	=	fopen(''' CED ''',''r'');']);
%	if Fp < 0, ChanList = []; SDP = 0; fSmpl = 0; return; end
	lCED		=	textscan(Fp, '%s', 'delimiter', '\n');	%cell array
	%white-space�� ���ڿ��� �Ϻη� �ν��ϵ��� delimiter  ������
	fclose(Fp);

	% ���� ������ ���� ��, �� ���ο����� [tab] ������ ����
	Header		=	lCED{1}(1);
	lCED		=	lCED{1}(2:end);
	lChan		=	cellfun(@(x)({strsplit(x,'\t')}), lCED);	% cell�� array

	number		=	str2num(char(cellfun(@(x)( x(1) ), lChan)));
	labels		=	cellfun(@(x)( x(2) ), lChan);

	return

