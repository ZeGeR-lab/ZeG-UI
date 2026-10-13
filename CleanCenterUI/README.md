# ZeG UI — Forever test build 0.4.2

A single-addon first pass at the **Clean Center** mockup: a clear world view, paired player/target frames above centered spell bars, compact party frames on the left, quiet chat below, and the minimap/quests at the upper right.

**Two action bars are the default. Choose one to eight bars, with twelve existing spell slots per bar.** The preset applies automatically when you first log in. No profile import or other UI addon is required.

**Version 0.4.2 fixes oversized buff/debuff icons.** The addon now saves the native size setting in its correct format, so the selected size no longer jumps to the maximum. The default is 27 HUD pixels; `/zeg auras` offers 15–60 in three-pixel steps. Older sizes round to the nearest supported step (28 becomes 27), including imported profiles. Existing positions and other appearance settings are retained. Installing this build corrects the active CCUI layout automatically; no settings reset is required. Size changes wait until combat and Blizzard Edit Mode end.

**Version 0.4.1 skins the built-in damage meters.** Their session windows and spell breakdowns use the shared dark panels, thin borders, flat bars, matching text and a small header accent. Open `/zeg meters` for the skin toggle, native/class colors, UI accent or custom RGBA bar color, panel opacity, row borders, header accent and meter font controls. The skin follows the current HUD palette and is included in saved/exported profiles. Existing profiles receive the default meter settings.

Enable damage meters through WoW's own options. Keep using their native settings and Edit Mode to move/resize windows, change row height, select damage/healing views or enable class colors. Native / class colors preserves the game's selected color policy; it does not enable class colors itself. Opacity -1 follows HUD opacity; 0 through 1 overrides the panel opacity. Disabling the skin restores the latest native artwork and fonts. Preferences changed during combat or Blizzard Edit Mode apply after it ends. This module targets the built-in Forever meters; it does not skin Details!, Recount or Skada.

**Version 0.4.0 adds all eight customization groups.** Open **Customize** in `/zeg`, or type `/zeg customize`.

| Page | Controls |
| --- | --- |
| Profiles | Save named layouts across characters; export current/saved layouts as text; import and load shared layouts. |
| Alignment | Snap dragged panels to a grid, show center guides, enter exact X/Y coordinates, mirror player and target frames. |
| Action bars | Set each bar's size, spacing, shape and buttons per line. All twelve native spell slots remain available. |
| Fonts | Choose a family and separate sizes/outlines for names, health, keybindings, cooldowns, casts, chat, auras, tooltips, swing text and meters. |
| Themes | Charcoal/teal, black/gold or class accent. The existing full color picker and class-colored health options remain available. |
| Buffs / tooltips | Matching borders/fonts; aura size, spacing and columns; movable buffs/debuffs; default, cursor or fixed tooltip position. |
| Swing timer | Slim themed strips centered between the player and target health bars; width, height, color, native combat/always visibility and optional native time text. |
| Idle fading | Optional chat, bag and menu fading; adjust delay, idle opacity and duration. Hover, typing, combat and editing restore opacity. |
| Damage meters | Skin native session/breakdown windows; choose native/class, accent or custom bar colors, opacity, borders, header accent and fonts. |

Existing per-character styles and positions are retained. New aura/tooltip styling and the swing presentation are enabled by default; idle fading starts off. Default bars still use the global size/shape and twelve buttons per line. You can right-click an unlocked mover to select it in Alignment. Exact coordinate entry bypasses drag snapping.

**Profiles:** type a name and choose Save / overwrite. Select a saved profile with the cycle button and choose Load. Export selects plain text for Ctrl+C; paste another export into the same field, name it, then choose Import as named and Load. Import saves without applying. Profiles include only CCUI preferences, positions and appearance, and keep native spell slots, keybindings, original-layout backups and enable/disable state. Loading during combat or Blizzard Edit Mode waits until it closes. Changing HUD sections through a profile restores native settings and reloads.

**Swing timers:** the game's main-hand, off-hand and ranged widgets own timing and availability. The addon styles their progress; it does not calculate swings. The native swing preference is enabled while this feature is active and its previous value is restored when disabled. A weapon timer appears when its native widget is active. If the client lacks those widgets, the feature has no display.

**Utility fading:** fading affects only the selected chat/bag/menu panels. Native actions and visibility stay in use. Action bars, cast bars and unit frames do not fade. The expanded bag flyout restores opacity while hovered, including during combat.

