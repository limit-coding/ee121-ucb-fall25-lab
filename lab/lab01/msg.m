function y = msg(x,n0,nf,nt,dbf, sf, fs)
%
%  msg(x,n0,nf,nt,dbf)
%
%  Computes a spectrogram
%
%      x  -- input signal
%      n0 -- first sample
%      nf -- block size for transform
%      nt -- number of time steps (blocks)
%      sf -- sampling frequency (for time/frequency axis labels)
%      fs -- center frequency (for freq. axis labels)
%
%  This extracts a segment of x starting at n0, of length nf*nt
%  The image plot is in dB, and autoscaled.  This can look very noisy
%     if there aren't any interesting signals present.
%

if nargin < 5,
    dbf = 40;
end;

if nargin < 6
    sf = 1;
end

if nargin <7
    fs = 0;
end


% rearrange the RF data into a 2D matrix of blocks verses time
xm = reshape(x(n0:(n0+nf*nt-1)),nf,nt);

% Do transforms for each block
xmf = fftshift(fft(xm),1);

% save the result, in case the user wants it
y = xmf;

xmfa = abs(xmf);
mx = max(max(xmfa));

xmfal = 20*log10(xmfa/mx);

time = linspace(n0,(nt*nf-1),nt)/sf;
freq = linspace(-sf/2,sf/2,nf)/1e6+fs/1e6;

image(time,freq,256*(xmfal+dbf)/dbf);
colormap(gray(256));
ylabel('Freq [MHz]')
xlabel('time [s]')

