# duck (Analog Rytm MKII, OS 1.74)

DUCK, AE 0012, ported to the MKII as an elemod: sidechain-style pumping
without the analog compressor. Every audio block the other voices' analog VCA
words are scaled by a gain that dips when the key track's voice hits.

With the FX track selected, press AMP (COMP) a second time for the DUCK page:

| knob | range | what |
|---|---|---|
| SRC | OFF, BD SD RS CP BT LT MT HT CH OH CY CB | the key track |
| DEP | 0..127 | depth: 127 pulls the other voices fully down (90 is about -10 dB) |
| ATK | 0..127 | attack, instant to about 85 ms (time constant) |
| HLD | 0..127 | hold at full depth after a hit, 0 to 170 ms |
| REL | 0..127 | release, 5 ms to about 2 s (time constant) |

The settings are global and held in RAM: they return to the defaults (SRC OFF)
at power-up, as on the MK1. The delay and reverb returns are not ducked.
Voices that two tracks share (RS/CP, MT/HT, CH/OH, CY/CB) duck together.

## What changed from the MK1

- **Hooks.** The VCA words are written by `0x40109940(frame)`, called once a
  block at `0x401212b2`; that call goes through `duck_gate` (keep2). The words
  sit where they do on the MK1 (frame +10+2v and +26+2v).
- **Key.** The source voice is read from the receive buffer `0x80007440` (12
  longs a frame, voice v in slot `0x401ef480[v]`). It is refilled later in the
  block, so DUCK sees the previous block's audio: one block (0.67 ms) late.
- **Knobs.** The MKII has no spare "Error" records left once rytm2_mods is in,
  so the knobs are the hidden HH TEST machine's records 443..447, renamed. At
  the first UI tick their RAM records take the dial art and encoder feel of
  COMP's MIX knob. The settings keep 8.8 fractions, as stock does, so turns
  smaller than a step add up.
- **Page.** Page 14, after COMP (page 11) in the COMP view's list, through
  core-ar2 0.4's page tables (`core_pages`, `core_params`) and page-key
  lists (`core_view_pages`, order 30: after comp-preview's preview).

## Needs and conflicts

- Needs core-ar2 0.4 (its page tables).
- Shares the COMP key with comp-preview 1.1: core-ar2 0.4 builds the
  COMP view's list (COMP, the preview, then DUCK), so the two link together.
- Links with the other ten rytm2_mods v1.2 mods and the AE MKII ports.

## Status

- Emulator (rytm-emu), core 0.4 + all eleven rytm2_mods mods (comp-preview
  1.1 included) + duck + cpu-probe: the COMP key steps COMP, preview, DUCK.
- Emulator (rytm-emu), core 0.4 + duck, and core 0.4 with the rytm2_mods
  mods (lfo-rnd 1.2, voice-dac 1.3) and cpu-probe: the page shows behind COMP.
  Earlier, with core 0.3 + the ae-pages framework + duck: the page shows behind COMP,
  the five knobs turn with value popups and long names. With SRC = BD, DEP
  90, ATK 3, HLD 22 (set directly in RAM; the emulator's encoder dead zone
  makes small turns unreliable), SD then BD 0.5 s later, SD's VCA L word:

  | t after BD | before | 15 ms | 25 ms | 55 ms | 105 ms | 205 ms | 405 ms | 1 s |
  |---|---|---|---|---|---|---|---|---|
  | MKII port | 12735 | 3761 | 3711 | 4759 | 6711 | 9296 | 11607 | 12675 |
  | MK1 (its design.md) | 12735 | 4103 | 3824 | 4669 | 6626 | 9228 | 11572 | 12673 |

  With SRC OFF the word stays at 12735.
- The emulator models the VCA words, not the analog VCA, so the audible
  result (and the -36/-48 dBFS key thresholds against the MKII's real input
  levels) were checked on hardware afterwards (below).
- Hardware, Analog Rytm MKII OS 1.74, 21 Oct 2026, core 0.4 with all eleven
  rytm2_mods mods and cpu-probe: COMP cycles COMP, comp-preview's preview,
  DUCK; each knob shows its popup and long name; with SRC BD and DEP about 90
  the other tracks duck on each BD hit, the preview's trace running beside it;
  DUCK stays shown on leaving the FX track. With core's page step and kept
  page, DUCK is kept on coming back after DELAY or a voice track, also with
  voice-dac and duck alone (no comp-preview), the header naming each page.
  Not measured: the exact gain
  curve against the table above.

Credit: hugz202 (AE-analog-rytm-mods, MIT) for the mod.
