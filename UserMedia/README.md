# User Media Layout

Place user-supplied or clearly licensed media here. This repository does not ship copyrighted Atari ROMs or commercial disks.

## Suggested layout

```text
UserMedia/
  Firmware/
    Atari/
    EmuTOS/
  Software/
    atariXL/
    atariXE/
    atari65XE/
    atari130XE/
    atariSTF/
    atariMegaST/
    atariStacy/
    atariSTE/
    atariMegaSTE/
    atariTT030/
    atariFalcon030/
    superXL/
    superMaxXL/
    superST/
    superMegaST/
    superMaxST/
    superTT/
    superMaxTT/
    superMaxFalcon/
    superFalconX1200/
```

## Policy

- Original Atari ROMs and TOS images belong under `Firmware/Atari/`.
- EmuTOS belongs under `Firmware/EmuTOS/`.
- ST, TT, and Falcon firmware must be bootable ROM images such as `.img`, `.rom`, `.bin`, or `.tos`. `EmuTOS` `.prg` files are useful downloads, but they are not accepted as system firmware.
- Disk, cartridge, cassette, and hard disk images belong under the matching `Software/<machine>/` folder.
- Only place media here if you own it or it is clearly public-domain/open-licensed.

## Recognized media formats

The scanner currently recognizes these extensions:

- Atari 8-bit: `.atr`, `.atr.gz`, `.atz`, `.xfd`, `.xfd.gz`, `.xfz`, `.dcm`, `.pro`, `.atx`, `.cas`, `.car`, `.cart`, `.rom`, `.bin`, `.com`, `.exe`, `.xex`, `.bas`, `.lst`
- Atari ST/TT/Falcon executable/media: `.st`, `.st.gz`, `.msa`, `.msa.gz`, `.dim`, `.dim.gz`, `.stx`, `.ipf`, `.raw`, `.ctr`, `.img`, `.hda`, `.hdf`, `.hdv`, `.vhd`, `.prg`, `.ttp`, `.tos`, `.mfm`, `.scp`, `.stt`, `.gem`, `.neo`, `.ximg`
- General archives/playlists and future import helpers: `.zip`, `.m3u`, `.sav`, `.vdi`, `.dat`, `.flp`, `.fdi`

Not every recognized file is directly bootable. Archives such as `.zip` are cataloged so you can keep downloads in the library, but the launcher only auto-boots real disk, cartridge, program, cassette, and hard-disk image formats.

## Super Max presets

The catalog includes researched `Super Max` presets for:

- `superMaxXL`: 1088 KB XE-compatible expanded RAM plus multi-drive virtual storage
- `superMaxST`: 14 MiB ST-RAM and 32 MHz accelerator-style timing
- `superMaxTT`: 14 MiB ST-RAM plus 1024 MiB TT-RAM
- `superMaxFalcon`: 14 MiB ST-RAM plus 1024 MiB TT-RAM with DSP path

## Optional preset mappings

If your filenames do not naturally match the preset names, add `UserMedia/PresetMappings.json`:

```json
{
  "mappings": [
    {
      "machine": "atariXL",
      "preset": "AtariWriter",
      "relativePath": "Software/atariXL/AtariWriter.atr"
    },
    {
      "machine": "atariFalcon030",
      "preset": "Cubase Audio Falcon",
      "relativePath": "Software/atariFalcon030/CubaseAudioFalcon.img"
    }
  ]
}
```

If no mapping file exists, the app falls back to heuristic filename matching inside the machine folder. It no longer auto-attaches an arbitrary first file.