Shortcuts: `/zeg profiles`, `/zeg layout`, `/zeg customize bars`, `/zeg fonts`, `/zeg themes`, `/zeg auras`, `/zeg tooltips`, `/zeg swing`, `/zeg fade`, `/zeg meters`. Apply a palette directly with `/zeg theme teal`, `/zeg theme gold` or `/zeg theme class`.

**Version 0.3.9 moves and themes the flight/vehicle exit button.** It sits to the left of the highest selected action row, with a dark panel, thin shared-color border, inset native exit icon and accent hover highlight. With one action row and available stances/forms, it sits above their panel so they remain clear. Its size follows button size and overall HUD scale. It follows a moved top row by default; use **Unlock panels** and the **Flight / vehicle exit** handle to save a separate position.

The original button remains in use, including its native parent, visibility, click/tooltip handlers, disabled/pending state and vehicle behavior. Clicking during a taxi flight requests an early landing at the next available stop; it retains the game's usual behavior. The preset records its placement in the private native layout so normal automatic positioning does not put it back over the action icons. Geometry changes wait until combat/Edit Mode ends, and `/zeg off` restores the original native layout.

**Version 0.3.8 adds a square, movable minimap with size controls, an Offline indicator on party frames, and numeric ability cooldowns.** Existing frame styles, row counts, triangle choices, utility modes, saved positions, EXP pip suppression, cast fills, and bag-hover fixes remain included.

Open **Minimap settings** in `/zeg`, or type **/zeg minimap**. Choose a size from **120 to 360** HUD pixels (default 180), then **Move minimap** to unlock panels and drag the Minimap handle. Lock panels when finished. Size and position are saved per character, and overall HUD scale applies to the map. Default quest and buff placement leaves space for the larger map; manually moved panels retain their own positions. Zone text, clock, tracking, mail/indicators, zoom and native map input remain functional. The border uses the shared HUD panel/border colors.

The map exposes **GetMinimapShape() = "SQUARE"** for shape-aware addon icons. Existing LibDBIcon icons are repositioned using that library's public API; their saved angles, visibility, click/tooltip/drag handlers and preferences are retained. New icons also see the square shape. Older library versions with only Refresh are supported without changing the icons' visibility or drag scripts. The previous shape provider is restored by `/zeg off`. Addons that hard-code circular coordinates may need their own compatibility change. Blizzard's native click-to-ping radius remains in use.

Disconnected party members show **Offline** in their health bar, with subdued health/power fills and no stale health number. For health bars thinner than ten pixels, Offline appears beside the name instead. Connection and roster events update the indicator, including during combat, and reconnecting restores the normal bar colors and numbers. Targeting and click-casting remain unchanged.

**Cooldown numbers** are on by default. Toggle them in `/zeg` or use **/zeg cooldowns on/off**. Blizzard's own countdown text sits inside the themed ability icons, including alternating triangles and stance/form buttons. Native timing, charges, global cooldown filtering and expiry remain in use; the addon does not calculate remaining time or create another timer. The charge and loss-of-control overlays keep their native display choices, avoiding duplicate charge numbers. The native global cooldown-number preference is not changed.

The matching stance/form bars, hover-expanding bags, and centered menu from 0.3.5 remain included. Warrior stances, druid forms, and other native stance buttons use the same dark panels and borders. The active stance has an accent outline. Stance buttons use squares by default, with a separate triangle switch; their native class availability, click handlers, tooltips, checked state, and cooldowns remain in use. Use **Unlock panels** to move the stance row beside the action bars.

The bag bar normally shows a single backpack. Hover it to reveal the individual native bags to its left, then click or drag onto the bag you want. The flyout remains open while moving between the backpack and bags, and closes about 0.3 seconds after leaving. A protected visibility gate handles opening and auto-hide, including combat; the original bag click, item drag/drop, free-slot count, and tooltip behavior stay in place. Reagent/keyring buttons are included when the client exposes them. **Bags: full** restores an always-visible bar. The addon temporarily enables the native expanded-bag preference so individual slots remain available inside the gate; `/zeg off` restores your original preference.

