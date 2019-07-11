function fig_closeIfExists(h)
%FIG_CLOSEIFEXISTS - Close figure window(s) without complaining if nonexisting

figure_handles= sort(findobj('Type','figure'));
to_be_closed= intersect(h, figure_handles);
close(to_be_closed);
