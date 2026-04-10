-- =====================================================================
-- 0. ANTI-DUPLICATE (FIX TRIỆT ĐỂ CHO WAVE / SOLARA)
-- =====================================================================
-- Dự phòng môi trường: Nếu getgenv() của Wave bị hỏng thì tự lùi về _G
local env = (type(getgenv) == "function" and getgenv()) or _G or shared

if env.ZiliHub_Loaded then
    warn("[ZILI NOTIFY] Script is already running! Execution blocked to prevent crash.")
    
    -- Dùng trick tạo Event ảo để ép dừng luồng script vĩnh viễn
    -- Đảm bảo 100% ngắt được script trên mọi loại Executor mà không văng lỗi đỏ
    return coroutine.yield()
end

env.ZiliHub_Loaded = true

-- =====================================================================
-- 1. BUNDLER SYSTEM (Allows Executor to understand 'require')
-- =====================================================================
local __modules = {}
local __cache = {}

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
    local ConfigFolder  = "Zili_Hub"

    if isfolder and not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

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
    local function ApplyToggleVisual(data, on)
        if data.Btn  then Tween(data.Btn,  0.2, {BackgroundColor3 = on and GOLDD or BG5}) end
        if data.Strk then Tween(data.Strk, 0.2, {Color            = on and GOLD2 or GOLD3}) end
        if data.Thumb then
            Tween(data.Thumb, 0.2, {
                BackgroundColor3 = on and GOLD2 or TEXT3,
                Position         = on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8),
            })
        end
        if data.MasterBar then
            Tween(data.MasterBar, 0.35, {BackgroundColor3 = on and GREEN or GOLD})
        end
        -- Stats-style Auto Add button
        if data.Btn and data.Btn:IsA("TextButton") and data.Btn.Text ~= "" then
            -- This is a stat add button, not a pill toggle
            if on then
                data.Btn.BackgroundColor3 = Color3.fromRGB(120, 90, 0)
                data.Btn.TextColor3       = Color3.fromRGB(10, 8, 2)
                data.Btn.Text             = "● Adding..."
            else
                Tween(data.Btn, 0.2, {BackgroundColor3 = Color3.fromRGB(8, 9, 20)})
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
        local autoLoadPath = ConfigFolder .. "/autoload.txt"
        if isfile(autoLoadPath) then
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
                        -- Slight delay so all UI is fully built before restoring
                        task.delay(0.5, function()
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
    local IslandData = {
        ["???? Shrine"] = Vector3.new(-7348.86, 3.27, -14950.54), -- co
        ["A Rock"] = Vector3.new(2534.69, 7.33, -8370.14), -- co
        ["Coco Island"] = Vector3.new(-3086.87, 94.54, -11755.48), -- co
        ["Colosseum"] = Vector3.new(-2031.47, 6.85, -7666.31), -- co
        ["Fishman Cave"] = Vector3.new(1842.72, 3.84, -12170.62), -- co
        ["Fishman Islands"] = Vector3.new(1791.87, -94.83, -12327.67),   
        ["Gravito's Fort"] = Vector3.new(264.84, 7.64, -11477.32), -- co
        ["Island Of Zou"] = Vector3.new(-3121.06, 11.73, -5256.59), -- co
        ["Kori Island"] = Vector3.new(-4266.8, 169.48, -2976.2), -- co
        ["Land of the Sky"] = Vector3.new(3452.06, 1438.24, -9077.78), -- co
        ["Logue Town"] = Vector3.new(-6587.53, 7.22, -7674.48), -- co
        ["Marine Base G-1"] = Vector3.new(-5996.11, 57.24, -11489.15), -- co
        ["Marine Fort F-1"] = Vector3.new(424.6, 19.45, -4479.89), -- co
        ["Mysterious Cliff"] = Vector3.new(78.64, 412.74, -8280.99), -- co
        ["Orange Town"] = Vector3.new(-4456.83, 5.3, -6640.93), -- co
        ["Restaurant Baratie"] = Vector3.new(-2949.38, 6.31, -6696.07), -- co
        ["Reverse Mountain"] = Vector3.new(-8001.37, 52.22, -8571.84), -- co
        ["Roca Island"] = Vector3.new(1532.26, 155.38, -6573.02), -- co
        ["Sandora"] = Vector3.new(-1540.96, 3.97, -3352.63), -- co
        ["Shark Park"] = Vector3.new(-1583.31, 12.29, -10076.3), -- co 
        ["Shell's Town"] = Vector3.new(-1337.18, 4.12, -5025.98), -- co
        ["Sphinx Island"] = Vector3.new(-4015.28, 41.28, -9154.84), -- co
        ["Town of Beginnings"] = Vector3.new(-522.6, 8.07, -3396) -- co
    }

    return IslandData
end

-- 📦 MODULE: GhostApexBypass.lua (GHOST TIER + STRICT EXECUTOR GUARD)
__modules["BYPASS ANTICHEAT"] = function()
    local Bypass = {}

    -- Ultra-fast local references (Zero Global Environment Footprint)
    local hookmetamethod = hookmetamethod
    local getnamecallmethod = getnamecallmethod
    local newcclosure = newcclosure
    local type, typeof = type, typeof
    local math_random = math.random
    local tick, os_clock = tick, os.clock
    local pcall = pcall
    local table_insert = table.insert
    local table_concat = table.concat

    local game = game
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- ==========================================
    -- 0. EXECUTOR INTEGRITY CHECK (THE GATEKEEPER)
    -- ==========================================
    local function VerifyExecutor()
        -- Nhận diện tên Executor hiện tại
        local executorName = "Unknown Executor"
        if type(identifyexecutor) == "function" then
            local success, name = pcall(identifyexecutor)
            if success and name then executorName = name end
        end

        -- Danh sách các hàm tàng hình bắt buộc phải có để chạy Ghost Tier
        local requiredFunctions = {
            {name = "hookmetamethod", func = hookmetamethod},
            {name = "getnamecallmethod", func = getnamecallmethod},
            {name = "newcclosure", func = newcclosure}
        }
        
        local missing = {}
        for _, item in ipairs(requiredFunctions) do
            if type(item.func) ~= "function" then
                table_insert(missing, item.name)
            end
        end

        -- Nếu thiếu hàm -> Chặn đứng quá trình inject và Kick ngay lập tức
        if #missing > 0 then
            local kickMsg = string.format(
                "\n[ZILI SECURITY] - BYPASS FAILED!\n\n" ..
                "Executor: %s\n" ..
                "Status: INCOMPATIBLE / UNSAFE\n" ..
                executorName
            )
            
            warn("[ZILI SECURITY] Bypass failed. Unsupported executor: " .. executorName)
            LocalPlayer:Kick(kickMsg)
            
            -- Đóng băng luồng (Thread) vĩnh viễn, không cho bất kỳ code nào bên dưới chạy
            task.wait(9e9) 
            return false
        end

        return true
    end

    -- ==========================================
    -- 1. BEHAVIORAL DRIFT (Session-Based State Machine)
    -- ==========================================
    local SessionStart = os_clock()
    
    local function GetSessionDrift(baseValue)
        local sessionTime = os_clock() - SessionStart
        local driftFactor = 0

        if sessionTime < 300 then
            driftFactor = math_random(-50, 0) / 100 
        elseif sessionTime < 1200 then
            driftFactor = math_random(-120, -40) / 100
        else
            driftFactor = math_random(-250, -80) / 100
        end

        return baseValue + driftFactor
    end

    -- ==========================================
    -- 2. MULTI-BASELINE MODEL & TRUST-WEIGHTING (Anti-Poisoning)
    -- ==========================================
    local RemoteProfiles = {}

    local function AllocateBaseline(args)
        if typeof(args[1]) ~= "table" then return nil end
        local baseline = {}
        if args[1].WalkSpeed then baseline.WalkSpeed = args[1].WalkSpeed end
        if args[1].JumpPower then baseline.JumpPower = args[1].JumpPower end
        return baseline
    end

    local function EvaluateTrust(profile, currentTime, args)
        local dt = currentTime - profile.lastCall
        if dt < 0.05 then return false end 
        
        local newBaseline = AllocateBaseline(args)
        if newBaseline then
            profile.baselines[profile.baselineIndex] = newBaseline
            profile.baselineIndex = (profile.baselineIndex % 5) + 1
            profile.trustWeight = math.min(profile.trustWeight + 1, 100)
            return true
        end
        return false
    end

    -- ==========================================
    -- 3. ASYNC QUEUE SYSTEM (Zero-Yield Routing)
    -- ==========================================
    local AsyncQueue = {}

    -- [FIX 2] Thêm nil-check + pcall: nếu remote bị destroy giữa chừng thì không crash
    RunService.Heartbeat:Connect(function(deltaTime)
        for i = #AsyncQueue, 1, -1 do
            local taskObj = AsyncQueue[i]
            taskObj.timer = taskObj.timer - deltaTime
            if taskObj.timer <= 0 then
                if taskObj.remote and taskObj.remote.Parent then
                    pcall(function() taskObj.remote:FireServer(table.unpack(taskObj.args)) end)
                end
                table.remove(AsyncQueue, i)
            end
        end
    end)

    -- ==========================================
    -- 4. THE ZERO-YIELD HOOK
    -- ==========================================
    function Bypass.Init()
        -- 🔒 LỚP BẢO VỆ VÒNG NGOÀI (Check Executor)
        if not VerifyExecutor() then return end

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method ~= "FireServer" then return oldNamecall(self, ...) end

            local args = {...}
            local currentTime = os_clock()

            if not RemoteProfiles[self] then
                RemoteProfiles[self] = {
                    baselines = {},
                    baselineIndex = 1,
                    lastCall = 0,
                    trustWeight = 0,
                    isTargeted = false
                }
            end

            local profile = RemoteProfiles[self]
            EvaluateTrust(profile, currentTime, args)
            profile.lastCall = currentTime

            -- Phân tích Payload bất thường
            if profile.trustWeight > 10 and typeof(args[1]) == "table" and args[1].WalkSpeed then
                profile.isTargeted = true
                
                if args[1].WalkSpeed > 20 then
                    local sample = profile.baselines[math_random(1, #profile.baselines)] or {WalkSpeed = 16}
                    local driftedSpeed = GetSessionDrift(sample.WalkSpeed or 16)
                    
                    args[1].WalkSpeed = driftedSpeed
                    
                    local dynamicJitter = (math_random(20, 80) / 1000) 
                    table_insert(AsyncQueue, {
                        remote = self,
                        args = args,
                        timer = dynamicJitter
                    })
                    
                    return nil
                end
            end

            return oldNamecall(self, ...)
        end))

        -- Đã đổi dòng thông báo theo đúng yêu cầu của bác
        print("[ZILI SECURITY] Anti-Cheat Bypass Initialized Successfully !!!")
    end

    return Bypass
end

-- 📦 MODULE: TweenToIsland.lua (BẢN FULL HOÀN CHỈNH - KHÔNG CẦN CHỈNH SỬA GÌ THÊM)
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

    -- =====================================================================
    -- STAMINA SPOOF (chỉ chạy khi đang tween)
    -- =====================================================================
    local Events   = ReplicatedStorage:WaitForChild("Events", 5)
    local TakeStam = Events and Events:WaitForChild("takestam", 5)

    -- [FIX 3] StaminaSpoof singleton: dùng _G._ZiliStaminaSpoofing để chỉ có 1 loop trên toàn script
    -- Tránh 3 module (TweenToIsland / AutoFarmLevel / AutoGetBuso) spam server ~60 req/s
    local isSpoofingStamina = false
    local function StartStaminaSpoof()
        if _G._ZiliStaminaSpoofing then return end
        _G._ZiliStaminaSpoofing = true
        isSpoofingStamina = true
        task.spawn(function()
            while isSpoofingStamina and _G._ZiliStaminaSpoofing and task.wait(0.05) do
                if TakeStam and TakeStam.Parent then
                    pcall(function() TakeStam:FireServer(0.545, "dash") end)
                else break end
            end
            _G._ZiliStaminaSpoofing = false
        end)
    end
    local function StopStaminaSpoof()
        isSpoofingStamina = false
        _G._ZiliStaminaSpoofing = false
    end

    -- =====================================================================
    -- ANTI-AFK & ANTI-SIT
    -- =====================================================================
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do conn:Disable() end
    end)
    if _G.AntiAfkConnection then _G.AntiAfkConnection:Disconnect() end
    _G.AntiAfkConnection = LocalPlayer.Idled:Connect(function()
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

    local function getRoot()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            return char.HumanoidRootPart
        end
        return nil
    end

    function Tween.Stop()
        Tween.IsTeleporting = false
        StopStaminaSpoof() -- 🛑 Dừng spoof khi stop tween
        if Tween.MoveConn then Tween.MoveConn:Disconnect(); Tween.MoveConn = nil end
        if Tween.NoclipConn then Tween.NoclipConn:Disconnect(); Tween.NoclipConn = nil end

        local root = getRoot()
        if root then
            for _, v in pairs(root:GetChildren()) do 
                if v.Name == "ZILI_AntiGravity" then v:Destroy() end 
            end
            pcall(function() root.Velocity = VEC_ZERO end)
        end
        if Tween.FakeFloor then Tween.FakeFloor:Destroy(); Tween.FakeFloor = nil end
    end

    function Tween.Start(targetData)
        Tween.Stop()
        Tween.IsTeleporting = true
        StartStaminaSpoof() -- ▶️ Bắt đầu spoof khi start tween
        
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

            -- [FIX 6] BodyVelocity deprecated → LinearVelocity (Roblox constraint mới)
            local antiGravity = root:FindFirstChild("ZILI_AntiGravity")
            if not antiGravity then
                antiGravity = Instance.new("LinearVelocity")
                antiGravity.Name = "ZILI_AntiGravity"
                antiGravity.MaxForce = math.huge
                antiGravity.VectorVelocity = Vector3.zero
                antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World
                local attachment = Instance.new("Attachment")
                attachment.Name = "ZILI_AntiGravityAttach"
                attachment.Parent = root
                antiGravity.Attachment0 = attachment
                antiGravity.Parent = root
            end

            local targetPos = stepData.pos

            Tween.MoveConn = RunService.Heartbeat:Connect(function(deltaTime)
                if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end

                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                pcall(function() root.Velocity = VEC_ZERO end)

                local currentPos = root.Position
                local distXZ = (Vector2.new(targetPos.X, targetPos.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude
                local max_step = math.min(MAX_SPEED * deltaTime, 120)

                -- ÉP Y = 7.33 NẾU KHÔNG PHẢI ĐẢO NGƯỜI CÁ (bay an toàn)
                if not stepData.isFishmanIn and not stepData.isFishmanExit then
                    if math.abs(currentPos.Y - 7.33) > 10 and distXZ > 50 then
                        Tween.MoveConn:Disconnect()
                        task.spawn(function()
                            root.CFrame = CFrame.new(currentPos.X, 7.33, currentPos.Z)
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
                    -- BAY ĐẾN MỤC TIÊU
                    local safeY = (stepData.isFishmanIn or stepData.isFishmanExit) and targetPos.Y or 7.33
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
    local isLvlFarmOn = {}
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Player = Players.LocalPlayer

    -- [FIX 1] Nguyên nhân insta-crash: original_require() trên server-sided ModuleScript bị Roblox block
    -- AutoGetBuso đã làm đúng, AutoFarmLevel chưa — fix để đồng bộ
    local QuestFunc = nil
    pcall(function()
        local mods = ReplicatedStorage:WaitForChild("Modules", 5)
        if not mods then return end
        local npc = mods:WaitForChild("NPCInteractions", 5)
        if not npc then return end
        local qf = npc:WaitForChild("QuestFunctions", 5)
        if not qf then return end
        QuestFunc = require(qf)
    end)
    local TweenToIsland = require("Island/TWEEN TO ISLAND")

    _G.LureFarm = false

    -- ================= CÀI ĐẶT FARM =================
    local CenterPoint = Vector3.new(7719.22, -2176.84, -17308.71)
    local SearchRadius = 150 
    local HoverHeight = 7.7
    local MoveSpeed = 65    
    local GatherWaitTime = 1.5 

    -- ================= CÀI ĐẶT AUTO QUEST =================
    local TargetMobName = "Fishman Karate User" 
    local QuestNPC_Pos =  Vector3.new(7731.41, -2175.84, -17222.65)
    local QuestName = "Becky" 
    -- ======================================================

    local TargetCFrame = nil
    local TaggedMobs = {}
    local GatherStartTime = 0 

    local isTakingQuest = false
    local isInteracting = false 
    local LastQuestCheck = 0
    local CurrentlyHasQuest = false
    local IsReadyToAttack = false

    local CurrentTargetMob = nil 
    local WaitUntil = 0 
    local LastHoverPos = nil

    local Events   = ReplicatedStorage:WaitForChild("Events", 5)
    local TakeStam = Events and Events:WaitForChild("takestam", 5)

    local isSpoofingStamina = false
    local function StartStaminaSpoof()
        if _G._ZiliStaminaSpoofing then return end
        _G._ZiliStaminaSpoofing = true
        isSpoofingStamina = true
        task.spawn(function()
            while isSpoofingStamina and _G._ZiliStaminaSpoofing and task.wait(0.05) do
                if TakeStam and TakeStam.Parent then
                    pcall(function() TakeStam:FireServer(0.545, "dash") end)
                else break end
            end
            _G._ZiliStaminaSpoofing = false
        end)
    end
    
    local function StopStaminaSpoof() isSpoofingStamina = false; _G._ZiliStaminaSpoofing = false end

    local function UnequipWeapons()
        pcall(function()
            local char = Player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    char.Humanoid:UnequipTools()
                end
            end
        end)
    end

    local function CheckAndEquipWeapon()
        local char = Player.Character
        if char and not char:FindFirstChildOfClass("Tool") then
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if tool:IsA("Tool") then 
                    char.Humanoid:EquipTool(tool)
                    break
                end
            end
        end
    end

    local function GetPlayerLevel()
        local lvl = 0
        pcall(function()
            local statsFolder = ReplicatedStorage:FindFirstChild("Stats" .. Player.Name)
            if statsFolder then
                local innerStats = statsFolder:FindFirstChild("Stats")
                if innerStats then
                    local levelObj = innerStats:FindFirstChild("Level")
                    if levelObj then
                        lvl = tonumber(levelObj.Value)
                        if not lvl or lvl == 0 then
                            lvl = tonumber(string.match(tostring(levelObj.Value), "%d+"))
                        end
                    end
                end
            end
        end)
        if not lvl or lvl == 0 then lvl = 190 end 
        return lvl
    end

    local function AutoClickUI(chatGui)
        pcall(function()
            if not chatGui:FindFirstChild("Frame") then return end
            
            local btns = {"go", "Go", "endChat", "Accept", "Yes", "Next", "Continue", "Okay", "Set", "Take"}
            for _, btnName in pairs(btns) do
                local btn = chatGui.Frame:FindFirstChild(btnName)
                if btn and btn.Visible and getconnections then
                    for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
                    for _, conn in pairs(getconnections(btn.Activated)) do pcall(function() conn:Fire() end) end
                end
            end

            for _, v in pairs(chatGui.Frame:GetDescendants()) do
                if v:IsA("TextButton") and v.Visible then
                    local txt = string.lower(v.Text)
                    if txt:match("yes") or txt:match("set") or txt:match("accept") or txt:match("sure") or txt:match("okay") or txt:match("next") or txt:match("continue") or txt:match("take") or txt:match("go") then
                        if getconnections then
                            for _, conn in pairs(getconnections(v.MouseButton1Click)) do conn:Fire() end
                            for _, conn in pairs(getconnections(v.Activated)) do pcall(function() conn:Fire() end) end
                        end
                    end
                end
            end
        end)
    end

    task.spawn(function()
        -- [FIX 5] WaitForChild có timeout, tránh treo nếu Events chưa load
        local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
        if not eventsFolder then return end
        local CombatRegister = eventsFolder:WaitForChild("CombatRegister", 10)
        if not CombatRegister then return end
        local currentCombo = 1 
        
        while true do
            -- [FIX 5] Khi farm tắt: nghỉ 0.5s rồi tiếp tục kiểm tra, không burn CPU
            if not _G.LureFarm then task.wait(0.5); continue end
            local attackDelay = 0.3 -- Tốc độ mặc định giữa các nhát chém
            
            if _G.LureFarm and not isTakingQuest and not isInteracting and IsReadyToAttack then
                local char = Player.Character
                if char and char:GetAttribute("SpawnLoaded") and not Player.PlayerGui:FindFirstChild("NPCCHAT") then
                    pcall(function()
                        CheckAndEquipWeapon() 
                        
                        local tool = char:FindFirstChildOfClass("Tool")
                        local weaponName = tool and tool.Name or "Melee"
                        
                        -- CHỈ CÓ ĐÒN 5 LÀ AIR (ĐỂ LẤY HIỆU ỨNG SLAM ĐẬP ĐẤT)
                        local state = (currentCombo == 5) and "Air" or "Ground"
                        local animFolder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild(weaponName) or ReplicatedStorage:WaitForChild("CombatAnimations"):WaitForChild("Melee")
                        local animName = (state == "Air") and "AirPunch"..currentCombo or "Punch"..currentCombo
                        local fakeAnim = animFolder:FindFirstChild(animName) or animFolder:GetChildren()[1]

                        local enemiesToHit = {}
                        local primaryCFrame = nil
                        
                        -- TÌM QUÁI
                        if CurrentTargetMob then
                            table.insert(enemiesToHit, CurrentTargetMob.PrimaryPart)
                            primaryCFrame = CurrentTargetMob.PrimaryPart.CFrame
                        else
                            local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
                            for _, m in pairs(folder:GetChildren()) do
                                if m.Name:match(TargetMobName) and m:IsA("Model") and m.PrimaryPart and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                                    if (m.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude <= 30 then 
                                        table.insert(enemiesToHit, m.PrimaryPart) 
                                        if not primaryCFrame then primaryCFrame = m.PrimaryPart.CFrame end
                                    end
                                end
                            end
                        end

                        if #enemiesToHit > 0 then
                            -- Bắn lệnh vung vũ khí
                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({
                                        [1] = "swingsfx",
                                        [2] = weaponName,
                                        [3] = currentCombo,
                                        [4] = state,
                                        [5] = false,
                                        [6] = fakeAnim,
                                        [7] = 2,
                                        [8] = 1.5
                                    })
                                end)
                            end)

                            -- Bắn lệnh gây sát thương
                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({
                                        [1] = "damage",
                                        [2] = enemiesToHit,
                                        [3] = weaponName,
                                        [4] = { [1] = currentCombo, [2] = state, [3] = weaponName },
                                        [5] = true,
                                        [6] = primaryCFrame,
                                        ["aircombo"] = state
                                    })
                                end)
                            end)

                            -- XỬ LÝ NHỊP ĐÁNH (CHỐNG BỊ SERVER KHÓA SÁT THƯƠNG)
                            if currentCombo == 5 then
                                attackDelay = 0.7 -- Nhát 5 (Slam) xong phải nghỉ xả hơi một chút như người thật
                                currentCombo = 1  -- Reset lại combo
                            else
                                currentCombo = currentCombo + 1
                            end
                        end
                    end)
                end
            else
                currentCombo = 1
            end
            
            -- Chờ theo thời gian đã tính toán ở trên
            task.wait(attackDelay) 
        end
    end)

    local function CheckQuestStatus()
        local hasQuest = false
        pcall(function()
            local statsFolder = ReplicatedStorage:FindFirstChild("Stats" .. Player.Name)
            if statsFolder then
                local questFolder = statsFolder:FindFirstChild("Quest")
                if questFolder and questFolder:FindFirstChild("CurrentQuest") then
                    local cq = tostring(questFolder.CurrentQuest.Value):gsub("%s+", ""):lower()
                    if cq ~= "" and cq ~= "none" and cq ~= "nil" and cq ~= "0" then
                        hasQuest = true
                        return
                    end
                end
                
                local innerStats = statsFolder:FindFirstChild("Stats")
                if innerStats then
                    local innerQuest = innerStats:FindFirstChild("Quest")
                    if innerQuest and innerQuest:FindFirstChild("CurrentQuest") then
                        local cq = tostring(innerQuest.CurrentQuest.Value):gsub("%s+", ""):lower()
                        if cq ~= "" and cq ~= "none" and cq ~= "nil" and cq ~= "0" then
                            hasQuest = true
                        end
                    end
                end
            end
        end)
        return hasQuest
    end

    local function StopAttacking()
        IsReadyToAttack = false
        _G.HoldingBlockKey = false
        _G.blocking = false
        _G.canuse = false 
        _G.midM1 = false
    end

    local function ForceClearStun()
        pcall(function()
            local char = Player.Character
            if char then
                _G.canuse = true
                if char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = 16
                end
                for _, v in pairs(char:GetChildren()) do
                    if v:IsA("ObjectValue") and (v.Name == "Value" or v.Name == "Stun" or v.Name == "Action") then
                        v:Destroy()
                    end
                end
            end
        end)
    end

    local function GetLureTarget()
        if tick() < WaitUntil then return "WAITING" end

        if CurrentTargetMob and CurrentTargetMob.Parent and CurrentTargetMob:FindFirstChild("Humanoid") then
            local hum = CurrentTargetMob.Humanoid
            if hum.Health < hum.MaxHealth and hum.Health > 0 then
                WaitUntil = tick() + 1.5
                CurrentTargetMob = nil
                return "WAITING"
            end
        end

        local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
        local bestMob, minDist = nil, math.huge
        local rootPos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position or CenterPoint
        
        for _, v in pairs(folder:GetChildren()) do
            if v.Name:match(TargetMobName) and v:IsA("Model") and v.PrimaryPart and v:FindFirstChild("Humanoid") then
                if v.Humanoid.Health > 0 and v.Humanoid.Health == v.Humanoid.MaxHealth then
                    local distToCenter = (v.PrimaryPart.Position - CenterPoint).Magnitude
                    if distToCenter <= SearchRadius then
                        local distToPlayer = (v.PrimaryPart.Position - rootPos).Magnitude
                        if distToPlayer < minDist then
                            minDist = distToPlayer
                            bestMob = v
                        end
                    end
                end
            end
        end
        
        CurrentTargetMob = bestMob
        return bestMob
    end

    task.spawn(function()
        while true do
            if _G.LureFarm then
            pcall(function()
                local char = Player.Character
                if not char then return end
                
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")

                if not root or not hum or hum.Health <= 0 then
                    TargetCFrame = nil 
                    isTakingQuest = false
                    isInteracting = false
                    return
                end

                if not char:GetAttribute("SpawnLoaded") then
                    TargetCFrame = nil
                    StopAttacking()
                    task.wait(5) 
                    
                    if char and char.Parent and hum.Health > 0 then
                        char:SetAttribute("SpawnLoaded", true)
                    end
                    return 
                end

                local isFarFromIsland = (root.Position.Y > -1000) or ((root.Position - CenterPoint).Magnitude > 600)
                if isFarFromIsland then
                    StopAttacking()
                    UnequipWeapons()
                    TargetCFrame = nil 
                    if not TweenToIsland.IsTeleporting then
                        if root.Position.Y > -1000 then
                            TweenToIsland.Start(Vector3.new(1791.87, -94.83, -12327.67)) 
                        else
                            TweenToIsland.Start(CenterPoint) 
                        end
                    end
                    return
                else
                    if TweenToIsland.IsTeleporting then TweenToIsland.Stop() end
                end
                
                local currentLvl = GetPlayerLevel()

                if not _G.AlreadySetFishmanSpawn then
                    local SetSpawnCoords = Vector3.new(7974.69, -2152.84, -17074.41)
                    local distToIsland = (root.Position - CenterPoint).Magnitude
                    
                    if distToIsland < 2000 then
                        StopAttacking()
                        UnequipWeapons()
                        
                        local standPos = SetSpawnCoords + Vector3.new(0, 0, 4)
                        TargetCFrame = CFrame.new(standPos, SetSpawnCoords)
                        
                        if (root.Position - standPos).Magnitude < 6 then
                            TargetCFrame = nil
                            
                            local targetPrompt = nil
                            local waitForNpc = tick()
                            
                            while tick() - waitForNpc < 15 do
                                root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                pcall(function() root.RotVelocity = Vector3.new(0,0,0) end)
                                
                                for _, prompt in pairs(workspace:GetDescendants()) do
                                    if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
                                        if (prompt.Parent.Position - SetSpawnCoords).Magnitude <= 20 then
                                            targetPrompt = prompt
                                            break
                                        end
                                    end
                                end
                                if targetPrompt then break end 
                                task.wait(0.5)
                            end
                            
                            if targetPrompt then
                                fireproximityprompt(targetPrompt)
                                
                                local waitAppear = tick()
                                while tick() - waitAppear < 3 do
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end
                                
                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 do 
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    
                                    local chatGui = Player.PlayerGui:FindFirstChild("NPCCHAT")
                                    if not chatGui then break end 
                                    
                                    AutoClickUI(chatGui)
                                    task.wait(0.4) 
                                end
                                
                                _G.AlreadySetFishmanSpawn = true
                                TargetCFrame = nil
                                task.wait(2)
                            end
                        end
                        return 
                    end
                end
                
                if tick() - LastQuestCheck > 2 then
                    LastQuestCheck = tick()
                    CurrentlyHasQuest = CheckQuestStatus()
                end

                if currentLvl >= 190 then
                    if not CurrentlyHasQuest and not isTakingQuest then
                        isTakingQuest = true
                    end
                else
                    isTakingQuest = false 
                end

                if isTakingQuest then
                    StopAttacking() 
                    local currentPos = root.Position
                    
                    if not isInteracting then
                        local standPos = QuestNPC_Pos + Vector3.new(0, 0, 4) 
                        TargetCFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                        
                        local distToNPC = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(standPos.X, 0, standPos.Z)).Magnitude
                        
                        if distToNPC <= 4 and math.abs(currentPos.Y - standPos.Y) <= 15 then
                            isInteracting = true 
                            TargetCFrame = nil   
                            
                            UnequipWeapons()
                            task.wait(0.2) 
                            
                            pcall(function() QuestFunc:QuestHandle(QuestName, "takequest") end)
                            
                            pcall(function()
                                for _, prompt in pairs(workspace:GetDescendants()) do
                                    if prompt:IsA("ProximityPrompt") then
                                        if prompt.Parent and (prompt.Parent.Position - root.Position).Magnitude <= 20 then
                                            fireproximityprompt(prompt)
                                        end
                                    end
                                end
                            end)
                            
                            local waitAppear = tick()
                            while tick() - waitAppear < 2 do
                                root.CFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                                pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                task.wait(0.2)
                            end
                            
                            local waitChatClose = tick()
                            while tick() - waitChatClose < 8 do 
                                root.CFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                                pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                
                                local chatGui = Player.PlayerGui:FindFirstChild("NPCCHAT")
                                if not chatGui then break end 
                                
                                AutoClickUI(chatGui)
                                task.wait(0.3) 
                            end
                            
                            ForceClearStun()
                            CurrentlyHasQuest = CheckQuestStatus()
                            isInteracting = false
                            isTakingQuest = false 
                            LastQuestCheck = tick() 
                        end
                    end
                    return 
                end

                local mobToLure = GetLureTarget()
                
                if mobToLure == "WAITING" then
                    IsReadyToAttack = false
                    if LastHoverPos then
                        TargetCFrame = CFrame.new(LastHoverPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    end
                elseif mobToLure then
                    GatherStartTime = 0 
                    local targetPos = mobToLure.PrimaryPart.Position
                    local hoverPos = targetPos + Vector3.new(0, HoverHeight, 0)
                    LastHoverPos = hoverPos
                    TargetCFrame = CFrame.new(hoverPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    
                    local dist = (root.Position - hoverPos).Magnitude
                    if dist <= 6 then 
                        IsReadyToAttack = true
                    else
                        IsReadyToAttack = false
                    end
                else
                    LastHoverPos = nil
                    local centerHover = CenterPoint + Vector3.new(0, HoverHeight, 0)
                    TargetCFrame = CFrame.new(centerHover) * CFrame.Angles(math.rad(-90), 0, 0)
                    
                    local distToCenter = (root.Position - centerHover).Magnitude
                    if distToCenter <= 4 then
                        if GatherStartTime == 0 then GatherStartTime = tick() end
                        
                        if tick() - GatherStartTime >= GatherWaitTime then
                            local canAttack = false
                            local hasFullHpMob = false
                            
                            local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
                            for _, m in pairs(folder:GetChildren()) do
                                if m.Name:match(TargetMobName) and m:IsA("Model") and m.PrimaryPart and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                                    if m.Humanoid.Health == m.Humanoid.MaxHealth and (m.PrimaryPart.Position - CenterPoint).Magnitude <= SearchRadius then
                                        hasFullHpMob = true
                                    end
                                    
                                    if (m.PrimaryPart.Position - root.Position).Magnitude <= 30 then 
                                        canAttack = true
                                        TaggedMobs[m] = tick() 
                                    end
                                end
                            end
                            
                            if not hasFullHpMob then
                                IsReadyToAttack = canAttack
                            else
                                IsReadyToAttack = false 
                            end
                        else
                            IsReadyToAttack = false
                        end
                    else
                        GatherStartTime = 0
                        IsReadyToAttack = false
                    end
                end
            end)
            end
            task.wait(0.01) 
        end
    end)

    task.spawn(function()
        while true do
            if _G.LureFarm then 
            pcall(function()
                local char = Player.Character
                if not char then return end
                
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")

                if not root or not hum or hum.Health <= 0 or not char:GetAttribute("SpawnLoaded") or TweenToIsland.IsTeleporting then
                    if root then
                        local bv = root:FindFirstChild("FloatForce")
                        if bv then bv:Destroy() end
                    end
                    if hum then hum.PlatformStand = false end
                    return 
                end
                
                root.Anchored = false
                
                if isInteracting or Player.PlayerGui:FindFirstChild("NPCCHAT") then
                    hum.PlatformStand = false 
                    local bv = root:FindFirstChild("FloatForce")
                    if bv then bv:Destroy() end
                else
                    hum.PlatformStand = true 
                    local bv = root:FindFirstChild("FloatForce")
                    if not bv then
                        -- [FIX 7] LinearVelocity thay BodyVelocity deprecated
                        local attach = root:FindFirstChild("FloatForceAttach") or Instance.new("Attachment")
                        attach.Name = "FloatForceAttach"; attach.Parent = root
                        bv = Instance.new("LinearVelocity")
                        bv.Name = "FloatForce"; bv.MaxForce = math.huge
                        bv.VectorVelocity = Vector3.zero
                        bv.RelativeTo = Enum.ActuatorRelativeTo.World
                        bv.Attachment0 = attach; bv.Parent = root
                    end
                end

                local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
                if folder then
                    for _, v in pairs(folder:GetChildren()) do
                        if v.Name:match(TargetMobName) and v:IsA("Model") and v.PrimaryPart and v:FindFirstChild("Humanoid") then
                            if v.Humanoid.Health > 0 then
                                if v.PrimaryPart.Size.X < 25 then
                                    v.PrimaryPart.Size = Vector3.new(30, 30, 30) 
                                end
                                v.PrimaryPart.CanCollide = false
                            else
                                if TaggedMobs[v] then TaggedMobs[v] = nil end
                            end
                        end
                    end
                end
            end)
            end
            task.wait(1) 
        end
    end)

    RunService.Stepped:Connect(function()
        if _G.LureFarm then
            local char = Player.Character
            if char then
                local isTweening = TweenToIsland.IsTeleporting
                local isReadyToFarm = char:GetAttribute("SpawnLoaded") and not isInteracting
                
                if isTweening or isReadyToFarm then
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        if not _G.LureFarm then return end
        if TweenToIsland.IsTeleporting then return end 
        
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root and TargetCFrame and char:GetAttribute("SpawnLoaded") then
            local currentPos = root.Position
            local targetPos = TargetCFrame.Position
            local dist = (currentPos - targetPos).Magnitude
            
            if dist > 0.5 then
                local dir = (targetPos - currentPos).Unit
                local step = dir * MoveSpeed * dt
                
                if step.Magnitude >= dist then
                    root.CFrame = TargetCFrame
                else
                    root.CFrame = CFrame.new(currentPos + step) * TargetCFrame.Rotation
                end
            else
                root.CFrame = TargetCFrame
            end
        end
    end)

        function isLvlFarmOn.Toggle(state)
        _G.LureFarm = state
        if state then
            -- BẬT giả mạo Stamina khi bắt đầu farm để chống giật lùi (Rubberband)
            StartStaminaSpoof()
        else
            -- TẮT giả mạo Stamina khi ngừng farm
            StopStaminaSpoof()
            
            StopAttacking()
            UnequipWeapons()
            ForceClearStun() 
        if TweenToIsland.IsTeleporting then TweenToIsland.Stop() end
             local char = Player.Character
            if char then
                if char:FindFirstChild("HumanoidRootPart") then
                    local bv = char.HumanoidRootPart:FindFirstChild("FloatForce")
                     if bv then bv:Destroy() end
                    end
                    if char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
                    end
         end
     end

    return isLvlFarmOn
end

-- 📦 MODULE: AutoGetBuso.lua
__modules["Farm/AutoGetBuso"] = function()
    local isBusoFarmOn = {}
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager") 
    local VirtualUser = game:GetService("VirtualUser")
    local Workspace = game:GetService("Workspace")
    local Player = Players.LocalPlayer

    local CurrentBackpack = nil
    local AttackHandler = nil

    -- ✅ Có timeout + pcall, không treo nữa
local QuestFunc = nil
pcall(function()
    local mods = ReplicatedStorage:WaitForChild("Modules", 5)
    if not mods then return end
    local npc = mods:WaitForChild("NPCInteractions", 5)
    if not npc then return end
    local qf = npc:WaitForChild("QuestFunctions", 5)
    if not qf then return end
    QuestFunc = require(qf)
end)

    _G.BusoFarm = false

    -- ================= CÀI ĐẶT TỌA ĐỘ VÀ THÔNG SỐ =================
    local Zou_Spawn_Pos = Vector3.new(-3121.05, 11.73, -5256.59) 
    local Kori_Center = Vector3.new(-4441.97, 56.48, -2949.36)
    local ShellTown_Center = Vector3.new(-1337.18, 4.12, -5025.98)
    local Fishman_Portal = Vector3.new(8585.12, -2138.84, -17087.38) -- Cổng thoát đảo Người Cá

    local SearchRadius = 350 
    local HoverHeight = 10.2 
    local MoveSpeed = 90    
    local GatherWaitTime = 1.5 

    local TargetMobName = "Yeti" 
    local QuestNPC_Pos = Vector3.new(-4245.19, 169.48, -2990.06)
    local QuestName = "Ray" 

    -- ================= BIẾN TRẠNG THÁI =================
    local TargetCFrame = nil
    local GatherStartTime = 0 
    local IsReadyToAttack = false

    local isTakingQuest = false
    local isInteracting = false 
    local LastQuestCheck = 0
    local CurrentlyHasQuest = false
    local HasTakenQuest = false
    local HasSetZouSpawn = false
    local QuestFinished = false
    local IsExitingFishman = false -- Đang wiggle cổng thoát

    local CurrentTargetMob = nil 
    local WaitUntil = 0 
    local LastHoverPos = nil

    -- =====================================================================
    -- STAMINA SPOOF
    -- =====================================================================
    local Events   = ReplicatedStorage:WaitForChild("Events", 5)
    local TakeStam = Events and Events:WaitForChild("takestam", 5)

    local isSpoofingStamina = false
    local function StartStaminaSpoof()
        if _G._ZiliStaminaSpoofing then return end
        _G._ZiliStaminaSpoofing = true
        isSpoofingStamina = true
        task.spawn(function()
            while isSpoofingStamina and _G._ZiliStaminaSpoofing and task.wait(0.05) do
                if TakeStam and TakeStam.Parent then
                    pcall(function() TakeStam:FireServer(0.545, "dash") end)
                else break end
            end
            _G._ZiliStaminaSpoofing = false
        end)
    end
    local function StopStaminaSpoof() isSpoofingStamina = false; _G._ZiliStaminaSpoofing = false end

    -- =====================================================================
    -- ANTI-AFK & ANTI-SIT
    -- =====================================================================
    pcall(function()
        for _, conn in pairs(getconnections(Player.Idled)) do conn:Disable() end
    end)
    if _G.AntiAfkConnection then _G.AntiAfkConnection:Disconnect() end
    _G.AntiAfkConnection = Player.Idled:Connect(function()
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

    local function UnequipWeapons()
        pcall(function()
            local char = Player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then char.Humanoid:UnequipTools() end
            end
        end)
    end

    local function CheckAndEquipWeapon()
        local char = Player.Character
        if not char then return end
        if char:FindFirstChildOfClass("Tool") then return end 

        local bp = Player:FindFirstChild("Backpack")
        if not bp then return end

        local tools = bp:GetChildren()
        local weaponToEquip = nil

        for _, tool in pairs(tools) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:match("sword") or name:match("blade") or name:match("katana") or name:match("pipe") then
                    weaponToEquip = tool; break
                end
            end
        end

        if not weaponToEquip then
            for _, tool in pairs(tools) do
                if tool:IsA("Tool") and not tool.Name:lower():match("combat") and not tool.Name:lower():match("melee") then
                    weaponToEquip = tool; break
                end
            end
        end

        if not weaponToEquip then
            for _, tool in pairs(tools) do
                if tool:IsA("Tool") then weaponToEquip = tool; break end
            end
        end

        if weaponToEquip then char.Humanoid:EquipTool(weaponToEquip) end
    end

    local function AutoClickUI(chatGui)
        pcall(function()
            if not chatGui:FindFirstChild("Frame") then return end
            
            local btns = {"go", "Go", "endChat", "Accept", "Yes", "Next", "Continue", "Okay", "Set", "Take"}
            for _, btnName in pairs(btns) do
                local btn = chatGui.Frame:FindFirstChild(btnName)
                if btn and btn.Visible and getconnections then
                    for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
                    for _, conn in pairs(getconnections(btn.Activated)) do pcall(function() conn:Fire() end) end
                end
            end

            for _, v in pairs(chatGui.Frame:GetDescendants()) do
                if v:IsA("TextButton") and v.Visible then
                    local txt = string.lower(v.Text)
                    if txt:match("yes") or txt:match("set") or txt:match("accept") or txt:match("sure") or txt:match("okay") or txt:match("next") or txt:match("continue") or txt:match("take") or txt:match("go") then
                        if getconnections then
                            for _, conn in pairs(getconnections(v.MouseButton1Click)) do conn:Fire() end
                            for _, conn in pairs(getconnections(v.Activated)) do pcall(function() conn:Fire() end) end
                        end
                    end
                end
            end
        end)
    end

    local function CheckQuestStatus()
        local hasQuest = false
        pcall(function()
            local statsFolder = ReplicatedStorage:FindFirstChild("Stats" .. Player.Name)
            if statsFolder then
                local questFolder = statsFolder:FindFirstChild("Quest")
                if questFolder and questFolder:FindFirstChild("CurrentQuest") then
                    local cq = tostring(questFolder.CurrentQuest.Value):gsub("%s+", ""):lower()
                    if cq ~= "" and cq ~= "none" and cq ~= "nil" and cq ~= "0" then hasQuest = true return end
                end
            end
        end)
        return hasQuest
    end

    local function ForceClearStun()
        pcall(function()
            local char = Player.Character
            if not char then return end
            
            _G.canuse = true
            _G.midM1 = false
            _G.blocking = false
            
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                if hum.Sit then hum.Sit = false end
            end

            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BoolValue") then
                    local name = v.Name:lower()
                    if name:match("stun") or name:match("busy") or name:match("action") or name:match("ragdoll") or name:match("cant") or name:match("paralyze") or name:match("attack") or name:match("hit") then
                        if v.Value == true then v.Value = false end
                    end
                elseif v:IsA("NumberValue") or v:IsA("IntValue") then
                    local name = v.Name:lower()
                    if name:match("stun") or name:match("busy") then
                        if v.Value > 0 then v.Value = 0 end
                    end
                end
            end
        end)
    end

    local function StopAttacking()
        IsReadyToAttack = false
        _G.HoldingBlockKey = false
        _G.blocking = false
        _G.canuse = false 
        _G.midM1 = false
        pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
        
        task.spawn(function()
            pcall(function()
                local char = Player.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                local weaponName = tool and tool.Name or "Melee"
                ReplicatedStorage:WaitForChild("Events"):WaitForChild("Block"):InvokeServer(false, weaponName, false)
            end)
        end)
    end

    local function GetLureTarget()
        if tick() < WaitUntil then return "WAITING" end

        if CurrentTargetMob and CurrentTargetMob.Parent and CurrentTargetMob:FindFirstChild("Humanoid") then
            local hum = CurrentTargetMob.Humanoid
            if hum.Health < hum.MaxHealth and hum.Health > 0 then
                WaitUntil = tick() + 1.5 
                CurrentTargetMob = nil
                return "WAITING"
            end
        end

        local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
        local bestMob, minDist = nil, math.huge
        local rootPos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position or Kori_Center
        
        for _, v in pairs(folder:GetChildren()) do
            if string.find(v.Name, TargetMobName) and v:IsA("Model") and v.PrimaryPart and v:FindFirstChild("Humanoid") then
                if v.Humanoid.Health > 0 and v.Humanoid.Health == v.Humanoid.MaxHealth then
                    local distToCenter = (v.PrimaryPart.Position - Kori_Center).Magnitude
                    if distToCenter <= SearchRadius then
                        local distToPlayer = (v.PrimaryPart.Position - rootPos).Magnitude
                        if distToPlayer < minDist then
                            minDist = distToPlayer
                            bestMob = v
                        end
                    end
                end
            end
        end
        
        CurrentTargetMob = bestMob
        return bestMob
    end

    -- ================= LUỒNG TỔNG CỦA GAME =================
    task.spawn(function()
        while true do
            if _G.BusoFarm then
            pcall(function()
                local char = Player.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")

                if not root or not hum or hum.Health <= 0 then TargetCFrame = nil; isTakingQuest = false; isInteracting = false; return end

                if not char:GetAttribute("SpawnLoaded") then
                    TargetCFrame = nil; StopAttacking(); task.wait(5) 
                    if char and char.Parent and hum.Health > 0 then char:SetAttribute("SpawnLoaded", true) end
                    return 
                end

                if tick() - LastQuestCheck > 2 then
                    LastQuestCheck = tick(); CurrentlyHasQuest = CheckQuestStatus()
                end

                -- ================= [PHASE 0]: THOÁT ĐẢO NGƯỜI CÁ =================
                if root.Position.Y < -1000 then
                    StopAttacking(); UnequipWeapons()
                    local distToPortal = (root.Position - Fishman_Portal).Magnitude

                    if distToPortal > 20 then
                        -- Còn xa cổng, bay thẳng tới
                        IsExitingFishman = false
                        TargetCFrame = CFrame.new(Fishman_Portal)
                    elseif not IsExitingFishman then
                        -- Đã đến gần cổng, wiggle để kích hoạt teleport
                        IsExitingFishman = true
                        TargetCFrame = nil

                        task.spawn(function()
                            local toggle = 1
                            local waited = 0
                            while waited < 10 and _G.BusoFarm and root and root.Parent and root.Position.Y < -1000 do
                                root.CFrame = CFrame.new(
                                    Fishman_Portal.X + toggle,
                                    Fishman_Portal.Y,
                                    Fishman_Portal.Z + toggle
                                )
                                pcall(function() pcall(function() root.Velocity = Vector3.new(0,0,0) end) end)
                                toggle = toggle * -1
                                task.wait(0.3)
                                waited = waited + 0.3
                            end
                            IsExitingFishman = false
                        end)
                    end
                    return -- Chờ qua cổng mới xử lý tiếp
                end

                -- ================= [PHASE POST-QUEST]: VỀ SHELL TOWN =================
                if QuestFinished then
                    local SetSpawnCoords = ShellTown_Center
                    local targetRobo = nil
                    
                    if workspace:FindFirstChild("NPCs") then
                        for _, npc in pairs(workspace.NPCs:GetChildren()) do
                            if npc.Name == "Robo" and npc:FindFirstChild("HumanoidRootPart") then
                                if (npc.HumanoidRootPart.Position - ShellTown_Center).Magnitude <= 500 then
                                    SetSpawnCoords = npc.HumanoidRootPart.Position
                                    targetRobo = npc
                                    break
                                end
                            end
                        end
                    end

                    local distToShellTown = (root.Position - SetSpawnCoords).Magnitude
                    
                    if distToShellTown > 100 then
                        StopAttacking(); UnequipWeapons()
                        TargetCFrame = CFrame.new(SetSpawnCoords)
                        return
                    else
                        StopAttacking(); UnequipWeapons()
                        
                        local standPos = SetSpawnCoords + Vector3.new(0, 0, 4)
                        TargetCFrame = CFrame.new(standPos, SetSpawnCoords)
                        
                        if (root.Position - standPos).Magnitude < 6 then
                            TargetCFrame = nil
                            task.wait(3)
                            local targetPrompt = nil
                            local waitForNpc = tick()
                            
                            while tick() - waitForNpc < 15 do
                                root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                pcall(function() root.RotVelocity = Vector3.new(0,0,0) end)
                                
                                if targetRobo then
                                    for _, prompt in pairs(targetRobo:GetDescendants()) do
                                        if prompt:IsA("ProximityPrompt") then
                                            targetPrompt = prompt
                                            break
                                        end
                                    end
                                end
                                
                                if not targetPrompt then
                                    for _, prompt in pairs(workspace:GetDescendants()) do
                                        if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
                                            if (prompt.Parent.Position - SetSpawnCoords).Magnitude <= 10 then
                                                local model = prompt:FindFirstAncestorOfClass("Model")
                                                if model then
                                                    local mName = string.lower(model.Name)
                                                    if not (mName:match("compass") or mName:match("eternal")) then
                                                        targetPrompt = prompt; break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                if targetPrompt then break end 
                                task.wait(0.5)
                            end
                        
                            if targetPrompt then
                                fireproximityprompt(targetPrompt)
                                local waitAppear = tick()
                                while tick() - waitAppear < 3 do
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end
                                
                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 do 
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    local chatGui = Player.PlayerGui:FindFirstChild("NPCCHAT")
                                    if not chatGui then break end 
                                    AutoClickUI(chatGui)
                                    task.wait(0.4) 
                                end
                                
                                _G.BusoFarm = false
                                TargetCFrame = nil
                                StopAttacking(); UnequipWeapons()
                                pcall(function()
                                    if hum then hum.PlatformStand = false end
                                    local bv = root:FindFirstChild("FloatForce")
                                    if bv then bv:Destroy() end
                                end)
                                print("✅ Quest Done!!")
                                return
                            end
                        end
                        return 
                    end
                end

                -- ================= [PHASE 1]: ZOU SPAWN =================
                if not HasSetZouSpawn then
                    local SetSpawnCoords = Zou_Spawn_Pos
                    local targetRobo = nil
                    
                    if workspace:FindFirstChild("NPCs") then
                        for _, npc in pairs(workspace.NPCs:GetChildren()) do
                            if npc.Name == "Robo" and npc:FindFirstChild("HumanoidRootPart") then
                                if (npc.HumanoidRootPart.Position - Zou_Spawn_Pos).Magnitude <= 500 then
                                    SetSpawnCoords = npc.HumanoidRootPart.Position
                                    targetRobo = npc
                                    break
                                end
                            end
                        end
                    end

                    local distToZou = (root.Position - SetSpawnCoords).Magnitude
                    
                    if distToZou > 100 then
                        StopAttacking(); UnequipWeapons()
                        TargetCFrame = CFrame.new(SetSpawnCoords)
                        return
                    else
                        StopAttacking(); UnequipWeapons()
                        
                        local standPos = SetSpawnCoords + Vector3.new(0, 0, 4)
                        TargetCFrame = CFrame.new(standPos, SetSpawnCoords)
                        
                        if (root.Position - standPos).Magnitude < 6 then
                            TargetCFrame = nil
                            task.wait(3)
                            local targetPrompt = nil
                            local waitForNpc = tick()
                            
                            while tick() - waitForNpc < 15 do
                                root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                pcall(function() root.RotVelocity = Vector3.new(0,0,0) end)
                                
                                if targetRobo then
                                    for _, prompt in pairs(targetRobo:GetDescendants()) do
                                        if prompt:IsA("ProximityPrompt") then
                                            targetPrompt = prompt; break
                                        end
                                    end
                                end
                                
                                if not targetPrompt then
                                    for _, prompt in pairs(workspace:GetDescendants()) do
                                        if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent:IsA("BasePart") then
                                            if (prompt.Parent.Position - SetSpawnCoords).Magnitude <= 10 then
                                                local model = prompt:FindFirstAncestorOfClass("Model")
                                                if model then
                                                    local mName = string.lower(model.Name)
                                                    if not (mName:match("compass") or mName:match("eternal")) then
                                                        targetPrompt = prompt; break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                if targetPrompt then break end 
                                task.wait(0.5)
                            end
                       
                            if targetPrompt then
                                fireproximityprompt(targetPrompt)
                                local waitAppear = tick()
                                while tick() - waitAppear < 3 do
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end
                                
                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 do 
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    local chatGui = Player.PlayerGui:FindFirstChild("NPCCHAT")
                                    if not chatGui then break end 
                                    AutoClickUI(chatGui)
                                    task.wait(0.4) 
                                end
                                
                                HasSetZouSpawn = true
                                TargetCFrame = nil
                                task.wait(2)
                            end
                        end
                        return 
                    end
                end

                -- ================= [PHASE 2]: BAY THẲNG TỚI KORI =================
                local isFarFromIsland = (root.Position.Y < -500) or ((root.Position - Kori_Center).Magnitude > 300)
                if isFarFromIsland then
                    StopAttacking(); UnequipWeapons()
                    TargetCFrame = CFrame.new(Kori_Center)
                    return
                end
                
                -- ================= [PHASE 3]: CHECK VÀ LẤY QUEST =================
                if CurrentlyHasQuest then 
                    HasTakenQuest = true
                    isTakingQuest = false
                elseif HasTakenQuest and not CurrentlyHasQuest then 
                    HasTakenQuest = false
                    QuestFinished = true
                    return
                elseif not HasTakenQuest and not QuestFinished then 
                    isTakingQuest = true 
                end

                if isTakingQuest then
                    StopAttacking() 
                    local currentPos = root.Position
                    local standPos = QuestNPC_Pos + Vector3.new(0, 0, 4) 

                    local distToQuest = (currentPos - standPos).Magnitude
                    if distToQuest > 10 then
                        TargetCFrame = nil
                        root.CFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                        task.wait(0.1)
                        return
                    end

                    if not isInteracting then
                        TargetCFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                        local distToNPC = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(standPos.X, 0, standPos.Z)).Magnitude
                        
                        if distToNPC <= 6 and math.abs(currentPos.Y - standPos.Y) <= 15 then
                            isInteracting = true
                            TargetCFrame = nil 
                            
                            UnequipWeapons()
                            task.wait(0.2) 
                            pcall(function() QuestFunc:QuestHandle(QuestName, "takequest") end)
                            
                            pcall(function()
                                for _, prompt in pairs(workspace:GetDescendants()) do
                                    if prompt:IsA("ProximityPrompt") then
                                        if prompt.Parent and (prompt.Parent.Position - root.Position).Magnitude <= 20 then
                                            fireproximityprompt(prompt)
                                        end
                                    end
                                end
                            end)

                            local waitAppear = tick()
                            while tick() - waitAppear < 2 do
                                root.CFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                                pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                task.wait(0.2)
                            end

                            local waitChatClose = tick()
                            while tick() - waitChatClose < 8 do 
                                root.CFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                                pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                
                                local chatGui = Player.PlayerGui:FindFirstChild("NPCCHAT")
                                if not chatGui then break end 
                                AutoClickUI(chatGui)
                                task.wait(0.3) 
                            end
                            
                            ForceClearStun()
                            CurrentlyHasQuest = CheckQuestStatus()
                            isInteracting = false; isTakingQuest = false; LastQuestCheck = tick() 
                        end
                    end
                    return 
                end

                -- ================= [PHASE 4]: TÌM QUÁI VÀ GOM =================
                local mobToLure = GetLureTarget()
                
                if mobToLure == "WAITING" then
                    IsReadyToAttack = false
                    if LastHoverPos then
                        TargetCFrame = CFrame.new(LastHoverPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    end
                elseif mobToLure then
                    GatherStartTime = 0 
                    local targetPos = mobToLure.PrimaryPart.Position
                    local hoverPos = targetPos + Vector3.new(0, HoverHeight, 0)
                    LastHoverPos = hoverPos
                    TargetCFrame = CFrame.new(hoverPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    
                    local dist = (root.Position - hoverPos).Magnitude
                    if dist <= 15 then 
                        IsReadyToAttack = true
                    else
                        IsReadyToAttack = false
                    end
                else
                    LastHoverPos = nil
                    local centerHover = Kori_Center + Vector3.new(0, HoverHeight, 0)
                    TargetCFrame = CFrame.new(centerHover) * CFrame.Angles(math.rad(-90), 0, 0)
                    
                    local distToCenter = (root.Position - centerHover).Magnitude
                    if distToCenter <= 4 then
                        if GatherStartTime == 0 then GatherStartTime = tick() end
                        
                        if tick() - GatherStartTime >= GatherWaitTime then
                            local canAttack = false
                            local hasFullHpMob = false
                            
                            local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
                            for _, m in pairs(folder:GetChildren()) do
                                if m.Name:match(TargetMobName) and m:IsA("Model") and m.PrimaryPart and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                                    if m.Humanoid.Health == m.Humanoid.MaxHealth and (m.PrimaryPart.Position - Kori_Center).Magnitude <= SearchRadius then
                                        hasFullHpMob = true
                                    end
                                    if (m.PrimaryPart.Position - root.Position).Magnitude <= 35 then 
                                        canAttack = true
                                    end
                                end
                            end
                            
                            if not hasFullHpMob or canAttack then
                                IsReadyToAttack = canAttack
                            else
                                IsReadyToAttack = false 
                            end
                        else
                            IsReadyToAttack = false
                        end
                    else
                        GatherStartTime = 0
                        IsReadyToAttack = false
                    end
                end
            end)
            end
            task.wait(0.01) 
        end
    end)

    -- ================= VÒNG LẶP CHIẾN ĐẤU =================
    task.spawn(function()
        local CombatRegister = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
        local BlockEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Block")
        local currentCombo = 1 
        
        while true do
            local attackDelay = 0.43 
            
            if _G.BusoFarm and not isTakingQuest and not isInteracting and IsReadyToAttack then
                local char = Player.Character
                if char and char:GetAttribute("SpawnLoaded") and not Player.PlayerGui:FindFirstChild("NPCCHAT") then
                    pcall(function()
                        CheckAndEquipWeapon() 
                        
                        local tool = char:FindFirstChildOfClass("Tool")
                        local weaponName = tool and tool.Name or "Melee"
                        
                        task.spawn(function() pcall(function() BlockEvent:InvokeServer(true, weaponName, false) end) end)
                        
                        local state = (currentCombo == 5) and "Air" or "Ground"
                        local animFolder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild(weaponName) or ReplicatedStorage:WaitForChild("CombatAnimations"):WaitForChild("Melee")
                        local animName = (state == "Air") and "AirPunch"..currentCombo or "Punch"..currentCombo
                        local fakeAnim = animFolder:FindFirstChild(animName) or animFolder:GetChildren()[1]

                        local enemiesToHit = {}
                        local primaryCFrame = nil
                        
                        if CurrentTargetMob then
                            table.insert(enemiesToHit, CurrentTargetMob.PrimaryPart)
                            primaryCFrame = CurrentTargetMob.PrimaryPart.CFrame
                        else
                            local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
                            for _, m in pairs(folder:GetChildren()) do
                                if m.Name:match(TargetMobName) and m:IsA("Model") and m.PrimaryPart and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                                    if (m.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude <= 35 then 
                                        table.insert(enemiesToHit, m.PrimaryPart) 
                                        if not primaryCFrame then primaryCFrame = m.PrimaryPart.CFrame end
                                    end
                                end
                            end
                        end

                        if #enemiesToHit > 0 then
                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({[1]="swingsfx", [2]=weaponName, [3]=currentCombo, [4]=state, [5]=false, [6]=fakeAnim, [7]=2, [8]=1.5})
                                end)
                            end)

                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({[1]="damage", [2]=enemiesToHit, [3]=weaponName, [4]={[1]=currentCombo, [2]=state, [3]=weaponName}, [5]=true, [6]=primaryCFrame, ["aircombo"]=state})
                                end)
                            end)

                            if currentCombo == 5 then
                                attackDelay = 0.7 
                                currentCombo = 1  
                            else
                                currentCombo = currentCombo + 1
                            end
                        end
                    end)
                end
            else
                currentCombo = 1
                task.spawn(function()
                    pcall(function()
                        local char = Player.Character
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        local weaponName = tool and tool.Name or "Melee"
                        BlockEvent:InvokeServer(false, weaponName, false)
                    end)
                end)
            end
            task.wait(attackDelay) 
        end
    end)

    task.spawn(function()
        while true do
            if _G.BusoFarm then 
            pcall(function()
                local char = Player.Character
                if not char then return end
                
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")

                if not root or not hum or hum.Health <= 0 or not char:GetAttribute("SpawnLoaded") then
                    if root then
                        local bv = root:FindFirstChild("FloatForce")
                        if bv then bv:Destroy() end
                    end
                    if hum then hum.PlatformStand = false end
                    return 
                end
                
                root.Anchored = false
                
                if isInteracting or Player.PlayerGui:FindFirstChild("NPCCHAT") then
                    hum.PlatformStand = false 
                    local bv = root:FindFirstChild("FloatForce")
                    if bv then bv:Destroy() end
                else
                    hum.PlatformStand = true 
                    local bv = root:FindFirstChild("FloatForce")
                    if not bv then
                        local attach = root:FindFirstChild("FloatForceAttach") or Instance.new("Attachment")
                        attach.Name = "FloatForceAttach"; attach.Parent = root
                        bv = Instance.new("LinearVelocity")
                        bv.Name = "FloatForce"; bv.MaxForce = math.huge
                        bv.VectorVelocity = Vector3.zero
                        bv.RelativeTo = Enum.ActuatorRelativeTo.World
                        bv.Attachment0 = attach; bv.Parent = root
                    end
                end

                local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mob") or workspace:FindFirstChild("NPCs") or workspace
                if folder then
                    for _, v in pairs(folder:GetChildren()) do
                        if string.find(v.Name, TargetMobName) and v:IsA("Model") and v.PrimaryPart and v:FindFirstChild("Humanoid") then
                            if v.Humanoid.Health > 0 then
                                if v.PrimaryPart.Size.X < 25 then v.PrimaryPart.Size = Vector3.new(30, 30, 30) end
                                v.PrimaryPart.CanCollide = false
                            end
                        end
                    end
                end
            end)
            end
            task.wait(1) 
        end
    end)

    RunService.Stepped:Connect(function()
        if _G.BusoFarm then
            local char = Player.Character
            if char then
                ForceClearStun()
                local isReadyToFarm = char:GetAttribute("SpawnLoaded") and not isInteracting
                
                if isReadyToFarm then
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                    end
                end
            end
        end
    end)

    -- ================= HEARTBEAT: DI CHUYỂN + QUẢN LÝ STAMINA SPOOF =================
    RunService.Heartbeat:Connect(function(dt)
        if not _G.BusoFarm then
            if isSpoofingStamina then StopStaminaSpoof() end
            return
        end
        
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root and TargetCFrame and char:GetAttribute("SpawnLoaded") then
            StartStaminaSpoof()

            local currentPos = root.Position
            local targetPos = TargetCFrame.Position
            local dist = (currentPos - targetPos).Magnitude
            
            if dist > 0.5 then
                local dir = (targetPos - currentPos).Unit
                local step = dir * MoveSpeed * dt
                if step.Magnitude >= dist then root.CFrame = TargetCFrame
                else root.CFrame = CFrame.new(currentPos + step) * TargetCFrame.Rotation end
            else
                root.CFrame = TargetCFrame
            end
        else
            if isSpoofingStamina then StopStaminaSpoof() end
        end
    end)

    function isBusoFarmOn.Toggle(state)
        _G.BusoFarm = state
        if not state then
            StopStaminaSpoof()
            StopAttacking()
            UnequipWeapons()
            ForceClearStun() 
            IsExitingFishman = false
            
            local char = Player.Character
            if char then
                if char:FindFirstChild("HumanoidRootPart") then
                    local bv = char.HumanoidRootPart:FindFirstChild("FloatForce")
                    if bv then bv:Destroy() end
                end
                if char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
            end
            HasTakenQuest = false; HasSetZouSpawn = false; CurrentTargetMob = nil; QuestFinished = false
        else
            HasSetZouSpawn = false 
            CurrentlyHasQuest = CheckQuestStatus()
            if CurrentlyHasQuest then HasTakenQuest = true; isTakingQuest = false end
        end
    end

    return isBusoFarmOn
end

-- 📦 MODULE: AutoGeppo.lua (FIX LỖI ĐỨNG IM & TỐI ƯU HOÀN TOÀN)
__modules["Farm/AutoGeppo"] = function()
    local AutoGeppoModule = {}
    
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")
    local LocalPlayer = Players.LocalPlayer

    _G.AutoGeppo = false

    -- Tọa độ YI trên Coco Island
    local Target_Pos = Vector3.new(-3086.87, 94.54, -11755.48) 
    -- Tọa độ Cổng TP Người Cá
    local Fishman_Portal = Vector3.new(8585.12, -2138.84, -17087.38)

    -- TẠO NỀN ẢO TỐI ƯU CHO LAG/MINIMIZE (Size bự 25x2x25)
    local FakeFloor = Instance.new("Part")
    FakeFloor.Name = "Geppo_FakeFloor"
    FakeFloor.Size = Vector3.new(25, 2, 25)
    FakeFloor.Anchored = true
    FakeFloor.CanCollide = true
    FakeFloor.Transparency = 1
    FakeFloor.Parent = nil

    -- BIẾN QUẢN LÝ TWEEN NỘI BỘ (Chống Memory Leak)
    local TweenConn = nil
    local IsTweening = false
    local IsDropping = false

    -- =====================================================================
    -- STAMINA SPOOF (chỉ chạy khi đang tween/dropping)
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
                    pcall(function() TakeStam:FireServer(0.545, "dash") end)
                else break end
            end
        end)
    end
    local function StopStaminaSpoof() isSpoofingStamina = false end

    -- =====================================================================
    -- ANTI-AFK & ANTI-SIT
    -- =====================================================================
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do conn:Disable() end
    end)
    if _G.AntiAfkConnection then _G.AntiAfkConnection:Disconnect() end
    _G.AntiAfkConnection = LocalPlayer.Idled:Connect(function()
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

    -- =========================================
    -- HỆ THỐNG TWEEN BAY MƯỢT TRỰC TIẾP
    -- =========================================
    local function StopTween()
        IsTweening = false
        IsDropping = false
        StopStaminaSpoof() -- 🛑 Dừng spoof khi dừng tween
        if TweenConn then 
            TweenConn:Disconnect()
            TweenConn = nil 
        end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            for _, v in pairs(root:GetChildren()) do 
                if v.Name == "ZILI_AntiGravity" then v:Destroy() end 
            end
            pcall(function() pcall(function() root.Velocity = Vector3.new(0,0,0) end) end)
        end
        if FakeFloor.Parent then FakeFloor.Parent = nil end
    end

    local function StartTween(targetPos, isPortal)
        if IsTweening or IsDropping then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        IsTweening = true
        StartStaminaSpoof() -- ▶️ Bắt đầu spoof khi bắt đầu tween
        FakeFloor.Parent = Workspace

        local antiGravity = root:FindFirstChild("ZILI_AntiGravity")
        if not antiGravity then
            local attach = root:FindFirstChild("ZILI_AntiGravityAttach") or Instance.new("Attachment")
            attach.Name = "ZILI_AntiGravityAttach"; attach.Parent = root
            antiGravity = Instance.new("LinearVelocity")
            antiGravity.Name = "ZILI_AntiGravity"; antiGravity.MaxForce = math.huge
            antiGravity.VectorVelocity = Vector3.zero
            antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World
            antiGravity.Attachment0 = attach; antiGravity.Parent = root
        end

        local MAX_SPEED = 90
        local flyTarget = Vector3.new(targetPos.X, targetPos.Y + 30, targetPos.Z)
        local isDiving = false 

        TweenConn = RunService.Heartbeat:Connect(function(deltaTime)
            if not IsTweening or not root or not root.Parent then StopTween(); return end
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then 
                    part.CanCollide = false 
                end
            end

            FakeFloor.CFrame = root.CFrame * CFrame.new(0, -3.2, 0) 
            pcall(function() pcall(function() root.Velocity = Vector3.new(0,0,0) end) end)

            local currentPos = root.Position
            local activeTarget = isDiving and targetPos or flyTarget
            
            local distXZ = (Vector2.new(activeTarget.X, activeTarget.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude
            local dist3D = (activeTarget - currentPos).Magnitude

            local max_step = MAX_SPEED * deltaTime
            if max_step > 150 then max_step = 150 end 
            local step = math.min(max_step, dist3D)

            if not isDiving then
                if distXZ < 15 then 
                    isDiving = true
                else
                    local dir = (activeTarget - currentPos).Unit
                    root.CFrame = CFrame.lookAt(currentPos + dir * step, activeTarget)
                end
            else
                if dist3D < 3 then 
                    if isPortal then
                        IsTweening = false
                        if TweenConn then TweenConn:Disconnect(); TweenConn = nil end
                        IsDropping = true
                        -- Spoof vẫn giữ chạy trong lúc dropping
                        
                        task.spawn(function()
                            local waited = 0
                            while waited < 4 do
                                if not root or not root.Parent or not _G.AutoGeppo then break end
                                root.CFrame = root.CFrame * CFrame.new(0, -0.5, 0)
                                pcall(function() pcall(function() root.Velocity = Vector3.new(0,0,0) end) end)
                                task.wait(0.5)
                                waited = waited + 0.5
                            end
                            StopTween() -- 🛑 Xong drop mới dừng spoof
                        end)
                    else
                        StopTween() -- 🛑 Đến đích bình thường, dừng spoof
                        if root and root.Parent then root.CFrame = CFrame.new(targetPos) end
                    end
                else
                    local dir = (activeTarget - currentPos).Unit
                    root.CFrame = CFrame.lookAt(currentPos + dir * step, activeTarget)
                end
            end
        end)
    end

    -- =========================================
    -- HÀM TỰ ĐỘNG CLICK GUI CHAT
    -- =========================================
    local function AutoClickUI(chatGui)
        pcall(function()
            if not chatGui:FindFirstChild("Frame") then return end
            
            local btns = {"go", "Go", "endChat", "Accept", "Yes", "Next", "Continue", "Okay", "Set", "Take", "Learn", "Buy"}
            for _, btnName in pairs(btns) do
                local btn = chatGui.Frame:FindFirstChild(btnName)
                if btn and btn.Visible and getconnections then
                    for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
                    for _, conn in pairs(getconnections(btn.Activated)) do pcall(function() conn:Fire() end) end
                end
            end

            for _, v in pairs(chatGui.Frame:GetDescendants()) do
                if v:IsA("TextButton") and v.Visible then
                    local txt = string.lower(v.Text)
                    if txt:match("yes") or txt:match("set") or txt:match("accept") or txt:match("sure") or txt:match("okay") or txt:match("next") or txt:match("continue") or txt:match("take") or txt:match("go") or txt:match("learn") or txt:match("buy") then
                        if getconnections then
                            for _, conn in pairs(getconnections(v.MouseButton1Click)) do conn:Fire() end
                            for _, conn in pairs(getconnections(v.Activated)) do pcall(function() conn:Fire() end) end
                        end
                    end
                end
            end
        end)
    end

    -- =========================================
    -- VÒNG LẶP XỬ LÝ CHÍNH
    -- =========================================
    task.spawn(function()
        while true do
            if _G.AutoGeppo then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local root = char.HumanoidRootPart
                        local currentPos = root.Position
                        
                        -- 1. DETECTED ĐANG Ở DƯỚI ĐẢO NGƯỜI CÁ
                        if currentPos.Y < -1000 and Target_Pos.Y > -500 then
                            local distToPortal = (currentPos - Fishman_Portal).Magnitude
                            
                            if distToPortal > 15 then
                                if not IsTweening and not IsDropping then
                                    StartTween(Fishman_Portal, true)
                                end
                            end
                            return
                        end

                        -- 2. BAY ĐẾN NPC MUA GEPPO (Khi đã ngoi lên trên)
                        if not IsDropping then
                            local dist = (currentPos - Target_Pos).Magnitude
                            if dist > 20 then
                                if not IsTweening then
                                    StartTween(Target_Pos, false)
                                end
                            else
                                -- ĐÃ TỚI NƠI
                                if IsTweening then StopTween() end
                                
                                local standPos = Target_Pos + Vector3.new(0, 0, 4) 
                                local lookAtPos = Vector3.new(Target_Pos.X, standPos.Y, Target_Pos.Z)
                                
                                pcall(function()
                                    for _, prompt in pairs(Workspace:GetDescendants()) do
                                        if prompt:IsA("ProximityPrompt") then
                                            if prompt.Parent and (prompt.Parent.Position - root.Position).Magnitude <= 20 then
                                                fireproximityprompt(prompt)
                                            end
                                        end
                                    end
                                end)

                                local waitAppear = tick()
                                while tick() - waitAppear < 2 and _G.AutoGeppo do
                                    root.CFrame = CFrame.lookAt(standPos, lookAtPos)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    if LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end

                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 and _G.AutoGeppo do 
                                    root.CFrame = CFrame.lookAt(standPos, lookAtPos)
                                    pcall(function() root.Velocity = Vector3.new(0,0,0) end)
                                    
                                    local chatGui = LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT")
                                    if not chatGui then break end 
                                    
                                    AutoClickUI(chatGui)
                                    task.wait(0.3) 
                                end
                                
                                task.wait(0.5)
                                
                                pcall(function()
                                    local args = { [1] = "skyWalkTrainer" }
                                    ReplicatedStorage:WaitForChild("Events"):WaitForChild("learnStyle"):FireServer(table.unpack(args))
                                end)
                                
                                AutoGeppoModule.Toggle(false)
                            end
                        end
                    end
                end)
            else
                if IsTweening or IsDropping then StopTween() end
            end
            task.wait(0.1)
        end
    end)

    -- HÀM BẬT/TẮT TỪ GIAO DIỆN
    function AutoGeppoModule.Toggle(state)
        _G.AutoGeppo = state
        if not state then
            StopTween() -- StopTween đã gọi StopStaminaSpoof bên trong rồi
        end
    end

    return AutoGeppoModule
end

-- 📦 MODULE: Farm/AutoFishMerchant
__modules["Farm/AutoFishMerchant"] = function()
    local AutoFishMerchant = {}

    -- =====================================================================
    -- SERVICES
    -- =====================================================================
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local VirtualUser       = game:GetService("VirtualUser")
    local RunService        = game:GetService("RunService")
    local workspace         = game:GetService("Workspace")
    local LocalPlayer       = Players.LocalPlayer

    -- =====================================================================
    -- CONSTANTS
    -- =====================================================================
    local MAX_SPEED        = 90
    local VEC_ZERO         = Vector3.new(0, 0, 0)
    -- [FIX 1] -3.05 → -4.05: top surface = HRP.Y - 3.05, flush với chân nhân vật.
    -- FakeFloor dày 2 units → center ở -4.05, top ở -4.05+1 = -3.05 dưới HRP.
    -- HRP cách mặt đất ~3 units (flyY=7.33, ground Y≈4) → -3.05 vừa sát chân.
    local OFFSET_FAKEFLOOR = CFrame.new(0, -4.05, 0)
    local DT_CAP           = 0.08 

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
        -- "single" = craft từng bait một (Count=1 mỗi call, loop)
        -- "all"    = craft hết 1 lần (Count=floor(fishCount/2), 1 call)
        CraftRareMode = "single",
        EquipRod     = true,
        EquipTitle   = true,
        BuyBait      = false,
        SellCommon   = false,
        SellRare     = false,
        SellLeg      = false,
        AutoMerchant = false,
    }

    local ItemsToBuy = {}

    _G.AutoFishing           = false
    _G.TargetBait            = nil   
    _G.KnownMerchantPos      = nil
    _G.MerchantProcessed     = false
    _G.MerchantSpawnTime     = 0
    _G.LastShopRefreshPeriod = -1

    local _lastShopPeriod = -1

    -- =====================================================================
    -- ANTI-AFK & ANTI-SIT
    -- =====================================================================
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do conn:Disable() end
    end)
    if _G.AntiAfkConnection then _G.AntiAfkConnection:Disconnect() end
    _G.AntiAfkConnection = LocalPlayer.Idled:Connect(function()
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
    -- REMOTES & SPOOF
    -- =====================================================================
    local FishingRemote = ReplicatedStorage:WaitForChild("Fishing", 5)
    if FishingRemote then
        FishingRemote = FishingRemote:WaitForChild("Remotes", 5):WaitForChild("Action", 5)
    end

    local Events   = ReplicatedStorage:WaitForChild("Events", 5)
    local TakeStam = Events and Events:WaitForChild("takestam", 5)

    -- [OPTIMIZE] Cache hot-path remotes một lần, tránh WaitForChild lặp lại trong loop
    local ToolsRemote        = Events and Events:WaitForChild("Tools", 5)
    local TitlesRemote       = Events and Events:WaitForChild("Titles", 5)
    local FishingShopRemoteR = ReplicatedStorage:WaitForChild("FishingShopRemote", 5)
    local CraftingRemoteR    = ReplicatedStorage:WaitForChild("CraftingRemote", 5)

    local isSpoofingStamina = false
    local function StartStaminaSpoof()
        if isSpoofingStamina then return end
        isSpoofingStamina = true
        task.spawn(function()
            while isSpoofingStamina and task.wait(0.05) do
                if TakeStam and TakeStam.Parent then
                    pcall(function() TakeStam:FireServer(0.545, "dash") end)
                else break end
            end
        end)
    end
    local function StopStaminaSpoof() isSpoofingStamina = false end

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

    -- [OPTIMIZE] Cache folder chứa bobble sau lần tìm thấy đầu tiên.
    -- Tránh scan toàn bộ workspace:GetDescendants() mỗi 0.2s trong vòng lặp chờ câu.
    local _bobbleFolderCache = nil
    local function GetMyBobble()
        local myName = LocalPlayer.Name
        -- Fast path: chỉ scan folder đã cache (O(children) thay vì O(all descendants))
        if _bobbleFolderCache and _bobbleFolderCache.Parent then
            for _, obj in pairs(_bobbleFolderCache:GetChildren()) do
                if string.find(obj.Name, myName) and obj:GetAttribute("Caught") == true then
                    return obj
                end
            end
        end
        -- Fallback: scan đầy đủ, đồng thời cache folder nếu tìm được
        for _, area in pairs({workspace, LocalPlayer.Character}) do
            if area then
                for _, obj in pairs(area:GetDescendants()) do
                    if string.find(obj.Name, myName) and obj:GetAttribute("Caught") == true then
                        -- Cache parent folder (nếu không phải root area) cho các lần sau
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

    local function EquipPhysicalRod(rodName)
        local char = LocalPlayer.Character
        if not char then return false end
        if char:FindFirstChild(rodName) then return true end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack and backpack:FindFirstChild(rodName) then
            char.Humanoid:EquipTool(backpack[rodName])
            task.wait(0.3); return true
        end
        -- Rod is in JSON inventory but not spawned physically yet
        -- (GBO uses custom inventory — server equip via Tools remote already done)
        local inv = GetInventory()
        if inv and (inv[rodName] or 0) > 0 then return true end
        return false
    end

    local _rodBuyPos = Vector3.new(-1343.85, 4.12, -4979.27)
    local _justBoughtRod = false  -- flag → RunLoop sẽ continue sau khi mua rod

    local function BuyFishingRodIfNeeded(inventory)
        if not inventory then return end
        for _, rodName in ipairs(RodsPriority) do
            if (inventory[rodName] or 0) > 0 then _justBoughtRod = false; return end
        end
        -- Không có rod nào → mua Fishing Rod
        _justBoughtRod  = true
        _cachedRodName  = nil   -- bắt buộc reset cache để AutoEquipRodSilent gọi lại equip
        TweenToPosAndWait(_rodBuyPos)
        if not _G.AutoFishing then return end
        pcall(function()
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):InvokeServer(
                workspace:WaitForChild("BuyableItems"):WaitForChild("Fishing Rod"), 1
            )
        end)
        task.wait(3)   -- chờ server xử lý và cập nhật inventory JSON
    end

    local _cachedRodName = nil
    local function AutoEquipRodSilent()
        local inventory = GetInventory()
        if not inventory then return _cachedRodName end
        for _, rodName in ipairs(RodsPriority) do
            if inventory[rodName] and inventory[rodName] > 0 then
                if rodName ~= _cachedRodName then
                    -- [OPTIMIZE] Dùng cached ToolsRemote thay vì WaitForChild mỗi lần
                    if ToolsRemote then
                        pcall(function() ToolsRemote:InvokeServer("equip", rodName) end)
                    end
                    _cachedRodName = rodName
                    task.wait(0.5) -- [SỬA LỖI LOGIC 3]: Đợi 0.5s cho Server bỏ cái cần mới vào Balo rồi mới chạy tiếp
                end
                return rodName
            end
        end
        _cachedRodName = nil
        return nil
    end

    -- [OPTIMIZE] Thêm guard _titleEquipping để tránh pile-up task khi RunLoop chạy
    -- nhanh hơn tổng thời gian equip (4 titles × 0.1s = 0.4s).
    local _titleEquipping = false
    local function AutoEquipTitleSilent()
        if _titleEquipping then return end
        _titleEquipping = true
        task.spawn(function()
            for _, titleName in ipairs(TitlesPriority) do
                -- [OPTIMIZE] Dùng cached TitlesRemote thay vì WaitForChild mỗi lần
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
        local preferred = _G.PreferredBait
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
    local Tween = { IsTeleporting = false, MoveConn = nil, NoclipConn = nil, FakeFloor = nil, _gen = 0 }

    function Tween.Stop()
        Tween.IsTeleporting = false
        Tween._gen = Tween._gen + 1   -- [FIX FPS] Invalidate mọi task.spawn cũ đang pending
        StopStaminaSpoof()
        if Tween.MoveConn   then Tween.MoveConn:Disconnect();   Tween.MoveConn   = nil end
        if Tween.NoclipConn then Tween.NoclipConn:Disconnect(); Tween.NoclipConn = nil end
        local root = getRoot()
        if root then
            root.Anchored = false 
            for _, v in pairs(root:GetChildren()) do
                if v.Name == "ZILI_AntiGravity" then v:Destroy() end
            end
            pcall(function() root.Velocity = VEC_ZERO end)
        end
        if Tween.FakeFloor then Tween.FakeFloor:Destroy(); Tween.FakeFloor = nil end
    end

    function Tween.Start(finalDest, onComplete, opts)
        opts = opts or {}
        Tween.Stop()
        Tween.IsTeleporting = true
        local myGen = Tween._gen   -- [FIX FPS] Snapshot generation của lần Start này
        StartStaminaSpoof()

        -- [OPTIMIZE] Cache danh sách BasePart của character, chỉ rebuild khi char đổi.
        -- Tránh gọi GetDescendants() mỗi frame Stepped (~60 lần/giây).
        local _noclipParts = {}
        local _noclipChar  = nil
        local function _rebuildNoclip(char)
            _noclipChar  = char
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
        -- [FIX] Backup noclip chạy theo task.wait, độc lập với RunService.Stepped.
        -- RunService.Stepped không chạy khi FPS < 5 hoặc game đang freeze (10-15s đơ).
        -- Loop này đảm bảo CanCollide = false vẫn được set dù game bị treo.
        -- [FIX FPS] Check thêm myGen == Tween._gen: khi Stop()->Start() xảy ra trong vòng
        -- 50ms, loop cũ đang task.wait(0.05) sẽ thấy gen đã đổi và thoát ngay, không leak.
        task.spawn(function()
            while Tween.IsTeleporting and myGen == Tween._gen do
                local char = LocalPlayer.Character
                if char then
                    if char ~= _noclipChar then _rebuildNoclip(char) end
                    for _, p in ipairs(_noclipParts) do
                        if p and p.Parent then p.CanCollide = false end
                    end
                    -- [FIX 2b] Backup loop update FakeFloor position, độc lập Heartbeat.
                    -- Khi FPS < 5 hoặc game freeze, Heartbeat ngưng → FakeFloor tụt lại
                    -- phía sau → server detect character lơ lửng → kick.
                    -- Loop task.wait này vẫn chạy (dù chậm hơn) khi Heartbeat ngưng.
                    local r = getRoot()
                    if r and Tween.FakeFloor and Tween.FakeFloor.Parent then
                        Tween.FakeFloor.CFrame = r.CFrame * OFFSET_FAKEFLOOR
                    end
                end
                task.wait(0.05)
            end
        end)

        local route       = {}
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
            pos         = finalDest,
            isPortal    = isPortalPos(finalDest),
            isFishmanIn = false, isFishmanExit = false,
            isMerchant  = opts.isMerchant or false,
        })

        local function flyTo(stepData, onStepComplete)
            -- [FIX] Disconnect MoveConn cũ TRƯỚC KHI tạo connection mới.
            -- Bug gốc: flyTo gọi đệ quy (retry high ping / Y-snap) ghi đè Tween.MoveConn
            -- mà không disconnect → connection cũ vẫn chạy ngầm → nhiều Heartbeat callbacks
            -- cùng lúc → CPU tăng mạnh, behavior lẫn lộn. Đặc biệt tệ ở high ping.
            if Tween.MoveConn then Tween.MoveConn:Disconnect(); Tween.MoveConn = nil end

            local root = getRoot()
            local wt = 0
            while not root and wt < 10 do task.wait(0.5); wt = wt + 0.5; root = getRoot() end
            if not Tween.IsTeleporting or not root then Tween.Stop(); return end

            if not Tween.FakeFloor then
                Tween.FakeFloor             = Instance.new("Part")
                Tween.FakeFloor.Name        = "ZILI_FakeFloor"
                Tween.FakeFloor.Size        = Vector3.new(15, 2, 15)
                Tween.FakeFloor.Anchored    = true
                Tween.FakeFloor.Transparency = 1
                Tween.FakeFloor.Parent      = workspace
            end

            local ag = root:FindFirstChild("ZILI_AntiGravity")
            if not ag then
                local attach = root:FindFirstChild("ZILI_AntiGravityAttach") or Instance.new("Attachment")
                attach.Name = "ZILI_AntiGravityAttach"; attach.Parent = root
                ag = Instance.new("LinearVelocity")
                ag.Name = "ZILI_AntiGravity"; ag.MaxForce = math.huge
                ag.VectorVelocity = Vector3.zero
                ag.RelativeTo = Enum.ActuatorRelativeTo.World
                ag.Attachment0 = attach; ag.Parent = root
            end
            local targetPos = stepData.pos

            local flyY
            if stepData.isMerchant then
                flyY = math.max(targetPos.Y, 4)
            elseif stepData.isFishmanIn or stepData.isFishmanExit then
                flyY = targetPos.Y
            else
                flyY = 7.33
            end

            -- [FIX] Watchdog: chạy song song, phát hiện stuck → force CFrame snap.
            -- Xử lý 3 trường hợp:
            --   • High ping: server liên tục kéo character về → bị stuck tại chỗ
            --   • FPS < 5: Heartbeat hiếm khi chạy → movement quá chậm / đứng yên
            --   • Freeze 10-15s: Heartbeat ngưng hoàn toàn → character không nhích
            -- Sau STALL_TIMEOUT giây không di chuyển đủ → snap thẳng đến target.
            local _watchDone    = false
            local _watchLastPos = root.Position
            -- [FIX 2a] 3 → 2s: phản ứng nhanh hơn khi freeze / FPS < 5
            local STALL_TIMEOUT = 2   -- giây không di chuyển → force snap
            task.spawn(function()
                while Tween.IsTeleporting and not _watchDone and myGen == Tween._gen do
                    task.wait(STALL_TIMEOUT)
                    if not Tween.IsTeleporting or _watchDone then break end
                    local curRoot = getRoot()
                    if not curRoot then break end
                    local curPos = curRoot.Position
                    -- Kiểm tra đã đến chưa — nếu rồi thì watchdog không cần làm gì
                    local distCheck = stepData.isMerchant
                        and (curPos - targetPos).Magnitude
                        or  (Vector2.new(curPos.X, curPos.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
                    if distCheck < (stepData.isMerchant and 25 or 30) then break end
                    -- Chưa đến: nếu chưa nhích đủ 3 units → force snap
                    if (curPos - _watchLastPos).Magnitude < 3 then
                        curRoot.CFrame = CFrame.new(targetPos.X, flyY, targetPos.Z)
                        if Tween.FakeFloor then
                            Tween.FakeFloor.CFrame = curRoot.CFrame * OFFSET_FAKEFLOOR
                        end
                        -- Reset LinearVelocity để xóa inertia cũ sau snap
                        local ag2 = curRoot:FindFirstChild("ZILI_AntiGravity")
                        if ag2 and ag2:IsA("LinearVelocity") then ag2.VectorVelocity = VEC_ZERO end
                    end
                    _watchLastPos = curRoot.Position
                end
            end)

            Tween.MoveConn = RunService.Heartbeat:Connect(function(rawDt)
                if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end
                local dt = math.min(rawDt, DT_CAP)

                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                pcall(function() root.Velocity = VEC_ZERO end)

                local cur    = root.Position
                local distXZ = (Vector2.new(targetPos.X, targetPos.Z) - Vector2.new(cur.X, cur.Z)).Magnitude

                if not stepData.isMerchant and not stepData.isFishmanIn and not stepData.isFishmanExit then
                    if math.abs(cur.Y - 7.33) > 10 and distXZ > 50 then
                        -- [FIX] Snap Y in-place thay vì disconnect + task.spawn + flyTo đệ quy.
                        -- Bug cũ: dưới FPS thấp nhiều Heartbeat frames có thể trigger block này
                        -- trước khi task.spawn(flyTo) kịp chạy → spawn pile-up, behavior lẫn lộn.
                        -- Fix: chỉ CFrame snap Y rồi return → frame sau Heartbeat tiếp tục bình thường.
                        root.CFrame = CFrame.new(cur.X, 7.33, cur.Z)
                        if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                        return
                    end
                end

                local arrived
                if stepData.isMerchant then
                    arrived = (cur - targetPos).Magnitude < 25
                else
                    arrived = distXZ < 30
                end

                if arrived then
                    _watchDone = true
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
                        elseif stepData.isPortal or stepData.isFishmanIn then
                            local toggle = 1
                            while waited < 20 do
                                if not Tween.IsTeleporting or not root then break end
                                if (root.Position - targetPos).Magnitude > 200 then break end
                                root.CFrame = CFrame.new(targetPos.X + toggle, targetPos.Y, targetPos.Z + toggle)
                                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                                toggle = toggle * -1; task.wait(0.3); waited = waited + 0.3
                            end
                            task.wait(1.5)
                        elseif stepData.isMerchant then
                            -- Fix3: snap character close to merchant and anchor immediately
                            -- so server cannot pull it back before BuyItemsFromMerchant runs
                            local landPos = Vector3.new(targetPos.X + 3, targetPos.Y, targetPos.Z + 3)
                            root.CFrame = CFrame.new(landPos)
                            if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                            root.Anchored = true   -- Fix1: lock in place before onStepComplete
                            task.wait(0.3)
                            -- Fix3: verify character wasn't pulled away during the wait
                            if (root.Position - landPos).Magnitude > 30 then
                                -- Server pulled us back — unanchor, retry flyTo from new position
                                root.Anchored = false
                                task.wait(0.3)
                                flyTo(stepData, onStepComplete)
                                return
                            end
                        else
                            root.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                            if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                            task.wait(0.2)
                            -- Fix3: verify arrival for non-merchant paths too
                            if (root.Position - targetPos).Magnitude > 60 then
                                -- Pulled back by server — retry
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
                    local tgt   = Vector3.new(targetPos.X, safeY, targetPos.Z)
                    local diff  = tgt - cur
                    local dist  = diff.Magnitude
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
        while not isDone and _G.AutoFishing do
            if not Tween.IsTeleporting and not isDone then break end
            task.wait(0.2)
        end
        if not _G.AutoFishing then Tween.Stop() end
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

        -- Helper: đọc peli hiện tại, trả về số (0 nếu lỗi)
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

        -- Không bay nếu peli đã >= 1M trước khi đi
        if getCurrentPeli() >= 1000000 then return false end

        TweenToPosAndWait(Cords.Sell)
        if not _G.AutoFishing then return false end

        inventory = GetInventory()
        if not inventory then return false end

        for _, fishName in ipairs(fishList) do
            local count = inventory[fishName] or 0
            if count > 0 then
                for i = 1, count do
                    if not _G.AutoFishing then break end
                    -- Check peli TRƯỚC khi bán con cá này
                    if getCurrentPeli() >= 1000000 then return true end
                    -- [OPTIMIZE] Dùng cached FishingShopRemoteR thay vì WaitForChild mỗi lần
                    if FishingShopRemoteR then
                        pcall(function()
                            FishingShopRemoteR:InvokeServer(table.unpack({{
                                ["Fish"]=fishName, ["All"]=false, ["Method"]="SellFish"
                            }}))
                        end)
                    end
                    -- Đợi server cập nhật peli (0.1s quá ngắn, server chưa kịp cộng tiền)
                    task.wait(0.3)
                    -- Check lại ngay sau khi sell + wait — nếu vừa chạm 1M thì dừng
                    if getCurrentPeli() >= 1000000 then return true end
                end
            end
        end
        return true
    end

    -- mode: "single" = loop Count=1 từng lần (an toàn, chậm hơn)
    --        "all"    = 1 call Count=floor(count/countPerCraft) (nhanh, craft hết 1 lần)
    local function AutoCraftSilent(blueprintType, extraDataKey, fishList, minCount, countPerCraft, mode)
        minCount      = minCount      or 1
        countPerCraft = countPerCraft or 1
        mode          = mode          or "single"
        local inventory = GetInventory()
        if not inventory then return false end

        -- [FIX 3 DEBUG] In inventory keys lần đầu để verify tên cá khớp FishLists
        -- Xóa block này sau khi confirm tên cá đúng.
        if blueprintType == "Rare Fish Bait" and _G._RareCraftDebugDone ~= true then
            _G._RareCraftDebugDone = true
            local found = {}
            for k, v in pairs(inventory) do
                if type(v) == "number" and v >= 1 then
                    found[#found+1] = k.."="..tostring(v)
                end
            end
            print("[ZILI DEBUG] Inventory keys:", table.concat(found, ", "))
        end

        local craftedAny = false
        for _, fishName in ipairs(fishList) do
            local count = inventory[fishName] or 0
            if count >= minCount then
                if not craftedAny then
                    TweenToPosAndWait(Cords.Craft)
                    craftedAny = true
                    if not _G.AutoFishing then return false end
                end

                local batches = math.floor(count / countPerCraft)
                if batches < 1 then continue end

                if mode == "all" then
                    -- ── MODE ALL: 1 call duy nhất, Count = số bait cần craft ──
                    -- Ví dụ: 30 Fangfish, countPerCraft=2 → Count=15 → server deduct 30 cá
                    if CraftingRemoteR then
                        pcall(function()
                            CraftingRemoteR:InvokeServer(table.unpack({{
                                ["BlueprintItem"] = blueprintType,
                                ["Method"]        = "Craft",
                                ["ExtraData"]     = {[fishName] = extraDataKey},
                                ["Count"]         = batches,
                            }}))
                        end)
                        task.wait(0.5)
                    end
                else
                    -- ── MODE SINGLE: loop Count=1, mỗi lần craft 1 bait ──
                    -- An toàn hơn, server không bao giờ reject do đủ điều kiện từng call
                    for _ = 1, batches do
                        if not _G.AutoFishing then return false end
                        if CraftingRemoteR then
                            pcall(function()
                                CraftingRemoteR:InvokeServer(table.unpack({{
                                    ["BlueprintItem"] = blueprintType,
                                    ["Method"]        = "Craft",
                                    ["ExtraData"]     = {[fishName] = extraDataKey},
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
                    if not _G.KnownMerchantPos or (_G.KnownMerchantPos - v).Magnitude > 5 then
                        _G.KnownMerchantPos  = v
                        _G.MerchantSpawnTime = os.time()
                        _G.MerchantProcessed = false
                        _lastShopPeriod      = -1   
                    end
                else
                    _G.KnownMerchantPos  = nil
                    _G.MerchantProcessed = false
                    _G.MerchantSpawnTime = 0
                    _lastShopPeriod      = -1
                end
            end)
        end

        _MerchantDetectConn1 = compassGuider.ChildAdded:Connect(function(child)
            if child.Name ~= "Traveling Merchant" then return end
            task.wait(0.2)  
            hookMerchantValue(child)
            local v = child.Value
            if typeof(v) == "Vector3" and v.Magnitude > 10 then
                _G.KnownMerchantPos  = v
                _G.MerchantSpawnTime = os.time()
                _G.MerchantProcessed = false
                _lastShopPeriod      = -1
            end
        end)

        _MerchantDetectConn2 = compassGuider.ChildRemoved:Connect(function(child)
            if child.Name ~= "Traveling Merchant" then return end
            _G.KnownMerchantPos  = nil
            _G.MerchantProcessed = false
            _G.MerchantSpawnTime = 0
            _lastShopPeriod      = -1
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
                    _G.KnownMerchantPos  = v
                    _G.MerchantSpawnTime = os.time()  
                    _G.MerchantProcessed = false
                    _lastShopPeriod      = -1
                end
            end
        end
    end

    task.spawn(SetupMerchantDetection)

    local function SendMerchantWebhook(shopData, boughtData)
        local url = _G.WebhookUrl or ""
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
            totalVal = totalVal + p
            table.insert(grouped[Rarity[name] or "Common"], {Name=name,Stock=data.Stock,Price=Fmt(p)})
        end

        local hidden = "||"..LocalPlayer.Name.."||"
        local T3     = string.rep(string.char(96),3)
        local fields, order = {}, {"Mythic","Legendary","Epic","Rare","Uncommon","Common"}
        for _,r in ipairs(order) do
            if #grouped[r] > 0 then
                table.insert(fields,{["name"]=UI[r].Title.." ("..#grouped[r]..")",["value"]="** **",["inline"]=false})
                for _,item in ipairs(grouped[r]) do
                    table.insert(fields,{["name"]=UI[r].Icon.." "..item.Name,["value"]=string.format("%s\nStock: %s\nPrice: %s Peli\n%s",T3,tostring(item.Stock),item.Price,T3),["inline"]=true})
                end
            end
        end

        local bLines, hasMythic, hasBought = "", false, false
        for name, amt in pairs(boughtData) do
            bLines  = bLines..string.format("+ %s x%d\n",name,amt)
            hasBought = true
            if (Rarity[name] or "Common")=="Mythic" then hasMythic=true end
        end
        if hasBought then table.insert(fields,{["name"]="\n✅ **PURCHASED ITEMS:**",["value"]=string.format("%sdiff\n%s%s",T3,bLines,T3),["inline"]=false}) end

        local color = hasMythic and 10494192 or hasBought and 65280 or 16711680
        local embeds, cur, idx = {}, {}, 1
        local function flush()
            local e={["color"]=color}
            if idx==1 then
                e["author"]      = {["name"]="🛒 TRAVELING MERCHANT",["icon_url"]="https://tr.rbxcdn.com/3932789139a04a9d70081d9f8e874cc6/150/150/Image/Png"}
                e["description"] = "**Player info:**\n🤰 User: "..hidden.."\n💰 Peli: "..currentPeli.."\n\n**📊 Summary:** "..total.." items | "..Fmt(totalVal).." Peli total"
            end
            if #cur>0 then e["fields"]=cur end
            table.insert(embeds,e); cur={}; idx=idx+1
        end
        for _,f in ipairs(fields) do table.insert(cur,f); if #cur==25 then flush() end end
        if #cur>0 or idx==1 then flush() end
        embeds[#embeds]["footer"] = {["text"]="ZILI HUB | "..os.date("%d/%m/%Y %H:%M:%S")}

        local payload = {["embeds"]=embeds}
        if hasMythic then payload["content"]="@everyone\n🟣 **SUCCESSFULLY PURCHASED A MYTHIC ITEM!**"; payload["allowed_mentions"]={["parse"]={"everyone"}} end

        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then pcall(function() req({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)}) end) end
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

    local function BuyItemsFromMerchant(npc)
        local questR    = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Quest")
        local merchantR = ReplicatedStorage:WaitForChild("Events"):WaitForChild("TravelingMerchentRemote")
        local root      = getRoot()

        -- root.Anchored is already set to true by flyTo's isMerchant arrived block (Fix1)
        -- Keep it anchored for the entire transaction duration

        -- Fix2: fire proximity prompt up to 3 times with a small gap
        -- At low FPS the first fire may not register server-side
        if root and npc then
            for attempt = 1, 3 do
                pcall(function()
                    for _, p in pairs(npc:GetDescendants()) do
                        if p:IsA("ProximityPrompt") then fireproximityprompt(p) end
                    end
                end)
                task.wait(0.4)
                -- If NPCCHAT already opened, stop retrying
                if LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT") then break end
            end
        end

        -- Fix2: retry questR:InvokeServer up to 3 times instead of once
        for attempt = 1, 3 do
            pcall(function() questR:InvokeServer({ [1] = { [1] = "npcChat", [2] = true } }) end)
            task.wait(0.3)
            if LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT") then break end
        end

        -- Fix2: wait for MerchentShop, clicking buttons without Visible check
        -- At 10 FPS minimized, v.Visible may return false even though button exists
        local shopGui = nil
        local deadline = tick() + 15
        while tick() < deadline and _G.AutoFishing do
            -- Click all candidate buttons regardless of Visible state
            local chatGui = LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT")
            if chatGui then
                local frame = chatGui:FindFirstChild("Frame") or chatGui:FindFirstChildWhichIsA("Frame", true)
                if frame then
                    pcall(function()
                        for _, v in pairs(frame:GetDescendants()) do
                            if v:IsA("TextButton") then  -- removed v.Visible check
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
            end
            task.wait(0.4)
            shopGui = LocalPlayer.PlayerGui:FindFirstChild("MerchentShop")
            if shopGui then break end
            -- Fix2: if chat closed without opening shop, retry questR
            if not chatGui and not shopGui then
                pcall(function() questR:InvokeServer({ [1] = { [1] = "npcChat", [2] = true } }) end)
                task.wait(0.5)
            end
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
                    local ok = pcall(function() return merchantR:InvokeServer(itemName, seed) end)
                    if ok then boughtData[itemName] = (boughtData[itemName] or 0) + 1 end
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

        if root then root.Anchored = false end
    end

    local BUY_PRIORITY = {
        "All Seeing Shamrock", "Mythical Fruit Chest", "Legendary Fruit Chest",
        "Legendary Fish Bait", "Rare Fruit Chest",
    }

    local function SyncConfigs(TogglesData)
        local baitVal = TogglesData["Config_SelectBait"] and TogglesData["Config_SelectBait"].Value
        _G.PreferredBait = (type(baitVal)=="string" and baitVal~="") and baitVal or nil

        local sell = TogglesData["Config_SellFish"] and TogglesData["Config_SellFish"].Value or {}
        _Configs.SellCommon = sell["Common Fish"]    == true
        _Configs.SellRare   = sell["Rare Fish"]      == true
        _Configs.SellLeg    = sell["Legendary Fish"] == true

        local craft = TogglesData["Config_CraftBait"] and TogglesData["Config_CraftBait"].Value or {}
        _Configs.CraftLeg  = craft["Legendary Fish Bait"] == true
        _Configs.CraftRare = craft["Rare Fish Bait"]      == true

        -- "Config_CraftRareMode": UI truyền vào "single" hoặc "all"
        -- Mặc định "single" nếu chưa có key hoặc giá trị không hợp lệ
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
        -- BuyBait dựa vào PreferredBait (bait user chọn), không phải TargetBait (bait hiện resolve được)
        -- Nếu user chọn Common Fish Bait thì luôn mua, kể cả khi inventory đang trống
        _Configs.BuyBait = (_G.PreferredBait == "Common Fish Bait")
    end

    -- =====================================================================
    -- MAIN LOOP
    -- Priority: 0=mua rod → 1=merchant → 2=equip rod+title → 3=mua mồi → 4=bán+craft → 5=câu
    -- =====================================================================
    local function RunLoop(TogglesData)
        while _G.AutoFishing do
            task.wait(1)
            -- [NEW] Fruit priority: nhường CPU cho AutoFruitManager xử lý fruit
            -- trước khi bước tiếp. Fishing tiếp tục ngay khi FruitPriorityActive = false.
            while _G.FruitPriorityActive do task.wait(0.3) end
            SyncConfigs(TogglesData)   -- sets _G.PreferredBait, _Configs.*

            if not FishingRemote then task.wait(2); continue end

            local char  = LocalPlayer.Character
            local hum   = char and char:FindFirstChild("Humanoid")
            local rPart = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not rPart or not hum or hum.Health <= 0 then
                task.wait(2); continue
            end

            pcall(function() ReplicatedStorage.Events.takestam:FireServer(0.545, "dash") end)

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 0: MUA ROD (block tất cả, mua + equip luôn trong hàm)
            -- ════════════════════════════════════════════════════════════════
            local invForRod = GetInventory()
            _justBoughtRod  = false
            BuyFishingRodIfNeeded(invForRod)
            if not _G.AutoFishing then break end
            if _justBoughtRod then continue end  -- vừa mua+equip xong → re-check từ đầu

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 1: TRAVELING MERCHANT
            -- ════════════════════════════════════════════════════════════════
            if _Configs.AutoMerchant then
                local curMin = tonumber(os.date("%M")) or 0
                -- Reset processed flag khi qua mốc :00 hoặc :30
                if curMin == 0 or curMin == 30 then
                    if _lastShopPeriod ~= curMin then
                        _lastShopPeriod = curMin
                        if _G.KnownMerchantPos then _G.MerchantProcessed = false end
                    end
                else
                    _lastShopPeriod = -1
                end

                -- Despawn guard: 10 phút
                if _G.KnownMerchantPos then
                    if os.time() - (_G.MerchantSpawnTime or 0) >= 600 then
                        _G.KnownMerchantPos  = nil
                        _G.MerchantProcessed = false
                        _G.MerchantSpawnTime = 0
                        _lastShopPeriod      = -1
                    end
                end

                if _G.KnownMerchantPos and not _G.MerchantProcessed then
                    local mPos = _G.KnownMerchantPos
                    TweenToPosAndWait(mPos, {isMerchant = true})
                    if _G.AutoFishing then
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
                            _G.MerchantProcessed = true
                            TweenToPosAndWait(mPos + Vector3.new(20, 0, 20))
                        else
                            _G.MerchantProcessed = true
                        end
                    end
                end
            end

            if not _G.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 2: EQUIP ROD + TITLE
            -- ════════════════════════════════════════════════════════════════
            local rodName = "Fishing Rod"
            if _Configs.EquipRod then
                rodName = AutoEquipRodSilent() or "Fishing Rod"
            end
            if _Configs.EquipTitle then AutoEquipTitleSilent() end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 3: MUA MỒI
            -- Dùng _G.PreferredBait (user đã chọn) không phải _G.TargetBait
            -- để đảm bảo fresh acc không có bait vẫn đi mua
            -- ════════════════════════════════════════════════════════════════
            if _Configs.BuyBait then   -- true khi PreferredBait == "Common Fish Bait"
                local invCheck = GetInventory() or {}
                if (invCheck["Common Fish Bait"] or 0) < 1 then
                    TweenToPosAndWait(Cords.Buy)
                    if _G.AutoFishing then
                        pcall(function()
                            ReplicatedStorage.Events.Shop:InvokeServer(
                                workspace.BuyableItems["Common Fish Bait"],
                                _G.FishBuyAmount or 50
                            )
                        end)
                        task.wait(1)
                    end
                end
            end

            if not _G.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 4: BÁN CÁ + CRAFT MỒI
            -- ════════════════════════════════════════════════════════════════
            if _Configs.SellCommon then AutoSellSilent(FishLists.Common) end
            if _Configs.SellRare   then AutoSellSilent(FishLists.Rare)   end
            if _Configs.SellLeg    then AutoSellSilent(FishLists.Leg)    end

            if _Configs.CraftLeg  then AutoCraftSilent("Legendary Fish Bait","Legendary Fish",FishLists.Leg,  1, 1, "all")  end
            if _Configs.CraftRare then AutoCraftSilent("Rare Fish Bait",     "Rare Fish",     FishLists.Rare, 2, 2, _Configs.CraftRareMode) end

            if not _G.AutoFishing then break end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITY 5: CÂU CÁ (ưu tiên thấp nhất)
            -- ════════════════════════════════════════════════════════════════
            -- Resolve bait ngay trước câu để dùng inventory mới nhất
            local invFish = GetInventory() or {}
            _G.TargetBait = ResolveBait(invFish)
            if not _G.TargetBait then continue end   -- không có bait nào → bỏ qua, vòng sau kiểm tra lại

            -- Phải có rod vật lý trước khi throw
            if not EquipPhysicalRod(rodName) then continue end

            pcall(function()
                local castPos = rPart.Position + (rPart.CFrame.LookVector * 30) - Vector3.new(0, 15, 0)
                FishingRemote:InvokeServer({["Goal"]=castPos,["Action"]="Throw",["Bait"]=_G.TargetBait})
                task.wait(1.2)
                pcall(function() FishingRemote:InvokeServer({["Action"]="Landed"}) end)

                local bobble, waited = nil, 0
                while waited < 30 and _G.AutoFishing and not _G.FruitPriorityActive do
                    bobble = GetMyBobble(); if bobble then break end
                    -- [FIX 4] Simulate input mỗi ~5s khi đang chờ bobble.
                    -- Khi minimize hoặc FPS < 5, server có thể coi là inactive → kick.
                    -- VirtualUser:ClickButton2 giả lập touch/click giữ session alive.
                    if math.floor(waited) % 5 == 0 and waited > 0 then
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton2(Vector2.new())
                        end)
                    end
                    task.wait(0.2); waited = waited + 0.2
                end
                -- [NEW] Fruit xuất hiện giữa chừng khi đang chờ bobble → cancel cast ngay
                if _G.FruitPriorityActive then
                    FishingRemote:InvokeServer({["Action"]="Cancel"})
                    return
                end

                if bobble and _G.AutoFishing then
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
                        if t < 11.5 then t = math.random(1150,1250)/100 end
                        if t > 15.5 then t = math.random(1450,1550)/100 end
                    elseif mm >= 1.0 then
                        if t < 9.5  then t = math.random(900, 1000)/100 end
                        if t > 11.5 then t = math.random(1050,1150)/100 end
                    else
                        if t < 6.5  then t = math.random(450, 550)/100  end
                        if t > 8.0  then t = math.random(750, 850)/100  end
                    end

                    task.wait(t)

                    if _G.AutoFishing then
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
                task.wait(0.1)
            end)
        end

        Tween.Stop()
    end

    -- =====================================================================
    -- PUBLIC API
    -- =====================================================================
    function AutoFishMerchant.Start(TogglesData)
        if _G.AutoFishing then return end
        _G.AutoFishing = true
        task.spawn(function() RunLoop(TogglesData) end)
    end

    function AutoFishMerchant.Stop()
        _G.AutoFishing = false
        Tween.Stop()
    end

    return AutoFishMerchant
end

-- 📦 MODULE: Farm/AutoFruitManager
__modules["Farm/AutoFruitManager"] = function()
    local AutoFruitManager = {}

    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer       = Players.LocalPlayer

    -- =====================================================================
    -- FRUIT LISTS (không đổi)
    -- =====================================================================
    local RARITY_ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }

    local FRUIT_RARITY = {
        Spin  = "Common", Suke   = "Common", Kilo  = "Common", Heal   = "Common",
        Bari  = "Rare",   Mero   = "Rare",   Horo  = "Rare",   Bomb   = "Rare",  Gomu = "Rare",
        Kira  = "Epic",   Spring = "Epic",   Yomi  = "Epic",
        Pika  = "Legendary", Mera  = "Legendary", Yami  = "Legendary", Smoke = "Legendary",
        Kage  = "Legendary", Paw   = "Legendary", Goru  = "Legendary", Yuki  = "Legendary",
        Magu  = "Legendary", Suna  = "Legendary", Goro  = "Legendary", Hie   = "Legendary",
        Gura  = "Legendary", Zushi = "Legendary",
        Dragon= "Mythic", Soul   = "Mythic", Mochi = "Mythic",
        Venom = "Mythic", Tori   = "Mythic", Pteranodon= "Mythic",
        Ope   = "Mythic", Buddha = "Mythic",
    }

    -- =====================================================================
    -- DROP ZONES (theo rarity — người chơi cung cấp)
    -- Common & Epic không có zone riêng → drop tại chỗ
    -- =====================================================================
    local DROP_ZONES = {
        Rare      = Vector3.new(-1399.33, 4.12, -5035.37),
        Legendary = Vector3.new(-1361.67, 4.12, -5034.76),
        Mythic    = Vector3.new(-1325.63, 4.12, -5037.1),
    }

    local Events       = ReplicatedStorage:WaitForChild("Events", 10)
    local FruitStorage = Events and Events:WaitForChild("FruitStorage", 10)
    local ToolsRemote  = Events and Events:WaitForChild("Tools", 10)

    -- =====================================================================
    -- HELPERS
    -- =====================================================================
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

    -- [FIX] EquipTool có verify: chờ tối đa 1s cho tới khi tool.Parent == char
    -- Bug cũ: chỉ gọi EquipTool rồi wait(0.3) cứng, không xác nhận thành công.
    local function EquipTool(tool)
        local char = LocalPlayer.Character
        if not char then return false end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return false end
        -- Đã cầm trên tay rồi
        if tool.Parent == char then return true end
        -- Tool phải ở backpack mới EquipTool được
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not backpack or tool.Parent ~= backpack then return false end

        hum:EquipTool(tool)
        -- Verify: polling đến khi tool vào character, tối đa 1 giây
        local waited = 0
        while waited < 1 do
            task.wait(0.1); waited = waited + 0.1
            if tool.Parent == char then return true end
        end
        return false
    end

    -- [NEW] Teleport đến vị trí drop zone rồi chờ server nhận vị trí
    local function TeleportTo(pos)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        -- Noclip tạm để không bị kẹt tường
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
        task.wait(0.6) -- đợi server nhận vị trí mới
        return true
    end

    -- [NEW] Kiểm tra nhanh có fruit cần xử lý không — dùng trong main loop để
    -- tránh lock _G.FruitPriorityActive khi không cần thiết.
    local function HasActionableFruit()
        local fruits = GetFruits()
        if #fruits == 0 then return false end
        local rarityFilter  = getgenv().Config_FruitRarity or "Common"
        local specificFruit = getgenv().Config_FruitSelect  or ""
        local minLevel      = GetMinKeepLevel(rarityFilter)
        local minDropLevel  = 0

        local autoStore = getgenv().AutoStoreFruit
        local autoDrop  = getgenv().AutoDropFruit

        for _, tool in ipairs(fruits) do
            local level = RARITY_ORDER[FRUIT_RARITY[tool.Name] or "Common"] or 1
            if specificFruit ~= "" then
                if string.find(string.lower(specificFruit), string.lower(tool.Name)) ~= nil then
                    if autoStore then return true end
                end
            elseif autoStore and minLevel > 0 and level >= minLevel then
                return true
            elseif autoDrop and minLevel > 0 and level < minLevel then
                return true
            elseif (autoStore or autoDrop) and minLevel == 0 then
                return true
            end
        end
        return false
    end

    -- =====================================================================
    -- CORE LOGIC
    -- =====================================================================
    local function DoAutoStore()
        local fruits = GetFruits()
        if #fruits == 0 then return end

        local rarityFilter  = getgenv().Config_FruitRarity or "Common"
        local specificFruit = getgenv().Config_FruitSelect  or ""
        local minLevel      = GetMinKeepLevel(rarityFilter)

        for _, tool in ipairs(fruits) do
            local level = RARITY_ORDER[FRUIT_RARITY[tool.Name] or "Common"] or 1
            local shouldStore = false

            if specificFruit ~= "" then
                shouldStore = string.find(string.lower(specificFruit), string.lower(tool.Name)) ~= nil
            elseif minLevel > 0 then
                shouldStore = level >= minLevel
            else
                shouldStore = true
            end

            if shouldStore and FruitStorage then
                -- [FIX] Equip trước, verify xong rồi mới invoke — truyền tool object,
                -- không phải boolean. Bug cũ: InvokeServer(true) → server không biết store gì.
                local ok = EquipTool(tool)
                if ok then
                    local char    = LocalPlayer.Character
                    local equipped = char and char:FindFirstChild(tool.Name)
                    if equipped then
                        pcall(function() FruitStorage:InvokeServer(equipped) end)
                        task.wait(0.8)
                    end
                end
            end
        end
    end

    -- [FIX + NEW] DoAutoDrop: nhóm fruit theo drop zone → teleport 1 lần/zone → drop hết
    -- Bug cũ: không di chuyển đến zone, drop tại chỗ.
    local function DoAutoDrop()
        local fruits = GetFruits()
        if #fruits == 0 then return end

        local rarityFilter  = getgenv().Config_FruitRarity or "Common"
        local specificFruit = getgenv().Config_FruitSelect  or ""
        local minKeepLevel  = GetMinKeepLevel(rarityFilter)

        -- Bước 1: lọc fruit cần drop, gắn zone tương ứng theo rarity
        -- Nhóm theo zone key để tối thiểu số lần teleport
        local groups = {} -- key = zone key, value = { pos, tools[] }

        for _, tool in ipairs(fruits) do
            local level  = RARITY_ORDER[FRUIT_RARITY[tool.Name] or "Common"] or 1
            local rarity = FRUIT_RARITY[tool.Name] or "Common"
            local shouldDrop = false

            if specificFruit ~= "" and string.find(string.lower(specificFruit), string.lower(tool.Name)) ~= nil then
                shouldDrop = false -- Không drop trái đang target
            elseif minKeepLevel > 0 then
                shouldDrop = level < minKeepLevel
            else
                shouldDrop = true
            end

            if shouldDrop and ToolsRemote then
                -- Tìm zone theo rarity của trái này
                local zonePos = DROP_ZONES[rarity] -- nil nếu Common/Epic
                local key     = zonePos and rarity or "inline"

                if not groups[key] then
                    groups[key] = { pos = zonePos, tools = {} }
                end
                table.insert(groups[key].tools, tool)
            end
        end

        -- Bước 2: với mỗi zone, teleport một lần rồi drop hết fruit thuộc zone đó
        for _, group in pairs(groups) do
            if group.pos then
                TeleportTo(group.pos)
            end

            for _, tool in ipairs(group.tools) do
                local ok = EquipTool(tool)
                if ok then
                    local char    = LocalPlayer.Character
                    local equipped = char and (char:FindFirstChild(tool.Name) or getNilTool(tool.Name))
                    if equipped then
                        pcall(function() ToolsRemote:InvokeServer("drop", equipped) end)
                        task.wait(0.5)
                    end
                end
            end
        end
    end

    -- =====================================================================
    -- MAIN LOOP
    -- =====================================================================
    local _running = false

    function AutoFruitManager.Start()
        if _running then return end
        _running = true
        _G.FruitPriorityActive = false

        task.spawn(function()
            while _running do
                task.wait(0.5) -- poll nhanh hơn (0.5s) để phát hiện fruit kịp thời

                local autoStore = getgenv().AutoStoreFruit
                local autoDrop  = getgenv().AutoDropFruit

                if (autoStore or autoDrop) and HasActionableFruit() then
                    -- [NEW] Signal cho fishing module dừng hành động hiện tại
                    _G.FruitPriorityActive = true
                    task.wait(0.4) -- đợi fishing nhìn thấy flag và dừng cast nếu đang chờ

                    if autoStore then pcall(DoAutoStore) end
                    if autoDrop  then pcall(DoAutoDrop)  end

                    -- Trả quyền lại cho fishing
                    _G.FruitPriorityActive = false
                end
            end
            _G.FruitPriorityActive = false
        end)
    end

    function AutoFruitManager.Stop()
        _running = false
        _G.FruitPriorityActive = false
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

-- 📦 MODULE: Stats/addStats
__modules["Stats/addStats"] = function()
    local addStats = {}
    
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")

    function addStats.Start(AutoStatsData)
        
        -- [BỘ LỌC THÔNG MINH]: Xóa dấu cách để đọc chuẩn tên stat game GPO
        local function GetCurrentStat(statName)
            local val = 0
            local cleanName = statName:gsub("%s+", "") -- Chuyển "Devil Fruit" -> "DevilFruit"
            
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
                            
                            if data.Cap == 0 or currentStat < data.Cap then
                                pcall(function()
                                    -- Gửi lệnh cộng điểm lên server
                                    statsEvent:FireServer(statName, nil, 1)
                                end)
                                
                                -- [TÍNH NĂNG MỚI]: HIỂN THỊ TIẾN ĐỘ TRỰC TIẾP LÊN NÚT
                                if data.Btn then
                                    local capText = data.Cap > 0 and tostring(data.Cap) or "Max"
                                    data.Btn.Text = "(" .. tostring(currentStat) .. "/" .. capText .. ")"
                                end
                            else
                                -- Tự tắt nút, trả về màu cũ khi đầy
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
                task.wait(0.1) -- Tốc độ đếm điểm
            end
        end)
    end

    return addStats
end

-- =====================================================================
-- GET BETTER OUT | MAIN HUB  (Optimized Build v2.9.0)
-- New: Toast notifications, keybind toggle (RightShift), session timer,
--      active-feature counter, global search, tooltips, collapsible cards,
--      tab badges, color theme picker, load optimization, logo unified.
-- =====================================================================
-- HOW TO SET YOUR LOGO:
--   1. Upload the PNG to Roblox (Creator Dashboard → Development Items → Images)
--   2. Copy the numeric asset ID (e.g. 12345678901)
--   3. Replace the number below:  rbxassetid://YOUR_ID_HERE
-- Source PNG: https://i.postimg.cc/NMRNsmrN/dfa59e7e_ce99_4091_9d64_a070f4a33687.png
-- =====================================================================

local LOGO_ASSET_ID = "rbxassetid://108561234878560" -- << REPLACE with your uploaded Roblox asset ID

-- =====================================================================
-- PLACE DETECTION  (must run before all requires)
-- =====================================================================
local PLACE_LOBBY = 1730877806
local PLACE_GAME  = 3978370137
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
            pcall(function() remote:FireServer(hubArg) end)
            pcall(function() chooseTypeUI.Enabled = false end)
            if seaArg then
                local wantText    = (seaArg == "Sea 2") and "Second Sea" or "First Sea"
                local wantPartial = (seaArg == "Sea 2") and "second" or "first"
                local function tryClick(btn)
                    pcall(function() firebutton(btn) end)
                    pcall(function() btn:activate() end)
                end
                local function matchesSea(btn)
                    local nm = btn.Name or ""; local tx = (btn:IsA("TextButton") and btn.Text) or ""
                    if nm == wantText or tx == wantText then return true end
                    return nm:lower():find(wantPartial,1,true) ~= nil or tx:lower():find(wantPartial,1,true) ~= nil
                end
                local function searchRoot(root)
                    for _, desc in ipairs(root:GetDescendants()) do
                        if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and matchesSea(desc) then
                            tryClick(desc); return true
                        end
                    end
                    return false
                end
                task.spawn(function()
                    local deadline = tick() + 25; local clicked = false
                    task.wait(0.4)
                    while not clicked and tick() < deadline do
                        local pg2 = Player_L:FindFirstChild("PlayerGui")
                        if pg2 and searchRoot(pg2) then clicked = true; break end
                        pcall(function() if searchRoot(game:GetService("CoreGui")) then clicked = true end end)
                        if not clicked then task.wait(0.3) end
                    end
                end)
            end
        end)
    end
end

local AutoRejoinModule = {}
AutoRejoinModule._running = false; AutoRejoinModule._thread = nil
AutoRejoinModule._hooked  = false; AutoRejoinModule.SESSION = "gbo_session.json"

function AutoRejoinModule._saveSession()
    pcall(function()
        if not writefile then return end
        local ok, js = pcall(function()
            return HttpService:JSONEncode({
                code=getgenv().PSCode or "", hub=getgenv().SelectedHub or "Regular",
                sea=getgenv().SelectedSea or "Sea 1", autoRejoin=true,
            })
        end)
        if ok then writefile(AutoRejoinModule.SESSION, js) end
    end)
end

function AutoRejoinModule.Start()
    if AutoRejoinModule._running then return end
    AutoRejoinModule._running = true
    AutoRejoinModule._saveSession()
    if not AutoRejoinModule._hooked then
        AutoRejoinModule._hooked = true
        pcall(function()
            Players.PlayerRemoving:Connect(function(p)
                if p ~= Player_L then return end
                AutoRejoinModule._saveSession()
                if AutoRejoinModule._running then
                    pcall(function() TeleportService_L:Teleport(PLACE_LOBBY, Player_L) end)
                end
            end)
        end)
        pcall(function()
            Player_L.OnTeleport:Connect(function(state)
                if not AutoRejoinModule._running then return end
                if state == Enum.TeleportState.Failed then
                    task.wait(3)
                    pcall(function() TeleportService_L:Teleport(PLACE_LOBBY, Player_L) end)
                end
            end)
        end)
    end
    AutoRejoinModule._thread = task.spawn(function()
        local noCharTicks = 0
        while AutoRejoinModule._running do
            task.wait(5); AutoRejoinModule._saveSession()
            if Player_L.Character then noCharTicks = 0
            else
                noCharTicks += 1
                if noCharTicks >= 3 and AutoRejoinModule._running then
                    pcall(function() TeleportService_L:Teleport(PLACE_LOBBY, Player_L) end); break
                end
            end
        end
    end)
end

function AutoRejoinModule.Stop()
    AutoRejoinModule._running = false
    if AutoRejoinModule._thread then task.cancel(AutoRejoinModule._thread); AutoRejoinModule._thread = nil end
    pcall(function()
        if deletefile and isfile and isfile(AutoRejoinModule.SESSION) then deletefile(AutoRejoinModule.SESSION) end
    end)
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
    _G._ZiliLoadReady=false; _G._ZiliShowMain=false
    task.spawn(function()
        task.wait(0.3)
        for _,s in ipairs(STAGES) do _setProgress(s[1],s[2]); task.wait(s[3]) end
        local waited=0
        while not _G._ZiliLoadReady and waited<20 do task.wait(0.08); waited+=0.08 end
        _dotRunning=false
        _setProgress(100,"Welcome back!")
        _TW(_pctLbl,0.2,{TextColor3=C3(72,225,135)}); _TW(_statusLbl,0.2,{TextColor3=C3(72,225,135)}); _TW(_pBorder,0.2,{Color=C3(72,225,135)})
        task.wait(0.5)
        if _blur then pcall(function() _TW(_blur,0.35,{Size=0}) end); task.delay(0.4,function() pcall(function() _blur:Destroy() end) end) end
        _TW(_panel,0.28,{BackgroundTransparency=1,Position=UDim2.new(0.5,-170,0.4,-185)})
        task.wait(0.22); _TW(_bg,0.32,{BackgroundTransparency=1}); task.wait(0.32)
        pcall(function() _lGui:Destroy() end); _G._ZiliShowMain=true
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
-- COLOR THEME SYSTEM
-- 4 presets; accent colors swap live across the entire hub
-- =====================================================================
local THEMES={
    {name="Gold",   main=C(255,215,85), c2=C(220,172,68),  c3=C(140,100,30), dark=C(35,26,6)},
    {name="Cyan",   main=C(45,225,218), c2=C(30,200,195),  c3=C(15,100,100), dark=C(3,30,30)},
    {name="Purple", main=C(185,95,255), c2=C(155,75,220),  c3=C(80,35,120),  dark=C(18,6,36)},
    {name="Rose",   main=C(255,90,160), c2=C(230,70,140),  c3=C(130,30,75),  dark=C(35,5,20)},
}
local _curTheme=1
local _themeObjects={}  -- {obj, prop} pairs registered for live recolour
local function RegTheme(obj,prop) table.insert(_themeObjects,{obj=obj,prop=prop}) end
local function ApplyTheme(idx)
    _curTheme=idx; local t=THEMES[idx]
    GOLD=t.c2; GOLD2=t.main; GOLD3=t.c3; GOLDD=t.dark
    for _,r in ipairs(_themeObjects) do pcall(function() r.obj[r.prop]=t.main end) end
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
            NEW("TextLabel",{Text=t.icon.."  "..t.msg,Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=t.col,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=501},tf)
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
    _searchOverlay=NEW("Frame",{Size=UDim2.new(0,380,0,320),Position=UDim2.new(0.5,-190,0,56),BackgroundColor3=BG1,BorderSizePixel=0,ZIndex=600},ScreenGui)
    CORNER(12,_searchOverlay); STROKE(GOLD,1.5,0.15,_searchOverlay)
    local hdr=NEW("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=BG2,ZIndex=601},_searchOverlay); CORNER(10,hdr)
    NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG2,BorderSizePixel=0,ZIndex=601},hdr)
    local sBox=NEW("TextBox",{Size=UDim2.new(1,-80,1,-10),Position=UDim2.new(0,12,0,5),BackgroundTransparency=1,Text="",PlaceholderText="Search features...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.GothamSemibold,TextSize=13,ZIndex=602},hdr)
    local closeS=NEW("TextButton",{Text="✕",Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-36,0.5,-14),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=14,ZIndex=602},hdr)
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
                NEW("TextLabel",{Text=r.name,Size=UDim2.new(0.6,0,0,18),Position=UDim2.new(0,12,0,4),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=603},row)
                NEW("TextLabel",{Text=r.desc,Size=UDim2.new(0.9,0,0,14),Position=UDim2.new(0,12,0,22),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=603},row)
                local tabBadge=NEW("TextLabel",{Text=r.tab,Size=UDim2.new(0,0,0,18),Position=UDim2.new(1,-8,0.5,-9),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=BG4,TextColor3=GOLD3,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=603},row)
                CORNER(4,tabBadge); NEW("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},tabBadge)
                row.MouseEnter:Connect(function() TWEEN(row,0.12,{BackgroundColor3=BG4}) end)
                row.MouseLeave:Connect(function() TWEEN(row,0.12,{BackgroundColor3=BG3}) end)
                row.MouseButton1Click:Connect(function()
                    pcall(function() _searchOverlay:Destroy() end); _searchOverlay=nil
                    -- jump to that tab
                    if Tabs and Tabs[r.tab] then Tabs[r.tab].btn:activate() end
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
    TWEEN_BACK(_searchOverlay,0.22,{Position=UDim2.new(0.5,-190,0,56)})
end

local BG0=C(4,3,10); local BG1=C(8,6,18); local BG2=C(11,9,24); local BG3=C(15,13,33)
local BG4=C(20,18,44); local BG5=C(7,6,16); local BG_HDR=C(10,9,22)
local GOLD=C(220,172,68); local GOLD2=C(255,215,115); local GOLD3=C(140,100,30); local GOLDD=C(35,26,6)
local TEXT1=C(245,242,232); local TEXT2=C(148,143,168); local TEXT3=C(60,55,82)
local COL_MAIN=C(255,215,85); local COL_FARM=C(255,105,40); local COL_TRAVEL=C(45,225,218)
local COL_FISH=C(65,165,255); local COL_STATS=C(185,95,255); local COL_PS=C(240,75,190); local COL_CFG=C(72,225,135)
local RED=C(240,60,60); local GREEN=C(55,220,130); local CYAN=C(45,225,218); local CYAND=C(5,40,38)
local PINK=C(240,75,190); local PINKD=C(42,8,48); local BLUE_A=C(65,165,255)
local ORANGE=C(255,105,40); local PURPLE=C(185,95,255); local AMBER=C(255,215,85)

-- =====================================================================
-- ICON SYSTEM (condensed)
-- =====================================================================
local function DrawIcon(parent,iconName,px,py,sz,col)
    sz=sz or 14; col=col or TEXT2
    local c=NEW("Frame",{Size=UDim2.new(0,sz,0,sz),Position=UDim2.new(0,px,0,py),BackgroundTransparency=1,BorderSizePixel=0},parent)
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
            task.defer(function() _G._GBO_ShowHub() end)
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
        if MainFrame and MainFrame.Visible then _G._GBO_HideHub()
        else _G._GBO_ShowHub() end
    end
end)

-- =====================================================================
-- MAIN FRAME
-- =====================================================================
local MainFrame=NEW("CanvasGroup",{Size=UDim2.new(0,720,0,520),Position=UDim2.new(0.5,-360,0.5,-260),BackgroundColor3=BG1,BorderSizePixel=0,ClipsDescendants=true,GroupTransparency=1},ScreenGui)
CORNER(14,MainFrame); STROKE(GOLD,1.8,0.06,MainFrame)
MainFrame.Visible=false
task.spawn(function()
    local waited=0
    while not _G._ZiliShowMain and waited<25 do task.wait(0.05);waited+=0.05 end
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

local sh1=NEW("Frame",{Size=UDim2.new(0,2,1.8,0),Position=UDim2.new(-0.12,0,-0.4,0),BackgroundColor3=GOLD2,BackgroundTransparency=0.91,ZIndex=0,BorderSizePixel=0,Rotation=16},MainFrame)
task.spawn(function() while MainFrame and MainFrame.Parent do sh1.Position=UDim2.new(-0.12,0,-0.4,0);TweenService:Create(sh1,TweenInfo.new(5.5,Enum.EasingStyle.Quad),{Position=UDim2.new(1.15,0,-0.4,0)}):Play();task.wait(10) end end)

local PARTICLE_COLORS={GOLD,GOLD2,COL_TRAVEL,COL_STATS,COL_FISH}
task.spawn(function()
    while MainFrame and MainFrame.Parent do task.wait(4);if not MainFrame or not MainFrame.Parent then break end
        local col=PARTICLE_COLORS[math.random(#PARTICLE_COLORS)];local sz=math.random(2,4);local xs=math.random(4,96)/100
        local p=NEW("Frame",{Size=UDim2.new(0,sz,0,sz),Position=UDim2.new(xs,0,1.04,0),BackgroundColor3=col,BackgroundTransparency=0.7,ZIndex=0,BorderSizePixel=0},MainFrame);CORNER(sz,p)
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
local tbGrad=Instance.new("UIGradient")
tbGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,COL_MAIN),ColorSequenceKeypoint.new(0.18,COL_FARM),ColorSequenceKeypoint.new(0.36,COL_TRAVEL),ColorSequenceKeypoint.new(0.54,COL_FISH),ColorSequenceKeypoint.new(0.72,COL_STATS),ColorSequenceKeypoint.new(0.88,COL_PS),ColorSequenceKeypoint.new(1,COL_CFG)})
tbGrad.Parent=tbLine
task.spawn(function() local t=0;while TopBar and TopBar.Parent do t+=0.015;tbGrad.Offset=Vector2.new(math.sin(t)*0.16,0);task.wait(0.1) end end)

local LogoBadge=NEW("Frame",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,12,0.5,-18),BackgroundColor3=C(10,10,26)},TopBar)
CORNER(8,LogoBadge); local badgeRing=STROKE(GOLD,2,0.1,LogoBadge)
local innerTint=NEW("Frame",{Size=UDim2.new(1,-4,1,-4),Position=UDim2.new(0,2,0,2),BackgroundColor3=C(18,15,40),BorderSizePixel=0},LogoBadge); CORNER(6,innerTint)
NEW("ImageLabel",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0.5,-11,0.5,-11),Image=LOGO_ASSET_ID,BackgroundTransparency=1,ZIndex=2},LogoBadge)
task.spawn(function() local cols={COL_MAIN,COL_TRAVEL,COL_FISH,COL_STATS,COL_PS,COL_CFG};local i=1;while TopBar and TopBar.Parent do TWEEN(badgeRing,1.4,{Color=cols[i],Transparency=0.05});task.wait(1.8);TWEEN(badgeRing,0.7,{Transparency=0.45});task.wait(0.9);i=(i%#cols)+1 end end)

NEW("TextLabel",{Text="ZILI HUB",Position=UDim2.new(0,56,0,8),Size=UDim2.new(0,88,0,18),TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=14,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},TopBar)
NEW("TextLabel",{Text="|",Position=UDim2.new(0,146,0,8),Size=UDim2.new(0,12,0,18),TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=15,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Center},TopBar)
NEW("TextLabel",{Text="GBO",Position=UDim2.new(0,160,0,8),Size=UDim2.new(0,42,0,18),TextColor3=CYAN,Font=Enum.Font.GothamBold,TextSize=14,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},TopBar)
-- Version + active feature counter
local _topSubLbl=NEW("TextLabel",{Text="v2.9  ·  PREMIUM  ·  0 active",Position=UDim2.new(0,56,0,28),Size=UDim2.new(0,220,0,12),TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=9,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},TopBar)
-- Session timer (bottom-right of TopBar)
local _sessionStart=tick()
local _sessionLbl=NEW("TextLabel",{Text="00:00",Position=UDim2.new(1,-160,0,8),Size=UDim2.new(0,60,0,16),TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=10,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right},TopBar)
Tooltip(_sessionLbl,"Session time")
-- Search button
local _searchBtn=NEW("TextButton",{Text="⌕",Position=UDim2.new(1,-165,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,28,0,28),TextColor3=GOLD2,TextSize=16,BackgroundColor3=BG3,Font=Enum.Font.Legacy,AutoButtonColor=false},TopBar)
CORNER(7,_searchBtn); STROKE(GOLD3,1,0.4,_searchBtn)
_searchBtn.MouseEnter:Connect(function() TWEEN(_searchBtn,0.15,{BackgroundColor3=BG4,TextColor3=C(255,255,255)}) end)
_searchBtn.MouseLeave:Connect(function() TWEEN(_searchBtn,0.15,{BackgroundColor3=BG3,TextColor3=GOLD2}) end)
_searchBtn.MouseButton1Click:Connect(OpenGlobalSearch)
Tooltip(_searchBtn,"Global search (all features)")

-- Session timer updater + feature counter
task.spawn(function()
    while TopBar and TopBar.Parent do
        task.wait(1)
        local elapsed=tick()-_sessionStart
        local m=math.floor(elapsed/60); local s=math.floor(elapsed%60)
        if _sessionLbl and _sessionLbl.Parent then _sessionLbl.Text=string.format("%02d:%02d",m,s) end
        local active=0
        for _,d in pairs(TogglesData) do if type(d)=="table" and d.Active then active+=1 end end
        if _topSubLbl and _topSubLbl.Parent then
            _topSubLbl.Text=string.format("v2.9  ·  PREMIUM  ·  %d active",active)
            _topSubLbl.TextColor3=active>0 and COL_CFG or TEXT3
        end
    end
end)

local function MakeCtrlBtn(text,posX,col,bgCol)
    local btn=NEW("TextButton",{Text=text,Position=UDim2.new(1,posX,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,28,0,28),TextColor3=col,TextSize=15,BackgroundColor3=bgCol or BG3,Font=Enum.Font.Legacy,AutoButtonColor=false},TopBar)
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
_G._GBO_HideHub = function() end
_G._GBO_ShowHub = function() end

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
                _autoHideTimer=0; _autoHideHidden=true; _G._GBO_HideHub()
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
local sdg=Instance.new("UIGradient"); sdg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(20,20,40)),ColorSequenceKeypoint.new(0.3,COL_TRAVEL),ColorSequenceKeypoint.new(0.6,GOLD3),ColorSequenceKeypoint.new(1,C(20,20,40))}); sdg.Rotation=90; sdg.Parent=sideDiv

local UserCard=NEW("Frame",{Size=UDim2.new(1,-14,0,58),Position=UDim2.new(0,7,1,-64),BackgroundColor3=BG3},Sidebar)
CORNER(10,UserCard); STROKE(GOLD,1,0.7,UserCard)
local ucTopBar=NEW("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=GOLD,BorderSizePixel=0},UserCard)
local ucGrad=Instance.new("UIGradient"); ucGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,COL_MAIN),ColorSequenceKeypoint.new(0.5,GOLD2),ColorSequenceKeypoint.new(1,COL_PS)}); ucGrad.Parent=ucTopBar
local UserImg=NEW("ImageLabel",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,9,0.5,-18),BackgroundColor3=BG4},UserCard)
CORNER(18,UserImg); STROKE(GOLD,1.5,0.25,UserImg)
pcall(function() UserImg.Image=Players:GetUserThumbnailAsync(LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420) end)
NEW("TextLabel",{Text=LocalPlayer.DisplayName,Position=UDim2.new(0,52,0,8),Size=UDim2.new(1,-56,0,16),TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=12,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},UserCard)
local premBadge=NEW("TextLabel",{Text="✦  PREMIUM",Position=UDim2.new(0,52,0,28),Size=UDim2.new(0,80,0,16),BackgroundColor3=GOLDD,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center},UserCard)
CORNER(4,premBadge); STROKE(GOLD3,1,0.2,premBadge)
task.spawn(function() while UserCard and UserCard.Parent do TWEEN(premBadge,2.0,{TextColor3=GOLD2});task.wait(2.5);TWEEN(premBadge,2.0,{TextColor3=C(255,230,140)});task.wait(2.5) end end)

local TabScroll=NEW("ScrollingFrame",{Size=UDim2.new(1,-8,1,-80),Position=UDim2.new(0,4,0,6),BackgroundTransparency=1,ScrollBarThickness=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),ClipsDescendants=true},Sidebar)
NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},TabScroll)
NEW("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)},TabScroll)
local PageContainer=NEW("Frame",{Size=UDim2.new(1,-178,1,-50),Position=UDim2.new(0,178,0,50),BackgroundTransparency=1},MainFrame)

-- =====================================================================
-- TAB SYSTEM
-- =====================================================================
local Tabs={}; local Pages={}; local SelectedTab=nil; local SelectedPage=nil
local TogglesData={}

local TAB_COLS={["Main"]=COL_MAIN,["Auto Farm"]=COL_FARM,["Travel"]=COL_TRAVEL,["Fishing + Merchant"]=COL_FISH,["Stats"]=COL_STATS,["Private Server"]=COL_PS,["Config"]=COL_CFG}
local TAB_ICONS={["Main"]="home",["Auto Farm"]="sword",["Travel"]="globe",["Fishing + Merchant"]="fish",["Stats"]="chart",["Config"]="gear",["Private Server"]="server"}
local SEP_COLS={FARM=COL_FARM,WORLD=COL_TRAVEL,DATA=COL_STATS,SERVER=COL_PS}

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
    local iconBg=NEW("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,10,0.5,-11),BackgroundColor3=tabColorD,BorderSizePixel=0},btn); CORNER(6,iconBg)
    DrawIcon(iconBg,iconName,4,4,14,TEXT3)
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
local AutoFarmPage,TravelPage,FishingPage,StatsPage,PrivateServerPage
if not IS_LOBBY then
    TabSep("FARM"); AutoFarmPage=AddTab("Auto Farm"); FishingPage=AddTab("Fishing + Merchant")
    TabSep("WORLD"); TravelPage=AddTab("Travel"); TabSep("DATA"); StatsPage=AddTab("Stats")
end
TabSep("SERVER"); PrivateServerPage=AddTab("Private Server"); local ConfigPage=AddTab("Config")

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
    NEW("TextLabel",{Text=label,Size=UDim2.new(1,-56,1,0),Position=UDim2.new(0,33,0,0),BackgroundTransparency=1,TextColor3=accentCol,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},bar)
    NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=accentCol,BorderSizePixel=0,BackgroundTransparency=0.55},bar)
    -- Collapse chevron
    local _collapsed=false
    local _fullH=card.Size.Y.Offset
    local chevron=NEW("TextLabel",{Text="▾",Size=UDim2.new(0,18,0,18),Position=UDim2.new(1,-22,0.5,-9),BackgroundTransparency=1,TextColor3=accentCol,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center},bar)
    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        _collapsed=not _collapsed
        if _collapsed then
            TWEEN(card,0.2,{Size=UDim2.new(1,-24,0,30)})
            TWEEN(chevron,0.2,{Rotation=90,TextColor3=TEXT3})
        else
            TWEEN(card,0.22,{Size=UDim2.new(1,-24,0,_fullH)})
            TWEEN(chevron,0.2,{Rotation=0,TextColor3=accentCol})
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
        Toast((on and "ON  " or "OFF  ")..configKey:gsub("([A-Z])"," %1"):gsub("^%s",""), on and ac or TEXT2, on and "⬡" or "○")
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
_G._GBO_HideHub = function() ToggleHub(false) end
_G._GBO_ShowHub = function() ToggleHub(true)  end

