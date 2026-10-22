# MKII ports (Analog Rytm MKII, OS 1.74)

The AE mods in `mods/` are for the Analog Rytm **MK1**. This folder holds their
ports to the **MKII**, OS 1.74, as [elekloader](https://github.com/irpina/elekloader)
elemods: each folder has a `mod.json` and its source, built with elekloader's
SDK and linked with core-ar2 0.4 (OS 1.74 only), next to the rytm2_mods mods.
duck and fx-sends add their pages through core-ar2 0.4's page tables
(`core_pages`, `core_params`), so they link beside rytm2_mods' pages: that
needs rytm2_mods' lfo-rnd 1.2, voice-dac 1.3, euclid-accents 1.2 and
velocity-humanise 1.2 or later (v1.2's builds of those four do not link with
core 0.4). duck shares COMP with comp-preview 1.1 or later, through core 0.4's
page-key lists.

| folder | MK1 mod | what | status |
|---|---|---|---|
| [cpu-probe](cpu-probe/README.md) | 0011 | CPU, AUDIO and PEAK readouts on the CHANNELS page | hardware |
| [duck](duck/README.md) | 0012 | DUCK page behind COMP: VCA ducking keyed by a track | hardware |
| [fx-sends](fx-sends/README.md) | 0010 | FX SENDS page behind AMP: a chorus send | hardware |
| TX machines | 0009 | not ported yet | |

"Hardware" means checked in rytm-emu and then on an Analog Rytm MKII (OS 1.74,
core-ar2 0.4, 21 Oct 2026). Each README says what was checked and what was not.

## Building

With an elekloader checkout (main) and the stock OS 1.74 `.syx`:

```
python3 -m elekloader.sdk.build mk2/duck --stock Analog_Rytm_MKII_OS1.74.syx
python3 -m elekloader.patch --stock Analog_Rytm_MKII_OS1.74.syx \
  --mod mods/core-ar2/out/core-0.4.elemod \
  --mod mk2/duck/out/duck-1.0.elemod \
  --out rytm-ae.syx --lockfile rytm-ae.lock.json
```

Keep the lockfile: it decides where fx-sends' CHR sits in the sound's storage.

## Builds that cannot be made

This one follows from what the MKII has room for, and the patcher refuses it:

- **fx-sends with both voice-dac and lfo-rnd**: the three need 62 bits of
  core-ar2's 56-bit sound storage. fx-sends links with either one.
