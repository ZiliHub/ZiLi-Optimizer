-- =====================================================================
-- WAIT FOR GAME TO FULLY LOAD BEFORE RUNNING SCRIPT
-- =====================================================================
repeat task.wait() until game:IsLoaded()

-- =====================================================================
-- 0. ANTI-DUPLICATE (FIX TRIỆT ĐỂ CHO WAVE / SOLARA)
-- =====================================================================
-- Dự phòng môi trường: Nếu getgenv() của Wave bị hỏng thì tự lùi về _G
local env = (type(getgenv) == "function" and getgenv()) or _G or shared

if env.ZiliHub_Loaded then
    warn("[ZILI NOTIFY] Script is already running! Execution blocked to prevent crash.")
    
    -- Dùng trick tạo Event ảo để ép dừng luồng script vĩnh viễn
    -- Đảm bảo 100% ngắt được script trên mọi loại Executor mà không văng lỗi đỏ
    local freezeThread = Instance.new("BindableEvent")
    freezeThread.Event:Wait() 
    return 
end

env.ZiliHub_Loaded = true

-- =====================================================================
-- 1. BUNDLER SYSTEM (Allows Executor to understand 'require')
-- =====================================================================
local __modules = {}
local __cache = {}

local ZiliState = {}  -- internal script state (replaces _G for private keys)
ZiliState.ActivityLog     = {}  -- ring buffer max 30 (persists via file)
ZiliState.MerchantCounter = 0   -- merchant visits this session

-- ── Global activity logger (file path set in Main UI after LocalPlayer known) ──
getgenv().ZiliLog = function(text, cat)
    local entry = {t = os.date("%H:%M"), text = text or "", cat = cat or "info"}
    table.insert(ZiliState.ActivityLog, 1, entry)
    if #ZiliState.ActivityLog > 30 then ZiliState.ActivityLog[31] = nil end
    pcall(function()
        local lf = getgenv()._ZiliLogFile
        if lf and writefile then
            writefile(lf, game:GetService("HttpService"):JSONEncode(ZiliState.ActivityLog))
        end
    end)
    if ZiliState._LogRefresh then pcall(ZiliState._LogRefresh) end
end

local original_require = require

local function require(path)
    if typeof(path) == "Instance" then
        return original_require(path)
    end

    if __cache[path] then return __cache[path] end
    local loader = __modules[path]
    if not loader then error("Error: Module not found -> " .. tostring(path)) end
    local result = loader()
    __cache[path] = result
    return result
end

-- =====================================================================
-- 2. MODULE PACKAGING (All logic packed into one file)
-- =====================================================================

-- 📦 MODULE: Config/ConfigManager  (GET BETTER OUT · Zili Hub) 
__modules["Config/ConfigManager"] = function()
    local ConfigManager = {}
    local HttpService   = game:GetService("HttpService")
    local TweenService  = game:GetService("TweenService")
    local ConfigFolder  = "Zili_Hub/configs"

    if isfolder then
        if not isfolder("Zili_Hub") then makefolder("Zili_Hub") end
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- CONSTANTS  (must match MainHub palette exactly)
    -- ══════════════════════════════════════════════════════════════════
    local BG5   = Color3.fromRGB(8,   9,  20)
    local GOLDD = Color3.fromRGB(50,  37,  12)
    local GOLD  = Color3.fromRGB(201, 148, 58)
    local GOLD2 = Color3.fromRGB(240, 190, 104)
    local GOLD3 = Color3.fromRGB(122,  90,  30)
    local GREEN = Color3.fromRGB(56,  190, 110)
    local TEXT3 = Color3.fromRGB(80,   75, 100)

    -- ══════════════════════════════════════════════════════════════════
    -- NOTIFICATION
    -- ══════════════════════════════════════════════════════════════════
    local function ShowNotify(titleText, contentText)
        local sg = Instance.new("ScreenGui")
        sg.Name = "ZiliConfigNotify"
        sg.ResetOnSpawn = false
        sg.Parent = gethui and gethui() or game:GetService("CoreGui")

        local notif = Instance.new("Frame", sg)
        notif.Size         = UDim2.new(0, 270, 0, 68)
        notif.Position     = UDim2.new(1, 290, 1, -88)
        notif.AnchorPoint  = Vector2.new(1, 1)
        notif.BackgroundColor3 = Color3.fromRGB(10, 11, 24)
        notif.BorderSizePixel  = 0
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 9)

        local accent = Instance.new("Frame", notif)
        accent.Size             = UDim2.new(0, 3, 0.7, 0)
        accent.Position         = UDim2.new(0, 0, 0.15, 0)
        accent.BackgroundColor3 = GOLD
        accent.BorderSizePixel  = 0
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

        local stroke = Instance.new("UIStroke", notif)
        stroke.Color       = GOLD
        stroke.Thickness   = 1.5
        stroke.Transparency = 0.2

        local topBar = Instance.new("Frame", notif)
        topBar.Size             = UDim2.new(1, 0, 0, 26)
        topBar.BackgroundColor3 = Color3.fromRGB(14, 15, 32)
        topBar.BorderSizePixel  = 0
        Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 9)
        local topBarExt = Instance.new("Frame", topBar)
        topBarExt.Size             = UDim2.new(1, 0, 0, 9)
        topBarExt.Position         = UDim2.new(0, 0, 1, -9)
        topBarExt.BackgroundColor3 = Color3.fromRGB(14, 15, 32)
        topBarExt.BorderSizePixel  = 0

        local title = Instance.new("TextLabel", notif)
        title.Size                = UDim2.new(1, -22, 0, 22)
        title.Position            = UDim2.new(0, 14, 0, 3)
        title.BackgroundTransparency = 1
        title.Text                = titleText
        title.TextColor3          = GOLD2
        title.Font                = Enum.Font.GothamBold
        title.TextSize            = 13
        title.TextXAlignment      = Enum.TextXAlignment.Left

        local content = Instance.new("TextLabel", notif)
        content.Size              = UDim2.new(1, -22, 0, 36)
        content.Position          = UDim2.new(0, 14, 0, 28)
        content.BackgroundTransparency = 1
        content.Text              = contentText
        content.TextColor3        = Color3.fromRGB(237, 232, 218)
        content.Font              = Enum.Font.GothamSemibold
        content.TextSize          = 12
        content.TextXAlignment    = Enum.TextXAlignment.Left
        content.TextWrapped       = true

        TweenService:Create(notif, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -14, 1, -88)}):Play()

        task.delay(3, function()
            local fade = TweenService:Create(notif,
                TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 290, 1, -88), BackgroundTransparency = 1})
            fade:Play()
            fade.Completed:Connect(function() sg:Destroy() end)
        end)
    end

    -- ══════════════════════════════════════════════════════════════════
    -- HELPERS
    -- ══════════════════════════════════════════════════════════════════
    local function DeepCopy(v)
        if type(v) == "table" then
            local t = {}
            for k, val in pairs(v) do t[k] = DeepCopy(val) end
            return t
        end
        return v
    end

    local function Tween(obj, t, props)
        TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
    end

    -- Apply toggle visual (Btn, Strk, Thumb) and optional MasterBar
    -- FIX #2: Use per-entry AccentCol/AccentDark (updated by ApplyTheme) so that
    -- a config load restores toggles with the CURRENT theme colour, not stale gold.
    local function ApplyToggleVisual(data, on)
        local acMain  = (data.AccentCol  and data.AccentCol)  or GOLD2
        local acDark  = (data.AccentDark and data.AccentDark) or GOLDD
        local acStroke= acMain
        if data.Btn  then Tween(data.Btn,  0.2, {BackgroundColor3 = on and acDark or BG5}) end
        if data.Strk then Tween(data.Strk, 0.2, {Color            = on and acMain or GOLD3}) end
        if data.Thumb then
            Tween(data.Thumb, 0.2, {
                BackgroundColor3 = on and acMain or TEXT3,
                Position         = on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8),
            })
        end
        if data.MasterBar then
            Tween(data.MasterBar, 0.35, {BackgroundColor3 = on and GREEN or GOLD})
        end
        -- Stats-style Auto Add button
        -- FIX: dùng GOLDD (50,37,12) giống tự nhấn + dùng Tween thay direct-set
        if data.Btn and data.Btn:IsA("TextButton") and data.Btn.Text ~= "" then
            -- This is a stat add button, not a pill toggle
            if on then
                Tween(data.Btn, 0.2, {BackgroundColor3 = GOLDD})
                data.Btn.TextColor3 = Color3.fromRGB(10, 8, 2)
                data.Btn.Text       = "● Adding..."
            else
                Tween(data.Btn, 0.2, {BackgroundColor3 = BG5})
                data.Btn.TextColor3 = GOLD2
                data.Btn.Text       = "Auto Add"
            end
            if data.Strk then Tween(data.Strk, 0.2, {Color = on and GOLD2 or GOLD3}) end
        end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- GET CURRENT SETTINGS  (self-describing: scans TogglesData)
    -- ══════════════════════════════════════════════════════════════════
    local function GetCurrentSettings(AutoStatsData, TogglesData)
        local settings = { Stats = {}, Toggles = {}, Values = {} }

        -- Stats
        if AutoStatsData then
            for stat, data in pairs(AutoStatsData) do
                local cap = data.Cap or 0
                if data.Box and data.Box.Text ~= "" then
                    cap = tonumber(data.Box.Text) or cap
                end
                settings.Stats[stat] = { Active = data.Active or false, Cap = cap }
            end
        end

        -- Scan ALL keys in TogglesData
        if TogglesData then
            for key, data in pairs(TogglesData) do
                -- Values: anything that has a .Value field
                if data.Value ~= nil then
                    local v = DeepCopy(data.Value)
                    -- Sanitise multi-select tables: keep only true entries
                    if type(v) == "table" then
                        local clean = {}
                        for k, val in pairs(v) do
                            if val == true then clean[k] = true end
                        end
                        v = clean
                    end
                    -- Sanitise scalar values (numbers, strings, booleans)
                    if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
                        settings.Values[key] = v
                    elseif type(v) == "table" then
                        settings.Values[key] = v
                    end
                end
                -- Toggles: anything that has .Active (and is not purely a value entry)
                if data.Active ~= nil then
                    settings.Toggles[key] = data.Active == true
                end
            end
        end

        return settings
    end

    -- ══════════════════════════════════════════════════════════════════
    -- APPLY SETTINGS  (restore from file)
    -- ══════════════════════════════════════════════════════════════════
    local function ApplySettings(settings, AutoStatsData, TogglesData)

        -- ── 1. Stats ─────────────────────────────────────────────────
        if settings.Stats and AutoStatsData then
            for statName, saved in pairs(settings.Stats) do
                local data = AutoStatsData[statName]
                if not data then continue end
                data.Active = saved.Active or false
                data.Cap    = saved.Cap    or 0
                if data.Box then
                    data.Box.Text = data.Cap > 0 and tostring(data.Cap) or ""
                end
                ApplyToggleVisual(data, data.Active)
                if data.Callback then
                    pcall(function() data.Callback(data.Active) end)
                end
            end
        end

        -- ── 2. Values FIRST (so callbacks can read correct Value) ────
        if settings.Values and TogglesData then
            for key, saved in pairs(settings.Values) do
                local data = TogglesData[key]
                if not data then continue end

                data.Value = DeepCopy(saved)

                -- Update HeadBtn text (TextBox or TextLabel badge)
                if data.HeadBtn then
                    if type(saved) == "table" then
                        local ct = 0
                        for _, v in pairs(saved) do if v then ct = ct + 1 end end
                        pcall(function()
                            data.HeadBtn.Text = ct > 0 and (ct .. " Selected") or "Select..."
                        end)
                    else
                        pcall(function()
                            data.HeadBtn.Text = (saved ~= nil and tostring(saved) ~= "")
                                and tostring(saved) or "Select..."
                        end)
                    end
                end

                -- Fire callback so downstream modules update
                if data.Callback then
                    pcall(function() data.Callback(data.Value) end)
                end
            end
        end

        -- ── 3. Toggles LAST (modules may depend on Values) ───────────
        if settings.Toggles and TogglesData then
            for toggleKey, savedState in pairs(settings.Toggles) do
                local data = TogglesData[toggleKey]
                if not data then continue end

                data.Active = savedState == true
                ApplyToggleVisual(data, data.Active)

                if data.Callback then
                    pcall(function() data.Callback(data.Active) end)
                end
            end
        end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- SYNC DROPDOWN / SPECIAL UI  (after load)
    -- ══════════════════════════════════════════════════════════════════
    local function SyncSpecialUI(TogglesData)
        if not TogglesData then return end
        -- Any entry with UpdateFn (race buttons, hub buttons, etc.)
        for _, data in pairs(TogglesData) do
            if data.UpdateFn then
                pcall(function() data.UpdateFn() end)
            end
        end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- FILE LIST  (refresh config list in UI)
    -- ══════════════════════════════════════════════════════════════════
    local function Refresh(UI)
        if not UI.ConfigList then return end
        for _, child in ipairs(UI.ConfigList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local filterText = (UI.SearchBox and UI.SearchBox.Text:lower()) or ""
        local files = {}
        pcall(function() files = listfiles(ConfigFolder) end)

        for _, filePath in ipairs(files) do
            pcall(function()
                local fileName = filePath:match("([^/\\]+)%.json$")
                if not fileName then return end
                if filterText ~= "" and not fileName:lower():find(filterText, 1, true) then return end

                local btn = Instance.new("TextButton", UI.ConfigList)
                btn.Size             = UDim2.new(1, -10, 0, 35)
                btn.BackgroundColor3 = Color3.fromRGB(30, 28, 52)
                btn.Text             = "  📄  " .. fileName
                btn.TextColor3       = Color3.fromRGB(210, 200, 180)
                btn.Font             = Enum.Font.GothamSemibold
                btn.TextSize         = 13
                btn.ZIndex           = 15
                btn.TextXAlignment   = Enum.TextXAlignment.Left
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                Instance.new("UIStroke", btn).Color        = Color3.fromRGB(50, 40, 15)
                Instance.new("UIStroke", btn).Thickness    = 1

                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(45,42,70)}):Play()
                end)
                btn.MouseLeave:Connect(function()
                    if UI.ConfigNameBox and UI.ConfigNameBox.Text ~= fileName then
                        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,28,52)}):Play()
                    end
                end)

                btn.MouseButton1Click:Connect(function()
                    if UI.ConfigNameBox then UI.ConfigNameBox.Text = fileName end
                    -- highlight selected
                    for _, c in ipairs(UI.ConfigList:GetChildren()) do
                        if c:IsA("TextButton") then
                            c.BackgroundColor3 = Color3.fromRGB(30, 28, 52)
                        end
                    end
                    btn.BackgroundColor3 = Color3.fromRGB(55, 42, 12)
                end)
            end)
        end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- LOAD BY NAME  (public API — called by multi-acc on lobby start)
    -- ══════════════════════════════════════════════════════════════════
    function ConfigManager.LoadByName(name, AutoStatsData, TogglesData)
        if not name or name == "" then return false end
        -- strip whitespace
        name = name:match("^%s*(.-)%s*$")
        local path = ConfigFolder .. "/" .. name .. ".json"
        if not isfile(path) then return false end
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(decoded) ~= "table" then return false end
        ApplySettings(decoded, AutoStatsData, TogglesData)
        SyncSpecialUI(TogglesData)
        ShowNotify("📂 Config Loaded", "Multi-acc: " .. name)
        return true
    end

    -- ══════════════════════════════════════════════════════════════════
    -- INIT  (called from MainHub after all UI is built)
    -- ══════════════════════════════════════════════════════════════════
    function ConfigManager.Init(UI, AutoStatsData, TogglesData)

        -- Search box filter
        if UI.SearchBox then
            UI.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                Refresh(UI)
            end)
        end

        -- ── CREATE ───────────────────────────────────────────────────
        UI.CreateBtn.MouseButton1Click:Connect(function()
            if not UI.ConfigNameBox or UI.ConfigNameBox.Text == "" then return end
            local name = UI.ConfigNameBox.Text
            local data = GetCurrentSettings(AutoStatsData, TogglesData)
            local ok, err = pcall(function()
                writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
            end)
            if ok then
                Refresh(UI)
                ShowNotify("✅ Config Created", "Saved as: " .. name)
            else
                ShowNotify("❌ Create Failed", tostring(err))
            end
        end)

        -- ── SAVE ─────────────────────────────────────────────────────
        UI.SaveBtn.MouseButton1Click:Connect(function()
            if not UI.ConfigNameBox or UI.ConfigNameBox.Text == "" then return end
            local name = UI.ConfigNameBox.Text
            local path = ConfigFolder .. "/" .. name .. ".json"
            if not isfile(path) then
                ShowNotify("⚠ Not Found", "Config not found. Use Create first.")
                return
            end
            local data = GetCurrentSettings(AutoStatsData, TogglesData)
            local ok, err = pcall(function()
                writefile(path, HttpService:JSONEncode(data))
            end)
            if ok then
                ShowNotify("💾 Config Saved", "Updated: " .. name)
            else
                ShowNotify("❌ Save Failed", tostring(err))
            end
        end)

        -- ── LOAD ─────────────────────────────────────────────────────
        UI.LoadBtn.MouseButton1Click:Connect(function()
            if not UI.ConfigNameBox or UI.ConfigNameBox.Text == "" then return end
            local path = ConfigFolder .. "/" .. UI.ConfigNameBox.Text .. ".json"
            if not isfile(path) then
                ShowNotify("⚠ File Not Found", UI.ConfigNameBox.Text .. ".json not found.")
                return
            end
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(readfile(path))
            end)
            if not ok or type(decoded) ~= "table" then
                ShowNotify("❌ Load Failed", "Could not parse config file.")
                return
            end
            ApplySettings(decoded, AutoStatsData, TogglesData)
            SyncSpecialUI(TogglesData)
            ShowNotify("📂 Config Loaded", "Loaded: " .. UI.ConfigNameBox.Text)
        end)

        -- ── DELETE ───────────────────────────────────────────────────
        UI.DeleteBtn.MouseButton1Click:Connect(function()
            if not UI.ConfigNameBox or UI.ConfigNameBox.Text == "" then return end
            local path = ConfigFolder .. "/" .. UI.ConfigNameBox.Text .. ".json"
            if isfile(path) then
                pcall(function() delfile(path) end)
                Refresh(UI)
                ShowNotify("🗑 Config Deleted", "Removed: " .. UI.ConfigNameBox.Text)
                UI.ConfigNameBox.Text = ""
            else
                ShowNotify("⚠ Not Found", "Nothing to delete.")
            end
        end)

        -- ── REFRESH ──────────────────────────────────────────────────
        UI.RefreshBtn.MouseButton1Click:Connect(function()
            Refresh(UI)
            ShowNotify("🔄 Refreshed", "Config list updated.")
        end)

        -- ── SET AUTO LOAD ─────────────────────────────────────────────
        if UI.SetAutoLoadBtn then
            UI.SetAutoLoadBtn.MouseButton1Click:Connect(function()
                if not UI.ConfigNameBox or UI.ConfigNameBox.Text == "" then return end
                local name = UI.ConfigNameBox.Text
                if not isfile(ConfigFolder .. "/" .. name .. ".json") then
                    ShowNotify("⚠ Not Found", "Save config first before setting auto load.")
                    return
                end
                pcall(function() writefile(ConfigFolder .. "/autoload.txt", name) end)
                ShowNotify("⭐ Auto Load Set", "Will auto-load: " .. name)
            end)
        end

        -- ── AUTO LOAD ON START ────────────────────────────────────────
        -- Skip nếu multi-acc mode: acc trigger sẽ load config riêng
        local autoLoadPath = ConfigFolder .. "/autoload.txt"
        if not getgenv()._ZiliMultiAccData and isfile(autoLoadPath) then
            local ok, autoName = pcall(function() return readfile(autoLoadPath) end)
            if ok and autoName and autoName ~= "" then
                -- strip any trailing newline/whitespace
                autoName = autoName:match("^%s*(.-)%s*$")
                local path = ConfigFolder .. "/" .. autoName .. ".json"
                if isfile(path) then
                    local ok2, decoded = pcall(function()
                        return HttpService:JSONDecode(readfile(path))
                    end)
                    if ok2 and type(decoded) == "table" then
                        -- FIX #1: All pages are now force-built before Config init, so
                        -- increase delay slightly to let all page callbacks settle.
                        task.delay(1.5, function()
                            ApplySettings(decoded, AutoStatsData, TogglesData)
                            SyncSpecialUI(TogglesData)
                            if UI.ConfigNameBox then UI.ConfigNameBox.Text = autoName end
                            ShowNotify("⚡ Auto Loaded", "Config: " .. autoName)
                        end)
                    end
                end
            end
        end

        Refresh(UI)
    end

    return ConfigManager
end

-- 📦 MODULE: IslandData.lua
__modules["Island/IslandData"] = function()
    local IslandData1 = {
        ["???? Shrine"] = Vector3.new(-7348.86, 3.27, -14950.54),
        ["A Rock"] = Vector3.new(2534.69, 7.33, -8370.14),
        ["Coco Island"] = Vector3.new(-3086.87, 94.54, -11755.48),
        ["Colosseum"] = Vector3.new(-2031.47, 6.85, -7666.31),
        ["Fishman Cave"] = Vector3.new(1842.72, 3.84, -12170.62),
        ["Fishman Islands"] = Vector3.new(1791.87, -94.83, -12327.67),
        ["Gravito's Fort"] = Vector3.new(264.84, 7.64, -11477.32),
        ["Island Of Zou"] = Vector3.new(-3121.06, 11.73, -5256.59),
        ["Kori Island"] = Vector3.new(-4266.8, 169.48, -2976.2),
        ["Land of the Sky"] = Vector3.new(3452.06, 1438.24, -9077.78),
        ["Logue Town"] = Vector3.new(-6587.53, 7.22, -7674.48),
        ["Marine Base G-1"] = Vector3.new(-5996.11, 57.24, -11489.15),
        ["Marine Fort F-1"] = Vector3.new(424.6, 19.45, -4479.89),
        ["Mysterious Cliff"] = Vector3.new(78.64, 412.74, -8280.99),
        ["Orange Town"] = Vector3.new(-4456.83, 5.3, -6640.93),
        ["Restaurant Baratie"] = Vector3.new(-2949.38, 6.31, -6696.07),
        ["Reverse Mountain"] = Vector3.new(-8001.37, 52.22, -8571.84),
        ["Roca Island"] = Vector3.new(1532.26, 155.38, -6573.02),
        ["Sandora"] = Vector3.new(-1540.96, 3.97, -3352.63),
        ["Shark Park"] = Vector3.new(-1583.31, 12.29, -10076.3),
        ["Shell's Town"] = Vector3.new(-1337.18, 4.12, -5025.98),
        ["Sphinx Island"] = Vector3.new(-4015.28, 41.28, -9154.84),
        ["Town of Beginnings"] = Vector3.new(-522.6, 8.07, -3396),
    }
    local IslandData2 = {
        ["Colosseum of Arc"] = Vector3.new(2218.55, 5.05, 6060.36),
        ["Desert Kingdom"] = Vector3.new(-3674.02, 19.66, 403.75),
        ["Dokkan Island"] = Vector3.new(9205.57, 2.97, -11822.75),
        ["Foro Island"] = Vector3.new(8162.13, 6.29, 4331.51),
        ["Ghost Ship"] = Vector3.new(5134.229, -569.914062, -11901.4492),
        ["Impel Base"] = Vector3.new(5935.1, 6.02, -9465.39),
        ["Mysterious Reef"] = Vector3.new(10130.2, -75.28, -27.63),
        ["Rose Kingdom"] = Vector3.new(9249.99, 25.27, 7849.86),
        ["Rovo Island"] = Vector3.new(-6358.93, 128.31, 408.79),
        ["Reverse Mountain"] = Vector3.new(-9044.43359, 113.108398, 434.633789),
        ["Sakura Stronghold"] = Vector3.new(6064.37, 12.84, -92.94),
        ["Sashi Island"] = Vector3.new(-1566.49, 38.86, -6479.77),
        ["Sett's Arena"] = Vector3.new(-7736.31, 10.27, -8113.47),
        ["Spirit Island"] = Vector3.new(-1331.21, 69.46, 10184.65),
        ["Thriller Bark"] = Vector3.new(9380.87, 15.86, -7004.65),
        ["Turtleback Cave"] = Vector3.new(1746.53, 20.07, -10555.12),
        ["Umi Island"] = Vector3.new(12775.84, 20.8, 2762.12),
        ["Whole Cake Island"] = Vector3.new(-6856.07, 27.07, 9245.86),
    }
    -- Dùng PlaceId để detect sea (reliable hơn stat value)
    if game.PlaceId == 7465136166 then return IslandData2 end
    return IslandData1
end

__modules["BYPASS_ANTICHEAT"] = function()
    local identity = (setthreadcontext or setthreadidentity or setidentity)
    if identity then pcall(identity, 7) end

    local cloneref = cloneref or function(x) return x end
    local hookmetamethod = hookmetamethod
    local getnamecallmethod = getnamecallmethod
    local newcclosure = newcclosure
    local typeof = typeof
    local math_random = math.random
    local os_clock = os.clock
    local pcall = pcall
    local task_wait = task.wait
    local task_spawn = task.spawn
    local table_insert = table.insert
    local table_remove = table.remove

    local game = cloneref(game)
    local RunService = cloneref(game:GetService("RunService"))
    local ReplicatedFirst = cloneref(game:GetService("ReplicatedFirst"))

    local Bypass = {}

    -- [A] THE BLINDER: ACTOR ERROR LOGGER DISABLE (VỚI TÍNH NĂNG TỰ KICK)
    local function BlindErrorLogger()
        task_spawn(function()
            pcall(function()
                local lp = game:GetService("Players").LocalPlayer
                local actor = ReplicatedFirst:WaitForChild("paul greyrat", 10) 
                
                -- 1. NẾU DEV ĐỔI TÊN HOẶC XÓA FILE -> KICK "Bypass Failed !"
                if not actor then
                    if game.PlaceId ~= 1730877806 and game.PlaceId ~= 7465136166 then
                        lp:Kick("Bypass Failed !")
                    end
                    return
                end

                -- 2. NẾU EXECUTOR KHÔNG HỖ TRỢ -> KICK "not support"
                if type(run_on_actor) ~= "function" then
                    if game.PlaceId ~= 1730877806 and game.PlaceId ~= 7465136166 then
                        lp:Kick("BAD EXECUTOR !!!")
                    end
                    return
                end

                -- ĐỢI ACTOR LOAD XONG
                while #actor:GetChildren() < 1 do task_wait(0.1) end

                -- 3. CHUI VÀO ACTOR CẮT DÂY CAMERA LỖI
                run_on_actor(actor, [[
                    local isBypassed = false
                    local Context = game:GetService('ScriptContext')
                    
                    for _, conn in next, getconnections(Context.Error) do 
                        if conn.Function and debug.getinfo(conn.Function).nups > 1 then 
                            hookfunction(conn.Function, function() end)
                            isBypassed = true
                        end
                    end
                    
                    -- NẾU CẮT DÂY BÊN TRONG THẤT BẠI -> KICK "Bypass Failed !"
                    if not isBypassed and game.PlaceId ~= 1730877806 and game.PlaceId ~= 7465136166 then
                        game.Players.LocalPlayer:Kick("Bypass Failed !")
                    end
                ]])
            end)
        end)
    end

    -- [B] BEHAVIORAL DRIFT (Session Variance)
    local SessionStart = os_clock()
    local function GetSessionDrift(baseValue)
        local sessionTime = os_clock() - SessionStart
        local driftFactor = 0
        if sessionTime < 300 then driftFactor = math_random(-50, 0) / 100 
        elseif sessionTime < 1200 then driftFactor = math_random(-120, -40) / 100
        else driftFactor = math_random(-250, -80) / 100 end
        return baseValue + driftFactor
    end

    -- [C] ASYNC QUEUE SYSTEM
    local AsyncQueue = {}
    RunService.Heartbeat:Connect(function(deltaTime)
        for i = #AsyncQueue, 1, -1 do
            local taskObj = AsyncQueue[i]
            taskObj.timer = taskObj.timer - deltaTime
            if taskObj.timer <= 0 then
                taskObj.remote:FireServer(unpack(taskObj.args))
                table_remove(AsyncQueue, i)
            end
        end
    end)

    -- [D] ZERO-YIELD SPOOFING HOOK
    local RemoteProfiles = {}

    function Bypass.Init()
        BlindErrorLogger()

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end

            local args = {...}
            if not RemoteProfiles[self] then RemoteProfiles[self] = { baselines = {}, baselineIndex = 1 } end
            local profile = RemoteProfiles[self]

            if typeof(args[1]) == "table" and args[1].WalkSpeed and args[1].WalkSpeed <= 20 then
                profile.baselines[profile.baselineIndex] = { WalkSpeed = args[1].WalkSpeed }
                profile.baselineIndex = (profile.baselineIndex % 5) + 1
            end

            -- SPOOFING TỐC ĐỘ HACK (> 20)
            if typeof(args[1]) == "table" and args[1].WalkSpeed and args[1].WalkSpeed > 20 then
                local sample = profile.baselines[math_random(1, #profile.baselines)] or { WalkSpeed = 16 }
                args[1].WalkSpeed = GetSessionDrift(sample.WalkSpeed or 16)
                
                table_insert(AsyncQueue, {
                    remote = self,
                    args = args,
                    timer = (math_random(20, 80) / 1000) 
                })
                return nil
            end

            return oldNamecall(self, ...)
        end))
        
        return true
    end

    Bypass.Init()
    return Bypass
end

-- 📦 MODULE: TweenToIsland.lua (BẢN FULL HOÀN CHỈNH - FIX CHUẨN TAKESTAM)
__modules["Island/TWEEN TO ISLAND"] = function()
    local Tween = {}
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualUser = game:GetService("VirtualUser")

    local LocalPlayer = Players.LocalPlayer
    local MAX_SPEED = 90
    local lastMerchantCheckMinute = -1
    Tween.IsTeleporting = false
    Tween.MoveConn = nil
    Tween.NoclipConn = nil 
    Tween.FakeFloor = nil
    Tween.Notify = function(title, content, duration) end

    local VEC_ZERO = Vector3.new(0, 0, 0)
    local OFFSET_FAKEFLOOR = CFrame.new(0, -3.05, 0)
    
    -- Biến khóa di chuyển khi đang nháy lên mặt nước lấy hơi
    local isFlicking = false 

    local function getRoot()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            return char.HumanoidRootPart
        end
        return nil
    end

    -- =====================================================================
    -- ⏱️ TIMER 20 GIÂY: TỰ ĐỘNG NHÁY LÊN 7.33 RỒI LẶN XUỐNG
    -- =====================================================================
    local function StartSimpleFlickTimer()
        task.spawn(function()
            local timer = 0
            while Tween.IsTeleporting do
                task.wait(1) 
                
                if not isFlicking then
                    local root = getRoot()
                    
                    if root and root.Position.Y < -20 and root.Position.Y > -500 then
                        timer = timer + 1
                        
                        if timer >= 20 then
                            Tween.Notify("Oxygen", "Nháy lên 7.33 bơm bong bóng!", 1)
                            isFlicking = true
                            
                            local currentSafeCF = root.CFrame 
                            
                            root.CFrame = CFrame.new(currentSafeCF.X, 7.33, currentSafeCF.Z)
                            root.Velocity = VEC_ZERO
                            
                            task.wait(0.5) 
                            
                            root.CFrame = currentSafeCF
                            
                            timer = 0
                            isFlicking = false
                        end
                    else
                        timer = 0
                    end
                end
            end
        end)
    end

    -- =====================================================================
    -- STAMINA SPOOF (Đã fix chuẩn: 0.505 + kèm tọa độ hiện tại)
    -- =====================================================================
    local Events   = ReplicatedStorage:WaitForChild("Events", 5)
    local TakeStam = Events and Events:WaitForChild("takestam", 5)

    local isSpoofingStamina = false
    local function StartStaminaSpoof()
        if isSpoofingStamina then return end
        isSpoofingStamina = true
        task.spawn(function()
            while isSpoofingStamina and task.wait(0.05) do
                if TakeStam and TakeStam.Parent then
                    pcall(function() 
                        local root = getRoot()
                        local currentCF = root and root.CFrame or CFrame.new()
                        -- Gửi chuẩn tọa độ để không bị văng
                        TakeStam:FireServer(0.505, "dash", currentCF) 
                    end)
                else break end
            end
        end)
    end
    local function StopStaminaSpoof()
        isSpoofingStamina = false
    end

    -- =====================================================================
    -- ANTI-AFK & ANTI-SIT
    -- =====================================================================
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do conn:Disable() end
    end)
    if ZiliState.AntiAfkConnection then ZiliState.AntiAfkConnection:Disconnect() end
    ZiliState.AntiAfkConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    local function PreventSitting(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if humanoid.Sit then humanoid.Sit = false; humanoid.Jump = true end
        end
    end
    if LocalPlayer.Character then PreventSitting(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(PreventSitting)

    -- =====================================================================
    -- TWEEN LOGIC
    -- =====================================================================

    function Tween.Stop()
        Tween.IsTeleporting = false
        isFlicking = false
        StopStaminaSpoof()
        if Tween.MoveConn then Tween.MoveConn:Disconnect(); Tween.MoveConn = nil end
        if Tween.NoclipConn then Tween.NoclipConn:Disconnect(); Tween.NoclipConn = nil end

        local root = getRoot()
        if root then
            for _, v in pairs(root:GetChildren()) do 
                if v.Name == "ZILI_AntiGravity" then v:Destroy() end 
            end
            root.Velocity = VEC_ZERO
        end
        if Tween.FakeFloor then Tween.FakeFloor:Destroy(); Tween.FakeFloor = nil end
    end

    function Tween.Start(targetData)
        Tween.Stop()
        Tween.IsTeleporting = true
        StartStaminaSpoof()
        StartSimpleFlickTimer()
        
        Tween.NoclipConn = RunService.Stepped:Connect(function()
            if Tween.IsTeleporting and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)

        local route = {}
        local finalDest = type(targetData) == "table" and targetData[#targetData] or targetData
        local initialRoot = getRoot()
        if not initialRoot then return end

        local function isPortalPos(pos)
            return pos.Y < -20 and pos.Y > -500
        end

        -- KỊCH BẢN 1: VÀO ĐẢO NGƯỜI CÁ
        if initialRoot.Position.Y > -1000 and finalDest.Y < -1000 then
            table.insert(route, {
                pos = Vector3.new(1842.72, -50, -12170.62), 
                isPortal = true,
                isFishmanIn = true,
                isFishmanExit = false,
                msg = "Entering Cave... Heading to Whirlpool"
            })
        end

        -- KỊCH BẢN 2: RA ĐẢO NGƯỜI CÁ
        if initialRoot.Position.Y < -1000 and finalDest.Y > -1000 then
            table.insert(route, {
                pos = Vector3.new(8585.12, -2138.84, -17087.38), 
                isPortal = true, 
                isFishmanIn = false,
                isFishmanExit = true,
                msg = "Leaving Cave... Heading to Exit Portal"
            })
        end

        -- KỊCH BẢN 3: CÁC ĐIỂM CÒN LẠI
        if type(targetData) == "table" then
            for i, pos in ipairs(targetData) do
                local isP = (i < #targetData) or isPortalPos(pos)
                table.insert(route, {
                    pos = pos, isPortal = isP, isFishmanIn = false, isFishmanExit = false,
                    msg = isP and "Heading to Portal..." or "Heading to final destination..."
                })
            end
        else
            local isP = isPortalPos(targetData)
            table.insert(route, {
                pos = targetData, isPortal = isP, isFishmanIn = false, isFishmanExit = false,
                msg = isP and "Heading to Portal..." or "Heading to destination..."
            })
        end

        local function flyTo(stepData, onComplete)
            local root = getRoot()
            local waitTime = 0
            while not root and waitTime < 10 do
                task.wait(0.5)
                waitTime = waitTime + 0.5
                root = getRoot()
            end
            
            if not Tween.IsTeleporting or not root then Tween.Stop(); return end

            if not Tween.FakeFloor then 
                Tween.FakeFloor = Instance.new("Part")
                Tween.FakeFloor.Name = "ZILI_FakeFloor"
                Tween.FakeFloor.Size = Vector3.new(15, 2, 15)
                Tween.FakeFloor.Anchored = true
                Tween.FakeFloor.Transparency = 1 
                Tween.FakeFloor.Parent = Workspace
            end

            local antiGravity = root:FindFirstChild("ZILI_AntiGravity") or Instance.new("BodyVelocity")
            antiGravity.Name = "ZILI_AntiGravity"
            antiGravity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            antiGravity.Velocity = VEC_ZERO
            antiGravity.Parent = root

            local targetPos = stepData.pos

            Tween.MoveConn = RunService.Heartbeat:Connect(function(deltaTime)
                if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end
                
                if isFlicking then return end 

                pcall(function()
                    ZiliState.swimming = false
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("UpperTorso") then
                        for _, v in pairs(char.UpperTorso:GetChildren()) do
                            if v:IsA("BodyPosition") then v:Destroy() end
                        end
                    end
                end)

                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                root.Velocity = VEC_ZERO

                local currentPos = root.Position
                local distXZ = (Vector2.new(targetPos.X, targetPos.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude
                local max_step = math.min(MAX_SPEED * deltaTime, 120)

                -- LẶN XUỐNG Y = -97.15 NẾU KHÔNG PHẢI ĐẢO NGƯỜI CÁ
                if not stepData.isFishmanIn and not stepData.isFishmanExit then
                    if math.abs(currentPos.Y - (-97.15)) > 10 and distXZ > 50 then
                        Tween.MoveConn:Disconnect()
                        task.spawn(function()
                            root.CFrame = CFrame.new(currentPos.X, -97.15, currentPos.Z)
                            task.wait(0.2)
                            flyTo(stepData, onComplete)
                        end)
                        return
                    end
                end

                -- ĐẾN GẦN MỤC TIÊU (Dưới 30 studs)
                if distXZ < 30 then 
                    Tween.MoveConn:Disconnect()
                    
                    task.spawn(function()
                        local waited = 0
                        
                        if stepData.isFishmanExit then
                            root.CFrame = CFrame.lookAt(root.Position, targetPos)
                            task.wait(0.1)
                            
                            while waited < 20 do
                                if not Tween.IsTeleporting or not root then break end
                                if (root.Position - targetPos).Magnitude > 200 then break end
                                
                                root.CFrame = root.CFrame * CFrame.new(0, 0, -3)
                                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                
                                task.wait(0.15)
                                waited = waited + 0.15
                            end

                        elseif stepData.isPortal or stepData.isFishmanIn then
                            local toggle = 1 
                            while waited < 20 do
                                if not Tween.IsTeleporting or not root then break end
                                if (root.Position - targetPos).Magnitude > 200 then break end
                                
                                local wiggle = toggle * 1
                                root.CFrame = CFrame.new(targetPos.X + wiggle, targetPos.Y, targetPos.Z + wiggle)
                                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                
                                toggle = toggle * -1
                                task.wait(0.3)
                                waited = waited + 0.3
                            end
                            task.wait(1.5)

                        else
                            root.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                            if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                            task.wait(0.2)
                        end

                        if onComplete then onComplete() end
                    end)
                else
                    -- BAY ĐẾN MỤC TIÊU NGẦM (HOẶC THEO CƠ CHẾ ĐẢO NGƯỜI CÁ)
                    local safeY = (stepData.isFishmanIn or stepData.isFishmanExit) and targetPos.Y or -97.15
                    local activeTarget = Vector3.new(targetPos.X, safeY, targetPos.Z)
                    local dir = (activeTarget - currentPos).Unit
                    root.CFrame = CFrame.new(currentPos + dir * math.min(max_step, (activeTarget - currentPos).Magnitude))
                end
            end)
        end

        local function processRoute(index)
            if not Tween.IsTeleporting then return end
            if index > #route then
                Tween.Notify("Success", "Arrived at destination!", 3)
                Tween.Stop() 
                return
            end

            local step = route[index]
            if step.msg then Tween.Notify("Traveling", step.msg, 3) end

            flyTo(step, function()
                processRoute(index + 1) 
            end)
        end

        processRoute(1)
    end

    return Tween
end

-- 📦 MODULE: AutoFarmLevel.lua
__modules["Farm/AutoFarmLevel"] = function()
    local AutoFarmLevel = {}

    local cloneref = cloneref or function(o) return o end
    local Players           = cloneref(game:GetService("Players"))
    local RunService        = cloneref(game:GetService("RunService"))
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local Workspace         = cloneref(game:GetService("Workspace"))

    local Player       = Players.LocalPlayer
    local Events       = ReplicatedStorage:WaitForChild("Events")
    local CombatReg    = Events:WaitForChild("CombatRegister")
    local QuestEvent   = Events:WaitForChild("Quest")
    local TakestamEv   = Events:WaitForChild("takestam")
    local SetSpawnEv   = Events:WaitForChild("SetSpawn")
    local StatsFolder  = ReplicatedStorage:WaitForChild("Stats"..Player.Name)
    local Level        = StatsFolder.Stats:WaitForChild("Level")
    local SpawnPoint   = StatsFolder.Stats:WaitForChild("SpawnPoint")
    local CurrentQuest = StatsFolder:WaitForChild("Quest"):WaitForChild("CurrentQuest")

    local VEC_ZERO        = Vector3.new(0,0,0)
    local FAKE_FLOOR_OFF  = CFrame.new(0,-3.05,0)

    local _active         = false
    local spawnSetFor     = {}  -- [zoneKey] = bool, reset on respawn
    local questDoneFor    = {}  -- [zoneKey] = true khi oneTimeQuest đã hoàn thành
    local _farmNavigating = false  -- true khi isFishman đang dùng IslandTween bay đến npcPos (step 3)

    -- ═══════════════════════════════════════════════════════════════
    -- ZONE TABLE
    --   minLvl/maxLvl  : level range (maxLvl exclusive)
    --   islandPos      : first waypoint IslandTween flies to
    --   spawnPos       : stand here + call SetSpawn  (nil = skip)
    --   specialSpawn   : true → wait for "Robo" ProximityPrompt
    --   npcPos/npcName : quest giver
    --   mobName        : name fragment to match enemy  ("" = any)
    --   mobPos      : vị trí trung tâm lure — về đây spam combo
    --   isFishman      : needs underwater portal
    -- ═══════════════════════════════════════════════════════════════
    local ZONES = {
        -- 1-15 · Town of Beginnings
        { minLvl=1,   maxLvl=15,
          islandPos=Vector3.new(-522.6,8.07,-3396),
          spawnPos=nil, specialSpawn=false,
          npcPos=Vector3.new(-579.29,5.94,-3431.57), npcName="Help Daph",
          mobName="Bandit",
          mobPos=Vector3.new(-644.67,8.44,-3472.14), isFishman=false },
        -- 15-30 · Sandora
        { minLvl=15,  maxLvl=30,
          islandPos=Vector3.new(-1540.96,3.97,-3352.63),
          spawnPos=Vector3.new(-1540.85,4.97,-3339.83), specialSpawn=false,
          npcPos=Vector3.new(-1709.41,3.97,-3378.05), npcName="Help Noah",
          mobName="Desert Bandit",
          mobPos=Vector3.new(-1795.54,9.97,-3352.12), isFishman=false },
        -- 30-40 · Island Of Zou
        { minLvl=30,  maxLvl=40,
          islandPos=Vector3.new(-3121.06,11.73,-5256.59),
          spawnPos=Vector3.new(-3150,11.73,-5233.55), specialSpawn=false,
          npcPos=Vector3.new(-3172.7,11.73,-5226.69), npcName="Help Zen",
          mobName="Zou Inhabitant",
          mobPos=Vector3.new(-3232.65,10.6,-5263.51), isFishman=false },
        -- 40-110 · Restaurant Baratie
        { minLvl=40,  maxLvl=110,
          islandPos=Vector3.new(-2978.68,52.58,-6796.24),
          spawnPos=Vector3.new(-2978.68,52.58,-6796.24), specialSpawn=false,
          npcPos=Vector3.new(-2968.77,6.31,-6698.06), npcName="Help Rice",
          mobName="Krieg Pirate",
          mobPos=Vector3.new(-2963.43,12.12,-6773.14), isFishman=false,
          farmHover=-8 },  -- FARM_HOVER override: -8 (quái thấp)
        -- 110-160 · Land of the Sky  [SPECIAL — high altitude, Robo spawn]
        { minLvl=110, maxLvl=160,
          islandPos=Vector3.new(3710.77,1699.64,-9467.87),
          spawnPos=Vector3.new(3710.77,1699.64,-9467.87), specialSpawn=true,
          npcPos=Vector3.new(4095.2,1818.97,-9832.73), npcName="Help zhen",
          mobName="Castle Guard", mobNames={"Castle Guard","Head Guardian"},
          mobPos=Vector3.new(4176.41,1820.07,-9884.6),
          mobPos2=Vector3.new(4201.2,1908.07,-9906.98),
          unstuckPos=Vector3.new(4243.44,1865.97,-9956.55),
          isFishman=false, farmHover=9 },
        -- 160-190 · Gravito's Fort  [SPECIAL — Robo spawn]
        { minLvl=160, maxLvl=190,
          islandPos=Vector3.new(261.78,7.64,-11481.53),
          spawnPos=Vector3.new(261.78,7.64,-11481.53), specialSpawn=true,
          npcPos=Vector3.new(184.64,41.46,-11659.11), npcName="Help Miska",
          mobName="Gravito's Undermen",
          mobPos=Vector3.new(276.01,41.46,-11753.38), isFishman=false, farmHover=9 },
        -- 190-375 · Fishman Island  [SPECIAL — underwater portal]
        { minLvl=190, maxLvl=375,
          islandPos=Vector3.new(1791.87,-94.83,-12327.67),
          spawnPos=Vector3.new(7975.97,-2152.84,-17073.7), specialSpawn=false,
          npcPos=Vector3.new(7731.41,-2175.84,-17222.65), npcName="Help becky",
          mobName="Fishman Karate User",
          mobPos=Vector3.new(7720.74,-2176.84,-17312.48), isFishman=true },
        -- 375+ · Kori Island  [proxy spawn: Island Of Zou → swim qua Kori, quest 1 lần]
        { minLvl=375, maxLvl=999, sea=1,
          islandPos=Vector3.new(-4245.74,169.48,-2990.84),
          spawnPos=Vector3.new(-3150,11.73,-5233.55), specialSpawn=false,
          npcPos=Vector3.new(-4245.74,169.48,-2990.84), npcName="Road to Armament",
          mobName="Yeti",
          mobPos=Vector3.new(-4468.41,66.37,-2930.09), isFishman=false,
          needsSwim=true, oneTimeQuest=true, spawnTag="zou", farmHover=11, comboY=66.37 },

        -- ── SEA 2 ZONES ─────────────────────────────────────────────
        -- 375-425 · Thriller Bark [Sea 2]
        { minLvl=375, maxLvl=425, sea=2,
          islandPos=Vector3.new(9380.87,15.86,-7004.65),
          spawnPos=Vector3.new(9389.48,15.86,-7007.7), specialSpawn=false,
          npcPos=Vector3.new(10309.87,56.86,-7731.26), npcName="Help Poro",
          mobName="Zombie",
          mobPos=Vector3.new(10466.49,58.21,-7650.65), isFishman=false,
          islandTweenToNpc=true, spawnTag="thriller", farmHover=8 },
        -- 425-675 · Rose Kingdom [Sea 2]
        { minLvl=425, maxLvl=675, sea=2,
          islandPos=Vector3.new(9249.99,25.27,7849.86),
          spawnPos=Vector3.new(7478.84,22.02,10629.83), specialSpawn=false,
          npcPos=Vector3.new(7121.37,56.27,10550.83), npcName="Help PJ",
          mobName="Crazy Wolf",
          mobPos=Vector3.new(6956.38,20.77,10653.97),
          mobPos2=Vector3.new(6735.85,20.87,10565.92), isFishman=false,
          islandTweenToNpc=true, spawnTag="rose", farmHover=8.5, sideOffset=5 },
    }

    -- ═══════════════════════════════════════════════════════════════
    -- PHYSICS HELPERS
    -- ═══════════════════════════════════════════════════════════════
    local charParts = {}
    local function updateCharParts(char)
        table.clear(charParts)
        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(charParts,v) end
        end
    end
    if Player.Character then updateCharParts(Player.Character) end
    Player.CharacterAdded:Connect(function(char)
        spawnSetFor = {}  -- reset per-zone spawn flags on respawn
        char.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") then table.insert(charParts,v) end
        end)
        updateCharParts(char)
    end)
    Player.CharacterRemoving:Connect(function() table.clear(charParts) end)

    RunService.Stepped:Connect(function()
        if _active then
            for _,p in ipairs(charParts) do
                if p.CanCollide then p.CanCollide = false end
            end
        end
    end)

    local function ResetPhysics()
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _,v in ipairs(root:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("LinearVelocity")
               or v.Name=="ZILI_AntiGravity" or v.Name=="LF_VelocityNode" then v:Destroy() end
        end
        root.Velocity=VEC_ZERO; root.RotVelocity=VEC_ZERO
        pcall(function() root.AssemblyLinearVelocity=VEC_ZERO end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- ISLAND TWEEN
    --   Pattern giống TWEEN TO ISLAND:
    --     TP xuống -97.15 → swim ngang → flick lên 7.33 mỗi 20s → TP thẳng lên Y đích
    --   Áp dụng cho TẤT CẢ đảo kể cả đảo cao (Sky Island Y=1699, Gravito's Y=41)
    -- ═══════════════════════════════════════════════════════════════
    local IslandTween
    local function LoadIslandTween()
        local T = { IsTeleporting=false, MoveConn=nil, NoclipConn=nil, FakeFloor=nil }
        local MAX_SPEED    = 90
        local isFlicking   = false
        local isSpoofStam  = false
        local PORTAL_ENTER = Vector3.new(1842.72,-50,-12170.62)
        local PORTAL_EXIT  = Vector3.new(8585.12,-2138.84,-17087.38)

        local function getRoot()
            local ch = Player.Character
            return ch and ch:FindFirstChild("HumanoidRootPart")
        end

        local function StartStamSpoof()
            if isSpoofStam then return end; isSpoofStam = true
            task.spawn(function()
                while isSpoofStam and task.wait(0.05) do
                    local r = getRoot()
                    if TakestamEv and TakestamEv.Parent then
                        pcall(function() TakestamEv:FireServer(0.505,"dash",r and r.CFrame or CFrame.new()) end)
                    else break end
                end
            end)
        end

        -- Flick timer: nháy lên 7.33 mỗi 20s khi đang dưới nước (-20 > Y > -500)
        task.spawn(function()
            local timer = 0
            while true do
                task.wait(1)
                if T.IsTeleporting and not isFlicking then
                    local r = getRoot()
                    if r and r.Position.Y < -20 and r.Position.Y > -500 then
                        timer = timer + 1
                        if timer >= 20 then
                            isFlicking = true
                            local cf = r.CFrame
                            r.CFrame = CFrame.new(cf.X, 7.33, cf.Z); r.Velocity = VEC_ZERO
                            task.wait(0.5); r.CFrame = cf
                            timer = 0; isFlicking = false
                        end
                    else
                        timer = 0  -- reset nếu không còn dưới nước
                    end
                else
                    timer = 0
                end
            end
        end)

        function T.Stop()
            T.IsTeleporting=false; isFlicking=false; isSpoofStam=false
            if T.MoveConn   then T.MoveConn:Disconnect();   T.MoveConn   = nil end
            if T.NoclipConn then T.NoclipConn:Disconnect(); T.NoclipConn = nil end
            local r = getRoot()
            if r then
                for _,v in pairs(r:GetChildren()) do
                    if v.Name=="ZILI_AntiGravity" then v:Destroy() end
                end
                r.Velocity = VEC_ZERO
            end
            if T.FakeFloor then T.FakeFloor:Destroy(); T.FakeFloor=nil end
        end

        function T.Start(targetData)
            T.Stop(); T.IsTeleporting=true
            StartStamSpoof()

            T.NoclipConn = RunService.Stepped:Connect(function()
                if T.IsTeleporting and Player.Character then
                    for _,p in pairs(Player.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide=false end
                    end
                end
            end)

            local route    = {}
            local finalDest= type(targetData)=="table" and targetData[#targetData] or targetData
            local r0       = getRoot(); if not r0 then return end

            -- Portal waypoints
            if r0.Position.Y > -1000 and finalDest.Y < -1000 then
                table.insert(route, {pos=PORTAL_ENTER, isFishmanIn=true})
            end
            if r0.Position.Y < -1000 and finalDest.Y > -1000 then
                table.insert(route, {pos=PORTAL_EXIT, isFishmanExit=true})
            end
            if type(targetData)=="table" then
                for _,p in ipairs(targetData) do table.insert(route,{pos=p}) end
            else
                table.insert(route, {pos=targetData})
            end

            local function flyTo(step, onDone)
                local r = getRoot()
                if not T.IsTeleporting or not r then T.Stop(); return end

                if not T.FakeFloor then
                    T.FakeFloor=Instance.new("Part"); T.FakeFloor.Name="ZILI_FakeFloor"
                    T.FakeFloor.Size=Vector3.new(15,2,15); T.FakeFloor.Anchored=true
                    T.FakeFloor.Transparency=1; T.FakeFloor.Parent=Workspace
                end
                local ag = r:FindFirstChild("ZILI_AntiGravity") or Instance.new("BodyVelocity")
                ag.Name="ZILI_AntiGravity"; ag.MaxForce=Vector3.new(9e9,9e9,9e9)
                ag.Velocity=VEC_ZERO; ag.Parent=r

                local tPos       = step.pos
                local fishmanIn  = step.isFishmanIn  or false
                local fishmanOut = step.isFishmanExit or false

                T.MoveConn = RunService.Heartbeat:Connect(function(dt)
                    if not T.IsTeleporting or not r.Parent then T.Stop(); return end
                    if isFlicking then return end
                    if T.FakeFloor then T.FakeFloor.CFrame=r.CFrame*FAKE_FLOOR_OFF end
                    r.Velocity = VEC_ZERO

                    local cur    = r.Position
                    local distXZ = (Vector2.new(tPos.X,tPos.Z)-Vector2.new(cur.X,cur.Z)).Magnitude
                    local mxStep = math.min(MAX_SPEED*dt, 120)

                    -- Luôn swim ở Y=-97.15 (giống TWEEN TO ISLAND), bỏ qua fishman portal
                    -- DoSetSpawn_Special tự TP xuống -97.15 trước khi gọi → startY=-97.15
                    -- → condition dưới skip ngay (abs(-97.15-(-97.15))=0 không >10)
                    if not fishmanIn and not fishmanOut then
                        if math.abs(cur.Y-(-97.15))>10 and distXZ>50 then
                            T.MoveConn:Disconnect()
                            task.spawn(function()
                                r.CFrame = CFrame.new(cur.X,-97.15,cur.Z)
                                task.wait(0.2)
                                flyTo(step, onDone)
                            end)
                            return
                        end
                    end

                    if distXZ < 30 then
                        T.MoveConn:Disconnect()
                        task.spawn(function()
                            if fishmanOut then
                                r.CFrame=CFrame.lookAt(r.Position,tPos); task.wait(0.1)
                                local w=0
                                while w<20 and T.IsTeleporting and r do
                                    if (r.Position-tPos).Magnitude>200 then break end
                                    r.CFrame=r.CFrame*CFrame.new(0,0,-3)
                                    if T.FakeFloor then T.FakeFloor.CFrame=r.CFrame*FAKE_FLOOR_OFF end
                                    task.wait(0.15); w+=0.15
                                end
                            elseif fishmanIn then
                                local toggle,w=1,0
                                while w<20 and T.IsTeleporting and r do
                                    if (r.Position-tPos).Magnitude>200 then task.wait(4); break end
                                    r.CFrame=CFrame.new(tPos.X+toggle,tPos.Y,tPos.Z+toggle)
                                    if T.FakeFloor then T.FakeFloor.CFrame=r.CFrame*FAKE_FLOOR_OFF end
                                    toggle=-toggle; task.wait(0.3); w+=0.3
                                end
                                task.wait(1.5)
                            else
                                -- TP thẳng lên Y đích (kể cả đảo cao Y=1818)
                                r.CFrame=CFrame.new(tPos)
                                if T.FakeFloor then T.FakeFloor.CFrame=r.CFrame*FAKE_FLOOR_OFF end
                                task.wait(0.2)
                            end
                            if onDone then onDone() end
                        end)
                    else
                        -- swim Y=-97.15 (trừ fishman portal)
                        local safeY = (fishmanIn or fishmanOut) and tPos.Y or -97.15
                        local at    = Vector3.new(tPos.X, safeY, tPos.Z)
                        local dir   = (at-cur).Unit
                        r.CFrame    = CFrame.new(cur + dir*math.min(mxStep,(at-cur).Magnitude))
                    end
                end)
            end

            local function processRoute(i)
                if not T.IsTeleporting then return end
                if i>#route then T.Stop(); return end
                flyTo(route[i], function() processRoute(i+1) end)
            end
            processRoute(1)
        end
        return T
    end
    IslandTween = LoadIslandTween()


    -- ═══════════════════════════════════════════════════════════════
    -- TWEEN COMBAT
    --   Fast velocity-based close-range movement.
    --   actionType "Farm"  → hover FARM_HOVER units above mob
    --   actionType "Move"  → go to exact pos
    -- ═══════════════════════════════════════════════════════════════
    local FARM_HOVER = 8
    local currentFarmHover = FARM_HOVER  -- per-zone override (vd: Baratie = -8)
    local function GetVelNode()
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil,nil end
        local att = root:FindFirstChild("LF_Attach") or Instance.new("Attachment",root)
        att.Name = "LF_Attach"
        local lv  = root:FindFirstChild("LF_VelocityNode") or Instance.new("LinearVelocity",root)
        lv.Name="LF_VelocityNode"; lv.Attachment0=att; lv.MaxForce=math.huge
        return lv, root
    end

    local function TweenCombat(targetCFrame, actionType)
        local lv, root = GetVelNode()
        if not root then return false end
        if IslandTween.IsTeleporting then
            IslandTween.Stop()
            task.wait(0.05)
            lv, root = GetVelNode()
            if not root then return false end
        end
        if not ZiliState.LastLFStamTick or tick()-ZiliState.LastLFStamTick >= 0.05 then
            ZiliState.LastLFStamTick = tick()
            pcall(function() TakestamEv:FireServer(0.505,"dash",root.CFrame) end)
        end
        local finalPos = targetCFrame.Position
        if actionType=="Farm" then
            finalPos = finalPos + Vector3.new(0, currentFarmHover, 0)
            -- sideOffset: dịch ngang theo trục X thế giới (cố định, không phụ thuộc orientation mob)
            if currentZone and currentZone.sideOffset then
                finalPos = finalPos + Vector3.new(currentZone.sideOffset, 0, 0)
            end
        end
        local dist = (finalPos-root.Position).Magnitude
        if dist > 2 then
            local dir = (finalPos-root.Position).Unit
            lv.VectorVelocity = dir*60
            return false
        else
            lv.VectorVelocity = VEC_ZERO
            if actionType=="Farm" then
                root.CFrame = CFrame.new(root.Position,
                    Vector3.new(targetCFrame.Position.X, root.Position.Y, targetCFrame.Position.Z))
            else
                root.CFrame = targetCFrame
            end
            return true
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- HELPERS
    -- ═══════════════════════════════════════════════════════════════
    local function GetLevel()
        local v=0; pcall(function() v=tonumber(Level.Value) or 0 end); return v>0 and v or 1
    end

    -- ═══════════════════════════════════════════════════════════════
    -- WORLD SCROLL — Sau khi farm Kori xong (BusoMastery >= 1)
    -- ═══════════════════════════════════════════════════════════════
    local worldScrollDone     = false  -- đã trigger DoWorldScroll
    local worldScrollFinished = false  -- đã snap xong afterScrollCF
    local lightningIsland = Vector3.new(-7348.86, 3.27, -14950.54)
    local afterScrollCF   = CFrame.new(-8562.48145, 76.3761597, -8378.80176)
    local vim             = Instance.new("VirtualInputManager")

    local function HasWorldScroll()
        local found = false
        pcall(function()
            local sf = ReplicatedStorage:FindFirstChild("Stats"..Player.Name)
            local invVal = sf and sf:FindFirstChild("Inventory") and sf.Inventory:FindFirstChild("Inventory")
            if not invVal then return end
            local data = game:GetService("HttpService"):JSONDecode(invVal.Value)
            if data and (data["World Scroll"] or 0) >= 1 then found = true end
        end)
        return found
    end

    local function GetBusoMastery()
        local buso = 0
        pcall(function()
            local sf = ReplicatedStorage:FindFirstChild("Stats"..Player.Name)
            local bv = sf and sf:FindFirstChild("Stats") and sf.Stats:FindFirstChild("BusoMastery")
            if bv then buso = tonumber(bv.Value) or 0 end
        end)
        return buso
    end

    local function DoWorldScroll()
        -- Nếu đã có WorldScroll trong inventory → snap thẳng
        if HasWorldScroll() then
            task.wait(1)
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = afterScrollCF end
            worldScrollFinished = true
            return
        end

        while _active do
            -- Bước 1: IslandTween → lightning island (retry sau mỗi lần die)
            IslandTween.Start(lightningIsland)
            local t1 = tick() + 120
            while tick() < t1 and _active do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not r then task.wait(0.3); continue end
                local xzD = (Vector2.new(r.Position.X,r.Position.Z) - Vector2.new(lightningIsland.X,lightningIsland.Z)).Magnitude
                if xzD <= 35 then
                    IslandTween.Stop()
                    -- Snap lên đúng Y đích khi đã trùng XZ
                    task.wait(0.1)
                    r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if r then r.CFrame = CFrame.new(r.Position.X, lightningIsland.Y, r.Position.Z) end
                    break
                end
                task.wait(0.3)
            end
            IslandTween.Stop()
            if not _active then return end

            -- Bước 2: wait 2s rồi lock position
            task.wait(2)
            if HasWorldScroll() then break end

            local lockConn = RunService.Heartbeat:Connect(function()
                local rr = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if rr then
                    rr.CFrame = CFrame.new(lightningIsland)
                    pcall(function() rr.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
                end
            end)

            -- Bước 3: Hold Alt nhặt, đồng thời detect nếu chết (character đổi)
            local gotItem = false
            local maxRetry = 20
            for i = 1, maxRetry do
                if HasWorldScroll() then gotItem = true; break end
                -- Detect die: HumanoidRootPart mất → chết → break để re-tween
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
                if not r or not hum or hum.Health <= 0 then
                    break  -- die → unlock → re-loop tween lại
                end
                vim:SendKeyEvent(true, Enum.KeyCode.LeftAlt, false, Player)
                task.wait(5)
                vim:SendKeyEvent(false, Enum.KeyCode.LeftAlt, false, Player)
                task.wait(1)
            end

            lockConn:Disconnect()
            task.wait(0.1)  -- đợi Heartbeat frame cuối dừng hẳn
            if gotItem or HasWorldScroll() then break end

            -- Chết hoặc hết retry → đợi respawn rồi re-tween
            task.wait(3)
        end

        if not _active then return end

        -- Confirm có World Scroll rồi mới snap
        if HasWorldScroll() then
            task.wait(3)
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = afterScrollCF end
            worldScrollFinished = true
        end
    end

    local function GetCurrentSea()
        -- [FIX BUG 1] Chỉ dùng PlaceId — stat CurrentSea cập nhật TRƯỚC khi server
        -- thực sự transfer player (ví dụ: lúc mua World Scroll ở Sea 1, CurrentSea
        -- đổi thành "Second" ngay lập tức). Nếu dùng stat fallback, GetCurrentZone()
        -- sẽ trả về Thriller Bark (sea=2, lvl 375–425) dù player vẫn đang ở Sea 1,
        -- khiến Level Farm tween đến tọa độ Thriller Bark không tồn tại.
        if game.PlaceId == 7465136166 then return 2 end
        return 1
    end

    local function GetCurrentZone()
        local lvl = GetLevel()
        local sea = GetCurrentSea()
        for _, z in ipairs(ZONES) do
            local zoneSea = z.sea or 1
            if zoneSea == sea and lvl >= z.minLvl and lvl < z.maxLvl then
                return z  -- break ngay khi match đúng sea + lvl
            end
        end
        -- Fallback: zone cuối cùng của sea hiện tại
        local fallback = nil
        for _, z in ipairs(ZONES) do
            if (z.sea or 1) == sea then fallback = z end
        end
        return fallback or ZONES[1]
    end

    local function IsOnIsland(zone)
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local pos = root.Position
        if zone.isFishman then return pos.Y < -1000 end
        -- Check distance từ islandPos, mobPos, npcPos — lấy min distance
        local d = (pos - zone.islandPos).Magnitude
        if zone.mobPos  then d = math.min(d, (pos - zone.mobPos).Magnitude)  end
        if zone.npcPos  then d = math.min(d, (pos - zone.npcPos).Magnitude)  end
        if zone.mobPos2 then d = math.min(d, (pos - zone.mobPos2).Magnitude) end
        return d < 1200
    end

    local function GetClosestMob(mobName)
        local char = Player.Character
        if not char or not char.PrimaryPart then return nil end
        local charPos = char.PrimaryPart.Position
        local folder  = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Enemies") or Workspace
        local best, minD = nil, math.huge
        for _,npc in ipairs(folder:GetChildren()) do
            if mobName=="" or npc.Name:find(mobName,1,true) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                local hum = npc:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health>0 then
                    local d=(hrp.Position-charPos).Magnitude
                    if d<minD then minD=d; best=npc end
                end
            end
        end
        return best
    end

    local function CheckHasQuest()
        local ok=false
        pcall(function()
            local qv=tostring(CurrentQuest.Value):gsub("%s+",""):lower()
            ok = qv~="" and qv~="none" and qv~="nil" and qv~="0"
        end)
        return ok
    end

    local function AutoClickChat(chatGui)
        for _,btn in pairs(chatGui:GetDescendants()) do
            if btn:IsA("TextButton") and btn.Visible then
                local t = btn.Text:lower()
                if t:match("go") or t:match("yes") or t:match("set") or t:match("accept")
                   or t:match("okay") or t:match("take") or t:match("next") or t:match("sure") then
                    if getconnections then
                        for _,c in pairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                        for _,c in pairs(getconnections(btn.Activated))         do pcall(function() c:Fire() end) end
                    end
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- HELPERS: IslandTween đến target rồi dừng khi đến gần
    -- ═══════════════════════════════════════════════════════════════
    local function TweenToAndWait(targetPos, threshold, timeout)
        threshold = threshold or 40
        timeout   = timeout   or 40
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - targetPos).Magnitude > threshold then
            IslandTween.Start(targetPos)
            local deadline = tick() + timeout
            while tick() < deadline and _active do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if r and (r.Position - targetPos).Magnitude <= threshold then break end
                -- [RUBBERBAND FIX] XZ đã đúng nhưng Y sai → TP thẳng không cần full tween
                -- Xảy ra khi server rubberband player về đúng XZ nhưng sai Y (phổ biến ở đảo cao)
                if r then
                    local xzDist = (Vector2.new(r.Position.X, r.Position.Z)
                                  - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
                    local yDiff  = math.abs(r.Position.Y - targetPos.Y)
                    if xzDist <= 50 and yDiff > 30 then
                        r.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                    end
                end
                task.wait(0.3)
            end
            IslandTween.Stop()
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- SET SPAWN — Normal (Sandora, Zou, v.v.)
    --   IslandTween → gần spawnPos → TweenCombat chính xác → FireServer
    -- ═══════════════════════════════════════════════════════════════
    local function DoSetSpawn_Normal(zone)
        if not zone.spawnPos then return end
        -- Bước 1: IslandTween đến gần spawnPos
        TweenToAndWait(zone.spawnPos, 60, 120)
        if not _active then return end
        -- Bước 2: TweenCombat chính xác đến spawnPos
        local limit = tick() + 15
        while tick() < limit do
            if not _active then return end
            if TweenCombat(CFrame.new(zone.spawnPos), "Move") then break end
            task.wait(0.05)
        end
        if not _active then return end
        task.wait(3)
        -- Bước 3: Fire SetSpawn + confirm SpawnPoint changed (retry tối đa 5 lần)
        local spBefore = tostring(SpawnPoint.Value)
        for i = 1, 5 do
            pcall(function() SetSpawnEv:FireServer() end)
            task.wait(2)
            if not _active then return end
            local spNow = tostring(SpawnPoint.Value)
            if spNow ~= spBefore and spNow ~= "" and spNow ~= "nil" then
                break  -- SpawnPoint đã đổi → confirm thành công
            end
        end
        task.wait(0.5)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- LEARN STYLE — IslandTween → npcPos → wait 5s → fire learnStyle
    -- ═══════════════════════════════════════════════════════════════
    local learnDoneFor = {}  -- [zoneKey] = true khi đã learn xong
    local LearnStyleEv = ReplicatedStorage:WaitForChild("Events"):WaitForChild("learnStyle")

    local function DoLearnStyle(zone)
        local zk = zone.npcName
        if learnDoneFor[zk] then return end  -- đã learn rồi → skip

        -- IslandTween → npcPos
        IslandTween.Start(zone.npcPos)
        local t1 = tick() + 90
        while tick() < t1 and _active do
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not r then task.wait(0.3); continue end
            if (r.Position - zone.npcPos).Magnitude <= 30 then break end
            task.wait(0.3)
        end
        IslandTween.Stop()
        if not _active then return end

        -- TweenCombat chính xác đến npcPos
        local t2 = tick() + 15
        while tick() < t2 and _active do
            if TweenCombat(CFrame.new(zone.npcPos), "Move") then break end
            task.wait(0.05)
        end
        if not _active then return end

        -- Wait 5s rồi fire remote
        task.wait(5)
        if not _active then return end
        pcall(function()
            local args = { [1] = zone.learnStyleArg }
            LearnStyleEv:FireServer(unpack(args))
        end)
        task.wait(1)
        learnDoneFor[zk] = true
    end

    -- ═══════════════════════════════════════════════════════════════
    -- SET SPAWN — Kori Island
    -- ═══════════════════════════════════════════════════════════════
    local function DoSetSpawn_Kori(zone)
        local function WaitWithStam(seconds)
            local deadline = tick() + seconds
            while tick() < deadline and _active do
                local rr = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if rr and TakestamEv and TakestamEv.Parent then
                    pcall(function() TakestamEv:FireServer(0.505,"dash",rr.CFrame) end)
                end
                task.wait(0.05)
            end
        end

        -- B0: Learn SkyWalk style từ NPC YI (1 lần, chỉ khi chưa có skill)
        -- Check ReplicatedStorage.Stats{name}.Skills.skyWalk → nếu true thì skip
        local hasSkyWalk = false
        pcall(function()
            local sf = ReplicatedStorage:FindFirstChild("Stats"..Player.Name)
            local sk = sf and sf:FindFirstChild("Skills")
            local sw = sk and sk:FindFirstChild("skyWalk")
            if sw and (sw.Value == true or sw.Value == 1) then hasSkyWalk = true end
        end)
        if not hasSkyWalk and not learnDoneFor[zone.npcName] then
            IslandTween.Start(Vector3.new(-3086.87, 94.54, -11755.48))
            local tL = tick() + 90
            while tick() < tL and _active do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not r then task.wait(0.3); continue end
                if (r.Position - Vector3.new(-3086.87,94.54,-11755.48)).Magnitude <= 30 then break end
                task.wait(0.3)
            end
            IslandTween.Stop()
            if not _active then return end
            local tL2 = tick() + 15
            while tick() < tL2 and _active do
                if TweenCombat(CFrame.new(-3086.87,94.54,-11755.48), "Move") then break end
                task.wait(0.05)
            end
            if not _active then return end
            task.wait(5)
            if not _active then return end
            pcall(function()
                LearnStyleEv:FireServer("skyWalkTrainer")
            end)
            task.wait(1)
            learnDoneFor[zone.npcName] = true
        end
        if not _active then return end

        -- B1: IslandTween → Zou → SetSpawn
        local sp = string.lower(tostring(SpawnPoint.Value))
        if not sp:find(zone.spawnTag, 1, true) then
            IslandTween.Start(zone.spawnPos)
            local t1 = tick()+90
            while tick()<t1 and _active do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not r then task.wait(0.3); continue end
                if (r.Position-zone.spawnPos).Magnitude<=60 then break end
                task.wait(0.3)
            end
            IslandTween.Stop()
            if not _active then return end
            WaitWithStam(3)
            if not _active then return end
            pcall(function() SetSpawnEv:FireServer() end)
            WaitWithStam(3)
            if not _active then return end
        end

        -- B2: IslandTween → npcPos Kori (skip nếu đã có quest rồi → đi thẳng mobPos)
        local alreadyHasQuest = false
        pcall(function()
            local q = tostring(CurrentQuest.Value):lower():gsub("%s+","")
            local expectQ = zone.npcName:lower():gsub("%s+","")
            if q ~= "none" and q ~= "" and q ~= "0" and q ~= "nil" and q:find(expectQ,1,true) then
                alreadyHasQuest = true
            end
        end)

        if not alreadyHasQuest then
            IslandTween.Start(zone.npcPos)
            local t2 = tick()+120
            while tick()<t2 and _active do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not r then task.wait(0.3); continue end
                if (r.Position-zone.npcPos).Magnitude<=150 then break end
                task.wait(0.3)
            end
            IslandTween.Stop()
            if not _active then return end

            -- B3: TweenCombat → npcPos → fire → retry cho đến khi CurrentQuest confirm
            local t3 = tick()+20
            while tick()<t3 and _active do
                if TweenCombat(CFrame.new(zone.npcPos), "Move") then break end
                task.wait(0.05)
            end
            if not _active then return end
            local tConfirm = tick()+15
            repeat
                pcall(function() QuestEvent:InvokeServer({"takequest", zone.npcName}) end)
                WaitWithStam(1)
                if not _active then return end
                local q = tostring(CurrentQuest.Value):lower():gsub("%s+","")
                if q ~= "none" and q ~= "" and q ~= "0" and q ~= "nil" then break end
            until tick()>tConfirm or not _active
            if not _active then return end
        end

        -- B4: snap -97.15 → WaitWithStam 2s → IslandTween bơi XZ đến mobPos
        --     → khi XZ trùng: snap lên Y mobPos
        local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame = CFrame.new(r.Position.X, -97.15, r.Position.Z) end
        WaitWithStam(2)
        if not _active then return end
        IslandTween.Start(zone.mobPos)
        local t4 = tick()+60
        while tick()<t4 and _active do
            r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not r then task.wait(0.3); continue end
            local xzD = (Vector2.new(r.Position.X,r.Position.Z)
                       - Vector2.new(zone.mobPos.X,zone.mobPos.Z)).Magnitude
            if xzD <= 40 then
                IslandTween.Stop()
                r.CFrame = CFrame.new(zone.mobPos.X, zone.mobPos.Y, zone.mobPos.Z)
                break
            end
            task.wait(0.3)
        end
        IslandTween.Stop()
        -- return → mainLoop noLure farm
    end

    -- ═══════════════════════════════════════════════════════════════
    -- SET SPAWN — Special (Sky Island, Gravito's Fort, v.v.)
    local function DoSetSpawn_Special(zone)
        local sp  = zone.spawnPos
        local npc = zone.npcPos

        -- ── Helper: wait N giây, fire TakestamEv mỗi 0.05s trong lúc chờ ──
        local function WaitWithStam(seconds)
            local deadline = tick() + seconds
            while tick() < deadline and _active do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if r and TakestamEv and TakestamEv.Parent then
                    pcall(function() TakestamEv:FireServer(0.505, "dash", r.CFrame) end)
                end
                task.wait(0.05)
            end
        end

        -- ── Helper: snap về Y=-97.15 rồi swim đến khi XZ trùng targetPos ──
        -- Nếu đã đúng XZ (xzD <= 60): chỉ snap -97.15, không start IslandTween
        --   → tránh IslandTween thấy distXZ < 30 và auto-TP lên luôn
        -- Nếu cần swim: IslandTween bơi, stop sớm ở xzD <= 60 (trước ngưỡng auto-TP < 30)
        --   → re-snap -97.15 sau khi stop phòng IslandTween kịp nhúc nhích Y
        local function SwimToXZ(targetPos)
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not r then return false end
            local xzD = (Vector2.new(r.Position.X, r.Position.Z)
                       - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
            r.CFrame = CFrame.new(r.Position.X, -97.15, r.Position.Z)
            task.wait(0.3)
            if not _active then return false end
            if xzD <= 60 then return true end  -- đã đúng XZ, không cần swim
            IslandTween.Stop()
            if not IslandTween.IsTeleporting then IslandTween.Start(targetPos) end
            local deadline = tick() + 90
            while tick() < deadline and _active do
                r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not r then task.wait(0.05); continue end
                xzD = (Vector2.new(r.Position.X, r.Position.Z)
                     - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
                if xzD <= 60 then IslandTween.Stop(); break end
                task.wait(0.05)
            end
            IslandTween.Stop()
            r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = CFrame.new(r.Position.X, -97.15, r.Position.Z) end
            task.wait(0.2)
            return _active
        end

        -- ── Helper: snap lên đúng targetPos (X,Y,Z), wait 5s với stam,
        --           confirm Y ≤ 30 studs; retry nếu sai (max 5 lần) ──
        local function SnapAndConfirmY(targetPos)
            for _ = 1, 5 do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not r then task.wait(0.5); continue end
                r.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                WaitWithStam(5)
                if not _active then return false end
                r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if r and math.abs(r.Position.Y - targetPos.Y) <= 30 then return true end
            end
            return false
        end

        -- ══ Part A: spawnPos ══════════════════════════════════════════
        if not SwimToXZ(sp) then return end
        WaitWithStam(3)
        if not _active then return end

        if not SnapAndConfirmY(sp) then return end
        if not _active then return end

        -- Đợi Robo appear gần spawnPos rồi mới SetSpawn
        local tRobo = tick() + 30
        while tick() < tRobo and _active do
            local found = false
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name == "Robo" then
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - sp).Magnitude <= 200 then found = true; break end
                end
            end
            if found then break end
            task.wait(0.5)
        end
        if not _active then return end
        pcall(function() SetSpawnEv:FireServer() end)
        WaitWithStam(3)
        if not _active then return end

        -- ══ Part B: npcPos ════════════════════════════════════════════
        if not SwimToXZ(npc) then return end
        WaitWithStam(3)
        if not _active then return end

        if not SnapAndConfirmY(npc) then return end
        if not _active then return end

        -- Đợi NPC quest xuất hiện: check workspace.NPCs trực tiếp, bỏ distance check
        local tNPC = tick() + 10
        while tick() < tNPC and _active do
            local npcFolder = Workspace:FindFirstChild("NPCs")
            local npcModel  = npcFolder and npcFolder:FindFirstChild(zone.npcName)
            if npcModel and npcModel:FindFirstChild("HumanoidRootPart") then
                pcall(function() QuestEvent:InvokeServer({"takequest", zone.npcName}) end)
                return
            end
            task.wait(0.1)
        end
        -- return → mainLoop: spawnSetFor[zoneKey]=true → TakeQuest via TweenCombat
    end

    -- ═══════════════════════════════════════════════════════════════
    -- SET SPAWN — Fishman Island
    --   IslandTween → gần spawnPos → TweenCombat chính xác → wait 4s → FireServer
    -- ═══════════════════════════════════════════════════════════════
    local function DoSetSpawn_Fishman(zone)
        -- Bước 1: IslandTween đến spawnPos
        TweenToAndWait(zone.spawnPos, 60, 50)
        if not _active then return end
        -- Bước 2: TweenCombat chính xác
        local limit = tick() + 15
        while tick() < limit do
            if not _active then return end
            if TweenCombat(CFrame.new(zone.spawnPos), "Move") then
                task.wait(4)
                pcall(function() SetSpawnEv:FireServer() end)
                task.wait(0.5); return
            end
            task.wait(0.05)
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- TAKE QUEST
    --   Đảo thường    : TweenCombat trực tiếp đến NPC (không IslandTween)
    --   Đảo đặc biệt  : Step 3 đã IslandTween đến gần npcPos rồi
    --                   → TakeQuest chỉ cần TweenCombat precision
    --   Vòng lặp farm : TweenCombat cho đến khi đủ cấp → IslandTween qua đảo mới
    -- ═══════════════════════════════════════════════════════════════
    local function TakeQuest(zone)
        local npcTarget = zone.npcPos + Vector3.new(0, 0, 3)

        -- Đảo fishman (đường xa dưới nước): vẫn cần IslandTween nếu còn xa
        if zone.isFishman then
            local r0 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r0 and (r0.Position - npcTarget).Magnitude > 150 then
                if not IslandTween.IsTeleporting then IslandTween.Start(zone.npcPos) end
                local flyLimit = tick() + 30
                while tick() < flyLimit and _active do
                    local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if r and (r.Position - npcTarget).Magnitude <= 150 then break end
                    task.wait(0.3)
                end
                if IslandTween.IsTeleporting then IslandTween.Stop() end
            end
        end
        -- Đảo specialSpawn: step 3 đã IslandTween đến gần npcPos
        -- → không cần IslandTween thêm, TweenCombat bên dưới sẽ xử lý precision

        -- TweenCombat chính xác đến NPC (áp dụng cho TẤT CẢ đảo)
        local limit = tick() + 25
        while tick() < limit do
            if not _active then return end
            if TweenCombat(CFrame.new(npcTarget), "Move") then break end
            task.wait(0.05)
        end

        -- Fire quest remote + scan mobs trong 200 studs
        pcall(function() QuestEvent:InvokeServer({"takequest", zone.npcName}) end)
        task.wait(0.5)
        -- Scan mobs gần NPC để init lure list
        lureMobList = {}; lureIdx = 1; farmPhase = PHASE_LURE
        local folder2 = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Enemies") or Workspace
        for _, npc in ipairs(folder2:GetChildren()) do
            if zone.mobName == "" or npc.Name:find(zone.mobName, 1, true) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                local hum = npc:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 and (hrp.Position - zone.npcPos).Magnitude <= 200 then
                    table.insert(lureMobList, npc)
                end
            end
        end
        pcall(getgenv().ZiliLog, "Quest @ "..zone.npcName.." | "..#lureMobList.." mobs found", "farm")
    end

    -- ═══════════════════════════════════════════════════════════════
    -- LURE / COMBO SYSTEM
    --   LURE  : kéo lần lượt từng mob ra, đánh 1 hit đảm bảo trừ máu
    --   COMBO : về center spam 4 hit trên mob gần nhất
    --   Reset : khi mob chết + respawn (full HP) → về LURE
    -- ═══════════════════════════════════════════════════════════════
    local PHASE_LURE  = "LURE"
    local PHASE_COMBO = "COMBO"
    local farmPhase   = PHASE_LURE
    local farmTier    = 1        -- 1=lower mobPos, 2=upper mobPos2 (zones có 2 tầng)
    local lureMobList = {}
    local lureIdx     = 1
    local LURE_RADIUS = 200

    local function ScanLureMobs(zone, centerOverride, radiusOverride)
        local center = centerOverride or zone.mobPos
        local radius = radiusOverride or LURE_RADIUS
        local otherCenter = nil
        if zone.mobPos2 then
            otherCenter = (center == zone.mobPos) and zone.mobPos2 or zone.mobPos
        end
        local function normName(s)
            return s:gsub("\xe2\x80\x99", "'"):lower()
        end
        local function matchMob(npcName)
            if zone.mobNames then
                for _, n in ipairs(zone.mobNames) do
                    if normName(npcName):find(normName(n), 1, true) then return true end
                end
                return false
            end
            return zone.mobName == "" or normName(npcName):find(normName(zone.mobName), 1, true)
        end
        local folder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Enemies") or Workspace
        local result = {}
        for _, npc in ipairs(folder:GetChildren()) do
            if matchMob(npc.Name) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                local hum = npc:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (hrp.Position - center).Magnitude
                    if d <= radius then
                        if otherCenter then
                            local dOther = (hrp.Position - otherCenter).Magnitude
                            if d < dOther then table.insert(result, npc) end
                        else
                            table.insert(result, npc)
                        end
                    end
                end
            end
        end
        return result
    end

    -- ═══════════════════════════════════════════════════════════════
    -- MELEE COMBAT  (CombatRegister, combo 1-4)
    -- ═══════════════════════════════════════════════════════════════
    getgenv().HitDelay   = getgenv().HitDelay   or 0.366
    getgenv().ComboDelay = getgenv().ComboDelay or 1

    local comboIdx        = 1
    local lastHit         = 0
    local currentHitDelay = getgenv().HitDelay
    local lastDmgDealt    = 0   -- tick() khi lần cuối gây dmg (dùng cho unstuck check)

    local function MeleeHit(mob)
        local now = tick()
        if now - lastHit < currentHitDelay then return end
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then
            local m = Player.Backpack:FindFirstChild("Melee")
            if m then pcall(function() char:FindFirstChild("Humanoid"):EquipTool(m) end) end
            return
        end
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        lastHit = now
        lastDmgDealt = now
        pcall(function() root.AssemblyLinearVelocity = root.CFrame.LookVector * 50 end)
        local anim = ReplicatedStorage:WaitForChild("CombatAnimations"):WaitForChild("Melee"):FindFirstChild("Punch" .. comboIdx)
        task.spawn(function() pcall(function() CombatReg:InvokeServer({"swingsfx", "Melee", comboIdx, "Ground", false, anim, 2, 1.5}) end) end)
        task.spawn(function() pcall(function() CombatReg:InvokeServer({"damage", {hrp}, "Melee", {comboIdx, "Ground", "Melee"}, true, root.CFrame, aircombo = "Ground"}) end) end)
        pcall(function() root.AssemblyLinearVelocity = VEC_ZERO end)
        comboIdx = (comboIdx >= 4) and 1 or (comboIdx + 1)
        currentHitDelay = (comboIdx == 1) and getgenv().ComboDelay or getgenv().HitDelay
    end

    local function MeleeHitMulti(mobList)
        local now = tick()
        if now - lastHit < currentHitDelay then return end
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then
            local m = Player.Backpack:FindFirstChild("Melee")
            if m then pcall(function() char:FindFirstChild("Humanoid"):EquipTool(m) end) end
            return
        end
        local hrps = {}
        for _, mob in ipairs(mobList) do
            if mob and mob.Parent then
                local hrp = mob:FindFirstChild("HumanoidRootPart")
                local hum = mob:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then table.insert(hrps, hrp) end
            end
        end
        if #hrps == 0 then return end
        lastHit = now
        lastDmgDealt = now
        pcall(function() root.AssemblyLinearVelocity = root.CFrame.LookVector * 50 end)
        local anim = ReplicatedStorage:WaitForChild("CombatAnimations"):WaitForChild("Melee"):FindFirstChild("Punch" .. comboIdx)
        task.spawn(function() pcall(function() CombatReg:InvokeServer({"swingsfx", "Melee", comboIdx, "Ground", false, anim, 2, 1.5}) end) end)
        task.spawn(function() pcall(function() CombatReg:InvokeServer({"damage", hrps, "Melee", {comboIdx, "Ground", "Melee"}, true, root.CFrame, aircombo = "Ground"}) end) end)
        pcall(function() root.AssemblyLinearVelocity = VEC_ZERO end)
        comboIdx = (comboIdx >= 4) and 1 or (comboIdx + 1)
        currentHitDelay = (comboIdx == 1) and getgenv().ComboDelay or getgenv().HitDelay
    end

    -- ═══════════════════════════════════════════════════════════════
    -- MAIN LOOP
    -- ═══════════════════════════════════════════════════════════════
    local lastQuestCheck     = 0
    local hasQuest           = false
    local currentZone        = nil
    local mainLoop_lastZoneKey = nil
    local _skyWalkLoop       = nil

    local function mainLoop()
        while true do
            task.wait(0.05)
            if not _active then continue end
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChild("Humanoid")
            if not root or not hum or hum.Health<=0 then continue end

            local zone    = GetCurrentZone()
            currentZone   = zone
            local zoneKey = zone.npcName  -- unique string per zone

            -- Check BusoMastery TRƯỚC MỌI THỨ → nếu Kori xong thì DoWorldScroll
            if zone.needsSwim then
                if worldScrollFinished then
                    task.wait(1); continue
                elseif worldScrollDone then
                    task.wait(1); continue
                else
                    -- Có World Scroll rồi → snap thẳng vào portal (chỉ Sea 1)
                    if HasWorldScroll() then
                        worldScrollDone = true
                        worldScrollFinished = true
                        -- [FIX BUG 1] Snap khi PlaceId xác nhận đang ở Sea 1
                        -- GetCurrentSea() giờ chỉ dùng PlaceId nên đáng tin hoàn toàn
                        if GetCurrentSea() == 1 then
                            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                            if r then r.CFrame = afterScrollCF end
                        end
                        -- Sync trạng thái với AutoEnterSecondSeaModule nếu đang chạy
                        if ZiliState.AutoEnterSecondSea and AutoEnterSecondSeaModule then
                            pcall(function() AutoEnterSecondSeaModule.Toggle(false) end)
                        end
                        task.wait(1); continue
                    end
                    local buso = GetBusoMastery()
                    if buso >= 1 then
                        worldScrollDone = true
                        task.spawn(DoWorldScroll)
                        task.wait(1); continue
                    end
                end
            end
            currentFarmHover = zone.farmHover or FARM_HOVER  -- per-zone FARM_HOVER override

            -- Reset farm state khi đổi zone (farmTier, lureMobList, farmPhase)
            -- Tránh farmTier=2 từ Land of the Sky còn sót khi qua Gravito's Fort
            if zoneKey ~= (mainLoop_lastZoneKey or zoneKey) then
                farmTier    = 1
                farmPhase   = PHASE_LURE
                lureMobList = {}
                hasQuest    = false; lastQuestCheck = 0
                local kff = Workspace:FindFirstChild("ZILI_KoriFakeFloor")
                if kff then kff:Destroy() end
            end
            mainLoop_lastZoneKey = zoneKey

            -- ── 1. Navigate to correct island ──────────────────────
            if not IsOnIsland(zone) then
                -- [FIX BUG 3] Chỉ quit quest KHÁC zone, không quit quest đúng zone.
                -- Root cause cũ: khi chết ở Kori respawn về Zou, IsOnIsland=false.
                -- Code cũ quit bất kỳ quest nào → xóa "Road to Armament".
                -- Fix: kiểm tra expectQ trước khi quit.
                local curQ    = tostring(CurrentQuest.Value):lower():gsub("%s+","")
                local hasAnyQ = curQ ~= "none" and curQ ~= "" and curQ ~= "nil" and curQ ~= "0"
                local expectQ = zone.npcName:lower():gsub("%s+","")
                if hasAnyQ and not curQ:find(expectQ, 1, true) then
                    pcall(function()
                        QuestEvent:InvokeServer(unpack({ { [1] = "quit" } }))
                    end)
                    task.wait(0.5)
                end
                -- needsSwim (Kori): xử lý toàn bộ flow ngay tại đây
                -- Zou setSpawn → swim → npcPos → TakeQuest → mobPos
                -- KHÔNG tween đến Kori trước rồi quay lại Zou
                if zone.needsSwim and not spawnSetFor[zoneKey] then
                    DoSetSpawn_Kori(zone)
                    spawnSetFor[zoneKey] = true
                    hasQuest = CheckHasQuest(); lastQuestCheck = tick()
                    if zone.oneTimeQuest and hasQuest then questDoneFor[zoneKey] = "pending" end
                    continue
                end
                -- [RUBBERBAND FIX] Chỉ snap khi IslandTween đã dừng:
                local xzDist = (Vector2.new(root.Position.X, root.Position.Z)
                              - Vector2.new(zone.islandPos.X, zone.islandPos.Z)).Magnitude
                local yDiff  = math.abs(root.Position.Y - zone.islandPos.Y)
                if not IslandTween.IsTeleporting and xzDist <= 120 and yDiff > 50 then
                    root.CFrame = CFrame.new(zone.islandPos)
                    task.wait(0.15)
                    continue
                end
                if not IslandTween.IsTeleporting then IslandTween.Start(zone.islandPos) end
                continue
            end
            -- Đã đến đảo — dừng IslandTween navigation tween
            -- KHÔNG stop nếu _farmNavigating=true (tween đang chạy cho step 3 → npcPos)
            if IslandTween.IsTeleporting and not _farmNavigating then IslandTween.Stop() end

            -- ── 2. Set spawn nếu chưa set ──────────────────────────
            local needSpawn = false
            if zone.spawnPos then
                if zone.isFishman then
                    local sp = string.lower(tostring(SpawnPoint.Value))
                    needSpawn = not sp:find("fishman")
                elseif zone.specialSpawn then
                    -- specialSpawn: CHỈ dùng flag spawnSetFor, KHÔNG dùng nearSpawn shortcut
                    -- Lý do: islandPos == spawnPos cho Sky Island → player vừa đến đảo đã
                    -- trong vòng 150 studs của spawnPos → nearSpawn=true → skip DoSetSpawn_Special
                    -- → nhảy thẳng TweenCombat mà chưa qua Robo/SetSpawn/NPC gì cả
                    -- DoSetSpawn_Special tự xử lý toàn bộ flow: Robo→SetSpawn→bay NPC→đợi NPC
                    needSpawn = not spawnSetFor[zoneKey]
                else
                    if not spawnSetFor[zoneKey] then
                        if zone.islandTweenToNpc then
                            -- Nếu đang trên island rồi → skip DoSetSpawn, đi thẳng npcPos
                            local r2 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                            if r2 and IsOnIsland(zone) then
                                spawnSetFor[zoneKey] = true
                            end
                        else
                            local r2 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                            local nearSpawn = r2 and (r2.Position - zone.spawnPos).Magnitude < 100
                            if nearSpawn then spawnSetFor[zoneKey] = true end
                        end
                    end
                    needSpawn = not spawnSetFor[zoneKey]
                end
            end
            if needSpawn then
                if zone.learnOnly then
                    DoLearnStyle(zone)
                    spawnSetFor[zoneKey] = true
                elseif zone.specialSpawn then
                    DoSetSpawn_Special(zone)
                elseif zone.isFishman then
                    DoSetSpawn_Fishman(zone)
                else
                    DoSetSpawn_Normal(zone)
                end
                spawnSetFor[zoneKey] = true
                continue
            end

            -- ── 3. Bay đến NPC area ─────────────────────────────────────
            if zone.isFishman then
                local npcTarget = zone.npcPos
                local distToNpc = (root.Position - npcTarget).Magnitude
                if distToNpc > 120 then
                    _farmNavigating = true
                    if not IslandTween.IsTeleporting then IslandTween.Start(npcTarget) end
                    continue
                end
                _farmNavigating = false
                if IslandTween.IsTeleporting then IslandTween.Stop() end
            end
            if zone.islandTweenToNpc and not hasQuest then
                local distToNpc = (root.Position - zone.npcPos).Magnitude
                if distToNpc > 120 then
                    _farmNavigating = true
                    if not IslandTween.IsTeleporting then IslandTween.Start(zone.npcPos) end
                    continue
                end
                if IslandTween.IsTeleporting then
                    IslandTween.Stop()
                    task.wait(0.5)  -- đợi flyTo coroutine và FakeFloor cleanup hẳn
                    lv, root = GetVelNode and GetVelNode() or nil, nil
                end
                _farmNavigating = false
            end

            -- ── 4. Quest — quit stale quest if it belongs to wrong zone ──
            local rawQ    = tostring(CurrentQuest.Value)
            local rawQLow = rawQ:lower():gsub("%s+","")
            local expectQ = zone.npcName:lower():gsub("%s+","")
            local hasAnyQuest    = rawQLow ~= "none" and rawQLow ~= "" and rawQLow ~= "nil" and rawQLow ~= "0"
            local isCorrectQuest = rawQLow:find(expectQ, 1, true)
            -- Chỉ quit khi có quest KHÁC zone hiện tại
            -- Nếu đúng quest (kể cả sau khi die/respawn) → giữ nguyên, không quit
            if hasAnyQuest and not isCorrectQuest then
                pcall(function()
                    QuestEvent:InvokeServer(unpack({ { [1] = "quit" } }))
                end)
                task.wait(0.5)
                hasQuest = false; lastQuestCheck = 0
                continue
            end
            -- Nếu đang có đúng quest → cập nhật hasQuest=true luôn (kể cả sau die)
            if hasAnyQuest and isCorrectQuest then
                hasQuest = true; lastQuestCheck = tick()
            end
            -- oneTimeQuest done detect
            if tick()-lastQuestCheck > 2 then
                lastQuestCheck=tick(); hasQuest=CheckHasQuest()
                if zone.oneTimeQuest and not hasQuest and questDoneFor[zoneKey] == "pending" then
                    questDoneFor[zoneKey] = true
                end
            end
            -- oneTimeQuest done: quest không làm lại nhưng vẫn tiếp tục farm bình thường
            -- hasQuest=false sau khi done → sẽ về npcPos nhận lại nhưng server reject → loop
            -- Fix: nếu done rồi thì bỏ qua bước take quest, đi thẳng vào farm
            if zone.oneTimeQuest and questDoneFor[zoneKey] == true and not hasQuest then
                hasQuest = true  -- giả lập có quest để skip TakeQuest
            end

            if not hasQuest then
                TakeQuest(zone)
                if zone.oneTimeQuest then questDoneFor[zoneKey] = "pending" end
                hasQuest=CheckHasQuest(); lastQuestCheck=tick()
                continue
            end

            -- ── 5. Farm combat ────────────────────────────────────────
            if zone.needsSwim then
                local kff = Workspace:FindFirstChild("ZILI_KoriFakeFloor")
                if not kff then
                    kff = Instance.new("Part")
                    kff.Name="ZILI_KoriFakeFloor"; kff.Size=Vector3.new(15,2,15)
                    kff.Anchored=true; kff.Transparency=1; kff.Parent=Workspace
                end
                local r0 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if r0 then kff.CFrame = r0.CFrame * FAKE_FLOOR_OFF end
                if not _skyWalkLoop then
                    local skillEvent = cloneref(ReplicatedStorage):WaitForChild("Events"):WaitForChild("Skill")
                    _skyWalkLoop = task.spawn(function()
                        while task.wait(0.1) do
                            if not _active then break end
                            pcall(function()
                                local ch = Player.Character
                                if ch and ch:FindFirstChild("HumanoidRootPart") then
                                    skillEvent:InvokeServer("Sky Walk2",{char=ch,cf=ch.HumanoidRootPart.CFrame})
                                end
                            end)
                        end
                        _skyWalkLoop = nil
                    end)
                end
            end
            -- Nếu zone có mobPos2 (vd: Land of the Sky):
            --   Tier 1 (lower): lure+kill quái quanh mobPos
            --   → hết quái → switch Tier 2 (upper): lure+kill quanh mobPos2
            --   → hết quái → đợi spawn tại mobPos2 → switch lại Tier 1
            -- Zone không có mobPos2: chỉ dùng mobPos bình thường
            local tierCenter = (zone.mobPos2 and farmTier == 2)
                               and zone.mobPos2 or zone.mobPos
            local center = tierCenter

            if farmPhase == PHASE_LURE then
                -- ── SMART LURE: fresh-scan mỗi iteration, sort theo distance ──
                local root0 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local aliveMobs = ScanLureMobs(zone, center)

                -- Phân loại: "chưa lure" = HP còn đầy (MaxHealth), "đã lure" = đã bị đánh
                local unlured = {}
                local lured   = {}
                for _, mob in ipairs(aliveMobs) do
                    local hum = mob:FindFirstChild("Humanoid")
                    if hum then
                        if hum.Health >= hum.MaxHealth then
                            table.insert(unlured, mob)
                        else
                            table.insert(lured, mob)
                        end
                    end
                end

                -- Sort unlured theo distance gần nhất từ vị trí hiện tại
                if root0 and #unlured > 0 then
                    table.sort(unlured, function(a, b)
                        local ha = a:FindFirstChild("HumanoidRootPart")
                        local hb = b:FindFirstChild("HumanoidRootPart")
                        if not ha then return false end
                        if not hb then return true end
                        return (ha.Position - root0.Position).Magnitude
                             < (hb.Position - root0.Position).Magnitude
                    end)
                end

                if #unlured == 0 then
                    if #aliveMobs > 0 then
                        -- Tất cả đã bị đánh → COMBO
                        lureMobList = aliveMobs
                        farmPhase   = PHASE_COMBO
                    else
                        -- Không có quái nào trong radius thường → check rộng hơn (x1.5)
                        -- để bắt mob 7+ đang đi vào nhưng chưa vào LURE_RADIUS
                        local widerMobs = ScanLureMobs(zone, center, LURE_RADIUS * 1.5)
                        if #widerMobs > 0 then
                            farmPhase = PHASE_LURE
                        elseif zone.mobPos2 then
                            if farmTier == 1 then
                                -- Lower xong → lên Upper
                                farmTier  = 2
                                farmPhase = PHASE_LURE
                            else
                                -- Upper xong → đợi spawn tại mobPos2 rồi về Tier 1
                                TweenCombat(CFrame.new(zone.mobPos2), "Farm")
                                task.wait(1)
                                -- Unstuck: nếu idle tại mobPos2 quá 15s không gây dmg
                                -- → tween ra điểm unstuck để quái bị kéo ra khỏi chỗ kẹt
                                if zone.unstuckPos and tick() - lastDmgDealt >= 15 then
                                    TweenCombat(CFrame.new(zone.unstuckPos), "Farm")
                                    task.wait(2)
                                end
                                -- Check lại: nếu đã có quái respawn ở tier 1 thì về luôn
                                local lowerMobs = ScanLureMobs(zone, zone.mobPos)
                                if #lowerMobs > 0 then
                                    farmTier  = 1
                                    farmPhase = PHASE_LURE
                                end
                                -- nếu chưa thì tiếp tục đứng đợi ở mobPos2
                            end
                        else
                            -- Zone 1 tầng: đứng đợi tại center
                            TweenCombat(CFrame.new(center), "Farm")
                        end
                    end
                    continue
                end

                -- Đi đến con gần nhất chưa bị đánh
                -- farmHover giữ nguyên (apply bởi TweenCombat "Farm")
                -- Y cố định = center.Y (zone.mobPos.Y) — không track hrp.Y theo mob
                -- → tránh tp underground khi mob rơi xuống hố hoặc di chuyển Y bất thường
                local mob = unlured[1]
                local hrp = mob:FindFirstChild("HumanoidRootPart")
                local hum = mob:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then continue end

                if TweenCombat(hrp.CFrame, "Farm") then
                    MeleeHit(mob)
                    task.wait(0.15)
                end

            elseif farmPhase == PHASE_COMBO then
                -- Fresh-scan để bắt quái respawn thêm hoặc quái mới full HP
                local freshMobs = ScanLureMobs(zone, center)
                local hasNewFullHP = false
                for _, mob in ipairs(freshMobs) do
                    local hum = mob:FindFirstChild("Humanoid")
                    if hum and hum.Health >= hum.MaxHealth then
                        hasNewFullHP = true; break
                    end
                end
                -- Nếu có quái mới full HP (respawn thêm) → quay về LURE để lure thêm
                if hasNewFullHP then
                    farmPhase = PHASE_LURE
                    continue
                end

                -- Kiểm tra còn mob bị damage không
                local anyDamaged = false
                for _, npc in ipairs(freshMobs) do
                    local h = npc:FindFirstChild("Humanoid")
                    if h and h.Health > 0 and h.Health < h.MaxHealth then
                        anyDamaged = true; break
                    end
                end

                if not anyDamaged then
                    farmPhase   = PHASE_LURE
                    lureMobList = {}
                    local hasUnlured = false
                    for _, npc in ipairs(ScanLureMobs(zone, center)) do
                        local h = npc:FindFirstChild("Humanoid")
                        if h and h.Health >= h.MaxHealth then hasUnlured = true; break end
                    end
                    if not hasUnlured then
                        -- zone.comboY: snap chính xác Y khi đứng tại center (bỏ qua farmHover)
                        -- Kori: comboY=66.37. Zones khác: dùng "Farm" + center bình thường.
                        if zone.comboY then
                            TweenCombat(CFrame.new(center.X, zone.comboY, center.Z), "Move")
                        else
                            TweenCombat(CFrame.new(center), "Farm")
                        end
                        task.wait(0.3)
                    end
                    continue
                end

                -- COMBO: về center đánh tất cả
                -- zone.comboY: dùng Y chính xác thay vì farmHover (Kori=66.37)
                lureMobList = freshMobs
                if zone.comboY then
                    if TweenCombat(CFrame.new(center.X, zone.comboY, center.Z), "Move") then
                        MeleeHitMulti(lureMobList)
                    end
                else
                    local comboHover = zone.comboHover or currentFarmHover
                    local comboCF = CFrame.new(center.X, center.Y - currentFarmHover + comboHover, center.Z)
                    if TweenCombat(comboCF, "Farm") then
                        MeleeHitMulti(lureMobList)
                    end
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- PUBLIC API
    -- ═══════════════════════════════════════════════════════════════
    local _conn = nil

    function AutoFarmLevel.Toggle(state)
        _active = state
        ZiliState.LureFarm = state
        if state then
            -- Reset lure state khi bật lại
            farmPhase   = PHASE_LURE
            farmTier    = 1
            lureMobList = {}; lureIdx = 1
            if not _conn then
                _conn = task.spawn(function()
                    task.wait(3)  -- chờ 3s trước khi bắt đầu
                    mainLoop()
                end)
            end
        else
            _conn = nil
            if IslandTween.IsTeleporting then IslandTween.Stop() end
            ResetPhysics()
        end
    end

    function AutoFarmLevel.IsActive() return _active end

    return AutoFarmLevel
end


-- 📦 MODULE: AutoGetBuso.lua  [REWRITE v3 — IslandTween + TweenCombat clone Level Farm]
-- Mirror y chang flow của Kori Island trong Level Farm:
--   DoSetSpawn_Kori (swim sang Kori, SetSpawn Zou) → TakeQuest (NPC Ray)
--   → PHASE_LURE (TweenCombat hrp.X/Z + center.Y) → PHASE_COMBO (center) → repeat
--   Auto-stop khi BusoMastery >= 1
__modules["Farm/AutoGetBuso"] = function()
    local AutoGetBusoModule = {}

    local cloneref          = cloneref or function(o) return o end
    local Players           = cloneref(game:GetService("Players"))
    local RunService        = cloneref(game:GetService("RunService"))
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local Workspace         = cloneref(game:GetService("Workspace"))
    local VirtualUser       = game:GetService("VirtualUser")

    local Player = Players.LocalPlayer

    -- ── Borrow IslandTween từ module đã load ─────────────────────────
    local IslandTween = require("Island/TWEEN TO ISLAND")

    -- ── Remote Events ─────────────────────────────────────────────────
    local Events     = cloneref(ReplicatedStorage):WaitForChild("Events", 10)
    local TakestamEv = Events:WaitForChild("takestam",       5)
    local SetSpawnEv = Events:WaitForChild("SetSpawn",       5)
    local QuestEvent = Events:WaitForChild("Quest",          5)
    local CombatReg  = Events:WaitForChild("CombatRegister", 5)

    local StatsFolder  = ReplicatedStorage:WaitForChild("Stats"..Player.Name, 10)
    local SpawnPoint   = StatsFolder and StatsFolder:FindFirstChild("Stats")
                         and StatsFolder.Stats:WaitForChild("SpawnPoint", 5)
    local CurrentQuest = StatsFolder and StatsFolder:WaitForChild("Quest", 5)
                         and StatsFolder.Quest:WaitForChild("CurrentQuest", 5)

    -- ── Tọa độ (mirror zone Kori trong Level Farm) ───────────────────
    local ZOU_SPAWN   = Vector3.new(-3150,   11.73,  -5233.55)
    local KORI_NPC    = Vector3.new(-4245.74,169.48, -2990.84)
    local CENTER      = Vector3.new(-4468.36,  66.37, -2930.21)  -- Y cứng 66.37
    local LURE_RADIUS = 350
    local MOB_NAME    = "Yeti"
    local QUEST_NAME  = "Road to Armament"

    ZiliState.BusoFarm = false

    -- ── AntiAFK ───────────────────────────────────────────────────────
    pcall(function()
        for _, c in pairs(getconnections(Player.Idled)) do c:Disable() end
    end)
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    -- ══════════════════════════════════════════════════════════════════
    -- TweenCombat (LinearVelocity, clone y chang Level Farm)
    -- ══════════════════════════════════════════════════════════════════
    local FARM_HOVER = 8
    local VEC_ZERO   = Vector3.new(0,0,0)

    local function GetVelNode()
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil, nil end
        local att = root:FindFirstChild("BF_Attach") or Instance.new("Attachment", root)
        att.Name = "BF_Attach"
        local lv  = root:FindFirstChild("BF_VelocityNode") or Instance.new("LinearVelocity", root)
        lv.Name="BF_VelocityNode"; lv.Attachment0=att; lv.MaxForce=math.huge
        return lv, root
    end

    local function TweenCombat(targetCFrame, actionType)
        local lv, root = GetVelNode()
        if not root then return false end
        if IslandTween.IsTeleporting then IslandTween.Stop() end
        -- Spoof stamina
        if not ZiliState.LastBFStamTick or tick()-ZiliState.LastBFStamTick >= 0.05 then
            ZiliState.LastBFStamTick = tick()
            pcall(function() TakestamEv:FireServer(0.505, "dash", root.CFrame) end)
        end
        local finalPos = targetCFrame.Position
        if actionType == "Farm" then finalPos = finalPos + Vector3.new(0, FARM_HOVER, 0) end
        local dist = (finalPos - root.Position).Magnitude
        if dist > 2 then
            lv.VectorVelocity = (finalPos - root.Position).Unit * 60
            return false
        else
            lv.VectorVelocity = VEC_ZERO
            if actionType == "Farm" then
                root.CFrame = CFrame.new(root.Position,
                    Vector3.new(targetCFrame.Position.X, root.Position.Y, targetCFrame.Position.Z))
            else
                root.CFrame = targetCFrame
            end
            return true
        end
    end

    -- ── TweenToAndWait (IslandTween long-distance, clone Level Farm) ──
    local function TweenToAndWait(targetPos, threshold, timeout)
        threshold = threshold or 40
        timeout   = timeout   or 60
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - targetPos).Magnitude > threshold then
            IslandTween.Start(targetPos)
            local deadline = tick() + timeout
            while tick() < deadline and ZiliState.BusoFarm do
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if r and (r.Position - targetPos).Magnitude <= threshold then break end
                if r then
                    local xzD = (Vector2.new(r.Position.X,r.Position.Z)
                               - Vector2.new(targetPos.X,targetPos.Z)).Magnitude
                    if xzD <= 50 and math.abs(r.Position.Y-targetPos.Y) > 30 then
                        r.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                    end
                end
                task.wait(0.3)
            end
            IslandTween.Stop()
        end
    end

    -- ── WaitWithStam ──────────────────────────────────────────────────
    local function WaitWithStam(seconds)
        local deadline = tick() + seconds
        while tick() < deadline and ZiliState.BusoFarm do
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r then pcall(function() TakestamEv:FireServer(0.505,"dash",r.CFrame) end) end
            task.wait(0.05)
        end
    end

    -- ── Helpers ───────────────────────────────────────────────────────
    local function GetBusoMastery()
        local v = 0
        pcall(function()
            local sf = ReplicatedStorage:FindFirstChild("Stats"..Player.Name)
            local bv = sf and sf:FindFirstChild("Stats") and sf.Stats:FindFirstChild("BusoMastery")
            if bv then v = tonumber(bv.Value) or 0 end
        end)
        return v
    end

    local function CheckHasQuest()
        local q = tostring(CurrentQuest and CurrentQuest.Value or ""):lower():gsub("%s+","")
        return q ~= "" and q ~= "none" and q ~= "nil" and q ~= "0"
    end

    local function ScanYeti()
        local result = {}
        local folder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Enemies") or Workspace
        for _, npc in ipairs(folder:GetChildren()) do
            if npc.Name:find(MOB_NAME, 1, true) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                local hum = npc:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0
                   and (hrp.Position - CENTER).Magnitude <= LURE_RADIUS then
                    table.insert(result, npc)
                end
            end
        end
        return result
    end

    -- ── Melee (clone Level Farm) ──────────────────────────────────────
    local HIT_DELAY  = 0.366
    local comboIdx   = 1
    local lastHit    = 0

    local function MeleeHit(mob)
        if tick() - lastHit < HIT_DELAY then return end
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then
            local m = Player.Backpack:FindFirstChild("Melee")
            if m then pcall(function() char:FindFirstChild("Humanoid"):EquipTool(m) end) end
            return
        end
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        local hum = mob:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        pcall(function()
            CombatReg:FireServer(comboIdx, hrp.CFrame, hrp.AssemblyLinearVelocity)
        end)
        comboIdx = comboIdx % 4 + 1
        lastHit  = tick()
    end

    local function MeleeHitMulti(mobs)
        for _, mob in ipairs(mobs) do
            local hum = mob:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then MeleeHit(mob) end
        end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- PHASE SYSTEM
    -- ══════════════════════════════════════════════════════════════════
    local PHASE_LURE  = "LURE"
    local PHASE_COMBO = "COMBO"
    local farmPhase   = PHASE_LURE
    local lureMobList = {}
    local lureIdx     = 1
    -- Quest guard (same fix như Level Farm Bug 3)
    local hasQuest       = false
    local lastQuestCheck = 0
    local spawnDone      = false
    -- Quest grace (Bug 3 AutoGetBuso — chết/respawn → CurrentQuest momentarily empty)
    local QUEST_GONE_GRACE = 8
    local _isDead          = false
    local _respawnTime     = 0

    -- ── DoSetSpawn_Kori (exact clone) ─────────────────────────────────
    local function DoSetSpawn_Kori()
        -- 1. Snap xuống nước dưới đảo hiện tại
        local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame = CFrame.new(r.Position.X, -97.15, r.Position.Z) end
        WaitWithStam(0.5)
        if not ZiliState.BusoFarm then return end

        -- 2. IslandTween bơi XZ đến Kori, dừng khi XZ <= 60
        IslandTween.Start(CENTER)
        local swimDeadline = tick() + 120
        while tick() < swimDeadline and ZiliState.BusoFarm do
            local rr = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not rr then task.wait(0.05); continue end
            local xzD = (Vector2.new(rr.Position.X,rr.Position.Z)
                       - Vector2.new(CENTER.X, CENTER.Z)).Magnitude
            if xzD <= 60 then IslandTween.Stop(); break end
            task.wait(0.05)
        end
        IslandTween.Stop()
        if not ZiliState.BusoFarm then return end

        -- 3. Snap lên đảo Zou (spawnPos), SetSpawn, chờ confirm
        TweenToAndWait(ZOU_SPAWN, 60, 40)
        if not ZiliState.BusoFarm then return end
        local limit = tick() + 15
        while tick() < limit and ZiliState.BusoFarm do
            if TweenCombat(CFrame.new(ZOU_SPAWN), "Move") then
                WaitWithStam(3)
                pcall(function() SetSpawnEv:FireServer() end)
                WaitWithStam(1)
                break
            end
            task.wait(0.05)
        end
        if not ZiliState.BusoFarm then return end

        -- 4. Snap lại xuống nước rồi IslandTween đến Kori Island thật
        local r2 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if r2 then r2.CFrame = CFrame.new(r2.Position.X, -97.15, r2.Position.Z) end
        WaitWithStam(0.5)
        IslandTween.Start(CENTER)
        local upDeadline = tick() + 120
        while tick() < upDeadline and ZiliState.BusoFarm do
            local rr = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not rr then task.wait(0.05); continue end
            if rr.Position.Y > 50 and (rr.Position - CENTER).Magnitude < 80 then
                IslandTween.Stop(); break
            end
            task.wait(0.05)
        end
        IslandTween.Stop()
    end

    -- ── TakeQuest (NPC Ray, clone TakeQuest Level Farm) ───────────────
    local function TakeQuest()
        local npcTarget = KORI_NPC + Vector3.new(0, 0, 3)
        -- TweenCombat chính xác đến NPC
        local limit = tick() + 25
        while tick() < limit and ZiliState.BusoFarm do
            if TweenCombat(CFrame.new(npcTarget), "Move") then break end
            task.wait(0.05)
        end
        if not ZiliState.BusoFarm then return end
        pcall(function() QuestEvent:InvokeServer({"takequest", QUEST_NAME}) end)
        task.wait(0.5)
        lureMobList = {}; lureIdx = 1; farmPhase = PHASE_LURE
        -- Scan initial mob list
        local folder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Enemies") or Workspace
        for _, npc in ipairs(folder:GetChildren()) do
            if npc.Name:find(MOB_NAME, 1, true) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                local hum = npc:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0
                   and (hrp.Position - CENTER).Magnitude <= LURE_RADIUS then
                    table.insert(lureMobList, npc)
                end
            end
        end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- MAIN LOOP
    -- ══════════════════════════════════════════════════════════════════
    local function mainLoop()
        while ZiliState.BusoFarm do
            task.wait(0.05)

            -- Done check
            if GetBusoMastery() >= 1 then
                AutoGetBusoModule.Toggle(false)
                pcall(getgenv().ZiliLog, "Buso Haki xong! Auto Get Buso dừng.", "buso")
                return
            end

            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChild("Humanoid")

            -- Death / respawn guard (same pattern Bug 3 fix)
            if not root or not hum or hum.Health <= 0 then
                if not _isDead then
                    _isDead = true
                    IslandTween.Stop()
                    local lv = root and root:FindFirstChild("BF_VelocityNode")
                    if lv then lv.VectorVelocity = Vector3.new(0,0,0) end
                end
                task.wait(0.3)
                continue
            end

            if _isDead then
                _isDead = false; _respawnTime = tick()
                pcall(getgenv().ZiliLog, "Respawn — chờ "..QUEST_GONE_GRACE.."s sync", "buso")
            end

            -- Buffer sau respawn: chờ stats sync, giữ hasQuest để không re-fire takequest
            if tick() - _respawnTime < QUEST_GONE_GRACE then
                task.wait(0.3)
                continue
            end

            -- ── Step 1: SetSpawn Zou + đến Kori (1 lần) ──────────────
            if not spawnDone then
                local sp = string.lower(tostring(SpawnPoint and SpawnPoint.Value or ""))
                if not sp:find("zou", 1, true)
                   or (root.Position - CENTER).Magnitude > 500 then
                    DoSetSpawn_Kori()
                end
                spawnDone = true
                hasQuest  = CheckHasQuest()
                lastQuestCheck = tick()
                continue
            end

            -- ── On-island check ───────────────────────────────────────
            local onIsland = root.Position.Y > 50
                          and (root.Position - CENTER).Magnitude < 600
            if not onIsland then
                -- Belum sampai → IslandTween
                if not IslandTween.IsTeleporting then IslandTween.Start(CENTER) end
                continue
            end
            if IslandTween.IsTeleporting then IslandTween.Stop() end

            -- ── Step 2: Quest guard (clone Level Farm Bug 3 fix) ──────
            local rawQ    = tostring(CurrentQuest and CurrentQuest.Value or ""):lower():gsub("%s+","")
            local hasAnyQ = rawQ ~= "" and rawQ ~= "none" and rawQ ~= "nil" and rawQ ~= "0"
            local correctQ = rawQ:find("road", 1, true) or rawQ:find("armament", 1, true)

            -- Sync hasQuest jika quest masih ada setelah respawn
            if hasAnyQ and correctQ then hasQuest = true; lastQuestCheck = tick() end
            -- Chỉ recheck sau 2s
            if tick() - lastQuestCheck > 2 then
                lastQuestCheck = tick()
                hasQuest = CheckHasQuest()
            end

            if not hasQuest then
                TakeQuest()
                hasQuest = CheckHasQuest(); lastQuestCheck = tick()
                continue
            end

            -- ── Step 3: LURE / COMBO ──────────────────────────────────
            if farmPhase == PHASE_LURE then
                local all     = ScanYeti()
                local unlured = {}
                for _, npc in ipairs(all) do
                    local h = npc:FindFirstChild("Humanoid")
                    if h and h.Health >= h.MaxHealth then
                        table.insert(unlured, npc)
                    end
                end

                -- Không có quái full HP → chuyển COMBO
                if #unlured == 0 then
                    local anyAlive = #all > 0
                    if anyAlive then
                        farmPhase = PHASE_COMBO
                    else
                        -- Tất cả chết → đứng center chờ respawn
                        TweenCombat(CFrame.new(CENTER), "Farm")
                        task.wait(0.5)
                    end
                    continue
                end

                -- Sort theo khoảng cách đến CENTER (lure gần trước)
                table.sort(unlured, function(a, b)
                    local ha = a:FindFirstChild("HumanoidRootPart")
                    local hb = b:FindFirstChild("HumanoidRootPart")
                    if not ha or not hb then return false end
                    return (ha.Position - CENTER).Magnitude < (hb.Position - CENTER).Magnitude
                end)

                local mob = unlured[1]
                local hrp = mob:FindFirstChild("HumanoidRootPart")
                local h2  = mob:FindFirstChild("Humanoid")
                if not hrp or not h2 or h2.Health <= 0 then continue end

                -- Y cứng = CENTER.Y, chỉ lấy XZ của mob → farmHover apply bởi TweenCombat
                local lureTarget = CFrame.new(hrp.Position.X, CENTER.Y, hrp.Position.Z)
                if TweenCombat(lureTarget, "Farm") then
                    MeleeHit(mob)
                    task.wait(0.15)
                end

            elseif farmPhase == PHASE_COMBO then
                local freshMobs = ScanYeti()
                -- Có quái mới full HP → về LURE
                for _, npc in ipairs(freshMobs) do
                    local h = npc:FindFirstChild("Humanoid")
                    if h and h.Health >= h.MaxHealth then
                        farmPhase = PHASE_LURE; break
                    end
                end
                if farmPhase == PHASE_LURE then continue end

                -- Kiểm tra còn mob damaged không
                local anyDamaged = false
                for _, npc in ipairs(freshMobs) do
                    local h = npc:FindFirstChild("Humanoid")
                    if h and h.Health > 0 and h.Health < h.MaxHealth then
                        anyDamaged = true; break
                    end
                end
                if not anyDamaged then
                    farmPhase = PHASE_LURE; lureMobList = {}
                    local w = tick() + 1
                    while tick() < w do
                        TweenCombat(CFrame.new(CENTER), "Farm"); task.wait(0.1)
                    end
                    continue
                end

                lureMobList = freshMobs
                -- Y cứng CENTER.Y
                if TweenCombat(CFrame.new(CENTER.X, CENTER.Y, CENTER.Z), "Farm") then
                    MeleeHitMulti(lureMobList)
                end

                -- Quest gone check với grace period
                local q2 = tostring(CurrentQuest and CurrentQuest.Value or ""):lower():gsub("%s+","")
                local questGone = (q2=="" or q2=="none" or q2=="nil" or q2=="0")
                if questGone then
                    local gend = tick() + QUEST_GONE_GRACE
                    while tick() < gend and ZiliState.BusoFarm do
                        local q3 = tostring(CurrentQuest and CurrentQuest.Value or ""):lower():gsub("%s+","")
                        if q3 ~= "" and q3 ~= "none" and q3 ~= "nil" and q3 ~= "0" then
                            questGone = false; break
                        end
                        task.wait(0.5)
                    end
                    if questGone then hasQuest = false end
                end
            end
        end
    end

    -- ── Toggle API ────────────────────────────────────────────────────
    function AutoGetBusoModule.Toggle(state)
        ZiliState.BusoFarm = state
        pcall(getgenv().ZiliLog,
            state and "Buso farm started (Kori Island)" or "Buso farm stopped", "buso")
        if state then
            spawnDone     = false
            hasQuest      = false
            lastQuestCheck= 0
            farmPhase     = PHASE_LURE
            lureMobList   = {}
            _isDead       = false
            _respawnTime  = 0
            task.spawn(mainLoop)
        else
            IslandTween.Stop()
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local lv = r and r:FindFirstChild("BF_VelocityNode")
            if lv then lv.VectorVelocity = Vector3.new(0,0,0) end
            spawnDone = false; hasQuest = false
            _isDead = false; _respawnTime = 0
        end
    end

    return AutoGetBusoModule
end

-- 📦 MODULE: AutoGeppo.lua  [REWRITE v2 — NPC Yi learn SkyWalk style]
-- Logic đơn giản: fly thẳng đến NPC Yi → fire learnStyle("skyWalkTrainer") → toggle off
-- Không cần qua Fishman Island portal nữa; Yi ở trực tiếp trên đảo Coco Island.
__modules["Farm/AutoGeppo"] = function()
    local AutoGeppoModule = {}

    local cloneref          = cloneref or function(o) return o end
    local Players           = cloneref(game:GetService("Players"))
    local RunService        = cloneref(game:GetService("RunService"))
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local Workspace         = cloneref(game:GetService("Workspace"))
    local VirtualUser       = game:GetService("VirtualUser")

    local Player = Players.LocalPlayer

    ZiliState.AutoGeppo = false

    -- ── Tọa độ NPC Yi (Coco Island / Sky Island) ─────────────────────
    -- Vector3 chính xác từ Level Farm (DoSetSpawn_Kori B0)
    local YI_POS = Vector3.new(-3086.87, 94.54, -11755.48)

    -- ── Remote Event ─────────────────────────────────────────────────
    local LearnStyleEv = nil
    pcall(function()
        LearnStyleEv = ReplicatedStorage:WaitForChild("Events", 5)
                        :WaitForChild("learnStyle", 5)
    end)

    local TakestamEv = nil
    pcall(function()
        TakestamEv = ReplicatedStorage:WaitForChild("Events", 5)
                      :WaitForChild("takestam", 5)
    end)

    -- ── AntiAFK ───────────────────────────────────────────────────────
    pcall(function()
        for _, c in pairs(getconnections(Player.Idled)) do c:Disable() end
    end)
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    -- ── Stamina Spoof ─────────────────────────────────────────────────
    local _spoofing = false
    local function StartSpoof()
        if _spoofing then return end
        _spoofing = true
        task.spawn(function()
            while _spoofing do
                if TakestamEv and TakestamEv.Parent then
                    local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    pcall(function() TakestamEv:FireServer(0.505, "dash", r and r.CFrame) end)
                end
                task.wait(0.05)
            end
        end)
    end
    local function StopSpoof() _spoofing = false end

    -- ── Fly tween ─────────────────────────────────────────────────────
    local FakeFloor = Instance.new("Part")
    FakeFloor.Name        = "Geppo_FakeFloor"
    FakeFloor.Size        = Vector3.new(25, 2, 25)
    FakeFloor.Anchored    = true
    FakeFloor.CanCollide  = true
    FakeFloor.Transparency = 1
    FakeFloor.Parent      = nil

    local _flyConn = nil
    local function StartFly(target)
        if _flyConn then _flyConn:Disconnect() end
        StartSpoof()
        FakeFloor.Parent = Workspace
        _flyConn = RunService.Heartbeat:Connect(function(dt)
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not r or not r.Parent then return end
            FakeFloor.CFrame = r.CFrame * CFrame.new(0, -3.2, 0)
            local cur  = r.Position
            local diff = target - cur
            local dist = diff.Magnitude
            if dist < 3 then return end
            local step = math.min(90 * dt, dist)
            r.CFrame = CFrame.lookAt(cur + diff.Unit * step, target)
            pcall(function() r.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        end)
    end
    local function StopFly()
        if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
        StopSpoof()
        if FakeFloor.Parent then FakeFloor.Parent = nil end
    end

    -- ── Kiểm tra đã có SkyWalk chưa ──────────────────────────────────
    local function HasSkyWalk()
        local has = false
        pcall(function()
            local sf = ReplicatedStorage:FindFirstChild("Stats"..Player.Name)
            local sk = sf and sf:FindFirstChild("Skills")
            local sw = sk and sk:FindFirstChild("skyWalk")
            if sw and (sw.Value == true or sw.Value == 1) then has = true end
        end)
        return has
    end

    -- ── MAIN LOOP ─────────────────────────────────────────────────────
    task.spawn(function()
        while true do
            task.wait(0.1)
            if not ZiliState.AutoGeppo then
                StopFly()
                task.wait(0.3)
                continue
            end

            -- Đã có SkyWalk rồi → tắt
            if HasSkyWalk() then
                AutoGeppoModule.Toggle(false)
                pcall(getgenv().ZiliLog, "SkyWalk (Geppo) đã học xong! Auto Geppo dừng.", "geppo")
                continue
            end

            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChild("Humanoid")
            if not root or not hum or hum.Health <= 0 then
                StopFly(); task.wait(0.5); continue
            end

            local dist = (root.Position - YI_POS).Magnitude

            if dist > 25 then
                -- Fly thẳng đến NPC Yi
                if not _flyConn then StartFly(YI_POS) end
            else
                -- Đã đến nơi — dừng fly, đứng trước Yi
                StopFly()
                root.CFrame = CFrame.new(YI_POS + Vector3.new(0, 0, 4))
                    * CFrame.Angles(0, math.pi, 0)
                task.wait(0.3)

                -- Fire ProximityPrompt nếu có (chat mở)
                pcall(function()
                    for _, prompt in ipairs(Workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            if prompt.Parent and (prompt.Parent.Position - root.Position).Magnitude <= 20 then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end)

                -- Đợi GUI chat mở (tối đa 3s) rồi auto-click
                local waitT = tick()
                while tick() - waitT < 3 and ZiliState.AutoGeppo do
                    local chatGui = Player.PlayerGui:FindFirstChild("NPCCHAT")
                    if chatGui then
                        -- Auto click tất cả nút confirm
                        for _, v in ipairs(chatGui:GetDescendants()) do
                            if v:IsA("TextButton") and v.Visible then
                                local t = string.lower(v.Text)
                                if t:match("yes") or t:match("set") or t:match("accept")
                                   or t:match("okay") or t:match("next") or t:match("continue")
                                   or t:match("take") or t:match("go") or t:match("learn")
                                   or t:match("buy") then
                                    if getconnections then
                                        for _, c in pairs(getconnections(v.MouseButton1Click)) do pcall(function() c:Fire() end) end
                                        for _, c in pairs(getconnections(v.Activated))         do pcall(function() c:Fire() end) end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.25)
                end

                -- Fire learnStyle remote trực tiếp (backup kể cả chat không mở)
                task.wait(0.5)
                if ZiliState.AutoGeppo then
                    pcall(function()
                        if LearnStyleEv then
                            LearnStyleEv:FireServer("skyWalkTrainer")
                        end
                    end)
                    task.wait(1.5)
                    -- Kiểm tra lại sau khi fire
                    if HasSkyWalk() then
                        AutoGeppoModule.Toggle(false)
                        pcall(getgenv().ZiliLog, "SkyWalk (Geppo) đã học xong!", "geppo")
                    else
                        -- Retry sau 3s nếu chưa learn được
                        task.wait(3)
                    end
                end
            end
        end
    end)

    -- ── Toggle API ────────────────────────────────────────────────────
    function AutoGeppoModule.Toggle(state)
        ZiliState.AutoGeppo = state
        pcall(getgenv().ZiliLog, state and "Geppo farm started (NPC Yi)" or "Geppo farm stopped", "geppo")
        if not state then StopFly() end
    end

    return AutoGeppoModule
end

-- 📦 MODULE: Farm/AutoEnterSecondSea
-- Logic: kiểm tra World Scroll → nếu chưa có thì đến lightning island nhặt
--        → sau khi có scroll: snap đến afterScrollCF (cổng vào Sea 2)
--        → toggle off khi xong
__modules["Farm/AutoEnterSecondSea"] = function()
    local AutoEnterSecondSeaModule = {}

    local cloneref          = cloneref or function(o) return o end
    local Players           = cloneref(game:GetService("Players"))
    local RunService        = cloneref(game:GetService("RunService"))
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local Workspace         = cloneref(game:GetService("Workspace"))

    local Player = Players.LocalPlayer
    local vim    = Instance.new("VirtualInputManager")

    ZiliState.AutoEnterSecondSea = false

    -- ── Tọa độ ───────────────────────────────────────────────────────
    local LIGHTNING_ISLAND = Vector3.new(-7348.86,   3.27, -14950.54)
    local AFTER_SCROLL_CF  = CFrame.new(-8562.48145, 76.3761597, -8378.80176)

    -- ── Remote ───────────────────────────────────────────────────────
    local TakestamEv = nil
    pcall(function()
        TakestamEv = ReplicatedStorage:WaitForChild("Events", 5)
                      :WaitForChild("takestam", 5)
    end)

    -- ── Check World Scroll trong inventory ───────────────────────────
    local function HasWorldScroll()
        local found = false
        pcall(function()
            local sf     = ReplicatedStorage:FindFirstChild("Stats"..Player.Name)
            local invVal = sf and sf:FindFirstChild("Inventory") and sf.Inventory:FindFirstChild("Inventory")
            if not invVal then return end
            local data = game:GetService("HttpService"):JSONDecode(invVal.Value)
            if data and (data["World Scroll"] or 0) >= 1 then found = true end
        end)
        return found
    end

    -- ── Check level đủ điều kiện ─────────────────────────────────────
    local function GetLevel()
        local lv = 0
        pcall(function()
            local sf = ReplicatedStorage:FindFirstChild("Stats"..Player.Name)
            local lv_v = sf and sf:FindFirstChild("Stats") and sf.Stats:FindFirstChild("Level")
            if lv_v then lv = tonumber(lv_v.Value) or 0 end
        end)
        return lv
    end

    -- ── Stamina Spoof ─────────────────────────────────────────────────
    local _spoofing = false
    local function StartSpoof()
        if _spoofing then return end
        _spoofing = true
        task.spawn(function()
            while _spoofing do
                if TakestamEv and TakestamEv.Parent then
                    local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    pcall(function() TakestamEv:FireServer(0.505, "dash", r and r.CFrame) end)
                end
                task.wait(0.05)
            end
        end)
    end
    local function StopSpoof() _spoofing = false end

    -- ── Fly ──────────────────────────────────────────────────────────
    local _flyConn = nil
    local function StartFly(target)
        if _flyConn then _flyConn:Disconnect() end
        StartSpoof()
        _flyConn = RunService.Heartbeat:Connect(function(dt)
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not r or not r.Parent then return end
            local cur  = r.Position
            local diff = target - cur
            local dist = diff.Magnitude
            if dist < 3 then return end
            local step = math.min(90 * dt, dist)
            r.CFrame = CFrame.lookAt(cur + diff.Unit * step, target)
            pcall(function() r.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        end)
    end
    local function StopFly()
        if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
        StopSpoof()
    end

    local function FlyToAndWait(target, thresh, timeout)
        thresh  = thresh  or 30
        timeout = timeout or 120
        StartFly(target)
        local dead = tick() + timeout
        while tick() < dead and ZiliState.AutoEnterSecondSea do
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r and (r.Position - target).Magnitude <= thresh then break end
            task.wait(0.2)
        end
        StopFly()
    end

    -- ── Lock position (giữ yên khi nhặt scroll) ──────────────────────
    local _lockConn = nil
    local function StartLock(pos)
        if _lockConn then _lockConn:Disconnect() end
        _lockConn = RunService.Heartbeat:Connect(function()
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r then
                r.CFrame = CFrame.new(pos)
                pcall(function() r.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
            end
        end)
    end
    local function StopLock()
        if _lockConn then _lockConn:Disconnect(); _lockConn = nil end
    end

    -- ════════════════════════════════════════════════════════════════
    -- MAIN LOGIC (chạy 1 lần khi toggle ON)
    -- ════════════════════════════════════════════════════════════════
    local function RunEnterSecondSea()
        -- Pre-check: level >= 325
        if GetLevel() < 325 then
            pcall(getgenv().ZiliLog, "Auto 2nd Sea: Cần Level 325+", "warn")
            AutoEnterSecondSeaModule.Toggle(false)
            return
        end

        -- Bước 1: Nếu đã có World Scroll → snap thẳng đến cổng
        if HasWorldScroll() then
            task.wait(1)
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = AFTER_SCROLL_CF end
            pcall(getgenv().ZiliLog, "Đã có World Scroll — đã snap đến cổng Sea 2!", "2ndsea")
            task.wait(2)
            AutoEnterSecondSeaModule.Toggle(false)
            return
        end

        -- Bước 2: Chưa có scroll → bay đến Lightning Island
        pcall(getgenv().ZiliLog, "Auto 2nd Sea: bay đến Lightning Island...", "2ndsea")

        while ZiliState.AutoEnterSecondSea do
            -- 2a. Fly đến Lightning Island
            FlyToAndWait(LIGHTNING_ISLAND, 30, 120)
            if not ZiliState.AutoEnterSecondSea then return end

            task.wait(2)
            if HasWorldScroll() then break end

            -- 2b. Lock position + Hold Alt để nhặt
            StartLock(LIGHTNING_ISLAND)
            local gotItem = false
            for i = 1, 20 do
                if HasWorldScroll() then gotItem = true; break end
                local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
                if not r or not hum or hum.Health <= 0 then break end  -- die → retry
                vim:SendKeyEvent(true,  Enum.KeyCode.LeftAlt, false, Player)
                task.wait(5)
                vim:SendKeyEvent(false, Enum.KeyCode.LeftAlt, false, Player)
                task.wait(1)
                if not ZiliState.AutoEnterSecondSea then StopLock(); return end
            end
            StopLock()

            if gotItem or HasWorldScroll() then break end
            -- Nếu chết → đợi respawn rồi re-fly
            task.wait(3)
        end

        if not ZiliState.AutoEnterSecondSea then return end

        -- Bước 3: Đã có scroll → snap đến cổng Sea 2
        if HasWorldScroll() then
            task.wait(3)
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = AFTER_SCROLL_CF end
            pcall(getgenv().ZiliLog, "World Scroll nhặt xong — đã snap đến cổng Sea 2!", "2ndsea")
        end

        task.wait(2)
        AutoEnterSecondSeaModule.Toggle(false)
    end

    -- ── Toggle API ────────────────────────────────────────────────────
    function AutoEnterSecondSeaModule.Toggle(state)
        ZiliState.AutoEnterSecondSea = state
        pcall(getgenv().ZiliLog,
            state and "Auto Enter 2nd Sea started" or "Auto Enter 2nd Sea stopped", "2ndsea")
        if state then
            task.spawn(RunEnterSecondSea)
        else
            StopFly()
            StopLock()
        end
    end

    return AutoEnterSecondSeaModule
end

-- 📦 MODULE: Farm/AutoFishMerchant  [FIXED v2]
__modules["Farm/AutoFishMerchant"] = function()
    local AutoFishMerchant = {}

    -- =====================================================================
    -- SERVICES
    -- =====================================================================
    local Players           = cloneref(game:GetService("Players"))
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local HttpService       = cloneref(game:GetService("HttpService"))
    local VirtualUser       = cloneref(game:GetService("VirtualUser"))
    local RunService        = cloneref(game:GetService("RunService"))
    local workspace         = cloneref(game:GetService("Workspace"))
    local LocalPlayer       = Players.LocalPlayer

    -- =====================================================================
    -- CONSTANTS
    -- =====================================================================
    local MAX_SPEED              = 90
    local VEC_ZERO               = Vector3.new(0, 0, 0)
    local MAX_MERCHANT_RETRY     = 6
    local HIGH_Y_MERCHANT_THRESH = 500
    local OFFSET_FAKEFLOOR       = CFrame.new(0, -4.05, 0)
    local DT_CAP                 = 0.08
    local SWIM_Y                 = -97.15
    local WATER_LINE             = 0

    local Cords = {
        Sell  = Vector3.new(-1328.47,  4.07, -4977.97),
        Buy   = Vector3.new(-1342.98,  4.12, -4985.11),
        Craft = Vector3.new(-1376.32,  4.12, -5063.43),
    }

    local FishLists = {
        Leg    = {"Anglerfish","Golden Polka Puffer","Golden Ribbon Angelfish","Golden Tigerfin","Swordfish","Jack-O'-Bite","Dark Skeletal Shark"},
        Rare   = {"Candy Corn Squid","Exotic Tigerfin","Crimson Polka Puffer","Fangfish","Crimson Snapper","Zebra Ribbon Angelfish"},
        Common = {"Blue-Lip Grouper","Tigerfin"},
    }

    local RodsPriority   = {"Devil Fruit Rod","Lovestruck Rod","Merchants Banana Rod","ODM Rod","Jack-O'Rod","Angler Rod","Epic Fishing Rod","Rare Fishing Rod","Common Fishing Rod","Fishing Rod"}
    local TitlesPriority = {"Novice Fisherman","Skilled Fisherman","Master Fisherman","Godly Fisherman"}

    -- =====================================================================
    -- RUNTIME STATE
    -- =====================================================================
    local _Configs = {
        CraftLeg      = false,
        CraftRare     = false,
        CraftRareMode = "single",
        CraftRod      = false,
        EquipRod      = true,
        EquipTitle    = true,
        BuyBait       = false,
        SellCommon    = false,
        SellRare      = false,
        SellLeg       = false,
        AutoMerchant  = false,
    }

    local ItemsToBuy = {}

    ZiliState.AutoFishing           = false
    ZiliState.TargetBait            = nil
    ZiliState.KnownMerchantPos      = nil
    ZiliState.MerchantProcessed     = false
    ZiliState.MerchantSpawnTime     = 0
    ZiliState.LastShopRefreshPeriod = -1
    -- [FIX-1] Flag báo hiệu merchant vừa spawn → ngắt câu ngay lập tức
    ZiliState.MerchantPending       = false

    local _lastShopPeriod = -1

    -- =====================================================================
    -- ANTI-AFK & ANTI-SIT
    -- =====================================================================
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do conn:Disable() end
    end)
    if ZiliState.AntiAfkConnection then ZiliState.AntiAfkConnection:Disconnect() end
    ZiliState.AntiAfkConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    local function PreventSitting(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if humanoid.Sit then humanoid.Sit = false; humanoid.Jump = true end
        end
    end
    if LocalPlayer.Character then PreventSitting(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(PreventSitting)

    -- =====================================================================
    -- AUTO-CLICK WELCOME / TUTORIAL DIALOG (PVP Protection screen)
    -- Tự động next qua màn hình hướng dẫn khi fresh acc vào game
    -- =====================================================================
    task.spawn(function()
        while true do
            task.wait(1.5)
            pcall(function()
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                if not pGui then return end
                for _, gui in pairs(pGui:GetChildren()) do
                    if not gui:IsA("ScreenGui") then continue end
                    for _, v in pairs(gui:GetDescendants()) do
                        if v:IsA("TextButton") and v.Visible then
                            local txt = string.lower(v.Text or "")
                            if txt == "next" or txt == "ok" or txt == "okay"
                                or txt:match("^continue") or txt:match("^skip")
                                or txt:match("^got it") or txt:match("^close") then
                                if getconnections then
                                    for _, c in pairs(getconnections(v.MouseButton1Click)) do pcall(function() c:Fire() end) end
                                    for _, c in pairs(getconnections(v.Activated))         do pcall(function() c:Fire() end) end
                                else
                                    v:GetPropertyChangedSignal("Visible"):Wait()
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- =====================================================================
    -- HELPERS
    -- =====================================================================
    local function getRoot()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then return char.HumanoidRootPart end
        return nil
    end

    local function GetInventory()
        local invStat = ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
        if not invStat then return nil end
        local invVal = invStat:FindFirstChild("Inventory")
        if invVal and invVal:FindFirstChild("Inventory") then
            local ok, res = pcall(function() return HttpService:JSONDecode(invVal.Inventory.Value) end)
            return ok and res or nil
        end
        return nil
    end

    -- Forward declarations cho remotes dùng trong helper functions
    -- (phải declare trước hàm dùng chúng để Lua closure capture đúng upvalue)
    local TitlesRemote
    local ToolsRemote

    local _bobbleFolderCache = nil
    local function GetMyBobble()
        local myName = LocalPlayer.Name
        if _bobbleFolderCache and _bobbleFolderCache.Parent then
            for _, obj in pairs(_bobbleFolderCache:GetChildren()) do
                if string.find(obj.Name, myName) and obj:GetAttribute("Caught") == true then
                    return obj
                end
            end
        end
        for _, area in pairs({workspace, LocalPlayer.Character}) do
            if area then
                for _, obj in pairs(area:GetDescendants()) do
                    if string.find(obj.Name, myName) and obj:GetAttribute("Caught") == true then
                        if obj.Parent ~= workspace and obj.Parent ~= LocalPlayer.Character then
                            _bobbleFolderCache = obj.Parent
                        end
                        return obj
                    end
                end
            end
        end
        return nil
    end

    -- =====================================================================
    -- [FIX-2] ROD EQUIP: Thêm retry và forceEquip flag
    -- Vấn đề cũ: sau UnequipTools(), rod về backpack nhưng _cachedRodName
    -- vẫn giữ nguyên → AutoEquipRodSilent skip server equip → rod không
    -- được EquipTool lên character → EquipPhysicalRod thất bại.
    -- Giải pháp: _cachedRodName chỉ dùng để tránh gọi server equip thừa,
    -- còn EquipPhysicalRod luôn kiểm tra physical state và equip nếu cần.
    -- =====================================================================
    local function EquipPhysicalRod(rodName)
        local char = LocalPlayer.Character
        if not char then return false end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return false end

        -- Rod đang cầm trong tay → ok
        if char:FindFirstChild(rodName) then return true end

        -- Rod trong backpack → physically equip ngay
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack and backpack:FindFirstChild(rodName) then
            pcall(function() hum:EquipTool(backpack[rodName]) end)
            task.wait(0.4)
            if char:FindFirstChild(rodName) then return true end
        end

        -- [FIX-2] Retry: chờ tối đa 2s để tool xuất hiện trong backpack
        -- (server có thể delay sync khi vừa gọi server equip remote)
        for _ = 1, 4 do
            task.wait(0.5)
            backpack = LocalPlayer:FindFirstChild("Backpack")
            if char:FindFirstChild(rodName) then return true end
            if backpack and backpack:FindFirstChild(rodName) then
                pcall(function() hum:EquipTool(backpack[rodName]) end)
                task.wait(0.4)
                if char:FindFirstChild(rodName) then return true end
            end
        end

        -- Fallback: rod tồn tại trong JSON inventory (server sẽ handle)
        local inv = GetInventory()
        if inv and (inv[rodName] or 0) > 0 then return true end
        return false
    end

    local _rodBuyPos = Vector3.new(-1343.85, 4.12, -4979.27)
    local _justBoughtRod = false

    local function BuyFishingRodIfNeeded(inventory)
        if not inventory then return end
        for _, rodName in ipairs(RodsPriority) do
            if (inventory[rodName] or 0) > 0 then _justBoughtRod = false; return end
        end
        _justBoughtRod  = true
        _cachedRodName  = nil
        TweenToPosAndWait(_rodBuyPos)
        if not ZiliState.AutoFishing then return end
        pcall(function()
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):InvokeServer(
                workspace:WaitForChild("BuyableItems"):WaitForChild("Fishing Rod"), 1
            )
        end)
        task.wait(3)
    end

    local _cachedRodName = nil
    local function AutoEquipRodSilent()
        local inventory = GetInventory()
        if not inventory then return _cachedRodName end
        for _, rodName in ipairs(RodsPriority) do
            if inventory[rodName] and inventory[rodName] > 0 then
                if rodName ~= _cachedRodName then
                    if ToolsRemote then
                        pcall(function() ToolsRemote:InvokeServer("equip", rodName) end)
                    end
                    _cachedRodName = rodName
                    -- [FIX-2] Tăng wait lên 1s để server sync backpack xong
                    -- trước khi EquipPhysicalRod kiểm tra
                    task.wait(1.0)
                end
                return rodName
            end
        end
        -- [FIX-2] Reset cache khi không còn rod → lần sau phải server-equip lại
        _cachedRodName = nil
        return nil
    end

    local _titleEquipping = false
    local function AutoEquipTitleSilent()
        if _titleEquipping then return end
        _titleEquipping = true
        task.spawn(function()
            for _, titleName in ipairs(TitlesPriority) do
                if TitlesRemote then
                    pcall(function() TitlesRemote:InvokeServer(titleName) end)
                end
                task.wait(0.1)
            end
            _titleEquipping = false
        end)
    end

    local BAIT_FALLBACK = {
        ["Legendary Fish Bait"] = {"Legendary Fish Bait", "Rare Fish Bait", "Common Fish Bait"},
        ["Rare Fish Bait"]      = {"Rare Fish Bait", "Common Fish Bait"},
        ["Common Fish Bait"]    = {"Common Fish Bait"},
    }
    local function ResolveBait(inv)
        local preferred = ZiliState.PreferredBait
        if not preferred then return nil end
        local chain = BAIT_FALLBACK[preferred]
        if not chain then return preferred end
        for _, bait in ipairs(chain) do
            if (inv[bait] or 0) > 0 then return bait end
        end
        return nil
    end

    -- =====================================================================
    -- TWEEN SYSTEM
    -- =====================================================================
    local isFlicking = false
    local Tween = { IsTeleporting = false, MoveConn = nil, NoclipConn = nil, FakeFloor = nil, _gen = 0, _merchantRetry = 0 }

    -- =====================================================================
    -- REMOTES
    -- =====================================================================
    local FishingRemote = ReplicatedStorage:WaitForChild("Fishing", 9e9)
    if FishingRemote then
        FishingRemote = FishingRemote:WaitForChild("Remotes", 9e9):WaitForChild("Action", 9e9)
    end

    local Events         = ReplicatedStorage:WaitForChild("Events", 9e9)
    local TakeStam       = Events:WaitForChild("takestam", 9e9)
    -- Assign vào forward-declared locals (đã khai báo trên để closures thấy đúng)
    ToolsRemote  = Events:WaitForChild("Tools", 9e9)
    TitlesRemote = Events:WaitForChild("Titles", 9e9)
    local FishingShopRemoteR = ReplicatedStorage:WaitForChild("FishingShopRemote", 9e9)
    local CraftingRemoteR    = ReplicatedStorage:WaitForChild("CraftingRemote", 9e9)

    local isSpoofingStamina = false
    local function StartStaminaSpoof()
        if isSpoofingStamina then return end
        isSpoofingStamina = true
        task.spawn(function()
            while isSpoofingStamina and task.wait(0.05) do
                if TakeStam and TakeStam.Parent then
                    pcall(function()
                        local root = getRoot()
                        local currentCF = root and root.CFrame or CFrame.new()
                        TakeStam:FireServer(0.505, "dash", currentCF)
                    end)
                else break end
            end
        end)
    end
    local function StopStaminaSpoof() isSpoofingStamina = false end

    -- =====================================================================
    -- TWEEN SYSTEM (FULL)
    -- =====================================================================
    local function StartSimpleFlickTimer()
        task.spawn(function()
            local timer = 0
            while Tween.IsTeleporting do
                task.wait(1)
                if not isFlicking then
                    local root = getRoot()
                    if root and root.Position.Y < -20 and root.Position.Y > -500 then
                        timer = timer + 1
                        if timer >= 20 then
                            isFlicking = true
                            local safeX = root.Position.X
                            local safeZ = root.Position.Z
                            root.CFrame = CFrame.new(safeX, 7.33, safeZ)
                            pcall(function() root.Velocity = VEC_ZERO end)
                            task.wait(0.5)
                            if Tween.IsTeleporting then
                                root.CFrame = CFrame.new(safeX, SWIM_Y, safeZ)
                                pcall(function() root.Velocity = VEC_ZERO end)
                            end
                            timer = 0
                            isFlicking = false
                        end
                    else
                        timer = 0
                    end
                end
            end
        end)
    end

    function Tween.Stop()
        Tween.IsTeleporting = false
        Tween._gen = Tween._gen + 1
        Tween._merchantRetry = 0
        isFlicking = false
        StopStaminaSpoof()
        if Tween.MoveConn then Tween.MoveConn:Disconnect(); Tween.MoveConn = nil end
        if Tween.NoclipConn then Tween.NoclipConn:Disconnect(); Tween.NoclipConn = nil end
        local root = getRoot()
        if root then
            root.Anchored = false
            for _, v in pairs(root:GetChildren()) do
                if v.Name == "ZILI_AntiGravity" then v:Destroy() end
            end
            pcall(function() root.Velocity = VEC_ZERO; root.AssemblyLinearVelocity = VEC_ZERO end)
        end
        if Tween.FakeFloor then Tween.FakeFloor:Destroy(); Tween.FakeFloor = nil end
    end

    function Tween.Start(finalDest, onComplete, opts)
        opts = opts or {}
        Tween.Stop()
        Tween.IsTeleporting = true
        local myGen = Tween._gen
        StartStaminaSpoof()
        StartSimpleFlickTimer()

        local _noclipParts = {}
        local _noclipChar  = nil
        local function _rebuildNoclip(char)
            _noclipChar = char
            _noclipParts = {}
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then _noclipParts[#_noclipParts + 1] = p end
            end
        end

        Tween.NoclipConn = RunService.Stepped:Connect(function()
            if not Tween.IsTeleporting then return end
            local char = LocalPlayer.Character
            if not char then return end
            if char ~= _noclipChar then _rebuildNoclip(char) end
            for _, p in ipairs(_noclipParts) do
                if p.Parent then p.CanCollide = false end
            end
        end)

        task.spawn(function()
            while Tween.IsTeleporting and myGen == Tween._gen do
                local char = LocalPlayer.Character
                if char then
                    if char ~= _noclipChar then _rebuildNoclip(char) end
                    for _, p in ipairs(_noclipParts) do
                        if p and p.Parent then p.CanCollide = false end
                    end
                    local r = getRoot()
                    if r and Tween.FakeFloor and Tween.FakeFloor.Parent then
                        Tween.FakeFloor.CFrame = r.CFrame * OFFSET_FAKEFLOOR
                    end
                end
                task.wait(0.05)
            end
        end)

        local route = {}
        local initialRoot = getRoot()
        if not initialRoot then Tween.Stop(); return end

        local function isPortalPos(pos) return pos.Y < -20 and pos.Y > -500 end

        if initialRoot.Position.Y > -1000 and finalDest.Y < -1000 then
            table.insert(route, {pos=Vector3.new(1842.72,-50,-12170.62), isPortal=true, isFishmanIn=true,  isFishmanExit=false, isMerchant=false})
        end
        if initialRoot.Position.Y < -1000 and finalDest.Y > -1000 then
            table.insert(route, {pos=Vector3.new(8585.12,-2138.84,-17087.38), isPortal=true, isFishmanIn=false, isFishmanExit=true, isMerchant=false})
        end
        table.insert(route, {
            pos        = finalDest,
            isPortal   = isPortalPos(finalDest),
            isFishmanIn = false, isFishmanExit = false,
            isMerchant = opts.isMerchant or false,
        })

        local function flyTo(stepData, onStepComplete)
            if Tween.MoveConn then Tween.MoveConn:Disconnect(); Tween.MoveConn = nil end

            local root = getRoot()
            local wt = 0
            while not root and wt < 10 do task.wait(0.5); wt = wt + 0.5; root = getRoot() end
            if not Tween.IsTeleporting or not root then Tween.Stop(); return end

            if not Tween.FakeFloor then
                Tween.FakeFloor = Instance.new("Part")
                Tween.FakeFloor.Name = "ZILI_FakeFloor"
                Tween.FakeFloor.Size = Vector3.new(15, 2, 15)
                Tween.FakeFloor.Anchored = true
                Tween.FakeFloor.Transparency = 1
                Tween.FakeFloor.Parent = workspace
            end

            local ag = root:FindFirstChild("ZILI_AntiGravity")
            if not ag or not ag:IsA("BodyVelocity") then
                if ag then ag:Destroy() end
                ag = Instance.new("BodyVelocity")
                ag.Name = "ZILI_AntiGravity"
                ag.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                ag.Velocity = VEC_ZERO
                ag.Parent = root
            end

            local targetPos = stepData.pos
            local flyY = (stepData.isFishmanIn or stepData.isFishmanExit) and targetPos.Y or SWIM_Y

            Tween.MoveConn = RunService.Heartbeat:Connect(function(rawDt)
                if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end
                if isFlicking then return end

                local dt = math.min(rawDt, DT_CAP)
                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end

                pcall(function() root.Velocity = VEC_ZERO; root.AssemblyLinearVelocity = VEC_ZERO end)

                local cur = root.Position
                local distXZ = (Vector2.new(targetPos.X, targetPos.Z) - Vector2.new(cur.X, cur.Z)).Magnitude

                if not stepData.isFishmanIn and not stepData.isFishmanExit then
                    if math.abs(cur.Y - SWIM_Y) > 10 and distXZ > 50 then
                        if TakeStam and TakeStam.Parent then
                            pcall(function() TakeStam:FireServer(0.505, "dash", root.CFrame) end)
                        end
                        root.CFrame = CFrame.new(cur.X, SWIM_Y, cur.Z)
                        if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                        return
                    end
                end

                local arrived = distXZ < 30
                if arrived then
                    Tween.MoveConn:Disconnect()
                    task.spawn(function()
                        local waited = 0
                        if stepData.isFishmanExit then
                            root.CFrame = CFrame.lookAt(root.Position, targetPos)
                            task.wait(0.1)
                            while waited < 20 do
                                if not Tween.IsTeleporting or not root then break end
                                if (root.Position - targetPos).Magnitude > 200 then break end
                                root.CFrame = root.CFrame * CFrame.new(0, 0, -3)
                                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                task.wait(0.15); waited = waited + 0.15
                            end
                            task.wait(4)
                        elseif stepData.isPortal or stepData.isFishmanIn then
                            local toggle = 1
                            while waited < 20 do
                                if not Tween.IsTeleporting or not root then break end
                                if (root.Position - targetPos).Magnitude > 200 then break end
                                root.CFrame = CFrame.new(targetPos.X + toggle, targetPos.Y, targetPos.Z + toggle)
                                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                toggle = toggle * -1; task.wait(0.3); waited = waited + 0.3
                            end
                            task.wait(4)
                        else
                            root.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                            if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                            task.wait(0.2)
                            if (root.Position - targetPos).Magnitude > 60 then
                                task.wait(0.2)
                                flyTo(stepData, onStepComplete)
                                return
                            end
                        end
                        if onStepComplete then onStepComplete() end
                    end)
                else
                    local maxS = math.min(MAX_SPEED * dt, 8)
                    local safeY = flyY
                    local tgt = Vector3.new(targetPos.X, safeY, targetPos.Z)
                    local diff = tgt - cur
                    local dist = diff.Magnitude
                    if dist > 0 then
                        root.CFrame = CFrame.new(cur + diff.Unit * math.min(maxS, dist))
                    end
                end
            end)
        end

        local function processRoute(idx)
            if not Tween.IsTeleporting then return end
            if idx > #route then Tween.Stop(); if onComplete then onComplete() end; return end
            flyTo(route[idx], function() processRoute(idx + 1) end)
        end
        processRoute(1)
    end

    function TweenToPosAndWait(targetPos, opts)
        local isDone = false
        Tween.Start(targetPos, function() isDone = true end, opts)
        while not isDone and ZiliState.AutoFishing do
            if not Tween.IsTeleporting and not isDone then break end
            task.wait(0.2)
        end
        if not ZiliState.AutoFishing then Tween.Stop() end
    end

    -- =====================================================================
    -- SELL / CRAFT
    -- =====================================================================
    local function AutoSellSilent(fishList)
        local inventory = GetInventory()
        if not inventory then return false end
        local shouldSell = false
        for _, name in ipairs(fishList) do if (inventory[name] or 0) > 0 then shouldSell = true; break end end
        if not shouldSell then return false end

        local function getCurrentPeli()
            local val = 0
            pcall(function()
                local n = ReplicatedStorage:FindFirstChild("Stats"..LocalPlayer.Name)
                n = n and n:FindFirstChild("Stats")
                n = n and n:FindFirstChild("Peli")
                if n then val = n.Value end
            end)
            return val
        end

        if getCurrentPeli() >= 1000000 then return false end

        TweenToPosAndWait(Cords.Sell)
        if not ZiliState.AutoFishing then return false end

        inventory = GetInventory()
        if not inventory then return false end

        for _, fishName in ipairs(fishList) do
            local count = inventory[fishName] or 0
            if count > 0 then
                for i = 1, count do
                    if not ZiliState.AutoFishing then break end
                    if getCurrentPeli() >= 1000000 then return true end
                    if FishingShopRemoteR then
                        pcall(function()
                            FishingShopRemoteR:InvokeServer(unpack({{
                                ["Fish"]=fishName, ["All"]=false, ["Method"]="SellFish"
                            }}))
                        end)
                    end
                    task.wait(0.3)
                    if getCurrentPeli() >= 1000000 then return true end
                end
            end
        end
        return true
    end

    -- =====================================================================
    -- [FIX-3] AUTO CRAFT — ExtraData key/value bị đảo ngược ở code cũ
    -- Code cũ:  ["ExtraData"] = {[fishName] = extraDataKey}
    --           → VD: {["Golden Polka Puffer"] = "Legendary Fish"}  ← SAI
    -- Code mới: ["ExtraData"] = {[extraDataKey] = fishName}
    --           → VD: {["Legendary Fish"] = "Golden Polka Puffer"}  ← ĐÚNG
    -- Tham chiếu từ decompiled remote spy:
    --   args[1].ExtraData = {["Legendary Fish"] = "Golden Polka Puffer"}
    -- =====================================================================
    local function AutoCraftSilent(blueprintType, extraDataKey, fishList, minCount, countPerCraft, mode)
        minCount      = minCount      or 1
        countPerCraft = countPerCraft or 1
        mode          = mode          or "single"
        local inventory = GetInventory()
        if not inventory then return false end

        local _debugFlagKey = "_CraftDebugDone_" .. blueprintType:gsub("%s","_")
        if _G[_debugFlagKey] ~= true then
            _G[_debugFlagKey] = true
            local found = {}
            for k, v in pairs(inventory) do
                if type(v) == "number" and v >= 1 then
                    found[#found+1] = k.."="..tostring(v)
                end
            end
            print("[ZILI DEBUG] ["..blueprintType.."] Inventory keys:", table.concat(found, ", "))
        end

        local craftedAny = false
        for _, fishName in ipairs(fishList) do
            local count = inventory[fishName] or 0
            if count >= minCount then
                if not craftedAny then
                    TweenToPosAndWait(Cords.Craft)
                    craftedAny = true
                    if not ZiliState.AutoFishing then return false end
                end

                local batches = math.floor(count / countPerCraft)
                if batches < 1 then continue end

                if mode == "all" then
                    if CraftingRemoteR then
                        pcall(function()
                            CraftingRemoteR:InvokeServer(unpack({{
                                ["BlueprintItem"] = blueprintType,
                                ["Method"]        = "Craft",
                                -- [FIX-3] ĐÃ SỬA: {[extraDataKey] = fishName}
                                ["ExtraData"]     = {[extraDataKey] = fishName},
                                ["Count"]         = batches,
                            }}))
                        end)
                        task.wait(0.5)
                    end
                else
                    for _ = 1, batches do
                        if not ZiliState.AutoFishing then return false end
                        if CraftingRemoteR then
                            pcall(function()
                                CraftingRemoteR:InvokeServer(unpack({{
                                    ["BlueprintItem"] = blueprintType,
                                    ["Method"]        = "Craft",
                                    -- [FIX-3] ĐÃ SỬA: {[extraDataKey] = fishName}
                                    ["ExtraData"]     = {[extraDataKey] = fishName},
                                    ["Count"]         = 1,
                                }}))
                            end)
                        end
                        task.wait(0.5)
                    end
                end
            end
        end
        return craftedAny
    end

    -- =====================================================================
    -- MERCHANT
    -- =====================================================================
    local function AutoClickMerchantUI()
        local chatGui = LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT")
        if not chatGui then return end
        local frame = chatGui:FindFirstChild("Frame") or chatGui:FindFirstChildWhichIsA("Frame", true)
        if not frame then return end
        pcall(function()
            for _, v in pairs(frame:GetDescendants()) do
                if v:IsA("TextButton") and v.Visible then
                    local txt = string.lower(v.Text or "")
                    local isAction = txt == "..." or txt == "go" or txt:match("yes") or txt:match("accept")
                        or txt:match("next") or txt:match("take") or txt:match("continue")
                        or txt:match("okay") or txt:match("set") or txt == "end"
                        or v.Name:lower():match("go") or v.Name:lower():match("continue")
                        or v.Name:lower():match("accept") or v.Name == "..."
                    if isAction and getconnections then
                        for _, c in pairs(getconnections(v.MouseButton1Click)) do pcall(function() c:Fire() end) end
                        for _, c in pairs(getconnections(v.Activated))         do pcall(function() c:Fire() end) end
                    end
                end
            end
        end)
    end

    local _MerchantDetectConn1 = nil
    local _MerchantDetectConn2 = nil
    local _MerchantAttrConn    = nil

    local function SetupMerchantDetection()
        if _MerchantDetectConn1 then _MerchantDetectConn1:Disconnect(); _MerchantDetectConn1 = nil end
        if _MerchantDetectConn2 then _MerchantDetectConn2:Disconnect(); _MerchantDetectConn2 = nil end
        if _MerchantAttrConn    then _MerchantAttrConn:Disconnect();    _MerchantAttrConn    = nil end

        local compassGuider = ReplicatedStorage:FindFirstChild("CompassGuider")
        if not compassGuider then
            task.delay(5, SetupMerchantDetection)
            return
        end

        local function hookMerchantValue(merchantObj)
            if not merchantObj or merchantObj.Name ~= "Traveling Merchant" then return end
            if _MerchantAttrConn then _MerchantAttrConn:Disconnect() end

            _MerchantAttrConn = merchantObj:GetPropertyChangedSignal("Value"):Connect(function()
                local v = merchantObj.Value
                if typeof(v) ~= "Vector3" then return end

                if v.Magnitude > 10 then
                    if not ZiliState.KnownMerchantPos or (ZiliState.KnownMerchantPos - v).Magnitude > 5 then
                        ZiliState.KnownMerchantPos  = v
                        ZiliState.MerchantSpawnTime = os.time()
                        ZiliState.MerchantProcessed = false
                        _lastShopPeriod      = -1
                        -- [FIX-1] Đánh dấu ngay để RunLoop ngắt câu ở vòng lặp tiếp
                        ZiliState.MerchantPending   = true
                    end
                else
                    ZiliState.KnownMerchantPos  = nil
                    ZiliState.MerchantProcessed = false
                    ZiliState.MerchantSpawnTime = 0
                    _lastShopPeriod      = -1
                    ZiliState.MerchantPending   = false
                end
            end)
        end

        _MerchantDetectConn1 = compassGuider.ChildAdded:Connect(function(child)
            if child.Name ~= "Traveling Merchant" then return end
            task.wait(0.2)
            hookMerchantValue(child)
            local v = child.Value
            if typeof(v) == "Vector3" and v.Magnitude > 10 then
                ZiliState.KnownMerchantPos  = v
                ZiliState.MerchantSpawnTime = os.time()
                ZiliState.MerchantProcessed = false
                _lastShopPeriod      = -1
                -- [FIX-1] Set pending ngay khi phát hiện spawn
                ZiliState.MerchantPending   = true
            end
        end)

        _MerchantDetectConn2 = compassGuider.ChildRemoved:Connect(function(child)
            if child.Name ~= "Traveling Merchant" then return end
            ZiliState.KnownMerchantPos  = nil
            ZiliState.MerchantProcessed = false
            ZiliState.MerchantSpawnTime = 0
            _lastShopPeriod      = -1
            ZiliState.MerchantPending   = false
            if _MerchantAttrConn then _MerchantAttrConn:Disconnect(); _MerchantAttrConn = nil end
        end)

        local existing = compassGuider:FindFirstChild("Traveling Merchant")
        if existing then
            hookMerchantValue(existing)
            local v = existing.Value
            if typeof(v) == "Vector3" and v.Magnitude > 10 then
                local npcActive = false
                for _, folder in pairs({workspace, workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Merchants")}) do
                    if folder then
                        for _, npc in ipairs(folder:GetChildren()) do
                            if npc.Name == "Traveling Merchant" or npc.Name == "Merchant" then
                                npcActive = true; break
                            end
                        end
                    end
                    if npcActive then break end
                end
                if npcActive then
                    ZiliState.KnownMerchantPos  = v
                    ZiliState.MerchantSpawnTime = os.time()
                    ZiliState.MerchantProcessed = false
                    _lastShopPeriod      = -1
                    ZiliState.MerchantPending   = true
                end
            end
        end
    end

    task.spawn(SetupMerchantDetection)

    -- =====================================================================
    -- [FIX-6] WEBHOOK — chỉ đếm item thực sự mua thành công
    -- Vấn đề cũ: pcall chỉ bắt Lua error, không bắt server trả về false/nil
    --            → ghi mua ngay cả khi không đủ peli hoặc hết stock
    -- Giải pháp: capture return value; chỉ count khi result truthy
    -- =====================================================================
    -- [FIX BUG 3] Lưu shadow ban riêng theo từng acc (không dùng file chung)
    local _sbPlayerName = game:GetService("Players").LocalPlayer.Name
    local _sbSafeName   = _sbPlayerName:gsub("[^%w_%-]", "_")
    local SHADOWBAN_FILE = "Zili_Hub/data/shadowban_" .. _sbSafeName .. ".json"

    local function SendMerchantWebhook(shopData, boughtData)
        local url = ZiliState.WebhookUrl or ""
        if url == "" then return end

        local function Fmt(n)
            n = tostring(n)
            while true do local k; n,k=string.gsub(n,"^(-?%d+)(%d%d%d)","%1,%2"); if k==0 then break end end
            return n
        end

        local currentPeli = "0"
        pcall(function()
            local s = ReplicatedStorage:FindFirstChild("Stats"..LocalPlayer.Name)
            if s and s.Stats and s.Stats.Peli then currentPeli = Fmt(s.Stats.Peli.Value) end
        end)

        local Rarity = {
            ["All Seeing Shamrock"]="Mythic",["Mythical Fruit Chest"]="Mythic",
            ["Legendary Fruit Chest"]="Legendary",["Tropical Parrot"]="Legendary",["Coffin Boat"]="Legendary",["Striker"]="Legendary",["Hoverboard"]="Legendary",["Legendary Fish Bait"]="Legendary",["Merchants Banana Rod"]="Legendary",["Knight's Gauntlet"]="Legendary",["Crab Cutlass"]="Legendary",["Bisento"]="Legendary",["Kessui"]="Legendary",["Raiui"]="Legendary",
            ["Hunter's Journal"]="Epic",["Jitte"]="Epic",["Crimson Nightcoat"]="Epic",["Sea-Breeze Haori"]="Epic",["Spirit Color Essence"]="Epic",["Raylo's Outfit"]="Epic",["Blossom Skirt"]="Epic",["Desert Merchant Outfit"]="Epic",["Sea-Breeze Skirt"]="Epic",["Tari's Karoo Coat"]="Epic",
            ["Platinum Coat"]="Epic",["Red Cloud Costume"]="Epic",["Demon Corps Costume"]="Epic",["Itadori Costume"]="Epic",["Hero's Costume"]="Epic",["Hero's Cape"]="Epic",["Ninja Costume"]="Epic",["Sabo's Outfit"]="Epic",["Black Bull Costume"]="Epic",["Thunder Haori"]="Epic",["Ten Tails Jinchuriki Costume"]="Epic",
            ["Happy Elf Outfit"]="Epic",["Candy Cane Outfit"]="Epic",["Nut Cracker's Tall Hat"]="Epic",["Santa's Reindeer Hat"]="Epic",["Santa's Outfit Dripped"]="Epic",["Nutcracker's Outfit"]="Epic",["Green Monster Outfit"]="Epic",["Green Monster Hat"]="Epic",
            ["Soul Trainer Outfit"]="Epic",["Soul Trainer Robes"]="Epic",["Soul Captain Outfit"]="Epic",["Kenpachi Outfit"]="Epic",["Grimmjow Outfit"]="Epic",["Ulquiorra Outfit"]="Epic",["Kisuke Outfit"]="Epic",["Ichigo Robes"]="Epic",["Ichigo War Outfit"]="Epic",["Coyote Outfit"]="Epic",
            ["Snow Detective Outfit"]="Epic",["Snow Detective Cap"]="Epic",["Festive Snow Dress"]="Epic",["Festive Snow Antlers"]="Epic",["Xmas Outfit"]="Epic",["Merry Dress"]="Epic",["Chill Hoodie"]="Epic",
            ["Blood Sorcerer Costume"]="Epic",["Panda Costume"]="Epic",["Frozen Star's Kimono"]="Epic",["Progidy Sorcerer Costume"]="Epic",["Krakatoa Curse Costume"]="Epic",["King of Curses Costume"]="Epic",["Honored Sorcerer Costume"]="Epic",["Sorcerer Hunter Costume"]="Epic",
            ["Frost Scout Outfit"]="Epic",["Frostpire Noble Outfit"]="Epic",["Frostpire Marshal Outfit"]="Epic",["Reindeer Costume"]="Epic",["Frostpire Dress"]="Epic",["Gingerbread Costume"]="Epic",
            ["Eggsplorer Jacket"]="Epic",["Starry Bunny Pajamas"]="Epic",["Starry Bunny Hood"]="Epic",["Cool Guy Egghead"]="Epic",["Eggsventurer's Hat"]="Epic",["Eggsventurer's Attire"]="Epic",["Bunny Costume"]="Epic",["Usamii Head"]="Epic",["Kumakawa Head"]="Epic",
            ["Martial Guardian's Costume"]="Epic",["Crimson Star Cap"]="Epic",["Ape Prince's Costume"]="Epic",["Power Scouter"]="Epic",["Martial Guardian's Cape"]="Epic",["Guardian's Turban"]="Epic",["Ape Warrior's Costume"]="Epic",["Snoozy Neko"]="Epic",["Future Swordsman's Costume"]="Epic",["Bulma's Costume"]="Epic",["Twin-Soul Ape's Outfit"]="Epic",["Angel of Time Costume"]="Epic",["God of Destruction's Costume"]="Epic",["Potata Earrings"]="Epic",["Fallen Ape Warrior's Costume"]="Epic",
            ["Thrilled Ship"]="Rare",["Spare Fruit Bag"]="Rare",["Rare Fruit Chest"]="Rare",["Bomi's Log Pose"]="Rare",["Gravity Blade"]="Rare",["Race Reroll"]="Rare",["Dark Root"]="Rare",["Rare Fish Bait"]="Rare",["Golden Staff"]="Rare",["Golden Hook"]="Rare",
            ["Karoo Mount"]="Uncommon",["Special Tailor Token"]="Uncommon",["SP Reset Essence"]="Common",
        }
        local UI = {
            Mythic    = {Title="🍆 Mythic",    Icon="🔮"},
            Legendary = {Title="🔥 Legendary", Icon="🔸"},
            Epic      = {Title="🟣 Epic",       Icon="🔹"},
            Rare      = {Title="🔵 Rare",       Icon="🔹"},
            Uncommon  = {Title="🟢 Uncommon",   Icon="▫️"},
            Common    = {Title="⚪ Common",      Icon="▫️"},
        }

        local grouped = {Mythic={},Legendary={},Epic={},Rare={},Uncommon={},Common={}}
        local total, totalVal = 0, 0
        for name, data in pairs(shopData) do
            total = total + 1
            local p = type(data.Price)=="string" and tonumber((data.Price:gsub(",",""))) or tonumber(data.Price) or 0
            local stock = tonumber((tostring(data.Stock):gsub(",",""))) or 0
            -- Total = gia * so luong tung item trong shop
            totalVal = totalVal + (p * math.max(1, stock))
            table.insert(grouped[Rarity[name] or "Epic"], {Name=name,Stock=data.Stock,Price=Fmt(p)})
        end

        -- [FIX-6] Không hiển thị section "PURCHASED ITEMS" nếu không mua được gì
        local hasBought = false
        for _, v in pairs(boughtData) do
            if v > 0 then hasBought = true; break end
        end

        local hidden = "||"..LocalPlayer.Name.."||"
        local T3     = string.rep(string.char(96),3)

        -- ── SHADOW BAN TRACKER (persist qua rejoin vao file) ──────────
        local _RESET_ITEMS = {
            ["Legendary Fish Bait"]   = true,
            ["Rare Fruit Chest"]      = true,
            ["Legendary Fruit Chest"] = true,
            ["Mythical Fruit Chest"]  = true,
        }
        -- Load count tu file
        local vc = 0
        pcall(function()
            if isfile and isfile(SHADOWBAN_FILE) then
                local ok, data = pcall(function() return HttpService:JSONDecode(readfile(SHADOWBAN_FILE)) end)
                if ok and type(data)=="table" and type(data.count)=="number" then
                    vc = data.count
                end
            end
        end)
        local hadResetItem = false
        for name, amt in pairs(boughtData) do
            if amt > 0 and _RESET_ITEMS[name] then hadResetItem=true; break end
        end
        if hadResetItem then vc = 0 else vc = vc + 1 end
        -- Save back to file
        pcall(function()
            if writefile then
                if makefolder then
                    pcall(function() makefolder("Zili_Hub") end)
                    pcall(function() makefolder("Zili_Hub/data") end)
                end
                writefile(SHADOWBAN_FILE, HttpService:JSONEncode({count=vc, updated=os.date("%d/%m/%Y %H:%M")}))
            end
        end)
        local function MakeBanBar(n)
            local filled = math.min(n, 10)
            return string.rep("▰", filled) .. string.rep("▱", math.max(0, 10 - filled)) .. " " .. n .. "/10"
        end
        local banIcon, banLabel
        if vc <= 0 then     banIcon = "🟢"; banLabel = "No Shadow Ban   "
        elseif vc < 3 then  banIcon = "🟡"; banLabel = "Low Risk            "
        elseif vc < 5 then  banIcon = "🟠"; banLabel = "Medium Risk      "
        elseif vc < 7 then  banIcon = "🔴"; banLabel = "High Risk           "
        else                banIcon = "⚫"; banLabel = "Shadow Banned  " end
        local banLine = banIcon .. " " .. banLabel .. " " .. MakeBanBar(vc)

        -- ── FIX TOTAL PELI: tính peli thực tế đã mua ─────────────────
        local totalSpent = 0
        for name, amt in pairs(boughtData) do
            if amt > 0 and shopData[name] then
                local p2 = type(shopData[name].Price)=="string" and tonumber((shopData[name].Price:gsub(",",""))) or tonumber(shopData[name].Price) or 0
                totalSpent = totalSpent + (p2 * amt)
            end
        end

        local fields, order = {}, {"Mythic","Legendary","Epic","Rare","Uncommon","Common"}

        -- ── ITEMS IN MERCHANT header ───────────────────────────────────
        table.insert(fields,{["name"]="📦 **Items In Merchant:**",["value"]="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",["inline"]=false})

        for _,r in ipairs(order) do
            if #grouped[r] > 0 then
                table.insert(fields,{["name"]=UI[r].Title.." ("..#grouped[r]..")",["value"]="** **",["inline"]=false})
                for _,item in ipairs(grouped[r]) do
                    table.insert(fields,{["name"]=UI[r].Icon.." "..item.Name,["value"]=string.format("%s\nStock: %s\nPrice: %s Peli\n%s",T3,tostring(item.Stock),item.Price,T3),["inline"]=true})
                end
            end
        end

        -- ── SHOP LOG (thay thế PURCHASED ITEMS) ───────────────────────
        local hasMythic = false
        local shopLogLines = ""
        if hasBought then
            for name, amt in pairs(boughtData) do
                if amt > 0 then
                    if (Rarity[name] or "Epic")=="Mythic" then hasMythic=true end
                    local p2 = type(shopData[name] and shopData[name].Price)=="string"
                        and tonumber((shopData[name].Price:gsub(",",""))) or tonumber(shopData[name] and shopData[name].Price) or 0
                    local itemTotal = Fmt(p2 * amt)
                    shopLogLines = shopLogLines .. string.format("+ %s x%d | Total: %s Peli\n", name, amt, itemTotal)
                end
            end
        else
            shopLogLines = "- None"
        end
        table.insert(fields,{["name"]="🗒️ **SHOP LOG**",["value"]=string.format("%sdiff\n%s%s",T3,shopLogLines,T3),["inline"]=false})

        local color = hasMythic and 10494192 or hasBought and 65280 or 16711680
        local embeds, cur, idx = {}, {}, 1
        local function flush()
            local e={["color"]=color}
            if idx==1 then
                e["author"]      = {["name"]="🛒 TRAVELING MERCHANT",["icon_url"]="https://i.postimg.cc/NMRNsmrN/dfa59e7e-ce99-4091-9d64-a070f4a33687.png"}
                e["description"] = "**Player info:**\n🤰 User: "..hidden.."\n💰 Peli: "..currentPeli.."\n"..banLine.."\n\n**📊 Summary:** "..total.." items | Total peli: **"..Fmt(totalVal).." Peli**"
            end
            if #cur>0 then e["fields"]=cur end
            table.insert(embeds,e); cur={}; idx=idx+1
        end
        for _,f in ipairs(fields) do table.insert(cur,f); if #cur==25 then flush() end end
        if #cur>0 or idx==1 then flush() end
        embeds[#embeds]["footer"] = {["text"]="ZILI HUB | "..os.date("%d/%m/%Y %H:%M:%S")}

        local payload = {["embeds"]=embeds}
        payload["username"]   = "ZiLi | 🛒 Merchant Log"
        payload["avatar_url"] = "https://i.postimg.cc/NMRNsmrN/dfa59e7e-ce99-4091-9d64-a070f4a33687.png"
        if hasMythic then payload["content"]="@everyone\n🟣 **SUCCESSFULLY PURCHASED A MYTHIC ITEM!**"; payload["allowed_mentions"]={["parse"]={"everyone"}} end

        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then pcall(function() req({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)}) end) end
    end

    -- =====================================================================
    -- MYTHIC CHEST WEBHOOK
    -- =====================================================================
    local _MYTHIC_WH_URL  = "https://discord.com/api/webhooks/1493543401608581190/AD87Cn0Xe6JXB4YluK5Sl5PEndBDD7pWEb4EZgKLWWG51dHDZBBZtEJnS_w1erwRxd-I"
    local _MYTHIC_WH_IMG  = "https://i.postimg.cc/jSwhzcDq/images-(1).jpg"
    local _MYTHIC_SET     = {["All Seeing Shamrock"]=true, ["Mythical Fruit Chest"]=true}

    local function SendMythicChestWebhook(boughtData)
        local mythicItems = {}
        for name, amt in pairs(boughtData) do
            -- [FIX-6] Chỉ gửi nếu amt > 0 (mua thực sự thành công)
            if _MYTHIC_SET[name] and amt > 0 then
                mythicItems[#mythicItems + 1] = {name = name, amt = amt}
            end
        end
        if #mythicItems == 0 then return end

        local req = (syn and syn.request) or (http and http.request) or http_request
                 or (fluxus and fluxus.request) or request
        if not req then return end

        local descParts = {}
        for _, item in ipairs(mythicItems) do
            descParts[#descParts + 1] = string.format(
                "✅  A player successfully purchased **%s** ×%d", item.name, item.amt
            )
        end

        local fields = {}
        for _, item in ipairs(mythicItems) do
            fields[#fields + 1] = {
                ["name"]   = "🔮  " .. item.name,
                ["value"]  = "Quantity: **" .. tostring(item.amt) .. "**",
                ["inline"] = true,
            }
        end

        local embed = {
            ["color"]       = 10494192,
            ["title"]       = "🍆  MYTHIC CHEST ALERT",
            ["description"] = table.concat(descParts, "\n"),
            ["thumbnail"]   = {["url"] = _MYTHIC_WH_IMG},
            ["fields"]      = fields,
            ["footer"]      = {["text"] = "ZILI HUB | " .. os.date("%d/%m/%Y %H:%M:%S")},
        }

        local payload = {["embeds"] = {embed}}
        local body = HttpService:JSONEncode(payload)
        -- Chỉ gửi tới hardcoded URL (không gửi kèm webhook fishing của user)
        pcall(function()
            req({Url=_MYTHIC_WH_URL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body})
        end)
    end

    local function FindNearbyMerchant(rPart, maxRadius)
        maxRadius = maxRadius or 80
        for _, folder in pairs({workspace, workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Merchants")}) do
            if folder then
                for _, npc in ipairs(folder:GetChildren()) do
                    if npc.Name == "Traveling Merchant" or npc.Name == "Merchant" then
                        local mr = npc:FindFirstChild("HumanoidRootPart")
                        if mr and (mr.Position - rPart.Position).Magnitude <= maxRadius then
                            return npc, mr.Position
                        end
                    end
                end
            end
        end
        return nil, nil
    end

    -- =====================================================================
    -- [FIX-6] BuyItemsFromMerchant — capture return value để track đúng
    -- =====================================================================
    local function BuyItemsFromMerchant(npc)
        local merchantR = ReplicatedStorage:WaitForChild("Events"):WaitForChild("TravelingMerchentRemote")
        local root      = getRoot()

        -- Mở shop trực tiếp qua remote, không cần ProximityPrompt / npcChat
        pcall(function() merchantR:InvokeServer("OpenShop") end)

        local shopGui = nil
        local deadline = tick() + 10
        while tick() < deadline and ZiliState.AutoFishing do
            task.wait(0.4)
            shopGui = LocalPlayer.PlayerGui:FindFirstChild("MerchentShop")
            if shopGui then break end
        end

        if not shopGui then
            if root then root.Anchored = false end
            return
        end
        task.wait(0.3)

        local seed = shopGui:GetAttribute("Seed")
        if not seed then
            if root then root.Anchored = false end
            return
        end

        local shopData, container = {}, nil
        local listGUI = shopGui:FindFirstChild("List", true)
        container = listGUI and listGUI:FindFirstChild("Redeemables") or listGUI
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("GuiObject") and obj.Name~="Template" and obj.Name~="UIListLayout" and obj.Name~="UIPadding" then
                    local al = obj:FindFirstChild("Amount",true); local pl = obj:FindFirstChild("Price",true)
                    if al and pl then
                        local s = tonumber(al.Text:match("%d+")) or 0
                        if not shopData[obj.Name] then shopData[obj.Name]={Stock=s,Price=pl.Text} end
                    end
                end
            end
        end

        local boughtData = {}
        for _, itemName in ipairs(ItemsToBuy) do
            local info = shopData[itemName]
            if info and info.Stock > 0 then
                for _ = 1, info.Stock do
                    -- [FIX-6] Capture cả ok lẫn result để biết server có thực sự xử lý không
                    -- result = false/nil → hết peli, đã có item, hoặc stock hết đồng thời
                    -- result = true/table → mua thành công
                    local ok, result = pcall(function() return merchantR:InvokeServer(itemName, seed) end)
                    if ok and result ~= false and result ~= nil then
                        boughtData[itemName] = (boughtData[itemName] or 0) + 1
                    end
                    task.wait(1)
                    pcall(function()
                        if LocalPlayer.PlayerGui:FindFirstChild("PromptQuestion") then
                            LocalPlayer.PlayerGui.PromptQuestion:Destroy()
                        end
                    end)
                end
            end
        end

        task.wait(1)
        pcall(function() merchantR:InvokeServer("Close") end)
        task.spawn(function() SendMerchantWebhook(shopData, boughtData) end)
        task.spawn(function() SendMythicChestWebhook(boughtData) end)

        -- Track merchant visit + log
        ZiliState.MerchantCounter = (ZiliState.MerchantCounter or 0) + 1
        pcall(function()
            local parts = {}
            for k, v in pairs(boughtData) do if v > 0 then parts[#parts+1] = k.." ×"..v end end
            local summary = #parts > 0 and table.concat(parts, ", ") or "nothing bought"
            getgenv().ZiliLog("Merchant #"..ZiliState.MerchantCounter.." — "..summary, "merchant")
            if ZiliState._MerchantCounterLbl and ZiliState._MerchantCounterLbl.Parent then
                ZiliState._MerchantCounterLbl.Text = tostring(ZiliState.MerchantCounter)
            end
        end)

        if root then root.Anchored = false end
    end

    local BUY_PRIORITY = {
        "All Seeing Shamrock", "Mythical Fruit Chest", "Legendary Fruit Chest",
        "Legendary Fish Bait", "Rare Fruit Chest",
    }

    local function SyncConfigs(TogglesData)
        local baitVal = TogglesData["Config_SelectBait"] and TogglesData["Config_SelectBait"].Value
        ZiliState.PreferredBait = (type(baitVal)=="string" and baitVal~="") and baitVal or nil

        local sell = TogglesData["Config_SellFish"] and TogglesData["Config_SellFish"].Value or {}
        _Configs.SellCommon = sell["Common Fish"]    == true
        _Configs.SellRare   = sell["Rare Fish"]      == true
        _Configs.SellLeg    = sell["Legendary Fish"] == true

        local craft = TogglesData["Config_CraftBait"] and TogglesData["Config_CraftBait"].Value or {}
        _Configs.CraftLeg  = craft["Legendary Fish Bait"] == true
        _Configs.CraftRare = craft["Rare Fish Bait"]      == true

        local rareMode = TogglesData["Config_CraftRareMode"] and TogglesData["Config_CraftRareMode"].Value
        _Configs.CraftRareMode = (rareMode == "all") and "all" or "single"

        local buy = TogglesData["Config_BuyItems"] and TogglesData["Config_BuyItems"].Value or {}
        local buySet = {}
        for name, on in pairs(buy) do if on then buySet[name] = true end end
        ItemsToBuy = {}
        for _, name in ipairs(BUY_PRIORITY) do
            if buySet[name] then table.insert(ItemsToBuy, name); buySet[name] = nil end
        end
        for name in pairs(buySet) do table.insert(ItemsToBuy, name) end

        _Configs.AutoMerchant = #ItemsToBuy > 0
        _Configs.BuyBait = (ZiliState.PreferredBait == "Common Fish Bait")
        _Configs.CraftRod = (ZiliState.AutoCraftRod == true)
    end

    -- =====================================================================
    -- [FIX-5 v2] AUTO USE SPARE FRUIT BAG
    -- Decompiled xác nhận RemoteEvent parented vào TOOL (nil space), không
    -- cần equip tool lên tay — chỉ cần getnilinstances() → FireServer(true).
    -- Việc gọi Tools:InvokeServer("equip") trước đó là SAI vì nó unequip rod.
    -- =====================================================================
    local function TryEquipFruitBag()
        local bagInv = GetInventory() or {}
        if bagInv["Fruit Bag"] then return end
        if (bagInv["Spare Fruit Bag"] or 0) <= 0 then return end

        local char     = LocalPlayer.Character
        local hum      = char and char:FindFirstChild("Humanoid")
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not char or not hum or not backpack then return end

        -- Bước 1: đưa từ inventory ra backpack trước
        pcall(function()
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Tools"):InvokeServer("equip", "Spare Fruit Bag")
        end)
        task.wait(1.0) -- chờ server sync backpack

        -- Bước 2: cầm lên tay
        local bagTool = backpack:FindFirstChild("Spare Fruit Bag")
        if not bagTool then return end
        pcall(function() hum:EquipTool(bagTool) end)
        task.wait(0.5)

        -- Bước 3: activate tool để trigger GUI confirm
        local equippedBag = char:FindFirstChild("Spare Fruit Bag")
        if equippedBag then
            local fired = false
            if getconnections then
                for _, c in pairs(getconnections(equippedBag.Activated)) do
                    pcall(function() c:Fire() end)
                    fired = true
                end
            end
            if not fired then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(
                        workspace.CurrentCamera.ViewportSize.X / 2,
                        workspace.CurrentCamera.ViewportSize.Y / 2
                    ))
                end)
            end
        end
        task.wait(0.5)

        -- Bước 4: chờ GUI "Are you sure?" xuất hiện (tối đa 5s)
        local guiFound = nil
        local deadline = tick() + 5
        while tick() < deadline do
            task.wait(0.2)
            for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
                local main = gui:FindFirstChild("Main")
                if main and main:FindFirstChild("Accept") then
                    guiFound = main
                    break
                end
            end
            if guiFound then break end
        end

        if guiFound then
            -- Bước 5a: fire Accept button connections
            local acceptBtn = guiFound:FindFirstChild("Accept")
            local fired = false
            if acceptBtn and getconnections then
                for _, c in pairs(getconnections(acceptBtn.MouseButton1Click)) do
                    pcall(function() c:Fire() end)
                    fired = true
                end
            end

            -- Bước 5b: fallback fire RemoteEvent trực tiếp từ tool
            if not fired then
                equippedBag = char:FindFirstChild("Spare Fruit Bag")
                if equippedBag then
                    local re = equippedBag:FindFirstChildOfClass("RemoteEvent")
                    if re then pcall(function() re:FireServer(true) end) end
                end
            end
        end

        task.wait(0.5)
        pcall(function() hum:UnequipTools() end)
        task.wait(0.3)
        _cachedRodName = nil
    end

    -- =====================================================================
    -- MAIN LOOP
    -- Priority: 0=mua rod → [FIX-1]Merchant check ngay đầu → 1=merchant
    --           → 2=equip rod+title → 3=mua mồi → 4=bán+craft → 5=câu
    -- =====================================================================
    local function RunLoop(TogglesData)
        while ZiliState.AutoFishing do
            task.wait(1)
            while ZiliState.FruitPriorityActive do task.wait(0.3) end

            -- ════════════════════════════════════════════════════════════════
            -- [FIX-1] MERCHANT INTERRUPT CHECK — PHẢI ĐẶT ĐẦU TIÊN
            -- Khi ZiliState.MerchantPending = true (set bởi hookMerchantValue khi
            -- merchant spawn), loop này sẽ xử lý merchant NGAY lập tức mà
            -- không cần đợi hết các bước dưới.
            -- ════════════════════════════════════════════════════════════════
            if ZiliState.MerchantPending and _Configs.AutoMerchant then
                -- Reset flag trước để tránh re-trigger trong lúc xử lý
                ZiliState.MerchantPending = false
                if ZiliState.KnownMerchantPos and not ZiliState.MerchantProcessed then
                    local mPos = ZiliState.KnownMerchantPos
                    -- Ngắt bất kỳ tween đang chạy (câu, bán cá...) bay thẳng đến merchant
                    Tween.Stop()
                    TweenToPosAndWait(mPos, {isMerchant = true})
                    if ZiliState.AutoFishing then
                        local char  = LocalPlayer.Character
                        local rPart = char and char:FindFirstChild("HumanoidRootPart")
                        if rPart then
                            -- [FIX BUG 2] Đợi NPC "Traveling Merchant" thực sự load xong
                            -- trước khi interact. Quan trọng khi FPS thấp (15fps) vì tween
                            -- xong nhưng NPC model chưa replicate đến client.
                            local foundNpc = nil
                            local npcDeadline = tick() + 8 -- đợi tối đa 8s
                            repeat
                                foundNpc = FindNearbyMerchant(rPart, 80)
                                if not foundNpc then task.wait(0.5) end
                            until foundNpc or tick() > npcDeadline or not ZiliState.AutoFishing

                            -- Nếu vẫn chưa thấy, teleport sát hơn rồi thử lần cuối
                            if not foundNpc and ZiliState.AutoFishing then
                                local root = getRoot()
                                if root then
                                    root.CFrame = CFrame.new(mPos + Vector3.new(0, 2, 0))
                                    task.wait(0.8)
                                end
                                local t2 = tick() + 4
                                repeat
                                    foundNpc = FindNearbyMerchant(rPart, 120)
                                    if not foundNpc then task.wait(0.5) end
                                until foundNpc or tick() > t2 or not ZiliState.AutoFishing
                            end

                            -- Chờ thêm 1 frame để model & ProximityPrompt load đủ
                            if foundNpc then
                                task.wait(0.5)
                                BuyItemsFromMerchant(foundNpc)
                                ZiliState.MerchantProcessed = true
                                TweenToPosAndWait(mPos + Vector3.new(20, 0, 20))
                            else
                                ZiliState.MerchantProcessed = true
                            end
                        end
                    end
                end
                -- Reset _cachedRodName để vòng sau equip lại rod đúng cách
                _cachedRodName = nil
                continue  -- restart loop từ đầu
            end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY -1: AUTO SET SPAWN → SHELL'S TOWN
            -- ════════════════════════════════════════════════════════════════
            if ZiliState.AutoSetSpawnShellTown and not ZiliState._ShellSpawnDone then
                local spawnOk, spawnVal = pcall(function()
                    local sf = ReplicatedStorage:FindFirstChild("Stats"..LocalPlayer.Name)
                    return sf and sf:FindFirstChild("Stats") and sf.Stats:FindFirstChild("SpawnPoint") and sf.Stats.SpawnPoint.Value
                end)
                if spawnOk and spawnVal == "Shell's Town" then
                    ZiliState._ShellSpawnDone = true
                elseif spawnOk and spawnVal then
                    -- Gọi thẳng remote SetSpawn không qua ProximityPrompt (tránh bug chờ vô tận)
                    pcall(function()
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("SetSpawn"):FireServer("Shell's Town")
                    end)
                    task.wait(1)
                    -- Verify lại sau khi gọi
                    local verifyOk, newSpawn = pcall(function()
                        local sf = ReplicatedStorage:FindFirstChild("Stats"..LocalPlayer.Name)
                        return sf and sf:FindFirstChild("Stats") and sf.Stats:FindFirstChild("SpawnPoint") and sf.Stats.SpawnPoint.Value
                    end)
                    if verifyOk and newSpawn == "Shell's Town" then
                        ZiliState._ShellSpawnDone = true
                        pcall(getgenv().ZiliLog, "Spawn set → Shell's Town", "spawn")
                    else
                        -- Server lag → retry 1 lần sau 2s rồi mark done
                        task.wait(2)
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("SetSpawn"):FireServer("Shell's Town")
                        end)
                        task.wait(1)
                        ZiliState._ShellSpawnDone = true
                    end
                end
            end
            if not ZiliState.AutoFishing then break end
            SyncConfigs(TogglesData)

            -- [FIX BUG 3] FishingRemote nil = lag quá nặng hoặc chưa replicate
            -- Thử WaitForChild ngắn thay vì bỏ qua ngay
            if not FishingRemote then
                local ok = pcall(function()
                    local fr = ReplicatedStorage:WaitForChild("Fishing", 8)
                    if fr then
                        FishingRemote = fr:WaitForChild("Remotes", 5):WaitForChild("Action", 5)
                    end
                end)
                if not FishingRemote then task.wait(3); continue end
            end

            local char  = LocalPlayer.Character
            local hum   = char and char:FindFirstChild("Humanoid")
            local rPart = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not rPart or not hum or hum.Health <= 0 then
                -- ── [FIX BUG 3] Xử lý chết + lag FPS thấp ─────────────────
                -- Vấn đề cũ:
                --   1. Sau CharacterAdded chỉ wait(3.5) cứng → FPS15 HRP chưa load
                --      → loop continue lại → rPart vẫn nil → stuck vô tận
                --   2. Không WaitForChild để confirm parts thực sự có mặt
                -- Giải pháp: đợi char cũ remove hẳn → đợi char mới → WaitForChild
                --            HumanoidRootPart với timeout rõ ràng trước khi continue
                local oldChar = LocalPlayer.Character
                if oldChar then
                    local oldHum = oldChar:FindFirstChildOfClass("Humanoid")
                    if oldHum and oldHum.Health <= 0 then
                        -- Đợi char cũ bị xóa khỏi workspace (timeout 10s)
                        local removed = false
                        local removeConn = oldChar.AncestryChanged:Connect(function(_, parent)
                            if not parent then removed = true end
                        end)
                        local t0 = tick()
                        while not removed and tick() - t0 < 10 and ZiliState.AutoFishing do
                            task.wait(0.3)
                        end
                        removeConn:Disconnect()
                    end
                    -- Đợi char mới spawn nếu char cũ vẫn còn là current char
                    if LocalPlayer.Character == oldChar and ZiliState.AutoFishing then
                        LocalPlayer.CharacterAdded:Wait()
                    end
                elseif ZiliState.AutoFishing then
                    LocalPlayer.CharacterAdded:Wait()
                end

                if not ZiliState.AutoFishing then continue end

                -- Đợi HumanoidRootPart + Humanoid thực sự tồn tại
                -- (quan trọng ở FPS 15 vì replication chậm hơn nhiều)
                local newChar = LocalPlayer.Character
                if newChar then
                    local hrpOk, hrpErr = pcall(function()
                        newChar:WaitForChild("HumanoidRootPart", 12)
                        newChar:WaitForChild("Humanoid", 12)
                    end)
                    -- Chờ thêm buffer cho health init + server-side settle
                    task.wait(2.5)
                    -- Verify health > 0 (đôi khi WaitForChild trả về nhưng Health chưa sync)
                    local verifyDeadline = tick() + 6
                    while tick() < verifyDeadline and ZiliState.AutoFishing do
                        local vc  = LocalPlayer.Character
                        local vh  = vc and vc:FindFirstChild("Humanoid")
                        local vrp = vc and vc:FindFirstChild("HumanoidRootPart")
                        if vc and vh and vrp and vh.Health > 0 then break end
                        task.wait(0.5)
                    end
                else
                    task.wait(4)
                end

                _cachedRodName = nil
                continue
            end

            pcall(function()
                local root = getRoot()
                local currentCF = root and root.CFrame or CFrame.new()
                ReplicatedStorage.Events.takestam:FireServer(0.505, "dash", currentCF)
            end)

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 0: MUA ROD
            -- ════════════════════════════════════════════════════════════════
            local invForRod = GetInventory()
            _justBoughtRod  = false
            BuyFishingRodIfNeeded(invForRod)
            if not ZiliState.AutoFishing then break end
            if _justBoughtRod then continue end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 0.5: AUTO USE SPARE FRUIT BAG [FIX-5]
            -- ════════════════════════════════════════════════════════════════
            if ZiliState.AutoEquipFruitBag then
                TryEquipFruitBag()
            end
            if not ZiliState.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 0.6: AUTO CRAFT ROD (Lovestruck Rod Blueprint)
            -- Dieu kien: co Mero + Merchants Banana Rod, chua co Lovestruck Rod
            -- ════════════════════════════════════════════════════════════════
            if _Configs.CraftRod and ZiliState.AutoFishing then
                local invCraft       = GetInventory() or {}
                local hasMero        = (invCraft["Mero"] or 0) > 0
                local hasBanRod      = (invCraft["Merchants Banana Rod"] or 0) > 0
                local hasBlueprint   = (invCraft["Lovestruck Rod Blueprint"] or 0) > 0
                local hasLovestruck  = (invCraft["Lovestruck Rod"] or 0) > 0
                if hasMero and hasBanRod and hasBlueprint and not hasLovestruck then
                    TweenToPosAndWait(Cords.Craft)
                    if ZiliState.AutoFishing then
                        pcall(function()
                            CraftingRemoteR:InvokeServer(unpack({{
                                ["BlueprintItem"] = "Lovestruck Rod Blueprint",
                                ["Method"]        = "Craft",
                                ["ExtraData"]     = {},
                                ["Count"]         = 1
                            }}))
                        end)
                        task.wait(1.5)
                        _cachedRodName = nil
                    end
                end
            end
            if not ZiliState.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 1: TRAVELING MERCHANT (định kỳ / despawn guard)
            -- [FIX-1] Merchant spawn đột xuất đã được xử lý ở đầu vòng lặp
            -- Đây chỉ còn là safety net cho trường hợp chưa processed
            -- ════════════════════════════════════════════════════════════════
            if _Configs.AutoMerchant then
                local curMin = tonumber(os.date("%M")) or 0
                if curMin == 0 or curMin == 30 then
                    if _lastShopPeriod ~= curMin then
                        _lastShopPeriod = curMin
                        if ZiliState.KnownMerchantPos then ZiliState.MerchantProcessed = false end
                    end
                else
                    _lastShopPeriod = -1
                end

                if ZiliState.KnownMerchantPos then
                    if os.time() - (ZiliState.MerchantSpawnTime or 0) >= 600 then
                        ZiliState.KnownMerchantPos  = nil
                        ZiliState.MerchantProcessed = false
                        ZiliState.MerchantSpawnTime = 0
                        _lastShopPeriod      = -1
                        ZiliState.MerchantPending   = false
                    end
                end

                if ZiliState.KnownMerchantPos and not ZiliState.MerchantProcessed then
                    local mPos = ZiliState.KnownMerchantPos
                    TweenToPosAndWait(mPos, {isMerchant = true})
                    if ZiliState.AutoFishing then
                        local foundNpc = FindNearbyMerchant(rPart, 80)
                        if not foundNpc then
                            task.wait(1)
                            local root = getRoot()
                            if root then
                                root.CFrame = CFrame.new(mPos + Vector3.new(0, 2, 0))
                                task.wait(0.5)
                            end
                            foundNpc = FindNearbyMerchant(rPart, 100)
                        end
                        if foundNpc then
                            BuyItemsFromMerchant(foundNpc)
                            ZiliState.MerchantProcessed = true
                            ZiliState.MerchantPending   = false
                            TweenToPosAndWait(mPos + Vector3.new(20, 0, 20))
                        else
                            ZiliState.MerchantProcessed = true
                            ZiliState.MerchantPending   = false
                        end
                    end
                end
            end

            if not ZiliState.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 2: EQUIP ROD + TITLE [FIX-2]
            -- _cachedRodName reset sau mỗi merchant/respawn nên đây sẽ
            -- gọi server equip lại và EquipPhysicalRod có retry logic
            -- ════════════════════════════════════════════════════════════════
            local rodName = "Fishing Rod"
            if _Configs.EquipRod then
                rodName = AutoEquipRodSilent() or "Fishing Rod"
            end
            if _Configs.EquipTitle then AutoEquipTitleSilent() end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 3: MUA MỒI
            -- ════════════════════════════════════════════════════════════════
            if _Configs.BuyBait then
                local invCheck = GetInventory() or {}
                if (invCheck["Common Fish Bait"] or 0) < 1 then
                    TweenToPosAndWait(Cords.Buy)
                    if ZiliState.AutoFishing then
                        pcall(function()
                            ReplicatedStorage.Events.Shop:InvokeServer(
                                workspace.BuyableItems["Common Fish Bait"],
                                ZiliState.FishBuyAmount or 50
                            )
                        end)
                        task.wait(1)
                    end
                end
            end

            if not ZiliState.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 4: BÁN CÁ + CRAFT MỒI
            -- ════════════════════════════════════════════════════════════════
            if _Configs.SellCommon then AutoSellSilent(FishLists.Common) end
            if _Configs.SellRare   then AutoSellSilent(FishLists.Rare)   end
            if _Configs.SellLeg    then AutoSellSilent(FishLists.Leg)    end

            -- [FIX-3] ExtraData đã được sửa trong AutoCraftSilent
            if _Configs.CraftLeg  then AutoCraftSilent("Legendary Fish Bait","Legendary Fish",FishLists.Leg,  1, 1, "single")  end
            if _Configs.CraftRare then AutoCraftSilent("Rare Fish Bait",     "Rare Fish",     FishLists.Rare, 2, 2, _Configs.CraftRareMode) end

            if not ZiliState.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 5: CÂU CÁ
            -- [FIX-1] Thêm check ZiliState.MerchantPending vào vòng chờ bobble
            --         để ngắt cast ngay khi merchant spawn
            -- ════════════════════════════════════════════════════════════════
            local invFish = GetInventory() or {}
            ZiliState.TargetBait = ResolveBait(invFish)
            if not ZiliState.TargetBait then continue end

            -- [FIX-2] EquipPhysicalRod đã có retry logic 2s
            if not EquipPhysicalRod(rodName) then continue end

            pcall(function()
                local castPos = rPart.Position + (rPart.CFrame.LookVector * 30) - Vector3.new(0, 15, 0)
                FishingRemote:InvokeServer({["Goal"]=castPos,["Action"]="Throw",["Bait"]=ZiliState.TargetBait})
                task.wait(1.2)
                pcall(function() FishingRemote:InvokeServer({["Action"]="Landed"}) end)

                local bobble, waited = nil, 0
                -- [FIX-1] Thêm ZiliState.MerchantPending vào điều kiện dừng chờ
                while waited < 30 and ZiliState.AutoFishing and not ZiliState.FruitPriorityActive and not ZiliState.MerchantPending do
                    bobble = GetMyBobble(); if bobble then break end
                    if math.floor(waited) % 5 == 0 and waited > 0 then
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton2(Vector2.new())
                        end)
                    end
                    task.wait(0.2); waited = waited + 0.2
                end

                -- [FIX-1] Merchant spawn giữa chừng → cancel cast ngay
                if ZiliState.MerchantPending then
                    FishingRemote:InvokeServer({["Action"]="Cancel"})
                    return
                end

                if ZiliState.FruitPriorityActive then
                    FishingRemote:InvokeServer({["Action"]="Cancel"})
                    return
                end

                if bobble and ZiliState.AutoFishing then
                    local mm   = bobble:GetAttribute("MoveMultiplier") or 1
                    local seed = bobble:GetAttribute("Seed") or tick()
                    local rng  = Random.new(seed)
                    local tool = char:FindFirstChildOfClass("Tool")
                    local acc  = (tool and tool:GetAttribute("Acceleration")) or 1
                    if acc <= 0 then acc = 1 end

                    local jumps = rng:NextInteger(2, 5) * mm
                    local delay = 0
                    if mm >= 1.2 then      delay = jumps * (math.random(18,25)/10 / acc)
                    elseif mm >= 1.0 then  delay = jumps * (math.random(10,14)/10 / acc)
                    else                   delay = jumps * (math.random(4, 8)/10  / acc) end

                    local uid = (LocalPlayer.UserId % 100) / 100
                    local t   = (5.5 + delay) + (math.random(20,50)/100 + uid)

                    if mm >= 1.2 then
                        if t < 12.5 then t = math.random(1150,1250)/100 end
                        if t > 15.5 then t = math.random(1450,1550)/100 end
                    elseif mm >= 1.0 then
                        if t < 9.5  then t = math.random(900, 1000)/100 end
                        if t > 11.5 then t = math.random(1050,1150)/100 end
                    else
                        if t < 6.5  then t = math.random(450, 550)/100  end
                        if t > 8.0  then t = math.random(750, 850)/100  end
                    end

                    -- [FIX-1] Trong lúc đợi reel timing, check tiếp merchant flag
                    local elapsed = 0
                    local step    = 0.2
                    while elapsed < t and not ZiliState.MerchantPending and ZiliState.AutoFishing do
                        task.wait(step)
                        elapsed = elapsed + step
                    end
                    if ZiliState.MerchantPending then
                        FishingRemote:InvokeServer({["Action"]="Cancel"})
                        return
                    end

                    if ZiliState.AutoFishing then
                        if FishingRemote:InvokeServer({["Action"]="Reel"}) then
                            task.wait(0.3)
                            FishingRemote:InvokeServer({["Action"]="HookReturning"})
                            task.wait(0.4)
                            FishingRemote:InvokeServer({["Action"]="Cancel"})
                        else
                            FishingRemote:InvokeServer({["Action"]="Cancel"})
                        end
                    end
                else
                    FishingRemote:InvokeServer({["Action"]="Cancel"})
                end

                task.wait(0.1)
                if char:FindFirstChild("Humanoid") then char.Humanoid:UnequipTools() end
                -- [FIX-2] Reset cache sau mỗi cast để lần sau EquipPhysicalRod
                -- không bị skip khi rod đã unequip về backpack
                _cachedRodName = nil
                task.wait(0.1)
            end)
        end

        Tween.Stop()
    end

    -- =====================================================================
    -- PUBLIC API
    -- =====================================================================
    function AutoFishMerchant.Start(TogglesData)
        if ZiliState.AutoFishing then return end
        ZiliState.AutoFishing = true
        task.spawn(function() RunLoop(TogglesData) end)
    end

    function AutoFishMerchant.Stop()
        ZiliState.AutoFishing = false
        Tween.Stop()
    end

    return AutoFishMerchant
end

-- 📦 MODULE: Farm/AutoFruitManager
__modules["Farm/AutoFruitManager"] = function()
    local AutoFruitManager = {}

    local Players           = cloneref(game:GetService("Players"))
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local RunService        = cloneref(game:GetService("RunService"))
    local HttpService       = cloneref(game:GetService("HttpService"))
    local LocalPlayer       = Players.LocalPlayer

    -- ============================================================
    -- TWEEN SYSTEM CONSTANTS
    -- ============================================================
    local SWIM_Y         = -97.15
    local MAX_SPEED      = 90
    local DT_CAP         = 0.05
    local VEC_ZERO       = Vector3.new(0, 0, 0)
    local OFFSET_FAKEFLOOR = CFrame.new(0, -3.5, 0)

    local function getRoot()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    -- ============================================================
    -- FRUIT LISTS
    -- ============================================================
    local RARITY_ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }

    local FRUIT_RARITY = {
        Spin  = "Common", Suke   = "Common", Kilo  = "Common", Heal   = "Common",
        Bari  = "Rare",   Mero   = "Rare",   Horo  = "Rare",   Bomb   = "Rare",  Gomu = "Rare",
        Kira  = "Epic",   Spring = "Epic",   Yomi  = "Epic",
        Pika  = "Legendary", Mera  = "Legendary", Yami  = "Legendary", Smoke = "Legendary",
        Kage  = "Legendary", Paw   = "Legendary", Goru  = "Legendary", Yuki  = "Legendary",
        Magu  = "Legendary", Suna  = "Legendary", Goro  = "Legendary", Hie   = "Legendary",
        Gura  = "Legendary", Zushi = "Legendary",
        Dragon = "Mythic", Soul   = "Mythic", Mochi  = "Mythic",
        Venom  = "Mythic", Tori   = "Mythic", Pteranodon = "Mythic",
        Ope    = "Mythic", Buddha = "Mythic",
    }

    -- ============================================================
    -- DROP ZONES
    -- ============================================================
    local DROP_ZONES = {
        Common    = Vector3.new(-1399.33, 4.12, -5035.37),
        Rare      = Vector3.new(-1399.33, 4.12, -5035.37),
        Epic      = Vector3.new(-1399.33, 4.12, -5035.37),
        Legendary = Vector3.new(-1361.67, 4.12, -5034.76),
        Mythic    = Vector3.new(-1325.63, 4.12, -5037.1),
    }

    -- ============================================================
    -- REMOTES
    -- ============================================================
    local Events       = ReplicatedStorage:WaitForChild("Events", 9e9)
    local FruitStorage = Events:WaitForChild("FruitStorage", 9e9)
    local ToolsRemote  = Events:WaitForChild("Tools", 9e9)
    local TakeStam     = Events:WaitForChild("takestam", 9e9)

    -- ============================================================
    -- STAMINA SPOOF
    -- ============================================================
    local isSpoofingStamina = false
    local function StartStaminaSpoof()
        if isSpoofingStamina then return end
        isSpoofingStamina = true
        task.spawn(function()
            while isSpoofingStamina and task.wait(0.05) do
                if TakeStam and TakeStam.Parent then
                    pcall(function()
                        local root = getRoot()
                        local currentCF = root and root.CFrame or CFrame.new()
                        TakeStam:FireServer(0.505, "dash", currentCF)
                    end)
                else break end
            end
        end)
    end
    local function StopStaminaSpoof() isSpoofingStamina = false end

    -- ============================================================
    -- TWEEN SYSTEM
    -- ============================================================
    local isFlicking = false
    local Tween = {
        IsTeleporting = false,
        MoveConn      = nil,
        NoclipConn    = nil,
        FakeFloor     = nil,
        _gen          = 0,
    }

    local function StartSimpleFlickTimer()
        task.spawn(function()
            local timer = 0
            while Tween.IsTeleporting do
                task.wait(1)
                if not isFlicking then
                    local root = getRoot()
                    if root and root.Position.Y < -20 and root.Position.Y > -500 then
                        timer = timer + 1
                        if timer >= 20 then
                            isFlicking = true
                            local sx, sz = root.Position.X, root.Position.Z
                            root.CFrame = CFrame.new(sx, 7.33, sz)
                            pcall(function() root.Velocity = VEC_ZERO end)
                            task.wait(0.5)
                            if Tween.IsTeleporting then
                                root.CFrame = CFrame.new(sx, SWIM_Y, sz)
                                pcall(function() root.Velocity = VEC_ZERO end)
                            end
                            timer = 0
                            isFlicking = false
                        end
                    else
                        timer = 0
                    end
                end
            end
        end)
    end

    function Tween.Stop()
        Tween.IsTeleporting = false
        Tween._gen = Tween._gen + 1
        isFlicking = false
        StopStaminaSpoof()
        if Tween.MoveConn   then Tween.MoveConn:Disconnect();   Tween.MoveConn   = nil end
        if Tween.NoclipConn then Tween.NoclipConn:Disconnect(); Tween.NoclipConn = nil end
        local root = getRoot()
        if root then
            root.Anchored = false
            for _, v in pairs(root:GetChildren()) do
                if v.Name == "ZILI_AntiGravity" then v:Destroy() end
            end
            pcall(function() root.Velocity = VEC_ZERO; root.AssemblyLinearVelocity = VEC_ZERO end)
        end
        if Tween.FakeFloor then Tween.FakeFloor:Destroy(); Tween.FakeFloor = nil end
    end

    function Tween.Start(finalDest, onComplete)
        Tween.Stop()
        Tween.IsTeleporting = true
        local myGen = Tween._gen
        StartStaminaSpoof()
        StartSimpleFlickTimer()

        local _noclipParts = {}
        local _noclipChar  = nil
        local function _rebuildNoclip(char)
            _noclipChar = char
            _noclipParts = {}
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then _noclipParts[#_noclipParts + 1] = p end
            end
        end

        Tween.NoclipConn = RunService.Stepped:Connect(function()
            if not Tween.IsTeleporting then return end
            local char = LocalPlayer.Character
            if not char then return end
            if char ~= _noclipChar then _rebuildNoclip(char) end
            for _, p in ipairs(_noclipParts) do
                if p.Parent then p.CanCollide = false end
            end
        end)

        task.spawn(function()
            while Tween.IsTeleporting and myGen == Tween._gen do
                local char = LocalPlayer.Character
                if char then
                    if char ~= _noclipChar then _rebuildNoclip(char) end
                    for _, p in ipairs(_noclipParts) do
                        if p and p.Parent then p.CanCollide = false end
                    end
                    local r = getRoot()
                    if r and Tween.FakeFloor and Tween.FakeFloor.Parent then
                        Tween.FakeFloor.CFrame = r.CFrame * OFFSET_FAKEFLOOR
                    end
                end
                task.wait(0.05)
            end
        end)

        local initialRoot = getRoot()
        if not initialRoot then Tween.Stop(); return end

        local route = { { pos = finalDest, isPortal = false, isFishmanIn = false, isFishmanExit = false } }

        local function flyTo(stepData, onStepComplete)
            if Tween.MoveConn then Tween.MoveConn:Disconnect(); Tween.MoveConn = nil end

            local root = getRoot()
            local wt = 0
            while not root and wt < 10 do task.wait(0.5); wt += 0.5; root = getRoot() end
            if not Tween.IsTeleporting or not root then Tween.Stop(); return end

            if not Tween.FakeFloor then
                Tween.FakeFloor = Instance.new("Part")
                Tween.FakeFloor.Name      = "ZILI_FakeFloor"
                Tween.FakeFloor.Size      = Vector3.new(15, 2, 15)
                Tween.FakeFloor.Anchored  = true
                Tween.FakeFloor.Transparency = 1
                Tween.FakeFloor.Parent    = workspace
            end

            local ag = root:FindFirstChild("ZILI_AntiGravity")
            if not ag or not ag:IsA("BodyVelocity") then
                if ag then ag:Destroy() end
                ag = Instance.new("BodyVelocity")
                ag.Name     = "ZILI_AntiGravity"
                ag.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                ag.Velocity = VEC_ZERO
                ag.Parent   = root
            end

            local targetPos = stepData.pos

            Tween.MoveConn = RunService.Heartbeat:Connect(function(rawDt)
                if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end
                if isFlicking then return end

                local dt  = math.min(rawDt, DT_CAP)
                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                pcall(function() root.Velocity = VEC_ZERO; root.AssemblyLinearVelocity = VEC_ZERO end)

                local cur    = root.Position
                local distXZ = (Vector2.new(targetPos.X, targetPos.Z) - Vector2.new(cur.X, cur.Z)).Magnitude

                if math.abs(cur.Y - SWIM_Y) > 10 and distXZ > 50 then
                    if TakeStam and TakeStam.Parent then
                        pcall(function() TakeStam:FireServer(0.505, "dash", root.CFrame) end)
                    end
                    root.CFrame = CFrame.new(cur.X, SWIM_Y, cur.Z)
                    if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                    return
                end

                if distXZ < 30 then
                    Tween.MoveConn:Disconnect()
                    task.spawn(function()
                        root.CFrame = CFrame.new(targetPos.X, targetPos.Y + 3, targetPos.Z)
                        if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                        task.wait(0.3)
                        if (root.Position - targetPos).Magnitude > 60 then
                            task.wait(0.2)
                            flyTo(stepData, onStepComplete)
                            return
                        end
                        if onStepComplete then onStepComplete() end
                    end)
                else
                    local maxS = math.min(MAX_SPEED * dt, 10)
                    local tgt  = Vector3.new(targetPos.X, SWIM_Y, targetPos.Z)
                    local diff = tgt - cur
                    local dist = diff.Magnitude
                    if dist > 0 then
                        root.CFrame = CFrame.new(cur + diff.Unit * math.min(maxS, dist))
                    end
                end
            end)
        end

        local function processRoute(idx)
            if not Tween.IsTeleporting then return end
            if idx > #route then Tween.Stop(); if onComplete then onComplete() end; return end
            flyTo(route[idx], function() processRoute(idx + 1) end)
        end
        processRoute(1)
    end

    -- Blocking wait wrapper
    local function TweenToPosAndWait(targetPos)
        local isDone = false
        Tween.Start(targetPos, function() isDone = true end)
        while not isDone do
            if not Tween.IsTeleporting and not isDone then break end
            task.wait(0.2)
        end
    end

    -- ============================================================
    -- DISCORD WEBHOOK
    -- ============================================================
    local function GetPSCode()
        local code = ""
        pcall(function()
            local rc = game:GetService("ReplicatedStorage"):FindFirstChild("reservedCode")
            if rc and rc.Value and rc.Value ~= "" then
                code = rc.Value
            end
        end)

        if code == "" then
            pcall(function()
                code = game.PrivateServerAccessKey or ""
            end)
        end
        if code == "" then
            pcall(function()
                code = game.PrivateServerId or ""
            end)
        end
        return code
    end
    local psCode = GetPSCode()

    local RARITY_COLOR = {
        Common    = 9803161,
        Rare      = 3447003,
        Epic      = 10181046,
        Legendary = 16744272,
        Mythic    = 16711680,
    }
    local RARITY_EMOJI = {
        Common = "⚪", Rare = "🔵", Epic = "🟣", Legendary = "🟠", Mythic = "🔴"
    }

    local function SendWebhook(fruitName, action)
        local webhookUrl = getgenv().Config_DiscordWebhook
        if not webhookUrl or webhookUrl == "" then return end

        local rarity = FRUIT_RARITY[fruitName] or "Common"

        local notifyFilter = getgenv().Config_WebhookRarities
        if type(notifyFilter) == "table" and not notifyFilter[rarity] then return end

        local isMythic     = rarity == "Mythic"
        local actionEmoji  = action == "Store" and "📦" or "🗑️"
        local rarityEmoji  = RARITY_EMOJI[rarity] or "⚪"
        local color        = RARITY_COLOR[rarity]  or 9803161
        local content      = isMythic and "@everyone\n🚨 **MYTHIC FRUIT DETECTED!**" or ""
        local userfruit = "||"..LocalPlayer.Name.."||"

        local payload = {
            content  = content,
            username = "🍎 Fruit Tracker",
            embeds   = {
                {
                    title       = actionEmoji .. "  Fruit " .. action .. "  —  " .. rarityEmoji .. " " .. rarity,
                    description = table.concat({
                        "━━━━━━━━━━━━━━━━━━━━━━",
                        "**🤰 User   : **" .. userfruit,
                        "**🔐 PS code: ** ||" .. (psCode ~= "" and psCode or "Public Server") .. "||",
                        "━━━━━━━━━━━━━━━━━━━━━━",
                        " **🍇 FRUIT LOG 🍇**",
                        "```diff",
                        "+ Fruit   : " .. fruitName,
                        "+ Rarity  : " .. rarity,
                        "- Action  : " .. action,
                        "```",
                    }, "\n"),
                    color  = color,
                    footer = {
                        text = "Zili_Hub" ..(isMythic and "  •  ⚠️ Rare catch!" or ""),
                    },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    thumbnail = {
                        url = getgenv().Config_WebhookThumbnail or "https://static.wikia.nocookie.net/grand-piece-online/images/7/72/DFIconRecreation.png/revision/latest?cb=20230711100403",
                    },
                },
            },
        }

        task.spawn(function()
            pcall(function()
                local http = (syn and syn.request) or (http and http.request) or request
                if not http then return end
                http({
                    Url     = webhookUrl,
                    Method  = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = HttpService:JSONEncode(payload),
                })
            end)
        end)
    end

    -- ============================================================
    -- HELPERS
    -- ============================================================
    local function GetFruits()
        local fruits = {}
        if LocalPlayer.Character then
            for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") and FRUIT_RARITY[tool.Name] then
                    table.insert(fruits, tool)
                end
            end
        end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and FRUIT_RARITY[tool.Name] then
                    table.insert(fruits, tool)
                end
            end
        end
        return fruits
    end

    local function getNilTool(name)
        if not getnilinstances then return nil end
        for _, v in next, getnilinstances() do
            if v.ClassName == "Tool" and v.Name == name then return v end
        end
        return nil
    end

    local function GetMinKeepLevel(selectedRarity)
        if type(selectedRarity) == "string" then
            return RARITY_ORDER[selectedRarity] or 0
        elseif type(selectedRarity) == "table" then
            local minLevel = 99
            for rarity, selected in pairs(selectedRarity) do
                if selected and RARITY_ORDER[rarity] then
                    minLevel = math.min(minLevel, RARITY_ORDER[rarity])
                end
            end
            return minLevel == 99 and 0 or minLevel
        end
        return 0
    end

    -- ============================================================
    -- INVENTORY CHECK
    -- Đọc JSON từ ReplicatedStorage.StatsJohnpork9876394543.Inventory.Inventory
    -- Trả về table { [fruitName] = count } hoặc {} nếu lỗi
    -- ============================================================
    local function GetInventory()
        local ok, invInst = pcall(function()
            return ReplicatedStorage
                :WaitForChild("StatsJohnpork9876394543", 5)
                :WaitForChild("Inventory", 5)
                :WaitForChild("Inventory", 5)
        end)
        if not ok or not invInst then return {} end
        local ok2, data = pcall(function()
            return HttpService:JSONDecode(invInst.Value)
        end)
        return (ok2 and type(data) == "table") and data or {}
    end

    local function IsInInventory(fruitName, inv)
        local count = inv[fruitName]
        return count ~= nil and count > 0
    end

    -- ============================================================
    -- EQUIP TOOL
    -- ============================================================
    local function EquipTool(tool)
        local char     = LocalPlayer.Character
        if not char then return nil end
        local hum      = char:FindFirstChild("Humanoid")
        if not hum then return nil end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return nil end

        if tool.Parent == char then return tool end

        if tool.Parent ~= backpack then
            tool.Parent = backpack
            task.wait(0.15)
        end

        hum:EquipTool(tool)
        local waited = 0
        while waited < 1.2 do
            task.wait(0.1); waited += 0.1
            if tool.Parent == char then return tool end
        end

        tool.Parent = char
        task.wait(0.35)
        if tool.Parent == char then return tool end

        local nilTool = getNilTool(tool.Name)
        if nilTool then
            nilTool.Parent = backpack
            task.wait(0.1)
            hum:EquipTool(nilTool)
            task.wait(0.6)
            if nilTool.Parent == char then return nilTool end
        end

        return nil
    end

    -- ============================================================
    -- CHECK NHANH
    -- ============================================================
    local function HasActionableFruit()
        local fruits    = GetFruits()
        if #fruits == 0 then return false end
        local autoStore = getgenv().AutoStoreFruit
        local autoDrop  = getgenv().AutoDropFruit
        if not autoStore and not autoDrop then return false end

        -- Khi cả 2 đều bật → mọi fruit đều cần xử lý (Store hoặc Drop)
        if autoStore and autoDrop then return true end

        local rarityFilter = getgenv().Config_FruitRarity or "Common"
        local minLevel     = GetMinKeepLevel(rarityFilter)

        for _, tool in ipairs(fruits) do
            local level = RARITY_ORDER[FRUIT_RARITY[tool.Name] or "Common"] or 1
            if autoStore and ((minLevel == 0) or (level >= minLevel)) then return true end
            if autoDrop  and ((minLevel == 0) or (level < minLevel))  then return true end
        end
        return false
    end

    -- ============================================================
    -- UNIFIED FRUIT ACTION
    -- Ưu tiên: Store trước, nếu fruit đã có trong Inventory thì Drop
    -- Khi chỉ 1 trong 2 toggle bật → hành vi cũ
    -- ============================================================
    local function DoFruitActions()
        local autoStore = getgenv().AutoStoreFruit
        local autoDrop  = getgenv().AutoDropFruit
        local fruits    = GetFruits()
        if #fruits == 0 then return end

        local rarityFilter = getgenv().Config_FruitRarity or "Common"
        local minLevel     = GetMinKeepLevel(rarityFilter)
        local bothEnabled  = autoStore and autoDrop

        -- Lấy inventory 1 lần duy nhất khi cả 2 toggle bật (tránh spam request)
        local inv = bothEnabled and GetInventory() or {}

        local toStore = {}
        local toDrop  = {}

        for _, tool in ipairs(fruits) do
            local level  = RARITY_ORDER[FRUIT_RARITY[tool.Name] or "Common"] or 1

            if bothEnabled then
                -- Ưu tiên Store; kiểm tra inventory: nếu đã có → Drop
                local meetsStoreLevel = (minLevel == 0) or (level >= minLevel)
                if meetsStoreLevel then
                    if IsInInventory(tool.Name, inv) then
                        -- Fruit đã có trong inventory → Drop
                        table.insert(toDrop, tool)
                    else
                        -- Chưa có → Store
                        table.insert(toStore, tool)
                    end
                else
                    -- Dưới ngưỡng filter → luôn Drop
                    table.insert(toDrop, tool)
                end

            elseif autoStore then
                if (minLevel == 0) or (level >= minLevel) then
                    table.insert(toStore, tool)
                end

            elseif autoDrop then
                if (minLevel == 0) or (level < minLevel) then
                    table.insert(toDrop, tool)
                end
            end
        end

        -- ── STORE ──────────────────────────────────────────────
        for _, tool in ipairs(toStore) do
            local fruitName = tool.Name
            local equipped  = EquipTool(tool)
            if equipped then
                local ok = pcall(function() FruitStorage:InvokeServer(equipped) end)
                if ok then SendWebhook(fruitName, "Store") end
                task.wait(0.9)
            else
                pcall(function() FruitStorage:InvokeServer(fruitName) end)
                SendWebhook(fruitName, "Store")
                task.wait(0.9)
            end
        end

        -- ── DROP (nhóm theo zone, tween 1 lần/zone) ────────────
        if #toDrop > 0 then
            local VirtualInputManager = game:GetService("VirtualInputManager")
            local groups = {}

            for _, tool in ipairs(toDrop) do
                local rarity  = FRUIT_RARITY[tool.Name] or "Common"
                local zonePos = DROP_ZONES[rarity]
                local key     = rarity
                if not groups[key] then
                    groups[key] = { pos = zonePos, tools = {} }
                end
                table.insert(groups[key].tools, tool)
            end

            for _, group in pairs(groups) do
                if group.pos then
                    TweenToPosAndWait(group.pos)
                    Tween.Stop()              -- ← THÊM: dọn sạch tween sau khi tới nơi
                    task.wait(0.8)            -- đợi character ổn định hơn
                end

                for _, tool in ipairs(group.tools) do
                    local fruitName = tool.Name

                    -- Retry equip tối đa 3 lần
                    local equipped = nil
                    for attempt = 1, 3 do
                        equipped = EquipTool(tool)
                        if equipped then break end
                        task.wait(0.3)
                    end
                    if not equipped then
                        warn("[AutoDrop] Không equip được:", fruitName)
                        continue
                    end

                    task.wait(0.5) -- server ghi nhận tool trên tay

                    -- Backspace drop
                    VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Backspace, false, game)
                    task.wait(0.15)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)

                    task.wait(0.6)
                    SendWebhook(fruitName, "Drop")
                    task.wait(0.5)
                end
            end
        end
    end

    -- ============================================================
    -- MAIN LOOP
    -- ============================================================
    local _running = false

    function AutoFruitManager.Start()
        if _running then return end
        _running = true
        ZiliState.FruitPriorityActive = false

        task.spawn(function()
            while _running do
                task.wait(0.5)

                local autoStore = getgenv().AutoStoreFruit
                local autoDrop  = getgenv().AutoDropFruit

                if (autoStore or autoDrop) and HasActionableFruit() then
                    ZiliState.FruitPriorityActive = true
                    task.wait(0.4) -- cho fishing module dừng

                    pcall(DoFruitActions)

                    ZiliState.FruitPriorityActive = false
                end
            end
            ZiliState.FruitPriorityActive = false
        end)
    end

    function AutoFruitManager.Stop()
        _running = false
        Tween.Stop()
        ZiliState.FruitPriorityActive = false
    end

    return AutoFruitManager
end

-- 📦 MODULE: Esp.lua
__modules["Island/Esp"] = function()
    local Esp = {}
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")

    local ESP_Holder = Workspace:FindFirstChild("ZILI_ESP_Holder") or Instance.new("Folder", Workspace)
    ESP_Holder.Name = "ZILI_ESP_Holder"

    function Esp.Toggle(isActive, islandsData)
        ESP_Holder:ClearAllChildren()
        if not isActive then return end
        
        for name, posData in pairs(islandsData) do
            local pos = type(posData) == "table" and posData[#posData] or posData
            local p = Instance.new("Part", ESP_Holder)
            p.Anchored = true; p.Transparency = 1; p.Position = pos; p.CanCollide = false
            
            local bg = Instance.new("BillboardGui", p)
            bg.AlwaysOnTop = true; bg.Size = UDim2.new(0, 200, 0, 50)
            
            local lb = Instance.new("TextLabel", bg)
            lb.Size = UDim2.new(1, 0, 1, 0); lb.BackgroundTransparency = 1
            lb.TextColor3 = Color3.fromRGB(255, 215, 0); lb.Font = Enum.Font.Arcade; lb.TextSize = 15
            lb.Text = name
            
            task.spawn(function()
                while p.Parent and isActive do
                    local char = Players.LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - pos).Magnitude
                        lb.Text = string.format("%s\n[%.0f m]", name, dist)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
    return Esp
end

-- 📦 MODULE: Misc/DisplayName
__modules["Misc/DisplayName"] = function()
    local DisplayName = {}
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local localPlayer = Players.LocalPlayer
    local playerGui = localPlayer:WaitForChild("PlayerGui")

    local ZILI_NAMES = {
        {name="✦ ZILI PHANTOM ✦",    col=Color3.fromRGB(130,100,255)},
        {name="⚡ ZILI STORM ⚡",      col=Color3.fromRGB(80,200,255)},
        {name="🌌 ZILI NEBULA 🌌",    col=Color3.fromRGB(170,60,255)},
        {name="👁 ZILI WATCHER 👁",   col=Color3.fromRGB(240,75,190)},
        {name="⚔ ZILI BLADE ⚔",      col=Color3.fromRGB(255,215,85)},
    }

    local active = false
    local currentName = ZILI_NAMES[1].name
    local currentColor = ZILI_NAMES[1].col
    local conn = nil

    local function overwriteUI()
        local healthBars = playerGui:FindFirstChild("HealthBars")
        if healthBars then
            for _, bar in pairs(healthBars:GetChildren()) do
                for _, lbl in pairs(bar:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Text ~= currentName then
                        lbl.Text = currentName
                        lbl.TextColor3 = currentColor
                    end
                end
            end
        end
        local list = playerGui:FindFirstChild("Playerlist")
        if list and list:FindFirstChild("Main") then
            local scroll = list.Main:FindFirstChild("ScrollingFrame")
            if scroll then
                for _, cont in pairs({
                    scroll:FindFirstChild("Pirate") and scroll.Pirate:FindFirstChild("Container"),
                    scroll:FindFirstChild("Marine") and scroll.Marine:FindFirstChild("Container"),
                }) do
                    if cont then
                        for _, frame in pairs(cont:GetChildren()) do
                            for _, lbl in pairs(frame:GetDescendants()) do
                                if lbl:IsA("TextLabel") and lbl.Text ~= currentName then
                                    for _, p in pairs(Players:GetPlayers()) do
                                        if lbl.Text:find(p.Name,1,true) or (p.DisplayName~="" and lbl.Text:find(p.DisplayName,1,true)) then
                                            lbl.Text = currentName; lbl.TextColor3 = currentColor; break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    function DisplayName.Start(nameIdx)
        local n = ZILI_NAMES[nameIdx] or ZILI_NAMES[1]
        currentName = n.name; currentColor = n.col
        active = true
        if conn then conn:Disconnect() end
        conn = RunService.RenderStepped:Connect(function() pcall(overwriteUI) end)
    end

    function DisplayName.Stop()
        active = false
        if conn then conn:Disconnect(); conn = nil end
    end

    function DisplayName.GetNames() return ZILI_NAMES end
    function DisplayName.IsActive() return active end

    return DisplayName
end

-- 📦 MODULE: Misc/CharacterChanger
__modules["Misc/CharacterChanger"] = function()
    local CC = {}
    local Players     = game:GetService("Players")
    local RunService  = game:GetService("RunService")
    local TweenService= game:GetService("TweenService")

    local player     = Players.LocalPlayer
    -- Support game-specific charFolder or fallback to player.Character
    local charFolder
    pcall(function() charFolder = workspace:WaitForChild("PlayerCharacters",3) end)
    local char = (charFolder and charFolder:FindFirstChild(player.Name))
             or player.Character or player.CharacterAdded:Wait()

    local MODE = "NONE"; local t = 0; local lastPulse = 0
    local cachedPartData = {}
    local loopConn = nil

    local HLs = {ICE=nil,GHOST=nil,SHADOW=nil,MAGMA=nil,MIDAS=nil,NEBULA=nil,DIAMOND=nil,PLASMA=nil}
    local customEffects = {}
    local magmaEmbers   = {}
    local slimeCores    = {}
    local scrapEyes     = {}
    local seraphimRings = {}
    local glitchTrails  = {}
    local puppetData    = {}

    -- RESPAWN
    if charFolder then
        charFolder.ChildAdded:Connect(function(nc)
            if nc.Name==player.Name then
                char=nc; cachedPartData={}
                for k in pairs(HLs) do HLs[k]=nil end
                customEffects={}; magmaEmbers={}; slimeCores={}; scrapEyes={}
                seraphimRings={}; glitchTrails={}; puppetData={}
            end
        end)
    end
    player.CharacterAdded:Connect(function(nc)
        if not charFolder then
            char=nc; cachedPartData={}
            for k in pairs(HLs) do HLs[k]=nil end
            customEffects={}; magmaEmbers={}; slimeCores={}; scrapEyes={}
            seraphimRings={}; glitchTrails={}; puppetData={}
        end
    end)

    local LAVA_HOT  = {Color3.fromRGB(255,80,0),Color3.fromRGB(255,35,0),Color3.fromRGB(255,175,0)}
    local LAVA_DARK = {Color3.fromRGB(22,8,2),Color3.fromRGB(38,12,4),Color3.fromRGB(55,18,6)}

    local function F(parent,pos,size,col,alpha)
        local f=Instance.new("Frame")
        f.Position=pos; f.Size=size; f.BackgroundColor3=col
        f.BackgroundTransparency=alpha or 0; f.BorderSizePixel=0; f.Parent=parent
        return f
    end
    local _sd={}
    local function seed(name)
        if not _sd[name] then local h=0;for i=1,#name do h=h+string.byte(name,i)*i*17 end;_sd[name]=(h%997)/997 end
        return _sd[name]
    end
    local BG={
        Head={sp=1.00,ph=0.00},UpperTorso={sp=0.95,ph=0.18},LowerTorso={sp=0.90,ph=0.34},
        LeftUpperArm={sp=1.05,ph=0.55},RightUpperArm={sp=1.05,ph=0.72},
        LeftLowerArm={sp=1.10,ph=0.88},RightLowerArm={sp=1.10,ph=1.02},
        LeftHand={sp=1.15,ph=1.15},RightHand={sp=1.15,ph=1.28},
        LeftUpperLeg={sp=0.85,ph=1.40},RightUpperLeg={sp=0.85,ph=1.56},
        LeftLowerLeg={sp=0.80,ph=1.68},RightLowerLeg={sp=0.80,ph=1.82},
        LeftFoot={sp=0.75,ph=1.95},RightFoot={sp=0.75,ph=2.08},
    }
    local function rebuildParts()
        cachedPartData={}; if not char then return end
        for _,p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
                local s=seed(p.Name); local bg=BG[p.Name] or {sp=1.0,ph=s*2.1}
                cachedPartData[#cachedPartData+1]={part=p,seed=s,bSpd=bg.sp,bPhs=bg.ph+s*0.28}
            end
        end
    end
    local function dHL(r) if r then pcall(function()r:Destroy()end) end; return nil end

    local function deepClean()
        for _,ld in ipairs(glitchTrails) do for _,pd in ipairs(ld.parts) do pcall(function()pd.fake:Destroy()end) end end; glitchTrails={}
        for _,v in ipairs(magmaEmbers)  do pcall(function()v.bb:Destroy()end) end;  magmaEmbers={}
        for _,v in ipairs(slimeCores)   do pcall(function()v.core:Destroy()end) end; slimeCores={}
        for _,v in ipairs(scrapEyes)    do pcall(function()v.sg:Destroy()end) end;   scrapEyes={}
        for _,eff in ipairs(customEffects) do pcall(function()eff:Destroy()end) end;  customEffects={}
        seraphimRings={}; puppetData={}
        for k,v in pairs(HLs) do HLs[k]=dHL(v) end
        for _,pd in ipairs(cachedPartData) do
            pcall(function()
                pd.part.Color=Color3.new(1,1,1); pd.part.Material=Enum.Material.SmoothPlastic
                pd.part.Transparency=0; pd.part.Reflectance=0; pd.part.CastShadow=true
            end)
        end
    end

    local function mkHL(fc,ft,oc,ot)
        local h=Instance.new("Highlight"); h.FillColor=fc; h.FillTransparency=ft
        h.OutlineColor=oc; h.OutlineTransparency=ot; h.Parent=char
        table.insert(customEffects,h); return h
    end

    local function spawnEffects(mode)
        local root=char and char:FindFirstChild("HumanoidRootPart"); if not root then return end
        if mode=="ICE" then local s=Instance.new("Smoke",root); s.Color=Color3.fromRGB(220,255,255); s.Opacity=0.2; s.Size=4; s.RiseVelocity=-2; table.insert(customEffects,s) end
    end

    local function createMagmaEmbers()
        magmaEmbers={}
        local eParts={"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}
        local idx=0
        for _,pn in ipairs(eParts) do
            local part=char and char:FindFirstChild(pn); if not part then continue end
            local sd=seed(pn)*997
            for j=1,6 do
                idx=idx+1
                local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,5,0,5)
                bb.StudsOffset=Vector3.new((((sd*j*29+11)%1000)/1000-0.5)*1.4,(((sd*j*43+17)%1000)/1000-0.5)*1.9,(((sd*j*61+7)%1000)/1000*0.7+0.3))
                bb.AlwaysOnTop=false; bb.LightInfluence=0; bb.Adornee=part; bb.Parent=part
                local ec=j%2==0 and Color3.fromRGB(255,130,0) or Color3.fromRGB(255,50,0)
                local ef=F(bb,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),ec,0.18); Instance.new("UICorner",ef).CornerRadius=UDim.new(1,0)
                magmaEmbers[#magmaEmbers+1]={bb=bb,dot=ef,phase=idx*0.74,speed=1.6+(idx%7)*0.38}
            end
        end
    end

    local function createSlimeCore()
        slimeCores={}
        local torso=char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")); if not torso then return end
        local core=Instance.new("Part"); core.Size=Vector3.new(1.2,1.2,1.2); core.Shape=Enum.PartType.Ball
        core.Material=Enum.Material.Neon; core.Color=Color3.fromRGB(100,255,100); core.CanCollide=false; core.Massless=true
        local weld=Instance.new("WeldConstraint"); weld.Part0=core; weld.Part1=torso; core.CFrame=torso.CFrame; weld.Parent=core; core.Parent=char
        local light=Instance.new("PointLight"); light.Color=core.Color; light.Range=8; light.Brightness=2; light.Parent=core
        slimeCores[1]={core=core,light=light}; table.insert(customEffects,core)
    end

    local function createScrapEye()
        scrapEyes={}
        local head=char and char:FindFirstChild("Head"); if not head then return end
        local sg=Instance.new("SurfaceGui"); sg.Face=Enum.NormalId.Front; sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud=50; sg.Parent=head
        local eye=F(sg,UDim2.new(0.6,0,0.3,0),UDim2.new(0,16,0,16),Color3.fromRGB(255,100,0),0); Instance.new("UICorner",eye).CornerRadius=UDim.new(1,0)
        scrapEyes[1]={sg=sg,eye=eye}; table.insert(customEffects,sg)
    end

    local function createSeraphim()
        seraphimRings={}
        local root=char and char:FindFirstChild("HumanoidRootPart"); local head=char and char:FindFirstChild("Head"); if not root then return end
        local ringColors={Color3.fromRGB(255,255,255),Color3.fromRGB(255,215,0),Color3.fromRGB(255,140,0)}
        local speeds={{2,1,0.5},{-1.5,2,1},{1,-1,2}}
        for i=1,3 do
            local ring=Instance.new("Part"); ring.Size=Vector3.new(1,1,1); ring.Anchored=true; ring.CanCollide=false; ring.CastShadow=false
            ring.Material=Enum.Material.Neon; ring.Color=ringColors[i]
            local mesh=Instance.new("SpecialMesh",ring); mesh.MeshId="rbxassetid://3270017"; mesh.Scale=Vector3.new(12,12,0.2)
            ring.Parent=char; table.insert(customEffects,ring); table.insert(seraphimRings,{part=ring,speed=speeds[i],offset=i})
        end
        if head then
            local eye=Instance.new("Part"); eye.Shape=Enum.PartType.Ball; eye.Size=Vector3.new(1.5,1.5,1.5)
            eye.Color=Color3.fromRGB(255,255,255); eye.Material=Enum.Material.Neon; eye.Anchored=true; eye.CanCollide=false; eye.CastShadow=false; eye.Parent=char
            local pe=Instance.new("ParticleEmitter",eye); pe.Color=ColorSequence.new(Color3.fromRGB(255,215,0))
            pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.5,2),NumberSequenceKeypoint.new(1,0)})
            pe.Rate=20; pe.Speed=NumberRange.new(0); pe.Lifetime=NumberRange.new(1)
            table.insert(customEffects,eye); table.insert(seraphimRings,{isEye=true,part=eye})
        end
    end

    local function createGlitchTrails()
        glitchTrails={}
        local colors={Color3.fromRGB(0,255,255),Color3.fromRGB(255,0,255)}
        for layer=1,2 do
            local cloneLayer={}
            for _,p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name~="HumanoidRootPart" and not p:FindFirstAncestorWhichIsA("Accessory") and not p:FindFirstAncestorWhichIsA("Hat") then
                    local clone=p:Clone()
                    for _,child in pairs(clone:GetChildren()) do if not child:IsA("DataModelMesh") then child:Destroy() end end
                    clone.Material=Enum.Material.Neon; clone.Color=colors[layer]; clone.Transparency=0.5
                    clone.Anchored=true; clone.CanCollide=false; clone.CastShadow=false; clone.Parent=workspace
                    table.insert(cloneLayer,{real=p,fake=clone})
                end
            end
            table.insert(glitchTrails,{layerIndex=layer,parts=cloneLayer})
        end
    end

    local function createPuppet()
        puppetData={}
        local root=char and char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local cross=Instance.new("Model",char); table.insert(customEffects,cross)
        local bar1=Instance.new("Part"); bar1.Size=Vector3.new(12,0.6,0.6); bar1.Material=Enum.Material.Wood; bar1.Color=Color3.fromRGB(120,80,40); bar1.Anchored=true; bar1.CanCollide=false; bar1.Parent=cross
        local bar2=Instance.new("Part"); bar2.Size=Vector3.new(0.6,0.6,12); bar2.Material=Enum.Material.Wood; bar2.Color=Color3.fromRGB(120,80,40); bar2.Anchored=true; bar2.CanCollide=false; bar2.Parent=cross
        local joints={"RightHand","LeftHand","RightFoot","LeftFoot","Head"}
        for idx,jName in ipairs(joints) do
            local joint=char:FindFirstChild(jName)
            if joint then
                local att=Instance.new("Attachment",joint); local beam=Instance.new("Beam",joint); beam.Attachment0=att
                local sp=Instance.new("Attachment",bar1); local spread=5.5
                if idx==1 then sp.Position=Vector3.new(spread,0,0) elseif idx==2 then sp.Position=Vector3.new(-spread,0,0)
                elseif idx==3 then sp.Position=Vector3.new(0,0,spread) elseif idx==4 then sp.Position=Vector3.new(0,0,-spread)
                else sp.Position=Vector3.new(0,0,0) end
                beam.Attachment1=sp; beam.Color=ColorSequence.new(Color3.fromRGB(255,50,50)); beam.Width0=0.15; beam.Width1=0.05; beam.LightEmission=1; beam.FaceCamera=true
                table.insert(customEffects,beam); table.insert(customEffects,att)
            end
        end
        puppetData.b1=bar1; puppetData.b2=bar2
    end

    local function createDomainExpansion(rootPos)
        local sphere=Instance.new("Part"); sphere.Shape=Enum.PartType.Ball; sphere.Size=Vector3.new(2,2,2)
        sphere.Anchored=true; sphere.CanCollide=false; sphere.CastShadow=false; sphere.Material=Enum.Material.Neon; sphere.Color=Color3.fromRGB(0,0,0); sphere.Position=rootPos; sphere.Parent=workspace
        TweenService:Create(sphere,TweenInfo.new(1.0,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=Vector3.new(40,40,40),Transparency=1}):Play()
        game.Debris:AddItem(sphere,1.2)
    end

    local function applyStatic(mode)
        if not HLs.ICE    and mode=="ICE"    then HLs.ICE    = mkHL(Color3.fromRGB(150,220,255),0.6,Color3.fromRGB(100,200,255),0.1)   end
        if not HLs.GHOST  and mode=="GHOST"  then HLs.GHOST  = mkHL(Color3.fromRGB(225,218,255),0.48,Color3.fromRGB(200,188,255),0.10) end
        if not HLs.SHADOW and mode=="SHADOW" then HLs.SHADOW = mkHL(Color3.fromRGB(0,0,0),0.2,Color3.fromRGB(80,0,10),0.4)            end
        if not HLs.MAGMA  and mode=="MAGMA"  then HLs.MAGMA  = mkHL(Color3.fromRGB(255,55,0),0.78,Color3.fromRGB(255,130,0),0.32)     end
        if not HLs.MIDAS  and mode=="MIDAS"  then HLs.MIDAS  = mkHL(Color3.fromRGB(255,200,0),0.85,Color3.fromRGB(255,255,150),0.20)  end
        if not HLs.NEBULA and mode=="NEBULA" then HLs.NEBULA = mkHL(Color3.fromRGB(50,0,100),0.8,Color3.fromRGB(180,50,255),0.10)     end
        if not HLs.DIAMOND and mode=="DIAMOND" then HLs.DIAMOND=mkHL(Color3.fromRGB(200,255,255),1,Color3.fromRGB(255,255,255),0.05)  end
        if not HLs.PLASMA and mode=="PLASMA" then HLs.PLASMA = mkHL(Color3.fromRGB(255,50,200),0.8,Color3.fromRGB(255,150,255),0.1)   end
        for _,pd in ipairs(cachedPartData) do
            local p=pd.part; local s=pd.seed; if not p or not p.Parent then continue end
            if mode=="ICE" then p.CastShadow=false; p.Material=Enum.Material.Foil; p.Color=Color3.fromRGB(170,220,255); p.Reflectance=0.05; p.Transparency=0.2
            elseif mode=="GHOST" then p.Material=Enum.Material.ForceField; p.Reflectance=0; p.CastShadow=false; if p.Name=="Head" then p.Transparency=1 else p.Color=s<0.32 and Color3.fromRGB(160,155,255) or s<0.66 and Color3.fromRGB(210,205,255) or Color3.fromRGB(248,246,255); p.Transparency=0.55+s*0.28 end
            elseif mode=="SHADOW" then p.CastShadow=false; p.Material=Enum.Material.Fabric; p.Color=Color3.fromRGB(0,0,0); p.Reflectance=0; p.Transparency=0
            elseif mode=="MAGMA" then p.CastShadow=false; if s>0.52 then p.Color=LAVA_HOT[(math.floor(s*14)%#LAVA_HOT)+1]; p.Material=Enum.Material.Neon; p.Transparency=0; p.Reflectance=0 else p.Color=LAVA_DARK[(math.floor(s*12)%#LAVA_DARK)+1]; p.Material=Enum.Material.Slate; p.Transparency=0; p.Reflectance=0.01+s*0.03 end
            elseif mode=="SLIME" then p.Material=Enum.Material.Glass; p.Transparency=0.5; p.Color=Color3.fromRGB(50,255,100)
            elseif mode=="SCRAP" then p.Material=Enum.Material.CorrodedMetal; p.Color=Color3.fromRGB(100,50,30); p.Transparency=0
            elseif mode=="MIDAS" then p.Material=Enum.Material.Foil; p.Color=Color3.fromRGB(255,170,0); p.Reflectance=0.2; p.Transparency=0
            elseif mode=="PLASMA" then p.Material=Enum.Material.ForceField; p.Color=Color3.fromRGB(255,50,200); p.CastShadow=false; if p.Name=="Head" then p.Transparency=1 else p.Transparency=0 end
            elseif mode=="DIAMOND" then p.Material=Enum.Material.Glass; p.Color=Color3.fromRGB(220,255,255); p.Reflectance=0.1; p.Transparency=0.55
            elseif mode=="NEBULA" then p.Material=Enum.Material.Neon; p.Color=Color3.fromRGB(10,0,30); p.Transparency=0.5; p.CastShadow=false
            elseif mode=="SERAPHIM" then p.Color=Color3.fromRGB(255,223,0); p.Material=Enum.Material.Neon; p.Transparency=0.2; p.CastShadow=false
            elseif mode=="GLITCH ANOMALY" then p.Color=Color3.fromRGB(15,15,15); p.Material=Enum.Material.Neon; p.CastShadow=false
            elseif mode=="PUPPET" then p.Material=Enum.Material.Wood; p.Color=Color3.fromRGB(210,180,140); p.Transparency=0
            elseif mode=="ECLIPSE PULSE" then p.Material=Enum.Material.Neon; p.Color=Color3.fromRGB(0,0,0); p.CastShadow=false
            end
        end
    end

    CC.MODES = {
        {id="ICE",           label="ICE",           col=Color3.fromRGB( 78,172,255)},
        {id="GHOST",         label="GHOST",         col=Color3.fromRGB(155,150,255)},
        {id="SHADOW",        label="SHADOW",        col=Color3.fromRGB( 80,  0, 15)},
        {id="MAGMA",         label="MAGMA",         col=Color3.fromRGB(200, 50,  0)},
        {id="SLIME",         label="SLIME",         col=Color3.fromRGB( 50,220,100)},
        {id="SCRAP",         label="SCRAP",         col=Color3.fromRGB(150, 80, 50)},
        {id="MIDAS",         label="MIDAS",         col=Color3.fromRGB(255,190,  0)},
        {id="PLASMA",        label="PLASMA",        col=Color3.fromRGB(255, 50,200)},
        {id="DIAMOND",       label="DIAMOND",       col=Color3.fromRGB(100,255,255)},
        {id="NEBULA",        label="NEBULA",        col=Color3.fromRGB(120, 40,200)},
        {id="SERAPHIM",      label="SERAPHIM",      col=Color3.fromRGB(255,215,  0)},
        {id="GLITCH ANOMALY",label="GLITCH",        col=Color3.fromRGB(  0,255,255)},
        {id="PUPPET",        label="PUPPET",        col=Color3.fromRGB(210,180,140)},
        {id="ECLIPSE PULSE", label="ECLIPSE",       col=Color3.fromRGB( 20, 20, 20)},
        {id="NONE",          label="RESET",         col=Color3.fromRGB( 55, 55, 65)},
    }

    function CC.SetMode(id)
        MODE=id
        if loopConn then loopConn:Disconnect(); loopConn=nil end
        deepClean(); rebuildParts(); lastPulse=0
        if MODE~="NONE" then
            applyStatic(MODE); spawnEffects(MODE)
            if MODE=="MAGMA"          then createMagmaEmbers()  end
            if MODE=="SLIME"          then createSlimeCore()     end
            if MODE=="SCRAP"          then createScrapEye()      end
            if MODE=="SERAPHIM"       then createSeraphim()      end
            if MODE=="GLITCH ANOMALY" then createGlitchTrails()  end
            if MODE=="PUPPET"         then createPuppet()        end
        end
        -- OPTIMIZED: use Heartbeat with frame-skip for non-critical modes
        -- Only use RenderStepped for modes that need per-frame smooth animation
        local needsPerFrame = (MODE=="ICE" or MODE=="GHOST" or MODE=="MAGMA" or MODE=="DIAMOND" or MODE=="PLASMA" or MODE=="SERAPHIM" or MODE=="GLITCH ANOMALY" or MODE=="PUPPET" or MODE=="ECLIPSE PULSE")
        local frameSkip = 0
        loopConn = RunService[needsPerFrame and "RenderStepped" or "Heartbeat"]:Connect(function(dt)
            t=t+dt
            if MODE=="NONE" then return end
            -- For low-priority modes, skip every other frame
            if not needsPerFrame then frameSkip+=1; if frameSkip%2~=0 then return end end

            local root=char and char:FindFirstChild("HumanoidRootPart")
            local head=char and char:FindFirstChild("Head")

            if MODE=="ICE" then
                for _,pd in ipairs(cachedPartData) do
                    local p=pd.part; if not p or not p.Parent or p.Name=="Head" then continue end
                    if p.Material==Enum.Material.Glass then p.Transparency=math.clamp(0.2+math.sin(t*pd.bSpd*1.5+pd.bPhs)*0.15,0.1,0.4) end
                end
            elseif MODE=="GHOST" then
                if HLs.GHOST and HLs.GHOST.Parent then HLs.GHOST.OutlineTransparency=math.clamp(math.sin(t*1.2)*0.16,0,0.28); HLs.GHOST.FillTransparency=0.46+math.sin(t*0.65)*0.06 end
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent or p.Name=="Head" then continue end; p.Transparency=math.clamp(0.55+pd.seed*0.26+math.sin(t*pd.bSpd*0.85+pd.bPhs)*0.07,0.30,0.90) end
            elseif MODE=="SHADOW" then
                if HLs.SHADOW and HLs.SHADOW.Parent then HLs.SHADOW.OutlineTransparency=0.38+math.sin(t*0.9)*0.12 end
            elseif MODE=="MAGMA" then
                local lp=math.sin(t*1.8)*0.10
                if HLs.MAGMA and HLs.MAGMA.Parent then HLs.MAGMA.OutlineTransparency=math.clamp(0.30+lp*2,0.12,0.58); HLs.MAGMA.FillTransparency=math.clamp(0.76+lp,0.64,0.90); HLs.MAGMA.OutlineColor=Color3.fromRGB(255,math.floor(50+(lp*0.5+0.5)*120),0) end
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent then continue end; if p.Material==Enum.Material.Neon then p.Transparency=math.clamp(math.sin(t*pd.bSpd*1.3+pd.bPhs)*0.07+pd.seed*0.04,0,0.14); p.Color=Color3.fromRGB(255,math.floor((math.sin(t*pd.bSpd*0.9+pd.bPhs)*0.5+0.5)*80+30+pd.seed*40),0) end end
                for _,em in ipairs(magmaEmbers) do em.dot.BackgroundTransparency=math.clamp(math.sin(t*em.speed+em.phase)*0.48+0.35,0.04,0.88) end
            elseif MODE=="SLIME" then
                if slimeCores[1] then local pulse=1.1+math.sin(t*5)*0.2; slimeCores[1].core.Size=Vector3.new(pulse,pulse,pulse) end
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent then continue end; p.Transparency=math.clamp(0.45+math.sin(t*pd.bSpd+pd.bPhs)*0.08,0.3,0.6) end
            elseif MODE=="SCRAP" then
                if scrapEyes[1] then scrapEyes[1].eye.BackgroundTransparency=(math.random()>0.85) and math.random(2,8)/10 or 0 end
            elseif MODE=="MIDAS" then
                if HLs.MIDAS and HLs.MIDAS.Parent then HLs.MIDAS.OutlineTransparency=0.15+math.sin(t*2)*0.1 end
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent then continue end; if p.Material==Enum.Material.Metal then p.Reflectance=math.clamp(0.1+math.sin(t*pd.bSpd*0.8+pd.bPhs)*0.05,0.05,0.15) end end
            elseif MODE=="PLASMA" then
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent or p.Name=="Head" then continue end; p.Color=math.random()>0.95 and Color3.fromRGB(150,200,255) or Color3.fromRGB(255,50,200) end
            elseif MODE=="DIAMOND" then
                if HLs.DIAMOND and HLs.DIAMOND.Parent then HLs.DIAMOND.OutlineTransparency=math.clamp(math.sin(t*3)*0.1,0,0.1) end
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent then continue end; if p.Material==Enum.Material.Glass then p.Transparency=math.clamp(0.55+math.sin(t*pd.bSpd+pd.bPhs)*0.1,0.45,0.65) end end
            elseif MODE=="NEBULA" then
                if HLs.NEBULA and HLs.NEBULA.Parent then HLs.NEBULA.OutlineTransparency=0.1+math.sin(t*1.5)*0.1 end
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent then continue end; local cVal=math.floor((math.sin(t*0.5+pd.bPhs)*0.5+0.5)*50); p.Color=Color3.fromRGB(cVal,0,cVal+20) end
            elseif MODE=="SERAPHIM" then
                if root then for _,data in ipairs(seraphimRings) do if not data.part or not data.part.Parent then continue end; if data.isEye and head then local bob=math.sin(t*4)*0.5; data.part.CFrame=head.CFrame*CFrame.new(0,2.5+bob,0) else local spd=data.speed; data.part.CFrame=root.CFrame*CFrame.Angles(t*spd[1],t*spd[2],t*spd[3]) end end end
            elseif MODE=="GLITCH ANOMALY" then
                if root then for _,ld in ipairs(glitchTrails) do local idx=ld.layerIndex; local noiseX=math.noise(t*10*idx,0,0)*1.5; local noiseY=math.noise(0,t*10*idx,0)*1.5; local noiseZ=math.noise(0,0,t*10*idx)*1.5; local isF=math.random()>0.8; local offset=CFrame.new(noiseX,noiseY,noiseZ); for _,pd in ipairs(ld.parts) do if pd.real and pd.fake and pd.real.Parent then if isF then pd.fake.Transparency=1 else pd.fake.Transparency=0.5; pd.fake.CFrame=pd.real.CFrame:Lerp(pd.real.CFrame*offset,0.5) end end end end end
            elseif MODE=="PUPPET" then
                if root and puppetData.b1 and puppetData.b2 then local tp=root.Position+Vector3.new(0,18,0); local sX=math.sin(t*3)*0.4; local sZ=math.cos(t*2.5)*0.4; local rY=t*2; puppetData.b1.CFrame=puppetData.b1.CFrame:Lerp(CFrame.new(tp)*CFrame.Angles(sX,rY,sZ),0.2); puppetData.b2.CFrame=puppetData.b1.CFrame*CFrame.Angles(0,math.rad(90),0) end
            elseif MODE=="ECLIPSE PULSE" then
                local cycle=(math.sin(t*3.5)+1)/2; local pf=cycle^10
                for _,pd in ipairs(cachedPartData) do local p=pd.part; if not p or not p.Parent then continue end; if pf>0.5 then p.Transparency=0; p.Color=Color3.fromRGB(255,255,255) else p.Transparency=1-pf; p.Color=Color3.fromRGB(0,0,0) end end
                if pf>0.95 and root and t-lastPulse>1.8 then createDomainExpansion(root.Position); lastPulse=t end
            end
        end)
    end

    function CC.Reset() MODE="NONE"; if loopConn then loopConn:Disconnect(); loopConn=nil end; deepClean() end
    function CC.GetMode() return MODE end
    return CC
end

-- 📦 MODULE: Misc/PlayerESP
__modules["Misc/PlayerESP"] = function()
    local ZiliESP = {}
    local Players     = game:GetService("Players")
    local RunService  = game:GetService("RunService")
    local Camera      = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    ZiliESP.State = {
        Master=false, Box=true, Chams=true, Text=true,
        Health=true, Tracer=true, OffScreen=true, PlayerList=true,
        MaxDist=10000,
    }
    local State = ZiliESP.State

    local Palette = {
        Color3.fromRGB(255,255,255), Color3.fromRGB(255,85,85),
        Color3.fromRGB(85,255,85),   Color3.fromRGB(85,170,255),
        Color3.fromRGB(255,255,85),  Color3.fromRGB(170,85,255),
        Color3.fromRGB(255,140,40),  Color3.fromRGB(45,225,218),
    }
    ZiliESP.Colors = {Box=4,Chams=2,Name=1,HealthHigh=3,HealthLow=2,Tracer=4,Arrow=4}
    local CurrentColors = ZiliESP.Colors

    local screenGui, espStorage, listPanel
    local listRows    = {}
    local playerData  = {}
    local tracked     = {}
    local sortedCache = {}
    local MAX_ROWS    = 20
    local started     = false

    -- ── UI PARENT ────────────────────────────────────────
    local function GetUIParent()
        local p; pcall(function() p=(typeof(gethui)=="function" and gethui()) or game:GetService("CoreGui") end)
        if not p or not pcall(function() local _=p.Name end) then p=LocalPlayer:WaitForChild("PlayerGui",3) end
        return p
    end

    -- ── PLAYER LIST ──────────────────────────────────────
    local function BuildPlayerList()
        listPanel=Instance.new("Frame",screenGui); listPanel.Size=UDim2.new(0,200,0,20)
        listPanel.Position=UDim2.new(0,10,0,10); listPanel.BackgroundColor3=Color3.fromRGB(10,10,16)
        listPanel.BackgroundTransparency=0.15; listPanel.BorderSizePixel=0
        Instance.new("UICorner",listPanel).CornerRadius=UDim.new(0,8)
        local stroke=Instance.new("UIStroke",listPanel); stroke.Color=Color3.fromRGB(70,70,90); stroke.Thickness=1
        local ll=Instance.new("UIListLayout",listPanel); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,0); ll.FillDirection=Enum.FillDirection.Vertical
        local lp=Instance.new("UIPadding",listPanel); lp.PaddingLeft=UDim.new(0,10); lp.PaddingRight=UDim.new(0,10); lp.PaddingTop=UDim.new(0,8); lp.PaddingBottom=UDim.new(0,8)
        local header=Instance.new("Frame",listPanel); header.BackgroundTransparency=1; header.Size=UDim2.new(1,0,0,18); header.LayoutOrder=0
        local hl=Instance.new("UIListLayout",header); hl.FillDirection=Enum.FillDirection.Horizontal; hl.HorizontalAlignment=Enum.HorizontalAlignment.Left; hl.VerticalAlignment=Enum.VerticalAlignment.Center
        local hTitle=Instance.new("TextLabel",header); hTitle.BackgroundTransparency=1; hTitle.Size=UDim2.new(0.6,0,1,0); hTitle.Text="⚡ PLAYERS"; hTitle.TextColor3=Color3.fromRGB(180,180,210); hTitle.Font=Enum.Font.GothamBold; hTitle.TextSize=11; hTitle.TextXAlignment=Enum.TextXAlignment.Left
        local hDist=Instance.new("TextLabel",header); hDist.BackgroundTransparency=1; hDist.Size=UDim2.new(0.4,0,1,0); hDist.Text="DIST"; hDist.TextColor3=Color3.fromRGB(120,120,150); hDist.Font=Enum.Font.GothamBold; hDist.TextSize=10; hDist.TextXAlignment=Enum.TextXAlignment.Right
        local div=Instance.new("Frame",listPanel); div.Size=UDim2.new(1,0,0,1); div.BackgroundColor3=Color3.fromRGB(60,60,80); div.BorderSizePixel=0; div.LayoutOrder=1
        for i=1,MAX_ROWS do
            local row=Instance.new("Frame",listPanel); row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,16); row.LayoutOrder=i+1; row.Visible=false
            local rl=Instance.new("UIListLayout",row); rl.FillDirection=Enum.FillDirection.Horizontal; rl.HorizontalAlignment=Enum.HorizontalAlignment.Left; rl.VerticalAlignment=Enum.VerticalAlignment.Center
            local nameL=Instance.new("TextLabel",row); nameL.BackgroundTransparency=1; nameL.Size=UDim2.new(0.65,0,1,0); nameL.Font=Enum.Font.Gotham; nameL.TextSize=11; nameL.TextXAlignment=Enum.TextXAlignment.Left; nameL.Text=""
            local distL=Instance.new("TextLabel",row); distL.BackgroundTransparency=1; distL.Size=UDim2.new(0.35,0,1,0); distL.Font=Enum.Font.GothamBold; distL.TextSize=11; distL.TextXAlignment=Enum.TextXAlignment.Right; distL.Text=""
            listRows[i]={frame=row,nameL=nameL,distL=distL}
        end
    end

    local listTimer=0
    local function UpdatePlayerList()
        local count=0
        for name,data in pairs(playerData) do
            if data.alive then count+=1; sortedCache[count]={name=name,dist=data.dist} end
        end
        for i=count+1,#sortedCache do sortedCache[i]=nil end
        table.sort(sortedCache,function(a,b) return a.dist<b.dist end)
        listPanel.Visible=State.Master and State.PlayerList
        for i,row in ipairs(listRows) do
            local entry=sortedCache[i]
            if entry then
                local tv=math.clamp(entry.dist/400,0,1)
                local col=Color3.fromRGB(80,255,120):Lerp(Color3.fromRGB(255,110,80),tv)
                row.nameL.Text=entry.name:sub(1,15); row.nameL.TextColor3=col
                row.distL.Text=entry.dist.."m"; row.distL.TextColor3=Color3.fromRGB(180,180,200)
                row.frame.Visible=true
            else row.frame.Visible=false end
        end
        listPanel.Size=UDim2.new(0,200,0,35+math.min(count,MAX_ROWS)*16+8)
    end

    -- ── DRAWING UTILS ────────────────────────────────────
    local function newLine(col,thick)
        local l=Drawing.new("Line"); l.Thickness=thick or 1; l.Color=col; l.Transparency=1; l.Visible=false; return l
    end
    local function newText(size)
        local t=Drawing.new("Text"); t.Size=size or 13; t.Font=Drawing.Fonts.UI; t.Outline=true; t.Color=Color3.new(1,1,1); t.Visible=false; return t
    end
    local function newCornerBox()
        local lines={}; for i=1,8 do lines[i]=newLine(Color3.new(1,1,1),1.5) end
        local function update(x,y,w,h,col,vis)
            local s=6
            local corners={{x,y},{x+w,y},{x,y+h},{x+w,y+h}}
            local segs={{1,true,false},{1,false,true},{2,true,true},{2,false,false},{3,true,false},{3,false,true},{4,true,true},{4,false,false}}
            for i,seg in ipairs(segs) do
                local c=corners[seg[1]]; local l=lines[i]; l.Visible=vis; l.Color=col
                if seg[2] then -- horizontal
                    local dir=seg[3] and -1 or 1
                    l.From=Vector2.new(c[1],c[2]); l.To=Vector2.new(c[1]+dir*s,c[2])
                else -- vertical
                    local dir=seg[1]<=2 and 1 or -1
                    l.From=Vector2.new(c[1],c[2]); l.To=Vector2.new(c[1],c[2]+dir*s)
                end
            end
        end
        local function remove() for _,l in ipairs(lines) do l:Remove() end end
        return update,remove
    end

    local LIMBS={"HumanoidRootPart","UpperTorso","LowerTorso","Torso","Head","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"}
    local function GetScreenBox(char)
        local parts={}
        for _,name in ipairs(LIMBS) do local p=char:FindFirstChild(name); if p and p:IsA("BasePart") then parts[#parts+1]=p end end
        if #parts==0 then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then parts[#parts+1]=p end end end
        if #parts==0 then return false,0,0,0,0 end
        local pMinX,pMinY=math.huge,math.huge; local pMaxX,pMaxY=-math.huge,-math.huge; local onScreen=false
        for _,part in ipairs(parts) do
            local s=part.Size/2; local cf=part.CFrame
            for _,off in ipairs({Vector3.new(s.X,s.Y,s.Z),Vector3.new(-s.X,s.Y,s.Z),Vector3.new(s.X,-s.Y,s.Z),Vector3.new(-s.X,-s.Y,s.Z),Vector3.new(s.X,s.Y,-s.Z),Vector3.new(-s.X,s.Y,-s.Z),Vector3.new(s.X,-s.Y,-s.Z),Vector3.new(-s.X,-s.Y,-s.Z)}) do
                local wp=cf*off; local sp,vis=Camera:WorldToViewportPoint(wp)
                if vis and sp.Z>0 then onScreen=true; pMinX=math.min(pMinX,sp.X); pMinY=math.min(pMinY,sp.Y); pMaxX=math.max(pMaxX,sp.X); pMaxY=math.max(pMaxY,sp.Y) end
            end
        end
        if not onScreen then return false,0,0,0,0 end
        return true,pMinX,pMinY,pMaxX-pMinX,pMaxY-pMinY
    end

    local ARROW_PADDING,ARROW_SIZE=40,10
    local function newArrow()
        local lines={newLine(Color3.new(1,1,1),1.5),newLine(Color3.new(1,1,1),1.5),newLine(Color3.new(1,1,1),1.5)}; local txt=newText(10)
        local function update(worldPos,col,dist,vis)
            lines[1].Visible=vis; lines[2].Visible=vis; lines[3].Visible=vis; txt.Visible=vis
            if not vis then return end
            local vp=Camera.ViewportSize; local center=Vector2.new(vp.X/2,vp.Y/2)
            local p3,_=Camera:WorldToViewportPoint(worldPos); local sp=Vector2.new(p3.X,p3.Y)
            if p3.Z<0 then sp=center+(center-sp) end
            local dir=(sp-center).Unit; local angle=math.atan2(dir.Y,dir.X); local cos_a=math.cos(angle); local sin_a=math.sin(angle)
            local scale=math.min(math.abs(cos_a)>0.001 and (vp.X/2-ARROW_PADDING)/math.abs(cos_a) or math.huge, math.abs(sin_a)>0.001 and (vp.Y/2-ARROW_PADDING)/math.abs(sin_a) or math.huge)
            local tip=center+Vector2.new(cos_a,sin_a)*scale; local perp=Vector2.new(-sin_a,cos_a); local base=tip-Vector2.new(cos_a,sin_a)*(ARROW_SIZE*1.6)
            local p1=base+perp*ARROW_SIZE; local p2=base-perp*ARROW_SIZE
            lines[1].From=tip; lines[1].To=p1; lines[1].Color=col; lines[2].From=tip; lines[2].To=p2; lines[2].Color=col; lines[3].From=p1; lines[3].To=p2; lines[3].Color=col
            txt.Text=dist.."m"; txt.Color=col; txt.Position=tip+Vector2.new(cos_a,sin_a)*14
        end
        local function remove() for _,l in ipairs(lines) do l:Remove() end; txt:Remove() end
        return update,remove
    end

    -- ── OPTIMIZED ESP ENGINE ─────────────────────────────
    -- FPS optimization: throttle updates to every 2 frames via frame counter
    local frameCount = 0
    local function CreateESP(model)
        if model.Name==LocalPlayer.Name then return end
        task.spawn(function()
            local hum=model:WaitForChild("Humanoid",5); if not hum then return end
            playerData[model.Name]={dist=9999,alive=true}

            local chams=Instance.new("Highlight",espStorage); chams.Adornee=model
            chams.FillTransparency=0.5; chams.OutlineTransparency=0.2
            chams.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; chams.Enabled=false

            local updateBox,removeBox=newCornerBox()
            local updateArrow,removeArrow=newArrow()
            local hpBg=newLine(Color3.fromRGB(0,0,0),4); local hpFill=newLine(Color3.fromRGB(85,255,85),4)
            local hpPct=newText(9); local nameText=newText(13); local tracer=newLine(Palette[CurrentColors.Tracer],1)

            local function hideAll()
                chams.Enabled=false; updateBox(0,0,0,0,Color3.new(),false); updateArrow(Vector3.new(),Color3.new(),0,false)
                hpBg.Visible=false; hpFill.Visible=false; hpPct.Visible=false; nameText.Visible=false; tracer.Visible=false
            end
            local function cleanup()
                playerData[model.Name]=nil; chams:Destroy(); removeBox(); removeArrow()
                hpBg:Remove(); hpFill:Remove(); hpPct:Remove(); nameText:Remove(); tracer:Remove()
            end

            local conn,ancestryConn
            ancestryConn=model.AncestryChanged:Connect(function()
                if not model.Parent then hideAll(); cleanup(); pcall(function()conn:Disconnect()end); ancestryConn:Disconnect() end
            end)

            -- OPTIMIZED: Use Heartbeat + skip every other frame for box/text calcs
            -- Chams update every frame is fine (GPU-only), but Drawing calls are expensive
            local localFrameSkip=0
            conn=RunService.Heartbeat:Connect(function()
                local hrp=model:FindFirstChild("HumanoidRootPart")
                if not model.Parent or hum.Health<=0 or not hrp then
                    hideAll(); cleanup(); conn:Disconnect(); ancestryConn:Disconnect(); return
                end
                local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist=myHRP and math.floor((hrp.Position-myHRP.Position).Magnitude) or 0
                playerData[model.Name]={dist=dist,alive=true}

                -- Always update chams (cheap)
                if not State.Master or dist>State.MaxDist then hideAll(); return end
                chams.Enabled=State.Chams; chams.FillColor=Palette[CurrentColors.Chams]; chams.OutlineColor=Palette[CurrentColors.Chams]

                -- Throttle expensive Drawing updates to every 2 frames
                localFrameSkip+=1; if localFrameSkip%2~=0 then return end

                local onScreen,bx,by,bw,bh=GetScreenBox(model)
                local boxCol=Palette[CurrentColors.Box]; local arrowCol=Palette[CurrentColors.Arrow or CurrentColors.Box]
                local ls=math.clamp(math.floor(State._labelSize or 13),8,32)
                if onScreen and bw>0 and bh>0 then
                    updateArrow(hrp.Position,arrowCol,dist,false)
                    updateBox(bx,by,bw,bh,boxCol,State.Box)
                    local pct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                    local col=Palette[CurrentColors.HealthLow]:Lerp(Palette[CurrentColors.HealthHigh],pct)
                    local barX=bx-7
                    hpBg.Visible=State.Health; hpBg.From=Vector2.new(barX,by); hpBg.To=Vector2.new(barX,by+bh); hpBg.Color=Color3.fromRGB(0,0,0)
                    hpFill.Visible=State.Health; hpFill.From=Vector2.new(barX,by+bh); hpFill.To=Vector2.new(barX,by+bh-bh*pct); hpFill.Color=col
                    hpPct.Visible=State.Health; hpPct.Size=math.max(8,math.floor(ls*0.7)); hpPct.Text=math.floor(pct*100).."%"; hpPct.Color=col; hpPct.Position=Vector2.new(barX-2,by-14)
                    nameText.Visible=State.Text; nameText.Size=ls; nameText.Text=model.Name.."  •  "..dist.."m"; nameText.Color=Palette[CurrentColors.Name]; nameText.Position=Vector2.new(bx+bw/2,by-ls-4)
                    tracer.Visible=State.Tracer; tracer.Color=Palette[CurrentColors.Tracer]; tracer.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y); tracer.To=Vector2.new(bx+bw/2,by+bh)
                else
                    updateBox(0,0,0,0,Color3.new(),false); hpBg.Visible=false; hpFill.Visible=false; hpPct.Visible=false; nameText.Visible=false; tracer.Visible=false
                    updateArrow(hrp.Position,arrowCol,dist,State.OffScreen)
                end
            end)
        end)
    end

    local function TryESP(model)
        if not model or not model:IsA("Model") then return end
        if model.Name==LocalPlayer.Name then return end
        if tracked[model.Name] then return end
        tracked[model.Name]=true; CreateESP(model)
    end
    local function HookPlayer(player)
        if player==LocalPlayer then return end
        if player.Character then TryESP(player.Character) end
        player.CharacterAdded:Connect(function(ch) tracked[player.Name]=nil; task.wait(1); TryESP(ch) end)
    end

    function ZiliESP.Start()
        if started then return end; started=true
        local uiParent=GetUIParent()
        local old=uiParent:FindFirstChild("ZiliESP_Module"); if old then old:Destroy() end
        screenGui=Instance.new("ScreenGui",uiParent); screenGui.Name="ZiliESP_Module"; screenGui.ResetOnSpawn=false
        espStorage=Instance.new("Folder",screenGui); espStorage.Name="ESP_Storage"
        BuildPlayerList()
        -- Player list: every 0.2s on Heartbeat (very cheap)
        RunService.Heartbeat:Connect(function(dt) listTimer+=dt; if listTimer>=0.2 then listTimer=0; UpdatePlayerList() end end)
        for _,p in ipairs(Players:GetPlayers()) do task.spawn(HookPlayer,p) end
        Players.PlayerAdded:Connect(HookPlayer)
        Players.PlayerRemoving:Connect(function(p) tracked[p.Name]=nil; playerData[p.Name]=nil end)
    end

    function ZiliESP.Stop()
        if screenGui then screenGui:Destroy() end
        started=false; tracked={}; playerData={}; sortedCache={}
    end

    -- Compatibility shims (used by UI code)
    function ZiliESP.GetState()    return State end
    function ZiliESP.GetPalette()  return Palette end
    function ZiliESP.GetCurrentColors() return CurrentColors end
    function ZiliESP.SetColor(key,idx) CurrentColors[key]=idx end
    function ZiliESP.Toggle(key,val) State[key]=val end
    function ZiliESP.SetMaxDist(v) State.MaxDist=math.max(0,v) end
    return ZiliESP
end

__modules["Farm/AutoFarmGun"] = function()
    local AutoFarmGun = {}

    local cloneref = cloneref or function(o) return o end

    local Players          = cloneref(game:GetService("Players"))
    local RunService       = cloneref(game:GetService("RunService"))
    local ReplicatedStorage= cloneref(game:GetService("ReplicatedStorage"))
    local Workspace        = cloneref(game:GetService("Workspace"))
    local VirtualUser      = cloneref(game:GetService("VirtualUser"))

    local Player       = Players.LocalPlayer
    local Events       = ReplicatedStorage:WaitForChild("Events")
    local CombatRegister   = Events:WaitForChild("CombatRegister")
    local QuestEvent       = Events:WaitForChild("Quest")
    local ShopEvent        = Events:WaitForChild("Shop")
    local ToolsEvent       = Events:WaitForChild("Tools")
    local TakestamEvent    = Events:WaitForChild("takestam")
    local SetSpawnEvent    = Events:WaitForChild("SetSpawn")
    local GunManager       = Events:WaitForChild("GunManager")
    local gunFunctions     = GunManager:WaitForChild("gunFunctions")

    local StatsFolder  = ReplicatedStorage:WaitForChild("Stats" .. Player.Name)
    local Peli         = StatsFolder.Stats:WaitForChild("Peli")
    local Level        = StatsFolder.Stats:WaitForChild("Level")
    local SpawnPoint   = StatsFolder.Stats:WaitForChild("SpawnPoint")
    local CurrentQuest = StatsFolder:WaitForChild("Quest"):WaitForChild("CurrentQuest")

    -- ==========================================
    -- 🗺️ TỌA ĐỘ (WAYPOINTS)
    -- ==========================================
    local QuestGiverBandit   = CFrame.new(-577.66, 5.84, -3431.78)
    local ShopRiflePos       = Vector3.new(-530.6, 5.94, -3449.26)
    local QuestGiverFishman  = CFrame.new(7735.64, -2175.84, -17223.24)
    local FishmanPortalEnter = Vector3.new(1791.87, -94.83, -12327.67)
    local FishmanSetSpawnPos = Vector3.new(7975.97, -2152.84, -17073.7)
    local FishmanFarmPos     = Vector3.new(7818.29, -2159.84, -17124.93)

    -- ==========================================
    -- ⚙️ CONFIG (chia sẻ qua _G để UI bên ngoài có thể ghi)
    -- ==========================================
    getgenv().HitDelay     = getgenv().HitDelay    or 0.366
    getgenv().ComboDelay   = getgenv().ComboDelay  or 1
    getgenv().FarmDistance = getgenv().FarmDistance or 8.5
    getgenv().ShootDelay   = getgenv().ShootDelay  or 0.25
    getgenv().ReloadDelay  = getgenv().ReloadDelay or 1.25

    local VEC_ZERO        = Vector3.new(0, 0, 0)
    local OFFSET_FAKEFLOOR= CFrame.new(0, -3.05, 0)

    local _active  = false
    local _conn    = nil
    local IslandTween

    -- ==========================================
    -- 🧹 PHYSICS HELPERS
    -- ==========================================
    local function GetGlobalVelocity()
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil, nil end
        local attach = root:FindFirstChild("GlobalAttach") or Instance.new("Attachment", root)
        attach.Name  = "GlobalAttach"
        local lv     = root:FindFirstChild("GlobalVelocity") or Instance.new("LinearVelocity", root)
        lv.Name          = "GlobalVelocity"
        lv.Attachment0   = attach
        lv.MaxForce      = math.huge
        return lv, root
    end

    local function ResetPhysics()
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, v in ipairs(root:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("LinearVelocity")
                   or v.Name == "GlobalAttach" or v.Name == "ZILI_AntiGravity" then
                    v:Destroy()
                end
            end
            root.Velocity               = VEC_ZERO
            root.RotVelocity            = VEC_ZERO
            root.AssemblyLinearVelocity = VEC_ZERO
        end
    end

    -- ==========================================
    -- 🏃 NOCLIP CACHE
    -- ==========================================
    local charParts = {}
    local function updateCharParts(char)
        table.clear(charParts)
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(charParts, v) end
        end
    end
    Player.CharacterAdded:Connect(function(char)
        char.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") then table.insert(charParts, v) end
        end)
        updateCharParts(char)
    end)
    Player.CharacterRemoving:Connect(function() table.clear(charParts) end)
    if Player.Character then updateCharParts(Player.Character) end

    RunService.Stepped:Connect(function()
        if _active then
            for _, part in ipairs(charParts) do
                if part.CanCollide then part.CanCollide = false end
            end
        end
    end)

    -- ==========================================
    -- 🛡️ ANTI-AFK & ANTI-SIT
    -- ==========================================
    pcall(function()
        for _, conn in ipairs(getconnections(Player.Idled)) do conn:Disable() end
    end)
    if ZiliState.AntiAfkConnection then ZiliState.AntiAfkConnection:Disconnect() end
    ZiliState.AntiAfkConnection = Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    local function PreventSitting(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if humanoid.Sit then humanoid.Sit = false; humanoid.Jump = true end
        end
    end
    if Player.Character then PreventSitting(Player.Character) end
    Player.CharacterAdded:Connect(PreventSitting)

    -- =====================================================================
    -- 📦 MODULE NỘI BỘ: IslandTween
    -- =====================================================================
    local function LoadIslandTweenModule()
        local Tween    = {}
        local MAX_SPEED= 90
        Tween.IsTeleporting = false
        Tween.MoveConn      = nil
        Tween.FakeFloor     = nil

        local isFlicking = false

        local function getRoot()
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                return char.HumanoidRootPart
            end
            return nil
        end

        local function StartSimpleFlickTimer()
            task.spawn(function()
                local timer = 0
                while Tween.IsTeleporting do
                    task.wait(1)
                    if not isFlicking then
                        local root = getRoot()
                        if root and root.Position.Y < -20 and root.Position.Y > -500 then
                            timer = timer + 1
                            if timer >= 20 then
                                isFlicking = true
                                local cf = root.CFrame
                                root.CFrame = CFrame.new(cf.X, 7.33, cf.Z)
                                root.Velocity = VEC_ZERO
                                task.wait(0.5)
                                root.CFrame = cf
                                timer = 0
                                isFlicking = false
                            end
                        else
                            timer = 0
                        end
                    end
                end
            end)
        end

        local TakeStam_Internal = Events:WaitForChild("takestam", 5)

        local isSpoofingStamina = false
        local function StartStaminaSpoof()
            if isSpoofingStamina then return end
            isSpoofingStamina = true
            task.spawn(function()
                while isSpoofingStamina and task.wait(0.05) do
                    if TakeStam_Internal and TakeStam_Internal.Parent then
                        pcall(function()
                            local root = getRoot()
                            local currentCF = root and root.CFrame or CFrame.new()
                            TakeStam_Internal:FireServer(0.505, "dash", currentCF)
                        end)
                    else break end
                end
            end)
        end

        function Tween.Stop()
            Tween.IsTeleporting = false
            isFlicking          = false
            isSpoofingStamina   = false
            if Tween.MoveConn then Tween.MoveConn:Disconnect(); Tween.MoveConn = nil end
            local root = getRoot()
            if root then
                for _, v in pairs(root:GetChildren()) do
                    if v.Name == "ZILI_AntiGravity" then v:Destroy() end
                end
                root.Velocity = VEC_ZERO
            end
            if Tween.FakeFloor then Tween.FakeFloor:Destroy(); Tween.FakeFloor = nil end
        end

        function Tween.Start(targetData)
            Tween.Stop()
            Tween.IsTeleporting = true
            StartStaminaSpoof()
            StartSimpleFlickTimer()

            local route     = {}
            local finalDest = type(targetData) == "table" and targetData[#targetData] or targetData
            local initialRoot = getRoot()
            if not initialRoot then return end

            local function isPortalPos(pos) return pos.Y < -20 and pos.Y > -500 end

            if initialRoot.Position.Y > -1000 and finalDest.Y < -1000 then
                table.insert(route, { pos = FishmanPortalEnter, isPortal = true, isFishmanIn = true, isFishmanExit = false })
            end
            if initialRoot.Position.Y < -1000 and finalDest.Y > -1000 then
                table.insert(route, { pos = Vector3.new(8585.12, -2138.84, -17087.38), isPortal = true, isFishmanIn = false, isFishmanExit = true })
            end

            if type(targetData) == "table" then
                for i, pos in ipairs(targetData) do
                    table.insert(route, { pos = pos, isPortal = (i < #targetData) or isPortalPos(pos), isFishmanIn = false, isFishmanExit = false })
                end
            else
                table.insert(route, { pos = targetData, isPortal = isPortalPos(targetData), isFishmanIn = false, isFishmanExit = false })
            end

            local function flyTo(stepData, onComplete)
                local root = getRoot()
                local waitTime = 0
                while not root and waitTime < 10 do
                    task.wait(0.5); waitTime = waitTime + 0.5; root = getRoot()
                end
                if not Tween.IsTeleporting or not root then Tween.Stop(); return end

                if not Tween.FakeFloor then
                    Tween.FakeFloor            = Instance.new("Part")
                    Tween.FakeFloor.Name       = "ZILI_FakeFloor"
                    Tween.FakeFloor.Size       = Vector3.new(15, 2, 15)
                    Tween.FakeFloor.Anchored   = true
                    Tween.FakeFloor.Transparency = 1
                    Tween.FakeFloor.Parent     = Workspace
                end

                local antiGravity = root:FindFirstChild("ZILI_AntiGravity") or Instance.new("BodyVelocity")
                antiGravity.Name      = "ZILI_AntiGravity"
                antiGravity.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
                antiGravity.Velocity  = VEC_ZERO
                antiGravity.Parent    = root

                local targetPos = stepData.pos

                Tween.MoveConn = RunService.Heartbeat:Connect(function(deltaTime)
                    if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end
                    if isFlicking then return end

                    if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                    root.Velocity = VEC_ZERO

                    local currentPos = root.Position
                    local distXZ     = (Vector2.new(targetPos.X, targetPos.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude
                    local max_step   = math.min(MAX_SPEED * deltaTime, 120)

                    -- Dive xuống -97.15 chỉ khi cả 2 đầu ở mặt trên
                    if targetPos.Y > -1000 and currentPos.Y > -1000 then
                        if math.abs(currentPos.Y - (-97.15)) > 10 and distXZ > 30 then
                            Tween.MoveConn:Disconnect()
                            task.spawn(function()
                                if TakeStam_Internal then pcall(function() TakeStam_Internal:FireServer(0.505, "dash", root.CFrame) end) end
                                task.wait(0.1)
                                root.CFrame = CFrame.new(currentPos.X, -97.15, currentPos.Z)
                                task.wait(0.2)
                                flyTo(stepData, onComplete)
                            end)
                            return
                        end
                    end

                    if distXZ < 30 then
                        Tween.MoveConn:Disconnect()
                        task.spawn(function()
                            local waited = 0
                            if stepData.isFishmanExit then
                                root.CFrame = CFrame.lookAt(root.Position, targetPos)
                                task.wait(0.1)
                                while waited < 20 do
                                    if not Tween.IsTeleporting or not root or (root.Position - targetPos).Magnitude > 300 then break end
                                    root.CFrame = root.CFrame * CFrame.new(0, 0, -3)
                                    if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                    task.wait(0.15); waited = waited + 0.15
                                end
                            elseif stepData.isPortal or stepData.isFishmanIn then
                                local toggle = 1
                                while waited < 20 do
                                    if not Tween.IsTeleporting or not root then break end
                                    if (root.Position - targetPos).Magnitude > 300 then task.wait(4); break end
                                    root.CFrame = CFrame.new(targetPos.X + toggle, targetPos.Y, targetPos.Z + toggle)
                                    if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                    toggle = (toggle == 1) and -1 or 1
                                    task.wait(0.3); waited = waited + 0.3
                                end
                                task.wait(1.5)
                            else
                                if TakeStam_Internal then pcall(function() TakeStam_Internal:FireServer(0.505, "dash", root.CFrame) end) end
                                task.wait(0.1)
                                root.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                task.wait(0.2)
                            end
                            if onComplete then onComplete() end
                        end)
                    else
                        local activeY      = (currentPos.Y > -1000 and targetPos.Y > -1000) and -97.15 or targetPos.Y
                        local activeTarget = Vector3.new(targetPos.X, activeY, targetPos.Z)
                        local dir          = (activeTarget - currentPos).Unit
                        root.CFrame        = CFrame.new(currentPos + dir * math.min(max_step, (activeTarget - currentPos).Magnitude))
                    end
                end)
            end

            local function processRoute(index)
                if not Tween.IsTeleporting then return end
                if index > #route then Tween.Stop(); return end
                flyTo(route[index], function() processRoute(index + 1) end)
            end
            processRoute(1)
        end

        return Tween
    end

    IslandTween = LoadIslandTweenModule()

    -- ==========================================
    -- ⚡ TWEEN COMBAT
    -- ==========================================
    local function tween_combat(targetCFrame, actionType)
        local lv, root = GetGlobalVelocity()
        if not root then return false end

        if IslandTween.IsTeleporting then IslandTween.Stop() end

        if not ZiliState.LastStaminaTween or tick() - ZiliState.LastStaminaTween >= 0.05 then
            ZiliState.LastStaminaTween = tick()
            pcall(function() TakestamEvent:FireServer(0.505, "dash", root.CFrame) end)
        end

        local finalPos = targetCFrame.Position
        if actionType == "Farm" then finalPos = finalPos + Vector3.new(0, getgenv().FarmDistance, 0) end

        local dist = (finalPos - root.Position).Magnitude
        local dir  = (dist > 0) and (finalPos - root.Position).Unit or VEC_ZERO

        if dist > 2 then
            lv.VectorVelocity = dir * 60
            root.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(dir.X, 0, dir.Z))
            return false
        else
            lv.VectorVelocity = VEC_ZERO
            if actionType == "Farm" then
                root.CFrame = CFrame.new(root.Position, Vector3.new(targetCFrame.Position.X, root.Position.Y, targetCFrame.Position.Z))
            else
                root.CFrame = targetCFrame
            end
            return true
        end
    end

    -- ==========================================
    -- 🎯 RADAR
    -- ==========================================
    local currentTarget, cachedNPCFolder = nil, nil

    local function GetClosestMob(mobName)
        local char = Player.Character
        if not char or not char.PrimaryPart then return nil end
        local charPos = char.PrimaryPart.Position

        if currentTarget and currentTarget.Parent then
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local hum = currentTarget:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 and (hrp.Position - charPos).Magnitude < 3000 then
                return currentTarget
            end
        end

        if not cachedNPCFolder or cachedNPCFolder.Parent == nil then
            cachedNPCFolder = workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("Enemies")
        end

        local closestMob, shortestDist = nil, math.huge
        if cachedNPCFolder then
            for _, npc in ipairs(cachedNPCFolder:GetChildren()) do
                if not mobName or string.find(npc.Name, mobName) then
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    local hum = npc:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local dist = (hrp.Position - charPos).Magnitude
                        if dist < shortestDist then shortestDist = dist; closestMob = npc end
                    end
                end
            end
        end
        currentTarget = closestMob
        return closestMob
    end

    -- ==========================================
    -- 🔫 GUN LOOPS (ĐÃ FIX AUTO CLICK)
    -- ==========================================
    local cachedGunCast = nil
    local function getGunCast()
        if cachedGunCast and cachedGunCast.Parent ~= nil then return cachedGunCast end
        for _, v in ipairs(getnilinstances()) do
            if v.ClassName == "RemoteEvent" and v.Name == "guncast" then
                cachedGunCast = v; return v
            end
        end
        return nil
    end

    task.spawn(function()
        while true do
            task.wait(getgenv().ShootDelay)
            if _active and Player.Character then
                local tool = Player.Character:FindFirstChildWhichIsA("Tool")
                if tool and (tool.Name == "Rifle" or tool:FindFirstChild("GunSettings")) then
                    local mob = GetClosestMob("Fishman Karate User")
                    if mob then
                        local head = mob:FindFirstChild("Head")
                        if head then
                            local gc = getGunCast()
                            if gc then
                                pcall(function() gc:FireServer(head.Position, head, 0.064) end)
                            else
                                -- Mô phỏng click để mồi súng tự kích hoạt
                                pcall(function() tool:Activate() end)
                            end
                            -- Tách damage để gọi liên tục
                            pcall(function()
                                GunManager:FireServer("fire", {
                                    ["Start"]    = CFrame.new(head.Position + Vector3.new(0, 5, 0)),
                                    ["Gun"]      = tool.Name,
                                    ["joe"]      = "true",
                                    ["Position"] = head.Position,
                                })
                            end)
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(getgenv().ReloadDelay)
            if _active and Player.Character then
                local tool = Player.Character:FindFirstChildWhichIsA("Tool")
                if tool and (tool.Name == "Rifle" or tool:FindFirstChild("GunSettings")) then
                    task.spawn(function()
                        pcall(function() gunFunctions:InvokeServer("reload", { ["Gun"] = tool.Name }) end)
                    end)
                end
            end
        end
    end)

    -- ==========================================
    -- 🗡️ VÒNG LẶP CHÍNH
    -- ==========================================
    local function AutoEquip()
        local char = Player.Character; if not char then return end
        local hum  = char:FindFirstChild("Humanoid"); if not hum then return end
        local rifle = Player.Backpack:FindFirstChild("Rifle")
        if rifle then
            hum:EquipTool(rifle)
        elseif not char:FindFirstChild("Rifle") then
            local melee = Player.Backpack:FindFirstChild("Melee")
            if melee then hum:EquipTool(melee) end
        end
    end

    local function mainLoop()
        local lastHitTime      = tick()
        local comboCount       = 1
        local currentWaitDelay = getgenv().HitDelay

        while true do
            task.wait(0.05)
            if not _active then continue end

            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            AutoEquip()
            local hasRifle = Player.Backpack:FindFirstChild("Rifle") or char:FindFirstChild("Rifle")

            if not hasRifle then
                if Peli.Value >= 300 then
                    if tween_combat(CFrame.new(ShopRiflePos), "BuyGun") then
                        ShopEvent:InvokeServer(workspace:WaitForChild("BuyableItems"):WaitForChild("Rifle"), 1)
                        task.wait(0.5)
                        ToolsEvent:InvokeServer("equip", "Rifle")
                    end
                else
                    if CurrentQuest.Value == "None" or CurrentQuest.Value == "" then
                        if tween_combat(QuestGiverBandit, "Quest") then
                            QuestEvent:InvokeServer({ "takequest", "Help Daph" })
                            task.wait(1)
                        end
                    else
                        local mob = GetClosestMob("Bandit")
                        if mob and mob:FindFirstChild("HumanoidRootPart") then
                            if tween_combat(mob.HumanoidRootPart.CFrame, "Farm") then
                                if tick() - lastHitTime >= currentWaitDelay then
                                    lastHitTime = tick()
                                    local anim = ReplicatedStorage:WaitForChild("CombatAnimations"):WaitForChild("Melee"):FindFirstChild("Punch" .. comboCount)
                                    task.spawn(function() pcall(function() CombatRegister:InvokeServer({ "swingsfx", "Melee", comboCount, "Ground", false, anim, 2, 1.5 }) end) end)
                                    task.spawn(function() pcall(function() CombatRegister:InvokeServer({ "damage", { mob.HumanoidRootPart }, "Melee", { comboCount, "Ground", "Melee" }, true, root.CFrame, aircombo = "Ground" }) end) end)
                                    comboCount = (comboCount >= 4) and 1 or (comboCount + 1)
                                    currentWaitDelay = (comboCount == 1) and getgenv().ComboDelay or getgenv().HitDelay
                                end
                            end
                        end
                    end
                end
            else
                -- Hủy quest rác khi vừa xuống đảo
                local currentQ = tostring(CurrentQuest.Value)
                if currentQ ~= "None" and currentQ ~= "" then
                    if (Level.Value < 190) or (Level.Value >= 190 and currentQ ~= "Help becky") then
                        pcall(function() QuestEvent:InvokeServer(unpack({ { [1] = "quit" } })) end)
                        task.wait(0.5)
                    end
                end

                -- Đi set spawn Fishman nếu chưa set
                local currentSpawnStr = string.lower(tostring(SpawnPoint.Value))
                if not string.find(currentSpawnStr, "fishman") then
                    if (root.Position - FishmanSetSpawnPos).Magnitude > 15 then
                        if not IslandTween.IsTeleporting then IslandTween.Start(FishmanSetSpawnPos) end
                    else
                        if tween_combat(CFrame.new(FishmanSetSpawnPos), "SetSpawn") then
                            task.wait(4)
                            pcall(function() SetSpawnEvent:FireServer() end)
                        end
                    end
                    continue
                end

                -- Farm
                if Level.Value < 190 then
                    tween_combat(CFrame.new(FishmanFarmPos), "Move")
                else
                    if CurrentQuest.Value == "None" or CurrentQuest.Value == "" then
                        if tween_combat(QuestGiverFishman, "Quest") then
                            QuestEvent:InvokeServer({ "takequest", "Help becky" })
                            task.wait(1)
                        end
                    else
                        tween_combat(CFrame.new(FishmanFarmPos), "Move")
                    end
                end
            end
        end
    end

    -- ==========================================
    -- 🔌 PUBLIC API
    -- ==========================================
    function AutoFarmGun.Toggle(state)
        _active = state
        if state then
            -- Khởi động vòng lặp chính nếu chưa chạy
            if not _conn then
                _conn = task.spawn(mainLoop)
            end
        else
            -- Dừng IslandTween và reset vật lý khi tắt
            if IslandTween and IslandTween.IsTeleporting then IslandTween.Stop() end
            ResetPhysics()
            -- _conn là coroutine task.spawn, không có :Disconnect()
            -- _active = false sẽ khiến mainLoop tự skip qua continue
        end
    end

    function AutoFarmGun.IsActive()
        return _active
    end
    return AutoFarmGun
end

-- 📦 MODULE: Stats/addStats
__modules["Stats/addStats"] = function()
    local addStats = {}
    
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")

    -- [HELPER]: Chuẩn hóa tên stat để gửi lên server (xóa dấu cách)
    local function CleanStatName(statName)
        return statName:gsub("%s+", "")
    end

    function addStats.Start(AutoStatsData)
        
        local function GetCurrentStat(statName)
            local val = 0
            local cleanName = CleanStatName(statName)
            
            pcall(function()
                local repStats = game:GetService("ReplicatedStorage"):FindFirstChild("Stats" .. Players.LocalPlayer.Name)
                if repStats then
                    local innerStats = repStats:FindFirstChild("Stats")
                    if innerStats then
                        if innerStats:FindFirstChild(statName) then
                            val = tonumber(innerStats[statName].Value)
                        elseif innerStats:FindFirstChild(cleanName) then
                            val = tonumber(innerStats[cleanName].Value)
                        end
                    end
                    
                    if not val or val == 0 then
                        if repStats:FindFirstChild(statName) then
                            val = tonumber(repStats[statName].Value)
                        elseif repStats:FindFirstChild(cleanName) then
                            val = tonumber(repStats[cleanName].Value)
                        end
                    end
                end
                
                if not val or val == 0 then
                    local ls = Players.LocalPlayer:FindFirstChild("leaderstats")
                    if ls then
                        if ls:FindFirstChild(statName) then 
                            val = tonumber(ls[statName].Value)
                        elseif ls:FindFirstChild(cleanName) then 
                            val = tonumber(ls[cleanName].Value) 
                        end
                    end
                end
            end)
            return val or 0
        end

        task.spawn(function()
            local rep = game:GetService("ReplicatedStorage")
            local statsEvent = rep:FindFirstChild("Events") and rep.Events:FindFirstChild("stats")
            
            while true do
                if statsEvent then
                    for statName, data in pairs(AutoStatsData) do
                        if data.Active then
                            local currentStat = GetCurrentStat(statName)
                            -- ✅ FIX: Dùng cleanName khi gửi lên server
                            local serverName = CleanStatName(statName)
                            
                            if data.Cap == 0 or currentStat < data.Cap then
                                pcall(function()
                                    -- ✅ Gửi "SwordMastery" thay vì "Sword Mastery"
                                    statsEvent:FireServer(serverName, nil, 1)
                                end)
                                
                                if data.Btn then
                                    local capText = data.Cap > 0 and tostring(data.Cap) or "Max"
                                    data.Btn.Text = "(" .. tostring(currentStat) .. "/" .. capText .. ")"
                                end
                            else
                                data.Active = false
                                if data.Btn and data.Strk then
                                    TweenService:Create(data.Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 90, 0)}):Play()
                                    TweenService:Create(data.Strk, TweenInfo.new(0.2), {Color = Color3.fromRGB(160, 120, 0)}):Play()
                                    data.Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    data.Btn.Text = "Auto Add"
                                end
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end

    return addStats
end

-- =====================================================================
-- GET BETTER OUT | MAIN HUB  (Optimized Build v2.9.0)
-- =====================================================================

-- =====================================================================
-- _initUI: wraps all UI construction to free 192 main-chunk locals
-- =====================================================================
local function _initUI()
local LOGO_ASSET_ID = "rbxassetid://72585475577182"
-- =====================================================================
-- PLACE DETECTION  (must run before all requires)
-- =====================================================================
local PLACE_LOBBY    = 1730877806
local IS_LOBBY

if PLACE_LOBBY ~= 0 then
    IS_LOBBY = (game.PlaceId == PLACE_LOBBY)
else
    IS_LOBBY = (game:GetService("ReplicatedStorage"):FindFirstChild("Fishing") == nil)
end

-- =====================================================================
-- REQUIRES
-- =====================================================================
local Bypass, Esp, TweenSys, IslandData
local AutoFarmLevel, AutoGetBuso, AutoGeppoFunc, AutoFishMerchantModule, AutoStats
local AutoEnterSecondSeaModule

-- =====================================================================
-- DEFERRED REQUIRES  (loaded in background after loading screen)
-- Splitting into small task.spawns prevents the executor from
-- freezing the main thread for 1-2s on startup.
-- =====================================================================
local _requiresDone = false
task.spawn(function()
    if not IS_LOBBY then
        task.wait(0)
        pcall(function() Bypass        = require("BYPASS ANTICHEAT") end)
        pcall(function() if Bypass and Bypass.Init then Bypass.Init() end end)
        task.wait(0)
        pcall(function() Esp           = require("Island/Esp") end)
        pcall(function() TweenSys      = require("Island/TWEEN TO ISLAND") end)
        pcall(function() if TweenSys then TweenSys.Notify = function() end end end)
        task.wait(0)
        pcall(function() IslandData    = require("Island/IslandData") end)
        task.wait(0)
        pcall(function() AutoFarmLevel = require("Farm/AutoFarmLevel") end)
        task.wait(0)
        pcall(function() AutoGetBuso   = require("Farm/AutoGetBuso") end)
        pcall(function() AutoGeppoFunc = require("Farm/AutoGeppo") end)
        pcall(function() AutoEnterSecondSeaModule = require("Farm/AutoEnterSecondSea") end)
        task.wait(0)
        pcall(function() AutoFishMerchantModule = require("Farm/AutoFishMerchant") end)
        task.wait(0)
        pcall(function() AutoStats     = require("Stats/addStats") end)
    end
    _requiresDone = true
end)

-- =====================================================================
-- SERVICES & LOCALS
-- =====================================================================
local ReplicatedStorage_L = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local UIS                 = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local HttpService         = game:GetService("HttpService")
local Player_L            = Players.LocalPlayer
local LocalPlayer         = Player_L
local TeleportService_L   = game:GetService("TeleportService")

-- =====================================================================
-- LOGIC MODULES
-- =====================================================================

local ServerModule = {}
function ServerModule.Join(code, hubArg, seaArg)
    local isPublic = (not code or code:match("^%s*$"))
    if isPublic then
        task.spawn(function() pcall(function() TeleportService_L:Teleport(PLACE_LOBBY, Player_L) end) end)
        return
    end

    -- 1. Join Private Server bằng code
    task.spawn(function()
        pcall(function() ReplicatedStorage_L:WaitForChild("Events"):WaitForChild("reserved"):InvokeServer(code) end)
    end)

    if hubArg ~= nil then
        task.spawn(function()
            local pGui = Player_L:WaitForChild("PlayerGui")
            local chooseTypeUI = pGui:WaitForChild("chooseType", 25)
            if not chooseTypeUI then return end
            local frame = chooseTypeUI:WaitForChild("Frame", 8)
            if not frame then return end
            local remote = frame:WaitForChild("RemoteEvent", 8)
            if not remote then return end
            
            task.wait(0.6)
            
            -- 2. Chọn Hub (tradeHub, fishHub, universeHub...)
            pcall(function() remote:FireServer(hubArg) end)
            pcall(function() chooseTypeUI.Enabled = false end)
            
            -- =========================================================
            -- 3. XỬ LÝ CHỌN SEA (Ép chạy Signal của Nút, dẹp Remote ảo)
            -- =========================================================
            if seaArg then
                -- Đợi 1 chút để UI kịp sinh ra
                task.wait(1.5) 
                
                local pGui = Player_L:FindFirstChild("PlayerGui")
                local wantPartial = (seaArg == "Sea 2") and "second" or "first"
                local correctBtn = nil
                
                -- Quét tìm cái nút ImageButton chuẩn của game
                if pGui then
                    for _, btn in ipairs(pGui:GetDescendants()) do
                        if btn:IsA("ImageButton") then
                            local btnName = (btn.Name or ""):lower()
                            local btnValue = btn:GetAttribute("buttonValue")
                            
                            -- Khớp tên nút và có chứa buttonValue
                            if btnValue ~= nil and btnName:find(wantPartial, 1, true) then
                                correctBtn = btn
                                break
                            end
                        end
                    end
                end
                
                -- Thực thi ép Click
                if correctBtn then
                    local clicked = false
                    
                    -- Cách 1: Dùng getconnections (Cách mạnh nhất, gọi trực tiếp code ẩn của game)
                    if type(getconnections) == "function" then
                        local conns = getconnections(correctBtn.MouseButton1Click)
                        for _, conn in pairs(conns) do
                            pcall(function() conn:Fire() end)
                            pcall(function() conn.Function() end)
                            clicked = true
                        end
                    end
                    
                    -- Cách 2 (Dự phòng): Nếu executor dỏm không hỗ trợ getconnections
                    if not clicked then
                        pcall(function() firebutton(correctBtn) end)
                        pcall(function() correctBtn:activate() end)
                    end
                end
            end
        end)
    end
end

local AutoRejoinModule = {}
AutoRejoinModule._running = false
AutoRejoinModule._thread  = nil
AutoRejoinModule._hooked  = false

local function _SaveAndReturnToLobby()
    getgenv()._ZiliPendingRejoin   = true
    -- [FIX BUG 2] Đọc per-player rejoin data trước (set bởi game world path,
    -- không ảnh hưởng getgenv().PSCode chung → tránh ghi đè acc khác)
    local _playerKey  = "_ZiliRejoinData_" .. Player_L.Name
    local _perPlayer  = getgenv()[_playerKey]
    local _maData     = getgenv()._ZiliMultiAccData
    getgenv()._ZiliRejoinCode = (_perPlayer and _perPlayer.psCode ~= "" and _perPlayer.psCode)
                             or (_maData and _maData.psCode ~= "" and _maData.psCode)
                             or getgenv().PSCode or ""
    getgenv()._ZiliRejoinHub  = (_perPlayer and _perPlayer.hub)
                             or (_maData and _maData.hub)
                             or getgenv().SelectedHub or "Regular"
    getgenv()._ZiliRejoinSea  = (_perPlayer and _perPlayer.sea)
                             or (_maData and _maData.sea)
                             or getgenv().SelectedSea or "Sea 1"
    task.wait(0.5)
    
    -- Ưu tiên dùng hàm teleport của Executor nếu có, nếu không có mới xài TeleportService
    if type(teleport) == "function" then
        pcall(function() teleport(PLACE_LOBBY) end)
    else
        pcall(function() TeleportService_L:Teleport(PLACE_LOBBY, Player_L) end)
    end
end

function AutoRejoinModule.Start()
    if AutoRejoinModule._running then return end
    AutoRejoinModule._running = true

    if not AutoRejoinModule._hooked then
        AutoRejoinModule._hooked = true

        -- Hook 1: TeleportService failure → retry lobby teleport
        pcall(function()
            TeleportService_L.TeleportInitFailed:Connect(function(plr, result, msg)
                if not AutoRejoinModule._running then return end
                if plr ~= Player_L then return end
                task.wait(4)
                _SaveAndReturnToLobby()
            end)
        end)

        -- Hook 2 (Đã sửa): Bắt thông báo lỗi từ GuiService (khi bị kick, mất mạng, văng game)
        pcall(function()
            local GuiService = game:GetService("GuiService")
            GuiService.ErrorMessageChanged:Connect(function(errorMessage)
                if not AutoRejoinModule._running then return end
                if errorMessage and errorMessage ~= "" then
                    -- errorMessage chính là dòng text hiện lên khi bị kick (VD: "You have been kicked...")
                    task.wait(0.5) 
                    _SaveAndReturnToLobby()
                end
            end)
        end)

        -- Hook 2b: Fallback PlayerRemoving (catches non-kick disconnects)
        pcall(function()
            Players.PlayerRemoving:Connect(function(p)
                if p ~= Player_L then return end
                if not AutoRejoinModule._running then return end
                -- Only trigger if not already going back to lobby
                if not getgenv()._ZiliPendingRejoin then
                    _SaveAndReturnToLobby()
                end
            end)
        end)

        -- Hook 3: game:BindToClose (executor may support this)
        pcall(function()
            game:BindToClose(function()
                if AutoRejoinModule._running then
                    local _playerKey2 = "_ZiliRejoinData_" .. Player_L.Name
                    local _perPlayer2 = getgenv()[_playerKey2]
                    local _maD = getgenv()._ZiliMultiAccData
                    getgenv()._ZiliPendingRejoin = true
                    getgenv()._ZiliRejoinCode    = (_perPlayer2 and _perPlayer2.psCode ~= "" and _perPlayer2.psCode)
                                               or (_maD and _maD.psCode ~= "" and _maD.psCode)
                                               or getgenv().PSCode or ""
                    getgenv()._ZiliRejoinHub     = (_perPlayer2 and _perPlayer2.hub) or (_maD and _maD.hub) or getgenv().SelectedHub or "Regular"
                    getgenv()._ZiliRejoinSea     = (_perPlayer2 and _perPlayer2.sea) or (_maD and _maD.sea) or getgenv().SelectedSea or "Sea 1"
                end
            end)
        end)
    end

    -- Poll: if no character for 15s AND not already returning, assume kicked → return to lobby
    AutoRejoinModule._thread = task.spawn(function()
        local noCharTicks = 0
        while AutoRejoinModule._running do
            task.wait(5)
            if getgenv()._ZiliPendingRejoin then noCharTicks=0; continue end
            if Player_L.Character and Player_L.Character.Parent then
                noCharTicks = 0
            else
                noCharTicks += 1
                if noCharTicks >= 3 and AutoRejoinModule._running then
                    _SaveAndReturnToLobby()
                    break
                end
            end
        end
    end)
end

function AutoRejoinModule.Stop()
    AutoRejoinModule._running = false
    if AutoRejoinModule._thread then
        task.cancel(AutoRejoinModule._thread)
        AutoRejoinModule._thread = nil
    end
    getgenv()._ZiliPendingRejoin = false
end

local SkinModule = {}
function SkinModule.Randomize()
    local setEvent = ReplicatedStorage_L:WaitForChild("Events"):WaitForChild("set")
    local function s(n,v) pcall(function() setEvent:FireServer(n,v) end) end
    s("Eye",math.random(1,74)); s("Mouth",math.random(1,36))
    s("Hair1",math.random(1,256)); s("Hair1Color",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    s("Hair2",math.random(1,256)); s("Hair2Color",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    s("Shirt",math.random(1,24)); s("ShirtPri",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    s("ShirtSec",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    s("Pants",math.random(1,22)); s("PantsPri",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    s("PantsSec",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    s("Shoe",math.random(1,12)); s("ShoeColor",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    s("SkinColor",math.random(1,10))
end

local RaceModule = {}
RaceModule.IsRunning = false
function RaceModule.GetCurrentRace()
    local stats = ReplicatedStorage_L:FindFirstChild("Stats"..Player_L.Name)
    if stats and stats:FindFirstChild("Customization") and stats.Customization:FindFirstChild("Race") then
        local raw = stats.Customization.Race.Value
        return raw == "Human" and raw or string.gsub(raw,"%d+","")
    end
    return "Unknown"
end
function RaceModule.Stop() RaceModule.IsRunning = false end
function RaceModule.Start(targetRace, onFound)
    if RaceModule.IsRunning then return end
    RaceModule.IsRunning = true
    task.spawn(function()
        local rerollRemote = ReplicatedStorage_L:WaitForChild("Events"):WaitForChild("reroll")
        while RaceModule.IsRunning do
            if targetRace and targetRace ~= "" then
                local cur = RaceModule.GetCurrentRace()
                if cur == "Unknown" then task.wait(2); continue end
                if string.lower(cur) == string.lower(targetRace) then
                    local snd = Instance.new("Sound", workspace)
                    snd.SoundId = "rbxassetid://2865227271"; snd:Play()
                    RaceModule.Stop(); if onFound then onFound() end; break
                else
                    pcall(function() rerollRemote:InvokeServer() end); task.wait(0.5)
                end
            else task.wait(1) end
        end
    end)
end

-- =====================================================================
-- SCREEN GUI
-- =====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")

-- =====================================================================
-- LOADING SCREEN  (v2.9 — lighter build)
-- Key optimisations:
--   • Removed heavy 680×680 ImageLabel (was forcing a texture decode stall)
--   • BlurEffect size capped at 6 (cheaper, still visible)
--   • Dot animation uses task.delay chain instead of while-loop tween spam
--   • Panel slide-in deferred one frame so Roblox can render first
-- =====================================================================
do
    local TS = TweenService
    local function _N(cls,p,par) local o=Instance.new(cls); for k,v in pairs(p) do o[k]=v end; if par then o.Parent=par end; return o end
    local function _R(r,p) _N("UICorner",{CornerRadius=UDim.new(0,r)},p) end
    local function _TW(o,t,pr) TS:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),pr):Play() end
    local C3 = Color3.fromRGB

    -- Blur: size 6 (lighter than 8, still blurs game world nicely). pcall-safe.
    local _blur = nil
    pcall(function()
        _blur = Instance.new("BlurEffect"); _blur.Size=0
        _blur.Parent = game:GetService("Lighting")
        _TW(_blur,0.4,{Size=6})
    end)

    local _lGui = _N("ScreenGui",{Name="ZiliLoader",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=9999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},gethui and gethui() or game:GetService("CoreGui"))
    -- Semi-transparent overlay — game world shows through the blur
    local _bg = _N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C3(4,3,12),BackgroundTransparency=0.22,ZIndex=1},_lGui)

    -- Panel (starts off-screen below, slides up after first frame)
    local _panel = _N("Frame",{Size=UDim2.new(0,340,0,370),Position=UDim2.new(0.5,-170,0.7,-185),BackgroundColor3=C3(9,7,20),BackgroundTransparency=0.06,ZIndex=3},_lGui)
    _R(20,_panel)
    local _pBorder = _N("UIStroke",{Color=C3(220,172,68),Thickness=1.4,Transparency=0.25},_panel)

    -- Gradient top line
    local _topLine = _N("Frame",{Size=UDim2.new(0.72,0,0,2),Position=UDim2.new(0.14,0,0,0),BackgroundColor3=C3(255,215,85),ZIndex=4},_panel); _R(2,_topLine)
    local _tlG = Instance.new("UIGradient")
    _tlG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C3(255,130,40)),ColorSequenceKeypoint.new(0.5,C3(255,215,115)),ColorSequenceKeypoint.new(1,C3(45,225,218))}); _tlG.Parent=_topLine

    -- Logo ring
    local _logoRing = _N("Frame",{Size=UDim2.new(0,80,0,80),Position=UDim2.new(0.5,-40,0,20),BackgroundColor3=C3(13,9,26),ZIndex=4},_panel); _R(40,_logoRing)
    local _logoStroke = _N("UIStroke",{Color=C3(220,172,68),Thickness=2,Transparency=0.1},_logoRing)
    _N("ImageLabel",{Size=UDim2.new(0,56,0,56),Position=UDim2.new(0.5,-28,0.5,-28),BackgroundTransparency=1,ZIndex=5,Image=LOGO_ASSET_ID,ScaleType=Enum.ScaleType.Fit},_logoRing)

    _N("TextLabel",{Size=UDim2.new(1,-24,0,28),Position=UDim2.new(0,12,0,112),BackgroundTransparency=1,ZIndex=4,Text="ZILI HUB",TextColor3=C3(255,215,115),Font=Enum.Font.GothamBlack,TextSize=22,TextXAlignment=Enum.TextXAlignment.Center},_panel)
    _N("TextLabel",{Size=UDim2.new(1,-24,0,16),Position=UDim2.new(0,12,0,142),BackgroundTransparency=1,ZIndex=4,Text="GET BETTER OUT  ·  Premium Build",TextColor3=C3(140,135,165),Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},_panel)
    _N("Frame",{Size=UDim2.new(0.76,0,0,1),Position=UDim2.new(0.12,0,0,170),BackgroundColor3=C3(38,32,78),ZIndex=4},_panel)
    local _statusLbl = _N("TextLabel",{Size=UDim2.new(1,-24,0,18),Position=UDim2.new(0,12,0,180),BackgroundTransparency=1,ZIndex=4,Text="Starting...",TextColor3=C3(148,143,168),Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},_panel)

    -- Dots
    local _dotsFrame = _N("Frame",{Size=UDim2.new(0,56,0,10),Position=UDim2.new(0.5,-28,0,206),BackgroundTransparency=1,ZIndex=4},_panel)
    local _dots={}
    for i=1,3 do _dots[i]=_N("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,(i-1)*20,0.5,-3),BackgroundColor3=C3(220,172,68),BackgroundTransparency=0.5,ZIndex=5},_dotsFrame); _R(3,_dots[i]) end

    -- Progress bar
    local _barTrack = _N("Frame",{Size=UDim2.new(1,-44,0,5),Position=UDim2.new(0,22,0,226),BackgroundColor3=C3(14,11,30),ZIndex=4},_panel); _R(3,_barTrack)
    local _barFill = _N("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C3(255,215,85),ZIndex=5},_barTrack); _R(3,_barFill)
    local _fg=Instance.new("UIGradient"); _fg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C3(255,120,40)),ColorSequenceKeypoint.new(0.5,C3(255,215,115)),ColorSequenceKeypoint.new(1,C3(45,225,218))}); _fg.Parent=_barFill
    local _pctLbl = _N("TextLabel",{Size=UDim2.new(1,-24,0,18),Position=UDim2.new(0,12,0,238),BackgroundTransparency=1,ZIndex=4,Text="0%",TextColor3=C3(255,215,115),Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center},_panel)
    _N("TextLabel",{Size=UDim2.new(1,-24,0,16),Position=UDim2.new(0,12,0,316),BackgroundTransparency=1,ZIndex=4,Text="v2.9.0  ·  Loading, please wait...",TextColor3=C3(55,50,78),Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center},_panel)

    -- Slide panel in AFTER one frame (prevents first-frame stall)
    task.defer(function()
        TS:Create(_panel,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-170,0.5,-185),BackgroundTransparency=0.06}):Play()
    end)

    -- Dot animation: task.delay chain (no while-loop tween spam)
    local _dotRunning = true
    local function _animDots()
        if not _dotRunning then return end
        for i=1,3 do
            task.delay((i-1)*0.16,function()
                if not(_dots[i] and _dots[i].Parent) then return end
                _TW(_dots[i],0.16,{BackgroundTransparency=0,Size=UDim2.new(0,8,0,8)})
                task.delay(0.18,function() if _dots[i] and _dots[i].Parent then _TW(_dots[i],0.18,{BackgroundTransparency=0.55,Size=UDim2.new(0,6,0,6)}) end end)
            end)
        end
        task.delay(0.75,_animDots)
    end
    task.delay(0.1,_animDots)

    -- Logo stroke pulse (2-color, slower = fewer tweens)
    local _lsCols={C3(255,215,115),C3(45,225,218)}; local _lsI=1
    local function _pulseStroke()
        if not(_logoStroke and _logoStroke.Parent) then return end
        _TW(_logoStroke,1.2,{Color=_lsCols[_lsI],Transparency=0})
        _lsI=_lsI%#_lsCols+1
        task.delay(1.5,_pulseStroke)
    end
    task.delay(0.2,_pulseStroke)

    -- Progress stages
    local _barW=340-44
    local function _setProgress(pct,label)
        _TW(_barFill,0.3,{Size=UDim2.new(0,math.max(0,math.floor(_barW*(pct/100))),1,0)})
        task.delay(0.06,function() if _pctLbl and _pctLbl.Parent then _pctLbl.Text=tostring(pct).."%" end end)
        if label and _statusLbl and _statusLbl.Parent then _statusLbl.Text=label end
    end

    local STAGES={{10,"Initializing...",0.18},{25,"Loading modules...",0.22},{40,"Setting up ESP...",0.20},{55,"Loading farm data...",0.22},{68,"Building UI...",0.20},{80,"Configuring tabs...",0.18},{92,"Almost ready...",0.15},{97,"Finalizing...",0.12}}
    getgenv()._ZiliLoadReady=false; getgenv()._ZiliShowMain=false
    task.spawn(function()
        task.wait(0.3)
        for _,s in ipairs(STAGES) do _setProgress(s[1],s[2]); task.wait(s[3]) end
        local waited=0
        while not getgenv()._ZiliLoadReady and waited<20 do task.wait(0.08); waited+=0.08 end
        _dotRunning=false
        _setProgress(100,"Welcome back!")
        _TW(_pctLbl,0.2,{TextColor3=C3(72,225,135)}); _TW(_statusLbl,0.2,{TextColor3=C3(72,225,135)}); _TW(_pBorder,0.2,{Color=C3(72,225,135)})
        task.wait(0.5)
        if _blur then pcall(function() _TW(_blur,0.35,{Size=0}) end); task.delay(0.4,function() pcall(function() _blur:Destroy() end) end) end
        _TW(_panel,0.28,{BackgroundTransparency=1,Position=UDim2.new(0.5,-170,0.4,-185)})
        task.wait(0.22); _TW(_bg,0.32,{BackgroundTransparency=1}); task.wait(0.32)
        pcall(function() _lGui:Destroy() end); getgenv()._ZiliShowMain=true
    end)
end

-- =====================================================================
-- HELPERS & COLORS
-- =====================================================================
local C = Color3.fromRGB
local function NEW(cls,props,parent)
    local i=Instance.new(cls); for k,v in pairs(props) do i[k]=v end; if parent then i.Parent=parent end; return i
end
local function CORNER(r,p) return NEW("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function STROKE(col,thick,trans,p) return NEW("UIStroke",{Color=col,Thickness=thick,Transparency=trans or 0},p) end
local function TWEEN(obj,t,props) TweenService:Create(obj,TweenInfo.new(t,Enum.EasingStyle.Quad),props):Play() end
local function TWEEN_BACK(obj,t,props) TweenService:Create(obj,TweenInfo.new(t,Enum.EasingStyle.Back,Enum.EasingDirection.Out),props):Play() end

-- =====================================================================
-- COLORS  (moved up — must be declared before Toast/TabBadge/Search)
-- =====================================================================
local BG0=Color3.fromRGB(4,3,10); local BG1=Color3.fromRGB(8,6,18); local BG2=Color3.fromRGB(11,9,24); local BG3=Color3.fromRGB(15,13,33)
local BG4=Color3.fromRGB(20,18,44); local BG5=Color3.fromRGB(7,6,16); local BG_HDR=Color3.fromRGB(10,9,22)
local GOLD=Color3.fromRGB(220,172,68); local GOLD2=Color3.fromRGB(255,215,115); local GOLD3=Color3.fromRGB(140,100,30); local GOLDD=Color3.fromRGB(35,26,6)
local TEXT1=Color3.fromRGB(245,242,232); local TEXT2=Color3.fromRGB(148,143,168); local TEXT3=Color3.fromRGB(60,55,82)
local COL_MAIN=Color3.fromRGB(255,215,85); local COL_FARM=Color3.fromRGB(255,105,40); local COL_TRAVEL=Color3.fromRGB(45,225,218)
local COL_FISH=Color3.fromRGB(65,165,255); local COL_STATS=Color3.fromRGB(185,95,255); local COL_PS=Color3.fromRGB(240,75,190); local COL_CFG=Color3.fromRGB(72,225,135)
local RED=Color3.fromRGB(240,60,60); local GREEN=Color3.fromRGB(55,220,130); local CYAN=Color3.fromRGB(45,225,218); local CYAND=Color3.fromRGB(5,40,38)
local PINK=Color3.fromRGB(240,75,190); local PINKD=Color3.fromRGB(42,8,48); local BLUE_A=Color3.fromRGB(65,165,255)
local ORANGE=Color3.fromRGB(255,105,40); local PURPLE=Color3.fromRGB(185,95,255); local AMBER=Color3.fromRGB(255,215,85)
local COL_MISC=Color3.fromRGB(120,90,255)  -- Misc tab: indigo/violet


-- =====================================================================
-- COLOR THEME SYSTEM
-- 4 presets; accent colors swap live across the entire hub
-- =====================================================================
local THEMES={
    {name="Gold",   main=C(255,215,85),  c2=C(220,172,68),  c3=C(140,100,30), dark=C(35,26,6)},
    {name="Cyan",   main=C(45,225,218),  c2=C(30,200,195),  c3=C(15,100,100), dark=C(3,30,30)},
    {name="Purple", main=C(185,95,255),  c2=C(155,75,220),  c3=C(80,35,120),  dark=C(18,6,36)},
    {name="Rose",   main=C(255,90,160),  c2=C(230,70,140),  c3=C(130,30,75),  dark=C(35,5,20)},
    {name="Blue",   main=C(65,165,255),  c2=C(45,140,230),  c3=C(20,70,140),  dark=C(4,16,36)},
    {name="Green",  main=C(55,220,130),  c2=C(40,190,110),  c3=C(18,100,55),  dark=C(4,26,14)},
    {name="Orange", main=C(255,130,40),  c2=C(230,105,25),  c3=C(140,60,10),  dark=C(36,18,4)},
    {name="Teal",   main=C(0,210,180),   c2=C(0,175,155),   c3=C(0,90,80),    dark=C(2,24,22)},
}
local _curTheme=1
local _themeObjects={}  -- {obj, prop, kind} where kind: "main","c2","c3","dark"
local function RegTheme(obj,prop,kind) table.insert(_themeObjects,{obj=obj,prop=prop,kind=kind or "main"}) end
local function ApplyTheme(idx)
    _curTheme=idx; local t=THEMES[idx]
    GOLD=t.c2; GOLD2=t.main; GOLD3=t.c3; GOLDD=t.dark
    for _,r in ipairs(_themeObjects) do
        pcall(function()
            local col = (r.kind=="c2" and t.c2) or (r.kind=="c3" and t.c3) or (r.kind=="dark" and t.dark) or t.main
            r.obj[r.prop]=col
        end)
    end
    -- Update all toggle pills that use GOLD accent
    for _,d in pairs(TogglesData or {}) do
        if type(d)=="table" then
            local isGoldAccent = d.AccentCol and
                math.abs((d.AccentCol.R - THEMES[1].main.R/255)) < 0.05
            if isGoldAccent or not d.AccentCol then
                d.AccentCol  = t.main
                d.AccentDark = t.dark
                if d.Active and d.Btn  then pcall(function() TWEEN(d.Btn,0.3,{BackgroundColor3=t.dark}) end) end
                if d.Active and d.Strk then pcall(function() TWEEN(d.Strk,0.3,{Color=t.main}) end) end
                if d.Active and d.Thumb then pcall(function() TWEEN(d.Thumb,0.3,{BackgroundColor3=t.main}) end) end
            end
        end
    end
end

-- =====================================================================
-- TOAST NOTIFICATION SYSTEM
-- Toast(msg, col, icon)  –  shows a slim popup at bottom-right
-- =====================================================================
local _toastQueue={}; local _toastRunning=false
local function Toast(msg,col,icon)
    col=col or GOLD2; icon=icon or "⬡"
    table.insert(_toastQueue,{msg=msg,col=col,icon=icon})
    if _toastRunning then return end
    _toastRunning=true
    task.spawn(function()
        while #_toastQueue>0 do
            local t=table.remove(_toastQueue,1)
            local tf=NEW("Frame",{Size=UDim2.new(0,240,0,36),Position=UDim2.new(1,10,1,-60),BackgroundColor3=BG1,BorderSizePixel=0,ZIndex=500},ScreenGui)
            CORNER(8,tf); STROKE(t.col,1.2,0.1,tf)
            local acBar=NEW("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=t.col,BorderSizePixel=0,ZIndex=501},tf); CORNER(2,acBar)
            local iconDot=NEW("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,14,0.5,-4),BackgroundColor3=t.col,BorderSizePixel=0,ZIndex=502},tf);CORNER(4,iconDot)
            NEW("TextLabel",{Text=t.msg,Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,28,0,0),BackgroundTransparency=1,TextColor3=t.col,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=501},tf)
            TWEEN(tf,0.25,{Position=UDim2.new(1,-254,1,-60)})
            task.wait(2.2)
            TWEEN(tf,0.2,{Position=UDim2.new(1,10,1,-60),BackgroundTransparency=1})
            task.wait(0.22); pcall(function() tf:Destroy() end)
            task.wait(0.08)
        end
        _toastRunning=false
    end)
end

-- =====================================================================
-- TOOLTIP SYSTEM
-- Tooltip(btn, text)  –  hover 0.6s → tiny popup near cursor
-- =====================================================================
local _tipFrame=nil
local function Tooltip(btn,text)
    local _hover=false
    btn.MouseEnter:Connect(function()
        _hover=true
        task.delay(0.6,function()
            if not _hover then return end
            if _tipFrame then pcall(function() _tipFrame:Destroy() end) end
            local mx,my=0,0
            pcall(function() local m=LocalPlayer:GetMouse(); mx=m.X; my=m.Y end)
            _tipFrame=NEW("Frame",{Size=UDim2.new(0,0,0,24),Position=UDim2.new(0,mx+12,0,my-28),BackgroundColor3=BG0,BorderSizePixel=0,ZIndex=800,AutomaticSize=Enum.AutomaticSize.X},ScreenGui)
            CORNER(5,_tipFrame); STROKE(GOLD3,1,0.3,_tipFrame)
            NEW("TextLabel",{Text=text,Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=10,ZIndex=801,TextXAlignment=Enum.TextXAlignment.Left},_tipFrame)
            NEW("UIPadding",{PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)},_tipFrame)
            TWEEN(_tipFrame,0.12,{BackgroundTransparency=0})
        end)
    end)
    btn.MouseLeave:Connect(function()
        _hover=false
        if _tipFrame then TWEEN(_tipFrame,0.1,{BackgroundTransparency=1}); local tf=_tipFrame; task.delay(0.12,function() pcall(function() tf:Destroy() end) end); _tipFrame=nil end
    end)
end

-- =====================================================================
-- TAB BADGE SYSTEM
-- TabBadge(tabName, count, col)  –  shows a dot/number on the tab button
-- =====================================================================
local _tabBadges={}
local function TabBadge(tabName,count,col)
    col=col or RED
    local td=Tabs and Tabs[tabName]; if not td then return end
    if _tabBadges[tabName] then pcall(function() _tabBadges[tabName]:Destroy() end) end
    if not count or count<=0 then _tabBadges[tabName]=nil; return end
    local badge=NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(1,-6,0,-4),BackgroundColor3=col,ZIndex=10},td.btn)
    CORNER(8,badge); STROKE(BG0,1.5,0,badge)
    NEW("TextLabel",{Text=count>9 and "9+" or tostring(count),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=C(255,255,255),Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=11},badge)
    _tabBadges[tabName]=badge
    TWEEN_BACK(badge,0.2,{Size=UDim2.new(0,17,0,17)})
    task.delay(0.2,function() TWEEN(badge,0.1,{Size=UDim2.new(0,16,0,16)}) end)
end

-- =====================================================================
-- GLOBAL SEARCH OVERLAY
-- Shows when user clicks 🔍 in TopBar; searches feature names across tabs
-- =====================================================================
local _searchRegistry={}  -- {name, tab, desc, toggle_key}
local function RegSearch(name,tabName,desc,toggleKey)
    table.insert(_searchRegistry,{name=name,tab=tabName,desc=desc or "",key=toggleKey})
end
local _searchOverlay=nil
local function OpenGlobalSearch()
    if _searchOverlay then pcall(function() _searchOverlay:Destroy() end); _searchOverlay=nil; return end
    -- Parent to ScreenGui (MainFrame may not be declared yet at call-registration time)
    local mfPos = MainFrame and MainFrame.AbsolutePosition or Vector2.new(0,0)
    local mfSz  = MainFrame and MainFrame.AbsoluteSize  or Vector2.new(720,520)
    local ox = mfPos.X + mfSz.X/2 - 190
    local oy = mfPos.Y + 52
    _searchOverlay=NEW("Frame",{Size=UDim2.new(0,380,0,310),Position=UDim2.new(0,ox,0,oy),BackgroundColor3=BG1,BorderSizePixel=0,ZIndex=600,ClipsDescendants=false},ScreenGui)
    CORNER(12,_searchOverlay); STROKE(GOLD,1.5,0.15,_searchOverlay)
    local hdr=NEW("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=BG2,ZIndex=601},_searchOverlay); CORNER(10,hdr)
    NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG2,BorderSizePixel=0,ZIndex=601},hdr)
    local sBox=NEW("TextBox",{Size=UDim2.new(1,-86,1,-10),Position=UDim2.new(0,36,0,5),BackgroundTransparency=1,Text="",PlaceholderText="Search features...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.GothamSemibold,TextSize=13,ZIndex=602},hdr)
    -- Magnifying glass icon in search header
    do local mg2=NEW("Frame",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,8,0.5,-10),BackgroundTransparency=1,ZIndex=603},hdr);local mc=NEW("Frame",{Size=UDim2.new(0,11,0,11),Position=UDim2.new(0,2,0,2),BackgroundTransparency=1,ZIndex=603},mg2);CORNER(6,mc);STROKE(GOLD2,1.8,0,mc);local mh=NEW("Frame",{Size=UDim2.new(0,5,0,2),Position=UDim2.new(0,11,0,13),BackgroundColor3=GOLD2,Rotation=45,ZIndex=603},mg2);CORNER(1,mh) end
    local closeS=NEW("TextButton",{Text="x",Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-36,0.5,-14),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=14,ZIndex=602},hdr)
    closeS.MouseButton1Click:Connect(function() pcall(function() _searchOverlay:Destroy() end); _searchOverlay=nil end)
    local resList=NEW("ScrollingFrame",{Size=UDim2.new(1,-16,1,-50),Position=UDim2.new(0,8,0,44),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=GOLD3,ZIndex=601,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},_searchOverlay)
    NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),HorizontalAlignment=Enum.HorizontalAlignment.Center},resList)
    NEW("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)},resList)
    local function BuildResults(q)
        resList:ClearAllChildren()
        NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),HorizontalAlignment=Enum.HorizontalAlignment.Center},resList)
        q=q:lower(); local count=0
        for _,r in ipairs(_searchRegistry) do
            if q=="" or r.name:lower():find(q,1,true) or r.desc:lower():find(q,1,true) then
                count+=1
                local row=NEW("TextButton",{Size=UDim2.new(1,-8,0,38),BackgroundColor3=BG3,Text="",AutoButtonColor=false,ZIndex=602},resList)
                CORNER(7,row); STROKE(C(28,24,52),1,0,row)
                NEW("TextLabel",{Text=r.name,Size=UDim2.new(0.65,0,0,20),Position=UDim2.new(0,12,0,4),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=603},row)
                NEW("TextLabel",{Text=r.desc,Size=UDim2.new(0.9,0,0,14),Position=UDim2.new(0,12,0,23),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=603},row)
                local tabBadge=NEW("TextLabel",{Text=r.tab,Size=UDim2.new(0,0,0,18),Position=UDim2.new(1,-8,0.5,-9),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=BG3,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=603},row)
                CORNER(4,tabBadge); NEW("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},tabBadge)
                row.MouseEnter:Connect(function() TWEEN(row,0.12,{BackgroundColor3=BG4}) end)
                row.MouseLeave:Connect(function() TWEEN(row,0.12,{BackgroundColor3=BG3}) end)
                row.MouseButton1Click:Connect(function()
                    pcall(function() _searchOverlay:Destroy() end); _searchOverlay=nil
                    -- Navigate to the tab
                    task.defer(function()
                        pcall(function()
                            if not (Tabs and Tabs[r.tab]) then return end
                            local td=Tabs[r.tab]
                            -- Build lazy page if not yet built
                            if _pageBuildFns and _pageBuildFns[r.tab] then
                                local fn=_pageBuildFns[r.tab]; _pageBuildFns[r.tab]=nil; pcall(fn)
                            end
                            -- Deactivate current tab
                            if SelectedTab and SelectedTab~=td.btn then
                                for _,tdd in pairs(Tabs) do
                                    if tdd.btn==SelectedTab then pcall(tdd.setInactive); break end
                                end
                                if SelectedPage then SelectedPage.Visible=false end
                            end
                            -- Activate target tab
                            SelectedTab=td.btn
                            SelectedPage=Pages[r.tab]
                            pcall(td.setActive)
                        end)
                    end)
                end)
            end
        end
        if count==0 then
            NEW("TextLabel",{Text="No results found",Size=UDim2.new(1,-8,0,40),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=602},resList)
        end
    end
    BuildResults("")
    sBox:GetPropertyChangedSignal("Text"):Connect(function() BuildResults(sBox.Text) end)
    sBox:CaptureFocus()
    -- Animate in from slightly above
    _searchOverlay.Position=UDim2.new(0,ox,0,oy-10)
    TWEEN_BACK(_searchOverlay,0.22,{Position=UDim2.new(0,ox,0,oy)})
end


-- =====================================================================
-- ICON SYSTEM (condensed)
-- =====================================================================
local function DrawIcon(parent,iconName,px,py,sz,col)
    sz=sz or 14; col=col or TEXT2
    local c=NEW("Frame",{Size=UDim2.new(0,sz,0,sz),Position=UDim2.new(0,px,0,py),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true},parent)
    local s=sz
    local function RR(x,y,w,h,r,clr) local f=NEW("Frame",{Size=UDim2.new(0,w,0,h),Position=UDim2.new(0,x,0,y),BackgroundColor3=clr or col,BorderSizePixel=0},c); if r and r>0 then CORNER(r,f) end; return f end
    local function L(x1,y1,x2,y2,th,clr) local dx=x2-x1;local dy=y2-y1;local len=math.sqrt(dx*dx+dy*dy);if len<0.5 then return end;local f=NEW("Frame",{Size=UDim2.new(0,len,0,th or 1.5),Position=UDim2.new(0,(x1+x2)/2,0,(y1+y2)/2),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=clr or col,BorderSizePixel=0,Rotation=math.deg(math.atan2(dy,dx))},c);CORNER(1,f);return f end
    local function Dot(cx,cy,d,clr) return RR(cx-d/2,cy-d/2,d,d,d/2,clr) end
    local function Ring(cx,cy,d,sw,clr) local f=NEW("Frame",{Size=UDim2.new(0,d,0,d),Position=UDim2.new(0,cx-d/2,0,cy-d/2),BackgroundTransparency=1,BorderSizePixel=0},c);CORNER(d/2,f);STROKE(clr or col,sw or 1.5,0,f);return f end
    if iconName=="home" then L(s*.5,s*.04,s*.04,s*.48,1.8);L(s*.5,s*.04,s*.96,s*.48,1.8);L(s*.04,s*.48,s*.96,s*.48,1.5);RR(s*.14,s*.46,s*.72,s*.52,2);RR(s*.38,s*.65,s*.24,s*.34,2)
    elseif iconName=="sword" then L(s*.78,s*.03,s*.14,s*.82,2.2);L(s*.26,s*.36,s*.62,s*.58,1.8);L(s*.62,s*.58,s*.82,s*.80,2.0);Dot(s*.88,s*.88,s*.20);Ring(s*.88,s*.88,s*.22,1.2)
    elseif iconName=="globe" then Ring(s*.5,s*.5,s*.92,1.8);L(s*.5,s*.04,s*.5,s*.96,1.4);L(s*.04,s*.5,s*.96,s*.5,1.4);Ring(s*.5,s*.5,s*.58,1.2)
    elseif iconName=="fish" then local body=NEW("Frame",{Size=UDim2.new(0,s*.66,0,s*.52),Position=UDim2.new(0,s*.02,0,s*.24),BackgroundColor3=col,BorderSizePixel=0},c);CORNER(s*.26,body);L(s*.62,s*.50,s*.98,s*.10,2);L(s*.62,s*.50,s*.98,s*.90,2);Ring(s*.16,s*.46,s*.14,1.5);Dot(s*.16,s*.46,s*.06)
    elseif iconName=="chart" then L(s*.04,s*.96,s*.96,s*.96,1.8);RR(s*.08,s*.52,s*.18,s*.44,2);RR(s*.32,s*.22,s*.18,s*.74,2);RR(s*.56,s*.38,s*.18,s*.58,2);RR(s*.80,s*.62,s*.12,s*.34,2)
    elseif iconName=="gear" then Ring(s*.5,s*.5,s*.50,1.8);Dot(s*.5,s*.5,s*.18);for i=0,5 do local a=(i/6)*math.pi*2-math.pi/6;local ox=s*.5+math.cos(a)*s*.48;local oy=s*.5+math.sin(a)*s*.48;RR(ox-s*.07,oy-s*.07,s*.14,s*.14,3) end
    elseif iconName=="shield" then local sh=NEW("Frame",{Size=UDim2.new(0,s*.84,0,s*.92),Position=UDim2.new(0,s*.08,0,s*.04),BackgroundTransparency=1,BorderSizePixel=0},c);CORNER(s*.20,sh);STROKE(col,1.8,0,sh);L(s*.5,s*.28,s*.70,s*.50,1.5);L(s*.70,s*.50,s*.50,s*.72,1.5);L(s*.50,s*.72,s*.30,s*.50,1.5);L(s*.30,s*.50,s*.50,s*.28,1.5)
    elseif iconName=="target" then Ring(s*.5,s*.5,s*.90,1.6);Ring(s*.5,s*.5,s*.52,1.4);Dot(s*.5,s*.5,s*.14);L(s*.5,s*.00,s*.5,s*.21,1.5);L(s*.5,s*.79,s*.5,s*1.0,1.5);L(s*.00,s*.5,s*.21,s*.5,1.5);L(s*.79,s*.5,s*1.0,s*.5,1.5)
    elseif iconName=="user" then Ring(s*.5,s*.26,s*.32,1.8);RR(s*.10,s*.56,s*.80,s*.44,s*.20)
    elseif iconName=="lightning" then L(s*.68,s*.02,s*.26,s*.52,2.2);L(s*.26,s*.52,s*.56,s*.48,1.8);L(s*.56,s*.48,s*.32,s*.98,2.2);L(s*.32,s*.98,s*.74,s*.48,1.8)
    elseif iconName=="eye" then L(s*.06,s*.50,s*.28,s*.18,1.8);L(s*.28,s*.18,s*.50,s*.10,1.8);L(s*.50,s*.10,s*.72,s*.18,1.8);L(s*.72,s*.18,s*.94,s*.50,1.8);L(s*.06,s*.50,s*.28,s*.76,1.8);L(s*.28,s*.76,s*.50,s*.84,1.8);L(s*.50,s*.84,s*.72,s*.76,1.8);L(s*.72,s*.76,s*.94,s*.50,1.8);Ring(s*.5,s*.5,s*.36,1.8);Dot(s*.5,s*.5,s*.16)
    elseif iconName=="fist" then RR(s*.02,s*.04,s*.20,s*.26,2);RR(s*.25,s*.00,s*.20,s*.26,2);RR(s*.48,s*.04,s*.20,s*.24,2);RR(s*.02,s*.28,s*.82,s*.46,3);RR(s*.78,s*.30,s*.20,s*.22,2);RR(s*.08,s*.72,s*.68,s*.22,3)
    elseif iconName=="wave" then L(s*.00,s*.60,s*.18,s*.28,2);L(s*.18,s*.28,s*.36,s*.60,2);L(s*.36,s*.60,s*.54,s*.28,2);L(s*.54,s*.28,s*.72,s*.60,2);L(s*.72,s*.60,s*.90,s*.36,2);Dot(s*.88,s*.22,s*.07);Dot(s*.96,s*.30,s*.05)
    elseif iconName=="fruit" then Ring(s*.5,s*.58,s*.74,2);RR(s*.46,s*.06,s*.08,s*.22,2);local leaf=NEW("Frame",{Size=UDim2.new(0,s*.26,0,s*.16),Position=UDim2.new(0,s*.50,0,s*.02),BackgroundColor3=col,BorderSizePixel=0},c);CORNER(s*.08,leaf);Dot(s*.38,s*.46,s*.12)
    elseif iconName=="chest" then RR(s*.06,s*.44,s*.88,s*.54,3);local lid=NEW("Frame",{Size=UDim2.new(0,s*.88,0,s*.34),Position=UDim2.new(0,s*.06,0,s*.10),BackgroundTransparency=1,BorderSizePixel=0},c);CORNER(s*.10,lid);STROKE(col,1.5,0,lid);local lk=NEW("Frame",{Size=UDim2.new(0,s*.22,0,s*.24),Position=UDim2.new(0,s*.39,0,s*.36),BackgroundTransparency=1,BorderSizePixel=0},c);CORNER(s*.06,lk);STROKE(col,1.4,0,lk)
    elseif iconName=="coin" then Ring(s*.5,s*.5,s*.88,2.2);Ring(s*.5,s*.5,s*.64,1.4);L(s*.5,s*.22,s*.5,s*.78,1.5);L(s*.34,s*.36,s*.66,s*.36,1.5);L(s*.34,s*.50,s*.60,s*.50,1.5);L(s*.34,s*.64,s*.66,s*.64,1.5)
    elseif iconName=="bottle" then RR(s*.36,s*.02,s*.28,s*.10,3);local body=NEW("Frame",{Size=UDim2.new(0,s*.62,0,s*.64),Position=UDim2.new(0,s*.19,0,s*.32),BackgroundColor3=col,BorderSizePixel=0},c);CORNER(s*.18,body);RR(s*.24,s*.50,s*.52,s*.16,2);Dot(s*.62,s*.68,s*.10)
    elseif iconName=="arrows" then Ring(s*.5,s*.38,s*.40,1.8);L(s*.70,s*.20,s*.78,s*.28,2);L(s*.78,s*.28,s*.64,s*.30,2);Ring(s*.5,s*.62,s*.40,1.8);L(s*.30,s*.80,s*.22,s*.72,2);L(s*.22,s*.72,s*.36,s*.70,2)
    elseif iconName=="server" then RR(s*.06,s*.04,s*.88,s*.24,3);RR(s*.06,s*.36,s*.88,s*.24,3);RR(s*.06,s*.68,s*.88,s*.24,3);L(s*.12,s*.16,s*.64,s*.16,1.2);L(s*.12,s*.48,s*.64,s*.48,1.2);L(s*.12,s*.80,s*.64,s*.80,1.2)
    elseif iconName=="wand" then L(s*.08,s*.92,s*.72,s*.28,2.5);L(s*.72,s*.28,s*.88,s*.08,2);Dot(s*.84,s*.08,s*.14,col);L(s*.82,s*.02,s*.96,s*.14,1.5);L(s*.96,s*.14,s*.82,s*.14,1.5);L(s*.82,s*.14,s*.82,s*.28,1.5);L(s*.68,s*.14,s*.82,s*.14,1.5)
    elseif iconName=="palette" then Ring(s*.5,s*.5,s*.88,1.8);Dot(s*.28,s*.30,s*.13,col);Dot(s*.56,s*.20,s*.13,col);Dot(s*.76,s*.38,s*.13,col);Dot(s*.72,s*.66,s*.13,col);Dot(s*.40,s*.76,s*.13,col);Dot(s*.22,s*.56,s*.13,col)
        local d1=Dot(s*.82,s*.16,s*.13,GREEN);if d1 then d1.Name="SDot";d1:SetAttribute("DotColor","GREEN") end
        local d2=Dot(s*.82,s*.48,s*.13,AMBER);if d2 then d2.Name="SDot";d2:SetAttribute("DotColor","AMBER") end
        local d3=Dot(s*.82,s*.80,s*.13,RED);if d3 then d3.Name="SDot";d3:SetAttribute("DotColor","RED") end
    end
    return c
end

-- =====================================================================
-- MINI LOGO
-- FIX: dragDist threshold prevents drag-release from reopening the hub
-- =====================================================================
local MiniLogo=NEW("ImageButton",{Size=UDim2.new(0,52,0,52),Position=UDim2.new(0,50,0.5,-26),Image=LOGO_ASSET_ID,BackgroundColor3=C(8,9,22),BackgroundTransparency=0,Visible=false,ZIndex=999},ScreenGui)
CORNER(26,MiniLogo); local miniLogoStroke=STROKE(GOLD2,2.2,0,MiniLogo)
task.spawn(function() local cols={COL_MAIN,COL_TRAVEL,COL_FISH,COL_STATS,COL_PS,COL_FARM};local i=1;while MiniLogo do task.wait(1.4);TWEEN(miniLogoStroke,1.0,{Color=cols[i]});i=(i%#cols)+1 end end)

local dM_mini,dStM_mini,sPM_mini,dragDist_mini
MiniLogo.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dM_mini=true; dStM_mini=inp.Position; sPM_mini=MiniLogo.Position; dragDist_mini=0
    end
end)
UIS.InputChanged:Connect(function(inp)
    if dM_mini and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=inp.Position-dStM_mini
        dragDist_mini=math.sqrt(delta.X^2+delta.Y^2)
        MiniLogo.Position=UDim2.new(sPM_mini.X.Scale,sPM_mini.X.Offset+delta.X,sPM_mini.Y.Scale,sPM_mini.Y.Offset+delta.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 and dM_mini then
        dM_mini=false
        -- Only re-open if mouse barely moved (true click, NOT drag-release)
        if (dragDist_mini or 0) < 6 and MiniLogo.Visible then
            task.defer(function() getgenv()._GBO_ShowHub() end)
        end
    end
end)

-- =====================================================================
-- KEYBIND TOGGLE  (default: RightShift — configurable in Config tab)
-- =====================================================================
local _keybindKey = Enum.KeyCode.RightShift
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode == _keybindKey then
        -- MiniLogo.Visible = true means hub is hidden → show it; otherwise hide
        if MiniLogo and MiniLogo.Visible then getgenv()._GBO_ShowHub()
        else getgenv()._GBO_HideHub() end
    end
end)

-- =====================================================================
-- MAIN FRAME
-- =====================================================================
    -- ─────────────────────────────────────────────────────────
    -- Sidebar section wrapped to free locals from _initUI scope
    local function _buildSidebar()
local MainFrame=NEW("CanvasGroup",{Size=UDim2.new(0,720,0,520),Position=UDim2.new(0.5,-360,0.5,-260),BackgroundColor3=BG1,BorderSizePixel=0,ClipsDescendants=true,BackgroundTransparency=1,GroupTransparency=1},ScreenGui)
local _mainFrameStroke=STROKE(GOLD,1.8,0.06,MainFrame); RegTheme(_mainFrameStroke,"Color","c2")
CORNER(14,MainFrame)
MainFrame.Visible=false
task.spawn(function()
    local waited=0
    while not getgenv()._ZiliShowMain and waited<25 do task.wait(0.05);waited+=0.05 end
    MainFrame.Visible=true; MainFrame.Size=UDim2.new(0,680,0,490); MainFrame.Position=UDim2.new(0.5,-340,0.5,-245)
    TweenService:Create(MainFrame,TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,720,0,520),Position=UDim2.new(0.5,-360,0.5,-260),GroupTransparency=0}):Play()
end)

-- =====================================================================
-- BACKGROUND (optimized — no per-frame dot grid)
-- =====================================================================
local BgBase=NEW("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=BG0,ZIndex=0,BorderSizePixel=0},MainFrame); CORNER(12,BgBase)
local BgGrad=Instance.new("UIGradient")
BgGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(8,6,20)),ColorSequenceKeypoint.new(0.4,C(5,5,14)),ColorSequenceKeypoint.new(0.8,C(6,7,18)),ColorSequenceKeypoint.new(1,C(4,4,11))})
BgGrad.Rotation=145; BgGrad.Parent=BgBase

local GLOW_DATA={{COL_MAIN,-0.12,-0.12},{COL_TRAVEL,1.08,-0.08},{COL_STATS,-0.08,1.08},{COL_PS,1.10,1.10}}
local cornerGlows={}
for i,gd in ipairs(GLOW_DATA) do local g=NEW("Frame",{Size=UDim2.new(0,160,0,160),Position=UDim2.new(gd[2],-80,gd[3],-80),BackgroundColor3=gd[1],BackgroundTransparency=0.93,ZIndex=0,BorderSizePixel=0},MainFrame);CORNER(80,g);table.insert(cornerGlows,g) end
task.spawn(function() local t=0;while MainFrame and MainFrame.Parent do t+=0.03;for i,g in ipairs(cornerGlows) do TWEEN(g,1.6,{BackgroundTransparency=0.94-0.035*math.sin(t+i*1.57)}) end;task.wait(1.6) end end)

local sh1=NEW("Frame",{Size=UDim2.new(0,2,1,0),Position=UDim2.new(-0.01,0,0,0),BackgroundColor3=GOLD2,BackgroundTransparency=0.91,ZIndex=0,BorderSizePixel=0,Rotation=16},BgBase)
task.spawn(function() while MainFrame and MainFrame.Parent do sh1.Position=UDim2.new(-0.01,0,0,0);TweenService:Create(sh1,TweenInfo.new(5.5,Enum.EasingStyle.Quad),{Position=UDim2.new(1.01,0,0,0)}):Play();task.wait(10) end end)

local PARTICLE_COLORS={GOLD,GOLD2,COL_TRAVEL,COL_STATS,COL_FISH}
task.spawn(function()
    while MainFrame and MainFrame.Parent do task.wait(4);if not MainFrame or not MainFrame.Parent then break end
        local col=PARTICLE_COLORS[math.random(#PARTICLE_COLORS)];local sz=math.random(2,4);local xs=math.random(4,96)/100
        local p=NEW("Frame",{Size=UDim2.new(0,sz,0,sz),Position=UDim2.new(xs,0,1.04,0),BackgroundColor3=col,BackgroundTransparency=0.7,ZIndex=0,BorderSizePixel=0},BgBase);CORNER(sz,p)
        local dur=math.random(7,13);TweenService:Create(p,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Position=UDim2.new(xs,math.random(-30,30),-0.05,0),BackgroundTransparency=1}):Play()
        task.delay(dur+0.2,function() if p and p.Parent then p:Destroy() end end)
    end
end)

local function MakeEdgeGlow(ax,ay)
    local col=(ax==0 and ay==0) and COL_TRAVEL or (ax==1 and ay==0) and COL_STATS or (ax==0 and ay==1) and COL_FISH or COL_PS
    local g=NEW("Frame",{Size=UDim2.new(0.28,0,0.28,0),AnchorPoint=Vector2.new(ax,ay),Position=UDim2.new(ax,0,ay,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0},MainFrame)
    local eg=Instance.new("UIGradient")
    eg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,col),ColorSequenceKeypoint.new(1,BG0)})
    eg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.84),NumberSequenceKeypoint.new(1,1)})
    eg.Rotation=(ax==0 and ay==0) and 135 or (ax==1 and ay==0) and 225 or (ax==0 and ay==1) and 45 or 315
    eg.Parent=g
end
MakeEdgeGlow(0,0);MakeEdgeGlow(1,0);MakeEdgeGlow(0,1);MakeEdgeGlow(1,1)

-- =====================================================================
-- TOP BAR
-- =====================================================================
local TopBar=NEW("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=BG2,BorderSizePixel=0},MainFrame)
CORNER(12,TopBar); NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG2,BorderSizePixel=0},TopBar)
local tbLine=NEW("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=GOLD,BorderSizePixel=0},TopBar)
RegTheme(tbLine,"BackgroundColor3","c2")
local tbGrad=Instance.new("UIGradient")
tbGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,COL_MAIN),ColorSequenceKeypoint.new(0.18,COL_FARM),ColorSequenceKeypoint.new(0.36,COL_TRAVEL),ColorSequenceKeypoint.new(0.54,COL_FISH),ColorSequenceKeypoint.new(0.72,COL_STATS),ColorSequenceKeypoint.new(0.88,COL_PS),ColorSequenceKeypoint.new(1,COL_CFG)})
tbGrad.Parent=tbLine
task.spawn(function() local t=0;while TopBar and TopBar.Parent do t+=0.015;tbGrad.Offset=Vector2.new(math.sin(t)*0.16,0);task.wait(0.1) end end)

local LogoBadge=NEW("Frame",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,12,0.5,-18),BackgroundColor3=C(10,10,26)},TopBar)
CORNER(8,LogoBadge); local badgeRing=STROKE(GOLD,2,0.1,LogoBadge)
NEW("ImageLabel",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0.5,-11,0.5,-11),Image=LOGO_ASSET_ID,BackgroundTransparency=1,ZIndex=2},LogoBadge)
task.spawn(function() local cols={COL_MAIN,COL_TRAVEL,COL_FISH,COL_STATS,COL_PS,COL_CFG};local i=1;while TopBar and TopBar.Parent do TWEEN(badgeRing,1.4,{Color=cols[i],Transparency=0.05});task.wait(1.8);TWEEN(badgeRing,0.7,{Transparency=0.45});task.wait(0.9);i=(i%#cols)+1 end end)

NEW("TextLabel",{Text="ZILI HUB",Position=UDim2.new(0,56,0,8),Size=UDim2.new(0,88,0,18),TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=14,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},TopBar)
NEW("TextLabel",{Text="|",Position=UDim2.new(0,146,0,8),Size=UDim2.new(0,12,0,18),TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=15,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Center},TopBar)
NEW("TextLabel",{Text="GBO",Position=UDim2.new(0,160,0,8),Size=UDim2.new(0,42,0,18),TextColor3=CYAN,Font=Enum.Font.GothamBold,TextSize=14,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},TopBar)
-- Version + active feature counter
local _topSubLbl=NEW("TextLabel",{Text="v2.9  ·  PREMIUM  ·  0 active",Position=UDim2.new(0,56,0,28),Size=UDim2.new(0,220,0,12),TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=9,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},TopBar)
-- Session timer (top-right, bigger, properly spaced from search button)
local _sessionStart=tick()
local _sessionLbl=NEW("TextLabel",{Text="00:00",Position=UDim2.new(1,-198,0,5),Size=UDim2.new(0,60,0,18),TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=12,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Center},TopBar)
local _uptimeIcon=NEW("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(1,-208,0,11),BackgroundTransparency=1,BorderSizePixel=0},TopBar)
do -- clock icon
    local ring=NEW("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0},_uptimeIcon); CORNER(7,ring); STROKE(TEXT3,1.2,0,ring)
    NEW("Frame",{Size=UDim2.new(0,1.5,0,5),Position=UDim2.new(0.5,-0.75,0.5,-4.5),BackgroundColor3=TEXT3,BorderSizePixel=0},_uptimeIcon)
    NEW("Frame",{Size=UDim2.new(0,4,0,1.5),Position=UDim2.new(0.5,0,0.5,-0.75),BackgroundColor3=TEXT3,BorderSizePixel=0},_uptimeIcon)
end
local _upLbl=NEW("TextLabel",{Text="UPTIME",Position=UDim2.new(1,-200,0,26),Size=UDim2.new(0,66,0,10),TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Center},TopBar)
Tooltip(_sessionLbl,"Script uptime")
-- Search button (DrawIcon magnifying glass, always renders)
local _searchBtn=NEW("TextButton",{Text="",Position=UDim2.new(1,-134,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,28,0,28),BackgroundColor3=BG3,AutoButtonColor=false},TopBar)
CORNER(7,_searchBtn); STROKE(GOLD3,1,0.4,_searchBtn)
do -- Draw magnifying glass manually
    local mg=NEW("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0},_searchBtn)
    local circle=NEW("Frame",{Size=UDim2.new(0,13,0,13),Position=UDim2.new(0,4,0,4),BackgroundTransparency=1,BorderSizePixel=0},mg); CORNER(7,circle); STROKE(GOLD2,1.8,0,circle)
    local handle=NEW("Frame",{Size=UDim2.new(0,6,0,2),Position=UDim2.new(0,16,0,19),BackgroundColor3=GOLD2,BorderSizePixel=0,Rotation=45},mg); CORNER(1,handle)
    _searchBtn.MouseEnter:Connect(function()
        TWEEN(_searchBtn,0.15,{BackgroundColor3=BG4})
        for _,ch in ipairs(mg:GetDescendants()) do
            if ch:IsA("UIStroke") then TWEEN(ch,0.15,{Color=C(255,255,255)}) end
            if ch:IsA("Frame") and ch.BackgroundColor3==GOLD2 then TWEEN(ch,0.15,{BackgroundColor3=C(255,255,255)}) end
        end
    end)
    _searchBtn.MouseLeave:Connect(function()
        TWEEN(_searchBtn,0.15,{BackgroundColor3=BG3})
        for _,ch in ipairs(mg:GetDescendants()) do
            if ch:IsA("UIStroke") then TWEEN(ch,0.15,{Color=GOLD2}) end
            if ch:IsA("Frame") and ch.BackgroundColor3~=GOLD2 then TWEEN(ch,0.15,{BackgroundColor3=GOLD2}) end
        end
    end)
end
_searchBtn.MouseButton1Click:Connect(OpenGlobalSearch)
Tooltip(_searchBtn,"Global search (all features)")

-- Session timer updater + feature counter
task.spawn(function()
    while TopBar and TopBar.Parent do
        task.wait(1)
        local elapsed=tick()-_sessionStart
        local totalSec=math.floor(elapsed)
        local weeks=math.floor(totalSec/604800); local days=math.floor((totalSec%604800)/86400)
        local h=math.floor((totalSec%86400)/3600); local m=math.floor((totalSec%3600)/60); local s=totalSec%60
        local timeStr
        if weeks>0 then timeStr=string.format("%dw %dd",weeks,days)
        elseif days>0 then timeStr=string.format("%dd %02d:%02d",days,h,m)
        elseif h>0 then timeStr=string.format("%d:%02d:%02d",h,m,s)
        else timeStr=string.format("%02d:%02d",m,s) end
        if _sessionLbl and _sessionLbl.Parent then _sessionLbl.Text=timeStr end
        local active=0
        if type(TogglesData)=="table" then
            for _,d in pairs(TogglesData) do if type(d)=="table" and d.Active then active+=1 end end
        end
        if _topSubLbl and _topSubLbl.Parent then
            _topSubLbl.Text=string.format("v2.9  ·  PREMIUM  ·  %d active",active)
            _topSubLbl.TextColor3=active>0 and COL_CFG or TEXT3
        end
        -- Pulse uptime color when features are active
        if _sessionLbl and _sessionLbl.Parent then
            _sessionLbl.TextColor3 = active>0 and COL_CFG or GOLD2
        end
    end
end)

local function MakeCtrlBtn(text,posX,col,bgCol)
    local btn=NEW("TextButton",{Text=text,Position=UDim2.new(1,posX,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,28,0,28),TextColor3=col,TextSize=15,BackgroundColor3=bgCol or BG3,Font=Enum.Font.GothamBold,AutoButtonColor=false},TopBar)
    CORNER(7,btn);STROKE(col,1,0.45,btn)
    btn.MouseEnter:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=BG4,TextColor3=C(255,255,255)}) end)
    btn.MouseLeave:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=bgCol or BG3,TextColor3=col}) end)
    return btn
end
local MinBtn=MakeCtrlBtn("-",-66,TEXT2)
local CloseBtn=MakeCtrlBtn("X",-32,RED)

-- =====================================================================
-- AUTO-HIDE SYSTEM
-- Hides hub after AUTO_HIDE_DELAY seconds of no mouse movement.
-- Any mouse movement restores it automatically.
-- =====================================================================
local AUTO_HIDE_DELAY  = 30   -- seconds (10–60); player-configurable in Config tab
local AUTO_HIDE_MIN    = 10
local AUTO_HIDE_MAX    = 60
local _autoHideTimer   = 0
local _autoHideEnabled = false
local _autoHideHidden  = false
local _autoHideOnLoad  = false  -- hide hub automatically while loading screen is up

-- Restore & hide functions (forward declared, filled in after ToggleHub is defined)
getgenv()._GBO_HideHub = function() end
getgenv()._GBO_ShowHub = function() end

task.spawn(function()
    -- FIX: Mouse movement / screen clicks only RESET the idle timer.
    -- They must NOT reopen the hub automatically — that is exclusively
    -- handled by clicking the MiniLogo button below.
    UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement then
            _autoHideTimer=0   -- reset idle counter; do NOT call ShowHub here
        end
    end)
    -- Also reset timer on any mouse button (prevents instant rehide after user
    -- opens via mini logo and immediately interacts with the hub)
    UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.MouseButton2 then
            _autoHideTimer=0
        end
    end)
    while true do
        task.wait(1)
        if _autoHideEnabled and MainFrame and MainFrame.Visible then
            _autoHideTimer+=1
            if _autoHideTimer>=AUTO_HIDE_DELAY then
                _autoHideTimer=0; _autoHideHidden=true; getgenv()._GBO_HideHub()
            end
        end
    end
end)

-- =====================================================================
-- SIDEBAR
-- =====================================================================
local Sidebar=NEW("Frame",{Size=UDim2.new(0,178,1,-50),Position=UDim2.new(0,0,0,50),BackgroundColor3=BG0,BorderSizePixel=0},MainFrame)
local sideGrad=Instance.new("UIGradient")
sideGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(14,11,30)),ColorSequenceKeypoint.new(0.4,C(10,8,22)),ColorSequenceKeypoint.new(1,C(7,5,17))})
sideGrad.Rotation=90; sideGrad.Parent=Sidebar
local sideDiv=NEW("Frame",{Size=UDim2.new(0,1,1,-8),Position=UDim2.new(1,-1,0,4),BackgroundColor3=GOLD,BackgroundTransparency=0.1,BorderSizePixel=0},Sidebar)
RegTheme(sideDiv,"BackgroundColor3","c2")

local UserCard=NEW("Frame",{Size=UDim2.new(1,-14,0,58),Position=UDim2.new(0,7,1,-64),BackgroundColor3=BG3},Sidebar)
CORNER(10,UserCard); STROKE(GOLD,1,0.7,UserCard)
local ucTopBar=NEW("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=GOLD,BorderSizePixel=0},UserCard)
local UserImg=NEW("ImageLabel",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,9,0.5,-18),BackgroundColor3=BG4},UserCard)
CORNER(18,UserImg); STROKE(GOLD,1.5,0.25,UserImg)
pcall(function() UserImg.Image=Players:GetUserThumbnailAsync(LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420) end)
NEW("TextLabel",{Text=LocalPlayer.DisplayName,Position=UDim2.new(0,52,0,8),Size=UDim2.new(1,-56,0,16),TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=12,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},UserCard)
local premBadge=NEW("Frame",{Position=UDim2.new(0,52,0,28),Size=UDim2.new(0,86,0,18),BackgroundColor3=GOLDD,BorderSizePixel=0},UserCard)
CORNER(4,premBadge); STROKE(GOLD3,1,0.2,premBadge)
-- Draw star icon manually (5 lines forming a star outline)
local starBg=NEW("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,4,0.5,-6),BackgroundTransparency=1,BorderSizePixel=0},premBadge)
do local s=12
    local function SL(x1,y1,x2,y2) local dx=x2-x1;local dy=y2-y1;local len=math.sqrt(dx*dx+dy*dy);if len<0.5 then return end;local f=NEW("Frame",{Size=UDim2.new(0,len,0,1.5),Position=UDim2.new(0,(x1+x2)/2,0,(y1+y2)/2),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=GOLD2,BorderSizePixel=0,Rotation=math.deg(math.atan2(dy,dx))},starBg);CORNER(1,f) end
    -- 5-point star lines
    local pts={{s*.5,0},{s*.62,s*.38},{s,s*.38},{s*.69,s*.62},{s*.79,s},{s*.5,s*.76},{s*.21,s},{s*.31,s*.62},{0,s*.38},{s*.38,s*.38}}
    for k=1,#pts,2 do local a,b=pts[k],pts[k+1];SL(a[1],a[2],b[1],b[2]) end
    SL(pts[#pts][1],pts[#pts][2],pts[1][1],pts[1][2])
end
NEW("TextLabel",{Text="PREMIUM",Position=UDim2.new(0,20,0,0),Size=UDim2.new(1,-22,1,0),BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left},premBadge)
task.spawn(function() while UserCard and UserCard.Parent do TWEEN(premBadge,2.0,{BackgroundColor3=GOLDD});task.wait(2.5);TWEEN(premBadge,2.0,{BackgroundColor3=C(50,38,8)});task.wait(2.5) end end)

local TabScroll=NEW("ScrollingFrame",{Size=UDim2.new(1,-8,1,-80),Position=UDim2.new(0,4,0,6),BackgroundTransparency=1,ScrollBarThickness=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),ClipsDescendants=true},Sidebar)
NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},TabScroll)
NEW("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)},TabScroll)
local PageContainer=NEW("Frame",{Size=UDim2.new(1,-178,1,-50),Position=UDim2.new(0,178,0,50),BackgroundTransparency=1},MainFrame)

-- =====================================================================
-- TAB SYSTEM
-- =====================================================================
local Tabs={}; local Pages={}; local SelectedTab=nil; local SelectedPage=nil
local TogglesData={}

local TAB_COLS={["Main"]=COL_MAIN,["Auto Farm"]=COL_FARM,["Travel"]=COL_TRAVEL,["Fishing + Merchant"]=COL_FISH,["Stats"]=COL_STATS,["Private Server"]=COL_PS,["Config"]=COL_CFG,["Misc"]=COL_MISC,["Auto Watch Ads"]=CYAN}
local TAB_ICONS={["Main"]="home",["Auto Farm"]="sword",["Travel"]="globe",["Fishing + Merchant"]="fish",["Stats"]="chart",["Config"]="gear",["Private Server"]="server",["Misc"]="wand",["Auto Watch Ads"]="lightning"}
local SEP_COLS={FARM=COL_FARM,WORLD=COL_TRAVEL,DATA=COL_STATS,SERVER=COL_PS,TOOLS=COL_MISC}

local function TabSep(label)
    local col=SEP_COLS[label] or GOLD3
    local f=NEW("Frame",{Size=UDim2.new(0,164,0,18),BackgroundTransparency=1},TabScroll)
    NEW("Frame",{Size=UDim2.new(0.28,0,0,1),Position=UDim2.new(0,6,0.5,0),BackgroundColor3=col,BorderSizePixel=0,BackgroundTransparency=0.7},f)
    NEW("Frame",{Size=UDim2.new(0.28,0,0,1),Position=UDim2.new(0.72,-6,0.5,0),BackgroundColor3=col,BorderSizePixel=0,BackgroundTransparency=0.7},f)
    NEW("TextLabel",{Text=label,Size=UDim2.new(0.44,0,1,0),Position=UDim2.new(0.28,0,0,0),BackgroundTransparency=1,TextColor3=col,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center},f)
end

-- =====================================================================
-- LAZY PAGE BUILD SYSTEM
-- Heavy tab pages (AutoFarm, Travel, Fishing, Stats) are NOT built at
-- startup. Their build functions are stored here and called only when
-- the player first clicks that tab. This is the single biggest crash fix.
-- =====================================================================
local _pageBuildFns = {}

local function AddTab(name)
    local iconName=TAB_ICONS[name] or "home"; local tabColor=TAB_COLS[name] or GOLD2
    local tabColorD=C(math.min(255,math.floor(tabColor.R*255*0.14+4)),math.min(255,math.floor(tabColor.G*255*0.14+4)),math.min(255,math.floor(tabColor.B*255*0.14+4)))
    local btn=NEW("TextButton",{Size=UDim2.new(0,162,0,40),BackgroundTransparency=1,Text="",AutoButtonColor=false,TextXAlignment=Enum.TextXAlignment.Left},TabScroll)
    CORNER(10,btn); btn.BackgroundColor3=tabColorD
    local accent=NEW("Frame",{Size=UDim2.new(0,3,0.50,0),Position=UDim2.new(0,2,0.25,0),BackgroundColor3=tabColor,BorderSizePixel=0,Visible=false},btn); CORNER(2,accent)
    local iconBg=NEW("Frame",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(0,9,0.5,-12),BackgroundColor3=tabColorD,BorderSizePixel=0},btn); CORNER(6,iconBg)
    DrawIcon(iconBg,iconName,5,5,14,tabColor)
    local nameLbl=NEW("TextLabel",{Text=name,Size=UDim2.new(1,-42,1,0),Position=UDim2.new(0,38,0,0),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},btn)
    local page=NEW("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,Name=name.."Page",ScrollBarThickness=3,ScrollBarImageColor3=tabColor,ClipsDescendants=true},PageContainer)
    Pages[name]=page
    local function setInactive()
        TWEEN(btn,0.18,{BackgroundTransparency=1}); TWEEN(nameLbl,0.18,{TextColor3=TEXT3}); nameLbl.Font=Enum.Font.GothamSemibold
        for _,ch in ipairs(iconBg:GetDescendants()) do
            if ch.Name=="SDot" then local dc=ch:GetAttribute("DotColor");local dim=dc=="GREEN" and C(20,60,35) or dc=="AMBER" and C(55,40,8) or C(65,18,18);TWEEN(ch,0.18,{BackgroundColor3=dim})
            elseif ch:IsA("Frame") then TWEEN(ch,0.18,{BackgroundColor3=TEXT3})
            elseif ch:IsA("UIStroke") then TWEEN(ch,0.18,{Color=TEXT3}) end
        end
        TWEEN(iconBg,0.18,{BackgroundColor3=C(10,10,22)}); accent.Visible=false; page.Visible=false
    end
    local function setActive()
        TWEEN(btn,0.2,{BackgroundColor3=tabColorD,BackgroundTransparency=0}); TWEEN(nameLbl,0.2,{TextColor3=tabColor}); nameLbl.Font=Enum.Font.GothamBold
        for _,ch in ipairs(iconBg:GetDescendants()) do
            if ch.Name=="SDot" then local dc=ch:GetAttribute("DotColor");local fc=dc=="GREEN" and GREEN or dc=="AMBER" and AMBER or RED;TWEEN(ch,0.2,{BackgroundColor3=fc})
            elseif ch:IsA("Frame") then TWEEN(ch,0.2,{BackgroundColor3=tabColor})
            elseif ch:IsA("UIStroke") then TWEEN(ch,0.2,{Color=tabColor}) end
        end
        TWEEN(iconBg,0.2,{BackgroundColor3=C(math.min(255,math.floor(tabColor.R*255*0.18+6)),math.min(255,math.floor(tabColor.G*255*0.18+6)),math.min(255,math.floor(tabColor.B*255*0.18+6)))})
        accent.Visible=true; page.Visible=true
    end
    Tabs[name]={btn=btn,setActive=setActive,setInactive=setInactive}
    Pages[name]=page
    btn.MouseEnter:Connect(function() if SelectedTab~=btn then TWEEN(btn,0.15,{BackgroundColor3=tabColorD,BackgroundTransparency=0.6});TWEEN(nameLbl,0.15,{TextColor3=TEXT1}) end end)
    btn.MouseLeave:Connect(function() if SelectedTab~=btn then TWEEN(btn,0.15,{BackgroundTransparency=1});TWEEN(nameLbl,0.15,{TextColor3=TEXT3}) end end)
    btn.MouseButton1Click:Connect(function()
        -- LAZY BUILD: if a build function is registered for this tab, run it once
        if _pageBuildFns[name] then
            local fn=_pageBuildFns[name]; _pageBuildFns[name]=nil
            task.spawn(fn)  -- build in background; content appears after 1 frame
        end
        if SelectedTab and SelectedTab~=btn then for _,td in pairs(Tabs) do if td.btn==SelectedTab then td.setInactive();break end end;if SelectedPage then SelectedPage.Visible=false end end
        SelectedTab=btn; SelectedPage=page; setActive()
    end)
    if SelectedTab==nil then SelectedTab=btn; SelectedPage=page; setActive() end
    return page
end

local MainPage=AddTab("Main")
local AutoFarmPage,TravelPage,StatsPage,PrivateServerPage
if not IS_LOBBY then
    TabSep("FARM"); AutoFarmPage=AddTab("Auto Farm")  -- Fishing merged into Auto Farm sub-tabs
    TabSep("WORLD"); TravelPage=AddTab("Travel"); TabSep("DATA"); StatsPage=AddTab("Stats")
end
TabSep("SERVER"); PrivateServerPage=AddTab("Private Server")
TabSep("TOOLS"); local MiscPage=IS_LOBBY and nil or AddTab("Misc"); local AdsPage=IS_LOBBY and nil or AddTab("Auto Watch Ads"); local ConfigPage=AddTab("Config")

-- =====================================================================
-- CARD HELPERS
-- =====================================================================
local function MakeCard(parent,h,layoutOrder)
    local f=NEW("Frame",{Size=UDim2.new(1,-24,0,h),BackgroundColor3=BG3,LayoutOrder=layoutOrder or 0,ClipsDescendants=true},parent)
    CORNER(10,f); STROKE(GOLD,1,0.78,f)
    NEW("Frame",{Size=UDim2.new(1,-2,0,1),Position=UDim2.new(0,1,0,0),BackgroundColor3=C(40,36,70),BorderSizePixel=0},f)
    return f
end

local function CardHeader(card,iconName,label,accentCol)
    accentCol=accentCol or GOLD
    local darkBg=C(math.min(255,math.floor(accentCol.R*255*0.06+BG_HDR.R*255*0.94)),math.min(255,math.floor(accentCol.G*255*0.06+BG_HDR.G*255*0.94)),math.min(255,math.floor(accentCol.B*255*0.06+BG_HDR.B*255*0.94)))
    local bar=NEW("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=darkBg},card); CORNER(8,bar)
    NEW("Frame",{Size=UDim2.new(1,0,0,15),Position=UDim2.new(0,0,1,-15),BackgroundColor3=darkBg,BorderSizePixel=0},bar)
    local accBar=NEW("Frame",{Size=UDim2.new(0,3,0.60,0),Position=UDim2.new(0,0,0.20,0),BackgroundColor3=accentCol,BorderSizePixel=0},bar); CORNER(2,accBar)
    local iconBg=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,8,0.5,-9),BackgroundColor3=C(math.min(255,math.floor(accentCol.R*255*0.18+8)),math.min(255,math.floor(accentCol.G*255*0.18+8)),math.min(255,math.floor(accentCol.B*255*0.18+8)))},bar)
    CORNER(5,iconBg); STROKE(accentCol,1,0.5,iconBg); DrawIcon(iconBg,iconName,2,2,14,accentCol)
    NEW("TextLabel",{Text=label,Size=UDim2.new(1,-56,1,0),Position=UDim2.new(0,33,0,0),BackgroundTransparency=1,TextColor3=accentCol,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},bar)
    NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=accentCol,BorderSizePixel=0,BackgroundTransparency=0.55},bar)
    -- Collapse chevron (Frame-based, always renders)
    local _collapsed=false
    local _fullH=card.Size.Y.Offset
    local chevBg=NEW("Frame",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-24,0.5,-10),BackgroundTransparency=1,BorderSizePixel=0},bar)
    -- Down arrow (two lines): renders as ∨
    local chL1=NEW("Frame",{Size=UDim2.new(0,8,0,2),Position=UDim2.new(0,1,0.5,-1),BackgroundColor3=accentCol,BorderSizePixel=0,Rotation=40},chevBg); CORNER(1,chL1)
    local chL2=NEW("Frame",{Size=UDim2.new(0,8,0,2),Position=UDim2.new(0,11,0.5,-1),BackgroundColor3=accentCol,BorderSizePixel=0,Rotation=-40},chevBg); CORNER(1,chL2)
    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        _collapsed=not _collapsed
        if _collapsed then
            TWEEN(card,0.2,{Size=UDim2.new(1,-24,0,30)})
            TWEEN(chL1,0.2,{Rotation=-40,BackgroundColor3=TEXT3})
            TWEEN(chL2,0.2,{Rotation=40,BackgroundColor3=TEXT3})
        else
            TWEEN(card,0.22,{Size=UDim2.new(1,-24,0,_fullH)})
            TWEEN(chL1,0.2,{Rotation=40,BackgroundColor3=accentCol})
            TWEEN(chL2,0.2,{Rotation=-40,BackgroundColor3=accentCol})
        end
    end)
    return bar
end

local function RowDivider(card,posY)
    NEW("Frame",{Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,0,posY),BackgroundColor3=C(22,20,48),BorderSizePixel=0},card)
end
local function RowLabel(card,mainText,subText,posY)
    NEW("TextLabel",{Text=mainText,Size=UDim2.new(0.62,0,0,22),Position=UDim2.new(0,14,0,posY),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},card)
    if subText then NEW("TextLabel",{Text=subText,Size=UDim2.new(0.68,0,0,13),Position=UDim2.new(0,14,0,posY+21),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},card) end
end

local function CardToggle(card,posY,configKey,callback,accentCol)
    accentCol=accentCol or GOLD2
    local accentDark=C(math.min(255,math.floor(accentCol.R*255*0.16+3)),math.min(255,math.floor(accentCol.G*255*0.16+3)),math.min(255,math.floor(accentCol.B*255*0.16+3)))
    local pill=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-60,0,posY),BackgroundColor3=BG5,Text="",AutoButtonColor=false},card)
    CORNER(20,pill); local strk=STROKE(TEXT3,1.2,0.3,pill)
    local thumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},pill); CORNER(20,thumb)
    TogglesData[configKey]={Active=false,Btn=pill,Strk=strk,Thumb=thumb,Callback=callback or function() end,AccentCol=accentCol,AccentDark=accentDark}
    pill.MouseButton1Click:Connect(function()
        local d=TogglesData[configKey]; d.Active=not d.Active; local on=d.Active
        local ac=d.AccentCol or GOLD2; local ad=d.AccentDark or GOLDD
        TWEEN(pill,0.22,{BackgroundColor3=on and ad or BG5}); TWEEN(strk,0.22,{Color=on and ac or TEXT3,Transparency=on and 0 or 0.3})
        TWEEN(thumb,0.22,{BackgroundColor3=on and ac or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)})
        -- Toast notification
        Toast((on and "ON" or "OFF").."  "..configKey:gsub("([A-Z])"," %1"):gsub("^%s",""), on and ac or TEXT2, on and "+" or "-")
        if d.Callback then d.Callback(on) end
    end)
    return pill,strk,thumb
end

local function PageLayout(page,padTop,gap)
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.CanvasSize=UDim2.new(0,0,0,0)
    NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,gap or 10)},page)
    NEW("UIPadding",{PaddingTop=UDim.new(0,padTop or 14),PaddingBottom=UDim.new(0,14)},page)
end

-- =====================================================================
-- MINIMIZE / SHOW (ToggleHub)
-- =====================================================================
local function ToggleHub(isVisible)
    if not isVisible then
        TweenService:Create(MainFrame,TweenInfo.new(0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=MiniLogo.Position,Size=UDim2.new(0,0,0,0),GroupTransparency=1}):Play()
        task.wait(0.38); MainFrame.Visible=false; MiniLogo.Visible=true
    else
        MiniLogo.Visible=false; MainFrame.Visible=true
        MainFrame.Position=MiniLogo.Position; MainFrame.Size=UDim2.new(0,0,0,0); MainFrame.GroupTransparency=1
        TweenService:Create(MainFrame,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-360,0.5,-260),Size=UDim2.new(0,720,0,520),GroupTransparency=0}):Play()
    end
end
-- Wire up the global functions used by auto-hide and mini-logo click
getgenv()._GBO_HideHub = function() ToggleHub(false) end
getgenv()._GBO_ShowHub = function() ToggleHub(true)  end

MinBtn.MouseButton1Click:Connect(function() ToggleHub(false) end)
-- NOTE: MiniLogo re-open is handled via getgenv()._GBO_ShowHub in the InputEnded drag-fix above

-- =====================================================================
-- MAIN PAGE
-- =====================================================================
PageLayout(MainPage,14,10)
-- Register features visible on both lobby and game world
RegSearch("Auto Hide UI","Config","Auto-hide hub after inactivity","AutoHide")
RegSearch("Color Theme","Config","Switch accent color preset","")
RegSearch("Keybind Toggle","Config","Set key to show/hide hub","")

-- =====================================================================
-- MULTI-ACC UI — split into 3 top-level functions so each has its own
-- Lua 5.1 register pool (limit = 200 per function, not per file).
--
-- st = shared state table passed between functions:
--   st.scroll, st.emptyLbl, st.accentCol, st.CYAND2
--   st.fmTitle, st.fmName, st.fmPS, st.fmCfg
--   st.fmHub, st.fmSea
--   st.fmHubBtns, st.fmSeaBtns
--   st.editIdx, st.refresh (fn)
-- =====================================================================

    -- Export vars needed outside _buildSidebar
    return MainFrame,
           TopBar,
           ring,
           circle,
           handle,
           CloseBtn,
           AUTO_HIDE_DELAY,
           AUTO_HIDE_MIN,
           AUTO_HIDE_MAX,
           _autoHideTimer,
           _autoHideEnabled,
           _autoHideHidden,
           _autoHideOnLoad,
           TogglesData,
           _pageBuildFns,
           MainPage,
           AutoFarmPage,
           TravelPage,
           StatsPage,
           PrivateServerPage,
           MakeCard,
           CardHeader,
           RowDivider,
           RowLabel,
           CardToggle,
           PageLayout,
           ToggleHub,
           TabBadge,
           RegSearch
    end -- _buildSidebar
    local MainFrame,TopBar,ring,circle,handle,CloseBtn,AUTO_HIDE_DELAY,AUTO_HIDE_MIN,AUTO_HIDE_MAX,_autoHideTimer,_autoHideEnabled,_autoHideHidden,_autoHideOnLoad,TogglesData,_pageBuildFns,MainPage,AutoFarmPage,TravelPage,StatsPage,PrivateServerPage,MakeCard,CardHeader,RowDivider,RowLabel,CardToggle,PageLayout,ToggleHub,TabBadge,RegSearch
    = _buildSidebar()
local MULTIACC_FILE = "Zili_Hub/multiaccs.json"
local _maccs = {}

local function MA_Load()
    _maccs = {}
    pcall(function()
        if isfile and isfile(MULTIACC_FILE) then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(MULTIACC_FILE)) end)
            if ok and type(decoded) == "table" then _maccs = decoded end
        end
    end)
end
local function MA_Save()
    pcall(function()
        if writefile then writefile(MULTIACC_FILE, HttpService:JSONEncode(_maccs)) end
    end)
end
getgenv()._ZiliMultiAcc = {
    Load=MA_Load, Save=MA_Save,
    GetAll=function() return _maccs end,
    SetAll=function(t) _maccs=t; MA_Save() end,
}
MA_Load()

-- ── Detect ngay nếu player hiện tại có trong _maccs list ─────────────
-- Phải set TRƯỚC khi IS_LOBBY block chạy để block DoJoinPS default
do
    local _myName = game:GetService("Players").LocalPlayer.Name
    getgenv()._ZiliMultiAccData = nil  -- reset
    for _, _acc in ipairs(_maccs) do
        if _acc.name == _myName then
            getgenv()._ZiliMultiAccData = {
                name       = _acc.name,
                psCode     = _acc.psCode     or "",
                configName = _acc.configName or "",
                hub        = _acc.hub        or "Regular",
                sea        = _acc.sea        or "Sea 1",
            }
            break
        end
    end
end

-- ── 1. List renderer ─────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════
-- MULTI-ACCOUNT  (v3 – slide-in form, card resizes, proper close)
-- ═══════════════════════════════════════════════════════════════════
local _MA_BASE_H = 260   -- card height when form is CLOSED
local _MA_FORM_H = 245   -- height of the slide-in form panel
-- list scroll height = _MA_BASE_H - 30(header) - 34(toolbar) - 1(sep) - 8(pad) = 187

local function MA_RenderList(st)
    for _,c in ipairs(st.scroll:GetChildren()) do
        if c:IsA("Frame") or (c:IsA("TextLabel") and c~=st.emptyLbl) then c:Destroy() end
    end
    st.emptyLbl.Parent=nil
    if #_maccs==0 then st.emptyLbl.Parent=st.scroll; return end
    for idx,acc in ipairs(_maccs) do
        local ac=st.accentCol
        local hubCol=(acc.hub=="Fish Hub" and COL_FISH) or (acc.hub=="Trade Hub" and AMBER) or (acc.hub=="Universe Hub" and COL_STATS) or ac
        local row=NEW("Frame",{Size=UDim2.new(1,-8,0,62),BackgroundColor3=C(11,12,28),LayoutOrder=idx,BorderSizePixel=0},st.scroll)
        CORNER(9,row); local rowStrk=STROKE(C(20,50,56),1,0.4,row)
        NEW("Frame",{Size=UDim2.new(0,3,0.7,0),Position=UDim2.new(0,0,0.15,0),BackgroundColor3=hubCol,BorderSizePixel=0},row)
        local initBg=NEW("Frame",{Size=UDim2.new(0,38,0,38),Position=UDim2.new(0,10,0.5,-19),BackgroundColor3=C(math.floor(hubCol.R*255*0.12),math.floor(hubCol.G*255*0.12),math.floor(hubCol.B*255*0.12)),BorderSizePixel=0},row);CORNER(19,initBg);STROKE(hubCol,1.2,0.2,initBg)
        NEW("TextLabel",{Text=(acc.name or "?"):sub(1,1):upper(),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=hubCol,Font=Enum.Font.GothamBold,TextSize=17,TextXAlignment=Enum.TextXAlignment.Center},initBg)
        NEW("TextLabel",{Text=acc.name or "?",Size=UDim2.new(0,155,0,18),Position=UDim2.new(0,56,0,7),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},row)
        local dest=(acc.hub=="Regular" or not acc.hub) and ("Regular / "..(acc.sea or "Sea 1")) or (acc.hub or "Regular")
        local destPill=NEW("Frame",{Size=UDim2.new(0,0,0,17),Position=UDim2.new(0,56,0,28),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=C(math.floor(hubCol.R*255*0.14),math.floor(hubCol.G*255*0.14),math.floor(hubCol.B*255*0.14)),BorderSizePixel=0},row);CORNER(9,destPill);STROKE(hubCol,1,0.35,destPill)
        NEW("UIPadding",{PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)},destPill)
        NEW("TextLabel",{Text=dest,Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,TextColor3=hubCol,Font=Enum.Font.GothamBold,TextSize=9},destPill)
        local eb=NEW("TextButton",{Size=UDim2.new(0,52,0,21),Position=UDim2.new(1,-114,1,-27),BackgroundColor3=C(16,20,40),Text="EDIT",TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=9,AutoButtonColor=false},row);CORNER(6,eb);STROKE(GOLD3,1,0.3,eb)
        local db=NEW("TextButton",{Size=UDim2.new(0,52,0,21),Position=UDim2.new(1,-58,1,-27),BackgroundColor3=C(36,8,8),Text="REMOVE",TextColor3=RED,Font=Enum.Font.GothamBold,TextSize=9,AutoButtonColor=false},row);CORNER(6,db);STROKE(RED,1,0.35,db)
        eb.MouseEnter:Connect(function() TWEEN(eb,0.1,{BackgroundColor3=C(25,30,60)}) end)
        eb.MouseLeave:Connect(function() TWEEN(eb,0.1,{BackgroundColor3=C(16,20,40)}) end)
        db.MouseEnter:Connect(function() TWEEN(db,0.1,{BackgroundColor3=C(55,12,12)}) end)
        db.MouseLeave:Connect(function() TWEEN(db,0.1,{BackgroundColor3=C(36,8,8)}) end)
        row.MouseEnter:Connect(function() TWEEN(rowStrk,0.12,{Transparency=0,Color=hubCol}) end)
        row.MouseLeave:Connect(function() TWEEN(rowStrk,0.12,{Transparency=0.4,Color=C(20,50,56)}) end)
        local ci=idx
        eb.MouseButton1Click:Connect(function()
            st.editIdx=ci; local a=_maccs[ci]
            st.fmTitle.Text="EDIT: "..(a.name or "?")
            st.fmName.Text=a.name or ""; st.fmPS.Text=a.psCode or ""; st.fmCfg.Text=a.configName or ""
            st.fmHub=a.hub or "Regular"; st.fmSea=a.sea or "Sea 1"
            for _,d in ipairs(st.fmHubBtns) do
                local sel=d.lbl==st.fmHub
                TWEEN(d.btn,0.14,{BackgroundColor3=sel and C(math.floor(d.col.R*255*0.12),math.floor(d.col.G*255*0.12),math.floor(d.col.B*255*0.12)) or C(8,9,22),BackgroundTransparency=sel and 0 or 0.3})
                TWEEN(d.sk,0.14,{Color=sel and d.col or C(35,35,55),Transparency=sel and 0.05 or 0.55})
                d.btn.TextColor3=sel and d.col or TEXT3; d.btn.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
            end
            for _,d in ipairs(st.fmSeaBtns) do
                local sel=d.lbl==st.fmSea
                TWEEN(d.btn,0.14,{BackgroundColor3=sel and C(4,18,44) or C(8,9,22),BackgroundTransparency=sel and 0 or 0.3})
                TWEEN(d.sk,0.14,{Color=sel and COL_FISH or C(35,35,55),Transparency=sel and 0.05 or 0.55})
                d.btn.TextColor3=sel and COL_FISH or TEXT3; d.btn.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
            end
            if st.openForm then st.openForm(true) end  -- true = keep title as-is
        end)
        db.MouseButton1Click:Connect(function()
            table.remove(_maccs,ci); MA_Save(); st.refresh()
            Toast("Removed: "..(acc.name or "?"),RED,"-")
        end)
    end
end

local function MA_BuildForm(maCard, st)
    local ac=st.accentCol; local CYAD=st.CYAND2

    -- ── Form panel: HIDDEN by default (Visible=false avoids stroke flicker) ──
    local formPanel=NEW("Frame",{
        Size=UDim2.new(1,-16,0,_MA_FORM_H),
        Position=UDim2.new(0,8,0,_MA_BASE_H+6),
        BackgroundColor3=C(9,10,24), BorderSizePixel=0,
        ClipsDescendants=true, Visible=false,
    },maCard)
    CORNER(10,formPanel)
    local formStrk=STROKE(ac,1,0.2,formPanel)

    -- ── Form header ──
    local fmHdr=NEW("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C(6,22,26),BorderSizePixel=0},formPanel);CORNER(9,fmHdr)
    NEW("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-16),BackgroundColor3=C(6,22,26),BorderSizePixel=0},fmHdr)
    -- accent bar left
    local fmAccBar=NEW("Frame",{Size=UDim2.new(0,3,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=ac,BorderSizePixel=0},fmHdr);CORNER(2,fmAccBar)
    -- divider line bottom of header
    NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=ac,BackgroundTransparency=0.7,BorderSizePixel=0},fmHdr)
    st.fmTitle=NEW("TextLabel",{Text="+ ADD ACCOUNT",Size=UDim2.new(1,-44,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,TextColor3=ac,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},fmHdr)
    -- Close button with drawn X
    local fmClose=NEW("TextButton",{Size=UDim2.new(0,32,0,32),Position=UDim2.new(1,-32,0,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=10},fmHdr)
    do  -- draw X using two diagonal lines
        local function XL(r) local f=NEW("Frame",{Size=UDim2.new(0,14,0,2),Position=UDim2.new(0.5,-7,0.5,-1),BackgroundColor3=TEXT2,BorderSizePixel=0,Rotation=r,ZIndex=11},fmClose);CORNER(1,f) end
        XL(45); XL(-45)
    end
    fmClose.MouseEnter:Connect(function() for _,c in ipairs(fmClose:GetChildren()) do if c:IsA("Frame") then TWEEN(c,0.1,{BackgroundColor3=RED}) end end end)
    fmClose.MouseLeave:Connect(function() for _,c in ipairs(fmClose:GetChildren()) do if c:IsA("Frame") then TWEEN(c,0.1,{BackgroundColor3=TEXT2}) end end end)

    -- ── CloseForm: hides panel AND shrinks card ──
    local function CloseForm()
        formPanel.Visible=false
        TWEEN(maCard,0.22,{Size=UDim2.new(1,-24,0,_MA_BASE_H)})
    end
    fmClose.MouseButton1Click:Connect(CloseForm)

    -- ── Input field helper ──
    local function FI(lbl,ph,px,py,w)
        w=w or 148
        NEW("TextLabel",{Text=lbl,Size=UDim2.new(0,w,0,12),Position=UDim2.new(0,px,0,py),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},formPanel)
        local bg=NEW("Frame",{Size=UDim2.new(0,w,0,26),Position=UDim2.new(0,px,0,py+13),BackgroundColor3=BG5,BorderSizePixel=0},formPanel);CORNER(7,bg)
        local sk=STROKE(C(28,26,55),1,0.3,bg)
        local tb=NEW("TextBox",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text="",PlaceholderText=ph,TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=11,ClearTextOnFocus=false},bg)
        tb.Focused:Connect(function() TWEEN(sk,0.15,{Color=ac,Transparency=0}) end)
        tb.FocusLost:Connect(function() TWEEN(sk,0.15,{Color=C(28,26,55),Transparency=0.3}) end)
        return tb
    end
    -- Two inputs side by side: Name | PS Code
    st.fmName=FI("Player Name","Roblox username...",10,38)
    st.fmPS=FI("Private Server Code","Paste PS code (optional)...",166,38)
    -- Config full width
    st.fmCfg=FI("Config Profile (optional)","e.g. myconfig",10,83,300)

    -- ── Section divider ──
    local function SecLabel(txt,y)
        local sf=NEW("Frame",{Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,0,y),BackgroundColor3=C(20,40,50),BorderSizePixel=0},formPanel)
        NEW("TextLabel",{Text=txt,Size=UDim2.new(0,0,0,12),Position=UDim2.new(0,0,0,-6),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=C(9,10,24),BorderSizePixel=0,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2},sf)
        NEW("UIPadding",{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)},sf:FindFirstChildOfClass("TextLabel"))
        return sf
    end
    SecLabel("HUB", 123)

    -- ── Hub pills ──
    local HUB_LIST={{lbl="Regular",col=ac},{lbl="Fish Hub",col=COL_FISH},{lbl="Trade Hub",col=AMBER},{lbl="Universe Hub",col=COL_STATS}}
    st.fmHubBtns={}
    for i,hd in ipairs(HUB_LIST) do
        local hb=NEW("TextButton",{Size=UDim2.new(0,72,0,24),Position=UDim2.new(0,10+(i-1)*78,0,132),BackgroundColor3=C(8,9,22),BackgroundTransparency=0.25,Text=hd.lbl,TextColor3=TEXT3,Font=Enum.Font.GothamSemibold,TextSize=9,AutoButtonColor=false},formPanel);CORNER(12,hb)
        local hsk=STROKE(C(30,30,55),1,0.5,hb)
        table.insert(st.fmHubBtns,{btn=hb,sk=hsk,lbl=hd.lbl,col=hd.col})
        hb.MouseButton1Click:Connect(function()
            st.fmHub=hd.lbl
            for _,d in ipairs(st.fmHubBtns) do
                local sel=d.lbl==st.fmHub
                local dc=C(math.floor(d.col.R*255*0.14),math.floor(d.col.G*255*0.14),math.floor(d.col.B*255*0.14))
                TWEEN(d.btn,0.15,{BackgroundColor3=sel and dc or C(8,9,22),BackgroundTransparency=sel and 0 or 0.2})
                TWEEN(d.sk,0.15,{Color=sel and d.col or C(30,30,55),Transparency=sel and 0 or 0.5})
                d.btn.TextColor3=sel and d.col or TEXT3; d.btn.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
            end
        end)
    end
    -- init Regular selected
    do local d=st.fmHubBtns[1];local dc=C(math.floor(d.col.R*255*0.14),math.floor(d.col.G*255*0.14),math.floor(d.col.B*255*0.14));d.btn.BackgroundColor3=dc;d.btn.BackgroundTransparency=0;d.sk.Color=d.col;d.sk.Transparency=0;d.btn.TextColor3=d.col;d.btn.Font=Enum.Font.GothamBold end

    SecLabel("SEA", 162)

    -- ── Sea pills ──
    st.fmSeaBtns={}
    for i,sl in ipairs({"Sea 1","Sea 2"}) do
        local sb=NEW("TextButton",{Size=UDim2.new(0,62,0,24),Position=UDim2.new(0,10+(i-1)*68,0,172),BackgroundColor3=C(8,9,22),BackgroundTransparency=0.2,Text=sl,TextColor3=TEXT3,Font=Enum.Font.GothamMedium,TextSize=9,AutoButtonColor=false},formPanel);CORNER(12,sb)
        local ssk=STROKE(C(30,30,55),1,0.5,sb)
        table.insert(st.fmSeaBtns,{btn=sb,sk=ssk,lbl=sl})
        sb.MouseButton1Click:Connect(function()
            st.fmSea=sl
            for _,d in ipairs(st.fmSeaBtns) do
                local sel=d.lbl==st.fmSea
                TWEEN(d.btn,0.15,{BackgroundColor3=sel and C(4,18,44) or C(8,9,22),BackgroundTransparency=sel and 0 or 0.2})
                TWEEN(d.sk,0.15,{Color=sel and COL_FISH or C(30,30,55),Transparency=sel and 0 or 0.5})
                d.btn.TextColor3=sel and COL_FISH or TEXT3; d.btn.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
            end
        end)
    end
    do local d=st.fmSeaBtns[1];d.btn.BackgroundColor3=C(4,18,44);d.btn.BackgroundTransparency=0;d.sk.Color=COL_FISH;d.sk.Transparency=0;d.btn.TextColor3=COL_FISH;d.btn.Font=Enum.Font.GothamBold end


    -- ── Save / Cancel ──
    local fmSave=NEW("TextButton",{
        Size=UDim2.new(0.55,-8,0,30),Position=UDim2.new(0,10,0,208),
        BackgroundColor3=CYAD,Text="SAVE ACCOUNT",TextColor3=ac,
        Font=Enum.Font.GothamBold,TextSize=11,AutoButtonColor=false,
    },formPanel);CORNER(8,fmSave);STROKE(ac,1.2,0.1,fmSave)
    local fmCancel=NEW("TextButton",{
        Size=UDim2.new(0.45,-8,0,30),Position=UDim2.new(0.55,2,0,208),
        BackgroundColor3=C(18,16,36),Text="CANCEL",TextColor3=TEXT2,
        Font=Enum.Font.GothamBold,TextSize=11,AutoButtonColor=false,
    },formPanel);CORNER(8,fmCancel);STROKE(TEXT3,1,0.5,fmCancel)
    fmSave.MouseEnter:Connect(function() TWEEN(fmSave,0.12,{BackgroundColor3=C(6,50,48),TextColor3=C(210,255,252)}) end)
    fmSave.MouseLeave:Connect(function() TWEEN(fmSave,0.12,{BackgroundColor3=CYAD,TextColor3=ac}) end)
    fmCancel.MouseEnter:Connect(function() TWEEN(fmCancel,0.12,{BackgroundColor3=C(30,26,55)}) end)
    fmCancel.MouseLeave:Connect(function() TWEEN(fmCancel,0.12,{BackgroundColor3=C(18,16,36)}) end)

    local function ResetSelections()
        for j,d in ipairs(st.fmHubBtns) do
            local sel=(j==1)
            local dc=C(math.floor(d.col.R*255*0.14),math.floor(d.col.G*255*0.14),math.floor(d.col.B*255*0.14))
            d.btn.BackgroundColor3=sel and dc or C(8,9,22); d.btn.BackgroundTransparency=sel and 0 or 0.2
            d.sk.Color=sel and d.col or C(30,30,55); d.sk.Transparency=sel and 0 or 0.5
            d.btn.TextColor3=sel and d.col or TEXT3; d.btn.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end
        for j,d in ipairs(st.fmSeaBtns) do
            local sel=(j==1)
            d.btn.BackgroundColor3=sel and C(4,18,44) or C(8,9,22); d.btn.BackgroundTransparency=sel and 0 or 0.2
            d.sk.Color=sel and COL_FISH or C(30,30,55); d.sk.Transparency=sel and 0 or 0.5
            d.btn.TextColor3=sel and COL_FISH or TEXT3; d.btn.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end
    end

    fmSave.MouseButton1Click:Connect(function()
        local nm=st.fmName.Text:match("^%s*(.-)%s*$")
        if nm=="" then Toast("Player name required",RED,"-"); return end
        local entry={name=nm,psCode=st.fmPS.Text:match("^%s*(.-)%s*$"),hub=st.fmHub,sea=st.fmSea,configName=st.fmCfg.Text:match("^%s*(.-)%s*$")}
        if st.editIdx then _maccs[st.editIdx]=entry else table.insert(_maccs,entry) end
        MA_Save(); st.refresh()
        Toast((st.editIdx and "Updated: " or "Added: ")..nm,ac,"+")
        st.editIdx=nil; st.fmName.Text=""; st.fmPS.Text=""; st.fmCfg.Text=""
        st.fmHub="Regular"; st.fmSea="Sea 1"
        ResetSelections(); CloseForm()
    end)
    fmCancel.MouseButton1Click:Connect(function()
        st.editIdx=nil; st.fmName.Text=""; st.fmPS.Text=""; st.fmCfg.Text=""
        st.fmHub="Regular"; st.fmSea="Sea 1"
        ResetSelections(); CloseForm()
    end)

    -- ── OpenForm: show panel + expand card ──
    local function OpenForm(keepTitle)
        if not keepTitle then
            st.editIdx=nil; st.fmTitle.Text="+ ADD ACCOUNT"
            st.fmName.Text=""; st.fmPS.Text=""; st.fmCfg.Text=""
            st.fmHub="Regular"; st.fmSea="Sea 1"
            ResetSelections()
        end
        formPanel.Visible=true
        -- Expand card to fit list + form
        TWEEN(maCard,0.25,{Size=UDim2.new(1,-24,0,_MA_BASE_H+_MA_FORM_H+8)})
    end
    st.openForm=OpenForm
    return OpenForm
end

local function BuildMultiAccCard(page, layoutOrder, accentCol)
    accentCol=accentCol or CYAN
    local CYAND2=C(3,30,32)
    -- Card starts at base height; expands when form opens
    local maCard=MakeCard(page,_MA_BASE_H,layoutOrder)
    CardHeader(maCard,"user","MULTI-ACCOUNT",accentCol)

    -- Toolbar: count + ADD button
    local maCountLbl=NEW("TextLabel",{Text="No accounts",Size=UDim2.new(0,140,0,24),Position=UDim2.new(0,12,0,34),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},maCard)
    local maAddBtn=NEW("TextButton",{
        Size=UDim2.new(0,110,0,27), Position=UDim2.new(1,-118,0,31),
        BackgroundColor3=CYAND2, Text="+ ADD ACCOUNT", TextColor3=accentCol,
        Font=Enum.Font.GothamBold, TextSize=9, AutoButtonColor=false,
    },maCard); CORNER(8,maAddBtn); STROKE(accentCol,1,0.25,maAddBtn)
    maAddBtn.MouseEnter:Connect(function() TWEEN(maAddBtn,0.12,{BackgroundColor3=C(6,48,48),TextColor3=C(210,255,252)}) end)
    maAddBtn.MouseLeave:Connect(function() TWEEN(maAddBtn,0.12,{BackgroundColor3=CYAND2,TextColor3=accentCol}) end)

    -- Separator
    NEW("Frame",{Size=UDim2.new(1,-16,0,1),Position=UDim2.new(0,8,0,62),BackgroundColor3=C(18,38,46),BorderSizePixel=0},maCard)

    -- Account scroll list
    local listH = _MA_BASE_H - 30 - 34 - 1 - 6  -- = 189
    local maScroll=NEW("ScrollingFrame",{
        Size=UDim2.new(1,-16,0,listH), Position=UDim2.new(0,8,0,65),
        BackgroundColor3=C(6,7,16), BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=accentCol,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
        ClipsDescendants=true,
    },maCard); CORNER(8,maScroll); STROKE(C(14,40,50),1,0.5,maScroll)
    NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Center},maScroll)
    NEW("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},maScroll)
    local maEmptyLbl=NEW("TextLabel",{
        Text="No accounts added yet.\nPress  + ADD ACCOUNT  to create one.",
        Size=UDim2.new(1,-16,0,64), BackgroundTransparency=1,
        TextColor3=TEXT3, Font=Enum.Font.GothamMedium, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Center, TextWrapped=true,
    },maScroll)

    local st={
        scroll=maScroll, emptyLbl=maEmptyLbl, countLbl=maCountLbl,
        accentCol=accentCol, CYAND2=CYAND2,
        fmHub="Regular", fmSea="Sea 1", editIdx=nil,
        fmHubBtns={}, fmSeaBtns={},
        fmName=nil, fmPS=nil, fmCfg=nil,
        fmTitle=nil,
        formPanel=nil, openForm=nil, refresh=nil,
    }
    st.refresh=function()
        MA_RenderList(st)
        local n=#_maccs
        if st.countLbl and st.countLbl.Parent then
            st.countLbl.Text=n==0 and "No accounts" or (n.." account"..(n>1 and "s" or ""))
            st.countLbl.TextColor3=n>0 and accentCol or TEXT3
        end
    end

    local openForm=MA_BuildForm(maCard,st)
    maAddBtn.MouseButton1Click:Connect(function() openForm(false) end)
    st.refresh()
    return maCard
end

-- =====================================================================
-- GAME WORLD PRIVATE SERVER PAGE BUILDER
-- Extracted into its own top-level function to stay under Lua 5.1's
-- 200-local-register limit. Receives page + TogglesData as parameters.
-- =====================================================================
local function BuildGWPSPage(PrivateServerPage, TogglesData)
    PageLayout(PrivateServerPage,14,10)
    getgenv().PSCode      = getgenv().PSCode      or ""
    getgenv().SelectedHub = getgenv().SelectedHub  or "Regular"
    getgenv().SelectedSea = getgenv().SelectedSea  or "Sea 1"

    local HUB_GRID = {
        {id="Regular",     label="Regular",      icon="globe",   col=COL_TRAVEL},
        {id="Trade Hub",   label="Trade Hub",    icon="coin",    col=AMBER},
        {id="Universe Hub",label="Universe Hub", icon="target",  col=COL_STATS},
        {id="Fish Hub",    label="Fish Hub",     icon="fish",    col=COL_FISH},
    }
    local SEA_OPTS = {{id="Sea 1",label="SEA 1",remote="First Sea"},{id="Sea 2",label="SEA 2",remote="Second Sea"}}
    local HubBtns  = {}
    local SeaBtns  = {}
    local seaHdrLbl
    local autoJoinActive = false

    local function FireSeaRemote(remoteName)
        pcall(function()
            local function getNil(name,class)
                for _,v in next,getnilinstances() do
                    if v.ClassName==class and v.Name==name then return v end
                end
            end
            getNil("RemoteEvent","RemoteEvent"):FireServer(remoteName)
        end)
    end
    local psBox

    local function ApplyPill(pill,strk,thumb,on,ac,ad)
        TWEEN(pill,0.22,{BackgroundColor3=on and ad or BG5})
        TWEEN(strk,0.22,{Color=on and ac or TEXT3,Transparency=on and 0 or 0.3})
        TWEEN(thumb,0.22,{BackgroundColor3=on and ac or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)})
    end
    local function UpdateHub()
        for _,hd in ipairs(HUB_GRID) do
            local d=HubBtns[hd.id]; if not d then continue end
            local sel=(hd.id==getgenv().SelectedHub); local ac=hd.col
            local acd=C(math.min(255,math.floor(ac.R*255*0.15+5)),math.min(255,math.floor(ac.G*255*0.15+5)),math.min(255,math.floor(ac.B*255*0.15+5)))
            TWEEN(d.Btn,0.18,{BackgroundColor3=sel and acd or BG4,BackgroundTransparency=sel and 0 or 0.3})
            TWEEN(d.Strk,0.18,{Color=sel and ac or C(35,35,55),Transparency=sel and 0.1 or 0.6})
            TWEEN(d.Lbl,0.18,{TextColor3=sel and ac or TEXT2}); d.Lbl.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
            for _,ch in ipairs(d.IcoBg:GetDescendants()) do
                if ch:IsA("Frame") then TWEEN(ch,0.18,{BackgroundColor3=sel and ac or TEXT3}) end
                if ch:IsA("UIStroke") then TWEEN(ch,0.18,{Color=sel and ac or TEXT3}) end
            end
        end
        local isReg=(getgenv().SelectedHub=="Regular")
        if seaHdrLbl then seaHdrLbl.Visible=isReg end
        for _,sd in ipairs(SEA_OPTS) do if SeaBtns[sd.id] then SeaBtns[sd.id].Btn.Visible=isReg end end
        if TogglesData["Config_SelectedHub"] then TogglesData["Config_SelectedHub"].Value=getgenv().SelectedHub end
    end
    local function UpdateSea()
        for _,sd in ipairs(SEA_OPTS) do
            local d=SeaBtns[sd.id]; if not d then continue end
            local sel=(getgenv().SelectedSea==sd.id)
            TWEEN(d.Btn,0.15,{BackgroundColor3=sel and C(8,18,44) or BG4,BackgroundTransparency=sel and 0 or 0.3})
            TWEEN(d.Strk,0.15,{Color=sel and COL_FISH or C(35,35,55),Transparency=sel and 0.1 or 0.6})
            TWEEN(d.Lbl,0.15,{TextColor3=sel and COL_FISH or TEXT2}); d.Lbl.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end
        if TogglesData["Config_SelectedSea"] then TogglesData["Config_SelectedSea"].Value=getgenv().SelectedSea end
    end

    -- ── Current server card ────────────────────────────────────────────
    local function GetPSCode()
        local code=""
        pcall(function() local rc=game:GetService("ReplicatedStorage"):FindFirstChild("reservedCode"); if rc and rc.Value and rc.Value~="" then code=rc.Value end end)
        if code=="" then pcall(function() code=game.PrivateServerAccessKey or "" end) end
        if code=="" then pcall(function() code=game.PrivateServerId or "" end) end
        return code
    end
    local _psCode=GetPSCode(); local isInPS=(_psCode~="")
    local psShort=isInPS and (string.sub(_psCode,1,8).."...") or "Public Server"
    local srvCard=MakeCard(PrivateServerPage,80,0); CardHeader(srvCard,isInPS and "server" or "globe","CURRENT SERVER",isInPS and GREEN or RED)
    local srvBadge=NEW("Frame",{Size=UDim2.new(0,74,0,22),Position=UDim2.new(1,-86,0,32),BackgroundColor3=isInPS and C(5,36,18) or C(36,8,8),BorderSizePixel=0},srvCard); CORNER(5,srvBadge); STROKE(isInPS and GREEN or RED,1,0.3,srvBadge)
    NEW("Frame",{Size=UDim2.new(0,7,0,7),Position=UDim2.new(0,7,0.5,-3.5),BackgroundColor3=isInPS and GREEN or RED,BorderSizePixel=0},srvBadge); CORNER(4,srvBadge:FindFirstChildOfClass("Frame"))
    NEW("TextLabel",{Text=isInPS and "PRIVATE" or "PUBLIC",Size=UDim2.new(1,-18,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1,TextColor3=isInPS and GREEN or RED,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},srvBadge)
    NEW("TextLabel",{Text="ID: "..psShort,Size=UDim2.new(1,-96,0,14),Position=UDim2.new(0,12,0,34),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},srvCard)
    NEW("TextLabel",{Text="Job: "..string.sub(game.JobId,1,16).."…",Size=UDim2.new(1,-96,0,12),Position=UDim2.new(0,12,0,52),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},srvCard)
    local copyBtn=NEW("TextButton",{Text=isInPS and "COPY CODE" or "NO CODE",Size=UDim2.new(0,74,0,18),Position=UDim2.new(1,-86,0,58),BackgroundColor3=isInPS and C(6,22,18) or BG3,TextColor3=isInPS and CYAN or TEXT3,Font=Enum.Font.GothamBold,TextSize=8,AutoButtonColor=false},srvCard)
    CORNER(5,copyBtn); STROKE(isInPS and CYAN or TEXT3,1,isInPS and 0.5 or 0.7,copyBtn)
    if isInPS then copyBtn.MouseButton1Click:Connect(function()
        local code=GetPSCode(); if code~="" then pcall(function() setclipboard(code) end)
        copyBtn.Text="COPIED!"; copyBtn.TextColor3=GREEN
        task.delay(2,function() if copyBtn and copyBtn.Parent then copyBtn.Text="COPY CODE"; copyBtn.TextColor3=CYAN end end) end
    end) end

    -- ── Server Setup card ──────────────────────────────────────────────
    local cfgCard=MakeCard(PrivateServerPage,286,1); CardHeader(cfgCard,"server","SERVER SETUP",PINK)
    NEW("TextLabel",{Text="Private Server Code",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,36),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},cfgCard)
    local psBg=NEW("Frame",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,52),BackgroundColor3=BG5,BorderSizePixel=0},cfgCard); CORNER(7,psBg); local psStrk=STROKE(GOLD3,1,0.45,psBg)
    psBox=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Paste Private Server code here...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=11,ClearTextOnFocus=false},psBg)
    psBox.Focused:Connect(function() TWEEN(psStrk,0.15,{Color=PINK}) end); psBox.FocusLost:Connect(function() TWEEN(psStrk,0.15,{Color=GOLD3}) end)
    TogglesData["Config_PSCode"]={Value="",HeadBtn=psBox,Callback=function(val) getgenv().PSCode=val or "";pcall(function() psBox.Text=val or "" end) end}
    psBox:GetPropertyChangedSignal("Text"):Connect(function() getgenv().PSCode=psBox.Text; if TogglesData["Config_PSCode"] then TogglesData["Config_PSCode"].Value=psBox.Text end end)
    RowDivider(cfgCard,92)
    NEW("TextLabel",{Text="Destination Hub",Size=UDim2.new(0.5,0,0,14),Position=UDim2.new(0,12,0,100),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},cfgCard)
    local HUB_Y=118
    for hi,hd in ipairs(HUB_GRID) do
        local ci=(hi-1)%2; local ri=math.floor((hi-1)/2)
        local hBtn=NEW("TextButton",{Size=UDim2.new(0.5,-8,0,46),Position=UDim2.new(ci*0.5,ci==0 and 5 or 3,0,HUB_Y+ri*52),BackgroundColor3=BG4,BackgroundTransparency=0.3,Text="",AutoButtonColor=false},cfgCard); CORNER(9,hBtn)
        local hIco=NEW("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,8,0.5,-11),BackgroundColor3=BG5,BorderSizePixel=0},hBtn); CORNER(6,hIco); DrawIcon(hIco,hd.icon,4,4,14,TEXT3)
        local hLbl=NEW("TextLabel",{Text=hd.label,Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,34,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},hBtn)
        HubBtns[hd.id]={Btn=hBtn,Strk=STROKE(C(35,35,55),1,0.6,hBtn),Lbl=hLbl,IcoBg=hIco}
        hBtn.MouseEnter:Connect(function() if hd.id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundTransparency=0.15}) end end)
        hBtn.MouseLeave:Connect(function() if hd.id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundTransparency=0.3}) end end)
        hBtn.MouseButton1Click:Connect(function() getgenv().SelectedHub=hd.id; UpdateHub() end)
    end
    TogglesData["Config_SelectedHub"]={Value="Regular",Callback=function(val) getgenv().SelectedHub=val or "Regular"; UpdateHub() end}
    local seaY=HUB_Y+2*52+4; RowDivider(cfgCard,seaY-2)
    seaHdrLbl=NEW("TextLabel",{Text="Sea (Regular only)",Size=UDim2.new(0.55,0,0,14),Position=UDim2.new(0,12,0,seaY+4),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},cfgCard)
    for si,sd in ipairs(SEA_OPTS) do
        local sb=NEW("TextButton",{Size=UDim2.new(0.5,-8,0,30),Position=UDim2.new((si-1)*0.5,si==1 and 5 or 3,0,seaY+22),BackgroundColor3=BG4,BackgroundTransparency=0.3,Text="",AutoButtonColor=false},cfgCard); CORNER(8,sb)
        local sl=NEW("TextLabel",{Text=sd.label,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center},sb)
        SeaBtns[sd.id]={Btn=sb,Strk=STROKE(C(35,35,55),1,0.6,sb),Lbl=sl}
        local remoteName=sd.remote
        sb.MouseButton1Click:Connect(function()
            getgenv().SelectedSea=sd.id; UpdateSea()
            FireSeaRemote(remoteName)
        end)
    end
    TogglesData["Config_SelectedSea"]={Value="Sea 1",Callback=function(val) getgenv().SelectedSea=val or "Sea 1"; UpdateSea() end}
    task.spawn(function() task.wait(0.05); UpdateHub(); UpdateSea() end)

    -- ── Auto Join + Rejoin card ────────────────────────────────────────
    local ctrlCard=MakeCard(PrivateServerPage,188,2); CardHeader(ctrlCard,"lightning","AUTO JOIN  ·  REJOIN",PINK)
    RowLabel(ctrlCard,"Auto Join PS",nil,36)
    local ajPill=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-60,0,40),BackgroundColor3=BG5,Text="",AutoButtonColor=false},ctrlCard); CORNER(20,ajPill); local ajStrk=STROKE(TEXT3,1.2,0.3,ajPill)
    local ajThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},ajPill); CORNER(20,ajThumb)
    local function SetAutoJoin(on)
        autoJoinActive=on; getgenv().GBO_AutoJoin=on
        ApplyPill(ajPill,ajStrk,ajThumb,on,COL_PS,PINKD)
        if TogglesData["Config_AutoJoinPS"] then TogglesData["Config_AutoJoinPS"].Value=on end
        if on then
            local inPS=false
            pcall(function() local rc=game:GetService("ReplicatedStorage"):FindFirstChild("reservedCode"); if rc and rc.Value and rc.Value~="" then inPS=true end end)
            if not inPS then inPS=(game.PrivateServerId~="") end
            if not inPS then task.spawn(function() task.wait(0.5); pcall(function() TeleportService_L:Teleport(PLACE_LOBBY,Player_L) end) end) end
        end
    end
    TogglesData["Config_AutoJoinPS"]={Value=false,Callback=function(val) SetAutoJoin(val==true) end}
    ajPill.MouseButton1Click:Connect(function() SetAutoJoin(not autoJoinActive) end)
    RowDivider(ctrlCard,78)
    local joinBtn=NEW("TextButton",{Size=UDim2.new(1,-24,0,34),Position=UDim2.new(0,12,0,84),BackgroundColor3=PINKD,Text="",AutoButtonColor=false},ctrlCard); CORNER(9,joinBtn); STROKE(PINK,1.5,0.2,joinBtn)
    DrawIcon(joinBtn,"server",12,7,20,PINK)
    NEW("TextLabel",{Text="JOIN NOW",Size=UDim2.new(1,-46,0,16),Position=UDim2.new(0,40,0,9),BackgroundTransparency=1,TextColor3=PINK,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},joinBtn)
    joinBtn.MouseEnter:Connect(function() TWEEN(joinBtn,0.15,{BackgroundColor3=C(55,12,48)}) end); joinBtn.MouseLeave:Connect(function() TWEEN(joinBtn,0.15,{BackgroundColor3=PINKD}) end)
    joinBtn.MouseButton1Click:Connect(function() TWEEN(joinBtn,0.08,{BackgroundColor3=C(80,20,65)}); task.wait(0.1); TWEEN(joinBtn,0.15,{BackgroundColor3=PINKD}); SetAutoJoin(true) end)
    RowDivider(ctrlCard,124)
    RowLabel(ctrlCard,"Auto Rejoin","Kicked → lobby → auto-joins PS",130)
    local arPill=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-60,0,134),BackgroundColor3=BG5,Text="",AutoButtonColor=false},ctrlCard); CORNER(20,arPill); local arStrk=STROKE(TEXT3,1.2,0.3,arPill)
    local arThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},arPill); CORNER(20,arThumb)
    TogglesData["GW_AutoRejoin"]={Active=false,Btn=arPill,Strk=arStrk,Thumb=arThumb,AccentCol=CYAN,AccentDark=CYAND,Callback=function(state) getgenv().AutoRejoin=state; if state then AutoRejoinModule.Start() else AutoRejoinModule.Stop() end end}
    arPill.MouseButton1Click:Connect(function() local d=TogglesData["GW_AutoRejoin"]; d.Active=not d.Active; local on=d.Active; ApplyPill(arPill,arStrk,arThumb,on,CYAN,CYAND); if d.Callback then d.Callback(on) end end)
    RowDivider(ctrlCard,166)
    NEW("TextLabel",{Text="Auto Rejoin only works when Auto Join PS is also ON",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,14,0,170),BackgroundTransparency=1,TextColor3=C(80,65,120),Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},ctrlCard)

    -- Multi-Account card
    BuildMultiAccCard(PrivateServerPage, 3, CYAN)
end

if IS_LOBBY then
    -- Wrapped into local function to reset Lua's 200-local register limit
    local function _buildLobbyUI()
        RegSearch("Auto Race Reroll","Main","Keep rerolling until target race","AutoRace")
        RegSearch("Randomize Skin","Main","One-shot randomize all cosmetics","AutoSkinDisco")
        RegSearch("Auto Change Skin","Main","Re-randomize every 30s","AutoChangeSkin")
        RegSearch("Private Server Join","Private Server","Join PS by code","")
        RegSearch("Auto Join PS","Private Server","Auto-join on start","Config_AutoJoinPS")
        RegSearch("Auto Rejoin","Private Server","Auto-rejoin if kicked","AutoRejoin")
        -- LOBBY BUILD --------------------------------------------------
        local function SetToggleState(key,state)
            local d=TogglesData[key];if not d then return end; d.Active=state; local on=state
            local ac=d.AccentCol or GOLD2; local ad=d.AccentDark or GOLDD
            TWEEN(d.Btn,0.22,{BackgroundColor3=on and ad or BG5}); TWEEN(d.Strk,0.22,{Color=on and ac or TEXT3,Transparency=on and 0 or 0.3})
            if d.Thumb then TWEEN(d.Thumb,0.22,{BackgroundColor3=on and ac or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)}) end
        end

        -- Race Reroll
        do
        local RaceCard=MakeCard(MainPage,318,1); CardHeader(RaceCard,"target","RACE CHANGER",AMBER)
        RowLabel(RaceCard,"Auto Race Reroll","Select a race below · stops on match",38)
        CardToggle(RaceCard,38,"AutoRace",function(state)
            if state then RaceModule.Start(getgenv().TargetRace or "",function() SetToggleState("AutoRace",false) end) else RaceModule.Stop() end
        end,AMBER)
        RowDivider(RaceCard,74)
        local rSearchBg=NEW("Frame",{Size=UDim2.new(1,-24,0,30),Position=UDim2.new(0,12,0,82),BackgroundColor3=BG5,BorderSizePixel=0},RaceCard); CORNER(6,rSearchBg); STROKE(GOLD3,1,0.5,rSearchBg)
        NEW("TextLabel",{Size=UDim2.new(0,28,1,0),BackgroundTransparency=1,Text="🔍",TextColor3=TEXT3,Font=Enum.Font.GothamMedium,TextSize=13},rSearchBg)
        local rSearch=NEW("TextBox",{Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,28,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Search race...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=true},rSearchBg)
        local rScroll=NEW("ScrollingFrame",{Size=UDim2.new(1,-24,0,148),Position=UDim2.new(0,12,0,120),BackgroundColor3=BG5,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=GOLD3,CanvasSize=UDim2.new(0,0,0,0)},RaceCard)
        CORNER(8,rScroll); STROKE(GOLD3,1,0.5,rScroll)
        NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Center},rScroll)
        NEW("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},rScroll)
        getgenv().TargetRace=""
        local RaceButtons={}
        local raceList={{"Cyborg","Cyborg"},{"Vampire","Vampire"},{"Mink","Mink"},{"Fishman","Fishman"},{"Skypian","Skypian"},{"Human","Human"},{"Dullahan","Dullahan (Not Working)"}}
        local function UpdateRaceSelection()
            for rn,d in pairs(RaceButtons) do local sel=(rn==getgenv().TargetRace);TWEEN(d.Btn,0.18,{BackgroundColor3=sel and GOLDD or BG4});TWEEN(d.Strk,0.18,{Color=sel and GOLD2 or C(40,40,55)});d.Btn.TextColor3=sel and TEXT1 or TEXT2;d.Icon.Text=sel and "✓" or "" end
            if TogglesData["Config_TargetRace"] then TogglesData["Config_TargetRace"].Value=getgenv().TargetRace end
        end
        for i,info in ipairs(raceList) do
            local rn,dn=info[1],info[2]
            local rBtn=NEW("TextButton",{Size=UDim2.new(1,-12,0,28),Name=rn,BackgroundColor3=BG4,Text="   "..dn,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,LayoutOrder=i},rScroll)
            CORNER(6,rBtn); local rStrk=STROKE(C(40,40,55),1,0,rBtn)
            local rIcon=NEW("TextLabel",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-26,0.5,-11),BackgroundTransparency=1,Text="",TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=13},rBtn)
            RaceButtons[rn]={Btn=rBtn,Icon=rIcon,Strk=rStrk}
            rBtn.MouseEnter:Connect(function() if rn~=getgenv().TargetRace then TWEEN(rBtn,0.12,{BackgroundColor3=BG3}) end end)
            rBtn.MouseLeave:Connect(function() if rn~=getgenv().TargetRace then TWEEN(rBtn,0.12,{BackgroundColor3=BG4}) end end)
            rBtn.MouseButton1Click:Connect(function() getgenv().TargetRace=(getgenv().TargetRace==rn) and "" or rn; UpdateRaceSelection() end)
        end
        rScroll.CanvasSize=UDim2.new(0,0,0,(#raceList*33)+12)
        rSearch:GetPropertyChangedSignal("Text"):Connect(function()
            local q=string.lower(rSearch.Text); local vis=0
            for rn,d in pairs(RaceButtons) do local show=q=="" or string.find(string.lower(rn),q);d.Btn.Visible=show~=nil;if show then vis+=1 end end
            rScroll.CanvasSize=UDim2.new(0,0,0,(vis*33)+12)
        end)
        UpdateRaceSelection()
        TogglesData["Config_TargetRace"]={Value="",Callback=function(val) getgenv().TargetRace=val or "";UpdateRaceSelection() end,UpdateFn=UpdateRaceSelection}
        end

        -- Skin Changer
        do
        local skinCard=MakeCard(MainPage,124,2); CardHeader(skinCard,"user","SKIN CHANGER",GOLD2)
        RowLabel(skinCard,"Randomize Once","One-shot: randomizes all cosmetics now",34)
        CardToggle(skinCard,38,"AutoSkinDisco",function(state) if not state then return end; task.spawn(function() SkinModule.Randomize();task.wait(0.25);SetToggleState("AutoSkinDisco",false) end) end,GOLD2)
        RowDivider(skinCard,72)
        RowLabel(skinCard,"Auto Change Skin","Re-randomize every 30s when active",78)
        CardToggle(skinCard,82,"AutoChangeSkin",function(state) getgenv().AutoChangeSkin=state; if state then task.spawn(function() while getgenv().AutoChangeSkin do SkinModule.Randomize();task.wait(30) end end) end end,GOLD2)
        end

        -- Private Server page (lobby)
        PageLayout(PrivateServerPage,14,10)
        getgenv().PSCode=getgenv().PSCode or ""; getgenv().SelectedHub=getgenv().SelectedHub or "Regular"; getgenv().SelectedSea=getgenv().SelectedSea or "Sea 1"
        local HubArgs={["Regular"]=true,["Trade Hub"]="tradeHub",["Universe Hub"]="universeHub",["Fish Hub"]="fishHub"}
        local HubButtons={}; local SeaBtns={}; local UpdateUIState; local _seaHeaderLbl
        local HUB_GRID={{id="Regular",label="Regular",icon="globe",col=COL_TRAVEL},{id="Trade Hub",label="Trade Hub",icon="coin",col=AMBER},{id="Universe Hub",label="Universe Hub",icon="target",col=COL_STATS},{id="Fish Hub",label="Fish Hub",icon="fish",col=COL_FISH}}
        local SEA_OPTS={{id="Sea 1",label="SEA 1",remote="First Sea"},{id="Sea 2",label="SEA 2",remote="Second Sea"}}
        local function FireSeaRemote(remoteName)
            pcall(function()
                local function getNil(name,class)
                    for _,v in next,getnilinstances() do
                        if v.ClassName==class and v.Name==name then return v end
                    end
                end
                getNil("RemoteEvent","RemoteEvent"):FireServer(remoteName)
            end)
        end
        local function ApplyPillState(pill,strk,thumb,on,ac,ad) TWEEN(pill,0.22,{BackgroundColor3=on and ad or BG5});TWEEN(strk,0.22,{Color=on and ac or TEXT3,Transparency=on and 0 or 0.3});TWEEN(thumb,0.22,{BackgroundColor3=on and ac or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)}) end
        local function UpdateHubSelection()
            for _,hd in ipairs(HUB_GRID) do local d=HubButtons[hd.id];if not d then continue end;local sel=(hd.id==getgenv().SelectedHub);local ac=hd.col;local acd=C(math.min(255,math.floor(ac.R*255*0.15+5)),math.min(255,math.floor(ac.G*255*0.15+5)),math.min(255,math.floor(ac.B*255*0.15+5)));TWEEN(d.Btn,0.18,{BackgroundColor3=sel and acd or BG4,BackgroundTransparency=sel and 0 or 0.3});TWEEN(d.Strk,0.18,{Color=sel and ac or C(35,35,55),Transparency=sel and 0.1 or 0.6});TWEEN(d.Lbl,0.18,{TextColor3=sel and ac or TEXT2});d.Lbl.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium;for _,ch in ipairs(d.IconBg:GetDescendants()) do if ch:IsA("Frame") then TWEEN(ch,0.18,{BackgroundColor3=sel and ac or TEXT3}) end;if ch:IsA("UIStroke") then TWEEN(ch,0.18,{Color=sel and ac or TEXT3}) end end end
            if UpdateUIState then UpdateUIState() end
            if TogglesData["Config_SelectedHub"] then TogglesData["Config_SelectedHub"].Value=getgenv().SelectedHub end
        end
        local function UpdateSeaSelection()
            for _,sd in ipairs(SEA_OPTS) do local d=SeaBtns[sd.id];if not d then continue end;local sel=(getgenv().SelectedSea==sd.id);TWEEN(d.Btn,0.15,{BackgroundColor3=sel and C(8,18,44) or BG4,BackgroundTransparency=sel and 0 or 0.3});TWEEN(d.Strk,0.15,{Color=sel and COL_FISH or C(35,35,55),Transparency=sel and 0.1 or 0.6});TWEEN(d.Lbl,0.15,{TextColor3=sel and COL_FISH or TEXT2});d.Lbl.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium end
            if TogglesData["Config_SelectedSea"] then TogglesData["Config_SelectedSea"].Value=getgenv().SelectedSea end
        end
        UpdateUIState=function()
            local isReg=(getgenv().SelectedHub=="Regular")
            for _,sd in ipairs(SEA_OPTS) do if SeaBtns[sd.id] then SeaBtns[sd.id].Btn.Visible=isReg end end
            if _seaHeaderLbl then _seaHeaderLbl.Visible=isReg end
        end

        -- Server Setup card (height pre-calculated so CardHeader caches correct _fullH)
        local _psCardH = 118 + 2*52 + 62 + 50  -- hub grid + sea + join btn + padding = 338 (HUB_START_Y=118 declared below; avoids nil arithmetic error)
        local psCard=MakeCard(PrivateServerPage,_psCardH,1); CardHeader(psCard,"server","SERVER SETUP",PINK)
        NEW("TextLabel",{Text="Private Server Code",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,36),BackgroundTransparency=1,TextColor3=PINK,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},psCard)
        NEW("TextLabel",{Text="Leave empty for public",Size=UDim2.new(1,-24,0,12),Position=UDim2.new(1,-150,0,37),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right},psCard)
        local psBg=NEW("Frame",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,52),BackgroundColor3=BG5,BorderSizePixel=0},psCard); CORNER(7,psBg); local psBgStrk=STROKE(GOLD3,1,0.45,psBg)
        local psBox=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Paste Private Server code here...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},psBg)
        psBox.Focused:Connect(function() TWEEN(psBgStrk,0.15,{Color=PINK}) end); psBox.FocusLost:Connect(function() TWEEN(psBgStrk,0.15,{Color=GOLD3}) end)
        TogglesData["Config_PSCode"]={Value="",HeadBtn=psBox,Callback=function(val) getgenv().PSCode=val or "";pcall(function() psBox.Text=val or "" end) end}
        psBox:GetPropertyChangedSignal("Text"):Connect(function() getgenv().PSCode=psBox.Text;TogglesData["Config_PSCode"].Value=psBox.Text end)
        RowDivider(psCard,92)
        NEW("TextLabel",{Text="Destination Hub",Size=UDim2.new(0.5,0,0,14),Position=UDim2.new(0,12,0,100),BackgroundTransparency=1,TextColor3=PINK,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},psCard)
        local HUB_START_Y=118
        for hi,hd in ipairs(HUB_GRID) do
            local ci=(hi-1)%2; local ri=math.floor((hi-1)/2)
            local hBtn=NEW("TextButton",{Size=UDim2.new(0.5,-8,0,46),Position=UDim2.new(ci*0.5,ci==0 and 5 or 3,0,HUB_START_Y+ri*52),BackgroundColor3=BG4,BackgroundTransparency=0.3,Text="",AutoButtonColor=false},psCard); CORNER(9,hBtn)
            local hStrk=STROKE(C(35,35,55),1,0.6,hBtn)
            local hIconBg=NEW("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,8,0.5,-11),BackgroundColor3=BG5,BorderSizePixel=0},hBtn); CORNER(6,hIconBg); DrawIcon(hIconBg,hd.icon,4,4,14,TEXT3)
            local hLbl=NEW("TextLabel",{Text=hd.label,Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,34,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},hBtn)
            HubButtons[hd.id]={Btn=hBtn,Strk=hStrk,Lbl=hLbl,IconBg=hIconBg}
            hBtn.MouseEnter:Connect(function() if hd.id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundTransparency=0.15}) end end)
            hBtn.MouseLeave:Connect(function() if hd.id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundTransparency=0.3}) end end)
            hBtn.MouseButton1Click:Connect(function() getgenv().SelectedHub=hd.id;UpdateHubSelection() end)
        end
        TogglesData["Config_SelectedSea"]={Value="Sea 1",Callback=function(val) getgenv().SelectedSea=val or "Sea 1";UpdateSeaSelection() end}
        TogglesData["Config_SelectedHub"]={Value="Regular",Callback=function(val) getgenv().SelectedHub=val or "Regular";UpdateHubSelection();UpdateUIState() end,UpdateFn=function() UpdateHubSelection();UpdateUIState() end}
        local seaY=HUB_START_Y+2*52+4; RowDivider(psCard,seaY-2)
        _seaHeaderLbl=NEW("TextLabel",{Text="Sea (Regular only)",Size=UDim2.new(0.55,0,0,14),Position=UDim2.new(0,12,0,seaY+4),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},psCard)
        for si2,sd in ipairs(SEA_OPTS) do
            local sb=NEW("TextButton",{Size=UDim2.new(0.5,-8,0,30),Position=UDim2.new((si2-1)*0.5,si2==1 and 5 or 3,0,seaY+22),BackgroundColor3=BG4,BackgroundTransparency=0.3,Text="",AutoButtonColor=false},psCard); CORNER(8,sb)
            local ss=STROKE(C(35,35,55),1,0.6,sb)
            local sl=NEW("TextLabel",{Text=sd.label,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center},sb)
            SeaBtns[sd.id]={Btn=sb,Strk=ss,Lbl=sl}
            local remoteName=sd.remote
            sb.MouseButton1Click:Connect(function()
                getgenv().SelectedSea=sd.id; UpdateSeaSelection()
                FireSeaRemote(remoteName)
            end)
        end
        local jnY=seaY+62; RowDivider(psCard,jnY-4)
        local joinNowBtn=NEW("TextButton",{Size=UDim2.new(1,-24,0,36),Position=UDim2.new(0,12,0,jnY),BackgroundColor3=PINKD,Text="",AutoButtonColor=false},psCard); CORNER(9,joinNowBtn); STROKE(PINK,1.5,0.2,joinNowBtn)
        DrawIcon(joinNowBtn,"server",12,8,20,PINK)
        NEW("TextLabel",{Text="JOIN NOW",Size=UDim2.new(1,-46,0,18),Position=UDim2.new(0,40,0,9),BackgroundTransparency=1,TextColor3=PINK,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},joinNowBtn)
        NEW("TextLabel",{Text="One-shot: join PS immediately",Size=UDim2.new(1,-46,0,12),Position=UDim2.new(0,40,0,26),BackgroundTransparency=1,TextColor3=C(160,60,130),Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},joinNowBtn)
        joinNowBtn.MouseEnter:Connect(function() TWEEN(joinNowBtn,0.15,{BackgroundColor3=C(55,12,48)}) end); joinNowBtn.MouseLeave:Connect(function() TWEEN(joinNowBtn,0.15,{BackgroundColor3=PINKD}) end)
        joinNowBtn.MouseButton1Click:Connect(function()
            TWEEN(joinNowBtn,0.08,{BackgroundColor3=C(80,20,65)}); task.wait(0.1); TWEEN(joinNowBtn,0.15,{BackgroundColor3=PINKD})
            task.spawn(function() local code=getgenv().PSCode or "";local hub=getgenv().SelectedHub or "Regular";local sea=getgenv().SelectedSea or "Sea 1";local arg=HubArgs[hub] or true;ServerModule.Join(code,arg,hub=="Regular" and sea or nil) end)
        end)
        task.spawn(function() task.wait(0.05);UpdateHubSelection();UpdateSeaSelection() end)

        -- Auto Join card
        local ajCard=MakeCard(PrivateServerPage,92,2); CardHeader(ajCard,"lightning","AUTO JOIN PS",PINK)
        NEW("TextLabel",{Text="Auto Join",Size=UDim2.new(0.7,0,0,20),Position=UDim2.new(0,14,0,36),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},ajCard)
        NEW("TextLabel",{Text="When ON: lobby auto-joins PS on start. Toggle saves preference only.",Size=UDim2.new(1,-24,0,22),Position=UDim2.new(0,14,0,58),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},ajCard)
        local ajPill=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-60,0,40),BackgroundColor3=BG5,Text="",AutoButtonColor=false},ajCard); CORNER(20,ajPill); local ajStrk=STROKE(TEXT3,1.2,0.3,ajPill)
        local ajThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},ajPill); CORNER(20,ajThumb)
        local autoJoinActive=false
        local function IsInPS()
            if game.PrivateServerId ~= "" then return true end
            local ok = false
            pcall(function()
                local rc = game:GetService("ReplicatedStorage"):FindFirstChild("reservedCode")
                if rc and rc.Value and rc.Value ~= "" then ok = true end
            end)
            return ok
        end
        local function DoJoinPS()
            if getgenv()._ZiliMultiAccData then return end
            local code=getgenv().PSCode or ""; local hub=getgenv().SelectedHub or "Regular"; local sea=getgenv().SelectedSea or "Sea 1"
            local arg=HubArgs[hub] or true
            task.spawn(function()
                while autoJoinActive do
                    if IsInPS() then break end
                    pcall(function() ServerModule.Join(code,arg,hub=="Regular" and sea or nil) end)
                    -- Đợi tối đa 5s, check mỗi 0.5s để phát hiện join thành công sớm hơn
                    local deadline = tick() + 5
                    while tick() < deadline do
                        if IsInPS() then return end  -- joined → dừng hẳn
                        task.wait(0.5)
                    end
                end
            end)
        end
        local function SetAutoJoin(on)
            autoJoinActive=on; getgenv().GBO_AutoJoin=on
            ApplyPillState(ajPill,ajStrk,ajThumb,on,COL_PS,PINKD)
            if TogglesData["Config_AutoJoinPS"] then TogglesData["Config_AutoJoinPS"].Value=on end
            if on then
                local inPS=false
                pcall(function() local rc=game:GetService("ReplicatedStorage"):FindFirstChild("reservedCode"); if rc and rc.Value and rc.Value~="" then inPS=true end end)
                if not inPS then inPS=(game.PrivateServerId~="") end
                if not inPS then task.delay(0.3, DoJoinPS) end
            end
        end
        TogglesData["Config_AutoJoinPS"]={Value=false,Callback=function(val) SetAutoJoin(val==true) end}
        ajPill.MouseButton1Click:Connect(function() SetAutoJoin(not autoJoinActive) end)

        -- ── AUTO REJOIN LOBBY-SIDE: if returning from a kicked session, auto-rejoin ──
        task.spawn(function()
            if getgenv()._ZiliPendingRejoin then
                getgenv()._ZiliPendingRejoin = false
                local rCode = getgenv()._ZiliRejoinCode or ""
                local rHub  = getgenv()._ZiliRejoinHub  or "Regular"
                local rSea  = getgenv()._ZiliRejoinSea  or "Sea 1"
                if rCode ~= "" then
                    getgenv().PSCode      = rCode
                    getgenv().SelectedHub = rHub
                    getgenv().SelectedSea = rSea
                    pcall(function() psBox.Text = rCode end)
                    task.wait(1.5)
                    -- [FIX BUG 2] Luôn dùng ServerModule.Join trực tiếp cho cả multi-acc
                    -- lẫn normal acc. SetAutoJoin(true) trong lobby chỉ teleport về lobby,
                    -- không join PS. _ZiliMultiAccData đã bị clear ở game world → không dùng
                    -- để phân biệt nữa. Per-player key (_ZiliRejoinData_NAME) đã lưu đúng code.
                    pcall(function()
                        ServerModule.Join(rCode, HubArgs[rHub] or true, rHub=="Regular" and rSea or nil)
                    end)
                end
            end
        end)

        -- Auto Rejoin card
        local arCard=MakeCard(PrivateServerPage,92,3); CardHeader(arCard,"target","AUTO REJOIN",CYAN)
        NEW("TextLabel",{Text="Auto Rejoin",Size=UDim2.new(0.7,0,0,20),Position=UDim2.new(0,14,0,36),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},arCard)
        NEW("TextLabel",{Text="Kicked → returns to lobby → auto-joins PS (needs Auto Join ON)",Size=UDim2.new(1,-24,0,22),Position=UDim2.new(0,14,0,58),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},arCard)
        CardToggle(arCard,40,"AutoRejoin",function(state) getgenv().AutoRejoin=state;if state then AutoRejoinModule.Start() else AutoRejoinModule.Stop() end end,CYAN)

        -- Multi-Account card (shared builder)
        BuildMultiAccCard(PrivateServerPage, 4, CYAN)


    else
        -- GAME WORLD BUILD -----------------------------------------------
        RegSearch("Island ESP","Main","Show island locations on screen","ESP_Island")
        RegSearch("Player ESP","Misc","Show player positions with HUD options","ESP_Player")
        RegSearch("Item ESP","Main","Show dropped items","ESP_Item")
        -- Status card
        local statusCard=MakeCard(MainPage,72,1); CardHeader(statusCard,"eye","HUB STATUS",GREEN)
        -- Green dot (Frame-based, always visible regardless of font support)
        local _connDot=NEW("Frame",{Size=UDim2.new(0,9,0,9),Position=UDim2.new(0,14,0,38),BackgroundColor3=GREEN,BorderSizePixel=0},statusCard); CORNER(5,_connDot)
        NEW("TextLabel",{Text="Connected  ·  GET BETTER OUT",Size=UDim2.new(0.65,0,0,18),Position=UDim2.new(0,30,0,34),BackgroundTransparency=1,TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},statusCard)
        NEW("TextLabel",{Text="Zili Hub  ·  v2.9.0  ·  Premium Build",Size=UDim2.new(1,-20,0,13),Position=UDim2.new(0,14,0,54),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},statusCard)
        local pingBadge=NEW("TextLabel",{Text=" LIVE",Size=UDim2.new(0,68,0,20),Position=UDim2.new(1,-80,0,36),BackgroundColor3=C(5,36,18),TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},statusCard)
        CORNER(4,pingBadge); STROKE(GREEN,1,0.35,pingBadge)
        local _liveDot=NEW("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,6,0.5,-3),BackgroundColor3=GREEN,BorderSizePixel=0},pingBadge); CORNER(3,_liveDot)
        task.spawn(function() while statusCard and statusCard.Parent do TWEEN(pingBadge,0.9,{TextColor3=C(120,255,175)});TWEEN(_liveDot,0.9,{BackgroundColor3=C(120,255,175)});task.wait(1.2);TWEEN(pingBadge,0.9,{TextColor3=GREEN});TWEEN(_liveDot,0.9,{BackgroundColor3=GREEN});task.wait(1.2) end end)

        -- ── PLAYER STATUS card ──────────────────────────────────────────────────
        local psCard=MakeCard(MainPage,186,2); CardHeader(psCard,"user","PLAYER STATUS",COL_STATS)

        local function _readLevel()
            local v=0; pcall(function()
                local sf=game:GetService("ReplicatedStorage"):FindFirstChild("Stats"..LocalPlayer.Name)
                local sn=sf and sf:FindFirstChild("Stats"); local ln=sn and sn:FindFirstChild("Level")
                if ln then v=tonumber(ln.Value) or 0 end end); return v
        end
        local function _readRace()
            local r="Unknown"; pcall(function()
                local sf=game:GetService("ReplicatedStorage"):FindFirstChild("Stats"..LocalPlayer.Name)
                if sf and sf:FindFirstChild("Customization") and sf.Customization:FindFirstChild("Race") then
                    local raw=sf.Customization.Race.Value
                    r=(raw=="Human") and raw or raw:gsub("%d+","") end end); return r
        end
        local function _readBan()
            local vc=0; pcall(function()
                local safe=LocalPlayer.Name:gsub("[^%w_%-]","_")
                local sbf="Zili_Hub/data/shadowban_"..safe..".json"
                if isfile and isfile(sbf) then
                    local ok,d=pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(sbf)) end)
                    if ok and type(d)=="table" and type(d.count)=="number" then vc=d.count end
                end end)
            if vc<=0 then return "Clean",GREEN
            elseif vc<3 then return "Low Risk ("..vc..")",C(220,200,50)
            elseif vc<5 then return "Med Risk ("..vc..")",C(255,145,30)
            elseif vc<7 then return "High Risk ("..vc..")",RED
            else return "Banned ("..vc..")",C(200,40,40) end
        end
        -- Improved _psRow: accent strip + value badge
        local function _psRow(card,posY,lbl,col)
            -- Subtle row background
            local rowBg=NEW("Frame",{Size=UDim2.new(1,-4,0,32),Position=UDim2.new(0,2,0,posY),BackgroundColor3=C(12,10,28),BackgroundTransparency=0.4,BorderSizePixel=0},card); CORNER(6,rowBg)
            -- Left color accent strip
            local strip=NEW("Frame",{Size=UDim2.new(0,3,0,20),Position=UDim2.new(0,8,0,posY+6),BackgroundColor3=col,BorderSizePixel=0},card); CORNER(2,strip)
            -- Label text
            NEW("TextLabel",{Text=lbl,Size=UDim2.new(0,80,0,22),Position=UDim2.new(0,18,0,posY+5),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},card)
            -- Value badge (pill with accent outline)
            local valBg=NEW("Frame",{Size=UDim2.new(0,96,0,22),Position=UDim2.new(1,-106,0,posY+5),BackgroundColor3=C(math.min(255,math.floor(col.R*255*0.08+8)),math.min(255,math.floor(col.G*255*0.08+8)),math.min(255,math.floor(col.B*255*0.08+8))),BorderSizePixel=0},card)
            CORNER(8,valBg); STROKE(col,1,0.6,valBg)
            local valLbl=NEW("TextLabel",{Text="...",Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=col,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},valBg)
            return valLbl
        end
        local psLvlLbl  = _psRow(psCard,34,"Level",GOLD2)
        RowDivider(psCard,68)
        local psRaceLbl = _psRow(psCard,72,"Race",CYAN)
        RowDivider(psCard,106)
        local psMerLbl  = _psRow(psCard,110,"Merchants",AMBER)
        RowDivider(psCard,144)
        local psBanLbl  = _psRow(psCard,148,"Shadowban",GREEN)
        ZiliState._MerchantCounterLbl = psMerLbl

        -- Level.Changed hook (log level-up events)
        task.spawn(function() pcall(function()
            local sf=game:GetService("ReplicatedStorage"):WaitForChild("Stats"..LocalPlayer.Name,10)
            local sn=sf and sf:WaitForChild("Stats",5); local ln=sn and sn:WaitForChild("Level",5)
            if not ln then return end
            local prev=ln.Value
            ln.Changed:Connect(function(nv)
                if nv>prev then pcall(getgenv().ZiliLog,"Level up! "..prev.." → "..nv,"farm") end
                prev=nv
                if psLvlLbl and psLvlLbl.Parent then psLvlLbl.Text=tostring(nv) end
            end)
        end) end)

        -- Refresh player status every 5s
        task.spawn(function()
            while psCard and psCard.Parent do
                if psLvlLbl and psLvlLbl.Parent then psLvlLbl.Text=tostring(_readLevel()) end
                if psRaceLbl and psRaceLbl.Parent then psRaceLbl.Text=_readRace() end
                if psMerLbl and psMerLbl.Parent then psMerLbl.Text=tostring(ZiliState.MerchantCounter) end
                if psBanLbl and psBanLbl.Parent then
                    local bl,bc=_readBan(); psBanLbl.Text=bl; psBanLbl.TextColor3=bc
                end
                task.wait(5)
            end
        end)

        -- ── QUICK STATUS card (layout 3) ──────────────────────────────────────────
        local quickCard=MakeCard(MainPage,118,3); CardHeader(quickCard,"lightning","QUICK STATUS",AMBER)
        local QT_DATA={{"Auto Farm","AutoFarmLevel",10,34,COL_FARM},{"Auto Buso","AutoBuso",120,34,COL_FARM},{"Auto Geppo","AutoGeppo",230,34,COL_FARM},{"Auto Fish","AutoFishMerchant",10,76,COL_FISH},{"Island ESP","ESP_Island",120,76,BLUE_A},{"Travel","TravelActive",230,76,COL_TRAVEL}}
        local quickDots={}
        for _,qt in ipairs(QT_DATA) do
            local label,key,px,py,acCol=qt[1],qt[2],qt[3],qt[4],qt[5]
            local box=NEW("Frame",{Size=UDim2.new(0,102,0,32),Position=UDim2.new(0,px,0,py),BackgroundColor3=C(10,11,24)},quickCard); CORNER(7,box); STROKE(C(22,20,44),1,0,box)
            NEW("TextLabel",{Text=label,Size=UDim2.new(1,-22,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},box)
            local dot=NEW("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(1,-14,0.5,-4),BackgroundColor3=C(30,28,50),BorderSizePixel=0},box); CORNER(4,dot); quickDots[key]={dot=dot,col=acCol}
        end
        task.spawn(function() while MainFrame and MainFrame.Parent do task.wait(0.5);for key,data in pairs(quickDots) do if data.dot and data.dot.Parent then local on=TogglesData[key] and TogglesData[key].Active;TWEEN(data.dot,0.3,{BackgroundColor3=on and data.col or C(30,28,50)}) end end end end)

        -- ── ACTIVITY LOG card (layout 4) ─────────────────────────────────────────
        local logCard=MakeCard(MainPage,240,4); CardHeader(logCard,"list","ACTIVITY LOG",GOLD)

        -- Init log file (per-player, persists across rejoins)
        local _logSafe=LocalPlayer.Name:gsub("[^%w_%-]","_")
        local _logFile="Zili_Hub/data/activity_".._logSafe..".json"
        getgenv()._ZiliLogFile=_logFile
        if not isfolder("Zili_Hub") and makefolder then makefolder("Zili_Hub") end
        if not isfolder("Zili_Hub/data") and makefolder then makefolder("Zili_Hub/data") end
        pcall(function()
            if isfile and isfile(_logFile) then
                local ok,saved=pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(_logFile)) end)
                if ok and type(saved)=="table" then ZiliState.ActivityLog=saved end
            end
        end)

        -- Category colors + short tag labels
        local _CAT_COL={
            merchant=GOLD, farm=COL_FARM, buso=PURPLE, geppo=CYAN,
            spawn=COL_CFG, fish=COL_FISH, info=TEXT3,
        }
        local _CAT_TAG={
            merchant="MRC", farm="FARM", buso="BUSO", geppo="GPPO",
            spawn="SPWN", fish="FISH", info="INFO",
        }

        -- 8 improved log rows (row height = 26px, starting at 36)
        local _logRows={}
        for i=1,8 do
            local py=34+(i-1)*26
            -- Row background (alternating subtle tint)
            local rowBg=NEW("Frame",{Size=UDim2.new(1,-8,0,24),Position=UDim2.new(0,4,0,py),BackgroundColor3=(i%2==0) and C(14,12,28) or C(10,9,22),BackgroundTransparency=0.3,BorderSizePixel=0},logCard); CORNER(5,rowBg)
            -- Category tag pill
            local tagBg=NEW("Frame",{Size=UDim2.new(0,36,0,16),Position=UDim2.new(0,8,0,py+4),BackgroundColor3=C(18,15,36),BorderSizePixel=0},logCard); CORNER(4,tagBg)
            local tagLbl=NEW("TextLabel",{Text="INFO",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center},tagBg)
            STROKE(TEXT3,1,0.5,tagBg)
            -- Main text
            local lbl=NEW("TextLabel",{Text="—",Size=UDim2.new(1,-104,0,20),Position=UDim2.new(0,50,0,py+2),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamSemibold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},logCard)
            -- Timestamp badge
            local tmeBg=NEW("Frame",{Size=UDim2.new(0,44,0,16),Position=UDim2.new(1,-52,0,py+4),BackgroundColor3=C(10,9,22),BorderSizePixel=0},logCard); CORNER(4,tmeBg)
            local tme=NEW("TextLabel",{Text="",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center},tmeBg)
            _logRows[i]={lbl=lbl,tme=tme,tagLbl=tagLbl,tagBg=tagBg,tmeBg=tmeBg,rowBg=rowBg}
        end
        local function _refreshLog()
            for i,row in ipairs(_logRows) do
                local e=ZiliState.ActivityLog[i]
                if e then
                    local col=_CAT_COL[e.cat] or TEXT3
                    local tag=_CAT_TAG[e.cat] or "INFO"
                    row.lbl.Text=e.text; row.lbl.TextColor3=col
                    row.tagLbl.Text=tag; row.tagLbl.TextColor3=col
                    pcall(function() STROKE(col,1,0.45,row.tagBg) end)
                    row.tagBg.BackgroundColor3=C(math.min(255,math.floor(col.R*255*0.12+8)),math.min(255,math.floor(col.G*255*0.12+8)),math.min(255,math.floor(col.B*255*0.12+8)))
                    row.tme.Text=e.t; row.tme.TextColor3=col
                    row.tmeBg.BackgroundColor3=C(math.min(255,math.floor(col.R*255*0.08+6)),math.min(255,math.floor(col.G*255*0.08+6)),math.min(255,math.floor(col.B*255*0.08+6)))
                else
                    row.lbl.Text="—"; row.lbl.TextColor3=TEXT3
                    row.tagLbl.Text="·"; row.tagLbl.TextColor3=TEXT3
                    row.tagBg.BackgroundColor3=C(18,15,36)
                    row.tme.Text=""; row.tme.TextColor3=TEXT3
                    row.tmeBg.BackgroundColor3=C(10,9,22)
                end
            end
        end
        ZiliState._LogRefresh=_refreshLog; _refreshLog()

        -- Private Server page (game world) — extracted to own function to avoid 200-local limit
        BuildGWPSPage(PrivateServerPage, TogglesData)
    end -- _buildLobbyUI
    _buildLobbyUI()
end -- end IS_LOBBY / else

-- =====================================================================

-- =====================================================================
-- 📦 MODULE: Misc/AutoWatchAds
-- =====================================================================
__modules["Misc/AutoWatchAds"] = function()
    local AutoWatchAds = {}
    local Running = {Exp=false, DropRate=false, RaceReroll=false}

    -- Map từng adType → args chính xác của game
    local AD_ARGS = {
        Exp        = {3457788725, "536248645108658"},
        DropRate   = {3457789187, "600025169914931"},
        RaceReroll = {940683010,  "250356898332440"},
    }

    -- Cooldown mỗi loại (giây) — đặt dư 2s để tránh server reject
    local AD_COOLDOWN = {
        Exp        = 32,
        DropRate   = 32,
        RaceReroll = 32,
    }

    local ADShopRemote = nil
    local function GetRemote()
        if ADShopRemote and ADShopRemote.Parent then return ADShopRemote end
        local ok, result = pcall(function()
            return game:GetService("ReplicatedStorage")
                       :WaitForChild("Events", 10)
                       :WaitForChild("ADShop", 10)
        end)
        if ok and result then ADShopRemote = result end
        return ADShopRemote
    end

    local function FireAd(adType)
        local args = AD_ARGS[adType]
        if not args then return false end
        local remote = GetRemote()
        if not remote then return false end
        local ok, err = pcall(function()
            remote:FireServer(args[1], args[2])
        end)
        if not ok then
            warn("[AutoWatchAds] FireAd("..adType..") failed: "..tostring(err))
        end
        return ok
    end

    function AutoWatchAds.StartLoop(adType)
        if Running[adType] then return end  -- ngăn double-start
        Running[adType] = true
        task.spawn(function()
            -- Fire ngay lập tức lần đầu, rồi mới chờ cooldown
            while Running[adType] do
                FireAd(adType)
                local cd = AD_COOLDOWN[adType] or 32
                local elapsed = 0
                while elapsed < cd and Running[adType] do
                    task.wait(1)
                    elapsed += 1
                end
            end
        end)
    end

    function AutoWatchAds.Stop(adType)
        Running[adType] = false
    end

    function AutoWatchAds.StopAll()
        for k in pairs(Running) do Running[k] = false end
    end

    function AutoWatchAds.FireOnce(adType)
        task.spawn(function() FireAd(adType) end)
    end

    function AutoWatchAds.GetRunning() return Running end
    return AutoWatchAds
end

-- MISC PAGE  (Character, Display Name, Player ESP)
-- =====================================================================

-- =====================================================================
-- AUTO WATCH ADS PAGE BUILDER
-- =====================================================================
_pageBuildFns["Auto Watch Ads"] = function()
    if IS_LOBBY or not AdsPage then return end  -- skip in lobby
    local AWA = require("Misc/AutoWatchAds")
    RegSearch("Auto Watch Ads","Auto Watch Ads","Auto watch in-game ads for rewards","")
    PageLayout(AdsPage,16,12)
    local AC = CYAN

    -- Header
    local adsHdr=MakeCard(AdsPage,52,0); adsHdr.BackgroundColor3=C(5,18,22); STROKE(AC,1,0.2,adsHdr)
    NEW("Frame",{Size=UDim2.new(0,4,0.6,0),Position=UDim2.new(0,0,0.2,0),BackgroundColor3=AC,BorderSizePixel=0},adsHdr);CORNER(2,adsHdr:FindFirstChildOfClass("Frame"))
    NEW("TextLabel",{Text="AUTO WATCH ADS",Size=UDim2.new(1,-50,0,18),Position=UDim2.new(0,14,0,8),BackgroundTransparency=1,TextColor3=AC,Font=Enum.Font.GothamBold,TextSize=14},adsHdr)
    NEW("TextLabel",{Text="Watches in-game ads automatically for bonus rewards",Size=UDim2.new(1,-50,0,14),Position=UDim2.new(0,14,0,28),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9},adsHdr)

    -- Warning
    local warnCard=MakeCard(AdsPage,38,1); warnCard.BackgroundColor3=C(26,18,4); STROKE(AMBER,1,0.3,warnCard)
    NEW("TextLabel",{Text="⚠  Each ad type has a ~30s cooldown. Loops respect this automatically.",Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=AMBER,Font=Enum.Font.GothamSemibold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},warnCard)

    -- Ad cards
    local ADS={
        {key="Exp",       icon="lightning", title="+2X EXP",        desc="Double experience points from all sources",   col=Color3.fromRGB(255,218,60), dark=C(28,22,4)},
        {key="DropRate",  icon="fruit",     title="+2X DROP RATE",   desc="Double drop rate from enemies and chests",    col=Color3.fromRGB(100,200,255),dark=C(6,16,28)},
        {key="RaceReroll",icon="wave",      title="RACE REROLL",     desc="Uses an ad watch to reroll your race",        col=Color3.fromRGB(180,100,255),dark=C(16,8,30)},
    }
    for idx,ad in ipairs(ADS) do
        local adCard=MakeCard(AdsPage,108,idx+1)
        adCard.BackgroundColor3=C(math.floor(ad.col.R*255*0.055),math.floor(ad.col.G*255*0.055),math.floor(ad.col.B*255*0.055))
        STROKE(ad.col,1.5,0.18,adCard)
        -- Accent bar
        NEW("Frame",{Size=UDim2.new(0,4,0.75,0),Position=UDim2.new(0,0,0.125,0),BackgroundColor3=ad.col,BorderSizePixel=0},adCard);CORNER(2,adCard:FindFirstChildOfClass("Frame"))
        -- Icon circle (uses DrawIcon)
        local ic=NEW("Frame",{Size=UDim2.new(0,44,0,44),Position=UDim2.new(0,14,0,32),BackgroundColor3=ad.dark,BorderSizePixel=0},adCard);CORNER(22,ic);STROKE(ad.col,1.5,0.2,ic)
        DrawIcon(ic,ad.icon,8,8,28,ad.col)
        -- Text
        NEW("TextLabel",{Text=ad.title,Size=UDim2.new(1,-120,0,20),Position=UDim2.new(0,68,0,30),BackgroundTransparency=1,TextColor3=ad.col,Font=Enum.Font.GothamBold,TextSize=15},adCard)
        NEW("TextLabel",{Text=ad.desc,Size=UDim2.new(1,-120,0,26),Position=UDim2.new(0,68,0,52),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=9,TextWrapped=true},adCard)
        -- Status badge
        local sBadge=NEW("Frame",{Size=UDim2.new(0,90,0,18),Position=UDim2.new(0,68,0,82),BackgroundColor3=ad.dark,BorderSizePixel=0},adCard);CORNER(9,sBadge);STROKE(ad.col,1,0.5,sBadge)
        local sLbl=NEW("TextLabel",{Text="● IDLE",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center},sBadge)
        -- Toggle
        local pill=NEW("TextButton",{Size=UDim2.new(0,52,0,26),Position=UDim2.new(1,-62,0.5,-13),BackgroundColor3=BG5,Text="",AutoButtonColor=false},adCard);CORNER(13,pill)
        local pSt=STROKE(C(44,44,66),1.5,0.3,pill)
        local pTh=NEW("Frame",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,3,0.5,-10),BackgroundColor3=C(70,70,100),BorderSizePixel=0},pill);CORNER(10,pTh)
        local adKey=ad.key; local adCol=ad.col; local adDark=ad.dark; local running=false
        local function setOn(on)
            running=on
            TWEEN(pill,0.2,{BackgroundColor3=on and adDark or BG5})
            TWEEN(pSt,0.2,{Color=on and adCol or C(44,44,66),Transparency=on and 0 or 0.3})
            TWEEN(pTh,0.2,{BackgroundColor3=on and adCol or C(70,70,100),Position=on and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)})
            TWEEN(adCard,0.2,{BackgroundColor3=on and C(math.floor(adCol.R*255*0.10),math.floor(adCol.G*255*0.10),math.floor(adCol.B*255*0.10)) or C(math.floor(adCol.R*255*0.055),math.floor(adCol.G*255*0.055),math.floor(adCol.B*255*0.055))})
            sLbl.Text=on and "▶ RUNNING" or "● IDLE"; sLbl.TextColor3=on and adCol or TEXT3
            if on then AWA.StartLoop(adKey) else AWA.Stop(adKey) end
            TogglesData["AWA_"..adKey]={Active=on}
        end
        pill.MouseButton1Click:Connect(function() setOn(not running) end)
        TogglesData["AWA_"..adKey]={Active=false,Callback=function(s) setOn(s) end}
    end
end


-- =====================================================================
-- AUTO FARM / TRAVEL / FISHING / STATS (game world only)
-- LAZY BUILD: each page is registered as a function in _pageBuildFns.
-- Content is built ONLY when the player first clicks that tab.
-- This eliminates the startup freeze entirely — 0 heavy instances on boot.
-- =====================================================================
local FishMasterBar  -- forward-declared; assigned inside Fishing lazy build
local AutoStatsData  -- forward-declared; assigned inside Stats lazy build
if not IS_LOBBY then

-- ── AUTO FARM ──────────────────────────────────────────────────────────
-- ── GUN FARM MODULE ────────────────────────────────────────────────
local AutoFarmGun; pcall(function() AutoFarmGun=require("Farm/AutoFarmGun") end)

-- ═══════════════════════════════════════════════════════════════
-- MERGED AUTO FARM + FISHING + MERCHANT  (sub-tab layout)
-- Sub-tabs: Farm | Fishing | Config | Fruit
-- ═══════════════════════════════════════════════════════════════
local function BuildAutoFarmPage(page)
    local ac = COL_FARM

    -- Disable outer scroll — sub-tabs handle scrolling
    page.AutomaticCanvasSize = Enum.AutomaticSize.None
    page.CanvasSize          = UDim2.new(0,0,0,0)
    page.ScrollBarThickness  = 0

    -- Wrapper Frame: avoids ScrollingFrame canvas-scale issues
    -- Size=(1,0,1,0) is relative to page.AbsoluteSize — always correct.
    local WRAP = NEW("Frame",{
        Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundTransparency=1, ClipsDescendants=true, ZIndex=1,
    }, page)


    -- Shared upvalues across sub-tab builders
    local FishMasterBar      = nil   -- set by _buildFishTab, read by _buildFarmTab
    local FishStatValues     = {}
    local fsStatusLbl_ref    = nil   -- upvalue reference for live-stat label

    -- ── SUB-TAB BAR ──────────────────────────────────────────────────────────
    local TAB_H  = 40
    local subTabBar = NEW("Frame",{
        Size=UDim2.new(1,0,0,TAB_H), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=BG2, BorderSizePixel=0, ZIndex=5,
    }, page)
    NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C(30,28,55),BorderSizePixel=0}, subTabBar)
    NEW("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,3)}, subTabBar)
    NEW("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)}, subTabBar)

    local subPages   = {}
    local subTabData = {}
    local curSubIdx  = 0

    local SUB_DEFS = {
        {name="Farm",    col=COL_FARM},
        {name="Fishing", col=ORANGE  },
        {name="Config",  col=GOLD    },
        {name="Fruit",   col=GREEN   },
    }

    local function SwitchSubTab(idx)
        if curSubIdx == idx then return end
        if curSubIdx > 0 then
            local old = subTabData[curSubIdx]
            TWEEN(old.btn,0.15,{BackgroundTransparency=1})
            TWEEN(old.lbl,0.15,{TextColor3=TEXT3})
            TWEEN(old.bar,0.15,{Size=UDim2.new(0,0,0,2)})
            if subPages[curSubIdx] then subPages[curSubIdx].Visible=false end
        end
        curSubIdx = idx
        local cur = subTabData[idx]
        local cc  = cur.col
        TWEEN(cur.btn,0.18,{
            BackgroundColor3=C(math.min(255,math.floor(cc.R*255*0.14+5)),math.min(255,math.floor(cc.G*255*0.14+5)),math.min(255,math.floor(cc.B*255*0.14+5))),
            BackgroundTransparency=0,
        })
        TWEEN(cur.lbl,0.18,{TextColor3=cc})
        TWEEN(cur.bar,0.18,{Size=UDim2.new(1,0,0,2)})
        if subPages[idx] then subPages[idx].Visible=true end
    end

    for i, def in ipairs(SUB_DEFS) do
        local btn=NEW("TextButton",{Size=UDim2.new(0,84,0,30),BackgroundTransparency=1,BackgroundColor3=BG3,Text="",AutoButtonColor=false,ZIndex=6}, subTabBar)
        CORNER(8,btn)
        local lbl=NEW("TextLabel",{Text=def.name,Size=UDim2.new(1,0,1,-3),Position=UDim2.new(0,0,0,0),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7}, btn)
        local bar=NEW("Frame",{Size=UDim2.new(0,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=def.col,BorderSizePixel=0,ZIndex=7}, btn)
        CORNER(1,bar)
        local sp=NEW("ScrollingFrame",{Size=UDim2.new(1,0,1,-TAB_H),Position=UDim2.new(0,0,0,TAB_H),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=def.col,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),ClipsDescendants=true,Visible=false,ZIndex=3}, WRAP)
        NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,10)}, sp)
        NEW("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,14)}, sp)
        subPages[i]=sp; subTabData[i]={btn=btn,lbl=lbl,bar=bar,col=def.col}
        local ci=i
        btn.MouseButton1Click:Connect(function() SwitchSubTab(ci) end)
        btn.MouseEnter:Connect(function() if curSubIdx~=ci then TWEEN(btn,0.12,{BackgroundTransparency=0.6}); TWEEN(lbl,0.12,{TextColor3=TEXT1}) end end)
        btn.MouseLeave:Connect(function() if curSubIdx~=ci then TWEEN(btn,0.12,{BackgroundTransparency=1}); TWEEN(lbl,0.12,{TextColor3=TEXT3}) end end)
    end

    local spFarm    = subPages[1]
    local spFishing = subPages[2]
    local spConfig  = subPages[3]
    local spFruit   = subPages[4]

    -- Card helper (mirror of BuildMiscPage SC)
    local function SC(sp,h,lo)
        local f=NEW("Frame",{Size=UDim2.new(1,-24,0,h),BackgroundColor3=BG3,LayoutOrder=lo or 0,ClipsDescendants=true},sp)
        CORNER(10,f); STROKE(GOLD,1,0.78,f)
        NEW("Frame",{Size=UDim2.new(1,-2,0,1),Position=UDim2.new(0,1,0,0),BackgroundColor3=C(40,36,70),BorderSizePixel=0},f)
        return f
    end

    -- Shared SetToggle used by Farm tab (needs FishMasterBar upvalue)
    local function SetToggle(key,state)
        local d=TogglesData[key]; if not d or d.Active==state then return end
        d.Active=state; local on=state
        local acT=d.AccentCol or GOLD2; local adT=d.AccentDark or GOLDD
        TWEEN(d.Btn,0.22,{BackgroundColor3=on and adT or BG5})
        TWEEN(d.Strk,0.22,{Color=on and acT or TEXT3,Transparency=on and 0 or 0.45})
        local tf=d.Thumb or (d.Btn and d.Btn:FindFirstChildOfClass("Frame"))
        if tf then TWEEN(tf,0.22,{BackgroundColor3=on and acT or TEXT3,Position=on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)}) end
        if key=="AutoFishMerchant" and FishMasterBar then TWEEN(FishMasterBar,0.35,{BackgroundColor3=on and GREEN or GOLD}) end
        if d.Callback then d.Callback(state) end
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- TAB 1 — FARM  (Level Farm + Misc Farm)
    -- ══════════════════════════════════════════════════════════════════════════
    local function _buildFarmTab()
        -- RegSearch
        RegSearch("Level Farm","Auto Farm","Auto kills enemies, respawns","AutoFarmLevel")
        RegSearch("Auto Farm Level for Fishing","Auto Farm","Switches farm/fish by level","AutoFarmForFishing")
        RegSearch("Auto Get Buso","Auto Farm","Auto buy Buso Haki at LVL 80","AutoBuso")
        RegSearch("Auto Get Geppo","Auto Farm","Auto buy Geppo at LVL 125","AutoGeppo")

        -- ── LEVEL FARM CARD ────────────────────────────────────────────────
        local lfCard=SC(spFarm,222,1); CardHeader(lfCard,"sword","LEVEL FARM",AMBER)
        NEW("TextLabel",{Text="METHOD",Size=UDim2.new(1,-24,0,11),Position=UDim2.new(0,12,0,38),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8},lfCard)
        local _farmMethod="melee"
        local _gunAlreadySaved=false
        if TogglesData["Config_FarmMethod"] and type(TogglesData["Config_FarmMethod"].Value)=="string" then
            _farmMethod=TogglesData["Config_FarmMethod"].Value
            if _farmMethod=="gun" then _gunAlreadySaved=true end
        end
        local METHODS={
            {id="melee",label="MELEE",badge="BEST", col=C(72,210,140),badgeCol=C(120,255,180),desc="✔ Melee is recommended  ·  ⚠ Gun is risky"},
            {id="gun",  label="GUN",  badge="RISKY",col=C(220,140,50),badgeCol=C(255,170,80), desc="⚠ Gun farm may be unstable and could cause unexpected behavior"},
        }
        local function ShowGunWarning(onConfirm)
            local TW2=game:GetService("TweenService")
            local wSg=Instance.new("ScreenGui"); wSg.Name="ZiliGunWarning"; wSg.ResetOnSpawn=false
            wSg.Parent=gethui and gethui() or game:GetService("CoreGui")
            local bd=Instance.new("Frame",wSg); bd.Size=UDim2.new(1,0,1,0); bd.BackgroundColor3=C(0,0,0); bd.BackgroundTransparency=0.55; bd.BorderSizePixel=0
            local cd=NEW("Frame",{Size=UDim2.new(0,270,0,130),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=C(16,14,30),BorderSizePixel=0},wSg)
            CORNER(12,cd); STROKE(C(220,140,50),1.5,0.1,cd)
            local acc=Instance.new("Frame",cd); acc.Size=UDim2.new(0,3,0.7,0); acc.Position=UDim2.new(0,0,0.15,0); acc.BackgroundColor3=C(220,140,50); acc.BorderSizePixel=0; CORNER(2,acc)
            NEW("TextLabel",{Text="⚠  GUN METHOD — RISKY",Size=UDim2.new(1,-18,0,22),Position=UDim2.new(0,14,0,8),BackgroundTransparency=1,TextColor3=C(255,170,80),Font=Enum.Font.GothamBold,TextSize=12},cd)
            NEW("TextLabel",{Text="Gun farm may be unstable.\nAre you sure?",Size=UDim2.new(1,-18,0,42),Position=UDim2.new(0,14,0,34),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true},cd)
            local function MkBtn(xOff,w,txt,bgC,txtC,cb)
                local b=NEW("TextButton",{Size=UDim2.new(0,w,0,26),Position=UDim2.new(0,xOff,0,94),BackgroundColor3=bgC,Text=txt,TextColor3=txtC,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false},cd)
                CORNER(8,b); b.MouseButton1Click:Connect(function() wSg:Destroy(); if cb then cb() end end)
            end
            MkBtn(14,114,"CANCEL",C(22,22,40),C(140,130,160),nil)
            MkBtn(142,114,"USE GUN ANYWAY",C(50,25,8),C(255,170,80),onConfirm)
            cd.BackgroundTransparency=1; TW2:Create(cd,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
        end
        local methodBtns={}
        local methodDesc
        for i,m in ipairs(METHODS) do
            local xOff=i==1 and 12 or 4; local xScale=i==1 and 0 or 0.5
            local selBg=C(math.floor(m.col.R*255*0.18),math.floor(m.col.G*255*0.18),math.floor(m.col.B*255*0.18))
            local offBg=C(14,14,26); local initSel=(_farmMethod==m.id)
            local mb=NEW("TextButton",{Size=UDim2.new(0.5,-16,0,42),Position=UDim2.new(xScale,xOff,0,48),BackgroundColor3=initSel and selBg or offBg,BorderSizePixel=0,Text="",AutoButtonColor=false},lfCard)
            local ms=STROKE(m.col,1.5,initSel and 0.05 or 0.65,mb)
            local mainLbl=NEW("TextLabel",{Text=m.label,Size=UDim2.new(1,-4,0,16),Position=UDim2.new(0,0,0,6),BackgroundTransparency=1,TextColor3=initSel and m.col or C(130,130,160),Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Center},mb)
            local badgeBg=NEW("Frame",{Size=UDim2.new(0,60,0,16),Position=UDim2.new(0.5,-30,0,24),BackgroundColor3=C(math.floor(m.badgeCol.R*255*0.08),math.floor(m.badgeCol.G*255*0.08),math.floor(m.badgeCol.B*255*0.08)),BorderSizePixel=0},mb); CORNER(8,badgeBg); STROKE(m.badgeCol,1,0.3,badgeBg)
            NEW("TextLabel",{Text=m.badge,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=m.badgeCol,Font=Enum.Font.GothamBold,TextSize=9},badgeBg)
            table.insert(methodBtns,{btn=mb,strk=ms,m=m,selBg=selBg,offBg=offBg,lbl=mainLbl})
            local mi=i; local mm=m
            mb.MouseButton1Click:Connect(function()
                if mm.id=="gun" and not _gunAlreadySaved then
                    ShowGunWarning(function()
                        _farmMethod="gun"; _gunAlreadySaved=true
                        if not TogglesData["Config_FarmMethod"] then TogglesData["Config_FarmMethod"]={Value="gun"} else TogglesData["Config_FarmMethod"].Value="gun" end
                        for j,d in ipairs(methodBtns) do local sel=(d.m.id=="gun"); TWEEN(d.btn,0.18,{BackgroundColor3=sel and d.selBg or d.offBg}); TWEEN(d.strk,0.18,{Transparency=sel and 0.05 or 0.65}); if d.lbl then d.lbl.TextColor3=sel and d.m.col or C(130,130,160) end end
                        if methodDesc then methodDesc.Text=mm.desc end
                    end); return
                end
                _farmMethod=mm.id
                if not TogglesData["Config_FarmMethod"] then TogglesData["Config_FarmMethod"]={Value=mm.id} else TogglesData["Config_FarmMethod"].Value=mm.id end
                for j,d in ipairs(methodBtns) do local sel=(j==mi); TWEEN(d.btn,0.18,{BackgroundColor3=sel and d.selBg or d.offBg}); TWEEN(d.strk,0.18,{Transparency=sel and 0.05 or 0.65}); if d.lbl then d.lbl.TextColor3=sel and d.m.col or C(130,130,160) end end
                if methodDesc then methodDesc.Text=mm.desc end
            end)
            mb.MouseEnter:Connect(function() if _farmMethod~=mm.id then TWEEN(mb,0.12,{BackgroundColor3=C(math.floor(mm.col.R*255*0.10),math.floor(mm.col.G*255*0.10),math.floor(mm.col.B*255*0.10))}) end end)
            mb.MouseLeave:Connect(function() if _farmMethod~=mm.id then TWEEN(mb,0.12,{BackgroundColor3=offBg}) end end)
        end
        if not TogglesData["Config_FarmMethod"] then TogglesData["Config_FarmMethod"]={Value=_farmMethod} end
        TogglesData["Config_FarmMethod"].Callback=function(val)
            _farmMethod=(val=="gun" or val=="melee") and val or "melee"
            for j,d in ipairs(methodBtns) do
                local sel=(d.m.id==_farmMethod); TWEEN(d.btn,0.18,{BackgroundColor3=sel and d.selBg or d.offBg}); TWEEN(d.strk,0.18,{Transparency=sel and 0.05 or 0.65})
                if d.lbl then d.lbl.TextColor3=sel and d.m.col or C(130,130,160) end
            end
        end
        methodDesc=NEW("TextLabel",{Text="✔ Melee is recommended  ·  ⚠ Gun is risky",Size=UDim2.new(1,-24,0,12),Position=UDim2.new(0,12,0,96),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center},lfCard)
        RowDivider(lfCard,112)
        RowLabel(lfCard,"Level Farm","Start farming with selected method",118)
        CardToggle(lfCard,118,"AutoFarmLevel",function(state)
            if _farmMethod=="melee" then if AutoFarmLevel then AutoFarmLevel.Toggle(state) end
            else if AutoFarmGun then AutoFarmGun.Toggle(state) end end
            pcall(getgenv().ZiliLog, state and "Level farm started" or "Level farm stopped","farm")
        end,AMBER)
        RowDivider(lfCard,156)
        RowLabel(lfCard,"Auto Farm Level for Fishing","< 375 → Farm  ·  ≥ 375 → Fish",162)
        local function GetPlayerLevel()
            local level=0; pcall(function() local sf=game:GetService("ReplicatedStorage"):FindFirstChild("Stats"..LocalPlayer.Name); if sf then local s=sf:FindFirstChild("Stats"); local lv=s and s:FindFirstChild("Level"); if lv then level=tonumber(lv.Value) or 0 end end end)
            return level
        end
        CardToggle(lfCard,172,"AutoFarmForFishing",function(state)
            if not state then SetToggle("AutoFarmLevel",false); SetToggle("AutoFishMerchant",false)
            else task.spawn(function() local level=GetPlayerLevel(); if level<375 then SetToggle("AutoFarmLevel",true) else SetToggle("AutoFishMerchant",true) end end)
            end
        end,COL_FISH)
        task.spawn(function()
            while AutoFarmPage and AutoFarmPage.Parent do task.wait(3)
                if not TogglesData["AutoFarmForFishing"] or not TogglesData["AutoFarmForFishing"].Active then continue end
                local level=GetPlayerLevel()
                if level<375 and TogglesData["AutoFishMerchant"] and TogglesData["AutoFishMerchant"].Active then
                    SetToggle("AutoFishMerchant",false); SetToggle("AutoFarmLevel",true)
                elseif level>=375 and TogglesData["AutoFarmLevel"] and TogglesData["AutoFarmLevel"].Active then
                    SetToggle("AutoFarmLevel",false); SetToggle("AutoFishMerchant",true)
                end
            end
        end)

        -- ── MISC FARM CARD ─────────────────────────────────────────────────
        local mfCard=SC(spFarm,148,2); CardHeader(mfCard,"fist","MISC FARM",GOLD2)
        local MISC_ROWS={
            {"Auto Get Buso","REQ → LVL 375+  ·  25,000 PELI",36,"AutoBuso",function(s) if AutoGetBuso then AutoGetBuso.Toggle(s) end end},
            {"Auto Get Geppo","REQ → LVL 375+  ·  Geppo Skill",78,"AutoGeppo",function(s) if AutoGetGeppo then AutoGetGeppo.Toggle(s) end end},
        }
        for i,row in ipairs(MISC_ROWS) do
            local label,req,py,key,baseCb=row[1],row[2],row[3],row[4],row[5]
            RowLabel(mfCard,label,req,py); if i>1 then RowDivider(mfCard,py-10) end
            local btn,strk,thumb=CardToggle(mfCard,py+8,key,baseCb,COL_FARM)
            if key=="AutoGeppo" then
                TogglesData[key].Callback=function(state)
                    if AutoGeppoFunc then AutoGeppoFunc.Toggle(state) end
                    if state then task.spawn(function() while ZiliState.AutoGeppo do task.wait(0.5) end; if TogglesData["AutoGeppo"] then TogglesData["AutoGeppo"].Active=false end end) end
                end
            end
        end
    end
    _buildFarmTab()

    -- ══════════════════════════════════════════════════════════════════════════
    -- TAB 2 — FISHING  (main toggle + live stats)
    -- ══════════════════════════════════════════════════════════════════════════
    local function _buildFishTab()
        RegSearch("Auto Fishing + Merchant","Auto Farm","Auto catch, sell, restock bait","AutoFishMerchant")

        -- Main fishing toggle card
        local fmCard=SC(spFishing,80,1); CardHeader(fmCard,"fish","FISHING + MERCHANT FARM",ORANGE)
        FishMasterBar=NEW("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=GOLD,BorderSizePixel=0},fmCard); CORNER(2,FishMasterBar)
        NEW("TextLabel",{Text="Enable Auto Fishing + Merchant",Size=UDim2.new(0.75,0,0,20),Position=UDim2.new(0,14,0,14),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=12},fmCard)
        NEW("TextLabel",{Text="Auto catch  ·  sell  ·  restock bait in loop",Size=UDim2.new(0.75,0,0,14),Position=UDim2.new(0,14,0,34),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9},fmCard)
        local StartFishToggle=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-58,0,40),BackgroundColor3=BG5,Text="",AutoButtonColor=false},fmCard)
        CORNER(13,StartFishToggle)
        local FishToggleStroke=STROKE(C(44,44,66),1,0.45,StartFishToggle)
        local FishThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},StartFishToggle); CORNER(9,FishThumb)
        TogglesData["AutoFishMerchant"]={Active=false,Btn=StartFishToggle,Strk=FishToggleStroke,Thumb=FishThumb,AccentCol=COL_FISH,AccentDark=C(10,40,60),MasterBar=FishMasterBar,Callback=function(on)
            if AutoFishing then AutoFishing.Toggle(on) end
            pcall(getgenv().ZiliLog, on and "Fish+Merchant started" or "Fish+Merchant stopped","fish")
        end}
        StartFishToggle.MouseButton1Click:Connect(function()
            local d=TogglesData["AutoFishMerchant"]; d.Active=not d.Active; local on=d.Active
            local acF=COL_FISH; local adF=C(10,40,60)
            TWEEN(StartFishToggle,0.22,{BackgroundColor3=on and adF or BG5}); TWEEN(FishToggleStroke,0.22,{Color=on and acF or C(44,44,66),Transparency=on and 0 or 0.45})
            TWEEN(FishThumb,0.22,{BackgroundColor3=on and acF or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)})
            TWEEN(FishMasterBar,0.35,{BackgroundColor3=on and COL_FISH or GOLD})
            if d.Callback then d.Callback(on) end
        end)

        -- Live stats card
        local fsCard=SC(spFishing,186,2); fsCard.BackgroundColor3=C(8,9,18)
        local fsHeader=NEW("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=BG_HDR},fsCard); CORNER(8,fsHeader)
        NEW("Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BackgroundColor3=BG_HDR,BorderSizePixel=0},fsHeader)
        local fsIconBg=NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,7,0,4),BackgroundColor3=C(28,14,0),BorderSizePixel=0},fsHeader); CORNER(4,fsIconBg)
        NEW("TextLabel",{Text="LIVE STATS",Size=UDim2.new(0,100,1,0),Position=UDim2.new(0,30,0,0),BackgroundTransparency=1,TextColor3=ORANGE,Font=Enum.Font.GothamBold,TextSize=9},fsHeader)
        local fsExpandBg=NEW("Frame",{Size=UDim2.new(0,22,0,16),Position=UDim2.new(1,-26,0.5,-8),BackgroundColor3=C(20,10,0),BorderSizePixel=0},fsHeader); CORNER(4,fsExpandBg); STROKE(ORANGE,1,0.3,fsExpandBg)
        local fsExpandBtn=NEW("TextButton",{Text="",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=2},fsExpandBg)
        local _fsPlusH=NEW("Frame",{Size=UDim2.new(0,10,0,2),Position=UDim2.new(0.5,-5,0.5,-1),BackgroundColor3=ORANGE,BorderSizePixel=0},fsExpandBg)
        local _fsPlusV=NEW("Frame",{Size=UDim2.new(0,2,0,10),Position=UDim2.new(0.5,-1,0.5,-5),BackgroundColor3=ORANGE,BorderSizePixel=0},fsExpandBg)
        local FISH_STAT_DEF={{"chest","MYTHIC","--","MythicChest",AMBER,1,0},{"arrows","LEG BAIT","--","LegBait",PURPLE,1,1},{"coin","PELI","--","Peli",COL_FISH,2,0},{"star","TARGET BAIT","--","TargetBait",GREEN,2,1}}
        NEW("Frame",{Size=UDim2.new(0,1,0,138),Position=UDim2.new(0.5,0,0,24),BackgroundColor3=C(28,26,48),BorderSizePixel=0},fsCard)
        NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,102),BackgroundColor3=C(28,26,48),BorderSizePixel=0},fsCard)
        for _,def in ipairs(FISH_STAT_DEF) do
            local iconName,lbl,val,key,accentC,row,col2=def[1],def[2],def[3],def[4],def[5],def[6],def[7]
            local rowY=(row==1) and 28 or 104; local xScale=col2*0.5; local cellMid=xScale+0.25
            local iconCell=NEW("Frame",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(cellMid,-14,0,rowY),BackgroundColor3=C(math.floor(accentC.R*255*0.08),math.floor(accentC.G*255*0.08),math.floor(accentC.B*255*0.08)),BorderSizePixel=0},fsCard); CORNER(6,iconCell); STROKE(accentC,1,0.3,iconCell)
            local valLbl=NEW("TextLabel",{Text=val,Size=UDim2.new(0.5,-4,0,22),Position=UDim2.new(xScale,2,0,rowY+30),BackgroundTransparency=1,TextColor3=accentC,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Center},fsCard)
            NEW("TextLabel",{Text=lbl,Size=UDim2.new(0.5,-4,0,11),Position=UDim2.new(xScale,2,0,rowY+54),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center},fsCard)
            FishStatValues[key]=valLbl
        end
        local fsStatusLbl=NEW("TextLabel",{Text="Status: Idle",Size=UDim2.new(1,-8,0,12),Position=UDim2.new(0,4,0,168),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},fsCard)
        fsStatusLbl_ref=fsStatusLbl
        getgenv().GBO_SetFishStatus=function(msg) pcall(function() if fsStatusLbl and fsStatusLbl.Parent then fsStatusLbl.Text="Status: "..(msg or "Idle") end end) end
        local _fsOverlay=nil
        fsExpandBtn.MouseButton1Click:Connect(function()
            if _fsOverlay and _fsOverlay.Parent then _fsOverlay:Destroy(); _fsOverlay=nil; _fsPlusV.Visible=true; return end
            _fsPlusV.Visible=false
            _fsOverlay=NEW("Frame",{Size=UDim2.new(0,150,0,150),Position=UDim2.new(0.5,-75,0.5,-75),BackgroundColor3=C(12,10,22),BorderSizePixel=0,ZIndex=80},fsCard)
            CORNER(10,_fsOverlay); STROKE(ORANGE,1.5,0.08,_fsOverlay)
            NEW("TextLabel",{Text="LIVE STATS",Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,TextColor3=ORANGE,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=81},_fsOverlay)
            local closeFs=NEW("TextButton",{Text="x",Size=UDim2.new(0,18,0,18),Position=UDim2.new(1,-20,0,1),BackgroundColor3=C(40,8,4),TextColor3=C(255,80,60),Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,ZIndex=81},_fsOverlay); CORNER(5,closeFs)
            closeFs.MouseButton1Click:Connect(function() if _fsOverlay then _fsOverlay:Destroy(); _fsOverlay=nil; _fsPlusV.Visible=true end end)
            local OVERLAY_DEFS={{"MYTHIC","MythicChest",AMBER,4,24},{"LEG BAIT","LegBait",PURPLE,79,24},{"PELI","Peli",COL_FISH,4,90},{"STATUS","Status",TEXT2,79,90}}
            for _,od in ipairs(OVERLAY_DEFS) do
                local lbl2,key2,col2,ox,oy=od[1],od[2],od[3],od[4],od[5]
                local cell=NEW("Frame",{Size=UDim2.new(0,63,0,56),Position=UDim2.new(0,ox,0,oy),BackgroundColor3=C(math.floor(col2.R*255*0.06),math.floor(col2.G*255*0.06),math.floor(col2.B*255*0.06)),BorderSizePixel=0,ZIndex=81},_fsOverlay); CORNER(6,cell); STROKE(col2,1,0.35,cell)
                local vLbl=NEW("TextLabel",{Text=FishStatValues[key2] and FishStatValues[key2].Text or "--",Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,8),BackgroundTransparency=1,TextColor3=col2,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=82},cell)
                NEW("TextLabel",{Text=lbl2,Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,32),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=82},cell)
                local kk=key2
                task.spawn(function() while _fsOverlay and _fsOverlay.Parent do task.wait(2); if FishStatValues[kk] then pcall(function() vLbl.Text=FishStatValues[kk].Text end) end end end)
            end
            TWEEN_BACK(_fsOverlay,0.22,{Position=UDim2.new(0.5,-75,0.5,-75)})
        end)
        local _lastMythic=0
        task.spawn(function()
            while fsCard and fsCard.Parent do task.wait(2.5)
                pcall(function()
                    local sf=game:GetService("ReplicatedStorage"):FindFirstChild("Stats"..LocalPlayer.Name); if not sf then return end
                    local inv={}; local invNode=sf:FindFirstChild("Inventory"); invNode=invNode and invNode:FindFirstChild("Value")
                    if invNode then local ok,decoded=pcall(function() return HttpService:JSONDecode(invNode.Value) end); if ok and type(decoded)=="table" then inv=decoded end end
                    local peliVal="0"; local sn=sf:FindFirstChild("Stats"); local pn=sn and sn:FindFirstChild("Peli")
                    if pn then peliVal=tostring(math.floor(tonumber(pn.Value) or 0)) end
                    local bait=ZiliState.TargetBait or "Common Fish Bait"
                    local mythicCount=inv["Mythical Fruit Chest"] or 0
                    if mythicCount>_lastMythic then
                        local gained=mythicCount-_lastMythic
                        Toast("+"..gained.." Mythic Chest"..(gained>1 and "s" or "").." obtained!",AMBER,"⬡")
                        TabBadge("Auto Farm",mythicCount,AMBER)
                    end
                    _lastMythic=mythicCount
                    local updates={MythicChest=tostring(mythicCount),LegBait=tostring(inv["Legendary Fish Bait"] or 0),Peli=peliVal,TargetBait=tostring(inv[bait] or 0)}
                    for key2,val2 in pairs(updates) do if FishStatValues[key2] then FishStatValues[key2].Text=val2 end end
                end)
            end
        end)
    end
    _buildFishTab()

    -- ══════════════════════════════════════════════════════════════════════════
    -- TAB 3 — CONFIG  (dropdowns + buy items list)
    -- ══════════════════════════════════════════════════════════════════════════
    local function _buildConfigTab()
        RegSearch("Auto Craft Lovestruck Rod","Auto Farm","Craft rod when Mero + Banana Rod + Blueprint available","AutoCraftRod")

        local fcCard=SC(spConfig,622,1); CardHeader(fcCard,"gear","CONFIGURATION",GOLD)

        local function CreateDropdown(parent,titleText,options,defaultSelect,posY,configKey,isMulti,showSearch)
            NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,posY),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=10,Text=titleText},parent)
            local headBtn=NEW("TextButton",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,posY-2),BackgroundColor3=BG5,Text=defaultSelect or "Select...",TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,AutoButtonColor=false},parent)
            CORNER(5,headBtn); local headStroke=STROKE(GOLD3,1,0.3,headBtn)
            local dropScroll=NEW("ScrollingFrame",{Size=UDim2.new(0,158,0,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=C(10,10,22),BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=GOLD2,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),ZIndex=200,Visible=false},parent)
            CORNER(5,dropScroll); STROKE(GOLD3,1,0,dropScroll); NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,1),SortOrder=Enum.SortOrder.LayoutOrder},dropScroll)
            local searchInput
            if showSearch then
                searchInput=NEW("TextBox",{Size=UDim2.new(1,-6,0,24),BackgroundColor3=C(10,10,22),Text="",PlaceholderText="Search...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,BorderSizePixel=0,ZIndex=201},dropScroll)
                CORNER(4,searchInput); STROKE(GOLD3,1,0.2,searchInput)
            end
            local initVal=isMulti and {} or nil
            local function defaultCallback(val)
                if isMulti then local ct=0; for _,b in ipairs(dropScroll:GetChildren()) do if b:IsA("TextButton") and TogglesData[configKey] and TogglesData[configKey].Value[b.Text] then ct+=1 end end
                    headBtn.Text=ct>0 and (ct.." selected") or "Select..."; headBtn.TextColor3=ct>0 and GOLD2 or TEXT3
                else for _,b in ipairs(dropScroll:GetChildren()) do if b:IsA("TextButton") then TWEEN(b,0.1,{TextColor3=b.Text==val and GOLD2 or TEXT2}) end end
                    if val then headBtn.Text=val; headBtn.TextColor3=GOLD2 end
                end
            end
            TogglesData[configKey]={Value=initVal,Callback=defaultCallback,HeadBtn=headBtn}
            if not isMulti and defaultSelect then TogglesData[configKey].Value=defaultSelect end
            local function openDrop()
                local absPos=headBtn.AbsolutePosition; local absSize=headBtn.AbsoluteSize
                dropScroll.Position=UDim2.new(0,absPos.X-fcCard.AbsolutePosition.X,0,absPos.Y-fcCard.AbsolutePosition.Y+absSize.Y+2)
                dropScroll.Size=UDim2.new(0,absSize.X,0,math.min(120,#options*26))
                dropScroll.Visible=true; TWEEN(headStroke,0.15,{Color=GOLD2})
            end
            local function closeDrop() dropScroll.Visible=false; TWEEN(headStroke,0.15,{Color=GOLD3}) end
            headBtn.MouseButton1Click:Connect(function() if dropScroll.Visible then closeDrop() else openDrop() end end)
            UIS.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 and dropScroll.Visible and not headBtn:IsDescendantOf(game.Players.LocalPlayer.PlayerGui) then closeDrop() end end)
            for idx,opt in ipairs(options) do
                local btn=NEW("TextButton",{Size=UDim2.new(1,-6,0,24),BackgroundTransparency=1,ZIndex=201,Text="  "..opt,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},dropScroll)
                btn.MouseEnter:Connect(function() TWEEN(btn,0.1,{BackgroundTransparency=0.85,BackgroundColor3=BG4,TextColor3=GOLD2}) end)
                btn.MouseLeave:Connect(function() local isSel=isMulti and (TogglesData[configKey] and TogglesData[configKey].Value[opt]) or (not isMulti and TogglesData[configKey] and TogglesData[configKey].Value==opt); TWEEN(btn,0.1,{BackgroundTransparency=isSel and 0.7 or 1,TextColor3=isSel and GOLD2 or TEXT2}) end)
                btn.MouseButton1Click:Connect(function()
                    if isMulti then local cur=TogglesData[configKey].Value; cur[opt]=not cur[opt]; if cur[opt] then TWEEN(btn,0.1,{TextColor3=GOLD2,BackgroundTransparency=0.7,BackgroundColor3=BG4}) else TWEEN(btn,0.1,{TextColor3=TEXT2,BackgroundTransparency=1}) end
                    else for _,ob in ipairs(dropScroll:GetChildren()) do if ob:IsA("TextButton") then TWEEN(ob,0.1,{TextColor3=ob==btn and GOLD2 or TEXT2,BackgroundTransparency=ob==btn and 0.7 or 1,BackgroundColor3=BG4}) end end; TogglesData[configKey].Value=opt; closeDrop() end
                    if defaultCallback then defaultCallback(isMulti and TogglesData[configKey].Value or opt) end
                end)
            end
        end

        CreateDropdown(fcCard,"Auto Select Bait",{"Common Fish Bait","Rare Fish Bait","Legendary Fish Bait"},nil,40,"Config_SelectBait",false,false)
        CreateDropdown(fcCard,"Auto Sell Fish",{"Common Fish","Rare Fish","Legendary Fish"},nil,86,"Config_SellFish",true,false)

        -- Buy items
        do
            local BUY_ITEMS={"All Seeing Shamrock","Mythical Fruit Chest","Legendary Fruit Chest","Tropical Parrot","Coffin Boat","Striker","Hoverboard","Legendary Fish Bait","Merchants Banana Rod","Knight's Gauntlet","Crab Cutlass","Bisento","Kessui","Raiui","Hunter's Journal","Jitte","Crimson Nightcoat","Sea-Breeze Haori","Spirit Color Essence","Platinum Coat","Red Cloud Costume","Demon Corps Costume","Rare Fruit Chest","Thrilled Ship","Spare Fruit Bag","Bomi's Log Pose","Gravity Blade","Race Reroll","Dark Root","Rare Fish Bait","Golden Staff","Golden Hook","Karoo Mount","Special Tailor Token","SP Reset Essence"}
            local ITEM_RARITY={["All Seeing Shamrock"]="Mythic",["Mythical Fruit Chest"]="Mythic",["Legendary Fruit Chest"]="Legendary",["Tropical Parrot"]="Legendary",["Coffin Boat"]="Legendary",["Striker"]="Legendary",["Hoverboard"]="Legendary",["Legendary Fish Bait"]="Legendary",["Merchants Banana Rod"]="Legendary",["Knight's Gauntlet"]="Legendary",["Crab Cutlass"]="Legendary",["Bisento"]="Legendary",["Kessui"]="Legendary",["Raiui"]="Legendary",["Hunter's Journal"]="Epic",["Jitte"]="Epic",["Crimson Nightcoat"]="Epic",["Sea-Breeze Haori"]="Epic",["Spirit Color Essence"]="Epic",["Platinum Coat"]="Epic",["Red Cloud Costume"]="Epic",["Demon Corps Costume"]="Epic",["Rare Fruit Chest"]="Rare",["Thrilled Ship"]="Rare",["Spare Fruit Bag"]="Rare",["Bomi's Log Pose"]="Rare",["Gravity Blade"]="Rare",["Race Reroll"]="Rare",["Dark Root"]="Rare",["Rare Fish Bait"]="Rare",["Golden Staff"]="Rare",["Golden Hook"]="Rare",["Karoo Mount"]="Uncommon",["Special Tailor Token"]="Uncommon",["SP Reset Essence"]="Common"}
            local RARITY_COL={Mythic=Color3.fromRGB(255,60,60),Legendary=Color3.fromRGB(255,165,0),Epic=Color3.fromRGB(170,70,255),Rare=Color3.fromRGB(60,170,255),Uncommon=Color3.fromRGB(56,200,110),Common=Color3.fromRGB(220,220,220)}
            NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,130),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=10,Text="Buy Items at Merchant"},fcCard)
            local buyCountBadge=NEW("TextLabel",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,128),BackgroundColor3=BG5,Text="Select items...",TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10},fcCard); CORNER(5,buyCountBadge); STROKE(GOLD3,1,0.3,buyCountBadge)
            local bss=STROKE(GOLD3,1,0.3,buyCountBadge)
            local buySearchBox=NEW("TextBox",{Size=UDim2.new(1,-24,0,26),Position=UDim2.new(0,12,0,158),BackgroundColor3=BG5,Text="",PlaceholderText="Search items...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,BorderSizePixel=0},fcCard)
            CORNER(6,buySearchBox); STROKE(GOLD3,1,0.3,buySearchBox)
            buySearchBox.Focused:Connect(function() buySearchBox.Text=""; TWEEN(bss,0.15,{Color=GOLD2}) end)
            buySearchBox.FocusLost:Connect(function() TWEEN(bss,0.15,{Color=GOLD3}) end)
            local buyList=NEW("ScrollingFrame",{Size=UDim2.new(1,-24,0,120),Position=UDim2.new(0,12,0,190),BackgroundColor3=BG5,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=GOLD2,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)},fcCard); CORNER(6,buyList)
            NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},buyList)
            local buyBtns={}
            TogglesData["Config_BuyItems"]={Value={},HeadBtn=buyCountBadge,Callback=function(val)
                if type(val)~="table" then return end
                local ct=0
                for itemName,data in pairs(buyBtns) do
                    local sel=val[itemName]==true
                    if data.check then data.check.Text=sel and "✓" or "" end
                    if data.nameLbl then local baseCol=RARITY_COL[ITEM_RARITY[itemName] or "Common"]; data.nameLbl.TextColor3=sel and baseCol or TEXT2; data.nameLbl.Font=sel and Enum.Font.GothamBold or Enum.Font.Gotham end
                    if sel then ct+=1 end
                end
                buyCountBadge.Text=ct>0 and (ct.." Selected") or "Select items..."
                buyCountBadge.TextColor3=ct>0 and GOLD2 or TEXT3
                TogglesData["Config_BuyItems"].Value=val
            end}
            for idx,itemName in ipairs(BUY_ITEMS) do
                local rarity=ITEM_RARITY[itemName] or "Common"; local rarCol=RARITY_COL[rarity]
                local row=NEW("Frame",{Size=UDim2.new(1,-6,0,26),BackgroundColor3=BG3,Name=itemName,BorderSizePixel=0},buyList); CORNER(4,row)
                local dotLbl=NEW("TextLabel",{Text="●",Size=UDim2.new(0,14,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,TextColor3=rarCol,Font=Enum.Font.GothamBold,TextSize=9},row)
                local nameLabel=NEW("TextLabel",{Text=itemName,Size=UDim2.new(1,-42,1,0),Position=UDim2.new(0,18,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},row)
                local check=NEW("TextLabel",{Text="",Size=UDim2.new(0,22,1,0),Position=UDim2.new(1,-24,0,0),BackgroundTransparency=1,TextColor3=rarCol,Font=Enum.Font.GothamBold,TextSize=12},row)
                local rowBtn=NEW("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false},row)
                rowBtn.MouseEnter:Connect(function() TWEEN(row,0.1,{BackgroundColor3=BG4}) end)
                rowBtn.MouseLeave:Connect(function() TWEEN(row,0.1,{BackgroundColor3=BG3}) end)
                local iN=itemName; local rC=rarCol
                rowBtn.MouseButton1Click:Connect(function()
                    local cur=TogglesData["Config_BuyItems"].Value; cur[iN]=not cur[iN]
                    if cur[iN] then check.Text="✓"; nameLabel.TextColor3=rC; nameLabel.Font=Enum.Font.GothamBold
                    else check.Text=""; nameLabel.TextColor3=rC; nameLabel.Font=Enum.Font.Gotham end
                    local ct=0; for _,v in pairs(cur) do if v then ct+=1 end end
                    buyCountBadge.Text=ct>0 and (ct.." Selected") or "Select items..."
                    buyCountBadge.TextColor3=ct>0 and GOLD2 or TEXT3
                end)
                buyBtns[itemName]={row=row,check=check,nameLbl=nameLabel,dot=dotLbl}
            end
            buySearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local ft=buySearchBox.Text:lower()
                for name,data in pairs(buyBtns) do data.row.Visible=ft=="" or name:lower():find(ft,1,true)~=nil end
            end)
        end

        CreateDropdown(fcCard,"Auto Craft Bait",{"Rare Fish Bait","Legendary Fish Bait"},nil,326,"Config_CraftBait",false,false)
        CreateDropdown(fcCard,"Craft Mode  (Rare Bait)",{"single","all"},"single",370,"Config_CraftRareMode",false,false)

        ZiliState.FishBuyAmount=50
        NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,410),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=10,Text="Buy Amount (per bait)"},fcCard)
        local buyAmtFrame=NEW("Frame",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,408),BackgroundColor3=BG5,BorderSizePixel=0},fcCard); CORNER(5,buyAmtFrame)
        local buyAmtStroke=STROKE(GOLD3,1,0.3,buyAmtFrame)
        local buyAmtBox=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="50",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=11,ClearTextOnFocus=true},buyAmtFrame)
        buyAmtBox.Focused:Connect(function() TWEEN(buyAmtStroke,0.15,{Color=GOLD2}) end)
        buyAmtBox.FocusLost:Connect(function() local n=tonumber(buyAmtBox.Text); if n and n>0 then ZiliState.FishBuyAmount=math.floor(n); buyAmtBox.Text=tostring(math.floor(n)) else buyAmtBox.Text=tostring(ZiliState.FishBuyAmount) end; TWEEN(buyAmtStroke,0.15,{Color=GOLD3}) end)
        TogglesData["Config_BaitAmount"]={Value=50,HeadBtn=buyAmtBox,Callback=function(val) local n=tonumber(val); if n and n>0 then ZiliState.FishBuyAmount=math.floor(n); buyAmtBox.Text=tostring(math.floor(n)) end end}

        NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,448),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=10,Text="Discord Webhook"},fcCard)
        local boxFrameWH=NEW("Frame",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,446),BackgroundColor3=BG5,BorderSizePixel=0},fcCard); CORNER(5,boxFrameWH); STROKE(GOLD3,1,0.3,boxFrameWH)
        local textBoxWH=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="",PlaceholderText="https://discord.com/api/webhooks/...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,ClearTextOnFocus=false},boxFrameWH)
        TogglesData["Config_Webhook"]={Value="",HeadBtn=textBoxWH,Callback=function(val) ZiliState.WebhookUrl=val; if textBoxWH then textBoxWH.Text=val or "" end end}
        textBoxWH.FocusLost:Connect(function() ZiliState.WebhookUrl=textBoxWH.Text; TogglesData["Config_Webhook"].Value=textBoxWH.Text end)

        RowDivider(fcCard,486)
        RowLabel(fcCard,"Auto Equip Fruit Bag","Auto equips fruit bag when looting",494)
        CardToggle(fcCard,494,"AutoEquipFruitBag",function(s) ZiliState.AutoEquipFruitBag=s end,GREEN)
        RowDivider(fcCard,532)
        RowLabel(fcCard,"Auto Set Spawn  —  Shell Town","Sets respawn point to Shell's Town on death",540)
        CardToggle(fcCard,540,"AutoSetSpawnShellTown",function(s) ZiliState.AutoSetSpawnShellTown=s; if s then ZiliState.SpawnPoint="ShellTown" end end,COL_FARM)
        RowDivider(fcCard,578)
        RowLabel(fcCard,"Auto Craft Lovestruck Rod","Craft when you have Mero + Banana Rod + Blueprint",586)
        CardToggle(fcCard,586,"AutoCraftRod",function(s) ZiliState.AutoCraftRod=s end,ORANGE)
    end
    _buildConfigTab()

    -- ══════════════════════════════════════════════════════════════════════════
    -- TAB 4 — FRUIT  (Fruit Management)
    -- ══════════════════════════════════════════════════════════════════════════
    local function _buildFruitTab()
        RegSearch("Auto Store Fruit","Auto Farm","Auto store fruit to inventory","AutoStoreFruit")
        RegSearch("Auto Drop Fruit","Auto Farm","Drop fruit when inventory full","AutoDropFruit")

        local function CreateDropdownFruit(parent,titleText,options,defaultSelect,posY,configKey)
            NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,posY),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=10,Text=titleText},parent)
            local hBtn=NEW("TextButton",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,posY-2),BackgroundColor3=BG5,Text=defaultSelect or "Select...",TextColor3=defaultSelect and GOLD2 or TEXT3,Font=Enum.Font.Gotham,TextSize=10,AutoButtonColor=false},parent)
            CORNER(5,hBtn); local hS=STROKE(GOLD3,1,0.3,hBtn)
            local dScroll=NEW("ScrollingFrame",{Size=UDim2.new(0,158,0,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=C(10,10,22),BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=GREEN,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),ZIndex=200,Visible=false},parent)
            CORNER(5,dScroll); STROKE(GOLD3,1,0,dScroll); NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,1),SortOrder=Enum.SortOrder.LayoutOrder},dScroll)
            TogglesData[configKey]={Value=defaultSelect,HeadBtn=hBtn,Callback=function(val) hBtn.Text=val or "Select..."; hBtn.TextColor3=val and GREEN or TEXT3 end}
            local function openD() dScroll.Size=UDim2.new(0,158,0,math.min(120,#options*26)); dScroll.Position=UDim2.new(1,-170,0,posY+22); dScroll.Visible=true; TWEEN(hS,0.15,{Color=GREEN}) end
            local function closeD() dScroll.Visible=false; TWEEN(hS,0.15,{Color=GOLD3}) end
            hBtn.MouseButton1Click:Connect(function() if dScroll.Visible then closeD() else openD() end end)
            for _,opt in ipairs(options) do
                local btn2=NEW("TextButton",{Size=UDim2.new(1,-6,0,24),BackgroundTransparency=1,ZIndex=201,Text="  "..opt,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},dScroll)
                btn2.MouseButton1Click:Connect(function() TogglesData[configKey].Value=opt; hBtn.Text=opt; hBtn.TextColor3=GREEN; closeD() end)
            end
        end

        local fruitCard=SC(spFruit,194,1); CardHeader(fruitCard,"fruit","FRUIT MANAGEMENT",GREEN)
        RowLabel(fruitCard,"Auto Store Fruit","Auto store fruit to inventory",34)
        CardToggle(fruitCard,44,"AutoStoreFruit",function(s) ZiliState.AutoStoreFruit=s end,GREEN)
        RowDivider(fruitCard,88)
        CreateDropdownFruit(fruitCard,"Fruit Rarity Filter",{"Common","Rare","Epic","Legendary","Mythic"},"Common",96,"Config_FruitRarity")
        NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,144),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=10,Text="Fruit Webhook"},fruitCard)
        local fruitWHFrame=NEW("Frame",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,142),BackgroundColor3=BG5,BorderSizePixel=0},fruitCard); CORNER(5,fruitWHFrame); STROKE(GOLD3,1,0.3,fruitWHFrame)
        local fruitWHBox=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Fruit webhook URL...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,ClearTextOnFocus=false},fruitWHFrame)
        TogglesData["Config_FruitWebhook"]={Value="",HeadBtn=fruitWHBox,Callback=function(val) getgenv().Config_DiscordWebhook=val; if fruitWHBox then fruitWHBox.Text=val or "" end end}
        fruitWHBox.FocusLost:Connect(function() getgenv().Config_DiscordWebhook=fruitWHBox.Text; TogglesData["Config_FruitWebhook"].Value=fruitWHBox.Text end)
        task.spawn(function() pcall(function() local FM=require("Farm/AutoFruitManager"); if FM and FM.Start then FM.Start() end end) end)
    end
    _buildFruitTab()

    SwitchSubTab(1)
end

_pageBuildFns["Auto Farm"] = function()
    if IS_LOBBY or not AutoFarmPage then return end
    BuildAutoFarmPage(AutoFarmPage)
end
-- Fishing + Merchant is now merged into Auto Farm sub-tabs
_pageBuildFns["Fishing + Merchant"] = nil

-- ── STATS ───────────────────────────────────────────────────────────────
_pageBuildFns["Stats"] = function()
    RegSearch("Auto Add Stats","Stats","Auto allocate stat points with cap","AutoStats")
    PageLayout(StatsPage,14,8)
    AutoStatsData={}
    local function CreateStatRow(statName,layoutOrder)
        local row=MakeCard(StatsPage,52,layoutOrder)
        NEW("TextLabel",{Text=statName,Size=UDim2.new(0.52,0,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left},row)
        local addBtn=NEW("TextButton",{Size=UDim2.new(0,100,0,26),Position=UDim2.new(1,-218,0.5,-13),BackgroundColor3=BG5,Text="Auto Add",TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=false},row); CORNER(6,addBtn); local btnStroke=STROKE(GOLD3,1,0,addBtn)
        local capBox=NEW("TextBox",{Size=UDim2.new(0,100,0,26),Position=UDim2.new(1,-108,0.5,-13),BackgroundColor3=BG5,Text="",PlaceholderText="Max Cap...",TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=12},row); CORNER(6,capBox); local boxStroke=STROKE(GOLD3,1,0,capBox)
        capBox.Focused:Connect(function() TWEEN(boxStroke,0.2,{Color=GOLD2}) end); capBox.FocusLost:Connect(function() TWEEN(boxStroke,0.2,{Color=GOLD3});local v=tonumber(capBox.Text);if v then AutoStatsData[statName].Cap=v else AutoStatsData[statName].Cap=0;capBox.Text="" end end)
        -- FIX: thêm Callback để ApplySettings (config load) kích hoạt đúng visual,
        -- giống hệt flow tự nhấn, tránh bug direct-set màu sai trong ApplyToggleVisual.
        local function StatVisualUpdate(active)
            TWEEN(addBtn,0.2,{BackgroundColor3=active and GOLDD or BG5})
            TWEEN(btnStroke,0.2,{Color=active and GOLD2 or GOLD3})
            addBtn.TextColor3=active and C(10,8,2) or GOLD2
            addBtn.Text=active and "● Adding..." or "Auto Add"
        end
        AutoStatsData[statName]={Active=false,Cap=0,Btn=addBtn,Strk=btnStroke,Box=capBox,Callback=StatVisualUpdate}
        addBtn.MouseButton1Click:Connect(function() local d=AutoStatsData[statName];d.Active=not d.Active;StatVisualUpdate(d.Active) end)
    end
    local StatList={"Strength","Stamina","Defense","Gun Mastery","Sword Mastery","Devil Fruit","Fighting Style Mastery"}
    for idx,sName in ipairs(StatList) do CreateStatRow(sName,idx) end
    -- FIX: đợi AutoStats module load xong (deferred require) rồi mới Start
    task.spawn(function()
        local waited = 0
        while not _requiresDone and waited < 15 do task.wait(0.1); waited += 0.1 end
        if AutoStats and AutoStats.Start then AutoStats.Start(AutoStatsData) end
    end)
end -- _pageBuildFns["Stats"]

end -- end if not IS_LOBBY

-- ══════════════════════════════════════════════════════════════════════
-- MISC PAGE BUILDER  (Character Style + Display Name + Player ESP)
-- ══════════════════════════════════════════════════════════════════════
local function BuildMiscPage(page)
    local ac = COL_MISC
    local CC   = require("Misc/CharacterChanger")
    local PESP = require("Misc/PlayerESP")

    -- Disable outer scroll: sub-tabs handle their own scrolling
    page.AutomaticCanvasSize = Enum.AutomaticSize.None
    page.CanvasSize          = UDim2.new(0,0,0,0)
    page.ScrollBarThickness  = 0

    -- Wrapper Frame: avoids ScrollingFrame canvas-scale issues
    -- Size=(1,0,1,0) is relative to page.AbsoluteSize — always correct.
    local WRAP = NEW("Frame",{
        Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundTransparency=1, ClipsDescendants=true, ZIndex=1,
    }, page)


    -- ═══════════════════════════════════════════════════════════════
    -- SUB-TAB BAR  (General | Combat | Visuals | Appearance | Language)
    -- ═══════════════════════════════════════════════════════════════
    local TAB_H = 40
    local subTabBar = NEW("Frame",{
        Size             = UDim2.new(1,0,0,TAB_H),
        Position         = UDim2.new(0,0,0,0),
        BackgroundColor3 = BG2,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, WRAP)
    NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C(30,28,55),BorderSizePixel=0}, subTabBar)
    NEW("UIListLayout",{
        FillDirection         = Enum.FillDirection.Horizontal,
        HorizontalAlignment   = Enum.HorizontalAlignment.Left,
        VerticalAlignment     = Enum.VerticalAlignment.Center,
        Padding               = UDim.new(0,3),
    }, subTabBar)
    NEW("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)}, subTabBar)

    local subPages   = {}
    local subTabData = {}
    local curSubIdx  = 0

    local SUB_DEFS = {
        { name="General",    col=COL_MISC  },
        { name="Combat",     col=COL_FARM  },
        { name="Visuals",    col=BLUE_A    },
        { name="Appearance", col=GOLD2     },
        { name="Language",   col=COL_TRAVEL},
    }

    local function SwitchSubTab(idx)
        if curSubIdx == idx then return end
        if curSubIdx > 0 then
            local old = subTabData[curSubIdx]
            TWEEN(old.btn, 0.15, {BackgroundTransparency=1})
            TWEEN(old.lbl, 0.15, {TextColor3=TEXT3})
            TWEEN(old.bar, 0.15, {Size=UDim2.new(0,0,0,2)})
            if subPages[curSubIdx] then subPages[curSubIdx].Visible=false end
        end
        curSubIdx = idx
        local cur = subTabData[idx]
        local cc  = cur.col
        TWEEN(cur.btn, 0.18, {
            BackgroundColor3    = C(math.min(255,math.floor(cc.R*255*0.14+5)),math.min(255,math.floor(cc.G*255*0.14+5)),math.min(255,math.floor(cc.B*255*0.14+5))),
            BackgroundTransparency = 0,
        })
        TWEEN(cur.lbl, 0.18, {TextColor3=cc})
        TWEEN(cur.bar, 0.18, {Size=UDim2.new(1,0,0,2)})
        if subPages[idx] then subPages[idx].Visible=true end
    end

    for i, def in ipairs(SUB_DEFS) do
        local btn = NEW("TextButton",{
            Size               = UDim2.new(0,90,0,30),
            BackgroundTransparency = 1,
            BackgroundColor3   = BG3,
            Text               = "",
            AutoButtonColor    = false,
            ZIndex             = 6,
        }, subTabBar)
        CORNER(8, btn)
        local lbl = NEW("TextLabel",{
            Text             = def.name,
            Size             = UDim2.new(1,0,1,-3),
            Position         = UDim2.new(0,0,0,0),
            BackgroundTransparency = 1,
            TextColor3       = TEXT3,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Center,
            ZIndex           = 7,
        }, btn)
        local bar = NEW("Frame",{
            Size             = UDim2.new(0,0,0,2),
            Position         = UDim2.new(0,0,1,-2),
            BackgroundColor3 = def.col,
            BorderSizePixel  = 0,
            ZIndex           = 7,
        }, btn)
        CORNER(1, bar)

        -- Sub-page ScrollingFrame
        local sp = NEW("ScrollingFrame",{
            Size                = UDim2.new(1,0,1,-TAB_H),
            Position            = UDim2.new(0,0,0,TAB_H),
            BackgroundTransparency = 1,
            BorderSizePixel     = 0,
            ScrollBarThickness  = 3,
            ScrollBarImageColor3 = def.col,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize          = UDim2.new(0,0,0,0),
            ClipsDescendants    = true,
            Visible             = false,
            ZIndex              = 3,
        }, WRAP)
        NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,10)}, sp)
        NEW("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,14)}, sp)

        subPages[i]   = sp
        subTabData[i] = {btn=btn,lbl=lbl,bar=bar,col=def.col}

        local ci = i
        btn.MouseButton1Click:Connect(function() SwitchSubTab(ci) end)
        btn.MouseEnter:Connect(function()
            if curSubIdx~=ci then TWEEN(btn,0.12,{BackgroundTransparency=0.6}); TWEEN(lbl,0.12,{TextColor3=TEXT1}) end
        end)
        btn.MouseLeave:Connect(function()
            if curSubIdx~=ci then TWEEN(btn,0.12,{BackgroundTransparency=1}); TWEEN(lbl,0.12,{TextColor3=TEXT3}) end
        end)
    end

    local spGeneral    = subPages[1]
    local spCombat     = subPages[2]
    local spVisuals    = subPages[3]
    local spAppearance = subPages[4]
    local spLanguage   = subPages[5]

    -- Helper: card on sub-page (mirrors MakeCard)
    local function SC(sp,h,lo)
        local f=NEW("Frame",{Size=UDim2.new(1,-24,0,h),BackgroundColor3=BG3,LayoutOrder=lo or 0,ClipsDescendants=true},sp)
        CORNER(10,f); STROKE(GOLD,1,0.78,f)
        NEW("Frame",{Size=UDim2.new(1,-2,0,1),Position=UDim2.new(0,1,0,0),BackgroundColor3=C(40,36,70),BorderSizePixel=0},f)
        return f
    end

    -- ═══════════════════════════════════════════════════════════════
    -- TAB 1 — GENERAL  (Character Style + Display Name)
    -- ═══════════════════════════════════════════════════════════════
    do
        local MODES       = CC.MODES
        local _charBtnRefs= {}
        local charCard    = SC(spGeneral,230,1)
        CardHeader(charCard,"wand","CHARACTER STYLE",ac)
        local activeDot=NEW("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,12,0,38),BackgroundColor3=C(55,55,65),BorderSizePixel=0},charCard); CORNER(4,activeDot)
        local activeLbl=NEW("TextLabel",{Text="none",Size=UDim2.new(0,160,0,12),Position=UDim2.new(0,26,0,35),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamMedium,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},charCard)
        local btnGrid=NEW("Frame",{Size=UDim2.new(1,-16,0,172),Position=UDim2.new(0,8,0,52),BackgroundTransparency=1},charCard)
        NEW("UIGridLayout",{CellSize=UDim2.new(0.2,-3,0,26),CellPadding=UDim2.new(0,3,0,3),HorizontalAlignment=Enum.HorizontalAlignment.Left,SortOrder=Enum.SortOrder.LayoutOrder},btnGrid)
        NEW("UIPadding",{PaddingLeft=UDim.new(0,2),PaddingTop=UDim.new(0,2)},btnGrid)
        local function setCharMode(id,m)
            CC.SetMode(id)
            for mid,b in pairs(_charBtnRefs) do
                local sel=(mid==id); TWEEN(b,0.15,{BackgroundTransparency=sel and 0 or 0.55})
                b.TextColor3=sel and Color3.new(1,1,1) or C(200,200,220)
            end
            local ltxt=id=="NONE" and "none" or id:lower()
            TWEEN(activeDot,0.2,{BackgroundColor3=m and m.col or C(55,55,65)})
            activeLbl.Text=ltxt; activeLbl.TextColor3=m and m.col or TEXT3
            Toast(id=="NONE" and "Style reset" or "Style: "..id,m and m.col or TEXT2,id=="NONE" and "-" or "+")
            if TogglesData["Misc_CharStyle"] then TogglesData["Misc_CharStyle"].Value=id end
        end
        for i,m in ipairs(MODES) do
            local btn=NEW("TextButton",{LayoutOrder=i,BackgroundColor3=m.col,BackgroundTransparency=0.55,BorderSizePixel=0,Text=m.label,TextColor3=C(200,200,220),TextSize=8,Font=Enum.Font.GothamBold,AutoButtonColor=false},btnGrid)
            CORNER(7,btn); STROKE(m.col,1.2,0.25,btn); _charBtnRefs[m.id]=btn
            local md=m
            btn.MouseButton1Click:Connect(function() setCharMode(md.id,md) end)
            btn.MouseEnter:Connect(function() if CC.GetMode()~=md.id then TWEEN(btn,0.1,{BackgroundTransparency=0.2}) end end)
            btn.MouseLeave:Connect(function() if CC.GetMode()~=md.id then TWEEN(btn,0.1,{BackgroundTransparency=0.55}) end end)
        end
        TogglesData["Misc_CharStyle"]={Value="NONE",Callback=function(val)
            local id=val or "NONE"; local found=nil
            for _,mm in ipairs(CC.MODES) do if mm.id==id then found=mm; break end end
            setCharMode(id,found)
        end}

        -- Display Name
        local DN_PRESETS={{name="Zili Supreme",col=C(120,80,255)},{name="ZiliHub Dev",col=C(45,225,218)},{name="Zili Phantom",col=C(200,50,255)},{name="ZiliGod",col=C(255,190,0)},{name="Zili.exe",col=C(240,75,190)}}
        local DN_COLORS={C(255,255,255),C(120,80,255),C(45,225,218),C(200,50,255),C(255,190,0),C(240,75,190),C(255,80,80),C(80,255,160)}
        local _dnColor=C(120,80,255); local _dnConn=nil; local _dnTimer=0
        local dnCard=SC(spGeneral,265,2); CardHeader(dnCard,"user","DISPLAY NAME",ac)
        NEW("TextLabel",{Text="Custom Name",Size=UDim2.new(0,100,0,12),Position=UDim2.new(0,12,0,36),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9},dnCard)
        local dnIBg=NEW("Frame",{Size=UDim2.new(1,-24,0,26),Position=UDim2.new(0,12,0,50),BackgroundColor3=BG5,BorderSizePixel=0},dnCard); CORNER(7,dnIBg)
        local dnStrk=STROKE(C(28,26,55),1,0.3,dnIBg)
        local dnBox=NEW("TextBox",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Enter display name...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=11,ClearTextOnFocus=false},dnIBg)
        dnBox.Focused:Connect(function() TWEEN(dnStrk,0.15,{Color=ac,Transparency=0}) end)
        dnBox.FocusLost:Connect(function() TWEEN(dnStrk,0.15,{Color=C(28,26,55),Transparency=0.3}) end)
        NEW("TextLabel",{Text="NAME COLOR",Size=UDim2.new(1,-24,0,11),Position=UDim2.new(0,12,0,84),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8},dnCard)
        local colRow=NEW("Frame",{Size=UDim2.new(1,-24,0,26),Position=UDim2.new(0,12,0,96),BackgroundTransparency=1},dnCard)
        for ci,col in ipairs(DN_COLORS) do
            local dot=NEW("TextButton",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,(ci-1)*28,0,2),BackgroundColor3=col,BorderSizePixel=0,Text="",AutoButtonColor=false},colRow); CORNER(11,dot)
            local ring=STROKE(C(255,255,255),2,ci==1 and 0.1 or 0.85,dot); local sc2=col; local sr=ring
            dot.MouseButton1Click:Connect(function()
                _dnColor=sc2; dnBox.TextColor3=sc2
                for _,ch in pairs(colRow:GetChildren()) do if ch:IsA("TextButton") then local r=ch:FindFirstChildOfClass("UIStroke"); if r then TWEEN(r,0.12,{Transparency=0.85}) end end end
                TWEEN(sr,0.12,{Transparency=0.1})
            end)
        end
        NEW("TextLabel",{Text="PRESETS",Size=UDim2.new(1,-24,0,11),Position=UDim2.new(0,12,0,130),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8},dnCard)
        local dnPF=NEW("Frame",{Size=UDim2.new(1,-24,0,54),Position=UDim2.new(0,12,0,142),BackgroundTransparency=1},dnCard)
        NEW("UIGridLayout",{CellSize=UDim2.new(0,97,0,22),CellPadding=UDim2.new(0,4,0,4),HorizontalAlignment=Enum.HorizontalAlignment.Left,SortOrder=Enum.SortOrder.LayoutOrder},dnPF)
        for i,pr in ipairs(DN_PRESETS) do
            local pb=NEW("TextButton",{LayoutOrder=i,BackgroundColor3=C(math.floor(pr.col.R*255*0.12),math.floor(pr.col.G*255*0.12),math.floor(pr.col.B*255*0.12)),BorderSizePixel=0,Text=pr.name,TextColor3=pr.col,TextSize=9,Font=Enum.Font.GothamBold,AutoButtonColor=false},dnPF)
            CORNER(6,pb); STROKE(pr.col,1,0.4,pb)
            pb.MouseButton1Click:Connect(function() dnBox.Text=pr.name;_dnColor=pr.col;dnBox.TextColor3=pr.col;Toast("Preset: "..pr.name,pr.col,"+") end)
        end
        NEW("TextLabel",{Text="Force Name Override",Size=UDim2.new(0.65,0,0,16),Position=UDim2.new(0,12,0,206),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=11},dnCard)
        CardToggle(dnCard,210,"Misc_DisplayName",function(on)
            if _dnConn then pcall(function() _dnConn:Disconnect() end); _dnConn=nil end
            if not on then return end
            local PL_L=game:GetService("Players"); local tName=dnBox.Text~="" and dnBox.Text or "Zili Supreme"; local tCol=_dnColor
            local pGui=PL_L.LocalPlayer:FindFirstChild("PlayerGui")
            _dnConn=game:GetService("RunService").Heartbeat:Connect(function(dt)
                _dnTimer=_dnTimer+dt; if _dnTimer<0.1 then return end; _dnTimer=0
                if not pGui then return end
                local hB=pGui:FindFirstChild("HealthBars")
                if hB then for _,bar in pairs(hB:GetChildren()) do for _,lb in pairs(bar:GetDescendants()) do if lb:IsA("TextLabel") and lb.Text~=tName then lb.Text=tName;lb.TextColor3=tCol end end end end
                pcall(function()
                    local mainFrame=PL_L.LocalPlayer.PlayerGui.Playerlist.Main
                    local scroll=mainFrame:FindFirstChild("ScrollingFrame")
                    if scroll then
                        for _,cont in pairs({scroll.Pirate and scroll.Pirate:FindFirstChild("Container"),scroll.Marine and scroll.Marine:FindFirstChild("Container")}) do
                            if cont then for _,fr in pairs(cont:GetChildren()) do for _,lb in pairs(fr:GetDescendants()) do if lb:IsA("TextLabel") and lb.Text~=tName then for _,p in pairs(PL_L:GetPlayers()) do if lb.Text:find(p.Name,1,true) or (p.DisplayName~="" and lb.Text:find(p.DisplayName,1,true)) then lb.Text=tName;lb.TextColor3=tCol;break end end end end end end
                        end
                    end
                end)
            end)
            Toast("Name override: "..tName,ac,"+")
        end,ac)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- TAB 2 — COMBAT
    -- ═══════════════════════════════════════════════════════════════
    do
        local ctCard=SC(spCombat,310,0); CardHeader(ctCard,"sword","COMBAT TOOLS",COL_MISC)

        RowLabel(ctCard,"Anti-Ragdoll","Block ragdoll & knockback",36)
        CardToggle(ctCard,36,"AntiRagdoll",function(on)
            _G.forceRagdoll=on and function(char)
                local hum=char and char:FindFirstChild("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.AutoRotate=true end
            end or nil
            if ZiliState._ragdollConn then ZiliState._ragdollConn:Disconnect(); ZiliState._ragdollConn=nil end
            if ZiliState._antiKBConn  then ZiliState._antiKBConn:Disconnect();  ZiliState._antiKBConn=nil  end
            if on then
                ZiliState._ragdollConn=game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Ragdoll").OnClientEvent:Connect(function(char)
                    if not char then return end
                    local hum=char:FindFirstChild("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.AutoRotate=true end
                    pcall(function() _G._antiRagdollFlag=true end)
                end)
                local lp=game:GetService("Players").LocalPlayer
                ZiliState._antiKBConn=game:GetService("RunService").Heartbeat:Connect(function()
                    local ch=lp.Character; local root=ch and ch:FindFirstChild("HumanoidRootPart"); local hum=ch and ch:FindFirstChild("Humanoid")
                    if not root or not hum then return end
                    if hum:GetState()==Enum.HumanoidStateType.Physics then
                        pcall(function() root.AssemblyLinearVelocity=Vector3.new(0,0,0) end)
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end)
            end
        end,COL_MISC)
        RowDivider(ctCard,68)

        RowLabel(ctCard,"Anti-Stun","Destroy stun objects + reset canuse",74)
        CardToggle(ctCard,74,"AntiStun",function(on)
            if ZiliState._antiStunConn then ZiliState._antiStunConn:Disconnect(); ZiliState._antiStunConn=nil end
            if on then
                local lp=game:GetService("Players").LocalPlayer
                ZiliState._antiStunConn=game:GetService("RunService").Heartbeat:Connect(function()
                    if _G.canuse==false then _G.canuse=true end
                    local stunFolder=lp:FindFirstChild("StunFolder")
                    if stunFolder then for _,s in ipairs(stunFolder:GetChildren()) do if s.Name=="Stun" then pcall(function() s:Destroy() end) end end end
                    local charInWs=game:GetService("Workspace"):FindFirstChild("PlayerCharacters")
                    charInWs=charInWs and charInWs:FindFirstChild(lp.Name)
                    if charInWs then for _,s in ipairs(charInWs:GetChildren()) do if s.Name=="Stun" then pcall(function() s:Destroy() end) end end end
                end)
            end
        end,COL_MISC)
        RowDivider(ctCard,106)

        RowLabel(ctCard,"Auto Buso","Press J when BusoBar < threshold",112)
        CardToggle(ctCard,112,"AutoBuso_Misc",function(on)
            ZiliState.AutoBuso_Misc=on
            if ZiliState._autoBusoConn then ZiliState._autoBusoConn:Disconnect(); ZiliState._autoBusoConn=nil end
            if on then
                local RS=game:GetService("ReplicatedStorage"); local lp=game:GetService("Players").LocalPlayer
                local VIM=Instance.new("VirtualInputManager"); local last=0
                ZiliState._autoBusoConn=game:GetService("RunService").Heartbeat:Connect(function()
                    if tick()-last<1.5 then return end
                    local ch=lp.Character; if not ch or not ch:FindFirstChildWhichIsA("Tool") then return end
                    local statsF=RS:FindFirstChild("Stats"..lp.Name); local bar=statsF and statsF:FindFirstChild("BusoBar")
                    if not bar then return end
                    local val=tonumber(bar.Value) or 100; local thr=math.clamp(tonumber(ZiliState.BusoThreshold) or 50,0,100)
                    if val<thr then
                        last=tick()
                        pcall(function()
                            VIM:SendKeyEvent(true,Enum.KeyCode.J,false,game.Players.LocalPlayer)
                            task.wait(0.05)
                            VIM:SendKeyEvent(false,Enum.KeyCode.J,false,game.Players.LocalPlayer)
                        end)
                    end
                end)
            end
        end,COL_MISC)
        ZiliState.BusoThreshold=ZiliState.BusoThreshold or "50"
        NEW("TextLabel",{Size=UDim2.new(0,32,0,12),Position=UDim2.new(1,-136,0,119),BackgroundTransparency=1,Text="Bar <",TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right},ctCard)
        local tBg=NEW("Frame",{Size=UDim2.new(0,52,0,22),Position=UDim2.new(1,-100,0,114),BackgroundColor3=C(12,12,26),BorderSizePixel=0},ctCard); CORNER(6,tBg); STROKE(COL_MISC,1,0.3,tBg)
        local tBox=NEW("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=ZiliState.BusoThreshold,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=11,PlaceholderText="0-100",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Center},tBg)
        tBox.FocusLost:Connect(function() local v=math.clamp(tonumber(tBox.Text) or 50,0,100); tBox.Text=tostring(v); ZiliState.BusoThreshold=tostring(v) end)
        RowDivider(ctCard,148)

        RowLabel(ctCard,"Hitbox Debug","Show hitbox visuals (red boxes)",154)
        CardToggle(ctCard,154,"HitboxDebug",function(on)
            pcall(function() game:GetService("Workspace"):SetAttribute("VisualHitboxDebug",on or nil) end)
        end,COL_MISC)
        RowDivider(ctCard,186)

        RowLabel(ctCard,"Optimize Map","Aggressive CPU/RAM optimization",192)
        CardToggle(ctCard,192,"OptimizeMap",function(on)
            task.spawn(function() pcall(function()
                local ws=game:GetService("Workspace"); local lt=game:GetService("Lighting")
                if on then
                    ZiliState._optBackup={}
                    for _,e in ipairs(lt:GetChildren()) do
                        table.insert(ZiliState._optBackup,{e,pcall(function() return e.Enabled end)}); pcall(function() e.Enabled=false end)
                    end
                    pcall(function() lt.GlobalShadows=false end)
                    for _,o in ipairs(ws:GetDescendants()) do
                        if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles") then pcall(function() o.Enabled=false end) end
                        if o:IsA("BasePart") then pcall(function() o.CastShadow=false end) end
                        if o:IsA("SpecialMesh") or o:IsA("UnionOperation") then pcall(function() o.RenderFidelity=Enum.RenderFidelity.Performance end) end
                        if (o:IsA("BillboardGui") or o:IsA("SurfaceGui")) and not o:IsDescendantOf(ws:FindFirstChild("PlayerCharacters") or ws) then pcall(function() o.Enabled=false end) end
                        if (o:IsA("Decal") or o:IsA("Texture")) and not o:IsDescendantOf(ws:FindFirstChild("PlayerCharacters") or ws) then pcall(function() o.Transparency=1 end) end
                    end
                    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
                else
                    if ZiliState._optBackup then
                        for _,d in ipairs(ZiliState._optBackup) do pcall(function() d[1].Enabled=d[2] end) end
                        ZiliState._optBackup=nil
                    end
                    pcall(function() lt.GlobalShadows=true end)
                    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic end)
                end
            end) end)
        end,COL_MISC)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- TAB 3 — VISUALS & ESP
    -- ═══════════════════════════════════════════════════════════════
    do
        local State         = PESP.GetState()
        local Palette       = PESP.GetPalette()
        local CurrentColors = PESP.GetCurrentColors()
        local PE_COL        = BLUE_A

        -- Island / Item ESP
        local vCard=SC(spVisuals,108,0); CardHeader(vCard,"eye","VISUALS & ESP",BLUE_A)
        RowLabel(vCard,"Island ESP",nil,36); CardToggle(vCard,36,"ESP_Island",function(s) if Esp and IslandData then Esp.Toggle(s,IslandData) end end,BLUE_A)
        RowDivider(vCard,68); RowLabel(vCard,"Item ESP",nil,74); CardToggle(vCard,74,"ESP_Item",function() end,BLUE_A)

        -- Player ESP
        local CARD_H=408
        local espCard=SC(spVisuals,CARD_H,1); CardHeader(espCard,"user","PLAYER ESP",PE_COL)
        CardToggle(espCard,36,"ESP_Player",function(on) State.Master=on; if on then PESP.Start() else State.Master=false end end,PE_COL)
        RowLabel(espCard,"Player ESP","Corner box · name · HP · tracer · off-screen arrow",36)
        RowDivider(espCard,68)

        local function SubToggle2(label,py,isRight,initV,stateKey)
            local pillX=isRight and UDim2.new(1,-50,0,py) or UDim2.new(0.5,-44,0,py)
            local lblX =isRight and UDim2.new(0.5,4,0,py+2) or UDim2.new(0,12,0,py+2)
            local lblW =isRight and UDim2.new(0.5,-58,0,14) or UDim2.new(0.5,-56,0,14)
            local pill=NEW("TextButton",{Size=UDim2.new(0,38,0,20),Position=pillX,BackgroundColor3=initV and C(8,28,72) or BG5,Text="",AutoButtonColor=false},espCard); CORNER(10,pill)
            local pSt=STROKE(initV and PE_COL or C(44,44,66),1,initV and 0 or 0.45,pill)
            local pTh=NEW("Frame",{Size=UDim2.new(0,14,0,14),Position=initV and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=initV and PE_COL or C(70,70,100),BorderSizePixel=0},pill); CORNER(7,pTh)
            NEW("TextLabel",{Text=label,Size=lblW,Position=lblX,BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=10},espCard)
            local st={v=initV}
            pill.MouseButton1Click:Connect(function()
                st.v=not st.v; local on=st.v
                TWEEN(pill,0.18,{BackgroundColor3=on and C(8,28,72) or BG5})
                TWEEN(pSt,0.18,{Color=on and PE_COL or C(44,44,66),Transparency=on and 0 or 0.45})
                TWEEN(pTh,0.18,{BackgroundColor3=on and PE_COL or C(70,70,100),Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
                State[stateKey]=on
            end)
        end
        SubToggle2("Show Health",  76, false,State.Health,    "Health")
        SubToggle2("Show Chams",   76, true, State.Chams,     "Chams")
        SubToggle2("Show Name",   106, false,State.Text,      "Text")
        SubToggle2("Show Tracer", 106, true, State.Tracer,    "Tracer")
        SubToggle2("Show Distance",136,false,State.Health,    "Health")
        SubToggle2("Player List", 136,true, State.PlayerList, "PlayerList")
        SubToggle2("Off-Screen ↗",166,false,State.OffScreen,  "OffScreen")
        RowDivider(espCard,196)

        local UIS_L=game:GetService("UserInputService")
        local function MakeSlider(label,py,minV,maxV,initV,fmt,onChange)
            NEW("TextLabel",{Text=label,Size=UDim2.new(0.62,0,0,14),Position=UDim2.new(0,12,0,py),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9},espCard)
            local numBg=NEW("Frame",{Size=UDim2.new(0,50,0,17),Position=UDim2.new(1,-62,0,py-2),BackgroundColor3=BG5,BorderSizePixel=0},espCard); CORNER(4,numBg)
            local numSt=STROKE(C(28,26,55),1,0.3,numBg)
            local numBox=NEW("TextBox",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,Text=string.format(fmt,initV),TextColor3=PE_COL,Font=Enum.Font.GothamBold,TextSize=9,ClearTextOnFocus=true},numBg)
            numBox.Focused:Connect(function() TWEEN(numSt,0.12,{Color=PE_COL,Transparency=0}) end)
            numBox.FocusLost:Connect(function() TWEEN(numSt,0.12,{Color=C(28,26,55),Transparency=0.3}) end)
            local track=NEW("Frame",{Size=UDim2.new(1,-24,0,4),Position=UDim2.new(0,12,0,py+18),BackgroundColor3=C(20,20,40),BorderSizePixel=0},espCard); CORNER(2,track)
            local fill=NEW("Frame",{Size=UDim2.new((initV-minV)/(maxV-minV),0,1,0),BackgroundColor3=PE_COL,BorderSizePixel=0},track); CORNER(2,fill)
            local knob=NEW("TextButton",{Size=UDim2.new(0,14,0,14),Position=UDim2.new((initV-minV)/(maxV-minV),-7,0.5,-7),BackgroundColor3=PE_COL,Text="",AutoButtonColor=false,BorderSizePixel=0},track); CORNER(7,knob)
            local dragging=false
            local function setVal(v)
                v=math.clamp(v,minV,maxV); local pct=(v-minV)/(maxV-minV)
                fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,-7,0.5,-7); numBox.Text=string.format(fmt,v); onChange(v)
            end
            knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
            UIS_L.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            UIS_L.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType==Enum.UserInputType.MouseMovement then
                    local tA=track.AbsolutePosition; local tS=track.AbsoluteSize
                    setVal(minV+math.clamp((inp.Position.X-tA.X)/tS.X,0,1)*(maxV-minV))
                end
            end)
            numBox.FocusLost:Connect(function() local v=tonumber(numBox.Text); if v then setVal(v) end end)
        end
        MakeSlider("Max Distance (x1000 studs)",204,0.1,10,(State.MaxDist or 5000)/1000,"%.1f",function(v) State.MaxDist=math.floor(v*1000) end)
        MakeSlider("Label Size (px)",           242,  8, 32, 13,                        "%.0f",function(v) State._labelSize=math.floor(v) end)
        RowDivider(espCard,276)

        NEW("TextLabel",{Text="COLOR PICKERS",Size=UDim2.new(1,-24,0,11),Position=UDim2.new(0,12,0,283),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8},espCard)
        local COL_DEFS={{lbl="Box",key="Box"},{lbl="Name",key="Name"},{lbl="HP",key="HealthHigh"},{lbl="Chams",key="Chams"},{lbl="Tracer",key="Tracer"},{lbl="Arrow",key="Arrow"}}
        local SW_ROW1_Y=296; local SW_ROW2_Y=354
        local SW_XS={12,100,188,12,100,188}; local SW_YS={SW_ROW1_Y,SW_ROW1_Y,SW_ROW1_Y,SW_ROW2_Y,SW_ROW2_Y,SW_ROW2_Y}
        local EXP_YS={SW_ROW1_Y+46,SW_ROW1_Y+46,SW_ROW1_Y+46,SW_ROW2_Y+46,SW_ROW2_Y+46,SW_ROW2_Y+46}
        local CARD_BASE=SW_ROW2_Y+44+10; CARD_H=CARD_BASE
        espCard.Size=UDim2.new(1,-24,0,CARD_H)
        local _openPick=nil; local _openPickBtn=nil; local swDots={}
        local function closePick()
            if _openPick and _openPick.Parent then _openPick:Destroy() end
            _openPick=nil; _openPickBtn=nil; TWEEN(espCard,0.15,{Size=UDim2.new(1,-24,0,CARD_H)})
        end
        for i,cd in ipairs(COL_DEFS) do
            local sx=SW_XS[i]; local sy=SW_YS[i]
            local swBg=NEW("Frame",{Size=UDim2.new(0,78,0,44),Position=UDim2.new(0,sx,0,sy),BackgroundColor3=C(10,10,24),BorderSizePixel=0},espCard); CORNER(8,swBg)
            local swSt=STROKE(C(30,28,55),1,0.35,swBg)
            local dot=NEW("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0.5,-11,0,4),BackgroundColor3=Palette[CurrentColors[cd.key] or 1],BorderSizePixel=0},swBg); CORNER(11,dot)
            NEW("TextLabel",{Text=cd.lbl,Size=UDim2.new(1,0,0,11),Position=UDim2.new(0,0,1,-11),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center},swBg)
            swDots[i]=dot
            local swBtn=NEW("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false},swBg)
            local myI=i; local myCD=cd; local mySS=swSt; local expandY=EXP_YS[i]
            swBtn.MouseButton1Click:Connect(function()
                if _openPickBtn==swBtn then closePick(); TWEEN(mySS,0.15,{Color=C(30,28,55),Transparency=0.35}); return end
                closePick(); _openPickBtn=swBtn
                TWEEN(espCard,0.15,{Size=UDim2.new(1,-24,0,CARD_H+40)})
                local pf=NEW("Frame",{Size=UDim2.new(1,-16,0,34),Position=UDim2.new(0,8,0,expandY),BackgroundColor3=C(9,9,24),BorderSizePixel=0,ZIndex=60},espCard)
                CORNER(7,pf); STROKE(PE_COL,1,0.2,pf); _openPick=pf
                NEW("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,5)},pf)
                NEW("UIPadding",{PaddingTop=UDim.new(0,7),PaddingLeft=UDim.new(0,6)},pf)
                for _,pc in ipairs(Palette) do
                    local pb=NEW("TextButton",{Size=UDim2.new(0,20,0,20),BackgroundColor3=pc,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=61},pf); CORNER(10,pb); STROKE(Color3.new(1,1,1),1,0.65,pb)
                    pb.MouseButton1Click:Connect(function()
                        for idx,palCol in ipairs(Palette) do if palCol==pc then CurrentColors[myCD.key]=idx; PESP.SetColor(myCD.key,idx); break end end
                        swDots[myI].BackgroundColor3=pc; closePick(); Toast(myCD.lbl.." color",pc,"+")
                    end)
                end
                TWEEN(mySS,0.15,{Color=PE_COL,Transparency=0})
            end)
            swBtn.MouseLeave:Connect(function() if _openPickBtn~=swBtn then TWEEN(mySS,0.15,{Color=C(30,28,55),Transparency=0.35}) end end)
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- TAB 4 — APPEARANCE  (Color Theme)
    -- ═══════════════════════════════════════════════════════════════
    do
        local thCard=SC(spAppearance,168,0); CardHeader(thCard,"fruit","COLOR THEME",GOLD2)
        NEW("TextLabel",{Text="Accent color applied across the entire hub",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,14,0,34),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},thCard)
        local _miscThemeBtns={}
        for i,th in ipairs(THEMES) do
            local col=(i-1)%4; local row=math.floor((i-1)/4)
            local bx=NEW("TextButton",{
                Size=UDim2.new(0.25,-8,0,42),
                Position=UDim2.new(col*0.25,col==0 and 6 or 4,0,52+row*50),
                BackgroundColor3=C(math.max(0,math.floor(th.main.R*255*0.10)),math.max(0,math.floor(th.main.G*255*0.10)),math.max(0,math.floor(th.main.B*255*0.10))),
                Text="",AutoButtonColor=false
            },thCard)
            CORNER(8,bx); local bxS=STROKE(th.c2,1.5,i==_curTheme and 0 or 0.55,bx)
            local dot=NEW("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0.5,-11,0,5),BackgroundColor3=th.main,BorderSizePixel=0},bx); CORNER(11,dot); STROKE(th.c2,1.5,0.1,dot)
            NEW("TextLabel",{Text=th.name,Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-16),BackgroundTransparency=1,TextColor3=th.main,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},bx)
            local activeBar=NEW("Frame",{Size=UDim2.new(i==_curTheme and 1 or 0,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=th.main,BorderSizePixel=0},bx); CORNER(1,activeBar)
            _miscThemeBtns[i]={btn=bx,strk=bxS,dot=dot,bar=activeBar}
            bx.MouseEnter:Connect(function() if _curTheme~=i then TWEEN(bx,0.12,{BackgroundColor3=C(math.max(0,math.floor(th.main.R*255*0.18)),math.max(0,math.floor(th.main.G*255*0.18)),math.max(0,math.floor(th.main.B*255*0.18)))}) end end)
            bx.MouseLeave:Connect(function() if _curTheme~=i then TWEEN(bx,0.12,{BackgroundColor3=C(math.max(0,math.floor(th.main.R*255*0.10)),math.max(0,math.floor(th.main.G*255*0.10)),math.max(0,math.floor(th.main.B*255*0.10)))}) end end)
            local thi=i; local thth=th
            bx.MouseButton1Click:Connect(function()
                ApplyTheme(thi)
                if TogglesData["Config_ColorTheme"] then TogglesData["Config_ColorTheme"].Value=thi end
                for j,td in ipairs(_miscThemeBtns) do
                    TWEEN(td.strk,0.2,{Transparency=j==thi and 0 or 0.55})
                    TWEEN(td.bar,0.2,{Size=UDim2.new(j==thi and 1 or 0,0,0,2)})
                end
                Toast("Theme: "..thth.name,thth.main,"+")
            end)
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- TAB 5 — LANGUAGE  (English / Tieng Viet)
    -- ═══════════════════════════════════════════════════════════════
    do
        local COL_LANG=COL_TRAVEL
        local langCard=SC(spLanguage,340,0); CardHeader(langCard,"globe","LANGUAGE / NGON NGU",COL_LANG)
        NEW("TextLabel",{Text="Select interface language / Chon ngon ngu giao dien",Size=UDim2.new(1,-24,0,24),Position=UDim2.new(0,12,0,36),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=9,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},langCard)

        local LANGS={
            {code="EN",name="English",      col=C(65,165,255)},
            {code="VI",name="Tieng Viet",   col=C(220,60,60) },
            {code="TH",name="Thai",          col=C(255,200,30) },
            {code="RU",name="Русский",       col=C(80,200,120) },
            {code="BR",name="Portugues BR",  col=C(0,168,89)  },
        }
        ZiliState.Language=ZiliState.Language or "EN"
        local langBtns={}

        local function applyLang(code)
            ZiliState.Language=code
            for _,ld in ipairs(langBtns) do
                local sel=(ld.code==code)
                TWEEN(ld.btn,0.18,{
                    BackgroundColor3=sel and C(math.floor(ld.col.R*255*0.14),math.floor(ld.col.G*255*0.14),math.floor(ld.col.B*255*0.14)) or C(8,9,22),
                    BackgroundTransparency=sel and 0 or 0.35,
                })
                ld.btn.TextColor3=sel and ld.col or TEXT3
                ld.btn.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
                if ld.strk then TWEEN(ld.strk,0.18,{Color=sel and ld.col or C(35,35,55),Transparency=sel and 0.05 or 0.55}) end
            end
            local _langNames={EN="Language: English",VI="Ngon ngu: Tieng Viet",TH="Language: Thai",RU="Yazyk: Russkiy",BR="Idioma: Portugues BR"}
            local _langCols={EN=C(65,165,255),VI=C(220,60,60),TH=C(255,200,30),RU=C(80,200,120),BR=C(0,168,89)}
            Toast(_langNames[code] or "Language changed",_langCols[code] or TEXT2,"+")
            if TogglesData["Misc_Language"] then TogglesData["Misc_Language"].Value=code end
        end

        for i,lg in ipairs(LANGS) do
            local col2=(i-1)%2; local row2=math.floor((i-1)/2)
            local xPos=col2==0 and UDim2.new(0,12,0,68+row2*54) or UDim2.new(0.5,4,0,68+row2*54)
            local bx=NEW("TextButton",{
                Size=UDim2.new(0.5,-16,0,44),Position=xPos,
                BackgroundColor3=C(8,9,22),BackgroundTransparency=0.35,
                Text=lg.name,TextColor3=TEXT3,Font=Enum.Font.GothamMedium,TextSize=13,
                AutoButtonColor=false,
            },langCard)
            CORNER(10,bx)
            local bxS=STROKE(C(35,35,55),1,0.55,bx)
            local ci_code=lg.code; local ci_col=lg.col
            table.insert(langBtns,{btn=bx,strk=bxS,code=ci_code,col=ci_col})
            bx.MouseButton1Click:Connect(function() applyLang(ci_code) end)
            bx.MouseEnter:Connect(function()
                if ZiliState.Language~=ci_code then TWEEN(bx,0.12,{BackgroundColor3=C(math.floor(ci_col.R*255*0.10),math.floor(ci_col.G*255*0.10),math.floor(ci_col.B*255*0.10)),BackgroundTransparency=0}) end
            end)
            bx.MouseLeave:Connect(function()
                if ZiliState.Language~=ci_code then TWEEN(bx,0.12,{BackgroundColor3=C(8,9,22),BackgroundTransparency=0.35}) end
            end)
        end
        applyLang(ZiliState.Language)

        RowDivider(langCard,244)
        NEW("TextLabel",{Text="TRANSLATION STATUS",Size=UDim2.new(1,-24,0,11),Position=UDim2.new(0,12,0,252),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=8},langCard)
        local TRANS_INFO={
            {lang="English",     pct="100%",col=C(55,220,130)},
            {lang="Tieng Viet",  pct="85%", col=C(255,190,50)},
            {lang="Thai",        pct="70%", col=C(255,200,30)},
            {lang="Русский",     pct="70%", col=C(80,200,120)},
            {lang="Portugues BR",pct="65%", col=C(0,168,89)},
        }
        for i,ti in ipairs(TRANS_INFO) do
            local ty=268+(i-1)*22
            NEW("TextLabel",{Text=ti.lang,Size=UDim2.new(0.6,0,0,16),Position=UDim2.new(0,12,0,ty),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},langCard)
            local pctBg=NEW("Frame",{Size=UDim2.new(0,0,0,17),Position=UDim2.new(1,-80,0,ty),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=C(math.floor(ti.col.R*255*0.10),math.floor(ti.col.G*255*0.10),math.floor(ti.col.B*255*0.10)),BorderSizePixel=0},langCard); CORNER(9,pctBg); STROKE(ti.col,1,0.35,pctBg)
            NEW("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},pctBg)
            NEW("TextLabel",{Text=ti.pct,Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,TextColor3=ti.col,Font=Enum.Font.GothamBold,TextSize=9},pctBg)
        end
    end

    -- Search registry
    RegSearch("Character Style","Misc","Visual effects on your character","")
    RegSearch("Display Name","Misc","Override display name in-game","Misc_DisplayName")
    RegSearch("Player ESP","Misc","Full player ESP with health/distance","ESP_Player")
    RegSearch("Anti-Ragdoll","Misc","Prevent ragdoll when hit","AntiRagdoll")
    RegSearch("Auto Buso","Misc","Auto press J when Buso bar below threshold","AutoBuso_Misc")
    RegSearch("Hitbox Debug","Misc","Visualize hitboxes in-game","HitboxDebug")
    RegSearch("Color Theme","Misc","Switch accent color preset","")
    RegSearch("Language","Misc","Switch interface language / Ngon ngu","")

    -- Activate first sub-tab
    SwitchSubTab(1)
end

-- Misc page lazy build
_pageBuildFns["Misc"] = function()
    if IS_LOBBY or not MiscPage then return end
    BuildMiscPage(MiscPage)
end

-- =====================================================================
-- FIX #1: Remove lazy-build — force-execute every pending page builder
-- NOW so that TogglesData / AutoStatsData are fully populated BEFORE
-- ConfigManager.Init + auto-load runs below.  Tab clicks still work
-- fine; the check `if _pageBuildFns[name]` will simply be nil.
-- =====================================================================
-- FIX: dùng thứ tự cố định thay vì pairs() để đảm bảo Auto Farm và Fishing
-- được build trước Stats (Stats cần TogglesData đã có AutoFishMerchant, AutoFarmLevel)
do
    local _buildOrder = {"Auto Watch Ads","Auto Farm","Travel","Stats","Misc"}
    for _, _lbName in ipairs(_buildOrder) do
        local _lbFn = _pageBuildFns[_lbName]
        if _lbFn then
            pcall(_lbFn)
            _pageBuildFns[_lbName] = nil
        end
    end
    -- Bất kỳ trang nào còn sót lại chưa trong danh sách
    for _lbName, _lbFn in pairs(_pageBuildFns) do
        pcall(_lbFn)
        _pageBuildFns[_lbName] = nil
    end
end

-- AutoStatsData accessible from Config (now populated by force-build above)
AutoStatsData = AutoStatsData or {}

-- =====================================================================
-- CONFIG PAGE  (both lobby and game world)
-- =====================================================================
PageLayout(ConfigPage,14,10)

-- [FIX] Wrapped into local function to reset Lua's 200-local register limit
local function _buildConfigPageCards()
-- Auto-hide card (at top of Config page)
local cfgAutoHideCard=MakeCard(ConfigPage,162,0); CardHeader(cfgAutoHideCard,"eye","AUTO HIDE UI",COL_CFG)

-- Row 1: Auto Hide toggle
NEW("TextLabel",{Text="Auto Hide",Size=UDim2.new(0.62,0,0,22),Position=UDim2.new(0,14,0,32),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},cfgAutoHideCard)
local _ahDelayLbl=NEW("TextLabel",{Text=string.format("Hides after %ds of inactivity (10–60s)",AUTO_HIDE_DELAY),Size=UDim2.new(1,-80,0,13),Position=UDim2.new(0,14,0,52),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},cfgAutoHideCard)
CardToggle(cfgAutoHideCard,36,"AutoHide",function(state) _autoHideEnabled=state;_autoHideTimer=0 end,COL_CFG)

RowDivider(cfgAutoHideCard,70)

-- Row 2: Custom delay input 10-60s
NEW("TextLabel",{Text="Hide Delay (10–60s)",Size=UDim2.new(0.62,0,0,20),Position=UDim2.new(0,14,0,78),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},cfgAutoHideCard)
local _ahBoxFrame=NEW("Frame",{Size=UDim2.new(0,72,0,26),Position=UDim2.new(1,-82,0,76),BackgroundColor3=BG5},cfgAutoHideCard); CORNER(6,_ahBoxFrame); local _ahBoxStroke=STROKE(GOLD3,1,0,_ahBoxFrame)
local _ahBox=NEW("TextBox",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,5,0,0),BackgroundTransparency=1,Text=tostring(AUTO_HIDE_DELAY),PlaceholderText="30",TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=12,ClearTextOnFocus=false},_ahBoxFrame)
_ahBox.Focused:Connect(function() TWEEN(_ahBoxStroke,0.15,{Color=COL_CFG}) end)
_ahBox.FocusLost:Connect(function()
    TWEEN(_ahBoxStroke,0.15,{Color=GOLD3})
    local v=tonumber(_ahBox.Text)
    if v then
        AUTO_HIDE_DELAY=math.clamp(math.floor(v),AUTO_HIDE_MIN,AUTO_HIDE_MAX)
    end
    -- always snap display to valid range regardless of what was typed
    _ahBox.Text=tostring(AUTO_HIDE_DELAY)
    _ahDelayLbl.Text=string.format("Hides after %ds of inactivity (10–60s)",AUTO_HIDE_DELAY)
    _autoHideTimer=0
end)

RowDivider(cfgAutoHideCard,112)

-- Row 3: Hide on Loading toggle
NEW("TextLabel",{Text="Auto Hide on Loading",Size=UDim2.new(0.62,0,0,22),Position=UDim2.new(0,14,0,120),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},cfgAutoHideCard)
NEW("TextLabel",{Text="Hides hub while loading screen is active",Size=UDim2.new(1,-80,0,13),Position=UDim2.new(0,14,0,142),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},cfgAutoHideCard)
CardToggle(cfgAutoHideCard,124,"AutoHideOnLoad",function(state)
    _autoHideOnLoad=state
    -- if loading screen is still up (ZiliShowMain not set yet), hide/show hub now
    if state and not getgenv()._ZiliShowMain then
        if MainFrame then MainFrame.Visible=false end
    elseif not state and not getgenv()._ZiliShowMain then
        if MainFrame then MainFrame.Visible=true end
    end
end,C(45,225,218))

-- ── THEME PICKER CARD ────────────────────────────────────────────────
local themeCard=MakeCard(ConfigPage,162,1); CardHeader(themeCard,"fruit","COLOR THEME",GOLD2)
NEW("TextLabel",{Text="Accent color applied across the entire hub",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,14,0,34),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},themeCard)
local _themeBtns={}
-- 2 rows × 4 cols
for i,th in ipairs(THEMES) do
    local col=(i-1)%4; local row=math.floor((i-1)/4)
    local bx=NEW("TextButton",{
        Size=UDim2.new(0.25,-8,0,42),
        Position=UDim2.new(col*0.25,col==0 and 6 or 4,0,52+row*50),
        BackgroundColor3=C(math.max(0,math.floor(th.main.R*255*0.10)),math.max(0,math.floor(th.main.G*255*0.10)),math.max(0,math.floor(th.main.B*255*0.10))),
        Text="",AutoButtonColor=false
    },themeCard)
    CORNER(8,bx); local bxS=STROKE(th.c2,1.5,i==1 and 0 or 0.55,bx)
    -- Color dot
    local dot=NEW("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0.5,-11,0,5),BackgroundColor3=th.main,BorderSizePixel=0},bx); CORNER(11,dot); STROKE(th.c2,1.5,0.1,dot)
    -- Theme name (stored so we can wire click on label too)
    local thmLbl=NEW("TextLabel",{Text=th.name,Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-16),BackgroundTransparency=1,TextColor3=th.main,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},bx)
    -- Active indicator bar
    local activeBar=NEW("Frame",{Size=UDim2.new(i==1 and 1 or 0,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=th.main,BorderSizePixel=0},bx); CORNER(1,activeBar)
    _themeBtns[i]={btn=bx,strk=bxS,dot=dot,bar=activeBar}
    bx.MouseEnter:Connect(function() if _curTheme~=i then TWEEN(bx,0.12,{BackgroundColor3=C(math.max(0,math.floor(th.main.R*255*0.18)),math.max(0,math.floor(th.main.G*255*0.18)),math.max(0,math.floor(th.main.B*255*0.18)))}) end end)
    bx.MouseLeave:Connect(function() if _curTheme~=i then TWEEN(bx,0.12,{BackgroundColor3=C(math.max(0,math.floor(th.main.R*255*0.10)),math.max(0,math.floor(th.main.G*255*0.10)),math.max(0,math.floor(th.main.B*255*0.10)))}) end end)
    local function _applyAndSaveTheme(idx)
        ApplyTheme(idx)
        for j,td in ipairs(_themeBtns) do
            TWEEN(td.strk,0.2,{Transparency=j==idx and 0 or 0.55})
            TWEEN(td.bar,0.2,{Size=UDim2.new(j==idx and 1 or 0,0,0,2)})
        end
        -- FIX #2: persist theme index so ConfigManager can save/load it
        if TogglesData["Config_ColorTheme"] then TogglesData["Config_ColorTheme"].Value=idx end
    end
    bx.MouseButton1Click:Connect(function() _applyAndSaveTheme(i); Toast("Theme: "..th.name,th.main,"+") end)
    -- Also fire theme on label click (user requested)
    thmLbl.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then _applyAndSaveTheme(i); Toast("Theme: "..th.name,th.main,"+") end
    end)
    -- Also fire on dot click
    dot.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then _applyAndSaveTheme(i); Toast("Theme: "..th.name,th.main,"+") end
    end)
end

-- FIX #2: Register Color Theme in TogglesData so ConfigManager saves/loads it
TogglesData["Config_ColorTheme"]={Value=_curTheme,Callback=function(idx)
    local n=tonumber(idx); if not (n and THEMES[n]) then return end
    ApplyTheme(n)
    for j,td in ipairs(_themeBtns) do
        TWEEN(td.strk,0.2,{Transparency=j==n and 0 or 0.55})
        TWEEN(td.bar,0.2,{Size=UDim2.new(j==n and 1 or 0,0,0,2)})
    end
end}

-- Register Language in TogglesData so ConfigManager auto-saves/loads it
TogglesData["Misc_Language"]={Value=ZiliState.Language or "EN",Callback=function(val)
    ZiliState.Language = (val=="VI") and "VI" or "EN"
end}


-- ── KEYBIND CONFIG CARD ───────────────────────────────────────────────
local kbCard=MakeCard(ConfigPage,110,2); CardHeader(kbCard,"lightning","KEYBIND",AMBER)
NEW("TextLabel",{Text="Toggle Hub Visibility",Size=UDim2.new(0.6,0,0,16),Position=UDim2.new(0,14,0,36),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},kbCard)
NEW("TextLabel",{Text="Press to show / hide the hub",Size=UDim2.new(0.7,0,0,13),Position=UDim2.new(0,14,0,54),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},kbCard)
-- Current key display badge
local _kbKeyBadge=NEW("Frame",{Size=UDim2.new(0,110,0,34),Position=UDim2.new(0,14,0,70),BackgroundColor3=C(22,18,6),BorderSizePixel=0},kbCard); CORNER(8,_kbKeyBadge)
local _kbKeyStroke=STROKE(AMBER,1.5,0.2,_kbKeyBadge)
-- Keyboard icon in badge
do local kico=NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,8,0.5,-8),BackgroundTransparency=1,BorderSizePixel=0},_kbKeyBadge)
    NEW("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0},kico); CORNER(3,kico); STROKE(AMBER,1.2,0,kico)
    for r=0,1 do for c=0,2 do NEW("Frame",{Size=UDim2.new(0,3,0,3),Position=UDim2.new(0,2+c*5,0,2+r*5),BackgroundColor3=AMBER,BackgroundTransparency=0.4,BorderSizePixel=0},kico) end end
end
local _kbLbl=NEW("TextLabel",{Text="RightShift",Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,28,0,0),BackgroundTransparency=1,TextColor3=AMBER,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},_kbKeyBadge)
-- Rebind button
local _kbBtn=NEW("TextButton",{Text="REBIND",Size=UDim2.new(0,80,0,34),Position=UDim2.new(1,-92,0,70),BackgroundColor3=C(30,20,4),TextColor3=AMBER,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false},kbCard)
CORNER(8,_kbBtn); local _kbS=STROKE(AMBER,1.2,0.3,_kbBtn)
_kbBtn.MouseEnter:Connect(function() TWEEN(_kbBtn,0.15,{BackgroundColor3=C(50,36,6),TextColor3=C(255,235,100)}) end)
_kbBtn.MouseLeave:Connect(function() TWEEN(_kbBtn,0.15,{BackgroundColor3=C(30,20,4),TextColor3=AMBER}) end)
local _listening=false
_kbBtn.MouseButton1Click:Connect(function()
    if _listening then return end
    _listening=true
    _kbBtn.Text="Listening..."
    TWEEN(_kbBtn,0.15,{BackgroundColor3=C(45,30,4)})
    TWEEN(_kbKeyStroke,0.15,{Transparency=0,Color=C(255,235,100)})
    local conn; conn=UIS.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            _keybindKey=inp.KeyCode
            local keyName=tostring(inp.KeyCode):gsub("Enum.KeyCode.","")
            _kbLbl.Text=keyName
            _kbBtn.Text="REBIND"
            TWEEN(_kbBtn,0.15,{BackgroundColor3=C(30,20,4),TextColor3=AMBER})
            TWEEN(_kbKeyStroke,0.15,{Transparency=0.2,Color=AMBER})
            Toast("Keybind: "..keyName,AMBER,"⚡")
            _listening=false; conn:Disconnect()
        end
    end)
end)
end -- _buildConfigPageCards
_buildConfigPageCards()

-- [FIX] Wrapped into local function to reset Lua's 200-local register limit
local function _buildConfigManagerCards()
-- Header card
local cfgHeaderCard=MakeCard(ConfigPage,38,3); cfgHeaderCard.BackgroundColor3=C(9,10,22)
NEW("Frame",{Size=UDim2.new(0,2,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=GOLD,BorderSizePixel=0},cfgHeaderCard)
NEW("TextLabel",{Text="CONFIG MANAGER  ·  SAVE  ·  LOAD  ·  AUTO",Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},cfgHeaderCard)

-- Two-panel container
local cfgContainer=NEW("Frame",{Size=UDim2.new(1,-24,0,390),BackgroundTransparency=1,LayoutOrder=4},ConfigPage)
NEW("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Top,Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},cfgContainer)

local LeftPanel=NEW("Frame",{Size=UDim2.new(0,238,1,0),BackgroundColor3=BG3,LayoutOrder=0},cfgContainer); CORNER(9,LeftPanel); STROKE(GOLD,1,0.65,LeftPanel)
local lpHead=NEW("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=BG_HDR},LeftPanel); CORNER(9,lpHead)
NEW("Frame",{Size=UDim2.new(1,0,0,15),Position=UDim2.new(0,0,1,-15),BackgroundColor3=BG_HDR,BorderSizePixel=0},lpHead)
NEW("TextLabel",{Text="+ SAVED CONFIGS",Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},lpHead)
local SearchBoxConfig=NEW("TextBox",{Size=UDim2.new(1,-16,0,28),Position=UDim2.new(0,8,0,40),BackgroundColor3=BG5,PlaceholderText="  Search configs...",Text="",TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=11},LeftPanel); CORNER(6,SearchBoxConfig); local SearchStrokeConfig=STROKE(GOLD3,1,0.3,SearchBoxConfig)
SearchBoxConfig.Focused:Connect(function() TWEEN(SearchStrokeConfig,0.2,{Color=GOLD2,Transparency=0}) end); SearchBoxConfig.FocusLost:Connect(function() TWEEN(SearchStrokeConfig,0.2,{Color=GOLD3,Transparency=0.3}) end)
local ConfigList=NEW("ScrollingFrame",{Size=UDim2.new(1,-16,1,-76),Position=UDim2.new(0,8,0,74),BackgroundColor3=C(6,7,14),ScrollBarThickness=2,ScrollBarImageColor3=GOLD3,BorderSizePixel=0},LeftPanel); CORNER(6,ConfigList); STROKE(C(25,22,8),1,0.2,ConfigList)
NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),HorizontalAlignment=Enum.HorizontalAlignment.Center},ConfigList); NEW("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},ConfigList)

local RightPanel=NEW("Frame",{Size=UDim2.new(1,-248,1,0),BackgroundColor3=BG3,LayoutOrder=1},cfgContainer); CORNER(8,RightPanel); STROKE(GOLD,1,0.72,RightPanel)
local rpHead=NEW("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=BG_HDR},RightPanel); CORNER(8,rpHead)
NEW("Frame",{Size=UDim2.new(1,0,0,15),Position=UDim2.new(0,0,1,-15),BackgroundColor3=BG_HDR,BorderSizePixel=0},rpHead)
NEW("TextLabel",{Text="▷ ACTIONS",Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},rpHead)
NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6),HorizontalAlignment=Enum.HorizontalAlignment.Center},RightPanel)
NEW("UIPadding",{PaddingTop=UDim.new(0,0),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},RightPanel)
local ConfigNameBox=NEW("TextBox",{Size=UDim2.new(1,0,0,34),BackgroundColor3=BG5,PlaceholderText="  Config name...",Text="",TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=12},RightPanel); CORNER(6,ConfigNameBox); local NameStroke=STROKE(GOLD3,1,0,ConfigNameBox)
ConfigNameBox.Focused:Connect(function() TWEEN(NameStroke,0.2,{Color=GOLD2}) end); ConfigNameBox.FocusLost:Connect(function() TWEEN(NameStroke,0.2,{Color=GOLD3}) end)
NEW("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C(30,28,55),BorderSizePixel=0},RightPanel)

local function CreateActionBtn(iconN,label,bgCol,hoverCol,strokeCol,textCol)
    textCol=textCol or TEXT1; local btn=NEW("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=bgCol,Text="",AutoButtonColor=false},RightPanel); CORNER(6,btn); STROKE(strokeCol,1,0.08,btn)
    local iHolder=NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,12,0.5,-8),BackgroundTransparency=1,BorderSizePixel=0},btn); DrawIcon(iHolder,iconN,0,0,16,strokeCol)
    NEW("TextLabel",{Text=label,Size=UDim2.new(1,-38,1,0),Position=UDim2.new(0,34,0,0),BackgroundTransparency=1,TextColor3=textCol,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},btn)
    btn.MouseEnter:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=hoverCol}) end); btn.MouseLeave:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=bgCol}) end)
    return btn
end
local CreateBtn     =CreateActionBtn("fruit",  "CREATE CONFIG", C(8,28,8),  C(12,44,12), GREEN,  GREEN)
local SaveBtn       =CreateActionBtn("gear",   "SAVE CONFIG",   C(10,12,32),C(16,20,52), BLUE_A, BLUE_A)
local LoadBtn       =CreateActionBtn("globe",  "LOAD CONFIG",   C(8,18,40), C(12,26,58), CYAN,   CYAN)
local RefreshBtn    =CreateActionBtn("wave",   "REFRESH LIST",  C(8,22,26), C(12,32,38), C(48,180,180),C(48,180,180))
local SetAutoLoadBtn=CreateActionBtn("lightning","SET AUTO LOAD",C(30,22,6),C(46,34,8),  AMBER,  AMBER)
local DeleteBtn     =CreateActionBtn("shield", "DELETE CONFIG", C(38,8,8),  C(58,12,12), RED,    RED)

pcall(function()
    local CL=require("Config/ConfigManager")
    if CL and CL.Init then CL.Init({ConfigNameBox=ConfigNameBox,ConfigList=ConfigList,CreateBtn=CreateBtn,SaveBtn=SaveBtn,LoadBtn=LoadBtn,RefreshBtn=RefreshBtn,SetAutoLoadBtn=SetAutoLoadBtn,DeleteBtn=DeleteBtn,SearchBox=SearchBoxConfig},AutoStatsData,TogglesData) end
end)

end -- _buildConfigManagerCards
_buildConfigManagerCards()

-- =====================================================================
-- DRAG (top bar)
-- =====================================================================
local d,dS,sP
TopBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;dS=i.Position;sP=MainFrame.Position end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then local delta=i.Position-dS;MainFrame.Position=UDim2.new(sP.X.Scale,sP.X.Offset+delta.X,sP.Y.Scale,sP.Y.Offset+delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)

-- =====================================================================
-- CLOSE BUTTON
-- =====================================================================
CloseBtn.MouseButton1Click:Connect(function()
    -- Show properly-sized confirmation dialog before closing
    local _confirmActive=true
    local confirmFrame=NEW("Frame",{Size=UDim2.new(0,300,0,132),Position=UDim2.new(0.5,-150,0.5,-66),BackgroundColor3=BG1,BorderSizePixel=0,ZIndex=999,ClipsDescendants=false},MainFrame)
    CORNER(12,confirmFrame); STROKE(RED,1.5,0.1,confirmFrame)
    -- Darken overlay
    local dimOverlay=NEW("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C(0,0,0),BackgroundTransparency=0.55,BorderSizePixel=0,ZIndex=998},MainFrame)
    CORNER(14,dimOverlay)
    NEW("TextLabel",{Text="Close Zili Hub?",Size=UDim2.new(1,-20,0,26),Position=UDim2.new(0,10,0,14),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=1000},confirmFrame)
    NEW("TextLabel",{Text="All running features will be stopped.",Size=UDim2.new(1,-20,0,16),Position=UDim2.new(0,10,0,44),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=1000},confirmFrame)
    local yesBtn=NEW("TextButton",{Text="CLOSE HUB",Size=UDim2.new(0,126,0,36),Position=UDim2.new(0,14,0,82),BackgroundColor3=C(38,8,8),TextColor3=RED,Font=Enum.Font.GothamBold,TextSize=13,AutoButtonColor=false,ZIndex=1000},confirmFrame); CORNER(8,yesBtn); STROKE(RED,1.2,0.15,yesBtn)
    local noBtn=NEW("TextButton",{Text="CANCEL",Size=UDim2.new(0,126,0,36),Position=UDim2.new(1,-140,0,82),BackgroundColor3=BG3,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=13,AutoButtonColor=false,ZIndex=1000},confirmFrame); CORNER(8,noBtn); STROKE(TEXT3,1,0.4,noBtn)
    yesBtn.MouseEnter:Connect(function() TWEEN(yesBtn,0.15,{BackgroundColor3=C(60,12,12)}) end); yesBtn.MouseLeave:Connect(function() TWEEN(yesBtn,0.15,{BackgroundColor3=C(38,8,8)}) end)
    noBtn.MouseEnter:Connect(function() TWEEN(noBtn,0.15,{BackgroundColor3=BG4}) end); noBtn.MouseLeave:Connect(function() TWEEN(noBtn,0.15,{BackgroundColor3=BG3}) end)
    TWEEN_BACK(confirmFrame,0.25,{Position=UDim2.new(0.5,-150,0.5,-66)})
    local function closeConfirm() _confirmActive=false; TWEEN(confirmFrame,0.18,{BackgroundTransparency=1,Position=UDim2.new(0.5,-150,0.45,-66)}); TWEEN(dimOverlay,0.18,{BackgroundTransparency=1}); task.delay(0.2,function() pcall(function() confirmFrame:Destroy() end); pcall(function() dimOverlay:Destroy() end) end) end
    noBtn.MouseButton1Click:Connect(closeConfirm)
    yesBtn.MouseButton1Click:Connect(function()
        closeConfirm()
        task.wait(0.22)
        getgenv().ZiliHub_Loaded=false
        local origPos=MainFrame.Position; local ox,oy=origPos.X.Offset,origPos.Y.Offset
        TWEEN(CloseBtn,0.06,{TextColor3=C(255,40,40)})
        local redOverlay=NEW("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C(200,20,20),BackgroundTransparency=0.87,ZIndex=100,BorderSizePixel=0},MainFrame); CORNER(10,redOverlay)
        task.wait(0.06); TWEEN(redOverlay,0.08,{BackgroundTransparency=1})
        local glitch={-7,5,-9,8,-3,6,-2,1,0}
        for _,dx in ipairs(glitch) do TweenService:Create(MainFrame,TweenInfo.new(0.02,Enum.EasingStyle.Linear),{Position=UDim2.new(origPos.X.Scale,ox+dx,origPos.Y.Scale,oy+math.random(-2,2))}):Play();task.wait(0.02) end
        local cx=MainFrame.AbsolutePosition.X+MainFrame.AbsoluteSize.X/2; local cy=MainFrame.AbsolutePosition.Y+MainFrame.AbsoluteSize.Y/2
        local allParticles={}
        for i=0,11 do
            local angle=(i/12)*math.pi*2; local dir={math.cos(angle),math.sin(angle)}; local sz=math.random(4,10)
            local col=i%3==0 and GOLD2 or i%3==1 and C(220,60,60) or C(255,240,200)
            local frag=NEW("Frame",{Size=UDim2.new(0,sz,0,sz),Position=UDim2.new(0,cx-sz/2,0,cy-sz/2),BackgroundColor3=col,BorderSizePixel=0,ZIndex=102},ScreenGui); CORNER(math.random(2,5),frag)
            table.insert(allParticles,{frag=frag,dir=dir,dist=math.random(120,240)})
        end
        local shockwave=NEW("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,cx-5,0,cy-5),BackgroundTransparency=1,ZIndex=105,BorderSizePixel=0},ScreenGui); CORNER(5,shockwave); STROKE(GOLD,2.5,0,shockwave)
        TweenService:Create(MainFrame,TweenInfo.new(0.38,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.new(origPos.X.Scale,ox+MainFrame.AbsoluteSize.X/2-10,origPos.Y.Scale,oy+MainFrame.AbsoluteSize.Y/2-10),Size=UDim2.new(0,20,0,20),GroupTransparency=1}):Play()
        TweenService:Create(shockwave,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,440,0,440),Position=UDim2.new(0,cx-220,0,cy-220)}):Play()
        for _,p in ipairs(allParticles) do TweenService:Create(p.frag,TweenInfo.new(0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(0,cx+p.dir[1]*p.dist,0,cy+p.dir[2]*p.dist),Size=UDim2.new(0,2,0,2),BackgroundTransparency=1}):Play() end
        task.wait(0.55)
        for _,p in ipairs(allParticles) do if p.frag and p.frag.Parent then p.frag:Destroy() end end
        if shockwave and shockwave.Parent then shockwave:Destroy() end
        ScreenGui:Destroy()
    end)
end)

-- =====================================================================
-- EXECUTOR DIAGNOSTICS (lightweight)
-- =====================================================================
local TweenService = cloneref(game:GetService("TweenService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))

local function RunExecutorDiagnostics()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local execName = "Unknown Executor"
    if type(identifyexecutor) == "function" then 
        pcall(function() execName = identifyexecutor() end) 
    end

    -- 1. IMPROVED CHECK
    local criticalDeps = {"hookmetamethod", "hookfunction", "getnamecallmethod", "newcclosure", "checkcaller", "cloneref", "run_on_actor", "getconnections"}
    local optionalDeps = {"getrawmetatable", "setreadonly", "fireproximityprompt", "readfile", "writefile", "isfile", "makefolder", "setclipboard", "request", "setthreadidentity", "setthreadcontext", "setidentity"}
    
    local totalDeps = #criticalDeps + #optionalDeps
    local supported = 0
    local missingCritical = 0

    for _, v in ipairs(criticalDeps) do 
        if type(env[v]) == "function" then supported = supported + 1 else missingCritical = missingCritical + 1 end 
    end
    for _, v in ipairs(optionalDeps) do 
        if type(env[v]) == "function" or (v == "request" and (type(env.request) == "function" or type(env.http) == "table")) then supported = supported + 1 end 
    end

    local pct = math.floor((supported / totalDeps) * 100)
    local isSafe = (missingCritical == 0 and pct >= 50)

    -- 2. DYNAMIC UI THEME
    local COLOR_SAFE = Color3.fromRGB(46, 204, 113)   -- Emerald Green
    local COLOR_DANGER = Color3.fromRGB(231, 76, 60)  -- Alizarin Red
    local BG_MAIN = Color3.fromRGB(20, 20, 25)
    local BG_HEADER = Color3.fromRGB(30, 30, 35)
    
    local themeColor = isSafe and COLOR_SAFE or COLOR_DANGER
    local uiHeight = isSafe and 100 or 120 
    local bottomOffset = 150

    -- ==========================================
    -- 🛡️ 3. GET HIDDEN UI & ANTI-SPAM (IMPROVED)
    -- ==========================================
    local targetGui = (type(gethui) == "function" and gethui()) or (pcall(function() return CoreGui.Name end) and CoreGui) or Players.LocalPlayer:WaitForChild("PlayerGui")
    
    if targetGui:FindFirstChild("ZiliDiagnostics") then
        targetGui.ZiliDiagnostics:Destroy()
    end

    -- 4. BUILD UI STANDALONE
    local sg = Instance.new("ScreenGui")
    sg.Name = "ZiliDiagnostics"
    sg.Parent = targetGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, uiHeight)
    -- Thay đổi vị trí xuất phát để khớp độ cao mới
    frame.Position = UDim2.new(1, 20, 1, -(uiHeight + bottomOffset)) 
    frame.BackgroundColor3 = BG_MAIN
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = themeColor
    frameStroke.Thickness = isSafe and 1 or 2 
    frameStroke.Parent = frame

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = BG_HEADER
    header.BorderSizePixel = 0
    header.Parent = frame
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    local headerFix = Instance.new("Frame") 
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = BG_HEADER
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "EXECUTOR CHECK"
    title.TextColor3 = themeColor
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Body Information
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -30, 0, 20)
    infoLabel.Position = UDim2.new(0, 15, 0, 40)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Executor: " .. execName
    infoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    infoLabel.Font = Enum.Font.GothamSemibold
    infoLabel.TextSize = 12
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = frame

    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(1, -30, 0, 20)
    scoreLabel.Position = UDim2.new(0, 15, 0, 58)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score: " .. pct .. "% (" .. supported .. "/" .. totalDeps .. " APIs)"
    scoreLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    scoreLabel.Font = Enum.Font.Gotham
    scoreLabel.TextSize = 11
    scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
    scoreLabel.Parent = frame

    -- Progress Bar
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -30, 0, 6)
    barBg.Position = UDim2.new(0, 15, 0, 82)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barBg.Parent = frame
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 3)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = themeColor
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 3)

    -- ==========================================
    -- 🚨 5. TWEENS & ANIMATIONS (OPTIMIZED)
    -- ==========================================
    if not isSafe then
        local warnLabel = Instance.new("TextLabel")
        warnLabel.Size = UDim2.new(1, -30, 0, 20)
        warnLabel.Position = UDim2.new(0, 15, 0, 95)
        warnLabel.BackgroundTransparency = 1
        warnLabel.Text = "MISSING FUNCTION. USE AT YOUR OWN RISK !!!"
        warnLabel.TextColor3 = COLOR_DANGER
        warnLabel.Font = Enum.Font.GothamBold
        warnLabel.TextSize = 11
        warnLabel.Parent = frame

        local blinkInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        TweenService:Create(warnLabel, blinkInfo, {TextTransparency = 0.6}):Play()
    end

    -- Sử dụng biến bottomOffset cho lúc trượt vào và trượt ra
    local showTween = TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -300, 1, -(uiHeight + bottomOffset))})
    local hideTween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 1, -(uiHeight + bottomOffset))})
    local barTween = TweenService:Create(barFill, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(pct / 100, 0, 1, 0)})

    showTween:Play()
    task.wait(0.4)
    barTween:Play()
    
    local displayTime = isSafe and 5 or 8
    task.delay(displayTime, function()
        hideTween:Play()
        hideTween.Completed:Wait()
        sg:Destroy()
    end)
end
task.spawn(RunExecutorDiagnostics)

-- =====================================================================
-- SIGNAL READY
-- =====================================================================
getgenv()._ZiliLoadReady = true

-- =====================================================================
-- MULTI-ACC AUTO TRIGGER  [FIX BUG 1]
-- 
-- Flow đúng:
--   LOBBY  (IS_LOBBY=true)  → hiện notification + join PS riêng
--                             KHÔNG load config ở đây vì Fishing/Farm
--                             toggles chưa được build trong lobby!
--                             _ZiliMultiAccData KHÔNG clear → giữ lại
--                             cho lần chạy script ở game world.
--
--   GAME WORLD (IS_LOBBY=false) → load config (toggles đã build đủ)
--                                + override PSCode/hub/sea
--                                + clear flag
-- =====================================================================
task.spawn(function()
    local maData = getgenv()._ZiliMultiAccData
    if not maData then return end

    -- ══════════════════════════════════════════════════════════════════
    -- GAME WORLD PATH: load config + override PS settings
    -- ══════════════════════════════════════════════════════════════════
    if not IS_LOBBY then
        local cfgName = maData.configName
        local psCode  = maData.psCode
        local hub     = maData.hub
        local sea     = maData.sea

        -- [FIX BUG 1] Đợi tất cả page builders + modules load xong
        -- (Fishing/Farm page builders chạy đồng bộ trước đây, nhưng
        --  modules như AutoFishMerchantModule load async → cần thêm thời gian)
        task.wait(4.5)

        if cfgName ~= "" then
            -- Thử load config, retry 1 lần nếu thất bại
            local loadOk = false
            pcall(function()
                local CL = require("Config/ConfigManager")
                if CL and CL.LoadByName then
                    loadOk = CL.LoadByName(cfgName, AutoStatsData or {}, TogglesData)
                end
            end)
            if not loadOk then
                task.wait(1.5)
                pcall(function()
                    local CL = require("Config/ConfigManager")
                    if CL and CL.LoadByName then
                        loadOk = CL.LoadByName(cfgName, AutoStatsData or {}, TogglesData)
                    end
                end)
            end

            -- Luôn override lại PSCode/hub/sea của acc này
            -- (LoadByName có thể đã restore PSCode sai từ config được share)
            task.wait(0.3)
            pcall(function()
                -- [FIX BUG 2] KHÔNG ghi getgenv().PSCode / SelectedHub / SelectedSea
                -- vì getgenv() SHARED giữa các tab executor → ghi đè làm acc 1,2,3
                -- join sai PS và bị kick ra lobby.
                -- Dùng per-player key để lưu rejoin data an toàn.
                local _playerKey = "_ZiliRejoinData_" .. game:GetService("Players").LocalPlayer.Name
                getgenv()[_playerKey] = { psCode = psCode, hub = hub, sea = sea }

                -- Update TogglesData (local scope, không ảnh hưởng acc khác)
                if TogglesData["Config_PSCode"] then
                    TogglesData["Config_PSCode"].Value = psCode
                    if TogglesData["Config_PSCode"].HeadBtn then
                        pcall(function() TogglesData["Config_PSCode"].HeadBtn.Text = psCode end)
                    end
                end
                -- Force off AutoJoinPS: gọi Callback(false) để autoJoinActive=false đúng cách
                if TogglesData["Config_AutoJoinPS"] then
                    if TogglesData["Config_AutoJoinPS"].Callback then
                        pcall(function() TogglesData["Config_AutoJoinPS"].Callback(false) end)
                    end
                    TogglesData["Config_AutoJoinPS"].Value = false
                end
                -- Override hub/sea trong TogglesData (không ghi vào getgenv chung)
                if TogglesData["Config_SelectedHub"] and TogglesData["Config_SelectedHub"].Callback then
                    pcall(function() TogglesData["Config_SelectedHub"].Callback(hub) end)
                end
                if TogglesData["Config_SelectedSea"] and TogglesData["Config_SelectedSea"].Callback then
                    pcall(function() TogglesData["Config_SelectedSea"].Callback(sea) end)
                end
            end)
        end

        -- Clear flag sau khi game world đã xử lý xong
        task.wait(2)
        getgenv()._ZiliMultiAccData = nil
        return
    end

    -- ══════════════════════════════════════════════════════════════════
    -- LOBBY PATH: notification + join PS
    -- KHÔNG load config ở đây (Fishing/Farm toggles chưa tồn tại)
    -- KHÔNG clear _ZiliMultiAccData (cần cho game world path)
    -- ══════════════════════════════════════════════════════════════════
    task.wait(3.0) -- đợi UI + ConfigManager.Init + config list load xong

    local cfgName = maData.configName
    local psCode  = maData.psCode
    local hub     = maData.hub
    local sea     = maData.sea
    local _HubArgs = {["Regular"]=true,["Trade Hub"]="tradeHub",["Universe Hub"]="universeHub",["Fish Hub"]="fishHub"}
    local psShort  = (psCode ~= "") and (psCode:sub(1,10).."...") or "Public"
    local cfgShort = (cfgName ~= "") and cfgName or "None"

    -- ── Notification ─────────────────────────────────────────────────
    local TweenService2 = game:GetService("TweenService")
    pcall(function()
        local sg2 = Instance.new("ScreenGui")
        sg2.Name = "ZiliMultiAccNotify"; sg2.ResetOnSpawn = false
        sg2.Parent = gethui and gethui() or game:GetService("CoreGui")
        local nf = Instance.new("Frame", sg2)
        nf.Size = UDim2.new(0, 290, 0, 86)
        nf.Position = UDim2.new(1, 310, 1, -110)
        nf.AnchorPoint = Vector2.new(1, 1)
        nf.BackgroundColor3 = Color3.fromRGB(8, 9, 20)
        nf.BorderSizePixel = 0
        Instance.new("UICorner", nf).CornerRadius = UDim.new(0, 10)
        local st2 = Instance.new("UIStroke", nf)
        st2.Color = Color3.fromRGB(48, 210, 160); st2.Thickness = 1.5; st2.Transparency = 0.1
        local acc2 = Instance.new("Frame", nf)
        acc2.Size = UDim2.new(0, 3, 0.7, 0); acc2.Position = UDim2.new(0, 0, 0.15, 0)
        acc2.BackgroundColor3 = Color3.fromRGB(48, 210, 160); acc2.BorderSizePixel = 0
        Instance.new("UICorner", acc2).CornerRadius = UDim.new(0, 2)
        local function ML(text, col, posY, size)
            local l = Instance.new("TextLabel", nf)
            l.Size = UDim2.new(1,-18,0,size or 14); l.Position = UDim2.new(0,14,0,posY)
            l.BackgroundTransparency=1; l.Text=text; l.TextColor3=col
            l.Font=Enum.Font.GothamSemibold; l.TextSize=size or 11
            l.TextXAlignment=Enum.TextXAlignment.Left
        end
        ML("👤 Multi-Acc: "..maData.name, Color3.fromRGB(48,210,160), 5, 12)
        ML("📂 Config: "..cfgShort,        Color3.fromRGB(200,190,240), 22, 11)
        ML("🔐 PS: "..psShort,             Color3.fromRGB(160,190,220), 38, 10)
        ML("🌐 "..hub.." / "..sea,         Color3.fromRGB(140,175,200), 52, 10)
        ML("⏳ Joining PS, config loads in-game...", Color3.fromRGB(100,180,140), 67, 9)
        TweenService2:Create(nf, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position=UDim2.new(1,-14,1,-110)}):Play()
        task.delay(7, function()
            local fade=TweenService2:Create(nf,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
                {Position=UDim2.new(1,310,1,-110),BackgroundTransparency=1})
            fade:Play(); fade.Completed:Connect(function() sg2:Destroy() end)
        end)
    end)

    -- ── Join PS của acc ───────────────────────────────────────────────
    -- [FIX BUG 1] KHÔNG load config ở đây nữa.
    -- Config sẽ được load ở game world path (IS_LOBBY=false) ở trên.
    -- _ZiliMultiAccData được GIỮ LẠI để game world path đọc được.
    task.wait(1.2)
    pcall(function()
        ServerModule.Join(psCode, _HubArgs[hub] or true, hub=="Regular" and sea or nil)
    end)
    -- Không clear _ZiliMultiAccData ở đây!
end)
end -- _initUI
_initUI()
