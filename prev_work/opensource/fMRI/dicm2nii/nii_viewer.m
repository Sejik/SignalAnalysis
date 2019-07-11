function nii_viewer(fname, overlayName)
% Basic tool to visualize NIfTI images.
% 
%  NII_VIEWER('/data/subj2/fileName.nii.gz')
%  NII_VIEWER('background.nii', 'overlay.nii')
%  NII_VIEWER('background.nii', {'overlay1.nii' 'overlay2.nii'})
% 
% If no input is provided, the viewer will ask for background NIfTI.
% 
% Here are some features and usage.
% 
% The basic use is to open a NIfTI file to view. When a NIfTI (background) is
% open, the display always uses the image plane close to xyz axes (voxel space)
% even for oblique acquisition. The possible confusion comes if the acquisition
% was tilted with a large angle, and then the orientation labeling will be less
% accurate. The benefit is that no interpolation is needed for the background
% image, and there is no need to switch coordinate system when images with
% different systems are overlaid. The display is always in correct scale at
% three axes even with non-isotropic voxels. The displayed IJK always correspond
% to left -> right, posterior -> anterior and inferior -> superior directions,
% although the NIfTI data may not be saved in this order or along these
% directions. The I-index is increasing from left to right even when the display
% is flipped as radiological convention (right on left side).
% 
% Navigation in 4D can be done by mouse click, dialing IJK and volume numbers,
% or using keys (arrow keys and [ ] for 3D, and < > for volume).
% 
% After the viewer is open, dragging and dropping a NIfTI file will open it as
% background, while dropping with Ctrl key down will add it as overlay.
% 
% By default, the viewer shows full view of the background image data. The
% zoom-in always applies to three views together, and enlarges around the
% location of the crosshair. To zoom around a different location, set the
% crosshair to the interested location, and apply zoom again either by View ->
% Zoom in, or pressing Ctrl (Cmd) and +/-. View -> Set crosshair at -> center of
% view (or pressing key C) can set the crosshair to the center of display for
% all three views.
% 
% Overlays are always mapped onto the coordinate of background image, so
% interpolation (nearest/linear/cubic/spline) is usually involved. The overlay
% makes sense only when it has the same coordinate system as the background
% image, while the resolution and dimension can be different. The viewer tries
% to match any of sform and qform between the images. If there is no match, a
% warning message will show up.
% 
% A special overlay feature "Add aligned overlay" can be used to check the
% effect of registration, or overlay an image to a different coordinate system
% without explicitly transformation. It will ask for a NIfTI and a
% transformation matrix which aligns the NIfTI to the background image. Here is
% an example to check FSL alignment. From a .feat/reg folder, Open "highres" as
% background image. "Add overlay" for "example_func". If there is head movement
% between the highres and the functional scans, the overlap will be off. Now
% "Add aligned overlay" for "example_func", and use "example_func2highres.mat"
% as the matrix. The two dataset should overlap well if the alignment matrix is
% accurate. Here is another example to overlay to a different system for FSL
% result. Open a file .feat/reg/standard.nii.gz as background. If an image like
% .feat/stats/zstat1.nii.gz is added as an overlay, a warning message will say
% inconsistent coordinate system since the zstat image is in Scanner Anat. The
% correct way is to "Add aligned overlay" for zstat1, and use
% .feat/reg/example_func2standard.mat as alignment matrix.
% 
% When the mouse pointer is moved onto a voxel, the voxel indices, corresponding
% x/y/z coordinates and voxel value will show on the panel. If there is an
% overlay, the overlay voxel value will also show up, unless its display is off.
% When the pointer moves onto the panel or the bottom-right quadrant, the
% information for the voxel at crosshair will be displayed. The display format
% is as following:
%  (i,j,k)=(x,y,z): val_background val_overlay1 val_overlay2 ...
%
% Note that although the x/y/z coordinates are shared by background and overlay
% images, IJK indices are always for background image (shown on title bar).
% 
% The mouse-over display can be turned on/off from Help -> Preferences ...
% 
% If there is a .txt label file in the same folder as the NIfTI file, like for
% AAL, the labels will be shown instead of voxel value. The txt file should have
% a voxel value and ROI label pair per line, like
%  1 Precentral_L
%  2 Precentral_R
% 
% Image display can be smoothed for background and overlays in 3D (default is
% off). The smooth is slow when the image dimension is large, even when the
% current implementation of smooth does not consider voxel size.
% 
% Background image and overlays are listed at the left side of the panel. All
% parameters of the bottom row of the panel are for the selected image. This
% feature is indicated by a frame grouping these parameters. Each NIfTI file has
% its own set of parameters (display min and max value, LUT, alpha, whether to
% smooth, interpolation method, and volume number) to control its display.
% Moving the mouse onto a parameter will show what the parameter means.
% 
% The lastly added overlay is on the top of display and top of the file list.
% The background and overlay order can be changed by the two small buttons next
% to the list, or from Overlay -> Move selected image ...
% 
% Each NIfTI display can be turned on/off by clicking the small checkbox at the
% left side of the file (or pressing key X). This provides a way to turn on/off
% an overlay back and forth to view the overlap. Most operations are applied to
% the selected NIfTI in the list, such as Show NIfTI hdr/ext under Window menu,
% Move/Close overlay under Overlay menu, and most operations under File menu.
% 
% A NIfTI mask can be applied to the selected image. Ideally, the mask should be
% binary, and the image corresponding to the non-zero part of the mask will be
% displayed. If non-binary mask is detected, a threshold to binarize will be
% asked. If the effect is not satisfied with the threshold, one can apply the
% mask with a different threshold without re-loading image. The way to remove a
% mask is to Remove, then Add overlay again. In case one likes to modulate the
% selected image with another NIfTI image (multiply two images), File -> Apply
% modulation will do it. If the mask image is not within 0 and 1, the lower and
% upper bound will be asked to normalize the range to [0 1]. A practical use of
% modulation is to use dti_FA map as weight for dti_V1 RGB image.
% 
% For multi-volume data, one can change the Volume Number (the parameter at
% rightmost of the panel) to check the head motion. Click in the number dialer
% and hold up or down arrow key, or press < or > key, to simulate movie play. It
% is better to open the 4D data as background, since it may be slower to map it
% to the background image.
% 
% Popular LUT options are implemented. Custom LUT can be added by File -> Load
% custom LUT. The color coding can be shown by View -> Show colorbar. There are
% several special LUTs. The "two-sided" allows to show both positive and
% negative data in one view. For example, if the display range is 3 to 10 for a
% t-map, positive T above 3 will be coded as red-yellow, and T below -3 will be
% coded as blue-green. This means the absolute display range values are used.
% 
% One of the special LUT is "lines" in red text. This is for normalized vector
% display, e.g. for diffusion vector. The viewer will refuse the LUT selection
% if the data is not normalized vector. Under this LUT, all other parameters for
% the display are ignored. The color of the "lines" is the max color of previous
% LUT. For example, if one likes to show blue vector lines, choose LUT "blue"
% first, then change it to "lines".
% 
% In case of complex image, most LUTs will display only the magnitude of the
% data, except the following three phase LUTs, where the magnitude is used as
% mask. Here is how the 3 phase LUTs encodes phase from 0 to 360 degree:
%  phase:  red-yellow monotonically,
%  phase3: red-yellow-green-yellow-red circularly, and 
%  phase6: red-yellow-green/violet-blue-cyan, with sharp change at 180 degree. 
% These LUTs are useful to visualize activation of periodic stimulus, such as
% those by expanding/shrinking ring or rotating wedge for retinotopy. To use
% this feature, one can save an complex NIfTI storing the Fourier component at
% the stimulus frequency.
% 
% Note that, for RGB NIfTI, the viewer always displays the data as color
% regardless of the LUT option. The display min and max value also have no
% effect on RGB image. There is special LUT, RGB, which is designed to display
% non-RGB NIfTI data as RGB, e.g. FSL-style 3-volome data. 
% 
% The viewer figure can be copied into clipboard (not available for Linux) or
% saved as variety of image format. For high quality picture, one can increase
% the output resolution from Help -> Preferences -> Resolution. Higher
% resolution will take longer time to copy or save, and result in larger file.
% If needed, one can change to white background for picture output. With white
% background, the threshold for the background image needs to be carefully
% selected to avoid strange effect with some background images. For this reason,
% white background is intended only for picture output.
% 
% The selected NIfTI can also be saved as different format from File -> Save
% NIfTI as. For example, a file can be saved as a different resolution. With a
% transformation matrix, a file can also be saved into a different template. The
% latter is needed for FSLview since it won't allow overlay with different
% resolution or dimension at least till version 5.0.8.
% 
% See also NII_TOOL, DICM2NII, NII_XFORM

%% By Xiangrui Li (xiangrui.li@gmail.com)
% History(yymmdd):
% 151021 Almost ready to publish.
% 151104 Include drag&drop by Maarten van der Seijs.
% 151105 Bug fix for Show NIfTI hdr/ext.
% 151106 Use hs.q.interp to avoid unnecessary interp for overlay;
%        Use check mark for colorbar/crosshair/background menu items.
% 151111 Take care of slope/inter of img; mask applies to DTI lines.
% 151114 Avoid see-thu for white background.
% 151119 Make smooth faster by using only 3 slices; Allow flip L/R.
% 151120 Implement key navigation and zoom in/out.
% 151121 Implement erode for white background; Add 'Show NIfTI essentials'. 
% 151122 Bug fix for background img with sform=0.
% 151123 Show coordinate system in fig title; show masked/aligned in file list;
%        Bug fix for alpha (0/1 only); Bug fix for background image R change.
% 151125 Avoid recursion for white background (failed under Linux).
% 151128 Change checkbox to radiobutton: looks better;
%        Fix the bug in reorient dim(perm), introduced in last revision.
% 151129 Correct Center crosshair (was off by 0.5); Use evt.Key & add A/C/X/F1. 
% 151201 Keep fig location & pref when 'open' & dnd: more user friendly.
% 151202 java robot trick allows to add overlay by Ctrl-dnd.
% 151206 Bug fix for RGB nii smooth; Change hs.q(i) to hs.q{i}.
% 151207 Implement 'Add modulation'.
% 151208 Add xyz display for each view.
% 151217 Callback uses subfunc directly, and include fh as input.
% 151222 Show ROI labels (eg AAL) if .txt file with same name exists.
% 151224 Implement more matlab LUTs and custom LUT.
% 151229 Store fname in p rather than fh UserData; Remove WheelFcn zoom.
% 151230 Use listbox for files; Add stack buttons; file order reversed.
% 160102 Store hs.q{i}.R0 if need interp; No coordinate change for background.
% 160104 set_cdata: avoid indexing for single vol img: may be much faster!
%        jscroll_handle from findjobj.m to set vertical scoll bar as needed.
% 160107 Rename XYZ label to IJK, implement "Set crosshair at XYZ".
% 160108 Fix the case of 2-form_code for background and addMask.
% 160109 Allow to turn off mouse-over display from Preferences;
%        Implement Help -> Check update for easy update;
%        Use Matlab built-in pref method for all files in the package.
% 160111 Use image ButtonDownFcn; Mouse down&move now is same as mouse move.
% 160112 Change back to line for crosshair: quiver is slow;
%        Bug fix for white backgrnd & saveas backgrnd due to list order reverse.
% 160113 Implement time course for a cube.
% 160114 Figure visible avoids weird hanging problem for some matlab versions.
% 160119 Allow adding multiple overlays with cellstr as 2nd input.
% 160131 set_file: bug fix for cb(j); dnd: restore mouse location.
% 160208 Allow moving background image in stack.
% 160209 RGBA data supported; Background image can use lut "lines".
% 160218 "lines": Fix non-isovoxel display; Same-dim background not required.
% 160402 nii_xform_mat: make up R for possible Analyze file.
% 160506 phase LUT to map complex img: useful for retinotopy.
% 160509 Have 3 phase LUTs; Implement 'Open in new window'.
% 160512 KeyPressFcn bug fix: use the smallest axis dim when zoom in.
% 160517 KeyPressFcn: avoid double-dlg by Ctrl-A; phase6: bug fix for blue b3.
% 160531 use handle() for fh & others: allow dot convention for early matlab.
% 160601 Add toCOG and to image center, re-organize 'Set crosshair at' menu.
% 160602 bug fix for 'closeAll' files.String(ib); COG uses abs and excludes NaN.
% 160605 Add 'RGB' LUT to force RGB display: DTI_V1 or fsl style RGB file.
% 160608 javaDropFcn: 2 more method for ctlDn; bug fix for fh.xxx in Resize.
%%

haveFig = nargin>1 && isstruct(overlayName); % internal call by 'open' or dnd
if haveFig
    hs = overlayName;
    fh = hs.fig;
    pf = get(hs.pref, 'UserData');
    pos = getpixelposition(fh);
    pos = pos(1:2); % location for new file
    if isfield(hs, 'newWin'), haveFig = false; end
    clear hs; % delete hs after getting pos and pf
else
    pf = getpref('nii_viewer_para');
    if isempty(pf) || ~isfield(pf, 'mouseOver')
        pf = struct('openPath', pwd, 'addPath', pwd, 'interp', 'linear', ...
            'extraV', NaN, 'dpi', '0', 'rightOnLeft', false, 'mouseOver', true);
        setpref('nii_viewer_para', fieldnames(pf), struct2cell(pf));
    end
%     if ~isfield(pf, 'newPref') % add new parameter
%         setpref('nii_viewer_para', 'newPref', val);
%         pf = getpref('nii_viewer_para');
%     end
end

if nargin<1
    types = '*.nii; *.hdr; *.nii.gz; *.hdr.gz';
    [fname, pName] = uigetfile([pf.openPath '/' types], 'Select NIfTI to view');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    setpref('nii_viewer_para', 'openPath', pName);
end

[hs.q{1}, hs.form_code, rg, dim] = read_nii(fname);
nVol = size(hs.q{1}.nii.img, 4);
hs.pixdim = hs.q{1}.pixdim;

mm = dim .* hs.pixdim; % FOV
siz = [sum(mm(1:2)) sum(mm(2:3))]; % image area width/height
x0 = mm(1) / siz(1); % normalized width of left images
y0 = mm(2) / siz(2); % normalized height of bottom image (tra)
z0 = mm(3) / siz(2); % normalized height of top images

res = screen_pixels;
% leave some room for system bar and figure menu/title/panel both dimension
siz = siz * min((res-[40 156]) ./ siz); % almost max size
if siz(2)>800, siz = siz*0.8; end % make it smaller on big screen
siz = ceil(siz);

p.fname = hs.q{1}.nii.hdr.file_name;
p.show = true; % img on
p.lb = rg(1); 
p.ub = rg(2);
p.lb_step = stepSize(rg(1));
p.ub_step = stepSize(rg(2));
if any(hs.q{1}.nii.hdr.datatype == [32 1792]) % complex
    p.lut = 26; % phase
elseif hs.q{1}.nii.hdr.intent_code == 1002 % Label
    p.lut = 24; % prism
else
    p.lut = 1; % grayscale
end
p.alpha = 1; % opaque
p.smooth = false;
p.interp = 1; % nearest
p.volume = 1; % first volume

hs.dim = single(dim); % single may save a lot memory for meshgrid
hs.siz = siz; % image panel size
hs.gap = min(hs.pixdim) ./ hs.pixdim * 3; % in unit of smallest pixdim

[pName, niiName, ext] = fileparts(p.fname);
if strcmpi(ext, '.gz'), [~, niiName] = fileparts(niiName); end

if haveFig
    fn = get(fh, 'Number');
    close(fh); 
