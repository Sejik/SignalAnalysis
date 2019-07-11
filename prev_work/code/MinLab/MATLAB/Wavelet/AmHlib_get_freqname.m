%%===============================================================================
function [ FreqName ] = AmHlib_get_freqname(f)	%벡터 경우 vs cell array 경우 구분!
% detect band of array f, and return band name
	% 먼저 타입을 검사하여 처리방법을 결정함
	if isfloat(f)
		FreqName			=	AmHlib_get_freqname_vector(f);

	elseif iscell(f)
		FreqName			=	f;			%f와 같은 규격

		for ff = 1 : length(f)
			FreqName{ff}	=	AmHlib_get_freqname_vector(f{ff});
		end
	end

function [FreqName] = AmHlib_get_freqname_vector(f)
	if		0< f(1) && f(end)<= 4,	FreqName	=	'delta';
	elseif	4<=f(1) && f(end)<= 8,	FreqName	=	'theta';
	elseif	8<=f(1) && f(end)<=13,	FreqName	=	'alpha';
	elseif 13<=f(1) && f(end)<=30,	FreqName	=	'beta';
	elseif 30<=f(1) && f(end)<=50,	FreqName	=	'gamma';
	elseif  0< f(1) && f(end)<=50,	FreqName	=	'whole';
	else,							FreqName	=	'unknonw';
	end