MinBtn.MouseButton1Click:Connect(function() ToggleHub(false) end)
-- NOTE: MiniLogo re-open is handled via _G._GBO_ShowHub in the InputEnded drag-fix above

-- =====================================================================
-- MAIN PAGE
-- =====================================================================
PageLayout(MainPage,14,10)
-- Register features visible on both lobby and game world
RegSearch("Auto Hide UI","Config","Auto-hide hub after inactivity","AutoHide")
RegSearch("Color Theme","Config","Switch accent color preset","")
RegSearch("Keybind Toggle","Config","Set key to show/hide hub","")

if IS_LOBBY then
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
    local RaceCard=MakeCard(MainPage,318,1); CardHeader(RaceCard,"target","RACE CHANGER",AMBER)
    RowLabel(RaceCard,"Auto Race Reroll","Select a race below · stops on match",38)
    CardToggle(RaceCard,38,"AutoRace",function(state)
        if state then RaceModule.Start(getgenv().TargetRace or "",function() SetToggleState("AutoRace",false) end) else RaceModule.Stop() end
    end,AMBER)
    RowDivider(RaceCard,74)
    local rSearchBg=NEW("Frame",{Size=UDim2.new(1,-24,0,30),Position=UDim2.new(0,12,0,82),BackgroundColor3=BG5,BorderSizePixel=0},RaceCard); CORNER(6,rSearchBg); STROKE(GOLD3,1,0.5,rSearchBg)
    NEW("TextLabel",{Size=UDim2.new(0,28,1,0),BackgroundTransparency=1,Text="🔍",TextColor3=TEXT3,Font=Enum.Font.Legacy,TextSize=13},rSearchBg)
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

    -- Skin Changer
    local skinCard=MakeCard(MainPage,124,2); CardHeader(skinCard,"user","SKIN CHANGER",GOLD2)
    RowLabel(skinCard,"Randomize Once","One-shot: randomizes all cosmetics now",34)
    CardToggle(skinCard,38,"AutoSkinDisco",function(state) if not state then return end; task.spawn(function() SkinModule.Randomize();task.wait(0.25);SetToggleState("AutoSkinDisco",false) end) end,GOLD2)
    RowDivider(skinCard,72)
    RowLabel(skinCard,"Auto Change Skin","Re-randomize every 30s when active",78)
    CardToggle(skinCard,82,"AutoChangeSkin",function(state) getgenv().AutoChangeSkin=state; if state then task.spawn(function() while getgenv().AutoChangeSkin do SkinModule.Randomize();task.wait(30) end end) end end,GOLD2)

    -- Private Server page (lobby)
    PageLayout(PrivateServerPage,14,10)
    getgenv().PSCode=getgenv().PSCode or ""; getgenv().SelectedHub=getgenv().SelectedHub or "Regular"; getgenv().SelectedSea=getgenv().SelectedSea or "Sea 1"
    local HubArgs={["Regular"]=true,["Trade Hub"]="tradeHub",["Universe Hub"]="universeHub",["Fish Hub"]="fishHub"}
    local HubButtons={}; local SeaBtns={}; local UpdateUIState; local _seaHeaderLbl
    local HUB_GRID={{id="Regular",label="Regular",icon="globe",col=COL_TRAVEL},{id="Trade Hub",label="Trade Hub",icon="coin",col=AMBER},{id="Universe Hub",label="Universe Hub",icon="target",col=COL_STATS},{id="Fish Hub",label="Fish Hub",icon="fish",col=COL_FISH}}
    local SEA_OPTS={{id="Sea 1",label="SEA 1"},{id="Sea 2",label="SEA 2"}}
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

    -- Server Setup card
    local psCard=MakeCard(PrivateServerPage,10,1); CardHeader(psCard,"server","SERVER SETUP",PINK)
    NEW("TextLabel",{Text="Private Server Code",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,36),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},psCard)
    NEW("TextLabel",{Text="Leave empty for public",Size=UDim2.new(1,-24,0,12),Position=UDim2.new(1,-150,0,37),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right},psCard)
    local psBg=NEW("Frame",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,52),BackgroundColor3=BG5,BorderSizePixel=0},psCard); CORNER(7,psBg); local psBgStrk=STROKE(GOLD3,1,0.45,psBg)
    local psBox=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Paste Private Server code here...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},psBg)
    psBox.Focused:Connect(function() TWEEN(psBgStrk,0.15,{Color=PINK}) end); psBox.FocusLost:Connect(function() TWEEN(psBgStrk,0.15,{Color=GOLD3}) end)
    TogglesData["Config_PSCode"]={Value="",HeadBtn=psBox,Callback=function(val) getgenv().PSCode=val or "";pcall(function() psBox.Text=val or "" end) end}
    psBox:GetPropertyChangedSignal("Text"):Connect(function() getgenv().PSCode=psBox.Text;TogglesData["Config_PSCode"].Value=psBox.Text end)
    RowDivider(psCard,92)
    NEW("TextLabel",{Text="Destination Hub",Size=UDim2.new(0.5,0,0,14),Position=UDim2.new(0,12,0,100),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},psCard)
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
    local seaY=HUB_START_Y+2*52+4; RowDivider(psCard,seaY-2)
    _seaHeaderLbl=NEW("TextLabel",{Text="Sea (Regular only)",Size=UDim2.new(0.55,0,0,14),Position=UDim2.new(0,12,0,seaY+4),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},psCard)
    for si2,sd in ipairs(SEA_OPTS) do
        local sb=NEW("TextButton",{Size=UDim2.new(0.5,-8,0,30),Position=UDim2.new((si2-1)*0.5,si2==1 and 5 or 3,0,seaY+22),BackgroundColor3=BG4,BackgroundTransparency=0.3,Text="",AutoButtonColor=false},psCard); CORNER(8,sb)
        local ss=STROKE(C(35,35,55),1,0.6,sb)
        local sl=NEW("TextLabel",{Text=sd.label,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center},sb)
        SeaBtns[sd.id]={Btn=sb,Strk=ss,Lbl=sl}
        sb.MouseButton1Click:Connect(function() getgenv().SelectedSea=sd.id;UpdateSeaSelection() end)
    end
    TogglesData["Config_SelectedSea"]={Value="Sea 1",Callback=function(val) getgenv().SelectedSea=val or "Sea 1";UpdateSeaSelection() end}
    TogglesData["Config_SelectedHub"]={Value="Regular",Callback=function(val) getgenv().SelectedHub=val or "Regular";UpdateHubSelection();UpdateUIState() end,UpdateFn=function() UpdateHubSelection();UpdateUIState() end}
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
    task.spawn(function() task.wait(0.05);psCard.Size=UDim2.new(1,-24,0,jnY+50);UpdateHubSelection();UpdateSeaSelection() end)

    -- Auto Join card
    local ajCard=MakeCard(PrivateServerPage,92,2); CardHeader(ajCard,"lightning","AUTO JOIN PS",PINK)
    NEW("TextLabel",{Text="Auto Join",Size=UDim2.new(0.7,0,0,20),Position=UDim2.new(0,14,0,36),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},ajCard)
    NEW("TextLabel",{Text="When ON: lobby auto-joins PS on start. Toggle saves preference only.",Size=UDim2.new(1,-24,0,22),Position=UDim2.new(0,14,0,58),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},ajCard)
    local ajPill=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-60,0,40),BackgroundColor3=BG5,Text="",AutoButtonColor=false},ajCard); CORNER(20,ajPill); local ajStrk=STROKE(TEXT3,1.2,0.3,ajPill)
    local ajThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},ajPill); CORNER(20,ajThumb)
    local autoJoinActive=false
    local function SetAutoJoin(on) autoJoinActive=on;getgenv().GBO_AutoJoin=on;ApplyPillState(ajPill,ajStrk,ajThumb,on,COL_PS,PINKD);if TogglesData["Config_AutoJoinPS"] then TogglesData["Config_AutoJoinPS"].Value=on end;if on then AutoRejoinModule._saveSession() end end
    TogglesData["Config_AutoJoinPS"]={Value=false,Callback=function(val) SetAutoJoin(val==true) end}
    ajPill.MouseButton1Click:Connect(function() SetAutoJoin(not autoJoinActive) end)

    -- Auto Rejoin card
    local arCard=MakeCard(PrivateServerPage,92,3); CardHeader(arCard,"target","AUTO REJOIN",CYAN)
    NEW("TextLabel",{Text="Auto Rejoin",Size=UDim2.new(0.7,0,0,20),Position=UDim2.new(0,14,0,36),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},arCard)
    NEW("TextLabel",{Text="Kicked → returns to lobby → auto-joins PS (needs Auto Join ON)",Size=UDim2.new(1,-24,0,22),Position=UDim2.new(0,14,0,58),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},arCard)
    CardToggle(arCard,40,"AutoRejoin",function(state) getgenv().AutoRejoin=state;if state then AutoRejoinModule.Start() else AutoRejoinModule.Stop() end end,CYAN)

    -- Lobby startup auto-join logic
    task.spawn(function()
        task.wait(2.0); local hs=HttpService; local pending=nil
        pcall(function() if isfile and isfile(AutoRejoinModule.SESSION) then local ok,data=pcall(function() return hs:JSONDecode(readfile(AutoRejoinModule.SESSION)) end);if ok and type(data)=="table" and data.autoRejoin then pending=data;pcall(function() deletefile(AutoRejoinModule.SESSION) end) end end end)
        if not pending then pcall(function() if not(isfile and isfile("gbo_multiacc.json")) then return end;local ok,mData=pcall(function() return hs:JSONDecode(readfile("gbo_multiacc.json")) end);if not ok or type(mData)~="table" then return end;local slot=mData[LocalPlayer.Name] or mData[LocalPlayer.DisplayName];if slot and type(slot)=="table" then pending={code=slot.code or "",hub=slot.hub or "Regular",sea=slot.sea or "Sea 1",autoRejoin=false,fromMultiAcc=true} end end) end
        if not pending then return end
        local pCode=pending.code or "";local pHub=pending.hub or "Regular";local pSea=pending.sea or "Sea 1"
        getgenv().PSCode=pCode;getgenv().SelectedHub=pHub;getgenv().SelectedSea=pSea
        pcall(function() psBox.Text=pCode end); UpdateHubSelection();UpdateSeaSelection()
        local shouldJoin=false
        if pending.autoRejoin then SetAutoJoin(true);shouldJoin=(pCode~="") elseif pending.fromMultiAcc then shouldJoin=(pCode~="") and (autoJoinActive==true) end
        if not shouldJoin then return end
        task.wait(0.4)
        pcall(function() ReplicatedStorage_L:WaitForChild("Events"):WaitForChild("reserved"):InvokeServer(pCode) end)
        task.spawn(function()
            local _arg=HubArgs[pHub] or true; if pHub=="Regular" then _arg=true end
            local pg=Player_L:WaitForChild("PlayerGui"); local cui=pg:WaitForChild("chooseType",20)
            if cui then local frm=cui:WaitForChild("Frame",8);if frm then local rem=frm:WaitForChild("RemoteEvent",8);if rem then task.wait(0.6);pcall(function() rem:FireServer(_arg) end);pcall(function() cui.Enabled=false end) end end end
        end)
    end)

