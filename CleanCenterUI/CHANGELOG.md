## 0.4.12 — Direct tracker editor, sliders and hover performance

- /zeg and minimap left-click now open a central settings menu with an Overview and organized sidebar.
- Cooldown tracker has Edit groups and Manager settings panels. Directly edit every group's skin, scale, text, background/opacity, countdown visibility, slots and timers; move/reset individual groups without a wizard.
- Group scale slider supports 25–250% in 1% steps; the optional setup wizard uses the same slider. Overview adds HUD scale/opacity sliders.
- Tooltip styling is cached by line count and invalidated by settings changes, avoiding repeated font/panel work on native hover Show calls.
- Bar visibility changes no longer schedule full reflows; tracker polling discovers new widgets instead of repeatedly rebuilding existing skins.
- All 64 simulated checks passed, including slider draft isolation/direct edits and repeated tooltip Show calls. Actual FPS improvement requires live-client validation.

## 0.4.11 — Optional compact countdown layout

- Fixed slots or Compact outside combat for Essential/Utility countdown hiding.
- Readable-state compaction outside combat; no position changes in combat or on secret state.
- Restore original native item positions when fixed mode is selected or hiding is disabled.

## 0.4.10 — Countdown display visibility

- Essential/Utility groups: Always show, Dim during countdown, Hide during countdown.
- Uses the native cooldown widget's display boolean directly through SetAlphaFromBoolean; no timer arithmetic, spell queries, or secret-state branching.
- Optional Fixed slots / Compact outside combat layout for countdown hiding.
- Compaction uses only readable native state and geometry; it freezes in combat and restores native positions when disabled.
- Preserves native tracking. Icon alpha returns to its original value after the native countdown stops or the feature is disabled.
- Group backgrounds suppressed in hide/dim modes; unlocked/editing icons remain visible for positioning.
- Countdown hiding is not a spell-usability test: native active-buff, global-cooldown or charge-recharge displays may also hide an icon. Buff groups retain native visibility.
- Unsupported clients report the missing alpha capability. Live Forever validation still required.

## 0.4.9 — Native tracker group skins

- Per-group framed, minimal, round and tile skins in guided setup.
- Reversible square/circle icon masks, themed borders and tile backgrounds.
- Flat buff-bar fills: native color in minimal skin, HUD accent in other skins.
- Per-group panel opacity and icon timer visibility where native cooldown widgets support it.
- Preserves original masks, fill textures/colors and countdown visibility when disabling skins.
- Native orientation/spacing and spell selection remain Blizzard settings; icon groups are not converted into custom bar trackers.

## 0.4.8 — Guided Blizzard tracker setup

- /zeg setup or Guided tracker setup on the Trackers page opens a four-step assistant.
- Detects player class, explains native group/display choices, previews sample icons/bars, and saves per-group scale, text size and background.
- Draft choices apply only on Save; group styles are included in profiles.
- Opens Blizzard spell configuration and reports manager availability. Spell selection, active visibility, sounds and notifications remain explicit native-editor steps.
- Offers placement through existing movers and advanced settings. Custom fade/popup rules are not implemented.

## 0.4.7 — Minimap launcher and triangle casting visuals

- Put the launcher on an independent UIParent overlay to avoid minimap-child rendering/clipping.
- Use a visible teal gear icon inside the map corner, above native artwork.
- Explicitly show and refresh the button after layout changes; retry creation when the minimap becomes available.
- Native minimap visibility is not changed.
- Clip nested native cast fill, completion flash and interrupt animation textures to the same triangle as their action button; restore original visuals in square mode.

## 0.4.6 — ZeG UI

- Renamed the displayed addon to ZeG UI.
- /zeg is the primary command; /ccui remains supported.
- Added a ZeG minimap launcher: left-click Settings, right-click Trackers.
- Retained installation folder and saved-variable names for layout compatibility.
- All 64 simulated scenarios passed, including launcher actions and command aliases. Live-client verification remains required.

## 0.4.6 — Blizzard tracker presentation (test build)

