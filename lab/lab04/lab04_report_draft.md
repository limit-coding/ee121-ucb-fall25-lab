# EE121 Lab 4 Report: Narrowband FM Receiver

姓名：  
学号：  
日期：  

## 1. Make a Narrowband FM Receiver

### 1.1 Experimental Goal

The goal of this lab is to build a narrowband FM receiver starting from the AM receiver structure used in Lab 3. The front end is similar: first find the desired signal in the RF capture, mix it down to complex baseband, and decimate it to a lower sample rate. The main difference is the demodulator. For AM, the message is contained in the signal magnitude, while for FM, the message is contained in the phase variation of the complex baseband signal.

In this experiment I used the provided capture:

```matlab
dataFile = 'vhf_tn1.mat';
```

The capture is centered at:

```text
fc = 145.000 MHz
fs = 2.4 MHz
```

The target signal is the strongest narrowband FM signal in the capture, corresponding to the N6NFI repeater near 145.230 MHz.

### 1.2 Finding the Signal Offset

I first skipped the first 2000 samples to avoid the SDR startup transient. Then I computed the spectrum of the received complex IQ samples and found the strongest non-DC component.

The measured frequency offset was:

```text
Offset frequency = +230.2 kHz
```

For the N6NFI repeater, the expected value is approximately:

```text
145.230 MHz - 145.000 MHz = +230 kHz
```

The corresponding RF frequency is:

```text
Estimated RF frequency = fc + offset
                       = 145.2302 MHz
```

![Capture spectrum overview](output/1.png)

After finding the offset, I mixed the selected signal to baseband using:

```matlab
xBaseband = x .* exp(-1j * 2*pi*offsetHz*t);
```

Then I decimated the signal by 120:

```matlab
xDecim = decimate_complex(xBaseband, 120);
fsDecim = fs / 120;
```

This gives:

```text
fsDecim = 2.4 MHz / 120 = 20 kHz
```

### 1.3 Magnitude of the Demodulated FM Signal

The magnitude of the demodulated and decimated FM signal is shown below.

![FM signal magnitude after channel selection](output/2.png)

The magnitude is approximately constant, except for noise and small channel variations. This is expected for FM because the information is carried by the instantaneous phase or frequency of the signal, not by its amplitude. Therefore, amplitude noise has relatively little effect on the recovered FM message, especially after normalizing the signal magnitude before the FM discriminator.

In the MATLAB code, this normalization was performed as:

```matlab
xNorm = xDecim ./ (abs(xDecim) + eps);
```

This removes most AM components before FM detection.

The spectrogram of the complex baseband signal before FM audio detection is shown below. The signal has already been shifted close to DC, and the time-varying structure shows that there is information in the phase/frequency of the signal.

![Complex baseband NBFM signal](output/3.png)

### 1.4 Decoded Audio Spectrogram

The FM-demodulated audio was obtained using:

```matlab
audio20k = imag(conj(xNorm(1:end-1)) .* xNorm(2:end));
```

The 20 kHz audio was then decimated by 2 to obtain a final 10 kHz audio signal:

```matlab
audio10k = decimate(audio20k, 2);
fsAudio = 10e3;
```

First, the decoded audio at 20 kHz is shown below.

![Decoded audio at 20 kHz](output/5.png)

After the final decimation by 2, the decoded audio at 10 kHz is shown below.

![Decoded audio at 10 kHz](output/6.png)

The spectrogram shows a clear narrowband audio signal. Compared with AM demodulation, the recovered FM audio is clearer because FM is much less sensitive to amplitude noise once the signal is above the threshold needed for reliable phase detection.

The final 10 kHz audio waveform is also shown below.

![Decoded audio waveform](output/7.png)

## 2. FM Demodulation

### 2.1 Problem with `diff(angle(baseband_signal))`

One intuitive way to demodulate FM is to differentiate the phase:

```matlab
audioBad = diff(angle(xDecim));
```

However, this does not work well because `angle()` returns phase values wrapped into the interval:

```text
[-pi, pi]
```

When the true phase crosses `pi`, MATLAB wraps it back to `-pi`, and vice versa. These artificial discontinuities appear as large jumps in the differentiated phase. As a result, `diff(angle(x))` produces large false spikes that are not part of the original message signal.

This explains why the audio from this method sounds distorted and why the waveform contains sharp jumps.

![FM discriminator comparison](output/4.png)

### 2.2 How the Proposed Method Works

The better method is:

```matlab
audioAngle = angle(conj(xDecim(1:end-1)) .* xDecim(2:end));
```

Let the complex baseband FM signal be:

```text
x[n] = A exp(j phi[n])
```

Then:

```text
conj(x[n-1]) x[n]
  = A^2 exp(j(phi[n] - phi[n-1]))
```

The angle of this product is:

```text
phi[n] - phi[n-1]
```

This is the phase difference between adjacent samples. Since instantaneous frequency is proportional to the rate of change of phase, this phase difference gives the original FM message signal.

