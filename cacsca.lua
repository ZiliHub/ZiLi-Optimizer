--[[
╔══════════════════════════════════════════════════════════════╗
║          FluentHub UI Library  •  v1.0.0  •  Luau           ║
║          Fluent Dark Theme  |  Full OOP Architecture         ║
╚══════════════════════════════════════════════════════════════╝

  QUICK-START
  ───────────
  local Hub  = loadstring(game:HttpGet("..."))()
  local Win  = Hub:CreateWindow("My Hub", "Game Name")
  local Tab  = Win:CreateTab("Main", "⚙")
  Tab:CreateButton("Click Me", function() print("clicked") end)
  Tab:CreateToggle("God Mode", false, function(v) print(v) end)
  Tab:CreateSlider("Speed", 0, 100, 16, function(v) print(v) end)
  Tab:CreateDropdown("Team", {"Red","Blue"}, "Red", function(v) end)
  Tab:CreateKeybind("Open Menu", Enum.KeyCode.RightShift, function() end)
  Hub:Notify("Ready", "Hub loaded successfully!", 4, "success")

  TAB ICONS  (paste any of these as the second arg to CreateTab)
  ─────────────────────────────────────────────────────────────
  "⚙" settings  "⚔" combat  "👁" visuals  "💊" misc
  "🏃" movement  "🎯" aim    "🔧" exploit  "★" main

  NOTIFY KINDS
  ────────────
  "info" (default)  "success"  "warning"  "error"
]]

-- ═══════════════════════════════════════════════════════════════
-- §1  SERVICE CLONES  (cloneref bypass)
-- ═══════════════════════════════════════════════════════════════

local cloneref   = cloneref or function(s) return s end
local getsenv    = getsenv  or function() return {} end

local TweenSvc   = cloneref(game:GetService("TweenService"))
local UIS        = cloneref(game:GetService("UserInputService"))
local CoreGui    = cloneref(game:GetService("CoreGui"))
local Players    = cloneref(game:GetService("Players"))

-- ═══════════════════════════════════════════════════════════════
-- §2  THEME  (edit here to reskin everything)
-- ═══════════════════════════════════════════════════════════════

local T = {
    -- Backgrounds
    Bg           = Color3.fromRGB(18, 18, 24),
    Bg2          = Color3.fromRGB(24, 24, 32),
    Bg3          = Color3.fromRGB(32, 32, 44),
    -- Accent
    Accent       = Color3.fromRGB(0,  150, 255),
    AccentDim    = Color3.fromRGB(0,  100, 200),
    AccentGlow   = Color3.fromRGB(60, 180, 255),
    -- Text
    Text         = Color3.fromRGB(240, 240, 245),
    TextSub      = Color3.fromRGB(155, 155, 170),
    TextMuted    = Color3.fromRGB(88,  88, 106),
    -- Borders & misc
    Border       = Color3.fromRGB(40,  40,  55),
    BtnBg        = Color3.fromRGB(28,  28,  40),
    BtnHover     = Color3.fromRGB(38,  38,  54),
    ToggleOff    = Color3.fromRGB(52,  52,  68),
    SliderTrack  = Color3.fromRGB(36,  36,  50),
    DropBg       = Color3.fromRGB(23,  23,  33),
    -- Status
    Success      = Color3.fromRGB(40,  200, 100),
    Warning      = Color3.fromRGB(255, 175,   0),
    Error        = Color3.fromRGB(255,  60,  60),
}

-- Fonts
local F = {
    Reg  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
    Med  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    Semi = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
}

-- TweenInfo presets
local TI = {
    Def    = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Fast   = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Slow   = TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.38, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    Linear = TweenInfo.new(1.0,  Enum.EasingStyle.Linear),
}

-- ═══════════════════════════════════════════════════════════════
-- §3  UTILITY LAYER
-- ═══════════════════════════════════════════════════════════════

local U = {}

--- Shorthand tween wrapper
function U.Tween(obj, info, goal)
    local t = TweenSvc:Create(obj, info, goal)
    t:Play()
    return t
end

--- Instance factory – sets all non-Parent props first, then parents.
function U.New(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

function U.Corner(p, r)
    return U.New("UICorner", {CornerRadius = UDim.new(0, r or 6), Parent = p})
end

function U.Stroke(p, col, thick)
    return U.New("UIStroke", {
        Color = col or T.Border,
        Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = p,
    })
end

function U.Pad(p, t, b, l, r)
    return U.New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
        Parent = p,
    })
end

--- Ripple click animation on a ClipsDescendants frame
function U.Ripple(frame, rx, ry)
    local sz  = math.max(frame.AbsoluteSize.X, frame.AbsoluteSize.Y) * 2.2
    local rip = U.New("Frame", {
        Size                   = UDim2.new(0, 0, 0, 0),
        Position               = UDim2.new(0, rx, 0, ry),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.78,
        ZIndex                 = frame.ZIndex + 12,
        Parent                 = frame,
    })
    U.Corner(rip, 100)
    U.Tween(rip, TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size                   = UDim2.new(0, sz, 0, sz),
        BackgroundTransparency = 1,
    })
    task.delay(0.52, function()
        if rip.Parent then rip:Destroy() end
    end)
end

--- Connects a hover tween pair to a button frame + detector
function U.HoverBind(frame, det, onC, offC)
    det.MouseEnter:Connect(function()  U.Tween(frame, TI.Fast, onC)  end)
    det.MouseLeave:Connect(function()  U.Tween(frame, TI.Fast, offC) end)
end

-- ═══════════════════════════════════════════════════════════════
-- §4  LOADING SCREEN
-- ═══════════════════════════════════════════════════════════════

