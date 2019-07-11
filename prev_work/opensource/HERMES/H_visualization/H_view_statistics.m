function varargout = H_view_statistics ( varargin )

% =========================================================================
%
% This function is part of the HERMES toolbox:
% http://hermes.ctb.upm.es/
% 
% Copyright (c)2010-2015 Universidad Politecnica de Madrid, Spain
% HERMES is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% HERMES is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details. You should have received 
% a copy of the GNU General Public License % along with HERMES. If not, 
% see <http://www.gnu.org/licenses/>.
% 
%
% ** Please cite: 
% Niso G, Bruna R, Pereda E, Guti�rrez R, Bajo R., Maest� F, & del-Pozo F. 
% HERMES: towards an integrated toolbox to characterize functional and 
% effective brain connectivity. Neuroinformatics 2013, 11(4), 405-434. 
% DOI: 10.1007/s12021-013-9186-1. 
%
% =========================================================================
% 
% Authors:  Guiomar Niso, 2011
%           Guiomar Niso, Ricardo Bruna, 2012
%


% H_VIEW_STATISTICS M-file for H_view_statistics.fig
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @H_view_statistics_OpeningFcn, ...
                   'gui_OutputFcn',  @H_view_statistics_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end % End initialization code - DO NOT EDIT

% Deactivation of the unwanted warnings.
%#ok<*INUSL,*INUSD,*DEFNU>


function H_view_statistics_OpeningFcn ( hObject, eventdata, handles, varargin )

% Sets the default background color.
elements   = findobj ( hObject, 'Type', 'uipanel', '-or', 'Style', 'text', '-or', 'Style', 'pushbutton', '-or', 'Style', 'checkbox' );
set ( hObject,  'Color',           H_background )
set ( elements, 'BackgroundColor', H_background )

% Initializes the data.
handles.data.project = varargin {1};

% Gets the list of calculated indexes.
handles.data.runs     = H_load ( handles.data.project, 'statistics' );
handles.data.indexes  = unique ( cat ( 1, handles.data.runs.index ) );

% Gets the labels of the channels.
handles.data.labels   = handles.data.project.sensors.label;

% Gets the layout and the coordinates (in cm).
handles.data.layout   = handles.data.project.sensors.layout;
handles.data.position = handles.data.project.sensors.position * 10;


% Coordinates
% handles.Coord2D = handles.data.project.sensors.layout;
% handles.Coord3D = handles.data.project.sensors.position;

% Fulfills the list of calculated indexes.
set ( handles.index, 'String', handles.data.indexes, 'Value', 1 )

% Sets the project name as title.
set ( handles.title, 'String', handles.data.project.name )

% Loads the data for the first index and run.
index_Callback ( handles.index, eventdata, handles )

uiwait ( handles.H_view_statistics );


function update ( handles )

% Hides the panels by default.
set ( handles.slider1_panel, 'Visible', 'off' )
set ( handles.slider2_panel, 'Visible', 'off' )

% Initializes the scrolls.
set ( handles.slider1, 'Min', 1, 'Max', 1, 'Value', 1, 'Visible', 'Off' )
set ( handles.slider2, 'Min', 1, 'Max', 1, 'Value', 1, 'Visible', 'Off' )

% Gets the statistics in the selected run.
run = handles.data.index_runs ( get ( handles.index_run, 'Value' ) );
handles.data.statistics = H_load ( handles.data.project, 'statistics', run );

% Gets the clusters in the selected run.
if numel ( handles.data.statistics.data )
    set ( handles.cluster, 'String', { handles.data.statistics.data.label }, 'Enable', 'on', 'Value', 1 )
    
else
    set ( handles.cluster, 'String', 'No significant clusters', 'Enable', 'off' )
end

% Gets the labels and values for the dimensions.
labels     = handles.data.statistics.origin.dimensions ( 1, 3: end );
dimensions = handles.data.statistics.origin.dimensions ( 2, 3: end );

% Initializes the sliders structure.
sliders = struct ( 'dimension', { [], [] }, 'indexes', [], 'label', [] );

