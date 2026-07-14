--[[
	===========================================================
	 ZILI HUB ENGINE — UI LIBRARY  (v2)
	 Modular Desktop UI Library for Roblox (Production Automation Hub)
	 Theme: Yellow / Black, Cyber-Minimal — fully re-themeable at runtime
	 ===========================================================
]]

local Players          = game:GetService("Players")
local TextService      = game:GetService("TextService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Debris           = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}
Library.__index = Library

--====================================================
-- THEME (mutable at runtime via Custom UI tab)
--====================================================
local Theme = {
	Background = Color3.fromRGB(15, 15, 17),
	Panel      = Color3.fromRGB(23, 23, 26),
	PanelLight = Color3.fromRGB(32, 32, 36),
	Accent     = Color3.fromRGB(240, 180, 41),
	AccentDim  = Color3.fromRGB(122, 92, 10),
	AccentMuted = Color3.fromRGB(196, 168, 112),
	Text       = Color3.fromRGB(241, 241, 243),
	MutedText  = Color3.fromRGB(168, 168, 174),
	Stroke     = Color3.fromRGB(255, 255, 255),
	Danger     = Color3.fromRGB(220, 70, 70),
	BackgroundImageTransparency = 0.45,
}

-- BuilderSans is Roblox's newer clean/geometric UI font (closer to the
-- reference look than Gotham). Resolved through a safe fallback: if the
-- exact enum name doesn't exist on some client (e.g. an older Roblox
-- version, or if a bold/black variant is actually named differently than
-- guessed here), this falls back to the proven Gotham family instead of
-- throwing "X is not a valid member of Font" and breaking the whole hub.
local function safeFont(name, fallback)
	local ok, result = pcall(function() return Enum.Font[name] end)
	return (ok and result) or fallback
end

local FONT       = safeFont("BuilderSansMedium", Enum.Font.GothamMedium)
local FONT_BOLD  = safeFont("BuilderSansBold", Enum.Font.GothamBold)
local FONT_BLACK = safeFont("BuilderSansExtraBold", Enum.Font.GothamBlack)
-- Monospace for numeric/technical readouts (Stat cards, FPS) — the
-- reference site loads JetBrains Mono for exactly this kind of data
-- display; Enum.Font.Code is Roblox's closest stable built-in equivalent.
local FONT_MONO = safeFont("Code", Enum.Font.Code)
print(("[ZiliHub] Font resolved: FONT=%s FONT_BOLD=%s FONT_BLACK=%s FONT_MONO=%s"):format(FONT.Name, FONT_BOLD.Name, FONT_BLACK.Name, FONT_MONO.Name))

--====================================================
-- PERFORMANCE / QUALITY SYSTEM
-- The hub is meant to sit on top of an already-heavy game, so it should
-- never be the thing that tips the client into a slideshow. "Auto" mode
-- watches real Heartbeat frame time and scales animation cost down when
-- the game itself is already struggling, then scales back up once frames
-- recover — no manual babysitting needed. Power users can still pin a
-- fixed level from the Performance tab.
--====================================================
local Quality = { Mode = "Auto", Resolved = "High" }
local QUALITY_TWEEN_SCALE = { High = 1, Balanced = 0.65, Low = 0 } -- 0 = snap instantly, skip TweenService entirely
local QualityListeners = {}

local function currentQuality()
	return Quality.Mode ~= "Auto" and Quality.Mode or Quality.Resolved
end

local function setQualityMode(mode)
	Quality.Mode = mode
	for _, fn in ipairs(QualityListeners) do task.spawn(fn, currentQuality()) end
end

local function setQualityResolved(level)
	if Quality.Resolved == level then return end
	Quality.Resolved = level
	if Quality.Mode == "Auto" then
		for _, fn in ipairs(QualityListeners) do task.spawn(fn, level) end
	end
end

local function onQualityChanged(fn) table.insert(QualityListeners, fn) end

-- Cheap exponential moving average of FPS, always running (not just in
-- Auto mode) so the Performance tab has a live number to show. No table
-- allocations, just one float updated per Heartbeat.
local LiveFPS = 60
RunService.Heartbeat:Connect(function(dt)
	if dt > 0 then
		LiveFPS = LiveFPS + ((1 / dt) - LiveFPS) * 0.1
	end
end)

-- Rolling FPS sample: averaged over ~60 Heartbeats (roughly 1s at 60fps,
-- longer if the game is already slow) so a single hitch doesn't flip
-- quality back and forth. Only runs the math while Mode == "Auto".
do
	local samples, accum = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		if Quality.Mode ~= "Auto" or dt <= 0 then return end
		samples = samples + 1
		accum = accum + dt
		if samples >= 60 then
			local avgFps = samples / accum
			samples, accum = 0, 0
			if avgFps < 24 then
				setQualityResolved("Low")
			elseif avgFps < 42 then
				setQualityResolved("Balanced")
			else
				setQualityResolved("High")
			end
		end
	end)
end

--====================================================
-- LIVE THEME BINDING SYSTEM
-- Every themed instance registers { Instance, Property, Role }.
-- Changing Theme.X and calling refreshTheme() updates everything
-- on screen instantly — this is what was missing before.
--====================================================
local ThemeBindings = {}

local function bindTheme(instance, property, role)
	table.insert(ThemeBindings, { Instance = instance, Property = property, Role = role })
	instance[property] = Theme[role]
	return instance
end

local function refreshTheme()
	for i = #ThemeBindings, 1, -1 do
		local b = ThemeBindings[i]
		if b.Instance and b.Instance.Parent then
			b.Instance[b.Property] = Theme[b.Role]
		else
			table.remove(ThemeBindings, i)
		end
	end
end

-- Long-running hubs create/destroy a lot of rows (dropdown lists, dynamic
-- tabs, config reloads). Without this, ThemeBindings only ever gets swept
-- when the user opens Custom UI and touches a color — everything else sits
-- in the table holding a hard reference to a destroyed Instance forever.
task.spawn(function()
	while true do
		task.wait(30)
		for i = #ThemeBindings, 1, -1 do
			local b = ThemeBindings[i]
			if not (b.Instance and b.Instance.Parent) then table.remove(ThemeBindings, i) end
		end
	end
end)

--====================================================
-- LOCALIZATION
--====================================================
local Localization = {
	en = {
		Dashboard = "Dashboard", AutoFarm = "Auto farm", Analytics = "Analytics", Settings = "Settings",
		Config = "Config", CustomUI = "Custom UI", LocalizationTab = "Localization",
		SearchPlaceholder = "Search settings, tasks...",
		Accent = "Accent", Background = "Background", Panel = "Panel",
		BackgroundImage = "Background image", BackgroundImageDesc = "Paste a decal or image asset id",
		SaveConfig = "Save configuration", ResetTheme = "Reset theme",
		Performance = "Performance", QualityMode = "Quality mode",
		QualityDesc = "Auto lowers animation quality automatically if the game's frame rate drops.",
		LiveFPS = "Live frame rate", ThemePresets = "Theme presets",
	},
	vi = {
		Dashboard = "Bảng điều khiển", AutoFarm = "Tự động cày", Analytics = "Phân tích", Settings = "Cài đặt",
		Config = "Cấu hình", CustomUI = "Tùy chỉnh giao diện", LocalizationTab = "Ngôn ngữ",
		SearchPlaceholder = "Tìm cài đặt, tác vụ...",
		Accent = "Màu nhấn", Background = "Nền", Panel = "Bảng",
		BackgroundImage = "Ảnh nền", BackgroundImageDesc = "Dán asset id ảnh hoặc decal",
		SaveConfig = "Lưu cấu hình", ResetTheme = "Khôi phục giao diện",
		Performance = "Hiệu năng", QualityMode = "Chế độ chất lượng",
		QualityDesc = "Auto sẽ tự động giảm chất lượng hiệu ứng nếu FPS của game bị tụt.",
		LiveFPS = "FPS hiện tại", ThemePresets = "Bộ giao diện có sẵn",
	},
}
local CurrentLang = "en"
-- Weak keys: once an instance is destroyed and dropped elsewhere, Lua can
-- actually collect it instead of this table holding it alive forever.
local LocaleBindings = setmetatable({}, { __mode = "k" })
local function L(key) return (Localization[CurrentLang] and Localization[CurrentLang][key]) or key end
local function bindLocale(instance, key)
	LocaleBindings[instance] = key
	instance.Text = L(key)
end
local function refreshLocale()
	for instance, key in pairs(LocaleBindings) do
		if instance and instance.Parent then instance.Text = L(key) else LocaleBindings[instance] = nil end
	end
end

--====================================================
-- LOW-LEVEL UTILITY
--====================================================
local Utility = {}

function Utility.Create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do inst[prop] = value end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

function Utility.Corner(radius) return Utility.Create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }) end

function Utility.Stroke(color, thickness, transparency)
	return Utility.Create("UIStroke", { Color = color or Theme.Stroke, Thickness = thickness or 1, Transparency = transparency or 0.88, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function Utility.Padding(all)
	return Utility.Create("UIPadding", { PaddingTop = UDim.new(0, all), PaddingBottom = UDim.new(0, all), PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all) })
end

-- A fake "Completed" signal for the instant-apply (Low quality) path, so
-- every existing call site that does `Utility.Tween(...).Completed:Wait()`
-- or `:Connect(...)` keeps working without special-casing quality itself.
local function instantSignalStub()
	return {
		Wait = function() end,
		Connect = function(_, fn)
			if fn then task.spawn(fn) end
			return { Disconnect = function() end }
		end,
	}
end

function Utility.Tween(instance, props, duration, style, direction)
	local scale = QUALITY_TWEEN_SCALE[currentQuality()] or 1
	if scale <= 0 then
		-- Low quality: write the end values directly, no TweenService
		-- object, no per-frame interpolation cost at all.
		for prop, value in pairs(props) do instance[prop] = value end
		return { Completed = instantSignalStub() }
	end
	local info = TweenInfo.new((duration or 0.2) * scale, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, info, props)
	tween:Play()
	return tween
end

-- Hover feedback as a translucent overlay instead of swapping the real
-- BackgroundColor3. Any button whose base color is theme-bound can safely
-- use this: refreshTheme() writes the base color directly and will never
-- race against / get fought by a hover tween again, no matter what color
-- the user picks via Custom UI.
function Utility.AddHoverDarken(button, amount, cornerRadius)
	amount = amount or 0.15
	local Overlay -- created lazily on first hover
	local function ensureOverlay()
		if Overlay then return Overlay end
		Overlay = Utility.Create("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1, ZIndex = (button.ZIndex or 1) + 1, Parent = button,
		})
		if cornerRadius then Utility.Corner(cornerRadius).Parent = Overlay end
		return Overlay
	end
	button.MouseEnter:Connect(function() Utility.Tween(ensureOverlay(), { BackgroundTransparency = 1 - amount }, 0.15) end)
	button.MouseLeave:Connect(function()
		if Overlay then Utility.Tween(Overlay, { BackgroundTransparency = 1 }, 0.15) end
	end)
end

-- Momentary highlight flash (used by search-reveal) via a throwaway overlay,
-- instead of tweening the instance's own BackgroundColor3. Rows use `card()`,
-- which theme-binds BackgroundColor3 to "Panel" — tweening that property
-- directly races refreshTheme() the same way the old hover-darken bug did:
-- if the theme changes mid-flash, the tween's captured end-color is stale
-- and the row visibly gets stuck on the wrong color. An overlay sidesteps
-- the bound property entirely, so it can never get stuck.
function Utility.FlashHighlight(instance, color, cornerRadius)
	local Overlay = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = 1,
		ZIndex = (instance.ZIndex or 1) + 1, Parent = instance,
	})
	if cornerRadius then Utility.Corner(cornerRadius).Parent = Overlay end
	Utility.Tween(Overlay, { BackgroundTransparency = 0.55 }, 0.15)
	task.delay(0.4, function()
		if not Overlay.Parent then return end
		local fade = Utility.Tween(Overlay, { BackgroundTransparency = 1 }, 0.3)
		fade.Completed:Wait()
		if Overlay.Parent then Overlay:Destroy() end
	end)
end

--====================================================
-- CENTRAL RENDERSTEPPED BUS (one connection for the whole hub)
--====================================================
local RenderBus = {}
local renderBusConn = nil
local function pushRenderBus(fn) table.insert(RenderBus, fn); return fn end
local function popRenderBus(fn)
	for i = #RenderBus, 1, -1 do if RenderBus[i] == fn then table.remove(RenderBus, i); break end end
end
local function ensureRenderBus()
	if renderBusConn then return end
	renderBusConn = RunService.RenderStepped:Connect(function(dt)
		for _, fn in ipairs(RenderBus) do fn(dt) end
	end)
end

--====================================================
-- VECTOR ICON SET
-- Hand-built with Frames/UIStroke/rotation instead of imported
-- image assets — guarantees consistent style, no broken icons,
-- and avoids generic "brand" glyphs.
--====================================================
local Icons = {}

local function iconBase(size)
	return Utility.Create("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 })
end

-- Dashboard: 2x2 grid of rounded squares
-- Dashboard: 2x2 grid of outlined rounded squares (Lucide "layout-dashboard" style)
-- Dashboard: matches Lucide's "layout-dashboard" rect layout exactly
-- (tall-left, short-top-right, tall-bottom-right, short-bottom-left)
function Icons.dashboard(size, color)
	size = size or 18
	local root = iconBase(size)
	local u = size / 24
	local rects = {
		{ x = 3, y = 3, w = 7, h = 9 },
		{ x = 14, y = 3, w = 7, h = 5 },
		{ x = 14, y = 12, w = 7, h = 9 },
		{ x = 3, y = 16, w = 7, h = 5 },
	}
	for _, r in ipairs(rects) do
		Utility.Create("Frame", {
			Size = UDim2.fromOffset(r.w * u, r.h * u),
			Position = UDim2.fromOffset(r.x * u, r.y * u),
			BackgroundTransparency = 1,
		}, { Utility.Corner(2), Utility.Stroke(color, 1.6, 0) }).Parent = root
	end
	return root
end

-- Auto farm: crossed swords (Lucide "swords" style) — shorter blades than a
-- corner-to-corner X (which reads too much like the Close glyph at 18px),
-- plus a crossguard near each tip and a pommel dot at the handle end so it
-- unmistakably reads as swords rather than a close/X icon.
function Icons.swords(size, color)
	size = size or 18
	local root = iconBase(size)
	for _, angle in ipairs({ -45, 45 }) do
		local rad = math.rad(angle)
		Utility.Create("Frame", {
			Size = UDim2.fromScale(0.72, 0.1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Rotation = angle, BackgroundColor3 = color,
		}, { Utility.Corner(2) }).Parent = root

		-- Crossguard sits near the blade tip, not the center, so it reads
		-- as a hilt rather than just thickening the middle of an X.
		local gx, gy = 0.5 + math.cos(rad) * 0.3, 0.5 + math.sin(rad) * 0.3
		Utility.Create("Frame", {
			Size = UDim2.fromScale(0.06, 0.24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(gx, gy),
			Rotation = angle + 90, BackgroundColor3 = color,
		}, { Utility.Corner(2) }).Parent = root

		-- Pommel dot at the opposite (handle) end
		local px, py = 0.5 - math.cos(rad) * 0.38, 0.5 - math.sin(rad) * 0.38
		Utility.Create("Frame", {
			Size = UDim2.fromScale(0.13, 0.13), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(px, py),
			BackgroundColor3 = color,
		}, { Utility.Corner(6) }).Parent = root
	end
	return root
end

-- Auto farm (legacy): lightning bolt (two overlapping rotated rectangles)
function Icons.bolt(size, color)
	size = size or 18
	local root = iconBase(size)
	local top = Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.34, size * 0.6),
		Position = UDim2.fromScale(0.58, 0.05),
		AnchorPoint = Vector2.new(0.5, 0),
		Rotation = 18, BackgroundColor3 = color,
	}, { Utility.Corner(2) })
	top.Parent = root
	local bottom = Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.34, size * 0.6),
		Position = UDim2.fromScale(0.42, 0.95),
		AnchorPoint = Vector2.new(0.5, 1),
		Rotation = 18, BackgroundColor3 = color,
	}, { Utility.Corner(2) })
	bottom.Parent = root
	return root
end

