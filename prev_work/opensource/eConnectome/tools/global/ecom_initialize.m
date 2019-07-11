function ECOM = ecom_initialize()
% ecom_initialize - create an ECOM structure for storing EEG/ECOG/MEG data
%
% Usage: ECOM = ecom_initialize
%               Output: ECOM - is a uniform structure for storing EEG/ECOG/MEG data.
%               It has following fields:
%               ECOM.name - is the name for the EEG/ECOG/MEG data.
%               ECOM.type - is the type of the time series data ('EEG', 'ECOG' or 'MEG').
%               ECOM.nbchan - is the number of channels.
%               ECOM.points - is the number of sampling points.
%               ECOM.srate - is the sampling rate.
%               ECOM.labeltype  - is the type of the electrode labels.
%                                             It is for EEG only, either 'standard' or 'customized'.  
%               ECOM.labels  - is a cell array for channel labels.
%               ECOM.locations  - stores channel locations.
%               ECOM.data  - is a 2D array (M * N) for the time series data,
%                                      where M equals the number of channels and 
%                                      N equals the number of sampling points.
%               ECOM.unit  - is the unit of the EEG/ECOG/MEG signal (e.g. 'uV').
%               ECOM.start - is the start channel to display in the time series view window. 
%               ECOM.end - is the end channel to display in the time series view window. 
%               ECOM.dispchans - is the number of channels to display in the time series view window. 
%               ECOM.bad - is a vector storing indices of bad channels. 
%               ECOM.vidx - is a vector storing indices of valid channels. 
%               ECOM.min - is the minimum value of the time series.
%               ECOM.max - is the maximum value of the time series.
%               ECOM.event - stores the information for events
%
% The ECOM structure is implemented as EEG, ECOG and MEG in the eegfc, ecogfc and megfc modules respectively. 
%
% Program Author: Yakang Dai, University of Minnesota, USA
%
% User feedback welcome: e-mail: econnect@umn.edu
%

% License
% ==============================================================
% This program is part of the eConnectome.
% 
% Copyright (C) 2010 Regents of the University of Minnesota. All rights reserved.
% Correspondence: binhe@umn.edu
% Web: econnectome.umn.edu
%
% This program is free software for academic research: you can redistribute it and/or modify
% it for non-commercial uses, under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see http://www.gnu.org/copyleft/gpl.html.
%
% This program is for research purposes only. This program
% CAN NOT be used for commercial purposes. This program 
% SHOULD NOT be used for medical purposes. The authors 
% WILL NOT be responsible for using the program in medical
% conditions.
% ==========================================

% Revision Logs
% ==========================================
%
% Yakang Dai, 20-May-2011 15:46:30
% Modify notes for Version 2.0 beta 
%
% Yakang Dai, 20-Apr-2010 16:18:30
% Add event field
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

ECOM.name     =  'UnTitled';
ECOM.type        =  'EEG';
ECOM.nbchan      = 1;
ECOM.points        = 1;
ECOM.srate       = 1;
ECOM.labeltype = '';
ECOM.labels    = {};
ECOM.locations = [];
ECOM.data        = [];
ECOM.unit    = 'uV';
ECOM.start   = 1;
ECOM.end   = 1;
ECOM.dispchans   = 1;
ECOM.bad = [];
ECOM.vidx = [];
ECOM.min = 0;
ECOM.max = 1;
ECOM.event = [];