for dimension = 1: numel ( labels )
    
    % Sets the metadata.
    slider.dimension = labels { dimension };
    
    % Gets the values as a vector of values x edges.
    values = dimensions { dimension };
    if strcmp ( labels { dimension }, 'lag' ),       values = values (:); end
    if strcmp ( labels { dimension }, 'frequency' ), values = values (:); end
    
    % Sets the number of values to average in every step.
    if strcmp ( labels { dimension }, 'frequency' ), slider.indexes = split ( size ( values, 1 ), 10 );
    else                                             slider.indexes = num2cell ( 1: size ( values, 1 ) );
    end
    
    % Creates the label for each type of dimension.
    if strcmp ( labels { dimension }, 'time' ),      slider.label = labelize ( slider.indexes, values, 'ms' );      end
    if strcmp ( labels { dimension }, 'lag' ),       slider.label = labelize ( slider.indexes, values, 'samples' ); end
    if strcmp ( labels { dimension }, 'band' ),      slider.label = labelize ( slider.indexes, values, 'Hz' );      end
    if strcmp ( labels { dimension }, 'frequency' ), slider.label = labelize ( slider.indexes, values, 'Hz' );      end
    
    if strcmp ( labels { dimension }, 'time' ), sliders (1) = slider;
    else                                        sliders (2) = slider;
    end
end

% Updates the labels of the sliders, if needed.
if ~isempty ( sliders (1).dimension )
    
    % Sets the scroll if there are several steps for the specified index.
    steps = numel ( sliders (1).label );
    if steps > 1, set ( handles.slider1, 'Max', steps, 'SliderStep', [ 1 5 ] ./ ( steps - 1 ), 'Visible', 'On' ), end
    
    % Writes out the metadata and the label for the current step.
    set ( handles.slider1_panel, 'Title', capitalize ( sliders (1).dimension ), 'Visible', 'On' )
    set ( handles.slider1_title, 'String', sliders (1).label {1} )
end

if ~isempty ( sliders (2).dimension )
    
    % Sets the scroll if there are several steps for the specified index.
    steps = numel ( sliders (2).label );
    if steps > 1, set ( handles.slider2, 'Max', steps, 'SliderStep', [ 1 5 ] ./ ( steps - 1 ), 'Visible', 'On' ), end
    
    % Writes out the metadata and the label for the current step.
    set ( handles.slider2_panel, 'Title', capitalize ( sliders (2).dimension ), 'Visible', 'On' )
    set ( handles.slider2_title, 'String', sliders (2).label {1} )
end

% Stores the information in the handles structure.
handles.controls.sliders = sliders;

% Prints the configuration for the index in the current run.
set ( handles.index_config, 'String', H_info ( handles.data.statistics ) )

% Plots the current (first) subject and condition.
show ( handles );


function show ( handles )

% Gets the selected step from each slider.
value1 = round ( get ( handles.slider1, 'Value' ) );
value2 = round ( get ( handles.slider2, 'Value' ) );

% Gets the sliders configuration.
sliders = handles.controls.sliders;
if ~isempty ( sliders (1).dimension ), set ( handles.slider1_title, 'String', sliders (1).label { value1 } ), end
if ~isempty ( sliders (2).dimension ), set ( handles.slider2_title, 'String', sliders (2).label { value2 } ), end

% Selects the range of indexes to use.
if ~isempty ( sliders (1).dimension ) && ~isempty ( sliders (2).dimension )
    indexes1 = sliders (2).indexes { value2 };
    indexes2 = sliders (1).indexes { value1 };
    
elseif ~isempty ( sliders (2).dimension )
    indexes1 = sliders (2).indexes { value2 };
    indexes2 = 1;
    
elseif ~isempty ( sliders (1).dimension )
    indexes1 = sliders (1).indexes { value1 };
    indexes2 = 1;
end

% If no significant clusters, sets the data to zeros.
if numel ( handles.data.statistics.data ) == 0
    data = zeros ( numel ( handles.data.labels ) );
    
% Otherwise gets the selected cluster.
else
    cluster = get ( handles.cluster, 'Value' );
    data    = handles.data.statistics.data ( cluster ).cluster ( :, :, indexes1, indexes2 );
end