-- Analytics: ascending bar chart, outline style (Lucide "bar-chart-3")
function Icons.chart(size, color)
	size = size or 18
	local root = iconBase(size)
	local heights = { 0.4, 0.7, 1.0 }
	local barW = size * 0.2
	local gap = size * 0.12
	for i, h in ipairs(heights) do
		Utility.Create("Frame", {
			Size = UDim2.fromOffset(barW, size * h),
			Position = UDim2.new(0, (i - 1) * (barW + gap), 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
		}, { Utility.Corner(2), Utility.Stroke(color, 1.6, 0) }).Parent = root
	end
	return root
end

-- Settings: gear/flower (Lucide "settings" style) — ring with rounded
-- petal-shaped teeth around it, plus a center circle sized to match
-- Lucide's actual proportions (radius 3 out of a 24 viewBox).
-- Crosshair/target — used for section headers like "Targeting".
function Icons.target(size, color)
	size = size or 16
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.82, 0.82), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	}, { Utility.Corner(1000), Utility.Stroke(color, 1.4, 0.1) }).Parent = root
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.16, 0.16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = color,
	}, { Utility.Corner(1000) }).Parent = root
	for _, spec in ipairs({
		{ Size = UDim2.fromScale(0.08, 0.2), Pos = UDim2.fromScale(0.5, 0.02) },
		{ Size = UDim2.fromScale(0.08, 0.2), Pos = UDim2.fromScale(0.5, 0.98) },
		{ Size = UDim2.fromScale(0.2, 0.08), Pos = UDim2.fromScale(0.02, 0.5) },
		{ Size = UDim2.fromScale(0.2, 0.08), Pos = UDim2.fromScale(0.98, 0.5) },
	}) do
		Utility.Create("Frame", {
			Size = spec.Size, AnchorPoint = Vector2.new(0.5, 0.5), Position = spec.Pos, BackgroundColor3 = color,
		}, { Utility.Corner(2) }).Parent = root
	end
	return root
end

-- Toast notification glyphs: check (Success), alert (Warning/Error — shape
-- is the same for both, color already tells them apart), info (Info).
function Icons.check(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.35, 0.1), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.36, 0.58), Rotation = 45, BackgroundColor3 = color,
	}, { Utility.Corner(1) }).Parent = root
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.62, 0.1), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.6, 0.42), Rotation = -45, BackgroundColor3 = color,
	}, { Utility.Corner(1) }).Parent = root
	return root
end

function Icons.alert(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.14, 0.42), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36), BackgroundColor3 = color,
	}, { Utility.Corner(2) }).Parent = root
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.14, 0.14), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.8), BackgroundColor3 = color,
	}, { Utility.Corner(4) }).Parent = root
	return root
end

function Icons.info(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.14, 0.14), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.22), BackgroundColor3 = color,
	}, { Utility.Corner(4) }).Parent = root
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.14, 0.42), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62), BackgroundColor3 = color,
	}, { Utility.Corner(2) }).Parent = root
	return root
end

function Icons.settings(size, color)
	size = size or 18
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.56, size * 0.56), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1,
	}, { Utility.Corner(size), Utility.Stroke(color, 2, 0) }).Parent = root

	local cx, cy = size / 2, size / 2
	local petalSize = size * 0.2
	for i = 0, 5 do
		local angle = math.rad(i * 60 + 15)
		local px = cx + math.cos(angle) * (size * 0.4)
		local py = cy + math.sin(angle) * (size * 0.4)
		Utility.Create("Frame", {
			Size = UDim2.fromOffset(petalSize, petalSize), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(px, py), BackgroundColor3 = color,
		}, { Utility.Corner(4) }).Parent = root
	end

	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.25, size * 0.25), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = color,
	}, { Utility.Corner(size) }).Parent = root
	return root
end

function Icons.search(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.62, size * 0.62), Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
	}, { Utility.Corner(size), Utility.Stroke(color, 1.6, 0) }).Parent = root
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.42, 1.6),
		Position = UDim2.fromOffset(size * 0.46, size * 0.78), Rotation = 45,
		BackgroundColor3 = color,
	}).Parent = root
	return root
end

-- Close (X) and minimize (—) drawn as vector shapes — avoids relying on a
-- text glyph ("✕") that doesn't render consistently on every font/device.
function Icons.close(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.86, 1.3), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Rotation = 45, BackgroundColor3 = color,
	}, { Utility.Corner(1) }).Parent = root
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.86, 1.3), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Rotation = -45, BackgroundColor3 = color,
	}, { Utility.Corner(1) }).Parent = root
	return root
end

function Icons.minimize(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.8, 1.3), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.72), BackgroundColor3 = color,
	}, { Utility.Corner(1) }).Parent = root
	return root
end

-- Maximize: single square outline (Lucide "square" style)
function Icons.maximize(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.7, size * 0.7), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1,
	}, { Utility.Corner(2), Utility.Stroke(color, 1.2, 0.1) }).Parent = root
	return root
end

-- Restore: two overlapping square outlines — the universal "un-maximize"
-- glyph. Positioned with Scale + AnchorPoint (not Offset) specifically
-- because this icon gets stretched to fill a 30x30 button in the TopBar
-- (Size overridden to UDim2.fromScale(1,1)); Offset-based children don't
-- scale with that stretch and end up squashed into a corner instead of
-- staying centered — that was the rendering bug.
function Icons.restore(size, color)
	size = size or 14
	local root = iconBase(size)
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.55, 0.55), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.66, 0.34), BackgroundTransparency = 1,
	}, { Utility.Corner(2), Utility.Stroke(color, 1.1, 0.1) }).Parent = root
	Utility.Create("Frame", {
		Size = UDim2.fromScale(0.55, 0.55), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.4, 0.62), BackgroundTransparency = 1,
	}, { Utility.Corner(2), Utility.Stroke(color, 1.1, 0.1) }).Parent = root
	return root
end

-- Reset: circular arrow (Lucide "rotate-ccw" style) — a ring with a gap
-- plus a small arrowhead, built from a stroked circle + two short bars.
function Icons.reset(size, color)
	size = size or 16
	local root = iconBase(size)
	local Ring = Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.7, size * 0.7), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1,
	}, { Utility.Corner(size), Utility.Stroke(color, 1.6, 0.25) })
	Ring.Parent = root
	-- Arrowhead suggesting rotation direction
	local Arrow = Utility.Create("Frame", {
		Size = UDim2.fromOffset(size * 0.2, size * 0.2), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.82, 0.22), Rotation = 45, BackgroundColor3 = color,
	})
	Arrow.Parent = root
	return root
end

-- Normalizes a pasted asset id: accepts "123456", "rbxassetid://123456",
-- or a full asset URL, and always returns the "rbxassetid://123456" form.
local function normalizeAssetId(input)
	input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if input == "" then return "" end
	if input:match("^rbxassetid://%d+$") then return input end
	local digits = input:match("(%d+)")
	if digits then return "rbxassetid://" .. digits end
	return input
end

local IconBuilders = {
	dashboard = Icons.dashboard,
	bolt = Icons.bolt,
	swords = Icons.swords,
	chart = Icons.chart,
	settings = Icons.settings,
	target = Icons.target,
}

--====================================================
-- ROOT SCREENGUI
--====================================================
local ScreenGui = Utility.Create("ScreenGui", {
	Name = "ZiliHubEngine", ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100, Parent = PlayerGui,
})

