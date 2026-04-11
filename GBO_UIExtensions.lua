-- =====================================================================
-- GET BETTER OUT | UI EXTENSIONS  v1.0.0
-- =====================================================================
-- MODULES INSIDE:
--   01 · Bootstrap & Services
--   02 · Shared Helpers & Colors
--   03 · Profile System          (JSON persist, UserCard, playtime)
--   04 · Confirmation Dialog      (popup: Yes / Cancel)
--   05 · Panic Button             (Delete key → kill all features)
--   06 · Feature Keybind Manager  (per-feature hotkey + rebind UI)
--   07 · Quick Action Bar         (always-visible shortcut strip)
--   08 · Mini Stats Overlay       (EXP/hr · Fish/hr corner HUD)
--   09 · Mythic Chest Log         (tracks chest timer, no spam)
--   10 · Level XP Progress Bar    (realtime bar on Main page)
--   11 · Visual Effects           (ripple, cursor trail, card glow)
--   12 · Multi-Profile Config     (named save slots + switch)
--   13 · Import / Export Config   (base64 string encode/decode)
--   14 · Misc Panel               (Change Char, Display Name + extras)
-- =====================================================================
-- USAGE:  Run AFTER MainHub_Optimized.lua.
--         loadstring(readfile("GBO_UIExtensions.lua"))()
-- =====================================================================

-- =====================================================================
-- 01 · BOOTSTRAP — wait for main hub
-- =====================================================================
local _bootWaited = 0
repeat task.wait(0.1); _bootWaited += 0.1
until _G._ZiliLoadReady or _bootWaited >= 30
if not _G._ZiliLoadReady then warn("[GBO_EXT] Main hub not ready; aborting."); return end

-- =====================================================================
-- 02 · SERVICES & SHARED HELPERS
-- =====================================================================
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")
local LocalPlayer  = Players.LocalPlayer

local C = Color3.fromRGB

local function NEW(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function CORNER(r, p)   return NEW("UICorner", {CornerRadius=UDim.new(0,r)}, p) end
local function STROKE(col, th, tr, p) return NEW("UIStroke", {Color=col, Thickness=th, Transparency=tr or 0}, p) end
local function TWEEN(o, t, pr)  TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad),  pr):Play() end
local function TWEEN_B(o, t, pr) TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Back,     Enum.EasingDirection.Out), pr):Play() end
local function TWEEN_E(o, t, pr) TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Elastic,  Enum.EasingDirection.Out), pr):Play() end

-- ── Colors (mirrors main hub palette exactly) ──────────────────────
local BG0=C(4,3,10); local BG1=C(8,6,18); local BG2=C(11,9,24)
local BG3=C(15,13,33); local BG4=C(20,18,44); local BG5=C(7,6,16)
local BG_HDR=C(10,9,22)
local GOLD=C(220,172,68); local GOLD2=C(255,215,115); local GOLD3=C(140,100,30)
local TEXT1=C(245,242,232); local TEXT2=C(148,143,168); local TEXT3=C(60,55,82)
local RED=C(240,60,60); local GREEN=C(55,220,130); local CYAN=C(45,225,218)
local AMBER=C(255,215,85); local ORANGE=C(255,105,40); local PURPLE=C(185,95,255)
local PINK=C(240,75,190); local BLUE_A=C(65,165,255)
local MISC_COL = C(160,80,255)  -- Misc accent: vivid violet

-- ── Extension screen GUI ───────────────────────────────────────────
local ExtGui = Instance.new("ScreenGui")
ExtGui.Name = "GBO_UIExtensions"
ExtGui.ResetOnSpawn = false
ExtGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ExtGui.DisplayOrder = 500
ExtGui.Parent = gethui and gethui() or game:GetService("CoreGui")

-- ── Shared toast (delegates to main hub global if available) ────────
local function Toast(msg, col, icon)
    if type(_G._GBO_Toast) == "function" then _G._GBO_Toast(msg, col, icon); return end
    col = col or GOLD2; icon = icon or "⬡"
    local tf = NEW("Frame", {Size=UDim2.new(0,260,0,36), Position=UDim2.new(1,10,1,-66),
        BackgroundColor3=BG1, BorderSizePixel=0, ZIndex=700}, ExtGui)
    CORNER(8, tf); STROKE(col, 1.2, 0.1, tf)
    NEW("Frame", {Size=UDim2.new(0,3,1,0), BackgroundColor3=col, BorderSizePixel=0, ZIndex=701}, tf); CORNER(2, tf:FindFirstChildWhichIsA("Frame"))
    NEW("TextLabel", {Text=icon.."  "..msg, Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, TextColor3=col, Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=702}, tf)
    TWEEN(tf, 0.25, {Position=UDim2.new(1,-274,1,-66)})
    task.delay(2.5, function()
        TWEEN(tf, 0.2, {Position=UDim2.new(1,10,1,-66), BackgroundTransparency=1})
        task.delay(0.22, function() pcall(function() tf:Destroy() end) end)
    end)
end

-- ── File I/O helpers ───────────────────────────────────────────────
local function ReadJSON(filename)
    local ok, data = pcall(function()
        if not (isfile and isfile(filename)) then return nil end
        local raw = readfile(filename)
        return HttpService:JSONDecode(raw)
    end)
    return ok and data or nil
end
local function WriteJSON(filename, data)
    pcall(function()
        if not writefile then return end
        writefile(filename, HttpService:JSONEncode(data))
    end)
end

