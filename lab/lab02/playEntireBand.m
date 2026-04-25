function audio_out = playEntireBand(data, fs)
    % 功能：对整个宽带信号进行AM包络解调、降采样，并绘制整带音频
    % fs: 2.4e6, decim: 240 -> fa: 10000 Hz
    
    decim = 240;
    fa = fs / decim;
    
    % 创建高效多相降采样器
    firdecim = dsp.FIRDecimator(decim);
    
    % AM解调逻辑：先取模（提取包络），再通过降采样滤波器
    % 这样你会听到该带宽内所有活跃频率的叠加
    audio_out = firdecim(abs(data));

    t = (0:length(audio_out)-1) / fa;
    figure;
    plot(t, audio_out);
    xlabel('Time (s)');
    ylabel('Magnitude');
    title('Whole-Band Demodulated Audio');
    grid on;
    
    % 播放声音
    fprintf('正在播放全波段音频 (采样率: %d Hz)...\n', fa);
    soundsc(audio_out, fa);
end