--====================================================
-- LOADING SCREEN  (adapted from reference: letter reveal,
-- floating embers, gradient progress bar, cycling status text)
--====================================================
local function buildLoadingScreen(titleWord, statusLines)
	titleWord = titleWord or "ZILI"
	statusLines = statusLines or { "initializing core...", "loading modules...", "ready." }

	-- Reuse a single named BlurEffect instead of stacking duplicates if
	-- this ever runs more than once — duplicate PostEffects compound their
	-- blur strength and quietly leak Lighting children over time.
	local Blur = Lighting:FindFirstChild("ZiliHubBlur")
	if not Blur then
		Blur = Instance.new("BlurEffect")
		Blur.Name = "ZiliHubBlur"
		Blur.Parent = Lighting
	end
	Blur.Size = 0
	-- Note: BlurEffect only affects the 3D viewport render — Roblox's own
	-- CoreGui (top menu, chat, currency display) is a separate compositor
	-- layer that no LocalScript can blur. That sharp strip at the very top
	-- of the screen during loading is expected Roblox behavior, not a bug.

	local Overlay = Utility.Create("Frame", {
		Name = "LoadingOverlay", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background, BackgroundTransparency = 1,
		ZIndex = 1000, Parent = ScreenGui,
	})

	local EmberLayer = Utility.Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Overlay })

	-- Single fixed-size container holds title + bar + status together so
	-- spacing stays consistent across resolutions (no more giant gaps).
	local Center = Utility.Create("Frame", {
		Size = UDim2.fromOffset(360, 170), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46), BackgroundTransparency = 1, ZIndex = 1001, Parent = Overlay,
	})

	local letterSpacing = 38
	local TitleHolder = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1, Parent = Center,
	})

	local letters = {}
	local totalWidth = #titleWord * letterSpacing
	for i = 1, #titleWord do
		local ch = titleWord:sub(i, i)
		local LetterHolder = Utility.Create("Frame", {
			Size = UDim2.fromOffset(34, 56),
			Position = UDim2.new(0.5, (i - 1) * letterSpacing - totalWidth / 2 + letterSpacing / 2, 0, 30),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = TitleHolder,
		})
		local Label = Utility.Create("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = ch,
			Font = FONT_BLACK, TextSize = 36, TextColor3 = Theme.Text, TextTransparency = 1, Parent = LetterHolder,
		})
		local Glow = Utility.Create("UIStroke", { Thickness = 1.5, Color = Theme.Accent, Transparency = 1, Parent = Label })
		Utility.Create("UIGradient", {
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.AccentDim) }),
			Rotation = 45, Parent = Glow,
		})
		table.insert(letters, { Holder = LetterHolder, Label = Label, Glow = Glow, BaseY = 0 })
	end

	local function spawnEmber()
		local size = math.random(4, 8)
		local Ember = Utility.Create("Frame", {
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.new(math.random(20, 80) / 100, 0, 1.05, 0),
			BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.3, Parent = EmberLayer,
		}, { Utility.Corner(size) })
		local life = math.random(3, 5)
		Utility.Tween(Ember, {
			Position = UDim2.new(Ember.Position.X.Scale, math.random(-40, 40), -0.05, 0),
			BackgroundTransparency = 1,
		}, life, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		Debris:AddItem(Ember, life)
	end

	local BarTrack = Utility.Create("Frame", {
		Size = UDim2.fromOffset(240, 5), AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 100), BackgroundColor3 = Theme.PanelLight, BackgroundTransparency = 1, ZIndex = 1001, Parent = Center,
	}, { Utility.Corner(3) })
	local BarFill = Utility.Create("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, ZIndex = 1001, Parent = BarTrack,
	}, { Utility.Corner(3) })
	Utility.Create("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.AccentDim), ColorSequenceKeypoint.new(1, Theme.Accent) }),
		Parent = BarFill,
	})

	local StatusLabel = Utility.Create("TextLabel", {
		Size = UDim2.fromOffset(300, 20), Position = UDim2.new(0.5, 0, 0, 122), AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 13, TextColor3 = Theme.MutedText,
		TextTransparency = 1, ZIndex = 1001, Parent = Center,
	})

	local function run(onDone)
		local q = currentQuality()
		-- BlurEffect is a full-viewport post-process; skip it outright on
		-- Low instead of just tweening it faster, since the cost comes from
		-- the effect being active at all, not from how it animates in.
		if q ~= "Low" then
			Utility.Tween(Blur, { Size = 28 }, 1.2)
		end
		Utility.Tween(Overlay, { BackgroundTransparency = 0.45 }, 0.5)

		-- Ember spawn rate scales down with quality; skip entirely on Low
		-- so we're not creating/tweening/destroying Frames every frame on
		-- top of a game that's already struggling to hold its frame time.
		local emberChance = q == "Balanced" and 0.97 or 0.93
		local emberConn = pushRenderBus(function()
			if q ~= "Low" and math.random() > emberChance then spawnEmber() end
		end)
		ensureRenderBus()

		for i, letter in ipairs(letters) do
			task.wait(0.05)
			local startY = letter.Holder.Position.Y.Offset
			letter.Holder.Position = UDim2.new(letter.Holder.Position.X.Scale, letter.Holder.Position.X.Offset, 0, startY + 24)
			Utility.Tween(letter.Label, { TextTransparency = 0 }, 0.35)
			Utility.Tween(letter.Glow, { Transparency = 0.2 }, 0.35)
			Utility.Tween(letter.Holder, { Position = UDim2.new(letter.Holder.Position.X.Scale, letter.Holder.Position.X.Offset, 0, startY) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end

		task.wait(0.25)
		Utility.Tween(BarTrack, { BackgroundTransparency = 0.5 }, 0.35)
		Utility.Tween(StatusLabel, { TextTransparency = 0 }, 0.35)

		local segments = #statusLines
		for i, text in ipairs(statusLines) do
			StatusLabel.Text = text
			Utility.Tween(BarFill, { Size = UDim2.new(i / segments, 0, 1, 0) }, 0.55, Enum.EasingStyle.Quad)
			task.wait(0.55)
		end

		task.wait(0.35)
		popRenderBus(emberConn)

		for _, letter in ipairs(letters) do
			local y = letter.Holder.Position.Y.Offset
			Utility.Tween(letter.Holder, { Position = UDim2.new(letter.Holder.Position.X.Scale, letter.Holder.Position.X.Offset, 0, y - 30) }, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			Utility.Tween(letter.Label, { TextTransparency = 1 }, 0.4)
			Utility.Tween(letter.Glow, { Transparency = 1 }, 0.4)
			task.wait(0.03)
		end
		Utility.Tween(BarTrack, { BackgroundTransparency = 1 }, 0.35)
		Utility.Tween(BarFill, { BackgroundTransparency = 1 }, 0.35)
		Utility.Tween(StatusLabel, { TextTransparency = 1 }, 0.35)
		local fade = Utility.Tween(Overlay, { BackgroundTransparency = 1 }, 0.5)
		if q ~= "Low" then Utility.Tween(Blur, { Size = 0 }, 0.6) end

		fade.Completed:Wait()
		Overlay:Destroy()
		Blur:Destroy()
		if onDone then onDone() end
	end

	return run
end

--====================================================
-- MINIMIZED LOGO BUTTON (logo only, drag + click to restore)
--====================================================
local function buildMinimizedLogo(logoId, onRestore)
	-- Pure logo image, no circular backdrop/border — just the artwork,
	-- bigger than before so it reads clearly as a standalone icon.
	local LogoBtn = Utility.Create("ImageButton", {
		Name = "ZiliHubLogo", Size = UDim2.fromOffset(66, 66), Position = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1, Image = logoId, ScaleType = Enum.ScaleType.Fit,
		AutoButtonColor = false, Visible = false, ZIndex = 999, Parent = ScreenGui,
	})

	local dragging, dragStart, startPos, moved = false, nil, nil, false
	LogoBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart, startPos = input.Position, LogoBtn.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			moved = true
			local delta = input.Position - dragStart
			LogoBtn.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
		end
	end)
	local lastClickTime = 0
	LogoBtn.MouseButton1Click:Connect(function()
		if moved then return end
		local now = tick()
		if now - lastClickTime <= 0.35 then
			lastClickTime = 0
			onRestore()
		else
			lastClickTime = now
		end
	end)
	LogoBtn.MouseEnter:Connect(function() Utility.Tween(LogoBtn, { Size = UDim2.fromOffset(72, 72) }, 0.15) end)
	LogoBtn.MouseLeave:Connect(function() Utility.Tween(LogoBtn, { Size = UDim2.fromOffset(66, 66) }, 0.15) end)

	return LogoBtn
end

--====================================================
-- WINDOW (MAIN HUB)
--====================================================
function Library:CreateWindow(config)
	config = config or {}
	local LogoId = normalizeAssetId(config.LogoId) ~= "" and normalizeAssetId(config.LogoId) or "rbxassetid://129001357397487"

	local NORMAL_SIZE, MAXIMIZED_SIZE = UDim2.new(0.78, 0, 0.82, 0), UDim2.new(0.96, 0, 0.94, 0)
	local NORMAL_MAX, MAXIMIZED_MAX = Vector2.new(960, 640), Vector2.new(1500, 960)
	local isMaximized = false

	local SizeConstraint = Utility.Create("UISizeConstraint", { MinSize = Vector2.new(420, 360), MaxSize = NORMAL_MAX })
	local MainFrame = Utility.Create("Frame", {
		Name = "MainHub", Size = NORMAL_SIZE, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), ClipsDescendants = true, Visible = false, Parent = ScreenGui,
	}, {
		Utility.Corner(16), Utility.Stroke(Theme.Stroke, 1, 0.88), SizeConstraint,
	})
	bindTheme(MainFrame, "BackgroundColor3", "Background")

	-- Background layer order matters here: everything decorative goes
	-- BELOW BackgroundImage, so a custom image (set via Custom UI) blends
	-- OVER this moody base through its own ImageTransparency, instead of
	-- getting hidden underneath an opaque layer created after it.
	local DepthGradient = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(11, 15, 20), ZIndex = -3, Parent = MainFrame,
	}, { Utility.Corner(16) })
	Utility.Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 13, 18)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 17, 23)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 21, 29)),
		}),
		Rotation = 105, Parent = DepthGradient,
	})

	-- Blueprint / tech grid: a faint vector grid instead of soft color
	-- blobs — an "engineering HUD" feel that fits a hub/tool better than a
	-- marketing-page color wash, and is genuinely a different visual
	-- language, not just a recolor. Every line is Scale-positioned, so the
	-- grid automatically adapts to any window size (including the
	-- maximize/restore feature) with zero recomputation needed on resize.
	local GRID_COLS, GRID_ROWS = 9, 7
	for i = 1, GRID_COLS - 1 do
		local Line = Utility.Create("Frame", {
			Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(i / GRID_COLS, 0, 0, 0),
			BackgroundTransparency = 1, ZIndex = -2, Parent = MainFrame,
		})
		bindTheme(Line, "BackgroundColor3", "AccentMuted")
		Line.BackgroundTransparency = 0.94
	end
	for i = 1, GRID_ROWS - 1 do
		local Line = Utility.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, i / GRID_ROWS, 0),
			BackgroundTransparency = 1, ZIndex = -2, Parent = MainFrame,
		})
		bindTheme(Line, "BackgroundColor3", "AccentMuted")
		Line.BackgroundTransparency = 0.94
	end

	-- One focused accent glow (not scattered blobs) — like a single "power
	-- indicator" light source anchored at a corner, more restrained and
	-- purposeful than a multi-color wash.
	local FocusGlow = Utility.Create("Frame", {
		Size = UDim2.fromOffset(360, 360), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.05, 0.02),
		BackgroundTransparency = 0.87, ZIndex = -2, Parent = MainFrame,
	}, { Utility.Corner(180) })
	bindTheme(FocusGlow, "BackgroundColor3", "Accent")

	-- A couple of thin accent-colored "circuit trace" corner brackets —
	-- small, sharp, technical details rather than soft shapes. Two opposite
	-- corners (not all four) keeps it a deliberate accent, not clutter.
	local TraceTL_H = Utility.Create("Frame", { Size = UDim2.new(0, 90, 0, 1.5), Position = UDim2.fromOffset(0, 90), BackgroundTransparency = 0.55, ZIndex = -2, Parent = MainFrame })
	bindTheme(TraceTL_H, "BackgroundColor3", "AccentMuted")
	local TraceTL_V = Utility.Create("Frame", { Size = UDim2.new(0, 1.5, 0, 90), Position = UDim2.fromOffset(90, 0), BackgroundTransparency = 0.55, ZIndex = -2, Parent = MainFrame })
	bindTheme(TraceTL_V, "BackgroundColor3", "AccentMuted")
	local TraceBR_H = Utility.Create("Frame", { Size = UDim2.new(0, 90, 0, 1.5), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, -90), BackgroundTransparency = 0.55, ZIndex = -2, Parent = MainFrame })
	bindTheme(TraceBR_H, "BackgroundColor3", "AccentMuted")
	local TraceBR_V = Utility.Create("Frame", { Size = UDim2.new(0, 1.5, 0, 90), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -90, 1, 0), BackgroundTransparency = 0.55, ZIndex = -2, Parent = MainFrame })
	bindTheme(TraceBR_V, "BackgroundColor3", "AccentMuted")

	-- Subtle vignette: four corner-anchored gradients darken just the very
	-- edges, pulling focus toward the center content — a classic, cheap
	-- (fully static) "premium panel" trick. Sits above the grid/glow but
	-- still below BackgroundImage.
	for _, corner in ipairs({
		{ pos = UDim2.fromScale(0, 0), rot = 135 }, { pos = UDim2.fromScale(1, 0), rot = 225 },
		{ pos = UDim2.fromScale(0, 1), rot = 45 },  { pos = UDim2.fromScale(1, 1), rot = 315 },
	}) do
		local VignetteCorner = Utility.Create("Frame", {
			Size = UDim2.fromOffset(220, 220), AnchorPoint = Vector2.new(corner.pos.X.Scale, corner.pos.Y.Scale),
			Position = corner.pos, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = -1, Parent = MainFrame,
		})
		Utility.Create("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(1, 1) }),
			Rotation = corner.rot, Parent = VignetteCorner,
		})
	end

	local BackgroundImage = Utility.Create("ImageLabel", {
		Name = "CustomBackground", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "",
		ScaleType = Enum.ScaleType.Crop, ImageTransparency = Theme.BackgroundImageTransparency, ZIndex = 0, Parent = MainFrame,
	}, { Utility.Corner(16) })

	--==========================
	-- TOP BAR
	--==========================
	local TopBar = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 0.42, ZIndex = 5, Parent = MainFrame }, { Utility.Corner(16) })
	bindTheme(TopBar, "BackgroundColor3", "Panel")
	local TopBarMask = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BorderSizePixel = 0, Parent = TopBar })
	bindTheme(TopBarMask, "BackgroundColor3", "Panel")

	-- Thin accent hairline under the TopBar — a small, cheap detail (one
	-- Frame + one UIGradient, no extra connections) that reads as a much
	-- more "premium suite" separator than a flat border.
	local TopBarHairline = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 47), BorderSizePixel = 0, ZIndex = 2, Parent = MainFrame,
	})
	local HairlineGradient = Utility.Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = TopBarHairline,
	})
	bindTheme(TopBarHairline, "BackgroundColor3", "Accent")

	-- Soft static glow behind the logo — a small, one-time detail (no
	-- animation, no continuous cost) that reads as "brand", not just an icon.
	local LogoGlow = Utility.Create("Frame", {
		Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(9, 7),
		BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.82, Parent = TopBar,
	}, { Utility.Corner(17) })
	bindTheme(LogoGlow, "BackgroundColor3", "Accent")

	local LogoIcon = Utility.Create("ImageLabel", {
		Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(15, 13), BackgroundTransparency = 1, Image = LogoId, Parent = TopBar,
	})
	bindTheme(LogoIcon, "ImageColor3", "Accent")

	local TitleLabel = Utility.Create("TextLabel", {
		Size = UDim2.fromOffset(0, 48), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromOffset(46, 0), BackgroundTransparency = 1,
		Text = config.Title or "Zili Hub", Font = FONT_BLACK, TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
	})
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	local TitleGradient = Utility.Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.Accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}),
		Parent = TitleLabel,
	})
	Utility.Create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6, Parent = TitleLabel })

	-- Search bar — its left edge gets bound to the Sidebar's width below
	-- (once Sidebar exists) so it lines up exactly with where content rows
	-- like "Hub active" start, instead of trailing the title text.
	local SearchHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(230, 30), Position = UDim2.fromOffset(200, 9), Parent = TopBar }, { Utility.Corner(8) })
	bindTheme(SearchHolder, "BackgroundColor3", "PanelLight")
	Utility.Stroke(Theme.Stroke, 1, 0.85).Parent = SearchHolder
	local SearchIcon = Icons.search(13, Theme.Accent)
	SearchIcon.Position = UDim2.fromOffset(10, 9)
	SearchIcon.Parent = SearchHolder

	local SearchBox = Utility.Create("TextBox", {
		Size = UDim2.new(1, -38, 1, 0), Position = UDim2.fromOffset(32, 0), BackgroundTransparency = 1,
		PlaceholderText = L("SearchPlaceholder"), Text = "", Font = FONT, TextSize = 12,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = SearchHolder,
	})
	bindTheme(SearchBox, "TextColor3", "Text")
	SearchBox.PlaceholderColor3 = Theme.MutedText

	-- Minimize + Maximize/Restore + Close (vector icons, not text glyphs)
	local MinimizeBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -116, 0, 9), Text = "", Parent = TopBar }, { Utility.Corner(8) })
	bindTheme(MinimizeBtn, "BackgroundColor3", "PanelLight")
	local MinimizeIcon = Icons.minimize(14, Theme.MutedText)
	MinimizeIcon.Size = UDim2.fromScale(1, 1)
	MinimizeIcon.Parent = MinimizeBtn

	local MaximizeBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -78, 0, 9), Text = "", Parent = TopBar }, { Utility.Corner(8) })
	bindTheme(MaximizeBtn, "BackgroundColor3", "PanelLight")
	local MaximizeIcon = Icons.maximize(13, Theme.MutedText)
	MaximizeIcon.Size = UDim2.fromScale(1, 1)
	MaximizeIcon.Parent = MaximizeBtn

	local CloseBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -40, 0, 9), Text = "", Parent = TopBar }, { Utility.Corner(8) })
	bindTheme(CloseBtn, "BackgroundColor3", "PanelLight")
	local CloseIcon = Icons.close(13, Theme.MutedText)
	CloseIcon.Size = UDim2.fromScale(1, 1)
	CloseIcon.Parent = CloseBtn

	local function recolorIcon(iconRoot, color)
		for _, d in ipairs(iconRoot:GetDescendants()) do
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then d.BackgroundColor3 = color end
			if d:IsA("UIStroke") then d.Color = color end
		end
	end

	-- Toggles between the normal window size and a larger capped size —
	-- same "restore vs maximize" behavior as a desktop window. Swaps the
	-- UISizeConstraint's MaxSize too, so maximizing on a big monitor
	-- actually gets bigger instead of immediately hitting the old cap.
	local function setMaximized(state)
		isMaximized = state
		SizeConstraint.MaxSize = state and MAXIMIZED_MAX or NORMAL_MAX
		Utility.Tween(MainFrame, { Size = state and MAXIMIZED_SIZE or NORMAL_SIZE }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		MaximizeIcon:Destroy()
		MaximizeIcon = (state and Icons.restore or Icons.maximize)(13, Theme.MutedText)
		MaximizeIcon.Size = UDim2.fromScale(1, 1)
		MaximizeIcon.Parent = MaximizeBtn
	end
	MaximizeBtn.MouseButton1Click:Connect(function() setMaximized(not isMaximized) end)
	MaximizeBtn.MouseEnter:Connect(function() recolorIcon(MaximizeIcon, Theme.Text) end)
	MaximizeBtn.MouseLeave:Connect(function() recolorIcon(MaximizeIcon, Theme.MutedText) end)

	-- Hover feedback via overlay-darken, same fix as everywhere else: these
	-- buttons are theme-bound (PanelLight) so directly swapping their
	-- BackgroundColor3 on hover would race against refreshTheme() and get
	-- visually "stuck" the same way Reset Theme used to.
	local CloseOverlay = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Danger, BackgroundTransparency = 1, ZIndex = (CloseBtn.ZIndex or 1) + 1, Parent = CloseBtn,
	}, { Utility.Corner(8) })

	MinimizeBtn.MouseEnter:Connect(function() recolorIcon(MinimizeIcon, Theme.Text) end)
	MinimizeBtn.MouseLeave:Connect(function() recolorIcon(MinimizeIcon, Theme.MutedText) end)
	CloseBtn.MouseEnter:Connect(function()
		Utility.Tween(CloseOverlay, { BackgroundTransparency = 0 }, 0.18)
		recolorIcon(CloseIcon, Color3.new(1, 1, 1))
	end)
	CloseBtn.MouseLeave:Connect(function()
		Utility.Tween(CloseOverlay, { BackgroundTransparency = 1 }, 0.18)
		recolorIcon(CloseIcon, Theme.MutedText)
	end)

	do
		local dragging, dragStart, startPos = false, nil, nil
		local targetPos = nil

		local function pointInGui(pos, gui)
			local p, s = gui.AbsolutePosition, gui.AbsoluteSize
			return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
		end

		TopBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local pos = input.Position
				-- Clicks on the window controls / search box are handled by
				-- their own signals; don't also treat them as a drag.
				if pointInGui(pos, MinimizeBtn) or pointInGui(pos, MaximizeBtn) or pointInGui(pos, CloseBtn) or pointInGui(pos, SearchHolder) then
					return
				end
				dragging = true
				dragStart, startPos = pos, MainFrame.Position
				targetPos = startPos
			end
		end)

		-- Global listeners (not TopBar-scoped) so the drag never "sticks":
		-- a GuiObject's own InputChanged stops firing the moment the cursor
		-- leaves its bounds during a fast drag — UserInputService doesn't.
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)

		-- Apply on the shared RenderBus (one connection for the whole hub)
		-- instead of writing Position on every raw input event — smoother
		-- and cheaper than mutating layout properties dozens of times/sec.
		pushRenderBus(function()
			if dragging and targetPos then
				MainFrame.Position = targetPos
			end
		end)
		ensureRenderBus()
	end

	local LogoBubble
	local function restore()
		LogoBubble.Visible = false
		MainFrame.Visible = true
		MainFrame.Rotation = -12
		MainFrame.Size = UDim2.fromOffset(40, 40)
		MainFrame.Position = LogoBubble.Position
		Utility.Tween(MainFrame, { Size = isMaximized and MAXIMIZED_SIZE or NORMAL_SIZE, Rotation = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	LogoBubble = buildMinimizedLogo(LogoId, restore)

	MinimizeBtn.MouseButton1Click:Connect(function()
		local savedPos = MainFrame.Position
		local tween = Utility.Tween(MainFrame, {
			Size = UDim2.fromOffset(40, 40), Rotation = 12, Position = LogoBubble.Position,
		}, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween.Completed:Wait()
		MainFrame.Visible = false
		MainFrame.Rotation = 0
		MainFrame.Size = isMaximized and MAXIMIZED_SIZE or NORMAL_SIZE
		MainFrame.Position = savedPos
		LogoBubble.Visible = true
		Utility.Tween(LogoBubble, { Size = UDim2.fromOffset(76, 76) }, 0.12)
		task.delay(0.12, function() Utility.Tween(LogoBubble, { Size = UDim2.fromOffset(66, 66) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end)
	end)

	-- Close confirmation modal (Yes/No) instead of closing instantly
	local ConfirmOverlay = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Visible = false, ZIndex = 50, Parent = MainFrame,
	}, { Utility.Corner(16) })
	local ConfirmBox = Utility.Create("Frame", {
		Size = UDim2.fromOffset(280, 150), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 51, Parent = ConfirmOverlay,
	}, { Utility.Corner(12), Utility.Stroke(Theme.Stroke, 1, 0.85) })
	bindTheme(ConfirmBox, "BackgroundColor3", "Panel")

	-- Warning icon: a ring with an exclamation mark, tinted Danger
	local WarnIconHolder = Utility.Create("Frame", {
		Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16),
		BackgroundTransparency = 1, ZIndex = 51, Parent = ConfirmBox,
	}, { Utility.Corner(17), Utility.Stroke(Theme.Danger, 2, 0.15) })
	Utility.Create("Frame", { Size = UDim2.fromOffset(3, 12), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.2), BackgroundColor3 = Theme.Danger, ZIndex = 51, Parent = WarnIconHolder }, { Utility.Corner(2) })
	Utility.Create("Frame", { Size = UDim2.fromOffset(3, 3), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.68), BackgroundColor3 = Theme.Danger, ZIndex = 51, Parent = WarnIconHolder }, { Utility.Corner(2) })

	local ConfirmText = Utility.Create("TextLabel", {
		Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 58), BackgroundTransparency = 1,
		Text = "Close the hub?", Font = FONT_BOLD, TextSize = 15, TextWrapped = true, ZIndex = 51, Parent = ConfirmBox,
	})
	bindTheme(ConfirmText, "TextColor3", "Text")
	local ConfirmSubtext = Utility.Create("TextLabel", {
		Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(12, 80), BackgroundTransparency = 1,
		Text = "This will fully shut down the UI.", Font = FONT, TextSize = 11, TextWrapped = true, ZIndex = 51, Parent = ConfirmBox,
	})
	bindTheme(ConfirmSubtext, "TextColor3", "MutedText")

	local YesBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(118, 36), Position = UDim2.fromOffset(12, 102), AutoButtonColor = false, Font = FONT_BOLD, Text = "Yes", TextSize = 13, ZIndex = 51, Parent = ConfirmBox }, { Utility.Corner(8) })
	YesBtn.BackgroundColor3 = Theme.Danger
	YesBtn.TextColor3 = Color3.new(1, 1, 1)
	Utility.AddHoverDarken(YesBtn, 0.15, 8)

	local NoBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(118, 36), Position = UDim2.new(1, -130, 0, 102), AutoButtonColor = false, Font = FONT_BOLD, Text = "No", TextSize = 13, ZIndex = 51, Parent = ConfirmBox }, { Utility.Corner(8) })
	bindTheme(NoBtn, "BackgroundColor3", "PanelLight")
	bindTheme(NoBtn, "TextColor3", "Text")
	Utility.AddHoverDarken(NoBtn, 0.1, 8)

	CloseBtn.MouseButton1Click:Connect(function()
		ConfirmOverlay.Visible = true
		ConfirmBox.Size = UDim2.fromOffset(252, 135)
		Utility.Tween(ConfirmOverlay, { BackgroundTransparency = 0.4 }, 0.15)
		Utility.Tween(ConfirmBox, { Size = UDim2.fromOffset(280, 150) }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	NoBtn.MouseButton1Click:Connect(function()
		local fade = Utility.Tween(ConfirmOverlay, { BackgroundTransparency = 1 }, 0.15)
		fade.Completed:Wait()
		ConfirmOverlay.Visible = false
	end)
	YesBtn.MouseButton1Click:Connect(function()
		ConfirmOverlay.Visible = false
		local tween = Utility.Tween(MainFrame, { Size = UDim2.fromOffset(0, 0), Rotation = 8 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween.Completed:Wait()
		MainFrame.Visible = false
	end)

	--==========================
	-- SIDEBAR + CONTENT AREA
	--==========================
	local Sidebar = Utility.Create("Frame", { Size = UDim2.new(0.22, 0, 1, -48), Position = UDim2.fromOffset(0, 48), BackgroundTransparency = 0.42, Parent = MainFrame }, {
		Utility.Create("UISizeConstraint", { MinSize = Vector2.new(150, 0), MaxSize = Vector2.new(220, math.huge) }),
		Utility.Corner(16),
	})
	bindTheme(Sidebar, "BackgroundColor3", "Panel")
	Utility.Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Sidebar })
	Utility.Padding(14).Parent = Sidebar

	local ContentArea = Utility.Create("Frame", { Size = UDim2.new(1, 0, 1, -48), Position = UDim2.fromOffset(0, 48), BackgroundTransparency = 1, ClipsDescendants = true, Parent = MainFrame }, { Utility.Corner(16) })
	local function repositionContentArea()
		ContentArea.Position = UDim2.new(0, Sidebar.AbsoluteSize.X, 0, 48)
		ContentArea.Size = UDim2.new(1, -Sidebar.AbsoluteSize.X, 1, -48)
		-- Search bar lines up with the same left edge as content rows,
		-- and shrinks responsively so it never reaches the window buttons
		local availableWidth = TopBar.AbsoluteSize.X - (Sidebar.AbsoluteSize.X + 16) - 100
		SearchHolder.Position = UDim2.fromOffset(Sidebar.AbsoluteSize.X + 16, 9)
		SearchHolder.Size = UDim2.fromOffset(math.clamp(availableWidth, 120, 260), 30)
	end
	Sidebar:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionContentArea)
	TopBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionContentArea)
	task.defer(repositionContentArea)

	local Window = setmetatable({
		ScreenGui = ScreenGui, MainFrame = MainFrame, Sidebar = Sidebar, ContentArea = ContentArea,
		BackgroundImage = BackgroundImage, Tabs = {}, ActiveTabButton = nil, SearchIndex = {},
	}, Library)

	-- Sidebar collapse-to-icons: a small chevron pinned to the bottom-left,
	-- parented to MainFrame (not Sidebar) so it's never swept into
	-- Sidebar's own UIListLayout alongside the tab buttons. ContentArea and
	-- the search bar already auto-follow Sidebar's width via the
	-- AbsoluteSize listener above — collapsing needs no extra wiring there.
	local sidebarCollapsed = false
	local NORMAL_SIDEBAR_SIZE = UDim2.new(0.22, 0, 1, -48)
	local COLLAPSED_SIDEBAR_SIZE = UDim2.new(0, 64, 1, -48)

	local CollapseBtn = Utility.Create("TextButton", {
		Size = UDim2.fromOffset(24, 24), Position = UDim2.new(0, 5, 1, -34), Text = "", Parent = MainFrame, ZIndex = 2,
	}, { Utility.Corner(6) })
	bindTheme(CollapseBtn, "BackgroundColor3", "PanelLight")
	local function buildChevron(pointingLeft)
		local Icon = Utility.Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = CollapseBtn })
		Utility.Create("Frame", {
			Size = UDim2.fromOffset(7, 1.3), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(pointingLeft and 0.42 or 0.58, 0.38), Rotation = pointingLeft and -40 or 40, BackgroundColor3 = Theme.MutedText,
		}, { Utility.Corner(1) }).Parent = Icon
		Utility.Create("Frame", {
			Size = UDim2.fromOffset(7, 1.3), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(pointingLeft and 0.42 or 0.58, 0.62), Rotation = pointingLeft and 40 or -40, BackgroundColor3 = Theme.MutedText,
		}, { Utility.Corner(1) }).Parent = Icon
		return Icon
	end
	local ChevronIcon = buildChevron(true)
	Utility.AddHoverDarken(CollapseBtn, 0.1, 6)

	local function setSidebarCollapsed(state)
		sidebarCollapsed = state
		Utility.Tween(Sidebar, { Size = state and COLLAPSED_SIDEBAR_SIZE or NORMAL_SIDEBAR_SIZE }, 0.22)
		for _, t in ipairs(Window.Tabs) do
			Utility.Tween(t.Label, { TextTransparency = state and 1 or 0 }, 0.15)
		end
		ChevronIcon:Destroy()
		ChevronIcon = buildChevron(not state)
	end
	CollapseBtn.MouseButton1Click:Connect(function() setSidebarCollapsed(not sidebarCollapsed) end)

	--==========================
	-- TOAST NOTIFICATIONS
	-- Stack lives directly on ScreenGui (not MainFrame) so a toast can
	-- still be seen even while the hub is minimized to its logo bubble.
	--==========================
	local NotifyLayer = Utility.Create("Frame", {
		Size = UDim2.fromOffset(300, 1), AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
		BackgroundTransparency = 1, ZIndex = 500, Parent = ScreenGui,
	})
	Utility.Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = NotifyLayer })

	local NOTIFY_COLORS = {
		Info = "Accent", Success = Color3.fromRGB(90, 200, 130),
		Warning = Color3.fromRGB(230, 175, 60), Error = "Danger",
	}
	local NOTIFY_ICONS = { Info = Icons.info, Success = Icons.check, Warning = Icons.alert, Error = Icons.alert }

	-- opts: { Title, Message, Type = "Info"|"Success"|"Warning"|"Error", Duration }
	function Window:Notify(opts)
		opts = opts or {}
		local kindColor = NOTIFY_COLORS[opts.Type] or NOTIFY_COLORS.Info
		local resolvedColor = typeof(kindColor) == "string" and Theme[kindColor] or kindColor

		local Toast = Utility.Create("Frame", {
			Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			ClipsDescendants = true, Parent = NotifyLayer,
		}, { Utility.Corner(10), Utility.Stroke(Theme.Stroke, 1, 0.85), Utility.Padding(12) })
		bindTheme(Toast, "BackgroundColor3", "Panel")

		local AccentBar = Utility.Create("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundTransparency = 1, Parent = Toast }, { Utility.Corner(2) })
		if typeof(kindColor) == "string" then bindTheme(AccentBar, "BackgroundColor3", kindColor) else AccentBar.BackgroundColor3 = kindColor end
		AccentBar.BackgroundTransparency = 0

		local IconHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(14, 1), BackgroundTransparency = 1, Parent = Toast })
		local iconBuilder = NOTIFY_ICONS[opts.Type] or NOTIFY_ICONS.Info
		local Glyph = iconBuilder(14, resolvedColor)
		Glyph.Size = UDim2.fromScale(1, 1)
		Glyph.Parent = IconHolder

		local TextHolder = Utility.Create("Frame", {
			Size = UDim2.new(1, -38, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.fromOffset(38, 0), BackgroundTransparency = 1, Parent = Toast,
		})
		Utility.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TextHolder })

		local Title = Utility.Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = opts.Title or "Notification",
			Font = FONT_BOLD, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TextHolder,
		})
		bindTheme(Title, "TextColor3", "Text")

		if opts.Message and opts.Message ~= "" then
			local Msg = Utility.Create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
				TextWrapped = true, Text = opts.Message, Font = FONT, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = TextHolder,
			})
			bindTheme(Msg, "TextColor3", "MutedText")
		end

		-- Slide in from the right + fade, hold, then slide out + fade.
		Toast.Position = UDim2.fromOffset(40, 0)
		Utility.Tween(Toast, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.05 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		task.delay(opts.Duration or 3.5, function()
			if not Toast.Parent then return end
			local fade = Utility.Tween(Toast, { Position = UDim2.fromOffset(40, 0), BackgroundTransparency = 1 }, 0.18)
			fade.Completed:Wait()
			if Toast.Parent then Toast:Destroy() end
		end)

		return Toast
	end

	--==========================
	-- SHARED COLOR PICKER MODAL
	-- A single modal lives directly under MainFrame (built last, so it's
	-- naturally the top-most sibling — no cross-branch ZIndex tricks).
	-- Every CreateColorPicker swatch reuses this one instance instead of
	-- spawning its own floating popup, which is what caused both the
	-- "overlaps other rows" and "can't click the picker" bugs.
	--==========================
	local ColorScrim = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Visible = false, ZIndex = 60, Parent = MainFrame,
	}, { Utility.Corner(16) })
	local ColorScrimBtn = Utility.Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 60, Parent = ColorScrim })

	local ColorBox = Utility.Create("Frame", {
		Size = UDim2.fromOffset(220, 312), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 61, Parent = ColorScrim,
	}, { Utility.Corner(12), Utility.Stroke(Theme.Stroke, 1, 0.8), Utility.Padding(14) })
	bindTheme(ColorBox, "BackgroundColor3", "PanelLight")

	local ColorTitle = Utility.Create("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61, Parent = ColorBox })
	bindTheme(ColorTitle, "TextColor3", "Text")

	local CSVSquare = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 150), Position = UDim2.fromOffset(0, 26), BackgroundColor3 = Color3.fromHSV(0, 1, 1), ZIndex = 61, Parent = ColorBox }, { Utility.Corner(8) })
	local CWhiteOverlay = Utility.Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 62, Parent = CSVSquare }, { Utility.Corner(8) })
	Utility.Create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = CWhiteOverlay })
	local CBlackOverlay = Utility.Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 63, Parent = CSVSquare }, { Utility.Corner(8) })
	Utility.Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }), Parent = CBlackOverlay })
	local CSVCursor = Utility.Create("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0), BackgroundTransparency = 1, ZIndex = 64, Parent = CSVSquare }, { Utility.Stroke(Color3.new(1, 1, 1), 2, 0) })

	local CHueTrack = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 184), ZIndex = 61, Parent = ColorBox }, { Utility.Corner(8) })
	do
		local stops = {}
		for h = 0, 6 do table.insert(stops, ColorSequenceKeypoint.new(h / 6, Color3.fromHSV(h / 6, 1, 1))) end
		Utility.Create("UIGradient", { Color = ColorSequence.new(stops), Parent = CHueTrack })
	end
	local CHueCursor = Utility.Create("Frame", { Size = UDim2.fromOffset(4, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 62, Parent = CHueTrack }, { Utility.Corner(2), Utility.Stroke(Color3.new(0, 0, 0), 1, 0.4) })

	local CHexBox = Utility.Create("TextBox", { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 212), Text = "", Font = FONT, TextSize = 13, ClearTextOnFocus = false, ZIndex = 61, Parent = ColorBox }, { Utility.Corner(6) })
	bindTheme(CHexBox, "BackgroundColor3", "Panel")
	bindTheme(CHexBox, "TextColor3", "Text")

	local CCancelBtn = Utility.Create("TextButton", { Size = UDim2.new(0.46, 0, 0, 32), Position = UDim2.fromOffset(0, 252), AutoButtonColor = false, Font = FONT, TextSize = 13, Text = "Cancel", ZIndex = 61, Parent = ColorBox }, { Utility.Corner(6) })
	bindTheme(CCancelBtn, "BackgroundColor3", "Panel")
	bindTheme(CCancelBtn, "TextColor3", "MutedText")

	local COkBtn = Utility.Create("TextButton", { Size = UDim2.new(0.46, 0, 0, 32), Position = UDim2.new(0.54, 0, 0, 252), AutoButtonColor = false, Font = FONT_BOLD, TextSize = 13, Text = "OK", ZIndex = 61, Parent = ColorBox }, { Utility.Corner(6) })
	bindTheme(COkBtn, "BackgroundColor3", "Accent")
	bindTheme(COkBtn, "TextColor3", "Background")
	COkBtn.MouseEnter:Connect(function() Utility.Tween(COkBtn, { BackgroundColor3 = Theme.AccentDim }, 0.15) end)
	COkBtn.MouseLeave:Connect(function() Utility.Tween(COkBtn, { BackgroundColor3 = Theme.Accent }, 0.15) end)
	CCancelBtn.MouseEnter:Connect(function() Utility.Tween(CCancelBtn, { BackgroundColor3 = Theme.PanelLight }, 0.15) end)
	CCancelBtn.MouseLeave:Connect(function() Utility.Tween(CCancelBtn, { BackgroundColor3 = Theme.Panel }, 0.15) end)

	-- Dragging the SV square / hue strip only updates the LIVE PREVIEW
	-- inside the modal (square, cursor, hex). The actual Theme write +
	-- refreshTheme() + user callback only fire once OK is pressed —
	-- that's "commit". Cancel / clicking outside discards the preview.
	local colorModalState = { hue = 0, sat = 0, val = 0, onApply = nil }

	local function colorModalPreview()
		local newColor = Color3.fromHSV(colorModalState.hue, colorModalState.sat, colorModalState.val)
		local hex = string.format("#%02X%02X%02X", math.floor(newColor.R * 255 + 0.5), math.floor(newColor.G * 255 + 0.5), math.floor(newColor.B * 255 + 0.5))
		CHexBox.Text = hex
		CSVSquare.BackgroundColor3 = Color3.fromHSV(colorModalState.hue, 1, 1)
		CSVCursor.Position = UDim2.fromScale(colorModalState.sat, 1 - colorModalState.val)
		CHueCursor.Position = UDim2.fromScale(colorModalState.hue, 0.5)
		return newColor
	end

	local function closeColorModal()
		ColorScrim.Visible = false
	end

	function Window:OpenColorPicker(title, startColor, onApply)
		colorModalState.hue, colorModalState.sat, colorModalState.val = Color3.toHSV(startColor)
		colorModalState.onApply = onApply
		ColorTitle.Text = title or "Edit color"
		colorModalPreview()
		ColorScrim.Visible = true
		ColorScrim.BackgroundTransparency = 1
		Utility.Tween(ColorScrim, { BackgroundTransparency = 0.45 }, 0.15)
	end

	local draggingSV, draggingHue = false, false
	CSVSquare.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true end end)
	CHueTrack.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true end end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSV, draggingHue = false, false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if draggingSV then
			colorModalState.sat = math.clamp((i.Position.X - CSVSquare.AbsolutePosition.X) / CSVSquare.AbsoluteSize.X, 0, 1)
			colorModalState.val = 1 - math.clamp((i.Position.Y - CSVSquare.AbsolutePosition.Y) / CSVSquare.AbsoluteSize.Y, 0, 1)
			colorModalPreview()
		elseif draggingHue then
			colorModalState.hue = math.clamp((i.Position.X - CHueTrack.AbsolutePosition.X) / CHueTrack.AbsoluteSize.X, 0, 1)
			colorModalPreview()
		end
	end)
	CHexBox.FocusLost:Connect(function()
		local hexStr = CHexBox.Text:gsub("#", "")
		if #hexStr == 6 and hexStr:match("^%x+$") then
			local r, g, b = tonumber(hexStr:sub(1, 2), 16), tonumber(hexStr:sub(3, 4), 16), tonumber(hexStr:sub(5, 6), 16)
			colorModalState.hue, colorModalState.sat, colorModalState.val = Color3.toHSV(Color3.fromRGB(r, g, b))
			colorModalPreview()
		end
	end)

	-- The modal now closes ONLY via OK / Cancel. There is deliberately no
	-- "click outside to close" anymore — that's what kept causing the
	-- picker to slam shut whenever a drag-release happened to land past
	-- the SV square / hue strip edge, no matter how the misfire was
	-- patched at the input-event level. ColorScrimBtn stays Active (so it
	-- still blocks clicks from reaching the sidebar/tabs behind it) but
	-- has no click handler — clicking it is now a harmless no-op.
	CCancelBtn.MouseButton1Click:Connect(closeColorModal)
	COkBtn.MouseButton1Click:Connect(function()
		local finalColor = colorModalPreview()
		if colorModalState.onApply then colorModalState.onApply(finalColor) end
		closeColorModal()
	end)

	--==========================
	-- SHARED CONFIRMATION MODAL
	-- Same pattern as the color picker: one modal built once, reused by
	-- every caller (e.g. "Reset to defaults") instead of each spot building
	-- its own popup. Use for anything destructive/irreversible.
	--==========================
	local ConfirmScrim = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Visible = false, ZIndex = 70, Parent = MainFrame,
	}, { Utility.Corner(16) })
	Utility.Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 70, Parent = ConfirmScrim })

	local ConfirmBox = Utility.Create("Frame", {
		Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), ZIndex = 71, Parent = ConfirmScrim,
	}, { Utility.Corner(12), Utility.Stroke(Theme.Stroke, 1, 0.85), Utility.Padding(18) })
	bindTheme(ConfirmBox, "BackgroundColor3", "PanelLight")

	local ConfirmTitle = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 71, Parent = ConfirmBox,
	})
	bindTheme(ConfirmTitle, "TextColor3", "Text")

	local ConfirmMessage = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(0, 24),
		BackgroundTransparency = 1, Font = FONT, TextSize = 13, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 71, Parent = ConfirmBox,
	})
	bindTheme(ConfirmMessage, "TextColor3", "MutedText")

	local ConfirmBtnRow = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 56), BackgroundTransparency = 1, ZIndex = 71, Parent = ConfirmBox })
	local ConfirmCancelBtn = Utility.Create("TextButton", { Size = UDim2.new(0.46, 0, 1, 0), AutoButtonColor = false, Font = FONT, TextSize = 13, Text = "Cancel", ZIndex = 71, Parent = ConfirmBtnRow }, { Utility.Corner(7) })
	bindTheme(ConfirmCancelBtn, "BackgroundColor3", "Panel")
	bindTheme(ConfirmCancelBtn, "TextColor3", "MutedText")
	local ConfirmOkBtn = Utility.Create("TextButton", { Size = UDim2.new(0.46, 0, 1, 0), Position = UDim2.new(0.54, 0, 0, 0), AutoButtonColor = false, Font = FONT_BOLD, TextSize = 13, Text = "Confirm", ZIndex = 71, Parent = ConfirmBtnRow }, { Utility.Corner(7) })
	bindTheme(ConfirmOkBtn, "TextColor3", "Background")
	Utility.AddHoverDarken(ConfirmCancelBtn, 0.08, 7)
	Utility.AddHoverDarken(ConfirmOkBtn, 0.12, 7)

	local confirmOnAccept = nil
	local function closeConfirm() ConfirmScrim.Visible = false end
	ConfirmCancelBtn.MouseButton1Click:Connect(closeConfirm)
	ConfirmOkBtn.MouseButton1Click:Connect(function()
		local cb = confirmOnAccept
		closeConfirm()
		if cb then task.spawn(cb) end
	end)

	-- opts: { Title, Message, ConfirmText, CancelText, Danger (bool), OnConfirm }
	function Window:Confirm(opts)
		opts = opts or {}
		ConfirmTitle.Text = opts.Title or "Are you sure?"
		ConfirmMessage.Text = opts.Message or ""
		ConfirmOkBtn.Text = opts.ConfirmText or "Confirm"
		ConfirmCancelBtn.Text = opts.CancelText or "Cancel"
		ConfirmOkBtn.BackgroundColor3 = opts.Danger and Theme.Danger or Theme.Accent
		confirmOnAccept = opts.OnConfirm
		ConfirmScrim.Visible = true
		ConfirmScrim.BackgroundTransparency = 1
		Utility.Tween(ConfirmScrim, { BackgroundTransparency = 0.45 }, 0.15)
	end

	--==========================
	-- SHARED TOOLTIP
	-- One bubble for the entire hub, reused/repositioned per hover instead
	-- of creating a new label per tooltip — attaching tooltips to dozens of
	-- rows still costs exactly one extra Instance, not one each.
	--==========================
	local TooltipBubble = Utility.Create("TextLabel", {
		Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 0.05,
		Font = FONT, TextSize = 12, Visible = false, ZIndex = 200, Parent = MainFrame,
	}, { Utility.Corner(6), Utility.Padding(8) })
	bindTheme(TooltipBubble, "BackgroundColor3", "PanelLight")
	bindTheme(TooltipBubble, "TextColor3", "Text")

	-- Attach a hover tooltip to any GuiObject inside this hub.
	function Window:AddTooltip(instance, text)
		instance.MouseEnter:Connect(function()
			TooltipBubble.Text = text
			TooltipBubble.Visible = true
		end)
		instance.MouseMoved:Connect(function(x, y)
			local base = MainFrame.AbsolutePosition
			TooltipBubble.Position = UDim2.fromOffset(x - base.X + 14, y - base.Y + 14)
		end)
		instance.MouseLeave:Connect(function() TooltipBubble.Visible = false end)
	end

	-- Search preview list: shows up to 6 matches as you type instead of
	-- silently jumping straight to whichever happened to match first.
	local SearchPreview = Utility.Create("Frame", {
		Size = UDim2.fromOffset(280, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(0, 38), Visible = false, ZIndex = 50, Parent = SearchHolder,
	}, { Utility.Corner(8), Utility.Stroke(Theme.Stroke, 1, 0.85), Utility.Padding(6) })
	bindTheme(SearchPreview, "BackgroundColor3", "PanelLight")
	Utility.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = SearchPreview })

	local function closeSearchPreview() SearchPreview.Visible = false end

	local function showSearchPreview(query)
		for _, c in ipairs(SearchPreview:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local shown = 0
		for _, entry in ipairs(Window.SearchIndex) do
			if shown >= 6 then break end
			if entry.KeywordsLower:find(query, 1, true) then
				shown = shown + 1
				local OptBtn = Utility.Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 26), AutoButtonColor = false, Font = FONT, TextSize = 12,
					Text = "  " .. entry.Keywords, TextXAlignment = Enum.TextXAlignment.Left, Parent = SearchPreview,
				}, { Utility.Corner(5) })
				bindTheme(OptBtn, "TextColor3", "Text")
				Utility.AddHoverDarken(OptBtn, 0.12, 5)
				OptBtn.MouseButton1Click:Connect(function()
					entry.Reveal()
					closeSearchPreview()
					SearchBox.Text = ""
				end)
			end
		end
		SearchPreview.Visible = shown > 0
		return shown > 0
	end

	-- Self-contained outside-click-close (not the shared dropdown registry
	-- near CreateDropdown — that's declared later in the file than this
	-- closure, so it isn't visible as an upvalue here).
	UserInputService.InputBegan:Connect(function(input)
		if not SearchPreview.Visible then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local pos, p, s = input.Position, SearchHolder.AbsolutePosition, SearchHolder.AbsoluteSize
		if not (pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y) then
			closeSearchPreview()
		end
	end)

	local searchQueued = false
	local searchNoResults = nil
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if searchQueued then return end
		searchQueued = true
		task.defer(function()
			searchQueued = false
			local query = SearchBox.Text:lower()
			if searchNoResults then searchNoResults.Visible = false end
			if query == "" then closeSearchPreview(); return end
			local found = showSearchPreview(query)
			if not found then
				-- Give feedback instead of silently doing nothing — the
				-- label is created lazily once and just reused/repositioned.
				if not searchNoResults then
					searchNoResults = Utility.Create("TextLabel", {
						Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
						Position = UDim2.new(0, 340, 0, 14), BackgroundTransparency = 1,
						Font = FONT, TextSize = 12, Text = "No results found", ZIndex = 3, Parent = TopBar,
					})
					bindTheme(searchNoResults, "TextColor3", "MutedText")
				end
				searchNoResults.Visible = true
			end
		end)
	end)

	return Window
