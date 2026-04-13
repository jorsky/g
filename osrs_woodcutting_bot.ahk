; =============================================================================
; OSRS Woodcutting Bot - AutoHotKey v1.1+
; =============================================================================
; Usage:
;   1. Open Old School RuneScape and log in
;   2. Position your character next to the trees you want to cut
;   3. Run this script
;   4. Press F1 to start/pause the bot
;   5. Press F2 to stop the bot and exit
;
; Setup:
;   - Set your OSRS client to "Fixed" mode (not resizable)
;   - Make sure the inventory is open (press Escape -> inventory tab)
;   - Adjust the tree color and coordinates below if needed
;   - Have an axe equipped or in your inventory
;
; Supported trees (change TreeType below):
;   "normal", "oak", "willow", "maple", "yew", "magic"
; =============================================================================

#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%

; ========================== CONFIGURATION ====================================

; Which tree type to cut
TreeType := "willow"

; Should the bot drop logs? (true = power-chop / drop, false = bank manually)
DropLogs := true

; Inventory full after 28 items — number of free slots at start
; (27 if axe is in inventory, 28 if equipped)
AxeInInventory := false

; Anti-ban: random camera movements and idle pauses
AntiBanEnabled := true

; How often to perform anti-ban actions (in minutes, approximate)
AntiBanIntervalMin := 2
AntiBanIntervalMax := 5

; Click timing randomisation (milliseconds)
ClickDelayMin := 80
ClickDelayMax := 220

; Time to wait for a tree to be chopped (milliseconds) — varies by tree
TreeChopTimeout := 0  ; auto-set per tree type below

; ==========================  TREE PROFILES ===================================

; Each profile: [trunk color, tolerance, avg chop time ms]
; Colors are approximate and may need tuning for your display/brightness
TreeProfiles := {}
TreeProfiles["normal"]  := {color: 0x2D4A1E, tolerance: 25, chopTime: 4000}
TreeProfiles["oak"]     := {color: 0x3B5323, tolerance: 25, chopTime: 6000}
TreeProfiles["willow"]  := {color: 0x4A6B35, tolerance: 30, chopTime: 8000}
TreeProfiles["maple"]   := {color: 0x5C4A1E, tolerance: 25, chopTime: 12000}
TreeProfiles["yew"]     := {color: 0x2B3D1A, tolerance: 25, chopTime: 18000}
TreeProfiles["magic"]   := {color: 0x1E3B5A, tolerance: 30, chopTime: 25000}

; Load the selected tree profile
ActiveProfile := TreeProfiles[TreeType]
TrunkColor := ActiveProfile.color
ColorTolerance := ActiveProfile.tolerance
if (TreeChopTimeout = 0)
    TreeChopTimeout := ActiveProfile.chopTime

; ========================== INVENTORY LAYOUT =================================
; Fixed-mode client inventory slot positions (top-left of each slot)
; Row x Col grid: 4 columns x 7 rows = 28 slots
; These coordinates assume default Fixed mode OSRS client position at top-left

InvStartX := 563   ; X of first inventory slot center
InvStartY := 213   ; Y of first inventory slot center
InvSlotW  := 42    ; horizontal spacing between slot centers
InvSlotH  := 36    ; vertical spacing between slot centers
InvCols   := 4
InvRows   := 7

; ========================== SEARCH AREA ======================================
; Area of the game viewport to scan for trees (Fixed mode)
SearchX1 := 5
SearchY1 := 5
SearchX2 := 515
SearchY2 := 340

; ========================== STATE VARIABLES ==================================

BotRunning := false
BotActive := false
LastAntiBan := A_TickCount
MaxInventorySlots := AxeInInventory ? 27 : 28
LogColor := 0x6B5430      ; approximate log color in inventory
LogColorTol := 30

; ========================== HOTKEYS ==========================================

F1::ToggleBot()
F2::StopBot()

; ========================== MAIN FUNCTIONS ===================================

ToggleBot() {
    global BotRunning, BotActive
    if (BotActive) {
        BotRunning := !BotRunning
        if (BotRunning) {
            ToolTip, Bot RESUMED, 10, 50
            SetTimer, RemoveToolTip, -2000
            GoSub, MainLoop
        } else {
            ToolTip, Bot PAUSED (F1 to resume), 10, 50
            SetTimer, RemoveToolTip, -3000
        }
    } else {
        BotActive := true
        BotRunning := true
        ToolTip, Bot STARTED - cutting %TreeType% trees, 10, 50
        SetTimer, RemoveToolTip, -3000
        GoSub, MainLoop
    }
}