else
    -- GAME WORLD BUILD -----------------------------------------------
    RegSearch("Island ESP","Main","Show island locations on screen","ESP_Island")
    RegSearch("Player ESP","Main","Show player positions","ESP_Player")
    RegSearch("Item ESP","Main","Show dropped items","ESP_Item")
    -- Status card
    local statusCard=MakeCard(MainPage,72,1); CardHeader(statusCard,"eye","HUB STATUS",GREEN)
    NEW("TextLabel",{Text="⬡  Connected  ·  GET BETTER OUT",Size=UDim2.new(0.65,0,0,18),Position=UDim2.new(0,14,0,34),BackgroundTransparency=1,TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},statusCard)
    NEW("TextLabel",{Text="Zili Hub  ·  v2.9.0  ·  Premium Build",Size=UDim2.new(1,-20,0,13),Position=UDim2.new(0,14,0,54),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},statusCard)
    local pingBadge=NEW("TextLabel",{Text="⬤  LIVE",Size=UDim2.new(0,68,0,20),Position=UDim2.new(1,-80,0,36),BackgroundColor3=C(5,36,18),TextColor3=GREEN,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},statusCard)
    CORNER(4,pingBadge); STROKE(GREEN,1,0.35,pingBadge)
    task.spawn(function() while statusCard and statusCard.Parent do TWEEN(pingBadge,0.9,{TextColor3=C(120,255,175)});task.wait(1.2);TWEEN(pingBadge,0.9,{TextColor3=GREEN});task.wait(1.2) end end)

    -- Quick status card
    local quickCard=MakeCard(MainPage,118,2); CardHeader(quickCard,"lightning","QUICK STATUS",AMBER)
    local QT_DATA={{"Auto Farm","AutoFarmLevel",10,34,COL_FARM},{"Auto Buso","AutoBuso",120,34,COL_FARM},{"Auto Geppo","AutoGeppo",230,34,COL_FARM},{"Auto Fish","AutoFishMerchant",10,76,COL_FISH},{"Island ESP","ESP_Island",120,76,BLUE_A},{"Travel","TravelActive",230,76,COL_TRAVEL}}
    local quickDots={}
    for _,qt in ipairs(QT_DATA) do
        local label,key,px,py,acCol=qt[1],qt[2],qt[3],qt[4],qt[5]
        local box=NEW("Frame",{Size=UDim2.new(0,102,0,32),Position=UDim2.new(0,px,0,py),BackgroundColor3=C(10,11,24)},quickCard); CORNER(7,box); STROKE(C(22,20,44),1,0,box)
        NEW("TextLabel",{Text=label,Size=UDim2.new(1,-22,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},box)
        local dot=NEW("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(1,-14,0.5,-4),BackgroundColor3=C(30,28,50),BorderSizePixel=0},box); CORNER(4,dot); quickDots[key]={dot=dot,col=acCol}
    end
    task.spawn(function() while MainFrame and MainFrame.Parent do task.wait(0.5);for key,data in pairs(quickDots) do if data.dot and data.dot.Parent then local on=TogglesData[key] and TogglesData[key].Active;TWEEN(data.dot,0.3,{BackgroundColor3=on and data.col or C(30,28,50)}) end end end end)

    -- ESP card
    local espCard=MakeCard(MainPage,148,3); CardHeader(espCard,"eye","VISUALS & ESP",BLUE_A)
    local ESP_ROWS={{"Island ESP",32,"ESP_Island",function(s) if Esp and IslandData then Esp.Toggle(s,IslandData) end end},{"Player ESP",70,"ESP_Player",function() end},{"Item ESP",108,"ESP_Item",function() end}}
    for _,row in ipairs(ESP_ROWS) do local lbl,py,key,cb=row[1],row[2],row[3],row[4];RowLabel(espCard,lbl,nil,py);if py>32 then RowDivider(espCard,py-2) end;CardToggle(espCard,py,key,cb,BLUE_A) end

    -- Private Server page (game world)
    PageLayout(PrivateServerPage,14,10)
    getgenv().PSCode=getgenv().PSCode or ""; getgenv().SelectedHub=getgenv().SelectedHub or "Regular"; getgenv().SelectedSea=getgenv().SelectedSea or "Sea 1"
    local GW_HubBtns={}; local GW_SeaBtns={}; local GW_seaHdrLbl; local GW_autoJoinActive=false; local GW_psBox
    local GW_HUB_GRID={{id="Regular",label="Regular",icon="globe",col=COL_TRAVEL},{id="Trade Hub",label="Trade Hub",icon="coin",col=AMBER},{id="Universe Hub",label="Universe Hub",icon="target",col=COL_STATS},{id="Fish Hub",label="Fish Hub",icon="fish",col=COL_FISH}}
    local GW_SEA_OPTS={{id="Sea 1",label="SEA 1"},{id="Sea 2",label="SEA 2"}}
    local function GW_ApplyPill(pill,strk,thumb,on,ac,ad) TWEEN(pill,0.22,{BackgroundColor3=on and ad or BG5});TWEEN(strk,0.22,{Color=on and ac or TEXT3,Transparency=on and 0 or 0.3});TWEEN(thumb,0.22,{BackgroundColor3=on and ac or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)}) end
    local function GW_UpdateHub()
        for _,hd in ipairs(GW_HUB_GRID) do local d=GW_HubBtns[hd.id];if not d then continue end;local sel=(hd.id==getgenv().SelectedHub);local ac=hd.col;local acd=C(math.min(255,math.floor(ac.R*255*0.15+5)),math.min(255,math.floor(ac.G*255*0.15+5)),math.min(255,math.floor(ac.B*255*0.15+5)));TWEEN(d.Btn,0.18,{BackgroundColor3=sel and acd or BG4,BackgroundTransparency=sel and 0 or 0.3});TWEEN(d.Strk,0.18,{Color=sel and ac or C(35,35,55),Transparency=sel and 0.1 or 0.6});TWEEN(d.Lbl,0.18,{TextColor3=sel and ac or TEXT2});d.Lbl.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium;for _,ch in ipairs(d.IcoBg:GetDescendants()) do if ch:IsA("Frame") then TWEEN(ch,0.18,{BackgroundColor3=sel and ac or TEXT3}) end;if ch:IsA("UIStroke") then TWEEN(ch,0.18,{Color=sel and ac or TEXT3}) end end end
        local isReg=(getgenv().SelectedHub=="Regular");if GW_seaHdrLbl then GW_seaHdrLbl.Visible=isReg end
        for _,sd in ipairs(GW_SEA_OPTS) do if GW_SeaBtns[sd.id] then GW_SeaBtns[sd.id].Btn.Visible=isReg end end
        if TogglesData["Config_SelectedHub"] then TogglesData["Config_SelectedHub"].Value=getgenv().SelectedHub end
    end
    local function GW_UpdateSea()
        for _,sd in ipairs(GW_SEA_OPTS) do local d=GW_SeaBtns[sd.id];if not d then continue end;local sel=(getgenv().SelectedSea==sd.id);TWEEN(d.Btn,0.15,{BackgroundColor3=sel and C(8,18,44) or BG4,BackgroundTransparency=sel and 0 or 0.3});TWEEN(d.Strk,0.15,{Color=sel and COL_FISH or C(35,35,55),Transparency=sel and 0.1 or 0.6});TWEEN(d.Lbl,0.15,{TextColor3=sel and COL_FISH or TEXT2});d.Lbl.Font=sel and Enum.Font.GothamBold or Enum.Font.GothamMedium end
        if TogglesData["Config_SelectedSea"] then TogglesData["Config_SelectedSea"].Value=getgenv().SelectedSea end
    end

    -- Current server card
    local isInPS=(game.PrivateServerId~=""); local psIdShort=isInPS and (string.sub(game.PrivateServerId,1,8).."…"..string.sub(game.PrivateServerId,-5)) or "Public Server"
    local gwSrvCard=MakeCard(PrivateServerPage,70,0); CardHeader(gwSrvCard,isInPS and "server" or "globe","CURRENT SERVER",isInPS and GREEN or RED)
    local srvBadge=NEW("TextLabel",{Text=isInPS and "PRIVATE" or "PUBLIC",Size=UDim2.new(0,78,0,20),Position=UDim2.new(1,-90,0,32),BackgroundColor3=isInPS and C(5,36,18) or C(36,8,8),TextColor3=isInPS and GREEN or RED,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center},gwSrvCard)
    CORNER(5,srvBadge); STROKE(isInPS and GREEN or RED,1,0.3,srvBadge)
    NEW("TextLabel",{Text="ID: "..psIdShort,Size=UDim2.new(1,-106,0,14),Position=UDim2.new(0,12,0,34),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},gwSrvCard)
    NEW("TextLabel",{Text="Job: "..string.sub(game.JobId,1,14).."…",Size=UDim2.new(1,-106,0,12),Position=UDim2.new(0,12,0,50),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},gwSrvCard)
    local copyBtn=NEW("TextButton",{Text="COPY CODE",Size=UDim2.new(0,78,0,18),Position=UDim2.new(1,-90,0,50),BackgroundColor3=C(6,22,18),TextColor3=CYAN,Font=Enum.Font.GothamBold,TextSize=8,AutoButtonColor=false},gwSrvCard); CORNER(5,copyBtn); STROKE(CYAN,1,0.5,copyBtn)
    copyBtn.MouseButton1Click:Connect(function() local code="";pcall(function() code=game.PrivateServerAccessKey or game.PrivateServerId or "" end);if code~="" then pcall(function() setclipboard(code) end);copyBtn.Text="COPIED";task.delay(2,function() if copyBtn and copyBtn.Parent then copyBtn.Text="COPY CODE" end end) end end)

    -- GW Server Setup card
    local gwCfgCard=MakeCard(PrivateServerPage,10,1); CardHeader(gwCfgCard,"server","SERVER SETUP",PINK)
    NEW("TextLabel",{Text="Private Server Code",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,36),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},gwCfgCard)
    local gwPsBg=NEW("Frame",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,52),BackgroundColor3=BG5,BorderSizePixel=0},gwCfgCard); CORNER(7,gwPsBg); local gwPsStrk=STROKE(GOLD3,1,0.45,gwPsBg)
    GW_psBox=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Paste Private Server code here...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},gwPsBg)
    GW_psBox.Focused:Connect(function() TWEEN(gwPsStrk,0.15,{Color=PINK}) end); GW_psBox.FocusLost:Connect(function() TWEEN(gwPsStrk,0.15,{Color=GOLD3}) end)
    TogglesData["Config_PSCode"]={Value="",HeadBtn=GW_psBox,Callback=function(val) getgenv().PSCode=val or "";pcall(function() GW_psBox.Text=val or "" end) end}
    GW_psBox:GetPropertyChangedSignal("Text"):Connect(function() getgenv().PSCode=GW_psBox.Text;if TogglesData["Config_PSCode"] then TogglesData["Config_PSCode"].Value=GW_psBox.Text end end)
    RowDivider(gwCfgCard,92)
    NEW("TextLabel",{Text="Destination Hub",Size=UDim2.new(0.5,0,0,14),Position=UDim2.new(0,12,0,100),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},gwCfgCard)
    local GW_HUB_Y=118
    for hi,hd in ipairs(GW_HUB_GRID) do
        local ci=(hi-1)%2;local ri=math.floor((hi-1)/2)
        local hBtn=NEW("TextButton",{Size=UDim2.new(0.5,-8,0,46),Position=UDim2.new(ci*0.5,ci==0 and 5 or 3,0,GW_HUB_Y+ri*52),BackgroundColor3=BG4,BackgroundTransparency=0.3,Text="",AutoButtonColor=false},gwCfgCard); CORNER(9,hBtn)
        local hs2=STROKE(C(35,35,55),1,0.6,hBtn)
        local hIco=NEW("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,8,0.5,-11),BackgroundColor3=BG5,BorderSizePixel=0},hBtn); CORNER(6,hIco); DrawIcon(hIco,hd.icon,4,4,14,TEXT3)
        local hLbl=NEW("TextLabel",{Text=hd.label,Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,34,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},hBtn)
        GW_HubBtns[hd.id]={Btn=hBtn,Strk=hs2,Lbl=hLbl,IcoBg=hIco}
        hBtn.MouseEnter:Connect(function() if hd.id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundTransparency=0.15}) end end)
        hBtn.MouseLeave:Connect(function() if hd.id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundTransparency=0.3}) end end)
        hBtn.MouseButton1Click:Connect(function() getgenv().SelectedHub=hd.id;GW_UpdateHub() end)
    end
    local GW_seaY=GW_HUB_Y+2*52+4; RowDivider(gwCfgCard,GW_seaY-2)
    GW_seaHdrLbl=NEW("TextLabel",{Text="Sea (Regular only)",Size=UDim2.new(0.55,0,0,14),Position=UDim2.new(0,12,0,GW_seaY+4),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},gwCfgCard)
    for si2,sd in ipairs(GW_SEA_OPTS) do
        local sb=NEW("TextButton",{Size=UDim2.new(0.5,-8,0,30),Position=UDim2.new((si2-1)*0.5,si2==1 and 5 or 3,0,GW_seaY+22),BackgroundColor3=BG4,BackgroundTransparency=0.3,Text="",AutoButtonColor=false},gwCfgCard); CORNER(8,sb)
        local ss=STROKE(C(35,35,55),1,0.6,sb)
        local sl=NEW("TextLabel",{Text=sd.label,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center},sb)
        GW_SeaBtns[sd.id]={Btn=sb,Strk=ss,Lbl=sl}
        sb.MouseButton1Click:Connect(function() getgenv().SelectedSea=sd.id;GW_UpdateSea() end)
    end
    TogglesData["Config_SelectedHub"]={Value="Regular",Callback=function(val) getgenv().SelectedHub=val or "Regular";GW_UpdateHub() end}
    TogglesData["Config_SelectedSea"]={Value="Sea 1",Callback=function(val) getgenv().SelectedSea=val or "Sea 1";GW_UpdateSea() end}
    task.spawn(function() task.wait(0.05);gwCfgCard.Size=UDim2.new(1,-24,0,GW_seaY+60);GW_UpdateHub();GW_UpdateSea() end)

    -- GW Auto Join + Rejoin card
    local gwCtrlCard=MakeCard(PrivateServerPage,188,2); CardHeader(gwCtrlCard,"lightning","AUTO JOIN  ·  REJOIN",PINK)
    RowLabel(gwCtrlCard,"Auto Join PS",nil,36)
    local gwAjPill=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-60,0,40),BackgroundColor3=BG5,Text="",AutoButtonColor=false},gwCtrlCard); CORNER(20,gwAjPill); local gwAjStrk=STROKE(TEXT3,1.2,0.3,gwAjPill)
    local gwAjThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},gwAjPill); CORNER(20,gwAjThumb)
    local function GW_SetAutoJoin(on)
        GW_autoJoinActive=on;getgenv().GBO_AutoJoin=on;GW_ApplyPill(gwAjPill,gwAjStrk,gwAjThumb,on,COL_PS,PINKD)
        if TogglesData["Config_AutoJoinPS"] then TogglesData["Config_AutoJoinPS"].Value=on end
        if on then AutoRejoinModule._saveSession();local inPS=false;pcall(function() local rc=game:GetService("ReplicatedStorage"):FindFirstChild("reservedCode");if rc and rc.Value and rc.Value~="" then inPS=true end end);if not inPS then inPS=(game.PrivateServerId~="") end;if not inPS then task.spawn(function() task.wait(0.5);pcall(function() TeleportService_L:Teleport(PLACE_LOBBY,Player_L) end) end) end end
    end
    TogglesData["Config_AutoJoinPS"]={Value=false,Callback=function(val) GW_SetAutoJoin(val==true) end}
    gwAjPill.MouseButton1Click:Connect(function() GW_SetAutoJoin(not GW_autoJoinActive) end)
    RowDivider(gwCtrlCard,78)
    local gwJoinBtn=NEW("TextButton",{Size=UDim2.new(1,-24,0,34),Position=UDim2.new(0,12,0,84),BackgroundColor3=PINKD,Text="",AutoButtonColor=false},gwCtrlCard); CORNER(9,gwJoinBtn); STROKE(PINK,1.5,0.2,gwJoinBtn)
    DrawIcon(gwJoinBtn,"server",12,7,20,PINK)
    NEW("TextLabel",{Text=isInPS and "SAVE SESSION" or "JOIN NOW",Size=UDim2.new(1,-46,0,16),Position=UDim2.new(0,40,0,9),BackgroundTransparency=1,TextColor3=PINK,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},gwJoinBtn)
    gwJoinBtn.MouseEnter:Connect(function() TWEEN(gwJoinBtn,0.15,{BackgroundColor3=C(55,12,48)}) end); gwJoinBtn.MouseLeave:Connect(function() TWEEN(gwJoinBtn,0.15,{BackgroundColor3=PINKD}) end)
    gwJoinBtn.MouseButton1Click:Connect(function() TWEEN(gwJoinBtn,0.08,{BackgroundColor3=C(80,20,65)});task.wait(0.1);TWEEN(gwJoinBtn,0.15,{BackgroundColor3=PINKD});AutoRejoinModule._saveSession();GW_SetAutoJoin(true) end)
    RowDivider(gwCtrlCard,124)
    RowLabel(gwCtrlCard,"Auto Rejoin","Kicked → lobby → auto-joins PS",130)
    local gwArPill=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-60,0,134),BackgroundColor3=BG5,Text="",AutoButtonColor=false},gwCtrlCard); CORNER(20,gwArPill); local gwArStrk=STROKE(TEXT3,1.2,0.3,gwArPill)
    local gwArThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},gwArPill); CORNER(20,gwArThumb)
    TogglesData["GW_AutoRejoin"]={Active=false,Btn=gwArPill,Strk=gwArStrk,Thumb=gwArThumb,AccentCol=CYAN,AccentDark=CYAND,Callback=function(state) getgenv().AutoRejoin=state;if state then AutoRejoinModule.Start() else AutoRejoinModule.Stop() end end}
    gwArPill.MouseButton1Click:Connect(function() local d=TogglesData["GW_AutoRejoin"];d.Active=not d.Active;local on=d.Active;GW_ApplyPill(gwArPill,gwArStrk,gwArThumb,on,CYAN,CYAND);if d.Callback then d.Callback(on) end end)
    RowDivider(gwCtrlCard,166)
    NEW("TextLabel",{Text="Auto Rejoin only works when Auto Join PS is also ON",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,14,0,170),BackgroundTransparency=1,TextColor3=C(80,65,120),Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},gwCtrlCard)
