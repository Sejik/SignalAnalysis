%function output = H_methods_GS2d ( data, config, waitbar )

% Modified Ernesto Pereda

% HERMES v0.001
% Guiomar Niso, Madrid (2013)
%
% (based on Daniel Chicharro, Ralph G. Andrzejak, PRE, 2009)
%
% Copyright 2013 Guiomar Niso, Ricardo Bruna, Ernesto Pereda 2013

% This file is part of HERMES.
%
% HERMES is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% HERMES is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with HERMES. If not, see <http://www.gnu.org/licenses/>.

% Checks the completitude of the configuration structure.
measures = {};

if isfield ( config, 'EmbDim' ),      m        = config.EmbDim;      end
if isfield ( config, 'TimeDelay' ),   tau      = config.TimeDelay;   end
if isfield ( config, 'Nneighbours' ), k        = config.Nneighbours; end
if isfield ( config, 'w1' ),          W        = config.w1;          end %theiler window
if isfield ( config, 'measures' ),    measures = config.measures;    end

% Checks the existence of the waitbar.
if nargin < 3, waitbar = []; end

% Fetchs option data
S_on = H_check ( config.measures, 'S' );
H_on = H_check ( config.measures, 'H' );
M_on = H_check ( config.measures, 'M' );
N_on = H_check ( config.measures, 'N' );
L_on = H_check ( config.measures, 'L' );

% Windows the data
%data = H_window ( data, config.window );

% Gets the size of the analysis data.
[ samples, channels, trials ] = size ( data );

% Reserves the needed memory.
if S_on, output.S.rawdata = ones ( channels, channels, trials ); end
if H_on, output.H.rawdata = ones ( channels, channels, trials ); end
if M_on, output.M.rawdata = ones ( channels, channels, trials ); end
if N_on, output.N.rawdata = ones ( channels, channels, trials ); end
if L_on, output.L.rawdata = ones ( channels, channels, trials ); end

% Throttled user cancelation check vars
interval_between_checks = 1; % in seconds
tic

% Calculates the indexes for each trial and pair of sensors.

Neff  = samples - (m-1)*tau; % Number of vectors

% Effective number of distances for each reference vector
Ncorrected = (Neff-(W*2+1))*ones(1,Neff);

for w = 1:W
    Ncorrected(w) = Neff-W-(w);
    Ncorrected(Neff-w+1) = Neff-W-(w);
end;

RkX=zeros(Neff,1,'single'); 
ch_emb = zeros( Neff,m,'single');
MdistX=zeros(Neff,Neff,'single');MdistY=MdistX;
ind=zeros(Neff,Neff,channels,'uint16');

if L_on,
    % Matrixes of rank distances
    MrankX = zeros ( Neff, Neff,'uint16' ); MrankY=MrankX;
end

%%%%%%% Calculation of the indexes %%%%%%%%
%  for window = 1: windows

