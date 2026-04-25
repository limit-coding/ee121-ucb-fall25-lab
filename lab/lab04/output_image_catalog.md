# Lab 4 Output Image Catalog

This file records all saved figures in `output/` so the plots can be reviewed later without guessing what each image means.

## Figure Number Meaning

The three data runs use the same figure numbering pattern.

| Figure No. | Plot Type | What It Shows | How To Use It |
|---|---|---|---|
| `1` | Capture spectrum overview | Spectrum of the original IQ capture. The red vertical line marks the selected strongest signal offset. | Use this to answer the signal offset question. |
| `2` | FM signal magnitude | Magnitude of the selected signal after mixing to baseband and decimating to 20 kHz. | Use this to show that FM has nearly constant envelope. |
| `3` | Complex baseband spectrogram | Spectrogram of the selected complex baseband signal before FM audio detection. | Use this to confirm the channel has information after frequency shifting. |
| `4` | FM discriminator comparison | Compares `diff(angle(x))`, `angle(conj(x[n-1])x[n])`, and `imag(conj(x[n-1])x[n])`. | Use this to explain why direct phase differencing after `angle()` is bad. |
| `5` | Decoded audio spectrogram, 20 kHz | Audio spectrogram immediately after FM detection. | Use this to inspect recovered audio before final decimation. |
| `6` | Decoded audio spectrogram, 10 kHz | Audio spectrogram after final decimation by 2. | Best spectrogram for the lab report. |
| `7` | Decoded audio waveform | Time-domain waveform of the final 10 kHz audio. | Useful for checking speech activity over time. |
| `8` | Low-frequency audio spectrum | Spectrum around the low-frequency audio region. | Use this to estimate the CTCSS/PL tone for N6NFI; for weather radio, use only as a low-frequency audio check. |

## Run 1: `vhf_tn1.mat`

This is the set currently used in `lab04_report_draft.md`.

Measured values from the saved figures:

```text
Offset frequency = +230.2 kHz
Estimated RF frequency = 145.2302 MHz
CTCSS frequency = 99.8 Hz
```

| File | Description |
|---|---|
| ![Run 1 figure 1](output/1.png) | Original capture spectrum and selected offset. |
| ![Run 1 figure 2](output/2.png) | Magnitude after channel selection and decimation. |
| ![Run 1 figure 3](output/3.png) | Complex baseband spectrogram. |
| ![Run 1 figure 4](output/4.png) | FM discriminator comparison. |
| ![Run 1 figure 5](output/5.png) | Decoded audio spectrogram at 20 kHz. |
| ![Run 1 figure 6](output/6.png) | Decoded audio spectrogram at 10 kHz. |
| ![Run 1 figure 7](output/7.png) | Decoded 10 kHz audio waveform. |
| ![Run 1 figure 8](output/8.png) | CTCSS search spectrum. |

## Run 2: `vhf_tn2.mat`

Measured values from the saved figures:

```text
Offset frequency = +230.2 kHz
Estimated RF frequency = 145.2302 MHz
CTCSS frequency = 99.8 Hz
```

| File | Description |
|---|---|
| ![Run 2 figure 1](output/tn2-1.png) | Original capture spectrum and selected offset. |
| ![Run 2 figure 2](output/tn2-2.png) | Magnitude after channel selection and decimation. |
| ![Run 2 figure 3](output/tn2-3.png) | Complex baseband spectrogram. |
| ![Run 2 figure 4](output/tn2-4.png) | FM discriminator comparison. |
| ![Run 2 figure 5](output/tn2-5.png) | Decoded audio spectrogram at 20 kHz. |
| ![Run 2 figure 6](output/tn2-6.png) | Decoded audio spectrogram at 10 kHz. |
| ![Run 2 figure 7](output/tn2-7.png) | Decoded 10 kHz audio waveform. |
| ![Run 2 figure 8](output/tn2-8.png) | CTCSS search spectrum. |

## Run 3: `vhf_tn3.mat`

Measured values from the saved figures:

```text
Offset frequency = +230.1 kHz
Estimated RF frequency = 145.2301 MHz
CTCSS frequency = 99.8 Hz
```

| File | Description |
|---|---|
| ![Run 3 figure 1](output/tn3-1.png) | Original capture spectrum and selected offset. |
| ![Run 3 figure 2](output/tn3-2.png) | Magnitude after channel selection and decimation. |
| ![Run 3 figure 3](output/tn3-3.png) | Complex baseband spectrogram. |
| ![Run 3 figure 4](output/tn3-4.png) | FM discriminator comparison. |
| ![Run 3 figure 5](output/tn3-5.png) | Decoded audio spectrogram at 20 kHz. |
| ![Run 3 figure 6](output/tn3-6.png) | Decoded audio spectrogram at 10 kHz. |
| ![Run 3 figure 7](output/tn3-7.png) | Decoded 10 kHz audio waveform. |
| ![Run 3 figure 8](output/tn3-8.png) | CTCSS search spectrum. |

## Run 4: `vhf_wr.mat`

Measured values from the saved figures:

```text
Offset frequency = +125.3 kHz
Estimated RF frequency = 162.1253 MHz
Low-frequency peak shown by figure 8 = 298.2 Hz
```

This is a weather-radio capture, so figure 8 should not be interpreted as the N6NFI CTCSS/PL tone. The important result is that the same NBFM receiver chain still recovers a clear voice-like audio spectrogram.

| File | Description |
|---|---|
| ![Run 4 figure 1](output/wr-1.png) | Original capture spectrum and selected offset. |
| ![Run 4 figure 2](output/wr-2.png) | Magnitude after channel selection and decimation. |
| ![Run 4 figure 3](output/wr-3.png) | Complex baseband spectrogram. |
| ![Run 4 figure 4](output/wr-4.png) | FM discriminator comparison. |
| ![Run 4 figure 5](output/wr-5.png) | Decoded audio spectrogram at 20 kHz. |
| ![Run 4 figure 6](output/wr-6.png) | Decoded audio spectrogram at 10 kHz. |
| ![Run 4 figure 7](output/wr-7.png) | Decoded 10 kHz audio waveform. |
| ![Run 4 figure 8](output/wr-8.png) | Low-frequency audio spectrum. |

## Main Takeaways

All three VHF amateur-radio captures show the same repeater signal near `+230 kHz` from the `145.000 MHz` center frequency. This corresponds to an RF frequency of about `145.230 MHz`, matching the N6NFI repeater transmit frequency.

All three runs also show a strong low-frequency tone near `99.8 Hz`, which is consistent with the expected `100.0 Hz` CTCSS/PL tone.

The weather-radio capture shows a different narrowband FM voice signal near `+125.3 kHz` from the `162.000 MHz` center frequency. Its low-frequency spectrum is not a N6NFI CTCSS measurement.

The most useful images for the final lab report are:

```text
output/1.png  or output/tn2-1.png  or output/tn3-1.png
output/2.png  or output/tn2-2.png  or output/tn3-2.png
output/4.png  or output/tn2-4.png  or output/tn3-4.png
output/6.png  or output/tn2-6.png  or output/tn3-6.png
output/8.png  or output/tn2-8.png  or output/tn3-8.png
output/wr-1.png through output/wr-8.png for the weather-radio extension
```