local function CreateLoadingScreen(title, onDone)
    -- Remove stale instance if re-running the script
    local old = CoreGui:FindFirstChild("_FH_Loader")
    if old then old:Destroy() end

    local sg = U.New("ScreenGui", {
        Name             = "_FH_Loader",
        ResetOnSpawn     = false,
        IgnoreGuiInset   = true,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        Parent           = CoreGui,
    })

    -- Full-screen canvas group (for smooth GroupTransparency fade-out)
    local canvas = U.New("CanvasGroup", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.Bg,
        GroupTransparency= 0,
        BorderSizePixel  = 0,
        Parent           = sg,
    })
    U.New("UIGradient", {
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 18)),
        }),
        Rotation = 135,
        Parent   = canvas,
    })

    -- ── Center card ──────────────────────────────────────────
    local card = U.New("Frame", {
        Name            = "Card",
        Size            = UDim2.new(0, 340, 0, 290),
        Position        = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint     = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent          = canvas,
    })
    U.New("UIListLayout", {
        FillDirection        = Enum.FillDirection.Vertical,
        HorizontalAlignment  = Enum.HorizontalAlignment.Center,
        VerticalAlignment    = Enum.VerticalAlignment.Center,
        Padding              = UDim.new(0, 16),
        Parent               = card,
    })

    -- Logo box (pulses)
    local logoBox = U.New("Frame", {
        Name             = "Logo",
        Size             = UDim2.new(0, 68, 0, 68),
        BackgroundColor3 = T.Bg2,
        Parent           = card,
    })
    U.Corner(logoBox, 14)
    U.Stroke(logoBox, T.Accent, 1.5)
    U.New("TextLabel", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = "◈",
        TextColor3       = T.Accent,
        TextSize         = 30,
        FontFace         = F.Bold,
        Parent           = logoBox,
    })

    -- Title
    U.New("TextLabel", {
        Size             = UDim2.new(0, 340, 0, 36),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = T.Text,
        TextSize         = 24,
        FontFace         = F.Bold,
        Parent           = card,
    })

    -- Subtitle
    U.New("TextLabel", {
        Size             = UDim2.new(0, 340, 0, 18),
        BackgroundTransparency = 1,
        Text             = "Fluent Edition  •  v1.0.0",
        TextColor3       = T.TextMuted,
        TextSize         = 12,
        FontFace         = F.Reg,
        Parent           = card,
    })

    -- Progress track + fill
    local pTrack = U.New("Frame", {
        Name             = "PTrack",
        Size             = UDim2.new(0, 260, 0, 4),
        BackgroundColor3 = T.Bg3,
        Parent           = card,
    })
    U.Corner(pTrack, 2)
    local pFill = U.New("Frame", {
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Accent,
        Parent           = pTrack,
    })
    U.Corner(pFill, 2)

    -- Status text
    local statusLbl = U.New("TextLabel", {
        Size             = UDim2.new(0, 340, 0, 16),
        BackgroundTransparency = 1,
        Text             = "Initializing...",
        TextColor3       = T.TextMuted,
        TextSize         = 11,
        FontFace         = F.Reg,
        Parent           = card,
    })

    -- ── Logo pulse loop ──────────────────────────────────────
    local pulseAlive = true
    task.spawn(function()
        while pulseAlive and logoBox.Parent do
            U.Tween(logoBox, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundColor3 = Color3.fromRGB(0, 28, 58)})
            task.wait(1.1)
            U.Tween(logoBox, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundColor3 = T.Bg2})
            task.wait(1.1)
        end
    end)

    -- ── Loading steps ────────────────────────────────────────
    local steps = {
        {msg = "Initializing library...",        pct = 0.15},
        {msg = "Cloning service references...",  pct = 0.32},
        {msg = "Loading UI modules...",          pct = 0.54},
        {msg = "Bypassing anti-cheat...",        pct = 0.72},
        {msg = "Compiling components...",        pct = 0.90},
        {msg = "Ready!",                         pct = 1.00},
    }

    task.spawn(function()
        for _, step in ipairs(steps) do
            task.wait(0.38)
            statusLbl.Text = step.msg
            U.Tween(pFill, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(step.pct, 0, 1, 0),
            })
        end

        task.wait(0.55)
        pulseAlive = false

        -- Fade out & destroy
        U.Tween(canvas, TI.Slow, {GroupTransparency = 1})
        task.wait(0.45)
        if sg.Parent then sg:Destroy() end
        if onDone then task.spawn(onDone) end
    end)

    return sg
end

-- ═══════════════════════════════════════════════════════════════
-- §5  NOTIFICATION MANAGER
-- ═══════════════════════════════════════════════════════════════

local NotifManager = {}
NotifManager.__index = NotifManager

function NotifManager.new()
    local self = setmetatable({}, NotifManager)

    local old = CoreGui:FindFirstChild("_FH_Notifs")
    if old then old:Destroy() end

    self._sg = U.New("ScreenGui", {
        Name           = "_FH_Notifs",
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent         = CoreGui,
    })

    self._holder = U.New("Frame", {
        Name                = "Holder",
        Size                = UDim2.new(0, 312, 1, 0),
        Position            = UDim2.new(1, -326, 0, 0),
        BackgroundTransparency = 1,
        Parent              = self._sg,
    })

    U.New("UIListLayout", {
        FillDirection       = Enum.FillDirection.Vertical,
        VerticalAlignment   = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding             = UDim.new(0, 8),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Parent              = self._holder,
    })
    U.Pad(self._holder, 0, 20, 0, 0)

    return self
end