for trial = 1: trials
        
    %  First we sort the distances for all the channels in each trial once
    % to save time, as sorting is a time-consuming process
    
    for ch = channels: -1: 1
               
        for i=0:m-1
            ch_emb(:,i+1) = data(1+i*tau:Neff+i*tau,ch,trial);
        end
        
        MdistX = squareform(pdist(ch_emb));
           
        for i=1:Neff-W
            for j=1:W
                MdistX(i,i+j)=inf; MdistX(i+j,i)=inf;
            end
        end
        
        % And now for the elements of the diagonal
        MdistX(MdistX==0)=inf; 
        
        [~, ind(:,:,ch)] = sort(MdistX);

    end
     
    %% Prepare the distance matrix X and Hsums1
   
    MdistX(MdistX==inf)=0;
    Hsums1 = sum(MdistX)./Ncorrected;
    
    for ch1 = 1: channels-1
                 
           % Calculate the matrices of ranks.
          % indX = ind(:,:,ch1);
                                   
           if ch1>1       
               MdistX=MdistY; Hsums1=Hsums2; RkX=RkY;
               if L_on, MrankX=MrankY; end
           else
               
               RkX=(1/k)*sum(MdistX(ind(1:k,:,ch1),:))';               
               if L_on, MrankX(ind(:,:,ch1),:) = 1:Neff; end
              
           end
               
        for ch2 =  channels:-1:ch1+1
                    
            % Creating the embbeding vectors
            for i=0:m-1
                ch_emb(:,i+1) = data (1+i*tau:Neff+i*tau,ch2,trial);
            end
            
            % Checks for user cancelation (Throttled)
            if toc > interval_between_checks
                tic        
                if ( H_stop ), return, end
            end
            
            MdistY = squareform(pdist(ch_emb));
            
            % Now we set to zero the distances to vectors closer to each
            % reference than the Theiler window
            
            for i=1:Neff-W
                for j=1:W
                    MdistY(i,i+j)=0; MdistY(i+j,i)=0;
                end
            end
            
            Hsums2 = sum(MdistY)./Ncorrected;
            
           % indY = ind(:,:,ch2);
            
            if L_on,
                
                % Matrixes of rank distances
                 MrankY(ind(:,:,ch2),:) = 1:Neff;
                             
            end
            
            for index = measures
                partialX.( index { 1 } ) = zeros ( Neff, 1 );
                partialY.( index { 1 } ) = zeros ( Neff, 1 );
            end
            
                          
            for n = 1:Neff
                
                RkY(n)=(1/k)*sum(MdistY(ind(1:k,n,ch2),n));
                
                RcondXY = (1/k) * sum ( MdistX ( ind ( 1: k, n, ch2 ), n ) );
                RcondYX = (1/k) * sum ( MdistY ( ind ( 1: k, n, ch1 ), n ) );
                               
                if S_on,
                    partialX.S ( n ) = RkX (n)/ RcondXY;
                    partialY.S ( n ) = RkY (n)/ RcondYX;
                end
                
                if H_on,
                    partialX.H ( n ) = log ( Hsums1 ( n ) / RcondXY );
                    partialY.H ( n ) = log ( Hsums2 ( n ) / RcondYX );
                end
                
                if M_on,
                    partialX.M ( n ) = ( Hsums1 ( n ) - RcondXY ) / ( Hsums1 ( n ) - RkX (n));
                    partialY.M ( n ) = ( Hsums2 ( n ) - RcondYX ) / ( Hsums1 ( n ) - RkY (n));
                end
                
                if N_on,
                    partialX.N ( n ) = ( Hsums1 ( n ) - RcondXY ) / ( Hsums1 ( n ) );
                    partialY.N ( n ) = ( Hsums2 ( n ) - RcondYX ) / ( Hsums1 ( n ) );
                end
                
                if L_on,
                    partialX.L ( n ) = ( ( Ncorrected ( n ) + 1 ) / 2 - sum ( MrankX ( ind ( 1: k, n, ch2 ), n ) ) / k ) / ( ( Ncorrected ( n ) + 1 ) / 2 - ( k + 1 ) / 2 );
                    partialY.L ( n ) = ( ( Ncorrected ( n ) + 1 ) / 2 - sum ( MrankY ( ind ( 1: k, n, ch1 ), n ) ) / k ) / ( ( Ncorrected ( n ) + 1 ) / 2 - ( k + 1 ) / 2 );
                end               
            end
             
            % Construcction of the indexes
            
            if S_on,
                output.S.rawdata ( ch1, ch2, trial ) = mean ( partialX.S );
                output.S.rawdata ( ch2, ch1, trial ) = mean ( partialY.S );
            end
            
            if H_on,
                output.H.rawdata ( ch1, ch2, trial ) = mean ( partialX.H );
                output.H.rawdata ( ch2, ch1, trial ) = mean ( partialY.H );
            end
            
            if M_on,
                output.M.rawdata ( ch1, ch2, trial ) = mean ( partialX.M );
                output.M.rawdata ( ch2, ch1, trial ) = mean ( partialY.M );
            end
            
            if N_on,
                output.N.rawdata ( ch1, ch2, trial ) = mean ( partialX.N );
                output.N.rawdata ( ch2, ch1, trial ) = mean ( partialY.N );
            end
            
            if L_on,
                output.L.rawdata ( ch1, ch2, trial ) = mean ( partialX.L );
                output.L.rawdata ( ch2, ch1, trial ) = mean ( partialY.L );
            end
            
            % Throttled check.
            %                 if toc > interval_between_checks
            %                     tic
            
            % Checks for user cancelation.
            %                     if ( H_stop ), return, end
            
            % Updates the waitbar.
            %                     if ~isempty ( waitbar )
            %                         waitbar.progress ( 5: 6 ) = [ trial trials ];
            %                         waitbar.progress ( 7: 8 ) = [ window windows ];
            %                         waitbar.progress ( 9 ) = ( 2 * channels - ch1 ) * ( ch1 - 1 ) / 2 + ( ch2 - ch1 );
            %                         waitbar.progress ( 10 ) = channels * ( channels - 1 ) / 2;
            %                         waitbar                = H_waitbar ( waitbar );
            %                     end
            %                 end
            
        end
    end
    
    % Updates the waitbar.
    %         if isstruct ( waitbar )
    %             waitbar.progress ( 5: 6 )   = [ trial trials ];
    %             waitbar.progress ( 7: 8 )   = [ window windows ];
    %             waitbar.progress ( 9: end ) = [];
    %             waitbar                     = H_waitbar ( waitbar );
    %         end
end

%end



% Averages across trials.
if S_on,
    output.S.data = mean ( output.S.rawdata, 4 );
    if sum( sum( output.S.data < 0 ) ) >= 1
        output.S.data (output.S.data < 0 ) = 0;
 %       warndlg ('Negative values of GS index S were obtained. It is advisable to increase the number of neighbours', 'GS warning');
    end
end

if H_on,
    output.H.data = mean ( output.H.rawdata, 4 );
    if sum( sum( output.H.data < 0 ) ) >= 1
        output.H.data (output.H.data < 0 ) = 0;
%        warndlg ('Negative values of GS index H were obtained. It is advisable to increase the number of neighbours', 'GS warning');
    end
end

if M_on,
    output.M.data = mean ( output.M.rawdata, 4 );
    if sum( sum( output.M.data < 0 ) ) >= 1
        output.M.data (output.M.data < 0 ) = 0;
 %       warndlg ('Negative values of GS index M were obtained. It is advisable to increase the number of neighbours', 'GS warning');
    end
end

if N_on,
    output.N.data = mean ( output.N.rawdata, 4 );
    if sum( sum( output.N.data < 0 ) ) >= 1
        output.N.data (output.N.data < 0 ) = 0;
 %       warndlg ('Negative values of GS index N were obtained. It is advisable to increase the number of neighbours', 'GS warning');
    end
end

if L_on,
    output.L.data = mean ( output.L.rawdata, 4 );
    if sum( sum( output.L.data < 0 ) ) >= 1
        output.L.data (output.L.data < 0 ) = 0;
  %      warndlg ('Negative values of GS index L were obtained. It is advisable to increase the number of neighbours', 'GS warning');
    end
end

% Removes trial information.
if S_on, output.S = rmfield ( output.S, 'rawdata' ); end
if H_on, output.H = rmfield ( output.H, 'rawdata' ); end
if M_on, output.M = rmfield ( output.M, 'rawdata' ); end
if N_on, output.N = rmfield ( output.N, 'rawdata' ); end
if L_on, output.L = rmfield ( output.L, 'rawdata' ); end
