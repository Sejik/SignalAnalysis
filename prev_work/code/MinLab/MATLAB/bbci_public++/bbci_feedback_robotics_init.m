function [H, cfd]= bbci_feedback_robotics_init(opt);

%{
%% most of those things do not really help
fast_fig= {'Clipping','off', 'HitTest','off', 'Interruptible','off'};
fast_axis= {'Clipping','off', 'HitTest','off', 'Interruptible','off', ...
            'DrawMode','fast'};
fast_obj= {'EraseMode','xor', 'HitTest','off', 'Interruptible','off'};
fast_text= {'HitTest','off', 'Interruptible','off', 'Clipping','off', ...
            'Interpreter','none'};

if isempty(opt.fig),
  H.fig= figure;
else
  H.fig= opt.fig;
  figure(H.fig);
end
%}

	return