function indexes = H_compute_CM ( project, config )

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
% ** Please cite: ---------------------------------------------------------
% Niso G, Bru�a R, Pereda E, Guti�rrez R, Bajo R., Maest� F, & del-Pozo F. 
% HERMES: towards an integrated toolbox to characterize functional and 
% effective brain connectivity. Neuroinformatics 2013, 11(4), 405-434. 
% DOI: 10.1007/s12021-013-9186-1. 
%
% =========================================================================
% 
% Authors:  Guiomar Niso, 2010
%           Guiomar Niso, Ricardo Bruna, 2012
%


% Configures the waitbar.
waitbar          = config.waitbar;
waitbar.title    = 'HERMES - Clasic measures';
waitbar.message  = 'Calculating indexes.';
waitbar.tic      = clock;
waitbar.progress = [ 0 1 ];

waitbar.state.progress = 0;
waitbar.state.message  = waitbar.message;
waitbar.state.title    = waitbar.title;

% Creates the waitbar.
waitbar = H_waitbar ( waitbar );

% Checks the completitude of the configuration structure.
config = config.CM;

if ~isfield ( config, 'measures' ),   config.measures   = {};  end
if ~isfield ( config, 'statistics' ), config.statistics = 0;   end
if ~isfield ( config, 'surrogates' ), config.surrogates = 100; end

% Appends the information of the execution to the project log.
H_log ( project, 'calling', config );

% Creates the flag from the number of trials.
config.trials = min ( min ( [ project.statistical.trials ] ) ) >= 8;

% Stores parameters, configuration and metadata in the indexes structure.
for index = config.measures
    switch index { 1 }
        case 'COR',  name = 'Correlation (COR)';
        case 'COH',  name = 'Coherence (COH)';
        case 'iCOH', name = 'Imaginary Coherence (iCOH)';
        case 'xCOR', name = 'Cross-Correlation (xCOR)';
        case 'PSI',  name = 'Phase Slope Index (PSI)';
        otherwise, continue
    end
    
    indexes.( index { 1 } ).type       = 'Classical index';
    indexes.( index { 1 } ).name       = name;
    indexes.( index { 1 } ).dimensions = H_dimensions ( index { 1 }, config, project );
    indexes.( index { 1 } ).date       = clock;
    indexes.( index { 1 } ).config     = config;
end

% Reserves memory for the indexes.
if H_check ( config.measures, 'COR'  ), indexes.COR.data  = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
if H_check ( config.measures, 'COH'  ), indexes.COH.data  = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
if H_check ( config.measures, 'xCOR' ), indexes.xCOR.data = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
if H_check ( config.measures, 'iCOH' ), indexes.iCOH.data = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
if H_check ( config.measures, 'PSI'  ), indexes.PSI.data  = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end

% Goes through all subjects and conditions.
for subject = 1: numel ( project.subjects )
    for condition = 1: numel ( project.conditions )
        
        % Configures the waitbar.
        waitbar.progress ( 1: 2 ) = [ subject numel( project.subjects ) ];
        waitbar.progress ( 3: 4 ) = [ condition numel( project.conditions ) ];
        
        % Loads the subject and condition data.
        data = H_load ( project, subject, condition );
        
        % Calculates the indexes.
        output = H_methods_CM ( data, config, waitbar );
        
        % Checks for user cancelation.
        if ( H_stop ), return, end
        
        % Stores the indexes in the output structure.
        if H_check ( config.measures, 'COR'  ), indexes.COR.data  { condition, subject } = output.COR.data;  end
        if H_check ( config.measures, 'COH'  ), indexes.COH.data  { condition, subject } = output.COH.data;  end
        if H_check ( config.measures, 'iCOH' ), indexes.iCOH.data { condition, subject } = output.iCOH.data; end
        if H_check ( config.measures, 'xCOR' ), indexes.xCOR.data { condition, subject } = output.xCOR.data; end
        if H_check ( config.measures, 'PSI'  ), indexes.PSI.data  { condition, subject } = output.PSI.data;  end
    end
end