end

--====================================================
-- TAB (sidebar entry, top-level) — now takes an icon kind:
-- "dashboard" | "bolt" | "chart" | "settings"
--====================================================
-- Remembers which tab was last active across sessions (opt-in via
-- Window:RestoreLastTab(), called once after all CreateTab calls). Kept
-- self-contained here (own filename, own availability check) rather than
-- reusing the config manager's file helpers, since those are declared
-- later in the file than CreateTab and wouldn't be visible as upvalues yet.
local LASTTAB_FILE = "ZiliHub_LastTab.txt"
local function lastTabIOAvailable()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end
local function saveLastTabIndex(index)
	if not lastTabIOAvailable() then return end
	pcall(writefile, LASTTAB_FILE, tostring(index))
end
local function loadLastTabIndex()
	if not lastTabIOAvailable() then return nil end
	local ok1, exists = pcall(isfile, LASTTAB_FILE)
	if not ok1 or not exists then return nil end
	local ok2, raw = pcall(readfile, LASTTAB_FILE)
	if not ok2 then return nil end
	return tonumber(raw)
end

-- Cascading entrance for the first ~14 rows when a tab/subtab page becomes
-- visible. Uses UIScale (a separate transform layer) + BackgroundTransparency
-- rather than Position — UIListLayout re-asserts every child's Position on
-- every layout pass, so animating Position directly would just get fought
-- and snapped back, the same class of bug as the theme-color race elsewhere
-- in this file. Capped at 14 rows so opening a huge tab doesn't visibly
-- trickle in for a long time or spawn dozens of tweens at once.
local STAGGER_CAP = 14
local function staggerReveal(container)
	local i = 0
	for _, row in ipairs(container:GetChildren()) do
		if row:IsA("Frame") or row:IsA("TextButton") then
			i = i + 1
			if i > STAGGER_CAP then break end
			local scaleObj = Utility.Create("UIScale", { Scale = 0.94, Parent = row })
			local originalTransparency = row.BackgroundTransparency
			row.BackgroundTransparency = 1
			task.delay((i - 1) * 0.025, function()
				if not row.Parent then return end
				Utility.Tween(row, { BackgroundTransparency = originalTransparency }, 0.18)
				Utility.Tween(scaleObj, { Scale = 1 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				task.delay(0.25, function() if scaleObj.Parent then scaleObj:Destroy() end end)
			end)
		end
	end
end

function Library:CreateTab(name, iconKind)
	local Sidebar, ContentArea, Window = self.Sidebar, self.ContentArea, self

	local Button = Utility.Create("TextButton", { Size = UDim2.new(1, 0, 0, 38), AutoButtonColor = false, Text = "", Parent = Sidebar }, { Utility.Corner(8) })
	bindTheme(Button, "BackgroundColor3", "Panel")

	-- Active-state highlight lives on its own overlay rather than tweening
	-- Button's own theme-bound BackgroundColor3 — avoids the "tween fights
	-- refreshTheme(), ends up stuck on a stale color" bug class (see
	-- AddHoverDarken / FlashHighlight above).
	local ActiveHighlight = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Button,
	}, { Utility.Corner(8) })
	bindTheme(ActiveHighlight, "BackgroundColor3", "PanelLight")
	Utility.AddHoverDarken(Button, 0.05, 8)

	-- Small accent bar on the left edge of the active tab — grows in/out
	-- from the middle, a common "premium sidebar" detail.
	local Indicator = Utility.Create("Frame", {
		Size = UDim2.new(0, 3, 0, 0), Position = UDim2.fromOffset(0, 19), AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1, Parent = Button,
	}, { Utility.Corner(2) })
	bindTheme(Indicator, "BackgroundColor3", "Accent")

	local IconHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(12, 10), BackgroundTransparency = 1, Parent = Button })
	local builder = IconBuilders[iconKind] or IconBuilders.dashboard
	local IconGlyph = builder(18, Theme.MutedText)
	IconGlyph.Size = UDim2.fromScale(1, 1)
	IconGlyph.Parent = IconHolder
	-- True path-morphing isn't really feasible for these vector-Frame icons
	-- without a lot of per-icon custom work — a quick scale "pop" via
	-- UIScale is the cheap, general-purpose stand-in for "the icon feels
	-- alive when it becomes active" instead of a flat instant color swap.
	local IconScale = Utility.Create("UIScale", { Scale = 1, Parent = IconHolder })

	-- "Live" indicator — a small pulsing dot on the icon corner, e.g. to
	-- show "Auto farm is currently running" without needing to open the
	-- tab. Toggled via Tab:SetLive(true/false); the pulse loop only runs
	-- while actually visible, so an unused hub pays nothing for this.
	local LiveDot = Utility.Create("Frame", {
		Size = UDim2.fromOffset(7, 7), Position = UDim2.fromOffset(23, 6), BackgroundColor3 = Theme.Accent,
		Visible = false, ZIndex = 3, Parent = Button,
	}, { Utility.Corner(4) })
	bindTheme(LiveDot, "BackgroundColor3", "Accent")
	local livePulsing = false
	local function setLive(state)
		LiveDot.Visible = state
		if state and not livePulsing then
			livePulsing = true
			task.spawn(function()
				while LiveDot.Visible and LiveDot.Parent do
					local t1 = Utility.Tween(LiveDot, { BackgroundTransparency = 0.65 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					t1.Completed:Wait()
					if not (LiveDot.Visible and LiveDot.Parent) then break end
					local t2 = Utility.Tween(LiveDot, { BackgroundTransparency = 0 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					t2.Completed:Wait()
				end
				livePulsing = false
			end)
		end
	end

	local Label = Utility.Create("TextLabel", {
		Size = UDim2.new(1, -42, 1, 0), Position = UDim2.fromOffset(40, 0), BackgroundTransparency = 1,
		Text = name, Font = FONT, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Button,
	})
	bindTheme(Label, "TextColor3", "MutedText")

	local function setIconColor(color)
		for _, d in ipairs(IconGlyph:GetDescendants()) do
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then d.BackgroundColor3 = color end
			if d:IsA("UIStroke") then d.Color = color end
		end
	end

	local Page = Utility.Create("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = ContentArea })

	local SubTabStrip = Utility.Create("Frame", { Size = UDim2.new(1, -32, 0, 34), Position = UDim2.fromOffset(16, 10), BackgroundTransparency = 1, Visible = false, Parent = Page })
	Utility.Create("UIListLayout", { Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = SubTabStrip })

	local SubTabBody = Utility.Create("Frame", { Size = UDim2.new(1, 0, 1, -44), Position = UDim2.fromOffset(0, 44), BackgroundTransparency = 1, Parent = Page })
	local FlatScroll = Utility.Create("ScrollingFrame", {
		Size = UDim2.new(1, -8, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = SubTabBody,
	})
	bindTheme(FlatScroll, "ScrollBarImageColor3", "Accent")
	Utility.Create("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder, Parent = FlatScroll })
	Utility.Padding(16).Parent = FlatScroll

	local function activate()
		if Window.ActiveTabButton == Button then return end
		for _, t in ipairs(Window.Tabs) do
			if t.Button ~= Button then
				Utility.Tween(t.ActiveHighlight, { BackgroundTransparency = 1 }, 0.18)
				Utility.Tween(t.Indicator, { Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1 }, 0.18)
				Utility.Tween(t.Label, { TextColor3 = Theme.MutedText }, 0.18)
				t.SetIconColor(Theme.MutedText)
				if t.Page.Visible then
					Utility.Tween(t.Page, { GroupTransparency = 1, Position = UDim2.fromScale(-0.03, 0) }, 0.16)
					task.delay(0.16, function() t.Page.Visible = false end)
				end
			end
		end
		Utility.Tween(ActiveHighlight, { BackgroundTransparency = 0 }, 0.18)
		Utility.Tween(Indicator, { Size = UDim2.new(0, 3, 0, 20), BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		Utility.Tween(Label, { TextColor3 = Theme.Accent }, 0.18)
		setIconColor(Theme.Accent)
		IconScale.Scale = 0.8
		Utility.Tween(IconScale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		Page.Visible = true
		Page.Position = UDim2.fromScale(0.03, 0)
		Page.GroupTransparency = 1
		Utility.Tween(Page, { GroupTransparency = 0, Position = UDim2.fromScale(0, 0) }, 0.22)
		staggerReveal(FlatScroll)
		Window.ActiveTabButton = Button
	end

	local Tab = {
		Window = Window, Button = Button, Label = Label, Page = Page, ActiveHighlight = ActiveHighlight, Indicator = Indicator,
		SubTabStrip = SubTabStrip, SubTabBody = SubTabBody, ContentPage = FlatScroll,
		SubTabs = {}, ActiveSubTabButton = nil, Activate = activate, SetIconColor = setIconColor, SetLive = setLive,
	}
	table.insert(Window.Tabs, Tab)
	local tabIndex = #Window.Tabs
	if tabIndex == 1 then task.defer(activate) end

	Button.MouseButton1Click:Connect(function()
		activate()
		saveLastTabIndex(tabIndex) -- only on a deliberate click, not the auto-open of tab 1
	end)

	function Tab:CreateSubTab(subName)
		SubTabStrip.Visible = true
		FlatScroll.Visible = false
		local Pill = Utility.Create("TextButton", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, AutoButtonColor = false, Text = "", Parent = SubTabStrip }, { Utility.Corner(7) })
		bindTheme(Pill, "BackgroundColor3", "PanelLight")
		local PillLabel = Utility.Create("TextLabel", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "  " .. subName .. "  ", Font = FONT, TextSize = 12, Parent = Pill })
		bindTheme(PillLabel, "TextColor3", "MutedText")

		local SubPage = Utility.Create("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = SubTabBody,
		})
		bindTheme(SubPage, "ScrollBarImageColor3", "Accent")
		Utility.Create("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder, Parent = SubPage })
		Utility.Padding(16).Parent = SubPage

		local function activateSub()
			if Tab.ActiveSubTabButton == Pill then return end
			for _, s in ipairs(Tab.SubTabs) do
				Utility.Tween(s.Pill, { BackgroundColor3 = Theme.PanelLight }, 0.15)
				Utility.Tween(s.Label, { TextColor3 = Theme.MutedText }, 0.15)
				s.SubPage.Visible = false
			end
			Utility.Tween(Pill, { BackgroundColor3 = Theme.AccentDim }, 0.15)
			Utility.Tween(PillLabel, { TextColor3 = Theme.Accent }, 0.15)
			SubPage.Visible = true
			staggerReveal(SubPage)
			Tab.ActiveSubTabButton = Pill
		end
		Pill.MouseButton1Click:Connect(activateSub)
		table.insert(Tab.SubTabs, { Pill = Pill, Label = PillLabel, SubPage = SubPage, Activate = activateSub })
		if #Tab.SubTabs == 1 then task.defer(activateSub) end

		local SubTabObj = { Page = SubPage, Window = Window }
		setmetatable(SubTabObj, { __index = Library.SectionFactory })
		return SubTabObj
	end

	setmetatable(Tab, { __index = Library.SectionFactory })
	return Tab
end

-- Call once after all Window:CreateTab(...) calls, e.g.:
--   Window:RestoreLastTab()
-- Restores whichever tab the user last clicked into, across sessions.
-- Silently does nothing if no file was saved yet or file I/O isn't
-- available in this environment.
function Library:RestoreLastTab()
	local idx = loadLastTabIndex()
	local tab = idx and self.Tabs[idx]
	if tab then tab.Activate() end
end

--====================================================
-- SECTION + COMPONENT FACTORY
--====================================================
Library.SectionFactory = {}

-- Tracks how many sections exist per content area so we can add breathing
-- room *between* logical groups without also padding the very first one
-- against the top edge. Weak-keyed so it doesn't outlive destroyed tabs.
local SectionCounts = setmetatable({}, { __mode = "k" })

-- iconKind is optional — e.g. Tab:CreateSection("Targeting", "target") to
-- get an icon + uppercase header like a settings-panel group title.
function Library.SectionFactory:CreateSection(title, iconKind)
	local parent = self.ContentPage or self.Page
	local count = (SectionCounts[parent] or 0) + 1
	SectionCounts[parent] = count
	if count > 1 then
		Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, Parent = parent })
	end

	local HeaderHolder = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = parent })

	-- Fixed offsets (not a UIListLayout) — a horizontal UIListLayout doesn't
	-- shrink Scale-sized siblings to fit remaining space, so a Scale-width
	-- text label placed after an icon would overflow past the container
	-- instead of accounting for the icon's width. Manual offsets sidestep
	-- that entirely and are just as simple here (only ever 0 or 1 icon).
	local textOffset = 0
	if iconKind then
		local IconHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(15, 15), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Parent = HeaderHolder })
		local builder = IconBuilders[iconKind] or IconBuilders.settings
		-- AccentMuted, not full Accent — section icons repeat on every group,
		-- so the hero accent stays reserved for the active tab + key values.
		local Glyph = builder(15, Theme.AccentMuted)
		Glyph.Size = UDim2.fromScale(1, 1)
		Glyph.Parent = IconHolder
		textOffset = 22
	end

	local Header = Utility.Create("TextLabel", {
		Size = UDim2.new(1, -textOffset, 0, 24), Position = UDim2.fromOffset(textOffset, 0), BackgroundTransparency = 1,
		Text = string.upper(title), Font = FONT_BLACK, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = HeaderHolder,
	})
	bindTheme(Header, "TextColor3", "MutedText")

	-- Thin divider under the header reinforces the group boundary without
	-- needing a full card/box around it.
	local Divider = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 23), BackgroundTransparency = 0.88, Parent = HeaderHolder })
	bindTheme(Divider, "BackgroundColor3", "Stroke")

	local Section = { Page = parent, Window = self.Window, Header = Header }
	setmetatable(Section, { __index = Library.ComponentFactory })
	return Section
