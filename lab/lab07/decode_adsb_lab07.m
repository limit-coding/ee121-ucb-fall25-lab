% EE121 Lab07 ADS-B / Mode-S offline decoder
% Input: rtl_sdr raw unsigned 8-bit IQ file, interleaved as I,Q,I,Q,...
% Example capture:
%   rtl_sdr -f 1090000000 -s 2400000 -g 49.6 -n 24000000 adsb_test_2.4M.iq

clear; clc;

filename = 'adsb_test_2.4M.iq';
fsRaw = 2.4e6;           % Sample rate used by rtl_sdr
fsDecode = 4.0e6;        % Decode after resampling to 4 MHz, 4 samples/us
maxMessagesToPrint = 80;
maxDebugFramesToPrint = 20;

fprintf('Reading %s ...\n', filename);
fid = fopen(filename, 'rb');
assert(fid > 0, 'Cannot open input file: %s', filename);
raw = fread(fid, inf, 'uint8=>double');
fclose(fid);

assert(mod(numel(raw), 2) == 0, 'IQ file must contain an even number of bytes.');

I = raw(1:2:end) - 127.5;
Q = raw(2:2:end) - 127.5;
mag = I.^2 + Q.^2;
clear raw I Q;

fprintf('Raw complex samples: %d, duration: %.2f s\n', numel(mag), numel(mag) / fsRaw);
fprintf('Raw magnitude percentiles: p50=%.1f, p90=%.1f, p99=%.1f, p99.9=%.1f, max=%.1f\n', ...
    prctile(mag, 50), prctile(mag, 90), prctile(mag, 99), prctile(mag, 99.9), max(mag));

% The raw 2.4 MS/s capture has 2.4 samples per ADS-B bit. Resampling the
% magnitude envelope to 4 MHz gives exactly 4 samples/us, making preamble
% and half-bit energy windows much cleaner for this lab decoder.
magRaw = mag;
if exist('resample', 'file') == 2
    mag = resample(magRaw, 5, 3);
else
    tRaw = (0:numel(magRaw)-1) / fsRaw;
    tDecode = 0:(1/fsDecode):tRaw(end);
    mag = interp1(tRaw, magRaw, tDecode, 'linear', 'extrap').';
end
mag(mag < 0) = 0;
fs = fsDecode;

fprintf('Resampled magnitude samples: %d, duration: %.2f s, fs=%.1f MHz\n', ...
    numel(mag), numel(mag) / fs, fs / 1e6);
fprintf('Resampled percentiles: p50=%.1f, p90=%.1f, p99=%.1f, p99.9=%.1f, max=%.1f\n', ...
    prctile(mag, 50), prctile(mag, 90), prctile(mag, 99), prctile(mag, 99.9), max(mag));

[~, strongestPos] = max(mag);
plotStart = max(1, strongestPos - round(25e-6 * fs));
plotEnd = min(numel(mag), strongestPos + round(250e-6 * fs));
figure(1);
plot((plotStart:plotEnd) / fs * 1e6, mag(plotStart:plotEnd));
grid on;
xlabel('Time (us)');
ylabel('Magnitude');
title(sprintf('Strongest pulse neighborhood, index %d', strongestPos));

[messages, debugFrames] = decode_adsb_from_magnitude(mag, fs, maxDebugFramesToPrint);

fprintf('\nCRC-valid ADS-B DF17/DF18 messages: %d\n', numel(messages));
fprintf('Idx          Raw message                  DF  ICAO    TC  Callsign\n');
fprintf('-------------------------------------------------------------------\n');

for k = 1:min(numel(messages), maxMessagesToPrint)
    msg = messages(k);
    fprintf('%-12d %-28s %2d  %-6s  %2d  %s\n', ...
        msg.index, msg.hex, msg.df, msg.icao, msg.typeCode, msg.callsign);
end

if isempty(messages)
    fprintf('\nNo CRC-valid message was found.\n');
    fprintf('If this happens with a real capture, try: stronger 1090 MHz antenna, outdoor/window placement,\n');
    fprintf('gain around 35-49.6 dB, sample rate 2.4 MS/s, and capture while dump1090 is seeing aircraft.\n');
end

if ~isempty(debugFrames)
    fprintf('\nBest non-CRC candidates for debugging:\n');
    fprintf('Idx          DF  ICAO    TC  CRC syndrome  CallsignGuess  Score\n');
    fprintf('-----------------------------------------------------------------\n');
    for k = 1:numel(debugFrames)
        d = debugFrames(k);
        fprintf('%-12d %2d  %-6s  %2d  %-12s  %-12s  %.3f\n', ...
            d.index, d.df, d.icao, d.typeCode, d.syndrome, d.callsign, d.quality);
    end
end

