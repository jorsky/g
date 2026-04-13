; =============================================================================
; OSRS 3-Tick Teak Woodcutting Bot - AutoHotKey v1.1+
; =============================================================================
; 3-tick manipulation woodcutting for maximum teak XP/hr.
;
; How 3T teaks work:
;   - OSRS runs on 0.6s game ticks (600ms per tick)
;   - Normal woodcutting rolls every 4 ticks (2.4s)
;   - By starting a 3-tick action (e.g. guam + swamp tar) and clicking the
;     tree on tick 2, you force a chop roll every 3 ticks (1.8s) instead
;   - This is ~33% faster XP than AFK chopping
;
; The cycle (every 1800ms / 3 ticks):
;   Tick 1: Use herb on tar (starts a 3-tick action)
;   Tick 2: Click the teak tree (interrupts into woodcutting)
;   Tick 3: Chop roll happens — you either get a log or don't
;   Repeat
;
; Setup:
;   1. OSRS client in Fixed mode
;   2. Equip your best axe
;   3. Inventory layout (configure slot positions below):
;      - Slot 1: Guam leaf (or any clean herb)
;      - Slot 2: Swamp tar
;      - Remaining slots: empty (will fill with teak logs)
;   4. Stand directly next to a teak tree
;   5. Zoom camera so the teak trunk is clearly visible in viewport
;   6. Run script, press F1 to start
;
; Alternative tick manip methods (change TickManipMethod below):
;   "herb_tar"   — Guam leaf + Swamp tar (most common)
;   "knife_logs" — Knife + Teak logs (need logs already)
;   "pestle_herb" — Pestle and mortar + herb (herblore secondaries)
;
; Controls:
;   F1 — Start / Pause
;   F2 — Stop and exit
;   F3 — Recalibrate: click the teak tree to set its position
; =============================================================================

#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
SetKeyDelay, -1
SetMouseDelay, -1

; ========================== CONFIGURATION ====================================

; Tick manipulation method
TickManipMethod := "herb_tar"

; Inventory slot positions for tick-manip items (Fixed mode coords)
; Slot 1 = first item (herb/knife/pestle), Slot 2 = second item (tar/logs/herb)
; These are center coords of inventory slots in Fixed mode client at top-left
InvStartX := 563
InvStartY := 213
InvSlotW  := 42
InvSlotH  := 36
InvCols   := 4
InvRows   := 7

; Tick manip item slot positions (slot numbers, 1-indexed, row-major)
ManipSlot1 := 1    ; herb / knife / pestle
ManipSlot2 := 2    ; tar / logs / herb

; Should the bot drop teak logs? (power-chop mode)
DropLogs := true

; Teak trunk color detection
TeakTrunkColor := 0x5A4020
TeakColorTolerance := 30

; Teak tree location — set manually or use F3 to calibrate
; 0,0 means "auto-detect via color search"
TeakTreeX := 0
TeakTreeY := 0

; Search area for teak tree (game viewport, Fixed mode)
SearchX1 := 5
SearchY1 := 5
SearchX2 := 515
SearchY2 := 340

; ========================== TIMING ===========================================
; 1 game tick = 600ms
; 3-tick cycle = 1800ms
;
; The timing here accounts for input lag, click processing, and AHK overhead.
; You may need to tune these by +/- 50ms depending on your ping and system.

GameTick := 600
ThreeTickCycle := GameTick * 3  ; 1800ms

; Delay after clicking herb on tar before clicking tree
; This should land on tick 2 of the 3-tick action
; ~600ms after the first click (1 tick later)
TickManipToTreeDelay := 580

; Delay after clicking tree before starting next cycle
; This fills the remaining time in the 3-tick window
PostTreeClickDelay := 1050

; Small random jitter range (+/- ms) added to each timing
; Keeps inputs from being perfectly robotic
TimingJitter := 40

; ========================== ANTI-BAN =========================================

AntiBanEnabled := true
AntiBanIntervalMin := 3   ; minutes
AntiBanIntervalMax := 7

; ========================== STATE ============================================

BotRunning := false
BotActive := false
LastAntiBan := A_TickCount
CycleCount := 0
LogsChopped := 0
StartTime := 0

; Teak log color in inventory (for dropping and counting)
TeakLogColor := 0x6B5A3A
TeakLogColorTol := 25

; ========================== HOTKEYS ==========================================

F1::ToggleBot()
F2::StopBot()
F3::CalibrateTree()

; ========================== COORDINATE HELPERS ===============================

GetSlotX(slotNum) {
    global InvStartX, InvSlotW, InvCols
    col := Mod(slotNum - 1, InvCols)
    return InvStartX + (col * InvSlotW)
}

GetSlotY(slotNum) {
    global InvStartY, InvSlotH, InvCols
    row := Floor((slotNum - 1) / InvCols)
    return InvStartY + (row * InvSlotH)
}

