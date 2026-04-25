load('ab310p7.mat');
load('ab127p6.mat');
% 1. 绘制原始频谱图
msg(ab127p6, 1, 2048, 8192, 60, 2.4e6, 310.7e6); 
% 截图：这张图里你应该能看到在 310.8 MHz 处有一条随时间变化的亮波。
fs=2.4e6;
f_offset=100e3;%目标在310.8，采集在310.7，向上偏了100k
t=(0:length(ab127p6)-1)'/fs;
%执行移频
dm=ab127p6 .*exp(-1i*2*pi*f_offset*t);

%240倍抽取
audio_base=decimate(dm,240);

%绘制包络
t_audio=(0:length(audio_base)-1)/(fs/240);
figure;
plot(t_audio,abs(audio_base));
xlabel('Time(s)');
ylabel('Manitude');

%听声音
soundsc(abs(audio_base),10000);

%对比：如果decimate改成120会怎样
audio_base_20k=decimate(dm,120);

soundsc(abs(audio_base_20k),20000);