end -- end IS_LOBBY / else

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
_pageBuildFns["Auto Farm"] = function()
    RegSearch("Start Level Farm","Auto Farm","Auto kills enemies, respawns","AutoFarmLevel")
    RegSearch("Auto Farm for Fishing","Auto Farm","Switches farm/fish by level","AutoFarmForFishing")
    RegSearch("Auto Get Buso","Auto Farm","Auto buy Buso Haki at LVL 80","AutoBuso")
    RegSearch("Auto Get Geppo","Auto Farm","Auto buy Geppo at LVL 125","AutoGeppo")
    PageLayout(AutoFarmPage,14,10)
    local lfCard=MakeCard(AutoFarmPage,144,1); CardHeader(lfCard,"sword","LEVEL FARM",AMBER)
    RowLabel(lfCard,"Start Level Farm","Auto kills enemies · respawns",34)
    CardToggle(lfCard,44,"AutoFarmLevel",function(state) AutoFarmLevel.Toggle(state) end,COL_FARM)
    RowDivider(lfCard,80)
    RowLabel(lfCard,"Auto Farm Level for Fishing","< 375 → Farm  ·  ≥ 375 → Fish",84)
    local function GetPlayerLevel() local level=0;pcall(function() local sf=game:GetService("ReplicatedStorage"):FindFirstChild("Stats"..LocalPlayer.Name);local sn=sf and sf:FindFirstChild("Stats");local ln=sn and sn:FindFirstChild("Level");if ln then level=ln.Value end end);return level end
    local function SetToggle(key,state)
        local d=TogglesData[key];if not d or d.Active==state then return end; d.Active=state; local on=state
        local ac=d.AccentCol or GOLD2;local ad=d.AccentDark or GOLDD
        TWEEN(d.Btn,0.22,{BackgroundColor3=on and ad or BG5});TWEEN(d.Strk,0.22,{Color=on and ac or TEXT3,Transparency=on and 0 or 0.3})
        local tf=d.Thumb or d.Btn:FindFirstChildOfClass("Frame");if tf then TWEEN(tf,0.22,{BackgroundColor3=on and ac or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)}) end
        if key=="AutoFishMerchant" and FishMasterBar then TWEEN(FishMasterBar,0.35,{BackgroundColor3=on and GREEN or GOLD}) end
        if d.Callback then d.Callback(state) end
    end
    CardToggle(lfCard,96,"AutoFarmForFishing",function(state)
        if not state then SetToggle("AutoFarmLevel",false);SetToggle("AutoFishMerchant",false)
        else task.spawn(function() local level=GetPlayerLevel();if level<375 then SetToggle("AutoFarmLevel",true);SetToggle("AutoFishMerchant",false) else SetToggle("AutoFarmLevel",false);SetToggle("AutoFishMerchant",true) end end) end
    end,COL_FISH)
    task.spawn(function() while MainFrame and MainFrame.Parent do task.wait(3);if not TogglesData["AutoFarmForFishing"] or not TogglesData["AutoFarmForFishing"].Active then continue end;local level=GetPlayerLevel();if level<375 then SetToggle("AutoFarmLevel",true);SetToggle("AutoFishMerchant",false) else SetToggle("AutoFarmLevel",false);SetToggle("AutoFishMerchant",true) end end end)

    local mfCard=MakeCard(AutoFarmPage,148,2); CardHeader(mfCard,"fist","MISC FARM",GOLD2)
    local MISC_ROWS={{"Auto Get Buso","REQ → LVL 80  ·  25,000 PELI",36,"AutoBuso",function(s) if AutoGetBuso then AutoGetBuso.Toggle(s) end end},{"Auto Get Geppo","REQ → LVL 125  ·  50,000 PELI",96,"AutoGeppo",nil}}
    for i,row in ipairs(MISC_ROWS) do
        local label,req,py,key,baseCb=row[1],row[2],row[3],row[4],row[5];RowLabel(mfCard,label,req,py);if i>1 then RowDivider(mfCard,py-2) end
        local btn,strk,thumb=CardToggle(mfCard,py+8,key,baseCb,COL_FARM)
        if key=="AutoGeppo" then
            TogglesData[key].Callback=function(state)
                if AutoGeppoFunc then AutoGeppoFunc.Toggle(state) end
                if state then task.spawn(function() while _G.AutoGeppo do task.wait(0.5) end;if TogglesData[key].Active then TogglesData[key].Active=false;TWEEN(btn,0.2,{BackgroundColor3=BG5});TWEEN(strk,0.2,{Color=TEXT3,Transparency=0.3});TWEEN(thumb,0.2,{BackgroundColor3=TEXT3,Position=UDim2.new(0,4,0.5,-9)}) end end) end
            end
        end
    end
