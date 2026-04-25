%% EE121 Lab 4 - Narrowband FM receiver
% This script loads one of the provided IQ captures, finds the strongest
% narrowband FM signal, mixes it to baseband, decimates it, demodulates the
% FM audio, and estimates the CTCSS tone.
%
% How to use:
%   1. Put this file in the same folder as vhf_tn1.mat, vhf_tn2.mat,
%      vhf_tn3.mat, and vhf_wr.mat.
%   2. Change dataFile below if you want to try another capture.
%   3. Run this script in MATLAB.
%   4. Check the command window for the detected frequency offset and
%      CTCSS estimate. Use the figures in your lab report.

clear; close all; clc;

%% -------------------- User settings --------------------

% Try these:
%   'vhf_tn1.mat'  - amateur radio N6NFI capture near 145 MHz
%   'vhf_tn2.mat'  - another amateur radio capture
%   'vhf_tn3.mat'  - another amateur radio capture
%   'vhf_wr.mat'   - weather radio capture near 162 MHz
dataFile = 'vhf_wr.mat';

% Set this to [] to let the script find the strongest signal automatically.
% For N6NFI in vhf_tn1.mat, the expected offset is about +230e3 Hz because
% the capture is centered at 145.000 MHz and the repeater transmits at
% 145.230 MHz.
manualOffsetHz = [];

% The first samples contain an SDR startup transient, so the lab asks us to
% skip them.
skipSamples = 2000;

% Decimation requested by the lab: 2.4 MHz / 120 = 20 kHz.
firstDecim = 120;

% Final audio decimation: 20 kHz / 2 = 10 kHz.
audioDecim = 2;

% Set true if you want MATLAB to play the decoded audio.
playAudio = true;

%% -------------------- Load data --------------------

S = load(dataFile);

% The .mat files may use names like tn1, tn2, tn3, or another capture name.
% This helper picks the largest numeric vector as the IQ data.
[x, dataVarName] = pick_iq_vector(S);
x = x(:);

% Use fc and fs from the .mat file if they exist. If not, use the lab values.
if isfield(S, 'fs')
    fs = double(S.fs);
else
    fs = 2.4e6;
end

if isfield(S, 'fc')
    fc = double(S.fc);
elseif contains(lower(dataFile), 'wr')
    fc = 162.0e6;
else
    fc = 145.0e6;
end

fprintf('Loaded %s\n', dataFile);
fprintf('Using IQ variable: %s, %d samples\n', dataVarName, length(x));
fprintf('Center frequency fc = %.6f MHz\n', fc/1e6);
fprintf('Sample rate fs = %.3f MHz\n\n', fs/1e6);

% Remove startup transient.
x = x(skipSamples+1:end);

% Remove a small DC offset. This makes the spectrum plot easier to read.
x = x - mean(x);

%% -------------------- Find strongest signal offset --------------------

if isempty(manualOffsetHz)
    offsetHz = find_strongest_offset(x, fs);
else
    offsetHz = manualOffsetHz;
end

fprintf('Detected offset = %.1f kHz\n', offsetHz/1e3);
fprintf('Estimated RF frequency = %.6f MHz\n\n', (fc + offsetHz)/1e6);

% Plot an overview spectrum and mark the chosen signal.
plot_overview_spectrum(x, fs, offsetHz);

%% -------------------- Mix signal to baseband --------------------

n = (0:length(x)-1).';
t = n / fs;

% Shift the selected RF channel from offsetHz down to 0 Hz.
xBaseband = x .* exp(-1j * 2*pi*offsetHz*t);

%% -------------------- Decimate to 20 kHz --------------------

xDecim = decimate_complex(xBaseband, firstDecim);
fsDecim = fs / firstDecim;

fprintf('After first decimation: fsDecim = %.1f kHz\n', fsDecim/1e3);

% This is the plot requested in report part 1(b). The magnitude should be
% nearly constant because FM carries information in phase, not amplitude.
timeDecim = (0:length(xDecim)-1).' / fsDecim;

figure('Name', 'FM signal magnitude after channel selection');
plot(timeDecim, abs(xDecim));
grid on;
xlabel('Time (s)');
ylabel('Magnitude');
title('Magnitude of demodulated and decimated FM signal');

% Spectrogram of the complex baseband signal before FM detection.
figure('Name', 'Complex baseband NBFM signal');
spectrogram(xDecim, hamming(512), 384, 1024, fsDecim, 'centered', 'yaxis');
title('Spectrogram after mixing and decimation');

%% -------------------- FM demodulation --------------------

% Method that often sounds bad:
% angle() wraps phase into [-pi, pi]. diff(angle()) turns wrap jumps into
% large false spikes, so this is shown only for comparison.
audioBad = diff(angle(xDecim));

% Better discriminator:
% conj(x[n-1])*x[n] has phase angle phi[n] - phi[n-1], which is the
% instantaneous frequency change. That is the FM message.
audioAngle = angle(conj(xDecim(1:end-1)) .* xDecim(2:end));

% Simpler narrowband discriminator:
% Normalize first so amplitude noise is mostly removed. For small phase
% increments, imag(exp(j*dphi)) = sin(dphi) is approximately dphi.
xNorm = xDecim ./ (abs(xDecim) + eps);
audio20k = imag(conj(xNorm(1:end-1)) .* xNorm(2:end));

% Remove DC before plotting/listening.
audio20k = audio20k - mean(audio20k);
audioAngle = audioAngle - mean(audioAngle);
audioBad = audioBad - mean(audioBad);

figure('Name', 'FM discriminator comparison');
subplot(3,1,1);
plot(audioBad);
grid on;
title('Bad method: diff(angle(x))');
xlabel('Sample');
ylabel('Amplitude');