function [messages, debugFrames] = decode_adsb_from_magnitude(mag, fs, maxDebugFrames)
    samplesPerUs = fs / 1e6;
    n = numel(mag);
    frameSpan = ceil(120 * samplesPerUs);

    if n < frameSpan
        error('Capture is too short for one ADS-B frame.');
    end

    % Coarse preamble score. ADS-B preamble has pulses at:
    % 0, 0.5, 1.0, 3.5 us, and quiet regions in between.
    highUs = [0, 0.5, 1.0, 3.5];
    lowUs  = [1.5, 2.0, 2.5, 3.0, 4.0, 4.5];
    shiftsHigh = round(highUs * samplesPerUs);
    shiftsLow = round(lowUs * samplesPerUs);

    scoreLen = n - frameSpan;
    score = zeros(scoreLen, 1);
    for s = shiftsHigh
        score = score + mag(1+s:scoreLen+s);
    end
    for s = shiftsLow
        score = score - 0.65 * mag(1+s:scoreLen+s);
    end

    noise = prctile(mag, 99.5);
    scoreThreshold = max(50, 2.0 * noise);
    [~, order] = sort(score, 'descend');

    maxCandidates = min(20000, numel(order));
    minSpacing = round(120 * samplesPerUs);
    candidates = zeros(maxCandidates, 1);
    candidateCount = 0;

    for ii = 1:maxCandidates
        idx = order(ii);
        if score(idx) < scoreThreshold
            break;
        end
        if candidateCount == 0 || all(abs(idx - candidates(1:candidateCount)) > minSpacing)
            candidateCount = candidateCount + 1;
            candidates(candidateCount) = idx;
        end
    end
    candidates = candidates(1:candidateCount);
    fprintf('Preamble candidates: %d, score threshold: %.1f\n', numel(candidates), scoreThreshold);

    csum = [0; cumsum(mag)];
    seen = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    messages = struct('index', {}, 'bits', {}, 'hex', {}, 'df', {}, 'icao', {}, ...
                      'typeCode', {}, 'callsign', {});
    debugFrames = struct('index', {}, 'df', {}, 'icao', {}, 'typeCode', {}, ...
                         'syndrome', {}, 'callsign', {}, 'quality', {});

    fineOffsets = -3:0.125:3;
    for c = 1:numel(candidates)
        baseIndex = candidates(c);
        for off = fineOffsets
            start = baseIndex + off;
            [bits, quality] = try_decode_one(csum, n, start, samplesPerUs);
            if isempty(bits)
                continue;
            end

            df = bits_to_int(bits(1:5));
            if ~(df == 17 || df == 18)
                continue;
            end

            hx = bits_to_hex(bits);
            typeCode = bits_to_int(bits(33:37));
            callsign = '';
            if typeCode >= 1 && typeCode <= 4
                callsign = decode_callsign(bits);
            end

            [crcOK, syndrome] = adsb_crc_check(bits);
            if numel(debugFrames) < maxDebugFrames
                d.index = round(start);
                d.df = df;
                d.icao = hx(3:8);
                d.typeCode = typeCode;
                d.syndrome = syndrome;
                d.callsign = callsign;
                d.quality = quality;
                debugFrames(end+1) = d; %#ok<AGROW>
            end

            if ~crcOK
                continue;
            end

            if isKey(seen, hx)
                continue;
            end
            seen(hx) = true;

            m.index = round(start);
            m.bits = bits;
            m.hex = hx;
            m.df = df;
            m.icao = hx(3:8);
            m.typeCode = typeCode;
            m.callsign = callsign;
            messages(end+1) = m; %#ok<AGROW>
        end
    end
end

function [bits, quality] = try_decode_one(csum, n, start, samplesPerUs)
    bits = [];
    quality = 0;

    highUs = [0, 0.5, 1.0, 3.5];
    lowUs  = [1.5, 2.0, 2.5, 3.0, 4.0, 4.5];

    high = zeros(size(highUs));
    low = zeros(size(lowUs));
    for k = 1:numel(highUs)
        high(k) = mean_window(csum, n, start + highUs(k) * samplesPerUs, ...
                              start + (highUs(k) + 0.5) * samplesPerUs);
    end
    for k = 1:numel(lowUs)
        low(k) = mean_window(csum, n, start + lowUs(k) * samplesPerUs, ...
                             start + (lowUs(k) + 0.5) * samplesPerUs);
    end

    if min(high) < 12 || min(high) < 1.25 * max(low)
        return;
    end
    quality = min(high) / (max(low) + 1e-9);

    bits = false(1, 112);
    dataStart = start + 8 * samplesPerUs;
    for k = 0:111
        firstHalf = mean_window(csum, n, dataStart + k * samplesPerUs, ...
                                dataStart + (k + 0.5) * samplesPerUs);
        secondHalf = mean_window(csum, n, dataStart + (k + 0.5) * samplesPerUs, ...
                                 dataStart + (k + 1.0) * samplesPerUs);
        bits(k+1) = firstHalf > secondHalf;
    end
end

function y = mean_window(csum, n, a, b)
    ia = max(1, round(a));
    ib = min(n, round(b));
    if ib <= ia
        y = 0;
    else
        y = (csum(ib + 1) - csum(ia)) / (ib - ia + 1);
    end
end

function [ok, syndrome] = adsb_crc_check(bits)
    % Mode-S generator polynomial: x^24 + x^23 + x^22 + x^21 + x^20
    % + x^19 + x^18 + x^17 + x^16 + x^15 + x^14 + x^13 + x^12
    % + x^10 + x^3 + 1, commonly written as 0xFFF409.
    poly = dec2bin(hex2dec('1FFF409'), 25) == '1';
    work = logical(bits);
    for k = 1:(numel(work) - 24)
        if work(k)
            work(k:k+24) = xor(work(k:k+24), poly);
        end
    end
    remainder = work(end-23:end);
    ok = ~any(remainder);
    syndrome = bits_to_hex(remainder);
end

function hx = bits_to_hex(bits)
    hx = '';
    for k = 1:4:numel(bits)
        hx = [hx dec2hex(bits_to_int(bits(k:k+3)), 1)]; %#ok<AGROW>
    end
end

function v = bits_to_int(bits)
    v = 0;
    for k = 1:numel(bits)
        v = v * 2 + double(bits(k));
    end
end

function callsign = decode_callsign(bits)
    charset = '#ABCDEFGHIJKLMNOPQRSTUVWXYZ#####_###############0123456789######';
    callsign = '';
    for k = 41:6:88
        v = bits_to_int(bits(k:k+5));
        if v + 1 <= numel(charset)
            ch = charset(v + 1);
            if ch ~= '#' && ch ~= '_'
                callsign = [callsign ch]; %#ok<AGROW>
            end
        end
    end
    callsign = strtrim(callsign);
end