-- ── Toggle state helper (accesses main hub's TogglesData global) ───
local function GetToggles()
    return getgenv and getgenv().TogglesData or {}
end

-- =====================================================================
-- 03 · PROFILE SYSTEM
-- Persists: username, playtime, per-feature usage count.
-- Exposes:  GBO.Profile.Save(), GBO.Profile.AddUse(featureKey)
-- UserCard displayed in MainFrame gutter (top-right of screen).
-- =====================================================================
local GBO = {}  -- main namespace exposed to _G at end

local PROFILE_FILE = "gbo_profile.json"

local Profile = {}
Profile.data = ReadJSON(PROFILE_FILE) or {}
Profile.data.username    = Profile.data.username or LocalPlayer.Name
Profile.data.playtime    = Profile.data.playtime or 0           -- seconds total
Profile.data.sessions    = Profile.data.sessions or 0
Profile.data.usageCount  = Profile.data.usageCount or {}        -- {featureKey = number}
Profile.data.sessions    = Profile.data.sessions + 1
Profile._sessionStart    = tick()

function Profile.Save()
    Profile.data.playtime = Profile.data.playtime + (tick() - Profile._sessionStart)
    Profile._sessionStart = tick()
    Profile.data.username = LocalPlayer.Name
    WriteJSON(PROFILE_FILE, Profile.data)
end

function Profile.AddUse(key)
    if not key then return end
    Profile.data.usageCount[key] = (Profile.data.usageCount[key] or 0) + 1
    -- Lazy-save every 10 uses to avoid spamming disk
    local total = 0
    for _, v in pairs(Profile.data.usageCount) do total += v end
    if total % 10 == 0 then Profile.Save() end
end

function Profile.FormatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if h > 0 then return string.format("%dh %dm", h, m) end
    return string.format("%dm", math.max(0, m))
end

-- ── UserCard UI ───────────────────────────────────────────────────
-- A compact floating card (top-right, ZIndex 300) that shows stats.
local _ucCard = NEW("Frame", {
    Size=UDim2.new(0,210,0,64), Position=UDim2.new(1,-224,0,8),
    BackgroundColor3=BG2, BorderSizePixel=0, ZIndex=300, Visible=true
}, ExtGui)
CORNER(10, _ucCard); STROKE(MISC_COL, 1.2, 0.35, _ucCard)

local _ucBar = NEW("Frame", {Size=UDim2.new(0,3,0.6,0), Position=UDim2.new(0,0,0.2,0),
    BackgroundColor3=MISC_COL, BorderSizePixel=0, ZIndex=301}, _ucCard); CORNER(2, _ucBar)
local _ucName = NEW("TextLabel", {Text=LocalPlayer.Name, Size=UDim2.new(1,-12,0,20),
    Position=UDim2.new(0,10,0,6), BackgroundTransparency=1, TextColor3=TEXT1,
    Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=302}, _ucCard)
local _ucSess = NEW("TextLabel", {Text="", Size=UDim2.new(1,-12,0,14),
    Position=UDim2.new(0,10,0,26), BackgroundTransparency=1, TextColor3=MISC_COL,
    Font=Enum.Font.GothamSemibold, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=302}, _ucCard)
local _ucPT   = NEW("TextLabel", {Text="", Size=UDim2.new(1,-12,0,13),
    Position=UDim2.new(0,10,0,43), BackgroundTransparency=1, TextColor3=TEXT3,
    Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=302}, _ucCard)

-- Live update every 30s
task.spawn(function()
    while _ucCard and _ucCard.Parent do
        local sessionSecs = tick() - Profile._sessionStart
        local totalSecs   = Profile.data.playtime + sessionSecs
        _ucSess.Text = "Session: " .. Profile.FormatTime(sessionSecs)
        _ucPT.Text   = "Total: "   .. Profile.FormatTime(totalSecs) ..
                       "  ·  Sessions: " .. Profile.data.sessions
        task.wait(30)
    end
end)
-- First tick immediately
task.defer(function()
    _ucSess.Text = "Session: 0m"
    _ucPT.Text   = "Total: " .. Profile.FormatTime(Profile.data.playtime) ..
                   "  ·  Sessions: " .. Profile.data.sessions
end)

-- Auto-save on exit / every 5min
task.spawn(function()
    while task.wait(300) do Profile.Save() end
end)
game:BindToClose(function() Profile.Save() end)

GBO.Profile = Profile

-- =====================================================================
-- 04 · CONFIRMATION DIALOG
-- Usage: GBO.Confirm("Title", "Are you sure?", onYes, onNo)
-- =====================================================================
local function Confirm(title, message, onYes, onNo)
    -- Dim overlay
    local overlay = NEW("Frame", {Size=UDim2.new(1,0,1,0), BackgroundColor3=C(0,0,0),
        BackgroundTransparency=0.55, ZIndex=900, BorderSizePixel=0}, ExtGui)
    CORNER(0, overlay)

    local card = NEW("Frame", {Size=UDim2.new(0,320,0,150), Position=UDim2.new(0.5,-160,0.5,-75),
        BackgroundColor3=BG2, BorderSizePixel=0, ZIndex=901}, ExtGui)
    CORNER(12, card); STROKE(RED, 1.5, 0.2, card)
    card.GroupTransparency = 1
    TWEEN_B(card, 0.28, {GroupTransparency=0})

    NEW("Frame", {Size=UDim2.new(0,3,0.55,0), Position=UDim2.new(0,0,0.22,0),
        BackgroundColor3=RED, BorderSizePixel=0, ZIndex=902}, card)
    NEW("TextLabel", {Text=title, Size=UDim2.new(1,-20,0,24), Position=UDim2.new(0,14,0,12),
        BackgroundTransparency=1, TextColor3=TEXT1, Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=902}, card)
    NEW("TextLabel", {Text=message, Size=UDim2.new(1,-20,0,36), Position=UDim2.new(0,14,0,40),
        BackgroundTransparency=1, TextColor3=TEXT2, Font=Enum.Font.Gotham, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=902}, card)

    local function closeAll()
        TWEEN(card, 0.15, {GroupTransparency=1})
        task.delay(0.15, function()
            pcall(function() card:Destroy() end)
            pcall(function() overlay:Destroy() end)
        end)
    end

    local yesBtn = NEW("TextButton", {Text="YES, CONFIRM", Size=UDim2.new(0,130,0,34),
        Position=UDim2.new(0,14,0,106), BackgroundColor3=C(38,8,8), TextColor3=RED,
        Font=Enum.Font.GothamBold, TextSize=11, AutoButtonColor=false, ZIndex=902}, card)
    CORNER(7, yesBtn); STROKE(RED, 1.2, 0.2, yesBtn)
    local noBtn = NEW("TextButton", {Text="CANCEL", Size=UDim2.new(0,120,0,34),
        Position=UDim2.new(1,-136,0,106), BackgroundColor3=BG4, TextColor3=TEXT2,
        Font=Enum.Font.GothamSemibold, TextSize=11, AutoButtonColor=false, ZIndex=902}, card)
    CORNER(7, noBtn); STROKE(C(35,35,55), 1, 0.3, noBtn)

    yesBtn.MouseButton1Click:Connect(function()
        closeAll(); if onYes then task.spawn(onYes) end
    end)
    noBtn.MouseButton1Click:Connect(function()
        closeAll(); if onNo then task.spawn(onNo) end
    end)
    overlay.MouseButton1Click:Connect(function()
        closeAll(); if onNo then task.spawn(onNo) end
    end)
end
GBO.Confirm = Confirm

-- =====================================================================
-- 05 · PANIC BUTTON
-- Default key: Delete. Custom via GBO.Panic.SetKey(KeyCode).
-- Disables ALL active features immediately.
-- =====================================================================
local Panic = {}
Panic._key = Enum.KeyCode.Delete

function Panic.Fire()
    local td = GetToggles()
    local count = 0
    for key, info in pairs(td) do
        if type(info) == "table" and info.Active then
            count += 1
            pcall(function()
                info.Active = false
                -- Reset UI pill/thumb visuals
                if info.Btn then
                    TWEEN(info.Btn, 0.15, {BackgroundColor3=BG5})
                    if info.Strk  then TWEEN(info.Strk, 0.15, {Color=C(60,55,82), Transparency=0.3}) end
                    if info.Thumb then TWEEN(info.Thumb, 0.15, {BackgroundColor3=C(60,55,82), Position=UDim2.new(0,4,0.5,-9)}) end
                    if info.MasterBar then TWEEN(info.MasterBar, 0.25, {BackgroundColor3=C(220,172,68)}) end
                end
                if info.Callback then info.Callback(false) end
            end)
        end
    end
    -- Also clear known getgenv flags
    pcall(function()
        local ge = getgenv()
        ge.AutoFarm         = false
        ge.AutoGetBuso      = false
        ge.AutoGeppo        = false
        ge.AutoFishMerchant = false
        ge.AutoChangeSkin   = false
        ge.AutoRejoin       = false
        ge.Auto2ndSea       = false
        ge.AutoChangeSkin   = false
    end)
    Toast("PANIC — " .. count .. " feature(s) stopped", RED, "🚨")
end

function Panic.SetKey(keyCode) Panic._key = keyCode end

UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Panic._key then Panic.Fire() end
end)

GBO.Panic = Panic

-- =====================================================================
-- 06 · FEATURE KEYBIND MANAGER
-- Stores binds in gbo_keybinds.json.
-- GBO.Keybind.Register(featureKey, displayName, defaultKey)
-- GBO.Keybind.OpenUI()  — opens the rebind window
-- =====================================================================
local KEYBIND_FILE = "gbo_keybinds.json"

local Keybind = {}
Keybind._binds    = ReadJSON(KEYBIND_FILE) or {}   -- {featureKey = "KeyCode_Name"}
Keybind._registry = {}                              -- {featureKey = {display, default}}

function Keybind.Register(key, display, defaultKey)
    Keybind._registry[key] = {display=display, default=defaultKey}
    if not Keybind._binds[key] then
        Keybind._binds[key] = tostring(defaultKey):gsub("Enum.KeyCode.", "")
    end
end

function Keybind.GetKey(key)
    local name = Keybind._binds[key]
    if not name then return nil end
    return Enum.KeyCode[name]
end

function Keybind.Save()
    WriteJSON(KEYBIND_FILE, Keybind._binds)
end

-- Global listener: fires the feature's toggle when its hotkey is pressed
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = tostring(inp.KeyCode):gsub("Enum.KeyCode.", "")
    for featureKey, boundName in pairs(Keybind._binds) do
        if keyName == boundName then
            local td = GetToggles()
            if td[featureKey] and td[featureKey].Btn then
                pcall(function() td[featureKey].Btn:activate() end)
                Profile.AddUse(featureKey)
            end
        end
    end
end)

-- Register default binds for known features
Keybind.Register("AutoFarmLevel",    "Auto Farm Level",    Enum.KeyCode.F5)
Keybind.Register("AutoFishMerchant", "Auto Fish+Merchant", Enum.KeyCode.F6)
Keybind.Register("AutoGetBuso",      "Auto Get Buso",      Enum.KeyCode.F7)
Keybind.Register("AutoGeppo",        "Auto Geppo",         Enum.KeyCode.F8)
Keybind.Register("ESP_Island",       "Island ESP",         Enum.KeyCode.F9)