- Trackers customization page and /zeg trackers.
- Cosmetic borders, matching timer text, optional group backgrounds for available Blizzard cooldown/buff viewers.
- Existing CCUI movers save each native group position; profile export includes tracker preferences and positions.
- Enable Blizzard tracking button, optional automatic enabling, availability/status message and native spell-settings access.
- Keeps native parents, timers, visibility, range warnings, proc glows and debuff indicators. No combat-state scraping or native tracking callback hooks.
- Changes and discovery wait until outside combat. Newly allocated widgets during combat may receive styling only after combat.
- First version uses Blizzard's four groups and spell-selection editor; no individual spell detachment or custom aura rules.
- Forever availability must be verified in the live client. Simulation does not establish live combat/taint safety.

# 0.4.4
- Place pet action buttons on an independent anchor above the main bars at a consistent scale and apply themed button styling.

# 0.4.3
- Centered swing timers between the player and target frames, below the character. Existing swing positions reset once and width is capped at 200 for this migration; later manual adjustments are retained.

# Changelog

## 0.4.2 — 2026-10-04

- Fixed the oversized buff/debuff icons shown in image(8).png. The previous code wrote a displayed percentage into a raw Edit Mode slider field, so native conversion clamped every requested size to 200% (60px before HUD scaling).
- Encode the native slider position correctly and use a compact 27px default. Size controls now follow the supported 15–60px range in three-pixel steps. Existing arbitrary sizes round to the nearest step, including saved/imported profiles; prior CCUI layout values are corrected without resetting positions or other settings.
- Preserve native icon geometry, aura state, click/tooltip handlers, class/secret data boundaries and original-layout backups. Combat/Edit Mode changes remain deferred; disabling styling restores the original native size.
- Corrected the native simulator's slider decoding, which previously repeated the addon mistake. Reproduced the maximum-size failure before the production fix. Added physical icon-size checks across every supported size, HUD scales 1/0.8, an old saved 93 value, legacy preferences/profile imports, options stepping, Edit Mode and restoration.
- Compiled 16 Lua modules and passed all 63 simulated scenarios, including all damage meter checks. No live WoW client was available.

## 0.4.1 — 2026-10-04

- Added a default-on skin for the built-in Forever damage meter session and spell breakdown windows: dark panels, thin shared-color borders, flat fills, matching fonts and a header accent.
- Added the Damage meters customization page and `/zeg meters`: native/class, HUD accent or custom RGBA bar colors; panel opacity; row border/header accent toggles; meter font size/outline and reset. Saved/shared profiles include the new settings; older profiles receive defaults.
- Kept native window ownership, geometry, scripts, session selection, minimizing, resizing, row values and calculations. Discover only public widget children; never inspect private combat tables or read/compare secret combat amounts, names or dimensions. Capture native artwork updates for reversible disable/restore.
- Defer preference changes during combat/Edit Mode while continuing to style newly created windows and rows. Added late-load, secret-color forwarding, forbidden-widget, native restore, profile and options coverage.
- Compiled 16 Lua modules and passed all 61 simulated scenarios, including the prior 50. No live WoW client was available.

## 0.4.0 — 2026-10-03

- Added account-wide named profiles with data-only text export/import, validation and combat/Edit Mode deferral. Native action slots, keybindings and original-layout backups remain local.
- Added alignment guides, drag snapping, exact coordinates and player/target mirroring; right-click movers to select them.
- Added independent size, spacing, square/triangle shape and wrapping for each action bar, retaining all 12 slots and fixed combat anchors.
- Added font family choices and per-category size/outline controls, plus charcoal/teal, black/gold and class-accent presets. Full custom colors remain available.
- Styled public native buff/debuff icons and tooltips while preserving native scripts, aura maps and text. Aura layout settings use the private native profile; debuffs follow the buff grid by default.
- Added a slim native swing presentation with main-hand/off-hand/ranged support, size/color controls and optional time text. Native widgets retain all timing and visibility decisions.
- Added optional utility fading with hover, typing, editing and combat restoration. Action, unit and cast bars remain unaffected.
- Added the eight-page Customize window and slash shortcuts. Preserved existing settings and all prior cast, EXP, bag, minimap, party, cooldown and travel-button fixes.
- Compiled 15 Lua modules and passed 50 simulated scenarios. No live WoW client was available.