end -- _pageBuildFns["Auto Farm"]

-- ── TRAVEL ─────────────────────────────────────────────────────────────
_pageBuildFns["Travel"] = function()
    RegSearch("Island Teleport","Travel","Tween to any island on map","TravelActive")
    RegSearch("Auto Enter 2nd Sea","Travel","Auto travel to 2nd sea portal","Auto2ndSea")
    PageLayout(TravelPage,14,10)
    local tpCard=MakeCard(TravelPage,148,1); tpCard.ZIndex=5; CardHeader(tpCard,"globe","ISLAND TELEPORT",CYAN)
    RowLabel(tpCard,"Target Island","Select destination",36)
    local SearchBox=NEW("TextBox",{Size=UDim2.new(0,172,0,30),Position=UDim2.new(1,-186,0,42),BackgroundColor3=BG5,Text="",PlaceholderText="Search Island...",TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=12,ClearTextOnFocus=true,ZIndex=6},tpCard)
    CORNER(7,SearchBox); local BoxStroke=STROKE(GOLD3,1,0,SearchBox); SearchBox.Focused:Connect(function() TWEEN(BoxStroke,0.2,{Color=GOLD2}) end); SearchBox.FocusLost:Connect(function() TWEEN(BoxStroke,0.2,{Color=GOLD3}) end)
    local DropdownScroll=NEW("ScrollingFrame",{Size=UDim2.new(0,172,0,150),Position=UDim2.new(0,0,0,0),BackgroundColor3=BG0,BorderSizePixel=0,ScrollBarThickness=2,Visible=false,ZIndex=200,ScrollBarImageColor3=GOLD,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)},ScreenGui)
    CORNER(7,DropdownScroll); STROKE(GOLD3,1,0,DropdownScroll)
    NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2)},DropdownScroll); NEW("UIPadding",{PaddingTop=UDim.new(0,4)},DropdownScroll)
    local Islands={};if IslandData then for n,_ in pairs(IslandData) do table.insert(Islands,n) end;table.sort(Islands) end
    local IslandButtons={}
    for _,islandName in ipairs(Islands) do
        local btn=NEW("TextButton",{Size=UDim2.new(1,-8,0,26),BackgroundTransparency=1,ZIndex=201,Text="  "..islandName,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},DropdownScroll); CORNER(4,btn)
        btn.MouseEnter:Connect(function() TWEEN(btn,0.12,{BackgroundTransparency=0.85,BackgroundColor3=BG4,TextColor3=GOLD2});btn.Font=Enum.Font.GothamBold end)
        btn.MouseLeave:Connect(function() TWEEN(btn,0.12,{BackgroundTransparency=1,TextColor3=TEXT2});btn.Font=Enum.Font.Gotham end)
        btn.MouseButton1Click:Connect(function() SearchBox.Text=string.gsub(btn.Text,"^%s*(.-)%s*$","%1");DropdownScroll.Visible=false end)
        table.insert(IslandButtons,btn)
    end
    SearchBox.Focused:Connect(function() local ap=SearchBox.AbsolutePosition;local as=SearchBox.AbsoluteSize;DropdownScroll.Position=UDim2.new(0,ap.X,0,ap.Y+as.Y+2);DropdownScroll.Size=UDim2.new(0,as.X,0,150);DropdownScroll.Visible=true end)
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function() local s=string.lower(SearchBox.Text);local cs=string.gsub(s,"'","");for _,b in ipairs(IslandButtons) do local n=string.lower(string.gsub(b.Text,"^%s*(.-)%s*$","%1"));local cn=string.gsub(n,"'","");b.Visible=s=="" or (string.find(cn,cs,1,true) and true or false) end end)
    local Mouse=LocalPlayer:GetMouse()
    UIS.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then local mx,my=Mouse.X,Mouse.Y;local dp,ds=DropdownScroll.AbsolutePosition,DropdownScroll.AbsoluteSize;local bp,bs=SearchBox.AbsolutePosition,SearchBox.AbsoluteSize;local inD=mx>=dp.X and mx<=dp.X+ds.X and my>=dp.Y and my<=dp.Y+ds.Y;local inB=mx>=bp.X and mx<=bp.X+bs.X and my>=bp.Y and my<=bp.Y+bs.Y;if not inD and not inB then DropdownScroll.Visible=false end end end)
    RowDivider(tpCard,104); RowLabel(tpCard,"Start Travel","Navigate automatically",110)
    local ToggleBtn=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-58,0,112),BackgroundColor3=BG5,Text="",AutoButtonColor=false},tpCard); CORNER(20,ToggleBtn); local ToggleStroke=STROKE(TEXT3,1,0.3,ToggleBtn)
    local TravelThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},ToggleBtn); CORNER(20,TravelThumb)
    ToggleBtn.MouseButton1Click:Connect(function()
        if not TweenSys then return end
        if TweenSys.IsTeleporting then TweenSys.Stop();TWEEN(ToggleBtn,0.2,{BackgroundColor3=BG5});TWEEN(ToggleStroke,0.2,{Color=TEXT3,Transparency=0.3});TWEEN(TravelThumb,0.2,{BackgroundColor3=TEXT3,Position=UDim2.new(0,4,0.5,-9)})
        else local td=IslandData and IslandData[SearchBox.Text];if not td then return end;TweenSys.Start(td);TWEEN(ToggleBtn,0.2,{BackgroundColor3=C(5,38,40)});TWEEN(ToggleStroke,0.2,{Color=COL_TRAVEL,Transparency=0});TWEEN(TravelThumb,0.2,{BackgroundColor3=COL_TRAVEL,Position=UDim2.new(1,-22,0.5,-9)}) end
    end)
    local sea2Card=MakeCard(TravelPage,90,2); CardHeader(sea2Card,"wave","AUTO 2ND SEA",BLUE_A)
    RowLabel(sea2Card,"Auto Enter 2nd Sea","Auto travel to 2nd sea portal",32); CardToggle(sea2Card,40,"Auto2ndSea",function(state) _G.Auto2ndSea=state end,COL_TRAVEL); RowDivider(sea2Card,72)
    NEW("TextLabel",{Text="Requires Level 700+  ·  Finish all quests",Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,14,0,76),BackgroundTransparency=1,TextColor3=GOLD3,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},sea2Card)
