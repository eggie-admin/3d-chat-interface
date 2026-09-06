# Legacy Drive Ingestion Notes

Source folder: `0B9Ta-9B_z53obURzSV9NWTA4cUk`

The supplied archive is a legacy Destiny Child community mod/resource collection. Metadata inspection found these top-level lanes:

- `01 - CHILDRENS TOYS`: miscellaneous files, fonts, wallpapers and helper material.
- `01 - MUSIC SWAP`: in-game audio replacement material.
- `02 - JAPANESE TENTACLES - VOICE SWAPS`: KR -> JP voice swaps.
- `03 - DC OST - MP3` and `03 - DC JP OST - MP3`: OST mirrors.
- `04 - ART SWAPS FOR DCJP`: JP/KR character-art swaps.
- `70 - DC REDUX EXTENDED`: extended remix material.
- `71 - WALLPAPERS`: wallpaper art.
- `73 - INTERIM REDUX OST`: interim/unreleased remix material.

The old art-swap guide points at the Android path:

`SDCARD/ANDROID/DATA/COM.STAIRS.DESTINYCHILD/FILES/ASSET/CHARACTER`

A historical comparison report also enumerates many `.pck` files in the character asset tree. Sample bulk-art archives were tens of megabytes each, so this Cathedral does not mirror those binaries into GitHub.

## Ingestion doctrine

1. Inspect metadata first.
2. Hash local mirrors before transformation.
3. Classify image/audio/archive/game-package/document types without executing them.
4. Never copy external content into the PET release automatically.
5. Record provenance and source URI.
6. Promote only material explicitly classified as `lum_original` or `generated_original`.
7. Keep legacy corpus usage to taxonomy, workflow study, and inspiration at a high level rather than pixel/audio extraction.

## What the archive contributes to Tiny Lum Pet

The useful architectural lesson is the **swap-pack pattern**: stable logical slots with replaceable content. Tiny Lum Pet adopts that idea safely as a manifest-driven system where animation rows and mood names are stable contracts while the actual Lum-owned sprite atlas can be replaced independently.