StopBot() {
    ToolTip, Bot STOPPED, 10, 50
    SetTimer, RemoveToolTip, -2000
    Sleep, 500
    ExitApp
}

; ========================== MAIN LOOP ========================================

MainLoop:
    while (BotRunning) {
        ; 1. Check if inventory is full
        if (IsInventoryFull()) {
            if (DropLogs) {
                DropAllLogs()
            } else {
                ToolTip, Inventory full! Pausing... (drop manually or bank), 10, 50
                BotRunning := false
                break
            }
        }

        ; 2. Find and click a tree
        found := FindAndClickTree()

        if (found) {
            ; 3. Wait for chopping to finish
            WaitForChop()
        } else {
            ; No tree found — small wait and retry
            ToolTip, Searching for tree..., 10, 50
            SetTimer, RemoveToolTip, -2000
            RandomSleep(1500, 2500)
        }

        ; 4. Anti-ban actions
        if (AntiBanEnabled) {
            CheckAntiBan()
        }
    }
return

; ========================== TREE DETECTION ===================================

FindAndClickTree() {
    global SearchX1, SearchY1, SearchX2, SearchY2
    global TrunkColor, ColorTolerance, ClickDelayMin, ClickDelayMax

    ; Search for the tree trunk color in the viewport
    PixelSearch, FoundX, FoundY, SearchX1, SearchY1, SearchX2, SearchY2, TrunkColor, ColorTolerance, Fast RGB
    if (ErrorLevel = 0) {
        ; Add small random offset so clicks aren't pixel-perfect
        RandOffX := RandomInt(-5, 5)
        RandOffY := RandomInt(-5, 5)
        ClickX := FoundX + RandOffX
        ClickY := FoundY + RandOffY

        ; Move mouse with human-like speed, then click
        HumanMouseMove(ClickX, ClickY)
        RandomSleep(ClickDelayMin, ClickDelayMax)
        Click, %ClickX%, %ClickY%

        ToolTip, Chopping %TreeType%..., 10, 50
        SetTimer, RemoveToolTip, -3000
        return true
    }
    return false
}

; ========================== WAIT FOR CHOP ====================================

WaitForChop() {
    global TreeChopTimeout, BotRunning

    ; Wait for the tree to be chopped (character goes idle)
    ; We detect this by checking if the character is still animating
    ; Simple approach: wait the average chop time with some variance
    variance := TreeChopTimeout * 0.3
    waitTime := TreeChopTimeout + RandomInt(-variance, variance)
    if (waitTime < 2000)
        waitTime := 2000

    ; Break the wait into intervals to stay responsive
    elapsed := 0
    interval := 500
    while (elapsed < waitTime && BotRunning) {
        Sleep, %interval%
        elapsed += interval

        ; Early exit: check if the tree disappeared (stump appeared)
        ; by re-checking for trunk color near where we clicked
        ; This is approximate — in practice you may want to refine this
    }

    ; Small random delay after chop to seem human
    RandomSleep(300, 800)
}

; ========================== INVENTORY MANAGEMENT =============================

IsInventoryFull() {
    global InvStartX, InvStartY, InvSlotW, InvSlotH, MaxInventorySlots, InvCols
    ; Check the last inventory slot for an item
    lastSlot := MaxInventorySlots
    row := Floor((lastSlot - 1) / InvCols)
    col := Mod(lastSlot - 1, InvCols)
    checkX := InvStartX + (col * InvSlotW)
    checkY := InvStartY + (row * InvSlotH)

    ; Check if the slot has an item (non-background color)
    ; Inventory background is dark brown: ~0x3E3529
    PixelGetColor, slotColor, checkX, checkY, RGB
    bgColor := 0x3E3529
    ; Simple color distance check
    return (ColorDistance(slotColor, bgColor) > 40)
}

