function varargout = bva_readmarker(varargin)

%bva_readmarker - read Brain Vision Data Exchange Marker File
%
% function [trigger] = bva_readmarker(file)
%
% Read stimulus markers and corresponding timepoints
% from Brain Vision Marker File and return it to the caller.
% Needed to provide a mean of epochising continous EEG data.
%
% Input:
%	file = Brain Vision Data Exchange Marker File
%
% Output:
%	out(1,:) = stimulus symbol
%	out(2,:) = stimulus time in continous data
%
% requires: 
%
% If mutiple segments are present (eg. discontinous recording,
% breaks, etc) the output will be wrapped in a cell array. 
%
% see also: ERRP/io
%

% Copyright (C) 2008-2012 Stefan Schinkel, HU Berlin
% http://people.physik.hu-berlin.de/~schinkel/
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% $Log$

%% debug settings
debug = 0;
if debug;warning('on','all');else warning('off','all');end

%% check number of input arguments
error(nargchk(0,1,nargin))

%% check number of out arguments
error(nargoutchk(0,2,nargout))					% must set 2 by tigoum

%% check && assign input
varargin{2} = [];

if ~isempty(varargin{1}),
	file = varargin{1};
else
	%use open dialog
   [filename, pathname] = uigetfile( {'*.vmrk'},  'Choose Marker File');

	if filename == 0
		error('ERRP:IO:bva_readmarker:NoMarkerFile','No Marker File Provided')
	else
		file = fullfile(pathname, filename);
	end
end

%open fp (for reading)
fid = fopen(file);

if fid == -1
	error('ERRP:IO:bva_readmarker:FileNotReadable','Couldn''t read marker file')
end

%% running index
ix=1;
segCounter = 0;
DataFile	=	'';

while 1
	%% readline
	dataStr = fgetl(fid);

	% leave the loop if end of file
	if	~ischar(dataStr), break, end
	
	% 20160514A. check header info by tigoum
	if	strncmp(dataStr, 'DataFile=', 9)
		DataFile	=	regexprep(dataStr, 'DataFile=(.+)', '$1');
	end

	% all markers start with Mk
	if	strncmp(dataStr,'Mk',2);
	
		% on multiple starts etc.
		% the recorder adds a "New Segment" maker
		if  strfind(dataStr,'New Segment')
			segCounter = segCounter + 1;
			ix = 1;
			if debug
			disp(sprintf('Found New Segment (%d). Resetting trials.',segCounter))
			end
		end 

		[t1 t2] = strread(dataStr,'%*s%s%d%*f%*f','delimiter',',');

		str = t1{1};
		% iff stimulus code, extract number
		% tigoum: if code is string, then colapse all & replace a mnemonic code
		if ~isempty(str)
			if segCounter<=0, segCounter=1; end	% miss 'New Segment' tag by err

			number	=	str2double(str(2:end));
			if isnan(number)					% it is non numerical
%				mkSym{ix}			=	str;	% memorying as string
%				res{segCounter,1}(ix)=	ix;		% alternative code
				continue						% -> finally, ignore!
			else
				res{segCounter,1}(ix)=	str2double(str(2:end));
			end

			res{segCounter,2}(ix)	=	t2;
			ix=ix+1;
		end

	end
end

fclose(fid);


% check marker type, by tigoum
if exist('mkSym', 'var') & ~isempty(mkSym)
	[STR, IA, IC]	=	unique(mkSym);			% sort & uniq
	% STR = sort & uniq string, ascending
	% IA : STR = mkSym(IA)
	% IC : mkSym = STR(IC)

	Code			=	[1:length(STR)];		% new code
	res{segCounter,1}=	Code(IC);				% replace marker code
end


% check if sth. was found
if segCounter == 0;
	error('ERRP:IO:bva_readmarker','No Segments found');
end


% prepare return values
% matrix for one segment
if segCounter == 1;
	out =  [res{1,1};res{1,2}];
% cell for mutiple 
else
	cnt = 1;
	for ix=1:segCounter
		if ~isempty(res{ix,1}) % only if there is data in segment
			out{cnt} = [res{ix,1};res{ix,2}];
			cnt = cnt + 1;
		end
	end
	
	
end

% return to caller
if numel(out) == 1;
	varargout{1} = out{1};
else
	varargout{1} = out;
end

if ~isempty(DataFile), varargout{2} = DataFile; end					% by tigoum


