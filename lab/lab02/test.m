% --- 纯净版 Whisper 验证脚本 ---
clear; clc;

fprintf('Status: Checking environment...\n');

% 1. 定义路径 (请确保这是你 which python 得到的路径)
my_path = '/opt/homebrew/Caskroom/miniforge/base/envs/matlab_ai/bin/python3';

% 2. 重置并连接引擎
pe = pyenv;
if pe.Status == "Loaded"
    if pe.ExecutionMode ~= "OutOfProcess"
        fprintf(['Step 0 Failed: MATLAB is currently using InProcess Python, which can break ssl/whisper on macOS.\n', ...
                 'Please restart MATLAB and rerun test.m so this script can use OutOfProcess mode.\n', ...
                 'Current: %s\n'], pe.Version);
        return;
    elseif string(pe.Version) ~= my_path
        fprintf(['Step 0 Failed: MATLAB is already using a different Python.\n', ...
                 'Current: %s\nTarget:  %s\n', ...
                 'Please restart MATLAB and rerun test.m.\n'], pe.Version, my_path);
        return;
    else
        fprintf('Step 0: Reusing current OutOfProcess Python environment.\n');
    end
end
try
    if pe.Status ~= "Loaded"
        pyenv('Version', my_path, 'ExecutionMode', 'OutOfProcess');
    end
    fprintf('Step 1: Python linked successfully.\n');
catch ME
    fprintf('Step 1 Failed: %s\n', ME.message);
    return;
end

% 3. 基础 Python 模块验证
try
    py.importlib.import_module('whisper');
    fprintf('Step 2: Whisper package imported successfully.\n');
catch ME
    fprintf('Step 2 Failed: %s\n', ME.message);
    if contains(string(ME.message), "_ssl.cpython") || contains(string(ME.message), "libcrypto.3.dylib")
        fprintf(['Hint: this is an OpenSSL dynamic-library conflict caused by InProcess mode.\n', ...
                 'Restart MATLAB and rerun test.m so the script can switch to OutOfProcess mode.\n']);
    end
    return;
end

% 4. 导入 Whisper 并加载最小模型
try
    fprintf('Step 3: Loading Whisper (tiny model)...\n');
    whisper = py.importlib.import_module('whisper');
    % 第一次运行会下载模型权重；若网络不可用则会在此报错
    model = whisper.load_model('tiny');
    fprintf('Step 4: Model loaded into memory!\n');
    
    % 最终测试：让 Python 打印一句话
    py.print('AI Engine is ready for BUPT Lab 2!');
    fprintf('\nCongratulations! Everything is working.\n');
catch ME
    fprintf('Final Step Failed: %s\n', ME.message);
    if contains(string(ME.message), "URLError") || ...
       contains(string(ME.message), "urlopen error") || ...
       contains(string(ME.message), "nodename nor servname")
        fprintf(['Hint: whisper package is installed, but model weights were not downloaded.\n', ...
                 'Please connect to the internet once and rerun this script so Whisper can cache the model under ~/.cache/whisper.\n']);
    end
end