; ========================== MAIN FUNCTIONS ===================================

ToggleBot() {
    global BotRunning, BotActive, StartTime, CycleCount, LogsChopped
    if (BotActive) {
        BotRunning := !BotRunning
        if (BotRunning) {
            ToolTip, 3T Teaks RESUMED, 10, 50
            SetTimer, RemoveToolTip, -2000
            GoSub, MainLoop3T
        } else {
            elapsed := Round((A_TickCount - StartTime) / 60000, 1)
            ToolTip, PAUSED | %CycleCount% cycles | %elapsed% min (F1 to resume), 10, 50
        }
    } else {
        BotActive := true
        BotRunning := true
        StartTime := A_TickCount
        CycleCount := 0
        LogsChopped := 0
        ToolTip, 3T Teaks STARTED, 10, 50
        SetTimer, RemoveToolTip, -2000
        GoSub, MainLoop3T
    }
}

StopBot() {
    global CycleCount, StartTime, LogsChopped
    elapsed := Round((A_TickCount - StartTime) / 60000, 1)
    ToolTip, STOPPED | %CycleCount% cycles | ~%LogsChopped% logs | %elapsed% min, 10, 50
    Sleep, 2000
    ExitApp
}

CalibrateTree() {
    global TeakTreeX, TeakTreeY
    ToolTip, Click on the teak tree trunk to set its position..., 10, 50
    KeyWait, LButton, D
    MouseGetPos, TeakTreeX, TeakTreeY
    ToolTip, Tree position set: %TeakTreeX%x %TeakTreeY%, 10, 50
    SetTimer, RemoveToolTip, -3000
}

; ========================== MAIN 3-TICK LOOP =================================

MainLoop3T:
    while (BotRunning) {
        ; Check inventory before each cycle
        if (IsInventoryFull3T()) {
            if (DropLogs) {
                DropTeakLogs()
            } else {
                ToolTip, Inventory full! Pausing..., 10, 50
                BotRunning := false
                break
            }
        }

        ; Find the tree if we don't have a fixed position
        if (TeakTreeX = 0 || TeakTreeY = 0) {
            if (!FindTeakTree()) {
                ToolTip, Can't find teak tree! Use F3 to calibrate, 10, 50
                RandomSleep(1500, 2500)
                continue
            }
        }

        ; Execute one 3-tick cycle
        Execute3TickCycle()

        CycleCount++

        ; Update status every 10 cycles
        if (Mod(CycleCount, 10) = 0) {
            UpdateStatus()
        }

        ; Anti-ban check
        if (AntiBanEnabled) {
            CheckAntiBan3T()
        }
    }
return

; ========================== 3-TICK CYCLE =====================================

Execute3TickCycle() {
    global ManipSlot1, ManipSlot2, TickManipMethod
    global TickManipToTreeDelay, PostTreeClickDelay, TimingJitter
    global TeakTreeX, TeakTreeY

    ; --- TICK 1: Start the 3-tick action ---
    ; Click item 1 (herb) on item 2 (tar)
    slot1X := GetSlotX(ManipSlot1)
    slot1Y := GetSlotY(ManipSlot1)
    slot2X := GetSlotX(ManipSlot2)
    slot2Y := GetSlotY(ManipSlot2)

    ; Click first item
    FastClick(slot1X, slot1Y)
    ; Tiny delay for the "use" action to register
    Sleep, % 50 + RandomInt(-10, 10)
    ; Click second item (starts 3-tick timer)
    FastClick(slot2X, slot2Y)

    ; --- Wait for TICK 2 ---
    jitter := RandomInt(-TimingJitter, TimingJitter)
    Sleep, % TickManipToTreeDelay + jitter

    ; --- TICK 2: Click the teak tree ---
    ; Add small random offset to tree click
    treeClickX := TeakTreeX + RandomInt(-3, 3)
    treeClickY := TeakTreeY + RandomInt(-3, 3)
    FastClick(treeClickX, treeClickY)

    ; --- Wait for TICK 3 (chop roll) and reset ---
    jitter := RandomInt(-TimingJitter, TimingJitter)
    Sleep, % PostTreeClickDelay + jitter
}

; ========================== TREE DETECTION ===================================

FindTeakTree() {
    global SearchX1, SearchY1, SearchX2, SearchY2
    global TeakTrunkColor, TeakColorTolerance
    global TeakTreeX, TeakTreeY

    PixelSearch, FoundX, FoundY, SearchX1, SearchY1, SearchX2, SearchY2, TeakTrunkColor, TeakColorTolerance, Fast RGB
    if (ErrorLevel = 0) {
        TeakTreeX := FoundX
        TeakTreeY := FoundY
        return true
    }
    return false
}

; ========================== INVENTORY ========================================

