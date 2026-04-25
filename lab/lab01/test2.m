%% EE121 Lab01 信号处理完整流程
% 建议先运行 load("ab310p7.mat") 确保数据在工作区

%% 1. 参数定义
fs = 2.4e6;              % 原始采样率 2.4MHz
f_target = 310.8e6;      % 目标信号频率
f_center = 310.7e6;      % 采集时的中心频率
f_offset = f_target - f_center; % 计算偏移量 (100kHz)

%% 2. 绘制原始频谱图 (观察信号偏移)
% 这一步会弹出一个图，亮线应该不在中心
msg(ab310p7, 1, 2048, 8192, 60, fs, f_center);
title('原始信号频谱 (目标在 310.8MHz)');

%% 3. 数字下变频 (移频)
% 生成时间向量，注意使用了 ' 转置，确保它是列向量
t = (0:length(ab310p7)-1)' / fs; 

% 这里的原理是：将信号乘以复指数，把 100kHz 处的信号搬移到 0Hz
dm = ab310p7 .* exp(-1i * 2 * pi * f_offset * t);

% 验证移频：现在亮线应该在 0 刻度中心了
figure; % 新开一个窗口画图
msg(dm, 1, 2048, 8192, 60, fs, 0);
title('移频后频谱 (目标已搬移至 0Hz)');

%% 4. 抽取与解调 (降采样)
% 使用 decimate 函数，将 2.4MHz 降到 10kHz (240倍抽取)
% 它内部会自动过滤掉 5kHz 以外的噪声（低通滤波）
audio_base = decimate(dm, 240);

% AM 解调：取复信号的幅度 (包络检波)
audio_final = abs(audio_base);

%% 5. 绘制时域波形 (用于报告的 Magnitude Plot)
fs_audio = fs / 240; % 现在的采样率是 10kHz
t_audio = (0:length(audio_final)-1) / fs_audio;

figure;
plot(t_audio, audio_final);
xlabel('时间 (s)'); ylabel('幅度 (Magnitude)');
title('AM 解调后的音频时域波形');

%% 6. 播放音频
fprintf('正在以 10kHz 采样率播放音频...\n');
soundsc(audio_final, fs_audio);