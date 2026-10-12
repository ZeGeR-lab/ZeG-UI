# ZeG UI

Full WoW Forever UI. Current test build: **0.4.12**.

## Installation

Download [ZeG-UI.zip](https://github.com/ZeGeR-lab/ZeG-UI/raw/refs/heads/main/ZeG-UI.zip). Extract its `CleanCenterUI` folder into `Interface/AddOns` and reload WoW. Replace the existing folder; do not install a duplicate. The legacy folder name is retained to preserve saved layouts.

- `/zeg`: open settings.
- `/zeg setup`: guided tracker setup with framed, minimal, round and tile skins, preview, opacity and timer controls.
- Minimap button: left-click Settings; right-click Trackers.
- `/zeg trackers`: style and move available native Blizzard tracker groups.
- `/ccui`: compatibility alias.

Blizzard handles cooldown and aura tracking; ZeG UI customizes its presentation.

All 64 simulated scenarios pass. Live-client appearance, combat and taint verification remain required.

Source, tests, detailed documentation and license are in [CleanCenterUI](CleanCenterUI/).

## Developer checks

Run `python3 CleanCenterUI/tests/run_checks.py` with a Lua 5.3/5.4 shared library installed.

Essential/Utility icon groups also support hiding or dimming during the native countdown display. Native buff/charge/GCD countdowns can affect this mode; it is not a spell-usability test. Configure in `/zeg setup`.

Countdown hiding offers Fixed slots or Compact outside combat. Compaction closes gaps only when native state and geometry are readable outside combat; combat positions stay fixed.

## Direct settings

`/zeg` opens the central menu. Choose **Cooldown tracker > Edit groups** to change group skins, 25–250% scale sliders, text, opacity, timers, hiding and slot options without a setup wizard. **Manager settings** contains enabling and Blizzard spell-selection access.

0.4.12 also caches tooltip styling and reduces repeated skin/reflow work to address hover FPS drops. All 64 simulated scenarios pass; live-client FPS validation remains required.
