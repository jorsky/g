# OSRS Woodcutting Bot (AutoHotKey)

AutoHotKey bots for woodcutting in Old School RuneScape. Includes two scripts:

1. **`osrs_woodcutting_bot.ahk`** — General woodcutting bot for any tree type (AFK chopping)
2. **`osrs_3t_teaks_bot.ahk`** — 3-tick teak manipulation bot for maximum XP/hr

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

---

# 3-Tick Teak Bot (`osrs_3t_teaks_bot.ahk`)

An advanced bot that performs 3-tick manipulation for teak woodcutting — the fastest woodcutting XP method in OSRS.

## How 3-Tick Teaks Work

OSRS runs on 0.6s game ticks. Normal woodcutting rolls every 4 ticks (2.4s). By starting a 3-tick action (like using a herb on swamp tar) and clicking the tree one tick later, you force a chop roll every 3 ticks (1.8s) — about **33% faster** than normal.

**The cycle (1.8 seconds):**
1. **Tick 1:** Click herb on swamp tar (starts 3-tick timer)
2. **Tick 2:** Click the teak tree (interrupts into woodcutting)
3. **Tick 3:** Chop roll happens — repeat from tick 1

## 3T Setup

1. **Equip** your best axe
2. **Inventory layout:**
   - Slot 1: Guam leaf (or any clean herb)
   - Slot 2: Swamp tar
   - Slots 3-28: Empty (fill with teak logs)
3. Stand next to a teak tree (Ape Atoll, Fossil Island, etc.)
4. Run the script, press **F3** to click the teak tree trunk (calibrates position)
5. Press **F1** to start

## 3T Controls

| Key | Action |
|-----|--------|
| F1  | Start / Pause |
| F2  | Stop and show stats |
| F3  | Calibrate tree position (click the trunk) |

## 3T Configuration

### Tick Manipulation Method
```ahk
TickManipMethod := "herb_tar"
```
Options: `"herb_tar"`, `"knife_logs"`, `"pestle_herb"`

### Timing Tuning
```ahk
TickManipToTreeDelay := 580   ; ms after herb+tar click before tree click
PostTreeClickDelay := 1050    ; ms after tree click before next cycle
TimingJitter := 40            ; +/- random ms added to each delay
```
If your connection has higher ping, increase `TickManipToTreeDelay` by ~20-50ms. If you're getting 4-tick chops instead of 3-tick, the timing is off — adjust these values.

### Inventory Slots
```ahk
ManipSlot1 := 1    ; herb position
ManipSlot2 := 2    ; tar position
```

## 3T Features

- **Tick-perfect cycling** — 1800ms loop matching OSRS 3-tick timing
- **XP/hr tracker** — Live display of cycles, logs, and estimated XP/hr
- **Tree calibration (F3)** — Click the tree once to lock its position
- **Auto-detection fallback** — Color-searches for teak trunks if not calibrated
- **Fast clicking** — Minimal mouse movement delay for tight tick windows
- **Shift-drop** — Drops teak logs automatically, preserving herb + tar
- **Lightweight anti-ban** — Brief camera nudges and mouse jitters that don't break the 3T rhythm

## Expected XP Rates

| Method | Approx XP/hr |
|--------|-------------|
| AFK Teaks (no tick manip) | ~60,000-80,000 |
| 2-Tick Teaks (very advanced) | ~170,000+ |
| **3-Tick Teaks (this bot)** | **~130,000-160,000** |

---

## Disclaimer

Using bots in Old School RuneScape is against Jagex's Terms of Service and may result in a ban. Use at your own risk.
