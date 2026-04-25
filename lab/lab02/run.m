%% EE121 Lab 2: 自动化 AI 扫描与转录系统 (M2 Mac 优化版)
clear; clc; close all;

% --- 第一部分：外部 Python 转录器配置 ---
fprintf('🚀 正在初始化外部 Python 转录环境...\n');
python_cmd = '/opt/homebrew/Caskroom/miniforge/base/envs/matlab_ai/bin/python3';
script_path = fullfile(pwd, 'transcribe_whisper.py');
ffmpeg_path = '/opt/homebrew/bin/ffmpeg';
output_dir = fullfile(pwd, 'output');
hasAI = exist(python_cmd, 'file') == 2 && exist(script_path, 'file') == 2;

if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end

if exist(ffmpeg_path, 'file') == 2
    current_path = string(getenv('PATH'));
    if strlength(current_path) == 0
        setenv('PATH', ffmpeg_path);
    elseif ~contains(current_path, "/opt/homebrew/bin")
        setenv('PATH', char("/opt/homebrew/bin:" + current_path));
    end
    setenv('FFMPEG_BINARY', ffmpeg_path);
else
    fprintf('⚠️ 未找到 ffmpeg: %s\n', ffmpeg_path);
end

if ~hasAI
    fprintf('❌ 外部转录器不可用。\n');
    fprintf('Python: %s\n', python_cmd);
    fprintf('Script: %s\n', script_path);
else
    fprintf('✅ 外部 Python 转录器已就绪。\n');
end

% --- 数据设置 ---
data_files = {'ab134.8_d1.mat', 'ab134.8_d2.mat', 'ab134.8_d3.mat', 'ab134.8_d4.mat'};
fs = 2.4e6;
fc = 134.8e6;
decim = 240;
fa = fs/decim; % 10000 Hz

% --- 主循环处理 ---
for idx = 1:length(data_files)
    if ~exist(data_files{idx}, 'file')
        fprintf('⚠️ 文件不存在，跳过: %s\n', data_files{idx});
        continue;
    end
    fprintf('\n--- 正在处理数据集: %s ---\n', data_files{idx});
    
    % 1. 加载数据
    vars = load(data_files{idx});
    fnames = fieldnames(vars);
    raw_data = vars.(fnames{1});
    raw_data = raw_data(:);
    
    % 2. 信号检测 (调用你的 findSignals 函数)
    [times, freqs] = findSignals(raw_data, fs, fc);
    unique_freqs = unique(round(freqs/5000)*5000);
    
    % 3. 处理检测到的频率
    for f_idx = 1:length(unique_freqs)
        f_target = unique_freqs(f_idx);
        f_offset = f_target - fc;
        
        % DSP 处理：移频 + 解调 (幅度解调 AM)
        t = (0:length(raw_data)-1)' / fs;
        shifted = raw_data .* exp(-1j * 2 * pi * f_offset * t);
        
        % 使用 FIRDecimator 或简单的 resample
        audio_final = abs(resample(double(shifted), 1, decim));
        
        % 归一化音频 (防止 AI 爆音)
        audio_final = audio_final - mean(audio_final);
        audio_final = audio_final / max(abs(audio_final) + eps);
        
        % 4. 保存音频文件 (Whisper 处理文件最稳)
        fname_base = sprintf('DataSet%d_Freq%.2fMHz', idx, f_target/1e6);
        wav_file = fullfile(output_dir, [fname_base, '.wav']);
        audiowrite(wav_file, audio_final, fa);
        
        % 5. AI 语音转文本 (核心修改点)
        transcript = "AI logic skipped";
        if hasAI
            try
                transcript_file = fullfile(output_dir, [fname_base, '_transcript.txt']);
                cmd = sprintf('"%s" "%s" "%s" --output "%s" --model base', ...
                              python_cmd, script_path, wav_file, transcript_file);
                [status, cmdout] = system(cmd);
                if status == 0
                    transcript = strtrim(string(fileread(transcript_file)));
                    if strlength(transcript) == 0
                        transcript = "Noise detected (no speech)";
                    end
                else
                    transcript = "AI processing error";
                    fprintf('  [!] Whisper 转录失败 (%s): %s\n', wav_file, strtrim(cmdout));
                end
            catch ME
                transcript = "AI processing error";
                fprintf('  [!] Whisper 转录失败 (%s): %s\n', wav_file, ME.message);
            end
        else
            transcript = "Whisper model unavailable";
        end
        
        % 6. 保存文本和绘图
        fid = fopen(fullfile(output_dir, [fname_base, '.txt']), 'w');
        fprintf(fid, 'Time: %.2f s\nFrequency: %.3f MHz\nTranscript: %s\n', ...
                times(f_idx), f_target/1e6, transcript);
        fclose(fid);
        
        % 绘图部分保持不变 (后台生成图片)
        f = figure('Visible', 'off');
        subplot(2,1,1); plot(audio_final); title(['Frequency: ', num2str(f_target/1e6), ' MHz']);
        subplot(2,1,2); spectrogram(audio_final, 256, 250, 256, fa, 'yaxis');
        saveas(f, fullfile(output_dir, [fname_base, '.png']));
        close(f);
        
        fprintf('  [√] %.3f MHz | 转录内容: %s\n', f_target/1e6, transcript);
    end
end
fprintf('\n✨ 吕同学，所有任务已"超频"完成！请查看文件夹下的成果。\n');