end

Library.ComponentFactory = {}

local function card(parent, height)
	local Holder = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, height or 52), BackgroundTransparency = 0.06, Parent = parent }, { Utility.Corner(10), Utility.Padding(18) })
	bindTheme(Holder, "BackgroundColor3", "Panel")

	-- Softer border (~6% white opacity) than before, with a faint AccentMuted
	-- edge-light (not full Accent — this repeats on every single row) and a
	-- top-to-bottom transparency ramp that fakes a subtle inset light source
	-- without needing an extra Instance for it.
	local Stroke = Utility.Stroke(Theme.Stroke, 1, 0.94)
	Stroke.Parent = Holder
	Utility.Create("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Stroke), ColorSequenceKeypoint.new(1, Theme.AccentMuted) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.45) }),
		Rotation = 75, Parent = Stroke,
	})

	-- Whole-row hover "lift": border brightens + the fill itself becomes a
	-- touch more opaque — reads as raised depth without any resize or
	-- reposition (which would jitter sibling rows in the shared
	-- UIListLayout the way a real hover-scale would).
	Holder.MouseEnter:Connect(function()
		Utility.Tween(Stroke, { Transparency = 0.5 }, 0.15)
		Utility.Tween(Holder, { BackgroundTransparency = 0 }, 0.15)
	end)
	Holder.MouseLeave:Connect(function()
		Utility.Tween(Stroke, { Transparency = 0.94 }, 0.2)
		Utility.Tween(Holder, { BackgroundTransparency = 0.06 }, 0.2)
	end)

	return Holder
