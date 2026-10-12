# ZeG UI

Full WoW Forever UI. Current test build: **0.4.7**.

## Installation

Download [ZeG-UI.zip](https://github.com/ZeGeR-lab/ZeG-UI/raw/refs/heads/main/ZeG-UI.zip). Extract its `CleanCenterUI` folder into `Interface/AddOns` and reload WoW. Replace the existing folder; do not install a duplicate. The legacy folder name is retained to preserve saved layouts.

- `/zeg`: open settings.
- Minimap button: left-click Settings; right-click Trackers.
- `/zeg trackers`: style and move available native Blizzard tracker groups.
- `/ccui`: compatibility alias.

Blizzard handles cooldown and aura tracking; ZeG UI customizes its presentation.

All 64 simulated scenarios pass. Live-client appearance, combat and taint verification remain required.

Source, tests, detailed documentation and license are in [CleanCenterUI](CleanCenterUI/).

## Developer checks

Run `python3 CleanCenterUI/tests/run_checks.py` with a Lua 5.3/5.4 shared library installed.
