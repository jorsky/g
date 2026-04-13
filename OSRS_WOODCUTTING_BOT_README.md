# OSRS Woodcutting Bot (AutoHotKey)

An AutoHotKey bot for woodcutting in Old School RuneScape. Supports multiple tree types, automatic log dropping (power-chopping), and anti-ban measures.

## Requirements

- Windows OS
- [AutoHotKey v1.1+](https://www.autohotkey.com/) installed
- Old School RuneScape client in **Fixed** mode

## Quick Start

1. Install AutoHotKey v1.1 from https://www.autohotkey.com/
2. Open OSRS and log in to your account
3. Set your client to **Fixed** mode (not Resizable)
4. Open your inventory tab
5. Equip your axe (or keep it in inventory slot 1)
6. Stand next to the trees you want to chop
7. Double-click `osrs_woodcutting_bot.ahk` to run the script
8. Press **F1** to start the bot

## Controls

| Key | Action |
|-----|--------|
| F1  | Start / Pause the bot |
| F2  | Stop the bot and exit |

## Configuration

Open `osrs_woodcutting_bot.ahk` in a text editor and modify the settings at the top:

### Tree Type
```ahk
TreeType := "willow"
```
Options: `"normal"`, `"oak"`, `"willow"`, `"maple"`, `"yew"`, `"magic"`

### Drop Mode
```ahk
DropLogs := true
```
- `true` — Power-chop mode: automatically shift-drops all logs when inventory is full
- `false` — Pauses when inventory is full (bank manually)

### Axe Location
```ahk
AxeInInventory := false
```
- `false` — Axe is equipped (28 inventory slots available)
- `true` — Axe is in inventory slot 1 (27 slots available, slot 1 is skipped during dropping)

### Anti-Ban
```ahk
AntiBanEnabled := true
AntiBanIntervalMin := 2
AntiBanIntervalMax := 5
```
Anti-ban actions include: random camera rotation, mouse wandering, idle pauses, opening random tabs, hovering inventory slots, and camera pitch adjustments.

## Tree Color Tuning

If the bot can't find trees, you may need to adjust the trunk colors for your display. Use AHK's `Window Spy` tool (included with AutoHotKey) to find the color of the tree trunk:

1. Run Window Spy from the AutoHotKey folder
2. Hover over a tree trunk in OSRS
3. Note the hex color value
4. Update the corresponding entry in the `TreeProfiles` section

## Features

- **Multi-tree support** — Pre-configured color profiles for 6 tree types
- **Power-chopping** — Automatic shift-click dropping of logs
- **Human-like mouse movement** — Curved, variable-speed mouse paths
- **Randomized timing** — Click delays and wait times are randomized
- **Anti-ban system** — Periodic random actions (camera moves, idle pauses, tab switching)
- **Pause/Resume** — Toggle the bot on and off without restarting

## Disclaimer

Using bots in Old School RuneScape is against Jagex's Terms of Service and may result in a ban. Use at your own risk.
