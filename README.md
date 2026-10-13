# ZeG UI

Full WoW Forever UI. Current test build: **0.4.14**.

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

## Layouts and finishing

- **Cooldown tracker > Edit groups:** octagonal icon skins and native/horizontal/vertical/grid-cluster/radial arrangements. Use Move group or Positions. Timer bars use rows/columns.
- **Action bars:** choose each bar's shape and arrangement, Thin/Soft/Bold/None borders, and inside/below hotkey labels. Inside labels shrink the background.
- Radial wheels use separate buttons, not true pie-slice secure click regions. Layout changes wait until outside combat.
- Removed recursive animation masks associated with triangle hover FPS loss; highlights now use pre-shaped textures. Only cast-fill masking remains; completion/proc flair stays native.

65 simulated scenarios pass. In-game FPS and native combat reflow still need verification.

## Compact menus and placement

Main settings and setup now use smaller, scrollable windows with fixed Unlock/Lock controls and a clear current-section indicator. Snapping and grid guides start off; optional snap only attracts within two units of a grid line, and Alt bypasses it. The minimap launcher is smaller. Existing positions are kept.

### 0.4.15

Action bars now support individual button positioning while retaining bar membership, fitted shape highlights, and ordinary column wrapping without radial presets. Tracker groups retain radial layouts with a 25–250% radius slider. Open `/zeg` → Action bars → Move individual buttons, then unlock frames.