-- ── Keybind Rebind UI ─────────────────────────────────────────────
function Keybind.OpenUI()
    -- close if already open
    local old = ExtGui:FindFirstChild("KeybindPanel")
    if old then old:Destroy(); return end

    local panel = NEW("Frame", {
        Name="KeybindPanel", Size=UDim2.new(0,360,0,420),
        Position=UDim2.new(0.5,-180,0.5,-210), BackgroundColor3=BG2,
        BorderSizePixel=0, ZIndex=600
    }, ExtGui)
    CORNER(12, panel); STROKE(PURPLE, 1.5, 0.2, panel)
    panel.GroupTransparency = 1
    TWEEN_B(panel, 0.3, {GroupTransparency=0})

    -- Header
    local hdr = NEW("Frame", {Size=UDim2.new(1,0,0,44), BackgroundColor3=BG_HDR, ZIndex=601}, panel)
    CORNER(10, hdr); NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG_HDR,BorderSizePixel=0,ZIndex=601},hdr)
    NEW("TextLabel", {Text="⌨  KEYBIND MANAGER", Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, TextColor3=PURPLE, Font=Enum.Font.GothamBold, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=602}, hdr)
    local closeKb = NEW("TextButton", {Text="✕", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-36,0.5,-14),
        BackgroundTransparency=1, TextColor3=TEXT3, Font=Enum.Font.GothamBold, TextSize=15, ZIndex=602}, hdr)
    closeKb.MouseButton1Click:Connect(function() TWEEN(panel, 0.15, {GroupTransparency=1}); task.delay(0.15, function() pcall(function() panel:Destroy() end) end) end)

    local scroll = NEW("ScrollingFrame", {
        Size=UDim2.new(1,-16,1,-56), Position=UDim2.new(0,8,0,52),
        BackgroundTransparency=1, ScrollBarThickness=2, ScrollBarImageColor3=PURPLE,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=601
    }, panel)
    NEW("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6),
        HorizontalAlignment=Enum.HorizontalAlignment.Center}, scroll)
    NEW("UIPadding", {PaddingTop=UDim.new(0,6), PaddingBottom=UDim.new(0,6)}, scroll)

    local listening = nil  -- featureKey currently listening for a rebind

    for featureKey, info in pairs(Keybind._registry) do
        local row = NEW("Frame", {Size=UDim2.new(1,-8,0,48), BackgroundColor3=BG3, BorderSizePixel=0, ZIndex=602}, scroll)
        CORNER(8, row); STROKE(C(28,24,52), 1, 0, row)
        NEW("TextLabel", {Text=info.display, Size=UDim2.new(0.55,0,0,18), Position=UDim2.new(0,12,0,6),
            BackgroundTransparency=1, TextColor3=TEXT1, Font=Enum.Font.GothamBold, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=603}, row)
        local keyLbl = NEW("TextLabel", {Text=Keybind._binds[featureKey] or "None",
            Size=UDim2.new(0,80,0,16), Position=UDim2.new(0,12,0,28),
            BackgroundTransparency=1, TextColor3=PURPLE, Font=Enum.Font.GothamSemibold, TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=603}, row)
        local rebindBtn = NEW("TextButton", {Text="REBIND", Size=UDim2.new(0,80,0,28),
            Position=UDim2.new(1,-90,0.5,-14), BackgroundColor3=BG4, TextColor3=PURPLE,
            Font=Enum.Font.GothamBold, TextSize=10, AutoButtonColor=false, ZIndex=603}, row)
        CORNER(6, rebindBtn); STROKE(PURPLE, 1, 0.3, rebindBtn)

        local fk = featureKey
        rebindBtn.MouseButton1Click:Connect(function()
            if listening == fk then
                listening = nil
                rebindBtn.Text = "REBIND"; rebindBtn.TextColor3 = PURPLE
                return
            end
            listening = fk
            rebindBtn.Text = "PRESS KEY"; rebindBtn.TextColor3 = AMBER

            local conn; conn = UIS.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                local kName = tostring(inp.KeyCode):gsub("Enum.KeyCode.", "")
                Keybind._binds[fk] = kName
                keyLbl.Text = kName
                Keybind.Save()
                listening = nil
                rebindBtn.Text = "REBIND"; rebindBtn.TextColor3 = PURPLE
                Toast("Bound " .. (Keybind._registry[fk] and Keybind._registry[fk].display or fk) .. " → " .. kName, PURPLE, "⌨")
                conn:Disconnect()
            end)
        end)
    end

    -- Drag
    local d, ds, sp
    hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;ds=i.Position;sp=panel.Position end end)
    UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then local delta=i.Position-ds;panel.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
end

GBO.Keybind = Keybind

-- =====================================================================
-- 07 · QUICK ACTION BAR
-- Always visible horizontal strip (top-left). 5 pinnable shortcuts.
-- GBO.QuickBar.Pin(featureKey, icon, label, col)
-- =====================================================================
local QuickBar = {}
QuickBar._pins = {}        -- ordered list of {key, label, icon, col}
QuickBar._MAX  = 5

-- Bar frame
local _qbFrame = NEW("Frame", {
    Size=UDim2.new(0,300,0,42), Position=UDim2.new(0,8,0,8),
    BackgroundColor3=BG2, BorderSizePixel=0, ZIndex=400
}, ExtGui)
CORNER(10, _qbFrame); STROKE(GOLD, 1, 0.45, _qbFrame)

-- Background shimmer
local _qbGrad = Instance.new("UIGradient")
_qbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C(14,12,28)),
    ColorSequenceKeypoint.new(1, C(8,7,20))
})
_qbGrad.Rotation = 90
_qbGrad.Parent = _qbFrame

local _qbList = NEW("Frame", {Size=UDim2.new(1,-10,1,0), Position=UDim2.new(0,5,0,0),
    BackgroundTransparency=1, ZIndex=401}, _qbFrame)
NEW("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left,
    VerticalAlignment=Enum.VerticalAlignment.Center,
    Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, _qbList)