## 0.3.9 — 2026-10-02

- Address the screenshot showing the taxi/vehicle exit button over the action-row icons/keybinds. Place the original button to the left of the highest selected row, following saved row coordinates. Keep a single-row layout's exit button above the stance/form panel to avoid overlap.
- Add a matching dark panel, thin HUD border, inset native normal/pressed exit artwork and accent hover highlight. Keep a square shape independent of the action/stance triangle choices; size follows button size and HUD scale.
- Add the Flight / vehicle exit mover and saved per-character override. Keep the original MainActionBar parent and native visibility, event/click/tooltip handlers, early-landing request, disabled/pending state and vehicle exit behavior.
- Record exit-button geometry in the private C_EditMode profile to leave automatic default positioning, bypass native Lua geometry wrappers, and defer layout during combat/Edit Mode. Preserve the native exit button's visibility policy and original-profile restoration.
- Retain all minimap, party Offline, cooldown-number, bar-count, stance, utility, cast and EXP fixes/preferences.

Status: eleven Lua modules compile and thirty-seven simulated scenarios pass. New checks cover square/triangle 1/2/3/8 rows, HUD scales 1/0.8, moved rows/exit overrides, taxi/vehicle tooltips/clicks/pending state, native show/hide, and original-parent movement in combat. Actual flight input/rendering, native layout interactions and taint still require in-game confirmation.

## 0.3.8 — 2026-10-02

- Add a square minimap mask, matching panel/border and quiet native frame artwork. Keep native map/container parents, events and input. Reanchor native zone/clock, tracking/indicators, zoom, instance and expansion controls around the square without replacing their handlers.
- Add a fixed minimap presentation anchor and movement handle, per-character 120–360 size (default 180), exact size entry, plus/minus buttons, Move/Reset controls, and `/zeg minimap [size/reset]`. Resizing and moving wait until combat/Edit Mode ends. Preserve old saved minimap coordinates and reserve physical space for default quests/buffs when the map grows.
- Publish the conventional SQUARE shape provider and restore the previous provider when disabling the preset. Refresh shape-aware LibDBIcon icons through public positioning methods, preserving angles/preferences/visibility/scripts; retain visibility and drag scripts when older libraries require Refresh. No library dependency or third-party source is bundled.
- Show Offline for disconnected party members using public connection and roster state. Subdue health/power fills, hide the stale health number, support thin health bars with a name-row label, and restore normal presentation on reconnect. Never infer connection from restricted health/range values or modify secure unit visibility/targeting.
- Add a default-on Cooldown numbers toggle and `/zeg cooldowns on/off`. Style the native normal-cooldown countdown inside square/triangle ability icons and stance/forms. Preserve native timing, expiry, charges and loss-of-control overlays; avoid duplicate charge timers, secret-time reads/calculations, and global CVar changes. Reassert the selected display flag after native resets.
- Preserve the previous EXP-pip, cast-fill, bag-hover and combat-position fixes and all existing row/shape/color/size/position preferences.

Status: eleven Lua modules compile and thirty-five simulated scenarios pass. Native square masking/input, icon-library integration, disconnect events, countdown rendering, and taint still need in-game confirmation; no live WoW client was run.

## 0.3.7 — 2026-10-02

- Address the screenshot showing EXP divider pips extending to the right of the themed strip. Reapply cosmetic suppression every tracking presentation tick as well as after native divider updates. Later cached callbacks, pool replacements, or alpha resets no longer depend on the existing instance post-hook to regain styling.
- Mask each native pooled divider's actual `BarDividerTexture` as well as its frame. Retain native EXP/rested calculation, updates, input, level-cap visibility, parents, and fixed bar geometry; no combat reflow, protected frame hiding, native Lua state writes, or secret dimension arithmetic is added.
- Add normal/reduced-scale triangle-HUD regressions that recreate stock-width dividers through a cached unhooked native method and reset pip/border alpha after the layout hook. Keep both native tracking containers suppressed and verify no addon geometry changes, layout queue changes, or progress/input replacement.
- Preserve the cast-fill and bag-hover fixes, stance styling, chosen row count, shapes, colors, frame sizes, utility modes, and saved positions.

