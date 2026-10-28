# fx-sends (Analog Rytm MKII, OS 1.74)

FX SENDS, AE 0010, ported to the MKII as an elemod: a chorus as one more send
effect, with the Analog Four chorus's controls.

On a voice track, press AMP a second time for the FX SENDS page:

| knob | range | what | kept |
|---|---|---|---|
| CHR | 0..127 | the track's send to the chorus | per sound, with the sound |
| PRE | 0..127 | pre-delay, 1 to 20 ms | global, RAM |
| SPD | 0..127 | LFO speed, 0.05 to 8 Hz | global, RAM |
| DEP | 0..127 | sweep depth, 0 to 8 ms | global, RAM |
| WID | 0..127 | stereo width: 0 mono, 127 the taps in opposite phase | global, RAM |
| FDB | 0..127 | feedback, 0 to 0.89 | global, RAM |
| HPF | 0..127 | one-pole high-pass on the chorus input, off to about 2 kHz | global, RAM |
| VOL | 0..127 | the return's level | global, RAM |

The seven global settings are shared by every track's page and go back to
their defaults (PRE 40, SPD 24, DEP 64, WID 96, FDB 0, HPF 0, VOL 100) at
power-up, as on the MK1.

The chorus is the MK1's code: two linearly interpolated taps on one 2048-sample
line, each swept by a triangle LFO, the input high-passed, the taps' average
fed back. It runs in the audio interrupt after the stock delay and reverb, on
the voices the codec captured, and its return is added to the PRE return words
(the path into the analog distortion and compressor), scaled like a stock
return by (2 x VOL x FX track level)². Nothing runs while no track sends and
the tail has died (about 3 s).

## What changed from the MK1

- **Hooks.** keep2 on both calls to the stock FX block `fx_generate`
  (`0x40121406`, `0x4011fe56`) and both calls to the return mixer
  (`0x401213a4`, `0x4011fe2e`). The receive buffer is `0x80007440`, 12 longs a
  frame (10 on the MK1), voice v in slot `0x401ef480[v]`; the voice's owning
  track comes from `0x40291138`.
- **Output words.** The MKII's return mixer keeps the 24-bit value in the low
  bytes of each word (`lsr.l #8`); the chorus is added the same way. Its return
  goes in words 12/13 of each output frame, where stock puts the delay and
  reverb returns when their routing byte is 0 and where voice-dac adds its DAC
  sum. That this is the PRE path on the MKII is read from the code and from
  voice-dac's notes, **not checked on hardware for this mod**.
- **CHR storage.** The MK1 kept CHR in the sound's free parameter word. Here
  it is a 7-bit sound field in core-ar2's mod storage (`fx_sends_chr`),
  so it travels with the sound and the sound's stock bytes stay stock. The
  audio interrupt never calls core: the UI tick (20 Hz) copies each track's CHR
  into a table the interrupt reads, and an edit updates its track at once. Each
  edit sends stock's sound change notice, as lfo-rnd and voice-dac do, so it is
  kept without a kit save.
- **Memory.** The line and buffers (8.5 KB) are this mod's `.bss`, not raw
  DRAM, so there is no clearing pass after boot.
- **Knobs.** The hidden CY TEST machine's parameter records 449..456, renamed.
  At the first UI tick their RAM records take the dial art and encoder feel of
  COMP's MIX knob (as duck does). The global settings keep 8.8 fractions; CHR
  keeps one fraction, for the track it was last turned on.
- **Page.** Page 15, after AMP (page 7) in the AMP view's list, through
  core-ar2 0.4's page tables (`core_pages`, `core_params`) and page-key lists
  (`core_view_pages`, order 30).

## Needs and conflicts

- Needs core-ar2 0.4 (its page tables).
- Uses 7 bits of core-ar2's 56-bit sound storage. voice-dac (39) and lfo-rnd
  (16) use 55, so **fx-sends cannot be in a build with both of them**; the
  patcher refuses that build ("the mods need 62 bits of sound storage"). It
  links with either one of them.
- With core 0.3 (before the page tables), linked and run in the emulator with
  core, ae-pages, cpu-probe, duck and the
  rytm2_mods v1.2 mods minus comp-preview (which then conflicted with duck) and
  minus lfo-rnd or voice-dac. It also linked with comp-preview when duck was left out.

## Status

Emulator (rytm-emu), core 0.4 + fx-sends, and core 0.4 with the rytm2_mods mods
(all but lfo-rnd, so with voice-dac 1.3 and comp-preview) and cpu-probe: the
page shows and its knobs
turn. Earlier, with core 0.3 + the ae-pages framework + fx-sends, and both full
builds above:

- The page shows behind AMP on the BD track with CHR PRE SPD DEP / WID FDB HPF
  VOL, long names in the header while a knob turns, values in the popups.
- Turning CHR stores it through core (`chr_trk[BD]` reads 20, as the knob).
- With CHR 20 and BD played, the chorus bus is the BD voice's slot times the
  send coefficient (checked against the receive buffer), and a run with VOL 0
  against VOL 100 differs only in the PRE words (12/13) of the output frames,
  L and R differing (WID 96). POST words are untouched.

**Hardware**, Analog Rytm MKII OS 1.74, 21 Oct 2026, core 0.4 with rytm2_mods
without lfo-rnd, and cpu-probe: CHORUS SEND opens behind AMP with popups and
long names, CHR on one track gives a chorus on that track only, and VOL changes
its level; DAC FILTER and the COMP preview work beside it; cpu-probe was read
with the chorus on. With core's page step (no lfo-rnd in the build) the header
names CHORUS SEND; with DAC SUM, the chorus and the preview together, the audio
interrupt reads 92% and peaks at 94%, nothing audible.

**Not checked on hardware:** the level of the return against the delay and
reverb, and CHR surviving a kit save, a reload and a power
cycle (the same storage path lfo-rnd and voice-dac use, which was
hardware-tested for them).