function NotifManager:Push(title, body, duration, kind)
    duration = duration or 4
    local accent = (kind == "success" and T.Success)
                or (kind == "warning" and T.Warning)
                or (kind == "error"   and T.Error)
                or T.Accent

    -- Card
    local card = U.New("Frame", {
        Name             = "Card",
        Size             = UDim2.new(1, 0, 0, 78),
        BackgroundColor3 = T.Bg2,
        ClipsDescendants = false,
        LayoutOrder      = math.floor(os.clock() * 1000),
        Parent           = self._holder,
    })
    U.Corner(card, 8)
    U.Stroke(card, T.Border, 1)

    -- Left accent strip
    local strip = U.New("Frame", {
        Size             = UDim2.new(0, 3, 0.65, 0),
        Position         = UDim2.new(0, 0, 0.175, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Parent           = card,
    })
    U.Corner(strip, 2)

    -- Inner content
    local inner = U.New("Frame", {
        Size                = UDim2.new(1, -18, 1, 0),
        Position            = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Parent              = card,
    })

    U.New("TextLabel", {
        Size             = UDim2.new(1, -28, 0, 22),
        Position         = UDim2.new(0, 0, 0, 11),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = T.Text,
        TextSize         = 14,
        FontFace         = F.Semi,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        Parent           = inner,
    })
    U.New("TextLabel", {
        Size             = UDim2.new(1, -6, 0, 30),
        Position         = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        Text             = body,
        TextColor3       = T.TextSub,
        TextSize         = 12,
        FontFace         = F.Reg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        Parent           = inner,
    })

    -- Close × button
    local closeBtn = U.New("TextButton", {
        Size             = UDim2.new(0, 18, 0, 18),
        Position         = UDim2.new(1, -22, 0, 7),
        BackgroundTransparency = 1,
        Text             = "×",
        TextColor3       = T.TextMuted,
        TextSize         = 18,
        FontFace         = F.Bold,
        ZIndex           = card.ZIndex + 2,
        Parent           = card,
    })

    -- Bottom progress bar
    local pbg = U.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = T.Bg3,
        BorderSizePixel  = 0,
        Parent           = card,
    })
    local pfill = U.New("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Parent           = pbg,
    })

    -- Slide-in from right
    card.Position = UDim2.new(1, 24, 1, 0)
    U.Tween(card, TI.Spring, {Position = UDim2.new(0, 0, 1, 0)})

    -- Progress countdown
    task.spawn(function()
        U.Tween(pfill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0),
        })
    end)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        U.Tween(card, TI.Def, {
            Position         = UDim2.new(1, 24, 1, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.28, function()
            if card.Parent then card:Destroy() end
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    task.delay(duration, dismiss)
end

-- ═══════════════════════════════════════════════════════════════
-- §6  TAB CLASS
--     Each Tab owns its sidebar button, its scrolling content
--     frame, its component list, and its signal connections.
-- ═══════════════════════════════════════════════════════════════

local Tab = {}
Tab.__index = Tab

function Tab.new(win, name, icon)
    local self   = setmetatable({}, Tab)
    self._win    = win
    self.Name    = name
    self._icon   = icon or "○"
    self._comps  = {}   -- {Name, Frame} entries for search
    self._conns  = {}   -- RBXScriptConnections to disconnect on destroy
    self.Active  = false
    self:_MakeButton()
    self:_MakeContent()
    return self
end

-- ── Tab sidebar button ────────────────────────────────────────
function Tab:_MakeButton()
    -- Outer container
    self._btn = U.New("Frame", {
        Name             = "TB_" .. self.Name,
        Size             = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = T.Bg3,
        BackgroundTransparency = 1,
        Parent           = self._win._tabScroll,
    })
    U.Corner(self._btn, 6)

    -- Glowing active indicator strip on the left edge
    self._indicator = U.New("Frame", {
        Size             = UDim2.new(0, 3, 0.58, 0),
        Position         = UDim2.new(0, 0, 0.21, 0),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Parent           = self._btn,
    })
    U.Corner(self._indicator, 2)

    -- Icon label
    self._iconLbl = U.New("TextLabel", {
        Name             = "Icon",
        Size             = UDim2.new(0, 20, 0, 20),
        Position         = UDim2.new(0, 10, 0.5, -10),
        BackgroundTransparency = 1,
        Text             = self._icon,
        TextColor3       = T.TextMuted,
        TextSize         = 14,
        FontFace         = F.Reg,
        Parent           = self._btn,
    })

    -- Name label
    self._nameLbl = U.New("TextLabel", {
        Name             = "Lbl",
        Size             = UDim2.new(1, -36, 1, 0),
        Position         = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        Text             = self.Name,
        TextColor3       = T.TextMuted,
        TextSize         = 13,
        FontFace         = F.Med,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = self._btn,
    })

    -- Invisible click detector on top
    local det = U.New("TextButton", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = self._btn.ZIndex + 1,
        Parent           = self._btn,
    })

    table.insert(self._conns, det.MouseEnter:Connect(function()
        if not self.Active then
            U.Tween(self._btn,     TI.Fast, {BackgroundTransparency = 0.55, BackgroundColor3 = T.Bg3})
            U.Tween(self._nameLbl, TI.Fast, {TextColor3 = T.TextSub})
        end
    end))
    table.insert(self._conns, det.MouseLeave:Connect(function()
        if not self.Active then
            U.Tween(self._btn,     TI.Fast, {BackgroundTransparency = 1})
            U.Tween(self._nameLbl, TI.Fast, {TextColor3 = T.TextMuted})
        end
    end))
    table.insert(self._conns, det.MouseButton1Click:Connect(function()
        self._win:_SwitchTab(self)
    end))
end

-- ── Tab scrolling content frame ───────────────────────────────
function Tab:_MakeContent()
    self._scroll = U.New("ScrollingFrame", {
        Name             = "TC_" .. self.Name,
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = T.Accent,
        ScrollBarImageTransparency = 0.45,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        BorderSizePixel        = 0,
        Visible                = false,
        Parent                 = self._win._contentHolder,
    })
    U.New("UIListLayout", {
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding             = UDim.new(0, 6),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Parent              = self._scroll,
    })
    U.Pad(self._scroll, 4, 10, 0, 0)
end

function Tab:_Activate()
    self.Active = true
    self._scroll.Visible = true
    U.Tween(self._btn,       TI.Def, {BackgroundColor3 = Color3.fromRGB(26, 26, 40), BackgroundTransparency = 0})
    U.Tween(self._nameLbl,   TI.Def, {TextColor3 = T.Accent})
    U.Tween(self._iconLbl,   TI.Def, {TextColor3 = T.Accent})
    U.Tween(self._indicator, TI.Def, {BackgroundTransparency = 0})
end

function Tab:_Deactivate()
    self.Active = false
    self._scroll.Visible = false
    U.Tween(self._btn,       TI.Def, {BackgroundTransparency = 1})
    U.Tween(self._nameLbl,   TI.Def, {TextColor3 = T.TextMuted})
    U.Tween(self._iconLbl,   TI.Def, {TextColor3 = T.TextMuted})
    U.Tween(self._indicator, TI.Def, {BackgroundTransparency = 1})
end

--- Case-insensitive search filter applied to this tab's components
function Tab:_Filter(q)
    for _, comp in ipairs(self._comps) do
        if comp.Frame then
            comp.Frame.Visible = (q == "") or
                (comp.Name:lower():find(q, 1, true) ~= nil)
        end
    end
end

function Tab:_Reg(comp)
    table.insert(self._comps, comp)
    return comp
end

-- ═══════════════════════════════════════════════════════════════
-- §6a  SECTION DIVIDER  (cosmetic label + line)
-- ═══════════════════════════════════════════════════════════════

function Tab:CreateSection(label)
    local comp = {Name = label or ""}

    local f = U.New("Frame", {
        Name             = "Sec_" .. (label or ""),
        Size             = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent           = self._scroll,
    })
    comp.Frame = f

    U.New("Frame", {
        Size             = UDim2.new(0, 3, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.25, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Parent           = f,
    })
    U.New("TextLabel", {
        Size             = UDim2.new(1, -10, 1, 0),
        Position         = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text             = (label or ""):upper(),
        TextColor3       = T.TextMuted,
        TextSize         = 11,
        FontFace         = F.Semi,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = f,
    })
    U.New("Frame", {
        Size             = UDim2.new(1, -10, 0, 1),
        Position         = UDim2.new(0, 10, 1, -1),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
        Parent           = f,
    })

    return self:_Reg(comp)
end

-- ═══════════════════════════════════════════════════════════════
-- §6b  BUTTON
-- ═══════════════════════════════════════════════════════════════

function Tab:CreateButton(name, cb)
    cb = cb or function() end
    local comp = {Name = name}

    local f = U.New("Frame", {
        Name             = "Btn_" .. name,
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.BtnBg,
        ClipsDescendants = true,
        Parent           = self._scroll,
    })
    U.Corner(f, 6); U.Stroke(f, T.Border)
    comp.Frame = f

    U.New("TextLabel", {
        Size             = UDim2.new(1, -50, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = name,
        TextColor3       = T.Text,
        TextSize         = 13,
        FontFace         = F.Med,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = f,
    })
    local arr = U.New("TextLabel", {
        Size             = UDim2.new(0, 22, 1, 0),
        Position         = UDim2.new(1, -26, 0, 0),
        BackgroundTransparency = 1,
        Text             = "›",
        TextColor3       = T.TextMuted,
        TextSize         = 20,
        FontFace         = F.Bold,
        Parent           = f,
    })
    local det = U.New("TextButton", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = f.ZIndex + 1,
        Parent           = f,
    })

    det.MouseEnter:Connect(function()
        U.Tween(f,   TI.Fast, {BackgroundColor3 = T.BtnHover})
        U.Tween(arr, TI.Fast, {TextColor3 = T.Accent, Position = UDim2.new(1, -22, 0, 0)})
    end)
    det.MouseLeave:Connect(function()
        U.Tween(f,   TI.Fast, {BackgroundColor3 = T.BtnBg})
        U.Tween(arr, TI.Fast, {TextColor3 = T.TextMuted, Position = UDim2.new(1, -26, 0, 0)})
    end)
    det.MouseButton1Click:Connect(function()
        local mp  = UIS:GetMouseLocation()
        local rx  = mp.X - f.AbsolutePosition.X
        local ry  = mp.Y - f.AbsolutePosition.Y
        U.Ripple(f, rx, ry)
        U.Tween(f, TI.Fast, {BackgroundColor3 = Color3.fromRGB(36, 88, 170)})
        task.delay(0.15, function() U.Tween(f, TI.Fast, {BackgroundColor3 = T.BtnHover}) end)
        task.spawn(cb)
    end)

    return self:_Reg(comp)
end

-- ═══════════════════════════════════════════════════════════════
-- §6c  TOGGLE
-- ═══════════════════════════════════════════════════════════════

function Tab:CreateToggle(name, default, cb)
    cb = cb or function() end
    local state = (default == true)
    local comp  = {Name = name}

    local f = U.New("Frame", {
        Name             = "Tog_" .. name,
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.BtnBg,
        ClipsDescendants = true,
        Parent           = self._scroll,
    })
    U.Corner(f, 6); U.Stroke(f, T.Border)
    comp.Frame = f

    U.New("TextLabel", {
        Size             = UDim2.new(1, -74, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = name,
        TextColor3       = T.Text,
        TextSize         = 13,
        FontFace         = F.Med,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = f,
    })

    -- Pill track
    local track = U.New("Frame", {
        Name             = "Track",
        Size             = UDim2.new(0, 44, 0, 24),
        Position         = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = state and T.Accent or T.ToggleOff,
        Parent           = f,
    })
    U.Corner(track, 12)

    -- Sliding knob
    local knob = U.New("Frame", {
        Name             = "Knob",
        Size             = UDim2.new(0, 18, 0, 18),
        Position         = UDim2.new(0, state and 23 or 3, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent           = track,
    })
    U.Corner(knob, 9)

    -- Knob inner glow when ON
    local glow = U.New("Frame", {
        Size             = UDim2.new(1, 6, 1, 6),
        Position         = UDim2.new(0, -3, 0, -3),
        BackgroundColor3 = T.AccentGlow,
        BackgroundTransparency = 1,
        ZIndex           = knob.ZIndex - 1,
        Parent           = knob,
    })
    U.Corner(glow, 12)

    local det = U.New("TextButton", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = f.ZIndex + 1,
        Parent           = f,
    })

    local function refresh()
        U.Tween(track, TI.Def,  {BackgroundColor3 = state and T.Accent or T.ToggleOff})
        U.Tween(knob,  TI.Def,  {Position = UDim2.new(0, state and 23 or 3, 0.5, -9)})
        U.Tween(glow,  TI.Def,  {BackgroundTransparency = state and 0.65 or 1})
    end

    det.MouseEnter:Connect(function() U.Tween(f, TI.Fast, {BackgroundColor3 = T.BtnHover}) end)
    det.MouseLeave:Connect(function() U.Tween(f, TI.Fast, {BackgroundColor3 = T.BtnBg})   end)
    det.MouseButton1Click:Connect(function()
        state = not state; refresh(); task.spawn(cb, state)
    end)

    comp.Set = function(v) state = not not v; refresh(); task.spawn(cb, state) end
    comp.Get = function()  return state end

    return self:_Reg(comp)
end

-- ═══════════════════════════════════════════════════════════════
-- §6d  SLIDER
-- ═══════════════════════════════════════════════════════════════

function Tab:CreateSlider(name, minV, maxV, default, cb)
    cb   = cb   or function() end
    minV = minV or 0
    maxV = maxV or 100
    local val  = math.clamp(default or minV, minV, maxV)
    local comp = {Name = name}

    local f = U.New("Frame", {
        Name             = "Sld_" .. name,
        Size             = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = T.BtnBg,
        Parent           = self._scroll,
    })
    U.Corner(f, 6); U.Stroke(f, T.Border)
    comp.Frame = f

    -- Top row: label + live value
    local top = U.New("Frame", {
        Size             = UDim2.new(1, -20, 0, 22),
        Position         = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1,
        Parent           = f,
    })
    U.New("TextLabel", {
        Size             = UDim2.new(0.65, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = name,
        TextColor3       = T.Text,
        TextSize         = 13,
        FontFace         = F.Med,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = top,
    })
    local valLbl = U.New("TextLabel", {
        Size             = UDim2.new(0.35, 0, 1, 0),
        Position         = UDim2.new(0.65, 0, 0, 0),
        BackgroundTransparency = 1,
        Text             = tostring(val),
        TextColor3       = T.Accent,
        TextSize         = 13,
        FontFace         = F.Semi,
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = top,
    })

    -- Track
    local track = U.New("Frame", {
        Name             = "Track",
        Size             = UDim2.new(1, -20, 0, 5),
        Position         = UDim2.new(0, 10, 0, 38),
        BackgroundColor3 = T.SliderTrack,
        Parent           = f,
    })
    U.Corner(track, 3)

    local fill = U.New("Frame", {
        Size             = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0),
        BackgroundColor3 = T.Accent,
        Parent           = track,
    })
    U.Corner(fill, 3)

    -- Knob
    local KS  = 14     -- base size
    local KSH = 18     -- hover size
    local pct = (val - minV) / (maxV - minV)
    local knob = U.New("Frame", {
        Name             = "Knob",
        Size             = UDim2.new(0, KS, 0, KS),
        Position         = UDim2.new(pct, -KS/2, 0.5, -KS/2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex           = track.ZIndex + 2,
        Parent           = track,
    })
    U.Corner(knob, KS/2)
    U.Stroke(knob, T.Accent, 2)

    -- Drag logic
    local dragging = false

    local function apply(px)
        local ap  = track.AbsolutePosition
        local as  = track.AbsoluteSize
        local p   = math.clamp((px - ap.X) / as.X, 0, 1)
        val       = math.round(minV + p * (maxV - minV))
        local fp  = (val - minV) / (maxV - minV)
        local ks  = dragging and KSH or KS
        U.Tween(fill,  TI.Fast, {Size     = UDim2.new(fp, 0, 1, 0)})
        U.Tween(knob,  TI.Fast, {Position = UDim2.new(fp, -ks/2, 0.5, -ks/2)})
        valLbl.Text = tostring(val)
        task.spawn(cb, val)
    end

    local c1 = track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; apply(i.Position.X)
        end
    end)
    local c2 = UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            apply(i.Position.X)
        end
    end)
    local c3 = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            local fp = (val - minV) / (maxV - minV)
            U.Tween(knob, TI.Fast, {Size = UDim2.new(0, KS, 0, KS), Position = UDim2.new(fp, -KS/2, 0.5, -KS/2)})
        end
    end)

    track.MouseEnter:Connect(function()
        if not dragging then
            local fp = (val - minV) / (maxV - minV)
            U.Tween(knob, TI.Fast, {Size = UDim2.new(0, KSH, 0, KSH), Position = UDim2.new(fp, -KSH/2, 0.5, -KSH/2)})
        end
    end)
    track.MouseLeave:Connect(function()
        if not dragging then
            local fp = (val - minV) / (maxV - minV)
            U.Tween(knob, TI.Fast, {Size = UDim2.new(0, KS, 0, KS), Position = UDim2.new(fp, -KS/2, 0.5, -KS/2)})
        end
    end)

    table.insert(self._conns, c1)
    table.insert(self._conns, c2)
    table.insert(self._conns, c3)

    comp.Set = function(v)
        val = math.clamp(v, minV, maxV)
        local fp = (val - minV) / (maxV - minV)
        U.Tween(fill,  TI.Def, {Size     = UDim2.new(fp, 0, 1, 0)})
        U.Tween(knob,  TI.Def, {Position = UDim2.new(fp, -KS/2, 0.5, -KS/2)})
        valLbl.Text = tostring(val)
    end
    comp.Get = function() return val end

    return self:_Reg(comp)
end

-- ═══════════════════════════════════════════════════════════════
-- §6e  DROPDOWN
-- ═══════════════════════════════════════════════════════════════

function Tab:CreateDropdown(name, opts, default, cb)
    cb  = cb or function() end
    local sel  = default or (opts and opts[1]) or "None"
    local open = false
    local ITEM_H = 32
    local MAXVIS = 5
    local comp   = {Name = name}

    -- Wrapper – ClipsDescendants OFF so the list can overflow
    local f = U.New("Frame", {
        Name             = "DD_" .. name,
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.BtnBg,
        ClipsDescendants = false,
        ZIndex           = 6,
        Parent           = self._scroll,
    })
    U.Corner(f, 6); U.Stroke(f, T.Border)
    comp.Frame = f

    -- Header (clips its own content)
    local hdr = U.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex           = f.ZIndex,
        Parent           = f,
    })
    U.Corner(hdr, 6)

    U.New("TextLabel", {
        Size             = UDim2.new(0.52, 0, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = name,
        TextColor3       = T.Text,
        TextSize         = 13,
        FontFace         = F.Med,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = f.ZIndex + 1,
        Parent           = hdr,
    })
    local selLbl = U.New("TextLabel", {
        Size             = UDim2.new(0.36, 0, 1, 0),
        Position         = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1,
        Text             = sel,
        TextColor3       = T.Accent,
        TextSize         = 12,
        FontFace         = F.Med,
        TextXAlignment   = Enum.TextXAlignment.Right,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        ZIndex           = f.ZIndex + 1,
        Parent           = hdr,
    })
    local arrow = U.New("TextLabel", {
        Size             = UDim2.new(0, 20, 1, 0),
        Position         = UDim2.new(1, -26, 0, 0),
        BackgroundTransparency = 1,
        Text             = "▾",
        TextColor3       = T.TextMuted,
        TextSize         = 13,
        ZIndex           = f.ZIndex + 1,
        Parent           = hdr,
    })

    -- Drop-down list panel
    local listH = math.min(#opts, MAXVIS) * ITEM_H + 8
    local list  = U.New("Frame", {
        Name             = "List",
        Size             = UDim2.new(1, 0, 0, 0),
        Position         = UDim2.new(0, 0, 1, 6),
        BackgroundColor3 = T.DropBg,
        ClipsDescendants = true,
        ZIndex           = f.ZIndex + 10,
        Visible          = false,
        Parent           = f,
    })
    U.Corner(list, 6); U.Stroke(list, T.Border)

    local scroll = U.New("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = T.Accent,
        CanvasSize             = UDim2.new(0, 0, 0, #opts * ITEM_H + 8),
        ZIndex                 = list.ZIndex + 1,
        Parent                 = list,
    })
    U.New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 0),
        Parent        = scroll,
    })
    U.Pad(scroll, 4, 4, 0, 0)

    for _, opt in ipairs(opts) do
        local ob = U.New("TextButton", {
            Name             = "Opt_" .. opt,
            Size             = UDim2.new(1, -8, 0, ITEM_H - 2),
            BackgroundColor3 = T.DropBg,
            BackgroundTransparency = 1,
            Text             = opt,
            TextColor3       = opt == sel and T.Accent or T.TextSub,
            TextSize         = 12,
            FontFace         = F.Reg,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = scroll.ZIndex + 1,
            Parent           = scroll,
        })
        U.Pad(ob, 0, 0, 12, 0)
        U.Corner(ob, 4)

        ob.MouseEnter:Connect(function()
            U.Tween(ob, TI.Fast, {BackgroundTransparency = 0,
                BackgroundColor3 = Color3.fromRGB(36, 36, 52), TextColor3 = T.Text})
        end)
        ob.MouseLeave:Connect(function()
            U.Tween(ob, TI.Fast, {BackgroundTransparency = 1,
                TextColor3 = ob.Text == sel and T.Accent or T.TextSub})
        end)
        ob.MouseButton1Click:Connect(function()
            sel         = opt
            selLbl.Text = sel
            -- Refresh option colors
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = child.Text == sel and T.Accent or T.TextSub
                end
            end
            -- Close
            open = false
            U.Tween(list,  TI.Def, {Size = UDim2.new(1, 0, 0, 0)})
            U.Tween(arrow, TI.Def, {Rotation = 0})
            task.delay(0.27, function()
                if not open then
                    list.Visible = false
                    f.Size = UDim2.new(1, 0, 0, 44)
                end
            end)
            task.spawn(cb, sel)
        end)
    end

    -- Header click detector
    local hBtn = U.New("TextButton", {
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = f.ZIndex + 2,
        Parent           = f,
    })
    hBtn.MouseEnter:Connect(function() U.Tween(f, TI.Fast, {BackgroundColor3 = T.BtnHover}) end)
    hBtn.MouseLeave:Connect(function() U.Tween(f, TI.Fast, {BackgroundColor3 = T.BtnBg})   end)
    hBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            list.Visible = true
            f.Size = UDim2.new(1, 0, 0, 44 + listH + 6)
            U.Tween(list,  TI.Def, {Size = UDim2.new(1, 0, 0, listH)})
            U.Tween(arrow, TI.Def, {Rotation = 180})
        else
            U.Tween(list,  TI.Def, {Size = UDim2.new(1, 0, 0, 0)})
            U.Tween(arrow, TI.Def, {Rotation = 0})
            task.delay(0.27, function()
                if not open then
                    list.Visible = false
                    f.Size = UDim2.new(1, 0, 0, 44)
                end
            end)
        end
    end)

    comp.Set = function(v)  sel = v; selLbl.Text = v end
    comp.Get = function()  return sel end

    return self:_Reg(comp)