end

local function registerSearch(window, keywords, revealFn)
	if window and window.SearchIndex then
		table.insert(window.SearchIndex, { Keywords = keywords, KeywordsLower = keywords:lower(), Reveal = revealFn })
	end
end

-- Shared "title (+ optional description)" text block used by Toggle/Slider/
-- Dropdown rows. When a description is given, the title gets bolder/larger
-- and a smaller muted line sits underneath — the two-line settings-row style.
-- Returns the row height the caller should use for its card().
local function buildLabelBlock(parent, title, description, rightGutter, baseHeight)
	rightGutter = rightGutter or 70
	if description and description ~= "" then
		local TitleLabel = Utility.Create("TextLabel", {
			Size = UDim2.new(1, -rightGutter, 0, 18), BackgroundTransparency = 1, Text = title or "",
			Font = FONT_BOLD, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
		})
		bindTheme(TitleLabel, "TextColor3", "Text")
		local DescLabel = Utility.Create("TextLabel", {
			Size = UDim2.new(1, -rightGutter, 0, 15), Position = UDim2.fromOffset(0, 19), BackgroundTransparency = 1,
			Text = description, Font = FONT, TextSize = 12, TextTransparency = 0.15, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
		})
		bindTheme(DescLabel, "TextColor3", "MutedText")
		return TitleLabel, DescLabel, (baseHeight or 52) + 12
	else
		local TitleLabel = Utility.Create("TextLabel", {
			Size = UDim2.new(1, -rightGutter, 0, 16), BackgroundTransparency = 1, Text = title or "",
			Font = FONT, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
		})
		bindTheme(TitleLabel, "TextColor3", "Text")
		return TitleLabel, nil, baseHeight or 52
	end
end

function Library.ComponentFactory:CreateToggle(opts)
	opts = opts or {}
	local state = opts.Default or false
	local Holder = card(self.Page, 52)
	local _, _, neededHeight = buildLabelBlock(Holder, opts.Title or "Toggle", opts.Description, 70)
	Holder.Size = UDim2.new(1, 0, 0, neededHeight)

	local Track = Utility.Create("Frame", { Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -44, 0.5, -12), BackgroundColor3 = state and Theme.AccentDim or Theme.PanelLight, Parent = Holder }, { Utility.Corner(12) })
	-- Soft glow behind the knob, created before Knob so sibling render order
	-- puts it underneath. Fades in on ON — a "premium" touch that costs one
	-- static Frame per toggle, not a continuous animation. Uses AccentMuted
	-- (not full Accent) — toggles are common/repeated, so the hero accent
	-- stays reserved for the active tab and key numeric values.
	local Glow = Utility.Create("Frame", {
		Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = state and UDim2.new(1, -12.5, 0.5, 0) or UDim2.new(0, 12.5, 0.5, 0),
		BackgroundColor3 = Theme.AccentMuted, BackgroundTransparency = state and 0.72 or 1, Parent = Track,
	}, { Utility.Corner(15) })
	local Knob = Utility.Create("Frame", { Size = UDim2.fromOffset(19, 19), Position = state and UDim2.new(1, -22, 0.5, -9.5) or UDim2.new(0, 3, 0.5, -9.5), BackgroundColor3 = state and Theme.AccentMuted or Theme.MutedText, Parent = Track }, { Utility.Corner(10) })
	local Btn = Utility.Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = Holder })

	local function set(newState, fireCallback)
		state = newState
		Utility.Tween(Track, { BackgroundColor3 = state and Theme.AccentDim or Theme.PanelLight }, 0.18)
		Utility.Tween(Knob, { Position = state and UDim2.new(1, -22, 0.5, -9.5) or UDim2.new(0, 3, 0.5, -9.5), BackgroundColor3 = state and Theme.AccentMuted or Theme.MutedText }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		Utility.Tween(Glow, { Position = state and UDim2.new(1, -12.5, 0.5, 0) or UDim2.new(0, 12.5, 0.5, 0), BackgroundTransparency = state and 0.72 or 1 }, 0.2)
		if fireCallback ~= false and opts.Callback then task.spawn(opts.Callback, state) end
	end
	Btn.MouseButton1Click:Connect(function() set(not state) end)

	registerSearch(self.Window, opts.Title or "", function() Utility.FlashHighlight(Holder, Theme.Accent, 10) end)

	return { Instance = Holder, Set = set, Get = function() return state end }
end

-- Pins a live-synced shortcut to an existing toggle onto another section
-- (typically the Dashboard), so common features can be flipped without
-- navigating into their actual tab. Usage:
--   local AutoLevel = LevelSection:CreateToggle({ Title = "Auto level grind", ... })
--   Library:PinToggle(QuickSection, AutoLevel, { Title = "Auto level grind" })
-- Both copies drive the exact same state — flipping either one updates the
-- other. A cheap poll (2x/sec, only while the pin exists) keeps the pinned
-- copy honest if the original changes some other way (e.g. loaded from a
-- config file) — simpler and more robust than wiring a full event system
-- through every component just for this one feature.
function Library:PinToggle(targetSection, originalToggleAPI, opts)
	opts = opts or {}
	local pinned = targetSection:CreateToggle({
		Title = opts.Title or "Pinned", Description = opts.Description,
		Default = originalToggleAPI.Get(),
		Callback = function(v) originalToggleAPI.Set(v, true) end,
	})
	task.spawn(function()
		local lastKnown = originalToggleAPI.Get()
		while pinned.Instance.Parent do
			task.wait(0.5)
			local current = originalToggleAPI.Get()
			if current ~= lastKnown then
				lastKnown = current
				pinned.Set(current, false)
			end
		end
	end)
	return pinned
end

-- Shared slider-drag state: ONE UserInputService connection handles
-- dragging for every slider in the hub, instead of each slider adding its
-- own permanent InputChanged/InputEnded listener. Previously, a hub with
-- (say) 40 sliders meant 40 separate global listeners all evaluating on
-- *every single mouse-move event in the whole game*, forever — a real,
-- measurable cost that scales directly with hub size. Now it's always 1.
local ActiveSlider = nil -- { Update = fn(x), OnEnd = fn() }
UserInputService.InputChanged:Connect(function(i)
	if ActiveSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
		ActiveSlider.Update(i.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 and ActiveSlider then
		if ActiveSlider.OnEnd then ActiveSlider.OnEnd() end
		ActiveSlider = nil
	end
end)

function Library.ComponentFactory:CreateSlider(opts)
	opts = opts or {}
	local min, max = opts.Min or 0, opts.Max or 100
	local value = opts.Default or min
	local hasDesc = opts.Description and opts.Description ~= ""

	local Holder = card(self.Page, hasDesc and 78 or 60)
	local Label = Utility.Create("TextLabel", { Size = UDim2.new(1, -50, 0, 16), BackgroundTransparency = 1, Text = opts.Title or "Slider", Font = hasDesc and FONT_BOLD or FONT, TextSize = hasDesc and 14 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
	bindTheme(Label, "TextColor3", "Text")

	-- Value shown as a small pill badge, not bare floating text — reads as
	-- a distinct, "designed" element rather than an afterthought number.
	local ValueBadge = Utility.Create("Frame", { Size = UDim2.fromOffset(40, 20), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, -2), Parent = Holder }, { Utility.Corner(6) })
	bindTheme(ValueBadge, "BackgroundColor3", "PanelLight")
	local ValueLabel = Utility.Create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(value), Font = FONT_MONO, TextSize = 13, Parent = ValueBadge })
	bindTheme(ValueLabel, "TextColor3", "Accent")

	local trackY = 30
	if hasDesc then
		local DescLabel = Utility.Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 15), Position = UDim2.fromOffset(0, 19), BackgroundTransparency = 1,
			Text = opts.Description, Font = FONT, TextSize = 12, TextTransparency = 0.15, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder,
		})
		bindTheme(DescLabel, "TextColor3", "MutedText")
		trackY = 48
	end

	local Track = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.fromOffset(0, trackY), BackgroundColor3 = Theme.PanelLight, Parent = Holder }, { Utility.Corner(3) })
	local Fill = Utility.Create("Frame", { Size = UDim2.fromScale((value - min) / (max - min), 1), BackgroundColor3 = Theme.AccentMuted, Parent = Track }, { Utility.Corner(3) })
	bindTheme(Fill, "BackgroundColor3", "AccentMuted")
	Utility.Create("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Theme.AccentMuted) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(1, 0) }),
		Parent = Fill,
	})
	-- Soft glow behind the thumb (same technique as the Toggle knob glow) —
	-- one static Frame, no continuous cost. AccentMuted, same reasoning as
	-- the toggle: sliders are a repeated control, not the hero accent spot.
	local KnobGlow = Utility.Create("Frame", {
		Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		BackgroundColor3 = Theme.AccentMuted, BackgroundTransparency = 0.7, Parent = Track,
	}, { Utility.Corner(11) })
	local Knob = Utility.Create("Frame", { Size = UDim2.fromOffset(13, 13), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0), Parent = Track }, { Utility.Corner(7) })
	bindTheme(Knob, "BackgroundColor3", "AccentMuted")

	-- Drag value bubble: floats above the knob while dragging, common on
	-- premium slider UIs so you can read the exact value without staring
	-- across at the small ValueLabel on the other side of the row.
	local Bubble = Utility.Create("Frame", {
		Size = UDim2.fromOffset(32, 20), AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new((value - min) / (max - min), 0, 0, -10),
		Visible = false, ZIndex = 10, Parent = Track,
	}, { Utility.Corner(6), Utility.Stroke(Theme.Stroke, 1, 0.8) })
	bindTheme(Bubble, "BackgroundColor3", "PanelLight")
	local BubbleLabel = Utility.Create("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 12,
		Text = tostring(value), Parent = Bubble,
	})
	bindTheme(BubbleLabel, "TextColor3", "Accent")

	local function setFromX(x)
		local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		value = math.floor(min + (max - min) * rel)
		ValueLabel.Text = tostring(value)
		BubbleLabel.Text = tostring(value)
		Fill.Size = UDim2.fromScale(rel, 1)
		Knob.Position = UDim2.new(rel, 0, 0.5, 0)
		KnobGlow.Position = UDim2.new(rel, 0, 0.5, 0)
		Bubble.Position = UDim2.new(rel, 0, 0, -10)
		if opts.Callback then task.spawn(opts.Callback, value) end
	end
	local sliderHandle = { Update = setFromX, OnEnd = function() Bubble.Visible = false end }
	Knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			Bubble.Visible = true
			ActiveSlider = sliderHandle
		end
	end)
	Track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			setFromX(i.Position.X)
			Bubble.Visible = true
			ActiveSlider = sliderHandle
		end
	end)
	-- If this exact slider is destroyed mid-drag, release the shared
	-- pointer so the next mouse move doesn't call into a dead instance.
	Holder.AncestryChanged:Connect(function(_, p)
		if not p and ActiveSlider == sliderHandle then ActiveSlider = nil end
	end)

	registerSearch(self.Window, opts.Title or "", function() Utility.FlashHighlight(Holder, Theme.Accent, 10) end)

	return { Instance = Holder, Get = function() return value end }
end

-- Click-outside-to-close for ALL dropdowns via one shared global listener,
-- instead of each dropdown registering its own permanent InputBegan hook —
-- same "one connection, not N" philosophy as the slider drag state above.
local OpenDropdowns = {} -- [OptionsFrame] = { trigger = SelectBtn, close = fn }
local function registerOpenDropdown(optionsFrame, triggerBtn, closeFn)
	OpenDropdowns[optionsFrame] = { trigger = triggerBtn, close = closeFn }
end
local function pointInsideGui(pos, gui)
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	for optionsFrame, entry in pairs(OpenDropdowns) do
		if optionsFrame.Visible and not pointInsideGui(input.Position, optionsFrame) and not pointInsideGui(input.Position, entry.trigger) then
			entry.close()
		end
	end
end)

