function [segment, d_fft, f, pks, locs] = plotDetectionExample(data, fs, fc, t0, output_name)
    % Plot one 2400-sample detection window and its FFT peaks.
    % This reproduces the example analysis figure described in EE121 Lab 2.
    %
    % Inputs:
    %   data        - complex IQ samples
    %   fs          - sample rate, e.g. 2.4e6
    %   fc          - center frequency, e.g. 134.8e6
    %   t0          - start time in seconds for the analysis window
    %   output_name - optional filename to save under output/

    if nargin < 4 || isempty(t0)
        t0 = 1.0;
    end

    if nargin < 5 || isempty(output_name)
        output_name = sprintf('detection_example_t%.2fs.png', t0);
    end

    freq_res = 1000;
    n_samp = round(fs / freq_res);
    n0 = round(t0 * fs);

    if n0 + n_samp > length(data)
        error('Selected time window exceeds available data length.');
    end

    segment = data(n0 + 1 : n0 + n_samp);
    d_fft = fftshift(fft(segment));
    f = (-n_samp/2 : n_samp/2 - 1) * freq_res;

    [pks, locs] = findpeaks(abs(d_fft), 'MinPeakProminence', 1e4);

    output_dir = fullfile(pwd, 'output');
    if exist(output_dir, 'dir') ~= 7
        mkdir(output_dir);
    end

    figure('Visible', 'off');

    subplot(2,1,1);
    plot(0:n_samp-1, abs(segment));
    title(sprintf('Signal Magnitude at t = %.2f s', t0));
    xlabel('samples');
    ylabel('Magnitude');
    grid on;

    subplot(2,1,2);
    plot(f, abs(d_fft), '-', f(locs), pks, 'o');
    title(sprintf('Spectrum Around fc = %.3f MHz', fc / 1e6));
    xlabel('Offset Frequency (Hz)');
    ylabel('Magnitude');
    grid on;

    saveas(gcf, fullfile(output_dir, output_name));
    close(gcf);
end