end

-- ═══════════════════════════════════════════════════════════════
-- §6f  KEYBIND
-- ═══════════════════════════════════════════════════════════════

function Tab:CreateKeybind(name, defKey, cb)
    cb  = cb or function() end
    local key       = defKey or Enum.KeyCode.Unknown
    local listening = false
    local comp      = {Name = name}

    local f = U.New("Frame", {
        Name             = "KB_" .. name,
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.BtnBg,
        ClipsDescendants = true,
        Parent           = self._scroll,
    })
    U.Corner(f, 6); U.Stroke(f, T.Border)
    comp.Frame = f

    U.New("TextLabel", {
        Size             = UDim2.new(0.58, 0, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = name,
        TextColor3       = T.Text,
        TextSize         = 13,
        FontFace         = F.Med,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = f,
    })

    -- Key badge pill
    local badge = U.New("Frame", {
        Name             = "Badge",
        Size             = UDim2.new(0, 84, 0, 26),
        Position         = UDim2.new(1, -96, 0.5, -13),
        BackgroundColor3 = T.Bg3,
        Parent           = f,
    })
    U.Corner(badge, 5); U.Stroke(badge, T.Border)

    local kLbl = U.New("TextLabel", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = key.Name,
        TextColor3       = T.Text,
        TextSize         = 12,
        FontFace         = F.Semi,
        Parent           = badge,
    })

    local det = U.New("TextButton", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = f.ZIndex + 1,
        Parent           = f,
    })

    det.MouseEnter:Connect(function() U.Tween(f, TI.Fast, {BackgroundColor3 = T.BtnHover}) end)
    det.MouseLeave:Connect(function()
        if not listening then U.Tween(f, TI.Fast, {BackgroundColor3 = T.BtnBg}) end
    end)

    det.MouseButton1Click:Connect(function()
        if listening then return end
        listening   = true
        kLbl.Text   = "[  ...]"
        U.Tween(badge, TI.Fast, {BackgroundColor3 = Color3.fromRGB(28, 52, 80)})

        -- Blink animation while waiting
        local blinkAlive = true
        task.spawn(function()
            local dots = {"[·  ]","[ · ]","[  ·]","[ · ]"}
            local i    = 1
            while blinkAlive do
                kLbl.Text = dots[i]
                i = (i % #dots) + 1
                task.wait(0.22)
            end
        end)

        -- One-shot key capture
        local capConn
        capConn = UIS.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            blinkAlive  = false
            listening   = false
            key         = input.KeyCode
            kLbl.Text   = input.KeyCode.Name
            U.Tween(badge, TI.Fast, {BackgroundColor3 = T.Bg3})
            U.Tween(f,     TI.Fast, {BackgroundColor3 = T.BtnBg})
            capConn:Disconnect()
        end)
        table.insert(self._conns, capConn)
    end)

    -- Global hotkey activation
    local hkConn = UIS.InputBegan:Connect(function(input, gp)
        if gp or listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard
           and input.KeyCode == key then
            task.spawn(cb, key)
        end
    end)
    table.insert(self._conns, hkConn)

    comp.Set = function(k) key = k; kLbl.Text = k.Name end
    comp.Get = function()  return key end

    return self:_Reg(comp)