-- Drag for quick bar
local _qd, _qds, _qsp
_qbFrame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _qd=true;_qds=i.Position;_qsp=_qbFrame.Position end end)
UIS.InputChanged:Connect(function(i) if _qd and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-_qds;_qbFrame.Position=UDim2.new(_qsp.X.Scale,_qsp.X.Offset+d.X,_qsp.Y.Scale,_qsp.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _qd=false end end)

local function _qbRebuild()
    -- Clear all button children
    for _, ch in ipairs(_qbList:GetChildren()) do
        if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end
    end
    local btnW = math.floor(((_qbFrame.AbsoluteSize.X - 10) / math.max(1, #QuickBar._pins)) - 4)
    btnW = math.clamp(btnW, 44, 80)
    _qbFrame.Size = UDim2.new(0, (#QuickBar._pins * (btnW+4)) + 10, 0, 42)

    for _, pin in ipairs(QuickBar._pins) do
        local col = pin.col or GOLD2
        local btn = NEW("TextButton", {Size=UDim2.new(0,btnW,0,32), BackgroundColor3=BG3,
            Text="", AutoButtonColor=false, ZIndex=402}, _qbList)
        CORNER(7, btn); STROKE(col, 1, 0.45, btn)
        NEW("TextLabel", {Text=pin.icon or "⬡", Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4),
            BackgroundTransparency=1, TextColor3=col, Font=Enum.Font.GothamBold, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Center, ZIndex=403}, btn)
        NEW("TextLabel", {Text=pin.label, Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,18),
            BackgroundTransparency=1, TextColor3=TEXT3, Font=Enum.Font.Gotham, TextSize=8,
            TextXAlignment=Enum.TextXAlignment.Center, ZIndex=403}, btn)

        -- Active state glow
        local activeStroke = btn:FindFirstChildWhichIsA("UIStroke")
        local function _updateActive()
            local td = GetToggles()
            local active = td[pin.key] and td[pin.key].Active
            if active then
                TWEEN(btn, 0.2, {BackgroundColor3=C(math.floor(col.R*255*0.12+4), math.floor(col.G*255*0.12+4), math.floor(col.B*255*0.12+4))})
                if activeStroke then TWEEN(activeStroke, 0.2, {Color=col, Transparency=0}) end
            else
                TWEEN(btn, 0.2, {BackgroundColor3=BG3})
                if activeStroke then TWEEN(activeStroke, 0.2, {Color=col, Transparency=0.45}) end
            end
        end
        _updateActive()

        btn.MouseEnter:Connect(function() TWEEN(btn, 0.12, {BackgroundColor3=BG4}) end)
        btn.MouseLeave:Connect(function() _updateActive() end)
        btn.MouseButton1Click:Connect(function()
            local td = GetToggles()
            if td[pin.key] and td[pin.key].Btn then
                pcall(function() td[pin.key].Btn:activate() end)
                Profile.AddUse(pin.key)
                task.delay(0.1, _updateActive)
            end
        end)

        -- Poll active state every 2s
        task.spawn(function()
            while btn and btn.Parent do task.wait(2); _updateActive() end
        end)
    end
end

function QuickBar.Pin(key, icon, label, col)
    -- No duplicates
    for _, p in ipairs(QuickBar._pins) do if p.key == key then return end end
    if #QuickBar._pins >= QuickBar._MAX then
        Toast("Quick Bar is full (" .. QuickBar._MAX .. " max). Unpin one first.", AMBER, "⚡")
        return
    end
    table.insert(QuickBar._pins, {key=key, icon=icon, label=label or key, col=col})
    _qbRebuild()
end

function QuickBar.Unpin(key)
    for i, p in ipairs(QuickBar._pins) do
        if p.key == key then table.remove(QuickBar._pins, i); _qbRebuild(); return end
    end
end

-- Default pins
QuickBar.Pin("AutoFarmLevel",    "⚔", "Farm",    ORANGE)
QuickBar.Pin("AutoFishMerchant", "🐟", "Fish",    BLUE_A)
QuickBar.Pin("AutoGetBuso",      "👊", "Buso",    PURPLE)
QuickBar.Pin("ESP_Island",       "🗺", "ESP",     CYAN)

-- Misc button in quick bar (opens Misc panel)
task.defer(function()
    local miscBtn = NEW("TextButton", {Size=UDim2.new(0,44,0,32), BackgroundColor3=BG3,
        Text="", AutoButtonColor=false, ZIndex=402}, _qbList)
    CORNER(7, miscBtn); STROKE(MISC_COL, 1, 0.35, miscBtn)
    NEW("TextLabel", {Text="✦", Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4),
        BackgroundTransparency=1, TextColor3=MISC_COL, Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=403}, miscBtn)
    NEW("TextLabel", {Text="Misc", Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,18),
        BackgroundTransparency=1, TextColor3=TEXT3, Font=Enum.Font.Gotham, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=403}, miscBtn)
    miscBtn.MouseButton1Click:Connect(function()
        if type(GBO.MiscPanel) == "function" then GBO.MiscPanel() end
    end)
    _qbFrame.Size = UDim2.new(0, (#QuickBar._pins * 56) + 52, 0, 42)
end)

GBO.QuickBar = QuickBar

-- =====================================================================
-- 08 · MINI STATS OVERLAY
-- Corner HUD for EXP/hr and Fish/hr. Only visible when farm/fish ON.
-- =====================================================================
local StatsOverlay = {}
StatsOverlay._expTotal   = 0
StatsOverlay._fishTotal  = 0
StatsOverlay._startTick  = nil
StatsOverlay._visible    = false

local _sovFrame = NEW("Frame", {
    Size=UDim2.new(0,196,0,90), Position=UDim2.new(0,8,1,-108),
    BackgroundColor3=BG1, BorderSizePixel=0, ZIndex=300, Visible=false
}, ExtGui)
CORNER(10, _sovFrame); STROKE(AMBER, 1.2, 0.3, _sovFrame)

-- Gradient tint
local _sovGrad = Instance.new("UIGradient")
_sovGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C(14,12,28)),
    ColorSequenceKeypoint.new(1, C(8,6,18))
})
_sovGrad.Rotation = 135; _sovGrad.Parent = _sovFrame

NEW("TextLabel", {Text="◆ LIVE STATS", Size=UDim2.new(1,-10,0,16), Position=UDim2.new(0,8,0,6),
    BackgroundTransparency=1, TextColor3=AMBER, Font=Enum.Font.GothamBold, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _sovFrame)

local _sovExpLbl  = NEW("TextLabel", {Text="EXP/hr  ·  --", Size=UDim2.new(1,-10,0,18), Position=UDim2.new(0,8,0,28),
    BackgroundTransparency=1, TextColor3=TEXT1, Font=Enum.Font.GothamBold, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _sovFrame)
local _sovFishLbl = NEW("TextLabel", {Text="Fish/hr  ·  --", Size=UDim2.new(1,-10,0,18), Position=UDim2.new(0,8,0,50),
    BackgroundTransparency=1, TextColor3=BLUE_A, Font=Enum.Font.GothamBold, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _sovFrame)
local _sovTimeLbl = NEW("TextLabel", {Text="", Size=UDim2.new(1,-10,0,12), Position=UDim2.new(0,8,0,74),
    BackgroundTransparency=1, TextColor3=TEXT3, Font=Enum.Font.Gotham, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _sovFrame)

function StatsOverlay.Show()
    if StatsOverlay._visible then return end
    StatsOverlay._visible   = true
    StatsOverlay._startTick = tick()
    _sovFrame.Visible = true
    _sovFrame.Position = UDim2.new(0,-210,1,-108)
    TWEEN(_sovFrame, 0.35, {Position=UDim2.new(0,8,1,-108)})
end

function StatsOverlay.Hide()
    if not StatsOverlay._visible then return end
    StatsOverlay._visible = false
    TWEEN(_sovFrame, 0.28, {Position=UDim2.new(0,-210,1,-108)})
    task.delay(0.3, function() _sovFrame.Visible = false end)
end

function StatsOverlay.AddEXP(amount)  StatsOverlay._expTotal  += (amount or 0) end
function StatsOverlay.AddFish(amount) StatsOverlay._fishTotal += (amount or 0) end

-- Internal update loop
task.spawn(function()
    while true do
        task.wait(5)
        if StatsOverlay._visible and StatsOverlay._startTick then
            local elapsed = math.max(1, tick() - StatsOverlay._startTick)
            local expHr  = math.floor(StatsOverlay._expTotal  / elapsed * 3600)
            local fishHr = math.floor(StatsOverlay._fishTotal / elapsed * 3600)
            local mins   = math.floor(elapsed / 60)
            _sovExpLbl.Text  = "EXP/hr  ·  " .. (expHr  > 0 and tostring(expHr)  or "--")
            _sovFishLbl.Text = "Fish/hr  ·  " .. (fishHr > 0 and tostring(fishHr) or "--")
            _sovTimeLbl.Text = "Running: " .. mins .. "m"
        end
    end
end)

-- Auto-show/hide based on active features
task.spawn(function()
    while true do
        task.wait(3)
        local td = GetToggles()
        local anyActive = (td.AutoFarmLevel and td.AutoFarmLevel.Active)
                       or (td.AutoFishMerchant and td.AutoFishMerchant.Active)
        if anyActive then StatsOverlay.Show() else StatsOverlay.Hide() end
    end
end)

-- Export hooks for modules to call
_G._GBO_AddEXP  = function(n) StatsOverlay.AddEXP(n) end
_G._GBO_AddFish = function(n) StatsOverlay.AddFish(n) end

GBO.StatsOverlay = StatsOverlay

-- =====================================================================
-- 09 · MYTHIC CHEST LOG
-- Tracks time since last Mythic Chest event. No spam logging.
-- Hook: call GBO.MythicLog.OnChest() when a mythic chest is received.
-- =====================================================================
local MythicLog = {}
MythicLog._lastChestTick = nil
MythicLog._startTick     = tick()
MythicLog._count         = 0

-- HUD card (bottom-right, above stats overlay)
local _mlFrame = NEW("Frame", {
    Size=UDim2.new(0,210,0,56), Position=UDim2.new(1,-222,1,-170),
    BackgroundColor3=BG2, BorderSizePixel=0, ZIndex=300, Visible=true
}, ExtGui)
CORNER(10, _mlFrame); STROKE(AMBER, 1.2, 0.35, _mlFrame)

NEW("TextLabel", {Text="◈ MYTHIC CHEST", Size=UDim2.new(1,-10,0,14), Position=UDim2.new(0,10,0,6),
    BackgroundTransparency=1, TextColor3=AMBER, Font=Enum.Font.GothamBold, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _mlFrame)
local _mlTimeLbl = NEW("TextLabel", {Text="Waiting for data...", Size=UDim2.new(1,-10,0,16),
    Position=UDim2.new(0,10,0,22), BackgroundTransparency=1, TextColor3=TEXT1,
    Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _mlFrame)
local _mlCntLbl  = NEW("TextLabel", {Text="", Size=UDim2.new(1,-10,0,12),
    Position=UDim2.new(0,10,0,40), BackgroundTransparency=1, TextColor3=TEXT3,
    Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _mlFrame)

function MythicLog.OnChest()
    MythicLog._lastChestTick = tick()
    MythicLog._count += 1
    Toast("MYTHIC CHEST received! (#" .. MythicLog._count .. ")", AMBER, "◈")
end

-- Update loop
task.spawn(function()
    while _mlFrame and _mlFrame.Parent do
        task.wait(15)
        local now = tick()
        if MythicLog._lastChestTick then
            local ago = math.floor((now - MythicLog._lastChestTick) / 60)
            _mlTimeLbl.Text = "Last: " .. ago .. "m ago"
            _mlTimeLbl.TextColor3 = ago < 30 and GREEN or ago < 60 and AMBER or RED
        else
            local sinceStart = math.floor((now - MythicLog._startTick) / 60)
            _mlTimeLbl.Text = "None yet (" .. sinceStart .. "m since start)"
            _mlTimeLbl.TextColor3 = TEXT2
        end
        _mlCntLbl.Text = "Total this session: " .. MythicLog._count
    end
end)

-- Export hook
_G._GBO_MythicChest = function() MythicLog.OnChest() end

GBO.MythicLog = MythicLog

-- =====================================================================
-- 10 · LEVEL XP PROGRESS BAR
-- Reads Stats from ReplicatedStorage (same pattern as main hub).
-- Shows realtime XP bar in a small overlay card.
-- =====================================================================
local XPBar = {}
XPBar._level = 0; XPBar._xp = 0; XPBar._xpMax = 100

-- Level/XP tables (example — adjust to match your game)
local XP_TABLE = {}
for i = 1, 700 do XP_TABLE[i] = math.floor(100 * (1.08 ^ i)) end

local function _getXPNeeded(level)
    return XP_TABLE[level] or math.floor(100 * (1.08 ^ level))
end

local _xpFrame = NEW("Frame", {
    Size=UDim2.new(0,210,0,62), Position=UDim2.new(1,-222,1,-106),
    BackgroundColor3=BG2, BorderSizePixel=0, ZIndex=300
}, ExtGui)
CORNER(10, _xpFrame); STROKE(GREEN, 1.2, 0.35, _xpFrame)

NEW("TextLabel", {Text="◉ LEVEL PROGRESS", Size=UDim2.new(1,-10,0,14), Position=UDim2.new(0,10,0,5),
    BackgroundTransparency=1, TextColor3=GREEN, Font=Enum.Font.GothamBold, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _xpFrame)
local _xpLvlLbl = NEW("TextLabel", {Text="Level --", Size=UDim2.new(1,-10,0,16), Position=UDim2.new(0,10,0,20),
    BackgroundTransparency=1, TextColor3=TEXT1, Font=Enum.Font.GothamBold, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=301}, _xpFrame)
local _xpTrack = NEW("Frame", {Size=UDim2.new(1,-20,0,6), Position=UDim2.new(0,10,0,40),
    BackgroundColor3=BG5, BorderSizePixel=0, ZIndex=301}, _xpFrame); CORNER(3, _xpTrack)
local _xpFill  = NEW("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=GREEN, BorderSizePixel=0, ZIndex=302}, _xpTrack); CORNER(3, _xpFill)
local _xpGrad  = Instance.new("UIGradient")
_xpGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(30,180,100)), ColorSequenceKeypoint.new(1, C(85,255,175))})
_xpGrad.Parent = _xpFill
local _xpPctLbl = NEW("TextLabel", {Text="0%", Size=UDim2.new(0,40,0,12), Position=UDim2.new(1,-44,0,50),
    BackgroundTransparency=1, TextColor3=TEXT3, Font=Enum.Font.GothamBold, TextSize=8,
    TextXAlignment=Enum.TextXAlignment.Right, ZIndex=301}, _xpFrame)

function XPBar.Update(level, xp)
    if not level or not xp then return end
    XPBar._level = level; XPBar._xp = xp; XPBar._xpMax = _getXPNeeded(level)
    local pct = math.clamp(xp / math.max(1, XPBar._xpMax), 0, 1)
    _xpLvlLbl.Text = "Level " .. level .. "  ·  " .. tostring(xp) .. " XP"
    TWEEN(_xpFill, 0.5, {Size=UDim2.new(pct, 0, 1, 0)})
    _xpPctLbl.Text = math.floor(pct * 100) .. "%"
end

-- Poll stats from ReplicatedStorage every 10s
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    while _xpFrame and _xpFrame.Parent do
        task.wait(10)
        pcall(function()
            local stats = RS:FindFirstChild("Stats" .. LocalPlayer.Name)
            if not stats then return end
            local lv  = stats:FindFirstChild("Level")
            local xpV = stats:FindFirstChild("EXP")
            if lv and xpV then XPBar.Update(lv.Value, xpV.Value) end
        end)
    end
end)

_G._GBO_XPBar = XPBar

GBO.XPBar = XPBar

-- =====================================================================
-- 11 · VISUAL EFFECTS
-- A) Ripple  — call GBO.FX.Ripple(button)  to wire it up
-- B) Cursor trail — global mouse trail in ExtGui
-- C) Card glow — GBO.FX.CardGlow(frame, on, accentColor)
-- =====================================================================
local FX = {}

-- A) RIPPLE ───────────────────────────────────────────────────────
function FX.Ripple(btn, col)
    col = col or C(255,255,255)
    btn.MouseButton1Click:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        local ap = btn.AbsolutePosition
        local localX = mouse.X - ap.X
        local localY = mouse.Y - ap.Y
        local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.2

        local ripple = NEW("Frame", {
            Size=UDim2.new(0,6,0,6),
            Position=UDim2.new(0, localX-3, 0, localY-3),
            BackgroundColor3=col,
            BackgroundTransparency=0.55,
            BorderSizePixel=0,
            ZIndex=btn.ZIndex+1,
            ClipsDescendants=false
        }, btn)
        CORNER(math.huge, ripple)
        TweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(0,localX-sz/2,0,localY-sz/2),
            BackgroundTransparency=1
        }):Play()
        task.delay(0.5, function() pcall(function() ripple:Destroy() end) end)
    end)
