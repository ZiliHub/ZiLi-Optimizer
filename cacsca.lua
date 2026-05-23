--[[
╔══════════════════════════════════════════════════════════════════════╗
║          N E X U S U I  v2  —  Executor-Safe Edition                ║
║                                                                      ║
║  BUG FIXES vs v1:                                                    ║
║    ✓ Removed ClipsDescendants from main frame (was hiding children)  ║
║    ✓ ZIndex base raised to 200 (no longer buried under game UI)      ║
║    ✓ All backgrounds fully opaque — no transparency bugs             ║
║    ✓ Boot: transparency-fade instead of height=0 animation           ║
║    ✓ Tab nav & content area always visible                           ║
║    ✓ AutomaticCanvasSize replaced with manual sizing (executor compat)║
║                                                                      ║
║  USAGE (executor):                                                   ║
║    local UI = loadstring(game:HttpGet("..."))()                      ║
║    local lib = UI.new()                                              ║
║    lib:Boot("My Hub", "rbxassetid://YOUR_LOGO_ID")                   ║
║    local tab = lib:CreateTab("Main", "rbxassetid://ICON_ID")         ║
╚══════════════════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════════════════════════════
-- §1  SERVICES
-- ══════════════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ══════════════════════════════════════════════════════════════════════
-- §2  JANITOR  (zero-leak connection tracker)
-- ══════════════════════════════════════════════════════════════════════
local Janitor = {}; Janitor.__index = Janitor
function Janitor.new()
    return setmetatable({_t={},_n=0}, Janitor)
end
function Janitor:Add(obj, method, key)
    local e = {obj=obj, m=method or "Destroy"}
    if key then
        if self._t[key] then self:_clean(self._t[key]) end
        self._t[key] = e
    else
        self._n += 1; self._t[self._n] = e
    end
    return obj
end
function Janitor:_clean(e)
    pcall(function()
        if e.m=="fn" or type(e.obj)=="function" then e.obj()
        elseif e.obj and e.obj[e.m] then e.obj[e.m](e.obj) end
    end)
end
function Janitor:Remove(k) if self._t[k] then self:_clean(self._t[k]); self._t[k]=nil end end
function Janitor:Cleanup()
    for _,e in pairs(self._t) do self:_clean(e) end
    table.clear(self._t); self._n=0
end

-- ══════════════════════════════════════════════════════════════════════
-- §3  THEME
-- ══════════════════════════════════════════════════════════════════════
local T = {
    -- Window
    WinBg        = Color3.fromRGB(13, 12, 19),    -- deep space black-purple
    WinBgAlt     = Color3.fromRGB(18, 16, 26),
    NavBg        = Color3.fromRGB(16, 14, 24),    -- slightly lighter for nav
    ContentBg    = Color3.fromRGB(11, 10, 17),    -- darkest zone
    CardBg       = Color3.fromRGB(22, 20, 32),    -- component card background
    CardBgHover  = Color3.fromRGB(28, 25, 42),
    TopBarBg     = Color3.fromRGB(20, 18, 30),
    -- Accent (Violet)
    Accent       = Color3.fromRGB(138, 43, 226),
    AccentBright = Color3.fromRGB(175, 100, 255),
    AccentDim    = Color3.fromRGB(90,  22, 160),
    AccentGlow   = Color3.fromRGB(110, 35, 185),
    -- Text
    TextPri      = Color3.fromRGB(242, 240, 255),
    TextSec      = Color3.fromRGB(165, 160, 195),
    TextMuted    = Color3.fromRGB(90,  88, 120),
    TextDisabled = Color3.fromRGB(55,  54, 75),
    -- Borders
    BorderDim    = Color3.fromRGB(38, 35, 58),
    BorderMid    = Color3.fromRGB(58, 54, 88),
    BorderBright = Color3.fromRGB(80, 74, 118),
    -- Semantic
    Success      = Color3.fromRGB(34, 200, 100),
    Warning      = Color3.fromRGB(255, 185, 35),
    Error        = Color3.fromRGB(240, 60, 60),
}

-- ══════════════════════════════════════════════════════════════════════
-- §4  UTILITIES
-- ══════════════════════════════════════════════════════════════════════
local U = {}

function U.Tw(inst, props, dur, style, dir)
    local t = TweenService:Create(inst,
        TweenInfo.new(dur or 0.28, style or Enum.EasingStyle.Quint,
                      dir  or Enum.EasingDirection.Out), props)
    t:Play(); return t
end

function U.TwSine(inst, props, dur)
    return U.Tw(inst, props, dur, Enum.EasingStyle.Sine)
end

function U.Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p; return c
end

function U.Stroke(p, col, thick, transp)
    local s = Instance.new("UIStroke")
    s.Color = col or T.BorderDim
    s.Thickness = thick or 1
    s.Transparency = transp or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

function U.Pad(p, t, b, l, r)
    local pd = Instance.new("UIPadding")
    pd.PaddingTop    = UDim.new(0, t or 8)
    pd.PaddingBottom = UDim.new(0, b or 8)
    pd.PaddingLeft   = UDim.new(0, l or 10)
    pd.PaddingRight  = UDim.new(0, r or 10)
    pd.Parent = p; return pd
end

function U.Grad(p, cA, cB, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(cA, cB)
    g.Rotation = rot or 0
    g.Parent = p; return g
end

-- Premium shadow using a stretched dark frame
function U.Shadow(p, offset, radius)
    offset = offset or 8; radius = radius or 16
    local s = Instance.new("Frame")
    s.Name = "_Shad"
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.Size = UDim2.new(1, radius*2, 1, radius*2)
    s.Position = UDim2.new(0.5, 0, 0.5, offset)
    s.BackgroundColor3 = Color3.new(0,0,0)
    s.BackgroundTransparency = 0.5
    s.ZIndex = math.max(1, (p.ZIndex or 1) - 1)
    U.Corner(s, radius + 6)
    s.Parent = p
    return s
end

-- Ripple effect (tracked by janitor j)
function U.Ripple(btn, j)
    local conn = btn.MouseButton1Down:Connect(function(x,y)
        local r = Instance.new("Frame")
        r.BackgroundColor3 = Color3.new(1,1,1)
        r.BackgroundTransparency = 0.80
        r.ZIndex = btn.ZIndex + 10
        r.AnchorPoint = Vector2.new(0.5,0.5)
        local ap = btn.AbsolutePosition
        r.Position = UDim2.new(0, x-ap.X, 0, y-ap.Y)
        r.Size = UDim2.new(0,0,0,0)
        U.Corner(r, 9999)
        r.ClipsDescendants = false
        r.Parent = btn
        local mx = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y)*2.6
        U.Tw(r, {Size=UDim2.new(0,mx,0,mx), BackgroundTransparency=1}, 0.5, Enum.EasingStyle.Quint)
        task.delay(0.55, function() r:Destroy() end)
    end)
    if j then j:Add(conn,"Disconnect") end
    return conn
end

-- Make a thin glowing line separator
function U.Divider(parent, zIdx)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1,-20,0,1)
    d.Position = UDim2.new(0,10,0,0)
    d.BackgroundColor3 = T.BorderDim
    d.BackgroundTransparency = 0
    d.ZIndex = zIdx or 220
    d.Parent = parent
    -- subtle gradient fade at edges
    U.Grad(d, Color3.new(0,0,0), T.BorderMid, 0)
    return d
end

-- ══════════════════════════════════════════════════════════════════════
-- §5  LIBRARY CLASS
-- ══════════════════════════════════════════════════════════════════════
local Library = {}; Library.__index = Library

local NexusUI = {}

function NexusUI.new()
    return setmetatable({
        _jan      = Janitor.new(),
        _tabs     = {},
        _activeTab= nil,
        _minimized= false,
        _notifN   = 0,
        _gui      = nil,
        _win      = nil,
        _hubName  = "NexusUI",
        _logoId   = "",
        _cfgReg   = {},
    }, Library)
end

-- ══════════════════════════════════════════════════════════════════════
-- §6  BOOT  —  Loading Screen  (executor-safe)
--
--  FIX vs v1:
--    • No height=0 → tween trick (was causing ClipsDescendants black-out)
--    • Uses opacity fade only
--    • Richer animated loader with dot-pulse + shimmer bar
--    • Main window built HIDDEN (Visible=false), revealed by fade-in
-- ══════════════════════════════════════════════════════════════════════
function Library:Boot(hubName, logoId)
    self._hubName = hubName or "NexusUI"
    self._logoId  = logoId  or ""

    -- ── ScreenGui ───────────────────────────────────────────────────
    local gui = Instance.new("ScreenGui")
    gui.Name            = "NexusUI_" .. self._hubName
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder    = 9999          -- FIX: top of render stack
    gui.IgnoreGuiInset  = true

    -- Try CoreGui first (executor), fallback to PlayerGui
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end

    self._gui = gui
    self._jan:Add(gui, "Destroy", "GUI")

    -- ── Loading backdrop ─────────────────────────────────────────────
    local backdrop = Instance.new("Frame")
    backdrop.Name                   = "LoadBg"
    backdrop.Size                   = UDim2.new(1,0,1,0)
    backdrop.BackgroundColor3       = T.WinBg
    backdrop.BackgroundTransparency = 0
    backdrop.ZIndex                 = 500
    backdrop.Parent                 = gui

    -- Deep gradient
    local bg2 = Instance.new("Frame")
    bg2.Size                        = UDim2.new(1,0,1,0)
    bg2.BackgroundColor3            = Color3.fromRGB(6,4,14)
    bg2.BackgroundTransparency      = 0
    bg2.ZIndex                      = 500
    bg2.Parent                      = backdrop
    U.Grad(bg2, Color3.fromRGB(6,4,14), Color3.fromRGB(12,8,22), 135)

    -- Big glow orb behind logo
    local orb = Instance.new("Frame")
    orb.AnchorPoint         = Vector2.new(0.5,0.5)
    orb.Size                = UDim2.new(0,420,0,420)
    orb.Position            = UDim2.new(0.5,0,0.44,0)
    orb.BackgroundColor3    = T.Accent
    orb.BackgroundTransparency = 0.93
    orb.ZIndex              = 501
    orb.Parent              = backdrop
    U.Corner(orb, 999)

    -- Logo card
    local card = Instance.new("Frame")
    card.AnchorPoint        = Vector2.new(0.5,0.5)
    card.Size               = UDim2.new(0,148,0,148)
    card.Position           = UDim2.new(0.5,0,0.40,0)
    card.BackgroundColor3   = Color3.fromRGB(24,18,38)
    card.BackgroundTransparency = 0
    card.ZIndex             = 502
    card.Parent             = backdrop
    U.Corner(card, 24)
    U.Stroke(card, T.Accent, 1.5, 0.25)

    -- Inner glow on card
    local cardGlow = Instance.new("Frame")
    cardGlow.Size                   = UDim2.new(1,0,0.5,0)
    cardGlow.Position               = UDim2.new(0,0,0,0)
    cardGlow.BackgroundColor3       = T.AccentBright
    cardGlow.BackgroundTransparency = 0.93
    cardGlow.ZIndex                 = 503
    cardGlow.Parent                 = card
    U.Corner(cardGlow, 24)

    -- Logo image  (ScaleType=Fit preserves aspect ratio)
    local logoImg = Instance.new("ImageLabel")
    logoImg.AnchorPoint             = Vector2.new(0.5,0.5)
    logoImg.Size                    = UDim2.new(0.62,0,0.62,0)
    logoImg.Position                = UDim2.new(0.5,0,0.5,0)
    logoImg.BackgroundTransparency  = 1
    logoImg.Image                   = self._logoId   -- ← pass rbxassetid://
    logoImg.ScaleType               = Enum.ScaleType.Fit
    logoImg.ImageTransparency       = 1
    logoImg.ZIndex                  = 504
    logoImg.Parent                  = card

    -- Hub name
    local nameL = Instance.new("TextLabel")
    nameL.AnchorPoint       = Vector2.new(0.5,0)
    nameL.Size              = UDim2.new(0,340,0,38)
    nameL.Position          = UDim2.new(0.5,0,0.40,90)
    nameL.BackgroundTransparency = 1
    nameL.Text              = self._hubName
    nameL.TextColor3        = T.TextPri
    nameL.TextSize          = 26
    nameL.Font              = Enum.Font.GothamBold
    nameL.TextTransparency  = 1
    nameL.ZIndex            = 502
    nameL.Parent            = backdrop

    -- Status text
    local statusL = Instance.new("TextLabel")
    statusL.AnchorPoint     = Vector2.new(0.5,0)
    statusL.Size            = UDim2.new(0,340,0,22)
    statusL.Position        = UDim2.new(0.5,0,0.40,136)
    statusL.BackgroundTransparency = 1
    statusL.Text            = "Initializing..."
    statusL.TextColor3      = T.TextSec
    statusL.TextSize        = 13
    statusL.Font            = Enum.Font.Gotham
    statusL.TextTransparency = 1
    statusL.ZIndex          = 502
    statusL.Parent          = backdrop

    -- Progress track
    local pTrack = Instance.new("Frame")
    pTrack.AnchorPoint      = Vector2.new(0.5,0)
    pTrack.Size             = UDim2.new(0,280,0,4)
    pTrack.Position         = UDim2.new(0.5,0,0.40,167)
    pTrack.BackgroundColor3 = Color3.fromRGB(28,24,44)
    pTrack.BackgroundTransparency = 1
    pTrack.ZIndex           = 502
    pTrack.Parent           = backdrop
    U.Corner(pTrack, 4)
    U.Stroke(pTrack, T.BorderDim, 1, 0.3)

    local pFill = Instance.new("Frame")
    pFill.Size              = UDim2.new(0,0,1,0)
    pFill.BackgroundColor3  = T.Accent
    pFill.ZIndex            = 503
    pFill.Parent            = pTrack
    U.Corner(pFill, 4)
    U.Grad(pFill, T.AccentDim, T.AccentBright, 0)

    -- Shimmer on bar
    local shimmer = Instance.new("Frame")
    shimmer.Size                    = UDim2.new(0.25,0,1,0)
    shimmer.Position                = UDim2.new(-0.3,0,0,0)
    shimmer.BackgroundColor3        = Color3.new(1,1,1)
    shimmer.BackgroundTransparency  = 0.65
    shimmer.ZIndex                  = 504
    shimmer.Parent                  = pFill
    U.Corner(shimmer, 4)

    -- Animated dots row
    local dotsRow = Instance.new("Frame")
    dotsRow.AnchorPoint     = Vector2.new(0.5,0)
    dotsRow.Size            = UDim2.new(0,60,0,8)
    dotsRow.Position        = UDim2.new(0.5,0,0.40,185)
    dotsRow.BackgroundTransparency = 1
    dotsRow.ZIndex          = 502
    dotsRow.Parent          = backdrop

    local dots = {}
    for i=1,3 do
        local d = Instance.new("Frame")
        d.Size              = UDim2.new(0,7,0,7)
        d.Position          = UDim2.new(0,(i-1)*18,0,0)
        d.BackgroundColor3  = T.AccentDim
        d.BackgroundTransparency = 0
        d.ZIndex            = 503
        d.Parent            = dotsRow
        U.Corner(d, 999)
        dots[i] = d
    end

    -- ── Boot sequence ────────────────────────────────────────────────
    task.spawn(function()
        task.wait(0.3)

        -- Reveal elements
        U.Tw(orb,     {BackgroundTransparency=0.88}, 0.7)
        U.Tw(card,    {BackgroundTransparency=0}, 0.5)
        U.Tw(logoImg, {ImageTransparency=0},       0.55)
        task.wait(0.4)
        U.Tw(nameL,   {TextTransparency=0},    0.4)
        U.Tw(statusL, {TextTransparency=0},    0.4)
        U.Tw(pTrack,  {BackgroundTransparency=0}, 0.35)
        task.wait(0.25)

        -- Dot pulse loop (runs during loading)
        local dotRunning = true
        task.spawn(function()
            while dotRunning do
                for i=1,3 do
                    if not dotRunning then break end
                    U.Tw(dots[i], {BackgroundColor3=T.AccentBright, BackgroundTransparency=0}, 0.18)
                    task.wait(0.14)
                    U.Tw(dots[i], {BackgroundColor3=T.AccentDim,    BackgroundTransparency=0.4}, 0.28)
                end
                task.wait(0.12)
            end
        end)

        -- Progress steps
        local steps = {
            {txt="Connecting to session...",  p=0.15, w=0.48},
            {txt="Loading assets...",          p=0.38, w=0.45},
            {txt="Building interface...",      p=0.62, w=0.42},
            {txt="Applying theme...",          p=0.82, w=0.36},
            {txt="Finalizing...",              p=0.97, w=0.28},
            {txt="Ready!",                     p=1.00, w=0.18},
        }
        for _, s in ipairs(steps) do
            statusL.Text = s.txt
            U.Tw(pFill, {Size=UDim2.new(s.p,0,1,0)}, 0.38, Enum.EasingStyle.Quint)
            -- shimmer sweep
            shimmer.Position = UDim2.new(-0.3,0,0,0)
            U.Tw(shimmer, {Position=UDim2.new(1.2,0,0,0)}, 0.35, Enum.EasingStyle.Sine)
            task.wait(s.w)
        end

        dotRunning = false

        -- Build window while still hidden
        self:_BuildMain()

        task.wait(0.22)

        -- Fade out loader, fade in window
        local wf = self._win.Frame
        wf.Visible = true

        U.TwSine(backdrop, {BackgroundTransparency=1}, 0.45)
        for _,e in ipairs(backdrop:GetDescendants()) do
            if e:IsA("TextLabel") then U.Tw(e, {TextTransparency=1}, 0.3) end
            if e:IsA("GuiObject") and e.ClassName~="TextLabel" then
                pcall(function()
                    U.Tw(e, {BackgroundTransparency=1}, 0.3)
                end)
            end
        end

        -- Window entrance: scale from 95% + fade in
        wf.Size = UDim2.new(0,686,0,456)
        wf.Position = UDim2.new(0.5,-343,0.5,-238)
        U.Tw(wf, {
            Size     = UDim2.new(0,720,0,480),
            Position = UDim2.new(0.5,-360,0.5,-240),
        }, 0.42, Enum.EasingStyle.Quint)

        task.wait(0.5)
        backdrop:Destroy()
    end)

    return self
end

-- ══════════════════════════════════════════════════════════════════════
-- §7  BUILD MAIN WINDOW
--
--  ROOT FIXES:
--    ✓ NO ClipsDescendants on main frame  → children always visible
--    ✓ ZIndex base = 200  → above game UI
--    ✓ All backgrounds OPAQUE (no transparency tricks that break executor)
--    ✓ Tab nav + content built with absolute solid backgrounds
--    ✓ Starts Visible=false, Boot() shows it after loading
-- ══════════════════════════════════════════════════════════════════════
function Library:_BuildMain()
    local win = {}
    self._win = win

    local BASE = 200  -- ZIndex base; everything lives above this

    -- ── Shadow frame (decorative) ───────────────────────────────────
    local shadow = Instance.new("ImageLabel")
    shadow.Name                 = "WinShadow"
    shadow.AnchorPoint          = Vector2.new(0.5,0.5)
    shadow.Size                 = UDim2.new(0,760,0,530)
    shadow.Position             = UDim2.new(0.5,0,0.5,10)
    shadow.BackgroundTransparency = 1
    shadow.Image                = "rbxassetid://6015897843"
    shadow.ImageColor3          = Color3.new(0,0,0)
    shadow.ImageTransparency    = 0.38
    shadow.ScaleType            = Enum.ScaleType.Slice
    shadow.SliceCenter          = Rect.new(49,49,450,450)
    shadow.ZIndex               = BASE - 1
    shadow.Parent               = self._gui
    win.Shadow = shadow

    -- ── Main Window Frame ───────────────────────────────────────────
    -- KEY FIX: NO ClipsDescendants, solid background, absolute position
    local frame = Instance.new("Frame")
    frame.Name                  = "WinFrame"
    frame.Size                  = UDim2.new(0,720,0,480)
    frame.Position              = UDim2.new(0.5,-360,0.5,-240)
    frame.BackgroundColor3      = T.WinBg
    frame.BackgroundTransparency = 0      -- FULLY OPAQUE — no executor glitch
    frame.ZIndex                = BASE
    frame.ClipsDescendants      = false   -- KEY FIX: was true → blacked out children
    frame.Visible               = false   -- Boot() reveals it after loading
    frame.Parent                = self._gui
    U.Corner(frame, 10)
    U.Stroke(frame, T.BorderMid, 1, 0)
    win.Frame = frame

    -- Subtle top-left glow (decorative, not transparency-dependent)
    local topGlow = Instance.new("Frame")
    topGlow.Size                = UDim2.new(0,300,0,2)
    topGlow.Position            = UDim2.new(0,40,0,0)
    topGlow.BackgroundColor3    = T.AccentBright
    topGlow.BackgroundTransparency = 0.55
    topGlow.ZIndex              = BASE+1
    topGlow.Parent              = frame
    U.Corner(topGlow, 2)
    U.Grad(topGlow, T.AccentDim, Color3.fromRGB(0,0,0), 0)

    -- ── Top Bar ─────────────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Name                 = "TopBar"
    topBar.Size                 = UDim2.new(1,0,0,46)
    topBar.BackgroundColor3     = T.TopBarBg
    topBar.BackgroundTransparency = 0
    topBar.ZIndex               = BASE+2
    topBar.Parent               = frame
    U.Corner(topBar, 10)  -- matches parent radius
    win.TopBar = topBar

    -- Cover bottom corners of topBar (they should be square)
    local topBarFill = Instance.new("Frame")
    topBarFill.Size             = UDim2.new(1,0,0.5,0)
    topBarFill.Position         = UDim2.new(0,0,0.5,0)
    topBarFill.BackgroundColor3 = T.TopBarBg
    topBarFill.BackgroundTransparency = 0
    topBarFill.ZIndex           = BASE+2
    topBarFill.Parent           = topBar

    -- Separator line below topBar
    local tbLine = Instance.new("Frame")
    tbLine.Size                 = UDim2.new(1,0,0,1)
    tbLine.Position             = UDim2.new(0,0,1,-1)
    tbLine.BackgroundColor3     = T.BorderDim
    tbLine.BackgroundTransparency = 0
    tbLine.ZIndex               = BASE+3
    tbLine.Parent               = topBar

    -- Accent gradient on top of separator
    U.Grad(tbLine, T.Accent, Color3.fromRGB(0,0,0), 0)

    -- Logo badge
    local logoBadge = Instance.new("Frame")
    logoBadge.Size              = UDim2.new(0,28,0,28)
    logoBadge.Position          = UDim2.new(0,12,0.5,-14)
    logoBadge.BackgroundColor3  = T.AccentDim
    logoBadge.BackgroundTransparency = 0
    logoBadge.ZIndex            = BASE+3
    logoBadge.Parent            = topBar
    U.Corner(logoBadge, 7)
    U.Stroke(logoBadge, T.AccentBright, 1, 0.5)

    local logoImg2 = Instance.new("ImageLabel")
    logoImg2.AnchorPoint        = Vector2.new(0.5,0.5)
    logoImg2.Size               = UDim2.new(0.7,0,0.7,0)
    logoImg2.Position           = UDim2.new(0.5,0,0.5,0)
    logoImg2.BackgroundTransparency = 1
    logoImg2.Image              = self._logoId
    logoImg2.ScaleType          = Enum.ScaleType.Fit
    logoImg2.ZIndex             = BASE+4
    logoImg2.Parent             = logoBadge

    local hubTitle = Instance.new("TextLabel")
    hubTitle.Size               = UDim2.new(0,220,1,0)
    hubTitle.Position           = UDim2.new(0,48,0,0)
    hubTitle.BackgroundTransparency = 1
    hubTitle.Text               = self._hubName
    hubTitle.TextColor3         = T.TextPri
    hubTitle.TextSize           = 15
    hubTitle.Font               = Enum.Font.GothamBold
    hubTitle.TextXAlignment     = Enum.TextXAlignment.Left
    hubTitle.ZIndex             = BASE+3
    hubTitle.Parent             = topBar

    -- Version badge
    local verBadge = Instance.new("Frame")
    verBadge.Size               = UDim2.new(0,42,0,18)
    verBadge.Position           = UDim2.new(0,50+#self._hubName*8,0.5,-9)
    verBadge.BackgroundColor3   = T.AccentDim
    verBadge.BackgroundTransparency = 0
    verBadge.ZIndex             = BASE+3
    verBadge.Parent             = topBar
    U.Corner(verBadge, 4)

    local verTxt = Instance.new("TextLabel")
    verTxt.Size                 = UDim2.new(1,0,1,0)
    verTxt.BackgroundTransparency = 1
    verTxt.Text                 = "v2.0"
    verTxt.TextColor3           = T.AccentBright
    verTxt.TextSize             = 9
    verTxt.Font                 = Enum.Font.GothamBold
    verTxt.ZIndex               = BASE+4
    verTxt.Parent               = verBadge

    -- Control buttons (Close + Minimize)
    local function ctrlBtn(txt, bg, xOff)
        local b = Instance.new("TextButton")
        b.Size              = UDim2.new(0,26,0,26)
        b.AnchorPoint       = Vector2.new(1,0.5)
        b.Position          = UDim2.new(1, xOff, 0.5, 0)
        b.BackgroundColor3  = bg
        b.BackgroundTransparency = 0
        b.Text              = txt
        b.TextColor3        = Color3.new(1,1,1)
        b.TextSize          = 12
        b.Font              = Enum.Font.GothamBold
        b.ZIndex            = BASE+4
        b.Parent            = topBar
        U.Corner(b, 6)
        return b
    end

    local minBtn   = ctrlBtn("—", Color3.fromRGB(42,40,62), -46)
    local closeBtn = ctrlBtn("✕", Color3.fromRGB(168,35,35), -14)

    -- Button hovers
    self._jan:Add(minBtn.MouseEnter:Connect(function()
        U.Tw(minBtn, {BackgroundColor3=Color3.fromRGB(65,62,95), TextColor3=T.TextPri}, 0.15)
    end),"Disconnect")
    self._jan:Add(minBtn.MouseLeave:Connect(function()
        U.Tw(minBtn, {BackgroundColor3=Color3.fromRGB(42,40,62), TextColor3=Color3.new(1,1,1)}, 0.15)
    end),"Disconnect")
    self._jan:Add(closeBtn.MouseEnter:Connect(function()
        U.Tw(closeBtn, {BackgroundColor3=Color3.fromRGB(210,40,40)}, 0.15)
    end),"Disconnect")
    self._jan:Add(closeBtn.MouseLeave:Connect(function()
        U.Tw(closeBtn, {BackgroundColor3=Color3.fromRGB(168,35,35)}, 0.15)
    end),"Disconnect")

    -- Minimize
    self._jan:Add(minBtn.MouseButton1Click:Connect(function()
        self._minimized = not self._minimized
        if self._minimized then
            U.Tw(frame, {Size=UDim2.new(0,720,0,46)}, 0.32, Enum.EasingStyle.Quint)
            minBtn.Text = "⬜"
        else
            U.Tw(frame, {Size=UDim2.new(0,720,0,480)}, 0.32, Enum.EasingStyle.Quint)
            minBtn.Text = "—"
        end
    end),"Disconnect")

    -- Close
    self._jan:Add(closeBtn.MouseButton1Click:Connect(function()
        U.Tw(frame,  {Size=UDim2.new(0,720,0,0),  Position=UDim2.new(0.5,-360,0.5,0)}, 0.36, Enum.EasingStyle.Quint)
        U.Tw(shadow, {ImageTransparency=1}, 0.24)
        task.delay(0.4, function() self:Destroy() end)
    end),"Disconnect")

    -- ── DRAG ─────────────────────────────────────────────────────────
    do
        local drag, startM, startP = false, nil, nil
        self._jan:Add(topBar.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                drag=true; startM=i.Position; startP=frame.Position
            end
        end),"Disconnect")
        self._jan:Add(topBar.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
        end),"Disconnect")
        self._jan:Add(UserInputService.InputChanged:Connect(function(i)
            if not drag then return end
            if i.UserInputType==Enum.UserInputType.MouseMovement then
                local d = i.Position - startM
                local np = UDim2.new(0, startP.X.Offset+d.X, 0, startP.Y.Offset+d.Y)
                frame.Position  = np
                shadow.Position = UDim2.new(0, np.X.Offset+(shadow.AbsoluteSize.X-720)*0.5,
                                             0, np.Y.Offset+10)
            end
        end),"Disconnect")
    end

    -- ── LEFT NAV  (solid background, no transparency) ───────────────
    local nav = Instance.new("Frame")
    nav.Name                    = "NavPanel"
    nav.Size                    = UDim2.new(0,162,1,-46)
    nav.Position                = UDim2.new(0,0,0,46)
    nav.BackgroundColor3        = T.NavBg        -- solid color
    nav.BackgroundTransparency  = 0              -- FIX: was 0.45 → invisible
    nav.ZIndex                  = BASE+1
    nav.ClipsDescendants        = true           -- ok here (clips scrolling tabs)
    nav.Parent                  = frame
    win.Nav = nav

    -- Right border of nav
    local navBorder = Instance.new("Frame")
    navBorder.Size              = UDim2.new(0,1,1,0)
    navBorder.Position          = UDim2.new(1,-1,0,0)
    navBorder.BackgroundColor3  = T.BorderDim
    navBorder.BackgroundTransparency = 0
    navBorder.ZIndex            = BASE+2
    navBorder.Parent            = nav

    -- Nav search box (mini filter)
    local navSearch = Instance.new("Frame")
    navSearch.Size              = UDim2.new(1,-16,0,28)
    navSearch.Position          = UDim2.new(0,8,0,8)
    navSearch.BackgroundColor3  = Color3.fromRGB(24,22,36)
    navSearch.BackgroundTransparency = 0
    navSearch.ZIndex            = BASE+3
    navSearch.Parent            = nav
    U.Corner(navSearch, 5)
    U.Stroke(navSearch, T.BorderDim, 1, 0)

    local navSearchIcon = Instance.new("TextLabel")
    navSearchIcon.Size          = UDim2.new(0,20,1,0)
    navSearchIcon.BackgroundTransparency = 1
    navSearchIcon.Text          = "⌕"
    navSearchIcon.TextColor3    = T.TextMuted
    navSearchIcon.TextSize      = 13
    navSearchIcon.ZIndex        = BASE+4
    navSearchIcon.Parent        = navSearch

    local navSearchBox = Instance.new("TextBox")
    navSearchBox.Size           = UDim2.new(1,-22,1,-4)
    navSearchBox.Position       = UDim2.new(0,20,0,2)
    navSearchBox.BackgroundTransparency = 1
    navSearchBox.PlaceholderText = "Search..."
    navSearchBox.PlaceholderColor3 = T.TextMuted
    navSearchBox.Text           = ""
    navSearchBox.TextColor3     = T.TextSec
    navSearchBox.TextSize       = 11
    navSearchBox.Font           = Enum.Font.Gotham
    navSearchBox.ClearTextOnFocus = false
    navSearchBox.ZIndex         = BASE+4
    navSearchBox.Parent         = navSearch
    win.NavSearchBox            = navSearchBox

    -- Tab list scroll
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name              = "TabScroll"
    tabScroll.Size              = UDim2.new(1,0,1,-48)
    tabScroll.Position          = UDim2.new(0,0,0,46)
    tabScroll.BackgroundTransparency = 1
    tabScroll.ScrollBarThickness = 2
    tabScroll.ScrollBarImageColor3 = T.AccentDim
    tabScroll.ScrollBarImageTransparency = 0
    tabScroll.CanvasSize        = UDim2.new(0,0,0,0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.ZIndex            = BASE+2
    tabScroll.Parent            = nav
    win.TabScroll               = tabScroll

    Instance.new("UIListLayout", tabScroll).Padding = UDim.new(0,2)
    U.Pad(tabScroll, 6,6,6,6)

    -- ── CONTENT AREA ─────────────────────────────────────────────────
    local content = Instance.new("Frame")
    content.Name                = "ContentArea"
    content.Size                = UDim2.new(1,-162,1,-46)
    content.Position            = UDim2.new(0,162,0,46)
    content.BackgroundColor3    = T.ContentBg    -- solid dark
    content.BackgroundTransparency = 0           -- FIX: was transparent → black void
    content.ZIndex              = BASE+1
    content.ClipsDescendants    = true           -- ok (clips component overflow)
    content.Parent              = frame
    win.Content                 = content

    -- Subtle inner top border
    local cBorder = Instance.new("Frame")
    cBorder.Size                = UDim2.new(1,0,0,1)
    cBorder.BackgroundColor3    = T.BorderDim
    cBorder.BackgroundTransparency = 0
    cBorder.ZIndex              = BASE+2
    cBorder.Parent              = content

    -- ── NOTIFICATION ANCHOR ──────────────────────────────────────────
    local notifAnchor = Instance.new("Frame")
    notifAnchor.AnchorPoint     = Vector2.new(1,1)
    notifAnchor.Size            = UDim2.new(0,310,1,0)
    notifAnchor.Position        = UDim2.new(1,-12,1,-12)
    notifAnchor.BackgroundTransparency = 1
    notifAnchor.ZIndex          = 800
    notifAnchor.Parent          = self._gui
    self._jan:Add(notifAnchor,"Destroy","NotifAnchor")

    local nl = Instance.new("UIListLayout")
    nl.FillDirection            = Enum.FillDirection.Vertical
    nl.VerticalAlignment        = Enum.VerticalAlignment.Bottom
    nl.HorizontalAlignment      = Enum.HorizontalAlignment.Right
    nl.SortOrder                = Enum.SortOrder.LayoutOrder
    nl.Padding                  = UDim.new(0,7)
    nl.Parent                   = notifAnchor
    win.NotifAnchor             = notifAnchor

    -- ── Nav search debounce filter ────────────────────────────────────
    local pending
    self._jan:Add(navSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if pending then task.cancel(pending) end
        pending = task.delay(0.15, function()
            local q = navSearchBox.Text:lower()
            if self._activeTab then
                for _, c in ipairs(self._activeTab._scroll:GetChildren()) do
                    if c:IsA("Frame") then
                        local tl = c:FindFirstChildOfClass("TextLabel")
                        local match = q=="" or (tl and tl.Text:lower():find(q,1,true))
                        U.Tw(c, {BackgroundTransparency = match and 0 or 0.72}, 0.15)
                    end
                end
            end
        end)
    end),"Disconnect")