end

-- ═══════════════════════════════════════════════════════════════
-- §7  WINDOW CLASS
-- ═══════════════════════════════════════════════════════════════

local Window = {}
Window.__index = Window

function Window.new(hubName, gameName, notifMgr)
    local self        = setmetatable({}, Window)
    self._hubName     = hubName  or "FluentHub"
    self._gameName    = gameName or "Unknown Game"
    self._notif       = notifMgr
    self._tabs        = {}
    self._activeTab   = nil
    self._conns       = {}
    self._minimized   = false
    self:_Build()
    return self
end

function Window:_Build()
    -- Guard against duplicate GUIs
    local old = CoreGui:FindFirstChild("_FH_Main")
    if old then old:Destroy() end

    self._sg = U.New("ScreenGui", {
        Name             = "_FH_Main",
        ResetOnSpawn     = false,
        IgnoreGuiInset   = true,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        Parent           = CoreGui,
    })

    -- Drop shadow (image-based)
    U.New("ImageLabel", {
        Size             = UDim2.new(0, 752, 0, 524),
        Position         = UDim2.new(0.5, -376, 0.5, -262),
        BackgroundTransparency = 1,
        Image            = "rbxassetid://5028857084",
        ImageColor3      = Color3.new(0, 0, 0),
        ImageTransparency= 0.52,
        ZIndex           = 0,
        Parent           = self._sg,
    })

    -- Main frame
    self._main = U.New("Frame", {
        Name             = "_FH_Win",
        Size             = UDim2.new(0, 720, 0, 472),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = T.Bg,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        Parent           = self._sg,
    })
    U.Corner(self._main, 8)
    U.Stroke(self._main, T.Border, 1)

    self:_BuildTopBar()
    self:_BuildBody()
    self:_SetupDrag()
    self:_SetupControlBtns()
    self:_SetupSearch()

    -- Spawn-in animation (scale from 0)
    self._main.Size = UDim2.new(0, 0, 0, 0)
    U.Tween(self._main, TI.Spring, {Size = UDim2.new(0, 720, 0, 472)})