The micro menu is centered between the EXP strips and the action bars. Its usual scale is retained where it fits; a very narrow triangle HUD can reduce that scale to keep the menu within the HUD width. The lowest action row moves up enough to reserve the menu's actual height and borders, including space for a second tracking strip. **Menu: corner** returns it to the lower right. Existing manually saved menu positions are retained; choosing **Menu: center** clears that menu position and docks it. Bags, menus, and stances remain separately movable.

The HUD includes a slim **EXP strip beneath the action bars**, matching **bag and micro-menu panels** in the lower-right corner, and clearer **one-pixel borders** around action rows, spell buttons, cast bars, and utility panels. Rested EXP uses a blue fill; normal EXP uses a muted violet fill. The EXP, bags, and menu sections have their own movement handles and switches.

**Version 0.3.4 adds optional alternating triangle action buttons and fixes escaping EXP divider artwork.** Select **Triangles** in `/zeg`, or use `/zeg shape triangles`. Up/down triangles fit closer together; at button size 48 the row becomes 334 pixels wide instead of 642, before HUD scaling. The EXP strip follows that width. Squares remain the default, and `/zeg shape square` restores them. Bar count, spell slots, keybindings, colors, and saved positions are preserved.

**Click the center of a triangle.** WoW buttons have rectangular hit regions; each triangle uses a separate narrow center column so overlapping button frames cannot select a neighbor. Tips and outer corners are outside that button's click column. Native actions, drag/drop, hover art, cooldown timing, and countdown numbers remain in use. Hover/press/flash textures are masked, and cooldown swipes use the matching triangle; radial edge flares and completion bling are suppressed while triangles are enabled. Square mode restores full hit regions and original edge/bling flags.

The EXP divider fix applies alpha immediately after Blizzard releases/reacquires its divider pool, including in combat. Newly created dividers cannot remain visible off to the right while an out-of-combat layout pass is pending. This change only suppresses stock border/divider artwork; native EXP, rested progress, tooltips, and tracking visibility remain in use.

The fixed visible anchors introduced in 0.3.3 remain: native action buttons anchor to independent row frames, and native EXP/tracking bars anchor to fixed tracking slots. Their scale does not follow a native hierarchy that moves or rescales. Both keep their original parents and native behavior. Borders and movement handles use those same fixed frames. Saved positions and appearance preferences are preserved.

The private character Edit Mode layout still records the preset's positions and non-default-position flags, preserving your original layout. Borders still use engine-anchored textures. Player/target/focus casts retain the independent presentations and original native parents introduced in 0.3.2.

Native action-bar settings remain Always visible with twelve slots and empty slots shown. The custom presentation can wrap those slots into multiple lines. Changing the bar count saves a complete native toggle mask and reloads after the server confirms it, outside combat and Edit Mode.

The appearance editor remains available: frame width/height, separate health and mana/power heights, RGB/hex colors with transparency, class-colored health, automatic power-type colors, and portrait visibility for player, target, pet, focus, and party frames.

This is an early installable test build. Syntax and simulated-client checks passed; it has **not been run inside WoW**. Visual alignment, combat clicks, bar paging, vehicle states, and each class's resources still need real-client testing. The generated picture is a design reference, not a screenshot of the working addon.

## Install

1. Close WoW completely.
2. Extract the ZIP into the **Interface/AddOns** directory belonging to your **WoW Forever** installation.
3. Check that the path is **Interface/AddOns/CleanCenterUI/CleanCenterUI.toc**, with no extra nested CleanCenterUI folder.
4. For the first test, disable other addons that move or replace action bars, unit frames, chat, or the minimap.
5. Launch WoW, enable **ZeG UI** on the character-selection AddOns screen, and log in. The two-bar preset applies automatically.

To update from an earlier build, replace the existing **CleanCenterUI** addon folder with this version while WoW is closed. Keep your saved variables: existing bar counts, sizes, colors, section switches, and panel positions carry over. Restart the client so native UI state contaminated by an earlier build is discarded. Initial bar configuration may reload the interface once.

The target is Forever interface **16001**, using the modern Blizzard UI. The reviewed source snapshot was **1.60.1.70124**. This package deliberately declines to apply on Retail or older Classic clients.

## Customize

Type **/zeg** to open the settings window.

