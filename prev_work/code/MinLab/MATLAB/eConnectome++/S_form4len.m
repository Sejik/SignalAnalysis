%% -----------------------------------------------------------------------------
% This is local function
%...............................................................................
%
%	input :
%		scalar	: any scalar
%
%	output:
%		strForm	: string form , ex) '%04d'
%
function [ strForm ] = S_form4len( scalar, zero )
	if nargin < 2, zero = false; end
	if zero, ZERO = '0'; else ZERO = ''; end			% '%02d' or '%2d'

	strForm			=	[ '%' ZERO num2str( floor(log10(scalar))+1 ) 'd' ];