end -- _pageBuildFns["Travel"]

-- ── FISHING + MERCHANT ─────────────────────────────────────────────────
_pageBuildFns["Fishing + Merchant"] = function()
    RegSearch("Auto Fishing + Merchant","Fishing + Merchant","Auto catch, sell, restock bait","AutoFishMerchant")
    RegSearch("Auto Store Fruit","Fishing + Merchant","Auto store fruit to inventory","AutoStoreFruit")
    RegSearch("Auto Drop Fruit","Fishing + Merchant","Drop fruit when inventory full","AutoDropFruit")
    PageLayout(FishingPage,14,10)
    local fmCard=MakeCard(FishingPage,80,1); CardHeader(fmCard,"fish","FISHING + MERCHANT FARM",ORANGE)
    FishMasterBar=NEW("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=GOLD,BorderSizePixel=0},fmCard); CORNER(2,FishMasterBar)
    NEW("TextLabel",{Text="Enable Auto Fishing + Merchant",Size=UDim2.new(0.75,0,0,20),Position=UDim2.new(0,14,0,32),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left},fmCard)
    NEW("TextLabel",{Text="Auto catch  ·  sell  ·  restock bait in loop",Size=UDim2.new(0.75,0,0,14),Position=UDim2.new(0,14,0,52),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},fmCard)
    local StartFishToggle=NEW("TextButton",{Size=UDim2.new(0,48,0,26),Position=UDim2.new(1,-58,0,40),BackgroundColor3=BG5,Text="",AutoButtonColor=false},fmCard); CORNER(20,StartFishToggle); local FishToggleStroke=STROKE(TEXT3,1,0.3,StartFishToggle)
    local FishThumb=NEW("Frame",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,4,0.5,-9),BackgroundColor3=TEXT3,BorderSizePixel=0},StartFishToggle); CORNER(20,FishThumb)
    TogglesData["AutoFishMerchant"]={Active=false,Btn=StartFishToggle,Strk=FishToggleStroke,Thumb=FishThumb,AccentCol=COL_FISH,AccentDark=C(8,20,42),MasterBar=FishMasterBar,Callback=function(state) _G.AutoFishMerchant=state;if state then AutoFishMerchantModule.Start(TogglesData) else AutoFishMerchantModule.Stop() end end}
    StartFishToggle.MouseButton1Click:Connect(function()
        local d=TogglesData["AutoFishMerchant"];d.Active=not d.Active;local on=d.Active;local ac=COL_FISH;local ad=C(8,20,42)
        TWEEN(StartFishToggle,0.22,{BackgroundColor3=on and ad or BG5});TWEEN(FishToggleStroke,0.22,{Color=on and ac or TEXT3,Transparency=on and 0 or 0.3});TWEEN(FishThumb,0.22,{BackgroundColor3=on and ac or TEXT3,Position=on and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,4,0.5,-9)})
        TWEEN(FishMasterBar,0.35,{BackgroundColor3=on and COL_FISH or GOLD});if d.Callback then d.Callback(on) end
    end)

    -- Live stats card
    local fsCard=MakeCard(FishingPage,132,2); fsCard.BackgroundColor3=C(8,9,18)
    local fsHeader=NEW("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=BG_HDR},fsCard); CORNER(8,fsHeader)
    NEW("Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BackgroundColor3=BG_HDR,BorderSizePixel=0},fsHeader)
    local fsIconBg=NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,7,0,4),BackgroundColor3=C(28,14,4)},fsHeader); CORNER(4,fsIconBg); DrawIcon(fsIconBg,"chart",2,2,12,ORANGE)
    NEW("TextLabel",{Text="LIVE STATS",Size=UDim2.new(0,100,1,0),Position=UDim2.new(0,30,0,0),BackgroundTransparency=1,TextColor3=ORANGE,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},fsHeader)
    local FISH_STAT_DEF={{"chest","MYTHIC","—","MythicChest",AMBER,1,0},{"arrows","LEG BAIT","—","LegBait",PURPLE,1,1},{"coin","PELI","0","Peli",CYAN,2,0},{"bottle","BAIT","—","Bait",ORANGE,2,1}}
    local FishStatValues={}
    NEW("Frame",{Size=UDim2.new(0,1,0,90),Position=UDim2.new(0.5,0,0,24),BackgroundColor3=C(28,26,48),BorderSizePixel=0},fsCard)
    NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,78),BackgroundColor3=C(28,26,48),BorderSizePixel=0},fsCard)
    for _,def in ipairs(FISH_STAT_DEF) do
        local iconName,lbl,val,key,accentC,row,col=def[1],def[2],def[3],def[4],def[5],def[6],def[7]
        local rowY=(row==1) and 26 or 80;local xScale=col*0.5;local cellMid=xScale+0.25
        local iconCell=NEW("Frame",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(cellMid,-13,0,rowY+2),BackgroundColor3=C(math.min(255,math.floor(accentC.R*255*0.14+8)),math.min(255,math.floor(accentC.G*255*0.14+8)),math.min(255,math.floor(accentC.B*255*0.14+8))),BorderSizePixel=0},fsCard); CORNER(6,iconCell); DrawIcon(iconCell,iconName,3,3,20,accentC)
        local valLbl=NEW("TextLabel",{Text=val,Size=UDim2.new(0.5,-4,0,20),Position=UDim2.new(xScale,2,0,rowY+30),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Center},fsCard)
        NEW("TextLabel",{Text=lbl,Size=UDim2.new(0.5,-4,0,11),Position=UDim2.new(xScale,2,0,rowY+52),BackgroundTransparency=1,TextColor3=accentC,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center},fsCard)
        FishStatValues[key]=valLbl
    end
    local fsStatusLbl=NEW("TextLabel",{Text="Status: Idle",Size=UDim2.new(1,-8,0,12),Position=UDim2.new(0,4,0,118),BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center},fsCard)
    getgenv().GBO_SetFishStatus=function(msg) pcall(function() if fsStatusLbl and fsStatusLbl.Parent then fsStatusLbl.Text="Status: "..(msg or "Idle") end end) end
    local _lastMythic=0
    task.spawn(function()
        while fsCard and fsCard.Parent do task.wait(2.5)
            pcall(function()
                local sf=game:GetService("ReplicatedStorage"):FindFirstChild("Stats"..LocalPlayer.Name);if not sf then return end
                local inv={}; local invNode=sf:FindFirstChild("Inventory");invNode=invNode and invNode:FindFirstChild("Inventory")
                if invNode then local ok,decoded=pcall(function() return HttpService:JSONDecode(invNode.Value) end);if ok and type(decoded)=="table" then inv=decoded end end
                local peliVal="0";local sn=sf:FindFirstChild("Stats");local pn=sn and sn:FindFirstChild("Peli");if pn then peliVal=tostring(pn.Value) end
                local bait=_G.TargetBait or "Common Fish Bait"
                local mythicCount=inv["Mythical Fruit Chest"] or 0
                -- Toast + tab badge when a new Mythic chest drops
                if mythicCount > _lastMythic then
                    local gained=mythicCount-_lastMythic
                    Toast("+"..gained.." Mythic Chest".. (gained>1 and "s" or "").." obtained!", AMBER, "⬡")
                    TabBadge("Fishing + Merchant", mythicCount, AMBER)
                end
                _lastMythic=mythicCount
                local updates={MythicChest=tostring(mythicCount),LegBait=tostring(inv["Legendary Fish Bait"] or 0),Peli=peliVal,Bait=tostring(inv[bait] or 0)}
                for key,val in pairs(updates) do if FishStatValues[key] then FishStatValues[key].Text=val end end
            end)
        end
    end)

    -- Fishing config card
    local fcCard=MakeCard(FishingPage,530,3); CardHeader(fcCard,"gear","CONFIGURATION",GOLD)
    local function CreateDropdown(parent,titleText,options,defaultSelect,posY,configKey,isMulti,showSearch)
        NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,posY),BackgroundTransparency=1,Text=titleText,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},parent)
        local headBtn=NEW("TextButton",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,posY-2),BackgroundColor3=BG5,TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=11,Text=isMulti and "Select..." or (defaultSelect or "Select..."),AutoButtonColor=false},parent); CORNER(5,headBtn); local headStroke=STROKE(GOLD3,1,0,headBtn)
        local dropScroll=NEW("ScrollingFrame",{Size=UDim2.new(0,158,0,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=BG0,BorderSizePixel=0,ScrollBarThickness=2,Visible=false,ZIndex=200,ScrollBarImageColor3=GOLD,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)},ScreenGui)
        CORNER(5,dropScroll); STROKE(GOLD3,1,0,dropScroll); NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2)},dropScroll); NEW("UIPadding",{PaddingTop=UDim.new(0,3)},dropScroll)
        local searchInput; if showSearch then searchInput=NEW("TextBox",{Size=UDim2.new(1,-6,0,22),BackgroundTransparency=1,Text="",PlaceholderText="Search...",TextColor3=TEXT1,Font=Enum.Font.Gotham,TextSize=11,PlaceholderColor3=TEXT3,ZIndex=201},dropScroll) end
        local initVal=isMulti and {} or nil
        local function defaultCallback(val)
            if isMulti then local ct=0;for _,b in ipairs(dropScroll:GetChildren()) do if b:IsA("TextButton") then local sel=type(val)=="table" and val[b.Name]==true;if sel then TWEEN(b,0.1,{TextColor3=GOLD2});b.Font=Enum.Font.GothamBold;if not b:FindFirstChild("TickMark") then NEW("TextLabel",{Name="TickMark",Text="✓",TextColor3=GOLD2,TextXAlignment=Enum.TextXAlignment.Right,Size=UDim2.new(1,-5,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=202},b) end;ct+=1 else TWEEN(b,0.1,{TextColor3=TEXT2});b.Font=Enum.Font.Gotham;local tm=b:FindFirstChild("TickMark");if tm then tm:Destroy() end end end end;headBtn.Text=ct>0 and (ct.." Selected") or "Select..."
            else for _,b in ipairs(dropScroll:GetChildren()) do if b:IsA("TextButton") then TWEEN(b,0.1,{TextColor3=b.Name==tostring(val) and GOLD2 or TEXT2});b.Font=b.Name==tostring(val) and Enum.Font.GothamBold or Enum.Font.Gotham end end;headBtn.Text=(val~=nil and tostring(val)~="") and tostring(val) or "Select..." end
        end
        TogglesData[configKey]={Value=initVal,Callback=defaultCallback,HeadBtn=headBtn}
        if not isMulti and defaultSelect then TogglesData[configKey].Value=defaultSelect end
        local function openDrop() local absPos=headBtn.AbsolutePosition;local absSize=headBtn.AbsoluteSize;dropScroll.Position=UDim2.new(0,absPos.X,0,absPos.Y+absSize.Y+2);dropScroll.Size=UDim2.new(0,absSize.X,0,150);dropScroll.Visible=true;TWEEN(headStroke,0.15,{Color=GOLD2});if showSearch and searchInput then searchInput:CaptureFocus() end end
        local function closeDrop() dropScroll.Visible=false;TWEEN(headStroke,0.15,{Color=GOLD3}) end
        headBtn.MouseButton1Click:Connect(function() if dropScroll.Visible then closeDrop() else openDrop() end end)
        UIS.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 and dropScroll.Visible then local mx,my=inp.Position.X,inp.Position.Y;local dp,ds=dropScroll.AbsolutePosition,dropScroll.AbsoluteSize;local bp,bs=headBtn.AbsolutePosition,headBtn.AbsoluteSize;if not(mx>=dp.X and mx<=dp.X+ds.X and my>=dp.Y and my<=dp.Y+ds.Y) and not(mx>=bp.X and mx<=bp.X+bs.X and my>=bp.Y and my<=bp.Y+bs.Y) then closeDrop() end end end)
        if showSearch and searchInput then searchInput:GetPropertyChangedSignal("Text"):Connect(function() local ft=searchInput.Text:lower();for _,b in ipairs(dropScroll:GetChildren()) do if b:IsA("TextButton") then b.Visible=ft=="" or (b.Name:lower():find(ft,1,true)~=nil) end end end) end
        for _,opt in ipairs(options) do
            local btn=NEW("TextButton",{Size=UDim2.new(1,-6,0,24),BackgroundTransparency=1,ZIndex=201,Text="  "..opt,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Name=opt,AutoButtonColor=false},dropScroll); CORNER(3,btn); btn.TextColor3=TEXT2
            btn.MouseEnter:Connect(function() TWEEN(btn,0.1,{BackgroundTransparency=0.85,BackgroundColor3=BG4,TextColor3=GOLD2});btn.Font=Enum.Font.GothamSemibold end)
            btn.MouseLeave:Connect(function() local isSel=isMulti and TogglesData[configKey].Value[opt] or (not isMulti and TogglesData[configKey].Value==opt);if not isSel then TWEEN(btn,0.1,{BackgroundTransparency=1,TextColor3=TEXT2});btn.Font=Enum.Font.Gotham end end)
            btn.MouseButton1Click:Connect(function()
                if isMulti then local cur=TogglesData[configKey].Value;cur[opt]=not cur[opt];if cur[opt] then TWEEN(btn,0.1,{TextColor3=GOLD2});btn.Font=Enum.Font.GothamBold;if not btn:FindFirstChild("TickMark") then NEW("TextLabel",{Name="TickMark",Text="✓",TextColor3=GOLD2,TextXAlignment=Enum.TextXAlignment.Right,Size=UDim2.new(1,-5,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=202},btn) end else TWEEN(btn,0.1,{TextColor3=TEXT2});btn.Font=Enum.Font.Gotham;local tm=btn:FindFirstChild("TickMark");if tm then tm:Destroy() end end;local ct=0;for _,v in pairs(cur) do if v then ct+=1 end end;headBtn.Text=ct>0 and (ct.." Selected") or "Select...";TogglesData[configKey].Callback(cur)
                else for _,ob in ipairs(dropScroll:GetChildren()) do if ob:IsA("TextButton") then TWEEN(ob,0.1,{TextColor3=TEXT2});ob.Font=Enum.Font.Gotham end end;TWEEN(btn,0.1,{TextColor3=GOLD2});btn.Font=Enum.Font.GothamBold;headBtn.Text=opt;closeDrop();TogglesData[configKey].Value=opt;TogglesData[configKey].Callback(opt) end
            end)
        end
    end
    CreateDropdown(fcCard,"Auto Select Bait",{"Common Fish Bait","Rare Fish Bait","Legendary Fish Bait"},nil,34,"Config_SelectBait",false,false)
    CreateDropdown(fcCard,"Auto Sell Fish",{"Common Fish","Rare Fish","Legendary Fish"},nil,78,"Config_SellFish",true,false)
    -- Buy items
    do
        local BUY_ITEMS={"All Seeing Shamrock","Mythical Fruit Chest","Legendary Fruit Chest","Legendary Fish Bait","Merchants Banana Rod","Race Reroll","Rare Fruit Chest","Rare Fish Bait","Karoo Mount","Special Tailor Token","SP Reset Essence","Knight's Gauntlet","Crab Cutlass","Bisento","Kessui","Raiui","Tropical Parrot","Coffin Boat","Striker","Hoverboard"}
        NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,122),BackgroundTransparency=1,Text="Auto Buy Items",TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},fcCard)
        local buyCountBadge=NEW("TextLabel",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,120),BackgroundColor3=BG5,TextColor3=TEXT3,Font=Enum.Font.GothamBold,TextSize=11,Text="Select items...",TextXAlignment=Enum.TextXAlignment.Center},fcCard); CORNER(5,buyCountBadge); STROKE(GOLD3,1,0,buyCountBadge)
        local buySearchBox=NEW("TextBox",{Size=UDim2.new(1,-24,0,26),Position=UDim2.new(0,12,0,150),BackgroundColor3=BG5,PlaceholderText="  Search items...",Text="",TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=11,ClearTextOnFocus=false},fcCard); CORNER(6,buySearchBox); local bss=STROKE(GOLD3,1,0,buySearchBox)
        buySearchBox.Focused:Connect(function() buySearchBox.Text="";TWEEN(bss,0.15,{Color=GOLD2}) end); buySearchBox.FocusLost:Connect(function() TWEEN(bss,0.15,{Color=GOLD3}) end)
        local buyList=NEW("ScrollingFrame",{Size=UDim2.new(1,-24,0,120),Position=UDim2.new(0,12,0,182),BackgroundColor3=BG0,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=GOLD,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)},fcCard); CORNER(6,buyList); STROKE(GOLD3,1,0,buyList)
        NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},buyList); NEW("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)},buyList)
        local buyBtns={}
        TogglesData["Config_BuyItems"]={Value={},HeadBtn=buyCountBadge,Callback=function(val) if type(val)~="table" then return end;local ct=0;for itemName,data in pairs(buyBtns) do local sel=val[itemName]==true;if data.check then data.check.Text=sel and "✓" or "" end;if data.nameLbl then data.nameLbl.TextColor3=sel and GOLD2 or TEXT2;data.nameLbl.Font=sel and Enum.Font.GothamBold or Enum.Font.Gotham end;if sel then ct+=1 end end;buyCountBadge.Text=ct>0 and (ct.." Selected") or "Select items...";buyCountBadge.TextColor3=ct>0 and GOLD2 or TEXT3;TogglesData["Config_BuyItems"].Value=val end}
        for idx,itemName in ipairs(BUY_ITEMS) do
            local row=NEW("Frame",{Size=UDim2.new(1,-6,0,26),BackgroundColor3=BG3,Name=itemName,BorderSizePixel=0,LayoutOrder=idx},buyList); CORNER(4,row)
            local nameLabel=NEW("TextLabel",{Text=itemName,Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},row)
            local check=NEW("TextLabel",{Text="",Size=UDim2.new(0,22,1,0),Position=UDim2.new(1,-24,0,0),BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Center},row)
            local rowBtn=NEW("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false},row)
            rowBtn.MouseEnter:Connect(function() TWEEN(row,0.1,{BackgroundColor3=BG4}) end); rowBtn.MouseLeave:Connect(function() TWEEN(row,0.1,{BackgroundColor3=BG3}) end)
            rowBtn.MouseButton1Click:Connect(function()
                local cur=TogglesData["Config_BuyItems"].Value;cur[itemName]=not cur[itemName]
                if cur[itemName] then check.Text="✓";TWEEN(nameLabel,0.1,{TextColor3=GOLD2});nameLabel.Font=Enum.Font.GothamBold else check.Text="";TWEEN(nameLabel,0.1,{TextColor3=TEXT2});nameLabel.Font=Enum.Font.Gotham end
                local ct=0;for _,v in pairs(cur) do if v then ct+=1 end end;buyCountBadge.Text=ct>0 and (ct.." Selected") or "Select items...";buyCountBadge.TextColor3=ct>0 and GOLD2 or TEXT3
            end)
            buyBtns[itemName]={row=row,check=check,nameLbl=nameLabel}
        end
        buySearchBox:GetPropertyChangedSignal("Text"):Connect(function() local ft=buySearchBox.Text:lower();for name,data in pairs(buyBtns) do data.row.Visible=ft=="" or name:lower():find(ft,1,true)~=nil end end)
    end
    CreateDropdown(fcCard,"Auto Craft Bait",{"Rare Fish Bait","Legendary Fish Bait"},nil,318,"Config_CraftBait",true,false)
    _G.FishBuyAmount=50
    NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,428),BackgroundTransparency=1,Text="Bait Buy Amount",TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},fcCard)
    local buyAmtFrame=NEW("Frame",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,426),BackgroundColor3=BG5},fcCard); CORNER(5,buyAmtFrame); local buyAmtStroke=STROKE(GOLD3,1,0,buyAmtFrame)
    local buyAmtBox=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="50",PlaceholderText="50",TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=12,ClearTextOnFocus=false},buyAmtFrame)
    buyAmtBox.Focused:Connect(function() TWEEN(buyAmtStroke,0.15,{Color=GOLD2}) end); buyAmtBox.FocusLost:Connect(function() local v=tonumber(buyAmtBox.Text);if v and v>0 then _G.FishBuyAmount=math.floor(v) else buyAmtBox.Text=tostring(_G.FishBuyAmount) end;TogglesData["Config_BaitAmount"].Value=_G.FishBuyAmount;TWEEN(buyAmtStroke,0.15,{Color=GOLD3}) end)
    TogglesData["Config_BaitAmount"]={Value=50,HeadBtn=buyAmtBox,Callback=function(val) local n=tonumber(val);if n and n>0 then _G.FishBuyAmount=math.floor(n);pcall(function() buyAmtBox.Text=tostring(math.floor(n)) end) end end}
    NEW("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,466),BackgroundTransparency=1,Text="Discord Webhook",TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},fcCard)
    local boxFrameWH=NEW("Frame",{Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,464),BackgroundColor3=BG5},fcCard); CORNER(5,boxFrameWH); local boxStrokeWH=STROKE(GOLD3,1,0,boxFrameWH)
    local textBoxWH=NEW("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="",PlaceholderText="https://discord...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ClipsDescendants=true},boxFrameWH)
    TogglesData["Config_Webhook"]={Value="",HeadBtn=textBoxWH,Callback=function(val) _G.WebhookUrl=val or "";pcall(function() textBoxWH.Text=val or "" end) end}
    textBoxWH.FocusLost:Connect(function() _G.WebhookUrl=textBoxWH.Text;TogglesData["Config_Webhook"].Value=textBoxWH.Text;TWEEN(boxStrokeWH,0.15,{Color=GOLD2});task.wait(0.2);TWEEN(boxStrokeWH,0.2,{Color=GOLD3}) end)

    -- Fruit management
    local fruitCard=MakeCard(FishingPage,238,4); CardHeader(fruitCard,"fruit","FRUIT MANAGEMENT",GREEN)
    RowLabel(fruitCard,"Auto Store Fruit","Auto store fruit to inventory",34); CardToggle(fruitCard,44,"AutoStoreFruit",function(state) _G.AutoStoreFruit=state end,GREEN)
    RowDivider(fruitCard,82)
    RowLabel(fruitCard,"Auto Drop Fruit","Drop fruit when inventory full",88); CardToggle(fruitCard,98,"AutoDropFruit",function(state) _G.AutoDropFruit=state end,GREEN)
    RowDivider(fruitCard,132)
    CreateDropdown(fruitCard,"Fruit Rarity Filter",{"Common","Rare","Epic","Legendary","Mythic"},"Common",138,"Config_FruitRarity",true,false)
    CreateDropdown(fruitCard,"Select Fruit",{"Bari Bari no Mi","Bomu Bomu no Mi","Doku Doku no Mi","Gomu Gomu no Mi","Gura Gura no Mi","Hie Hie no Mi","Magu Magu no Mi","Mero Mero no Mi","Ope Ope no Mi","Pika Pika no Mi","Suna Suna no Mi","Yami Yami no Mi","Zushi Zushi no Mi"},"",186,"Config_FruitSelect",false,true)
    task.spawn(function() pcall(function() local FM=require("Farm/AutoFruitManager");if FM and FM.Start then FM.Start(TogglesData) end end) end)
end -- _pageBuildFns["Fishing + Merchant"]

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
        AutoStatsData[statName]={Active=false,Cap=0,Btn=addBtn,Strk=btnStroke,Box=capBox}
        addBtn.MouseButton1Click:Connect(function() local d=AutoStatsData[statName];d.Active=not d.Active;TWEEN(addBtn,0.2,{BackgroundColor3=d.Active and GOLDD or BG5});TWEEN(btnStroke,0.2,{Color=d.Active and GOLD2 or GOLD3});addBtn.TextColor3=d.Active and C(10,8,2) or GOLD2;addBtn.Text=d.Active and "● Adding..." or "Auto Add" end)
    end
    local StatList={"Strength","Stamina","Defense","Gun Mastery","Sword Mastery","Devil Fruit","Fighting Style Mastery"}
    for idx,sName in ipairs(StatList) do CreateStatRow(sName,idx) end
    if AutoStats and AutoStats.Start then AutoStats.Start(AutoStatsData) end
end -- _pageBuildFns["Stats"]

end -- end if not IS_LOBBY

-- AutoStatsData accessible from Config (empty table until Stats tab opened)
AutoStatsData = AutoStatsData or {}

-- =====================================================================
-- CONFIG PAGE  (both lobby and game world)
-- =====================================================================
PageLayout(ConfigPage,14,10)

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
    if state and not _G._ZiliShowMain then
        if MainFrame then MainFrame.Visible=false end
    elseif not state and not _G._ZiliShowMain then
        if MainFrame then MainFrame.Visible=true end
    end
end,C(45,225,218))

