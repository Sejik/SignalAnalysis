function [trl, event] = trialfun_oddball_stimlocked(cfg)

% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

% search for "trigger" events
value  = [event.value]';
sample = [event.sample]';

% determine the number of samples before and after the trigger
pretrig  = -cfg.trialdef.prestim  * hdr.Fs;
posttrig =  cfg.trialdef.poststim * hdr.Fs;

rsp_indx   = find(ismember(value,[256 4096]));
stim_indx  = find(ismember(value,[1 2]));

trl = [];
for istim = 1:length(stim_indx);
  
  if value(stim_indx(istim)) == 2
    trl_rsp_indx = find(rsp_indx > stim_indx(istim),1,'first');
    rsp = value(rsp_indx(trl_rsp_indx));
    RT  = (sample(rsp_indx(trl_rsp_indx)) - sample(stim_indx(istim))) / hdr.Fs;
  else
    rsp = 0;
    RT  = 0;
  end
  
  newtrl   = [ sample(stim_indx(istim))+pretrig sample(stim_indx(istim))+posttrig pretrig value(stim_indx(istim)) rsp RT];
  trl      = [ trl; newtrl ];
  
end