end

-- ── Top bar ───────────────────────────────────────────────────
function Window:_BuildTopBar()
    self._topbar = U.New("Frame", {
        Name             = "TopBar",
        Size             = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = T.Bg2,
        ClipsDescendants = true,
        Parent           = self._main,
    })
    U.Corner(self._topbar, 8)
    -- Mask to make only the top 2 corners round
    U.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 8),
        Position         = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = T.Bg2,
        BorderSizePixel  = 0,
        ZIndex           = self._topbar.ZIndex,
        Parent           = self._topbar,
    })
    U.New("UIGradient", {
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 22, 32)),
        }),
        Rotation = 90,
        Parent   = self._topbar,
    })

    -- Logo icon
    local icon = U.New("Frame", {
        Size             = UDim2.new(0, 28, 0, 28),
        Position         = UDim2.new(0, 14, 0.5, -14),
        BackgroundColor3 = T.Accent,
        Parent           = self._topbar,
    })
    U.Corner(icon, 6)
    U.New("TextLabel", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = "◈",
        TextColor3       = Color3.new(1, 1, 1),
        TextSize         = 14,
        FontFace         = F.Bold,
        Parent           = icon,
    })

    -- Hub name
    U.New("TextLabel", {
        Size             = UDim2.new(0, 180, 1, 0),
        Position         = UDim2.new(0, 50, 0, 0),
        BackgroundTransparency = 1,
        Text             = self._hubName,
        TextColor3       = T.Text,
        TextSize         = 14,
        FontFace         = F.Semi,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = self._topbar,
    })

    -- Game name (centered)
    U.New("TextLabel", {
        Size             = UDim2.new(0, 220, 0, 22),
        Position         = UDim2.new(0.5, -110, 0.5, -11),
        BackgroundTransparency = 1,
        Text             = self._gameName,
        TextColor3       = T.TextMuted,
        TextSize         = 12,
        FontFace         = F.Reg,
        Parent           = self._topbar,
    })

    -- Control buttons (right side)
    local ctrl = U.New("Frame", {
        Size             = UDim2.new(0, 70, 0, 30),
        Position         = UDim2.new(1, -84, 0.5, -15),
        BackgroundTransparency = 1,
        Parent           = self._topbar,
    })
    U.New("UIListLayout", {
        FillDirection       = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0, 6),
        Parent              = ctrl,
    })

    self._minBtn = U.New("TextButton", {
        Size             = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = T.Bg3,
        Text             = "−",
        TextColor3       = T.TextSub,
        TextSize         = 16,
        FontFace         = F.Bold,
        Parent           = ctrl,
    })
    U.Corner(self._minBtn, 6)

    self._closeBtn = U.New("TextButton", {
        Size             = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = T.Bg3,
        Text             = "×",
        TextColor3       = T.TextSub,
        TextSize         = 18,
        FontFace         = F.Bold,
        Parent           = ctrl,
    })
    U.Corner(self._closeBtn, 6)