-- ── THEME PICKER CARD ────────────────────────────────────────────────
local themeCard=MakeCard(ConfigPage,80,1); CardHeader(themeCard,"fruit","COLOR THEME",GOLD2)
NEW("TextLabel",{Text="Theme",Size=UDim2.new(0.4,0,0,20),Position=UDim2.new(0,14,0,34),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},themeCard)
local _themeBtns={}
for i,th in ipairs(THEMES) do
    local bx=NEW("TextButton",{Size=UDim2.new(0,56,0,26),Position=UDim2.new(0,100+(i-1)*62,0,38),BackgroundColor3=C(math.floor(th.main.R*255*0.12),math.floor(th.main.G*255*0.12),math.floor(th.main.B*255*0.12)),Text=th.name,TextColor3=th.main,Font=Enum.Font.GothamBold,TextSize=9,AutoButtonColor=false},themeCard)
    CORNER(5,bx); local bxS=STROKE(th.c2,1,i==1 and 0.1 or 0.6,bx)
    _themeBtns[i]={btn=bx,strk=bxS}
    bx.MouseButton1Click:Connect(function()
        ApplyTheme(i)
        for j,td in ipairs(_themeBtns) do TWEEN(td.strk,0.18,{Transparency=j==i and 0.1 or 0.6}) end
        Toast("Theme: "..th.name,th.main,"⬡")
    end)