DropAllLogs() {
    global InvStartX, InvStartY, InvSlotW, InvSlotH, InvCols, InvRows
    global LogColor, LogColorTol, ClickDelayMin, ClickDelayMax, BotRunning
    global AxeInInventory

    ToolTip, Dropping logs..., 10, 50

    ; Hold shift for shift-drop
    Send, {Shift down}
    Sleep, 100

    startSlot := AxeInInventory ? 2 : 1  ; skip axe slot if in inventory

    ; Drop column by column (more natural pattern)
    Loop, %InvCols% {
        col := A_Index - 1
        Loop, %InvRows% {
            if (!BotRunning)
                break 2
            row := A_Index - 1
            slotNum := (row * InvCols) + col + 1

            if (slotNum < startSlot)
                continue

            slotX := InvStartX + (col * InvSlotW)
            slotY := InvStartY + (row * InvSlotH)

            ; Check if this slot contains a log
            PixelGetColor, pixColor, slotX, slotY, RGB
            if (ColorClose(pixColor, LogColor, LogColorTol)) {
                HumanMouseMove(slotX, slotY)
                RandomSleep(50, 120)
                Click, %slotX%, %slotY%
                RandomSleep(ClickDelayMin, ClickDelayMax)
            }
        }
    }

    Send, {Shift up}
    Sleep, 100
    ToolTip, Logs dropped!, 10, 50
    SetTimer, RemoveToolTip, -2000
    RandomSleep(400, 800)
}

; ========================== ANTI-BAN =========================================

CheckAntiBan() {
    global LastAntiBan, AntiBanIntervalMin, AntiBanIntervalMax

    intervalMs := RandomInt(AntiBanIntervalMin * 60000, AntiBanIntervalMax * 60000)
    if (A_TickCount - LastAntiBan > intervalMs) {
        PerformAntiBan()
        LastAntiBan := A_TickCount
    }
}

PerformAntiBan() {
    action := RandomInt(1, 6)

    if (action = 1) {
        ; Rotate camera randomly
        RotateCamera()
    } else if (action = 2) {
        ; Move mouse to a random location and back
        RandomMouseWander()
    } else if (action = 3) {
        ; Brief idle pause
        RandomSleep(2000, 5000)
    } else if (action = 4) {
        ; Open a random tab and close it
        OpenRandomTab()
    } else if (action = 5) {
        ; Hover over a random inventory slot
        HoverRandomSlot()
    } else if (action = 6) {
        ; Small camera pitch adjustment
        AdjustCameraPitch()
    }
}

RotateCamera() {
    ; Use middle mouse button or arrow keys to rotate camera
    direction := RandomInt(0, 1) ? "{Left}" : "{Right}"
    holdTime := RandomInt(300, 1200)
    Send, %direction%
    Sleep, %holdTime%
    ; Small counter-rotation sometimes
    if (RandomInt(1, 3) = 1) {
        opposite := (direction = "{Left}") ? "{Right}" : "{Left}"
        counterTime := RandomInt(100, 400)
        Send, %opposite%
        Sleep, %counterTime%
    }
}

RandomMouseWander() {
    global SearchX1, SearchY1, SearchX2, SearchY2
    MouseGetPos, origX, origY
    wanderX := RandomInt(SearchX1, SearchX2)
    wanderY := RandomInt(SearchY1, SearchY2)
    HumanMouseMove(wanderX, wanderY)
    RandomSleep(500, 1500)
    HumanMouseMove(origX, origY)
}

OpenRandomTab() {
    ; Press a random F-key to open a game tab, then go back to inventory
    tabs := ["{F1}", "{F2}", "{F3}", "{F4}", "{F5}"]
    randomTab := tabs[RandomInt(1, tabs.MaxIndex())]
    Send, %randomTab%
    RandomSleep(800, 2000)
    Send, {Escape}  ; back to inventory
    RandomSleep(200, 500)
}

HoverRandomSlot() {
    global InvStartX, InvStartY, InvSlotW, InvSlotH, InvCols, InvRows
    col := RandomInt(0, InvCols - 1)
    row := RandomInt(0, InvRows - 1)
    hoverX := InvStartX + (col * InvSlotW)
    hoverY := InvStartY + (row * InvSlotH)
    HumanMouseMove(hoverX, hoverY)
    RandomSleep(300, 1000)
}

AdjustCameraPitch() {
    direction := RandomInt(0, 1) ? "{Up}" : "{Down}"
    holdTime := RandomInt(200, 600)
    Send, %direction%
    Sleep, %holdTime%
}

; ========================== UTILITY FUNCTIONS ================================

HumanMouseMove(targetX, targetY) {
    ; Move mouse in a slightly curved, human-like path
    MouseGetPos, startX, startY
    steps := RandomInt(8, 18)
    Loop, %steps% {
        progress := A_Index / steps
        ; Add slight curve using sine wave
        curve := Sin(progress * 3.14159) * RandomInt(-8, 8)
        currentX := startX + (targetX - startX) * progress + curve
        currentY := startY + (targetY - startY) * progress + curve * 0.5
        MouseMove, %currentX%, %currentY%, 0
        Sleep, % RandomInt(5, 15)
    }
    ; Final precise move
    MouseMove, %targetX%, %targetY%, 0
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
