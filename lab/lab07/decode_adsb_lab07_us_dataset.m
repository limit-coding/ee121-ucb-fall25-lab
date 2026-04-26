% EE121 Lab07 official US ADS-B dataset decoder.
% This script is for the provided .mat captures, especially adsb_3.mat.
% The official data is sampled at 3.2 MHz, then resampled to 4 MHz by
% resample(da,5,4). It follows the lab handout flow:
% envelope -> threshold -> 2 MHz binary waveform -> strfind preamble
% -> Manchester decode -> ICAO/callsign extraction -> CRC filtering.

clear; clc;

matFile = 'adsb_3.mat';      % Change to 'adsb_1.mat' if needed
fsRaw = 3.2e6;
fs4 = 4.0e6;
thresholdList = [10 20 30];
maxPacketsToPrint = 60;

fprintf('Loading %s ...\n', matFile);
S = load(matFile);

if isfield(S, 'd3')
    x = S.d3;
elseif isfield(S, 'd1')
    x = S.d1;
else
    error('No variable named d1 or d3 found in %s.', matFile);
end

if isfield(S, 'fs')
    fsRaw = double(S.fs);
end

da = abs(x(:));
clear x S;

fprintf('Raw samples: %d, duration %.2f s, fs %.1f MHz\n', ...
    numel(da), numel(da) / fsRaw, fsRaw / 1e6);
fprintf('Raw envelope percentiles: p50=%.2f, p90=%.2f, p99=%.2f, p99.9=%.2f, max=%.2f\n', ...
    prctile(da, 50), prctile(da, 90), prctile(da, 99), prctile(da, 99.9), max(da));

% Official handout: 3.2 MHz -> 4 MHz, so use 5/4.
if exist('resample', 'file') == 2
    d4 = resample(da, 5, 4);
else
    tRaw = (0:numel(da)-1) / fsRaw;
    t4 = 0:(1/fs4):tRaw(end);
    d4 = interp1(tRaw, da, t4, 'linear', 'extrap').';
end
d4(d4 < 0) = 0;

fprintf('4 MHz samples: %d, duration %.2f s\n', numel(d4), numel(d4) / fs4);
fprintf('4 MHz envelope percentiles: p50=%.2f, p90=%.2f, p99=%.2f, p99.9=%.2f, max=%.2f\n\n', ...
    prctile(d4, 50), prctile(d4, 90), prctile(d4, 99), prctile(d4, 99.9), max(d4));

allPackets = struct('threshold', {}, 'phase', {}, 'index2MHz', {}, 'bits', {}, ...
                    'hex', {}, 'df', {}, 'icao', {}, 'tc', {}, 'callsign', {}, ...
                    'validManchester', {}, 'crcOK', {});

for threshold = thresholdList
    fprintf('=== Threshold %.1f ===\n', threshold);
    db4 = d4 > threshold;

    packetsThisThreshold = [];
    for phase = 1:2
        db = db4(phase:2:end);       % 2 MHz binary waveform
        packets = find_packets_in_binary(db, threshold, phase);
        packetsThisThreshold = [packetsThisThreshold packets]; %#ok<AGROW>
    end

    fprintf('Packets found by preamble: %d\n', numel(packetsThisThreshold));
    print_packet_summary(packetsThisThreshold, maxPacketsToPrint);
    allPackets = [allPackets packetsThisThreshold]; %#ok<AGROW>
    fprintf('\n');
end

summarize_results(allPackets);
plot_strongest_region(d4, fs4);
if ~isempty(allPackets)
    plot_candidate_packet(d4, fs4, allPackets(1));
end