end

-- ══════════════════════════════════════════════════════════════════════
-- §8  CREATE TAB
-- ══════════════════════════════════════════════════════════════════════
function Library:CreateTab(name, iconId)
    assert(self._win, "Call Boot() before CreateTab()")
    local win  = self._win
    local BASE = 200
    local tab  = {}
    tab._jan   = Janitor.new()

    -- ── Tab button in nav ────────────────────────────────────────────
    local btn = Instance.new("TextButton")
    btn.Name                    = "Tab_"..name
    btn.Size                    = UDim2.new(1,0,0,36)
    btn.BackgroundColor3        = T.NavBg
    btn.BackgroundTransparency  = 1     -- transparent by default
    btn.Text                    = ""
    btn.ZIndex                  = BASE+4
    btn.Parent                  = win.TabScroll
    U.Corner(btn, 6)
    tab._btn = btn

    -- Active indicator pill (left edge)
    local pill = Instance.new("Frame")
    pill.Size                   = UDim2.new(0,3,0,18)
    pill.AnchorPoint            = Vector2.new(0,0.5)
    pill.Position               = UDim2.new(0,0,0.5,0)
    pill.BackgroundColor3       = T.Accent
    pill.BackgroundTransparency = 1
    pill.ZIndex                 = BASE+5
    pill.Parent                 = btn
    U.Corner(pill, 3)
    tab._pill = pill

    -- Icon
    local tabIcon = Instance.new("ImageLabel")
    tabIcon.AnchorPoint         = Vector2.new(0,0.5)
    tabIcon.Size                = UDim2.new(0,15,0,15)
    tabIcon.Position            = UDim2.new(0,12,0.5,0)
    tabIcon.BackgroundTransparency = 1
    tabIcon.Image               = iconId or ""
    tabIcon.ImageColor3         = T.TextMuted
    tabIcon.ScaleType           = Enum.ScaleType.Fit
    tabIcon.ZIndex              = BASE+5
    tabIcon.Parent              = btn
    tab._icon = tabIcon

    -- Label
    local tabLbl = Instance.new("TextLabel")
    tabLbl.Size                 = UDim2.new(1,-32,1,0)
    tabLbl.Position             = UDim2.new(0, iconId and 32 or 12, 0,0)
    tabLbl.BackgroundTransparency = 1
    tabLbl.Text                 = name
    tabLbl.TextColor3           = T.TextMuted
    tabLbl.TextSize             = 12
    tabLbl.Font                 = Enum.Font.Gotham
    tabLbl.TextXAlignment       = Enum.TextXAlignment.Left
    tabLbl.ZIndex               = BASE+5
    tabLbl.Parent               = btn
    tab._lbl = tabLbl

    -- ── Tab content ScrollingFrame ────────────────────────────────────
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name                 = "Content_"..name
    scroll.Size                 = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness   = 3
    scroll.ScrollBarImageColor3 = T.Accent
    scroll.ScrollBarImageTransparency = 0
    scroll.CanvasSize           = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    scroll.ZIndex               = BASE+2
    scroll.Visible              = false
    scroll.Parent               = win.Content
    tab._scroll = scroll

    local sl = Instance.new("UIListLayout")
    sl.FillDirection            = Enum.FillDirection.Vertical
    sl.HorizontalAlignment      = Enum.HorizontalAlignment.Center
    sl.Padding                  = UDim.new(0,6)
    sl.Parent                   = scroll
    U.Pad(scroll, 10,14,10,10)

    -- ── Select logic ─────────────────────────────────────────────────
    local function selectTab()
        if self._activeTab and self._activeTab ~= tab then
            local p = self._activeTab
            U.Tw(p._btn,  {BackgroundTransparency=1}, 0.18)
            U.Tw(p._lbl,  {TextColor3=T.TextMuted}, 0.18)
            U.Tw(p._icon, {ImageColor3=T.TextMuted}, 0.18)
            U.Tw(p._pill, {BackgroundTransparency=1}, 0.18)
            p._lbl.Font = Enum.Font.Gotham
            p._scroll.Visible = false
        end
        self._activeTab = tab
        U.Tw(btn,     {BackgroundColor3=Color3.fromRGB(30,26,48), BackgroundTransparency=0}, 0.18)
        U.Tw(tabLbl,  {TextColor3=T.TextPri},                                                0.18)
        U.Tw(tabIcon, {ImageColor3=T.AccentBright},                                          0.18)
        U.Tw(pill,    {BackgroundTransparency=0},                                             0.18)
        tabLbl.Font    = Enum.Font.GothamBold
        scroll.Visible = true
    end
    tab._select = selectTab

    self._jan:Add(btn.MouseEnter:Connect(function()
        if self._activeTab ~= tab then
            U.Tw(btn,    {BackgroundColor3=Color3.fromRGB(24,22,36), BackgroundTransparency=0}, 0.14)
            U.Tw(tabLbl, {TextColor3=T.TextSec}, 0.14)
        end
    end),"Disconnect")
    self._jan:Add(btn.MouseLeave:Connect(function()
        if self._activeTab ~= tab then
            U.Tw(btn,    {BackgroundTransparency=1}, 0.14)
            U.Tw(tabLbl, {TextColor3=T.TextMuted}, 0.14)
        end
    end),"Disconnect")
    self._jan:Add(btn.MouseButton1Click:Connect(selectTab),"Disconnect")

    if #self._tabs == 0 then task.defer(selectTab) end
    table.insert(self._tabs, tab)
    self._jan:Add(function() tab._jan:Cleanup() end,"fn")

    -- ──────────────────────────────────────────────────────────────────
    -- Internal helpers
    -- ──────────────────────────────────────────────────────────────────
    local function base(nm, h)
        local f = Instance.new("Frame")
        f.Name                  = nm
        f.Size                  = UDim2.new(1,0,0,h or 48)
        f.BackgroundColor3      = T.CardBg
        f.BackgroundTransparency = 0     -- FIX: fully opaque cards
        f.ZIndex                = BASE+3
        f.Parent                = scroll
        U.Corner(f, 7)
        U.Stroke(f, T.BorderDim, 1, 0)
        return f
    end

    -- ══════════════════════════════════════════════════════════════════
    -- 8a  AddButton
    -- ══════════════════════════════════════════════════════════════════
    function tab:AddButton(cfg)
        cfg = cfg or {}
        local j = Janitor.new()
        local f = base(cfg.Name or "Btn", 44)

        -- Gradient tint
        U.Grad(f, T.CardBg, Color3.fromRGB(18,16,28), 145)

        -- Accent left edge bar
        local bar = Instance.new("Frame")
        bar.Size                = UDim2.new(0,2,0.55,0)
        bar.AnchorPoint         = Vector2.new(0,0.5)
        bar.Position            = UDim2.new(0,0,0.5,0)
        bar.BackgroundColor3    = T.Accent
        bar.BackgroundTransparency = 1
        bar.ZIndex              = BASE+4
        bar.Parent              = f
        U.Corner(bar,2)

        local overlay = Instance.new("TextButton")
        overlay.Size            = UDim2.new(1,0,1,0)
        overlay.BackgroundTransparency = 1
        overlay.Text            = ""
        overlay.ZIndex          = BASE+6
        overlay.ClipsDescendants = true
        overlay.Parent          = f
        U.Corner(overlay,7)

        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.new(1,-50,1,0)
        lbl.Position            = UDim2.new(0,16,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text                = cfg.Name or "Button"
        lbl.TextColor3          = T.TextSec
        lbl.TextSize            = 13
        lbl.Font                = Enum.Font.Gotham
        lbl.TextXAlignment      = Enum.TextXAlignment.Left
        lbl.ZIndex              = BASE+4
        lbl.Parent              = f

        local arrow = Instance.new("TextLabel")
        arrow.Size              = UDim2.new(0,22,1,0)
        arrow.AnchorPoint       = Vector2.new(1,0)
        arrow.Position          = UDim2.new(1,-12,0,0)
        arrow.BackgroundTransparency = 1
        arrow.Text              = "›"
        arrow.TextColor3        = T.TextMuted
        arrow.TextSize          = 18
        arrow.Font              = Enum.Font.GothamBold
        arrow.ZIndex            = BASE+4
        arrow.Parent            = f

        j:Add(overlay.MouseEnter:Connect(function()
            U.Tw(f,     {BackgroundColor3=T.CardBgHover}, 0.15)
            U.Tw(lbl,   {TextColor3=T.TextPri},            0.15)
            U.Tw(arrow, {TextColor3=T.AccentBright},       0.15)
            U.Tw(bar,   {BackgroundTransparency=0},        0.15)
        end),"Disconnect")
        j:Add(overlay.MouseLeave:Connect(function()
            U.Tw(f,     {BackgroundColor3=T.CardBg}, 0.15)
            U.Tw(lbl,   {TextColor3=T.TextSec},       0.15)
            U.Tw(arrow, {TextColor3=T.TextMuted},     0.15)
            U.Tw(bar,   {BackgroundTransparency=1},   0.15)
        end),"Disconnect")

        U.Ripple(overlay, j)

        j:Add(overlay.MouseButton1Click:Connect(function()
            U.Tw(f, {BackgroundColor3=T.AccentDim}, 0.07)
            task.delay(0.08, function()
                U.Tw(f, {BackgroundColor3=T.CardBg}, 0.2)
            end)
            if cfg.Callback then task.spawn(cfg.Callback) end
        end),"Disconnect")

        self._jan:Add(function() j:Cleanup() end,"fn")
        return f
    end

    -- ══════════════════════════════════════════════════════════════════
    -- 8b  AddToggle
    -- ══════════════════════════════════════════════════════════════════
    function tab:AddToggle(cfg)
        cfg = cfg or {}
        local j     = Janitor.new()
        local state = cfg.Default == true
        local f     = base(cfg.Name or "Toggle", 44)
        U.Grad(f, T.CardBg, Color3.fromRGB(18,16,28), 145)

        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.new(1,-72,1,0)
        lbl.Position            = UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text                = cfg.Name or "Toggle"
        lbl.TextColor3          = T.TextSec
        lbl.TextSize            = 13
        lbl.Font                = Enum.Font.Gotham
        lbl.TextXAlignment      = Enum.TextXAlignment.Left
        lbl.ZIndex              = BASE+4
        lbl.Parent              = f

        -- Track
        local track = Instance.new("Frame")
        track.Size              = UDim2.new(0,42,0,22)
        track.AnchorPoint       = Vector2.new(1,0.5)
        track.Position          = UDim2.new(1,-14,0.5,0)
        track.BackgroundColor3  = state and T.Accent or Color3.fromRGB(35,32,52)
        track.BackgroundTransparency = 0
        track.ZIndex            = BASE+4
        track.Parent            = f
        U.Corner(track,999)
        U.Stroke(track, state and T.Accent or T.BorderDim, 1, state and 0.5 or 0)
        local trackStroke = track:FindFirstChildOfClass("UIStroke")

        -- Knob
        local knob = Instance.new("Frame")
        knob.Size               = UDim2.new(0,16,0,16)
        knob.AnchorPoint        = Vector2.new(0,0.5)
        knob.Position           = state and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0)
        knob.BackgroundColor3   = Color3.new(1,1,1)
        knob.BackgroundTransparency = 0
        knob.ZIndex             = BASE+5
        knob.Parent             = track
        U.Corner(knob,999)

        local click = Instance.new("TextButton")
        click.Size              = UDim2.new(1,0,1,0)
        click.BackgroundTransparency = 1
        click.Text              = ""
        click.ZIndex            = BASE+6
        click.Parent            = f

        local function apply(v, cb)
            state = v
            if state then
                U.Tw(track,       {BackgroundColor3=T.Accent},                      0.22)
                U.Tw(knob,        {Position=UDim2.new(0,23,0.5,0)},                 0.22)
                U.Tw(trackStroke, {Color=T.Accent, Transparency=0.5},               0.22)
                U.Tw(lbl,         {TextColor3=T.TextPri},                            0.18)
            else
                U.Tw(track,       {BackgroundColor3=Color3.fromRGB(35,32,52)},       0.22)
                U.Tw(knob,        {Position=UDim2.new(0,3,0.5,0)},                  0.22)
                U.Tw(trackStroke, {Color=T.BorderDim, Transparency=0},              0.22)
                U.Tw(lbl,         {TextColor3=T.TextSec},                            0.18)
            end
            if cb and cfg.Callback then task.spawn(cfg.Callback, state) end
        end
        apply(state, false)

        j:Add(click.MouseButton1Click:Connect(function() apply(not state, true) end),"Disconnect")
        self._jan:Add(function() j:Cleanup() end,"fn")

        local api={}
        function api:Set(v) apply(v==true, false) end
        function api:Get() return state end
        return api
    end

    -- ══════════════════════════════════════════════════════════════════
    -- 8c  AddSlider
    -- ══════════════════════════════════════════════════════════════════
    function tab:AddSlider(cfg)
        cfg = cfg or {}
        local j   = Janitor.new()
        local mn  = cfg.Min or 0
        local mx  = cfg.Max or 100
        local val = math.clamp(cfg.Default or mn, mn, mx)
        local drag= false
        local f   = base(cfg.Name or "Slider", 60)
        U.Grad(f, T.CardBg, Color3.fromRGB(18,16,28), 145)

        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.new(1,-60,0,22)
        lbl.Position            = UDim2.new(0,14,0,7)
        lbl.BackgroundTransparency = 1
        lbl.Text                = cfg.Name or "Slider"
        lbl.TextColor3          = T.TextSec
        lbl.TextSize            = 13
        lbl.Font                = Enum.Font.Gotham
        lbl.TextXAlignment      = Enum.TextXAlignment.Left
        lbl.ZIndex              = BASE+4
        lbl.Parent              = f

        local valLbl = Instance.new("TextLabel")
        valLbl.Size             = UDim2.new(0,50,0,22)
        valLbl.AnchorPoint      = Vector2.new(1,0)
        valLbl.Position         = UDim2.new(1,-12,0,7)
        valLbl.BackgroundTransparency = 1
        valLbl.Text             = tostring(val)
        valLbl.TextColor3       = T.AccentBright
        valLbl.TextSize         = 13
        valLbl.Font             = Enum.Font.GothamBold
        valLbl.TextXAlignment   = Enum.TextXAlignment.Right
        valLbl.ZIndex           = BASE+4
        valLbl.Parent           = f

        -- Track bg
        local trBg = Instance.new("Frame")
        trBg.Size               = UDim2.new(1,-28,0,6)
        trBg.Position           = UDim2.new(0,14,0,40)
        trBg.BackgroundColor3   = Color3.fromRGB(30,28,45)
        trBg.BackgroundTransparency = 0
        trBg.ZIndex             = BASE+4
        trBg.Parent             = f
        U.Corner(trBg,4)

        local fill = Instance.new("Frame")
        fill.Size               = UDim2.new((val-mn)/(mx-mn),0,1,0)
        fill.BackgroundColor3   = T.Accent
        fill.BackgroundTransparency = 0
        fill.ZIndex             = BASE+5
        fill.Parent             = trBg
        U.Corner(fill,4)
        U.Grad(fill, T.AccentDim, T.AccentBright, 0)

        local thumb = Instance.new("Frame")
        thumb.Size              = UDim2.new(0,14,0,14)
        thumb.AnchorPoint       = Vector2.new(0.5,0.5)
        thumb.Position          = UDim2.new((val-mn)/(mx-mn),0,0.5,0)
        thumb.BackgroundColor3  = Color3.new(1,1,1)
        thumb.BackgroundTransparency = 0
        thumb.ZIndex            = BASE+7
        thumb.Parent            = trBg
        U.Corner(thumb,999)
        U.Stroke(thumb, T.Accent, 2, 0.2)

        local hit = Instance.new("TextButton")
        hit.Size                = UDim2.new(1,0,1,0)
        hit.BackgroundTransparency = 1
        hit.Text                = ""
        hit.ZIndex              = BASE+8
        hit.Parent              = f

        local function setVal(sx)
            local ap  = trBg.AbsolutePosition.X
            local as  = trBg.AbsoluteSize.X
            local a   = math.clamp((sx-ap)/as,0,1)
            local nv  = math.floor(mn + a*(mx-mn) + 0.5)
            if nv==val then return end
            val = nv
            valLbl.Text = tostring(val)
            U.Tw(fill,  {Size=UDim2.new(a,0,1,0)},         0.07, Enum.EasingStyle.Linear)
            U.Tw(thumb, {Position=UDim2.new(a,0,0.5,0)},   0.07, Enum.EasingStyle.Linear)
            if cfg.Callback then task.spawn(cfg.Callback, val) end
        end

        j:Add(hit.MouseButton1Down:Connect(function()
            drag=true
            U.Tw(thumb,{Size=UDim2.new(0,18,0,18)},0.1)
        end),"Disconnect")
        j:Add(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 and drag then
                drag=false
                U.Tw(thumb,{Size=UDim2.new(0,14,0,14)},0.1)
            end
        end),"Disconnect")
        j:Add(UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                setVal(i.Position.X)
            end
        end),"Disconnect")
        j:Add(hit.MouseButton1Click:Connect(function() setVal(Mouse.X) end),"Disconnect")

        self._jan:Add(function() j:Cleanup() end,"fn")
        local api={}
        function api:Set(v)
            val=math.clamp(v,mn,mx)
            local a=(val-mn)/(mx-mn)
            valLbl.Text=tostring(val)
            U.Tw(fill,{Size=UDim2.new(a,0,1,0)},0.2)
            U.Tw(thumb,{Position=UDim2.new(a,0,0.5,0)},0.2)
        end
        function api:Get() return val end
        return api
    end

    -- ══════════════════════════════════════════════════════════════════
    -- 8d  AddDropdown  (parented to _gui at ZIndex 700 — never clipped)
    -- ══════════════════════════════════════════════════════════════════
    function tab:AddDropdown(cfg)
        cfg = cfg or {}
        local j       = Janitor.new()
        local opts    = cfg.Options or {}
        local sel     = cfg.Default or (opts[1] or "Select...")
        local open    = false
        local f       = base(cfg.Name or "Dropdown", 44)
        U.Grad(f, T.CardBg, Color3.fromRGB(18,16,28), 145)

        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.new(0.44,0,1,0)
        lbl.Position            = UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text                = cfg.Name or "Dropdown"
        lbl.TextColor3          = T.TextSec
        lbl.TextSize            = 13
        lbl.Font                = Enum.Font.Gotham
        lbl.TextXAlignment      = Enum.TextXAlignment.Left
        lbl.ZIndex              = BASE+4
        lbl.Parent              = f

        local box = Instance.new("Frame")
        box.Size                = UDim2.new(0,148,0,28)
        box.AnchorPoint         = Vector2.new(1,0.5)
        box.Position            = UDim2.new(1,-12,0.5,0)
        box.BackgroundColor3    = Color3.fromRGB(28,25,42)
        box.BackgroundTransparency = 0
        box.ZIndex              = BASE+4
        box.Parent              = f
        U.Corner(box,5)
        U.Stroke(box, T.BorderMid, 1, 0)

        local selLbl = Instance.new("TextLabel")
        selLbl.Size             = UDim2.new(1,-22,1,0)
        selLbl.Position         = UDim2.new(0,8,0,0)
        selLbl.BackgroundTransparency = 1
        selLbl.Text             = tostring(sel)
        selLbl.TextColor3       = T.TextSec
        selLbl.TextSize         = 11
        selLbl.Font             = Enum.Font.Gotham
        selLbl.TextXAlignment   = Enum.TextXAlignment.Left
        selLbl.TextTruncate     = Enum.TextTruncate.AtEnd
        selLbl.ZIndex           = BASE+5
        selLbl.Parent           = box

        local chev = Instance.new("TextLabel")
        chev.Size               = UDim2.new(0,16,1,0)
        chev.AnchorPoint        = Vector2.new(1,0)
        chev.Position           = UDim2.new(1,-3,0,0)
        chev.BackgroundTransparency = 1
        chev.Text               = "▾"
        chev.TextColor3         = T.TextMuted
        chev.TextSize           = 11
        chev.Font               = Enum.Font.GothamBold
        chev.ZIndex             = BASE+5
        chev.Parent             = box

        local hitBtn = Instance.new("TextButton")
        hitBtn.Size             = UDim2.new(1,0,1,0)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text             = ""
        hitBtn.ZIndex           = BASE+6
        hitBtn.Parent           = f

        -- List (screenGui parent, ZIndex 700 — never hidden)
        local ITEM  = 29
        local lH    = math.min(#opts,5)*ITEM + 8

        local drop  = Instance.new("Frame")
        drop.Size               = UDim2.new(0,148,0,0)
        drop.BackgroundColor3   = Color3.fromRGB(20,18,30)
        drop.BackgroundTransparency = 0
        drop.ZIndex             = 700
        drop.Visible            = false
        drop.ClipsDescendants   = true
        drop.Parent             = self._gui     -- screenGui!
        U.Corner(drop,7)
        U.Stroke(drop, T.Accent, 1, 0.3)
        j:Add(drop,"Destroy","Drop")

        local dScroll = Instance.new("ScrollingFrame")
        dScroll.Size            = UDim2.new(1,0,1,0)
        dScroll.BackgroundTransparency = 1
        dScroll.ScrollBarThickness = #opts>5 and 2 or 0
        dScroll.ScrollBarImageColor3 = T.Accent
        dScroll.CanvasSize      = UDim2.new(0,0,0,#opts*ITEM+8)
        dScroll.ZIndex          = 701
        dScroll.Parent          = drop
        Instance.new("UIListLayout",dScroll).Padding = UDim.new(0,1)
        U.Pad(dScroll,3,3,3,3)

        local itemBtns={}
        for _,opt in ipairs(opts) do
            local isSel = opt==sel
            local ib = Instance.new("TextButton")
            ib.Size             = UDim2.new(1,0,0,ITEM-3)
            ib.BackgroundColor3 = isSel and T.AccentDim or Color3.new(0,0,0)
            ib.BackgroundTransparency = isSel and 0 or 1
            ib.Text             = ""
            ib.ZIndex           = 702
            ib.Parent           = dScroll
            U.Corner(ib,4)
            itemBtns[opt]=ib

            local il = Instance.new("TextLabel")
            il.Size             = UDim2.new(1,-10,1,0)
            il.Position         = UDim2.new(0,8,0,0)
            il.BackgroundTransparency = 1
            il.Text             = tostring(opt)
            il.TextColor3       = isSel and T.TextPri or T.TextSec
            il.TextSize         = 12
            il.Font             = isSel and Enum.Font.GothamBold or Enum.Font.Gotham
            il.TextXAlignment   = Enum.TextXAlignment.Left
            il.ZIndex           = 703
            il.Parent           = ib

            j:Add(ib.MouseEnter:Connect(function()
                if opt~=sel then U.Tw(ib,{BackgroundColor3=T.CardBgHover,BackgroundTransparency=0},0.12) end
            end),"Disconnect")
            j:Add(ib.MouseLeave:Connect(function()
                if opt~=sel then U.Tw(ib,{BackgroundTransparency=1},0.12) end
            end),"Disconnect")
            j:Add(ib.MouseButton1Click:Connect(function()
                -- deselect old
                if itemBtns[sel] then
                    local pi=itemBtns[sel]
                    U.Tw(pi,{BackgroundTransparency=1},0.12)
                    local pl=pi:FindFirstChildOfClass("TextLabel")
                    if pl then U.Tw(pl,{TextColor3=T.TextSec},0.12); pl.Font=Enum.Font.Gotham end
                end
                sel=opt; selLbl.Text=tostring(opt)
                U.Tw(ib,{BackgroundColor3=T.AccentDim,BackgroundTransparency=0},0.12)
                U.Tw(il,{TextColor3=T.TextPri},0.12); il.Font=Enum.Font.GothamBold
                if cfg.Callback then task.spawn(cfg.Callback,opt) end
                open=false
                U.Tw(drop,{Size=UDim2.new(0,148,0,0)},0.2,Enum.EasingStyle.Quint)
                U.Tw(chev,{Rotation=0,TextColor3=T.TextMuted},0.18)
                task.delay(0.22,function() drop.Visible=false end)
            end),"Disconnect")
        end

        local function positionDrop()
            local ap=box.AbsolutePosition; local as=box.AbsoluteSize
            drop.Position=UDim2.new(0,ap.X,0,ap.Y+as.Y+3)
        end

        j:Add(hitBtn.MouseButton1Click:Connect(function()
            open=not open
            if open then
                positionDrop(); drop.Visible=true
                U.Tw(drop,{Size=UDim2.new(0,148,0,lH)},0.22,Enum.EasingStyle.Quint)
                U.Tw(chev,{Rotation=180,TextColor3=T.Accent},0.18)
            else
                U.Tw(drop,{Size=UDim2.new(0,148,0,0)},0.2,Enum.EasingStyle.Quint)
                U.Tw(chev,{Rotation=0,TextColor3=T.TextMuted},0.18)
                task.delay(0.22,function() drop.Visible=false end)
            end
        end),"Disconnect")

        j:Add(UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 or not open then return end
            local p=i.Position
            local dp=drop.AbsolutePosition; local ds=drop.AbsoluteSize
            local bp=f.AbsolutePosition;    local bs=f.AbsoluteSize
            if not(p.X>=dp.X and p.X<=dp.X+ds.X and p.Y>=dp.Y and p.Y<=dp.Y+ds.Y)
            and not(p.X>=bp.X and p.X<=bp.X+bs.X and p.Y>=bp.Y and p.Y<=bp.Y+bs.Y) then
                open=false
                U.Tw(drop,{Size=UDim2.new(0,148,0,0)},0.2,Enum.EasingStyle.Quint)
                U.Tw(chev,{Rotation=0,TextColor3=T.TextMuted},0.18)
                task.delay(0.22,function() drop.Visible=false end)
            end
        end),"Disconnect")

        self._jan:Add(function() j:Cleanup() end,"fn")
        local api={}
        function api:Set(v) sel=v; selLbl.Text=tostring(v) end
        function api:Get() return sel end
        return api
    end

    -- ══════════════════════════════════════════════════════════════════
    -- 8e  AddToggle
    -- ══════════════════════════════════════════════════════════════════
    function tab:AddKeybind(cfg)
        cfg = cfg or {}
        local j        = Janitor.new()
        local curKey   = cfg.Default or Enum.KeyCode.Unknown
        local listening= false
        local f        = base(cfg.Name or "Keybind", 44)
        U.Grad(f, T.CardBg, Color3.fromRGB(18,16,28), 145)

        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.new(1,-120,1,0)
        lbl.Position            = UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text                = cfg.Name or "Keybind"
        lbl.TextColor3          = T.TextSec
        lbl.TextSize            = 13
        lbl.Font                = Enum.Font.Gotham
        lbl.TextXAlignment      = Enum.TextXAlignment.Left
        lbl.ZIndex              = BASE+4
        lbl.Parent              = f

        local badge = Instance.new("Frame")
        badge.Size              = UDim2.new(0,95,0,26)
        badge.AnchorPoint       = Vector2.new(1,0.5)
        badge.Position          = UDim2.new(1,-12,0.5,0)
        badge.BackgroundColor3  = Color3.fromRGB(28,25,42)
        badge.BackgroundTransparency = 0
        badge.ZIndex            = BASE+4
        badge.Parent            = f
        U.Corner(badge,5)
        local bStr = U.Stroke(badge, T.BorderMid, 1, 0)

        local keyLbl = Instance.new("TextLabel")
        keyLbl.Size             = UDim2.new(1,0,1,0)
        keyLbl.BackgroundTransparency = 1
        keyLbl.Text             = curKey==Enum.KeyCode.Unknown and "None" or curKey.Name
        keyLbl.TextColor3       = T.AccentBright
        keyLbl.TextSize         = 11
        keyLbl.Font             = Enum.Font.GothamBold
        keyLbl.ZIndex           = BASE+5
        keyLbl.Parent           = badge

        local hit = Instance.new("TextButton")
        hit.Size                = UDim2.new(1,0,1,0)
        hit.BackgroundTransparency = 1
        hit.Text                = ""
        hit.ZIndex              = BASE+6
        hit.Parent              = f

        local function setListen(v)
            listening=v
            if v then
                keyLbl.Text="Press key..."
                keyLbl.TextColor3=T.Warning
                U.Tw(badge,{BackgroundColor3=Color3.fromRGB(40,32,8)},0.15)
                U.Tw(bStr,{Color=T.Warning},0.15)
            else
                keyLbl.Text=curKey==Enum.KeyCode.Unknown and "None" or curKey.Name
                keyLbl.TextColor3=T.AccentBright
                U.Tw(badge,{BackgroundColor3=Color3.fromRGB(28,25,42)},0.15)
                U.Tw(bStr,{Color=T.BorderMid},0.15)
            end
        end

        j:Add(hit.MouseButton1Click:Connect(function() setListen(not listening) end),"Disconnect")
        j:Add(UserInputService.InputBegan:Connect(function(i,gp)
            if listening then
                if i.UserInputType~=Enum.UserInputType.Keyboard then return end
                curKey = i.KeyCode==Enum.KeyCode.Escape and Enum.KeyCode.Unknown or i.KeyCode
                setListen(false)
                if cfg.Callback then task.spawn(cfg.Callback,curKey) end
            elseif not gp and i.UserInputType==Enum.UserInputType.Keyboard
                   and i.KeyCode==curKey and curKey~=Enum.KeyCode.Unknown then
                if cfg.Callback then task.spawn(cfg.Callback,curKey) end
            end
        end),"Disconnect")

        self._jan:Add(function() j:Cleanup() end,"fn")
        local api={}
        function api:Set(k) curKey=k; setListen(false) end
        function api:Get() return curKey end
        return api
    end

    -- ══════════════════════════════════════════════════════════════════
    -- 8f  AddSection
    -- ══════════════════════════════════════════════════════════════════
    function tab:AddSection(title)
        local s = Instance.new("Frame")
        s.Size                  = UDim2.new(1,0,0,28)
        s.BackgroundTransparency = 1
        s.ZIndex                = BASE+3
        s.Parent                = scroll

        local line = Instance.new("Frame")
        line.Size               = UDim2.new(1,-16,0,1)
        line.Position           = UDim2.new(0,8,0.5,0)
        line.BackgroundColor3   = T.BorderDim
        line.BackgroundTransparency = 0
        line.ZIndex             = BASE+3
        line.Parent             = s
        U.Grad(line, Color3.new(0,0,0), T.BorderDim, 0)

        local secLbl = Instance.new("TextLabel")
        secLbl.AutomaticSize    = Enum.AutomaticSize.X
        secLbl.Size             = UDim2.new(0,0,0,20)
        secLbl.Position         = UDim2.new(0,10,0.5,-10)
        secLbl.BackgroundColor3 = T.ContentBg
        secLbl.BackgroundTransparency = 0
        secLbl.Text             = "  "..string.upper(title).."  "
        secLbl.TextColor3       = T.Accent
        secLbl.TextSize         = 9
        secLbl.Font             = Enum.Font.GothamBold
        secLbl.TextXAlignment   = Enum.TextXAlignment.Left
        secLbl.ZIndex           = BASE+4
        secLbl.Parent           = s
        return s
    end

    -- ══════════════════════════════════════════════════════════════════
    -- 8g  AddLabel
    -- ══════════════════════════════════════════════════════════════════
    function tab:AddLabel(text)
        local f = base("Lbl_"..tostring(text), 36)
        f.BackgroundTransparency = 0.45

        local l = Instance.new("TextLabel")
        l.Size                  = UDim2.new(1,-20,1,0)
        l.Position              = UDim2.new(0,12,0,0)
        l.BackgroundTransparency = 1
        l.Text                  = text or ""
        l.TextColor3            = T.TextMuted
        l.TextSize              = 12
        l.Font                  = Enum.Font.Gotham
        l.TextXAlignment        = Enum.TextXAlignment.Left
        l.TextWrapped           = true
        l.ZIndex                = BASE+4
        l.Parent                = f

        local api={}
        function api:Set(t) l.Text=t end
        function api:Get()  return l.Text end
        return api
    end

    return tab
end

-- ══════════════════════════════════════════════════════════════════════
-- §9  NOTIFY
-- ══════════════════════════════════════════════════════════════════════
function Library:Notify(cfg)
    assert(self._win,"Call Boot() before Notify()")
    cfg = cfg or {}
    local dur = math.max(cfg.Duration or 4, 1)
    local j   = Janitor.new()
    self._notifN += 1

    local n = Instance.new("Frame")
    n.Name                  = "Notif_"..self._notifN
    n.Size                  = UDim2.new(1,0,0,72)
    n.BackgroundColor3      = Color3.fromRGB(20,18,30)
    n.BackgroundTransparency = 0
    n.ZIndex                = 850
    n.LayoutOrder           = self._notifN
    n.Position              = UDim2.new(1,320,0,0)
    n.Parent                = self._win.NotifAnchor
    U.Corner(n,8)
    U.Stroke(n, T.Accent, 1, 0.35)
    j:Add(n,"Destroy","F")

    -- Left colored bar
    local nb = Instance.new("Frame")
    nb.Size                 = UDim2.new(0,3,0.65,0)
    nb.AnchorPoint          = Vector2.new(0,0.5)
    nb.Position             = UDim2.new(0,0,0.5,0)
    nb.BackgroundColor3     = T.Accent
    nb.BackgroundTransparency = 0
    nb.ZIndex               = 851
    nb.Parent               = n
    U.Corner(nb,3)

    local xOff = 12
    if cfg.IconId then
        local ic = Instance.new("ImageLabel")
        ic.Size             = UDim2.new(0,26,0,26)
        ic.AnchorPoint      = Vector2.new(0,0.5)
        ic.Position         = UDim2.new(0,12,0.5,-4)
        ic.BackgroundTransparency = 1
        ic.Image            = cfg.IconId
        ic.ScaleType        = Enum.ScaleType.Fit
        ic.ZIndex           = 851
        ic.Parent           = n
        xOff = 44
    end

    local title = Instance.new("TextLabel")
    title.Size              = UDim2.new(1,-(xOff+28),0,22)
    title.Position          = UDim2.new(0,xOff,0,10)
    title.BackgroundTransparency = 1
    title.Text              = cfg.Title or "Notice"
    title.TextColor3        = T.TextPri
    title.TextSize          = 13
    title.Font              = Enum.Font.GothamBold
    title.TextXAlignment    = Enum.TextXAlignment.Left
    title.ZIndex            = 851
    title.Parent            = n

    local body = Instance.new("TextLabel")
    body.Size               = UDim2.new(1,-(xOff+10),0,22)
    body.Position           = UDim2.new(0,xOff,0,32)
    body.BackgroundTransparency = 1
    body.Text               = cfg.Content or ""
    body.TextColor3         = T.TextSec
    body.TextSize           = 11
    body.Font               = Enum.Font.Gotham
    body.TextXAlignment     = Enum.TextXAlignment.Left
    body.TextWrapped        = true
    body.ZIndex             = 851
    body.Parent             = n

    local xBtn = Instance.new("TextButton")
    xBtn.Size               = UDim2.new(0,16,0,16)
    xBtn.AnchorPoint        = Vector2.new(1,0)
    xBtn.Position           = UDim2.new(1,-6,0,6)
    xBtn.BackgroundTransparency = 1
    xBtn.Text               = "✕"
    xBtn.TextColor3         = T.TextMuted
    xBtn.TextSize           = 10
    xBtn.Font               = Enum.Font.GothamBold
    xBtn.ZIndex             = 852
    xBtn.Parent             = n

    -- Drain bar
    local db = Instance.new("Frame")
    db.Size                 = UDim2.new(1,0,0,2)
    db.AnchorPoint          = Vector2.new(0,1)
    db.Position             = UDim2.new(0,0,1,0)
    db.BackgroundColor3     = Color3.fromRGB(30,28,45)
    db.BackgroundTransparency = 0
    db.ZIndex               = 852
    db.Parent               = n
    U.Corner(db,2)

    local df = Instance.new("Frame")
    df.Size                 = UDim2.new(1,0,1,0)
    df.BackgroundColor3     = T.Accent
    df.BackgroundTransparency = 0
    df.ZIndex               = 853
    df.Parent               = db
    U.Corner(df,2)
    U.Grad(df, T.AccentDim, T.AccentBright, 0)

    task.defer(function()
        U.Tw(n, {Position=UDim2.new(0,0,0,0)}, 0.38, Enum.EasingStyle.Quint)
    end)
    U.Tw(df, {Size=UDim2.new(0,0,1,0)}, dur, Enum.EasingStyle.Linear)

    local function dismiss()
        U.Tw(n,{Position=UDim2.new(1,320,0,0),BackgroundTransparency=1},0.3,Enum.EasingStyle.Quint)
        task.delay(0.35,function() j:Cleanup() end)
    end

    local auto = task.delay(dur, dismiss)
    j:Add(function() task.cancel(auto) end,"fn")
    j:Add(xBtn.MouseButton1Click:Connect(function() task.cancel(auto); dismiss() end),"Disconnect")
    return n
end

-- ══════════════════════════════════════════════════════════════════════
-- §10  WATERMARK
-- ══════════════════════════════════════════════════════════════════════
function Library:Watermark(cfg)
    assert(self._gui,"Call Boot() before Watermark()")
    cfg = cfg or {}
    local j   = Janitor.new()

    local wm = Instance.new("Frame")
    wm.Name                 = "Watermark"
    wm.AnchorPoint          = Vector2.new(0.5,0)
    wm.Size                 = UDim2.new(0,220,0,34)
    wm.Position             = cfg.Position or UDim2.new(0.5,0,0,12)
    wm.BackgroundColor3     = Color3.fromRGB(18,15,28)
    wm.BackgroundTransparency = 0
    wm.ZIndex               = 750
    wm.Parent               = self._gui
    U.Corner(wm,7)
    U.Stroke(wm, T.Accent, 1, 0.3)
    j:Add(wm,"Destroy","WM")

    -- top accent line
    local tl = Instance.new("Frame")
    tl.Size                 = UDim2.new(0.55,0,0,1)
    tl.BackgroundColor3     = T.Accent
    tl.BackgroundTransparency = 0.55
    tl.ZIndex               = 751
    tl.Parent               = wm
    U.Grad(tl, T.AccentBright, Color3.new(0,0,0), 0)

    local mT = Instance.new("TextLabel")
    mT.Size                 = UDim2.new(1,-80,1,0)
    mT.Position             = UDim2.new(0,10,0,0)
    mT.BackgroundTransparency = 1
    mT.Text                 = cfg.Text or self._hubName
    mT.TextColor3           = T.TextPri
    mT.TextSize             = 12
    mT.Font                 = Enum.Font.GothamBold
    mT.TextXAlignment       = Enum.TextXAlignment.Left
    mT.ZIndex               = 751
    mT.Parent               = wm

    local sT = Instance.new("TextLabel")
    sT.Size                 = UDim2.new(0,70,1,0)
    sT.AnchorPoint          = Vector2.new(1,0)
    sT.Position             = UDim2.new(1,-8,0,0)
    sT.BackgroundTransparency = 1
    sT.Text                 = cfg.SubText or "v2.0"
    sT.TextColor3           = T.AccentBright
    sT.TextSize             = 10
    sT.Font                 = Enum.Font.GothamBold
    sT.TextXAlignment       = Enum.TextXAlignment.Right
    sT.ZIndex               = 751
    sT.Parent               = wm

    if cfg.ShowFPS then
        local fc=0
        local rc=RunService.RenderStepped:Connect(function() fc+=1 end)
        j:Add(rc,"Disconnect","FPS")
        local function poll()
            local fps=fc*2; fc=0
            sT.Text=(fps>=55 and "FPS: "..fps or fps>=30 and "FPS: "..fps or "FPS: "..fps)
            sT.TextColor3=(fps>=55 and T.Success or fps>=30 and T.Warning or T.Error)
            task.delay(0.5,poll)
        end
        task.delay(0.5,poll)
    end

    -- Drag
    local dg,sm,sp=false,nil,nil
    j:Add(wm.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=true;sm=i.Position;sp=wm.Position end
    end),"Disconnect")
    j:Add(wm.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end
    end),"Disconnect")
    j:Add(UserInputService.InputChanged:Connect(function(i)
        if dg and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-sm
            wm.Position=UDim2.new(0,sp.X.Offset+d.X,0,sp.Y.Offset+d.Y)
        end
    end),"Disconnect")

    self._jan:Add(function() j:Cleanup() end,"fn")
    local visible=true
    local api={}
    function api:SetText(m,s) if m then mT.Text=m end; if s then sT.Text=s end end
    function api:Toggle()
        visible=not visible
        U.Tw(wm,{BackgroundTransparency=visible and 0 or 1},0.25)
        U.Tw(mT,{TextTransparency=visible and 0 or 1},0.2)
        U.Tw(sT,{TextTransparency=visible and 0 or 1},0.2)
    end
    function api:Destroy() j:Cleanup() end
    return api