end

-- B) CURSOR TRAIL ─────────────────────────────────────────────────
local _trail = {}
local _trailActive = true
local _trailGui = NEW("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    ZIndex=1, BorderSizePixel=0}, ExtGui)

task.spawn(function()
    local mouse = LocalPlayer:GetMouse()
    while true do
        task.wait(0.03)
        if not _trailActive then continue end
        local dot = NEW("Frame", {
            Size=UDim2.new(0,6,0,6),
            Position=UDim2.new(0,mouse.X-3,0,mouse.Y-3),
            BackgroundColor3=GOLD2,
            BackgroundTransparency=0.5,
            BorderSizePixel=0,
            ZIndex=2
        }, _trailGui)
        CORNER(3, dot)
        TWEEN(dot, 0.35, {BackgroundTransparency=1, Size=UDim2.new(0,2,0,2)})
        task.delay(0.36, function() pcall(function() dot:Destroy() end) end)
        table.insert(_trail, dot)
        if #_trail > 12 then table.remove(_trail, 1) end
    end
end)

function FX.SetTrailEnabled(on) _trailActive = on end

-- C) CARD GLOW ────────────────────────────────────────────────────
function FX.CardGlow(frame, active, accentColor)
    accentColor = accentColor or GOLD2
    local existing = frame:FindFirstChildWhichIsA("UIStroke")
    if not existing then
        existing = STROKE(accentColor, 1.5, 0.8, frame)
    end
    if active then
        TWEEN(existing, 0.3, {Color=accentColor, Transparency=0.15, Thickness=1.8})
        -- Pulse animation
        local conn; conn = task.spawn(function()
            while frame and frame.Parent and active do
                TWEEN(existing, 1.2, {Transparency=0.05})
                task.wait(1.3)
                TWEEN(existing, 1.2, {Transparency=0.3})
                task.wait(1.3)
            end
        end)
        frame:SetAttribute("GlowTask", true)
    else
        TWEEN(existing, 0.3, {Color=C(35,32,60), Transparency=0.7, Thickness=1})
        frame:SetAttribute("GlowTask", false)
    end
end

-- Export for main hub modules to call
_G._GBO_CardGlow = FX.CardGlow

GBO.FX = FX

-- =====================================================================
-- 12 · MULTI-PROFILE CONFIG  +  IMPORT / EXPORT
-- ── Multi-Profile ──────────────────────────────────────────────────
-- Profiles saved to gbo_multiprofile.json
-- {profiles: {name: {toggleStates}}, active: "name"}
-- ── Import/Export ──────────────────────────────────────────────────
-- Encodes all toggle states to base64. Paste to restore.
-- =====================================================================
local MultiConfig = {}
local MP_FILE = "gbo_multiprofile.json"
MultiConfig._data = ReadJSON(MP_FILE) or {profiles={}, active=nil}

-- ── Base64 encode/decode (pure Lua) ──────────────────────────────
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function B64Encode(data)
    local result, padding = {}, 0
    local len = #data
    for i = 1, len, 3 do
        local b1 = data:byte(i)
        local b2 = i+1 <= len and data:byte(i+1) or 0
        local b3 = i+2 <= len and data:byte(i+2) or 0
        local c1 = math.floor(b1 / 4)
        local c2 = (b1 % 4) * 16 + math.floor(b2 / 16)
        local c3 = (b2 % 16) * 4  + math.floor(b3 / 64)
        local c4 = b3 % 64
        table.insert(result, B64_CHARS:sub(c1+1,c1+1))
        table.insert(result, B64_CHARS:sub(c2+1,c2+1))
        table.insert(result, (i+1<=len) and B64_CHARS:sub(c3+1,c3+1) or "=")
        table.insert(result, (i+2<=len) and B64_CHARS:sub(c4+1,c4+1) or "=")
    end
    return table.concat(result)
end

local function B64Decode(data)
    data = data:gsub("[^"..B64_CHARS.."=]", "")
    local result = {}
    for i = 1, #data, 4 do
        local s1 = B64_CHARS:find(data:sub(i,i), 1, true) or 1
        local s2 = B64_CHARS:find(data:sub(i+1,i+1), 1, true) or 1
        local s3 = data:sub(i+2,i+2) == "=" and 0 or (B64_CHARS:find(data:sub(i+2,i+2), 1, true) or 1)
        local s4 = data:sub(i+3,i+3) == "=" and 0 or (B64_CHARS:find(data:sub(i+3,i+3), 1, true) or 1)
        s1=s1-1;s2=s2-1;s3=s3-1;s4=s4-1
        table.insert(result, string.char(s1*4 + math.floor(s2/16)))
        if data:sub(i+2,i+2) ~= "=" then
            table.insert(result, string.char((s2%16)*16 + math.floor(s3/4)))
        end
        if data:sub(i+3,i+3) ~= "=" then
            table.insert(result, string.char((s3%4)*64 + s4))
        end
    end
    return table.concat(result)
end

function MultiConfig.SnapshotToggles()
    local td = GetToggles(); local snap = {}
    for k, info in pairs(td) do
        if type(info) == "table" then
            snap[k] = info.Active or info.Value or false
        end
    end
    return snap
end

function MultiConfig.ApplySnapshot(snap)
    local td = GetToggles()
    for k, val in pairs(snap) do
        local info = td[k]
        if type(info) == "table" then
            pcall(function()
                if info.Callback then info.Callback(val) end
                if info.Active ~= nil then info.Active = val end
                if info.Value  ~= nil then info.Value  = val end
                if info.Btn and info.Strk and info.Thumb then
                    local col = info.AccentCol or GOLD2
                    local dark = info.AccentDark or BG5
                    TWEEN(info.Btn,  0.2, {BackgroundColor3= val and dark or BG5})
                    TWEEN(info.Strk, 0.2, {Color=val and col or C(60,55,82), Transparency=val and 0 or 0.3})
                    TWEEN(info.Thumb,0.2, {BackgroundColor3=val and col or C(60,55,82),
                        Position=val and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)})
                end
            end)
        end
    end
end

function MultiConfig.Save()
    WriteJSON(MP_FILE, MultiConfig._data)
end

function MultiConfig.CreateProfile(name)
    if not name or name == "" then Toast("Enter a profile name", RED, "✕"); return end
    MultiConfig._data.profiles[name] = MultiConfig.SnapshotToggles()
    MultiConfig._data.active = name
    MultiConfig.Save()
    Toast("Profile saved: " .. name, GREEN, "✓")
end

function MultiConfig.LoadProfile(name)
    local profile = MultiConfig._data.profiles[name]
    if not profile then Toast("Profile not found: " .. name, RED, "✕"); return end
    MultiConfig.ApplySnapshot(profile)
    MultiConfig._data.active = name
    MultiConfig.Save()
    Toast("Profile loaded: " .. name, CYAN, "↺")
end

function MultiConfig.DeleteProfile(name)
    if not MultiConfig._data.profiles[name] then return end
    MultiConfig._data.profiles[name] = nil
    if MultiConfig._data.active == name then MultiConfig._data.active = nil end
    MultiConfig.Save()
    Toast("Profile deleted: " .. name, AMBER, "🗑")
end

function MultiConfig.Export()
    local snap = MultiConfig.SnapshotToggles()
    local ok, js = pcall(function() return HttpService:JSONEncode(snap) end)
    if not ok then Toast("Export failed", RED, "✕"); return "" end
    return B64Encode(js)
