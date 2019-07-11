function driver = iqdownload_M933xA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence)
% download an IQ waveform to the M933xA
    driver = [];
    if (~isempty(sequence))
        errordlg('Sequence mode is not yet implemented for the M933xA');
        return;
    end
    try
        driver = instrument.driver.AgM933x();
    catch e
        errordlg({'Can''t open N933xA device driver (AgM933x):' e.message});
        return;
    end
    % initOptions = 'QueryInstrStatus=true, simulate=false, DriverSetup= DDS=false, Trace=false';
    initOptions = 'QueryInstrStatus=true, simulate=false, DriverSetup= DDS=false, Model=M9330A , Trace=false';  % Changed by Ray C
    idquery = true;
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        reset = true;
    else
        reset = false;
    end
    driver.Initialize(arbConfig.visaAddr, idquery, reset, initOptions); 
    driver.AbortGeneration();
    driver.DeviceSpecific.Arbitrary.Waveform.ClearAll();
    switch (downloadToChannel{1})
        case 'I+Q to channel 1+2'
            gen_arb_M933xA(arbConfig, driver, 1, real(data), marker1, fs, segmNum);
            gen_arb_M933xA(arbConfig, driver, 2, imag(data), marker2, fs, segmNum);
        case 'I+Q to channel 2+1'
            gen_arb_M933xA(arbConfig, driver, 1, imag(data), marker1, fs, segmNum);
            gen_arb_M933xA(arbConfig, driver, 2, real(data), marker2, fs, segmNum);
        case 'I to channel 1'
            gen_arb_M933xA(arbConfig, driver, 1, real(data), marker1, fs, segmNum);
        case 'I to channel 2'
            gen_arb_M933xA(arbConfig, driver, 2, real(data), marker1, fs, segmNum);
        case 'Q to channel 1'
            gen_arb_M933xA(arbConfig, driver, 1, imag(data), marker1, fs, segmNum);
        case 'Q to channel 2'
            gen_arb_M933xA(arbConfig, driver, 2, imag(data), marker1, fs, segmNum);
    end
    driver.DeviceSpecific.InitiateGeneration();   % Commented out by Ray C
    if (~exist('keepOpen') || keepOpen == 0)
        driver.Close();
    end;
end



function gen_arb_M933xA(arbConfig, driver, chan, data, marker, fs, segm_num)
    if (isfield(arbConfig, 'ampType'))
        switch arbConfig.ampType
% 1 = differential, 0 = single ended, 2 = amplified  % Modified by Ray C
            case 'DC'   % Added by Ray C 
                driver.DeviceSpecific.Output.Configuration(num2str(chan), 0);
            case 'DAC'  % Added by Ray C
                driver.DeviceSpecific.Output.Configuration(num2str(chan), 1);
            case 'AC'
                driver.DeviceSpecific.Output.Configuration(num2str(chan), 2);
        end
    end
    if (isfield(arbConfig,'amplitude'))
        driver.DeviceSpecific.Arbitrary.Gain(num2str(chan), arbConfig.amplitude(chan));    
    end
	driver.DeviceSpecific.Arbitrary.Waveform.Predistortion.Enabled = false;
    waveformHandle = driver.DeviceSpecific.Arbitrary.Waveform.Create(data);
   	driver.DeviceSpecific.Arbitrary.Waveform.Handle(num2str(chan), waveformHandle);
	driver.DeviceSpecific.Output.Enabled(num2str(chan), true);
 end


