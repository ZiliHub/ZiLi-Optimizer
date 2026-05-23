--[[
╔══════════════════════════════════════════════════════════════════╗
║                     N E X U S   U I                              ║
║            Premium Glassmorphism UI Library for Roblox           ║
║                                                                  ║
║  USAGE:                                                          ║
║    local NexusUI = loadstring(...)() -- or require(module)       ║
║    local Library = NexusUI.new()                                 ║
║                                                                  ║
║    -- Pass your rbxassetid:// logo below:                        ║
║    Library:Boot("My Hub", "rbxassetid://YOUR_LOGO_ID_HERE")      ║
║                                                                  ║
║    local tab = Library:CreateTab("Main", "rbxassetid://ICON_ID") ║
║    tab:AddButton({ Name = "Click", Callback = function() end })  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
--]]

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 1 · SERVICES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 2 · JANITOR  (Zero-Leak Memory Management)
--
--   Every RBXScriptConnection, Instance, and task is tracked here.
--   Call janitor:Cleanup() to atomically disconnect and destroy
--   every resource without a single leak.
--
--   Usage:
--     local j = Janitor.new()
--     j:Add(frame.MouseEnter:Connect(fn), "Disconnect")   -- event
--     j:Add(someFrame, "Destroy")                          -- instance
--     j:Add(function() print("ran on cleanup") end, "fn") -- arbitrary
--     j:Cleanup()   -- destroys everything
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
    return setmetatable({ _tasks = {}, _counter = 0 }, Janitor)
end

--- Add a resource to be cleaned up.
--- @param object  any     – Instance, RBXScriptConnection, or function
--- @param method  string  – "Destroy", "Disconnect", or "fn" (calls object())
--- @param key     string? – optional stable key; replaces previous entry
function Janitor:Add(object, method, key)
    local entry = { obj = object, method = method or "Destroy" }
    if key then
        -- Replace existing entry with the same key (auto-clean the old one)
        if self._tasks[key] then
            self:_cleanEntry(self._tasks[key])
        end
        self._tasks[key] = entry
    else
        self._counter += 1
        self._tasks[self._counter] = entry
    end
    return object
end

function Janitor:_cleanEntry(entry)
    local obj, method = entry.obj, entry.method
    pcall(function()
        if method == "fn" or type(obj) == "function" then
            obj()
        elseif obj and obj[method] then
            obj[method](obj)
        end
    end)
end

--- Remove and clean a single keyed entry.
function Janitor:Remove(key)
    if self._tasks[key] then
        self:_cleanEntry(self._tasks[key])
        self._tasks[key] = nil
    end
end

--- Clean ALL tracked resources and reset the Janitor.
function Janitor:Cleanup()
    for _, entry in pairs(self._tasks) do
        self:_cleanEntry(entry)
    end
    table.clear(self._tasks)
    self._counter = 0
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 3 · THEME
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local T = {
    -- Backgrounds
    Bg          = Color3.fromRGB(15,  15,  20),
    BgAlt       = Color3.fromRGB(20,  20,  28),
    Surface     = Color3.fromRGB(25,  25,  35),
    SurfaceAlt  = Color3.fromRGB(32,  30,  45),

    -- Accent — Violet glow
    Accent      = Color3.fromRGB(138, 43,  226),
    AccentLight = Color3.fromRGB(175, 100, 255),
    AccentDark  = Color3.fromRGB(100, 20,  175),
    AccentGlow  = Color3.fromRGB(138, 43,  226),

    -- Text
    TextPri     = Color3.fromRGB(240, 240, 255),
    TextSec     = Color3.fromRGB(160, 160, 190),
    TextMuted   = Color3.fromRGB(90,  90,  120),

    -- Borders
    Border      = Color3.fromRGB(55,  50,  80),
    BorderLight = Color3.fromRGB(80,  75,  110),

    -- Semantic
    Success     = Color3.fromRGB(34,  197, 94),
    Warning     = Color3.fromRGB(251, 191, 36),
    Error       = Color3.fromRGB(239, 68,  68),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 4 · UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Util = {}

--- Fire-and-forget tween. Returns the Tween object.
function Util.Tween(inst, props, dur, style, dir)
    local info = TweenInfo.new(
        dur   or 0.3,
        style or Enum.EasingStyle.Quint,
        dir   or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

--- Quick linear tween (for progress bars, sliders, etc.)
function Util.TweenLinear(inst, props, dur)
    return Util.Tween(inst, props, dur, Enum.EasingStyle.Linear)
end

--- Fake drop-shadow via a dark sliced ImageLabel.
--- Parented BEHIND the target frame (ZIndex - 1).
function Util.Shadow(parent, spread)
    spread = spread or 18
    local s      = Instance.new("ImageLabel")
    s.Name       = "_Shadow"
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.BackgroundTransparency = 1
    s.Position   = UDim2.new(0.5, 0, 0.5, 6)
    s.Size       = UDim2.new(1, spread * 2, 1, spread * 2)
    s.ZIndex     = math.max(1, parent.ZIndex - 1)
    -- Soft circular shadow (Roblox stock asset – always available)
    s.Image      = "rbxassetid://6015897843"
    s.ImageColor3 = Color3.fromRGB(0, 0, 0)
    s.ImageTransparency = 0.45
    s.ScaleType  = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49, 49, 450, 450)
    s.Parent     = parent
    return s
end

--- UICorner helper
function Util.Corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

--- UIStroke helper
function Util.Stroke(parent, col, thick, transp)
    local s = Instance.new("UIStroke")
    s.Color       = col   or T.Border
    s.Thickness   = thick or 1
    s.Transparency = transp or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent      = parent
    return s
end

--- UIPadding helper (top, bottom, left, right all in px)
function Util.Pad(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 8)
    p.PaddingBottom = UDim.new(0, b or 8)
    p.PaddingLeft   = UDim.new(0, l or 10)
    p.PaddingRight  = UDim.new(0, r or 10)
    p.Parent        = parent
    return p
end

--- Ripple click effect. Connections tracked by janitor.
function Util.Ripple(btn, janitor)
    local conn = btn.MouseButton1Down:Connect(function(x, y)
        local r     = Instance.new("Frame")
        r.BackgroundColor3 = Color3.new(1, 1, 1)
        r.BackgroundTransparency = 0.82
        r.ZIndex    = btn.ZIndex + 8
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        local ap    = btn.AbsolutePosition
        local as    = btn.AbsoluteSize
        r.Position  = UDim2.new(0, x - ap.X, 0, y - ap.Y)
        r.Size      = UDim2.new(0, 0, 0, 0)
        Util.Corner(r, 9999)
        r.Parent    = btn

        local maxD  = math.max(as.X, as.Y) * 2.8
        Util.Tween(r, {
            Size = UDim2.new(0, maxD, 0, maxD),
            BackgroundTransparency = 1,
        }, 0.55, Enum.EasingStyle.Quint)

        task.delay(0.6, function() r:Destroy() end)
    end)
    if janitor then janitor:Add(conn, "Disconnect") end
    return conn
end

--- Horizontal UIGradient shortcut
function Util.Gradient(parent, colA, colB, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colA),
        ColorSequenceKeypoint.new(1, colB),
    })
    g.Rotation = rotation or 0
    g.Parent   = parent
    return g
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 5 · LIBRARY CLASS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local Library = {}
Library.__index = Library

local NexusUI = {}  -- Module table returned to the user

--- Create a new Library instance.
function NexusUI.new()
    return setmetatable({
        _janitor    = Janitor.new(),
        _tabs       = {},
        _activeTab  = nil,
        _minimized  = false,
        _notifCount = 0,
        _screenGui  = nil,
        _win        = nil,     -- main window tables
        _hubName    = "NexusUI",
        _logoId     = "rbxassetid://0",
    }, Library)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 6 · BOOT / LOADING SCREEN