Status: ten modules compile and twenty-eight simulated scenarios pass. The late-refresh regression failed against 0.3.6 before the fix. The screenshot confirms the visual recurrence, but the exact live native callback path and rendering still require in-game confirmation.

## 0.3.6 — 2026-10-02

- Keep the themed cast fill opaque while forwarding native range, value, and RGB directly. Hiding the stock fill can no longer make the independent display transparent through copied fill alpha. Retain native whole-bar fades, visibility, text, icon, casting/channeling updates, original parents, and scripts.
- Fix the reported `Invalid frame handle for AddToAutoHide` bag-hover error. Register only our explicitly protected dock with the explicitly protected flyout. Native backpack/bag widgets are never registered as protected handles.
- Handle hover on our secure parent headers through propagated native mouse motion. Retain every native bag tooltip/click/drag script without wrapping or replacing it. Keep combat-safe visibility and the 0.3-second auto-hide, reversible Full mode, and original bag preference restoration.
- Strengthen the simulator to reject ordinary frame handles in AddToAutoHide. Reproduce the previous hover failure, add masked-fill opacity regressions at HUD scales 1 and 0.8, and check progressive casts, reverse channels, native interrupt color/fades, secret RGB, original ownership, and no combat geometry changes.

Status: ten modules compile and twenty-six simulated scenarios pass. Both regression checks failed against the previous implementation before the fixes. Live WoW cast rendering, propagated mouse targeting, restricted execution, and taint still require in-game validation.

## 0.3.5 — 2026-10-02

- Style native warrior/druid/other stance/form buttons with matching panels, borders, sizes, native checked-state accent outlines, and independent Squares/Triangles selection. Preserve native containers, class availability, action handlers, tooltips, and cooldowns. Add a stance movement handle.
- Add a single-backpack compact mode. Native individual bags are inside a protected visibility gate, opened by secure hover wrappers/header motion and closed through a 0.3-second auto-hide. Preserve original click/drag handlers and tooltips. Retain a Full mode and restore original parents when switching back.
- Preserve the original expanded-bag CVar for restoration through `/zeg off`; enable native individual slots inside the compact gate without calling native Lua state setters. Include native reagent/keyring entries where available.
- Dock the micro menu between EXP/tracking strips and action rows. Reserve its measured height plus themed padding; keep its usual size where it fits and reduce scale for narrow HUDs. Include native nested menu scaling in measurements. Retain Corner mode and user-saved menu positions; explicit mode selection clears the saved menu position.
- Configure horizontal menu and horizontal/left bags in the private native profile copy through C_EditMode, without writing live native layout fields.
- Add `/zeg stance square/triangles`, `/zeg bags hover/full`, `/zeg menu center/corner`, and settings controls. Preserve main action shape, chosen row count, colors, frame sizes, and saved layout. Reset layout restores the new default utility modes.
- Extend simulation with three/six/no-form cases, reversible stance shapes, class highlight/click/tooltip ownership, production hover snippets through visibility-only frame handles, bag clicks/drag/auto-hide in combat, combat mode deferral, original bag preference restoration, native orientation defaults, menu/EXP/action non-overlap at multiple scales, full/corner modes, and missing secure hover API fallback.

Status: ten modules compiled and twenty-four simulated scenarios passed. Live WoW hover input, class changes, protected layout, clipping, and taint still require in-game validation.

## 0.3.4 — 2026-10-02

