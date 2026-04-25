function [h, tbw, samples] = designLowpassDemo(fs)
    % Low-pass filter design demo for EE121 Lab 2.
    % Target: decimate from 2.4 MHz to 10 kHz, LPF BW = 9.5 kHz,
    % transition width = 0.5 kHz.

    if nargin < 1
        fs = 2.4e6;
    end

    bw = 9.5e3;
    transition_width = 0.5e3;

    tbw = 2 * bw / transition_width;
    filter_time = tbw / bw;
    samples = round(filter_time * fs);

    h = wsinc(tbw, samples);

    fprintf('Desired TBW: %.2f\n', tbw);
    fprintf('Filter length: %.6f s (%.2f ms)\n', filter_time, filter_time * 1e3);
    fprintf('Number of samples at %.1f MHz: %d\n', fs / 1e6, samples);

    t = [0:samples - 1] / fs;
    figure;
    plot(t * 1000, h);
    title('Windowed Sinc Low-Pass Filter');
    xlabel('Time (ms)');
    ylabel('Amplitude');
    grid on;

    [H, f] = freqz(h, 1, 4096, fs / 1e6);
    figure;
    loglog(f, abs(H));
    title('Frequency Response of Windowed Sinc Filter');
    xlabel('Frequency (MHz)');
    ylabel('Magnitude');
    grid on;
end