IsInventoryFull3T() {
    global InvStartX, InvStartY, InvSlotW, InvSlotH, InvCols
    ; Check slot 28 (last slot) — manip items in slots 1-2, axe equipped
    ; So 26 log slots available (slots 3-28)
    lastRow := Floor(27 / InvCols)   ; slot 28 = index 27
    lastCol := Mod(27, InvCols)
    checkX := InvStartX + (lastCol * InvSlotW)
    checkY := InvStartY + (lastRow * InvSlotH)

    PixelGetColor, slotColor, checkX, checkY, RGB
    bgColor := 0x3E3529
    return (ColorDistance(slotColor, bgColor) > 40)
}

DropTeakLogs() {
    global InvStartX, InvStartY, InvSlotW, InvSlotH, InvCols, InvRows
    global TeakLogColor, TeakLogColorTol, BotRunning, LogsChopped

    ToolTip, Dropping teak logs..., 10, 50

    Send, {Shift down}
    Sleep, 80

    ; Start from slot 3 (skip herb + tar in slots 1-2)
    ; Drop column by column for efficiency
    Loop, %InvCols% {
        col := A_Index - 1
        Loop, %InvRows% {
            if (!BotRunning)
                break 2
            row := A_Index - 1
            slotNum := (row * InvCols) + col + 1

            ; Skip manip item slots
            if (slotNum <= 2)
                continue

            slotX := InvStartX + (col * InvSlotW)
            slotY := InvStartY + (row * InvSlotH)

            PixelGetColor, pixColor, slotX, slotY, RGB
            if (ColorClose(pixColor, TeakLogColor, TeakLogColorTol)) {
                FastClick(slotX, slotY)
                Sleep, % RandomInt(80, 150)
                LogsChopped++
            }
        }
    }

    Send, {Shift up}
    Sleep, 80
    ToolTip, Logs dropped!, 10, 50
    SetTimer, RemoveToolTip, -1500
    RandomSleep(200, 500)
}

; ========================== STATUS DISPLAY ===================================

UpdateStatus() {
    global CycleCount, StartTime, LogsChopped

    elapsed := (A_TickCount - StartTime) / 1000  ; seconds
    if (elapsed < 1)
        elapsed := 1
    elapsedMin := Round(elapsed / 60, 1)

    ; Estimate XP (teak log = 85 xp)
    xpGained := LogsChopped * 85
    xpPerHour := Round((xpGained / elapsed) * 3600)

    ToolTip, 3T Teaks | %CycleCount% cycles | ~%LogsChopped% logs | %elapsedMin%m | ~%xpPerHour% xp/hr, 10, 50
    SetTimer, RemoveToolTip, -5000
}

; ========================== ANTI-BAN =========================================

CheckAntiBan3T() {
    global LastAntiBan, AntiBanIntervalMin, AntiBanIntervalMax

    intervalMs := RandomInt(AntiBanIntervalMin * 60000, AntiBanIntervalMax * 60000)
    if (A_TickCount - LastAntiBan > intervalMs) {
        PerformAntiBan3T()
        LastAntiBan := A_TickCount
    }
}

PerformAntiBan3T() {
    ; 3T-specific anti-ban — keep it brief so we don't lose rhythm
    action := RandomInt(1, 4)

    if (action = 1) {
        ; Quick camera nudge
        direction := RandomInt(0, 1) ? "{Left}" : "{Right}"
        Send, %direction%
        Sleep, % RandomInt(150, 400)
    } else if (action = 2) {
        ; Tiny idle pause (just 1-2 extra ticks)
        Sleep, % RandomInt(600, 1200)
    } else if (action = 3) {
        ; Hover a random inventory slot briefly
        col := RandomInt(0, 3)
        row := RandomInt(0, 6)
        hoverX := GetSlotX(row * 4 + col + 1)
        hoverY := GetSlotY(row * 4 + col + 1)
        MouseMove, %hoverX%, %hoverY%, 5
        Sleep, % RandomInt(200, 600)
    } else if (action = 4) {
        ; Slight mouse jitter near current position
        MouseGetPos, mx, my
        MouseMove, % mx + RandomInt(-15, 15), % my + RandomInt(-15, 15), 3
        Sleep, % RandomInt(100, 300)
        MouseMove, %mx%, %my%, 3
    }
}

; ========================== UTILITY FUNCTIONS ================================

FastClick(x, y) {
    ; Fast click for tick-manipulation — minimal delay
    MouseMove, %x%, %y%, 2
    Sleep, % RandomInt(10, 30)
    Click, %x%, %y%
}

RandomSleep(minMs, maxMs) {
    sleepTime := RandomInt(minMs, maxMs)
    Sleep, %sleepTime%
}

RandomInt(min, max) {
    Random, result, %min%, %max%
    return result
}

ColorDistance(color1, color2) {
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF
    return Sqrt((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2)
}

ColorClose(color1, color2, tolerance) {
    return (ColorDistance(color1, color2) <= tolerance)
}

RemoveToolTip:
    ToolTip
return