- **Visible action bars:** 1–8. Existing spell slots and keybindings are retained; additional rows expose the corresponding built-in bars.
- **HUD size**, **button size**, and **panel opacity**.
- **Button shape:** Squares or alternating up/down Triangles. Triangles use closer spacing and narrower center click areas; switch shapes outside combat or let a saved change apply after combat.
- **Stances:** independent Squares/Triangles switch, active-stance accent outline, and a movement handle. Classes with no native forms keep the row hidden.
- **Bags:** Hover shows one backpack and reveals the other bags on mouseover; Full shows every bag. Native bag actions and item dragging are retained.
- **Menu:** Center places the micro menu above EXP and reserves a gap below the action bars; Corner moves it to the lower right. Selecting a menu mode replaces a manually saved menu position.
- **Minimap settings:** square map, 120–360 size entry and plus/minus controls, Move minimap, and Reset minimap. Reset affects only the minimap size/position.
- **Cooldown numbers:** enable/disable numeric ability countdowns inside the icons.
- **Flight / vehicle exit:** themed square button to the left of the top action row; drag its handle under Unlock panels for a separate saved position.
- **Appearance** opens the frame editor. Choose Player, Target, Pet, Focus, or Party. Party changes apply to all five custom party frames.
- Enter **frame width/height**, **health height**, or **mana/power height** and press Enter, or use the plus/minus buttons. Total frame height resizes health while retaining power height; changing a bar height resizes its frame to fit.
- **Class-colored health** switches class coloring on/off for the selected frame. With it on, NPCs use reaction colors when available. Choosing a **custom health color** turns class/reaction coloring off. **Power type colors** works similarly: mana/rage/energy can use game colors or any custom color.
- Color swatches open the native color picker, including RGB/hex entry and transparency. Changes preview outside combat; **Cancel** restores the previous color and automatic-color mode.
- **Portrait / player icon** hides or shows the portrait. Hiding it expands the bars into its space.
- **HUD color scheme** offers independent colors for panels, borders, text, highlights, empty bars, normal EXP, and rested EXP. **Reset this frame** and **Reset HUD colors** restore their respective appearance defaults.
- Switch action bars, unit frames, party frames, cast bars, chat, minimap, quest placement, EXP styling, bag styling, or micro-menu styling individually. Switching a section reloads the interface; a disabled section uses the stock UI.
- **Bar borders** switches the added borders on or off without reloading. It applies to action rows/buttons, cast bars/icons, EXP/tracking strips, bags, and the micro menu.
- **Unlock panels**, click a health or mana/power bar to open its appearance controls, and drag the name area to move a unit frame. Then **Lock panels**. Positions are saved for that character. Unit frames can be placed while their units are absent; extra action bars are only shown in edit mode if selected.
- **Reset layout** restores the two-bar layout, sizes, opacity, and automatic positions. It preserves frame appearance settings and spells.

Direct commands:

| Command | Effect |
| --- | --- |
| `/zeg appearance` | Open player frame appearance |
| `/zeg appearance target` | Edit target; also accepts pet, focus, and party |
| `/zeg colors` | Open the appearance and HUD color editor |
| `/zeg bars 1` | One visible action bar |
| `/zeg bars 2` | Two visible action bars |
| `/zeg bars 3` | Three visible action bars |
| `/zeg bars 8` | All eight built-in bars |
| `/zeg shape triangles` | Compact alternating up/down triangle buttons |
| `/zeg shape square` | Square buttons and full click areas |
| `/zeg stance triangles` / `/zeg stance square` | Change stance/form shape independently |
| `/zeg bags hover` / `/zeg bags full` | Compact expanding bags / always-visible bags |
| `/zeg menu center` / `/zeg menu corner` | Dock the micro menu above EXP / move it to the corner |
| `/zeg minimap` | Open square minimap controls |
| `/zeg minimap 240` | Set minimap size; accepts 120–360 HUD pixels |
| `/zeg minimap reset` | Reset only minimap size and position |
| `/zeg cooldowns on` / `/zeg cooldowns off` | Show/hide numeric ability cooldowns |
| `/zeg meters` | Open built-in damage meter skin controls |
| `/zeg unlock` / `/zeg lock` | Move panels / finish moving |
| `/zeg scale 0.9` | Smaller HUD |
| `/zeg opacity 0.7` | More transparent panels |
| `/zeg borders off` / `/zeg borders on` | Hide / show the added bar and utility borders |
| `/zeg reset` | Restore preset layout |
| `/zeg off` / `/zeg on` | Turn the preset off / on and reload |
| `/zeg info` | Print client/build and setup diagnostics |
| `/zeg taint` | Print sampled native security metadata and the stage where taint was first observed |