end

function MultiConfig.Import(encoded)
    if not encoded or encoded == "" then Toast("Nothing to import", RED, "✕"); return end
    local ok, snap = pcall(function()
        return HttpService:JSONDecode(B64Decode(encoded))
    end)
    if not ok or type(snap) ~= "table" then
        Toast("Invalid config string", RED, "✕"); return
    end
    MultiConfig.ApplySnapshot(snap)
    Toast("Config imported successfully!", GREEN, "✓")
end

GBO.MultiConfig = MultiConfig
GBO.B64Encode   = B64Encode
GBO.B64Decode   = B64Decode

-- ── Multi-Config UI Panel ─────────────────────────────────────────
function MultiConfig.OpenUI()
    local old = ExtGui:FindFirstChild("MultiConfigPanel")
    if old then old:Destroy(); return end

    local panel = NEW("Frame", {
        Name="MultiConfigPanel", Size=UDim2.new(0,400,0,480),
        Position=UDim2.new(0.5,-200,0.5,-240), BackgroundColor3=BG2,
        BorderSizePixel=0, ZIndex=600
    }, ExtGui)
    CORNER(12, panel); STROKE(GREEN, 1.5, 0.2, panel)
    panel.GroupTransparency = 1; TWEEN_B(panel, 0.3, {GroupTransparency=0})

    -- Header
    local hdr = NEW("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=BG_HDR,ZIndex=601},panel)
    CORNER(10,hdr); NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG_HDR,BorderSizePixel=0,ZIndex=601},hdr)
    NEW("TextLabel",{Text="⚙  CONFIG PROFILES  +  IMPORT / EXPORT",Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=602},hdr)
    local closeC=NEW("TextButton",{Text="✕",Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-36,0.5,-14),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=15,ZIndex=602},hdr)
    closeC.MouseButton1Click:Connect(function() TWEEN(panel,0.15,{GroupTransparency=1}); task.delay(0.15,function() pcall(function() panel:Destroy() end) end) end)

    -- Section: Create/Load Profile
    local nameBox = NEW("TextBox",{Size=UDim2.new(1,-140,0,32),Position=UDim2.new(0,10,0,54),BackgroundColor3=BG5,PlaceholderText=" Profile name...",Text="",TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=11,ZIndex=602},panel); CORNER(7,nameBox); STROKE(GREEN,1,0.4,nameBox)
    local saveBtn=NEW("TextButton",{Size=UDim2.new(0,116,0,32),Position=UDim2.new(1,-126,0,54),BackgroundColor3=C(6,30,12),TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=11,Text="SAVE PROFILE",AutoButtonColor=false,ZIndex=602},panel); CORNER(7,saveBtn); STROKE(GREEN,1,0.2,saveBtn)
    saveBtn.MouseButton1Click:Connect(function() MultiConfig.CreateProfile(nameBox.Text); nameBox.Text="" end)
    FX.Ripple(saveBtn, GREEN)

    -- Profile list
    NEW("TextLabel",{Text="SAVED PROFILES",Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,96),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=602},panel)
    local pList=NEW("ScrollingFrame",{Size=UDim2.new(1,-20,0,160),Position=UDim2.new(0,10,0,114),BackgroundColor3=BG1,ScrollBarThickness=2,ScrollBarImageColor3=GREEN,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=602},panel); CORNER(8,pList); STROKE(C(20,40,24),1,0.3,pList)
    NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Center},pList)
    NEW("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},pList)

    local function refreshList()
        for _,ch in ipairs(pList:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        local any = false
        for pName, _ in pairs(MultiConfig._data.profiles) do
            any = true
            local row=NEW("Frame",{Size=UDim2.new(1,-10,0,36),BackgroundColor3=BG3,BorderSizePixel=0,ZIndex=603},pList); CORNER(7,row)
            local isActive=(MultiConfig._data.active==pName)
            STROKE(isActive and GREEN or C(28,40,28),1,isActive and 0 or 0.5,row)
            NEW("TextLabel",{Text=(isActive and "▸ " or "  ")..pName,Size=UDim2.new(1,-90,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=isActive and GREEN or TEXT1,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=604},row)
            local loadB=NEW("TextButton",{Text="LOAD",Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-86,0.5,-12),BackgroundColor3=BG4,TextColor3=CYAN,Font=Enum.Font.GothamBold,TextSize=9,AutoButtonColor=false,ZIndex=604},row); CORNER(5,loadB); STROKE(CYAN,1,0.3,loadB)
            local delB =NEW("TextButton",{Text="✕",   Size=UDim2.new(0,28,0,24),Position=UDim2.new(1,-32,0.5,-12),BackgroundColor3=BG4,TextColor3=RED,Font=Enum.Font.GothamBold,TextSize=11,AutoButtonColor=false,ZIndex=604},row); CORNER(5,delB); STROKE(RED,1,0.4,delB)
            local pn=pName
            loadB.MouseButton1Click:Connect(function() MultiConfig.LoadProfile(pn); refreshList() end)
            delB.MouseButton1Click:Connect(function()
                Confirm("Delete Profile","Delete '"..pn.."'? This cannot be undone.",function() MultiConfig.DeleteProfile(pn); refreshList() end)
            end)
        end
        if not any then
            NEW("TextLabel",{Text="No saved profiles yet",Size=UDim2.new(1,-10,0,36),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=603},pList)
        end
    end
    refreshList()

    -- Import/Export section
    NEW("Frame",{Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,0,285),BackgroundColor3=C(28,26,48),BorderSizePixel=0,ZIndex=602},panel)
    NEW("TextLabel",{Text="IMPORT / EXPORT  (base64)",Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,292),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=602},panel)

    local ieBox=NEW("TextBox",{Size=UDim2.new(1,-20,0,72),Position=UDim2.new(0,10,0,310),BackgroundColor3=BG5,PlaceholderText=" Paste config string here to import, or export to fill this...",Text="",TextColor3=TEXT1,Font=Enum.Font.Gotham,TextSize=10,TextWrapped=true,MultiLine=true,ZIndex=602},panel); CORNER(7,ieBox); STROKE(AMBER,1,0.4,ieBox)

    local expB=NEW("TextButton",{Text="EXPORT CONFIG",Size=UDim2.new(0.5,-14,0,32),Position=UDim2.new(0,10,0,390),BackgroundColor3=C(30,26,6),TextColor3=AMBER,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,ZIndex=602},panel); CORNER(7,expB); STROKE(AMBER,1,0.2,expB)
    local impB=NEW("TextButton",{Text="IMPORT CONFIG",Size=UDim2.new(0.5,-14,0,32),Position=UDim2.new(0.5,4,0,390),BackgroundColor3=C(8,18,40),TextColor3=CYAN,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,ZIndex=602},panel); CORNER(7,impB); STROKE(CYAN,1,0.2,impB)

    expB.MouseButton1Click:Connect(function()
        local encoded = MultiConfig.Export(); ieBox.Text = encoded
        Toast("Config exported! Copy the string above.", AMBER, "↑")
    end)
    impB.MouseButton1Click:Connect(function()
        MultiConfig.Import(ieBox.Text)
    end)
    FX.Ripple(expB, AMBER); FX.Ripple(impB, CYAN)

    local statusLbl=NEW("TextLabel",{Text="Active: "..(MultiConfig._data.active or "none"),Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,432),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=602},panel)

    -- Drag
    local d,ds,sp
    hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;ds=i.Position;sp=panel.Position end end)
    UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then local dt=i.Position-ds;panel.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dt.X,sp.Y.Scale,sp.Y.Offset+dt.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
end

GBO.MultiConfig.OpenUI = MultiConfig.OpenUI

-- =====================================================================
-- 13 · MISC PANEL
-- Draggable secondary window. Accent: MISC_COL (violet).
-- Sections: Change Character, Change Display Name, + Utility features.
-- =====================================================================
local _miscOpen = false

