%{
AsciiArb is a sample program that demonstrates how to download an arbitrary waveform
	into instrument volatile memory and play back the same with the configuration below:
	This arb generates a 8192 point pulse waveform, of which the first 400 points define a
	positive pulse from 0 volts to the maximum defined voltage amplitude.

Wave Shape: Arb
Amplitude:	2 Volt Peak to Peak
Offset:		0 Volt
Output Impedance:	50 Ohm
Output: Enabled

This example will work with the Agilent 33210A, 33220A, and 33250A
%}


% clears all variables, closes all open files

%%function String = User_Fgen(Onset, Offset, Freq )
function String = User_Fgen(Freq)
%opens and creates a visa session for communication with function generator

fgen = visa('AGILENT','usb0::2391::1031::MY44052879::INSTR');
set (fgen,'OutputBufferSize',100000);
fopen(fgen);

%Query Idendity string and report
fprintf (fgen, '*IDN?');
idn = fscanf (fgen);
fprintf (idn)
fprintf ('\n\n')

%Clear and reset instrument
fprintf (fgen, '*RST');
fprintf (fgen, '*CLS');


	% Create arb waveform with 8192 points of 0-1 data
	fprintf('Generating Waveform...\n\n')
	
    rise=[];
	for i = 1:1:10        % Set rise time (10 points) */
		z = (i-1)/10;
        y = num2str(z);
        s1 = sprintf(', %s', y);
        rise = [rise s1];
    end
    
    width=[];
	for i= 11:1:411      % Set pulse width (400 points) */
        y = num2str(1);
        s2 = sprintf(', %s', y);
        width = [width s2];
    end
    
    fall=[];
	for i = 412:1:422   % Set fall time (10 points) */
		z= (422 - i)/10;
        y = num2str(z);
        s3 = sprintf(', %s', y);
        fall = [fall s3];
    end
    
    low=[];
	for i = 423:1:8192   % Set remaining points to zero */
		y = num2str(0);
        s4 = sprintf(', %s', y);
        low = [low s4];
    end
    
    %combine all of the strings
    s = [rise width fall low];
    
    % combine string of data with scpi command
	arbstring =sprintf('DATA VOLATILE %s', s);

    
	%Send Command to set the desired configuration
	fprintf('Downloading Waveform...\n\n')
	fprintf(fgen, arbstring);
    %make instrument wait for data to download before moving on to next
    %command set
	fprintf(fgen, '*WAI');
	fprintf('Download Complete\n\n');
    
    %Set desired configuration.
    
    %arbstring = sprintf('VOLT %s', Onset);
    %fprintf(fgen, arbstring);
    %arbstring = sprintf('VOLT:OFFSET %s', Offset);
    %fprintf(fgen, arbstring);
    %fprintf(fgen,'OUTPUT:LOAD 50'); % set output load to 50 ohms
    %arbstring = sprintf('FREQ %s', Freq);
    %fprintf(fgen, arbstring);
    %fprintf(fgen,'FUNC:USER VOLATILE');
    %fprintf(fgen,'FUNC:SHAP USER');

    
    %Set desired configuration.
    fprintf(fgen,'VOLT 2'); % set max waveform amplitude to 2 Vpp
    fprintf(fgen,'VOLT:OFFSET 0'); % set offset to 0 V
    fprintf(fgen,'OUTPUT:LOAD 50'); % set output load to 50 ohms
    fprintf(fgen,'FREQ 100'); %set frequency to 1KHz
    fprintf(fgen,'FUNC:USER VOLATILE');
    fprintf(fgen,'FUNC:SHAP USER');

	%Set desired configuration.
    %fprintf(fgen,'VOLT 2'); % set max waveform amplitude to 2 Vpp
    %fprintf(fgen,'VOLT:OFFSET 0'); % set offset to 0 V
    %fprintf(fgen,'OUTPUT:LOAD 50'); % set output load to 50 ohms
    %temp_Freq = num2str(Freq);
    %arbstring = sprintf('FREQ %s',  100);
    %fprintf(fgen, arbstring);
    
    %fprintf(fgen,'FREQ 100'); %set frequency to 1KHz
    %fprintf(fgen,'FUNC:USER VOLATILE');
    %fprintf(fgen,'FUNC:SHAP USER');
 

    %Enable Output
    fprintf(fgen,'OUTPUT ON'); % turn on channel 1 output


% Read Error
fprintf(fgen, 'SYST:ERR?');
errorstr = fscanf (fgen);

% error checking
if strncmp (errorstr, '+0,"No error"',13)
   errorcheck = 'Arbitrary waveform generated without any error \n';
   fprintf (errorcheck)
else
   errorcheck = ['Error reported: ', errorstr];
   fprintf (errorcheck)
end

%closes the visa session with the function generator
fclose(fgen);
end