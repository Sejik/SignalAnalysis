function [H, cfd]= bbci_feedback_cursor_init(opt);

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

clf;
set(H.fig, 'Menubar','none', ...
         'Renderer','painters', ...
         'DoubleBuffer','on', ...
         'Color',[0 0 0], ...
         'Pointer','custom', ...
         'PointerShapeCData',ones(16)*NaN, ...
         fast_fig{:});
set(H.fig, 'Position',opt.geometry);

w0= 2*opt.target_width;
w= w0/(1-w0);
cfd.target_width= w;
H.ax= axes('position',[0 0 1 1]+opt.gap_to_border*[1 1 -2 -2]);
set(H.ax, 'XLim',[-1-w 1+w], 'YLim',[-1-w 1+w]);
axis('square');
set(H.ax, 'XTick',[], ...
          'YTick',[], ...
          'Color',opt.background, ...
          fast_axis{:});
H.punchline= line([-1 1; -1 1], [-1 -1; 1 1], ...
                  'Color',[0 0 0], ...
                  'LineWidth', 2, ...
                  opt.punchline_spec{:});
if ~opt.punchline,
  set(H.punchline, 'Visible','off');
end
H.center= patch([-1 1 1 -1]*opt.center_size, ...
                [-1 -1 1 1]*opt.center_size, opt.color_center);

set(H.center, 'EdgeColor','none', fast_obj{3:end});

if opt.rate_control & ~strcmpi(opt.timeout_policy,'hitiflateral'),
  set(H.center, 'Visible','off');
end

H.msg= text(0, 0, ' ');
H.msg_punch= text(0, -0.75, ' ');
set([H.msg H.msg_punch], ...
     'HorizontalAli','center', 'VerticalAli','middle', ...
     'FontUnits','normalized', opt.msg_spec{:}, fast_text{:});
set(H.msg_punch, opt.points_spec{:});

opt_cueArrows= opt_substruct(opt, stimutil_cueArrows);
[H.cue, H.fixation]= stimutil_cueArrows(opt.classes, opt_cueArrows, ...
                                        'cross',1, ...
                                        'cross_size',0.75, ...
                                        'cross_width', 0.075);

t= 1 + cfd.target_width;
H.frame= patch([1 1 -1 -1 t t -t -t t t], ...
               [1 -1 -1 1 1 t t -t -t 1], opt.frame_color);
set(H.frame, 'EdgeColor','none');

H.points= text(-0.5, 1 + cfd.target_width/2, 'hit: 0');
H.points(2)= text(0.5, 1 + cfd.target_width/2, 'miss: 0');
set(H.points, 'VerticalAli','middle', ...
              'HorizontalAli','center', ...
              'FontUnits','normalized', ...
              opt.points_spec{:}, fast_text{:});
if opt.show_score,
  set(H.points, 'Visible','on');
else
  set(H.points, 'Visible','off');
end
H.rejected_counter= text(0, -1 - cfd.target_width/2, 'rej: 0');
set(H.rejected_counter, ...
    'VerticalAli','middle', ...
    'HorizontalAli','center', ...
    'FontUnits','normalized', ...
    opt.points_spec{:}, fast_text{:});
if opt.show_rejected,
  set(H.rejected_counter, 'Visible','on');
else
  set(H.rejected_counter, 'Visible','off');
end

%H.cursor = line(0, 0, 'Color','k', 'LineStyle','none');
%set(H.cursor, fast_obj{3:end}, opt.cursor_active_spec{:});
ud.xData= get(H.fixation, 'XData');
ud.yData= get(H.fixation, 'YData');
H.cursor= patch(ud.xData, ud.yData, [0 0 0]);
set(H.cursor, 'EdgeColor','none', ...
              'UserData', ud, ...
              'Visible','off');
