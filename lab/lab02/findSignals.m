function [times, freqs, offsets] = findSignals(data, fs, fc)
    % 功能：自动检测信号出现的时刻和频率
    % freqs   - 实际载波频率 (Hz)
    % offsets - 相对中心频率 fc 的偏移频率 (Hz)
    
    freq_res = 1000;         % 1kHz 分辨率
    n_samp = fs / freq_res;  % 窗口大小 (2400点)
    
    times = [];
    freqs = [];
    offsets = [];
    
    % 按实验要求：每隔 2400 个样本检查一次
    for n0 = 0 : n_samp : (length(data) - n_samp)
        segment = data(n0 + 1 : n0 + n_samp);
        % FFT 并平移到中心
        d_fft = abs(fftshift(fft(segment)));
        
        % 设定阈值（根据 Data Set 调整，1e4 是个不错的起点）
        [pks, locs] = findpeaks(d_fft, 'MinPeakProminence', 1e4);
        
        if ~isempty(locs)
            curr_time = n0 / fs;
            % 计算相对于中心频率的偏移
            offset = (locs - n_samp/2) * freq_res;
            actual_f = offset + fc;
            
            times = [times; repmat(curr_time, length(actual_f), 1)];
            freqs = [freqs; actual_f];
            offsets = [offsets; offset];
        end
    end
    
    % 绘图展示识别结果（用于实验报告）
    figure;
    plot(times, freqs/1e6, 'x');
    grid on; xlabel('时间 (s)'); ylabel('频率 (MHz)');
    title('自动信号检测图 (Air Band Scanner)');
end
