function S = scanAndExtract(data, fs, fc)
    % 功能：提取所有发现的信号音频，存入结构体 S
    
    % 调用之前的函数寻找位置
    [times, freqs] = findSignals(data, fs, fc);
    
    % 归并相近的频率点
    unique_freqs = unique(round(freqs/5000)*5000); 
    
    % 初始化结构体数组
    S = struct('time', {}, 'freq', {}, 'audio', {});
    firdecim = dsp.FIRDecimator(240);
    
    for i = 1:length(unique_freqs)
        f_target = unique_freqs(i);
        f_offset = f_target - fc;
        
        % 1. 移频：将目标信号移到 0 Hz
        t = (0:length(data)-1)' / fs;
        shifted = data .* exp(-1j * 2 * pi * f_offset * t);
        
        % 2. 关键实验提示：先降采样，再取模 (abs)
        % 这样可以滤掉目标频率以外的其他信号噪声
        audio_iq = firdecim(shifted);
        audio_final = abs(audio_iq);
        
        % 3. 存入结构体
        S(i).time = times(find(abs(freqs - f_target) < 1000, 1));
        S(i).freq = f_target;
        S(i).audio = audio_final;
        
        fprintf('已提取频率: %.3f MHz\n', f_target/1e6);
    end
end