% Calculates permutation statistics.
if config.statistics
    
    % Configures the waitbar.
    waitbar.tic      = clock;
    waitbar.message  = 'Calculating permutation statistics (this could take a while).';
    waitbar.progress = [ 0 1 ];
    waitbar = H_waitbar ( waitbar );
    
    % Reserves memory for the statistics.
    if H_check ( config.measures, 'COR'  ), indexes.COR.pval  = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
    if H_check ( config.measures, 'COH'  ), indexes.COH.pval  = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
    if H_check ( config.measures, 'xCOR' ), indexes.xCOR.pval = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
    if H_check ( config.measures, 'iCOH' ), indexes.iCOH.pval = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
    if H_check ( config.measures, 'PSI'  ), indexes.PSI.pval  = cell ( numel ( project.conditions ), numel ( project.subjects ) ); end
    
    % Applies permutation statistics to discard random interactions.
    for subject = 1: numel ( project.subjects )
        for condition = 1: numel ( project.conditions )
            
            % Configures the waitbar.
            waitbar.progress ( 1: 2 ) = [ subject numel( project.subjects ) ];
            waitbar.progress ( 3: 4 ) = [ condition numel( project.conditions ) ];
            
            % Loads the subject and condition data.
            data = H_load ( project, subject, condition );
            
            % Reserves memory for the indexes.
            if H_check ( config.measures, 'COR'  ), surrogates.COR  = zeros ( size ( indexes.COR.data  { condition, subject } ) ); end
            if H_check ( config.measures, 'xCOR' ), surrogates.xCOR = zeros ( size ( indexes.xCOR.data { condition, subject } ) ); end
            if H_check ( config.measures, 'COH'  ), surrogates.COH  = zeros ( size ( indexes.COH.data  { condition, subject } ) ); end
            if H_check ( config.measures, 'iCOH' ), surrogates.iCOH = zeros ( size ( indexes.iCOH.data { condition, subject } ) ); end
            if H_check ( config.measures, 'PSI'  ), surrogates.PSI  = zeros ( size ( indexes.PSI.data  { condition, subject } ) ); end
            
            % Performs n iterations.
            for iteration = 1: config.surrogates
                
                % Calculates the indexes of the surrogated data.
                surrogate = H_methods_CM ( H_surrogate ( data, 'suffle' ), config );
                
                % Checks for user cancelation.
                if ( H_stop ), return, end
                
                % Stores a 1 if the value is lower than the index.
                if H_check ( config.measures, 'COR'  ), surrogates.COR  = surrogates.COR  + ( abs ( surrogate.COR.data )  > abs ( indexes.COR.data  { condition, subject } ) ); end
                if H_check ( config.measures, 'xCOR' ), surrogates.xCOR = surrogates.xCOR + ( abs ( surrogate.xCOR.data ) > abs ( indexes.xCOR.data { condition, subject } ) ); end
                if H_check ( config.measures, 'COH'  ), surrogates.COH  = surrogates.COH  + ( abs ( surrogate.COH.data )  > abs ( indexes.COH.data  { condition, subject } ) ); end
                if H_check ( config.measures, 'iCOH' ), surrogates.iCOH = surrogates.iCOH + ( abs ( surrogate.iCOH.data ) > abs ( indexes.iCOH.data { condition, subject } ) ); end
                if H_check ( config.measures, 'PSI'  ), surrogates.PSI  = surrogates.PSI  + ( abs ( surrogate.PSI.data )  > abs ( indexes.PSI.data  { condition, subject } ) ); end
                
                % Updates the waitbar.
                waitbar.progress ( 5: 6 ) = [ iteration config.surrogates ];
                waitbar = H_waitbar ( waitbar );
            end
            
            % Gets the p-value by dividing by the number of iterations.
            if H_check ( config.measures, 'COR'  ), indexes.COR.pval  { condition, subject } = surrogates.COR  / ( config.surrogates + 1 ); end
            if H_check ( config.measures, 'xCOR' ), indexes.xCOR.pval { condition, subject } = surrogates.xCOR / ( config.surrogates + 1 ); end
            if H_check ( config.measures, 'COH'  ), indexes.COH.pval  { condition, subject } = surrogates.COH  / ( config.surrogates + 1 ); end
            if H_check ( config.measures, 'iCOH' ), indexes.iCOH.pval { condition, subject } = surrogates.iCOH / ( config.surrogates + 1 ); end
            if H_check ( config.measures, 'PSI'  ), indexes.PSI.pval  { condition, subject } = surrogates.PSI  / ( config.surrogates + 1 ); end
        end
    end
end

% Checks for user cancelation.
if ( H_stop ), return, end

delete ( waitbar.handle );
waitbar.handle = [];

% Appends the information of the successful execution to the project log.
H_log ( project, 'success' );
