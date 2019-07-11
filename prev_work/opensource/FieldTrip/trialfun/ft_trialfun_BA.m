function [trl, event] = ft_trialfun_BA(cfg)

hdr = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

% set the defaults
cfg.trigformat = ft_getopt(cfg, 'trigformat', 'S %d');

sel = find(strcmp({event.type}, 'Stimulus'));
ntrial = length(sel);
fprintf('found %d segments in the data\n', ntrial);

sample = [event.sample];
if any(diff(sample)<0)
  % events should be ordered according to the sample in the file at which they occur
  warning('reordering events based on their sample number');
  [sample, order] = sort(sample);
  event = event(order);
end

% for Brain Vision Analyzer the event type and value are strings
type  = {event.type};
value = {event.value};

begsample = nan(1,ntrial);
endsample = nan(1,ntrial);
offset    = nan(1,ntrial);
stim      = cell(1,ntrial);

for i=1:ntrial
  begevt = sel(i);
  if i<ntrial
    endevt = sel(i+1);
  else
    endevt = length(event);
  end
  
  % specify at which data sample the trial begins
  begsample(i) = sample(sel(i));
  
  % construct a list of all stimulus events in each segment
  stim{i} = find(strcmp(type((begevt+1):endevt), 'Stimulus'))+begevt;
end

% the endsample of each trial aligns with the beginsample of the next one
endsample(1:end-1) = begsample(2:end);
% the last endsample corresponds to the end of the file
endsample(end)     = hdr.nSamples*hdr.nTrials;

% add the stimulus events to the output, if possible
numstim = cellfun(@length, stim);
if all(numstim==numstim(1))
  for i=1:length(stim)
    for j=1:numstim(i)
      stimvalue  = sscanf(value{stim{i}(j)}, cfg.trigformat);
      stimsample = sample(stim{i}(j));
      stimtime   = (stimsample - begsample(i) + offset(i))/hdr.Fs; % relative to 'Time 0'
      trialinfo(i,2*(j-1)+1) = stimvalue;
      trialinfo(i,2*(j-1)+2) = stimtime;
    end % j
  end % i
else
  warning('the trials have a varying number of stimuli, not adding them to the "trl" matrix');
  trialinfo = [];
end

% combine the sample information and the trial information
trl = cat(2, [begsample(:) endsample(:) offset(:)], trialinfo);

end