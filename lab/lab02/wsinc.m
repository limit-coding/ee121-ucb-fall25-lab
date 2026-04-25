function h = wsinc(tbw, samples)
    % h = wsinc(tbw, samples)
    % Returns a windowed sinc using a Hamming window.

    if mod(samples, 2)  % odd
        t = [-(samples - 1) / 2 : (samples - 1) / 2]' / samples * tbw;
    else  % even
        t = [-(samples) / 2 : (samples) / 2 - 1]' / samples * tbw;
    end

    h = sinc(t) .* hamming(samples);
end
