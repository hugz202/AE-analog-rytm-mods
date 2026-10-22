# Analog Rytm MK1 - OS 1.74 mods

Build pipeline that patches the official Analog Rytm MK1 OS 1.74 firmware
with extra features:

| mod | what it does |
|---|---|
| **0009 TX machines** | seven Machinedrum TX-8 / TX-9 ports as new machines: BD TX-9 and a fully digital BD TX-9 DIGI on the BD track, SD TX-9 / SD TX-8, XT TX-9 / XT TX-8 toms on LT and MT/HT, and an 808 kick (BT TX-8) on the BT track's resonator - calibrated against recordings of a Machinedrum |
| **0010 FX SENDS** | a chorus as a third send effect, with the Analog Four chorus's controls (PRE SPD DEP WID FDB HPF VOL), on a second AMP page; each track's send is saved with its sound |
| **0011 CPU probe** | a measuring build: live processor-load readouts in GLOBAL > MIDI CONFIG > CHANNELS |
| **0012 DUCK** | sidechain-style pumping: pick a track on a page behind COMP and its hits pull every other voice down, at the voices' own analog VCAs (depth, attack, hold, release) |
| 0000 shared | small helpers the other mods call into (no controls) |

How to use them on the instrument: [docs/MANUAL.md](docs/MANUAL.md).
How to build a firmware: [BUILD.md](BUILD.md).
How to flash and get back to stock: [docs/FLASHING.md](docs/FLASHING.md).
**Read [docs/HAZARDS.md](docs/HAZARDS.md) before flashing.**

## Builds

| `make` | mods |
|---|---|
| `full` (default) | TX machines, FX SENDS, DUCK |
| `fx` | TX machines, FX SENDS |
| `tx` | TX machines only |
| `probe` | TX machines, FX SENDS, CPU probe |

## MKII

Ports of these mods to the Analog Rytm **MKII**, OS 1.74, as elekloader elemods, are
in [mk2/](mk2/README.md). Everything else in this README is about the MK1.

## What you need

- An Analog Rytm **MK1** (not the MKII), and the official **OS 1.74** `.syx` from
  Elektron's website. It is not included here: download it and put it in `stock/`
  (`stock/SHA256SUMS` lists the exact file the mods are built against).
- A machine that can run the build: Linux, macOS, or Windows with WSL (Ubuntu).
- Transfer (Elektron's app) or any SysEx tool to send the firmware.

## How it works

The stock firmware is unpacked, and each mod adds small ColdFire assembly routines
in unused space of the image (padding, and the routines of machines the firmware
carries but never offers) plus a few "detours" - jumps from stock code into those
routines. Every patched location is listed in `registry/allocations.toml` with the
exact stock bytes it expects, and the build refuses to touch anything that does not
match. `make` then reads the finished `.syx` back and checks every changed byte, the
untouched embedded bootstrap (the recovery menu), and each detour's return path. The
firmware stays version 1.74, so going back to stock is a normal reinstall.

## Where this comes from

This repository is based on **rytm1_mods**, an Analog Rytm MK1 port (OS 1.73) of the
MKII `rytm-mods` project, and keeps its pipeline and conventions. Added here:

- the TX machines (0009), FX SENDS (0010), the CPU probe (0011) and DUCK (0012);
- **OS 1.74**: every address moved from 1.73 to 1.74 with `tools/port_os.py`, and the
  1.74 builds checked to be byte-equivalent to the 1.73 ones apart from the moved
  addresses (see [docs/PORT-1.74.md](docs/PORT-1.74.md));
- detour chains in `tools/build.py`, so two mods can share a stock hook (DUCK and
  FX SENDS both add a page through the same four).

The other rytm1_mods mods (euclidean accents, velocity humanise, LFO RND, SMP CUT)
are not part of this repository.

## Layout

```
mods/<id>/         one folder per mod: mod.toml (what it is, what it needs),
                   stub.s (its code), design.md (how it was worked out, if any)
registry/          allocations.toml: every patched address, its expected bytes, owner
re/                symbols.toml: the firmware addresses the mods use, with evidence;
                   notes on the analog voices, the FX engine, the hidden machines
tools/             build.py, verify.py, layout.py, symbols.py, mkreg_*.py (generate
                   registry blocks), gen_tx_tables.py, port_os.py, tx_measure/
docs/              MANUAL, FLASHING, HAZARDS, PORT-1.74
stock/             put the official OS 1.74 .syx here
```

## Status

The `make full` image has been flashed on an Analog Rytm MK1 and played: TX machines,
the chorus send and the DUCK page all work. The CPU probe ran on the instrument on
OS 1.73; its 1.74 build passes every build check but has not been flashed yet.

## Thanks

- [elektron-firmware-tool](https://github.com/mischa85/elektron-firmware-tool) by
  mischa85, which packs and unpacks the `.syx` (fetched by `make setup`).
- The rytm1_mods / rytm-mods projects this builds on.

## License

MIT - see [LICENSE](LICENSE). This covers the mods, tools and documentation here.
It does not cover Elektron's firmware, which you supply yourself, or the
elektron-firmware-tool that `make setup` downloads (MIT, its own licence).
`tools/tx_atk_data.py` holds attack and click waveforms measured from the
Machinedrum TX plugins, for calibration.

## Disclaimer

This is unofficial, modified firmware. It is not made, endorsed or supported by
Elektron. You use it at your own risk; read HAZARDS.md first. The OS can always be
reinstalled from the stock `.syx`, including from the STARTUP menu if a build ever
fails to boot.
