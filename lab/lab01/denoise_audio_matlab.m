function denoise_audio_matlab(inputFile, modeName)
% DENOISE_AUDIO_MATLAB Generate denoised WAV files with MATLAB.
%   denoise_audio_matlab()
%   denoise_audio_matlab("新的音乐.wav", "balanced")
%
% Modes:
%   "gentle"   - light broadband cleanup
%   "balanced" - recommended default
%   "hum"      - stronger 50 Hz harmonic suppression
%   "strong"   - more aggressive cleanup

if nargin < 1 || strlength(string(inputFile)) == 0
    inputFile = "新的音乐.wav";
end
if nargin < 2 || strlength(string(modeName)) == 0
    modeName = "balanced";
end

inputFile = string(inputFile);
modeName = lower(string(modeName));

[x, fs] = audioread(inputFile);
if size(x, 2) == 1
    x = [x, x];
end

params = get_mode_params(modeName, fs);
y = zeros(size(x));
for ch = 1:size(x, 2)
    y(:, ch) = process_channel(x(:, ch), fs, params);
end

outputDir = fullfile("output_matlab", erase(inputFile, ".wav"));
if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

outputFile = fullfile(outputDir, sprintf("%s_%s.wav", erase(inputFile, ".wav"), modeName));
audiowrite(outputFile, y, fs);
fprintf("Saved: %s\n", outputFile);
end

function y = process_channel(x, fs, params)
x = highpass_stage(x, fs, params.highpassHz);
reference = x;

if params.applyHumNotch
    for f0 = [50 100 150 200 250]
        if f0 < fs / 2
            x = notch_stage(x, fs, f0, params.notchQ);
        end
    end
end

y = spectral_denoise(x, fs, params);
y = (1 - params.dryMix) * y + params.dryMix * reference;
y = match_level(y, reference, params.targetRmsRatio);

if params.lowpassHz > 0 && params.lowpassHz < fs / 2
    d = designfilt("lowpassiir", ...
        "FilterOrder", 8, ...
        "PassbandFrequency", params.lowpassHz, ...
        "PassbandRipple", 0.2, ...
        "SampleRate", fs);
    y = filtfilt(d, y);
end

y = max(min(y, 1), -1);
end

function y = match_level(y, reference, targetRatio)
refRms = sqrt(mean(reference .^ 2) + eps);
yRms = sqrt(mean(y .^ 2) + eps);
gain = targetRatio * refRms / yRms;
gain = min(gain, 3.0);
y = y * gain;
end

function y = highpass_stage(x, fs, cutoffHz)
d = designfilt("highpassiir", ...
    "FilterOrder", 6, ...
    "HalfPowerFrequency", cutoffHz, ...
    "SampleRate", fs);
y = filtfilt(d, x);
end

function y = notch_stage(x, fs, centerHz, q)
wo = centerHz / (fs / 2);
bw = wo / q;
[b, a] = iirnotch(wo, bw);
y = filtfilt(b, a, x);
end

function y = spectral_denoise(x, fs, params)
winLength = 2048;
hopLength = 512;
fftLength = 2048;
window = hann(winLength, "periodic");

[S, f, t] = stft(x, fs, ...
    "Window", window, ...
    "OverlapLength", winLength - hopLength, ...
    "FFTLength", fftLength);

mag = abs(S);
phase = angle(S);

frameEnergy = mean(mag .^ 2, 1);
[~, idx] = sort(frameEnergy, "ascend");
noiseFrames = idx(1:max(6, round(numel(idx) * params.noiseFrameRatio)));
noiseProfile = median(mag(:, noiseFrames), 2);

smoothProfile = movmean(noiseProfile, 7);
threshold = params.noiseFloorScale * smoothProfile;
gain = 1 - params.reductionStrength .* (threshold ./ max(mag, eps));
gain = max(gain, params.minGain);
gain = min(gain, 1.0);

if params.useHighFreqTaper
    taper = ones(size(f));
    highIdx = f >= params.taperStartHz;
    taper(highIdx) = linspace(1, params.highFreqGain, nnz(highIdx));
    gain = gain .* taper;
end

gain = smoothdata(gain, 2, "movmean", 5);
Y = gain .* mag .* exp(1j * phase);
y = istft(Y, fs, ...
    "Window", window, ...
    "OverlapLength", winLength - hopLength, ...
    "FFTLength", fftLength);

targetLength = length(x);
if length(y) < targetLength
    y(end + 1:targetLength, 1) = 0;
else
    y = y(1:targetLength);
end
end

function params = get_mode_params(modeName, fs)
params = struct( ...
    "highpassHz", 28, ...
    "applyHumNotch", false, ...
    "notchQ", 18, ...
    "noiseFrameRatio", 0.12, ...
    "noiseFloorScale", 1.35, ...
    "reductionStrength", 0.78, ...
    "minGain", 0.28, ...
    "dryMix", 0.18, ...
    "targetRmsRatio", 0.92, ...
    "useHighFreqTaper", false, ...
    "taperStartHz", 7000, ...
    "highFreqGain", 1.0, ...
    "lowpassHz", 0);

switch modeName
    case "gentle"
        params.highpassHz = 28;
        params.noiseFloorScale = 1.18;
        params.reductionStrength = 0.58;
        params.minGain = 0.45;
        params.dryMix = 0.30;
        params.targetRmsRatio = 0.96;

    case "balanced"
        params.highpassHz = 28;
        params.noiseFloorScale = 1.35;
        params.reductionStrength = 0.78;
        params.minGain = 0.28;
        params.dryMix = 0.22;
        params.targetRmsRatio = 0.94;

    case "hum"
        params.highpassHz = 32;
        params.applyHumNotch = true;
        params.notchQ = 22;
        params.noiseFloorScale = 1.28;
        params.reductionStrength = 0.72;
        params.minGain = 0.30;
        params.dryMix = 0.25;
        params.targetRmsRatio = 0.95;

    case "strong"
        params.highpassHz = 35;
        params.noiseFloorScale = 1.48;
        params.reductionStrength = 0.86;
        params.minGain = 0.18;
        params.dryMix = 0.12;
        params.targetRmsRatio = 0.90;
        params.useHighFreqTaper = true;
        params.taperStartHz = min(7000, fs / 2 - 100);
        params.highFreqGain = 0.82;
        params.lowpassHz = min(15500, fs / 2 - 200);

    otherwise
        error("Unsupported mode: %s", modeName);
end
end