else
    res = screen_pixels(1); % use 1st screen
    pos = round((res-siz)/2);

    set(0, 'ShowHiddenHandles', 'on');
    a = handle(findobj('Type', 'figure', 'Tag', 'nii_viewer'));
    set(0, 'ShowHiddenHandles', 'off');
    if isempty(a)
        fn = 'ni' * 256.^(1:2)'; % start with a big number for figure
    elseif numel(a) == 1
        fn = get(a, 'Number') + 1;
    else
        fn = max(cell2mat(get(a, 'Number'))) + 1;
    end
end
fh = figure(fn);
hs.fig = handle(fh); % have to use numeric for uipanel for older matlab
figNam = ['nii_viewer - ' p.fname ' (' formcode2str(hs.form_code(1)) ')'];
if pos(1)+siz(1) > res(1), pos(1) = res(1)-siz(1)-10; end
if pos(2)+siz(2) > res(2)-130, pos(2) = min(pos(2), 50); end
set(fh, 'Toolbar', 'none', 'Menubar', 'none', 'Renderer', 'opengl', ...
    'NumberTitle', 'off', 'Tag', 'nii_viewer', 'DockControls', 'off', ...
    'Position', [pos siz+[0 64]], 'Name', figNam);
warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
jFrame = get(fh, 'JavaFrame');
jAxisComponent = jFrame.getAxisComponent;
cb = @(cmd) {@nii_viewer_cb cmd hs.fig}; % callback shortcut
xyz = [0 0 0]; % start cursor location
c = round(hs.q{1}.R \ [xyz 1]'); c = c(1:3)' + 1; % 
ind = c<=1 | c>=dim;
c(ind) = round(dim(ind)/2);
% c = round(dim/2); % start cursor at the center of images
xyz = round(hs.q{1}.R * [c-1 1]'); % take care of rounding error

%% control panel
pos = getpixelposition(fh); pos = [1 pos(4)-64 pos(3) 64];
ph = uipanel(fh, 'Units', 'pixels', 'Position', pos, 'BorderType', 'none');
hs.panel = ph;
clr = get(ph, 'BackgroundColor');

% NIfTI list: do this earlier so jscroll_handle runs faster
feature('DefaultCharacterSet', 'UTF-8'); % needed for old matlab to show 9746/4
hs.files = uicontrol(ph, 'Style', 'listbox', 'BackgroundColor', 'w', ...
    'FontName', 'default', 'Position', [2 4 100 60], ...
    'KeyPressFcn', @KeyPressFcn, 'String', {[9746 ' ' niiName]}, 'Value', 1, ...
    'TooltipString', ['Select image to show/modify its display parameters.' ...
                       char(10) 'Click checkbox to turn on/off image']);
setappdata(hs.files, 'PreviousValue', 1);
try
    % java_dnd based on dndcontrol at matlabcentral/fileexchange/53511
    try java_dnd(jAxisComponent, {@javaDropFcn hs.fig}); catch, end
    drawnow; jScrollPane = jscroll_handle(jAxisComponent); % must drawnow
    % jScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED = 20
    cbStr = 'set(gcbo, ''VerticalScrollBarPolicy'', 20)';
    set(jScrollPane, 'VerticalScrollBarPolicy', 20, ...
        'AdjustmentValueChangedCallback', cbStr);
    jListbox = handle(jScrollPane.getViewport.getView, 'CallbackProperties');
    jListbox.MouseClickedCallback = cb('files');
catch % use listbox callback if java trick fails
    set(hs.files, 'Callback', cb('files'));
end

hs.overlay(1) = uicontrol(ph, 'Style', 'pushbutton', 'FontSize', 7, ...
    'Callback', cb('stack'), 'Enable', 'off', ...
    'String', char(9660), 'Position', [102 36 16 15], 'Tag', 'down', ...
    'TooltipString', 'Move selected image one level down');
hs.overlay(2) = uicontrol(ph, 'Style', 'pushbutton', 'FontSize', 7, ...
    'Callback', cb('stack'), 'Enable', 'off', ...
    'String', char(9650), 'Position', [102 50 16 15], 'Tag', 'up', ...
    'TooltipString', 'Move selected image one level up');

% IJK java spinners
labls = 'IJK';
str = {'Left to Right' 'Posterior to Anterior' 'Inferior to Superior'};
pos = [38 44 22]; posTxt = [36 10 20];
for i = 1:numel(labls)
    loc = [(i-1)*64+136 pos];
    txt = sprintf('%s, 1:%g', str{i}, dim(i));
    hs.ijk(i) = java_spinner(loc, [c(i) 1 dim(i) 1], ph, cb('ijk'), '#', txt);
    uicontrol(ph, 'Style', 'text', 'String', labls(i), 'BackgroundColor', clr, ...
        'Position', [loc(1)-11 posTxt], 'TooltipString', txt, 'FontWeight', 'bold');
end

hs.value = uicontrol(ph, 'Style', 'text', 'Position', [308 38 siz(1)-308 20], ...
    'BackgroundColor', clr, 'UserData', false, 'Enable', 'inactive', ...
    'TooltipString', '(i,j,k)=(x,y,z): val1 val2 ...');

% Controls for each file
uipanel('Parent', ph, 'Units', 'pixels', 'Position', [102 2 412 34], ...
    'BorderType', 'etchedin', 'BorderWidth', 2);
hs.lb = java_spinner([108 8 52 22], [p.lb -inf inf p.lb_step], ph, ...
    cb('lb'), '#.##', 'min value (threshold)');
hs.ub = java_spinner([160 8 52 22], [p.ub -inf inf p.ub_step], ph, ...
    cb('ub'), '#.##', 'max value (clipped)');
hs.lutStr = {'grayscale' 'red' 'green' 'blue' 'violet' 'yellow' 'cyan' ...
    'red-yellow' 'blue-green' 'two-sided'  '<html><font color="red">lines' ...
    'parula' 'jet' 'hsv' 'hot' 'cool' 'spring' 'summer' 'autumn' 'winter' ...
    'bone' 'copper' 'pink' 'prism' 'flag' 'phase' 'phase3' 'phase6' 'RGB'};
hs.lut = uicontrol(ph, 'Style', 'popup', 'Position', [214 8 74 22], ...
    'String', hs.lutStr, 'BackgroundColor', 'w', 'Callback', cb('lut'), ...
    'Value', p.lut, 'TooltipString', 'Lookup table options for non-RGB data');

hs.alpha = java_spinner([288 8 44 22], [1 0 1 0.1], ph, cb('alpha'), '#.#', ...
    'Alpha: 0 transparent, 1 opaque');

hs.smooth = uicontrol(ph, 'Style', 'checkbox', 'Value', p.smooth, ...
    'Position', [332 8 60 22], 'String', 'smooth', ...
    'BackgroundColor', clr, 'Callback', cb('smooth'), ...
    'TooltipString', 'Smooth image in 3D');
hs.interp = uicontrol(ph, 'Style', 'popup', 'Position', [392 8 68 22], ...
    'String', {'nearest' 'linear' 'cubic' 'spline'}, 'Value', p.interp, ...
    'Callback', cb('interp'), 'Enable', 'off', 'BackgroundColor', 'w', ... 
    'TooltipString', 'Interpolation method for overlay');
hs.volume = java_spinner([462 8 44 22], [1 1 nVol 1], ph, cb('volume'), '#', ...
    ['Volume number, 1:' num2str(nVol)]);
hs.volume.setEnabled(nVol>1);

%% Three views: sag, cor, tra
% this panel makes resize easy: subplot relative to the panel
hs.frame = uipanel(fh, 'Units', 'pixels', 'Position', [1 1 siz], ...
    'BorderType', 'none', 'BackgroundColor', 'k');
pos = [x0 y0 1-x0 z0;  0 y0 x0 z0;  0 0 x0 y0];
for i = 1:3
    j = 1:3; j(j==i) = [];
    hs.ax(i) = subplot('Position', pos(i,:), 'Parent', hs.frame);
    hs.hsI(i) = image(zeros(dim(j([2 1])), 'single')); hold(hs.ax(i), 'on');
    
    x = [c(j(1))+[-1 1 0 0]*hs.gap(j(1)); 0 dim(j(1))+1 c(j(1))*[1 1]];
    y = [c(j(2))+[0 0 -1 1]*hs.gap(j(2)); c(j(2))*[1 1] 0 dim(j(2))+1];
    hs.cross(i,:) = line(x, y);

    hs.xyz(i) = text(0.02, 0.96, num2str(xyz(i)), 'Units', 'normalized', ...
        'Parent', hs.ax(i), 'FontSize', 12);
end
set(hs.hsI, 'ButtonDownFcn', cb('mousedown'), 'Visible', 'off'); % for copyimg
p.hsI = copyimg(hs);
set(hs.files, 'UserData', p); % after get p.hsI
hs.iback = 1;

labls='ASLSLP'; 
pos = [0.95 0.5; 0.47 0.96; 0 0.5; 0.47 0.96; 0 0.5; 0.47 0.05]; 
for i = 1:numel(labls)
    hs.ras(i) = text(pos(i,1), pos(i,2), labls(i), 'Units', 'normalized', ...
        'Parent', hs.ax(ceil(i/2)), 'FontSize', 12, 'FontWeight', 'bold');
end

% early matlab's colormap works only for axis, so ax(4) is needed.
hs.ax(4) = subplot('Position', [x0 0 1-x0 y0], 'Parent', hs.frame, 'Ylim', [0 1]);
colorbar('Units', 'Normalized', 'Position', [x0+0.2 y0*0.15 0.03 y0*0.7]);
hs.colorbar = findobj(fh, 'Tag', 'Colorbar'); % trick for early matlab
set(hs.colorbar, 'Visible', 'off', 'UIContextMenu', '', 'EdgeColor', [1 1 1]);
% hs.colorbar = colorbar(hs.ax(4), 'YTicks', [0 0.5 1], 'Color', [1 1 1], ...
%     'Location', 'west', 'PickableParts', 'none', 'Visible', 'off');

% image() makes YDir reversed. Turn off ax and ticks
set(hs.ax, 'YDir', 'normal', 'Visible', 'off');
set([hs.ras hs.cross(:)' hs.xyz], 'Color', 'b', 'UIContextMenu', '');
try set([hs.ras hs.cross(:)' hs.xyz], 'PickableParts', 'none'); % new matlab
catch, set([hs.ras hs.cross(:)' hs.xyz], 'HitTest', 'off'); % old ones
end

%% menus
h = uimenu(fh, 'Label', '&File');
uimenu(h, 'Label', 'Open', 'Accelerator', 'O', 'UserData', pName, 'Callback', cb('open'));
uimenu(h, 'Label', 'Open in new window', 'Callback', cb('open'));
uimenu(h, 'Label', 'Apply mask', 'Callback', cb('mask'));
uimenu(h, 'Label', 'Apply modulation', 'Callback', cb('mask'));
uimenu(h, 'Label', 'Load custom LUT', 'Callback', cb('custom'));
h_savefig = uimenu(h, 'Label', 'Save figure as');
h_saveas = uimenu(h, 'Label', 'Save NIfTI as');
uimenu(h, 'Label', 'Close window', 'Accelerator', 'W', 'Callback', 'close gcf');

uimenu(h_saveas, 'Label', 'SPM 3D NIfTI (one file/pair per volume)', 'Callback', cb('saveas'));
uimenu(h_saveas, 'Label', 'NIfTI standard RGB (for AFNI, later mricron)', ...
    'Callback', cb('saveas'), 'Separator', 'on');
uimenu(h_saveas, 'Label', 'FSL style RGB (RGB saved in dim 4)', 'Callback', cb('saveas'));
uimenu(h_saveas, 'Label', 'Old mricron style RGB (RGB saved in dim 3)', 'Callback', cb('saveas'));
uimenu(h_saveas, 'Label', 'file with a new resolution', 'Callback', cb('saveas'), 'Separator', 'on');
uimenu(h_saveas, 'Label', 'file matching background', 'Callback', cb('saveas'));
uimenu(h_saveas, 'Label', 'file in aligned template space', 'Callback', cb('saveas'));

fmt = {'pdf' 'eps' 'png' 'jpg' 'tif' 'bmp'};
if ispc, fmt = [fmt 'emf']; end
for i = 1:numel(fmt)
    uimenu(h_savefig, 'Label', fmt{i}, 'Callback', cb('save'));
end

if ispc || ismac
    h = uimenu(fh, 'Label', '&Edit');
    uimenu(h, 'Label', 'Copy figure', 'Separator', 'on', 'Callback', cb('copy'));
end

h_over = uimenu(fh, 'Label', '&Overlay');
hs.add = uimenu(h_over, 'Label', 'Add overlay', 'Accelerator', 'A', ...
    'UserData', pf.addPath, 'Callback', cb('add'));
uimenu(h_over, 'Label', 'Add aligned overlay', 'Callback', cb('add'));

h = uimenu(h_over, 'Label', 'Move selected image', 'Enable', 'off');
uimenu(h, 'Label', 'to top',         'Callback', cb('stack'), 'Tag', 'top');
uimenu(h, 'Label', 'to bottom',      'Callback', cb('stack'), 'Tag', 'bottom');
uimenu(h, 'Label', 'one level up',   'Callback', cb('stack'), 'Tag', 'up');
uimenu(h, 'Label', 'one level down', 'Callback', cb('stack'), 'Tag', 'down');
hs.overlay(3) = h;

hs.overlay(5) = uimenu(h_over, 'Label', 'Remove overlay', 'Accelerator', 'R', ...
    'Callback',  cb('close'), 'Enable', 'off');
hs.overlay(4) = uimenu(h_over, 'Label', 'Remove overlays', 'Accelerator', 'Q', ...
    'Callback', cb('closeAll'), 'Enable', 'off');

h_view = uimenu(fh, 'Label', '&View');
h = uimenu(h_view, 'Label', 'Zoom in by');
for i = [1 1.2 1.5 2 3 4 5 8 10 20]
    uimenu(h, 'Label', num2str(i), 'Callback',  cb('zoom'));
end
uimenu(h_view, 'Label', 'White background', 'Callback',  cb('background'));
hLR = uimenu(h_view, 'Label', 'Right on left side', 'Callback',  cb('flipLR'));
uimenu(h_view, 'Label', 'Show colorbar', 'Callback',  cb('colorbar'));
uimenu(h_view, 'Label', 'Show crosshair', 'Separator', 'on', ...
    'Checked', 'on', 'Callback',  cb('cross'));
h = uimenu(h_view, 'Label', 'Set crosshair at');
uimenu(h, 'Label', 'center of view', 'Callback',  cb('viewCenter'));
uimenu(h, 'Label', 'center of image', 'Callback',  cb('center'));
uimenu(h, 'Label', 'COG of image', 'Callback',  cb('toCOG'));
uimenu(h, 'Label', 'a point [x y z]', 'Callback',  cb('toXYZ'));
uimenu(h_view, 'Label', 'Crosshair color', 'Callback',  cb('color'));
h = uimenu(h_view, 'Label', 'Crosshair gap');
for i = [1 2 3 4 5 6 8 10 20 40]
    str = num2str(i); if i==6, str = [str ' (default)']; end %#ok
    uimenu(h, 'Label', str, 'Callback', cb('gap'));
end
h = uimenu(h_view, 'Label', 'Crosshair thickness');
uimenu(h, 'Label', '0.5 (default)', 'Callback', cb('thickness'));
for i = [0.75 1 2 4 8]
    uimenu(h, 'Label', num2str(i), 'Callback', cb('thickness'));
end

h = uimenu(fh, 'Label', '&Window');
uimenu(h, 'Label', 'Show NIfTI essentials', 'Callback', cb('essential'));
uimenu(h, 'Label', 'Show NIfTI hdr', 'Callback', cb('hdr'));
uimenu(h, 'Label', 'Show NIfTI ext', 'Callback', cb('ext'));
uimenu(h, 'Label', 'DICOM to NIfTI converter', 'Callback', 'dicm2nii', 'Separator', 'on');
h = uimenu(h, 'Label', 'Time course ...', 'Callback', cb('plot'), 'Separator', 'on');
setappdata(h, 'edge', 5);

h = uimenu(fh, 'Label', '&Help');
hs.pref = uimenu(h, 'Label', 'Preferences', 'UserData', pf, ...
    'Callback', @(~,~)pref_dialog(gcbo));
uimenu(h, 'Label', 'Key shortcut', 'Callback', cb('keyHelp'));
uimenu(h, 'Label', 'Show help text', 'Callback', 'doc nii_viewer');
checkUpdate = dicm2nii('', 'checkUpdate', 'func_handle');
uimenu(h, 'Label', 'Check update', 'Callback', @(~,~)checkUpdate('nii_viewer'));
uimenu(h, 'Label', 'About', 'Callback', cb('about'));

%% finalize gui
if isnumeric(fh) % for older matlab
    fh = handle(fh);
    schema.prop(fh, 'Number', 'mxArray'); fh.Number = fn;
    hs.lut = handle(hs.lut);
    hs.frame = handle(hs.frame);
    hs.files = handle(hs.files);                   
end
guidata(fh, hs); % store handles and data
set(fh, 'ResizeFcn', cb('resize'), ... % 'SizeChangedFcn' for later matlab
    'KeyPressFcn', @KeyPressFcn, ... % WindowKeyPressFcn has dual effect
    'PaperPositionMode', 'auto', 'HandleVisibility', 'Callback');
nii_viewer_cb(fh, [], 'resize', fh); % avoid some weird problem

if pf.mouseOver, set(fh, 'WindowButtonMotionFcn', cb('mousemove')); end
if pf.rightOnLeft, nii_viewer_cb(hLR, [], 'flipLR', fh); end
set_cdata(hs);

if nargin>1
    if ischar(overlayName)
        addOverlay(overlayName, fh);
    elseif iscellstr(overlayName)
        for i=1:numel(overlayName), addOverlay(overlayName{i}, fh); end
    end
end

if hs.form_code(1)<1
    warndlg(['There is no valid form code in NIfTI. The orientation ' ...
        'labeling is likely meaningless.']);
end

%% callbacks
function nii_viewer_cb(h, evt, cmd, fh)
hs = guidata(fh);
switch cmd
    case 'ijk'
        ix = find(h == hs.ijk);
        set_cdata(hs, ix);
        set_cross(hs, ix);
        xyz = set_xyz(hs);
        for i = 1:3, set(hs.xyz(i), 'String', xyz(i)); end % need 3 if oblique
    case 'mousedown' % image clicked
        % if ~strcmp(get(fh, 'SelectionType'), 'normal'), return; end
        ax = gca;
        c = get(ax, 'CurrentPoint');
        c = round(c(1, 1:2));
        i = 1:3;
        i(ax==hs.ax(1:3)) = [];
        hs.ijk(i(1)).setValue(c(1));
        hs.ijk(i(2)).setValue(c(2));
    case {'lb' 'ub' 'lut' 'alpha' 'smooth' 'interp' 'volume'};
        p = hs.files.UserData;
        i = hs.files.Value;
        val = get(h, 'Value');
        
        if val == 11 && val~=p(i).lut
            hs.lut.UserData = p(i).lut; % remember old lut
        end
        if strcmp(cmd, 'lut')
            err = false;
            if val == 11 % error check for vector lines
                err = true;
                if size(hs.q{i}.nii.img,4)~=3
                    errordlg('Not valid vector data: dim4 is not 3');
                else
                    a = sum(hs.q{i}.nii.img.^2, 4); a = a(a(:)>1e-4);
                    if any(abs(a-1)>0.1)
                        errordlg('Not valid vector data: squared sum is not 1');
                    else err = false; % passed all checks
                    end
                end
            elseif any(val == 26:28) % error check for phase img
                err = ~isfield(hs.q{i}, 'phase');
                if err, warndlg('Seleced image is not complex data.'); end
            elseif val == 29 % RGB
                err = size(hs.q{i}.nii.img,4)~=3;
                if err, errordlg('RGB LUT requres 3-volume data.'); end
            end
            if err, hs.lut.Value = p(i).lut; return; end % undo selection
        end
        
        p(i).(cmd) = val;
        hs.files.UserData = p;
        if any(strcmp(cmd, {'lut' 'lb' 'ub'})), set_colorbar(hs); end
        if strcmp(cmd, 'volume'), set_xyz(hs); end
        set_cdata(hs);
    case 'resize'
        if isempty(hs), return; end
        cb = fh.ResizeFcn;
        fh.ResizeFcn = ''; drawnow; % avoid weird effect
        clnObj = onCleanup(@() set(fh, 'ResizeFcn', cb)); % restore func
        
        posP = getpixelposition(hs.panel); % get old height in pixels
        posF = getpixelposition(fh); % asked position by user
        posI = getpixelposition(hs.frame); % old size
        
        res = screen_pixels;
        oldF = round([posI(3) posI(4)+posP(4)]); % old fig size
        if isequal(oldF, posF(3:4)), return; end % only move, no size change
        if all(posF(3:4) >= oldF) % enlarge
            a = max([posF(3) posF(4)-posP(4)] ./ hs.siz) * hs.siz;
            a(1) = min(a(1), res(1)-30); % leave space for MAC dock etc
            a(2) = min(a(2), res(2)-92-posP(4)); % leave space for title bar etc
            a = min(a ./ hs.siz) * hs.siz;
        elseif all(posF(3:4) <= oldF) % shrink
            a = min([posF(3) posF(4)-posP(4)] ./ hs.siz) * hs.siz;
        else % one side enlarge, another side shrink: use old size
            a = posI(3:4);
        end
        d = posF(1)+a(1)-res(1);
        if d>0, posF(1) = posF(1) - d; end
        d = posF(2)+a(2)+posP(4)+92-res(2);
        if d>0, posF(2) = posF(2) - d; end
        posF(1) = max(posF(1), 10);
        posF(2) = max(posF(2), 50);
        posF(3:4) = [a(1) a(2)+posP(4)]; % final figure size
        fh.Position = posF; % done for fig
        
        posP(2) = posF(4)-posP(4)+1; 
        posP(3) = posF(3);
        set(hs.panel, 'Position', posP); % done for control panel
        hs.frame.Position = [1 1 a]; % done for image panel
        
        pos = getpixelposition(hs.value);
        pos(3) = max(1, posP(3)-pos(1)-1);
        set(hs.value, 'Position', pos);
    case 'files'
        try % try java MouseClickedCallback first
            evt = struct(handle(evt));
            x = evt.X;
            y = evt.Y;
            i = h.locationToIndex(java.awt.Point(x, y)); % 0-based
            height = h.FixedCellHeight;
        catch % arrow key up/down will change checkbox if mouse is there
            xy = get(0, 'PointerLocation');
            drawnow; i = hs.files.Value - 1;
            height = hs.files.Extent(4) - 5; % based on 19 vs 14 from java h.FixedCellHeight
            posH = getpixelposition(hs.files, true);
            posF = getpixelposition(fh);
            x = xy(1) - posF(1) - posH(1);
            y = posH(4) - (xy(2) - posF(2) - posH(2)); % start from top
        end
        y = y / height;
        if x<hs.files.FontSize+3 && y>i && y<i+1, toggle_img(hs); end
        set_file(hs);
    case 'mousemove'
        % if ~strcmp(get(fh, 'SelectionType'), 'normal'), return; end
        c = cell2mat(get(hs.ax(1:3), 'CurrentPoint'));
        c = c([1 3 5], 1:2); % 3x2
        x = cell2mat(get(hs.ax(1:3), 'XLim')); 
        y = cell2mat(get(hs.ax(1:3), 'YLim')); 
        I = cell2mat(get(hs.ijk, 'Value'))';
        if     c(1,1)>x(1,1) && c(1,1)<x(1,2) && c(1,2)>y(1,1) && c(1,2)<y(1,2)%sag
            I = [I(1) c(1,:)];
        elseif c(2,1)>x(2,1) && c(2,1)<x(2,2) && c(2,2)>y(2,1) && c(2,2)<y(2,2)%cor
            I = [c(2,1) I(2) c(2,2)];
        elseif c(3,1)>x(3,1) && c(3,1)<x(3,2) && c(3,2)>y(3,1) && c(3,2)<y(3,2)%tra
            I = [c(3,:) I(3)];
        end
        set_xyz(hs, I);
    case 'open'
        pf = get(hs.pref, 'UserData');
        [fname, pName] = uigetfile([pf.openPath '/*.nii; *.hdr;' ...
            '*.nii.gz; *.hdr.gz'], 'Select a NIfTI to view');
        if ~ischar(fname), return; end
        fname = fullfile(pName, fname);
        if strcmp(get(h, 'Label'), 'Open in new window'), hs.newWin = true; end
        nii_viewer(fname, hs);
    case 'add'
        pName = get(hs.add, 'UserData');
        [fname, pName] = uigetfile([pName '/*.nii; *.hdr;' ...
            '*.nii.gz; *.hdr.gz'], 'Select overlay NIfTI');
        if ~ischar(fname), return; end
        fname = fullfile(pName, fname);
        
        if ~isempty(strfind(get(h,'Label'), 'aligned'))
            [mtx, pName] = uigetfile([pName '/*.mat'], ['Select the ' ...
                'text matrix file which aligns the nii to background']);
            if ~ischar(mtx), return; end
            mtx = fullfile(pName, mtx);
            try 
                R = load(mtx, '-ascii');
                if ~isequal(size(R), [4 4])
                    error('Invalid transformation matrix file: %s', mtx);
                end
            catch me
                errordlg(me.message);
                return;
            end
            addOverlay(fname, fh, R, mtx);
        else
            addOverlay(fname, fh);
        end
        setpref('nii_viewer_para', 'addPath', pName);
    case 'closeAll'
        p = hs.files.UserData;
        ib = hs.iback;
        ind = 1:numel(p);
        ind(ind==ib) = [];
        for j = ind, delete(p(j).hsI); end
        hs.iback = 1;
        hs.q(ind) = []; guidata(fh, hs);
        set(hs.files, 'String', hs.files.String(ib), 'Value', 1, 'UserData', p(ib));
        set_file(hs);
        set_xyz(hs);
    case 'close'
        i = hs.files.Value;
        ib = hs.iback;
        if i==ib, return; end % no touch to background
        p = hs.files.UserData;
        delete(p(i).hsI); % 3 images
        if i<ib, hs.iback = ib-1; end
        hs.q(i) = []; guidata(fh, hs);
        p(i) = [];
        
        str = hs.files.String;
        str(i) = [];
        i = max(1, i-1);
        set(hs.files, 'Value', i, 'String', str, 'UserData', p);
        set_file(hs);
        set_xyz(hs);
    case {'hdr' 'ext' 'essential'}
        j = hs.files.Value;
        if strcmp(cmd, 'hdr')
            hdr = hs.q{j}.nii.hdr;
        elseif strcmp(cmd, 'ext')
            if ~isfield(hs.q{j}.nii, 'ext')
                errordlg('No extension for the selected NIfTI'); 
                return;
            end
            hdr = {};
            for i = 1:numel(hs.q{j}.nii.ext)
                if ~isfield(hs.q{j}.nii.ext(i), 'edata_decoded'), continue; end
                hdr{end+1} = hs.q{j}.nii.ext(i).edata_decoded; %#ok
            end
            if isempty(hdr)
                errordlg('No known extension for the selected NIfTI'); 
                return;
            elseif numel(hdr) == 1, hdr = hdr{1};
            end
        elseif strcmp(cmd, 'essential')
            hdr = nii_essential(hs.q{j});
        end
        nam = hs.files.String;
        nam = nam{j}(3:end);
        if ~isstrprop(nam(1), 'alpha'), nam = ['x' nam]; end % like genvarname
        nam(~isstrprop(nam, 'alphanum')) = '_'; % make it valid for var name
        nam = [nam '_' cmd];
        nam = strrep(nam, '__', '_');
        assignin('base', nam, hdr);
        evalin('base', ['open ' nam]);
    case 'cross' % show/hide crosshairs and RAS labels
        if strcmp(get(h, 'Checked'), 'on')
            set(h, 'Checked', 'off');
            set([hs.cross(:)' hs.ras hs.xyz], 'Visible', 'off');
        else
            set(h, 'Checked', 'on');
            set([hs.cross(:)' hs.ras hs.xyz], 'Visible', 'on');
        end
    case 'color' % crosshair color
        c = uisetcolor(get(hs.ras(1), 'Color'), 'Pick crosshair color');
        if numel(c) ~= 3, return; end
        set([hs.cross(:)' hs.ras hs.xyz], 'Color', c);
    case 'thickness'
        c = strtok(get(h, 'Label'));
        set(hs.cross(:)', 'LineWidth', str2double(c));
    case 'gap'
        c = str2double(strtok(get(h, 'Label')));
        hs.gap = min(hs.pixdim) ./ hs.pixdim * c / 2;
        guidata(fh, hs);
        set_cross(hs, 1:3);
    case 'copy'
        set(hs.panel, 'Visible', 'off');
        clnObj = onCleanup(@() set(hs.panel, 'Visible', 'on'));
        pf = get(hs.pref, 'UserData');
        print(fh, '-dbitmap', '-noui', ['-r' pf.dpi]);
        % print(fh, '-dmeta', '-painters');
    case 'save'
        ext = get(h, 'Label');
        fmt = ext;
        if strcmp(ext, 'jpg'), fmt = 'jpeg';
        elseif strcmp(ext, 'tif'), fmt = 'tiff';
        elseif strcmp(ext, 'eps'), fmt = 'epsc';
        elseif strcmp(ext, 'emf'), fmt = 'meta';
        end
        [fname, pName] = uiputfile(['*.' ext], 'Input file name to save figure');
        if ~ischar(fname), return; end
        fname = fullfile(pName, fname);
        if any(strcmp(ext, {'eps' 'pdf' 'emf'})), render = '-painters';
        else render = '-opengl';
        end
        pf = get(hs.pref, 'UserData');
        set(hs.panel, 'Visible', 'off');
        clnObj = onCleanup(@() set(hs.panel, 'Visible', 'on'));
        % print(fh, fname, render, ['-d' fmt]);
        print(fh, fname, render, '-noui', ['-d' fmt], ['-r' pf.dpi], '-cmyk');
    case 'colorbar'
        if strcmpi(get(hs.colorbar, 'Visible'), 'on')
            set(hs.colorbar, 'Visible', 'off'); 
            set(h, 'Checked', 'off');
        else 
            set(hs.colorbar, 'Visible', 'on'); 
            set(h, 'Checked', 'on');
            set_colorbar(hs);
        end
    case 'about'
        reviseDate = dicm2nii('', 'reviseDate', 'func_handle');
        str = sprintf(['nii_viewer.m by Xiangrui Li\n\n' ...
            'Last updated on 20%s\n\n', ...
            'Feedback to: xiangrui.li@gmail.com\n'], reviseDate(mfilename));
        helpdlg(str, 'About nii_viewer')
    case 'stack'
        uicontrol(double(hs.files)); % focus away from the two buttons
        i = hs.files.Value;
        p = hs.files.UserData;
        n = numel(p);
        switch get(h, 'Tag') % for both uimenu and pushbutton
            case 'up' % one level up
                if i==1, return; end
                for j = 1:3, uistack(p(i).hsI(j)); end
                ind = [1:i-2 i i-1 i+1:n]; i = i-1;
            case 'down' % one level down
                if i==n, return; end
                for j = 1:3, uistack(p(i).hsI(j), 'down'); end
                ind = [1:i-1 i+1 i i+2:n]; i = i+1;
            case 'top'
                step = i-1;
                if step==0, return; end
                for j = 1:3, uistack(p(i).hsI(j), 'up', step); end
                ind = [i 1:i-1 i+1:n]; i = 1;
            case 'bottom'
                step = n-i;
                if step==0, return; end
                for j = 1:3, uistack(p(i).hsI(j), 'down', step); end
                ind = [1:i-1 i+1:n i]; i = n;
            otherwise
                error('Unknown stack level: %s', get(h, 'Tag'));
        end
        
        str = hs.files.String;
        set(hs.files, 'String', str(ind), 'Value', i, 'UserData', p(ind));
        hs.iback = find(hs.iback == ind);
        
        hs.q = hs.q(ind);
        guidata(fh, hs);
    case 'saveas' % this uses nii_tool/xform_nii, and not related to viewer
        save_nii_as(hs, get(h, 'Label'));
    case 'zoom'
        m = str2double(get(h, 'Label'));
        a = min(hs.dim) / m;
        if a<1, m = min(hs.dim); end
        set_zoom(m, hs);
    case 'mask'
        addMask(hs, h);
    case 'background'
        if strcmp(get(h, 'Checked'), 'on');
            set(h, 'Checked', 'off');
            hs.frame.BackgroundColor = [0 0 0];
            set(hs.colorbar, 'EdgeColor', [1 1 1]);
        else
            set(h, 'Checked', 'on');
            hs.frame.BackgroundColor = [1 1 1];
            set(hs.colorbar, 'EdgeColor', [0 0 0]);
        end
        set_cdata(hs);
    case 'flipLR'
        if strcmp(get(h, 'Checked'), 'on');
            set(h, 'Checked', 'off');
            set(hs.ax([2 3]), 'XDir', 'normal');
            set(hs.ras([3 5]), 'String', 'L');
        else
            set(h, 'Checked', 'on');
            set(hs.ax([2 3]), 'XDir', 'reverse');
            set(hs.ras([3 5]), 'String', 'R');
        end
    case 'keyHelp'
        str = sprintf([ ...
           'Following key press are effective when the focus is on the\n' ...
           'figure or file list, but not other uicontrol.\n\n' ...
           'Left or Right arrow key: Move crosshair left or right.\n\n' ...
           'Up or Down arrow key: Move crosshair superior or inferior.\n\n' ...
           '[ or ] key: Move crosshair posterior or anterior.\n\n' ...
           '< or > key: Decrease or increase volume number.\n\n' ...
           'Ctrl + or - key: Zoom in or out by 10%% around crosshair.\n\n' ...
           'A: Toggle on/off crosshair.\n\n' ...
           'C: Crosshair to view center.\n\n' ...
           'X: Toggle on/off selected image.\n\n' ...
           'F1: Show help text.\n']);
        helpdlg(str, 'Key Shortcut');
    case 'center' % image center
        jf = hs.files.Value;
        dim = hs.q{jf}.nii.hdr.dim(2:4);
        c = round(hs.q{hs.iback}.R \ (hs.q{jf}.R * [dim/2-1 1]')) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'viewCenter'
        c(1) = mean(get(hs.ax(2), 'XLim'));
        c(2) = mean(get(hs.ax(1), 'XLim'));
        c(3) = mean(get(hs.ax(1), 'YLim'));
        c = round(c-0.5);
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'toXYZ'
        c = cell2mat(get(hs.ijk, 'Value'));
        c = hs.q{hs.iback}.R * [c-1; 1];
        c = sprintf('%g %g %g', round(c(1:3)));
        str = 'X Y Z coordinates in mm';
        a = inputdlg(str, 'Set crosshair to a point', 1, {c});
        if isempty(a), return; end
        c = sscanf(a{1}, '%g %g %g');
        if numel(c) ~= 3
            errordlg('Invalid XYZ coordinates');
            return;
        end
        c = round(hs.q{hs.iback}.R \ [c(:); 1]) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'toCOG'
        jf = hs.files.Value;
        img = hs.q{jf}.nii.img(:,:,:,hs.volume.getValue);
        img(isnan(img)) = 0;
        img = double(abs(img));
        gs = sum(img(:));
        c = ones(3,1);
        for i = 1:3
            if size(img,i)==1, continue; end
            a = shiftdim(img, i-1);
            a = sum(sum(a,3),2);
            c(i) = (1:size(img,i)) * a / gs;
        end
        c = round(hs.q{hs.iback}.R \ (hs.q{jf}.R * [c-1; 1])) + 1;
        for i = 1:3, hs.ijk(i).setValue(c(i)); end
    case 'custom'
        pName = get(hs.add, 'UserData');
        [fname, pName] = uigetfile([pName '/*.lut'], 'Select LUT file');
        if ~ischar(fname), return; end
        [~, nam] = fileparts(fname);
        nam = strtok(nam, '.');
        str = hs.lut.String;
        ind = find(strcmp(str, nam));
        if ~isempty(ind)
            set(hs.lut, 'Value', ind);
        else
            fname = fullfile(pName, fname);
            fid = fopen(fname);
            lut = fread(fid, '*uint8');
            fclose(fid);
            lut = reshape(lut, [numel(lut)/3 3]);
            lut = single(lut) / 255;
            hs.lutStr{end+1} = lut;
            guidata(fh, hs);
            set(hs.lut, 'String', [str; nam], 'Value', numel(str)+1);
        end
        nii_viewer_cb(hs.lut, [], 'lut', fh);
    case 'plot'
        i = hs.files.Value;
        img = hs.q{i}.nii.img;
        dim = size(img); dim(numel(dim)+1:4) = 1;
        if dim(4)<2, return; end
        d = num2str(getappdata(h, 'edge'));
        d = inputdlg(['Cube will be around crosshair.' char(10) ...
            'Enter edge length in voxels'], 'Time course', 1, {d});
        if isempty(d), return; end
        d = str2double(d{1});
        setappdata(h, 'edge', d);
        r = (d-1) / 2;
        for j=3:-1:1, c(j) = get(hs.ijk(j), 'Value'); end
        if isfield(hs.q{i}, 'R0')
            c = hs.q{i}.R \ (hs.q{i}.R0 * [c-1 1]');
            c = c(1:3)' + 1;       
        end
        x = max(1, round(c(1)-r)) : min(dim(1), round(c(1)+r));
        y = max(1, round(c(2)-r)) : min(dim(2), round(c(2)+r));
        z = max(1, round(c(3)-r)) : min(dim(3), round(c(3)+r));
        img = img(x,y,z,:);
        dim = size(img);
        img = reshape(img, [prod(dim(1:3)) dim(4)]);
        img = mean(single(img), 1);
        fh1 = figure(9); plot(img); 
        xlabel('Volume number');
        str = hs.files.String;
        c = sprintf('(%g,%g,%g)', round(c));
        set(fh1, 'Name', [str{i}(3:end) ' time course around voxel ' c]);
    otherwise
        error('Unknown Callback: %s', cmd);
end

%% zoom in/out with a factor
function set_zoom(m, hs)
c = hs.dim(:) / 2;
if m <= 1, I = c; % full view regardless of crosshair location
else I = cell2mat(get(hs.ijk, 'Value'));
end
lim = round([I I] + c/m*[-1 1]) + 0.5;
axis(hs.ax(1), [lim(2,:) lim(3,:)]);
axis(hs.ax(2), [lim(1,:) lim(3,:)]);
axis(hs.ax(3), [lim(1,:) lim(2,:)]);

%% KeyPressFcn callback for hs.files and figure
function KeyPressFcn(h, evt)
key = evt.Key;
ctl = evt.Modifier;
if any(strcmpi(ctl, 'control')) && strcmpi(get(h, 'Type'), 'figure')
    set(h, 'UserData', true); % for javaDropFcn
end
if isempty(key) || any(strcmp(key, ctl)), return; end
hs = guidata(h);
if ~isempty(ctl) && (any(strcmp(ctl, 'control')) || any(strcmp(ctl, 'command')))
    if any(strcmp(key, {'a' 'o' 'r' 'q' 'w'})) % only 'a' wont pass to figure
        if strcmp(key, 'a') && strcmpi(get(h, 'Type'), 'uicontrol') % not fig
            nii_viewer_cb(hs.add, [], 'add', hs.fig); 
        end
    elseif strcmp(key, 'add') || strcmp(key, 'equal')
        [dim, i] = min(hs.dim);
        if     i==1, d = get(hs.ax(2), 'XLim');
        elseif i==2, d = get(hs.ax(1), 'XLim');
        else         d = get(hs.ax(1), 'YLim');
        end
        d = abs(diff(d'));
        if d<=3, return; end % ignore
        m = dim / d * 1.1;
        if round(dim/2/m)==d/2, m = dim / (d-1); end
        set_zoom(m, hs);
    elseif strcmp(key, 'subtract') || strcmp(key, 'hyphen')
        d = abs(diff(get(hs.ax(2), 'XLim')));
        m = hs.dim(1) / d;
        if m<=1, return; end
        m = m / 1.1;
        if round(hs.dim(1)/2/m)==d/2, m = hs.dim(1) / (d+1); end
        if m<1.01, m = 1; end
        set_zoom(m, hs);
   end
   return;
end

switch key
    case 'leftarrow'
        val = max(get(hs.ijk(1), 'Value')-1, 1);
        hs.ijk(1).setValue(val);
    case 'rightarrow'
        val = min(get(hs.ijk(1), 'Value')+1, hs.dim(1));
        hs.ijk(1).setValue(val);
    case 'uparrow'
        if ~strcmpi('figure', get(h, 'Type')) && ...
                getappdata(hs.files, 'PreviousValue')>1
            drawnow; set_file(hs); % drawnow to force Value update
            return; % avoid dual effect
        end
        val = min(get(hs.ijk(3),'Value')+1, hs.dim(3));
        hs.ijk(3).setValue(val);
    case 'downarrow'
        if ~strcmpi('figure', get(h,'Type')) && ...
                getappdata(hs.files, 'PreviousValue') < numel(hs.q)
            drawnow; set_file(hs); % drawnow to force Value update
            return;
        end
        val = max(get(hs.ijk(3),'Value')-1, 1);
        hs.ijk(3).setValue(val);
    case 'rightbracket' % ]
        val = min(get(hs.ijk(2),'Value')+1, hs.dim(2));
        hs.ijk(2).setValue(val);
    case 'leftbracket' % [
        val = max(get(hs.ijk(2),'Value')-1, 1);
        hs.ijk(2).setValue(val);
    case 'period' % . or >
        val = min(get(hs.volume,'Value')+1, get(hs.volume.Model,'Maximum'));
        hs.volume.setValue(val);
    case 'comma' % , or <
        val = max(get(hs.volume,'Value')-1, 1);
        hs.volume.setValue(val);
    case 'c'
        nii_viewer_cb([], [], 'viewCenter', hs.fig);
    case 'x'
        toggle_img(hs);
    case 'a'
        h = findobj(hs.fig, 'Type', 'uimenu', 'Label', 'Show crosshair');
        nii_viewer_cb(h, [], 'cross', hs.fig);
    case 'f1'
        doc nii_viewer;
end

%% Drop callback: drop as background, Ctrl-drop as overlay
% No method was found to simply detect Ctrl key like KbCheck, even with java.
% Here we try three methods one by one to minimize the chance to miss Control
% key. 1, CurrentModifier; 2, KeyPressFnc to set UserData; 3, java robot click
% to set SelectionType to alt. Still miss Ctl sometimes.
function javaDropFcn(~, evt, fh)
try
    % drawnow/pause sets CurrentModifier & fires KeyPressFnc, but not for Linux
    fh.UserData = false; % KeyPressFnc will set it ture if ctlDn
    figure(fh); drawnow; oldState = pause('on'); pause(0.2);
    cln1 = onCleanup(@() pause(oldState));
    
    ctlDn = any(strcmpi(fh.CurrentModifier, 'control'));
    if ~ctlDn, ctlDn = fh.UserData; end
    if ~ctlDn % this seems to be the only fallback for Linux
        mouseXY = get(0, 'PointerLocation');
        cln = onCleanup(@() set(0, 'PointerLocation', mouseXY));
        hs = guidata(fh);
        posF = getpixelposition(fh);
        posA = getpixelposition(hs.ax(4), true); % relative to figure
        c = posF(1:2) + posA(1:2) + posA(3:4)/2; % ax(4) center xy
        res = screen_pixels;
        robot = java.awt.Robot;
        robot.mouseMove(c(1), res(2)-c(2)); 
        btn1 = java.awt.event.InputEvent.BUTTON1_MASK; % 16
        robot.mousePress(btn1); pause(0.1); robot.mouseRelease(btn1);
        ctlDn = strcmpi(fh.SelectionType, 'alt');
    end
    
    if strcmp(evt.DropType, 'file')
        fname = evt.Data{1};
    else % string
        fname = strtrim(evt.Data);
    end
    nii_tool('hdr', fname); % make sure valid nii
   
    if ctlDn
        addOverlay(fname, fh);
    else    
        nii_viewer(fname, guidata(fh));
    end
catch me
    errordlg(me.message);
end

%% update CData/AlphaData for 1 or 3 of the sag/cor/tra views
function set_cdata(hs, iaxis)
if nargin<2, iaxis = 1:3; end
interStr = get(hs.interp, 'String');
p = hs.files.UserData;
for i = 1:numel(p)
    if ~p(i).show, continue; end % save time, but need to update when enabled
    lut = p(i).lut;
    if lut == 11 % "lines" special case: do it separately
        vector_lines(hs, i, iaxis); continue; 
    elseif ~strcmpi(get(p(i).hsI(1), 'Type'), 'image') % was "lines"
        delete(p(i).hsI); % delete quiver
        p(i).hsI = copyimg(hs);
        hs.files.UserData = p; % update hsI
        if i>1, for j=1:3; uistack(p(i).hsI(j), 'down', i-1); end; end
    end
    t = round(p(i).volume);
    img = hs.q{i}.nii.img;
    isRGB = size(img, 8)>2;
    if isRGB % avoid indexing for single vol img: could speed up a lot
        img = permute(img(:,:,:,t,:,:,:,:), [1:3 8 4:7]);
    elseif size(img,4)>1 && lut~=29
        img = img(:,:,:,t);
    end    
    if ~isfloat(img)
        img = single(img);
        if isfield(hs.q{i}, 'scl_slope')
            img = img * hs.q{i}.scl_slope + hs.q{i}.scl_inter;
        end
    end
    
    if isfield(hs.q{i}, 'mask'),
        img = bsxfun(@times, img, hs.q{i}.mask);
    end
    if isfield(hs.q{i}, 'modulation')
        img = bsxfun(@times, img, hs.q{i}.modulation);
    end

    if any(lut == 26:28) % interp/smooth both mag and phase
        img(:,:,:,2) = hs.q{i}.phase(:,:,:,t);
    end
    
    dim4 = size(img,4);
    for ix = iaxis
        ind = get(hs.ijk(ix), 'Value'); % faster than hs.ijk(ix).getValue
        ind = round(ind);
        if ind<1 || ind>hs.dim(ix), continue; end
        ii = {':' ':' ':'};
        io = ii;
        dim = hs.dim;
        dim(ix) = 1; % 1 slice at dim ix
        im = zeros([dim dim4], 'single');
        
        if isfield(hs.q{i}, 'R0') % interp, maybe smooth
            [Y, X, Z] = meshgrid(1:dim(2), 1:dim(1), 1:dim(3));
            I = [X(:) Y(:) Z(:)]' - 1; % ijk grids of background img
            I(ix,:) = ind-1; I(4,:) = 1;
            I = hs.q{i}.R \ (hs.q{i}.R0 * I) + 1; % ijk+1 for overlay img
            
            for j = 1:dim4
                if p(i).smooth
                    ns = 3; % number of voxels (odd) used for smooth
                    d3 = dim; d3(ix) = ns; % e.g. 3 slices
                    b = zeros(d3, 'single');
                    I0 = I(1:3,:);
                    for k = 1:ns % interp for each slice
                        I0(ix,:) = I(ix,:) - (ns+1)/2 + k;
                        a = interp3a(img(:,:,:,j), I0, interStr{p(i).interp});
                        ii{ix} = k; b(ii{:}) = reshape(a, dim);
                    end
                    b = smooth23(b, 'gaussian', ns);
                    io{ix} = (ns+1)/2;
                    im(:,:,:,j) = b(io{:}); % middle one
                else
                    a = interp3a(img(:,:,:,j), I, interStr{p(i).interp});
                    im(:,:,:,j) = reshape(a, dim);
                end
            end
        elseif p(i).smooth % smooth only
            ns = 3; % odd number of slices to smooth
            ind1 = ind - (ns+1)/2 + (1:ns); % like ind+(-1:1)
            if any(ind1<1 | ind1>hs.dim(ix)), ind1 = ind; end % 2D
            ii{ix} = ind1;
            io{ix} = mean(1:numel(ind1)); % middle slice
            for j = 1:dim4
                a = smooth23(img(ii{:},j), 'gaussian', ns);
                im(:,:,:,j) = a(io{:});
            end
        else % no interp or smooth
            io{ix} = ind;
            im(:) = img(io{:}, :);
        end
        
        if     ix == 1, im = permute(im, [3 2 4 1]);
        elseif ix == 2, im = permute(im, [3 1 4 2]);
        elseif ix == 3, im = permute(im, [2 1 4 3]);
        end
        
        if ~isRGB % not NIfTI RGB
            rg = sort([p(i).lb p(i).ub]);
            if any(lut == 26:28)
                im = im(:,:,2) .* single(im(:,:,1)>min(abs(rg))); % mag as mask
                rg = [0 1]; % disable later scaling
            end
            if rg(2)<0 % asking for negative data
                rg = -rg([2 1]);
                if lut~=10, im = -im; end
            end
            if lut == 10 % two-sided, store negative value
                rg = sort(abs(rg));
                im_neg = -single(im) .* (im<0);
                im_neg = (im_neg-rg(1)) / (rg(2)-rg(1));
                im_neg(im_neg>1) = 1; im_neg(im_neg<0) = 0;
                alfa = im_neg; % add positive part later
                im_neg = repmat(im_neg, [1 1 3]); % gray now
            else
                alfa = single(0);
            end
            
            if lut ~= 29 % not forced into RGB
                im = (im-rg(1)) / (rg(2)-rg(1));
                im(im>1) = 1; im(im<0) = 0;
                alfa = im + alfa;
                im = repmat(im, [1 1 3]); % gray now
            end
            
            switch lut
                case 1, % gray do nothing
                case 2, im(:,:,2:3) = 0; % red
                case 3, im(:,:,[1 3]) = 0; % green
                case 4, im(:,:,1:2) = 0; % blue
                case 5, im(:,:,2) = 0; % violet
                case 6, im(:,:,3) = 0; % yellow
                case 7, im(:,:,1) = 0; % cyan
                case {8 19} % red_yellow, autumn
                    a = im(:,:,1); a(a>0) = 1; im(:,:,1) = a;
                    im(:,:,3) = 0;
                case 9 % blue_green
                    im(:,:,1) = 0;
                    a = im(:,:,3); a(a==0) = 1; a = 1 - a; im(:,:,3) = a;
                case 10 % two-sided: combine red_yellow & blue_green
                    im(:,:,3) = 0;
                    a = im(:,:,1); a(a>0) = 1; im(:,:,1) = a;
                    im_neg(:,:,1) = 0;
                    a = im_neg(:,:,3); a(a==0) = 1; a = 1 - a; im_neg(:,:,3) = a;
                    im = im + im_neg;
                case 15 % hot
                    a = im(:,:,1); a = a/0.375; a(a>1) = 1; im(:,:,1) = a;
                    a = im(:,:,2); a = a/0.375-1;
                    a(a<0) = 0; a(a>1) = 1; im(:,:,2) = a;
                    a = im(:,:,3); a = a*4-3; a(a<0) = 0; im(:,:,3) = a;
                case 16 % cool
                    a = im(:,:,2); a(a==0) = 1; a = 1 - a; im(:,:,2) = a;
                    a = im(:,:,3); a(a>0) = 1; im(:,:,3) = a;
                case 17 % spring
                    a = im(:,:,1); a(a>0) = 1; im(:,:,1) = a;
                    a = im(:,:,3); a(a==0) = 1; a = 1 - a; im(:,:,3) = a;
                case 18 % summer
                    a = im(:,:,2); a(a==0) = -1; a = a/2+0.5; im(:,:,2) = a;
                    a = im(:,:,3); a(a>0) = 0.4; im(:,:,3) = a;
                case 20 % winter
                    im(:,:,1) = 0;
                    a = im(:,:,3); a(a==0) = 2; a = 1-a/2; im(:,:,3) = a;
                case 22 % copper
                    a = im(:,:,1); a = a*1.25; a(a>1) = 1; im(:,:,1) = a;
                    im(:,:,2) = im(:,:,2) * 0.7812;
                    im(:,:,3) = im(:,:,3) * 0.5;
                case 26 % phase, like red_yellow
                    im(:,:,1) = 1; im(:,:,3) = 0;
                case 27 % red-yellow-green-yellow-red
                    a = im(:,:,1);
                    b1 = a<=0.25;
                    b2 = a>0.25 & a<=0.5;
                    b3 = a>0.5 & a<=0.75;
                    b4 = a>0.75;
                    a(b1 | b4) = 1;
                    a(b2) = (0.5-a(b2))*4;
                    a(b3) = (a(b3)-0.5)*4;
                    im(:,:,1) = a;
                    
                    a = im(:,:,2);
                    a(b2 | b3) = 1;
                    a(b1) = a(b1)*4;
                    a(b4) = (1-a(b4))*4;
                    im(:,:,2) = a;
                    
                    im(:,:,3) = 0;
                case 28 % red-yellow-green/violet-blue-cyan
                    a = im(:,:,1);
                    b1 = a<=0.25;
                    b2 = a>0.25 & a<=0.5;
                    b3 = a>0.5 & a<=0.75;
                    b4 = a>0.75;
                    a(b2) =  (0.5-a(b2))*4; a(b1) = 1;
                    a(b3) = (0.75-a(b3))*4; a(b4) = 0;
                    im(:,:,1) = a;
                    
                    a = im(:,:,2);
                    a(b1) = a(b1)*4; a(b2) = 1;
                    a(b3) = 0; a(b4) = (a(b4)-0.75)*4;
                    im(:,:,2) = a;
                    
                    a = im(:,:,3);
                    a(b1 | b2) = 0;
                    a(b3 | b4) = 1;
                    im(:,:,3) = a;
                case 29 % disp non-NIfTI RGB as RGB
                    if min(im(:)) < 0 % use abs if there is negative value
                        rg(1) = 0;
                        im = abs(im);
                    end
                    if hs.q{i}.nii.hdr.datatype==2, rg = [0 255]; end % uint8
                    if max(im(:)) > 1
                        im = (im-rg(1)) / (rg(2)-rg(1));
                    end
                    im(im>1) = 1; im(im<0) = 0;
                   alfa = sum(im,3)/3;
                otherwise % parula(12), jet(13), hsv(14), bone(21), pink(23), custom
                    if lut <= 25
                        try
                            map = feval(hs.lut.String{lut}, 256);
                        catch me
                            if lut == 12 % parula is not in old matlab
                                map = lut2map(lut);
                            else
                                rethrow(me);
                            end
                        end
                        a = round(im(:,:,1) * size(map,1));
                    else % custom
                        map = hs.lutStr{lut};
                        a = round(im(:,:,1) * (size(map,1)-1)) + 1; % 1st is bkgrnd
                    end
                    
                    for j = 1:size(a,1)
                        for k = 1:size(a,2)
                            if a(j,k)>0, im(j,k,:) = map(a(j,k),:); end
                        end
                    end                    
%                     ua = unique(a)';
%                     ua(isnan(ua)) = [];
%                     if ua(1)==0, ua(1) = []; end
%                     R = a*0; G = R; B = R;
%                     for j = ua
%                         k = j == a;
%                         R(k) = map(j,1);
%                         G(k) = map(j,2);
%                         B(k) = map(j,3);
%                     end
%                     im = cat(3, R, G, B);
            end
        elseif dim4 == 3 % NIfTI RGB
            if max(im(:))>2, im = im / 255; end % guess uint8
            im(im>1) = 1; im(im<0) = 0;
            alfa = sum(im,3) / dim4; % avoid mean
        elseif dim4 == 4 % NIfTI RGBA
            if max(im(:))>2, im = im / 255; end % guess uint8
            im(im>1) = 1; im(im<0) = 0;
            alfa = im(:,:,4);
            im = im(:,:,1:3);
        else
            error('Unknown data type: %s', p(i).fname);
        end
        
        if i==hs.iback && isequal(hs.frame.BackgroundColor, [1 1 1])
            alfa = img2mask(alfa);
        elseif dim4 ~= 4
            alfa = alfa > 0;
        end
        alfa = p(i).alpha * alfa;
        set(p(i).hsI(ix), 'CData', im, 'AlphaData', alfa);
    end
end

%% Add an overlay
function addOverlay(fname, fh, mtx, mtxFile)
hs = guidata(fh);
frm = hs.form_code;
aligned = nargin>2 && ~isempty(mtx);
R_back = hs.q{hs.iback}.R;
if aligned % aligned mtx: do it in special way
    [q, ~, rg, dim] = read_nii(fname, frm, 0); % no re-orient
    R0 = nii_xform_mat(hs.q{hs.iback}.nii.hdr, frm(1)); % original background R
    
    % see nii_xform for more comment on following method
    R = R0 / diag([hs.q{hs.iback}.nii.hdr.pixdim(2:4) 1]) * mtx * diag([q.pixdim 1]);
    [~, i1] = max(abs(q.R(1:3,1:3)));
    [~, i0] = max(abs(R(1:3,1:3)));
    flp = sign(R(i0+[0 4 8])) ~= sign(q.R(i1+[0 4 8]));
    if any(flp)
        rotM = diag([1-flp*2 1]);
        rotM(1:3,4) = (dim-1).* flp;
        R = R / rotM;
    end

    [q.R, perm, q.flip] = reorient(R, dim); % in case we apply mask to it
    if ~isequal(perm, 1:3)
        dim = dim(perm);
        q.pixdim = q.pixdim(perm);
        q.nii.img = permute(q.nii.img, [perm 4:8]);
    end
    for j = 1:3
        if q.flip(j), q.nii.img = flipdim(q.nii.img, j); end %#ok 
    end
    q.alignMtx = mtxFile; % info only for NIfTI essentials
else
    [q, frm, rg, dim] = read_nii(fname, frm);

    % Silently use another background R_back matching overlay: very rare
    if frm>0 && frm ~= hs.form_code(1) && any(frm == hs.form_code)
        R = nii_xform_mat(hs.q{hs.iback}.nii.hdr, frm); % img re-orient already done
        R_back = reorient(R, hs.q{hs.iback}.nii.hdr.dim(2:4));
    elseif frm ~= hs.form_code(1)
        warndlg(['There is no matching coordinate system between the overlay ' ...
         'image and the background image. The overlay is likely meaningless.'], ...
         'Transform Inconsistent');
    end
end
ii = [1 6 11 13:15]; % diag and offset
if ~isequal(hs.dim, dim) || any(abs(R_back(ii)./q.R(ii)-1) > 0.01)
    q.R0 = R_back;
end

% add a slot, and make first for new overlay after no error to read file
p = hs.files.UserData;
n = numel(p);
p(2:n+1) = p(1:n);
hs.q(2:n+1) = hs.q(1:n);
hs.q{1} = q;

% duplicate image obj for overlay: will be at top
p(1).hsI = copyimg(hs);

% set default for new overlay
p(1).fname = q.nii.hdr.file_name;
p(1).show = true; % img on
p(1).lb = rg(1); 
p(1).ub = rg(2);
p(1).lb_step = stepSize(rg(1)); 
p(1).ub_step = stepSize(rg(2));
if any(q.nii.hdr.datatype == [32 1792]) % complex
    p(1).lut = 26; % phase
elseif q.nii.hdr.intent_code == 1002 % Label
    p(1).lut = 24; % prism
else
    a = setdiff(2:7, [p.lut]); % use smallest unused lut in 2:7
    if isempty(a), a = 2; end % red
    p(1).lut = a(1);
end
p(1).alpha = 1; % opaque
p(1).smooth = false;
p(1).interp = 1; % nearest
p(1).volume = 1; % first volume

[pName, niiName, ext] = fileparts(p(1).fname);
if strcmpi(ext, '.gz'), [~, niiName] = fileparts(niiName); end
if aligned, niiName = [niiName '(aligned)']; end
str = hs.files.String;
str = [[9746 ' ' niiName]; str]; % add to the top of the list
set(hs.files, 'String', str, 'Value', 1, 'UserData', p);
set(hs.add, 'UserData', pName);
hs.iback = hs.iback + 1;

guidata(fh, hs); % update hs.q for nii
set_file(hs); % show para for new overlay
set_cdata(hs);
set_xyz(hs);

%% Reorient 4x4 R
function [R, perm, flp] = reorient(R, dim)
a = abs(R(1:3,1:3));
[~, ixyz] = max(a);
if ixyz(2) == ixyz(1), a(ixyz(2),2) = 0; [~, ixyz(2)] = max(a(:,2)); end
if any(ixyz(3) == ixyz(1:2)), ixyz(3) = setdiff(1:3, ixyz(1:2)); end
[~, perm] = sort(ixyz);
R(:,1:3) = R(:,perm);
flp = R([1 6 11]) < 0;
rotM = diag([1-flp*2 1]);
rotM(1:3, 4) = (dim(perm)-1) .* flp; % 0 or dim-1
R = R / rotM; % xform matrix after flip

%% Load, re-orient nii, return essential nii stuff
% nii.img may be re-oriented, but nii.hdr is not touched
function [q, frm, rg, dim] = read_nii(fname, ask_code, reOri)
q.nii = nii_tool('load', fname);
ndim = q.nii.hdr.dim(1);
dim = q.nii.hdr.dim(2:8);
dim(dim<1 | dim>32767 | mod(dim,1)>0) = 1;
if ndim>4 % 4+ dim, put all into dim4
    if sum(dim(4:7)>1)>1
        warndlg([fname ' has 5 or more dimension. Dimension above 4 are ' ...
            'all treated as volumes for visualization']);        
    end
    dim(4) = prod(dim(4:7)); dim(5:7) = 1;
    q.nii.img = reshape(q.nii.img, [dim size(q.nii.img, 8)]);
end

if nargin<2, ask_code = []; end
[q.R, frm] = nii_xform_mat(q.nii.hdr, ask_code);
dim = dim(1:3);
q.pixdim = q.nii.hdr.pixdim(2:4);
q.flip = false(1,3);
if nargin<3 || reOri
    [q.R, perm, q.flip] = reorient(q.R, dim);
    if ~isequal(perm, 1:3)
        dim = dim(perm);
        q.pixdim = q.pixdim(perm);
        q.nii.img = permute(q.nii.img, [perm 4:8]);
    end
    for i = 1:3, if q.flip(i), q.nii.img = flipdim(q.nii.img, i); end; end %#ok
end
if size(q.nii.img,4)<4 && ~isfloat(q.nii.img)
    q.nii.img = single(q.nii.img); 
end
if q.nii.hdr.scl_slope==0, q.nii.hdr.scl_slope = 1; end
if q.nii.hdr.scl_slope~=1 || q.nii.hdr.scl_inter~=0
    if isfloat(q.nii.img)
        q.nii.img = q.nii.img  * q.nii.hdr.scl_slope + q.nii.hdr.scl_inter;
    else
        q.scl_slope = q.nii.hdr.scl_slope;
        q.scl_inter = q.nii.hdr.scl_inter;
    end
end

% check if ROI labels available: the same file name with .txt extension
if q.nii.hdr.intent_code == 1002 % Label
    [pth, nam, ext] = fileparts(q.nii.hdr.file_name);
    nam1 = fullfile(pth, [nam '.txt']);
    if strcmpi(ext, '.gz') && ~exist(nam1, 'file')
        [~, nam] = fileparts(nam);
        nam1 = fullfile(pth, [nam '.txt']);
    end
    if exist(nam1, 'file') % each line format: 1 ROI_1
        fid = fopen(nam1);
        while 1
            ln = fgetl(fid);
            if ~ischar(ln), break; end
            [ind, a] = strtok(ln);
            ind = str2double(ind);
            try q.labels{ind} = strtrim(a); catch, end
        end
        fclose(fid);
    end
end

if ~isreal(q.nii.img)
    q.phase = angle(q.nii.img); % -pi to pi
    q.phase = mod(q.phase/(2*pi), 1); % 0~1
    q.nii.img = abs(q.nii.img); % real now
end

img = q.nii.img(:,:,:,1,1,1,1,1);
if ~isfloat(img)
    img = single(img) * q.nii.hdr.scl_slope + q.nii.hdr.scl_inter;
end

if q.nii.hdr.intent_code > 1000 || isfield(q, 'labels')
    rg = [min(img(:)) max(img(:))];
elseif q.nii.hdr.datatype == 511
    rg = [0 1];
elseif any(q.nii.hdr.datatype == [128 2304])
    rg = [0 255];
else
    rg = get_range(img);
end

%% Return xform mat and form_code: form_code may have two if no valid ask_code
function [R, frm] = nii_xform_mat(hdr, ask_code)
c = [hdr.sform_code hdr.qform_code];
f = c(c>=1 & c<=4); f(mod(f,1)>0) = []; % 1/2/3/4 only
if isempty(f) || ~strncmp(hdr.magic, 'n', 1) % make up R for Analyze file
    R = [diag(hdr.pixdim(2:4)) -(hdr.dim(2:4).*hdr.pixdim(2:4)/2)'; 0 0 0 1];
    R(1,:) = -R(1,:); % left handed?
    frm = 0;
    return;
end
useS = true; frm = c(1);
if nargin<2 || isempty(ask_code)
    if c(1)<1 && c(2)>0, frm = c(2); useS = false; end
    if all(c>0) && c(1)~=c(2), frm(2) = c(c~=frm); end % return 2 frm code
elseif numel(ask_code) == 1
    if c(1)~=ask_code && c(2)==ask_code, frm = c(2); useS = false; end
elseif numel(ask_code) == 2
    if c(1)~=ask_code(1) && ... 
          (c(2)==ask_code(1) || (c(1)~=ask_code(2) && c(2)==ask_code(2)))
        frm = c(2); useS = false;
    end
end
if useS
    R = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
else % use qform
    b = hdr.quatern_b;
    c = hdr.quatern_c;
    d = hdr.quatern_d;
    a = sqrt(1-b*b-c*c-d*d);
    R = [1-2*(c*c+d*d)  2*(b*c-d*a)     2*(b*d+c*a);
         2*(b*c+d*a)    1-2*(b*b+d*d)   2*(c*d-b*a);
         2*(b*d-c*a )   2*(c*d+b*a)     1-2*(b*b+c*c)];
    R = R * diag(hdr.pixdim(2:4));
    if hdr.pixdim(1)<0, R(:,3) = -R(:,3); end % qfac
    R = [R [hdr.qoffset_x hdr.qoffset_y hdr.qoffset_z]'; 0 0 0 1];
end

%% Create java SpinnerNumber
% h = java_spinner(pos_1x4, [val min max step], parent, callback, fmt, helpTxt)
function h = java_spinner(pos, val, parent, callback, fmt, helpTxt)
mdl = javax.swing.SpinnerNumberModel(val(1), val(2), val(3), val(4));
% jSpinner = javax.swing.JSpinner(mdl);
jSpinner = com.mathworks.mwswing.MJSpinner(mdl);
h = javacomponent(jSpinner, pos, parent);
set(h, 'StateChangedCallback', callback, 'ToolTipText', helpTxt);
jEditor = javaObject('javax.swing.JSpinner$NumberEditor', h, fmt);
h.setEditor(jEditor);
h.setFont(java.awt.Font('Tahoma', java.awt.Font.PLAIN, 11));

%% estimate intensity for lower and upper bound of display
function rg = get_range(img)
if size(img,8)>2
    if max(img(:))>2, rg = [0 255];
    else rg = [0 1];
    end
    return;
end
ind = abs(img(:))>50;
if sum(ind)<numel(img)/10, ind = abs(img(:))>std(img(:))/2; end
im = img(ind);
mn = mean(im);
sd = std(im);
rg = mn + [-2 2]*sd;
mi = min(img(:)); ma = max(img(:));
if rg(1)<=0 && mn-sd>0, rg(1) = sd/5; end
if rg(1)<mi || isnan(rg(1)), rg(1) = mi; end
if rg(2)>ma || isnan(rg(2)), rg(2) = ma; end
if rg(1)==rg(2), rg(1) = mi; end
rg = str2num(sprintf('%.2g ', rg)); %#ok<*ST2NM>
if rg(1)==rg(2), rg(1) = mi; end
if abs(rg(1))>10, rg(1) = floor(rg(1)/2)*2; end % even number
if abs(rg(2))>10, rg(2) = ceil(rg(2)/2)*2; end % even number

%% Draw vector lines, called by set_cdata
function vector_lines(hs, i, iaxis)
p = hs.files.UserData;
dim = single(size(hs.q{i}.nii.img));
if strcmpi(get(p(i).hsI(1), 'Type'), 'image') % just switch to "lines"
    delete(p(i).hsI);
    lut = hs.lut.UserData; % last lut
    if isempty(lut), lut = 2; end % default red
    clr = lut2map(lut, hs); clr = clr(end,:);
    cb = get(hs.hsI(1), 'ButtonDownFcn');
    for j = 1:3
        p(i).hsI(j) = quiver(hs.ax(j), 1, 1, 0, 0, 'Color', clr, ...
            'ShowArrowHead', 'off', 'AutoScale', 'off', 'ButtonDownFcn', cb);
    end
    crossFront(hs); % to be safe before next
    if i>1, for j = 1:3, uistack(p(i).hsI(j), 'down', i-1); end; end
    hs.files.UserData = p;
    
    if isfield(hs.q{i}, 'R0') && ~isfield(hs.q{i}, 'ivec')
        [Y, X, Z] = meshgrid(1:dim(2), 1:dim(1), 1:dim(3));
        I = [X(:) Y(:) Z(:)]' - 1; I(4,:) = 1;
        I = hs.q{i}.R0 \ (hs.q{i}.R * I) + 1;
        hs.q{i}.ivec = reshape(I(1:3,:)', dim);

        R0 = hs.q{i}.R0(1:3, 1:3);
        R0 = bsxfun(@rdivide, R0, sqrt(sum(R0.^2)));
        R = hs.q{i}.R(1:3, 1:3);
        R = bsxfun(@rdivide, R, sqrt(sum(R.^2)));
        [pd, j] = min(hs.q{i}.pixdim);
        hs.q{i}.Rvec = R0 / R * pd / hs.q{hs.iback}.pixdim(j);
        
        guidata(hs.fig, hs);
    end
end

img = hs.q{i}.nii.img;
% This is needed since vec is in image ref, at least for fsl
img(:,:,:,hs.q{i}.flip) = -img(:,:,:,hs.q{i}.flip);
if isfield(hs.q{i}, 'mask') % ignore modulation
    img = bsxfun(@times, img, hs.q{i}.mask);
end
if any(abs(diff(hs.q{hs.iback}.pixdim))>1e-4) % non isovoxel background
    pd = hs.q{hs.iback}.pixdim;
    pd = pd / min(pd);
    for j = 1:3, img(:,:,:,j) = img(:,:,:,j) / pd(j); end
end

if isfield(hs.q{i}, 'Rvec')
    img = reshape(img, [prod(dim(1:3)) dim(4)]);
    img = img * hs.q{i}.Rvec;
    img = reshape(img, dim);
end

for ix = iaxis
    I = round(get(hs.ijk(ix), 'Value'));
    j = 1:3; j(ix) = [];
    if isfield(hs.q{i}, 'ivec')
        I = abs(hs.q{i}.ivec(:,:,:,ix) - I);
        [~, I] = min(I, [], ix);
        
        ii = {1:dim(1) 1:dim(2) 1:dim(3)};
        ii{ix} = single(1);
        [ii{2}, ii{1}, ii{3}] = meshgrid(ii{[2 1 3]});
        ii{ix} = single(I);
        io = {':' ':' ':' ':'}; io{ix} = 1;
        im = img(io{:});
        for k = 1:2
            im(:,:,:,k) = interp3(img(:,:,:,j(k)), ii{[2 1 3]}, 'nearest');
        end
    
        ind = sub2ind(dim(1:3), ii{:});
        X = hs.q{i}.ivec(:,:,:,j(1)); X = permute(X(ind), [j([2 1]) ix]);
        Y = hs.q{i}.ivec(:,:,:,j(2)); Y = permute(Y(ind), [j([2 1]) ix]);    
    else
        ii = {':' ':' ':'};
        ii{ix} = I;
        im = img(ii{:}, j);
        [X, Y] = meshgrid(1:dim(j(1)), 1:dim(j(2)));
    end
    
    im = permute(im, [j([2 1]) 4 ix]);
    im(im==0) = nan; % avoid dots in emf and eps
    X = X - im(:,:,1)/2;
    Y = Y - im(:,:,2)/2;
    set(p(i).hsI(ix), 'XData', X, 'YData', Y, 'UData', im(:,:,1), 'VData', im(:,:,2));
end

%% Bring cross and label to front
function crossFront(hs)
for i = 1:3
    txt = allchild(hs.ax(i));
    ind = strcmpi(get(txt, 'Type'), 'text');
    txt = txt(ind); % a number, two letters, plus junk text with matlab 2010b
    uistack([txt' hs.cross(i,:)], 'top');
end

%% Compute color map for LUT
function map = lut2map(lut, hs)
map = linspace(0,1,64)'*[1 1 1]; % gray
if     lut == 1, return; % gray
elseif lut == 2, map(:,2:3) = 0; % red
elseif lut == 3, map(:,[1 3]) = 0; % green
elseif lut == 4, map(:,1:2) = 0; % blue
elseif lut == 5, map(:,2) = 0; % violet
elseif lut == 6, map(:,3) = 0; % yellow
elseif lut == 7, map(:,1) = 0; % cyan
elseif any(lut == [8 19 26]), map(:,3) = 0; map(:,1) = 1; % red_yellow
elseif lut == 9, map(:,1) = 0; map(:,3) = map(end:-1:1,3); % blue_green
elseif lut == 10 % two-sided
    map = map(1:2:end,:); % half
    map_neg = map;
    map(:,3) = 0; map(:,1) = 1; % red_yellow
    map_neg(:,1) = 0; map_neg(:,3) = map_neg(end:-1:1,3); % blue_green
    map = [map_neg(end:-1:1,:); map];
elseif lut == 11, map(:,2:3) = 0; % vector lines
elseif lut == 12 % parula not in old matlab, otherwise this can be omitted
    map = [ 0.208 0.166 0.529
            0.212 0.190 0.578
            0.212 0.214 0.627
            0.208 0.239 0.677
            0.196 0.264 0.728
            0.171 0.292 0.779
            0.125 0.324 0.830
            0.059 0.360 0.868
            0.012 0.388 0.882
            0.006 0.409 0.883
            0.017 0.427 0.879
            0.033 0.443 0.872
            0.050 0.459 0.864
            0.063 0.474 0.855
            0.072 0.489 0.847
            0.078 0.504 0.838
            0.079 0.520 0.831
            0.075 0.538 0.826
            0.064 0.557 0.824
            0.049 0.577 0.823
            0.034 0.597 0.820
            0.026 0.614 0.814
            0.024 0.629 0.804
            0.023 0.642 0.791
            0.023 0.653 0.777
            0.027 0.664 0.761
            0.038 0.674 0.744
            0.059 0.684 0.725
            0.084 0.693 0.706
            0.113 0.702 0.686
            0.145 0.710 0.665
            0.180 0.718 0.642
            0.218 0.725 0.619
            0.259 0.732 0.595
            0.302 0.738 0.571
            0.348 0.742 0.547
            0.395 0.746 0.524
            0.442 0.748 0.503
            0.487 0.749 0.484
            0.530 0.749 0.466
            0.571 0.749 0.449
            0.610 0.747 0.434
            0.647 0.746 0.419
            0.683 0.743 0.404
            0.718 0.741 0.390
            0.752 0.738 0.377
            0.786 0.736 0.363
            0.819 0.733 0.350
            0.851 0.730 0.336
            0.882 0.727 0.322
            0.914 0.726 0.306
            0.945 0.726 0.289
            0.974 0.731 0.267
            0.994 0.745 0.240
            0.999 0.765 0.216
            0.996 0.786 0.197
            0.988 0.807 0.179
            0.979 0.827 0.163
            0.970 0.848 0.147
            0.963 0.871 0.131
            0.959 0.895 0.113
            0.960 0.922 0.095
            0.966 0.951 0.076
            0.976 0.983 0.054];
elseif lut < 26 % matlab LUT
    map = feval(hs.lut.String{lut}, 64);
elseif lut == 27 % phase3: red-yellow-green-yellow-red
    a = map(:,1);
    map(1:32,3) = 0; map(1:16,1) = 1; map(17:32,2) = 1;
    map(1:16,2) = a(1:4:64); map(17:32,1) = a(64:-4:1);
    map(33:64,:) = map(32:-1:1,:);
elseif lut == 28 % phase6: red-yellow-green/violet-blue-cyan
    a = map(:,1);
    map(1:32,3) = 0; map(1:16,1) = 1; map(17:32,2) = 1;
    map(1:16,2) = a(1:4:64); map(17:32,1) = a(64:-4:1);
    map(33:48,2) = 0; map(33:48,3) = 1; map(33:48,1) = a(64:-4:1);
    map(49:64,1) = 0; map(49:64,3) = 1; map(49:64,2) = a(1:4:64);
elseif lut == 29 % RGB
else % custom
    map = hs.lutStr{lut};
end

%% Preference dialog
function pref_dialog(pref)
pf = get(pref, 'UserData');
d = dialog('Name', 'Preferences', 'Visible', 'off');
pos = getpixelposition(d);
pos(3:4) = [396 300];
h.fig = ancestor(pref, 'figure');  

uicontrol('Parent', d, 'Style', 'text', 'Position', [8 274 300 22], ...
    'String', 'Background (template) image folder:', 'HorizontalAlignment', 'left');
h.openPath = uicontrol(d, 'Style', 'edit', 'String', pf.openPath, ...
    'Position', [8 256 350 22], 'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
    'TooltipString', 'nii_viewer will point to this folder when you "Open" image');
uicontrol('Parent', d, 'Position', [358 257 30 22], 'Tag', 'browse', ...
    'String', '...', 'Callback', @pref_dialog_cb);

h.rightOnLeft = uicontrol(d, 'Style', 'popup', 'BackgroundColor', 'w', ...
    'Position', [8 220 380 22], 'Value', pf.rightOnLeft+1, ...
    'String', {'Neurological orientation (left on left side)' ...
               'Radiological orientation (right on left side)'}, ...
    'TooltipString', 'Display convention also applies to future use');

h.mouseOver = uicontrol(d, 'Style', 'checkbox', ...
    'Position', [8 182 380 22], 'Value', pf.mouseOver, ...
    'String', 'Show coordinates and intensity when mouse moves over image', ...
    'TooltipString', 'Also apply to future use');

uipanel(d, 'Units', 'Pixels', 'Position', [4 110 390 56], 'BorderType', 'etchedin', ...
    'BorderWidth', 2, 'Title', 'For "Save NIfTI as" if interpolation is applicable');
str = {'nearest' 'linear' 'cubic' 'spline'};
val = find(strcmp(str, pf.interp));
uicontrol('Parent', d, 'Style', 'text', 'Position', [8 116 140 22], ...
    'String', 'Interpolation method:', 'HorizontalAlignment', 'right');
h.interp = uicontrol(d, 'Style', 'popup', 'String', str, ...
    'Position', [150 120 68 22], 'Value', val, 'BackgroundColor', 'w');

uicontrol('Parent', d, 'Style', 'text', 'Position', [230 116 90 22], ...
    'String', 'Missing value:', 'HorizontalAlignment', 'right');
h.extraV = uicontrol(d, 'Style', 'edit', 'String', num2str(pf.extraV), ...
    'Position', [324 120 60 22], 'BackgroundColor', 'w', ...
    'TooltipString', 'NaN or 0 is typical, but can be any number');

str = strtrim(cellstr(num2str([0 120 150 200 300 600 1200]')));
val = find(strcmp(str, pf.dpi));
uipanel(d, 'Units', 'Pixels', 'Position', [4 40 390 56], 'BorderType', 'etchedin', ...
    'BorderWidth', 2, 'Title', 'For "Save figure as" and "Copy figure"');
uicontrol('Parent', d, 'Style', 'text', 'Position', [8 46 90 22], ...
    'String', 'Resolution:', 'HorizontalAlignment', 'right');
h.dpi = uicontrol(d, 'Style', 'popup', 'String', str, ...
    'Position', [110 50 50 22], 'Value', val, 'BackgroundColor', 'w', ...
    'TooltipString', 'in DPI (0 means screen resolution)');

uicontrol('Parent', d, 'Position', [300 10 70 24], 'Tag', 'OK', ...
    'String', 'OK', 'Callback', {@pref_dialog_cb, pref});
uicontrol('Parent', d, 'Position',[200 10 70 24], ...
    'String', 'Cancel', 'Callback', 'delete(gcf)');

set(d, 'Position', pos, 'Visible', 'on');
guidata(d, h);

%% Preference dialog callback
function pref_dialog_cb(h, ~, pref)
hs = guidata(h);
if strcmp(get(h, 'Tag'), 'OK') % done
    pf = get(pref, 'UserData');
    fh = hs.fig;
    
    pf.rightOnLeft = get(hs.rightOnLeft, 'Value')==2;
    hLR = findobj(fh, 'Type', 'uimenu', 'Label', 'Right on left side');
    if strcmp(get(hLR, 'Checked'), 'off') == pf.rightOnLeft
        nii_viewer_cb(hLR, [], 'flipLR', fh);
    end
    
    pf.mouseOver = get(hs.mouseOver, 'Value');
    if pf.mouseOver
        set(fh, 'WindowButtonMotionFcn', {@nii_viewer_cb 'mousemove' fh});
    else
        set(fh, 'WindowButtonMotionFcn', '');        
    end
    
    i = get(hs.interp, 'Value');
    str = get(hs.interp, 'String');
    pf.interp = str{i};
    
    pf.extraV = str2double(get(hs.extraV, 'String'));
    pf.openPath = get(hs.openPath, 'String');

    i = get(hs.dpi, 'Value');
    str = get(hs.dpi, 'String');
    pf.dpi = str{i}; 
        
    set(pref, 'UserData', pf);
    setpref('nii_viewer_para', fieldnames(pf), struct2cell(pf));
    delete(get(h, 'Parent'));
elseif strcmp(get(h, 'Tag'), 'browse') % set openPath
    pth = uigetdir(pwd, 'Select folder for background image');
    if ~ischar(pth), return; end
    set(hs.openPath, 'String', pth);
end

%% Simple version of interp3
function V = interp3a(V, I, method)
persistent v;
if isempty(v)
    try 
        griddedInterpolant({1:3, 1:3, 1:3}, ones(3,3,3), 'nearest', 'none');
        v = 2014;
    catch
        try
            griddedInterpolant({1:3, 1:3, 1:3}, ones(3,3,3), 'nearest');
            v = 2013;
        catch
            v = 2011;
        end
    end
end
if v > 2011
    d = size(V); d(numel(d)+1:3) = 1;
    if  v > 2013
        F = griddedInterpolant({1:d(1), 1:d(2), 1:d(3)}, V, method, 'none');
    else
        F = griddedInterpolant({1:d(1), 1:d(2), 1:d(3)}, V, method);
    end
    V = F(I(1,:), I(2,:), I(3,:)); % interpolate
else % earlier matlab
    V = interp3(V, I(2,:), I(1,:), I(3,:), method, nan);
end

%% 2D/3D smooth wrapper: no input check for 2D
function out = smooth23(in, method, n, varargin)
if size(in,3)>1, out = smooth3(in, method, n, varargin{:}); return; end
if nargin<3 || isempty(n), n = 3; end
if numel(n)==1, n = [n n]; end
k = floor(n/2);
if k<1, out = in; return; end
n = k * 2 + 1; % odd number
if strcmp(method, 'box')
    kernal = ones(n) / n(1)/n(2);
elseif strcmp(method, 'gaussian')
    if nargin<4 || isempty(varargin{1}), sd = 0.65; 
    else sd = varargin{1}; 
    end
    [x, y] = meshgrid(-k(2):k(2), -k(1):k(1));
    kernal = exp(-(x.*x  +  y.*y) / (2*sd*sd));
    kernal = kernal / sum(kernal(:));
else
    fprintf(2, 'Invalid smooth method: %s\n', method);
    out = in; return;
end
in = [repmat(in(1,:), [k(1) 1]); in; repmat(in(end,:), [k(1) 1])];
in = [repmat(in(:,1), [1 k(2)])  in  repmat(in(:,end), [1 k(2)])];
out = conv2(in, kernal, 'valid');

%% Show ijk/xyz and value
function xyz = set_xyz(hs, I)
if nargin<2
    for i=3:-1:1, I(i) = get(hs.ijk(i), 'Value'); end
end

p = hs.files.UserData;
I = round(I);
xyz = round(hs.q{hs.iback}.R * [I-1 1]');
str = sprintf('(%g,%g,%g)=(%i,%i,%i): ', I, xyz(1:3));

for i = numel(p):-1:1 % show botton one first
    if p(i).show == 0, continue; end
    t = round(p(i).volume);
    if isfield(hs.q{i}, 'R0') % need interpolation
        I0 = hs.q{i}.R \ (hs.q{i}.R0 * [I-1 1]'); % overlay ijk
        I0 = round(I0+1);
    else I0 = I;
    end
    try
        val = hs.q{i}.nii.img(I0(1),I0(2),I0(3),t,:);
        if isfield(hs.q{i}, 'scl_slope')
            val = val * hs.q{i}.scl_slope + hs.q{i}.scl_inter;
        end
    catch
        val = nan; % out of range
    end
    
    if isfield(hs.q{i}, 'labels')
        try 
            labl = hs.q{i}.labels{val};
            str = sprintf('%s %s', str, labl);
            continue; % skip numeric val assignment
        catch
        end
    end
    
    fmtstr = '%.4g ';
    if numel(val)>1
        fmtstr = repmat(fmtstr, 1, numel(val));
        fmtstr = ['[' fmtstr]; fmtstr(end) = ']'; %#ok
    end
    str = sprintf(['%s ' fmtstr], str, val);
end
set(hs.value, 'String', str);

%% nii essentials
function s = nii_essential(q)
hdr = q.nii.hdr;
s.FileName = hdr.file_name;
if isfield(q, 'mask_info'), s.MaskedBy = q.mask_info; end
if isfield(q, 'modulation_info'), s.ModulatdBy = q.modulation_info; end
if isfield(q, 'alignMtx'), s.AlignMatrix = q.alignMtx; end
switch hdr.intent_code
    case 2, s.intent = 'Correlation'; s.DoF = hdr.intent_p1;
    case 3, s.intent = 'T-test';      s.DoF = hdr.intent_p1;
    case 4, s.intent = 'F-test';      s.DoF = [hdr.intent_p1 hdr.intent_p2];
    case 5, s.intent = 'Z-score';
    case 6, s.intent = 'Chi squared'; s.DoF = hdr.intent_p1;
        
    % several non-statistical intent_code
    case 1002, s.intent = 'Label'; % e.g. AAL labels
    case 2003, s.intent = 'RGB'; % triplet in the 5th dimension
    case 2004, s.intent = 'RGBA'; % quadruplet in the 5th dimension
end
switch hdr.datatype
    case 0,
    case 1,    s.DataType = 'logical';
    case 2,    s.DataType = 'uint8';
    case 4,    s.DataType = 'int16';
    case 8,    s.DataType = 'int32';
    case 16,   s.DataType = 'single';
    case 32,   s.DataType = 'single complex';
    case 64,   s.DataType = 'double';
    case 128,  s.DataType = 'uint8 RGB';
    case 256,  s.DataType = 'int8';
    case 511,  s.DataType = 'single RGB';
    case 512,  s.DataType = 'uint16';
    case 768,  s.DataType = 'uint32';
    case 1024, s.DataType = 'int64';
    case 1280, s.DataType = 'uint64';
    case 1792, s.DataType = 'double complex';
    case 2304, s.DataType = 'uint8 RGBA';
    otherwise, s.DataType = 'unknown';
end
s.Dimension = hdr.dim(2:hdr.dim(1)+1);
switch bitand(hdr.xyzt_units, 7)
    case 1, s.VoxelUnit = 'meters';
    case 2, s.VoxelUnit = 'millimeters';
    case 3, s.VoxelUnit = 'micrometers';
end 
s.VoxelSize = hdr.pixdim(2:4);
switch bitand(hdr.xyzt_units, 56)
    case 8,  s.TemporalUnit = 'seconds';
    case 16, s.TemporalUnit = 'milliseconds';
    case 24, s.TemporalUnit = 'microseconds';
    case 32, s.TemporalUnit = 'Hertz';
    case 40, s.TemporalUnit = 'ppm';
    case 48, s.TemporalUnit = 'radians per second';
end 
if isfield(s, 'TemporalUnit') && strfind(s.TemporalUnit, 'seconds')
    s.TR = hdr.pixdim(5);
end
if hdr.dim_info>0
    s.FreqPhaseSliceDim = bitand(hdr.dim_info, [3 12 48]) ./ [1 4 16];
    a = bitand(hdr.dim_info, 192) / 64;
    if a>0 && s.FreqPhaseSliceDim(2)>0
        ax = 'xyz'; % ijk to be accurate
        pm = ''; if a == 2, pm = '-'; end 
        s.PhaseEncodingDirection = [pm ax(s.FreqPhaseSliceDim(2))]; 
    end
end

switch hdr.slice_code
    case 0,
    case 1, s.SliceOrder = 'Sequential Increasing';
    case 2,	s.SliceOrder = 'Sequential Decreasing';
    case 3,	s.SliceOrder = 'Alternating Increasing 1';
    case 4,	s.SliceOrder = 'Alternating Decreasing 1';
    case 5,	s.SliceOrder = 'Alternating Increasing 2';
    case 6,	s.SliceOrder = 'Alternating Decreasing 2';
    otherwise, s.SliceOrder = 'Multiband?';
end
if ~isempty(hdr.descrip), s.Notes = hdr.descrip; end
str = formcode2str(hdr.qform_code);
if ~isempty(str), s.qform = str; end
if hdr.qform_code>0
    s.qfac = hdr.pixdim(1);
    s.quatern_bcd = [hdr.quatern_b hdr.quatern_c hdr.quatern_d];
    s.qoffset_xyz = [hdr.qoffset_x hdr.qoffset_y hdr.qoffset_z];
end
str = formcode2str(hdr.sform_code);
if ~isempty(str), s.sform = str; end
if hdr.sform_code>0
    s.srow_xyz = [hdr.srow_x; hdr.srow_y; hdr.srow_z];
end

%% decode NIfTI form_code
function str = formcode2str(code)
switch code
    case 0, str = '';
    case 1, str = 'Scanner Anat';
    case 2, str = 'Aligned Anat';
    case 3, str = 'Talairach';
    case 4, str = 'mni_152';
    otherwise, str = 'Unknown';
end

%% Get a mask based on image intesity, but with inside brain filled
function r = img2mask(img)
mn = mean(img(img(:)>0));
r = smooth23(img, 'box', 5) > mn/8; % smooth, binarize
if sum(r(:))==0, return; end

try
    C = contourc(double(r), [1 1]);
    i = 1; c = {};
    while size(C,2)>2 % split C into contours
        k = C(2,1) + 1;
        c{i} = C(:, 2:k); C(:,1:k) = []; %#ok
        i = i+1;
    end
    
    nc = numel(c);
    rg = nan(nc, 4); % minX minY maxX maxY
    for i = 1:nc
        rg(i,:) = [min(c{i},[],2)' max(c{i},[],2)'];
    end
    ind = false(nc,1);
    foo = min(rg(:,1)); ind = ind | foo==rg(:,1);
    foo = min(rg(:,2)); ind = ind | foo==rg(:,2);
    foo = max(rg(:,3)); ind = ind | foo==rg(:,3);
    foo = max(rg(:,4)); ind = ind | foo==rg(:,4);
    c = c(ind); % outmost contour(s) 
    len = cellfun(@(x) size(x,2), c);
    [~, ind] = sort(len, 'descend');
    c = c(ind);
    C = c{1};
    if isequal(C(:,1), C(:,end)), c(2:end) = []; end % only 1st if closed
    nc = numel(c);
    for i = nc:-1:2 % remove closed contours except one with max len
        if isequal(c{i}(:,1), c{i}(:,end)), c(i) = []; end
    end
    nc = numel(c);
    while nc>1 % +1 contours, put all into 1st
        d2 = nan(nc-1, 2); % distance^2 from C(:,end) to other start/endpoint
        for i = 2:nc
            d2(i-1,:) = sum((C(:,end)*[1 1] - c{i}(:,[1 end])).^2);
        end
        [i, j] = find(d2 == min(d2(:)));
        i = i + 1; % start with 2nd
        if j == 1, C = [C c{i}]; %#ok C(:,1) connect to c{i}(:,1)
        else C = [C c{i}(:,end:-1:1)]; %#ok C(:,end) to c{i}(:,end)
        end
        c(i) = []; nc = nc-1;
    end
    if ~isequal(C(:,1), C(:,end)), C(:,end+1) = C(:,1); end % close the contour
    x = C(1, :);
    y = C(2, :);
    [m, n] = size(r);

    % following is the method in Octave poly2mask
    xe = [x(1:numel(x)-1); x(1, 2:numel(x))]; % edge x
    ye = [y(1:numel(y)-1); y(1, 2:numel(y))]; % edge y
    ind = ye(1,:) == ye(2,:);
    xe(:,ind) = []; ye(:, ind) = []; % reomve horizontal edges
    minye = min(ye);
    maxye = max(ye);
    t = (ye == [minye; minye]);
    exminy = xe(:); exminy = exminy(t);
    exmaxy = xe(:); exmaxy = exmaxy(~t);
    maxye = maxye';
    minye = minye';
    m_inv = (exmaxy - exminy) ./ (maxye - minye);
    ge = [maxye minye exmaxy m_inv];
    ge = sortrows(ge, [1 3]);
    ge = [-Inf -Inf -Inf -Inf; ge];

    gei = size(ge, 1);
    sl = ge(gei, 1);
    ae = []; % active edge
    while (sl == ge(gei, 1))
        ae = [ge(gei, 2:4); ae]; %#ok
        gei = gei - 1;
    end

    miny = min(y);
    if miny < 1, miny = 1; end

    while (sl >= miny)
        if (sl <= m) % check vert clipping
            ie = round(reshape(ae(:, 2), 2, size(ae, 1)/2));
            ie(1, :) = ie(1, :) + (ie(1, :) ~= ie(2, :));
            ie(1, (ie(1, :) < 1)) = 1;
            ie(2, (ie(2, :) > n)) = n;
            ie = ie(:, (ie(1, :) <= n));
            ie = ie(:, (ie(2, :) >= 1));
            for i = 1:size(ie,2)
                r(sl, ie(1, i):ie(2, i)) = true;
            end
        end

        sl = sl - 1;
        ae = ae((ae(:, 1) ~= sl), :);
        ae(:, 2) = ae(:, 2) - ae(:, 3);

        while (sl == ge(gei, 1))
            ae = [ae; ge(gei, 2:4)]; %#ok
            gei = gei - 1;
        end

        if size(ae,1) > 0
            ae = sortrows(ae, 2);
        end
    end
catch %me, fprintf(2, '%s\n', me.message); assignin('base', 'me', me);
end

%% update colorbar map label
function set_colorbar(hs)
if strcmpi(get(hs.colorbar, 'Visible'), 'off'), return; end
p = hs.files.UserData(hs.files.Value);
if p.lut == 11, map = lut2map(hs.lut.UserData, hs);
else map = lut2map(p.lut, hs);
end
rg = sort([p.lb p.ub]);
if any(p.lut == 26:28)
    labls = [0 180 360];
elseif p.lut~=10
    if rg(2)<0, rg = rg([2 1]); end
    mn = str2double(num2str(mean(rg), '%.4g'));
    labls = [rg(1) mn rg(2)];
else
    rg = sort(abs(rg));
    labls = {num2str(-rg(2)) num2str(rg(1),'+/-%g') num2str(rg(2))};
end
% colormap in earlier matlab version changes values in colorbar.
% So we have to set those values each time.
% set(hs.colorbar, 'YTickLabel', labls); % new matlab
colormap(hs.ax(4), map);
set(get(hs.colorbar, 'Children'), 'YData', [0 1]); % Trick for old matlab
set(hs.colorbar, 'YTickLabel', labls, 'YTick', [0 0.5 1], 'Ylim', [0 1]);

%% return screen size in pixels
function res = screen_pixels(id)
res = get(0, 'MonitorPositions');
if size(res,1)<2, res = res(1, 3:4); return; end % single/duplicate monitor
if nargin, res = res(id,3:4); return; end
res = sortrows(res);
res = res(end,1:2) + res(end,3:4) - res(1,1:2);

%% estimate StepSize for java spinner
function d = stepSize(val)
d = abs(val/10);
d = str2double(sprintf('%.1g', d));
d = max(d, 0.01);
if d>4, d = round(d/2)*2; end

%% add mask or modulation
function addMask(hs, h)
i = hs.files.Value;
pName = fileparts(hs.files.UserData(i).fname);
[fname, pName] = uigetfile([pName '/*.nii;*.hdr;*.nii.gz;*.hdr.gz'], ...
    'Select mask NIfTI');
if ~ischar(fname), return; end
fname = fullfile(pName, fname);

nii = nii_tool('load', fname);
hdr = hs.q{i}.nii.hdr;
codes = [hdr.sform_code hdr.qform_code];
[R, frm] = nii_xform_mat(nii.hdr, codes);
if ~any(frm == codes)
    str = ['There is no matching coordinate system between the selected ' ...
        'image and the mask image. Do you want to apply the mask anyway?'];
    btn = questdlg(str, 'Apply mask?', 'Cancel', 'Apply', 'Cancel');
    if isempty(btn) || strcmp(btn, 'Cancel'), return; end
    R0 = nii_xform_mat(hdr, codes(1));
else
    R0 = nii_xform_mat(hdr, frm); % may be the same as hs.q{i}.R
end
R0 = reorient(R0, hdr.dim(2:4)); % do this since img was done when loaded

% this wont work if lines is background & Mprage is overlay
if all(isfield(hs.q{i}, {'R0' 'alignMtx'})) % background as mask
    R1 = reorient(R, nii.hdr.dim(2:4));
    if all(abs(R1(:)-hs.q{i}.R0(:))<1e-4), R0 = hs.q{i}.R; end % not 100% safe
end

dim = single(size(hs.q{i}.nii.img)); % dim for reoriented img
dim(numel(dim)+1:3) = 1; dim = dim(1:3);
[Y, X, Z] = meshgrid(1:dim(2), 1:dim(1), 1:dim(3));
I = [X(:) Y(:) Z(:)]'-1; I(4,:) = 1;
I = R \ (R0 * I) + 1; % ijk+1 for mask
I = round(I * 100) / 100;

im = single(nii.img(:,:,:,1,1,1,1,1)); % first mask volume
slope = nii.hdr.scl_slope;
if slope==0, slope = 1; end
im = im * slope + nii.hdr.scl_inter;
im = interp3a(im, I, 'nearest');
im1 = im(~isnan(im)); % for threshold computation
im = reshape(im, dim);

if strcmp(get(h, 'Label'), 'Apply mask'); % binary mask
    if numel(unique(im1))<3
        thre = min(im1);
    else
        rg = get_range(im1);
        str = sprintf('Threshold for non-binary mask (%.3g to %.4g)', ...
            min(im1), max(im1));
        a = inputdlg(str, 'Input mask threshold', 1, {num2str(rg(1),'%.3g')});
        if isempty(a), return; end
        thre = str2double(a{1});
        fname = [fname ' (threshold = ' a{1} ')']; % info only
    end
    hs.q{i}.mask = abs(im)>thre;
    hs.q{i}.mask_info = fname;
    noteStr = '(masked)';
else % modulation
    mi = min(im1); ma = max(im1);
    if mi<0 || ma>1
        str = {sprintf('Lower bound to clip to 0 (image min = %.2g)', mi) ...
               sprintf('Upper bound to clip to 1 (image max = %.2g)', ma)};
        def = strtrim(cellstr(num2str([mi;ma], '%.2g'))');
        a = inputdlg(str, 'Input modulation range', 1, def);
        if isempty(a), return; end
        mi = str2double(a{1}); ma = str2double(a{2});
        fname = [fname ' (range [' a{1} ' ' a{2} '])'];
    end
    im(im<mi) = mi; im(im>ma) = ma;
    hs.q{i}.modulation = (im-mi) / (ma-mi);
    hs.q{i}.modulation_info = fname;
    noteStr = '(modulated)';
end
guidata(hs.fig, hs);
set_cdata(hs);

str = hs.files.String{i};
n = numel(noteStr);
if numel(str)<n || ~strcmp(str(end+(-n+1:0)), noteStr)
    hs.files.String{i} = [str noteStr];
end

%% update crosshair: ix correspond to one of the three spinners, not views
function set_cross(hs, ix)
h = hs.cross;
for i = ix
    c = get(hs.ijk(i), 'Value');
    g = hs.gap(i);
    if i == 1 % I changed
        set([h(2,3:4) h(3,3:4)], 'XData', [c c]);
        set([h(2,1) h(3,1)], 'XData', [0 c-g]);
        set([h(2,2) h(3,2)], 'XData', [c+g hs.dim(1)+1]);
    elseif i == 2 % J
        set(h(1,3:4), 'XData', [c c]);
        set(h(1,1), 'XData', [0 c-g]);
        set(h(1,2), 'XData', [c+g hs.dim(2)+1]);
        set(h(3,1:2), 'YData', [c c]);
        set(h(3,3), 'YData', [0 c-g]);
        set(h(3,4), 'YData', [c+g hs.dim(2)+1]);
    else % K
        set([h(1,1:2) h(2,1:2)], 'YData', [c c]);
        set([h(1,3) h(2,3)], 'YData', [0 c-g]);
        set([h(1,4) h(2,4)], 'YData', [c+g hs.dim(3)+1]);
    end
end

%% turn on/off NIfTI
function toggle_img(hs)
i = get(hs.files, 'Value');
p = hs.files.UserData(i);
if p.show % checked
    hs.files.String{i}(1) = 9744;
else
    hs.files.String{i}(1) = 9746;
end
p.show = ~p.show;
hs.files.UserData(i) = p;

states = {'off' 'on'};
set(p.hsI, 'Visible', states{p.show+1});
if p.show, set_cdata(hs); end
set_xyz(hs);

%% Return java handle of the first ScrollPaneUI in figure
% Extracted from findjobj.m by Yair Altman (matlabcentral/fileexchange/14317)
function jObj = jscroll_handle(jAxisComponent)
try
    jRootPane = jAxisComponent.getParent.getParent.getRootPane;
    jRootPane = jRootPane.getTopLevelAncestor;
    jObj = childScroll(jRootPane);
catch
    jObj = [];
end

% recursive function to find ScrollPaneUI, called by jscroll_handle
function jObj = childScroll(parent)
jObj = [];
try nComp = parent.getComponentCount; catch, return; end
for i = 0:nComp-1
    try
        h = parent.getComponent(i);
        typ = h.getUIClassID;
        if strcmp(typ, 'ScrollPaneUI')
            jObj = handle(h, 'CallbackProperties'); % got it
        elseif ~isempty(strfind(typ, 'Menu'))
            continue; % skip menu and its child
        end
    catch % still check its child if no UIClassID: needed for old matlab
    end
    if ~isempty(jObj), return; end % done
    jObj = childScroll(h);
end

%% Switch display parameters to seleted file
function set_file(hs)
i = hs.files.Value;
setappdata(hs.files, 'PreviousValue', i); % store it for keyPressFcn
p = hs.files.UserData(i);
nam = {'lb' 'ub' 'alpha' 'volume' 'lut' 'smooth' 'interp' };
cb = cell(4,1);
for j = 1:4 % avoid firing spinner callback
    cb{j} = hs.(nam{j}).StateChangedCallback;
    hs.(nam{j}).StateChangedCallback = '';
end

for j = 1:numel(nam)
    set(hs.(nam{j}), 'Value', p.(nam{j}));
end
set(hs.lb.Model, 'StepSize', p.lb_step);
set(hs.ub.Model, 'StepSize', p.ub_step);
nVol = size(hs.q{i}.nii.img, 4);
set(hs.volume, 'Enable', nVol>1, 'ToolTipText', ['Volume number, 1:' num2str(nVol)]);
set(hs.volume.Model, 'Maximum', nVol);

for j = 1:4 % restore spinner callback
    hs.(nam{j}).StateChangedCallback = cb{j};
end
set_colorbar(hs);

off_on = {'off' 'on'};
set(hs.interp, 'Enable', off_on{isfield(hs.q{i}, 'R0')+1});
set(hs.overlay(1:4), 'Enable', off_on{(numel(hs.q)>1)+1}); % stack & Close overlays
set(hs.overlay(5), 'Enable', off_on{(i~=hs.iback)+1}); % Close overlay

%% Duplicate image handles, inlcuding ButtonDownFcn for new matlab
function h = copyimg(hs)
h = hs.hsI;
cb = get(hs.hsI(1), 'ButtonDownFcn');
for i = 1:3
    h(i) = copyobj(hs.hsI(i), hs.ax(i));
    set(h(i), 'Visible', 'on', 'ButtonDownFcn', cb); % cb needed for 2014b+
end
crossFront(hs);

%% Save selected nii as another file
function save_nii_as(hs, c)
i = hs.files.Value;
hs.files.UserData;
nam = hs.files.UserData(i).fname;
pName = fileparts(nam);

if ~isempty(strfind(c, 'dim 4')) % fsl RGB
    nii = nii_tool('load', nam); % re-load to be safe
    if any(size(nii.img,8) == 3:4)
        nii.img = permute(nii.img, [1:3 8 4:7]);
    elseif ~any(nii.hdr.dim(5) == 3:4)
        errordlg('Selected image is not RGB data.'); return;
    end
    [fname, pName] = uiputfile([pName '/*.nii'], ...
        'Input name for FSL RGB file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_tool('save', nii, fname);
elseif ~isempty(strfind(c, 'dim 3')) % old mricron RGB
    nii = nii_tool('load', nam);
    if any(nii.hdr.dim(5) == 3:4)
        nii.img = permute(nii.img, [1:3 5:7 4]);
    elseif ~any(size(nii.img,8) == 3:4)
        errordlg('Selected image is not RGB data'); return;
    end
    [fname, pName] = uiputfile([pName '/*.nii'], ...
        'Input name for old mricrom styte file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    old = nii_tool('RGBStyle', 'mricron');
    nii_tool('save', nii, fname);
    nii_tool('RGBStyle', old);
elseif ~isempty(strfind(c, 'AFNI')) % NIfTI RGB
    nii = nii_tool('load', nam);
    if any(nii.hdr.dim(5) == 3:4)
        nii.img = permute(nii.img, [1:3 5:8 4]);
    elseif ~any(size(nii.img,8) == 3:4)
        errordlg('Selected image is not RGB data'); return;
    end
    nii.img = abs(nii.img);
    [fname, pName] = uiputfile([pName '/*.nii'], ...
        'Input name for NIfTI standard RGB file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    old = nii_tool('RGBStyle', 'afni');
    nii_tool('save', nii, fname);
    nii_tool('RGBStyle', old);
elseif ~isempty(strfind(c, '3D')) % SPM 3D
    nii = nii_tool('load', nam);
    if nii.hdr.dim(5)<2
        errordlg('Selected image is not multi-volume data'); return;
    end
    [fname, pName] = uiputfile([pName '/*.nii'], ...
        'Input base name for SPM 3D file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    nii_tool('save', nii, fname, 1); % force 3D
elseif ~isempty(strfind(c, 'new resolution'))
    str = 'Resolution for three dimension in mm';
    a = inputdlg(str, 'Input space resolution', 1, {'3 3 3'});
    if isempty(a), return; end
    res = sscanf(a{1}, '%g %g %g');
    if numel(res) ~= 3
        errordlg('Invalid space resolution');
        return;
    end
    if isequal(res, hs.q{i}.nii.hdr.pixdim(2:4))
        warndlg('The input resolution is the same as current one');
        return;
    end
    [fname, pName] = uiputfile([pName '/*.nii;nii.gz'], ...
        'Input result name for the new resolution file');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    pf = get(hs.pref, 'UserData');
    nii_xform(nam, res, fname, pf.interp, pf.extraV)
elseif ~isempty(strfind(c, 'matching background'))
    if i == hs.iback
        errordlg('You seleted background image');
        return;
    end
    [fname, pName] = uiputfile([pName '/*.nii;*.nii.gz'], ...
        'Input result file name');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    pf = get(hs.pref, 'UserData');
    nii_xform(nam, hs.files.UserData(hs.iback).fname, fname, pf.interp, pf.extraV)
elseif ~isempty(strfind(c, 'aligned template'))
    [temp, pName] = uigetfile([pName '/*.nii;*.nii.gz'], ...
        'Select the aligned template file');
    if ~ischar(temp), return; end
    temp = fullfile(pName, temp);
    [mtx, pName] = uigetfile([pName '/*.mat'], ['Select the text ' ...
        'matrix file which aligns the nii to the template']);
    if ~ischar(mtx), return; end
    mtx = fullfile(pName, mtx);
    [fname, pName] = uiputfile([pName '/*.nii;*.nii.gz'], ...
        'Input result file name');
    if ~ischar(fname), return; end
    fname = fullfile(pName, fname);
    pf = get(hs.pref, 'UserData');
    nii_xform(nam, {temp mtx}, fname, pf.interp, pf.extraV)
else
    errordlg(sprintf('%s not implemented yet.', c));
end
%%