--
--   Library:Boot(hubName, logoAssetId)
--
--   logoAssetId: pass your rbxassetid:// string, e.g.
--       "rbxassetid://12345678"
--   The ImageLabel uses ScaleType = Fit to keep your logo's
--   aspect ratio perfectly intact regardless of its dimensions.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:Boot(hubName, logoAssetId)
    self._hubName = hubName or "NexusUI"
    self._logoId  = logoAssetId or "rbxassetid://0"

    -- ── ScreenGui ──────────────────────────────────────────────
    local gui = Instance.new("ScreenGui")
    gui.Name            = "NexusUI_" .. self._hubName
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder    = 999
    gui.IgnoreGuiInset  = true

    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    self._screenGui = gui
    self._janitor:Add(gui, "Destroy", "ScreenGui")

    -- ── Loading Canvas ─────────────────────────────────────────
    local canvas = Instance.new("Frame")
    canvas.Name                  = "LoadingCanvas"
    canvas.Size                  = UDim2.new(1, 0, 1, 0)
    canvas.BackgroundColor3      = T.Bg
    canvas.BackgroundTransparency = 0
    canvas.ZIndex                = 500
    canvas.Parent                = gui
    -- Deep gradient backdrop
    Util.Gradient(canvas, Color3.fromRGB(8, 5, 18), Color3.fromRGB(5, 10, 25), 145)

    -- Ambient glow orb (decorative)
    local orb = Instance.new("ImageLabel")
    orb.AnchorPoint          = Vector2.new(0.5, 0.5)
    orb.Size                 = UDim2.new(0, 500, 0, 500)
    orb.Position             = UDim2.new(0.5, 0, 0.45, 0)
    orb.BackgroundTransparency = 1
    orb.Image                = "rbxassetid://6015897843"
    orb.ImageColor3          = T.Accent
    orb.ImageTransparency    = 0.88
    orb.ScaleType            = Enum.ScaleType.Slice
    orb.SliceCenter          = Rect.new(49, 49, 450, 450)
    orb.ZIndex               = 501
    orb.Parent               = canvas

    -- Logo card
    local logoCard = Instance.new("Frame")
    logoCard.Name               = "LogoCard"
    logoCard.AnchorPoint        = Vector2.new(0.5, 0.5)
    logoCard.Size               = UDim2.new(0, 160, 0, 160)
    logoCard.Position           = UDim2.new(0.5, 0, 0.42, 0)
    logoCard.BackgroundColor3   = T.Surface
    logoCard.BackgroundTransparency = 1     -- starts invisible
    logoCard.ZIndex             = 502
    logoCard.Parent             = canvas
    Util.Corner(logoCard, 22)
    Util.Stroke(logoCard, T.Accent, 1.5, 0.3)
    Util.Shadow(logoCard, 40)

    -- Inner gradient on card
    Util.Gradient(logoCard, Color3.fromRGB(30, 22, 50), T.Surface, 135)

    --[[
        Logo Image:
        • ScaleType = Fit ensures your asset's original aspect ratio is
          always preserved — no stretching.
        • Replace the Image property with your own rbxassetid://.
    --]]
    local logoImg = Instance.new("ImageLabel")
    logoImg.AnchorPoint         = Vector2.new(0.5, 0.5)
    logoImg.Size                = UDim2.new(0.68, 0, 0.68, 0)
    logoImg.Position            = UDim2.new(0.5, 0, 0.5, 0)
    logoImg.BackgroundTransparency = 1
    logoImg.Image               = self._logoId   -- ← Your rbxassetid://
    logoImg.ScaleType           = Enum.ScaleType.Fit
    logoImg.ImageTransparency   = 1              -- fades in
    logoImg.ZIndex              = 503
    logoImg.Parent              = logoCard

    -- Hub name
    local nameTag = Instance.new("TextLabel")
    nameTag.AnchorPoint         = Vector2.new(0.5, 0)
    nameTag.Size                = UDim2.new(0, 320, 0, 38)
    nameTag.Position            = UDim2.new(0.5, 0, 0.42, 102)
    nameTag.BackgroundTransparency = 1
    nameTag.Text                = self._hubName
    nameTag.TextColor3          = T.TextPri
    nameTag.TextSize            = 26
    nameTag.Font                = Enum.Font.GothamBold
    nameTag.TextTransparency    = 1
    nameTag.ZIndex              = 502
    nameTag.Parent              = canvas

    -- Status text
    local statusTag = Instance.new("TextLabel")
    statusTag.AnchorPoint       = Vector2.new(0.5, 0)
    statusTag.Size              = UDim2.new(0, 320, 0, 22)
    statusTag.Position          = UDim2.new(0.5, 0, 0.42, 147)
    statusTag.BackgroundTransparency = 1
    statusTag.Text              = "Initializing..."
    statusTag.TextColor3        = T.TextSec
    statusTag.TextSize          = 13
    statusTag.Font              = Enum.Font.Gotham
    statusTag.TextTransparency  = 1
    statusTag.ZIndex            = 502
    statusTag.Parent            = canvas

    -- Progress track
    local progressTrack = Instance.new("Frame")
    progressTrack.AnchorPoint   = Vector2.new(0.5, 0)
    progressTrack.Size          = UDim2.new(0, 280, 0, 4)
    progressTrack.Position      = UDim2.new(0.5, 0, 0.42, 178)
    progressTrack.BackgroundColor3 = T.SurfaceAlt
    progressTrack.BackgroundTransparency = 1
    progressTrack.ZIndex        = 502
    progressTrack.Parent        = canvas
    Util.Corner(progressTrack, 4)

    local progressFill = Instance.new("Frame")
    progressFill.Size           = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = T.Accent
    progressFill.ZIndex         = 503
    progressFill.Parent         = progressTrack
    Util.Corner(progressFill, 4)
    Util.Gradient(progressFill, T.AccentDark, T.AccentLight, 0)

    -- ── Animated Boot Sequence ─────────────────────────────────
    task.spawn(function()
        task.wait(0.25)

        -- Phase 1: reveal logo card
        Util.Tween(logoCard,  { BackgroundTransparency = 0.15 }, 0.7)
        Util.Tween(logoImg,   { ImageTransparency = 0 },         0.6)
        Util.Tween(orb,       { ImageTransparency = 0.80 },      0.9)
        task.wait(0.45)

        -- Phase 2: reveal text + track
        Util.Tween(nameTag,      { TextTransparency = 0 }, 0.45)
        Util.Tween(statusTag,    { TextTransparency = 0 }, 0.45)
        Util.Tween(progressTrack,{ BackgroundTransparency = 0.4 }, 0.45)
        task.wait(0.3)

        -- Phase 3: progress steps
        local steps = {
            { text = "Authenticating...",   pct = 0.18, wait = 0.55 },
            { text = "Loading Assets...",   pct = 0.42, wait = 0.50 },
            { text = "Building Interface...",pct = 0.68, wait = 0.45 },
            { text = "Applying Theme...",   pct = 0.87, wait = 0.38 },
            { text = "Ready!",              pct = 1.00, wait = 0.28 },
        }
        for _, step in ipairs(steps) do
            statusTag.Text = step.text
            Util.TweenLinear(progressFill, { Size = UDim2.new(step.pct, 0, 1, 0) }, 0.38)
            task.wait(step.wait)
        end

        task.wait(0.25)

        -- Build main window (hidden)
        self:_BuildMainWindow()

        -- Phase 4: fade-out loading canvas and reveal main window
        Util.Tween(canvas,     { BackgroundTransparency = 1 }, 0.55, Enum.EasingStyle.Sine)
        Util.Tween(nameTag,    { TextTransparency = 1 },       0.35)
        Util.Tween(statusTag,  { TextTransparency = 1 },       0.3)
        Util.Tween(logoCard,   { BackgroundTransparency = 1 }, 0.4)
        Util.Tween(logoImg,    { ImageTransparency = 1 },      0.3)
        Util.Tween(progressTrack, { BackgroundTransparency = 1 }, 0.3)

        -- Reveal main window
        local wf = self._win.Frame
        Util.Tween(wf, { BackgroundTransparency = 0.1,
                         Size = UDim2.new(0, 720, 0, 480) }, 0.5, Enum.EasingStyle.Quint)

        task.wait(0.6)
        canvas:Destroy()
    end)

    return self
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 7 · BUILD MAIN WINDOW  (called internally after boot)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:_BuildMainWindow()
    local win = {}
    self._win = win

    -- ── Outer shadow ───────────────────────────────────────────
    local shadow = Instance.new("Frame")
    shadow.Name               = "WinShadow"
    shadow.AnchorPoint        = Vector2.new(0.5, 0.5)
    shadow.Size               = UDim2.new(0, 760, 0, 520)
    shadow.Position           = UDim2.new(0.5, 0, 0.5, 6)
    shadow.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.55
    shadow.ZIndex             = 9
    shadow.Parent             = self._screenGui
    Util.Corner(shadow, 12)
    win.Shadow = shadow

    -- ── Main Frame ─────────────────────────────────────────────
    local frame = Instance.new("Frame")
    frame.Name                = "MainFrame"
    -- starts collapsed (height = 0) for the boot reveal animation
    frame.Size                = UDim2.new(0, 720, 0, 0)
    frame.Position            = UDim2.new(0.5, -360, 0.5, -240)
    frame.BackgroundColor3    = T.Bg
    frame.BackgroundTransparency = 0.1   -- glassmorphism layer
    frame.ZIndex              = 10
    frame.ClipsDescendants    = true
    frame.Parent              = self._screenGui
    Util.Corner(frame, 8)
    Util.Stroke(frame, T.Border, 1, 0.35)
    -- Subtle purple tint gradient for depth
    Util.Gradient(frame, Color3.fromRGB(18, 14, 30), Color3.fromRGB(10, 10, 18), 145)
    win.Frame = frame

    -- Decorative ambient orb top-right corner
    local ambientOrb = Instance.new("Frame")
    ambientOrb.Size             = UDim2.new(0, 220, 0, 220)
    ambientOrb.Position         = UDim2.new(1, -70, 0, -70)
    ambientOrb.BackgroundColor3 = T.Accent
    ambientOrb.BackgroundTransparency = 0.91
    ambientOrb.ZIndex           = 10
    ambientOrb.Parent           = frame
    Util.Corner(ambientOrb, 999)

    -- ── Top Bar ────────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Name               = "TopBar"
    topBar.Size               = UDim2.new(1, 0, 0, 48)
    topBar.BackgroundColor3   = T.BgAlt
    topBar.BackgroundTransparency = 0.25
    topBar.ZIndex             = 15
    topBar.Parent             = frame
    win.TopBar = topBar

    -- Bottom border line
    local tbBorder = Instance.new("Frame")
    tbBorder.Size             = UDim2.new(1, 0, 0, 1)
    tbBorder.Position         = UDim2.new(0, 0, 1, -1)
    tbBorder.BackgroundColor3 = T.Border
    tbBorder.BackgroundTransparency = 0.4
    tbBorder.ZIndex           = 16
    tbBorder.Parent           = topBar

    -- Logo badge in top bar
    local logoBadge = Instance.new("Frame")
    logoBadge.Size            = UDim2.new(0, 30, 0, 30)
    logoBadge.Position        = UDim2.new(0, 12, 0.5, -15)
    logoBadge.BackgroundColor3 = T.Accent
    logoBadge.BackgroundTransparency = 0.35
    logoBadge.ZIndex          = 16
    logoBadge.Parent          = topBar
    Util.Corner(logoBadge, 7)

    local tbLogo = Instance.new("ImageLabel")
    tbLogo.AnchorPoint        = Vector2.new(0.5, 0.5)
    tbLogo.Size               = UDim2.new(0.72, 0, 0.72, 0)
    tbLogo.Position           = UDim2.new(0.5, 0, 0.5, 0)
    tbLogo.BackgroundTransparency = 1
    tbLogo.Image              = self._logoId    -- ← logo passed to Boot()
    tbLogo.ScaleType          = Enum.ScaleType.Fit
    tbLogo.ZIndex             = 17
    tbLogo.Parent             = logoBadge

    local hubTitle = Instance.new("TextLabel")
    hubTitle.Size             = UDim2.new(0, 200, 1, 0)
    hubTitle.Position         = UDim2.new(0, 52, 0, 0)
    hubTitle.BackgroundTransparency = 1
    hubTitle.Text             = self._hubName
    hubTitle.TextColor3       = T.TextPri
    hubTitle.TextSize         = 16
    hubTitle.Font             = Enum.Font.GothamBold
    hubTitle.TextXAlignment   = Enum.TextXAlignment.Left
    hubTitle.ZIndex           = 16
    hubTitle.Parent           = topBar

    -- Window controls: Minimize + Close
    local function makeCtrlBtn(text, bgColor, offsetX)
        local btn = Instance.new("TextButton")
        btn.Size              = UDim2.new(0, 28, 0, 28)
        btn.AnchorPoint       = Vector2.new(1, 0.5)
        btn.Position          = UDim2.new(1, offsetX, 0.5, 0)
        btn.BackgroundColor3  = bgColor
        btn.BackgroundTransparency = 0.35
        btn.Text              = text
        btn.TextColor3        = T.TextSec
        btn.TextSize          = 13
        btn.Font              = Enum.Font.GothamBold
        btn.ZIndex            = 17
        btn.Parent            = topBar
        Util.Corner(btn, 6)
        return btn
    end

    local minBtn   = makeCtrlBtn("—", T.SurfaceAlt, -46)
    local closeBtn = makeCtrlBtn("✕", Color3.fromRGB(185, 40, 40), -12)

    -- Hover on Minimize
    self._janitor:Add(minBtn.MouseEnter:Connect(function()
        Util.Tween(minBtn, { BackgroundTransparency = 0.05, TextColor3 = T.TextPri }, 0.18)
    end), "Disconnect")
    self._janitor:Add(minBtn.MouseLeave:Connect(function()
        Util.Tween(minBtn, { BackgroundTransparency = 0.35, TextColor3 = T.TextSec }, 0.18)
    end), "Disconnect")

    -- Hover on Close
    self._janitor:Add(closeBtn.MouseEnter:Connect(function()
        Util.Tween(closeBtn, {
            BackgroundTransparency = 0.05,
            BackgroundColor3       = Color3.fromRGB(220, 30, 30),
            TextColor3             = T.TextPri,
        }, 0.18)
    end), "Disconnect")
    self._janitor:Add(closeBtn.MouseLeave:Connect(function()
        Util.Tween(closeBtn, {
            BackgroundTransparency = 0.35,
            BackgroundColor3       = Color3.fromRGB(185, 40, 40),
        }, 0.18)
    end), "Disconnect")

    -- Minimize toggle
    self._janitor:Add(minBtn.MouseButton1Click:Connect(function()
        self._minimized = not self._minimized
        if self._minimized then
            Util.Tween(frame,  { Size = UDim2.new(0, 720, 0, 48) },  0.35, Enum.EasingStyle.Quint)
            Util.Tween(shadow, { Size = UDim2.new(0, 760, 0, 80) },  0.35, Enum.EasingStyle.Quint)
            minBtn.Text = "□"
        else
            Util.Tween(frame,  { Size = UDim2.new(0, 720, 0, 480) }, 0.35, Enum.EasingStyle.Quint)
            Util.Tween(shadow, { Size = UDim2.new(0, 760, 0, 520) }, 0.35, Enum.EasingStyle.Quint)
            minBtn.Text = "—"
        end
    end), "Disconnect")

    -- Close: fade out → destroy everything via Janitor
    self._janitor:Add(closeBtn.MouseButton1Click:Connect(function()
        Util.Tween(frame,  { BackgroundTransparency = 1,
                             Size = UDim2.new(0, 680, 0, 0) }, 0.38, Enum.EasingStyle.Quint)
        Util.Tween(shadow, { BackgroundTransparency = 1 },         0.28)
        task.delay(0.42, function() self:Destroy() end)
    end), "Disconnect")

    -- ── Drag Logic ────────────────────────────────────────────
    -- All connections tracked in janitor; no RunService.RenderStepped used.
    do
        local dragging, startMouse, startFrame = false, nil, nil

        self._janitor:Add(topBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging   = true
                startMouse = inp.Position
                startFrame = frame.Position
            end
        end), "Disconnect")

        self._janitor:Add(topBar.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end), "Disconnect")

        self._janitor:Add(UserInputService.InputChanged:Connect(function(inp)
            if not dragging then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
                local delta = inp.Position - startMouse
                frame.Position = UDim2.new(
                    startFrame.X.Scale, startFrame.X.Offset + delta.X,
                    startFrame.Y.Scale, startFrame.Y.Offset + delta.Y
                )
                shadow.Position = UDim2.new(
                    frame.Position.X.Scale,
                    frame.Position.X.Offset + (shadow.AbsoluteSize.X - frame.AbsoluteSize.X) * 0.5,
                    frame.Position.Y.Scale,
                    frame.Position.Y.Offset + 6
                )
            end
        end), "Disconnect")
    end

    -- ── Left Tab Navigation ───────────────────────────────────
    local tabNav = Instance.new("Frame")
    tabNav.Name               = "TabNav"
    tabNav.Size               = UDim2.new(0, 158, 1, -48)
    tabNav.Position           = UDim2.new(0, 0, 0, 48)
    tabNav.BackgroundColor3   = T.BgAlt
    tabNav.BackgroundTransparency = 0.45
    tabNav.ZIndex             = 12
    tabNav.Parent             = frame
    win.TabNav = tabNav

    -- Right border separator
    local navLine = Instance.new("Frame")
    navLine.Size              = UDim2.new(0, 1, 1, 0)
    navLine.Position          = UDim2.new(1, -1, 0, 0)
    navLine.BackgroundColor3  = T.Border
    navLine.BackgroundTransparency = 0.4
    navLine.ZIndex            = 13
    navLine.Parent            = tabNav

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name            = "TabScroll"
    tabScroll.Size            = UDim2.new(1, 0, 1, -8)
    tabScroll.Position        = UDim2.new(0, 0, 0, 8)
    tabScroll.BackgroundTransparency = 1
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize      = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.ZIndex          = 13
    tabScroll.Parent          = tabNav
    win.TabScroll = tabScroll

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection   = Enum.FillDirection.Vertical
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding         = UDim.new(0, 3)
    tabLayout.Parent          = tabScroll
    Util.Pad(tabScroll, 6, 6, 6, 6)

    -- ── Content Area ──────────────────────────────────────────
    local content = Instance.new("Frame")
    content.Name              = "ContentArea"
    content.Size              = UDim2.new(1, -158, 1, -48)
    content.Position          = UDim2.new(0, 158, 0, 48)
    content.BackgroundTransparency = 1
    content.ZIndex            = 11
    content.ClipsDescendants  = true
    content.Parent            = frame
    win.ContentArea = content

    -- ── Notification Anchor (bottom-right of screen, above GUI) ──
    local notifAnchor = Instance.new("Frame")
    notifAnchor.Name          = "NotifAnchor"
    notifAnchor.AnchorPoint   = Vector2.new(1, 1)
    notifAnchor.Size          = UDim2.new(0, 330, 1, -20)
    notifAnchor.Position      = UDim2.new(1, -14, 1, -14)
    notifAnchor.BackgroundTransparency = 1
    notifAnchor.ZIndex        = 800
    notifAnchor.Parent        = self._screenGui
    self._janitor:Add(notifAnchor, "Destroy", "NotifAnchor")

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.FillDirection       = Enum.FillDirection.Vertical
    notifLayout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    notifLayout.Padding             = UDim.new(0, 8)
    notifLayout.Parent              = notifAnchor
    win.NotifAnchor = notifAnchor
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 8 · CREATE TAB
--
--   local tab = Library:CreateTab("Settings", "rbxassetid://123")
--   Returns a Tab object exposing:
--     tab:AddButton   tab:AddToggle   tab:AddSlider
--     tab:AddDropdown tab:AddKeybind  tab:AddSection  tab:AddLabel
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:CreateTab(name, iconId)
    assert(self._win, "Call Library:Boot() before CreateTab()")
    local win = self._win

    local tab = {}
    tab._janitor = Janitor.new()

    -- ── Tab Button (nav) ──────────────────────────────────────
    local btn = Instance.new("TextButton")
    btn.Name              = "TabBtn_" .. name
    btn.Size              = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3  = T.Surface
    btn.BackgroundTransparency = 1
    btn.Text              = ""
    btn.ZIndex            = 14
    btn.Parent            = win.TabScroll
    Util.Corner(btn, 6)
    tab._btn = btn

    -- Left active indicator pill
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, 3, 0.55, 0)
    pill.AnchorPoint      = Vector2.new(0, 0.5)
    pill.Position         = UDim2.new(0, 0, 0.5, 0)
    pill.BackgroundColor3 = T.Accent
    pill.BackgroundTransparency = 1
    pill.ZIndex           = 15
    pill.Parent           = btn
    Util.Corner(pill, 3)
    tab._pill = pill

    local tabIcon = Instance.new("ImageLabel")
    tabIcon.AnchorPoint       = Vector2.new(0, 0.5)
    tabIcon.Size              = UDim2.new(0, 16, 0, 16)
    tabIcon.Position          = UDim2.new(0, 12, 0.5, 0)
    tabIcon.BackgroundTransparency = 1
    tabIcon.Image             = iconId or ""
    tabIcon.ImageColor3       = T.TextMuted
    tabIcon.ScaleType         = Enum.ScaleType.Fit
    tabIcon.ZIndex            = 15
    tabIcon.Parent            = btn
    tab._icon = tabIcon

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Size             = UDim2.new(1, -(iconId and 36 or 14), 1, 0)
    tabLabel.Position         = UDim2.new(0, iconId and 34 or 14, 0, 0)
    tabLabel.BackgroundTransparency = 1
    tabLabel.Text             = name
    tabLabel.TextColor3       = T.TextMuted
    tabLabel.TextSize         = 13
    tabLabel.Font             = Enum.Font.Gotham
    tabLabel.TextXAlignment   = Enum.TextXAlignment.Left
    tabLabel.ZIndex           = 15
    tabLabel.Parent           = btn
    tab._label = tabLabel

    -- ── Content ScrollingFrame ────────────────────────────────
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name               = "TabContent_" .. name
    scroll.Size               = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = T.Accent
    scroll.ScrollBarImageTransparency = 0.4
    scroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex             = 12
    scroll.Visible            = false
    scroll.Parent             = win.ContentArea
    tab._scroll = scroll

    local cLayout = Instance.new("UIListLayout")
    cLayout.FillDirection     = Enum.FillDirection.Vertical
    cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cLayout.Padding           = UDim.new(0, 7)
    cLayout.Parent            = scroll
    Util.Pad(scroll, 12, 14, 14, 14)

    -- ── Tab Selection Logic ───────────────────────────────────
    local function selectTab()
        -- Deactivate previous tab (restore its visuals)
        if self._activeTab and self._activeTab ~= tab then
            local prev = self._activeTab
            Util.Tween(prev._btn,   { BackgroundTransparency = 1 },          0.22)
            Util.Tween(prev._label, { TextColor3 = T.TextMuted },             0.22)
            Util.Tween(prev._icon,  { ImageColor3 = T.TextMuted },            0.22)
            Util.Tween(prev._pill,  { BackgroundTransparency = 1 },           0.22)
            prev._label.Font  = Enum.Font.Gotham
            prev._scroll.Visible = false
        end
        self._activeTab = tab
        Util.Tween(btn,      { BackgroundTransparency = 0.55 }, 0.22)
        Util.Tween(tabLabel, { TextColor3 = T.TextPri },         0.22)
        Util.Tween(tabIcon,  { ImageColor3 = T.AccentLight },    0.22)
        Util.Tween(pill,     { BackgroundTransparency = 0 },     0.22)
        tabLabel.Font = Enum.Font.GothamBold
        scroll.Visible = true
    end
    tab._select = selectTab

    self._janitor:Add(btn.MouseEnter:Connect(function()
        if self._activeTab ~= tab then
            Util.Tween(btn,      { BackgroundTransparency = 0.78 }, 0.16)
            Util.Tween(tabLabel, { TextColor3 = T.TextSec },         0.16)
        end
    end), "Disconnect")
    self._janitor:Add(btn.MouseLeave:Connect(function()
        if self._activeTab ~= tab then
            Util.Tween(btn,      { BackgroundTransparency = 1 },     0.16)
            Util.Tween(tabLabel, { TextColor3 = T.TextMuted },       0.16)
        end
    end), "Disconnect")
    self._janitor:Add(btn.MouseButton1Click:Connect(selectTab), "Disconnect")

    -- Auto-select first tab
    if #self._tabs == 0 then task.defer(selectTab) end

    table.insert(self._tabs, tab)
    self._janitor:Add(function() tab._janitor:Cleanup() end, "fn")

    -- ─────────────────────────────────────────────────────────
    -- Internal: base frame factory for every component
    -- ─────────────────────────────────────────────────────────
    local function makeBase(compName, h)
        local f = Instance.new("Frame")
        f.Name                = compName
        f.Size                = UDim2.new(1, 0, 0, h or 48)
        f.BackgroundColor3    = T.Surface
        f.BackgroundTransparency = 0.25
        f.ZIndex              = 13
        f.Parent              = scroll
        Util.Corner(f, 6)
        Util.Stroke(f, T.Border, 1, 0.58)
        return f
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 8a · Tab:AddButton({ Name, Callback })
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function tab:AddButton(cfg)
        cfg = cfg or {}
        local j    = Janitor.new()
        local base = makeBase(cfg.Name or "Button", 48)

        -- Invisible overlay button (clips children for ripple)
        local overlay = Instance.new("TextButton")
        overlay.Size              = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundTransparency = 1
        overlay.Text              = ""
        overlay.ZIndex            = 16
        overlay.ClipsDescendants  = true
        overlay.Parent            = base
        Util.Corner(overlay, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -50, 1, 0)
        lbl.Position          = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Button"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        local arrow = Instance.new("TextLabel")
        arrow.Size            = UDim2.new(0, 24, 1, 0)
        arrow.AnchorPoint     = Vector2.new(1, 0)
        arrow.Position        = UDim2.new(1, -12, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text            = "›"
        arrow.TextColor3      = T.TextMuted
        arrow.TextSize        = 20
        arrow.Font            = Enum.Font.GothamBold
        arrow.ZIndex          = 14
        arrow.Parent          = base

        -- Hover
        j:Add(overlay.MouseEnter:Connect(function()
            Util.Tween(base,  { BackgroundTransparency = 0.05,
                                BackgroundColor3 = T.SurfaceAlt }, 0.18)
            Util.Tween(arrow, { TextColor3 = T.Accent },             0.18)
        end), "Disconnect")
        j:Add(overlay.MouseLeave:Connect(function()
            Util.Tween(base,  { BackgroundTransparency = 0.25,
                                BackgroundColor3 = T.Surface },   0.18)
            Util.Tween(arrow, { TextColor3 = T.TextMuted },          0.18)
        end), "Disconnect")

        -- Ripple (tracked by janitor j)
        Util.Ripple(overlay, j)

        -- Click flash + callback
        j:Add(overlay.MouseButton1Click:Connect(function()
            Util.Tween(base, { BackgroundColor3 = T.Accent }, 0.08)
            task.delay(0.09, function()
                Util.Tween(base, { BackgroundColor3 = T.Surface,
                                   BackgroundTransparency = 0.25 }, 0.22)
            end)
            if cfg.Callback then task.spawn(cfg.Callback) end
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")
        return base
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 8b · Tab:AddToggle({ Name, Default, Callback })
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function tab:AddToggle(cfg)
        cfg = cfg or {}
        local j       = Janitor.new()
        local state   = cfg.Default == true
        local base    = makeBase(cfg.Name or "Toggle", 48)

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -68, 1, 0)
        lbl.Position          = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Toggle"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        -- Track
        local track = Instance.new("Frame")
        track.Size            = UDim2.new(0, 44, 0, 24)
        track.AnchorPoint     = Vector2.new(1, 0.5)
        track.Position        = UDim2.new(1, -14, 0.5, 0)
        track.BackgroundColor3 = state and T.Accent or T.SurfaceAlt
        track.ZIndex          = 14
        track.Parent          = base
        Util.Corner(track, 12)
        local trackStroke = Util.Stroke(track, state and T.Accent or T.Border, 1,
                                               state and 0.4 or 0.5)

        -- Knob
        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 18, 0, 18)
        knob.AnchorPoint      = Vector2.new(0, 0.5)
        knob.Position         = state and UDim2.new(0, 23, 0.5, 0)
                                       or UDim2.new(0, 3,  0.5, 0)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.ZIndex           = 16
        knob.Parent           = track
        Util.Corner(knob, 999)

        -- Clickable area
        local click = Instance.new("TextButton")
        click.Size            = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text            = ""
        click.ZIndex          = 17
        click.Parent          = base

        local function applyState(newState, skipCb)
            state = newState
            if state then
                Util.Tween(track, { BackgroundColor3 = T.Accent },              0.25)
                Util.Tween(knob,  { Position = UDim2.new(0, 23, 0.5, 0) },      0.25)
                Util.Tween(trackStroke, { Color = T.Accent, Transparency = 0.4 }, 0.25)
            else
                Util.Tween(track, { BackgroundColor3 = T.SurfaceAlt },          0.25)
                Util.Tween(knob,  { Position = UDim2.new(0, 3,  0.5, 0) },      0.25)
                Util.Tween(trackStroke, { Color = T.Border, Transparency = 0.5 }, 0.25)
            end
            if not skipCb and cfg.Callback then
                task.spawn(cfg.Callback, state)
            end
        end

        j:Add(click.MouseButton1Click:Connect(function()
            applyState(not state)
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")

        -- Public API
        local api = {}
        function api:Set(v)  applyState(v == true, false) end
        function api:Get()   return state                  end
        return api
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 8c · Tab:AddSlider({ Name, Min, Max, Default, Callback })
    --
    --   Drag input is handled ONLY via UserInputService.InputChanged
    --   (no RunService loop). The dragging flag is set on MouseButton1Down
    --   and cleared on InputEnded — fully cleaned up by janitor.
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function tab:AddSlider(cfg)
        cfg = cfg or {}
        local j     = Janitor.new()
        local mn    = cfg.Min     or 0
        local mx    = cfg.Max     or 100
        local val   = math.clamp(cfg.Default or mn, mn, mx)
        local drag  = false
        local base  = makeBase(cfg.Name or "Slider", 62)

        -- Label row
        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -65, 0, 24)
        lbl.Position          = UDim2.new(0, 16, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Slider"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        local valLbl = Instance.new("TextLabel")
        valLbl.Size           = UDim2.new(0, 52, 0, 24)
        valLbl.AnchorPoint    = Vector2.new(1, 0)
        valLbl.Position       = UDim2.new(1, -14, 0, 8)
        valLbl.BackgroundTransparency = 1
        valLbl.Text           = tostring(val)
        valLbl.TextColor3     = T.AccentLight
        valLbl.TextSize       = 13
        valLbl.Font           = Enum.Font.GothamBold
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.ZIndex         = 14
        valLbl.Parent         = base

        -- Track
        local trackBg = Instance.new("Frame")
        trackBg.Size          = UDim2.new(1, -28, 0, 6)
        trackBg.Position      = UDim2.new(0, 14, 0, 43)
        trackBg.BackgroundColor3 = T.SurfaceAlt
        trackBg.BackgroundTransparency = 0.25
        trackBg.ZIndex        = 14
        trackBg.Parent        = base
        Util.Corner(trackBg, 4)

        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new((val - mn) / (mx - mn), 0, 1, 0)
        fill.BackgroundColor3 = T.Accent
        fill.ZIndex           = 15
        fill.Parent           = trackBg
        Util.Corner(fill, 4)
        Util.Gradient(fill, T.AccentDark, T.AccentLight, 0)

        -- Thumb
        local thumb = Instance.new("Frame")
        thumb.Size            = UDim2.new(0, 16, 0, 16)
        thumb.AnchorPoint     = Vector2.new(0.5, 0.5)
        thumb.Position        = UDim2.new((val - mn) / (mx - mn), 0, 0.5, 0)
        thumb.BackgroundColor3 = Color3.new(1, 1, 1)
        thumb.ZIndex          = 17
        thumb.Parent          = trackBg
        Util.Corner(thumb, 999)
        Util.Stroke(thumb, T.Accent, 2, 0.15)

        -- Invisible hit area over entire base
        local hit = Instance.new("TextButton")
        hit.Size              = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text              = ""
        hit.ZIndex            = 18
        hit.Parent            = base

        local function applyVal(screenX)
            local ap   = trackBg.AbsolutePosition.X
            local as   = trackBg.AbsoluteSize.X
            local alpha = math.clamp((screenX - ap) / as, 0, 1)
            local newV  = math.floor(mn + alpha * (mx - mn) + 0.5)
            if newV ~= val then
                val = newV
                valLbl.Text = tostring(val)
                Util.TweenLinear(fill,  { Size = UDim2.new(alpha, 0, 1, 0) },             0.08)
                Util.TweenLinear(thumb, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.08)
                if cfg.Callback then task.spawn(cfg.Callback, val) end
            end
        end

        j:Add(hit.MouseButton1Down:Connect(function()
            drag = true
            Util.Tween(thumb, { Size = UDim2.new(0, 20, 0, 20) }, 0.14)
        end), "Disconnect")

        -- InputEnded on UserInputService so release works even outside frame
        j:Add(UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and drag then
                drag = false
                Util.Tween(thumb, { Size = UDim2.new(0, 16, 0, 16) }, 0.14)
            end
        end), "Disconnect")

        -- InputChanged: only fires from one connection, no RunService needed
        j:Add(UserInputService.InputChanged:Connect(function(inp)
            if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                applyVal(inp.Position.X)
            end
        end), "Disconnect")

        -- Click-to-set (no drag)
        j:Add(hit.MouseButton1Click:Connect(function()
            applyVal(Mouse.X)
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")

        local api = {}
        function api:Set(v)
            val = math.clamp(v, mn, mx)
            local a = (val - mn) / (mx - mn)
            valLbl.Text = tostring(val)
            Util.Tween(fill,  { Size = UDim2.new(a, 0, 1, 0) },             0.2)
            Util.Tween(thumb, { Position = UDim2.new(a, 0, 0.5, 0) }, 0.2)
        end
        function api:Get() return val end
        return api
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 8d · Tab:AddDropdown({ Name, Options, Default, Callback })
    --
    --   CRITICAL ZIndex trick:
    --     The dropdown list is parented directly to _screenGui (NOT to
    --     the component frame). This means it is NEVER clipped by
    --     ClipsDescendants on the content area or main window.
    --     ZIndex 600 ensures it renders above all other UI elements.
    --     Position is computed from AbsolutePosition in screen space.
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function tab:AddDropdown(cfg)
        cfg = cfg or {}
        local j        = Janitor.new()
        local opts     = cfg.Options or {}
        local selected = cfg.Default or (opts[1] or "Select...")
        local open     = false
        local base     = makeBase(cfg.Name or "Dropdown", 48)

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(0.46, 0, 1, 0)
        lbl.Position          = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Dropdown"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        -- Value box
        local box = Instance.new("Frame")
        box.Size              = UDim2.new(0, 148, 0, 30)
        box.AnchorPoint       = Vector2.new(1, 0.5)
        box.Position          = UDim2.new(1, -12, 0.5, 0)
        box.BackgroundColor3  = T.SurfaceAlt
        box.BackgroundTransparency = 0.15
        box.ZIndex            = 14
        box.Parent            = base
        Util.Corner(box, 5)
        Util.Stroke(box, T.Border, 1, 0.42)

        local selLbl = Instance.new("TextLabel")
        selLbl.Size           = UDim2.new(1, -26, 1, 0)
        selLbl.Position       = UDim2.new(0, 9, 0, 0)
        selLbl.BackgroundTransparency = 1
        selLbl.Text           = tostring(selected)
        selLbl.TextColor3     = T.TextSec
        selLbl.TextSize       = 12
        selLbl.Font           = Enum.Font.Gotham
        selLbl.TextXAlignment = Enum.TextXAlignment.Left
        selLbl.TextTruncate   = Enum.TextTruncate.AtEnd
        selLbl.ZIndex         = 15
        selLbl.Parent         = box

        local chevron = Instance.new("TextLabel")
        chevron.Size          = UDim2.new(0, 18, 1, 0)
        chevron.AnchorPoint   = Vector2.new(1, 0)
        chevron.Position      = UDim2.new(1, -3, 0, 0)
        chevron.BackgroundTransparency = 1
        chevron.Text          = "▾"
        chevron.TextColor3    = T.TextMuted
        chevron.TextSize      = 11
        chevron.Font          = Enum.Font.GothamBold
        chevron.ZIndex        = 15
        chevron.Parent        = box

        local hitBtn = Instance.new("TextButton")
        hitBtn.Size           = UDim2.new(1, 0, 1, 0)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text           = ""
        hitBtn.ZIndex         = 16
        hitBtn.Parent         = base

        -- ── Dropdown list (HIGH ZIndex, parented to screenGui) ──
        local ITEM_H  = 30
        local MAX_VIS = 5
        local listH   = math.min(#opts, MAX_VIS) * ITEM_H + 10

        local dropFrame = Instance.new("Frame")
        dropFrame.Name          = "Drop_" .. (cfg.Name or "DD")
        dropFrame.Size          = UDim2.new(0, 148, 0, 0)   -- collapsed
        dropFrame.BackgroundColor3 = T.BgAlt
        dropFrame.BackgroundTransparency = 0
        dropFrame.ZIndex        = 600          -- always above everything
        dropFrame.Visible       = false
        dropFrame.ClipsDescendants = true
        dropFrame.Parent        = self._screenGui  -- ← parented to screenGui!
        Util.Corner(dropFrame, 6)
        Util.Stroke(dropFrame, T.Accent, 1, 0.38)
        Util.Shadow(dropFrame, 12)
        j:Add(dropFrame, "Destroy", "DropFrame")

        local dropScroll = Instance.new("ScrollingFrame")
        dropScroll.Size         = UDim2.new(1, 0, 1, 0)
        dropScroll.BackgroundTransparency = 1
        dropScroll.ScrollBarThickness = (#opts > MAX_VIS) and 3 or 0
        dropScroll.ScrollBarImageColor3 = T.Accent
        dropScroll.CanvasSize   = UDim2.new(0, 0, 0, #opts * ITEM_H + 10)
        dropScroll.ZIndex       = 601
        dropScroll.Parent       = dropFrame

        local dLayout = Instance.new("UIListLayout")
        dLayout.FillDirection   = Enum.FillDirection.Vertical
        dLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        dLayout.Padding         = UDim.new(0, 2)
        dLayout.Parent          = dropScroll
        Util.Pad(dropScroll, 4, 4, 4, 4)

        -- Populate items
        local itemBtns = {}
        for _, opt in ipairs(opts) do
            local isSel = opt == selected
            local ib = Instance.new("TextButton")
            ib.Size             = UDim2.new(1, 0, 0, ITEM_H - 4)
            ib.BackgroundColor3 = T.Surface
            ib.BackgroundTransparency = isSel and 0.1 or 1
            ib.Text             = ""
            ib.ZIndex           = 602
            ib.Parent           = dropScroll
            Util.Corner(ib, 4)
            itemBtns[opt] = ib

            local il = Instance.new("TextLabel")
            il.Size             = UDim2.new(1, -10, 1, 0)
            il.Position         = UDim2.new(0, 8, 0, 0)
            il.BackgroundTransparency = 1
            il.Text             = tostring(opt)
            il.TextColor3       = isSel and T.AccentLight or T.TextSec
            il.TextSize         = 12
            il.Font             = isSel and Enum.Font.GothamBold or Enum.Font.Gotham
            il.TextXAlignment   = Enum.TextXAlignment.Left
            il.ZIndex           = 603
            il.Parent           = ib

            j:Add(ib.MouseEnter:Connect(function()
                if opt ~= selected then
                    Util.Tween(ib, { BackgroundTransparency = 0.55 }, 0.14)
                    Util.Tween(il, { TextColor3 = T.TextPri },         0.14)
                end
            end), "Disconnect")
            j:Add(ib.MouseLeave:Connect(function()
                if opt ~= selected then
                    Util.Tween(ib, { BackgroundTransparency = 1 },     0.14)
                    Util.Tween(il, { TextColor3 = T.TextSec },         0.14)
                end
            end), "Disconnect")

            j:Add(ib.MouseButton1Click:Connect(function()
                -- Update previous selected
                if itemBtns[selected] then
                    local prevIb = itemBtns[selected]
                    local prevIl = prevIb:FindFirstChildOfClass("TextLabel")
                    Util.Tween(prevIb, { BackgroundTransparency = 1 }, 0.14)
                    if prevIl then
                        Util.Tween(prevIl, { TextColor3 = T.TextSec }, 0.14)
                        prevIl.Font = Enum.Font.Gotham
                    end
                end
                selected = opt
                selLbl.Text = tostring(opt)
                Util.Tween(ib, { BackgroundTransparency = 0.1 }, 0.14)
                Util.Tween(il, { TextColor3 = T.AccentLight },    0.14)
                il.Font = Enum.Font.GothamBold

                if cfg.Callback then task.spawn(cfg.Callback, opt) end

                -- Close list
                open = false
                Util.Tween(dropFrame,  { Size = UDim2.new(0, 148, 0, 0) },       0.22, Enum.EasingStyle.Quint)
                Util.Tween(chevron,    { Rotation = 0, TextColor3 = T.TextMuted }, 0.22)
                task.delay(0.23, function() dropFrame.Visible = false end)
            end), "Disconnect")
        end

        -- Position list relative to box in screen space
        local function positionList()
            local ap = box.AbsolutePosition
            local as = box.AbsoluteSize
            dropFrame.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
            dropFrame.Size     = UDim2.new(0, as.X, 0, 0)
        end

        j:Add(hitBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                positionList()
                dropFrame.Visible = true
                Util.Tween(dropFrame,  { Size = UDim2.new(0, 148, 0, listH) },          0.24, Enum.EasingStyle.Quint)
                Util.Tween(chevron,    { Rotation = 180, TextColor3 = T.Accent },        0.22)
            else
                Util.Tween(dropFrame,  { Size = UDim2.new(0, 148, 0, 0) },              0.22, Enum.EasingStyle.Quint)
                Util.Tween(chevron,    { Rotation = 0,   TextColor3 = T.TextMuted },     0.22)
                task.delay(0.23, function() dropFrame.Visible = false end)
            end
        end), "Disconnect")

        -- Click-away to close
        j:Add(UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not open then return end
            local p   = inp.Position
            local dp  = dropFrame.AbsolutePosition
            local ds  = dropFrame.AbsoluteSize
            local bp  = base.AbsolutePosition
            local bs  = base.AbsoluteSize
            local inD = p.X >= dp.X and p.X <= dp.X + ds.X and p.Y >= dp.Y and p.Y <= dp.Y + ds.Y
            local inB = p.X >= bp.X and p.X <= bp.X + bs.X and p.Y >= bp.Y and p.Y <= bp.Y + bs.Y
            if not inD and not inB then
                open = false
                Util.Tween(dropFrame, { Size = UDim2.new(0, 148, 0, 0) },           0.22, Enum.EasingStyle.Quint)
                Util.Tween(chevron,   { Rotation = 0, TextColor3 = T.TextMuted },    0.22)
                task.delay(0.23, function() dropFrame.Visible = false end)
            end
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")

        local api = {}
        function api:Set(v)  selected = v; selLbl.Text = tostring(v) end
        function api:Get()   return selected                           end
        return api
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 8e · Tab:AddKeybind({ Name, Default, Callback })
    --
    --   Two modes:
    --   1. Listening mode  – click badge, then press any key to bind.
    --      Escape clears the bind.
    --   2. Active mode     – pressing the bound key fires Callback.
    --   Both connections are fully tracked by janitor.
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function tab:AddKeybind(cfg)
        cfg = cfg or {}
        local j         = Janitor.new()
        local curKey    = cfg.Default or Enum.KeyCode.Unknown
        local listening = false
        local base      = makeBase(cfg.Name or "Keybind", 48)

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -120, 1, 0)
        lbl.Position          = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Keybind"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        local badge = Instance.new("Frame")
        badge.Size            = UDim2.new(0, 95, 0, 28)
        badge.AnchorPoint     = Vector2.new(1, 0.5)
        badge.Position        = UDim2.new(1, -12, 0.5, 0)
        badge.BackgroundColor3 = T.SurfaceAlt
        badge.BackgroundTransparency = 0.1
        badge.ZIndex          = 14
        badge.Parent          = base
        Util.Corner(badge, 5)
        local badgeStroke = Util.Stroke(badge, T.Border, 1, 0.42)

        local keyLbl = Instance.new("TextLabel")
        keyLbl.Size           = UDim2.new(1, 0, 1, 0)
        keyLbl.BackgroundTransparency = 1
        keyLbl.Text           = curKey == Enum.KeyCode.Unknown and "None"
                                                                or curKey.Name
        keyLbl.TextColor3     = T.AccentLight
        keyLbl.TextSize       = 12
        keyLbl.Font           = Enum.Font.GothamBold
        keyLbl.ZIndex         = 15
        keyLbl.Parent         = badge

        local hit = Instance.new("TextButton")
        hit.Size              = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text              = ""
        hit.ZIndex            = 16
        hit.Parent            = base

        local function setListening(v)
            listening = v
            if v then
                keyLbl.Text     = "Press key..."
                keyLbl.TextColor3 = T.Warning
                Util.Tween(badge,       { BackgroundColor3 = Color3.fromRGB(45, 35, 8) }, 0.18)
                Util.Tween(badgeStroke, { Color = T.Warning },                             0.18)
            else
                keyLbl.Text     = curKey == Enum.KeyCode.Unknown and "None" or curKey.Name
                keyLbl.TextColor3 = T.AccentLight
                Util.Tween(badge,       { BackgroundColor3 = T.SurfaceAlt }, 0.18)
                Util.Tween(badgeStroke, { Color = T.Border },                 0.18)
            end
        end

        j:Add(hit.MouseButton1Click:Connect(function()
            setListening(not listening)
        end), "Disconnect")

        j:Add(UserInputService.InputBegan:Connect(function(inp, gpe)
            if listening then
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if inp.KeyCode == Enum.KeyCode.Escape then
                    curKey = Enum.KeyCode.Unknown
                else
                    curKey = inp.KeyCode
                end
                setListening(false)
                if cfg.Callback then task.spawn(cfg.Callback, curKey) end
            elseif not gpe
                and inp.UserInputType == Enum.UserInputType.Keyboard
                and inp.KeyCode == curKey
                and curKey ~= Enum.KeyCode.Unknown then
                -- Fire callback when hotkey is pressed during play
                if cfg.Callback then task.spawn(cfg.Callback, curKey) end
            end
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")

        local api = {}
        function api:Set(k) curKey = k; setListening(false) end
        function api:Get() return curKey end
        return api
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 8f · Tab:AddSection(title)  — visual divider + heading
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function tab:AddSection(title)
        local sec = Instance.new("Frame")
        sec.Name              = "Section_" .. title
        sec.Size              = UDim2.new(1, 0, 0, 26)
        sec.BackgroundTransparency = 1
        sec.ZIndex            = 13
        sec.Parent            = scroll

        local secLbl = Instance.new("TextLabel")
        secLbl.Size           = UDim2.new(1, -10, 0, 18)
        secLbl.Position       = UDim2.new(0, 6, 0, 4)
        secLbl.BackgroundTransparency = 1
        secLbl.Text           = string.upper(title)
        secLbl.TextColor3     = T.Accent
        secLbl.TextSize       = 10
        secLbl.Font           = Enum.Font.GothamBold
        secLbl.TextXAlignment = Enum.TextXAlignment.Left
        secLbl.LetterSpacing  = 1.5
        secLbl.ZIndex         = 14
        secLbl.Parent         = sec

        local line = Instance.new("Frame")
        line.Size             = UDim2.new(1, -6, 0, 1)
        line.Position         = UDim2.new(0, 3, 1, -3)
        line.BackgroundColor3 = T.Border
        line.BackgroundTransparency = 0.45
        line.ZIndex           = 14
        line.Parent           = sec

        return sec
    end

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 8g · Tab:AddLabel(text) — informational text row
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function tab:AddLabel(text)
        local base = makeBase("Label_" .. (text or ""), 38)
        base.BackgroundTransparency = 0.55

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -20, 1, 0)
        lbl.Position          = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = text or ""
        lbl.TextColor3        = T.TextSec
        lbl.TextSize          = 12
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.TextWrapped       = true
        lbl.ZIndex            = 14
        lbl.Parent            = base

        local api = {}
        function api:Set(t) lbl.Text = t end
        function api:Get()  return lbl.Text end
        return api
    end

    return tab
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 9 · SEARCH BAR
--
--   Library:AddSearchBar()
--   Adds a live search field above the content area that filters
--   component frames by name.
--
--   DEBOUNCE: Filtering only triggers 0.15 s after the LAST
--   keystroke, preventing frame drops during fast typing.
--   The debounce uses task.cancel() on the pending thread — no
--   polling loop, zero idle overhead.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:AddSearchBar()
    assert(self._win, "Call Library:Boot() before AddSearchBar()")
    local win = self._win
    local pending = nil     -- debounce thread handle

    local container = Instance.new("Frame")
    container.Name              = "SearchBar"
    container.Size              = UDim2.new(1, -24, 0, 32)
    container.AnchorPoint       = Vector2.new(0.5, 0)
    container.Position          = UDim2.new(0.5, 0, 0, 8)
    container.BackgroundColor3  = T.SurfaceAlt
    container.BackgroundTransparency = 0.2
    container.ZIndex            = 20
    container.Parent            = win.ContentArea
    Util.Corner(container, 6)
    Util.Stroke(container, T.Border, 1, 0.45)

    local icon = Instance.new("TextLabel")
    icon.Size             = UDim2.new(0, 28, 1, 0)
    icon.Position         = UDim2.new(0, 4, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text             = "🔍"
    icon.TextSize         = 13
    icon.ZIndex           = 21
    icon.Parent           = container

    local box = Instance.new("TextBox")
    box.Size              = UDim2.new(1, -38, 1, -2)
    box.Position          = UDim2.new(0, 30, 0, 1)
    box.BackgroundTransparency = 1
    box.PlaceholderText   = "Search components..."
    box.PlaceholderColor3 = T.TextMuted
    box.Text              = ""
    box.TextColor3        = T.TextPri
    box.TextSize          = 12
    box.Font              = Enum.Font.Gotham
    box.TextXAlignment    = Enum.TextXAlignment.Left
    box.ClearTextOnFocus  = false
    box.ZIndex            = 21
    box.Parent            = container

    -- ── Debounced filter logic ────────────────────────────────
    -- One GetPropertyChangedSignal connection; cancels any pending
    -- filter task before scheduling a new one 0.15 s out.
    self._janitor:Add(
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if pending then task.cancel(pending) end
            pending = task.delay(0.15, function()
                local q = box.Text:lower()
                if self._activeTab then
                    for _, child in ipairs(self._activeTab._scroll:GetChildren()) do
                        if child:IsA("Frame") then
                            local tl = child:FindFirstChildOfClass("TextLabel")
                            local match = q == "" or (tl and tl.Text:lower():find(q, 1, true))
                            Util.Tween(child,
                                { BackgroundTransparency = match and 0.25 or 0.82 }, 0.18)
                        end
                    end
                end
            end)
        end),
    "Disconnect")

    return box
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 10 · NOTIFICATION SYSTEM
--
--   Library:Notify({ Title, Content, Duration, IconId })
--
--   • Notifications stack at the bottom-right of the screen.
--   • Each one slides in from the right via TweenService (no loop).
--   • A drain bar counts down the duration visually.
--   • Clicking ✕ dismisses early; all resources cleaned by janitor.
--   • IconId: optional rbxassetid:// for a 32×32 icon on the left.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:Notify(cfg)
    assert(self._win, "Call Library:Boot() before Notify()")
    cfg = cfg or {}
    local dur  = math.max(cfg.Duration or 4, 1)
    local j    = Janitor.new()
    self._notifCount += 1

    local anchor = self._win.NotifAnchor

    -- ── Notification frame ─────────────────────────────────────
    local notif = Instance.new("Frame")
    notif.Name                = "Notif_" .. self._notifCount
    notif.Size                = UDim2.new(1, 0, 0, 76)
    notif.BackgroundColor3    = T.BgAlt
    notif.BackgroundTransparency = 0.04
    notif.ZIndex              = 850
    notif.LayoutOrder         = self._notifCount
    -- Start off the right edge; slides in
    notif.Position            = UDim2.new(1, 340, 0, 0)
    notif.Parent              = anchor
    Util.Corner(notif, 8)
    Util.Stroke(notif, T.Accent, 1, 0.42)
    Util.Shadow(notif, 10)
    j:Add(notif, "Destroy", "Frame")

    Util.Gradient(notif, Color3.fromRGB(22, 18, 38), T.BgAlt, 165)

    -- Left accent pill
    local sideBar = Instance.new("Frame")
    sideBar.Size              = UDim2.new(0, 3, 0.62, 0)
    sideBar.AnchorPoint       = Vector2.new(0, 0.5)
    sideBar.Position          = UDim2.new(0, 0, 0.5, 0)
    sideBar.BackgroundColor3  = T.Accent
    sideBar.ZIndex            = 851
    sideBar.Parent            = notif
    Util.Corner(sideBar, 3)

    -- Optional icon
    local textX = 14
    if cfg.IconId then
        local ic = Instance.new("ImageLabel")
        ic.Size               = UDim2.new(0, 30, 0, 30)
        ic.AnchorPoint        = Vector2.new(0, 0.5)
        ic.Position           = UDim2.new(0, 14, 0.5, -4)
        ic.BackgroundTransparency = 1
        ic.Image              = cfg.IconId
        ic.ScaleType          = Enum.ScaleType.Fit
        ic.ZIndex             = 851
        ic.Parent             = notif
        textX = 52
    end

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size             = UDim2.new(1, -(textX + 30), 0, 22)
    titleLbl.Position         = UDim2.new(0, textX, 0, 11)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text             = cfg.Title or "Notification"
    titleLbl.TextColor3       = T.TextPri
    titleLbl.TextSize         = 14
    titleLbl.Font             = Enum.Font.GothamBold
    titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
    titleLbl.ZIndex           = 851
    titleLbl.Parent           = notif

    -- Content
    local contLbl = Instance.new("TextLabel")
    contLbl.Size              = UDim2.new(1, -(textX + 14), 0, 26)
    contLbl.Position          = UDim2.new(0, textX, 0, 34)
    contLbl.BackgroundTransparency = 1
    contLbl.Text              = cfg.Content or ""
    contLbl.TextColor3        = T.TextSec
    contLbl.TextSize          = 12
    contLbl.Font              = Enum.Font.Gotham
    contLbl.TextXAlignment    = Enum.TextXAlignment.Left
    contLbl.TextWrapped       = true
    contLbl.ZIndex            = 851
    contLbl.Parent            = notif

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 18, 0, 18)
    closeBtn.AnchorPoint      = Vector2.new(1, 0)
    closeBtn.Position         = UDim2.new(1, -8, 0, 7)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text             = "✕"
    closeBtn.TextColor3       = T.TextMuted
    closeBtn.TextSize         = 11
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.ZIndex           = 852
    closeBtn.Parent           = notif

    -- Duration drain bar
    local drainBg = Instance.new("Frame")
    drainBg.Size              = UDim2.new(1, 0, 0, 2)
    drainBg.AnchorPoint       = Vector2.new(0, 1)
    drainBg.Position          = UDim2.new(0, 0, 1, 0)
    drainBg.BackgroundColor3  = T.Surface
    drainBg.BackgroundTransparency = 0.5
    drainBg.ZIndex            = 852
    drainBg.Parent            = notif
    Util.Corner(drainBg, 2)

    local drainFill = Instance.new("Frame")
    drainFill.Size            = UDim2.new(1, 0, 1, 0)
    drainFill.BackgroundColor3 = T.Accent
    drainFill.ZIndex          = 853
    drainFill.Parent          = drainBg
    Util.Corner(drainFill, 2)
    Util.Gradient(drainFill, T.AccentDark, T.AccentLight, 0)

    -- ── Animations ────────────────────────────────────────────
    -- Slide in
    task.defer(function()
        Util.Tween(notif, { Position = UDim2.new(0, 0, 0, 0) }, 0.4, Enum.EasingStyle.Quint)
    end)

    -- Drain bar
    Util.TweenLinear(drainFill, { Size = UDim2.new(0, 0, 1, 0) }, dur)

    local function dismiss()
        Util.Tween(notif, {
            Position = UDim2.new(1, 340, 0, 0),
            BackgroundTransparency = 1,
        }, 0.32, Enum.EasingStyle.Quint)
        task.delay(0.35, function() j:Cleanup() end)
    end

    local autoThread = task.delay(dur, dismiss)
    j:Add(function() task.cancel(autoThread) end, "fn")   -- cancel if dismissed early

    j:Add(closeBtn.MouseButton1Click:Connect(function()
        task.cancel(autoThread)
        dismiss()
    end), "Disconnect")

    return notif
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 11 · DESTROY
--
--   Library:Destroy()
--   Calls janitor:Cleanup() which atomically:
--     • Disconnects every InputBegan / MouseButton1Click / etc.
--     • Destroys the ScreenGui (and all children)
--     • Cancels any pending task.delay threads
--   Zero memory leaks guaranteed by design.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:Destroy()
    self._janitor:Cleanup()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ██████████████████████████████████████████████████████████████
--          P A R T   2  —  E X T E N D E D   A P I
-- ██████████████████████████████████████████████████████████████
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─────────────────────────────────────────────────────────────
-- The following six features are injected into the existing
-- Library / Tab objects declared in Part 1:
--
--   Tab:AddTextInput   – single-line & multi-line validated input
--   Tab:AddColorPicker – HSV wheel + hex preview with live preview
--   Tab:AddMultiDropdown – multi-select checklist dropdown
--   Tab:AddProgressBar   – read-only animated progress display
--   Library:SetTheme     – runtime theme swapper (Violet/Cyan/Rose/Mono)
--   Library:SaveConfig / Library:LoadConfig  – JSON config persistence
--   Library:Watermark    – draggable floating HUD label
-- ─────────────────────────────────────────────────────────────

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 13 · TAB EXTENSION INJECTION
--
--   Because CreateTab() closes over `tab` and injects methods
--   directly onto it, the cleanest approach for Part 2 is to
--   wrap CreateTab in a decorator so every new Tab also receives
--   the extended components automatically.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local _originalCreateTab = Library.CreateTab

function Library:CreateTab(name, iconId)
    -- Build the base tab via the original Part-1 implementation
    local tab = _originalCreateTab(self, name, iconId)

    -- ──────────────────────────────────────────────────────────
    -- Shared makeBase (mirrors the private one inside CreateTab)
    -- ──────────────────────────────────────────────────────────
    local function makeBase2(compName, h)
        local f = Instance.new("Frame")
        f.Name                   = compName
        f.Size                   = UDim2.new(1, 0, 0, h or 48)
        f.BackgroundColor3       = T.Surface
        f.BackgroundTransparency = 0.25
        f.ZIndex                 = 13
        f.Parent                 = tab._scroll
        Util.Corner(f, 6)
        Util.Stroke(f, T.Border, 1, 0.58)
        return f
    end

    -- ══════════════════════════════════════════════════════════
    -- 13a · Tab:AddTextInput({ Name, Default, Placeholder,
    --                          MultiLine, MaxLength, Callback,
    --                          Validator })
    --
    --  MultiLine = true  → 80 px tall TextBox (3 lines)
    --  Validator = function(text) → bool, errMsg
    --    If validator returns false the border turns red and the
    --    error message is shown; Callback is NOT fired.
    --  Callback fires on FocusLost (Enter or click-away).
    -- ══════════════════════════════════════════════════════════

    function tab:AddTextInput(cfg)
        cfg = cfg or {}
        local j       = Janitor.new()
        local ml      = cfg.MultiLine == true
        local maxLen  = cfg.MaxLength or 200
        local h       = ml and 88 or 68
        local base    = makeBase2(cfg.Name or "TextInput", h)

        -- Label
        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -14, 0, 22)
        lbl.Position          = UDim2.new(0, 14, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Input"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        -- Input box frame (inner card)
        local boxFrame = Instance.new("Frame")
        boxFrame.Size             = UDim2.new(1, -28, 0, ml and 54 or 30)
        boxFrame.Position         = UDim2.new(0, 14, 0, 31)
        boxFrame.BackgroundColor3 = T.SurfaceAlt
        boxFrame.BackgroundTransparency = 0.08
        boxFrame.ZIndex           = 14
        boxFrame.ClipsDescendants = true
        boxFrame.Parent           = base
        Util.Corner(boxFrame, 5)
        local boxStroke = Util.Stroke(boxFrame, T.Border, 1, 0.4)

        -- Char counter badge
        local charCount = Instance.new("TextLabel")
        charCount.Size            = UDim2.new(0, 46, 0, 16)
        charCount.AnchorPoint     = Vector2.new(1, 0)
        charCount.Position        = UDim2.new(1, -6, 0, ml and -20 or -18)
        charCount.BackgroundTransparency = 1
        charCount.Text            = "0/" .. maxLen
        charCount.TextColor3      = T.TextMuted
        charCount.TextSize        = 10
        charCount.Font            = Enum.Font.Gotham
        charCount.TextXAlignment  = Enum.TextXAlignment.Right
        charCount.ZIndex          = 15
        charCount.Parent          = base

        -- Error label
        local errLbl = Instance.new("TextLabel")
        errLbl.Size               = UDim2.new(1, -14, 0, 14)
        errLbl.Position           = UDim2.new(0, 14, 1, -16)
        errLbl.BackgroundTransparency = 1
        errLbl.Text               = ""
        errLbl.TextColor3         = T.Error
        errLbl.TextSize           = 10
        errLbl.Font               = Enum.Font.Gotham
        errLbl.TextXAlignment     = Enum.TextXAlignment.Left
        errLbl.ZIndex             = 15
        errLbl.Parent             = base

        local textBox = Instance.new("TextBox")
        textBox.Size              = UDim2.new(1, -10, 1, 0)
        textBox.Position          = UDim2.new(0, 8, 0, 0)
        textBox.BackgroundTransparency = 1
        textBox.PlaceholderText   = cfg.Placeholder or ("Enter " .. (cfg.Name or "value") .. "…")
        textBox.PlaceholderColor3 = T.TextMuted
        textBox.Text              = cfg.Default or ""
        textBox.TextColor3        = T.TextPri
        textBox.TextSize          = 12
        textBox.Font              = Enum.Font.Gotham
        textBox.TextXAlignment    = Enum.TextXAlignment.Left
        textBox.TextYAlignment    = ml and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        textBox.MultiLine         = ml
        textBox.TextWrapped       = ml
        textBox.ClearTextOnFocus  = false
        textBox.ZIndex            = 15
        textBox.Parent            = boxFrame
        Util.Pad(textBox, ml and 5 or 0, ml and 5 or 0, 2, 2)

        -- Focus glow
        j:Add(textBox.Focused:Connect(function()
            Util.Tween(boxStroke, { Color = T.Accent, Transparency = 0.2 }, 0.2)
            Util.Tween(boxFrame,  { BackgroundTransparency = 0.02 },         0.2)
        end), "Disconnect")

        j:Add(textBox.FocusLost:Connect(function(enterPressed)
            local txt = textBox.Text

            -- Enforce max length (silent truncation)
            if #txt > maxLen then
                txt = txt:sub(1, maxLen)
                textBox.Text = txt
            end

            -- Validate
            local ok, msg = true, ""
            if cfg.Validator then
                ok, msg = cfg.Validator(txt)
            end

            if not ok then
                errLbl.Text = msg or "Invalid input"
                Util.Tween(boxStroke, { Color = T.Error, Transparency = 0.1 }, 0.18)
                Util.Tween(base, { BackgroundColor3 = Color3.fromRGB(40, 15, 15) }, 0.18)
                task.delay(2.5, function()
                    errLbl.Text = ""
                    Util.Tween(boxStroke, { Color = T.Border, Transparency = 0.4 }, 0.25)
                    Util.Tween(base, { BackgroundColor3 = T.Surface }, 0.25)
                end)
            else
                errLbl.Text = ""
                Util.Tween(boxStroke, { Color = T.Border, Transparency = 0.4 }, 0.22)
                Util.Tween(boxFrame,  { BackgroundTransparency = 0.08 },          0.22)
                if cfg.Callback then task.spawn(cfg.Callback, txt, enterPressed) end
            end
        end), "Disconnect")

        -- Live char counter
        j:Add(textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local n = #textBox.Text
            charCount.Text  = n .. "/" .. maxLen
            charCount.TextColor3 = (n >= maxLen) and T.Warning or T.TextMuted
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")

        local api = {}
        function api:Set(v)   textBox.Text = tostring(v)  end
        function api:Get()    return textBox.Text          end
        function api:Focus()  textBox:CaptureFocus()       end
        return api
    end

    -- ══════════════════════════════════════════════════════════
    -- 13b · Tab:AddColorPicker({ Name, Default, Callback })
    --
    --   Default: Color3 value (or uses Accent by default).
    --
    --   The panel contains three elements:
    --     1. Saturation/Value 2-D square (click/drag)
    --     2. Hue vertical strip (click/drag)
    --     3. Live Hex #RRGGBB display + copy button
    --
    --   Both 2-D and 1-D drags use UserInputService.InputChanged
    --   (not RenderStepped) and are fully disconnected by the
    --   Janitor when the tab or library is destroyed.
    -- ══════════════════════════════════════════════════════════

    function tab:AddColorPicker(cfg)
        cfg = cfg or {}
        local j        = Janitor.new()
        local initC    = cfg.Default or T.Accent
        local h_, s_, v_ = Color3.toHSV(initC)

        -- Helper: Color3 → 6-char hex
        local function toHex(c)
            return string.format("%02X%02X%02X",
                math.floor(c.R * 255 + 0.5),
                math.floor(c.G * 255 + 0.5),
                math.floor(c.B * 255 + 0.5))
        end

        local PANEL_H  = 210   -- collapsed state: 48, expanded: 210
        local base     = makeBase2(cfg.Name or "ColorPicker", 48)
        base.ClipsDescendants = true

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(0.5, 0, 0, 48)
        lbl.Position          = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Color Picker"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        -- Swatch preview + chevron
        local swatch = Instance.new("Frame")
        swatch.Size           = UDim2.new(0, 28, 0, 22)
        swatch.AnchorPoint    = Vector2.new(1, 0.5)
        swatch.Position       = UDim2.new(1, -42, 0, 13)
        swatch.BackgroundColor3 = initC
        swatch.ZIndex         = 14
        swatch.Parent         = base
        Util.Corner(swatch, 5)
        Util.Stroke(swatch, T.Border, 1, 0.25)

        local chevron = Instance.new("TextLabel")
        chevron.Size          = UDim2.new(0, 18, 0, 48)
        chevron.AnchorPoint   = Vector2.new(1, 0)
        chevron.Position      = UDim2.new(1, -12, 0, 0)
        chevron.BackgroundTransparency = 1
        chevron.Text          = "▾"
        chevron.TextColor3    = T.TextMuted
        chevron.TextSize      = 13
        chevron.Font          = Enum.Font.GothamBold
        chevron.ZIndex        = 14
        chevron.Parent        = base

        -- ── SV Square ─────────────────────────────────────────
        local SV_SIZE = 150   -- px

        local svFrame = Instance.new("Frame")
        svFrame.Size          = UDim2.new(0, SV_SIZE, 0, SV_SIZE)
        svFrame.Position      = UDim2.new(0, 14, 0, 54)
        svFrame.BackgroundColor3 = Color3.fromHSV(h_, 1, 1)
        svFrame.ZIndex        = 15
        svFrame.Parent        = base
        Util.Corner(svFrame, 5)
        Util.Stroke(svFrame, T.Border, 1, 0.4)

        -- White→transparent overlay (saturation axis)
        local svWhite = Instance.new("ImageLabel")
        svWhite.Size          = UDim2.new(1, 0, 1, 0)
        svWhite.BackgroundTransparency = 1
        svWhite.Image         = "rbxassetid://0"
        svWhite.ZIndex        = 16
        svWhite.Parent        = svFrame
        Util.Gradient(svWhite, Color3.new(1,1,1), Color3.new(1,1,1,0), 0)
        -- Transparent→black overlay (value axis)
        local svBlack = Instance.new("ImageLabel")
        svBlack.Size          = UDim2.new(1, 0, 1, 0)
        svBlack.BackgroundTransparency = 1
        svBlack.Image         = "rbxassetid://0"
        svBlack.ZIndex        = 17
        svBlack.Parent        = svFrame
        Util.Gradient(svBlack, Color3.new(0,0,0,0), Color3.new(0,0,0), 90)

        -- SV cursor
        local svCursor = Instance.new("Frame")
        svCursor.Size         = UDim2.new(0, 10, 0, 10)
        svCursor.AnchorPoint  = Vector2.new(0.5, 0.5)
        svCursor.Position     = UDim2.new(s_, 0, 1 - v_, 0)
        svCursor.BackgroundColor3 = Color3.new(1,1,1)
        svCursor.ZIndex       = 19
        svCursor.Parent       = svFrame
        Util.Corner(svCursor, 999)
        Util.Stroke(svCursor, Color3.new(0,0,0), 1.5, 0.05)

        -- Hit button over SV square
        local svHit = Instance.new("TextButton")
        svHit.Size            = UDim2.new(1, 0, 1, 0)
        svHit.BackgroundTransparency = 1
        svHit.Text            = ""
        svHit.ZIndex          = 20
        svHit.Parent          = svFrame

        -- ── Hue Strip ─────────────────────────────────────────
        local HUE_W = 18
        local hueStrip = Instance.new("ImageLabel")
        hueStrip.Size         = UDim2.new(0, HUE_W, 0, SV_SIZE)
        hueStrip.Position     = UDim2.new(0, SV_SIZE + 24, 0, 54)
        hueStrip.BackgroundTransparency = 1
        -- Built-in Roblox rainbow spectrum (always available)
        hueStrip.Image        = "rbxassetid://6020299385"
        hueStrip.ZIndex       = 15
        hueStrip.Parent       = base
        Util.Corner(hueStrip, 4)
        Util.Stroke(hueStrip, T.Border, 1, 0.4)

        local hueCursor = Instance.new("Frame")
        hueCursor.Size        = UDim2.new(1, 4, 0, 4)
        hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        hueCursor.Position    = UDim2.new(0.5, 0, h_, 0)
        hueCursor.BackgroundColor3 = Color3.new(1,1,1)
        hueCursor.ZIndex      = 17
        hueCursor.Parent      = hueStrip
        Util.Corner(hueCursor, 2)
        Util.Stroke(hueCursor, Color3.new(0,0,0), 1.2, 0.05)

        local hueHit = Instance.new("TextButton")
        hueHit.Size           = UDim2.new(1, 0, 1, 0)
        hueHit.BackgroundTransparency = 1
        hueHit.Text           = ""
        hueHit.ZIndex         = 18
        hueHit.Parent         = hueStrip

        -- ── Hex Row ───────────────────────────────────────────
        local hexRowY  = 54 + SV_SIZE + 10

        local hexFrame = Instance.new("Frame")
        hexFrame.Size         = UDim2.new(0, SV_SIZE + HUE_W + 10, 0, 28)
        hexFrame.Position     = UDim2.new(0, 14, 0, hexRowY)
        hexFrame.BackgroundColor3 = T.SurfaceAlt
        hexFrame.BackgroundTransparency = 0.1
        hexFrame.ZIndex       = 15
        hexFrame.Parent       = base
        Util.Corner(hexFrame, 5)
        Util.Stroke(hexFrame, T.Border, 1, 0.42)

        local hashLbl = Instance.new("TextLabel")
        hashLbl.Size          = UDim2.new(0, 14, 1, 0)
        hashLbl.Position      = UDim2.new(0, 6, 0, 0)
        hashLbl.BackgroundTransparency = 1
        hashLbl.Text          = "#"
        hashLbl.TextColor3    = T.TextMuted
        hashLbl.TextSize      = 12
        hashLbl.Font          = Enum.Font.GothamBold
        hashLbl.ZIndex        = 16
        hashLbl.Parent        = hexFrame

        local hexBox = Instance.new("TextBox")
        hexBox.Size           = UDim2.new(1, -48, 1, -2)
        hexBox.Position       = UDim2.new(0, 20, 0, 1)
        hexBox.BackgroundTransparency = 1
        hexBox.Text           = toHex(initC)
        hexBox.TextColor3     = T.AccentLight
        hexBox.TextSize       = 12
        hexBox.Font           = Enum.Font.GothamBold
        hexBox.TextXAlignment = Enum.TextXAlignment.Left
        hexBox.ClearTextOnFocus = false
        hexBox.ZIndex         = 16
        hexBox.Parent         = hexFrame

        -- ── Central update function ────────────────────────────
        local function updateColor(fireCallback)
            local c = Color3.fromHSV(h_, s_, v_)
            swatch.BackgroundColor3 = c
            svFrame.BackgroundColor3 = Color3.fromHSV(h_, 1, 1)
            svCursor.Position = UDim2.new(s_, 0, 1 - v_, 0)
            hueCursor.Position = UDim2.new(0.5, 0, h_, 0)
            hexBox.Text = toHex(c)
            if fireCallback and cfg.Callback then
                task.spawn(cfg.Callback, c)
            end
        end
        updateColor(false)

        -- ── SV drag ───────────────────────────────────────────
        local svDrag = false
        j:Add(svHit.MouseButton1Down:Connect(function()
            svDrag = true
        end), "Disconnect")
        j:Add(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                svDrag = false
            end
        end), "Disconnect")
        j:Add(UserInputService.InputChanged:Connect(function(i)
            if svDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local ap = svFrame.AbsolutePosition
                local as = svFrame.AbsoluteSize
                s_ = math.clamp((i.Position.X - ap.X) / as.X, 0, 1)
                v_ = 1 - math.clamp((i.Position.Y - ap.Y) / as.Y, 0, 1)
                updateColor(true)
            end
        end), "Disconnect")

        -- ── Hue drag ──────────────────────────────────────────
        local hueDrag = false
        j:Add(hueHit.MouseButton1Down:Connect(function()
            hueDrag = true
        end), "Disconnect")
        -- Re-use the same InputEnded/InputChanged connections
        -- (they check separate drag flags, both safe)
        j:Add(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDrag = false
            end
        end), "Disconnect")
        j:Add(UserInputService.InputChanged:Connect(function(i)
            if hueDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local ap = hueStrip.AbsolutePosition
                local as = hueStrip.AbsoluteSize
                h_ = math.clamp((i.Position.Y - ap.Y) / as.Y, 0, 1)
                updateColor(true)
            end
        end), "Disconnect")

        -- ── Hex input ─────────────────────────────────────────
        j:Add(hexBox.FocusLost:Connect(function()
            local raw = hexBox.Text:gsub("#", ""):upper()
            if #raw == 6 then
                local r = tonumber(raw:sub(1,2), 16)
                local g = tonumber(raw:sub(3,4), 16)
                local b = tonumber(raw:sub(5,6), 16)
                if r and g and b then
                    local c = Color3.fromRGB(r, g, b)
                    h_, s_, v_ = Color3.toHSV(c)
                    updateColor(true)
                    return
                end
            end
            -- Restore on bad input
            hexBox.Text = toHex(Color3.fromHSV(h_, s_, v_))
        end), "Disconnect")

        -- ── Expand / Collapse ─────────────────────────────────
        local expanded  = false
        local hitToggle = Instance.new("TextButton")
        hitToggle.Size              = UDim2.new(1, 0, 0, 48)
        hitToggle.BackgroundTransparency = 1
        hitToggle.Text              = ""
        hitToggle.ZIndex            = 21
        hitToggle.Parent            = base

        j:Add(hitToggle.MouseButton1Click:Connect(function()
            expanded = not expanded
            local targetH = expanded and (PANEL_H + hexRowY + 8) or 48
            Util.Tween(base,    { Size = UDim2.new(1, 0, 0, targetH) }, 0.3, Enum.EasingStyle.Quint)
            Util.Tween(chevron, { Rotation = expanded and 180 or 0 },     0.3)
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")

        local api = {}
        function api:Set(c)
            h_, s_, v_ = Color3.toHSV(c)
            updateColor(false)
        end
        function api:Get()
            return Color3.fromHSV(h_, s_, v_)
        end
        return api
    end

    -- ══════════════════════════════════════════════════════════
    -- 13c · Tab:AddMultiDropdown({ Name, Options, Defaults, Callback })
    --
    --   A checklist-style dropdown. Each option shows a checkbox.
    --   Callback receives a table of currently selected options.
    --   Like AddDropdown, the list panel is parented to screenGui
    --   at ZIndex 601 to avoid clipping issues.
    -- ══════════════════════════════════════════════════════════

    function tab:AddMultiDropdown(cfg)
        cfg     = cfg or {}
        local j = Janitor.new()
        local opts      = cfg.Options  or {}
        local selected  = {}
        -- Seed from defaults
        if cfg.Defaults then
            for _, v in ipairs(cfg.Defaults) do selected[v] = true end
        end

        local open = false
        local base = makeBase2(cfg.Name or "MultiSelect", 48)

        local function countSel()
            local n = 0
            for _ in pairs(selected) do n += 1 end
            return n
        end

        local function summaryText()
            local n = countSel()
            if n == 0 then return "None selected"
            elseif n == 1 then
                for k in pairs(selected) do return k end
            else return n .. " selected" end
        end

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(0.46, 0, 1, 0)
        lbl.Position          = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "MultiSelect"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        -- Value box
        local box = Instance.new("Frame")
        box.Size              = UDim2.new(0, 148, 0, 30)
        box.AnchorPoint       = Vector2.new(1, 0.5)
        box.Position          = UDim2.new(1, -12, 0.5, 0)
        box.BackgroundColor3  = T.SurfaceAlt
        box.BackgroundTransparency = 0.15
        box.ZIndex            = 14
        box.Parent            = base
        Util.Corner(box, 5)
        Util.Stroke(box, T.Border, 1, 0.42)

        local selLbl = Instance.new("TextLabel")
        selLbl.Size           = UDim2.new(1, -26, 1, 0)
        selLbl.Position       = UDim2.new(0, 9, 0, 0)
        selLbl.BackgroundTransparency = 1
        selLbl.Text           = summaryText()
        selLbl.TextColor3     = T.TextSec
        selLbl.TextSize       = 11
        selLbl.Font           = Enum.Font.Gotham
        selLbl.TextXAlignment = Enum.TextXAlignment.Left
        selLbl.TextTruncate   = Enum.TextTruncate.AtEnd
        selLbl.ZIndex         = 15
        selLbl.Parent         = box

        local chevron = Instance.new("TextLabel")
        chevron.Size          = UDim2.new(0, 18, 1, 0)
        chevron.AnchorPoint   = Vector2.new(1, 0)
        chevron.Position      = UDim2.new(1, -3, 0, 0)
        chevron.BackgroundTransparency = 1
        chevron.Text          = "▾"
        chevron.TextColor3    = T.TextMuted
        chevron.TextSize      = 11
        chevron.Font          = Enum.Font.GothamBold
        chevron.ZIndex        = 15
        chevron.Parent        = box

        local hitBtn = Instance.new("TextButton")
        hitBtn.Size           = UDim2.new(1, 0, 1, 0)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text           = ""
        hitBtn.ZIndex         = 16
        hitBtn.Parent         = base

        -- ── List panel ────────────────────────────────────────
        local ITEM_H  = 30
        local MAX_VIS = 5
        local listH   = math.min(#opts, MAX_VIS) * ITEM_H + 10

        local dropFrame = Instance.new("Frame")
        dropFrame.Name          = "MultiDrop_" .. (cfg.Name or "MD")
        dropFrame.Size          = UDim2.new(0, 148, 0, 0)
        dropFrame.BackgroundColor3 = T.BgAlt
        dropFrame.BackgroundTransparency = 0
        dropFrame.ZIndex        = 601
        dropFrame.Visible       = false
        dropFrame.ClipsDescendants = true
        dropFrame.Parent        = self._screenGui   -- ← screenGui parent
        Util.Corner(dropFrame, 6)
        Util.Stroke(dropFrame, T.Accent, 1, 0.38)
        Util.Shadow(dropFrame, 12)
        j:Add(dropFrame, "Destroy", "DropFrame")

        local dropScroll = Instance.new("ScrollingFrame")
        dropScroll.Size         = UDim2.new(1, 0, 1, 0)
        dropScroll.BackgroundTransparency = 1
        dropScroll.ScrollBarThickness = (#opts > MAX_VIS) and 3 or 0
        dropScroll.ScrollBarImageColor3 = T.Accent
        dropScroll.CanvasSize   = UDim2.new(0, 0, 0, #opts * ITEM_H + 10)
        dropScroll.ZIndex       = 602
        dropScroll.Parent       = dropFrame
        local dLayout2 = Instance.new("UIListLayout")
        dLayout2.Padding        = UDim.new(0, 2)
        dLayout2.Parent         = dropScroll
        Util.Pad(dropScroll, 4, 4, 4, 4)

        -- Populate checkboxes
        for _, opt in ipairs(opts) do
            local isSel = selected[opt] == true
            local row = Instance.new("TextButton")
            row.Size            = UDim2.new(1, 0, 0, ITEM_H - 4)
            row.BackgroundColor3 = isSel and T.Surface or Color3.new(0,0,0)
            row.BackgroundTransparency = isSel and 0.1 or 1
            row.Text            = ""
            row.ZIndex          = 603
            row.Parent          = dropScroll
            Util.Corner(row, 4)

            -- Checkbox square
            local cb = Instance.new("Frame")
            cb.Size             = UDim2.new(0, 14, 0, 14)
            cb.AnchorPoint      = Vector2.new(0, 0.5)
            cb.Position         = UDim2.new(0, 6, 0.5, 0)
            cb.BackgroundColor3 = isSel and T.Accent or T.SurfaceAlt
            cb.BackgroundTransparency = isSel and 0 or 0.1
            cb.ZIndex           = 604
            cb.Parent           = row
            Util.Corner(cb, 3)
            Util.Stroke(cb, isSel and T.Accent or T.Border, 1, isSel and 0.3 or 0.45)

            local check = Instance.new("TextLabel")
            check.Size          = UDim2.new(1, 0, 1, 0)
            check.BackgroundTransparency = 1
            check.Text          = isSel and "✓" or ""
            check.TextColor3    = Color3.new(1,1,1)
            check.TextSize      = 10
            check.Font          = Enum.Font.GothamBold
            check.ZIndex        = 605
            check.Parent        = cb

            local rl = Instance.new("TextLabel")
            rl.Size             = UDim2.new(1, -28, 1, 0)
            rl.Position         = UDim2.new(0, 26, 0, 0)
            rl.BackgroundTransparency = 1
            rl.Text             = tostring(opt)
            rl.TextColor3       = isSel and T.TextPri or T.TextSec
            rl.TextSize         = 12
            rl.Font             = isSel and Enum.Font.GothamBold or Enum.Font.Gotham
            rl.TextXAlignment   = Enum.TextXAlignment.Left
            rl.ZIndex           = 604
            rl.Parent           = row

            j:Add(row.MouseButton1Click:Connect(function()
                selected[opt] = not selected[opt]
                local s = selected[opt]
                Util.Tween(cb, {
                    BackgroundColor3 = s and T.Accent or T.SurfaceAlt,
                    BackgroundTransparency = s and 0 or 0.1,
                }, 0.15)
                check.Text   = s and "✓" or ""
                rl.Font      = s and Enum.Font.GothamBold or Enum.Font.Gotham
                Util.Tween(rl, { TextColor3 = s and T.TextPri or T.TextSec }, 0.15)
                selLbl.Text  = summaryText()
                -- Build result list and fire callback
                if cfg.Callback then
                    local res = {}
                    for k, v in pairs(selected) do if v then res[#res+1] = k end end
                    task.spawn(cfg.Callback, res)
                end
            end), "Disconnect")
        end

        local function positionList()
            local ap = box.AbsolutePosition
            local as = box.AbsoluteSize
            dropFrame.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
            dropFrame.Size     = UDim2.new(0, as.X, 0, 0)
        end

        j:Add(hitBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                positionList()
                dropFrame.Visible = true
                Util.Tween(dropFrame, { Size = UDim2.new(0, 148, 0, listH) }, 0.24, Enum.EasingStyle.Quint)
                Util.Tween(chevron,   { Rotation = 180, TextColor3 = T.Accent }, 0.22)
            else
                Util.Tween(dropFrame, { Size = UDim2.new(0, 148, 0, 0) }, 0.22, Enum.EasingStyle.Quint)
                Util.Tween(chevron,   { Rotation = 0,   TextColor3 = T.TextMuted }, 0.22)
                task.delay(0.24, function() dropFrame.Visible = false end)
            end
        end), "Disconnect")

        -- Click-away dismissal
        j:Add(UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not open then return end
            local p  = inp.Position
            local dp = dropFrame.AbsolutePosition; local ds = dropFrame.AbsoluteSize
            local bp = base.AbsolutePosition;     local bs = base.AbsoluteSize
            local inD = p.X>=dp.X and p.X<=dp.X+ds.X and p.Y>=dp.Y and p.Y<=dp.Y+ds.Y
            local inB = p.X>=bp.X and p.X<=bp.X+bs.X and p.Y>=bp.Y and p.Y<=bp.Y+bs.Y
            if not inD and not inB then
                open = false
                Util.Tween(dropFrame, { Size = UDim2.new(0, 148, 0, 0) }, 0.22, Enum.EasingStyle.Quint)
                Util.Tween(chevron,   { Rotation = 0, TextColor3 = T.TextMuted }, 0.22)
                task.delay(0.24, function() dropFrame.Visible = false end)
            end
        end), "Disconnect")

        self._janitor:Add(function() j:Cleanup() end, "fn")

        local api = {}
        function api:Set(tbl)
            table.clear(selected)
            for _, v in ipairs(tbl) do selected[v] = true end
            selLbl.Text = summaryText()
        end
        function api:Get()
            local res = {}
            for k, v in pairs(selected) do if v then res[#res+1] = k end end
            return res
        end
        return api
    end

    -- ══════════════════════════════════════════════════════════
    -- 13d · Tab:AddProgressBar({ Name, Value, Max, Color,
    --                            ShowPercent, Label })
    --
    --   A read-only animated progress bar.
    --   api:Set(v)  → smoothly animates to the new value.
    --   api:SetLabel(t) → updates the sub-label text at runtime.
    -- ══════════════════════════════════════════════════════════

    function tab:AddProgressBar(cfg)
        cfg = cfg or {}
        local maxV  = cfg.Max   or 100
        local curV  = math.clamp(cfg.Value or 0, 0, maxV)
        local barC  = cfg.Color or T.Accent
        local base  = makeBase2(cfg.Name or "Progress", 62)

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(0.72, 0, 0, 22)
        lbl.Position          = UDim2.new(0, 16, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text              = cfg.Name or "Progress"
        lbl.TextColor3        = T.TextPri
        lbl.TextSize          = 13
        lbl.Font              = Enum.Font.Gotham
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.ZIndex            = 14
        lbl.Parent            = base

        -- Percent badge
        local pctLbl = Instance.new("TextLabel")
        pctLbl.Size           = UDim2.new(0, 52, 0, 22)
        pctLbl.AnchorPoint    = Vector2.new(1, 0)
        pctLbl.Position       = UDim2.new(1, -14, 0, 8)
        pctLbl.BackgroundTransparency = 1
        pctLbl.Text           = string.format("%.0f%%", (curV / maxV) * 100)
        pctLbl.TextColor3     = T.AccentLight
        pctLbl.TextSize       = 13
        pctLbl.Font           = Enum.Font.GothamBold
        pctLbl.TextXAlignment = Enum.TextXAlignment.Right
        pctLbl.ZIndex         = 14
        pctLbl.Parent         = base

        -- Sub label
        local subLbl = Instance.new("TextLabel")
        subLbl.Size           = UDim2.new(1, -14, 0, 14)
        subLbl.Position       = UDim2.new(0, 14, 1, -17)
        subLbl.BackgroundTransparency = 1
        subLbl.Text           = cfg.Label or ""
        subLbl.TextColor3     = T.TextMuted
        subLbl.TextSize       = 10
        subLbl.Font           = Enum.Font.Gotham
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.ZIndex         = 14
        subLbl.Parent         = base

        -- Track
        local track = Instance.new("Frame")
        track.Size            = UDim2.new(1, -28, 0, 7)
        track.Position        = UDim2.new(0, 14, 0, 38)
        track.BackgroundColor3 = T.SurfaceAlt
        track.BackgroundTransparency = 0.2
        track.ZIndex          = 14
        track.Parent          = base
        Util.Corner(track, 5)

        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new(curV / maxV, 0, 1, 0)
        fill.BackgroundColor3 = barC
        fill.ZIndex           = 15
        fill.Parent           = track
        Util.Corner(fill, 5)
        Util.Gradient(fill, barC:Lerp(Color3.new(0,0,0), 0.25), barC:Lerp(Color3.new(1,1,1), 0.18), 0)

        -- Animated shimmer highlight
        local shimmer = Instance.new("Frame")
        shimmer.Size          = UDim2.new(0.3, 0, 1, 0)
        shimmer.Position      = UDim2.new(-0.3, 0, 0, 0)
        shimmer.BackgroundColor3 = Color3.new(1,1,1)
        shimmer.BackgroundTransparency = 0.72
        shimmer.ZIndex        = 16
        shimmer.ClipsDescendants = false
        shimmer.Parent        = fill
        Util.Corner(shimmer, 5)

        -- Shimmer animation loop (uses TweenService, NOT RenderStepped)
        local function runShimmer()
            shimmer.Position = UDim2.new(-0.3, 0, 0, 0)
            Util.TweenLinear(shimmer, { Position = UDim2.new(1.1, 0, 0, 0) }, 1.6)
            task.delay(2.4, runShimmer)
        end
        task.spawn(runShimmer)

        local api = {}
        function api:Set(v)
            curV = math.clamp(v, 0, maxV)
            local alpha = curV / maxV
            pctLbl.Text = string.format("%.0f%%", alpha * 100)
            Util.Tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.38, Enum.EasingStyle.Quint)
        end
        function api:SetLabel(t) subLbl.Text = t end
        function api:Get()       return curV        end
        return api
    end

    return tab
end   -- end Library:CreateTab override

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 14 · THEME SYSTEM
--
--   Library:SetTheme(presetName)
--
--   Preset names:  "Violet"  (default)
--                  "Cyan"
--                  "Rose"
--                  "Mono"    (white-on-dark, no color accent)
--
--   Switching the theme:
--     1. Mutates the shared T table (all Util helpers read T directly)
--     2. Iterates every live Instance inside the ScreenGui and
--        re-tints anything whose original color matches the OLD
--        accent values — so all buttons, pills, strokes, fills
--        update without being re-created.
--
--   You can also pass a custom Color3 instead of a name:
--     Library:SetTheme(Color3.fromRGB(255, 80, 0))
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ThemePresets = {
    Violet = {
        Accent      = Color3.fromRGB(138,  43, 226),
        AccentLight = Color3.fromRGB(175, 100, 255),
        AccentDark  = Color3.fromRGB(100,  20, 175),
    },
    Cyan = {
        Accent      = Color3.fromRGB( 0,  210, 255),
        AccentLight = Color3.fromRGB(80,  235, 255),
        AccentDark  = Color3.fromRGB( 0,  145, 200),
    },
    Rose = {
        Accent      = Color3.fromRGB(220,  50, 120),
        AccentLight = Color3.fromRGB(255, 100, 160),
        AccentDark  = Color3.fromRGB(165,  20,  80),
    },
    Emerald = {
        Accent      = Color3.fromRGB( 16, 200, 120),
        AccentLight = Color3.fromRGB( 60, 240, 155),
        AccentDark  = Color3.fromRGB(  8, 140,  80),
    },
    Mono = {
        Accent      = Color3.fromRGB(200, 200, 200),
        AccentLight = Color3.fromRGB(240, 240, 240),
        AccentDark  = Color3.fromRGB(140, 140, 140),
    },
}

function Library:SetTheme(preset)
    assert(self._screenGui, "Call Library:Boot() before SetTheme()")

    -- Resolve new accent colors
    local newA, newAL, newAD
    if typeof(preset) == "Color3" then
        newA  = preset
        newAL = preset:Lerp(Color3.new(1,1,1), 0.28)
        newAD = preset:Lerp(Color3.new(0,0,0), 0.28)
    else
        local p = ThemePresets[preset] or ThemePresets.Violet
        newA, newAL, newAD = p.Accent, p.AccentLight, p.AccentDark
    end

    local oldA, oldAL, oldAD = T.Accent, T.AccentLight, T.AccentDark

    -- Helper: is this color "close" to a reference? (tolerance 18/255)
    local function close(c, ref)
        local tol = 18 / 255
        return math.abs(c.R - ref.R) < tol
           and math.abs(c.G - ref.G) < tol
           and math.abs(c.B - ref.B) < tol
    end

    -- Recursively re-tint all descendants
    local function recolor(inst)
        -- Frame / TextLabel / ImageLabel  → BackgroundColor3 / ImageColor3
        if inst:IsA("GuiObject") then
            if close(inst.BackgroundColor3, oldA)  then
                Util.Tween(inst, { BackgroundColor3 = newA  }, 0.35, Enum.EasingStyle.Sine)
            elseif close(inst.BackgroundColor3, oldAL) then
                Util.Tween(inst, { BackgroundColor3 = newAL }, 0.35, Enum.EasingStyle.Sine)
            elseif close(inst.BackgroundColor3, oldAD) then
                Util.Tween(inst, { BackgroundColor3 = newAD }, 0.35, Enum.EasingStyle.Sine)
            end
        end
        if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
            if close(inst.ImageColor3, oldA)  then
                Util.Tween(inst, { ImageColor3 = newA  }, 0.35, Enum.EasingStyle.Sine)
            elseif close(inst.ImageColor3, oldAL) then
                Util.Tween(inst, { ImageColor3 = newAL }, 0.35, Enum.EasingStyle.Sine)
            end
        end
        if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
            if close(inst.TextColor3, oldA)  then
                Util.Tween(inst, { TextColor3 = newA  }, 0.35, Enum.EasingStyle.Sine)
            elseif close(inst.TextColor3, oldAL) then
                Util.Tween(inst, { TextColor3 = newAL }, 0.35, Enum.EasingStyle.Sine)
            end
        end
        if inst:IsA("UIStroke") then
            if close(inst.Color, oldA) then
                Util.Tween(inst, { Color = newA }, 0.35, Enum.EasingStyle.Sine)
            end
        end
        if inst:IsA("ScrollingFrame") then
            if close(inst.ScrollBarImageColor3, oldA) then
                inst.ScrollBarImageColor3 = newA
            end
        end
        for _, child in ipairs(inst:GetChildren()) do
            recolor(child)
        end
    end

    -- Mutate the global theme table FIRST so new instances use it
    T.Accent      = newA
    T.AccentLight = newAL
    T.AccentDark  = newAD

    recolor(self._screenGui)

    self:Notify({
        Title   = "Theme Changed",
        Content = "Accent updated successfully.",
        Duration = 2.5,
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 15 · CONFIG SYSTEM
--
--   Library:SaveConfig(name)
--   Library:LoadConfig(name)
--   Library:ListConfigs()    → table of saved config names
--   Library:DeleteConfig(name)
--
--   Configs are serialized as JSON-like Luau tables and stored
--   inside a single folder under LocalPlayer.PlayerGui called
--   "NexusUI_Configs".  Each config is a StringValue child.
--
--   Components must call Library:_RegisterConfig(key, getter, setter)
--   to participate.  The helper macro below shows how AddToggle,
--   AddSlider, etc. can self-register automatically.
--
--   SaveConfig snapshot format (Luau table → JSON string):
--     { version = 1, values = { [key] = serialized_value, ... } }
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Library._configRegistry = {}   -- { [key] = { get = fn, set = fn } }

--- Register a component for config persistence.
--- key: stable string identifier (e.g. "Main.SpeedHack")
--- get: function() → string|number|boolean
--- set: function(value)
function Library:_RegisterConfig(key, get, set)
    self._configRegistry[key] = { get = get, set = set }
end

--- Tiny JSON encoder (numbers / booleans / strings / tables only).
--- Avoids requiring HttpService just to encode simple data.
local function encodeJSON(val)
    local t = type(val)
    if t == "number"  then return tostring(val)
    elseif t == "boolean" then return val and "true" or "false"
    elseif t == "string"  then
        -- Escape backslash, double-quote, newline
        local s = val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')
        return '"' .. s .. '"'
    elseif t == "table"   then
        -- Array or object?
        local isArr = #val > 0
        local parts = {}
        if isArr then
            for _, v in ipairs(val) do parts[#parts+1] = encodeJSON(v) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(val) do
                parts[#parts+1] = '"' .. tostring(k) .. '":' .. encodeJSON(v)
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

--- Minimal JSON decoder for the subset we encode above.
local function decodeJSON(s)
    s = s:match("^%s*(.-)%s*$")  -- trim
    if s == "true"  then return true  end
    if s == "false" then return false end
    local n = tonumber(s)
    if n   then return n end
    -- String
    local str = s:match('^"(.*)"$')
    if str then
        return (str:gsub('\\"', '"'):gsub('\\\\', '\\'):gsub('\\n', '\n'))
    end
    -- Array
    if s:sub(1,1) == "[" then
        local arr = {}
        local inner = s:sub(2, -2)
        -- Simple split on top-level commas (works for flat arrays)
        for item in (inner .. ","):gmatch("([^,]+),") do
            arr[#arr+1] = decodeJSON(item:match("^%s*(.-)%s*$"))
        end
        return arr
    end
    -- Object
    if s:sub(1,1) == "{" then
        local obj = {}
        local inner = s:sub(2, -2)
        for kv in (inner .. ","):gmatch('("[^"]+":.-),') do
            local k, v = kv:match('^"([^"]+)":(.+)$')
            if k and v then obj[k] = decodeJSON(v:match("^%s*(.-)%s*$")) end
        end
        return obj
    end
    return nil
end

--- Get (or create) the config folder in PlayerGui.
local function getConfigFolder()
    local pg     = LocalPlayer:WaitForChild("PlayerGui")
    local folder = pg:FindFirstChild("NexusUI_Configs")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name   = "NexusUI_Configs"
        folder.Parent = pg
    end
    return folder
end

function Library:SaveConfig(configName)
    configName = configName or "default"
    local values = {}
    for key, entry in pairs(self._configRegistry) do
        local ok, val = pcall(entry.get)
        if ok then values[key] = val end
    end
    local payload = encodeJSON({ version = 1, values = values })

    local folder = getConfigFolder()
    local sv = folder:FindFirstChild(configName)
    if not sv then
        sv = Instance.new("StringValue")
        sv.Name   = configName
        sv.Parent = folder
    end
    sv.Value = payload

    self:Notify({
        Title   = "Config Saved",
        Content = "\"" .. configName .. "\" written successfully.",
        Duration = 2.5,
    })
    return true
end

function Library:LoadConfig(configName)
    configName = configName or "default"
    local folder = getConfigFolder()
    local sv     = folder:FindFirstChild(configName)
    if not sv then
        self:Notify({
            Title   = "Config Not Found",
            Content = "No config named \"" .. configName .. "\".",
            Duration = 3,
        })
        return false
    end

    local ok, data = pcall(decodeJSON, sv.Value)
    if not ok or type(data) ~= "table" or not data.values then
        self:Notify({
            Title   = "Load Failed",
            Content = "Config file is corrupted.",
            Duration = 3,
        })
        return false
    end

    local loaded, failed = 0, 0
    for key, val in pairs(data.values) do
        local entry = self._configRegistry[key]
        if entry then
            local s, err = pcall(entry.set, val)
            if s then loaded += 1 else failed += 1 end
        end
    end

    self:Notify({
        Title   = "Config Loaded",
        Content = string.format("\"" .. configName .. "\" — %d OK, %d skipped.", loaded, failed),
        Duration = 3,
    })
    return true
end

function Library:ListConfigs()
    local folder = getConfigFolder()
    local names  = {}
    for _, sv in ipairs(folder:GetChildren()) do
        if sv:IsA("StringValue") then names[#names+1] = sv.Name end
    end
    return names
end

function Library:DeleteConfig(configName)
    local folder = getConfigFolder()
    local sv     = folder:FindFirstChild(configName)
    if sv then
        sv:Destroy()
        self:Notify({
            Title   = "Config Deleted",
            Content = "\"" .. configName .. "\" removed.",
            Duration = 2,
        })
        return true
    end
    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 16 · WATERMARK (Floating HUD label)
--
--   Library:Watermark({ Text, SubText, Position, Visible })
--
--   Returns an api:
--     api:SetText(main, sub)  – update labels at runtime
--     api:Toggle()            – fade show/hide
--     api:Destroy()           – remove and clean up
--
--   Draggable by default. FPS counter updates every 0.5 s using a
--   single task.delay chain (no RenderStepped, no while loop).
--   Passing ShowFPS = true enables the live counter.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:Watermark(cfg)
    assert(self._screenGui, "Call Library:Boot() before Watermark()")
    cfg = cfg or {}
    local j       = Janitor.new()
    local visible = cfg.Visible ~= false   -- default true

    -- ── Frame ─────────────────────────────────────────────────
    local wm = Instance.new("Frame")
    wm.Name               = "Watermark"
    wm.AnchorPoint        = Vector2.new(0.5, 0)
    wm.Size               = UDim2.new(0, 240, 0, 38)
    wm.Position           = cfg.Position or UDim2.new(0.5, 0, 0, 14)
    wm.BackgroundColor3   = T.BgAlt
    wm.BackgroundTransparency = 0.08
    wm.ZIndex             = 750
    wm.Parent             = self._screenGui
    Util.Corner(wm, 7)
    Util.Stroke(wm, T.Accent, 1, 0.38)
    Util.Shadow(wm, 12)
    Util.Gradient(wm, Color3.fromRGB(22, 15, 38), T.BgAlt, 160)
    j:Add(wm, "Destroy", "WmFrame")

    -- Left accent bar
    local bar = Instance.new("Frame")
    bar.Size              = UDim2.new(0, 3, 0.6, 0)
    bar.AnchorPoint       = Vector2.new(0, 0.5)
    bar.Position          = UDim2.new(0, 0, 0.5, 0)
    bar.BackgroundColor3  = T.Accent
    bar.ZIndex            = 751
    bar.Parent            = wm
    Util.Corner(bar, 3)

    -- Main text
    local mainTxt = Instance.new("TextLabel")
    mainTxt.Size              = UDim2.new(1, -68, 1, 0)
    mainTxt.Position          = UDim2.new(0, 12, 0, 0)
    mainTxt.BackgroundTransparency = 1
    mainTxt.Text              = cfg.Text or self._hubName
    mainTxt.TextColor3        = T.TextPri
    mainTxt.TextSize          = 13
    mainTxt.Font              = Enum.Font.GothamBold
    mainTxt.TextXAlignment    = Enum.TextXAlignment.Left
    mainTxt.ZIndex            = 751
    mainTxt.Parent            = wm

    -- Sub text (version / status)
    local subTxt = Instance.new("TextLabel")
    subTxt.Size               = UDim2.new(1, -12, 1, 0)
    subTxt.AnchorPoint        = Vector2.new(1, 0)
    subTxt.Position           = UDim2.new(1, -10, 0, 0)
    subTxt.BackgroundTransparency = 1
    subTxt.Text               = cfg.SubText or "v2.0"
    subTxt.TextColor3         = T.TextMuted
    subTxt.TextSize           = 11
    subTxt.Font               = Enum.Font.Gotham
    subTxt.TextXAlignment     = Enum.TextXAlignment.Right
    subTxt.ZIndex             = 751
    subTxt.Parent             = wm

    -- FPS counter (optional)
    local fpsLbl
    if cfg.ShowFPS then
        fpsLbl = Instance.new("TextLabel")
        fpsLbl.Size               = UDim2.new(0, 52, 1, 0)
        fpsLbl.AnchorPoint        = Vector2.new(1, 0)
        fpsLbl.Position           = UDim2.new(1, -10, 0, 0)
        fpsLbl.BackgroundTransparency = 1
        fpsLbl.Text               = "FPS: --"
        fpsLbl.TextColor3         = T.AccentLight
        fpsLbl.TextSize           = 10
        fpsLbl.Font               = Enum.Font.GothamBold
        fpsLbl.TextXAlignment     = Enum.TextXAlignment.Right
        fpsLbl.ZIndex             = 751
        fpsLbl.Parent             = wm

        -- FPS sampling: counts RenderStepped frames over 0.5 s window
        -- Uses a recurring task.delay chain — no persistent connection
        local frameCount   = 0
        local rsConn
        rsConn = RunService.RenderStepped:Connect(function()
            frameCount += 1
        end)
        j:Add(rsConn, "Disconnect", "FPSConn")

        local function sampleFPS()
            local fps = math.floor(frameCount * 2 + 0.5)   -- ×2 = per-second
            fpsLbl.Text = "FPS: " .. fps
            fpsLbl.TextColor3 = fps >= 55 and T.Success
                             or fps >= 30 and T.Warning
                             or T.Error
            frameCount = 0
            task.delay(0.5, sampleFPS)
        end
        task.delay(0.5, sampleFPS)
    end

    -- ── Drag ─────────────────────────────────────────────────
    local wmDrag, wmStart, wmPos = false, nil, nil
    j:Add(wm.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            wmDrag = true; wmStart = inp.Position; wmPos = wm.Position
        end
    end), "Disconnect")
    j:Add(wm.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            wmDrag = false
        end
    end), "Disconnect")
    j:Add(UserInputService.InputChanged:Connect(function(inp)
        if wmDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - wmStart
            wm.Position = UDim2.new(
                wmPos.X.Scale, wmPos.X.Offset + d.X,
                wmPos.Y.Scale, wmPos.Y.Offset + d.Y)
        end
    end), "Disconnect")

    -- ── API ───────────────────────────────────────────────────
    local api = {}

    function api:SetText(main, sub)
        if main then mainTxt.Text = main end
        if sub  then subTxt.Text  = sub  end
    end

    function api:Toggle()
        visible = not visible
        Util.Tween(wm, {
            BackgroundTransparency = visible and 0.08 or 1,
            Size = visible and UDim2.new(0, 240, 0, 38)
                           or UDim2.new(0, 100, 0, 38),
        }, 0.3, Enum.EasingStyle.Quint)
        for _, child in ipairs(wm:GetDescendants()) do
            if child:IsA("TextLabel") then
                Util.Tween(child, { TextTransparency = visible and 0 or 1 }, 0.25)
            end
        end
    end

    function api:SetVisible(v)
        if v ~= visible then api:Toggle() end
    end

    function api:Destroy()
        j:Cleanup()
    end

    self._janitor:Add(function() j:Cleanup() end, "fn")
    return api
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 17 · CONTEXT MENU
--
--   Library:ContextMenu({ Items })
--
--   Items = {
--     { Name = "Copy",   Icon = "rbxassetid://...", Action = fn },
--     { Name = "Delete", Icon = "rbxassetid://...", Action = fn, Danger = true },
--   }
--
--   Spawns a polished right-click style menu at the mouse position.
--   Closes on any click outside, or when an item is selected.
--   Returns a close() function for programmatic dismissal.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:ContextMenu(cfg)
    assert(self._screenGui, "Call Library:Boot() before ContextMenu()")
    cfg = cfg or {}
    local items = cfg.Items or {}
    local j     = Janitor.new()

    local ITEM_H = 32
    local menuW  = cfg.Width or 190
    local menuH  = #items * ITEM_H + 10

    -- Position at mouse cursor, nudging if too close to the screen edge
    local mx = Mouse.X
    local my = Mouse.Y
    local vpSize = workspace.CurrentCamera.ViewportSize
    local posX = math.min(mx + 4, vpSize.X - menuW  - 8)
    local posY = math.min(my + 4, vpSize.Y - menuH - 8)

    local menu = Instance.new("Frame")
    menu.Name               = "ContextMenu"
    menu.Size               = UDim2.new(0, menuW, 0, 0)   -- animates open
    menu.Position           = UDim2.new(0, posX, 0, posY)
    menu.BackgroundColor3   = T.BgAlt
    menu.BackgroundTransparency = 0
    menu.ZIndex             = 900
    menu.ClipsDescendants   = true
    menu.Parent             = self._screenGui
    Util.Corner(menu, 7)
    Util.Stroke(menu, T.Accent, 1, 0.35)
    Util.Shadow(menu, 14)
    j:Add(menu, "Destroy", "MenuFrame")

    -- Slide open
    task.defer(function()
        Util.Tween(menu, { Size = UDim2.new(0, menuW, 0, menuH) }, 0.22, Enum.EasingStyle.Quint)
    end)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection     = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding           = UDim.new(0, 2)
    layout.Parent            = menu
    Util.Pad(menu, 4, 4, 4, 4)

    local function close()
        Util.Tween(menu, {
            Size = UDim2.new(0, menuW, 0, 0),
            BackgroundTransparency = 1,
        }, 0.18, Enum.EasingStyle.Quint)
        task.delay(0.2, function() j:Cleanup() end)
    end

    for _, item in ipairs(items) do
        local row = Instance.new("TextButton")
        row.Size              = UDim2.new(1, 0, 0, ITEM_H - 4)
        row.BackgroundColor3  = item.Danger and Color3.fromRGB(50, 12, 12)
                                             or T.Surface
        row.BackgroundTransparency = 0.55
        row.Text              = ""
        row.ZIndex            = 901
        row.Parent            = menu
        Util.Corner(row, 5)

        if item.Icon then
            local ic = Instance.new("ImageLabel")
            ic.Size           = UDim2.new(0, 15, 0, 15)
            ic.AnchorPoint    = Vector2.new(0, 0.5)
            ic.Position       = UDim2.new(0, 8, 0.5, 0)
            ic.BackgroundTransparency = 1
            ic.Image          = item.Icon
            ic.ImageColor3    = item.Danger and T.Error or T.TextSec
            ic.ScaleType      = Enum.ScaleType.Fit
            ic.ZIndex         = 902
            ic.Parent         = row
        end

        local itemLbl = Instance.new("TextLabel")
        itemLbl.Size          = UDim2.new(1, -32, 1, 0)
        itemLbl.Position      = UDim2.new(0, item.Icon and 28 or 10, 0, 0)
        itemLbl.BackgroundTransparency = 1
        itemLbl.Text          = item.Name or "Option"
        itemLbl.TextColor3    = item.Danger and T.Error or T.TextSec
        itemLbl.TextSize      = 12
        itemLbl.Font          = Enum.Font.Gotham
        itemLbl.TextXAlignment = Enum.TextXAlignment.Left
        itemLbl.ZIndex        = 902
        itemLbl.Parent        = row

        j:Add(row.MouseEnter:Connect(function()
            Util.Tween(row,     { BackgroundTransparency = 0.12 }, 0.14)
            Util.Tween(itemLbl, { TextColor3 = item.Danger and T.Error or T.TextPri }, 0.14)
        end), "Disconnect")
        j:Add(row.MouseLeave:Connect(function()
            Util.Tween(row,     { BackgroundTransparency = 0.55 }, 0.14)
            Util.Tween(itemLbl, { TextColor3 = item.Danger and T.Error or T.TextSec }, 0.14)
        end), "Disconnect")
        j:Add(row.MouseButton1Click:Connect(function()
            close()
            if item.Action then task.spawn(item.Action) end
        end), "Disconnect")
    end

    -- Click-away to close
    j:Add(UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local p  = inp.Position
        local mp = menu.AbsolutePosition
        local ms = menu.AbsoluteSize
        if not (p.X>=mp.X and p.X<=mp.X+ms.X and p.Y>=mp.Y and p.Y<=mp.Y+ms.Y) then
            close()
        end
    end), "Disconnect")

    return close
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 18 · DIALOG (Modal Confirmation / Input)
--
--   Library:Dialog({ Title, Content, Buttons, Input })
--
--   Buttons = {
--     { Label = "Confirm", Style = "primary", Callback = fn },
--     { Label = "Cancel",  Style = "ghost",   Callback = fn },
--   }
--   Input = true → adds a TextBox to the dialog.
--                  The first Callback receives (inputText).
--   Returns: close() function.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Library:Dialog(cfg)
    assert(self._screenGui, "Call Library:Boot() before Dialog()")
    cfg = cfg or {}
    local j      = Janitor.new()
    local btns   = cfg.Buttons or {{ Label = "OK", Style = "primary" }}
    local hasIn  = cfg.Input == true
    local dlgH   = hasIn and 200 or 160

    -- Scrim (darkened backdrop)
    local scrim = Instance.new("Frame")
    scrim.Size              = UDim2.new(1, 0, 1, 0)
    scrim.BackgroundColor3  = Color3.new(0, 0, 0)
    scrim.BackgroundTransparency = 1
    scrim.ZIndex            = 960
    scrim.Parent            = self._screenGui
    j:Add(scrim, "Destroy", "Scrim")
    Util.Tween(scrim, { BackgroundTransparency = 0.55 }, 0.28)

    -- Dialog card
    local card = Instance.new("Frame")
    card.AnchorPoint        = Vector2.new(0.5, 0.5)
    card.Size               = UDim2.new(0, 0, 0, 0)     -- scales in
    card.Position           = UDim2.new(0.5, 0, 0.5, 0)
    card.BackgroundColor3   = T.BgAlt
    card.BackgroundTransparency = 0.04
    card.ZIndex             = 961
    card.Parent             = self._screenGui
    Util.Corner(card, 10)
    Util.Stroke(card, T.Accent, 1.5, 0.3)
    Util.Shadow(card, 24)
    j:Add(card, "Destroy", "Card")

    Util.Tween(card, { Size = UDim2.new(0, 360, 0, dlgH) }, 0.32, Enum.EasingStyle.Quint)
    Util.Gradient(card, Color3.fromRGB(20, 14, 36), T.BgAlt, 150)

    -- Top accent line
    local topLine = Instance.new("Frame")
    topLine.Size            = UDim2.new(1, 0, 0, 2)
    topLine.BackgroundColor3 = T.Accent
    topLine.ZIndex          = 962
    topLine.Parent          = card
    Util.Gradient(topLine, T.AccentDark, T.AccentLight, 0)

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size           = UDim2.new(1, -28, 0, 28)
    titleLbl.Position       = UDim2.new(0, 18, 0, 14)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text           = cfg.Title or "Confirm"
    titleLbl.TextColor3     = T.TextPri
    titleLbl.TextSize       = 16
    titleLbl.Font           = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex         = 962
    titleLbl.Parent         = card

    -- Content
    local contentLbl = Instance.new("TextLabel")
    contentLbl.Size         = UDim2.new(1, -36, 0, hasIn and 34 or 52)
    contentLbl.Position     = UDim2.new(0, 18, 0, 48)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text         = cfg.Content or "Are you sure?"
    contentLbl.TextColor3   = T.TextSec
    contentLbl.TextSize     = 13
    contentLbl.Font         = Enum.Font.Gotham
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextWrapped  = true
    contentLbl.ZIndex       = 962
    contentLbl.Parent       = card

    -- Optional text input
    local dlgBox
    if hasIn then
        local ibg = Instance.new("Frame")
        ibg.Size              = UDim2.new(1, -36, 0, 32)
        ibg.Position          = UDim2.new(0, 18, 0, 100)
        ibg.BackgroundColor3  = T.Surface
        ibg.BackgroundTransparency = 0.1
        ibg.ZIndex            = 962
        ibg.Parent            = card
        Util.Corner(ibg, 5)
        Util.Stroke(ibg, T.Border, 1, 0.38)

        dlgBox = Instance.new("TextBox")
        dlgBox.Size           = UDim2.new(1, -16, 1, -2)
        dlgBox.Position       = UDim2.new(0, 10, 0, 1)
        dlgBox.BackgroundTransparency = 1
        dlgBox.PlaceholderText = cfg.Placeholder or "Type here…"
        dlgBox.PlaceholderColor3 = T.TextMuted
        dlgBox.Text           = ""
        dlgBox.TextColor3     = T.TextPri
        dlgBox.TextSize       = 13
        dlgBox.Font           = Enum.Font.Gotham
        dlgBox.ClearTextOnFocus = false
        dlgBox.ZIndex         = 963
        dlgBox.Parent         = ibg
    end

    -- Buttons row
    local btnRow = Instance.new("Frame")
    btnRow.Size             = UDim2.new(1, -36, 0, 36)
    btnRow.Position         = UDim2.new(0, 18, 1, -50)
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex           = 962
    btnRow.Parent           = card

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    btnLayout.Padding       = UDim.new(0, 8)
    btnLayout.Parent        = btnRow

    local function close()
        Util.Tween(scrim, { BackgroundTransparency = 1 }, 0.22)
        Util.Tween(card,  { Size = UDim2.new(0, 360, 0, 0),
                            BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Quint)
        task.delay(0.25, function() j:Cleanup() end)
    end

    for _, bDef in ipairs(btns) do
        local isPrimary = bDef.Style == "primary"
        local isDanger  = bDef.Style == "danger"

        local btnFrame = Instance.new("TextButton")
        btnFrame.Size         = UDim2.new(0, 100, 1, 0)
        btnFrame.BackgroundColor3 = isPrimary and T.Accent
                                 or isDanger  and Color3.fromRGB(185,40,40)
                                 or T.SurfaceAlt
        btnFrame.BackgroundTransparency = isPrimary and 0.08 or 0.35
        btnFrame.Text         = bDef.Label or "OK"
        btnFrame.TextColor3   = isPrimary and Color3.new(1,1,1)
                             or isDanger  and Color3.new(1,1,1)
                             or T.TextSec
        btnFrame.TextSize     = 13
        btnFrame.Font         = Enum.Font.GothamBold
        btnFrame.ZIndex       = 963
        btnFrame.Parent       = btnRow
        Util.Corner(btnFrame, 6)
        if isPrimary then Util.Stroke(btnFrame, T.Accent, 1, 0.25) end

        j:Add(btnFrame.MouseEnter:Connect(function()
            Util.Tween(btnFrame, { BackgroundTransparency = 0.0 }, 0.15)
        end), "Disconnect")
        j:Add(btnFrame.MouseLeave:Connect(function()
            Util.Tween(btnFrame, { BackgroundTransparency = isPrimary and 0.08 or 0.35 }, 0.15)
        end), "Disconnect")
        Util.Ripple(btnFrame, j)

        j:Add(btnFrame.MouseButton1Click:Connect(function()
            close()
            if bDef.Callback then
                if hasIn and dlgBox then
                    task.spawn(bDef.Callback, dlgBox.Text)
                else
                    task.spawn(bDef.Callback)
                end
            end
        end), "Disconnect")
    end

    return close
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 19 · MODULE RETURN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return NexusUI

--[[
════════════════════════════════════════════════════════════════
  QUICK-START EXAMPLE
════════════════════════════════════════════════════════════════

local NexusUI = require(path.to.NexusUI)  -- or loadstring(...)()
local lib     = NexusUI.new()

--  ↓ Replace with your actual rbxassetid:// values
lib:Boot("My Cheat Hub", "rbxassetid://YOUR_LOGO_ASSET_ID")

-- Tabs
local mainTab = lib:CreateTab("Main",     "rbxassetid://ICON_ID_1")
local espTab  = lib:CreateTab("Visuals",  "rbxassetid://ICON_ID_2")
local miscTab = lib:CreateTab("Misc",     "rbxassetid://ICON_ID_3")

-- Search bar (optional)
lib:AddSearchBar()

-- Main tab components
mainTab:AddSection("Player")

mainTab:AddButton({
    Name     = "Teleport to Spawn",
    Callback = function()
        -- your logic here
        lib:Notify({
            Title   = "Teleported",
            Content = "Moved to spawn successfully.",
            Duration = 3,
        })
    end,
})

local speedToggle = mainTab:AddToggle({
    Name     = "Speed Hack",
    Default  = false,
    Callback = function(state)
        print("Speed hack:", state)
    end,
})

local speedSlider = mainTab:AddSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 250,
    Default  = 16,
    Callback = function(val)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end,
})

mainTab:AddSection("Keybinds")

mainTab:AddKeybind({
    Name     = "Toggle Menu",
    Default  = Enum.KeyCode.RightShift,
    Callback = function(key)
        print("Keybind fired:", key)
    end,
})

-- Visuals tab
espTab:AddDropdown({
    Name     = "ESP Style",
    Options  = { "Box", "Corner Box", "Skeleton", "Chams", "Full Bright" },
    Default  = "Box",
    Callback = function(val)
        print("ESP style:", val)
    end,
})

-- Notification example
lib:Notify({
    Title    = "NexusUI Loaded",
    Content  = "All modules initialized successfully.",
    Duration = 5,
    -- IconId = "rbxassetid://YOUR_ICON",  ← optional
})

════════════════════════════════════════════════════════════════
  PART 2 · EXTENDED QUICK-START
════════════════════════════════════════════════════════════════

-- ── TextInput ────────────────────────────────────────────────
mainTab:AddSection("Input")

local usernameInput = mainTab:AddTextInput({
    Name        = "Target Player",
    Placeholder = "Enter username…",
    MaxLength   = 20,
    -- Optional validator: reject empty strings
    Validator   = function(txt)
        if txt == "" then return false, "Name cannot be empty" end
        return true
    end,
    Callback    = function(txt, pressedEnter)
        print("Target set to:", txt, "| Enter:", pressedEnter)
    end,
})

local noteInput = mainTab:AddTextInput({
    Name        = "Notes",
    MultiLine   = true,       -- 3-line tall TextBox
    Placeholder = "Write notes here…",
    Callback    = function(txt) print("Notes:", txt) end,
})

-- ── ColorPicker ───────────────────────────────────────────────
espTab:AddSection("Colors")

local espColor = espTab:AddColorPicker({
    Name     = "ESP Box Color",
    Default  = Color3.fromRGB(255, 80, 80),
    Callback = function(color)
        print("ESP color:", color)
    end,
})

-- ── MultiDropdown ─────────────────────────────────────────────
espTab:AddMultiDropdown({
    Name     = "Active Players",
    Options  = { "Player1", "Player2", "Player3", "Player4", "Player5" },
    Defaults = { "Player1" },
    Callback = function(selected)
        print("Selected:", table.concat(selected, ", "))
    end,
})

-- ── ProgressBar ───────────────────────────────────────────────
local healthBar = miscTab:AddProgressBar({
    Name    = "Player Health",
    Value   = 75,
    Max     = 100,
    Label   = "Current HP",
    Color   = Color3.fromRGB(34, 197, 94),
})
-- Update it dynamically:
-- healthBar:Set(50)
-- healthBar:SetLabel("Critical!")

-- ── Theme Switcher ────────────────────────────────────────────
miscTab:AddSection("Appearance")
miscTab:AddDropdown({
    Name    = "Theme",
    Options = { "Violet", "Cyan", "Rose", "Emerald", "Mono" },
    Default = "Violet",
    Callback = function(preset)
        lib:SetTheme(preset)
    end,
})

-- Or pass a raw Color3:
-- lib:SetTheme(Color3.fromRGB(255, 165, 0))   -- orange

-- ── Config Save / Load ────────────────────────────────────────
-- Register a toggle so it participates in config saving:
local fovToggle = miscTab:AddToggle({
    Name    = "Wide FOV",
    Default = false,
    Callback = function(state)
        -- workspace.CurrentCamera.FieldOfView = state and 110 or 70
    end,
})
lib:_RegisterConfig("Misc.WideFOV",
    function() return fovToggle:Get() end,
    function(v) fovToggle:Set(v)      end
)

miscTab:AddButton({
    Name     = "💾  Save Config",
    Callback = function()
        lib:SaveConfig("MyProfile")
    end,
})
miscTab:AddButton({
    Name     = "📂  Load Config",
    Callback = function()
        lib:LoadConfig("MyProfile")
    end,
})

-- ── Watermark ─────────────────────────────────────────────────
local wm = lib:Watermark({
    Text    = "NexusUI",
    SubText = "v2.0",
    ShowFPS = true,       -- live FPS counter
})
-- Toggle visibility with a keybind:
mainTab:AddKeybind({
    Name    = "Toggle Watermark",
    Default = Enum.KeyCode.F2,
    Callback = function()
        wm:Toggle()
    end,
})
-- Update text at runtime:
-- wm:SetText("NexusUI", "Authenticated")

-- ── Context Menu (right-click style) ─────────────────────────
mainTab:AddButton({
    Name     = "Open Context Menu",
    Callback = function()
        lib:ContextMenu({
            Items = {
                {
                    Name   = "Copy Player",
                    Action = function() print("Copied!") end,
                },
                {
                    Name   = "Teleport To",
                    Action = function() print("Teleporting…") end,
                },
                {
                    Name   = "Kick Player",
                    Danger = true,
                    Action = function() print("Kicked.") end,
                },
            },
        })
    end,
})

-- ── Dialog (modal confirmation) ───────────────────────────────
mainTab:AddButton({
    Name     = "Open Confirm Dialog",
    Callback = function()
        lib:Dialog({
            Title   = "Confirm Action",
            Content = "Are you sure you want to execute this action? It cannot be undone.",
            Buttons = {
                {
                    Label    = "Confirm",
                    Style    = "primary",
                    Callback = function()
                        print("Confirmed!")
                    end,
                },
                {
                    Label    = "Cancel",
                    Style    = "ghost",
                    Callback = function()
                        print("Cancelled.")
                    end,
                },
            },
        })
    end,
})

-- Dialog with text input:
mainTab:AddButton({
    Name     = "Rename Dialog",
    Callback = function()
        lib:Dialog({
            Title       = "Rename",
            Content     = "Enter a new name for the script:",
            Input       = true,
            Placeholder = "my_script",
            Buttons     = {
                {
                    Label    = "Rename",
                    Style    = "primary",
                    Callback = function(text)
                        print("New name:", text)
                    end,
                },
                { Label = "Cancel", Style = "ghost" },
            },
        })
    end,
})

════════════════════════════════════════════════════════════════
--]]