local function OpenMiscPanel()
    local old = ExtGui:FindFirstChild("MiscPanel")
    if old then
        TWEEN(old, 0.15, {GroupTransparency=1})
        task.delay(0.16, function() pcall(function() old:Destroy() end) end)
        _miscOpen = false; return
    end
    _miscOpen = true

    local panel = NEW("Frame", {
        Name="MiscPanel", Size=UDim2.new(0,420,0,560),
        Position=UDim2.new(0.5,-210,0.5,-280), BackgroundColor3=BG2,
        BorderSizePixel=0, ZIndex=550
    }, ExtGui)
    CORNER(14, panel)
    local pStrk = STROKE(MISC_COL, 1.8, 0.2, panel)
    panel.GroupTransparency = 1; TWEEN_B(panel, 0.32, {GroupTransparency=0})

    -- Gradient bg
    local _mpGrad = Instance.new("UIGradient")
    _mpGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,C(11,8,24)),ColorSequenceKeypoint.new(1,C(7,5,16))})
    _mpGrad.Rotation = 145; _mpGrad.Parent = panel

    -- Stripe glow pulse
    task.spawn(function()
        while panel and panel.Parent do
            TWEEN(pStrk, 1.5, {Transparency=0.05})
            task.wait(1.7)
            TWEEN(pStrk, 1.5, {Transparency=0.3})
            task.wait(1.7)
        end
    end)

    -- Header
    local hdr = NEW("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=BG_HDR,ZIndex=551},panel)
    CORNER(12,hdr); NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG_HDR,BorderSizePixel=0,ZIndex=551},hdr)
    -- Accent line
    local acLine=NEW("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=MISC_COL,BorderSizePixel=0,ZIndex=552},hdr)
    local acGrad=Instance.new("UIGradient"); acGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,MISC_COL),ColorSequenceKeypoint.new(0.5,PINK),ColorSequenceKeypoint.new(1,BLUE_A)}); acGrad.Parent=acLine
    -- Logo bar
    NEW("Frame",{Size=UDim2.new(0,3,0.55,0),Position=UDim2.new(0,12,0.225,0),BackgroundColor3=MISC_COL,BorderSizePixel=0,ZIndex=553},hdr)
    NEW("TextLabel",{Text="✦  MISC",Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0,22,0,0),BackgroundTransparency=1,TextColor3=MISC_COL,Font=Enum.Font.GothamBlack,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=553},hdr)
    NEW("TextLabel",{Text="Miscellaneous Utilities",Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0.4,0,0,0),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=553},hdr)
    local closeM=NEW("TextButton",{Text="✕",Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-36,0.5,-14),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=15,ZIndex=553},hdr)
    closeM.MouseButton1Click:Connect(function() TWEEN(panel,0.18,{GroupTransparency=1}); task.delay(0.2,function() pcall(function() panel:Destroy() end) end); _miscOpen=false end)

    -- Scroll container
    local scroll=NEW("ScrollingFrame",{Size=UDim2.new(1,-16,1,-58),Position=UDim2.new(0,8,0,56),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=MISC_COL,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=551},panel)
    NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,10),HorizontalAlignment=Enum.HorizontalAlignment.Center},scroll)
    NEW("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10)},scroll)

    -- Helper: card builder
    local function MCard(h)
        local c=NEW("Frame",{Size=UDim2.new(1,-8,0,h),BackgroundColor3=BG3,BorderSizePixel=0,ZIndex=552},scroll); CORNER(10,c); STROKE(C(35,28,60),1,0.4,c); return c
    end
    local function MHeader(card, label, col)
        col=col or MISC_COL
        NEW("Frame",{Size=UDim2.new(0,3,0.5,0),Position=UDim2.new(0,0,0.25,0),BackgroundColor3=col,BorderSizePixel=0,ZIndex=553},card)
        NEW("TextLabel",{Text=label,Size=UDim2.new(1,-12,0,18),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,TextColor3=col,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=553},card)
    end

    -- Helper: dropdown builder
    local function MakeDropdown(parent, yPos, items, onSelect, placeholder)
        local bg=NEW("Frame",{Size=UDim2.new(1,-24,0,30),Position=UDim2.new(0,12,0,yPos),BackgroundColor3=BG5,BorderSizePixel=0,ZIndex=554},parent); CORNER(7,bg); local bgS=STROKE(MISC_COL,1,0.5,bg)
        local lbl=NEW("TextLabel",{Text=placeholder or "Select...",Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=555},bg)
        NEW("TextLabel",{Text="▾",Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),BackgroundTransparency=1,TextColor3=MISC_COL,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=555},bg)
        local _ddOpen=false; local _ddList=nil
        local function openDD()
            if _ddList then pcall(function() _ddList:Destroy() end); _ddList=nil; _ddOpen=false; return end
            _ddOpen=true; TWEEN(bgS,0.15,{Transparency=0,Color=MISC_COL})
            local ddPos=bg.AbsolutePosition; local ddSz=bg.AbsoluteSize
            _ddList=NEW("ScrollingFrame",{Size=UDim2.new(0,ddSz.X,0,math.min(#items*32,160)),Position=UDim2.new(0,ddPos.X,0,ddPos.Y+ddSz.Y+4),BackgroundColor3=BG1,ScrollBarThickness=2,ScrollBarImageColor3=MISC_COL,CanvasSize=UDim2.new(0,0,0,#items*32),ZIndex=700,BorderSizePixel=0},ExtGui)
            CORNER(8,_ddList); STROKE(MISC_COL,1.2,0.2,_ddList)
            for idx,item in ipairs(items) do
                local ib=NEW("TextButton",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,(idx-1)*32),BackgroundTransparency=1,Text=item,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=701},_ddList)
                NEW("UIPadding",{PaddingLeft=UDim.new(0,12)},ib)
                ib.MouseEnter:Connect(function() TWEEN(ib,0.1,{BackgroundTransparency=0.6,BackgroundColor3=MISC_COL}) end)
                ib.MouseLeave:Connect(function() TWEEN(ib,0.1,{BackgroundTransparency=1}) end)
                ib.MouseButton1Click:Connect(function()
                    lbl.Text=item; lbl.TextColor3=TEXT1
                    pcall(function() _ddList:Destroy() end); _ddList=nil; _ddOpen=false
                    TWEEN(bgS,0.15,{Transparency=0.5}); if onSelect then onSelect(item) end
                end)
            end
        end
        bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then openDD() end end)
        return {bg=bg, label=lbl}
    end

    -- ── CARD 1: CHANGE CHARACTER ───────────────────────────────────
    local charCard = MCard(110)
    MHeader(charCard, "👤  CHANGE CHARACTER", MISC_COL)

    -- Character list — fill from ReplicatedStorage or use defaults
    local charList = {}
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local chars = RS:FindFirstChild("Characters")
        if chars then
            for _, ch in ipairs(chars:GetChildren()) do
                table.insert(charList, ch.Name)
            end
        end
    end)
    if #charList == 0 then
        charList = {"Default","Character_01","Character_02","Character_03",
                    "Character_04","Character_05","Character_06"}
    end
    table.sort(charList)

    local charDD = MakeDropdown(charCard, 36, charList, function(selected)
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local setEv = RS:WaitForChild("Events"):WaitForChild("set")
            setEv:FireServer("Character", selected)
        end)
        Toast("Character → " .. selected, MISC_COL, "👤")
    end, "Select character...")

    local applyCharBtn=NEW("TextButton",{Text="APPLY",Size=UDim2.new(0,80,0,26),Position=UDim2.new(1,-92,0,76),BackgroundColor3=C(20,10,40),TextColor3=MISC_COL,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,ZIndex=553},charCard); CORNER(7,applyCharBtn); STROKE(MISC_COL,1,0.3,applyCharBtn)
    applyCharBtn.MouseButton1Click:Connect(function()
        local sel = charDD.label.Text
        if sel == "Select character..." then Toast("Please select a character first", AMBER, "⚠"); return end
        pcall(function()
            local RS=game:GetService("ReplicatedStorage")
            local setEv=RS:WaitForChild("Events"):WaitForChild("set")
            setEv:FireServer("Character", sel)
        end)
        Toast("Applied character: "..sel, MISC_COL, "✓")
    end)
    FX.Ripple(applyCharBtn, MISC_COL)

    -- ── CARD 2: CHANGE DISPLAY NAME ───────────────────────────────
    local nameCard = MCard(110)
    MHeader(nameCard, "✏  CHANGE DISPLAY NAME", PINK)

    -- Display name list
    local nameList = {}
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local names = RS:FindFirstChild("DisplayNames")
        if names then
            for _, n in ipairs(names:GetChildren()) do
                table.insert(nameList, n.Name)
            end
        end
    end)
    if #nameList == 0 then
        nameList = {"Player","Rookie","Explorer","Veteran","Champion",
                    "Legend","Mythic","Supreme","Nova","Shadow","Zili"}
    end
    table.sort(nameList)

    local nameDD = MakeDropdown(nameCard, 36, nameList, function(selected)
        pcall(function()
            local RS=game:GetService("ReplicatedStorage")
            local setEv=RS:WaitForChild("Events"):WaitForChild("set")
            setEv:FireServer("DisplayName", selected)
        end)
        Toast("Display Name → " .. selected, PINK, "✏")
    end, "Select display name...")

    local applyNameBtn=NEW("TextButton",{Text="APPLY",Size=UDim2.new(0,80,0,26),Position=UDim2.new(1,-92,0,76),BackgroundColor3=C(40,8,30),TextColor3=PINK,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,ZIndex=553},nameCard); CORNER(7,applyNameBtn); STROKE(PINK,1,0.3,applyNameBtn)
    applyNameBtn.MouseButton1Click:Connect(function()
        local sel = nameDD.label.Text
        if sel == "Select display name..." then Toast("Please select a name first", AMBER, "⚠"); return end
        pcall(function()
            local RS=game:GetService("ReplicatedStorage")
            local setEv=RS:WaitForChild("Events"):WaitForChild("set")
            setEv:FireServer("DisplayName", sel)
        end)
        Toast("Applied name: "..sel, PINK, "✓")
    end)
    FX.Ripple(applyNameBtn, PINK)

    -- ── CARD 3: PANIC + KEYBINDS ──────────────────────────────────
    local utilCard = MCard(130)
    MHeader(utilCard, "⚡  QUICK UTILITIES", AMBER)

    -- Panic button
    local panicBtn=NEW("TextButton",{Text="🚨  PANIC — STOP ALL FEATURES",Size=UDim2.new(1,-24,0,34),Position=UDim2.new(0,12,0,36),BackgroundColor3=C(40,8,8),TextColor3=RED,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=false,ZIndex=553},utilCard); CORNER(8,panicBtn); STROKE(RED,1.5,0.2,panicBtn)
    panicBtn.MouseEnter:Connect(function() TWEEN(panicBtn,0.1,{BackgroundColor3=C(60,12,12)}) end)
    panicBtn.MouseLeave:Connect(function() TWEEN(panicBtn,0.1,{BackgroundColor3=C(40,8,8)}) end)
    panicBtn.MouseButton1Click:Connect(function()
        Confirm("Panic","Stop ALL active features right now?", function() GBO.Panic.Fire() end)
    end)
    FX.Ripple(panicBtn, RED)

    -- Keybind Manager button
    local kbBtn2=NEW("TextButton",{Text="⌨  KEYBIND MANAGER",Size=UDim2.new(0.5,-16,0,30),Position=UDim2.new(0,12,0,80),BackgroundColor3=BG4,TextColor3=PURPLE,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,ZIndex=553},utilCard); CORNER(7,kbBtn2); STROKE(PURPLE,1,0.3,kbBtn2)
    kbBtn2.MouseButton1Click:Connect(function() GBO.Keybind.OpenUI() end)
    FX.Ripple(kbBtn2, PURPLE)

    -- Multi-Config button
    local cfgBtn2=NEW("TextButton",{Text="⚙  PROFILES / CONFIG",Size=UDim2.new(0.5,-16,0,30),Position=UDim2.new(0.5,4,0,80),BackgroundColor3=BG4,TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,ZIndex=553},utilCard); CORNER(7,cfgBtn2); STROKE(GREEN,1,0.3,cfgBtn2)
    cfgBtn2.MouseButton1Click:Connect(function() GBO.MultiConfig.OpenUI() end)
    FX.Ripple(cfgBtn2, GREEN)

    -- Panic key label
    NEW("TextLabel",{Text="Panic Key: "..tostring(GBO.Panic._key):gsub("Enum.KeyCode.",""),Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,120),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=553},utilCard)

    -- ── CARD 4: CURSOR TRAIL + VISUAL TOGGLES ─────────────────────
    local vfxCard = MCard(90)
    MHeader(vfxCard, "✨  VISUAL SETTINGS", CYAN)

    -- Cursor trail toggle
    local _trailOn = true
    local trailPill=NEW("TextButton",{Size=UDim2.new(0,48,0,24),Position=UDim2.new(1,-58,0,36),BackgroundColor3=BG5,Text="",AutoButtonColor=false,ZIndex=553},vfxCard); CORNER(20,trailPill); local trailS=STROKE(CYAN,1.2,0.3,trailPill)
    local trailTh=NEW("Frame",{Size=UDim2.new(0,17,0,17),Position=UDim2.new(1,-21,0.5,-8.5),BackgroundColor3=CYAN,BorderSizePixel=0,ZIndex=554},trailPill); CORNER(20,trailTh)
    NEW("TextLabel",{Text="Cursor Trail",Size=UDim2.new(0.75,0,0,24),Position=UDim2.new(0,12,0,36),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=553},vfxCard)
    trailPill.MouseButton1Click:Connect(function()
        _trailOn=not _trailOn; FX.SetTrailEnabled(_trailOn)
        TWEEN(trailPill,0.2,{BackgroundColor3=_trailOn and C(5,38,40) or BG5})
        TWEEN(trailS,0.2,{Color=_trailOn and CYAN or C(60,55,82),Transparency=_trailOn and 0 or 0.3})
        TWEEN(trailTh,0.2,{BackgroundColor3=_trailOn and CYAN or C(60,55,82),Position=_trailOn and UDim2.new(1,-21,0.5,-8.5) or UDim2.new(0,4,0.5,-8.5)})
    end)

    -- UserCard toggle
    local _ucOn = true
    local ucPill=NEW("TextButton",{Size=UDim2.new(0,48,0,24),Position=UDim2.new(1,-58,0,62),BackgroundColor3=C(20,10,40),Text="",AutoButtonColor=false,ZIndex=553},vfxCard); CORNER(20,ucPill); local ucS=STROKE(MISC_COL,1.2,0,ucPill)
    local ucTh=NEW("Frame",{Size=UDim2.new(0,17,0,17),Position=UDim2.new(1,-21,0.5,-8.5),BackgroundColor3=MISC_COL,BorderSizePixel=0,ZIndex=554},ucPill); CORNER(20,ucTh)
    NEW("TextLabel",{Text="Show User Card",Size=UDim2.new(0.75,0,0,24),Position=UDim2.new(0,12,0,62),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=553},vfxCard)
    ucPill.MouseButton1Click:Connect(function()
        _ucOn=not _ucOn; _ucCard.Visible=_ucOn
        TWEEN(ucPill,0.2,{BackgroundColor3=_ucOn and C(20,10,40) or BG5})
        TWEEN(ucS,0.2,{Color=_ucOn and MISC_COL or C(60,55,82),Transparency=_ucOn and 0 or 0.3})
        TWEEN(ucTh,0.2,{BackgroundColor3=_ucOn and MISC_COL or C(60,55,82),Position=_ucOn and UDim2.new(1,-21,0.5,-8.5) or UDim2.new(0,4,0.5,-8.5)})
    end)

    -- ── CARD 5: SESSION STATS ─────────────────────────────────────
    local sessCard = MCard(86)
    MHeader(sessCard, "📊  SESSION STATS", GREEN)

    local function _fmtTime(s) local h=math.floor(s/3600);local m=math.floor((s%3600)/60);local sec=math.floor(s%60);return string.format("%02d:%02d:%02d",h,m,sec) end
    local _sessTimeLbl=NEW("TextLabel",{Text="",Size=UDim2.new(1,-24,0,18),Position=UDim2.new(0,12,0,32),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=553},sessCard)
    local _sessCtLbl=NEW("TextLabel",{Text="",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,54),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=553},sessCard)
    task.spawn(function()
        while sessCard and sessCard.Parent do
            local elapsed = tick() - Profile._sessionStart
            local total = 0
            for _, v in pairs(Profile.data.usageCount) do total += v end
            _sessTimeLbl.Text = "⏱  " .. _fmtTime(elapsed)
            _sessCtLbl.Text   = "Feature uses this session: " .. total .. "  ·  Sessions: " .. Profile.data.sessions
            task.wait(1)
        end
    end)

    -- Drag
    local d,ds,sp
    hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;ds=i.Position;sp=panel.Position end end)
    UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then local dt=i.Position-ds;panel.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dt.X,sp.Y.Scale,sp.Y.Offset+dt.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