- Suppress native EXP container borders and pooled dividers immediately after native divider refreshes, including in combat. Reacquired/new divider frames no longer wait for an out-of-combat layout pass to lose their stock artwork.
- Add a saved Squares/Triangles selector and `/zeg shape square` / `/zeg shape triangles`. Squares remain the default on upgrade; Reset layout restores squares.
- Alternate original up/down alpha masks, thin themed outlines, and triangle cooldown swipes. Mask native hover/press/checked/flash art without changing its textures or handlers. Suppress radial cooldown edge/bling while triangles are selected; restore original flags on returning to squares.
- Pack triangles at half-button width plus two pixels and resize EXP/row heights/automatic unit placement to match. At size 48, twelve buttons occupy a 334-pixel row instead of 642 pixels.
- Give each overlapping native button a separate center click column, retaining native actions and drag/drop. Explain center clicking in the settings and README. Return to original hit insets, stack-count positions, and square outlines when selecting squares.
- Preserve the fixed native button/EXP geometry and parent chains, bar count, keybinds, portraits, frame sizes, colors, movers, section switches, and original-layout restoration.
- Add combat pool-refresh coverage and triangle combat movement at normal/reduced HUD scales. Check physical click-column separation, unique button centers, shape reversal, unchanged native handlers/action slots, masked art, EXP width, border switching, and combat deferral.

Status: nine modules compiled, nineteen simulated scenarios passed, and four TGA assets verified. Actual WoW masking, clicks, cooldown rendering, clipping, and taint behavior still require in-game testing.

## 0.3.3 — 2026-10-02

- Address the remaining live combat shift after 0.3.2. Native saved-position preferences alone were insufficient in the reported client.
- Anchor native action buttons directly to independent fixed row frames. Retain their original button/container/bar parents, native scripts, action slots, paging, keybinds, and visibility.
- Give native EXP/tracking bars fixed presentation slots while retaining their native tracking-container/manager ownership, updates, resting, tooltip behavior, and level-cap hiding.
- Set visual widgets to ignore inherited parent scaling, using the HUD's effective scale set outside combat. Native movement and scale changes cannot carry the visible widgets right.
- Place borders and movement handles on the fixed presentation frames. Decorative visibility/alpha follows native visibility; extra row borders and level-cap tracking borders hide correctly.
- Keep the secret-safe panel rendering, cast presenters, full appearance editor, saved panel preferences, and native restoration from 0.3.2.
- Add normal-scale and reduced-scale regression cases that forcibly move/reparent/rescale native action bars and move tracking containers during combat, despite non-default saved positions. Resolve actual screen rectangles of buttons, rows, EXP bars, and fills before and after. Verify native XP ownership, live EXP updates/tooltips, and no addon combat geometry writes.

Status: syntax and seventeen simulated scenarios passed. Actual WoW combat, clipping, vehicle, and input validation is still required.

## 0.3.2 — 2026-10-02

- Save preset anchors and non-default-position flags through the private C_EditMode layout. Native managed-frame combat arrangement now leaves placed bars, EXP/tracking containers, utility panels, minimap, buffs, and quest tracker alone.
- Keep tracking containers under their native manager after C_EditMode placement, preserving XP update/tooltips ownership.
- Preserve target/focus cast bars' original parents and native OnShow methods. Keep native target/focus frames alive while masking their stock artwork.
- Add fixed player/target/focus cast presenters that forward native widget values, range, text, icon, color, alpha, and visibility directly into separate display widgets. No cast-time arithmetic, comparisons, or secret layout inheritance is involved. Detailed native stage effects are outside the minimal presentation.
- Replace BackdropTemplate panels with solid background and four engine-anchored border textures. Never compute backdrop UVs from secret width/height, including movers and click-to-edit overlays.
- Preserve bar count, appearance controls, portraits, health/power sizing/colors, EXP/bags/menu switches, and saved panel positions.
- Expand regression checks to reproduce default native combat repositioning, verify stable anchors and parents in combat, exercise the actual target-parent method contract, forward secret cast data without arithmetic, reject Lua backdrop usage, and cover disabled cast styling.

Status: syntax and fifteen simulated scenarios passed. Live WoW combat and taint validation remains required.

## 0.3.1 — 2026-10-01

