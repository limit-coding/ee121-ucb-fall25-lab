% EE121 Lab 5 analysis script
% Run this file from the folder containing:
%   audi_key.mat, mazda_key.mat, prius_key.mat

clear; close all; clc;

%% 1. Audi signal: OOK / split phase style waveform
S = load('audi_key.mat');
if isfield(S, 'da')
    da = S.da;
elseif isfield(S, 'dp')
    % Some distributed copies of the Audi file store the data as dp.
    da = S.dp;
else
    error('Could not find Audi signal variable da or dp in audi_key.mat');
end
if isfield(S, 'fs')
    fs = S.fs;
else
    fs = 2.4e6;
    fprintf('audi_key.mat did not include fs; using fs = %.1f MHz\n', fs / 1e6);
end

t_audi = (0:length(da)-1) / fs;
env_audi = abs(da);

figure(1);
plot(t_audi * 1e3, env_audi);
grid on;
xlabel('Time, ms');
ylabel('Amplitude');
title('Audi key fob: amplitude waveform');

% Make a simple OOK decision threshold. If this threshold is not clean on
% your plot, manually adjust threshold_audi and rerun.
low_level = median(env_audi);
high_level = prctile(env_audi, 99);
threshold_audi = low_level + 0.35 * (high_level - low_level);
bits_audi_raw = env_audi > threshold_audi;

% Find the active part of the packet.
idx_active = find(bits_audi_raw);
start_idx = idx_active(1);
stop_idx = idx_active(end);
packet = bits_audi_raw(start_idx:stop_idx);

% Estimate pulse length from runs of high/low values inside the packet.
edges = [1; find(diff(packet(:)) ~= 0) + 1; length(packet(:)) + 1];
run_lengths = diff(edges);

% Manchester/split-phase data should mostly have one or two half-bit runs.
% Use the lower half of run lengths to estimate one pulse / half-bit time.
short_runs = run_lengths(run_lengths > 0 & run_lengths < prctile(run_lengths, 70));
half_bit_samples = median(short_runs);
bit_time = 2 * half_bit_samples / fs;
num_bits = round(length(packet) / (2 * half_bit_samples));

fprintf('Audi threshold: %.3f\n', threshold_audi);
fprintf('Audi estimated half-bit pulse: %.1f samples = %.3f us\n', ...
    half_bit_samples, half_bit_samples / fs * 1e6);
fprintf('Audi estimated bit time: %.3f us\n', bit_time * 1e6);
fprintf('Audi estimated number of bits: %d\n', num_bits);

figure(2);
plot(t_audi(start_idx:stop_idx) * 1e3, env_audi(start_idx:stop_idx));
hold on;
yline(threshold_audi, '--r', 'Threshold');
grid on;
xlabel('Time, ms');
ylabel('Amplitude');
title('Audi key fob: packet only');

zoom_samples = min(round(4e-3 * fs), length(packet));
figure(3);
plot((0:zoom_samples-1) / fs * 1e3, env_audi(start_idx:start_idx+zoom_samples-1));
hold on;
yline(threshold_audi, '--r', 'Threshold');
grid on;
xlabel('Time from packet start, ms');
ylabel('Amplitude');
title('Audi key fob: zoom of first bits');

%% 2a. Mazda signal: decimate and plot amplitude
S = load('mazda_key.mat');
if isfield(S, 'dm')
    dm = S.dm;
else
    error('Could not find Mazda signal variable dm in mazda_key.mat');
end
if isfield(S, 'fs')
    fs = S.fs;
else
    fs = 2.4e6;
    fprintf('mazda_key.mat did not include fs; using fs = %.1f MHz\n', fs / 1e6);
end

dmd = decimate(dm, 10);
fsa = fs / 10;
t_mazda = (0:length(dmd)-1) / fsa;

figure(4);
plot(t_mazda * 1e3, abs(dmd));
grid on;
xlabel('Time, ms');
ylabel('Amplitude');
title('Mazda key fob: amplitude after decimation to 240 kHz');

%% 2b. Mazda spectrogram
figure(5);
window_len = 240;       % 1 kHz resolution at 240 kHz sample rate
overlap_len = 120;
nfft = 240;
spectrogram(dmd, window_len, overlap_len, nfft, fsa, 'centered', 'yaxis');
title('Mazda key fob: spectrogram after 10x decimation');
colorbar;

%% 2c. Mazda FSK decode by isolating one frequency
% The two FSK tones are about 96 kHz apart. Estimate one tone from the
% average spectrum, then mix it to baseband and decimate to 40 kHz.
nfft_peak = 8192;
X = fftshift(fft(dmd, nfft_peak));
f_axis = (-nfft_peak/2:nfft_peak/2-1) * fsa / nfft_peak;

% Ignore near-DC bins so the chosen peak is one of the FSK tones.
search_mask = abs(f_axis) > 10e3 & abs(f_axis) < 115e3;
[~, peak_local] = max(abs(X(search_mask)));
freq_candidates = f_axis(search_mask);
f_offset = freq_candidates(peak_local);

fprintf('Mazda selected FSK tone offset: %.1f kHz\n', f_offset / 1e3);

n = (0:length(dmd)-1).';
tone_to_baseband = dmd(:) .* exp(-1j * 2 * pi * f_offset * n / fsa);

figure(6);
spectrogram(tone_to_baseband, window_len, overlap_len, nfft, fsa, 'centered', 'yaxis');
title('Mazda selected FSK tone mixed to baseband');
colorbar;

% Decimate to 40 kHz. This low-pass filters out the other FSK tone.
mazda_one_tone = decimate(tone_to_baseband, 6);
fsb = fsa / 6;
t_one = (0:length(mazda_one_tone)-1) / fsb;
env_one = abs(mazda_one_tone);

figure(7);
plot(t_one * 1e3, env_one);
grid on;
xlabel('Time, ms');
ylabel('Amplitude');
title('Mazda isolated FSK tone: OOK-like amplitude');

figure(8);
first_half = 1:floor(length(env_one)/2);
plot(t_one(first_half) * 1e3, env_one(first_half));
grid on;
xlabel('Time, ms');
ylabel('Amplitude');
title('Mazda isolated tone: first half zoom');

figure(9);
second_half = floor(length(env_one)/2):length(env_one);
plot(t_one(second_half) * 1e3, env_one(second_half));
grid on;
xlabel('Time, ms');
ylabel('Amplitude');
title('Mazda isolated tone: second half zoom');

fprintf('\nReport hints:\n');
fprintf('- Audi is OOK. Bits are represented by transitions, not steady high/low levels.\n');
fprintf('- Mazda amplitude before FSK demod is not clean OOK because information is in frequency.\n');
fprintf('- Mazda first half usually acts like a preamble/synchronization section.\n');
fprintf('- Decoding the other FSK tone should give the complementary bit stream.\n');
