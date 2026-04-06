# BreakSync

Break timer bar for World of Warcraft (Retail, Patch 12.0.0+). Shows a centered on-screen timer bar when a break is called — even if you don't have DBM or BigWigs installed. Syncs with both.

## Features

- **Standalone bar** — no DBM or BigWigs required. Works for solo players or groups.
- **DBM sync** — listens for break timers broadcast over the `D5` addon message protocol (`BT` command).
- **BigWigs sync** — hooks `BigWigs_StartBreak` / `BigWigs_StopBreak` callbacks via `BigWigsLoader` if BigWigs is installed.
- **Broadcasts to group** — `/bs break` sends the `D5/BT` message so DBM and BigWigs users in your group also see their own bars.
- **Draggable** — drag the bar anywhere; position is saved per-character.

## Source files

- **src/config.lua** — `BreakSyncDB` SavedVariables, defaults (bar size, position, debug).
- **src/utils.lua** — `BS.Debug(...)`.
- **src/bar.lua** — the break timer `StatusBar`: countdown, icon, sender name, drag-to-move.
- **src/comms.lua** — `CHAT_MSG_ADDON` listener for the `D5` prefix; optional `BigWigsLoader` message hooks.
- **src/options.lua** — Settings panel: debug toggle, test/stop bar buttons, Reset to Defaults.
- **src/commands.lua** — slash commands (see below).
- **BreakSync.lua** — entry point: wires up all modules on `ADDON_LOADED`.

## Commands

| Command | Action |
|---------|--------|
| `/bs break <minutes>` | Start a break timer (1–60 min). Broadcasts to group. |
| `/bs stop` | Cancel the active break timer. Broadcasts cancel to group. |
| `/bs test` | Show a 5-minute test bar (local only). |
| `/bs debug` | Toggle debug output. |
| `/bs reset` | Reset all settings to defaults and reload UI. |

Options panel: **Settings → AddOns → BreakSync**.

## Compatibility

| Addon | Behaviour |
|-------|-----------|
| Neither | Standalone. Use `/bs break` to start timers locally or broadcast to the group. |
| BigWigs only | Break timers started by BigWigs users appear on your bar automatically. |
| DBM only | Break timers started by DBM users appear on your bar automatically. |
| Both | Works with whichever the raid leader uses. |

## References

See **`references/`** for the BigWigs and DBM source files used to reverse-engineer the break timer protocol. Those files are not loaded by the addon.