This method avoids the main problem of `diff(angle(x))` because it computes the phase difference directly between adjacent complex samples.

### 2.3 Why `angle()` Can Be Replaced by `imag()`

The lab also proposes the simpler method:

```matlab
xNorm = xDecim ./ abs(xDecim);
audio20k = imag(conj(xNorm(1:end-1)) .* xNorm(2:end));
```

After normalization:

```text
xNorm[n] ≈ exp(j phi[n])
```

Therefore:

```text
conj(xNorm[n-1]) xNorm[n]
  = exp(j(phi[n] - phi[n-1]))
  = exp(j Delta phi)
```

The imaginary part is:

```text
imag(exp(j Delta phi)) = sin(Delta phi)
```

For narrowband FM and sufficiently high sample rate, the phase change between adjacent samples is small, so:

```text
sin(Delta phi) ≈ Delta phi
```

Thus:

```text
imag(conj(x[n-1]) x[n]) ≈ phi[n] - phi[n-1]
```

This is why the imaginary-part method works as a simpler FM discriminator.

## 3. Finding the CTCSS Frequency

CTCSS stands for Continuous Tone-Coded Squelch System. It is a low-frequency tone transmitted together with the voice signal. A repeater can use this tone as an access code: it only retransmits signals that contain the correct tone. This prevents the repeater from retransmitting random noise or unrelated signals.

After decoding the FM audio and decimating it to 10 kHz, I computed the low-frequency spectrum of the audio and searched for the strongest tone between 50 Hz and 300 Hz.

The measured strongest low-frequency tone was:

```text
CTCSS frequency = 99.8 Hz
```

For N6NFI, the expected CTCSS/PL tone is approximately:

```text
100.0 Hz
```

The measured result agrees with the expected value.

![Low-frequency audio spectrum for CTCSS](output/8.png)

## 4. Using an AM Receiver on an FM Signal

When listening to a NOAA or other narrowband FM station using NBFM demodulation, the receiver directly extracts the message from the phase or frequency variation of the signal. This produces clear audio when the signal is strong enough.

If the receiver is switched to AM demodulation while tuned exactly to the center of the FM signal, the audio is usually weak or unintelligible because an ideal FM signal has nearly constant amplitude. AM detection only measures the envelope:

```text
AM detector output ≈ |x(t)|
```

Since FM does not intentionally vary the amplitude, there is little message in the envelope.

However, when the receiver is tuned slightly away from the FM carrier, the station can begin to become audible even with AM demodulation. This happens because the slope of the receiver filter converts some frequency variation into amplitude variation. As the FM signal moves back and forth in frequency, being off-center causes the signal amplitude after filtering to change. This creates an accidental AM component that the AM detector can recover.

This effect is called slope detection. It is not as good as proper FM demodulation, but it explains why an FM station can sometimes be heard using AM demodulation when the receiver is tuned off-center.

## 5. Conclusion

In this lab, I built a narrowband FM receiver using the provided SDR IQ capture. The receiver found the strongest signal, mixed it to baseband, decimated it to 20 kHz, and recovered the audio using a phase-difference FM discriminator. The final audio was decimated to 10 kHz for cleaner listening.

The experiment showed that FM information is contained in the phase of the complex signal rather than its magnitude. This is why the magnitude of the baseband FM signal remains almost constant and why an AM envelope detector does not work well on a centered FM signal.

The measured CTCSS tone for the N6NFI repeater was approximately:

```text
99.8 Hz
```

This is consistent with the expected PL tone of about 100 Hz.

## 6. Additional Runs and Figure Records

In addition to the main `vhf_tn1.mat` result used above, I also ran the same narrowband FM receiver on `vhf_tn2.mat`, `vhf_tn3.mat`, and the weather-radio capture `vhf_wr.mat`. The three amateur-radio captures all show the same N6NFI repeater signal near `+230 kHz` from the `145.000 MHz` center frequency, and all three give a CTCSS tone near `100 Hz`.

The weather-radio capture is different. It is centered near `162.000 MHz`, and the strongest selected signal appears at about `+125.3 kHz`, corresponding to an RF frequency of about `162.1253 MHz`. Unlike the N6NFI repeater, the weather-radio signal is not expected to contain the same 100 Hz CTCSS/PL access tone.

| Capture | Offset Frequency | Estimated RF Frequency | Estimated CTCSS Tone |
|---|---:|---:|---:|
| `vhf_tn1.mat` | `+230.2 kHz` | `145.2302 MHz` | `99.8 Hz` |
| `vhf_tn2.mat` | `+230.2 kHz` | `145.2302 MHz` | `99.8 Hz` |
| `vhf_tn3.mat` | `+230.1 kHz` | `145.2301 MHz` | `99.8 Hz` |
| `vhf_wr.mat` | `+125.3 kHz` | `162.1253 MHz` | Not a N6NFI CTCSS measurement |