- Configure a separate character Edit Mode layout through C_EditMode, preserving the original layout and unrelated native system settings. Set the eight keyboard action bars to Always visible, horizontal, one row, twelve buttons, and empty slots shown.
- Fix the modeled combat-visibility conflict where an existing Out of Combat preference hid the main bar after addon placement.
- Replace native proxy-setting writes and repeated MultiActionBar_Update/SetShowGrid/forced-button-Show calls with a single bulk action-bar toggle C API call. Bar-count changes reload outside combat/Edit Mode once the server confirms the preferences.
- Stop calling the native tracking-bar tick updater and chat-position Lua saver during reflow/restoration.
- Preserve the configured native profile through logout; /zeg off restores original native toggles, layout selection, and chat geometry.
- Add /zeg taint to sample native security metadata without indexing aura maps or inspecting secret spell/health values. Record the first stage where sampled taint is observed.
- Preserve the complete appearance editor, EXP/bag/menu styling, saved sizes/colors/portraits, and movable panels.
- Retain stock bars if required native configuration is unavailable, character layout slots are full, or the gamepad interface is active.
- Add regression checks for the original combat-disappearance behavior, stable chosen rows during combat, private native profile changes, original-profile restoration, untouched gamepad flyout scripts, forbidden aura-table boundaries, profile capacity, preset layouts, and missing APIs.

Status: syntax and fourteen simulated scenarios passed. Live-client combat, paging, and taint validation is still required.

## 0.3.0 — 2026-10-01

- Added per-frame width/height, health height, and mana/power height controls for player, target, pet, focus, and all five party frames.
- Added a native RGB/hex color picker with transparency, live preview, and reversible cancellation.
- Added per-frame class-colored health and automatic power-type color switches; choosing a custom color disables the corresponding automatic mode.
- Added portrait visibility switches that reclaim icon space for the bars.
- Added an Appearance button and `/zeg appearance [player/target/pet/focus/party]` / `/zeg colors` commands.
- Added click-to-edit health/power overlays while unlocked; overlays hide when locked or in combat and preserve secure targeting/menu/click-cast attributes.
- Added configurable HUD panel, border, text, highlight, empty-bar, EXP, and rested EXP colors.
- Adjusted automatic unit/party/cast placement to accommodate resized frames while retaining user-saved positions.
- Changed integration around the reported compact-party health-color and cooldown-viewer aura-map taint paths: bypass native Edit Mode geometry wrappers, avoid writes to native layout fields, add call barriers, and defer reflow while Blizzard Edit Mode is open. Actual taint behavior was not reproduced in the simulator.
- Preserved existing settings on upgrade; layout reset keeps appearance settings. Added separate frame and HUD-color resets.
- Expanded simulated checks for native Edit Mode wrappers/state, per-frame color isolation, picker setup/cancellation, class/power colors, portrait space, exact numeric sizing, unlocked clicks, combat/Edit Mode deferral, party spacing, and migration.

Status: syntax and ten simulated scenarios passed. Live-client testing is required to confirm both reported taint errors are resolved.

## 0.2.0 — 2026-10-01

- Added a slim native EXP/tracking-bar area beneath the action bars, matching their width and button-size changes.
- Styled normal EXP in muted violet and rested EXP in blue; retained native updates, tooltips, animations, rested progress, and level-cap visibility.
- Added dark panels and clearer one-pixel borders around action rows/buttons, player/target/focus cast bars, and cast icons.
- Added matching bag and micro-menu panels, independently movable and separately switchable from action bars.
- Positioned the bag panel above the micro menu with spacing based on the menu's actual height.
- Added a Bar borders setting and `/zeg borders on/off` commands; preserved existing per-character settings.
- Extended simulated checks for tracking-manager ownership, EXP/rested updates, max-level hiding, native utility click/drag handlers, section switches, border changes, and EXP width/position changes.

Status: simulated checks passed; real WoW rendering and secure-action testing pending.

## 0.1.0 — 2026-10-01

- Added the automatic Clean Center layout preset for WoW Forever.
- Defaulted to two action bars; added a selector for one to eight.
- Added compact unit/party frames and styling for native action buttons and cast bars.
- Positioned native chat, minimap, buff icons, quest tracker, menus, and bags buttons.
- Added per-character panel movement, sizing, opacity, module switches, reset, and disable/restore controls.
- Deferred layout changes requested during combat.
- Added client diagnostics and simulated-client validation.

Status: early test build; real WoW rendering and secure-action testing pending.
