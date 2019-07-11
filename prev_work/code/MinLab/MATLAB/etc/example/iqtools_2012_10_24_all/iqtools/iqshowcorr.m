function iqshowcorr(filename)
% plot the magnitude correction (and phase correction if available)
if (~exist('filename'))
    filename = 'ampCorr.mat';
end

if (exist(filename, 'file'))
    load(filename);
    figure(10);
    clf(10);
    hold off;
    if (size(ampCorr,2) > 2)  % complex correction available
        phase = -1 * 180 / pi * unwrap(angle(ampCorr(:,3)));
        subplot(2,1,1);
        plot(ampCorr(:,1), -1*ampCorr(:,2), '.-');
        xlabel('Frequency (Hz)');
        ylabel('dB');
        grid on;
        subplot(2,1,2);
        plot(ampCorr(:,1), phase, 'm.-');
        xlabel('Frequency (Hz)');
        ylabel('degree');
        grid on;
        set(10, 'Name', 'Frequency and Phase Response');
    else
        plot(ampCorr(:,1), -1 * ampCorr(:,2), '.-');
        set(10, 'Name', 'Frequency Response');
        xlabel('Frequency (Hz)');
        ylabel('dB');
        grid on;
    end
else
    errordlg('No correction file available. Please use "Calibrate" to create a correction file');
end