function Library.ComponentFactory:CreateDropdown(opts)
	opts = opts or {}
	local options = opts.Options or {}
	local selected = opts.Default or options[1]
	local open = false
	local hasDesc = opts.Description and opts.Description ~= ""

	local Holder = card(self.Page, hasDesc and 62 or 52)
	local Label = Utility.Create("TextLabel", { Size = UDim2.new(0.5, 0, 0, 18), BackgroundTransparency = 1, Text = opts.Title or "Dropdown", Font = hasDesc and FONT_BOLD or FONT, TextSize = hasDesc and 14 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
	bindTheme(Label, "TextColor3", "Text")
	if hasDesc then
		local DescLabel = Utility.Create("TextLabel", {
			Size = UDim2.new(0.5, 0, 0, 15), Position = UDim2.fromOffset(0, 19), BackgroundTransparency = 1,
			Text = opts.Description, Font = FONT, TextSize = 12, TextTransparency = 0.15, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder,
		})
		bindTheme(DescLabel, "TextColor3", "MutedText")
	else
		Label.Size = UDim2.new(0.5, 0, 1, 0)
	end

	local SelectBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(170, 30), Position = UDim2.new(1, -170, 0.5, -15), AutoButtonColor = false, Font = FONT, Text = "  " .. tostring(selected), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder }, { Utility.Corner(7) })
	bindTheme(SelectBtn, "BackgroundColor3", "PanelLight")
	bindTheme(SelectBtn, "TextColor3", "Text")

	-- Chevron — previously nothing distinguished this from a plain button.
	local ChevronHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), BackgroundTransparency = 1, Parent = SelectBtn })
	local function buildDropdownChevron()
		local Icon = Utility.Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = ChevronHolder })
		Utility.Create("Frame", {
			Size = UDim2.fromOffset(6, 1.2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.28, 0.4), Rotation = 45, BackgroundColor3 = Theme.MutedText,
		}, { Utility.Corner(1) }).Parent = Icon
		Utility.Create("Frame", {
			Size = UDim2.fromOffset(6, 1.2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.72, 0.4), Rotation = -45, BackgroundColor3 = Theme.MutedText,
		}, { Utility.Corner(1) }).Parent = Icon
		return Icon
	end
	local ChevronIcon = buildDropdownChevron()

	local OptionsFrame = Utility.Create("Frame", { Size = UDim2.fromOffset(170, #options * 28), Position = UDim2.new(1, -170, 1, 4), ClipsDescendants = true, Visible = false, ZIndex = 5, Parent = Holder }, { Utility.Corner(7), Utility.Stroke(Theme.Stroke, 1, 0.85) })
	bindTheme(OptionsFrame, "BackgroundColor3", "PanelLight")
	Utility.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = OptionsFrame })

	for i, opt in ipairs(options) do
		local OptBtn = Utility.Create("TextButton", { Size = UDim2.new(1, 0, 0, 28), AutoButtonColor = false, Font = FONT, Text = "  " .. tostring(opt), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, LayoutOrder = i, Parent = OptionsFrame })
		bindTheme(OptBtn, "BackgroundColor3", "PanelLight")
		bindTheme(OptBtn, "TextColor3", "MutedText")
		Utility.AddHoverDarken(OptBtn, 0.12)
		OptBtn.MouseButton1Click:Connect(function()
			selected = opt
			SelectBtn.Text = "  " .. tostring(opt)
			open = false
			OptionsFrame.Visible = false
			Holder.ZIndex = 1
			Utility.Tween(ChevronIcon, { Rotation = 0 }, 0.15)
			if opts.Callback then task.spawn(opts.Callback, opt) end
		end)
	end
	-- Under Sibling ZIndexBehavior, a nested child's ZIndex only outranks
	-- ITS OWN siblings — it can't draw over an unrelated card lower in the
	-- list unless that card's *container* (Holder) also has a higher
	-- ZIndex than the other row cards. That's what was causing the popup
	-- to render behind the next row instead of over it.
	SelectBtn.MouseButton1Click:Connect(function()
		open = not open
		OptionsFrame.Visible = open
		Holder.ZIndex = open and 10 or 1
		Utility.Tween(ChevronIcon, { Rotation = open and 180 or 0 }, 0.15)
	end)

	-- Click-outside-to-close, via the one shared global listener below
	-- rather than each dropdown adding its own permanent InputBegan hook.
	registerOpenDropdown(OptionsFrame, SelectBtn, function()
		open = false
		OptionsFrame.Visible = false
		Holder.ZIndex = 1
		Utility.Tween(ChevronIcon, { Rotation = 0 }, 0.15)
	end)

	registerSearch(self.Window, opts.Title or "", function() Utility.FlashHighlight(Holder, Theme.Accent, 10) end)

	return { Instance = Holder, Get = function() return selected end }
end

-- Free-text input row. opts: { Title, Description, Placeholder, Default,
-- Numeric (bool — rejects non-numbers on blur), Callback(text) }
function Library.ComponentFactory:CreateTextbox(opts)
	opts = opts or {}
	local hasDesc = opts.Description and opts.Description ~= ""
	local Holder = card(self.Page, hasDesc and 62 or 52)
	buildLabelBlock(Holder, opts.Title or "Input", opts.Description, 190)

	local Box = Utility.Create("TextBox", {
		Size = UDim2.fromOffset(170, 30), Position = UDim2.new(1, -170, 0.5, -15),
		Text = tostring(opts.Default or ""), PlaceholderText = opts.Placeholder or "",
		Font = FONT, TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Holder,
	}, { Utility.Corner(7), Utility.Padding(8) })
	bindTheme(Box, "BackgroundColor3", "PanelLight")
	bindTheme(Box, "TextColor3", "Text")
	bindTheme(Box, "PlaceholderColor3", "MutedText")

	-- Focus highlight — previously nothing showed which field currently has
	-- focus, easy to lose track of when a row has both a description and
	-- an input right next to each other.
	local BoxStroke = Utility.Stroke(Theme.AccentMuted, 1.3, 1)
	BoxStroke.Parent = Box
	Box.Focused:Connect(function() Utility.Tween(BoxStroke, { Transparency = 0.3 }, 0.15) end)
	Box.FocusLost:Connect(function() Utility.Tween(BoxStroke, { Transparency = 1 }, 0.2) end)

	Box.FocusLost:Connect(function()
		if opts.Numeric then
			local n = tonumber(Box.Text)
			if not n then
				Box.Text = tostring(opts.Default or 0)
				return
			end
			Box.Text = tostring(n)
		end
		if opts.Callback then task.spawn(opts.Callback, Box.Text) end
	end)

	registerSearch(self.Window, opts.Title or "", function() Utility.FlashHighlight(Holder, Theme.Accent, 10) end)

	return { Instance = Holder, Get = function() return Box.Text end, Set = function(v) Box.Text = tostring(v) end }
end

-- Keybind picker: click the pill, then press any key to bind it (Esc
-- cancels). Only listens for input while actively "capturing" a key press —
-- no permanent global listener, so having many keybinds costs nothing when
-- idle. Note: this only lets the user *pick* a key and hands it back via
-- Callback/Get — actually reacting to that key being pressed during
-- gameplay is up to your own game-logic script, same as any other setting.
-- opts: { Title, Description, Default (Enum.KeyCode), Callback(Enum.KeyCode) }
function Library.ComponentFactory:CreateKeybind(opts)
	opts = opts or {}
	local hasDesc = opts.Description and opts.Description ~= ""
	local Holder = card(self.Page, hasDesc and 62 or 52)
	buildLabelBlock(Holder, opts.Title or "Keybind", opts.Description, 130)

	local currentKey = opts.Default
	local listening = false

	local KeyBtn = Utility.Create("TextButton", {
		Size = UDim2.fromOffset(110, 30), Position = UDim2.new(1, -110, 0.5, -15), AutoButtonColor = false,
		Font = FONT_BOLD, TextSize = 12, Text = currentKey and currentKey.Name or "None", Parent = Holder,
	}, { Utility.Corner(7) })
	bindTheme(KeyBtn, "BackgroundColor3", "PanelLight")
	bindTheme(KeyBtn, "TextColor3", "Text")
	Utility.AddHoverDarken(KeyBtn, 0.1, 7)

	local KeyBtnStroke = Utility.Stroke(Theme.AccentMuted, 1.3, 1)
	KeyBtnStroke.Parent = KeyBtn
	local listeningPulse = false

	KeyBtn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		KeyBtn.Text = "..."
		-- Pulsing border while waiting for a key press — much easier to
		-- notice than a lone "..." text change buried in a busy panel.
		listeningPulse = true
		task.spawn(function()
			while listeningPulse do
				local t1 = Utility.Tween(KeyBtnStroke, { Transparency = 0.2 }, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				t1.Completed:Wait()
				if not listeningPulse then break end
				local t2 = Utility.Tween(KeyBtnStroke, { Transparency = 0.8 }, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				t2.Completed:Wait()
			end
			Utility.Tween(KeyBtnStroke, { Transparency = 1 }, 0.15)
		end)
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			listening = false
			listeningPulse = false
			conn:Disconnect()
			if input.KeyCode == Enum.KeyCode.Escape then
				KeyBtn.Text = currentKey and currentKey.Name or "None"
				return
			end
			currentKey = input.KeyCode
			KeyBtn.Text = currentKey.Name
			if opts.Callback then task.spawn(opts.Callback, currentKey) end
		end)
	end)

	registerSearch(self.Window, opts.Title or "", function() Utility.FlashHighlight(Holder, Theme.Accent, 10) end)

	return { Instance = Holder, Get = function() return currentKey end }
end

-- Multi-select: like Dropdown, but several options can stay picked at once.
-- The button shows a summary ("2 selected") instead of a single value.
-- opts: { Title, Description, Options, Default (array of picked strings), Callback(array) }
function Library.ComponentFactory:CreateMultiSelect(opts)
	opts = opts or {}
	local options = opts.Options or {}
	local selected = {}
	for _, v in ipairs(opts.Default or {}) do selected[v] = true end
	local open = false
	local hasDesc = opts.Description and opts.Description ~= ""

	local Holder = card(self.Page, hasDesc and 62 or 52)
	buildLabelBlock(Holder, opts.Title or "Select", opts.Description, 190)

	local function summaryText()
		local list, count = {}, 0
		for k in pairs(selected) do table.insert(list, k); count = count + 1 end
		if count == 0 then return "None" end
		if count == 1 then return list[1] end
		return count .. " selected"
	end

	local SelectBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(170, 30), Position = UDim2.new(1, -170, 0.5, -15), AutoButtonColor = false, Font = FONT, Text = "  " .. summaryText(), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder }, { Utility.Corner(7) })
	bindTheme(SelectBtn, "BackgroundColor3", "PanelLight")
	bindTheme(SelectBtn, "TextColor3", "Text")

	-- Chevron, matching Dropdown for visual consistency between the two
	-- "opens a popup list" controls.
	local ChevronHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), BackgroundTransparency = 1, Parent = SelectBtn })
	local ChevronIcon = Utility.Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = ChevronHolder })
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(6, 1.2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.28, 0.4), Rotation = 45, BackgroundColor3 = Theme.MutedText,
	}, { Utility.Corner(1) }).Parent = ChevronIcon
	Utility.Create("Frame", {
		Size = UDim2.fromOffset(6, 1.2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.72, 0.4), Rotation = -45, BackgroundColor3 = Theme.MutedText,
	}, { Utility.Corner(1) }).Parent = ChevronIcon

	local OptionsFrame = Utility.Create("Frame", { Size = UDim2.fromOffset(170, #options * 28), Position = UDim2.new(1, -170, 1, 4), ClipsDescendants = true, Visible = false, ZIndex = 5, Parent = Holder }, { Utility.Corner(7), Utility.Stroke(Theme.Stroke, 1, 0.85) })
	bindTheme(OptionsFrame, "BackgroundColor3", "PanelLight")
	Utility.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = OptionsFrame })

	local function fireCallback()
		if not opts.Callback then return end
		local list = {}
		for k in pairs(selected) do table.insert(list, k) end
		task.spawn(opts.Callback, list)
	end

	for i, opt in ipairs(options) do
		local OptBtn = Utility.Create("TextButton", { Size = UDim2.new(1, 0, 0, 28), AutoButtonColor = false, Font = FONT, Text = "  " .. tostring(opt), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, LayoutOrder = i, Parent = OptionsFrame })
		bindTheme(OptBtn, "BackgroundColor3", "PanelLight")
		bindTheme(OptBtn, "TextColor3", "MutedText")
		Utility.AddHoverDarken(OptBtn, 0.12)
		local Check = Utility.Create("Frame", {
			Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			BackgroundTransparency = selected[opt] and 0 or 1, ZIndex = 6, Parent = OptBtn,
		}, { Utility.Corner(4) })
		bindTheme(Check, "BackgroundColor3", "AccentMuted")
		OptBtn.MouseButton1Click:Connect(function()
			if selected[opt] then selected[opt] = nil else selected[opt] = true end
			Check.BackgroundTransparency = selected[opt] and 0 or 1
			SelectBtn.Text = "  " .. summaryText()
			fireCallback()
		end)
	end
	SelectBtn.MouseButton1Click:Connect(function()
		open = not open
		OptionsFrame.Visible = open
		Holder.ZIndex = open and 10 or 1
		Utility.Tween(ChevronIcon, { Rotation = open and 180 or 0 }, 0.15)
	end)
	registerOpenDropdown(OptionsFrame, SelectBtn, function()
		open = false
		OptionsFrame.Visible = false
		Holder.ZIndex = 1
		Utility.Tween(ChevronIcon, { Rotation = 0 }, 0.15)
	end)

	registerSearch(self.Window, opts.Title or "", function() Utility.FlashHighlight(Holder, Theme.Accent, 10) end)

	return {
		Instance = Holder,
		Get = function()
			local list = {}
			for k in pairs(selected) do table.insert(list, k) end
			return list
		end,
	}
end

function Library.ComponentFactory:CreateButton(opts)
	opts = opts or {}
	local isSecondary = opts.Style == "secondary"

	local Btn = Utility.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false, Font = FONT_BOLD,
		Text = "", TextSize = 13, Parent = self.Page,
	}, { Utility.Corner(8), Utility.Stroke(Theme.Stroke, 1, 0.92) })

	if isSecondary then
		bindTheme(Btn, "BackgroundColor3", "PanelLight")
	else
		bindTheme(Btn, "BackgroundColor3", "Accent")
	end

	local hasIcon = opts.Icon ~= nil
	local Label = Utility.Create("TextLabel", {
		Size = UDim2.new(1, hasIcon and -28 or 0, 1, 0), Position = UDim2.fromOffset(hasIcon and 24 or 0, 0),
		BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 13, Text = opts.Title or "Button",
		TextColor3 = isSecondary and (opts.Danger and Theme.Danger or Theme.Text) or Theme.Background,
		Parent = Btn,
	})
	if isSecondary then
		bindTheme(Label, "TextColor3", opts.Danger and "Danger" or "Text")
	else
		bindTheme(Label, "TextColor3", "Background")
	end

	if hasIcon then
		local IconHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), BackgroundTransparency = 1, Parent = Btn })
		local iconColor = isSecondary and (opts.Danger and Theme.Danger or Theme.Text) or Theme.Background
		local Glyph = opts.Icon(16, iconColor)
		Glyph.Size = UDim2.fromScale(1, 1)
		Glyph.Parent = IconHolder
	end

	-- Hover feedback via overlay (never fights with refreshTheme, no matter
	-- what color the user customizes Accent/Panel to — see Utility.AddHoverDarken).
	Utility.AddHoverDarken(Btn, isSecondary and 0.08 or 0.15, 8)

	Btn.MouseButton1Click:Connect(function()
		-- Press feedback via a throwaway overlay (Transparency only) instead
		-- of resizing the button — Btn sits directly in the section's
		-- UIListLayout, so shrinking/growing its own Size would visibly
		-- shove every row below it up and back down on every click. Same
		-- bug class as the old hover-scale-card idea ruled out earlier.
		Utility.FlashHighlight(Btn, Color3.new(0, 0, 0), 8)
		if opts.Callback then task.spawn(opts.Callback) end
	end)
	return { Instance = Btn }
end