Bar count, geometry, colors, portrait visibility, and opacity changes requested during combat are saved and applied after combat. Bar-count changes reload the interface after native preferences sync. Click-to-edit overlays hide automatically when combat starts. Layout changes also wait until Blizzard Edit Mode has closed; use `/zeg unlock` to move this preset. Unlocking, switching sections, and turning the preset off require being out of combat.

## First in-game check

For 0.4.2, confirm buffs return to a compact size after login, then use `/zeg auras` to try sizes 24, 27 and 30. Check both buffs and debuffs, duration/count text, tooltips and right-click cancellation. Change size during combat and Edit Mode, then confirm it applies after each ends. Reload and confirm your size and positions persist. These checks still require a live client.

For 0.4.1, open the built-in damage meter and `/zeg meters`. Check damage and healing views, native class colors, accent/custom colors and font sizes. Enter combat, change sessions, scroll rows and open a spell breakdown; confirm values, bar fill and native clicks still work. Minimize/restore, move/resize the windows and try extra windows. Turn the skin off and on, use Edit Mode, and reload to check saved appearance. These checks require a live client; the packaged validation uses a simulator.

Start on one character, target an NPC, and open **/zeg**. Check the one-, two-, and three-bar options. Cast a spell by clicking and by keybind, change the main bar's page, and try any class stance or pet actions. Join a party to check the left-side frames. Gain EXP, hover the EXP strip, and check rested EXP after resting. Open your bags and several micro-menu buttons, then try dragging an item onto a bag button. Move the EXP, bags, and menu with **Unlock panels**. Test a short fight, then reload and confirm the chosen layout persists.

For this update, resize and move the minimap at HUD scales 1 and 0.8; try addon-icon clicks, tooltips and dragging at each edge/corner. Change zones, toggle minimap rotation, enter/leave combat, use Edit Mode, and reload. Confirm the map stays square, the saved position persists, and map/clock/zoom input works. Have a party member disconnect and reconnect, including during combat, and try a thin health bar. Use an ability with a cooldown and charges; check countdown numbers, completion, both icon shapes, and the on/off toggle. Continue checking EXP pips, casts/channels, bag hovering, menu spacing, stance selection, paging, vehicles, and pets. Run **/zeg taint** if an error recurs and include its output with the error text. These live checks are needed to confirm rendering, input, and taint behavior.

A screenshot and the output of **/zeg info** are useful feedback. If there is a Lua error, include its full text. To return to your stock layout, leave combat and run **/zeg off** before disabling the addon.

## Scope of this first pass

- Original player, target, pet, focus, and five-person party frame styling.
- Existing Blizzard action buttons are restyled and anchored to fixed row frames while keeping their native button/container/bar parent chain. Native frame position changes cannot carry their visible buttons away. Native parent clipping, temporary attachments, vehicle states, and class-specific behavior still require live testing. Fixed cast displays mirror native status-bar range/value, text, icon, RGB, whole-frame alpha, and visibility without reading secret cast times in Lua. Their fill opacity is independent of the deliberately masked stock fill. Native casting code and original cast-bar parents remain in use; detailed native stage effects are not reproduced by the minimal displays.
- Native buff icons, minimap, quest tracker, menus, bags buttons, and chat remain interactive.
- Built-in damage meters retain their native parents, geometry, scripts, resizing, session choices, combat calculations, numeric formatting and class-color decisions. The skin only styles public widgets; it never reads combat sources, pooled data providers, secret amounts/text or native dimensions. It forwards native bar colors without interpreting restricted values.
- The EXP section restyles the native tracking-bar manager, preserving EXP updates, hover text/tooltips, rested progress, and level-cap visibility. Stock container borders and divider/pip textures are masked after native divider updates and on every tracking presentation tick; this cosmetic check does not reposition native frames or read their dimensions. Blizzard can show a second tracking strip for its other active tracking bars. This addon does not replace or duplicate the EXP calculation.
- Bag and micro-menu panels preserve their original buttons, clicks, and drag/drop. Compact bags use explicitly protected parent hover/visibility gates and native expanded slots, with mouse motion propagated from the real bag buttons and no native tooltip-script wrappers. Only protected headers are registered for auto-hide. Full mode restores the original bag parents. The micro menu retains its native parent chain and event handling. These sections can be styled independently of the action bars.
- Blizzard raid frames, bags windows, quest windows, nameplates, and other menus retain their standard appearance.
- The four sample ability indicators above the bar in the concept image are not implemented as a separate tracker in this build.
- Spell art, portraits, names, health, mana, and quests come from your character, so they vary from the mockup.
- Original stock action-bar toggles, active Edit Mode layout, and chat geometry are retained for restoration. **/zeg off** restores them before reloading. Logging out preserves the preset's native profile; turn the preset off before disabling the addon through the AddOns screen. The separate ZeG UI layout remains available for reuse. If the original layout was deleted or renamed, the addon cannot automatically select it.
- A free character Edit Mode layout slot is needed. If all character slots are full or the required native APIs are unavailable, the addon retains stock bar behavior and reports this through **/zeg info**. With the gamepad interface active, Blizzard continues to manage its own bars.

