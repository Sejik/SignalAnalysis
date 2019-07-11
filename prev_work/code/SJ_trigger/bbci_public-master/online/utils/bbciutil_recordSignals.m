function state= bbciutil_recordSignals(varargin)
%ACQ_RECORDSIGNALS - Save Signals to File
%
%Synopsis:
%  STATE= bbciutil_recordSignals('init', FILENAME, OPT)
%  STATE= bbciutil_recordSignals(SOURCE, MARKER, <NMARKERS>)
%  STATE= bbciutil_recordSignals('close', STATE);

% 02-2012 Benjamin Blankertz  (based on code by Max Sagebaum)


if ischar(varargin{1}),
  cmd= varargin{1};
  switch(cmd),
   case 'init',
    filename= varargin{2};
    
    % Write Header file
    opt= varargin{3};
    props= {'Scale'       0.1       'DOUBLE'
            'Precision'   'int16'   'CHAR'};
    opt_hdr= opt_setDefaults(opt, props);
    opt_hdr.DataPoints= 0;
    file_writeBVheader(filename, opt_hdr);
    state= struct('precision', opt_hdr.Precision, ...
                  'factor', diag(1./opt_hdr.Scale));
    
    % Open EEG file for writing
    state.fid_eeg= fopen([filename '.eeg'], 'w');
    if state.fid_eeg==-1,
      error('Cannot open %s.eeg for writing', filename);
    end
    
    % Write an empty marker file
    file_writeBVmarkers(filename, struct('time',[], 'y',[], 'event',struct), opt_hdr);
    state.fid_mrk= fopen([filename '.vmrk'], 'A');

    % and add the marker 'segment start'
    msg= sprintf('Mk1=New Segment,,1,1,0,%s000', ...
                 datestr(now,'yyyymmddHHMMSSFFF'));
    fprintf(state.fid_mrk, [msg 13 10]);
    state.mrkCount=1;
    
   case 'close',
    state= varargin{2};
    fclose(state.fid_eeg);
    fclose(state.fid_mrk);
    state.fid_eeg= [];
    state.fid_mrk= [];
  end
  
  return;
end


source= varargin{1};
marker= varargin{2};
if nargin>2,
  nMarkers= varargin{3};
else
  nMarkers= length(marker.desc);
end

state= source.record;
 
% Write data to *.eeg file
fwrite(state.fid_eeg, state.factor*source.x', state.precision);

% Write (the last #nMarkers) markers to *.vmrk file
for i= 1:nMarkers,
  state.mrkCount= state.mrkCount + 1;
  idx= length(marker.desc)-nMarkers+i;
  if iscell(marker.desc),
    descstr= marker.desc{idx};
  else
    if marker.desc(idx)>0,
      descstr= sprintf('S%3d', marker.desc(idx));
    else
      descstr= sprintf('R%3d', marker.desc(idx));
    end
  end
  switch(descstr(1)),
   case 'S',
    mrktype= 'Stimulus';
   case 'R',
    mrktype= 'Response';
   otherwise,
    mrktype= 'Unknown';
  end
  fprintf(state.fid_mrk, ['Mk%d=%s,%s,%d,1,0' 13 10], ...
          state.mrkCount, mrktype, descstr, ...
          round(marker.time(idx)/1000*source.fs));
end