subplot(3,1,2);
plot(audioAngle);
grid on;
title('Better method: angle(conj(x[n-1]) x[n])');
xlabel('Sample');
ylabel('Amplitude');

subplot(3,1,3);
plot(audio20k);
grid on;
title('Simpler method: imag(conj(x[n-1]) x[n]) after normalization');
xlabel('Sample');
ylabel('Amplitude');

% Spectrogram requested in report part 1(c), before final audio decimation.
figure('Name', 'Decoded audio at 20 kHz');
spectrogram(audio20k, hamming(512), 384, 1024, fsDecim, 'yaxis');
title('Decoded NBFM audio, fs = 20 kHz');

%% -------------------- Decimate audio to 10 kHz --------------------

audio10k = decimate(audio20k, audioDecim);
fsAudio = fsDecim / audioDecim;
audio10k = audio10k - mean(audio10k);

fprintf('Final audio sample rate = %.1f kHz\n\n', fsAudio/1e3);

figure('Name', 'Decoded audio at 10 kHz');
spectrogram(audio10k, hamming(512), 384, 1024, fsAudio, 'yaxis');
title('Decoded NBFM audio after final decimation, fs = 10 kHz');

figure('Name', 'Decoded audio waveform');
timeAudio = (0:length(audio10k)-1).' / fsAudio;
plot(timeAudio, audio10k);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Decoded audio waveform');

%% -------------------- Estimate CTCSS tone --------------------

% N6NFI has a low-frequency CTCSS/PL tone around 100 Hz. Weather radio
% generally will not have this same repeater access tone, so this estimate
% is mainly meaningful for the vhf_tn*.mat amateur-radio captures.
[ctcssHz, toneFreq, toneMag] = estimate_ctcss(audio10k, fsAudio);

fprintf('Estimated strongest low-frequency tone = %.1f Hz\n', ctcssHz);
fprintf('For N6NFI, the expected CTCSS/PL tone is about 100.0 Hz.\n');

figure('Name', 'Low-frequency audio spectrum for CTCSS');
plot(toneFreq, toneMag);
grid on;
xlim([0 300]);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title(sprintf('CTCSS search: strongest tone near %.1f Hz', ctcssHz));

%% -------------------- Optional audio playback --------------------

if playAudio
    fprintf('Playing 20 kHz audio...\n');
    soundsc(audio20k, fsDecim);
    pause(length(audio20k)/fsDecim + 1);

    fprintf('Playing 10 kHz audio...\n');
    soundsc(audio10k, fsAudio);
end

%% -------------------- Local helper functions --------------------

function [x, name] = pick_iq_vector(S)
% Pick the largest numeric vector in the loaded .mat struct.
    names = fieldnames(S);
    bestName = '';
    bestLen = 0;
    bestValue = [];

    for k = 1:numel(names)
        v = S.(names{k});
        if isnumeric(v) && isvector(v) && numel(v) > bestLen && numel(v) > 1000
            bestName = names{k};
            bestLen = numel(v);
            bestValue = v;
        end
    end

    if isempty(bestName)
        error('Could not find a numeric IQ vector in the MAT file.');
    end

    x = bestValue;
    name = bestName;
end

function offsetHz = find_strongest_offset(x, fs)
% Estimate the frequency offset of the strongest non-DC signal.
    maxSearchSamples = min(length(x), 2^21);
    xSearch = x(1:maxSearchSamples);

    nfft = 2^16;
    win = hamming(8192);
    noverlap = 4096;

    [Pxx, f] = pwelch(xSearch, win, noverlap, nfft, fs, 'centered');

    % Ignore DC and the outermost edge of the capture. DC can be an SDR
    % artifact; the edges can be distorted by the receiver/filter.
    mask = abs(f) > 5e3 & abs(f) < 0.48*fs;

    f2 = f(mask);
    P2 = Pxx(mask);

    [~, idx] = max(P2);
    offsetHz = f2(idx);
end

function y = decimate_complex(x, r)
% MATLAB decimate works well for real vectors. This wrapper makes the
% complex case explicit and robust.
    y = decimate(real(x), r) + 1j*decimate(imag(x), r);
end

function plot_overview_spectrum(x, fs, offsetHz)
% Plot the spectrum around the SDR center frequency.
    maxSearchSamples = min(length(x), 2^21);
    xSearch = x(1:maxSearchSamples);

    nfft = 2^16;
    [Pxx, f] = pwelch(xSearch, hamming(8192), 4096, nfft, fs, 'centered');
    PdB = 10*log10(Pxx + eps);

    figure('Name', 'Capture spectrum overview');
    plot(f/1e3, PdB);
    hold on;
    xline(offsetHz/1e3, 'r', 'LineWidth', 1.5);
    grid on;
    xlabel('Frequency offset from center (kHz)');
    ylabel('Power/frequency (dB/Hz)');
    title(sprintf('Strongest signal offset = %.1f kHz', offsetHz/1e3));
end

function [ctcssHz, fSmall, magSmall] = estimate_ctcss(audio, fsAudio)
% Search for a low-frequency tone between 50 Hz and 300 Hz.
    audio = audio(:);

    % Use a longer segment for finer resolution if enough data exists.
    N = min(length(audio), 20000);
    seg = audio(1:N);
    seg = seg - mean(seg);

    Nfft = 2^nextpow2(N);
    A = abs(fft(seg .* hamming(N), Nfft));
    f = (0:Nfft-1).' * fsAudio / Nfft;

    half = f <= fsAudio/2;
    f = f(half);
    A = A(half);

    lowMask = f >= 50 & f <= 300;
    fSmall = f(lowMask);
    magSmall = A(lowMask);

    [~, idx] = max(magSmall);
    ctcssHz = fSmall(idx);
end