-- Dashboard-style stat card: big number/value with a small label under it.
-- Numeric values count up from their current text on :Set(), reusing
-- Utility.Tween so it automatically snaps instantly under Low quality
-- instead of animating a NumberValue every frame.
function Library.ComponentFactory:CreateStat(opts)
	opts = opts or {}
	local hasSpark = opts.Sparkline == true
	local Holder = card(self.Page, hasSpark and 86 or 64)

	local ValueLabel = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Font = FONT_MONO, TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(opts.Value or 0), Parent = Holder,
	})
	bindTheme(ValueLabel, "TextColor3", "Accent")

	local Label = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 26), BackgroundTransparency = 1,
		Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Title or "Stat", Parent = Holder,
	})
	bindTheme(Label, "TextColor3", "MutedText")

	-- Optional mini sparkline: a row of thin bars, not a connected line —
	-- much cheaper in Roblox UI (no per-segment rotation/length trig needed,
	-- just Size.Y per bar) — shows the last N values at a glance.
	local SparkBars
	local SparkHistory = {}
	local SPARK_COUNT = opts.SparklinePoints or 12
	if hasSpark then
		local SparkHolder = Utility.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 48), BackgroundTransparency = 1, Parent = Holder,
		})
		SparkBars = {}
		for i = 1, SPARK_COUNT do
			local Bar = Utility.Create("Frame", {
				AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / SPARK_COUNT, 1, 1, 0),
				Size = UDim2.new(1 / SPARK_COUNT, -2, 0, 3), BackgroundTransparency = 0.35, Parent = SparkHolder,
			}, { Utility.Corner(1) })
			bindTheme(Bar, "BackgroundColor3", "AccentMuted")
			SparkBars[i] = Bar
		end
	end
	local function pushSparkPoint(value)
		if not SparkBars then return end
		table.insert(SparkHistory, value)
		if #SparkHistory > SPARK_COUNT then table.remove(SparkHistory, 1) end
		local maxVal = 1
		for _, v in ipairs(SparkHistory) do if v > maxVal then maxVal = v end end
		for i, Bar in ipairs(SparkBars) do
			local v = SparkHistory[i]
			local h = v and math.max(3, (v / maxVal) * 14) or 0
			Utility.Tween(Bar, { Size = UDim2.new(1 / SPARK_COUNT, -2, 0, h) }, 0.25)
		end
	end

	local api = { Instance = Holder, ValueLabel = ValueLabel }

	function api:Set(value)
		if type(value) == "number" then
			local counter = Instance.new("NumberValue")
			counter.Value = tonumber(ValueLabel.Text) or 0
			counter.Changed:Connect(function(v) ValueLabel.Text = tostring(math.floor(v + 0.5)) end)
			Utility.Tween(counter, { Value = value }, 0.5)
			task.delay(0.55, function() counter:Destroy() end)
			pushSparkPoint(value)
			-- Threshold coloring (opts.DangerIf): flags an unhealthy value
			-- instead of the number always looking the same regardless of
			-- state. Note: this tweens the same property bindTheme manages
			-- for the default case, same trade-off as the toggle/slider
			-- controls elsewhere — acceptable since threshold flips are rare,
			-- deliberate state changes, not a hover flicker.
			if opts.DangerIf then
				Utility.Tween(ValueLabel, { TextColor3 = opts.DangerIf(value) and Theme.Danger or Theme.Accent }, 0.2)
			end
		else
			ValueLabel.Text = tostring(value)
		end
	end

	if type(opts.Value) == "number" and opts.Value > 0 then
		ValueLabel.Text = "0"
		api:Set(opts.Value)
	elseif hasSpark then
		pushSparkPoint(opts.Value or 0)
	end

	return api
end

-- Paint-style color picker row: a swatch button that opens the single
-- shared modal (built once per Window in CreateWindow / OpenColorPicker).
-- No more per-instance floating popups — fixes both the row-overlap bug
-- and the click-through-blocking bug from the old cross-branch ZIndex hack.
function Library.ComponentFactory:CreateColorPicker(opts)
	opts = opts or {}
	local role = opts.Role
	local startColor = Theme[role]

	local Holder = card(self.Page, 36)
	Utility.Create("TextLabel", { Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, Text = opts.Title or role, Font = FONT, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })

	local SwatchBtn = Utility.Create("TextButton", { Size = UDim2.fromOffset(70, 26), Position = UDim2.new(1, -70, 0.5, -13), AutoButtonColor = false, Text = "", BackgroundColor3 = startColor, Parent = Holder }, { Utility.Corner(6), Utility.Stroke(Theme.Stroke, 1, 0.8) })
	Utility.AddHoverDarken(SwatchBtn, 0.1, 6)
	local function contrastColor(c)
		-- Perceived brightness (ITU-R BT.601) decides black-vs-white text —
		-- previously hardcoded white, unreadable on light swatch colors
		-- (e.g. the Azure/Emerald presets' lighter accent shades).
		local brightness = c.R * 0.299 + c.G * 0.587 + c.B * 0.114
		return brightness > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	end
	local HexLabel = Utility.Create("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = FONT, TextSize = 11,
		Text = string.format("#%02X%02X%02X", math.floor(startColor.R * 255), math.floor(startColor.G * 255), math.floor(startColor.B * 255)),
		TextColor3 = contrastColor(startColor), Parent = SwatchBtn,
	})

	SwatchBtn.MouseButton1Click:Connect(function()
		self.Window:OpenColorPicker(opts.Title or role, Theme[role], function(newColor)
			SwatchBtn.BackgroundColor3 = newColor
			HexLabel.Text = string.format("#%02X%02X%02X", math.floor(newColor.R * 255 + 0.5), math.floor(newColor.G * 255 + 0.5), math.floor(newColor.B * 255 + 0.5))
			HexLabel.TextColor3 = contrastColor(newColor)
			Theme[role] = newColor
			refreshTheme()
			if opts.Callback then opts.Callback(newColor) end
		end)
	end)

	return { Instance = Holder, Get = function() return Theme[role] end }
end

--====================================================
-- BUILT-IN: SETTINGS > CUSTOM UI helper
--====================================================
--====================================================
-- BUILT-IN: CONFIG MANAGER (save/load named .json profiles)
-- Uses executor file functions (writefile/readfile/listfiles) when
-- available, guarded by pcall so it never errors on environments
-- without them. Wire opts.GetData / opts.OnLoad to your own settings
-- table once your 12k-line config system is in place.
--====================================================
local CONFIG_FOLDER = "ZiliHubConfigs"

local function configFileIOAvailable()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function ensureConfigFolder()
	if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
		if not isfolder(CONFIG_FOLDER) then
			pcall(makefolder, CONFIG_FOLDER)
		end
	end
end

local function listConfigNames()
	local names = {}
	if typeof(listfiles) ~= "function" then return names end
	local ok, files = pcall(listfiles, CONFIG_FOLDER)
	if ok and files then
		for _, path in ipairs(files) do
			local name = path:match("([^/\\]+)%.json$")
			if name then table.insert(names, name) end
		end
	end
	return names
end

function Library:CreateConfigManager(ConfigSubTab, opts)
	opts = opts or {}
	local HttpService = game:GetService("HttpService")
	ensureConfigFolder()

	local Section = ConfigSubTab:CreateSection(L("Config"))

	local NameHolder = card(Section.Page, 52)
	Utility.Create("TextLabel", { Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Text = "Config name", Font = FONT, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = NameHolder })
	local NameBox = Utility.Create("TextBox", { Size = UDim2.fromOffset(180, 30), Position = UDim2.new(1, -180, 0.5, -15), Text = "", PlaceholderText = "e.g. default", Font = FONT, TextSize = 12, ClearTextOnFocus = false, Parent = NameHolder }, { Utility.Corner(7) })
	bindTheme(NameBox, "BackgroundColor3", "PanelLight")
	bindTheme(NameBox, "TextColor3", "Text")

	local existing = listConfigNames()
	local SelectHolder = Section:CreateDropdown({
		Title = "Saved configs",
		Options = #existing > 0 and existing or { "(none saved yet)" },
		Default = existing[1] or "(none saved yet)",
	})

	if #existing == 0 then
		local EmptyHint = Utility.Create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = Section.Page })
		local EmptyIconHolder = Utility.Create("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(0, 2), BackgroundTransparency = 1, Parent = EmptyHint })
		local EmptyGlyph = Icons.info(16, Theme.MutedText)
		EmptyGlyph.Size = UDim2.fromScale(1, 1)
		EmptyGlyph.Parent = EmptyIconHolder
		local EmptyLabel = Utility.Create("TextLabel", {
			Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(24, 0), BackgroundTransparency = 1, TextWrapped = true,
			Text = "No configs saved yet — type a name above and hit Save to create your first one.",
			Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = EmptyHint,
		})
		bindTheme(EmptyLabel, "TextColor3", "MutedText")
	end

	if not configFileIOAvailable() then
		local Warn = Utility.Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, TextWrapped = true,
			Text = "File saving isn't available in this environment (requires an executor with writefile/readfile).",
			Font = FONT, TextSize = 11, TextColor3 = Theme.MutedText, Parent = Section.Page,
		})
	end

	Section:CreateButton({
		Title = "Save config",
		Callback = function()
			local name = NameBox.Text ~= "" and NameBox.Text or SelectHolder.Get()
			if not configFileIOAvailable() or not name or name == "" or name == "(none saved yet)" then return end
			local data = opts.GetData and opts.GetData() or {}
			local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
			if ok then
				pcall(writefile, CONFIG_FOLDER .. "/" .. name .. ".json", encoded)
			end
		end,
	})

	Section:CreateButton({
		Title = "Load selected config",
		Callback = function()
			local name = SelectHolder.Get()
			if not configFileIOAvailable() or not name or name == "(none saved yet)" then return end
			local function doLoad()
				local path = CONFIG_FOLDER .. "/" .. name .. ".json"
				if not isfile(path) then return end
				local ok, raw = pcall(readfile, path)
				if not ok then return end
				local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
				if ok2 and opts.OnLoad then opts.OnLoad(decoded) end
			end
			local window = ConfigSubTab.Window
			if window and window.Confirm then
				window:Confirm({
					Title = "Load \"" .. name .. "\"?", ConfirmText = "Load",
					Message = "This overwrites your current settings with the saved config.",
					OnConfirm = doLoad,
				})
			else
				doLoad()
			end
		end,
	})

	return Section
end

-- Drop this into any tab/sub-tab, e.g.:
--   local PerfTab = SettingsTab:CreateSubTab(L("Performance"))
--   Window:ApplyPerformanceTab(PerfTab)
function Library:ApplyPerformanceTab(PerfSubTab)
	local Section = PerfSubTab:CreateSection(L("Performance"))

	local StatusHolder = card(Section.Page, 58)
	Utility.Create("TextLabel", {
		Size = UDim2.new(0.6, 0, 0, 16), BackgroundTransparency = 1, Text = L("LiveFPS"),
		Font = FONT, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Text, Parent = StatusHolder,
	})
	local FPSLabel = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 20), BackgroundTransparency = 1,
		Text = "-- FPS  ·  High", Font = FONT_MONO, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusHolder,
	})
	bindTheme(FPSLabel, "TextColor3", "Accent")

	-- Only ticks while the row is actually on screen (Holder.Parent chain
	-- visible) — updating Text less than every frame keeps TextService
	-- measuring cost negligible even on huge hubs.
	local alive = true
	StatusHolder.AncestryChanged:Connect(function(_, parent) if not parent then alive = false end end)
	task.spawn(function()
		while alive do
			FPSLabel.Text = string.format("%d FPS  ·  %s", math.floor(LiveFPS + 0.5), currentQuality())
			task.wait(0.4)
		end
	end)

	Section:CreateDropdown({
		Title = L("QualityMode"),
		Options = { "Auto", "High", "Balanced", "Low" },
		Default = Quality.Mode,
		Callback = function(choice) setQualityMode(choice) end,
	})

	local DescLabel = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, TextWrapped = true,
		Text = L("QualityDesc"), Font = FONT, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = Section.Page,
	})
	bindTheme(DescLabel, "TextColor3", "MutedText")

	return Section
end

local THEME_PRESETS = {
	{ Name = "Amber",   Accent = Color3.fromRGB(240, 180, 41), AccentDim = Color3.fromRGB(122, 92, 10),  AccentMuted = Color3.fromRGB(196, 168, 112), Background = Color3.fromRGB(15, 15, 17), Panel = Color3.fromRGB(23, 23, 26), PanelLight = Color3.fromRGB(32, 32, 36) },
	{ Name = "Crimson", Accent = Color3.fromRGB(230, 70, 70),  AccentDim = Color3.fromRGB(110, 30, 30), AccentMuted = Color3.fromRGB(190, 120, 120), Background = Color3.fromRGB(16, 14, 15), Panel = Color3.fromRGB(24, 20, 21), PanelLight = Color3.fromRGB(34, 28, 29) },
	{ Name = "Azure",   Accent = Color3.fromRGB(70, 150, 240), AccentDim = Color3.fromRGB(25, 60, 110), AccentMuted = Color3.fromRGB(120, 155, 200), Background = Color3.fromRGB(13, 15, 18), Panel = Color3.fromRGB(20, 23, 28), PanelLight = Color3.fromRGB(28, 32, 38) },
	{ Name = "Emerald", Accent = Color3.fromRGB(70, 210, 140), AccentDim = Color3.fromRGB(25, 90, 60), AccentMuted = Color3.fromRGB(120, 180, 155), Background = Color3.fromRGB(13, 16, 15), Panel = Color3.fromRGB(19, 24, 22), PanelLight = Color3.fromRGB(27, 33, 30) },
	{ Name = "Violet",  Accent = Color3.fromRGB(160, 110, 240), AccentDim = Color3.fromRGB(70, 45, 110), AccentMuted = Color3.fromRGB(165, 140, 200), Background = Color3.fromRGB(15, 14, 18), Panel = Color3.fromRGB(22, 21, 27), PanelLight = Color3.fromRGB(31, 29, 38) },
}

function Library:ApplyCustomUITab(CustomUISubTab, MainFrame, BackgroundImageInstance)
	local PresetSection = CustomUISubTab:CreateSection(L("ThemePresets"))
	local PresetHolder = card(PresetSection.Page, 58)
	Utility.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = PresetHolder,
	})
	for _, preset in ipairs(THEME_PRESETS) do
		local Swatch = Utility.Create("TextButton", {
			Size = UDim2.fromOffset(30, 30), BackgroundColor3 = preset.Accent, Text = "", Parent = PresetHolder,
		}, { Utility.Corner(15), Utility.Stroke(Color3.new(1, 1, 1), 1.3, 0.75) })
		Utility.AddHoverDarken(Swatch, 0.15, 15)
		Swatch.MouseButton1Click:Connect(function()
			Theme.Accent, Theme.AccentDim, Theme.AccentMuted = preset.Accent, preset.AccentDim, preset.AccentMuted
			Theme.Background, Theme.Panel, Theme.PanelLight = preset.Background, preset.Panel, preset.PanelLight
			refreshTheme()
		end)
	end

	local ColorSection = CustomUISubTab:CreateSection("Theme colors")
	ColorSection:CreateColorPicker({ Title = L("Accent"), Role = "Accent" })
	ColorSection:CreateColorPicker({ Title = L("Background"), Role = "Background" })
	ColorSection:CreateColorPicker({ Title = L("Panel"), Role = "Panel" })

	local ImgSection = CustomUISubTab:CreateSection(L("BackgroundImage"))
	local ImgHolder = card(ImgSection.Page, 58)
	Utility.Create("TextLabel", { Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, Text = L("BackgroundImageDesc"), Font = FONT, TextSize = 12, TextColor3 = Theme.MutedText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = ImgHolder })
	local ImgBox = Utility.Create("TextBox", { Size = UDim2.fromOffset(180, 30), Position = UDim2.new(1, -180, 0.5, -15), Text = "", PlaceholderText = "rbxassetid://...", Font = FONT, TextSize = 12, ClearTextOnFocus = false, Parent = ImgHolder }, { Utility.Corner(7) })
	bindTheme(ImgBox, "BackgroundColor3", "PanelLight")
	bindTheme(ImgBox, "TextColor3", "Text")

	ImgBox.FocusLost:Connect(function()
		local normalized = normalizeAssetId(ImgBox.Text)
		ImgBox.Text = normalized
		BackgroundImageInstance.Image = normalized
		BackgroundImageInstance.ImageTransparency = Theme.BackgroundImageTransparency
	end)

	local ResetSection = CustomUISubTab:CreateSection(" ")
	ResetSection:CreateButton({
		Title = L("ResetTheme"),
		Style = "secondary",
		Danger = true,
		Icon = Icons.reset,
		Callback = function()
			local window = CustomUISubTab.Window
			local function doReset()
				Theme.Accent = Color3.fromRGB(240, 180, 41)
				Theme.AccentDim = Color3.fromRGB(122, 92, 10)
				Theme.AccentMuted = Color3.fromRGB(196, 168, 112)
				Theme.Background = Color3.fromRGB(15, 15, 17)
				Theme.Panel = Color3.fromRGB(23, 23, 26)
				Theme.PanelLight = Color3.fromRGB(32, 32, 36)
				refreshTheme()
				ImgBox.Text = ""
				BackgroundImageInstance.Image = ""
			end
			-- Destructive action → confirm first instead of firing instantly.
			if window and window.Confirm then
				window:Confirm({
					Title = "Reset theme?", Danger = true, ConfirmText = "Reset",
					Message = "This clears your custom colors and background image back to defaults.",
					OnConfirm = doReset,
				})
			else
				doReset()
			end
		end,
	})
end

--====================================================
-- ENTRY POINT
--====================================================
function Library:Init(config)
	config = config or {}
	local runLoading = buildLoadingScreen(config.LoadingTitle, config.LoadingStatusLines)
	local Window = self:CreateWindow(config)
	task.spawn(function()
		runLoading(function()
			Window.MainFrame.Visible = true
			Window.MainFrame.Size = UDim2.fromOffset(0, 0)
			Utility.Tween(Window.MainFrame, { Size = UDim2.new(0.78, 0, 0.82, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	end)
	return Window
end

return Library
