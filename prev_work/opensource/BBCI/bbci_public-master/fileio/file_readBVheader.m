function hdr= file_readBVheader(hdrName, varargin)
% FILE_READBVHEADER - Read Header in BrainVision Format
%
% Synopsis:
%   HDR= file_readBVheader(HDRNAME)
%
% Arguments:
%   HDRNAME: name of header file (no extension),
%            relative to BTB.RawDir unless beginning with '/'.
%            HDRNAME may also contain '*' as wildcard or be a cell
%            array of strings
%
% Returns:
%   HDR: header structure:
%        .clab: channel labels (cell array)
%        .scale: scaling factors for each channel
%        .fs: sampling interval of raw data
%        .endian: byte ordering: 'l' little or 'b' big
%        .len: length of the data set in seconds. Note this information
%              is not neccessarily included in the header file. If it is
%              not, hdr.len is set to 0.
%
% See also: file_*

props= {'Verbose'   1   'BOOL'};

if nargin==0,
  hdr= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(hdrName, 'CHAR|CELL{CHAR}');

if ischar(hdrName) && ismember('*', hdrName,'legacy'),
  tmpName= fileutil_getFilelist(hdrName, 'Ext','vhdr');
  if isempty(tmpName), error('%s.vhdr not found', hdrName); end
  hdrName= tmpName;
end
if iscell(hdrName),
  hdr_array= struct([]);
  for ii= 1:length(hdrName),
    hdr= file_readBVheader(hdrName{ii});
    hdr_array= struct_sloppycat(hdr_array, hdr, 'matchsize',1);
  end
  hdr.DataFile= {hdr_array.DataFile};
  hdr.MarkerFile= {hdr_array.MarkerFile};
  hdr.DataFormat= util_catIfNonequal({hdr_array.DataFormat});  
  hdr.DataOrientation= util_catIfNonequal({hdr_array.DataOrientation});  
  hdr.DataType= util_catIfNonequal({hdr_array.DataType});  
  hdr.NumberOfChannels= util_catIfNonequal({hdr_array.NumberOfChannels});
  hdr.DataPoints= cat(2, {hdr_array.DataPoints});
%  hdr.SamplingInterval= cat(2, {hdr_array.SamplingInterval});
  hdr.SamplingInterval= util_catIfNonequal({hdr_array.SamplingInterval});
  hdr.BinaryFormat= util_catIfNonequal({hdr_array.BinaryFormat});  
  hdr.UseBigEndianOrder= util_catIfNonequal({hdr_array.UseBigEndianOrder});
  hdr.fs= util_catIfNonequal({hdr_array.fs});
  hdr.len= cat(1, hdr_array.len);
  hdr.endian= util_catIfNonequal({hdr_array.endian});
  hdr.clab= util_catIfNonequal({hdr_array.clab});
  hdr.clab_ref= util_catIfNonequal({hdr_array.clab_ref});
  hdr.scale= util_catIfNonequal({hdr_array.scale});
  if isfield(hdr_array, 'impedances'),
    hdr.impedances= cat(1, hdr_array.impedances);
    hdr.impedances_time= cat(2, {hdr_array.impedances_time});
  end
  if isfield(hdr_array, 'impedance_ref'),
    hdr.impedance_ref= cat(1, hdr_array.impedance_ref);
    hdr.impedance_gnd= cat(1, hdr_array.impedance_gnd);
  end
  return;
end

if fileutil_isAbsolutePath(hdrName),
  fullName= hdrName;
else
  global BTB
  fullName= fullfile(BTB.RawDir, hdrName);
end

fid= fopen([fullName '.vhdr'], 'r');
if fid==-1, error(sprintf('\nEEG file not found: %s.vhdr\n', fullName)); end
[dmy, filename]= fileparts(fullName);

getEntry(fid, '[Common Infos]'); 
hdr.DataFile= getEntry(fid, 'DataFile=', 0, [filename '.eeg']);
hdr.MarkerFile= getEntry(fid, 'MarkerFile=', 0, [filename '.vmrk']);
hdr.DataFormat= getEntry(fid, 'DataFormat=', 0);
hdr.DataOrientation= getEntry(fid, 'DataOrientation=', 0);
hdr.DataType= getEntry(fid, 'DataType=', 0);
getEntry(fid, '[Common Infos]'); 
hdr.NumberOfChannels= str2num(getEntry(fid, 'NumberOfChannels='));
hdr.DataPoints= getEntry(fid, 'DataPoints=', 0, '0');
getEntry(fid, '[Common Infos]'); 
hdr.SamplingInterval= str2num(getEntry(fid, 'SamplingInterval='));