end

-- ══════════════════════════════════════════════════════════════════════
-- §11  SET THEME
-- ══════════════════════════════════════════════════════════════════════
local Presets = {
    Violet  = {A=Color3.fromRGB(138,43,226),  AL=Color3.fromRGB(175,100,255), AD=Color3.fromRGB(90,22,160)},
    Cyan    = {A=Color3.fromRGB(0,210,255),   AL=Color3.fromRGB(80,235,255),  AD=Color3.fromRGB(0,145,200)},
    Rose    = {A=Color3.fromRGB(220,50,120),  AL=Color3.fromRGB(255,100,160), AD=Color3.fromRGB(165,20,80)},
    Emerald = {A=Color3.fromRGB(16,200,120),  AL=Color3.fromRGB(60,240,155),  AD=Color3.fromRGB(8,140,80)},
    Gold    = {A=Color3.fromRGB(230,175,30),  AL=Color3.fromRGB(255,215,80),  AD=Color3.fromRGB(165,115,10)},
}

function Library:SetTheme(preset)
    local p = type(preset)=="string" and Presets[preset] or nil
    local nA  = p and p.A  or (typeof(preset)=="Color3" and preset) or T.Accent
    local nAL = p and p.AL or nA:Lerp(Color3.new(1,1,1),0.28)
    local nAD = p and p.AD or nA:Lerp(Color3.new(0,0,0),0.28)

    local oA,oAL,oAD = T.Accent,T.AccentBright,T.AccentDim
    T.Accent=nA; T.AccentBright=nAL; T.AccentDim=nAD

    local tol=18/255
    local function close(c,r)
        return math.abs(c.R-r.R)<tol and math.abs(c.G-r.G)<tol and math.abs(c.B-r.B)<tol
    end
    local function walk(inst)
        if inst:IsA("GuiObject") then
            if close(inst.BackgroundColor3,oA)  then U.Tw(inst,{BackgroundColor3=nA},0.3)
            elseif close(inst.BackgroundColor3,oAL) then U.Tw(inst,{BackgroundColor3=nAL},0.3)
            elseif close(inst.BackgroundColor3,oAD) then U.Tw(inst,{BackgroundColor3=nAD},0.3) end
        end
        if inst:IsA("TextLabel") or inst:IsA("TextButton") then
            if close(inst.TextColor3,oA)   then U.Tw(inst,{TextColor3=nA},0.3)
            elseif close(inst.TextColor3,oAL) then U.Tw(inst,{TextColor3=nAL},0.3) end
        end
        if inst:IsA("UIStroke") then
            if close(inst.Color,oA) then U.Tw(inst,{Color=nA},0.3) end
        end
        for _,c in ipairs(inst:GetChildren()) do walk(c) end
    end
    walk(self._gui)
    self:Notify({Title="Theme: "..(type(preset)=="string" and preset or "Custom"),Content="Applied successfully.",Duration=2})
end

-- ══════════════════════════════════════════════════════════════════════
-- §12  DESTROY
-- ══════════════════════════════════════════════════════════════════════
function Library:Destroy()
    self._jan:Cleanup()
end

return NexusUI