% Averages in bands, if needed.
if size ( data, 3 ) > 1, data = mean ( data, 3 ); end
if size ( data, 4 ) > 1, data = mean ( data, 4 ); end

% Draws the data.
% H_plot ( data, handles )
H_plot_stat ( data, handles )

% Stores the data in the figure.
guidata ( handles.H_view_statistics, handles );


function prev_Callback ( hObject, eventdata, handles )
subject = str2double ( get ( handles.subject, 'String' ) );
set ( handles.subject, 'String', subject - 1 )
subject_Callback ( handles.subject, eventdata, handles )


function next_Callback ( hObject, eventdata, handles )
subject = str2double ( get ( handles.subject, 'String' ) );
set ( handles.subject, 'String', subject + 1 )
subject_Callback ( handles.subject, eventdata, handles )


function index_Callback     ( hObject, eventdata, handles )

% Gets the list of runs where the selected index was calculated.
index = handles.data.indexes { get ( handles.index, 'Value' ) };
handles.data.index_runs = find ( strcmp ( cat ( 1, handles.data.runs.index ), index ) );

% Fills the list of runs with the avaliable runs.
set ( handles.index_run, 'String', { ( handles.data.runs ( handles.data.index_runs ).description ) }, 'Value', 1 );

% Calls the run callback.
index_run_Callback ( handles.index_run, eventdata, handles )

function index_run_Callback ( hObject, eventdata, handles )

update ( handles )


function slider1_Callback      ( hObject, eventdata, handles ), show ( handles )
function slider2_Callback      ( hObject, eventdata, handles ), show ( handles )
function cluster_Callback      ( hObject, eventdata, handles ), show ( handles )
function show_labels_Callback ( hObject, eventdata, handles ), show ( handles )

function pdf_Callback  ( hObject, eventdata, handles ), savePDF ( handles, hObject );

function H_view_statistics_CloseRequestFcn ( hObject, eventdata, handles ), uiresume
function H_view_statistics_OutputFcn       ( hObject, eventdata, handles ), delete ( hObject )



function grouped = split ( total, segments )

% Gets the size and centroid for each group.
groupsize = ( total - 1 ) / segments;
centroids = ( groupsize / 2: groupsize: total ) + 1;

% Creates the empty groups.
grouped = cell ( segments, 1 );

% Goes through all the segments and fills the groups.
for segment = 1: segments
    beggining = max ( round ( centroids ( segment ) - groupsize / 2 ), 1 );
    ending    = min ( round ( centroids ( segment ) + groupsize / 2 ), total );
    grouped { segment } = beggining: ending;
end


function labels = labelize ( segments, values, units )

% Creates the empty labels.
labels = cell ( size ( segments ) );

% Goes through all the segments and fills the labels.
for segment = 1: numel ( segments )
    
    % Gets the values to show.
    indexes = segments { segment };
    value   = values ( indexes, : );
    
    % Shows one single value, if only one, or the range, if several.
    if numel ( value ) == 1, labels { segment } = sprintf ( '%.1f %s', value, units );
    else                     labels { segment } = sprintf ( '%.1f to %.1f %s', value (1), value (end), units );
    end
end


function output = capitalize ( input )
output = input;
output (1) = upper ( output (1) );



function savePDF ( handles, this )
set ( handles.H_view_statistics, 'PaperPositionMode', 'auto' )
[ filename, folder ] = uiputfile ( '*.pdf' );
% set ( hObject, 'Visible', 'Off' )
% print ( handles.H_view_statistics, '-dpdf', '-append', strcat ( folder, filename, '.eps' ) )
% set ( hObject, 'Visible', 'On' )

[ folder, filename, extension ] = fileparts ( strcat ( folder, filename ) );
set ( this, 'Visible', 'Off' )
print ( handles.H_view_statistics, '-dpsc', '-append', strcat ( folder, '/', filename, '.eps' ) )
set ( this, 'Visible', 'On' )
ps2pdf ( 'psfile', strcat ( folder, '/', filename, '.eps' ), 'pdffile', strcat ( folder, '/', filename, extension ) );
delete ( strcat ( folder, '/', filename, '.eps' ) )
