% 2. 指向你刚建好的、纯净的专属环境路径
% 注意：路径中的 Python 版本是刚才 pip 日志里的 3.10
my_path = '/opt/homebrew/Caskroom/miniforge/base/envs/matlab_ai/bin/python3';
pe = pyenv;
if pe.Status == "Loaded"
    if pe.ExecutionMode ~= "OutOfProcess"
        fprintf(['❌ 当前 MATLAB 正在使用 InProcess Python，这会导致 macOS 下 ssl/whisper 动态库冲突。\n', ...
                 '请重启 MATLAB，再运行本脚本，脚本会自动切换到 OutOfProcess 模式。\n', ...
                 '当前 Python:\n%s\n'], pe.Version);
        return;
    elseif string(pe.Version) ~= my_path
        fprintf(['❌ 当前 MATLAB 已加载其他 Python:\n%s\n', ...
                 '目标路径是:\n%s\n', ...
                 '请先重启 MATLAB，再运行本脚本。\n'], pe.Version, my_path);
        return;
    else
        fprintf('ℹ️ 复用当前已加载的 OutOfProcess Python 环境。\n');
    end
end

if pe.Status ~= "Loaded"
    pyenv('Version', my_path, 'ExecutionMode', 'OutOfProcess');
end

% 3. 终极验证：尝试加载 Whisper 库
try
    py.importlib.import_module('whisper');
    fprintf('Whisper package import succeeded.\n');
    fprintf('Next step: run test.m to verify the model can be downloaded and loaded.\n');
catch ME
    fprintf('❌ 链接失败: %s\n', ME.message);
end