end

GBO.MiscPanel = OpenMiscPanel

-- =====================================================================
-- 14 · CLOSE CONFIRMATION HOOK
-- Wraps _G._GBO_HideHub so it asks for confirmation first.
-- =====================================================================
local _origHide = _G._GBO_HideHub
_G._GBO_HideHub = function()
    Confirm("Hide Hub", "Hide the main hub window?",
        function() if _origHide then _origHide() end end,
        nil)
end

-- =====================================================================
-- 15 · EXPORTS & FINAL INIT
-- =====================================================================
_G.GBO = GBO

-- Apply ripple to Quick Bar buttons retroactively (they're already built)
task.defer(function()
    for _, ch in ipairs(_qbList:GetChildren()) do
        if ch:IsA("TextButton") then FX.Ripple(ch, GOLD2) end
    end
end)

-- First XP pull
task.delay(3, function()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local stats = RS:FindFirstChild("Stats" .. LocalPlayer.Name)
        if stats then
            local lv  = stats:FindFirstChild("Level")
            local xpV = stats:FindFirstChild("EXP")
            if lv and xpV then GBO.XPBar.Update(lv.Value, xpV.Value) end
        end
    end)
end)

Toast("GBO Extensions loaded ✓", MISC_COL, "✦")

-- Panic key reminder
task.delay(5, function()
    Toast("Panic key: DELETE  ·  Misc: click ✦ in Quick Bar", TEXT2, "ℹ")
end)

-- =====================================================================
-- QUICK REFERENCE  (print to console)
-- =====================================================================
-- _G.GBO.Confirm(title, msg, onYes)        -- show confirm dialog
-- _G.GBO.Panic.Fire()                      -- kill all features
-- _G.GBO.Panic.SetKey(Enum.KeyCode.Delete) -- change panic key
-- _G.GBO.Keybind.Register(key, name, kc)   -- add feature keybind
-- _G.GBO.Keybind.OpenUI()                  -- open rebind window
-- _G.GBO.QuickBar.Pin(key, icon, label)    -- pin to quick bar
-- _G.GBO.QuickBar.Unpin(key)               -- remove pin
-- _G.GBO.StatsOverlay.AddEXP(n)            -- feed EXP/hr counter
-- _G.GBO.StatsOverlay.AddFish(n)           -- feed Fish/hr counter
-- _G.GBO.MythicLog.OnChest()               -- record mythic chest
-- _G.GBO.XPBar.Update(level, xp)           -- update XP bar
-- _G.GBO.FX.Ripple(btn, col)               -- wire ripple to button
-- _G.GBO.FX.CardGlow(frame, on, col)       -- toggle card border glow
-- _G.GBO.FX.SetTrailEnabled(bool)          -- cursor trail on/off
-- _G.GBO.MultiConfig.CreateProfile(name)   -- save current config
-- _G.GBO.MultiConfig.LoadProfile(name)     -- load a config
-- _G.GBO.MultiConfig.Export()              -- returns base64 string
-- _G.GBO.MultiConfig.Import(str)           -- load from base64
-- _G.GBO.MultiConfig.OpenUI()              -- open config manager UI
-- _G.GBO.MiscPanel()                       -- toggle Misc window
-- _G.GBO.Profile.AddUse(featureKey)        -- track feature usage
-- =====================================================================