function packets = find_packets_in_binary(db, threshold, phase)
    preamble = [1 0 1 0 0 0 0 1 0 1 0 0 0 0 0 0];
    packetStart = strfind(db', preamble);
    packets = struct('threshold', {}, 'phase', {}, 'index2MHz', {}, 'bits', {}, ...
                     'hex', {}, 'df', {}, 'icao', {}, 'tc', {}, 'callsign', {}, ...
                     'validManchester', {}, 'crcOK', {});

    minLen = 16 + 112 * 2;
    for k = 1:numel(packetStart)
        idx = packetStart(k);
        if idx + minLen - 1 > numel(db)
            continue;
        end

        packet2 = db(idx + 16:idx + 16 + 112 * 2 - 1);
        [bits, validManchester] = manchester_decode(packet2);
        if isempty(bits)
            continue;
        end

        df = bits_to_int(bits(1:5));
        hx = bits_to_hex(bits);
        icao = hx(3:8);
        tc = bits_to_int(bits(33:37));
        crcOK = adsb_crc_ok(bits);

        callsign = '';
        if df == 17 && tc >= 1 && tc <= 4
            callsign = decode_callsign(bits);
        end

        p.threshold = threshold;
        p.phase = phase;
        p.index2MHz = idx;
        p.bits = bits;
        p.hex = hx;
        p.df = df;
        p.icao = icao;
        p.tc = tc;
        p.callsign = callsign;
        p.validManchester = validManchester;
        p.crcOK = crcOK;
        packets(end+1) = p; %#ok<AGROW>
    end
end

function [bits, validFraction] = manchester_decode(packet2)
    pairs = reshape(packet2, 2, []).';
    bits = false(1, size(pairs, 1));
    valid = false(1, size(pairs, 1));

    for k = 1:size(pairs, 1)
        if isequal(pairs(k,:), [1 0])
            bits(k) = 1;     % falling transition
            valid(k) = true;
        elseif isequal(pairs(k,:), [0 1])
            bits(k) = 0;     % rising transition
            valid(k) = true;
        end
    end

    validFraction = mean(valid);
    if validFraction < 0.70
        bits = [];
    end
end

function summarize_results(allPackets)
    if isempty(allPackets)
        fprintf('No decodable packets found.\n');
        return;
    end

    crcPackets = allPackets(arrayfun(@(p) p.crcOK, allPackets));
    icaosAll = unique({allPackets.icao});
    icaosAll = icaosAll(~cellfun(@isempty, icaosAll));
    icaosCRC = unique({crcPackets.icao});
    icaosCRC = icaosCRC(~cellfun(@isempty, icaosCRC));

    identAll = allPackets(arrayfun(@(p) p.df == 17 && p.tc >= 1 && p.tc <= 4 && ...
                                   ~isempty(p.callsign), allPackets));
    identCRC = crcPackets(arrayfun(@(p) p.df == 17 && p.tc >= 1 && p.tc <= 4 && ...
                                   ~isempty(p.callsign), crcPackets));

    callsigns = unique({identCRC.callsign});
    callsigns = callsigns(~cellfun(@isempty, callsigns));

    fprintf('=== Overall ===\n');
    fprintf('All preamble candidates decoded: %d\n', numel(allPackets));
    fprintf('CRC-valid packets: %d\n', numel(crcPackets));
    fprintf('Unique ICAO candidates before CRC: %d\n', numel(icaosAll));
    fprintf('Unique ICAO after CRC: %d\n', numel(icaosCRC));
    if ~isempty(icaosCRC)
        fprintf('%s\n', strjoin(icaosCRC, ' '));
    end
    fprintf('IDENT-like packets before CRC: %d\n', numel(identAll));
    fprintf('CRC-valid IDENT packets decoded: %d\n', numel(identCRC));

    fprintf('\nCRC-valid IDENT packets:\n');
    for k = 1:numel(identCRC)
        fprintf('ICAO %s  Callsign %-8s  Hex %s\n', ...
            identCRC(k).icao, identCRC(k).callsign, identCRC(k).hex);
    end

    fprintf('\nUnique callsigns:\n');
    for k = 1:numel(callsigns)
        fprintf('%s\n', callsigns{k});
    end
end

function print_packet_summary(packets, maxPacketsToPrint)
    if isempty(packets)
        return;
    end
    fprintf('Phase  Index2MHz   DF  ICAO    TC  Manch  CRC  Callsign  Hex\n');
    fprintf('--------------------------------------------------------------------------\n');
    for k = 1:min(numel(packets), maxPacketsToPrint)
        p = packets(k);
        fprintf('%5d  %-10d %2d  %-6s  %2d  %.2f   %3d  %-8s  %s\n', ...
            p.phase, p.index2MHz, p.df, p.icao, p.tc, p.validManchester, ...
            p.crcOK, p.callsign, p.hex);
    end
end

function plot_strongest_region(d4, fs4)
    [~, pos] = max(d4);
    a = max(1, pos - round(25e-6 * fs4));
    b = min(numel(d4), pos + round(250e-6 * fs4));
    figure(10);
    plot((a:b) / fs4 * 1e6, d4(a:b));
    grid on;
    xlabel('Time (us)');
    ylabel('Envelope');
    title(sprintf('US dataset strongest region at 4 MHz, index %d', pos));
end

function plot_candidate_packet(d4, fs4, packet)
    start4 = packet.phase + 2 * (packet.index2MHz - 1);
    a = max(1, start4 - round(5e-6 * fs4));
    b = min(numel(d4), start4 + round(130e-6 * fs4));
    figure(11);
    plot((a:b) / fs4 * 1e6, d4(a:b));
    grid on;
    xlabel('Time (us)');
    ylabel('Envelope');
    title(sprintf('US dataset preamble candidate, threshold %.1f, phase %d, index %d', ...
        packet.threshold, packet.phase, packet.index2MHz));
end

function ok = adsb_crc_ok(bits)
    poly = dec2bin(hex2dec('1FFF409'), 25) == '1';
    work = logical(bits);
    for k = 1:(numel(work) - 24)
        if work(k)
            work(k:k+24) = xor(work(k:k+24), poly);
        end
    end
    ok = ~any(work(end-23:end));
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