end

-- ── Body (sidebar + content) ──────────────────────────────────
function Window:_BuildBody()
    self._body = U.New("Frame", {
        Name             = "Body",
        Size             = UDim2.new(1, 0, 1, -52),
        Position         = UDim2.new(0, 0, 0, 52),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = self._main,
    })

    -- Left sidebar ──────────────────────────────────────────
    self._sidebar = U.New("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = T.Bg2,
        BorderSizePixel  = 0,
        Parent           = self._body,
    })
    -- Right border line
    U.New("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
        Parent           = self._sidebar,
    })
    U.New("UIGradient", {
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 36)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 28)),
        }),
        Rotation = 90,
        Parent   = self._sidebar,
    })

    self._tabScroll = U.New("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, -10),
        Position         = UDim2.new(0, 0, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 0,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Parent                 = self._sidebar,
    })
    U.New("UIListLayout", {
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding             = UDim.new(0, 4),
        Parent              = self._tabScroll,
    })
    U.Pad(self._tabScroll, 8, 8, 8, 8)

    -- Right content area ────────────────────────────────────
    self._contentArea = U.New("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -160, 1, 0),
        Position         = UDim2.new(0, 160, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = self._body,
    })

    -- Search bar
    self._searchBar = U.New("Frame", {
        Name             = "SearchBar",
        Size             = UDim2.new(1, -20, 0, 34),
        Position         = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = T.Bg3,
        Parent           = self._contentArea,
    })
    U.Corner(self._searchBar, 6)
    U.Stroke(self._searchBar, T.Border)

    U.New("TextLabel", {
        Size             = UDim2.new(0, 22, 1, 0),
        Position         = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text             = "⌕",
        TextColor3       = T.TextMuted,
        TextSize         = 16,
        Parent           = self._searchBar,
    })
    self._searchBox = U.New("TextBox", {
        Size             = UDim2.new(1, -38, 1, 0),
        Position         = UDim2.new(0, 33, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText  = "Search components...",
        PlaceholderColor3= T.TextMuted,
        Text             = "",
        TextColor3       = T.Text,
        TextSize         = 13,
        FontFace         = F.Reg,
        ClearTextOnFocus = false,
        Parent           = self._searchBar,
    })

    -- Component content holder
    self._contentHolder = U.New("Frame", {
        Name             = "ContentHolder",
        Size             = UDim2.new(1, -20, 1, -54),
        Position         = UDim2.new(0, 10, 0, 52),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = self._contentArea,
    })
end

-- ── Drag system ───────────────────────────────────────────────
function Window:_SetupDrag()
    local drag, ds, sp = false, nil, nil
    local c1 = self._topbar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; sp = self._main.Position
        end
    end)
    local c2 = UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            self._main.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y
            )
        end
    end)
    local c3 = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    table.insert(self._conns, c1)
    table.insert(self._conns, c2)
    table.insert(self._conns, c3)
end

-- ── Control button logic ──────────────────────────────────────
function Window:_SetupControlBtns()
    self._minBtn.MouseEnter:Connect(function()
        U.Tween(self._minBtn, TI.Fast, {BackgroundColor3 = Color3.fromRGB(48, 48, 66)})
    end)
    self._minBtn.MouseLeave:Connect(function()
        U.Tween(self._minBtn, TI.Fast, {BackgroundColor3 = T.Bg3})
    end)
    self._minBtn.MouseButton1Click:Connect(function() self:_ToggleMinimize() end)

    self._closeBtn.MouseEnter:Connect(function()
        U.Tween(self._closeBtn, TI.Fast, {BackgroundColor3 = Color3.fromRGB(190, 44, 44),
                                          TextColor3       = Color3.new(1,1,1)})
    end)
    self._closeBtn.MouseLeave:Connect(function()
        U.Tween(self._closeBtn, TI.Fast, {BackgroundColor3 = T.Bg3, TextColor3 = T.TextSub})
    end)
    self._closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)