end

-- ── KEYBIND CONFIG CARD ───────────────────────────────────────────────
local kbCard=MakeCard(ConfigPage,72,2); CardHeader(kbCard,"lightning","KEYBIND",AMBER)
NEW("TextLabel",{Text="Toggle Hub",Size=UDim2.new(0.5,0,0,20),Position=UDim2.new(0,14,0,34),BackgroundTransparency=1,TextColor3=TEXT1,Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},kbCard)
local _kbLbl=NEW("TextLabel",{Text="RightShift",Size=UDim2.new(0.4,0,0,18),Position=UDim2.new(0.55,0,0,36),BackgroundTransparency=1,TextColor3=AMBER,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center},kbCard)
local _kbBtn=NEW("TextButton",{Text="Click to rebind",Size=UDim2.new(0,108,0,26),Position=UDim2.new(1,-120,0,38),BackgroundColor3=BG5,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=10,AutoButtonColor=false},kbCard)
CORNER(6,_kbBtn); local _kbS=STROKE(GOLD3,1,0.3,_kbBtn)
local _listening=false
_kbBtn.MouseButton1Click:Connect(function()
    if _listening then return end
    _listening=true; _kbBtn.Text="Press any key..."; _kbBtn.TextColor3=AMBER; TWEEN(_kbS,0.15,{Color=AMBER,Transparency=0})
    local conn; conn=UIS.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            _keybindKey=inp.KeyCode
            _kbLbl.Text=tostring(inp.KeyCode):gsub("Enum.KeyCode.","")
            _kbBtn.Text="Click to rebind"; _kbBtn.TextColor3=TEXT2
            TWEEN(_kbS,0.15,{Color=GOLD3,Transparency=0.3})
            Toast("Keybind set: ".._kbLbl.Text,AMBER,"⚡")
            _listening=false; conn:Disconnect()
        end
    end)
end)

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

-- =====================================================================
-- EXECUTOR DIAGNOSTICS (lightweight)
-- =====================================================================
local function RunExecutorDiagnostics()
    local env=getgenv and getgenv() or _G; local name="Unknown Engine"
    if type(identifyexecutor)=="function" then pcall(function() name=identifyexecutor() end) end
    local deps={"hookmetamethod","hookfunction","getrawmetatable","setreadonly","getnamecallmethod","newcclosure","cloneref","fireproximityprompt","getconnections","readfile","writefile","isfile","makefolder","isfolder","getgenv","identifyexecutor","setclipboard","request"}
    local sup=0; for _,v in ipairs(deps) do if type(env[v])=="function" or (v=="request" and (type(env.request)=="function" or type(env.http)=="table")) then sup+=1 end end
    local pct=math.floor((sup/#deps)*100); local scoreCol=pct>=80 and C(72,225,135) or pct>=50 and AMBER or RED
    local sg=NEW("ScreenGui",{Name="ZiliDiag"},game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))
    local frame=NEW("Frame",{Size=UDim2.new(0,260,0,104),Position=UDim2.new(1,20,1,-170),BackgroundColor3=BG1,BorderSizePixel=0},sg); CORNER(10,frame); STROKE(GOLD,1.5,0.1,frame)
    -- Header: lightning icon + COMPATIBILITY label
    local diagHdr=NEW("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=BG_HDR},frame); CORNER(10,diagHdr)
    NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG_HDR,BorderSizePixel=0},diagHdr)
    local _litBg=NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,8,0.5,-8),BackgroundTransparency=1},diagHdr); DrawIcon(_litBg,"lightning",0,0,16,scoreCol)
    NEW("TextLabel",{Text="COMPATIBILITY CHECK",Size=UDim2.new(1,-34,1,0),Position=UDim2.new(0,30,0,0),BackgroundTransparency=1,TextColor3=scoreCol,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},diagHdr)
    NEW("TextLabel",{Text="ZILI  ·  "..name.."  ·  Score: "..pct.."%  ("..sup.."/"..#deps..")",Size=UDim2.new(1,-16,0,24),Position=UDim2.new(0,8,0,30),BackgroundTransparency=1,TextColor3=scoreCol,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},frame)
    local barBg=NEW("Frame",{Size=UDim2.new(1,-20,0,5),Position=UDim2.new(0,10,0,58),BackgroundColor3=C(12,10,26)},frame); CORNER(3,barBg)
    local barFill=NEW("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=scoreCol},barBg); CORNER(3,barFill)
    TweenService:Create(frame,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(1,-280,1,-170)}):Play()
    task.wait(0.5); TweenService:Create(barFill,TweenInfo.new(1.0,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.new(pct/100,0,1,0)}):Play()
    task.delay(7,function() TweenService:Create(frame,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.new(1,20,1,-170)}):Play();task.wait(0.4);sg:Destroy() end)
end
task.spawn(RunExecutorDiagnostics)

-- =====================================================================
-- SIGNAL READY
-- =====================================================================
_G._ZiliLoadReady = true
