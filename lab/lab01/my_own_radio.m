%% 增强型 FM 降噪解调算法

% 1. 解调 (核心不变)
audio_raw = diff(unwrap(angle(raw_signal))); 
audio_raw = [0; audio_raw]; 

% 2. 去除直流偏移 (消除中心尖峰带来的嗡嗡声)
audio_raw = audio_raw - mean(audio_raw);

% 3. 降采样
decim_factor = round(fs / 48000); 
audio_dec = decimate(audio_raw, decim_factor);
fs_new = fs / decim_factor;

% ------------------ 关键降噪步骤 ------------------

% 4. 强力去加重 (De-emphasis) —— 消除"嘶嘶"声的特效药
% FM广播发射时人工提升了高频，接收端必须压低，否则高频噪声巨大
tau = 75e-6; % 如果觉得还是吵，可以把 75 改成 100
alpha = 1 / (1 + fs_new * tau);
audio_deemph = filter(alpha, [1, -(1-alpha)], audio_dec);

% 5. 砖墙式带通滤波 (只保留人耳有效的 30Hz - 12kHz)
% 12kHz 以上全是无线电底噪，直接切掉
[b, a] = butter(6, [30, 12000]/(fs_new/2), 'bandpass');
audio_filtered = filter(b, a, audio_deemph);

% 6. 幅度归一化 (防止爆音)
audio_final = audio_filtered / max(abs(audio_filtered));

% ------------------------------------------------

% 播放对比
fprintf('对比播放：1. 原始解调  2. 强力降噪\n');
% soundsc(audio_dec, fs_new); % 1. 原始
% pause(length(audio_dec)/fs_new + 1);
soundsc(audio_final, fs_new);   % 2. 降噪版