## Development and validation

The package contains original Lua source, four original triangle textures, and simulated-client checks. Run `python3 tests/run_checks.py` with a Lua 5.3/5.4 shared library available. The addon code uses Lua 5.1-compatible syntax; the development runner uses a modern Lua library. `tests/generate_shapes.py` regenerates the exact uncompressed 32-bit TGA assets using Pillow; Pillow is not needed to install or use the addon.

Reference: Blizzard UI source mirrored at https://github.com/Gethe/wow-ui-source/tree/forever — especially the action-bar, secure-template, settings, unit API, and casting-bar files. Blizzard code is not included in this package.

## Native UI integration

Native Edit Mode wraps positioning/scaling and visibility methods with Lua that writes shared state. CleanCenterUI uses original widget Base methods for geometry, configures a private layout copy through C_EditMode, and sets action-bar toggles through one bulk C API call. It never assigns native action-bar layout/visibility fields or calls Settings.SetValue, MultiActionBar_Update, SetShowGrid, or forced button Show during reflow. Blizzard initializes button visibility, paging, and combat visibility after the configuration reload. Reflow waits until combat and Edit Mode end. The addon does not patch Blizzard health-color functions, gamepad flyout handlers, aura maps, or secret-value comparisons. Panel rendering uses anchored solid textures without BackdropTemplate, native width/height arithmetic, or changes to Blizzard backdrop code. The simulator reproduces default managed-frame combat movement, injects an additional native move/rescale even with non-default saved positions, verifies physical screen rectangles at two HUD scales, and covers and the target OnShow parent contract, and forwards secret cast values into independent displays. It checks these integration boundaries; it does not implement WoW's taint engine and cannot prove the reported live errors are gone.


### Blizzard trackers (0.4.6 test build)
Open `/zeg trackers`. Click **Enable Blizzard tracking**, or opt into **Enable tracking on login**. If the status says unavailable, this client/character does not expose the required native manager; report `/zeg info` and the tracker status.

Use **Choose spells in Blizzard** to select supported spells (fallback: WoW Options > Cooldown Manager). CCUI styles the actual Blizzard frames; there is no duplicated tracker and no need to hide its parent. The four native groups remain Essential, Utility, Buff icons and Buff bars.

Enable the desired group skins and optional backgrounds. **Move group** unlocks CCUI movers; drag a tracker and use `/zeg lock` afterwards. Reset group positions restores the initial native placement. Skin toggles return a group to its native visuals; spell visibility, icon sizes and layout within groups remain Blizzard settings. Profiles include group positions and tracker preferences.

Live check: enable tracking; select a cooldown/buff; move the group; cast and verify timer/stack/glow behavior in combat; change settings during combat and verify deferred application; reload and switch spec; toggle skin off and verify native presentation. This build has not been run in WoW. No multi-enemy DoT tracker or Power Auras trigger engine is included.


### ZeG UI branding and launcher (0.4.6)
Use `/zeg` to open settings and `/zeg trackers` for cooldown groups. `/ccui` remains a compatibility alias. The ZeG minimap button opens Settings on left-click and Trackers on right-click.
The existing CleanCenterUI installation folder, TOC filename and saved-variable names are retained to preserve existing character layouts during this branding update. Replace the old folder with the included folder; do not install a second copy alongside it.


