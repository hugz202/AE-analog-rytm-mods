# cpu-probe (Analog Rytm MKII, OS 1.74)

The CPU probe, AE 0011, ported to the MKII as an elemod. It is a measuring mod,
not one for daily use.

Three labels of SETTINGS > MIDI CONFIG > CHANNELS show the load instead of
their names. The settings themselves are untouched.

| label | shows | what |
|---|---|---|
| PERF CHANNEL | `CPU 78.3%` | time the processor was not idle: audio, sequencer, UI, all of it |
| AUTO CHANNEL | `AUDIO 61.2%` | the audio interrupt's average share of the time |
| PROG CH IN CH | `PEAK 74.0%` | the audio interrupt's largest share of a single block |

Each covers the time since the label was last drawn, so leave the page up for a
few seconds while playing. CPU - AUDIO is what the sequencer, the screen and
the card get.

## How it measures

- Time base: DMA timer 0's counter, free-running at the 132 MHz bus clock
  (core-ar2 starts it at boot if nothing has; the OS reads it too).
- AUDIO and PEAK: the counter at core's `ev_render_in` (subscribed first) and
  `ev_render_out` (subscribed last). On the MK1 the probe hooked the interrupt's
  prologue and epilogue itself; core owns those places on the MKII, so the
  prologue, the epilogue and core's own dispatch fall outside the measured time.
  The readings are therefore slightly low compared with the MK1 method.
- CPU: main() ends in a `bra.s .` spin once it has started the OS tasks. The
  call before it (`jsr 0x400a34d4` at `0x40100a8c`) is repointed to the probe,
  which makes that call and then spins itself, adding up the short gaps between
  timer reads. Any longer gap was taken by an interrupt or a task.

## Sites

| address | op | what |
|---|---|---|
| `0x40100a8c` | keep2 | main()'s last call -> the idle loop |
| `0x400459d6` | jmp | PERF CHANNEL label getter's `pea` |
| `0x400459fe` | jmp | AUTO CHANNEL label getter's `pea` |
| `0x40045a26` | jmp | PROG CH IN CH label getter's `pea` |

Plus `ev_render_in` and `ev_render_out`. RAM: 512 B code, 80 B .bss.

## Status

- Builds for OS 1.74 with core-ar2 0.3 and 0.4. Links with core 0.3 and all
  eleven rytm2_mods v1.2 mods, and with core 0.4 and their page-table versions.
- Emulator (rytm-emu): the three labels show readouts. Every other screen of
  the walk through GLOBAL > MIDI CONFIG > CHANNELS is pixel-identical to stock.
  The emulator does not model the hardware's timing, so its numbers mean nothing.
- Hardware, Analog Rytm MKII OS 1.74, 21 Oct 2026, core 0.4: the readouts
  show beside duck (all eleven rytm2_mods mods) and beside fx-sends.

Credit: hugz202 (AE-analog-rytm-mods, MIT) for the mod; MKII port in this folder.