getEntry(fid, '[Binary Infos]');
hdr.BinaryFormat= getEntry(fid, 'BinaryFormat=', 0);
hdr.UseBigEndianOrder= getEntry(fid, 'UseBigEndianOrder=', 0);

hdr.fs= 1000000/hdr.SamplingInterval;
%make a check if hdr.fs is a whole number
if(hdr.fs ~= round(hdr.fs))
  warning('file_readBVheader: hdr.fs was not a whole number: %f',hdr.fs); 
  hdr.fs= round(hdr.fs);
  hdr.SamplingInterval=1000000/hdr.fs;
end
% Version fuer nicht ganzzahlige Samplingraten, z.b. gtec

hdr.len= str2num(hdr.DataPoints)/hdr.fs;
if isequal(hdr.UseBigEndianOrder, 'YES'),
  hdr.endian='b';
else
  hdr.endian='l';
end

getEntry(fid, '[Channel Infos]');
hdr.clab= cell(1, hdr.NumberOfChannels);
hdr.clab_ref= cell(1, hdr.NumberOfChannels);
hdr.scale= zeros(1, hdr.NumberOfChannels);
hdr.unitOfClab= cell(1, hdr.NumberOfChannels);
ci= 0;
while ci<hdr.NumberOfChannels,
  str= fgets(fid);
  if isempty(str) || str(1)==';', continue; end
  [chno,chname,refname,resol,unit]= ...
    strread(str, 'Ch%u=%s%s%f%s', 'delimiter',',');
  ci= ci+1;
  hdr.clab(ci)= chname(1);
  hdr.clab_ref(ci)= refname(1);
  hdr.unitOfClab{ci}= unit{1};
  if resol==0,
    resol= 1;
  end
  hdr.scale(ci)= resol;
end
units= unique(hdr.unitOfClab);
if length(units)==1,
  % all channels hvae the same unit
  if isempty(units{1}),
    hdr.unit= 'a.u.';
  else
    hdr.unit= units{1};
  end
else
  % pick the prevalent unit
  util_warning('different units found', 'readBVheader:units', 'Interval',10);
  occurrences= cellfun(@(x)(length(strmatch(x,hdr.unitOfClab,'exact'))), ...
                       units);
  [mm, midx]= max(occurrences);
  hdr.unit= units{midx};
end

check= getEntry(fid, '[Coordinates]', 0, -1);
if check==1,
  hdr.pos3d= zeros(hdr.NumberOfChannels, 3);
  ci= 0;
  while ci<hdr.NumberOfChannels,
    str= fgets(fid);
    if isempty(str) | str(1)==';', continue; end
    ci= ci+1;
    [chno, hdr.pos3d(ci,1), hdr.pos3d(ci,2), hdr.pos3d(ci,3)]= ...
        strread(str, 'Ch%u=%f%f%f', 'delimiter',',');
  end
end


fseek(fid,0,'bof');
[imp_exists, imp_str]= getEntry(fid, 'Impedance ', 0, 0);

if imp_exists
  hdr.impedances= NaN*zeros(1, hdr.NumberOfChannels);
  while ~feof(fid),
    str= strtrim(fgets(fid));
    if isempty(str) | str(1)==';', continue; end
    [chname,impedance]= ...
        strread(str, '%s%s%*[^\n]');
    clab= chname{1}(1:end-1);
    impedance= impedance{1};
    if strcmp(impedance, 'Out')      % if 'Out of Range'
      impedance= Inf;
    elseif strcmp(impedance, '???'),
      impedance= NaN;
    else
      impedance= str2num(impedance);
    end
    if strcmp(clab, 'Ref'),
      hdr.impedance_ref= impedance;
      continue;
    elseif strcmp(clab, 'Gnd'),
      hdr.impedance_gnd= impedance;
      continue;
    end
    ci= util_chanind(hdr, clab);
    if isempty(ci),
      if opt.Verbose,
        warning('Impedance of unknown channel ''%s'' found\n', clab);
      end
      continue;
    end
    hdr.impedances(ci)= impedance;
  end
  hdr.impedances_time= imp_str(21:28);
end

fclose(fid);



function [entry, str]= getEntry(fid, keyword, mandatory, default_value)

if ~exist('mandatory','var'), mandatory=1; end
if ~exist('default_value','var'), default_value=[]; end
entry= 1;

if keyword(1)=='[', 
  fseek(fid, 0, 'bof');
end
ok= 0;
while ~ok && ~feof(fid),
  str= fgets(fid);
  ok= strncmp(keyword, str, length(keyword));
end
if ~ok,
  if mandatory,
    error(sprintf('keyword <%s> not found', keyword));
  else
    entry= default_value;
    return;
  end
end
if keyword(end)=='=',
  entry= deblank(str(length(keyword)+1:end));
end
