# AtariEMU

Native macOS ARM64 starter project for a broad Atari emulator spanning XL/XE through Falcon, including virtual "Super" presets for high-end non-historical configurations.

## What this is

This repository is now a real-core launcher shell for macOS ARM64. It gives you:

- A shared emulator core with machine descriptors, firmware/media policy, operating-system profiles, and capture/export targets.
- Historical machine profiles for Atari XL, XE, 65XE, 130XE, ST/F, Mega ST, Stacy, STE, Mega STE, TT030, and Falcon030.
- Virtual "Super" presets for Super XL, Super ST, Super Mega ST, Super TT, and Super Falcon X1200.
- A SwiftUI macOS shell with a presets menu, loader overlay, and external-core launch control.
- Real backend integration: Atari800 for XL/XE-class machines and Hatari for ST, TT, and Falcon-class machines.
- Tests that validate the catalog and preset declarations.

## Why this structure

The machine families in scope are different enough that you should not force them into one monolithic code path:

- XL/XE centers on a 6502-family CPU plus ANTIC, GTIA, POKEY, SIO, and cartridge/disk workflows.
- ST, Mega ST, Stacy, STE, and Mega STE center on 68000-class timing, Shifter-era video, and TOS/MiNT desktop workflows.
- TT030 and Falcon030 move into 68030-era timing, larger memory maps, SCSI/IDE storage, MiNT, Linux/m68k, and in Falcon's case the DSP56001.
- The virtual "Super" presets provide clearly labeled overclocked/max-RAM configurations without pretending they are historical retail machines.

The shared abstractions in `AtariEmuCore` keep the machine catalog, firmware policy, and preset metadata stable while the macOS app hands real execution off to the upstream emulators.

## Presets and Loader UX

The app now models:

- A `Presets` menu in the macOS menu bar.
- Per-machine launch presets that can auto-select the machine profile and boot flow.
- A green boot splash followed by an animated rainbow loader overlay.
- Software preset manifests for popular Atari titles and OS targets, while keeping the actual media user-supplied unless it is clearly open-source.
- Local media discovery from `UserMedia/`, with optional explicit preset mappings and heuristic filename matching.
- An in-app `Add Media` flow that copies selected disk/program/cartridge images into the current machine catalog and rescans immediately.

Preset launches now resolve local firmware/media and hand the selected machine off to a real backend process. Video is rendered by the external emulator window, not by the SwiftUI shell.

## Firmware and media policy

This repository does not bundle original Atari ROMs, Atari TOS, Atari DOS, or commercial software images.

- Original Atari firmware is modeled as user-supplied.
- EmuTOS remains the default open firmware path for ST, TT, and Falcon-class machines when present.
- Atari MiNT and Linux/m68k are modeled as optional user-supplied boot targets.
- Hatari and Atari800 are integrated as the first real runtime backends. Capture/export polishing is still a follow-on task.
- Local media discovery recognizes a broad Atari format set including `.atr`, `.atz`, `.xfd`, `.xfz`, `.atx`, `.pro`, `.xex`, `.com`, `.exe`, `.bas`, `.lst`, `.car`, `.cart`, `.cas`, `.st`, `.msa`, `.dim`, `.stx`, `.ipf`, `.raw`, `.ctr`, `.img`, `.hda`, `.hdf`, `.hdv`, `.vhd`, `.zip`, plus compound formats like `.atr.gz`, `.xfd.gz`, `.st.gz`, and `.msa.gz`.
- The machine catalog now includes researched `Super Max` presets for XL/XE, ST, TT, and Falcon, alongside the earlier fantasy overclock presets.

See `FIRMWARE_POLICY.md`, `UserMedia/README.md`, [CuratedOpenCollection/manifest.json](/Users/atarick/Documents/atarixl : atari falcon emu/CuratedOpenCollection/manifest.json), and [CuratedOpenCollection/ST_FALCON_FOCUS.md](/Users/atarick/Documents/atarixl : atari falcon emu/CuratedOpenCollection/ST_FALCON_FOCUS.md) for the drop-in layout, verified open-software starter list, and the ST/Falcon-focused set.

## Build

```bash
swift build --arch arm64
swift run AtariEmuApp
```

## Real cores

The app looks for these binaries in the workspace and launches them directly:

- `third_party/atari800/build/src/atari800`
- `third_party/hatari/build/src/hatari`

Environment overrides are also supported:

- `ATARIEMU_ATARI800_BIN`
- `ATARIEMU_HATARI_BIN`
- `ATARIEMU_USERMEDIA`
- `ATARIEMU_WORKSPACE_ROOT`

`Hatari` is used for ST/F, Mega ST, Stacy, STE, Mega STE, TT030, Falcon030, and the virtual ST/TT/Falcon presets. Falcon launches explicitly request DSP emulation.

`Atari800` is used for XL, XE, 65XE, 130XE, and the XL virtual presets.

## Notes

- The launcher shell now stops, relaunches, and switches between real backend processes instead of simulating frames in-process.
- The current app bundle resolves `UserMedia/` and `third_party/` relative to the repository so you can run it from `dist/AtariEmuApp.app` without hardcoding paths.
- `swift test` is still not reliable in this local CLT-only setup.

## Suggested next steps

1. Package the built cores and their runtime assets inside the macOS app bundle instead of resolving them from `third_party/`.
2. Add a capture pipeline that wraps Hatari/Atari800 recordings into the user-facing export formats you want.
3. Expand media heuristics and explicit per-preset config generation for MiNT, Linux/m68k, and Falcon workstation flows.
4. Promote the launcher into per-machine `.app` bundles once the packaging path is stable.