end

-- ── Search wiring ─────────────────────────────────────────────
function Window:_SetupSearch()
    self._searchBox.Focused:Connect(function()
        U.Tween(self._searchBar, TI.Fast, {BackgroundColor3 = Color3.fromRGB(36, 36, 52)})
        U.Stroke(self._searchBar, T.Accent, 1) -- highlight border
    end)
    self._searchBox.FocusLost:Connect(function()
        U.Tween(self._searchBar, TI.Fast, {BackgroundColor3 = T.Bg3})
        U.Stroke(self._searchBar, T.Border, 1)
    end)
    local c = self._searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self._activeTab then
            self._activeTab:_Filter(self._searchBox.Text:lower())
        end
    end)
    table.insert(self._conns, c)
end

-- ── Minimize / restore ────────────────────────────────────────
function Window:_ToggleMinimize()
    self._minimized = not self._minimized
    if self._minimized then
        U.Tween(self._main, TI.Def, {Size = UDim2.new(0, 720, 0, 52)})
        self._minBtn.Text = "□"
    else
        U.Tween(self._main, TI.Def, {Size = UDim2.new(0, 720, 0, 472)})
        self._minBtn.Text = "−"
    end
end

-- ── Tab switching ─────────────────────────────────────────────
function Window:_SwitchTab(tab)
    if self._activeTab == tab then return end
    if self._activeTab then self._activeTab:_Deactivate() end
    self._activeTab = tab
    tab:_Activate()
    self._searchBox.Text = ""
end

-- ── Public API ────────────────────────────────────────────────
function Window:CreateTab(name, icon)
    local tab = Tab.new(self, name, icon)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_SwitchTab(tab) end
    return tab
end

function Window:Destroy()
    U.Tween(self._main, TI.Def, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
    task.delay(0.3, function()
        for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
        for _, t in ipairs(self._tabs) do
            for _, c in ipairs(t._conns) do pcall(function() c:Disconnect() end) end
        end
        if self._sg and self._sg.Parent then self._sg:Destroy() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- §8  PUBLIC API  (the table returned to the caller)
-- ═══════════════════════════════════════════════════════════════

local FluentHub  = {}
FluentHub.__index = FluentHub

function FluentHub.new()
    local self    = setmetatable({}, FluentHub)
    self._notif   = NotifManager.new()
    return self
end

--[[
    FluentHub:CreateWindow(hubName, gameName)
    ─────────────────────────────────────────
    Shows the loading screen, then creates and reveals the main
    window. Returns a proxy so callers can chain :CreateTab() etc.
    immediately – calls queue until the window is ready.
]]
function FluentHub:CreateWindow(hubName, gameName)
    local win = nil

    CreateLoadingScreen(hubName or "FluentHub", function()
        win = Window.new(hubName, gameName, self._notif)
    end)

    -- Transparent proxy – method calls are forwarded to `win`
    -- once the loading screen completes. This lets user code
    -- write synchronous-looking chains immediately after
    -- :CreateWindow() without needing to await a Promise.
    local proxy = {}
    local proxyMT = {
        __index = function(_, k)
            -- Spin until the window is constructed
            while not win do task.wait(0.05) end
            local v = win[k]
            if type(v) == "function" then
                -- Re-bind `self` to the real window instance
                return function(s, ...)
                    if s == proxy then
                        return v(win, ...)
                    else
                        return v(s, ...)
                    end
                end
            end
            return v
        end,
        __newindex = function(_, k, v)
            while not win do task.wait(0.05) end
            win[k] = v
        end,
    }
    return setmetatable(proxy, proxyMT)
end

--[[
    FluentHub:Notify(title, body, duration, kind)
    ─────────────────────────────────────────────
    kind: "info" | "success" | "warning" | "error"
]]
function FluentHub:Notify(title, body, duration, kind)
    self._notif:Push(title, body, duration, kind)
end

-- ═══════════════════════════════════════════════════════════════
-- §9  ENTRY POINT
-- ═══════════════════════════════════════════════════════════════

return FluentHub.new()

--[[
╔══════════════════════════════════════════════════════════════╗
║  FULL USAGE EXAMPLE                                          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  local Hub = loadstring(...)()                               ║
║                                                              ║
║  local Win = Hub:CreateWindow("Nova Hub", "Brookhaven")      ║
║                                                              ║
║  -- ── Tab 1 ──────────────────────────────────────────── ── ║
║  local Combat = Win:CreateTab("Combat", "⚔")                 ║
║                                                              ║
║  Combat:CreateSection("Movement")                            ║
║                                                              ║
║  local speedSlider = Combat:CreateSlider(                    ║
║      "Walk Speed", 16, 200, 16,                              ║
║      function(v)                                             ║
║          game.Players.LocalPlayer.Character                  ║
║              .Humanoid.WalkSpeed = v                         ║
║      end                                                     ║
║  )                                                           ║
║                                                              ║
║  Combat:CreateToggle("Infinite Jump", false, function(on)    ║
║      -- toggle logic here                                    ║
║  end)                                                        ║
║                                                              ║
║  Combat:CreateSection("Targeting")                           ║
║                                                              ║
║  Combat:CreateDropdown(                                      ║
║      "Aimbot Target",                                        ║
║      {"Head","Torso","HumanoidRootPart"},                    ║
║      "Head",                                                 ║
║      function(v) print("Target:", v) end                     ║
║  )                                                           ║
║                                                              ║
║  Combat:CreateKeybind(                                       ║
║      "Toggle Aimbot",                                        ║
║      Enum.KeyCode.CapsLock,                                  ║
║      function(k) print("Fired by", k.Name) end               ║
║  )                                                           ║
║                                                              ║
║  -- ── Tab 2 ────────────────────────────────────────────── ║
║  local Misc = Win:CreateTab("Misc", "⚙")                    ║
║                                                              ║
║  Misc:CreateButton("Rejoin Server", function()               ║
║      game:GetService("TeleportService")                      ║
║          :Teleport(game.PlaceId)                             ║
║  end)                                                        ║
║                                                              ║
║  -- ── Notifications ──────────────────────────────────── ── ║
║  Hub:Notify("Nova Hub", "Loaded successfully!", 4, "success")║
║  Hub:Notify("Warning",  "Anti-cheat detected!", 5, "warning")║
║  Hub:Notify("Error",    "Script failed to run", 4, "error")  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
]]