The repeated amateur-radio results confirm that the receiver chain is working consistently across multiple captures. The weather-radio result further shows that the same FM discriminator can be used on a different narrowband FM voice signal.

### 6.1 Figure Number Guide

Each run saved eight figures with the same meaning:

| Figure No. | Plot Type | What It Shows | How It Was Used |
|---|---|---|---|
| `1` | Capture spectrum overview | Original IQ spectrum and selected strongest signal offset. | Used to answer the offset-frequency question. |
| `2` | FM signal magnitude | Magnitude after mixing to baseband and decimating to 20 kHz. | Used to show FM has nearly constant envelope. |
| `3` | Complex baseband spectrogram | Spectrogram before FM audio detection. | Used to confirm that the selected baseband channel contains information. |
| `4` | FM discriminator comparison | Comparison of `diff(angle(x))`, `angle(conj(x[n-1])x[n])`, and `imag(conj(x[n-1])x[n])`. | Used to explain the FM demodulator. |
| `5` | Decoded audio spectrogram, 20 kHz | Audio spectrogram immediately after FM detection. | Used to inspect the recovered audio before final decimation. |
| `6` | Decoded audio spectrogram, 10 kHz | Audio spectrogram after final decimation by 2. | Best spectrogram for the final audio result. |
| `7` | Decoded audio waveform | Time-domain waveform of the final 10 kHz audio. | Used to inspect speech activity over time. |
| `8` | Low-frequency audio spectrum | Spectrum in the low-frequency tone region. | Used to estimate CTCSS for N6NFI; for weather radio, used only as a low-frequency audio check. |

### 6.2 Complete Saved Figures for `vhf_tn1.mat`

![tn1 capture spectrum overview](output/1.png)

![tn1 FM signal magnitude](output/2.png)

![tn1 complex baseband spectrogram](output/3.png)

![tn1 FM discriminator comparison](output/4.png)

![tn1 decoded audio spectrogram at 20 kHz](output/5.png)

![tn1 decoded audio spectrogram at 10 kHz](output/6.png)

![tn1 decoded audio waveform](output/7.png)

![tn1 CTCSS low-frequency spectrum](output/8.png)

### 6.3 Complete Saved Figures for `vhf_tn2.mat`

![tn2 capture spectrum overview](output/tn2-1.png)

![tn2 FM signal magnitude](output/tn2-2.png)

![tn2 complex baseband spectrogram](output/tn2-3.png)

![tn2 FM discriminator comparison](output/tn2-4.png)

![tn2 decoded audio spectrogram at 20 kHz](output/tn2-5.png)

![tn2 decoded audio spectrogram at 10 kHz](output/tn2-6.png)

![tn2 decoded audio waveform](output/tn2-7.png)

![tn2 CTCSS low-frequency spectrum](output/tn2-8.png)

### 6.4 Complete Saved Figures for `vhf_tn3.mat`

![tn3 capture spectrum overview](output/tn3-1.png)

![tn3 FM signal magnitude](output/tn3-2.png)

![tn3 complex baseband spectrogram](output/tn3-3.png)

![tn3 FM discriminator comparison](output/tn3-4.png)

![tn3 decoded audio spectrogram at 20 kHz](output/tn3-5.png)

![tn3 decoded audio spectrogram at 10 kHz](output/tn3-6.png)

![tn3 decoded audio waveform](output/tn3-7.png)

![tn3 CTCSS low-frequency spectrum](output/tn3-8.png)

### 6.5 Complete Saved Figures for `vhf_wr.mat`

For the weather-radio capture, the same receiver chain was applied. The strongest signal was found at:

```text
Offset frequency = +125.3 kHz
Estimated RF frequency = 162.1253 MHz
```

The final decoded audio spectrogram is different from the amateur-radio voice signal because weather-radio audio is usually generated or heavily processed, with compressed dynamic range for intelligibility. The low-frequency spectrum plot should not be interpreted as the N6NFI CTCSS result.

![wr capture spectrum overview](output/wr-1.png)

![wr FM signal magnitude](output/wr-2.png)

![wr complex baseband spectrogram](output/wr-3.png)

![wr FM discriminator comparison](output/wr-4.png)

![wr decoded audio spectrogram at 20 kHz](output/wr-5.png)

![wr decoded audio spectrogram at 10 kHz](output/wr-6.png)

![wr decoded audio waveform](output/wr-7.png)

![wr low-frequency audio spectrum](output/wr-8.png)

## Appendix: Main MATLAB Code Used

The receiver was implemented in:

```text
lab04_nbfm_receiver.m
```

The main FM demodulation section is:

```matlab
% Normalize magnitude to remove AM components.
xNorm = xDecim ./ (abs(xDecim) + eps);

% Narrowband FM discriminator.
audio20k = imag(conj(xNorm(1:end-1)) .* xNorm(2:end));

% Remove DC component.
audio20k = audio20k - mean(audio20k);

% Decimate to 10 kHz audio.
audio10k = decimate(audio20k, 2);
fsAudio = fsDecim / 2;
```
