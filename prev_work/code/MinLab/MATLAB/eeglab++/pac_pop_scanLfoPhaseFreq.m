% pac_pop_scanLfoPhaseFreq() - scan low-frequency phase
       
% Author: Makoto Miyakoshi, JSPS/SCCN,INC,UCSD 2012. He likes Pacman Power-Pill Mix.
% History:
% 06/24/2013 ver 1.1 by Makoto. Explanatin in GUI renewed.
% 01/15/2013 ver 1.0 by Makoto. Created.

% Copyright (C) 2012 Makoto Miyakoshi, JSPS/SCCN,INC,UCSD;
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function EEG = pac_pop_scanLfoPhaseFreq(EEG)

userInput = inputgui('title', 'pac_pop_scanLfoPhaseFreq', 'geom', ...
   {{2 7 [0 0] [1 1]} {2 7 [1 0] [1 1]} ...
    {2 7 [0 1] [1 1]} {2 7 [1 1] [1 1]} ...
    {2 7 [0 2] [1 1]} {2 7 [1 2] [1 1]} ...
    {2 7 [0 3] [1 1]} {2 7 [1 3] [1 1]} ...
    {2 7 [0 4] [1 1]} {2 7 [1 4] [1 1]} ...
    {2 7 [0 5] [1 1]} {2 7 [1 5] [1 1]} ...
    {2 7 [0 6] [1 1]} {2 7 [1 6] [1 1]}}, ... 
'uilist',...
   {{'style' 'text' 'string' 'LFO freq range [loHz hiHz]'}                     {'style' 'edit' 'string' '0.5 8'}... 
    {'style' 'text' 'string' 'How many points in LFO [N]'}                     {'style' 'edit' 'string' '15'}...
    {'style' 'text' 'string' 'HFO freq range [loHz hiHz]; [loHz 0]->hipass' }  {'style' 'edit' 'string' '100 0'}...
    {'style' 'text' 'string' 'HFO amp percentile range [lo% hi%]'}             {'style' 'edit' 'string' '0.1 3'}...
    {'style' 'text' 'string' 'How many points in HFO percentiles [N]'}         {'style' 'edit' 'string' '15'}...
    {'style' 'text' 'string' 'Plot Modulation Index or mean vector length'}    {'style' 'popupmenu' 'string' 'mean vector length|Modulation Index' 'value' 1}...
    {'style' 'text' 'string' 'Normalize color schema across channels'}         {'style' 'checkbox' 'value' 1}});

phaseFreqRange = str2num(userInput{1,1});
numPhaseFreqs  = str2num(userInput{1,2});
ampFreqRange   = str2num(userInput{1,3});
hasRateRange   = str2num(userInput{1,4});
numHasRates    = str2num(userInput{1,5});
plotType       = userInput{1,6};
normalizeColor = userInput{1,7};

EEG = pac_scanLfoPhaseFreq(EEG, phaseFreqRange, numPhaseFreqs, ampFreqRange, hasRateRange, numHasRates, plotType, normalizeColor);