### Guided setup (0.4.8)
Run `/zeg setup`, or select **Guided tracker setup** in `/zeg trackers`.
1. Choose one of Blizzard's four native groups.
2. Preview and choose group scale, text size and background.
3. Enable tracking and choose spells/visibility/available alerts in Blizzard's editor.
4. Save style and unlock placement; `/zeg lock` finishes movement.
Draft changes stay local to the wizard until Save. Repeat for other groups. This assistant does not automatically select spells or create a new tracking engine. Sounds, popup-style native alerts and active visibility are available only where Blizzard's editor exposes them; custom fades/popups are not included.


### Group display skins (0.4.9)
Run `/zeg setup`, choose a group and proceed to its preview. Cycle **Skin** through framed, minimal, round and tiles. Adjust scale, timer/text size, group background and its opacity. Icon groups also offer a countdown visibility toggle when supported by the native widget. Save to apply; repeat for other groups.
Buff bars use flat native-color fills in minimal mode or HUD accent fills in other modes. Round mode rounds the bar's spell icon. Disable a group skin to restore original masks, fills and timer visibility. These options style existing native viewers; orientation/spacing remain in Blizzard Edit Mode, and spells stay in the native group selected in Blizzard's editor.


### Hide or dim cooldown displays (0.4.10)
In `/zeg setup`, select Essential or Utility, go to the preview and cycle **Always show** to **Dim during countdown** or **Hide during countdown**, then Save. The mode tracks the native cooldown widget's display rather than calculating spell readiness. Native active-buff, GCD or charge-recharge timers can also hide an icon. Choose **Fixed slots** or **Compact outside combat**. Compaction closes gaps only outside combat when native state and geometry are readable; combat layout freezes. The group background is suppressed so it does not leave an empty box. Unlocking restores icons for placement. Native buff-icon/bar groups keep their own visibility behavior.


### Direct settings and sliders (0.4.12)
`/zeg` or minimap left-click opens the organized settings menu. Choose **Cooldown tracker > Edit groups**, select Essential, Utility, Buff icons or Buff bars, and change its appearance directly. Sliders control scale (25–250%) and background opacity; skin, text, visibility, slot behavior and timer controls are alongside them. Move/reset the selected group from the same panel. Changes save automatically and protected layout changes wait until combat ends.
**Manager settings** contains enabling, automatic startup, global background and default text controls, plus Blizzard spell selection. **Optional guided setup** remains available but is not required. Overview provides HUD scale and opacity sliders and links to unit-frame, minimap and module settings.
This version also caches tooltip styling and reduces recurring reflow/skin work to address hover FPS drops. In-game performance is not measured by the simulator.


### Layout patterns and octagons (0.4.13)
**Cooldown tracker > Edit groups**: choose the group, select Octagons under Skin, and choose Arrangement: Blizzard, Horizontal, Vertical, Grid cluster or Radial wheel. Move it with Move group or Positions. Timer bars support rows/columns; radial is reserved for icon groups. Layout changes wait until outside combat; Blizzard may update native aura layouts in combat.
**Action bars**: select a bar, choose Shape and Layout independently. Vertical is one column; Grid cluster uses up to four columns; Horizontal wraps using Buttons per line. Radial displays all 12 native action slots in a wheel with non-overlapping rectangular click regions. This is not a true pie-slice menu. Octagons create diamond gaps when tiled in a grid.
This build removes broad animation masking associated with the reported triangle hover regression. Hover art is a pre-shaped texture; the native completion/proc flair is no longer clipped to a triangle. Live FPS confirmation remains necessary.


**Action-bar finishing:** select Thin, Soft, Bold or None under Border. Soft is the default for new border preferences and uses a wider blurred stroke. Set Hotkey labels to Inside icons to remove the below-icon label strip and shrink the bar background; Below icons restores the original spacing. These settings are independent per bar and included in profiles.


### Compact menus and free placement (0.4.14)
`/zeg` opens a smaller scrollable menu. The current section is marked with an accent stripe and breadcrumb. Unlock/Lock frames remains in the fixed header; Snap can also be toggled there. The setup wizard uses a shorter scrollable body, with preview scaling anchored to its own holder to avoid overlapping controls.
On first use of this version, snapping and dense grid guides are disabled. Re-enable them in Positions if wanted. Optional snapping only nudges a coordinate within two units of a grid line; hold Alt when dropping a panel for exact free placement. Existing saved positions are kept.
The minimap launcher is smaller and independent of map scale.
