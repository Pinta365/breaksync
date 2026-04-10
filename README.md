# BreakSync

Break timer bar for World of Warcraft (Retail, Patch 12.0.0+). Shows a centered on-screen timer bar when a break is called — even if you don't have DBM or BigWigs installed. Syncs with both.

## Download

* [Wago Addons](https://addons.wago.io/addons/breaksync)
* [CurseForge](https://www.curseforge.com/wow/addons/breaksync)

## Features

- **Standalone bar** — no DBM or BigWigs required. Works for solo players or groups.
- **DBM sync** — listens for break timers broadcast over the `D5` addon message protocol (`BT` command).
- **BigWigs sync** — hooks `BigWigs_StartBreak` / `BigWigs_StopBreak` callbacks via `BigWigsLoader` if BigWigs is installed.
- **Broadcasts to group** — `/bs break` sends the `D5/BT` message so DBM and BigWigs users in your group also see their own bars.
- **Persists across reloads and alt-swaps** — active break timers survive a `/reload` or logging to an alt. The bar resumes with the correct time remaining automatically. Matches BigWigs and DBM behaviour.
- **Draggable** — drag the bar anywhere; position is saved.
- **Customisable appearance** — adjust width, height, font size, colour, opacity and icon visibility from the options panel. Style presets for BreakSync, BigWigs, and DBM looks.

## Source files

- **src/config.lua** — `BreakSyncDB` SavedVariables, defaults, style preset definitions.
- **src/utils.lua** — `BS.Debug(...)`.
- **src/bar.lua** — the break timer `StatusBar`: countdown, icon, sender name, drag-to-move, `BS.RefreshBarAppearance()`.
- **src/comms.lua** — `CHAT_MSG_ADDON` listener for the `D5` prefix; optional `BigWigsLoader` message hooks.
- **src/options.lua** — Settings panel: appearance controls, style presets, debug toggle, test/stop buttons, Reset to Defaults.
- **src/commands.lua** — slash commands (see below).
- **BreakSync.lua** — entry point: wires up all modules on `ADDON_LOADED`, resumes saved break timer on `PLAYER_ENTERING_WORLD`.

## Commands

| Command | Action |
|---------|--------|
| `/bs break <minutes>` | Start a break timer (1–60 min). Broadcasts to group. |
| `/bs stop` | Cancel the active break timer. Broadcasts cancel to group. |
| `/bs test` | Show a 5-minute test bar (local only, not saved). |
| `/bs debug` | Toggle debug output. |
| `/bs reset` | Reset all settings to defaults and reload UI. |

Options panel: **Settings → AddOns → BreakSync**.

## Appearance options

All settings are live — no reload required.

| Setting | Range | Default |
|---------|-------|---------|
| Bar Width | 150–700 px | 420 px |
| Bar Height | 14–60 px | 30 px |
| Font Size | 10–22 pt | 14 pt |
| Background Opacity | 0–100% | 85% |
| Bar Color | color picker | green |
| Show Icon | on/off | on |

**Style presets:**

| Preset | Width | Height | Font | Colour |
|--------|-------|--------|------|--------|
| BreakSync | 420 px | 30 px | 14 pt | Green |
| BigWigs | 180 px | 18 px | 10 pt | Blue/purple |
| DBM | 183 px | 20 px | 13 pt | Green |

## Compatibility

| Addon | Behaviour |
|-------|-----------|
| Neither | Standalone. Use `/bs break` to start timers locally or broadcast to the group. |
| BigWigs only | Break timers started by BigWigs users appear on your bar automatically. |
| DBM only | Break timers started by DBM users appear on your bar automatically. |
| Both | Works with whichever the raid leader uses. |
