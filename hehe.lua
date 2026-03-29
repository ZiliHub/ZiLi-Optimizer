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

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  📦 MODULE: Config/ConfigManager  (GET BETTER OUT · Zili Hub)   ║
-- ║  Self-describing: auto-discovers all Value/Toggle keys from      ║
-- ║  TogglesData — no manual VALUE_KEYS list needed ever again.      ║
-- ╚══════════════════════════════════════════════════════════════════╝
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
                        for k, val in pairs(v) do if val == true then clean[k] = true end end
                        v = clean
                    end
                    settings.Values[key] = v
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

                -- Update HeadBtn text
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

    RunService.Heartbeat:Connect(function(deltaTime)
        for i = #AsyncQueue, 1, -1 do
            local taskObj = AsyncQueue[i]
            taskObj.timer = taskObj.timer - deltaTime
            
            if taskObj.timer <= 0 then
                taskObj.remote:FireServer(unpack(taskObj.args))
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
    local function StopStaminaSpoof()
        isSpoofingStamina = false
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
            root.Velocity = VEC_ZERO
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

            local antiGravity = root:FindFirstChild("ZILI_AntiGravity") or Instance.new("BodyVelocity")
            antiGravity.Name = "ZILI_AntiGravity"
            antiGravity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            antiGravity.Velocity = VEC_ZERO
            antiGravity.Parent = root

            local targetPos = stepData.pos

            Tween.MoveConn = RunService.Heartbeat:Connect(function(deltaTime)
                if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end

                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                root.Velocity = VEC_ZERO

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

    local QuestFunc = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NPCInteractions"):WaitForChild("QuestFunctions"))
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
        local CombatRegister = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
        local currentCombo = 1 
        
        while true do
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
                                root.Velocity = Vector3.new(0,0,0)
                                root.RotVelocity = Vector3.new(0,0,0)
                                
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
                                    root.Velocity = Vector3.new(0,0,0)
                                    if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end
                                
                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 do 
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    root.Velocity = Vector3.new(0,0,0)
                                    
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
                                root.Velocity = Vector3.new(0,0,0)
                                if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                task.wait(0.2)
                            end
                            
                            local waitChatClose = tick()
                            while tick() - waitChatClose < 8 do 
                                root.CFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                                root.Velocity = Vector3.new(0,0,0)
                                
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
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "FloatForce"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.new(0, 0, 0)
                        bv.Parent = root
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

    local QuestFunc = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NPCInteractions"):WaitForChild("QuestFunctions"))

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
                                root.Velocity = Vector3.new(0, 0, 0)
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
                                root.Velocity = Vector3.new(0,0,0)
                                root.RotVelocity = Vector3.new(0,0,0)
                                
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
                                    root.Velocity = Vector3.new(0,0,0)
                                    if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end
                                
                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 do 
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    root.Velocity = Vector3.new(0,0,0)
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
                                root.Velocity = Vector3.new(0,0,0)
                                root.RotVelocity = Vector3.new(0,0,0)
                                
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
                                    root.Velocity = Vector3.new(0,0,0)
                                    if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end
                                
                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 do 
                                    root.CFrame = CFrame.new(standPos, SetSpawnCoords)
                                    root.Velocity = Vector3.new(0,0,0)
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
                                root.Velocity = Vector3.new(0,0,0)
                                if Player.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                task.wait(0.2)
                            end

                            local waitChatClose = tick()
                            while tick() - waitChatClose < 8 do 
                                root.CFrame = CFrame.new(standPos, Vector3.new(QuestNPC_Pos.X, standPos.Y, QuestNPC_Pos.Z))
                                root.Velocity = Vector3.new(0,0,0)
                                
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
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "FloatForce"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.new(0, 0, 0)
                        bv.Parent = root
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
            root.Velocity = Vector3.new(0, 0, 0)
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

        local antiGravity = root:FindFirstChild("ZILI_AntiGravity") or Instance.new("BodyVelocity")
        antiGravity.Name = "ZILI_AntiGravity"
        antiGravity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        antiGravity.Velocity = Vector3.new(0, 0, 0)
        antiGravity.Parent = root

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
            root.Velocity = Vector3.new(0, 0, 0)

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
                                root.Velocity = Vector3.new(0, 0, 0)
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
                                    root.Velocity = Vector3.new(0,0,0)
                                    if LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT") then break end
                                    task.wait(0.2)
                                end

                                local waitChatClose = tick()
                                while tick() - waitChatClose < 8 and _G.AutoGeppo do 
                                    root.CFrame = CFrame.lookAt(standPos, lookAtPos)
                                    root.Velocity = Vector3.new(0,0,0)
                                    
                                    local chatGui = LocalPlayer.PlayerGui:FindFirstChild("NPCCHAT")
                                    if not chatGui then break end 
                                    
                                    AutoClickUI(chatGui)
                                    task.wait(0.3) 
                                end
                                
                                task.wait(0.5)
                                
                                pcall(function()
                                    local args = { [1] = "skyWalkTrainer" }
                                    ReplicatedStorage:WaitForChild("Events"):WaitForChild("learnStyle"):FireServer(unpack(args))
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
    local OFFSET_FAKEFLOOR = CFrame.new(0, -3.05, 0)
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
        CraftLeg     = false,
        CraftRare    = false,
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

    local function GetMyBobble()
        local myName = LocalPlayer.Name
        for _, area in pairs({workspace, LocalPlayer.Character}) do
            if area then
                for _, obj in pairs(area:GetDescendants()) do
                    if string.find(obj.Name, myName) and obj:GetAttribute("Caught") == true then
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
                    pcall(function() ReplicatedStorage:WaitForChild("Events"):WaitForChild("Tools"):InvokeServer("equip", rodName) end)
                    _cachedRodName = rodName
                    task.wait(0.5) -- [SỬA LỖI LOGIC 3]: Đợi 0.5s cho Server bỏ cái cần mới vào Balo rồi mới chạy tiếp
                end
                return rodName
            end
        end
        _cachedRodName = nil
        return nil
    end

    local function AutoEquipTitleSilent()
        task.spawn(function()
            for _, titleName in ipairs(TitlesPriority) do
                pcall(function() ReplicatedStorage:WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(titleName) end)
                task.wait(0.1)
            end
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
    local Tween = { IsTeleporting = false, MoveConn = nil, NoclipConn = nil, FakeFloor = nil }

    function Tween.Stop()
        Tween.IsTeleporting = false
        StopStaminaSpoof()
        if Tween.MoveConn   then Tween.MoveConn:Disconnect();   Tween.MoveConn   = nil end
        if Tween.NoclipConn then Tween.NoclipConn:Disconnect(); Tween.NoclipConn = nil end
        local root = getRoot()
        if root then
            root.Anchored = false 
            for _, v in pairs(root:GetChildren()) do
                if v.Name == "ZILI_AntiGravity" then v:Destroy() end
            end
            root.Velocity = VEC_ZERO
        end
        if Tween.FakeFloor then Tween.FakeFloor:Destroy(); Tween.FakeFloor = nil end
    end

    function Tween.Start(finalDest, onComplete, opts)
        opts = opts or {}
        Tween.Stop()
        Tween.IsTeleporting = true
        StartStaminaSpoof()

        Tween.NoclipConn = RunService.Stepped:Connect(function()
            if Tween.IsTeleporting and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
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

            local ag       = root:FindFirstChild("ZILI_AntiGravity") or Instance.new("BodyVelocity")
            ag.Name        = "ZILI_AntiGravity"
            ag.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
            ag.Velocity    = VEC_ZERO
            ag.Parent      = root
            local targetPos = stepData.pos

            local flyY
            if stepData.isMerchant then
                flyY = math.max(targetPos.Y, 4)
            elseif stepData.isFishmanIn or stepData.isFishmanExit then
                flyY = targetPos.Y
            else
                flyY = 7.33
            end

            Tween.MoveConn = RunService.Heartbeat:Connect(function(rawDt)
                if not Tween.IsTeleporting or not root.Parent then Tween.Stop(); return end
                local dt = math.min(rawDt, DT_CAP)

                if Tween.FakeFloor then Tween.FakeFloor.CFrame = root.CFrame * OFFSET_FAKEFLOOR end
                root.Velocity = VEC_ZERO

                local cur    = root.Position
                local distXZ = (Vector2.new(targetPos.X, targetPos.Z) - Vector2.new(cur.X, cur.Z)).Magnitude

                if not stepData.isMerchant and not stepData.isFishmanIn and not stepData.isFishmanExit then
                    if math.abs(cur.Y - 7.33) > 10 and distXZ > 50 then
                        Tween.MoveConn:Disconnect()
                        task.spawn(function()
                            root.CFrame = CFrame.new(cur.X, 7.33, cur.Z)
                            task.wait(0.2)
                            flyTo(stepData, onStepComplete)
                        end)
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
                    pcall(function()
                        ReplicatedStorage:WaitForChild("FishingShopRemote"):InvokeServer(unpack({{
                            ["Fish"]=fishName, ["All"]=false, ["Method"]="SellFish"
                        }}))
                    end)
                    -- Đợi server cập nhật peli (0.1s quá ngắn, server chưa kịp cộng tiền)
                    task.wait(0.3)
                    -- Check lại ngay sau khi sell + wait — nếu vừa chạm 1M thì dừng
                    if getCurrentPeli() >= 1000000 then return true end
                end
            end
        end
        return true
    end

    local function AutoCraftSilent(blueprintType, extraDataKey, fishList, minCount, countPerCraft)
        minCount      = minCount      or 1
        countPerCraft = countPerCraft or 1   -- số cá dùng mỗi lần craft (rare = 2)
        local inventory = GetInventory()
        if not inventory then return false end
        local craftedAny = false
        for _, fishName in ipairs(fishList) do
            local count = inventory[fishName] or 0
            if count >= minCount then
                if not craftedAny then
                    TweenToPosAndWait(Cords.Craft)
                    craftedAny = true
                    if not _G.AutoFishing then return false end
                end
                -- Craft từng batch countPerCraft con — tránh gửi dư cá lên server
                local batches = math.floor(count / countPerCraft)
                for _ = 1, batches do
                    if not _G.AutoFishing then return false end
                    pcall(function()
                        ReplicatedStorage:WaitForChild("CraftingRemote"):InvokeServer(unpack({{
                            ["BlueprintItem"]=blueprintType, ["Method"]="Craft",
                            ["ExtraData"]={[extraDataKey]=fishName}, ["Count"]=countPerCraft,
                        }}))
                    end)
                    task.wait(0.5)
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

            if _Configs.CraftLeg  then AutoCraftSilent("Legendary Fish Bait","Legendary Fish",FishLists.Leg,  1, 1) end
            if _Configs.CraftRare then AutoCraftSilent("Rare Fish Bait",     "Rare Fish",     FishLists.Rare, 2, 2) end

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
                while waited < 30 and _G.AutoFishing do
                    bobble = GetMyBobble(); if bobble then break end
                    task.wait(0.2); waited = waited + 0.2
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
                        if t < 5.5  then t = math.random(450, 550)/100  end
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

-- 📦 MODULE: Farm/AutoFruitManager (BULLETPROOF FIXED)
__modules["Farm/AutoFruitManager"] = function()
    local AutoFruitManager = {}

    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer       = Players.LocalPlayer

    -- =====================================================================
    -- FRUIT LISTS 
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

    local Events       = ReplicatedStorage:WaitForChild("Events", 10)
    local FruitStorage = Events and Events:WaitForChild("FruitStorage", 10)
    local ToolsRemote  = Events and Events:WaitForChild("Tools", 10)

    -- =====================================================================
    -- HELPERS (FIXED)
    -- =====================================================================
    -- Lấy trái cây ở cả trong TÚI và TRÊN TAY
    local function GetFruits()
        local fruits = {}
        -- Tìm trên tay trước
        if LocalPlayer.Character then
            for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") and FRUIT_RARITY[tool.Name] then
                    table.insert(fruits, tool)
                end
            end
        end
        -- Tìm trong túi
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

    -- Đã fix: Chống crash khi UI trả về String thay vì Table
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

    -- Hàm tự động cầm vũ khí/trái cây lên tay
    local function EquipTool(tool)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and tool.Parent ~= char then
            char.Humanoid:EquipTool(tool)
            task.wait(0.3) -- Đợi server nhận diện đã cầm
        end
    end

    -- =====================================================================
    -- CORE LOGIC
    -- =====================================================================
    local function DoAutoStore()
        local fruits = GetFruits()
        if #fruits == 0 then return end

        local rarityFilter = getgenv().Config_FruitRarity or "Common"
        local specificFruit = getgenv().Config_FruitSelect or ""

        local minLevel = GetMinKeepLevel(rarityFilter)
        
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
                EquipTool(tool) -- BẮT BUỘC EQUIP TRƯỚC KHI STORE
                pcall(function() FruitStorage:InvokeServer(true) end)
                task.wait(0.8)
            end
        end
    end

    local function DoAutoDrop()
        local fruits = GetFruits()
        if #fruits == 0 then return end

        local rarityFilter = getgenv().Config_FruitRarity or "Common"
        local specificFruit = getgenv().Config_FruitSelect or ""
        local minKeepLevel = GetMinKeepLevel(rarityFilter)

        for _, tool in ipairs(fruits) do
            local level = RARITY_ORDER[FRUIT_RARITY[tool.Name] or "Common"] or 1
            local shouldDrop = false

            if specificFruit ~= "" and string.find(string.lower(specificFruit), string.lower(tool.Name)) ~= nil then
                shouldDrop = false -- Không vứt trái đang được target
            elseif minKeepLevel > 0 then
                shouldDrop = level < minKeepLevel -- Drop nếu cùi bắp hơn mức chọn
            else
                shouldDrop = true
            end

            if shouldDrop and ToolsRemote then
                EquipTool(tool) -- BẮT BUỘC EQUIP TRƯỚC KHI DROP
                local toolObj = LocalPlayer.Character:FindFirstChild(tool.Name) or getNilTool(tool.Name)
                if toolObj then
                    pcall(function() ToolsRemote:InvokeServer("drop", toolObj) end)
                    task.wait(0.5)
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

        task.spawn(function()
            while _running do
                task.wait(1.5) 
                
                -- Fix: Quét qua getgenv() để đảm bảo đồng bộ với UI Toggle
                if getgenv().AutoStoreFruit then
                    pcall(DoAutoStore)
                end

                if getgenv().AutoDropFruit then
                    pcall(DoAutoDrop)
                end
            end
        end)
    end

    function AutoFruitManager.Stop()
        _running = false
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
-- GET BETTER OUT | MAIN HUB  (Main UI & Logic Integration)
-- =====================================================================

-- =====================================================================
-- PLACE DETECTION  (phải chạy TRƯỚC tất cả require)
-- =====================================================================
local PLACE_LOBBY = 1730877806   -- ← điền PlaceId lobby (nếu 0 = auto detect)
local PLACE_GAME  = 3978370137   -- ← điền PlaceId game world (nếu 0 = auto detect)
local IS_LOBBY

if PLACE_LOBBY ~= 0 then
    IS_LOBBY = (game.PlaceId == PLACE_LOBBY)
else
    -- Auto-detect: lobby không có RemoteEvent "Fishing"
    IS_LOBBY = (game:GetService("ReplicatedStorage"):FindFirstChild("Fishing") == nil)
end

-- =====================================================================
-- REQUIRES  (game-world modules chỉ load khi ở game world)
-- =====================================================================
local Bypass, Esp, TweenSys, IslandData
local AutoFarmLevel, AutoGetBuso, AutoGeppoFunc, AutoFishMerchantModule, AutoStats

if not IS_LOBBY then
    pcall(function() Bypass        = require("BYPASS ANTICHEAT") end)
    pcall(function() Esp           = require("Island/Esp") end)
    pcall(function() TweenSys      = require("Island/TWEEN TO ISLAND") end)
    pcall(function() IslandData    = require("Island/IslandData") end)
    pcall(function() AutoFarmLevel = require("Farm/AutoFarmLevel") end)
    pcall(function() AutoGetBuso   = require("Farm/AutoGetBuso") end)
    pcall(function() AutoGeppoFunc = require("Farm/AutoGeppo") end)
    pcall(function() AutoFishMerchantModule = require("Farm/AutoFishMerchant") end)
    pcall(function() AutoStats     = require("Stats/addStats") end)
end

pcall(function() if Bypass and Bypass.Init then Bypass.Init() end end)
pcall(function()
    if TweenSys then TweenSys.Notify = function() end end
end)

-- =====================================================================
-- 📦 LOGIC MODULES (Lobby-only features)
-- =====================================================================
local ReplicatedStorage_L = game:GetService("ReplicatedStorage")
local Player_L            = game.Players.LocalPlayer

-- ── Private Server ────────────────────────────────────────────────────
local TeleportService_L = game:GetService("TeleportService")
local ServerModule = {}

-- Join private server.
-- code == "" or nil  →  teleport to public lobby (main menu)
-- code == "some_code" →  join that private server then pick hub
function ServerModule.Join(code, hubArg)
    local isPublic = (not code or code:match("^%s*$"))

    if isPublic then
        -- Empty code = go to public server (main menu / lobby)
        task.spawn(function()
            pcall(function()
                TeleportService_L:Teleport(PLACE_LOBBY, Player_L)
            end)
        end)
        return
    end

    -- Private server: use unpack(args) pattern
    task.spawn(function()
        pcall(function()
            local args = { [1] = code }
            ReplicatedStorage_L:WaitForChild("Events")
                :WaitForChild("reserved")
                :InvokeServer(unpack(args))
        end)
    end)

    -- After teleport loads the lobby, pick hub destination
    if hubArg ~= nil then
        task.spawn(function()
            local playerGui = Player_L:WaitForChild("PlayerGui")
            local chooseTypeUI = playerGui:WaitForChild("chooseType", 20)
            if chooseTypeUI then
                local frame = chooseTypeUI:WaitForChild("Frame", 5)
                if frame then
                    local remote = frame:WaitForChild("RemoteEvent", 5)
                    if remote then
                        task.wait(0.5)
                        pcall(function() remote:FireServer(hubArg) end)
                        pcall(function() chooseTypeUI.Enabled = false end)
                    end
                end
            end
        end)
    end
end

-- ── Auto Rejoin ───────────────────────────────────────────────────────
local AutoRejoinModule = {}
AutoRejoinModule._hooked    = false
AutoRejoinModule._running   = false
AutoRejoinModule._thread    = nil

function AutoRejoinModule.Start()
    if AutoRejoinModule._running then return end
    AutoRejoinModule._running = true

    -- Hook teleport state (covers TeleportFailed, Kicked via teleport, etc.)
    if not AutoRejoinModule._hooked then
        AutoRejoinModule._hooked = true

        -- Teleport state listener
        Player_L.OnTeleport:Connect(function(teleportState, _, _)
            if not AutoRejoinModule._running then return end
            if teleportState == Enum.TeleportState.Failed then
                task.wait(3)
                if AutoRejoinModule._running then
                    AutoRejoinModule._doRejoin()
                end
            end
        end)
    end

    -- Background heartbeat: detect if we somehow got disconnected or
    -- the character is removed and never re-added (kick detection fallback)
    AutoRejoinModule._thread = task.spawn(function()
        while AutoRejoinModule._running do
            task.wait(5)
            -- If player's character is nil for 5s+ = likely kicked
            if not Player_L.Character and AutoRejoinModule._running then
                task.wait(5)  -- give Roblox time to respawn normally
                if not Player_L.Character and AutoRejoinModule._running then
                    AutoRejoinModule._doRejoin()
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
end

function AutoRejoinModule._doRejoin()
    if not AutoRejoinModule._running then return end
    local code = getgenv().PSCode or ""
    local hub  = getgenv().SelectedHub or "Regular"
    local sea  = getgenv().SelectedSea or "Sea 1"

    -- Lưu pending join vào getgenv() (tồn tại qua teleport trong cùng executor session)
    getgenv().GBO_PendingJoin = {code=code, hub=hub, sea=sea}

    -- Backup bằng file để lobby đọc lại ngay cả khi executor reset getgenv
    pcall(function()
        if writefile then
            local ok, js = pcall(function()
                return game:GetService("HttpService"):JSONEncode({code=code,hub=hub,sea=sea})
            end)
            if ok then writefile("gbo_pending_join.json", js) end
        end
    end)

    -- Delay ngẫu nhiên tránh spam, rồi về lobby để lobby tự join PS
    task.wait(math.random(2, 5))
    pcall(function()
        TeleportService_L:Teleport(PLACE_LOBBY, Player_L)
    end)
end

-- ── Skin Changer ──────────────────────────────────────────────────────
local SkinModule = {}
function SkinModule.Randomize()
    local setEvent = ReplicatedStorage_L:WaitForChild("Events"):WaitForChild("set")
    local function setAvatar(name, value)
        pcall(function() setEvent:FireServer(name, value) end)
    end
    setAvatar("Eye",       math.random(1,74))
    setAvatar("Mouth",     math.random(1,36))
    setAvatar("Hair1",     math.random(1,256))
    setAvatar("Hair1Color",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    setAvatar("Hair2",     math.random(1,256))
    setAvatar("Hair2Color",Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    setAvatar("Shirt",     math.random(1,24))
    setAvatar("ShirtPri",  Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    setAvatar("ShirtSec",  Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    setAvatar("Pants",     math.random(1,22))
    setAvatar("PantsPri",  Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    setAvatar("PantsSec",  Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    setAvatar("Shoe",      math.random(1,12))
    setAvatar("ShoeColor", Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))
    setAvatar("SkinColor", math.random(1,10))
end

-- ── Race Reroll ───────────────────────────────────────────────────────
local RaceModule = {}
RaceModule.IsRunning = false
function RaceModule.GetCurrentRace()
    local stats = ReplicatedStorage_L:FindFirstChild("Stats" .. Player_L.Name)
    if stats and stats:FindFirstChild("Customization") and stats.Customization:FindFirstChild("Race") then
        local raw = stats.Customization.Race.Value
        return raw == "Human" and raw or string.gsub(raw, "%d+", "")
    end
    return "Unknown"
end
function RaceModule.Stop()  RaceModule.IsRunning = false  end
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
                    RaceModule.Stop()
                    if onFound then onFound() end
                    break
                else
                    pcall(function() rerollRemote:InvokeServer() end)
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
    end)
end

-- =====================================================================
-- SERVICES & LOCALS
-- =====================================================================
local UIS         = game:GetService("UserInputService")
local TweenService= game:GetService("TweenService")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- =====================================================================
-- SCREEN GUI
-- =====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
end
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

-- =====================================================================
-- HELPERS
-- =====================================================================
local C = Color3.fromRGB
local function NEW(cls, props, parent)
    local i = Instance.new(cls)
    for k,v in pairs(props) do i[k]=v end
    if parent then i.Parent = parent end
    return i
end
local function CORNER(r, p) return NEW("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function STROKE(col, thick, trans, p)
    return NEW("UIStroke",{Color=col,Thickness=thick,Transparency=trans or 0},p)
end
local function TWEEN(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
end
local function TWEEN_BACK(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Back, Enum.EasingDirection.Out), props):Play()
end

-- ── Core palette ───────────────────────────────────────────────────────
local BG0   = C(6,   7, 16)   -- deepest bg
local BG1   = C(9,  10, 22)   -- main panel
local BG2   = C(12, 13, 28)   -- sidebar
local BG3   = C(16, 17, 36)   -- card bg
local BG4   = C(20, 22, 46)   -- card hover
local BG5   = C(7,   8, 18)   -- input bg
local BG_HDR= C(10, 11, 24)   -- card header bg

-- ── Gold (luxury) ───────────────────────────────────────────────────────
local GOLD  = C(201,148, 58)
local GOLD2 = C(240,190,104)
local GOLD3 = C(122, 90, 30)
local GOLDD = C(40,  30,  8)   -- dark gold (toggle ON bg)

-- ── Text ────────────────────────────────────────────────────────────────
local TEXT1 = C(230,226,212)
local TEXT2 = C(148,144,168)
local TEXT3 = C(68,  64, 90)

-- ── Section accent colors ────────────────────────────────────────────────
local RED    = C(200, 55, 55)
local GREEN  = C(56,  190,110)
local CYAN   = C(0,   210,200)   -- HUB STATUS / connected
local CYAND  = C(0,    40, 38)   -- dark bg for cyan badges
local PINK   = C(200,  80,220)   -- SERVER STATUS badge
local PINKD  = C(40,   10, 50)   -- dark bg for pink
local BLUE_A = C(80,  130,240)   -- VISUALS / ESP section
local ORANGE = C(230, 140, 40)   -- FISHING section
local PURPLE = C(140,  90,230)   -- BAIT / CONFIG
local AMBER  = C(255, 185, 50)   -- quick status

-- =====================================================================
-- ICON DRAW SYSTEM (SVG-style, pure Frames)
-- =====================================================================
local function DrawIcon(parent, iconName, px, py, sz, col)
    sz  = sz  or 14
    col = col or TEXT2
    local c = NEW("Frame",{
        Size=UDim2.new(0,sz,0,sz),
        Position=UDim2.new(0,px,0,py),
        BackgroundTransparency=1, BorderSizePixel=0
    }, parent)

    -- filled rounded rect
    local function RR(x,y,w,h,r,clr)
        local f=NEW("Frame",{Size=UDim2.new(0,w,0,h),Position=UDim2.new(0,x,0,y),
            BackgroundColor3=clr or col,BorderSizePixel=0},c)
        CORNER(r,f); return f
    end
    -- line from (x1,y1) to (x2,y2), rotates around its own center
    local function L(x1,y1,x2,y2,th,clr)
        local dx=x2-x1; local dy=y2-y1
        local len=math.sqrt(dx*dx+dy*dy)
        if len<0.5 then return end
        local ang=math.deg(math.atan2(dy,dx))
        local f=NEW("Frame",{
            Size=UDim2.new(0,len,0,th or 2),
            Position=UDim2.new(0,(x1+x2)/2,0,(y1+y2)/2),
            AnchorPoint=Vector2.new(0.5,0.5),
            BackgroundColor3=clr or col,
            BorderSizePixel=0, Rotation=ang
        },c)
        CORNER(1,f); return f
    end
    -- circle dot
    local function Dot(cx,cy,d,clr)
        return RR(cx-d/2,cy-d/2,d,d,d/2,clr)
    end
    -- circle ring (stroke only)
    local function Ring(cx,cy,d,sw,clr)
        local f=NEW("Frame",{
            Size=UDim2.new(0,d,0,d),
            Position=UDim2.new(0,cx-d/2,0,cy-d/2),
            BackgroundTransparency=1,BorderSizePixel=0
        },c)
        CORNER(d/2,f); STROKE(clr or col,sw or 1.5,0,f); return f
    end

    local s=sz

    -- ── TAB ICONS ──────────────────────────────────────────────────
    if iconName=="home" then
        -- Roof (two slopes + eave)
        L(s*.5,s*.06, s*.02,s*.5,  1.5)   -- left slope
        L(s*.5,s*.06, s*.98,s*.5,  1.5)   -- right slope
        L(s*.02,s*.5, s*.98,s*.5,  1.5)   -- eave
        -- Body
        RR(s*.15,s*.48, s*.7,s*.5, 2)
        -- Door
        RR(s*.38,s*.67, s*.24,s*.32, 1)

    elseif iconName=="sword" then
        L(s*.72,s*.04, s*.12,s*.72, 2)    -- blade
        L(s*.22,s*.38, s*.58,s*.64, 1.5)  -- crossguard
        L(s*.62,s*.65, s*.9, s*.9,  2)    -- handle
        Dot(s*.9,s*.9, s*.18)              -- pommel

    elseif iconName=="globe" then
        Ring(s*.5,s*.5, s*.96, 1.5)        -- outer ring
        L(s*.02,s*.5,  s*.98,s*.5, 1.5)   -- equator
        L(s*.5, s*.02, s*.5, s*.98,1.5)   -- meridian
        -- curved meridians (approximate with short lines)
        L(s*.3,s*.06, s*.3,s*.94, 1)      -- left arc hint
        L(s*.7,s*.06, s*.7,s*.94, 1)      -- right arc hint

    elseif iconName=="fish" then
        -- Body
        local b=NEW("Frame",{Size=UDim2.new(0,s*.68,0,s*.55),
            Position=UDim2.new(0,0,0,s*.225),
            BackgroundColor3=col,BorderSizePixel=0},c)
        CORNER(s*.28,b)
        -- Tail V
        L(s*.62,s*.5,  s*.97,s*.07, 2)
        L(s*.62,s*.5,  s*.97,s*.93, 2)
        -- Tail center
        L(s*.62,s*.5,  s*.98,s*.5,  1.5)
        -- Eye
        Dot(s*.14,s*.47, s*.14)

    elseif iconName=="chart" then
        -- Three bars (short, mid, tall)
        RR(s*.04,  s*.5,  s*.22,s*.5,  2)
        RR(s*.38,  s*.22, s*.22,s*.78, 2)
        RR(s*.73,  s*.0,  s*.22,s*1.0, 2)
        -- baseline
        L(0,s*1.0-1, s,s*1.0-1, 1.5)

    elseif iconName=="gear" then
        -- Body ring
        Ring(s*.5,s*.5, s*.56, 1.5)
        -- Center hole
        Dot(s*.5,s*.5, s*.2)
        -- 4 straight teeth
        RR(s*.43,0,       s*.14,s*.2,  1)
        RR(s*.43,s*.8,    s*.14,s*.2,  1)
        RR(0,    s*.43,   s*.2, s*.14, 1)
        RR(s*.8, s*.43,   s*.2, s*.14, 1)
        -- 4 diagonal teeth
        L(s*.14,s*.14, s*.3,s*.3,  3)
        L(s*.86,s*.14, s*.7,s*.3,  3)
        L(s*.14,s*.86, s*.3,s*.7,  3)
        L(s*.86,s*.86, s*.7,s*.7,  3)

    -- ── CARD HEADER ICONS ─────────────────────────────────────────
    elseif iconName=="shield" then
        -- Outer shield
        local sh=NEW("Frame",{Size=UDim2.new(0,s*.88,0,s*.9),
            Position=UDim2.new(0,s*.06,0,s*.05),
            BackgroundTransparency=1,BorderSizePixel=0},c)
        CORNER(s*.22,sh); STROKE(col,1.5,0,sh)
        -- Inner cross
        L(s*.5,s*.28, s*.5,s*.72, 1.5)
        L(s*.28,s*.5, s*.72,s*.5, 1.5)

    elseif iconName=="lightning" then
        L(s*.66,s*.04, s*.32,s*.52, 2)    -- top stroke
        L(s*.32,s*.52, s*.68,s*.52, 1.5)  -- middle
        L(s*.68,s*.52, s*.34,s*.96, 2)    -- bottom stroke

    elseif iconName=="eye" then
        -- Outer oval
        local e=NEW("Frame",{Size=UDim2.new(0,s*.96,0,s*.56),
            Position=UDim2.new(0,s*.02,0,s*.22),
            BackgroundTransparency=1,BorderSizePixel=0},c)
        CORNER(s*.28,e); STROKE(col,1.5,0,e)
        -- Pupil
        Dot(s*.5,s*.5, s*.28)

    elseif iconName=="fist" then
        -- Knuckles (3 bumps top)
        RR(s*.08, s*.18, s*.22,s*.22, 3)
        RR(s*.38, s*.12, s*.22,s*.22, 3)
        RR(s*.68, s*.18, s*.22,s*.22, 3)
        -- Main fist body
        RR(s*.06, s*.35, s*.88,s*.58, 4)

    elseif iconName=="wave" then
        -- Sine-wave approximation (4 line segments)
        L(0,     s*.5,  s*.25,s*.18, 2)
        L(s*.25, s*.18, s*.5, s*.82, 2)
        L(s*.5,  s*.82, s*.75,s*.18, 2)
        L(s*.75, s*.18, s*1.0,s*.5,  2)

    elseif iconName=="fruit" then
        -- Apple circle
        Dot(s*.5,s*.58, s*.8)
        -- Stem
        RR(s*.46,s*.04, s*.08,s*.18, 1)
        -- Leaf
        L(s*.5,s*.1, s*.74,s*.02, 1.5)

    elseif iconName=="target" then
        -- Outer ring
        Ring(s*.5,s*.5, s*.96, 1.5)
        -- Middle ring
        Ring(s*.5,s*.5, s*.58, 1.5)
        -- Center dot
        Dot(s*.5,s*.5, s*.18)
        -- Crosshairs (4 short lines)
        L(s*.5,s*.0,  s*.5,s*.18, 1.5)  -- top
        L(s*.5,s*.82, s*.5,s*1.0, 1.5)  -- bottom
        L(s*.0,s*.5,  s*.18,s*.5, 1.5)  -- left
        L(s*.82,s*.5, s*1.0,s*.5, 1.5)  -- right

    elseif iconName=="user" then
        -- Head circle
        Ring(s*.5,s*.28, s*.38, 1.5)
        -- Body / shoulders arc (approximate with frame)
        local body = RR(s*.1,s*.6, s*.8,s*.4, s*.18)

    -- ── FISHING STAT ICONS ──────────────────────────────────────────────
    elseif iconName=="chest" then
        -- Chest body
        RR(s*.06,s*.45, s*.88,s*.52, 3)
        -- Chest lid
        RR(s*.06,s*.08, s*.88,s*.38, 3)
        -- Lid divider line
        L(s*.06,s*.45, s*.94,s*.45, 1.5)
        -- Lock clasp
        RR(s*.38,s*.36, s*.24,s*.20, 2)
        -- Keyhole
        Dot(s*.5,s*.56, s*.12)

    elseif iconName=="arrows" then
        -- Left arrow (←)
        L(s*.44,s*.28, s*.08,s*.28, 2)
        L(s*.08,s*.28, s*.20,s*.15, 2)
        L(s*.08,s*.28, s*.20,s*.41, 2)
        -- Right arrow (→)
        L(s*.56,s*.72, s*.92,s*.72, 2)
        L(s*.92,s*.72, s*.80,s*.59, 2)
        L(s*.92,s*.72, s*.80,s*.85, 2)
        -- Divider hint
        L(s*.44,s*.18, s*.56,s*.82, 1)

    elseif iconName=="coin" then
        -- Outer ring
        Ring(s*.5,s*.5, s*.88, 2)
        -- Inner ring
        Ring(s*.5,s*.5, s*.52, 1.5)
        -- Dollar/Peli sign vertical
        L(s*.5,s*.18, s*.5,s*.82, 1.5)
        -- Dollar/Peli sign crossbars
        L(s*.3,s*.32, s*.7,s*.32, 1.5)
        L(s*.3,s*.68, s*.7,s*.68, 1.5)

    elseif iconName=="bottle" then
        -- Neck
        RR(s*.38,s*.02, s*.24,s*.22, 2)
        -- Shoulder transition
        RR(s*.28,s*.20, s*.44,s*.12, 3)
        -- Body
        RR(s*.14,s*.30, s*.72,s*.65, 4)
        -- Label stripe
        RR(s*.22,s*.50, s*.56,s*.14, 2)
        -- Cap
        RR(s*.34,s*.0,  s*.32,s*.10, 2)

    end

    return c
end

-- Tween tất cả frames + strokes trong icon container (dùng cho tab active/inactive)
local function TweenIcon(iconContainer, clr, t)
    for _,f in ipairs(iconContainer:GetDescendants()) do
        if f:IsA("Frame") then
            TWEEN(f, t, {BackgroundColor3=clr})
        elseif f:IsA("UIStroke") then
            TWEEN(f, t, {Color=clr})
        end
    end
end

-- Toggle helper
local function MakePillToggle(parent, posX, posY, w, h, configKey, onCallback)
    local pill = NEW("TextButton",{
        Size=UDim2.new(0,w or 44,0,h or 24), Position=UDim2.new(0,posX,0,posY),
        BackgroundColor3=BG5, Text="", AutoButtonColor=false
    }, parent)
    CORNER(20, pill)
    local strk = STROKE(GOLD3, 1, 0, pill)
    local thumb = NEW("Frame",{
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,4,0.5,-8),
        BackgroundColor3=TEXT3, BorderSizePixel=0
    }, pill)
    CORNER(20, thumb)

    TogglesData[configKey] = TogglesData[configKey] or {Active=false,Btn=pill,Strk=strk,Thumb=thumb}
    TogglesData[configKey].Btn   = pill
    TogglesData[configKey].Strk  = strk
    TogglesData[configKey].Thumb = thumb
    if onCallback then TogglesData[configKey].Callback = onCallback end

    pill.MouseButton1Click:Connect(function()
        local d = TogglesData[configKey]
        d.Active = not d.Active
        local on = d.Active
        TWEEN(pill,  0.22, {BackgroundColor3 = on and GOLDD or BG5})
        TWEEN(strk,  0.22, {Color = on and GOLD2 or GOLD3})
        TWEEN(thumb, 0.22, {
            BackgroundColor3 = on and GOLD2 or TEXT3,
            Position = on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
        })
        if d.Callback then d.Callback(on) end
    end)
    return pill, strk, thumb
end

-- =====================================================================
-- MINI LOGO (Minimized state)
-- =====================================================================
local MiniLogo = NEW("ImageButton",{
    Size=UDim2.new(0,54,0,54), Position=UDim2.new(0,50,0.5,-27),
    Image="rbxassetid://108561234878560",
    BackgroundColor3=BG3, BackgroundTransparency=0,
    Visible=false, ZIndex=999
}, ScreenGui)
CORNER(27, MiniLogo)
STROKE(GOLD, 2.5, 0, MiniLogo)

local dM,dStM,sPM
MiniLogo.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dM=true;dStM=i.Position;sPM=MiniLogo.Position end end)
UIS.InputChanged:Connect(function(i) if dM and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dStM;MiniLogo.Position=UDim2.new(sPM.X.Scale,sPM.X.Offset+d.X,sPM.Y.Scale,sPM.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dM=false end end)

-- =====================================================================
-- MAIN FRAME
-- =====================================================================
local MainFrame = NEW("CanvasGroup",{
    Size=UDim2.new(0,720,0,520), Position=UDim2.new(0.5,-360,0.5,-230),
    BackgroundColor3=BG1, BorderSizePixel=0, ClipsDescendants=true
}, ScreenGui)
CORNER(12, MainFrame)
STROKE(GOLD, 1.5, 0.1, MainFrame)

-- ── ANIMATED BACKGROUND ───────────────────────────────────────────────
-- Deep gradient base
local BgBase = NEW("Frame",{
    Size=UDim2.new(1,0,1,0), BackgroundColor3=BG0,
    ZIndex=0, BorderSizePixel=0, ClipsDescendants=false
}, MainFrame)
CORNER(12, BgBase)
local BgGrad = Instance.new("UIGradient")
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   C(10, 11, 26)),
    ColorSequenceKeypoint.new(0.45, C(14, 15, 36)),
    ColorSequenceKeypoint.new(1,   C(7,  8,  18)),
})
BgGrad.Rotation = 135
BgGrad.Parent = BgBase

-- Gold corner accent glow (top-left)
local glowTL = NEW("Frame",{
    Size=UDim2.new(0,220,0,220),
    Position=UDim2.new(0,-60,0,-60),
    BackgroundColor3=C(120,90,20),
    BackgroundTransparency=0.93, ZIndex=0, BorderSizePixel=0
}, MainFrame)
CORNER(110, glowTL)

-- Gold corner accent glow (bottom-right)
local glowBR = NEW("Frame",{
    Size=UDim2.new(0,180,0,180),
    Position=UDim2.new(1,-100,1,-100),
    BackgroundColor3=C(100,70,15),
    BackgroundTransparency=0.94, ZIndex=0, BorderSizePixel=0
}, MainFrame)
CORNER(90, glowBR)

-- Shimmer sweep line (repeating)
local shimmer = NEW("Frame",{
    Size=UDim2.new(0,3,1.6,0),
    Position=UDim2.new(-0.1,0,-0.3,0),
    BackgroundColor3=GOLD2,
    BackgroundTransparency=0.91, ZIndex=0, BorderSizePixel=0,
    Rotation=18
}, MainFrame)

-- Floating gold particle spawner
local function SpawnBgDot()
    if not MainFrame or not MainFrame.Parent then return end
    local sz = math.random(2, 5)
    local xRatio = math.random(5, 95) / 100
    local p = NEW("Frame",{
        Size=UDim2.new(0,sz,0,sz),
        Position=UDim2.new(xRatio,0, 1.04, 0),
        BackgroundColor3=math.random()<0.6 and GOLD or GOLD2,
        BackgroundTransparency=math.random(60,80)/100,
        ZIndex=0, BorderSizePixel=0
    }, MainFrame)
    CORNER(sz, p)
    local dur = math.random(5,10)
    TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
        Position=UDim2.new(xRatio, math.random(-30,30), -0.06, 0),
        BackgroundTransparency=1
    }):Play()
    task.delay(dur+0.2, function() if p and p.Parent then p:Destroy() end end)
end

task.spawn(function()
    while MainFrame and MainFrame.Parent do
        local ap = MainFrame.AbsoluteSize
        if ap.X > 50 then
            shimmer.Position = UDim2.new(-0.1,0,-0.3,0)
            TweenService:Create(shimmer, TweenInfo.new(4.0, Enum.EasingStyle.Quad), {
                Position=UDim2.new(1.1,0,-0.3,0)
            }):Play()
        end
        task.wait(7.0)
    end
end)

task.spawn(function()
    while MainFrame and MainFrame.Parent do
        task.wait(0.9)
        SpawnBgDot()
    end
end)

-- ── CORNER L-BRACKETS ────────────────────────────────────────────────
-- Decorative cyan L-brackets overlaid on MainFrame corners
local BRACKET_LEN = 18
local BRACKET_THICK = 2
local BRACKET_COLOR = CYAN
local BRACKET_TRANS = 0.25

local function MakeBracket(anchorX, anchorY, flipX, flipY)
    local bGroup = NEW("Frame",{
        Size=UDim2.new(0, BRACKET_LEN+BRACKET_THICK, 0, BRACKET_LEN+BRACKET_THICK),
        AnchorPoint=Vector2.new(anchorX, anchorY),
        Position=UDim2.new(anchorX, anchorX==0 and 2 or -2, anchorY, anchorY==0 and 2 or -2),
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=50
    }, MainFrame)
    -- Horizontal bar
    local hx = flipX and (BRACKET_LEN) or 0
    NEW("Frame",{
        Size=UDim2.new(0, BRACKET_LEN, 0, BRACKET_THICK),
        Position=UDim2.new(0, flipX and 0 or 0, 0, flipY and BRACKET_LEN or 0),
        BackgroundColor3=BRACKET_COLOR, BackgroundTransparency=BRACKET_TRANS, BorderSizePixel=0, ZIndex=51
    }, bGroup)
    -- Vertical bar
    NEW("Frame",{
        Size=UDim2.new(0, BRACKET_THICK, 0, BRACKET_LEN),
        Position=UDim2.new(0, flipX and BRACKET_LEN or 0, 0, flipY and BRACKET_THICK or 0),
        BackgroundColor3=BRACKET_COLOR, BackgroundTransparency=BRACKET_TRANS, BorderSizePixel=0, ZIndex=51
    }, bGroup)
    return bGroup
end

-- 4 corners: TL, TR, BL, BR
local bracketTL = MakeBracket(0, 0, false, false)
local bracketTR = MakeBracket(1, 0, true,  false)
local bracketBL = MakeBracket(0, 1, false, true)
local bracketBR = MakeBracket(1, 1, true,  true)

-- Animate brackets: subtle pulse
task.spawn(function()
    while MainFrame and MainFrame.Parent do
        for _, br in ipairs({bracketTL,bracketTR,bracketBL,bracketBR}) do
            for _, f in ipairs(br:GetChildren()) do
                if f:IsA("Frame") then
                    TWEEN(f, 1.5, {BackgroundTransparency=0.05})
                end
            end
        end
        task.wait(2.0)
        for _, br in ipairs({bracketTL,bracketTR,bracketBL,bracketBR}) do
            for _, f in ipairs(br:GetChildren()) do
                if f:IsA("Frame") then
                    TWEEN(f, 1.5, {BackgroundTransparency=BRACKET_TRANS})
                end
            end
        end
        task.wait(2.0)
    end
end)

-- =====================================================================
-- TOP BAR
-- =====================================================================
local TopBar = NEW("Frame",{
    Size=UDim2.new(1,0,0,48), BackgroundColor3=BG2, BorderSizePixel=0
}, MainFrame)
CORNER(12, TopBar)
-- extend bottom corners
NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG2,BorderSizePixel=0}, TopBar)
-- bottom border gradient line
local topBorderLine = NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=GOLD,BorderSizePixel=0,BackgroundTransparency=0.55}, TopBar)
local topLineGrad = Instance.new("UIGradient")
topLineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C(0,210,200)),
    ColorSequenceKeypoint.new(0.35, GOLD2),
    ColorSequenceKeypoint.new(0.65, GOLD),
    ColorSequenceKeypoint.new(1, C(140,90,230)),
})
topLineGrad.Parent = topBorderLine

-- Hexagonal logo badge (drawn with frames to simulate hex shape)
local LogoBadge = NEW("Frame",{
    Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,13,0.5,-17),
    BackgroundColor3=C(12,14,30)
}, TopBar)
CORNER(6, LogoBadge)
STROKE(GOLD, 1.5, 0.15, LogoBadge)
-- inner hex fill
local hexInner = NEW("Frame",{
    Size=UDim2.new(0,26,0,26),Position=UDim2.new(0.5,-13,0.5,-13),
    BackgroundColor3=C(20,22,48)
},LogoBadge)
CORNER(5,hexInner)
NEW("ImageLabel",{
    Size=UDim2.new(0,20,0,20), Position=UDim2.new(0.5,-10,0.5,-10),
    Image="rbxassetid://108561234878560", BackgroundTransparency=1
}, LogoBadge)
-- animated glow ring on badge
local badgeGlow = STROKE(GOLD2, 1, 0.6, LogoBadge)
task.spawn(function()
    while TopBar and TopBar.Parent do
        TWEEN(badgeGlow,1.2,{Transparency=0.2})
        task.wait(1.4)
        TWEEN(badgeGlow,1.2,{Transparency=0.75})
        task.wait(1.4)
    end
end)

-- Title: "ZILI HUB" in gold
NEW("TextLabel",{
    Text="ZILI HUB", Position=UDim2.new(0,55,0,8),
    Size=UDim2.new(0,90,0,18), TextColor3=GOLD2,
    Font=Enum.Font.GothamBold, TextSize=13, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left
}, TopBar)
-- Separator
NEW("TextLabel",{
    Text="|", Position=UDim2.new(0,148,0,8),
    Size=UDim2.new(0,12,0,18), TextColor3=TEXT3,
    Font=Enum.Font.GothamBold, TextSize=14, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Center
}, TopBar)
-- "GBO" in cyan
NEW("TextLabel",{
    Text="GBO", Position=UDim2.new(0,163,0,8),
    Size=UDim2.new(0,40,0,18), TextColor3=CYAN,
    Font=Enum.Font.GothamBold, TextSize=13, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left
}, TopBar)

-- Version badge below title
local VerBadge = NEW("TextLabel",{
    Text="v2.5  ·  PREMIUM",
    Position=UDim2.new(0,55,0,28), Size=UDim2.new(0,200,0,12),
    TextColor3=TEXT3, Font=Enum.Font.GothamBold, TextSize=9,
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
}, TopBar)

-- Control buttons
local function MakeCtrlBtn(text, posX, col, bgCol)
    local btn = NEW("TextButton",{
        Text=text, Position=UDim2.new(1,posX,0.5,0),
        AnchorPoint=Vector2.new(0,0.5),
        Size=UDim2.new(0,26,0,26), TextColor3=col,
        TextSize=12, BackgroundColor3=bgCol or BG3,
        Font=Enum.Font.GothamBold, AutoButtonColor=false
    }, TopBar)
    CORNER(6, btn)
    STROKE(col, 1, 0.5, btn)
    btn.MouseEnter:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=BG4,TextColor3=C(255,255,255)}) end)
    btn.MouseLeave:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=bgCol or BG3,TextColor3=col}) end)
    return btn
end
local MinBtn   = MakeCtrlBtn("—", -64, TEXT2)
local CloseBtn = MakeCtrlBtn("✕", -32, RED)

-- =====================================================================
-- SIDEBAR
-- =====================================================================
local Sidebar = NEW("Frame",{
    Size=UDim2.new(0,178,1,-48), Position=UDim2.new(0,0,0,48),
    BackgroundColor3=BG2, BorderSizePixel=0
}, MainFrame)
CORNER(12, Sidebar)
-- right divider
NEW("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=GOLD,BackgroundTransparency=0.82,BorderSizePixel=0}, Sidebar)

-- User card
local UserCard = NEW("Frame",{
    Size=UDim2.new(1,-16,0,60), Position=UDim2.new(0,8,1,-68),
    BackgroundColor3=BG3
}, Sidebar)
CORNER(10, UserCard)
STROKE(GOLD, 1, 0.65, UserCard)
-- gold top accent on user card
NEW("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,0,0),BackgroundColor3=GOLD,BorderSizePixel=0,BackgroundTransparency=0.5}, UserCard)
CORNER(10, UserCard:FindFirstChildOfClass("Frame"))

local UserImg = NEW("ImageLabel",{
    Size=UDim2.new(0,38,0,38), Position=UDim2.new(0,10,0.5,-19),
    BackgroundColor3=BG4
}, UserCard)
CORNER(19, UserImg)
STROKE(GOLD, 1.5, 0.3, UserImg)
pcall(function() UserImg.Image=Players:GetUserThumbnailAsync(LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420) end)

NEW("TextLabel",{
    Text=LocalPlayer.DisplayName,
    Position=UDim2.new(0,55,0,10), Size=UDim2.new(1,-59,0,18),
    TextColor3=TEXT1, Font=Enum.Font.GothamBold, TextSize=12,
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
}, UserCard)
NEW("TextLabel",{
    Text="⭐  Premium",
    Position=UDim2.new(0,55,0,30), Size=UDim2.new(1,-59,0,14),
    TextColor3=GOLD2, Font=Enum.Font.GothamBold, TextSize=10,
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
}, UserCard)

-- TAB SCROLL
local TabScroll = NEW("ScrollingFrame",{
    Size=UDim2.new(1,-8,1,-80), Position=UDim2.new(0,4,0,6),
    BackgroundTransparency=1, ScrollBarThickness=0,
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    CanvasSize=UDim2.new(0,0,0,0), ClipsDescendants=true
}, Sidebar)
local TabLayout = NEW("UIListLayout",{
    HorizontalAlignment=Enum.HorizontalAlignment.Center,
    Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder
}, TabScroll)
NEW("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)}, TabScroll)

-- Tab section separator helper
local function TabSep(label)
    local f = NEW("Frame",{Size=UDim2.new(0,160,0,20),BackgroundTransparency=1}, TabScroll)
    local line = NEW("Frame",{Size=UDim2.new(1,-60,0,1),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C(30,28,55),BorderSizePixel=0}, f)
    NEW("Frame",{Size=UDim2.new(1,-60,0,1),Position=UDim2.new(1,-0,0.5,0),BackgroundColor3=C(30,28,55),BorderSizePixel=0}, f) -- right side
    NEW("TextLabel",{
        Text=label, Size=UDim2.new(0,60,1,0), Position=UDim2.new(0.5,-30,0,0),
        BackgroundTransparency=1, TextColor3=TEXT3, Font=Enum.Font.GothamBold,
        TextSize=8, TextXAlignment=Enum.TextXAlignment.Center
    }, f)
    return f
end

-- PAGE CONTAINER
local PageContainer = NEW("Frame",{
    Size=UDim2.new(1,-178,1,-48), Position=UDim2.new(0,178,0,48),
    BackgroundTransparency=1
}, MainFrame)

-- Tab system
local Tabs={} local Pages={} local SelectedTab=nil local SelectedPage=nil

local TAB_ICONS = {
    ["Main"]              = "home",
    ["Auto Farm"]         = "sword",
    ["Travel"]            = "globe",
    ["Fishing + Merchant"]= "fish",
    ["Stats"]             = "chart",
    ["Config"]            = "gear",
    ["Private Server"]    = "shield",
}local function AddTab(name)
    local iconName = TAB_ICONS[name] or "home"
    local btn = NEW("TextButton",{
        Size=UDim2.new(0,162,0,36), BackgroundTransparency=1,
        Text="", TextColor3=TEXT3,
        Font=Enum.Font.GothamSemibold, TextSize=12,
        AutoButtonColor=false, TextXAlignment=Enum.TextXAlignment.Left
    }, TabScroll)
    CORNER(7, btn)
    btn.BackgroundColor3 = BG3

    -- left accent bar — sits at very left edge, BEHIND icon
    local accent = NEW("Frame",{
        Size=UDim2.new(0,3,0.6,0), Position=UDim2.new(0,0,0.2,0),
        BackgroundColor3=GOLD2, BorderSizePixel=0, Visible=false
    }, btn)
    CORNER(2, accent)

    -- SVG-style icon (centered vertically in 36px button)
    local iconContainer = DrawIcon(btn, iconName, 10, 11, 14, TEXT3)

    -- name label (offset right of icon)
    local nameLbl = NEW("TextLabel",{
        Text=name, Size=UDim2.new(1,-38,1,0), Position=UDim2.new(0,36,0,0),
        BackgroundTransparency=1, TextColor3=TEXT3,
        Font=Enum.Font.GothamSemibold, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left
    }, btn)

    local page = NEW("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Visible=false, Name=name.."Page",
        ScrollBarThickness=3, ScrollBarImageColor3=GOLD,
        ClipsDescendants=true
    }, PageContainer)

    Tabs[name]=btn; Pages[name]=page

    btn.MouseEnter:Connect(function()
        if SelectedTab~=btn then
            TWEEN(nameLbl,0.15,{TextColor3=TEXT1})
            TWEEN(btn,0.15,{BackgroundTransparency=0.88})
        end
    end)
    btn.MouseLeave:Connect(function()
        if SelectedTab~=btn then
            TWEEN(nameLbl,0.15,{TextColor3=TEXT3})
            TWEEN(btn,0.15,{BackgroundTransparency=1})
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if SelectedTab then
            TWEEN(SelectedTab,0.18,{BackgroundTransparency=1})
            -- reset name label color of previous tab
            local lbls = {}
            for _,c in ipairs(SelectedTab:GetChildren()) do if c:IsA("TextLabel") then table.insert(lbls,c) end end
            if lbls[1] then TWEEN(lbls[1],0.18,{TextColor3=TEXT3}); lbls[1].Font=Enum.Font.GothamSemibold end
            -- reset previous icon color
            for _,child in ipairs(SelectedTab:GetChildren()) do
                if child:IsA("Frame") and child~=accent then TweenIcon(child,TEXT3,0.18) end
            end
            -- hide previous accent bar
            local prevAccent = SelectedTab:FindFirstChild("Frame")
            if prevAccent then prevAccent.Visible=false end
            if SelectedPage then SelectedPage.Visible=false end
        end
        SelectedTab=btn; SelectedPage=page
        TWEEN(btn,0.18,{BackgroundTransparency=0.82})
        TWEEN(nameLbl,0.18,{TextColor3=GOLD2})
        nameLbl.Font=Enum.Font.GothamBold
        TweenIcon(iconContainer,GOLD2,0.18)
        accent.Visible=true; page.Visible=true
    end)
    if SelectedTab==nil then
        btn.BackgroundTransparency=0.82
        nameLbl.TextColor3=GOLD2; nameLbl.Font=Enum.Font.GothamBold
        TweenIcon(iconContainer,GOLD2,0)
        SelectedTab=btn; SelectedPage=page; page.Visible=true; accent.Visible=true
    end
    return page
end

-- Build tabs based on PlaceId
local MainPage = AddTab("Main")
local AutoFarmPage, TravelPage, FishingPage, StatsPage
local PrivateServerPage  -- Lobby only

if not IS_LOBBY then
    -- Game world: all tabs
    TabSep("FARM")
    AutoFarmPage = AddTab("Auto Farm")
    TabSep("WORLD")
    TravelPage   = AddTab("Travel")
    FishingPage  = AddTab("Fishing + Merchant")
    TabSep("DATA")
    StatsPage    = AddTab("Stats")
else
    -- Lobby: Private Server dedicated tab
    TabSep("SERVER")
    PrivateServerPage = AddTab("Private Server")
end

local ConfigPage = AddTab("Config")

-- =====================================================================
-- SHARED DATA
-- =====================================================================
local TogglesData = {}

-- =====================================================================
-- CARD BUILDER HELPERS
-- =====================================================================
local function MakeCard(parent, h, layoutOrder)
    local f = NEW("Frame",{
        Size=UDim2.new(1,-24,0,h), BackgroundColor3=BG3,
        LayoutOrder=layoutOrder or 0, ClipsDescendants=true
    }, parent)
    CORNER(8, f)
    STROKE(GOLD, 1, 0.82, f)
    return f
end

-- CardHeader: accent color per section, letter-tracked label, small square icon
local function CardHeader(card, iconName, label, accentCol)
    accentCol = accentCol or GOLD
    local darkBg = C(
        math.floor(accentCol.R*255*0.04 + BG_HDR.R*255*0.96),
        math.floor(accentCol.G*255*0.04 + BG_HDR.G*255*0.96),
        math.floor(accentCol.B*255*0.04 + BG_HDR.B*255*0.96)
    )

    local bar = NEW("Frame",{
        Size=UDim2.new(1,0,0,28), BackgroundColor3=BG_HDR
    }, card)
    CORNER(8, bar)
    -- extend bottom half to cover corners
    NEW("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=BG_HDR,BorderSizePixel=0}, bar)

    -- Left accent bar (colored)
    local accBar = NEW("Frame",{
        Size=UDim2.new(0,2,0.55,0),Position=UDim2.new(0,0,0.225,0),
        BackgroundColor3=accentCol,BorderSizePixel=0
    },bar)
    CORNER(1,accBar)

    -- Small square icon (colored)
    local iconBg = NEW("Frame",{
        Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,7,0,6),
        BackgroundColor3=C(
            math.min(255, math.floor(accentCol.R*255*0.15 + 10)),
            math.min(255, math.floor(accentCol.G*255*0.15 + 10)),
            math.min(255, math.floor(accentCol.B*255*0.15 + 10))
        )
    },bar)
    CORNER(4,iconBg)
    DrawIcon(iconBg, iconName, 2, 2, 12, accentCol)

    -- Label (uppercase, letter-spaced simulation via Gotham)
    NEW("TextLabel",{
        Text=label, Size=UDim2.new(1,-40,1,0), Position=UDim2.new(0,30,0,0),
        BackgroundTransparency=1, TextColor3=accentCol,
        Font=Enum.Font.GothamBold,
        TextSize=9, TextXAlignment=Enum.TextXAlignment.Left
    }, bar)

    -- Bottom accent line (thin, colored)
    local bottomLine = NEW("Frame",{
        Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=accentCol,BorderSizePixel=0,BackgroundTransparency=0.7
    },bar)

    return bar
end

local function RowDivider(card, posY)
    NEW("Frame",{
        Size=UDim2.new(1,-24,0,1), Position=UDim2.new(0,12,0,posY),
        BackgroundColor3=C(25,24,50), BorderSizePixel=0
    }, card)
end

local function RowLabel(card, mainText, subText, posY)
    NEW("TextLabel",{
        Text=mainText, Size=UDim2.new(0.62,0,0,22), Position=UDim2.new(0,14,0,posY),
        BackgroundTransparency=1, TextColor3=TEXT1, Font=Enum.Font.GothamSemibold,
        TextSize=14, TextXAlignment=Enum.TextXAlignment.Left
    }, card)
    if subText then
        NEW("TextLabel",{
            Text=subText, Size=UDim2.new(0.68,0,0,14), Position=UDim2.new(0,14,0,posY+22),
            BackgroundTransparency=1, TextColor3=GOLD3, Font=Enum.Font.GothamBold,
            TextSize=10, TextXAlignment=Enum.TextXAlignment.Left
        }, card)
    end
end

-- Pill toggle factory for cards
local function CardToggle(card, posY, configKey, callback)
    local pill = NEW("TextButton",{
        Size=UDim2.new(0,44,0,24), Position=UDim2.new(1,-56,0,posY),
        BackgroundColor3=BG5, Text="", AutoButtonColor=false
    }, card)
    CORNER(20, pill)
    local strk = STROKE(GOLD3, 1, 0, pill)
    local thumb = NEW("Frame",{
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,4,0.5,-8),
        BackgroundColor3=TEXT3, BorderSizePixel=0
    }, pill)
    CORNER(20, thumb)

    TogglesData[configKey] = {Active=false, Btn=pill, Strk=strk, Thumb=thumb, Callback=callback or function() end}

    pill.MouseButton1Click:Connect(function()
        local d = TogglesData[configKey]
        d.Active = not d.Active
        local on = d.Active
        TWEEN(pill,  0.22, {BackgroundColor3=on and GOLDD or BG5})
        TWEEN(strk,  0.22, {Color=on and GOLD2 or GOLD3})
        TWEEN(thumb, 0.22, {
            BackgroundColor3=on and GOLD2 or TEXT3,
            Position=on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
        })
        if d.Callback then d.Callback(on) end
    end)
    return pill, strk, thumb
end

-- Page layout helper
local function PageLayout(page, padTop, gap)
    local l = NEW("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,gap or 10)
    }, page)
    NEW("UIPadding",{PaddingTop=UDim.new(0,padTop or 14),PaddingLeft=UDim.new(0,0),PaddingRight=UDim.new(0,0),PaddingBottom=UDim.new(0,14)}, page)
    return l
end

-- =====================================================================
-- ██████  MAIN PAGE
-- =====================================================================
PageLayout(MainPage, 14, 10)

if IS_LOBBY then
    -- ══════════════════════════════════════════════════════════════════
    -- LOBBY BUILD — Race Reroll, Skin Changer, Private Server
    -- ══════════════════════════════════════════════════════════════════

    -- Helper: sync toggle visual state từ bên ngoài (e.g. auto-off callback)
    local function SetToggleState(key, state)
        local d = TogglesData[key]
        if not d then return end
        d.Active = state
        local on = state
        TWEEN(d.Btn,  0.22, {BackgroundColor3 = on and GOLDD or BG5})
        TWEEN(d.Strk, 0.22, {Color           = on and GOLD2 or GOLD3})
        if d.Thumb then
            TWEEN(d.Thumb, 0.22, {
                BackgroundColor3 = on and GOLD2 or TEXT3,
                Position         = on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
            })
        end
    end

    -- ── RACE REROLL ──────────────────────────────────────────────────
    local RaceCard = MakeCard(MainPage, 318, 1)
    CardHeader(RaceCard, "target", "RACE CHANGER", AMBER)

    -- Toggle row
    RowLabel(RaceCard, "Auto Race Reroll", "Select a race below · auto-stops on match", 38)
    CardToggle(RaceCard, 38, "AutoRace", function(state)
        if state then
            RaceModule.Start(getgenv().TargetRace or "", function()
                SetToggleState("AutoRace", false)
            end)
        else
            RaceModule.Stop()
        end
    end)
    RowDivider(RaceCard, 74)

    -- Search box
    local rSearchBg = NEW("Frame",{Size=UDim2.new(1,-24,0,30),Position=UDim2.new(0,12,0,82),BackgroundColor3=BG5,BorderSizePixel=0},RaceCard)
    CORNER(6,rSearchBg); STROKE(GOLD3,1,0.5,rSearchBg)
    NEW("TextLabel",{Size=UDim2.new(0,28,1,0),BackgroundTransparency=1,Text="🔍",TextColor3=TEXT3,Font=Enum.Font.Legacy,TextSize=13},rSearchBg)
    local rSearch = NEW("TextBox",{Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,28,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Search race...",TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=true},rSearchBg)

    -- Race scroll list
    local rScroll = NEW("ScrollingFrame",{
        Size=UDim2.new(1,-24,0,148),Position=UDim2.new(0,12,0,120),
        BackgroundColor3=BG5,BorderSizePixel=0,
        ScrollBarThickness=2,ScrollBarImageColor3=GOLD3,CanvasSize=UDim2.new(0,0,0,0)
    },RaceCard)
    CORNER(8,rScroll); STROKE(GOLD3,1,0.5,rScroll)
    NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Center},rScroll)
    NEW("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},rScroll)

    getgenv().TargetRace = ""
    local RaceButtons = {}
    local raceList = {{"Cyborg","Cyborg"},{"Vampire","Vampire"},{"Mink","Mink"},{"Fishman","Fishman"},{"Skypian","Skypian"},{"Human","Human"},{"Dullahan","Dullahan (Not Working)"}}

    local function UpdateRaceSelection()
        for rn,d in pairs(RaceButtons) do
            local sel = (rn == getgenv().TargetRace)
            TWEEN(d.Btn,0.18,{BackgroundColor3=sel and GOLDD or BG4})
            TWEEN(d.Strk,0.18,{Color=sel and GOLD2 or C(40,40,55)})
            d.Btn.TextColor3 = sel and TEXT1 or TEXT2
            d.Icon.Text = sel and "✓" or ""
        end
        -- save for config (value kept up-to-date via Callback entry below)
        if TogglesData["Config_TargetRace"] then
            TogglesData["Config_TargetRace"].Value = getgenv().TargetRace
        end
    end

    for i,info in ipairs(raceList) do
        local rn,dn = info[1],info[2]
        local rBtn = NEW("TextButton",{
            Size=UDim2.new(1,-12,0,28),Name=rn,
            BackgroundColor3=BG4,Text="   "..dn,
            TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,LayoutOrder=i
        },rScroll)
        CORNER(6,rBtn)
        local rStrk = STROKE(C(40,40,55),1,0,rBtn)
        local rIcon = NEW("TextLabel",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-26,0.5,-11),BackgroundTransparency=1,Text="",TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=13},rBtn)
        RaceButtons[rn] = {Btn=rBtn,Icon=rIcon,Strk=rStrk}
        rBtn.MouseEnter:Connect(function() if rn~=getgenv().TargetRace then TWEEN(rBtn,0.12,{BackgroundColor3=BG3}) end end)
        rBtn.MouseLeave:Connect(function() if rn~=getgenv().TargetRace then TWEEN(rBtn,0.12,{BackgroundColor3=BG4}) end end)
        rBtn.MouseButton1Click:Connect(function()
            getgenv().TargetRace = (getgenv().TargetRace==rn) and "" or rn
            UpdateRaceSelection()
        end)
    end
    rScroll.CanvasSize = UDim2.new(0,0,0,(#raceList*33)+12)

    rSearch:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(rSearch.Text)
        local vis = 0
        for rn,d in pairs(RaceButtons) do
            local show = q=="" or string.find(string.lower(rn),q)
            d.Btn.Visible = show~=nil
            if show then vis=vis+1 end
        end
        rScroll.CanvasSize = UDim2.new(0,0,0,(vis*33)+12)
    end)

    UpdateRaceSelection()
    -- expose UpdateFn + Callback so ConfigManager can restore and re-highlight on load
    TogglesData["Config_TargetRace"] = {
        Value     = "",
        Callback  = function(val)
            getgenv().TargetRace = val or ""
            UpdateRaceSelection()
        end,
        UpdateFn  = UpdateRaceSelection,
    }

    -- ── SKIN CHANGER ─────────────────────────────────────────────────
    local skinCard = MakeCard(MainPage, 124, 2)
    CardHeader(skinCard, "user", "SKIN CHANGER", GOLD2)

    -- One-shot randomize
    RowLabel(skinCard, "Randomize Once", "One-shot: randomizes all cosmetics now", 34)
    CardToggle(skinCard, 38, "AutoSkinDisco", function(state)
        if not state then return end
        task.spawn(function()
            SkinModule.Randomize()
            task.wait(0.25)
            SetToggleState("AutoSkinDisco", false)
        end)
    end)
    RowDivider(skinCard, 72)

    -- Auto Change Skin loop (saves to config)
    RowLabel(skinCard, "Auto Change Skin", "Re-randomize every race reroll or on loop", 78)
    CardToggle(skinCard, 82, "AutoChangeSkin", function(state)
        getgenv().AutoChangeSkin = state
        if state then
            task.spawn(function()
                while getgenv().AutoChangeSkin do
                    SkinModule.Randomize()
                    task.wait(30)  -- randomize every 30s when on
                end
            end)
        end
    end)

    -- ── PRIVATE SERVER ────────────────────────────────────────────────
    getgenv().PSCode       = ""
    getgenv().SelectedHub  = "Regular"
    getgenv().SelectedSea  = "Sea 1"

    local HubArgs = {["Regular"]=true,["Trade Hub"]="tradeHub",["Universe Hub"]="universeHub",["Fish Hub"]="fishHub"}
    local HubButtons = {}
    local SeaToggles = {}
    local UpdateUIState  -- forward decl

    -- ── PS page layout ────────────────────────────────────────────────
    PageLayout(PrivateServerPage, 14, 10)

    local psCard = MakeCard(PrivateServerPage, 468, 1)
    CardHeader(psCard, "globe", "PRIVATE SERVER", PINK)

    -- Code input
    local psBg = NEW("Frame",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,36),BackgroundColor3=BG5,BorderSizePixel=0},psCard)
    CORNER(6,psBg); STROKE(GOLD3,1,0.5,psBg)
    local psBox = NEW("TextBox",{
        Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,
        Text="",PlaceholderText="Paste Private Server code here...",
        TextColor3=TEXT1,PlaceholderColor3=TEXT3,Font=Enum.Font.Gotham,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false
    },psBg)
    -- Init Config_PSCode entry with HeadBtn ref so ConfigManager can restore text
    TogglesData["Config_PSCode"] = {
        Value    = "",
        HeadBtn  = psBox,
        Callback = function(val)
            getgenv().PSCode = val or ""
            pcall(function() psBox.Text = val or "" end)
        end,
    }
    psBox:GetPropertyChangedSignal("Text"):Connect(function()
        getgenv().PSCode = psBox.Text
        TogglesData["Config_PSCode"].Value = psBox.Text
    end)

    -- Auto Join toggle
    RowDivider(psCard, 76)
    RowLabel(psCard, "Auto Join Server", "Empty code = public server · code = private", 82)
    CardToggle(psCard, 82, "AutoJoinPS", function(state)
        if not state then return end
        -- Nếu đã trong PS rồi → bỏ qua
        if game.PrivateServerId ~= "" then
            task.spawn(function() task.wait(0.3); SetToggleState("AutoJoinPS", false) end)
            return
        end
        local code = getgenv().PSCode or ""
        local arg
        if code == "" then
            arg = nil
        else
            arg = HubArgs[getgenv().SelectedHub]
            if getgenv().SelectedHub == "Regular" then
                arg = (getgenv().SelectedSea == "Sea 2") and 2 or true
            end
        end
        ServerModule.Join(code, arg)
        task.spawn(function() task.wait(1); SetToggleState("AutoJoinPS", false) end)
    end)

    -- Hub destination
    RowDivider(psCard, 120)
    RowLabel(psCard, "Destination Hub", "Choose where to join", 126)

    local hubListFrame = NEW("ScrollingFrame",{
        Size=UDim2.new(1,-24,0,148),Position=UDim2.new(0,12,0,152),
        BackgroundColor3=BG5,BorderSizePixel=0,
        ScrollBarThickness=2,ScrollBarImageColor3=GOLD3,CanvasSize=UDim2.new(0,0,0,0)
    },psCard)
    CORNER(8,hubListFrame); STROKE(GOLD3,1,0.5,hubListFrame)
    local hubLayout = NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Center},hubListFrame)
    NEW("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},hubListFrame)
    hubLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        hubListFrame.CanvasSize = UDim2.new(0,0,0,hubLayout.AbsoluteContentSize.Y+12)
    end)

    local hubList = {{"Regular","🌍  Regular"},{"Trade Hub","🤝  Trade Hub"},{"Universe Hub","🌌  Universe Hub"},{"Fish Hub","🎣  Fish Hub"}}

    local function UpdateHubSelection()
        for id,d in pairs(HubButtons) do
            local sel = (id==getgenv().SelectedHub)
            TWEEN(d.Btn,0.18,{BackgroundColor3=sel and GOLDD or BG4})
            TWEEN(d.Strk,0.18,{Color=sel and GOLD2 or C(40,40,55)})
            d.Btn.TextColor3 = sel and TEXT1 or TEXT2
            d.Icon.Text = sel and "✓" or ""
        end
        if UpdateUIState then UpdateUIState() end
        -- keep Value in sync (Config_SelectedHub entry set below)
        if TogglesData["Config_SelectedHub"] then
            TogglesData["Config_SelectedHub"].Value = getgenv().SelectedHub
        end
    end

    for i,hd in ipairs(hubList) do
        local id,label = hd[1],hd[2]
        local hBtn = NEW("TextButton",{
            Size=UDim2.new(1,-12,0,30),Name=id,
            BackgroundColor3=BG4,Text="   "..label,
            TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,LayoutOrder=i
        },hubListFrame)
        CORNER(6,hBtn); local hStrk=STROKE(C(40,40,55),1,0,hBtn)
        local hIcon=NEW("TextLabel",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-26,0.5,-11),BackgroundTransparency=1,Text="",TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=13},hBtn)
        HubButtons[id]={Btn=hBtn,Icon=hIcon,Strk=hStrk}
        hBtn.MouseEnter:Connect(function() if id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundColor3=BG3}) end end)
        hBtn.MouseLeave:Connect(function() if id~=getgenv().SelectedHub then TWEEN(hBtn,0.12,{BackgroundColor3=BG4}) end end)
        hBtn.MouseButton1Click:Connect(function()
            if getgenv().SelectedHub~=id then getgenv().SelectedHub=id; UpdateHubSelection() end
        end)
    end

    -- Sea selector (only visible for Regular)
    local seaDivider = RowDivider(psCard, 314)
    local seaMainLbl = RowLabel(psCard, "Regular Sea", "Choose Sea 1 or Sea 2", 320)

    RowLabel(psCard, "Sea 1", nil, 358)
    CardToggle(psCard, 358, "Sea1Toggle", function(state)
        if getgenv().SelectedHub~="Regular" or not state then return end
        getgenv().SelectedSea = "Sea 1"
        TogglesData["Config_SelectedSea"].Value = "Sea 1"
        if TogglesData["Sea2Toggle"] and TogglesData["Sea2Toggle"].Active then
            SetToggleState("Sea2Toggle",false)
        end
    end)
    RowDivider(psCard, 394)
    RowLabel(psCard, "Sea 2", nil, 400)
    CardToggle(psCard, 400, "Sea2Toggle", function(state)
        if getgenv().SelectedHub~="Regular" or not state then return end
        getgenv().SelectedSea = "Sea 2"
        TogglesData["Config_SelectedSea"].Value = "Sea 2"
        if TogglesData["Sea1Toggle"] and TogglesData["Sea1Toggle"].Active then
            SetToggleState("Sea1Toggle",false)
        end
    end)

    -- Config_SelectedSea entry with restore Callback
    TogglesData["Config_SelectedSea"] = {
        Value    = "Sea 1",
        Callback = function(val)
            getgenv().SelectedSea = val or "Sea 1"
            local isS1 = (getgenv().SelectedSea == "Sea 1")
            -- visually sync sea toggles without firing their callbacks
            SetToggleState("Sea1Toggle", isS1)
            SetToggleState("Sea2Toggle", not isS1)
        end,
    }

    -- Default: Sea 1 ON, hub = Regular
    task.spawn(function()
        task.wait(0.1)
        UpdateHubSelection()
        SetToggleState("Sea1Toggle", true)
    end)

    -- ── AUTO-JOIN khi vào lobby sau khi bị kick (từ Auto Rejoin game world) ──
    task.spawn(function()
        task.wait(2.5)  -- chờ lobby load xong
        local pending = getgenv().GBO_PendingJoin
        -- Fallback: đọc file nếu executor đã reset getgenv sau teleport
        if not pending then
            pcall(function()
                if isfile and isfile("gbo_pending_join.json") then
                    local hs = game:GetService("HttpService")
                    local ok, data = pcall(function()
                        return hs:JSONDecode(readfile("gbo_pending_join.json"))
                    end)
                    if ok and type(data)=="table" then
                        pending = data
                        pcall(function() deletefile("gbo_pending_join.json") end)
                    end
                end
            end)
        end
        if pending and type(pending)=="table" and (pending.code or pending.hub) then
            getgenv().GBO_PendingJoin = nil
            local pCode = pending.code or ""
            local pHub  = pending.hub  or "Regular"
            local pSea  = pending.sea  or "Sea 1"
            -- Sync UI
            getgenv().PSCode      = pCode
            getgenv().SelectedHub = pHub
            getgenv().SelectedSea = pSea
            pcall(function() psBox.Text = pCode end)
            -- Sync hub selection + sea
            if TogglesData["Config_SelectedHub"] and TogglesData["Config_SelectedHub"].Callback then
                TogglesData["Config_SelectedHub"].Callback(pHub)
            end
            if TogglesData["Config_SelectedSea"] and TogglesData["Config_SelectedSea"].Callback then
                TogglesData["Config_SelectedSea"].Callback(pSea)
            end
            -- Auto join
            local _HubArgs = {["Regular"]=true,["Trade Hub"]="tradeHub",["Universe Hub"]="universeHub",["Fish Hub"]="fishHub"}
            local arg = _HubArgs[pHub] or true
            if pHub == "Regular" then
                arg = (pSea == "Sea 2") and 2 or true
            end
            task.wait(1.0)
            ServerModule.Join(pCode, arg)
        end
    end)

    UpdateUIState = function()
        local isReg = (getgenv().SelectedHub=="Regular")
        for _,obj in ipairs({seaDivider, seaMainLbl}) do if obj then obj.Visible=isReg end end
        if TogglesData["Sea1Toggle"] then TogglesData["Sea1Toggle"].Btn.Visible=isReg end
        if TogglesData["Sea2Toggle"] then TogglesData["Sea2Toggle"].Btn.Visible=isReg end
        -- hide sea labels
        local kids = psCard:GetChildren()
        for i,c in ipairs(kids) do
            if c:IsA("TextLabel") and (c.Text=="Sea 1" or c.Text=="Sea 2") then c.Visible=isReg end
        end
    end

    -- ── AUTO REJOIN ───────────────────────────────────────────────────
    local rejoinCard = MakeCard(PrivateServerPage, 82, 2)
    CardHeader(rejoinCard, "lightning", "AUTO REJOIN", CYAN)
    RowLabel(rejoinCard, "Auto Rejoin", "Re-joins after kick / teleport fail", 34)
    CardToggle(rejoinCard, 38, "AutoRejoin", function(state)
        getgenv().AutoRejoin = state
        if state then
            AutoRejoinModule.Start()
        else
            AutoRejoinModule.Stop()
        end
    end)
    RowDivider(rejoinCard, 70)
    NEW("TextLabel",{
        Text="Uses saved PS code + hub. Empty code = public server.",
        Size=UDim2.new(1,-24,0,14), Position=UDim2.new(0,12,0,72),
        BackgroundTransparency=1, TextColor3=TEXT3,
        Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left
    }, rejoinCard)

    -- expose UpdateFn + Callback for ConfigManager
    TogglesData["Config_SelectedHub"] = {
        Value    = "Regular",
        Callback = function(val)
            getgenv().SelectedHub = val or "Regular"
            UpdateHubSelection()
            UpdateUIState()
        end,
        UpdateFn = function()
            UpdateHubSelection()
            UpdateUIState()
        end,
    }

else
    -- ══════════════════════════════════════════════════════════════════
    -- GAME WORLD BUILD — Status, Quick Status, ESP
    -- ══════════════════════════════════════════════════════════════════

    -- Status card
    local statusH = 72
    local statusCard = MakeCard(MainPage, statusH, 1)
    CardHeader(statusCard, "shield", "HUB STATUS", CYAN)
    -- top accent bar with gradient
    local statusTopBar = NEW("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,0,0),BackgroundColor3=CYAN,BorderSizePixel=0,BackgroundTransparency=0.3}, statusCard)

    local statusTxt = NEW("TextLabel",{
        Text="⬡  Connected  ·  GET BETTER OUT",
        Size=UDim2.new(0.65,0,0,18), Position=UDim2.new(0,14,0,34),
        BackgroundTransparency=1, TextColor3=CYAN,
        Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left
    }, statusCard)
    NEW("TextLabel",{
        Text="Zili Hub  ·  v2.5.0  ·  Premium Build",
        Size=UDim2.new(1,-20,0,13), Position=UDim2.new(0,14,0,54),
        BackgroundTransparency=1, TextColor3=TEXT3,
        Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left
    }, statusCard)
    -- Animated LIVE badge
    local pingBadge = NEW("TextLabel",{
        Text="⬤  LIVE", Size=UDim2.new(0,68,0,20), Position=UDim2.new(1,-80,0,36),
        BackgroundColor3=CYAND, TextColor3=CYAN,
        Font=Enum.Font.GothamBold, TextSize=10, TextXAlignment=Enum.TextXAlignment.Center
    }, statusCard)
    CORNER(4, pingBadge); STROKE(CYAN, 1, 0.35, pingBadge)
    task.spawn(function()
        while statusCard and statusCard.Parent do
            TWEEN(pingBadge, 0.8, {TextColor3=C(140,255,248)})
            task.wait(1.0)
            TWEEN(pingBadge, 0.8, {TextColor3=CYAN})
            task.wait(1.0)
        end
    end)

    -- Quick status
    local quickH = 118
    local quickCard = MakeCard(MainPage, quickH, 2)
    CardHeader(quickCard, "lightning", "QUICK STATUS", AMBER)

    local QT_DATA = {
        {"Auto Farm","AutoFarmLevel",10,34},  {"Auto Buso","AutoBuso",120,34},  {"Auto Geppo","AutoGeppo",230,34},
        {"Auto Fish","AutoFishMerchant",10,76},{"Island ESP","ESP_Island",120,76},{"Travel","TravelActive",230,76},
    }
    local quickDots = {}
    for _,qt in ipairs(QT_DATA) do
        local label,key,px,py = qt[1],qt[2],qt[3],qt[4]
        local box = NEW("Frame",{Size=UDim2.new(0,102,0,32),Position=UDim2.new(0,px,0,py),BackgroundColor3=BG5},quickCard)
        CORNER(6,box); STROKE(C(30,28,55),1,0,box)
        NEW("TextLabel",{Text=label,Size=UDim2.new(1,-22,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},box)
        local dot=NEW("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(1,-14,0.5,-4),BackgroundColor3=C(50,48,72),BorderSizePixel=0},box)
        CORNER(4,dot); quickDots[key]=dot
    end
    task.spawn(function()
        while MainFrame and MainFrame.Parent do
            task.wait(0.3)
            for key,dot in pairs(quickDots) do
                if dot and dot.Parent then
                    local on = TogglesData[key] and TogglesData[key].Active
                    TWEEN(dot,0.2,{BackgroundColor3=on and GOLD2 or C(50,48,72)})
                end
            end
        end
    end)

    -- ESP / Visuals
    local espH = 148
    local espCard = MakeCard(MainPage, espH, 3)
    CardHeader(espCard, "eye", "VISUALS & ESP", BLUE_A)
    local ESP_ROWS = {
        {"Island ESP",  32,"ESP_Island",  function(s) if Esp and IslandData then Esp.Toggle(s,IslandData) end end},
        {"Player ESP",  70,"ESP_Player",  function() end},
        {"Item ESP",   108,"ESP_Item",    function() end},
    }
    for _,row in ipairs(ESP_ROWS) do
        local lbl,py,key,cb = row[1],row[2],row[3],row[4]
        RowLabel(espCard,lbl,nil,py)
        if py>32 then RowDivider(espCard,py-2) end
        CardToggle(espCard,py,key,cb)
    end

    -- ── PRIVATE SERVER (Game World) ───────────────────────────────────
    -- Người chơi setup PS code ở đây, save config, auto rejoin khi bị kick
    getgenv().PSCode      = getgenv().PSCode      or ""
    getgenv().SelectedHub = getgenv().SelectedHub or "Regular"
    getgenv().SelectedSea = getgenv().SelectedSea or "Sea 1"

    local GW_HubArgs = {
        ["Regular"]      = true,
        ["Trade Hub"]    = "tradeHub",
        ["Universe Hub"] = "universeHub",
        ["Fish Hub"]     = "fishHub",
    }

    -- Helper scoped to game-world so it doesn't conflict with lobby SetToggleState
    local function GW_SetToggleState(key, state)
        local d = TogglesData[key]
        if not d then return end
        d.Active = state
        TWEEN(d.Btn,  0.22, {BackgroundColor3 = state and GOLDD or BG5})
        TWEEN(d.Strk, 0.22, {Color           = state and GOLD2 or GOLD3})
        if d.Thumb then
            TWEEN(d.Thumb, 0.22, {
                BackgroundColor3 = state and GOLD2 or TEXT3,
                Position         = state and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8),
            })
        end
    end

    local gwPsCardH = 198
    local gwPsCard = MakeCard(MainPage, gwPsCardH, 4)
    CardHeader(gwPsCard, "shield", "SERVER STATUS", PINK)

    -- PUBLIC / PRIVATE status badge (dynamic)
    local serverBadge = NEW("TextLabel",{
        Text= game.PrivateServerId ~= "" and "PRIVATE" or "PUBLIC",
        Size=UDim2.new(0,68,0,18), Position=UDim2.new(1,-80,0,5),
        BackgroundColor3 = game.PrivateServerId ~= "" and C(30,8,50) or PINKD,
        TextColor3 = game.PrivateServerId ~= "" and PURPLE or PINK,
        Font=Enum.Font.GothamBold, TextSize=9, TextXAlignment=Enum.TextXAlignment.Center
    }, gwPsCard)
    CORNER(4, serverBadge)
    STROKE(game.PrivateServerId ~= "" and PURPLE or PINK, 1, 0.4, serverBadge)

    -- PS Code input
    local gwPsBg = NEW("Frame",{
        Size=UDim2.new(1,-24,0,32), Position=UDim2.new(0,12,0,36),
        BackgroundColor3=BG5, BorderSizePixel=0
    }, gwPsCard)
    CORNER(6, gwPsBg); STROKE(GOLD3, 1, 0.5, gwPsBg)
    local gwPsBox = NEW("TextBox",{
        Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1, Text="",
        PlaceholderText="Private Server code (empty = public)...",
        TextColor3=TEXT1, PlaceholderColor3=TEXT3,
        Font=Enum.Font.Gotham, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false,
    }, gwPsBg)
    gwPsBox:GetPropertyChangedSignal("Text"):Connect(function()
        getgenv().PSCode = gwPsBox.Text
        if TogglesData["Config_PSCode"] then
            TogglesData["Config_PSCode"].Value = gwPsBox.Text
        end
    end)

    -- Register Config_PSCode (shared key — same as lobby, config carries across)
    -- If already registered by lobby run (shouldn't happen in game world) skip.
    if not TogglesData["Config_PSCode"] then
        TogglesData["Config_PSCode"] = {
            Value   = "",
            HeadBtn = gwPsBox,
            Callback = function(val)
                getgenv().PSCode = val or ""
                pcall(function() gwPsBox.Text = val or "" end)
            end,
        }
    else
        -- Update HeadBtn to point to game-world box
        TogglesData["Config_PSCode"].HeadBtn = gwPsBox
        TogglesData["Config_PSCode"].Callback = function(val)
            getgenv().PSCode = val or ""
            pcall(function() gwPsBox.Text = val or "" end)
        end
    end

    -- Hub row (compact single-line text)
    RowDivider(gwPsCard, 78)
    RowLabel(gwPsCard, "Destination Hub", "Where to go after joining", 84)

    local gwHubCycle = {"Regular","Trade Hub","Universe Hub","Fish Hub"}
    local gwHubIdx   = 1
    local gwHubBtn   = NEW("TextButton",{
        Size=UDim2.new(0,130,0,22), Position=UDim2.new(1,-142,0,88),
        BackgroundColor3=GOLDD, TextColor3=GOLD2,
        Font=Enum.Font.GothamBold, TextSize=11,
        Text=gwHubCycle[gwHubIdx], AutoButtonColor=false
    }, gwPsCard)
    CORNER(5, gwHubBtn); STROKE(GOLD3,1,0,gwHubBtn)
    gwHubBtn.MouseButton1Click:Connect(function()
        gwHubIdx = (gwHubIdx % #gwHubCycle) + 1
        getgenv().SelectedHub = gwHubCycle[gwHubIdx]
        gwHubBtn.Text = gwHubCycle[gwHubIdx]
        if TogglesData["Config_SelectedHub"] then
            TogglesData["Config_SelectedHub"].Value = getgenv().SelectedHub
        end
    end)

    -- Auto Join toggle
    RowDivider(gwPsCard, 120)
    RowLabel(gwPsCard, "Auto Join", "Trong PS rồi = bỏ qua · Ngoài public = về lobby tự join", 126)
    CardToggle(gwPsCard, 126, "GW_AutoJoinPS", function(state)
        if not state then return end
        -- Kiểm tra đã trong PS chưa
        if game.PrivateServerId ~= "" then
            -- Đã trong PS đúng rồi → tắt toggle, không làm gì
            task.spawn(function() task.wait(0.3); GW_SetToggleState("GW_AutoJoinPS", false) end)
            return
        end
        -- Đang trong public → lưu pending, về lobby để tự join PS
        local code = getgenv().PSCode or ""
        local hub  = getgenv().SelectedHub or "Regular"
        local sea  = getgenv().SelectedSea or "Sea 1"
        getgenv().GBO_PendingJoin = {code=code, hub=hub, sea=sea}
        pcall(function()
            if writefile then
                local hs = game:GetService("HttpService")
                local ok, js = pcall(function()
                    return hs:JSONEncode({code=code,hub=hub,sea=sea})
                end)
                if ok then writefile("gbo_pending_join.json", js) end
            end
        end)
        task.spawn(function()
            task.wait(1.2)
            GW_SetToggleState("GW_AutoJoinPS", false)
            pcall(function() TeleportService_L:Teleport(PLACE_LOBBY, Player_L) end)
        end)
    end)

    -- Auto Rejoin toggle
    RowDivider(gwPsCard, 158)
    RowLabel(gwPsCard, "Auto Rejoin", "Re-joins after kick / teleport fail", 164)
    CardToggle(gwPsCard, 164, "GW_AutoRejoin", function(state)
        getgenv().AutoRejoin = state
        if state then
            AutoRejoinModule.Start()
        else
            AutoRejoinModule.Stop()
        end
    end)

end  -- end IS_LOBBY/else

-- =====================================================================
-- ██████  AUTO FARM PAGE  (game world only)
-- =====================================================================
if not IS_LOBBY then
PageLayout(AutoFarmPage, 14, 10)

-- Level Farm card
local lfH = 144
local lfCard = MakeCard(AutoFarmPage, lfH, 1)
CardHeader(lfCard, "sword", "LEVEL FARM", AMBER)
RowLabel(lfCard, "Start Level Farm", "Auto kills enemies · respawns", 34)

local StartFarmToggle, SFToggleStroke, SFThumb = CardToggle(lfCard, 44, "AutoFarmLevel", function(state)
    AutoFarmLevel.Toggle(state)
    if state then warn("Auto Farming Level On ..") else warn("Auto Farming Level Off ..") end
end)

RowDivider(lfCard, 80)
RowLabel(lfCard, "Auto Farm Level for Fishing", "< 375 → Farm  ·  ≥ 375 → Fish", 84)

-- Helper: đọc level hiện tại của player
local function GetPlayerLevel()
    local level = 0
    pcall(function()
        local statsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Stats" .. LocalPlayer.Name)
        local statsNode   = statsFolder and statsFolder:FindFirstChild("Stats")
        local levelNode   = statsNode   and statsNode:FindFirstChild("Level")
        if levelNode then level = levelNode.Value end
    end)
    return level
end

-- Helper: bật/tắt toggle theo state (không trigger click, set trực tiếp)
local function SetToggle(key, state)
    local d = TogglesData[key]
    if not d or d.Active == state then return end
    d.Active = state
    local on = state
    TWEEN(d.Btn,  0.22, {BackgroundColor3 = on and GOLDD or BG5})
    TWEEN(d.Strk, 0.22, {Color           = on and GOLD2 or GOLD3})
    local thumbFrame = d.Btn:FindFirstChildOfClass("Frame")
    if thumbFrame then
        TWEEN(thumbFrame, 0.22, {
            BackgroundColor3 = on and GOLD2 or TEXT3,
            Position         = on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)
        })
    end
    -- FishMasterBar animation for AutoFishMerchant
    if key == "AutoFishMerchant" and FishMasterBar then
        TWEEN(FishMasterBar, 0.35, {BackgroundColor3 = on and GREEN or GOLD})
    end
    if d.Callback then d.Callback(state) end
end

local _, AFFStroke, AFFThumb = CardToggle(lfCard, 96, "AutoFarmForFishing", function(state)
    if not state then
        -- Khi tắt: dừng cả 2
        SetToggle("AutoFarmLevel",    false)
        SetToggle("AutoFishMerchant", false)
    else
        -- Khi bật: check level ngay lập tức, không chờ 3s
        task.spawn(function()
            local level = GetPlayerLevel()
            if level < 375 then
                SetToggle("AutoFarmLevel",    true)
                SetToggle("AutoFishMerchant", false)
            else
                SetToggle("AutoFarmLevel",    false)
                SetToggle("AutoFishMerchant", true)
            end
        end)
    end
end)

-- Background loop: kiểm tra level mỗi 3s khi AFF đang bật
task.spawn(function()
    while MainFrame and MainFrame.Parent do
        task.wait(3)
        if not TogglesData["AutoFarmForFishing"] or not TogglesData["AutoFarmForFishing"].Active then
            continue
        end
        local level = GetPlayerLevel()
        if level < 375 then
            SetToggle("AutoFarmLevel",     true)
            SetToggle("AutoFishMerchant",  false)
        else
            SetToggle("AutoFarmLevel",     false)
            SetToggle("AutoFishMerchant",  true)
        end
    end
end)

-- Misc Farm card
local mfH = 148
local mfCard = MakeCard(AutoFarmPage, mfH, 2)
CardHeader(mfCard, "fist", "MISC FARM", GOLD2)

-- Gamepass badge
local gpBadge = NEW("TextLabel",{
    Text="GAMEPASS", Size=UDim2.new(0,72,0,16), Position=UDim2.new(1,-84,0,7),
    BackgroundColor3=GOLDD, TextColor3=GOLD2,
    Font=Enum.Font.GothamBold, TextSize=8, TextXAlignment=Enum.TextXAlignment.Center
}, mfCard)
CORNER(4, gpBadge)
STROKE(GOLD3, 1, 0, gpBadge)

local MISC_ROWS = {
    {"Auto Get Buso",  "REQ → LVL 80  ·  25,000 PELI",  36, "AutoBuso",  function(s) if AutoGetBuso then AutoGetBuso.Toggle(s) end end},
    {"Auto Get Geppo", "REQ → LVL 125  ·  50,000 PELI", 96, "AutoGeppo", nil},
}
for i,row in ipairs(MISC_ROWS) do
    local label,req,py,key,baseCb = row[1],row[2],row[3],row[4],row[5]
    RowLabel(mfCard, label, req, py)
    if i > 1 then RowDivider(mfCard, py-2) end
    local btn,strk,thumb = CardToggle(mfCard, py+8, key, baseCb)
    -- Geppo auto-off logic
    if key=="AutoGeppo" then
        TogglesData[key].Callback = function(state)
            if AutoGeppoFunc then AutoGeppoFunc.Toggle(state) end
            if state then
                task.spawn(function()
                    while _G.AutoGeppo do task.wait(0.5) end
                    if TogglesData[key].Active then
                        TogglesData[key].Active=false
                        TWEEN(btn,0.2,{BackgroundColor3=BG5}); TWEEN(strk,0.2,{Color=GOLD3})
                        TWEEN(thumb,0.2,{BackgroundColor3=TEXT3,Position=UDim2.new(0,4,0.5,-8)})
                    end
                end)
            end
        end
    end
end

-- =====================================================================
-- ██████  TRAVEL PAGE
-- =====================================================================
PageLayout(TravelPage, 14, 10)

-- Island Teleport card (no Force Stop - use toggle to stop)
local tpH = 148
local tpCard = MakeCard(TravelPage, tpH, 1)
tpCard.ZIndex = 5
CardHeader(tpCard, "globe", "ISLAND TELEPORT", CYAN)

-- Target Island label
RowLabel(tpCard, "Target Island", "Select destination", 36)
-- Search box
local SearchBox = NEW("TextBox",{
    Size=UDim2.new(0,172,0,30), Position=UDim2.new(1,-186,0,42),
    BackgroundColor3=BG5, Text="", PlaceholderText="Search Island...",
    TextColor3=GOLD2, Font=Enum.Font.GothamSemibold, TextSize=12,
    ClearTextOnFocus=true, ZIndex=6
}, tpCard)
CORNER(7, SearchBox)
local BoxStroke = STROKE(GOLD3, 1, 0, SearchBox)
SearchBox.Focused:Connect(function() TWEEN(BoxStroke,0.2,{Color=GOLD2}) end)
SearchBox.FocusLost:Connect(function() TWEEN(BoxStroke,0.2,{Color=GOLD3}) end)

-- Dropdown — parented to ScreenGui so it overlays everything
local DropdownScroll = NEW("ScrollingFrame",{
    Size=UDim2.new(0,172,0,150), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=BG0, BorderSizePixel=0,
    ScrollBarThickness=2, Visible=false, ZIndex=200,
    ScrollBarImageColor3=GOLD,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0)
}, ScreenGui)
CORNER(7, DropdownScroll)
STROKE(GOLD3, 1, 0, DropdownScroll)
local DropLayout = NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2)}, DropdownScroll)
NEW("UIPadding",{PaddingTop=UDim.new(0,4)}, DropdownScroll)

local Islands={}
if IslandData then for n,_ in pairs(IslandData) do table.insert(Islands,n) end; table.sort(Islands) end
local IslandButtons={}
for _,islandName in ipairs(Islands) do
    local btn=NEW("TextButton",{
        Size=UDim2.new(1,-8,0,26), BackgroundTransparency=1, ZIndex=201,
        Text="  "..islandName, TextColor3=TEXT2,
        Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left
    }, DropdownScroll)
    CORNER(4, btn)
    btn.MouseEnter:Connect(function() TWEEN(btn,0.12,{BackgroundTransparency=0.85,BackgroundColor3=BG4,TextColor3=GOLD2}); btn.Font=Enum.Font.GothamBold end)
    btn.MouseLeave:Connect(function() TWEEN(btn,0.12,{BackgroundTransparency=1,TextColor3=TEXT2}); btn.Font=Enum.Font.Gotham end)
    btn.MouseButton1Click:Connect(function() SearchBox.Text=string.gsub(btn.Text,"^%s*(.-)%s*$","%1"); DropdownScroll.Visible=false end)
    table.insert(IslandButtons, btn)
end

SearchBox.Focused:Connect(function()
    -- Position below SearchBox using AbsolutePosition
    local ap = SearchBox.AbsolutePosition
    local as = SearchBox.AbsoluteSize
    DropdownScroll.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
    DropdownScroll.Size = UDim2.new(0, as.X, 0, 150)
    DropdownScroll.Visible = true
end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local s=string.lower(SearchBox.Text); local cs=string.gsub(s,"'","")
    for _,b in ipairs(IslandButtons) do
        local n=string.lower(string.gsub(b.Text,"^%s*(.-)%s*$","%1")); local cn=string.gsub(n,"'","")
        b.Visible = s=="" or string.find(cn,cs,1,true) and true or false
    end
end)
local Mouse=LocalPlayer:GetMouse()
UIS.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        local mx,my=Mouse.X,Mouse.Y
        local dp,ds=DropdownScroll.AbsolutePosition,DropdownScroll.AbsoluteSize
        local bp,bs=SearchBox.AbsolutePosition,SearchBox.AbsoluteSize
        local inD=mx>=dp.X and mx<=dp.X+ds.X and my>=dp.Y and my<=dp.Y+ds.Y
        local inB=mx>=bp.X and mx<=bp.X+bs.X and my>=bp.Y and my<=bp.Y+bs.Y
        if not inD and not inB then DropdownScroll.Visible=false end
    end
end)

-- Start Travel row
RowDivider(tpCard, 104)
RowLabel(tpCard, "Start Travel", "Navigate automatically", 110)
local ToggleBtn = NEW("TextButton",{
    Size=UDim2.new(0,44,0,24), Position=UDim2.new(1,-58,0,112),
    BackgroundColor3=BG5, Text="", AutoButtonColor=false
}, tpCard)
CORNER(20, ToggleBtn)
local ToggleStroke = STROKE(GOLD3, 1, 0, ToggleBtn)
local TravelThumb = NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,4,0.5,-8),BackgroundColor3=TEXT3,BorderSizePixel=0}, ToggleBtn)
CORNER(20, TravelThumb)
ToggleBtn.MouseButton1Click:Connect(function()
    if not TweenSys then return end
    if TweenSys.IsTeleporting then
        TweenSys.Stop()
        TWEEN(ToggleBtn,0.2,{BackgroundColor3=BG5}); TWEEN(ToggleStroke,0.2,{Color=GOLD3})
        TWEEN(TravelThumb,0.2,{BackgroundColor3=TEXT3,Position=UDim2.new(0,4,0.5,-8)})
    else
        local td=IslandData and IslandData[SearchBox.Text]; if not td then return end
        TweenSys.Start(td)
        TWEEN(ToggleBtn,0.2,{BackgroundColor3=GOLDD}); TWEEN(ToggleStroke,0.2,{Color=GOLD2})
        TWEEN(TravelThumb,0.2,{BackgroundColor3=GOLD2,Position=UDim2.new(1,-20,0.5,-8)})
    end
end)

-- Auto 2nd Sea card
local sea2Card = MakeCard(TravelPage, 90, 2)
CardHeader(sea2Card, "wave", "AUTO 2ND SEA", BLUE_A)

RowLabel(sea2Card, "Auto Enter 2nd Sea", "Auto travel to 2nd sea portal", 32)
CardToggle(sea2Card, 40, "Auto2ndSea", function(state)
    _G.Auto2ndSea = state
end)
RowDivider(sea2Card, 72)
-- info label
NEW("TextLabel",{
    Text="Requires Level 700+  ·  Finish all quests",
    Size=UDim2.new(1,-24,0,14), Position=UDim2.new(0,14,0,76),
    BackgroundTransparency=1, TextColor3=GOLD3,
    Font=Enum.Font.GothamBold, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left
}, sea2Card)

-- Dummy ESP references for compat
local EspSectionFrame=NEW("Frame",{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1,Visible=false},TravelPage)
local EspToggleBtn=NEW("TextButton",{Text=""},EspSectionFrame)
local EspToggleStroke=NEW("UIStroke",{},EspToggleBtn)
local EspThumb=NEW("Frame",{},EspToggleBtn)
EspToggleBtn.MouseButton1Click:Connect(function() end)

-- =====================================================================
-- ██████  FISHING + MERCHANT PAGE
-- =====================================================================
PageLayout(FishingPage, 14, 10)

-- Master toggle card - taller for better text
local fmH = 80
local fmCard = MakeCard(FishingPage, fmH, 1)
CardHeader(fmCard, "fish", "FISHING + MERCHANT FARM", ORANGE)

local FishMasterBar = NEW("Frame",{
    Size=UDim2.new(0,3,1,0), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=GOLD, BorderSizePixel=0
}, fmCard)
CORNER(2, FishMasterBar)

-- main label
NEW("TextLabel",{
    Text="Enable Auto Fishing + Merchant",
    Size=UDim2.new(0.75,0,0,20), Position=UDim2.new(0,14,0,32),
    BackgroundTransparency=1, TextColor3=TEXT1,
    Font=Enum.Font.GothamSemibold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left
}, fmCard)
-- sub label
NEW("TextLabel",{
    Text="Auto catch  ·  sell  ·  restock bait in loop",
    Size=UDim2.new(0.75,0,0,14), Position=UDim2.new(0,14,0,52),
    BackgroundTransparency=1, TextColor3=TEXT2,
    Font=Enum.Font.Gotham, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left
}, fmCard)

local StartFishToggle = NEW("TextButton",{
    Size=UDim2.new(0,44,0,24), Position=UDim2.new(1,-56,0,40),
    BackgroundColor3=BG5, Text="", AutoButtonColor=false
}, fmCard)
CORNER(20, StartFishToggle)
local FishToggleStroke = STROKE(GOLD3, 1, 0, StartFishToggle)
local FishThumb = NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,4,0.5,-8),BackgroundColor3=TEXT3,BorderSizePixel=0}, StartFishToggle)
CORNER(20, FishThumb)

TogglesData["AutoFishMerchant"] = {
    Active    = false,
    Btn       = StartFishToggle,
    Strk      = FishToggleStroke,
    Thumb     = FishThumb,
    MasterBar = FishMasterBar,
    Callback  = function(state)
        _G.AutoFishMerchant = state
        if state then
            AutoFishMerchantModule.Start(TogglesData)
        else
            AutoFishMerchantModule.Stop()
        end
    end,
}
StartFishToggle.MouseButton1Click:Connect(function()
    local d=TogglesData["AutoFishMerchant"]; d.Active=not d.Active; local on=d.Active
    TWEEN(StartFishToggle,0.22,{BackgroundColor3=on and GOLDD or BG5})
    TWEEN(FishToggleStroke,0.22,{Color=on and GOLD2 or GOLD3})
    TWEEN(FishThumb,0.22,{BackgroundColor3=on and GOLD2 or TEXT3, Position=on and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8)})
    TWEEN(FishMasterBar,0.35,{BackgroundColor3=on and GREEN or GOLD})
    if d.Callback then d.Callback(on) end
end)

-- Live stats row - 4 columns with drawn icons (chest/arrows/coin/bottle)
local fsH = 98
local fsCard = MakeCard(FishingPage, fsH, 2)
fsCard.BackgroundColor3 = C(8, 9, 18)
-- Override the stroke color from MakeCard
local fsStroke = fsCard:FindFirstChildOfClass("UIStroke")
if fsStroke then fsStroke.Color = C(30,28,52); fsStroke.Transparency = 0.3 end

-- Header strip
local fsHeader = NEW("Frame",{
    Size=UDim2.new(1,0,0,24), BackgroundColor3=BG_HDR
}, fsCard)
CORNER(8, fsHeader)
NEW("Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BackgroundColor3=BG_HDR,BorderSizePixel=0},fsHeader)
-- header left accent bar
local fsAccBar = NEW("Frame",{Size=UDim2.new(0,2,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=ORANGE,BorderSizePixel=0},fsHeader)
CORNER(1,fsAccBar)
-- header icon
local fsIconBg = NEW("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,7,0,4),BackgroundColor3=C(28,14,4)},fsHeader)
CORNER(4,fsIconBg)
DrawIcon(fsIconBg,"chart",2,2,12,ORANGE)
NEW("TextLabel",{
    Text="LIVE STATS",
    Size=UDim2.new(0,120,1,0),Position=UDim2.new(0,30,0,0),
    BackgroundTransparency=1,TextColor3=ORANGE,Font=Enum.Font.GothamBold,
    TextSize=9,TextXAlignment=Enum.TextXAlignment.Left
},fsHeader)
-- header bottom line
local fsHdrLine = NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=ORANGE,BorderSizePixel=0,BackgroundTransparency=0.7},fsHeader)

-- ── MINI toggle on the right of header ──
local compactActive = false
local CompactWidget  -- forward ref

-- "MINI" label
NEW("TextLabel",{
    Text="MINI",
    Size=UDim2.new(0,26,1,0),Position=UDim2.new(1,-72,0,0),
    BackgroundTransparency=1,TextColor3=TEXT3,Font=Enum.Font.GothamBold,
    TextSize=8,TextXAlignment=Enum.TextXAlignment.Right
},fsHeader)

local compactPill = NEW("TextButton",{
    Size=UDim2.new(0,40,0,16), Position=UDim2.new(1,-46,0,4),
    BackgroundColor3=BG5, Text="", AutoButtonColor=false
},fsHeader)
CORNER(20,compactPill)
local compactStrk = STROKE(GOLD3,1,0,compactPill)
local compactThumb = NEW("Frame",{
    Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,2,0.5,-6),
    BackgroundColor3=TEXT3,BorderSizePixel=0
},compactPill)
CORNER(20,compactThumb)

-- ── 4 stat cells with DRAWN icons ──
-- Layout: 4 equal columns in 438px wide card → each cell ~109px wide
-- Icons: chest(MythicChest) | arrows(LegBait) | coin(Peli) | bottle(Bait)
local FISH_STAT_DEF = {
    -- { iconName, label, initVal, xOffset, key, color }
    { "chest",  "MYTHIC",   "—",   0,   "MythicChest", AMBER  },
    { "arrows", "LEG.BAIT", "—",   0,   "LegBait",     PURPLE },
    { "coin",   "PELI",     "0",   0,   "Peli",        CYAN   },
    { "bottle", "BAIT",     "—",   0,   "Bait",        ORANGE },
}
local FishStatValues = {}

-- use UDim2 scale for 4 equal columns
for i, def in ipairs(FISH_STAT_DEF) do
    local iconName,lbl,val,_,key,accentC = def[1],def[2],def[3],def[4],def[5],def[6]
    local xScale = (i-1) * 0.25

    -- Vertical divider between cells
    if i > 1 then
        NEW("Frame",{
            Size=UDim2.new(0,1,0.5,0),
            Position=UDim2.new(xScale, 0, 0.28, 0),
            BackgroundColor3=C(28,26,48),BorderSizePixel=0
        }, fsCard)
    end

    local cellW = 0.25

    -- Icon background (small square, colored tint)
    local iconCell = NEW("Frame",{
        Size=UDim2.new(0,28,0,28),
        Position=UDim2.new(xScale + cellW/2, -14, 0, 26),
        BackgroundColor3=C(
            math.min(255,math.floor(accentC.R*255*0.12+8)),
            math.min(255,math.floor(accentC.G*255*0.12+8)),
            math.min(255,math.floor(accentC.B*255*0.12+8))
        ),
        BorderSizePixel=0
    }, fsCard)
    CORNER(6, iconCell)
    STROKE(accentC, 1, 0.6, iconCell)
    DrawIcon(iconCell, iconName, 4, 4, 20, accentC)

    -- Value number
    local valLbl = NEW("TextLabel",{
        Text=val,
        Size=UDim2.new(cellW,-4,0,18),
        Position=UDim2.new(xScale,2, 0, 57),
        BackgroundTransparency=1, TextColor3=GOLD2,
        Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Center
    }, fsCard)

    -- Label under value
    NEW("TextLabel",{
        Text=lbl,
        Size=UDim2.new(cellW,-4,0,12),
        Position=UDim2.new(xScale,2, 0, 78),
        BackgroundTransparency=1, TextColor3=accentC,
        Font=Enum.Font.GothamBold, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Center
    }, fsCard)

    FishStatValues[key] = valLbl
end

-- ══════════════════════════════════════════════════════════════════════
-- Compact floating widget (matches image 4 style: 160×165, drawn icons,
-- session timer at bottom, L-bracket corners)
-- ══════════════════════════════════════════════════════════════════════
CompactWidget = NEW("ScreenGui",{
    Name="GBO_CompactStats", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Enabled=false
}, gethui and gethui() or game.CoreGui)

local CW_W, CW_H = 162, 168
local cwFrame = NEW("Frame",{
    Size=UDim2.new(0,CW_W,0,CW_H),
    Position=UDim2.new(1,-CW_W-14,0.5,-CW_H/2),
    BackgroundColor3=C(8,9,18), BorderSizePixel=0
},CompactWidget)
CORNER(10,cwFrame)
STROKE(GOLD,1.5,0.12,cwFrame)

-- Animated shimmer
local cwShimmer = NEW("Frame",{
    Size=UDim2.new(0,2,1.6,0),Position=UDim2.new(-0.1,0,-0.3,0),
    BackgroundColor3=GOLD2,BackgroundTransparency=0.93,ZIndex=0,
    BorderSizePixel=0,Rotation=16
},cwFrame)

-- Top bar
local cwTopBar = NEW("Frame",{
    Size=UDim2.new(1,0,0,24), BackgroundColor3=C(10,11,22), BorderSizePixel=0
},cwFrame)
CORNER(10,cwTopBar)
NEW("Frame",{
    Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),
    BackgroundColor3=C(10,11,22),BorderSizePixel=0
},cwTopBar)
-- top bar accent left bar (orange = fishing)
local cwAccBar = NEW("Frame",{Size=UDim2.new(0,2,0.5,0),Position=UDim2.new(0,0,0.25,0),BackgroundColor3=ORANGE,BorderSizePixel=0},cwTopBar)
CORNER(1,cwAccBar)
-- top bar title
NEW("TextLabel",{
    Text="FILLING...",
    Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,TextColor3=ORANGE,Font=Enum.Font.GothamBold,
    TextSize=8,TextXAlignment=Enum.TextXAlignment.Left
},cwTopBar)
-- top bar border bottom
local cwHdrLine = NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=ORANGE,BorderSizePixel=0,BackgroundTransparency=0.65},cwTopBar)

-- Close button
local cwClose = NEW("TextButton",{
    Size=UDim2.new(0,18,0,18),Position=UDim2.new(1,-22,0.5,-9),
    BackgroundColor3=C(35,12,12),Text="✕",TextColor3=RED,
    Font=Enum.Font.GothamBold,TextSize=8,AutoButtonColor=false
},cwTopBar)
CORNER(4,cwClose)
STROKE(RED,1,0.5,cwClose)

-- ── L-bracket corners on compact widget ──
local function CWBracket(ax,ay,fx,fy)
    local bL=10; local bT=1.5
    local bg=NEW("Frame",{
        Size=UDim2.new(0,bL+bT,0,bL+bT),
        AnchorPoint=Vector2.new(ax,ay),
        Position=UDim2.new(ax,ax==0 and 2 or -2,ay,ay==0 and 2 or -2),
        BackgroundTransparency=1,BorderSizePixel=0,ZIndex=10
    },cwFrame)
    NEW("Frame",{
        Size=UDim2.new(0,bL,0,bT),
        Position=UDim2.new(0,0,0,fy and bL or 0),
        BackgroundColor3=CYAN,BackgroundTransparency=0.2,BorderSizePixel=0,ZIndex=11
    },bg)
    NEW("Frame",{
        Size=UDim2.new(0,bT,0,bL),
        Position=UDim2.new(0,fx and bL or 0,0,fy and bT or 0),
        BackgroundColor3=CYAN,BackgroundTransparency=0.2,BorderSizePixel=0,ZIndex=11
    },bg)
end
CWBracket(0,0,false,false)
CWBracket(1,0,true, false)
CWBracket(0,1,false,true)
CWBracket(1,1,true, true)

-- ── 2×2 stat grid ──
local CW_ITEMS = {
    { "chest",  "MYTHIC",   "MythicChest", 0,   24,  AMBER  },
    { "bottle", "BAIT",     "Bait",        0.5, 24,  ORANGE },
    { "coin",   "PELI",     "Peli",        0,   94,  CYAN   },
    { "arrows", "LEG",      "LegBait",     0.5, 94,  PURPLE },
}
local cwValues = {}
local CW_CELL_W = CW_W/2 - 2
local CW_CELL_H = 66

for _,item in ipairs(CW_ITEMS) do
    local iconN,lbl,key,xs,yo,aCol = item[1],item[2],item[3],item[4],item[5],item[6]
    local xOff = xs==0 and 2 or 1
    local cell = NEW("Frame",{
        Size=UDim2.new(0,CW_CELL_W,0,CW_CELL_H-2),
        Position=UDim2.new(0, xs==0 and 2 or CW_W/2+1, 0, yo),
        BackgroundColor3=C(
            math.min(255,math.floor(aCol.R*255*0.10+9)),
            math.min(255,math.floor(aCol.G*255*0.10+9)),
            math.min(255,math.floor(aCol.B*255*0.10+9))
        ),BorderSizePixel=0
    },cwFrame)
    CORNER(7,cell)
    STROKE(aCol,1,0.55,cell)

    -- Icon (drawn, centered top of cell)
    local iSz=22
    local iconHolder = NEW("Frame",{
        Size=UDim2.new(0,iSz,0,iSz),
        Position=UDim2.new(0.5,-iSz/2,0,5),
        BackgroundTransparency=1,BorderSizePixel=0
    },cell)
    DrawIcon(iconHolder,iconN,0,0,iSz,aCol)

    -- Value
    local vl = NEW("TextLabel",{
        Text="—",
        Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,29),
        BackgroundTransparency=1,TextColor3=GOLD2,
        Font=Enum.Font.GothamBold,TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Center
    },cell)

    -- Label
    NEW("TextLabel",{
        Text=lbl,
        Size=UDim2.new(1,0,0,11),Position=UDim2.new(0,0,1,-12),
        BackgroundTransparency=1,TextColor3=aCol,
        Font=Enum.Font.GothamBold,TextSize=7,
        TextXAlignment=Enum.TextXAlignment.Center
    },cell)

    cwValues[key] = vl
end

-- ── Session timer bar at bottom ──
local timerBar = NEW("Frame",{
    Size=UDim2.new(1,0,0,22),
    Position=UDim2.new(0,0,1,-22),
    BackgroundColor3=C(9,10,20),BorderSizePixel=0
},cwFrame)
CORNER(10,timerBar)
NEW("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,0,0),BackgroundColor3=C(9,10,20),BorderSizePixel=0},timerBar)
-- timer top line
NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,0),BackgroundColor3=GOLD3,BorderSizePixel=0,BackgroundTransparency=0.6},timerBar)

local timerLabel = NEW("TextLabel",{
    Text="0H  0M  0S",
    Size=UDim2.new(0.65,0,1,0),Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,TextColor3=TEXT2,
    Font=Enum.Font.GothamBold,TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left
},timerBar)
NEW("TextLabel",{
    Text="ZILI HUB",
    Size=UDim2.new(0.35,0,1,0),Position=UDim2.new(0.65,0,0,0),
    BackgroundTransparency=1,TextColor3=GOLD3,
    Font=Enum.Font.GothamBold,TextSize=8,
    TextXAlignment=Enum.TextXAlignment.Right
},timerBar)
-- Pad right
NEW("UIPadding",{PaddingRight=UDim.new(0,6)},timerBar)

-- Session timer logic
local sessionStartTime = os.time()
task.spawn(function()
    while CompactWidget and CompactWidget.Parent do
        task.wait(1)
        if compactActive and timerLabel and timerLabel.Parent then
            local elapsed = os.time() - sessionStartTime
            local h = math.floor(elapsed / 3600)
            local m = math.floor((elapsed % 3600) / 60)
            local s = elapsed % 60
            pcall(function()
                timerLabel.Text = string.format("%dH  %02dM  %02dS", h, m, s)
            end)
        end
    end
end)

-- CW: drag
local cwDrag,cwDragSt,cwDragPos=false,nil,nil
cwTopBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        cwDrag=true; cwDragSt=i.Position; cwDragPos=cwFrame.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if cwDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-cwDragSt
        cwFrame.Position=UDim2.new(cwDragPos.X.Scale,cwDragPos.X.Offset+d.X,cwDragPos.Y.Scale,cwDragPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then cwDrag=false end
end)

-- CW shimmer loop
task.spawn(function()
    while CompactWidget and CompactWidget.Parent do
        if compactActive then
            cwShimmer.Position = UDim2.new(-0.1,0,-0.3,0)
            TweenService:Create(cwShimmer,TweenInfo.new(3.0,Enum.EasingStyle.Quad),{
                Position=UDim2.new(1.1,0,-0.3,0)
            }):Play()
        end
        task.wait(6.0)
    end
end)

-- Compact toggle logic
local function SetCompactMode(on)
    compactActive = on
    TWEEN(compactPill,0.2,{BackgroundColor3=on and GOLDD or BG5})
    TWEEN(compactStrk,0.2,{Color=on and GOLD2 or GOLD3})
    TWEEN(compactThumb,0.2,{BackgroundColor3=on and GOLD2 or TEXT3, Position=on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)})
    if on then
        -- Sync values ngay khi bật
        for k,vl in pairs(cwValues) do
            local main = FishStatValues[k]
            if main then vl.Text = main.Text end
        end
        MainFrame.Visible = false
        MiniLogo.Visible  = false
        CompactWidget.Enabled = true
    else
        CompactWidget.Enabled = false
        MainFrame.Visible = true
    end
end

compactPill.MouseButton1Click:Connect(function() SetCompactMode(not compactActive) end)
cwClose.MouseButton1Click:Connect(function() SetCompactMode(false) end)

-- Live stat update — 2s interval, tự dừng khi card bị destroy
task.spawn(function()
    while fsCard and fsCard.Parent do
        task.wait(2)
        pcall(function()
            local statFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Stats" .. LocalPlayer.Name)
            if not statFolder then return end

            -- Decode inventory JSON một lần duy nhất mỗi tick
            local inv = {}
            local invNode = statFolder:FindFirstChild("Inventory")
            invNode = invNode and invNode:FindFirstChild("Inventory")
            if invNode then
                local ok, decoded = pcall(function() return HttpService:JSONDecode(invNode.Value) end)
                if ok and type(decoded)=="table" then inv = decoded end
            end

            -- Peli
            local peliVal = "0"
            local statsNode = statFolder:FindFirstChild("Stats")
            local peliNode  = statsNode and statsNode:FindFirstChild("Peli")
            if peliNode then peliVal = tostring(peliNode.Value) end

            local bait = _G.TargetBait or "Common Fish Bait"

            local updates = {
                MythicChest = tostring(inv["Mythical Fruit Chest"] or 0),
                LegBait     = tostring(inv["Legendary Fish Bait"] or 0),
                Peli        = peliVal,
                Bait        = tostring(inv[bait] or 0),
            }

            for key, val in pairs(updates) do
                if FishStatValues[key] then FishStatValues[key].Text = val end
                if cwValues[key] then cwValues[key].Text = val end
            end
        end)
    end
    -- Card bị destroy → dọn compact widget luôn
    if CompactWidget then CompactWidget:Destroy() end
end)

-- Config card
local fcH = 428
local ConfigFishFrame = MakeCard(FishingPage, fcH, 3)
CardHeader(ConfigFishFrame, "gear", "CONFIGURATION", GOLD)

-- Dropdown factory (unchanged logic)
local function CreateDropdown(parent, titleText, options, defaultSelect, posY, configKey, isMulti, showSearch)
    local lbl=NEW("TextLabel",{
        Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,posY),
        BackgroundTransparency=1,Text=titleText,TextColor3=TEXT1,
        Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left
    },parent)

    local headBtn=NEW("TextButton",{
        Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,posY-2),
        BackgroundColor3=BG5,TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=11,
        Text=isMulti and "Select..." or (defaultSelect or "Select..."),AutoButtonColor=false
    },parent)
    CORNER(5,headBtn)
    local headStroke=STROKE(GOLD3,1,0,headBtn)

    -- dropScroll parented to ScreenGui so it's NEVER clipped by cards
    local dropScroll=NEW("ScrollingFrame",{
        Size=UDim2.new(0,158,0,0),   -- height set dynamically
        Position=UDim2.new(0,0,0,0), -- position set when opened
        BackgroundColor3=BG0,BorderSizePixel=0,ScrollBarThickness=2,
        Visible=false,ZIndex=200,ScrollBarImageColor3=GOLD,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)
    },ScreenGui)
    CORNER(5,dropScroll)
    STROKE(GOLD3,1,0,dropScroll)
    NEW("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,2)},dropScroll)
    NEW("UIPadding",{PaddingTop=UDim.new(0,3)},dropScroll)

    local searchInput
    if showSearch then
        searchInput=NEW("TextBox",{
            Size=UDim2.new(1,-6,0,22),BackgroundTransparency=1,
            Text="",PlaceholderText="Search...",TextColor3=TEXT1,
            Font=Enum.Font.Gotham,TextSize=11,PlaceholderColor3=TEXT3,ZIndex=201
        },dropScroll)
    end

    -- Init value — Callback restores headBtn text + checkmarks when config is loaded
    local initVal = isMulti and {} or nil
    local function defaultCallback(val)
        if isMulti then
            -- restore tick marks on each option button
            local ct = 0
            for _, b in ipairs(dropScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    local selected = type(val)=="table" and val[b.Name]==true
                    if selected then
                        TWEEN(b,0.1,{TextColor3=GOLD2}); b.Font=Enum.Font.GothamBold
                        if not b:FindFirstChild("TickMark") then
                            NEW("TextLabel",{Name="TickMark",Text="✓",TextColor3=GOLD2,
                                TextXAlignment=Enum.TextXAlignment.Right,
                                Size=UDim2.new(1,-5,1,0),BackgroundTransparency=1,
                                Font=Enum.Font.GothamBold,TextSize=12,ZIndex=202},b)
                        end
                        ct = ct + 1
                    else
                        TWEEN(b,0.1,{TextColor3=TEXT2}); b.Font=Enum.Font.Gotham
                        if b:FindFirstChild("TickMark") then b.TickMark:Destroy() end
                    end
                end
            end
            headBtn.Text = ct > 0 and (ct .. " Selected") or "Select..."
        else
            -- single select: highlight chosen option
            for _, b in ipairs(dropScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    local selected = b.Name == tostring(val)
                    TWEEN(b,0.1,{TextColor3=selected and GOLD2 or TEXT2})
                    b.Font = selected and Enum.Font.GothamBold or Enum.Font.Gotham
                end
            end
            headBtn.Text = (val ~= nil and tostring(val) ~= "") and tostring(val) or "Select..."
        end
    end
    TogglesData[configKey] = {Value=initVal, Callback=defaultCallback, HeadBtn=headBtn}
    if not isMulti and (defaultSelect == nil or defaultSelect == "") then
        headBtn.Text = "Select..."
    elseif not isMulti and defaultSelect then
        -- set initial value if there's a default
        TogglesData[configKey].Value = defaultSelect
    end

    local function openDrop()
        -- Calculate absolute position of headBtn to place dropScroll just below it
        local absPos  = headBtn.AbsolutePosition
        local absSize = headBtn.AbsoluteSize
        local maxH    = 150 -- max visible height of list
        dropScroll.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
        dropScroll.Size     = UDim2.new(0, absSize.X, 0, maxH)
        dropScroll.Visible  = true
        TWEEN(headStroke,0.15,{Color=GOLD2})
        if showSearch and searchInput then searchInput:CaptureFocus() end
    end

    local function closeDrop()
        dropScroll.Visible = false
        TWEEN(headStroke,0.15,{Color=GOLD3})
    end

    headBtn.MouseButton1Click:Connect(function()
        if dropScroll.Visible then closeDrop() else openDrop() end
    end)

    -- Close when clicking outside
    UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and dropScroll.Visible then
            local mx, my = inp.Position.X, inp.Position.Y
            local dp, ds = dropScroll.AbsolutePosition, dropScroll.AbsoluteSize
            local bp, bs = headBtn.AbsolutePosition, headBtn.AbsoluteSize
            local inDrop = mx>=dp.X and mx<=dp.X+ds.X and my>=dp.Y and my<=dp.Y+ds.Y
            local inHead = mx>=bp.X and mx<=bp.X+bs.X and my>=bp.Y and my<=bp.Y+bs.Y
            if not inDrop and not inHead then closeDrop() end
        end
    end)

    local function refreshList()
        local ft = showSearch and searchInput and searchInput.Text:lower() or ""
        for _,b in ipairs(dropScroll:GetChildren()) do if b:IsA("TextButton") then b.Visible=false end end
        for _,opt in ipairs(options) do
            local b=dropScroll:FindFirstChild(opt)
            if b and opt:lower():find(ft,1,true) then b.Visible=true end
        end
    end
    if showSearch and searchInput then searchInput:GetPropertyChangedSignal("Text"):Connect(refreshList) end

    for _,opt in ipairs(options) do
        local btn=NEW("TextButton",{
            Size=UDim2.new(1,-6,0,24),BackgroundTransparency=1,ZIndex=201,
            Text="  "..opt,Font=Enum.Font.Gotham,TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left,Name=opt,AutoButtonColor=false
        },dropScroll)
        CORNER(3,btn)
        btn.TextColor3=TEXT2

        btn.MouseEnter:Connect(function() TWEEN(btn,0.1,{BackgroundTransparency=0.85,BackgroundColor3=BG4,TextColor3=GOLD2}); btn.Font=Enum.Font.GothamSemibold end)
        btn.MouseLeave:Connect(function()
            local isSel = isMulti and TogglesData[configKey].Value[opt] or (not isMulti and TogglesData[configKey].Value==opt)
            if not isSel then TWEEN(btn,0.1,{BackgroundTransparency=1,TextColor3=TEXT2}); btn.Font=Enum.Font.Gotham end
        end)

        btn.MouseButton1Click:Connect(function()
            if isMulti then
                local cur=TogglesData[configKey].Value; cur[opt]=not cur[opt]
                if cur[opt] then
                    TWEEN(btn,0.1,{TextColor3=GOLD2}); btn.Font=Enum.Font.GothamBold
                    if not btn:FindFirstChild("TickMark") then
                        NEW("TextLabel",{Name="TickMark",Text="✓",TextColor3=GOLD2,TextXAlignment=Enum.TextXAlignment.Right,Size=UDim2.new(1,-5,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=202},btn)
                    end
                else
                    TWEEN(btn,0.1,{TextColor3=TEXT2}); btn.Font=Enum.Font.Gotham
                    if btn:FindFirstChild("TickMark") then btn.TickMark:Destroy() end
                end
                local ct=0; for _,v in pairs(cur) do if v then ct=ct+1 end end
                headBtn.Text = ct>0 and (ct.." Selected") or "Select..."
                TogglesData[configKey].Callback(cur)
            else
                for _,ob in ipairs(dropScroll:GetChildren()) do
                    if ob:IsA("TextButton") then TWEEN(ob,0.1,{TextColor3=TEXT2}); ob.Font=Enum.Font.Gotham end
                end
                TWEEN(btn,0.1,{TextColor3=GOLD2}); btn.Font=Enum.Font.GothamBold
                headBtn.Text=opt
                closeDrop()
                TogglesData[configKey].Value=opt; TogglesData[configKey].Callback(opt)
            end
        end)
    end
end

-- ── BAIT (single select, no default) ──
local baitOpts={"Common Fish Bait","Rare Fish Bait","Legendary Fish Bait"}
CreateDropdown(ConfigFishFrame,"Auto Select Bait",baitOpts,nil,34,"Config_SelectBait",false,false)

-- ── SELL FISH (multi, no default) ──
local sellOpts={"Common","Rare","Legendary"}
CreateDropdown(ConfigFishFrame,"Auto Sell Fish",sellOpts,nil,78,"Config_SellFish",true,false)

-- ── AUTO BUY ITEMS (multi + always-visible search, full rarity list) ──
do
    local BUY_ITEMS_SORTED = {
        -- Mythic
        "All Seeing Shamrock","Mythical Fruit Chest",
        -- Legendary
        "Legendary Fruit Chest","Legendary Fish Bait","Merchants Banana Rod",
        "Knight's Gauntlet","Crab Cutlass","Bisento","Kessui","Raiui",
        "Tropical Parrot","Coffin Boat","Striker","Hoverboard",
        -- Epic
        "Hunter's Journal","Jitte","Spirit Color Essence",
        "Crimson Nightcoat","Sea-Breeze Haori","Raylo's Outfit",
        "Blossom Skirt","Desert Merchant Outfit","Sea-Breeze Skirt","Tari's Karoo Coat",
        -- Rare
        "Race Reroll","Rare Fruit Chest","Spare Fruit Bag","Bomi's Log Pose",
        "Gravity Blade","Dark Root","Rare Fish Bait","Golden Staff","Golden Hook","Thrilled Ship",
        -- Uncommon / Common
        "Karoo Mount","Special Tailor Token","SP Reset Essence",
    }
    local ITEM_RARITY = {
        ["All Seeing Shamrock"]="* Mythic",["Mythical Fruit Chest"]="* Mythic",
        ["Legendary Fruit Chest"]="+ Legendary",["Legendary Fish Bait"]="+ Legendary",
        ["Merchants Banana Rod"]="+ Legendary",["Knight's Gauntlet"]="+ Legendary",
        ["Crab Cutlass"]="+ Legendary",["Bisento"]="+ Legendary",
        ["Kessui"]="+ Legendary",["Raiui"]="+ Legendary",
        ["Tropical Parrot"]="+ Legendary",["Coffin Boat"]="+ Legendary",
        ["Striker"]="+ Legendary",["Hoverboard"]="+ Legendary",
        ["Hunter's Journal"]="# Epic",["Jitte"]="# Epic",
        ["Spirit Color Essence"]="# Epic",["Crimson Nightcoat"]="# Epic",
        ["Sea-Breeze Haori"]="# Epic",["Raylo's Outfit"]="# Epic",
        ["Blossom Skirt"]="# Epic",["Desert Merchant Outfit"]="# Epic",
        ["Sea-Breeze Skirt"]="# Epic",["Tari's Karoo Coat"]="# Epic",
        ["Race Reroll"]="- Rare",["Rare Fruit Chest"]="- Rare",
        ["Spare Fruit Bag"]="- Rare",["Bomi's Log Pose"]="- Rare",
        ["Gravity Blade"]="- Rare",["Dark Root"]="- Rare",
        ["Rare Fish Bait"]="- Rare",["Golden Staff"]="- Rare",
        ["Golden Hook"]="- Rare",["Thrilled Ship"]="- Rare",
        ["Karoo Mount"]="Uncommon",["Special Tailor Token"]="Uncommon",
        ["SP Reset Essence"]="Common",
    }
    local RARITY_COLOR = {
        ["* Mythic"]=C(220,80,255),  ["+ Legendary"]=C(255,185,50),
        ["# Epic"]=C(160,80,255),    ["- Rare"]=C(80,140,255),
        ["Uncommon"]=C(80,210,120),  ["Common"]=C(180,175,195),
    }
    -- LayoutOrder theo rarity để UIListLayout sort đúng thứ tự
    local RARITY_ORDER = {
        ["* Mythic"]=1, ["+ Legendary"]=2, ["# Epic"]=3,
        ["- Rare"]=4,   ["Uncommon"]=5,    ["Common"]=6,
    }

    -- label
    NEW("TextLabel",{
        Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,122),
        BackgroundTransparency=1,Text="Auto Buy Items",TextColor3=TEXT1,
        Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left
    },ConfigFishFrame)

    -- count badge (shows N Selected)
    local buyCountBadge = NEW("TextLabel",{
        Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,120),
        BackgroundColor3=BG5,TextColor3=TEXT3,
        Font=Enum.Font.GothamBold,TextSize=11,Text="Select items...",
        TextXAlignment=Enum.TextXAlignment.Center
    },ConfigFishFrame)
    CORNER(5,buyCountBadge)
    STROKE(GOLD3,1,0,buyCountBadge)

    -- search box — xóa khi click vào, giữ nguyên khi blur
    local buySearchBox = NEW("TextBox",{
        Size=UDim2.new(1,-24,0,26),Position=UDim2.new(0,12,0,150),
        BackgroundColor3=BG5,PlaceholderText="  Search items...",
        Text="",TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=11,
        ClearTextOnFocus=false, MultiLine=false
    },ConfigFishFrame)
    CORNER(6,buySearchBox)
    local buySearchStroke = STROKE(GOLD3,1,0,buySearchBox)
    -- Xóa text khi click vào (focused) để gõ filter mới
    buySearchBox.Focused:Connect(function()
        buySearchBox.Text = ""
        TWEEN(buySearchStroke,0.15,{Color=GOLD2})
    end)
    buySearchBox.FocusLost:Connect(function()
        TWEEN(buySearchStroke,0.15,{Color=GOLD3})
    end)

    -- scrolling list — UIListLayout sort theo LayoutOrder (rarity)
    local buyList = NEW("ScrollingFrame",{
        Size=UDim2.new(1,-24,0,120),Position=UDim2.new(0,12,0,182),
        BackgroundColor3=BG0,BorderSizePixel=0,
        ScrollBarThickness=2,ScrollBarImageColor3=GOLD,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)
    },ConfigFishFrame)
    CORNER(6,buyList)
    STROKE(GOLD3,1,0,buyList)
    NEW("UIListLayout",{
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,2),
        SortOrder=Enum.SortOrder.LayoutOrder  -- sort theo rarity order
    },buyList)
    NEW("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)},buyList)

    -- init toggledata — Callback restores checkmarks when config is loaded
    TogglesData["Config_BuyItems"] = {
        Value    = {},
        HeadBtn  = buyCountBadge,
        Callback = function(val)
            if type(val) ~= "table" then return end
            local ct = 0
            for itemName, row in pairs(buyBtns) do
                local selected = val[itemName] == true
                local nameLabel = row:FindFirstChildOfClass("TextLabel")  -- first TextLabel = rarity tag, 2nd = name
                local nameLbl, checkLbl
                for _, child in ipairs(row:GetChildren()) do
                    if child:IsA("TextLabel") then
                        if child.Size.X.Offset <= 80 then
                            -- narrow = rarity tag, skip
                        elseif child.Size.X.Offset == 20 then
                            checkLbl = child
                        else
                            nameLbl = child
                        end
                    end
                end
                if checkLbl then checkLbl.Text = selected and "✓" or "" end
                if nameLbl  then
                    nameLbl.TextColor3 = selected and GOLD2 or TEXT2
                    nameLbl.Font       = selected and Enum.Font.GothamBold or Enum.Font.Gotham
                end
                if selected then ct = ct + 1 end
            end
            buyCountBadge.Text       = ct > 0 and (ct .. " Selected") or "Select items..."
            buyCountBadge.TextColor3 = ct > 0 and GOLD2 or TEXT3
        end,
    }

    local buyBtns = {}
    for idx,itemName in ipairs(BUY_ITEMS_SORTED) do
        local rarLabel = ITEM_RARITY[itemName] or "# Epic"  -- default Epic nếu không có trong list
        local rarColor = RARITY_COLOR[rarLabel] or C(160,80,255)
        local rarOrder = RARITY_ORDER[rarLabel] or 3  -- default Epic order
        local row = NEW("Frame",{
            Size=UDim2.new(1,-6,0,26),BackgroundColor3=BG3,
            Name=itemName,BorderSizePixel=0,
            LayoutOrder = rarOrder * 1000 + idx  -- sort by rarity first, then original order within rarity
        },buyList)
        CORNER(4,row)

        -- rarity tag
        NEW("TextLabel",{
            Text=rarLabel,Size=UDim2.new(0,80,1,0),Position=UDim2.new(0,6,0,0),
            BackgroundTransparency=1,TextColor3=rarColor,
            Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left
        },row)
        -- item name
        local nameLabel = NEW("TextLabel",{
            Text=itemName,Size=UDim2.new(1,-110,1,0),Position=UDim2.new(0,82,0,0),
            BackgroundTransparency=1,TextColor3=TEXT2,
            Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left
        },row)
        -- checkmark
        local check = NEW("TextLabel",{
            Text="",Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),
            BackgroundTransparency=1,TextColor3=GOLD2,
            Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Center
        },row)

        local rowBtn = NEW("TextButton",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="",AutoButtonColor=false
        },row)

        local function refreshBuyCount()
            local ct=0
            for _,v in pairs(TogglesData["Config_BuyItems"].Value) do if v then ct=ct+1 end end
            buyCountBadge.Text = ct>0 and (ct.." Selected") or "Select items..."
            buyCountBadge.TextColor3 = ct>0 and GOLD2 or TEXT3
        end

        rowBtn.MouseEnter:Connect(function() TWEEN(row,0.1,{BackgroundColor3=BG4}) end)
        rowBtn.MouseLeave:Connect(function() TWEEN(row,0.1,{BackgroundColor3=BG3}) end)
        rowBtn.MouseButton1Click:Connect(function()
            local cur = TogglesData["Config_BuyItems"].Value
            cur[itemName] = not cur[itemName]
            if cur[itemName] then
                check.Text="✓"; TWEEN(nameLabel,0.1,{TextColor3=GOLD2}); nameLabel.Font=Enum.Font.GothamBold
            else
                check.Text=""; TWEEN(nameLabel,0.1,{TextColor3=TEXT2}); nameLabel.Font=Enum.Font.Gotham
            end
            refreshBuyCount()
        end)

        buyBtns[itemName] = row
    end

    -- search filter
    buySearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local ft = buySearchBox.Text:lower()
        for name, row in pairs(buyBtns) do
            row.Visible = ft=="" or name:lower():find(ft,1,true)~=nil
        end
    end)
end

-- ── CRAFT BAIT (multi, no default) ──
local craftOpts={"Rare","Legendary"}
CreateDropdown(ConfigFishFrame,"Auto Craft Bait",craftOpts,nil,318,"Config_CraftBait",true,false)

-- ── BAIT BUY AMOUNT ──
_G.FishBuyAmount = 50
NEW("TextLabel",{
    Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,354),
    BackgroundTransparency=1,Text="Bait Buy Amount",TextColor3=TEXT1,
    Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left
},ConfigFishFrame)
local buyAmtFrame = NEW("Frame",{
    Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,352),
    BackgroundColor3=BG5
},ConfigFishFrame)
CORNER(5,buyAmtFrame)
local buyAmtStroke = STROKE(GOLD3,1,0,buyAmtFrame)
local buyAmtBox = NEW("TextBox",{
    Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,Text="50",PlaceholderText="50",
    TextColor3=GOLD2,Font=Enum.Font.GothamSemibold,TextSize=12,
    ClearTextOnFocus=false
},buyAmtFrame)
buyAmtBox.Focused:Connect(function() TWEEN(buyAmtStroke,0.15,{Color=GOLD2}) end)
buyAmtBox.FocusLost:Connect(function()
    local v = tonumber(buyAmtBox.Text)
    if v and v > 0 then
        _G.FishBuyAmount = math.floor(v)
    else
        buyAmtBox.Text = tostring(_G.FishBuyAmount)
    end
    TogglesData["Config_BaitAmount"].Value = _G.FishBuyAmount
    TWEEN(buyAmtStroke,0.15,{Color=GOLD3})
end)

-- Track BaitAmount so ConfigManager can save/restore it
TogglesData["Config_BaitAmount"] = {
    Value    = 50,
    HeadBtn  = buyAmtBox,
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            _G.FishBuyAmount = math.floor(n)
            pcall(function() buyAmtBox.Text = tostring(math.floor(n)) end)
        end
    end,
}

-- ==========================================
-- Ô NHẬP DISCORD WEBHOOK (Dùng chuẩn UI mới)
-- ==========================================
NEW("TextLabel",{
    Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0,392),
    BackgroundTransparency=1,Text="Discord Webhook",TextColor3=TEXT1,
    Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left
}, ConfigFishFrame)

local boxFrameWH = NEW("Frame",{
    Size=UDim2.new(0,158,0,24),Position=UDim2.new(1,-170,0,390),
    BackgroundColor3=BG5
}, ConfigFishFrame)
CORNER(5, boxFrameWH)
local boxStrokeWH = STROKE(GOLD3, 1, 0, boxFrameWH)

local textBoxWH = NEW("TextBox",{
    Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,Text="",PlaceholderText="https://discord...",
    TextColor3=TEXT1,PlaceholderColor3=TEXT3,
    Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,
    ClearTextOnFocus=false,ClipsDescendants=true
}, boxFrameWH)

-- Full init with HeadBtn + Callback so ConfigManager can restore text
TogglesData["Config_Webhook"] = {
    Value    = "",
    HeadBtn  = textBoxWH,
    Callback = function(val)
        _G.WebhookUrl = val or ""
        pcall(function() textBoxWH.Text = val or "" end)
    end,
}

-- Xử lý khi dán link xong (Chớp viền vàng báo thành công)
textBoxWH.FocusLost:Connect(function()
    local txt = textBoxWH.Text
    _G.WebhookUrl = txt
    TogglesData["Config_Webhook"].Value = txt
    TWEEN(boxStrokeWH, 0.15, {Color=GOLD2})
    task.wait(0.2)
    TWEEN(boxStrokeWH, 0.2, {Color=GOLD3})
end)

-- ── AUTO STORE / DROP FRUIT CARD ──
local fruitCardH = 238
local fruitCard = MakeCard(FishingPage, fruitCardH, 4)
CardHeader(fruitCard, "fruit", "FRUIT MANAGEMENT", GREEN)

-- Auto Store Fruit row
RowLabel(fruitCard, "Auto Store Fruit", "Auto store fruit to inventory", 34)
CardToggle(fruitCard, 44, "AutoStoreFruit", function(state)
    _G.AutoStoreFruit = state
end)
RowDivider(fruitCard, 82)

-- Auto Drop Fruit row
RowLabel(fruitCard, "Auto Drop Fruit", "Drop fruit when inventory full", 88)
CardToggle(fruitCard, 98, "AutoDropFruit", function(state)
    _G.AutoDropFruit = state
end)
RowDivider(fruitCard, 132)

-- Fruit Rarity Filter (multi-select)
local RARITY_OPTS = {"Common", "Rare", "Epic", "Legendary", "Mythic"}
CreateDropdown(fruitCard, "Fruit Rarity Filter", RARITY_OPTS, "Common", 138, "Config_FruitRarity", true, false)

-- Select specific Fruit (single + search)
local FRUIT_OPTS = {
    "Bari Bari no Mi","Bomu Bomu no Mi","Doku Doku no Mi","Gomu Gomu no Mi",
    "Gura Gura no Mi","Hie Hie no Mi","Magu Magu no Mi","Mero Mero no Mi",
    "Mori Mori no Mi","Nikyu Nikyu no Mi","Ope Ope no Mi","Pika Pika no Mi",
    "Suna Suna no Mi","Tori Tori no Mi","Yami Yami no Mi","Zushi Zushi no Mi",
}
CreateDropdown(fruitCard, "Select Fruit", FRUIT_OPTS, FRUIT_OPTS[1], 186, "Config_FruitSelect", false, true)

-- =====================================================================
-- ██████  STATS PAGE
-- =====================================================================
PageLayout(StatsPage, 14, 8)

local AutoStatsData = {}

local function CreateStatRow(statName, layoutOrder)
    local row = MakeCard(StatsPage, 52, layoutOrder)

    -- stat name
    NEW("TextLabel",{
        Text=statName, Size=UDim2.new(0.52,0,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, TextColor3=TEXT1,
        Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left
    }, row)

    -- auto add button
    local addBtn=NEW("TextButton",{
        Size=UDim2.new(0,100,0,26), Position=UDim2.new(1,-218,0.5,-13),
        BackgroundColor3=BG5, Text="Auto Add",
        TextColor3=GOLD2, Font=Enum.Font.GothamBold, TextSize=12,
        AutoButtonColor=false
    }, row)
    CORNER(6, addBtn)
    local btnStroke=STROKE(GOLD3,1,0,addBtn)

    -- max cap input
    local capBox=NEW("TextBox",{
        Size=UDim2.new(0,100,0,26), Position=UDim2.new(1,-108,0.5,-13),
        BackgroundColor3=BG5, Text="", PlaceholderText="Max Cap...",
        TextColor3=GOLD2, Font=Enum.Font.GothamSemibold, TextSize=12
    }, row)
    CORNER(6, capBox)
    local boxStroke=STROKE(GOLD3,1,0,capBox)

    capBox.Focused:Connect(function() TWEEN(boxStroke,0.2,{Color=GOLD2}) end)
    capBox.FocusLost:Connect(function()
        TWEEN(boxStroke,0.2,{Color=GOLD3})
        local v=tonumber(capBox.Text)
        if v then AutoStatsData[statName].Cap=v else AutoStatsData[statName].Cap=0; capBox.Text="" end
    end)

    AutoStatsData[statName]={Active=false,Cap=0,Btn=addBtn,Strk=btnStroke,Box=capBox}
    addBtn.MouseButton1Click:Connect(function()
        local d=AutoStatsData[statName]; d.Active=not d.Active
        TWEEN(addBtn,0.2,{BackgroundColor3=d.Active and GOLDD or BG5})
        TWEEN(btnStroke,0.2,{Color=d.Active and GOLD2 or GOLD3})
        addBtn.TextColor3=d.Active and C(10,8,2) or GOLD2
        addBtn.Text=d.Active and "● Adding..." or "Auto Add"
    end)
end

local StatList={"Strength","Stamina","Defense","Gun Mastery","Sword Mastery","Devil Fruit","Fighting Style Mastery"}
for idx,sName in ipairs(StatList) do CreateStatRow(sName, idx) end

if AutoStats and AutoStats.Start then AutoStats.Start(AutoStatsData) end

end  -- end if not IS_LOBBY (AutoFarm → Stats pages)

-- AutoStatsData cần tồn tại để ConfigManager.Init không bị lỗi (kể cả ở lobby)
if not AutoStatsData then AutoStatsData = {} end

-- =====================================================================
-- ██████  CONFIG PAGE  (both lobby and game world)
-- =====================================================================
PageLayout(ConfigPage, 14, 10)

-- Config header card
local cfgHeaderCard = MakeCard(ConfigPage, 38, 0)
cfgHeaderCard.BackgroundColor3 = C(9,10,22)
-- left accent bar
local cfgAcc = NEW("Frame",{Size=UDim2.new(0,2,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=GOLD,BorderSizePixel=0},cfgHeaderCard)
CORNER(1,cfgAcc)
-- "CONFIG MANAGER" main title
NEW("TextLabel",{
    Text="CONFIG MANAGER",
    Size=UDim2.new(0,148,1,0), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, TextColor3=GOLD2,
    Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left
}, cfgHeaderCard)
-- breadcrumb separators
local CFG_CRUMBS = {
    {" SAVE", CYAN},
    {" LOAD", GREEN},
    {" AUTO", AMBER},
}
local crumbX = 162
for _, cr in ipairs(CFG_CRUMBS) do
    NEW("TextLabel",{
        Text="·", Size=UDim2.new(0,10,1,0), Position=UDim2.new(0,crumbX,0,0),
        BackgroundTransparency=1, TextColor3=TEXT3,
        Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Center
    }, cfgHeaderCard)
    crumbX = crumbX + 10
    local cLbl = NEW("TextLabel",{
        Text=cr[1], Size=UDim2.new(0,42,1,0), Position=UDim2.new(0,crumbX,0,0),
        BackgroundTransparency=1, TextColor3=cr[2],
        Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left
    }, cfgHeaderCard)
    crumbX = crumbX + 42
end

local cfgContainer = NEW("Frame",{
    Size=UDim2.new(1,-24,0,390), BackgroundTransparency=1, LayoutOrder=1
}, ConfigPage)
-- Horizontal layout for the two panels
NEW("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left,
    VerticalAlignment=Enum.VerticalAlignment.Top,
    Padding=UDim.new(0,10),
    SortOrder=Enum.SortOrder.LayoutOrder
}, cfgContainer)

-- ── LEFT PANEL: File list ──
local LeftPanel = NEW("Frame",{
    Size=UDim2.new(0,238,1,0),
    BackgroundColor3=BG3, LayoutOrder=0
}, cfgContainer)
CORNER(9, LeftPanel)
STROKE(GOLD, 1, 0.65, LeftPanel)

local lpHead = NEW("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=BG_HDR}, LeftPanel)
CORNER(9, lpHead)
NEW("Frame",{Size=UDim2.new(1,0,0,15),Position=UDim2.new(0,0,1,-15),BackgroundColor3=BG_HDR,BorderSizePixel=0},lpHead)
-- accent bar
local lpAcc = NEW("Frame",{Size=UDim2.new(0,2,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=GOLD2,BorderSizePixel=0},lpHead)
CORNER(1,lpAcc)
NEW("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,0,0),BackgroundColor3=GOLD,BorderSizePixel=0,BackgroundTransparency=0.5},lpHead)
NEW("TextLabel",{
    Text="+ SAVED CONFIGS",
    Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,14,0,0),
    BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,
    TextSize=10,TextXAlignment=Enum.TextXAlignment.Left
},lpHead)

local SearchBoxConfig = NEW("TextBox",{
    Size=UDim2.new(1,-16,0,28), Position=UDim2.new(0,8,0,40),
    BackgroundColor3=BG5, PlaceholderText="  Search configs...",
    Text="", TextColor3=GOLD2, Font=Enum.Font.GothamSemibold, TextSize=11
}, LeftPanel)
CORNER(6, SearchBoxConfig)
local SearchStrokeConfig = STROKE(GOLD3,1,0.3,SearchBoxConfig)
SearchBoxConfig.Focused:Connect(function() TWEEN(SearchStrokeConfig,0.2,{Color=GOLD2,Transparency=0}) end)
SearchBoxConfig.FocusLost:Connect(function() TWEEN(SearchStrokeConfig,0.2,{Color=GOLD3,Transparency=0.3}) end)

local ConfigList = NEW("ScrollingFrame",{
    Size=UDim2.new(1,-16,1,-76), Position=UDim2.new(0,8,0,74),
    BackgroundColor3=C(6,7,14), ScrollBarThickness=2, ScrollBarImageColor3=GOLD3,
    BorderSizePixel=0
}, LeftPanel)
CORNER(6, ConfigList)
STROKE(C(25,22,8),1,0.2,ConfigList)
local ListLayout = NEW("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),HorizontalAlignment=Enum.HorizontalAlignment.Center},ConfigList)
NEW("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},ConfigList)

-- ── RIGHT PANEL: Actions ──
local RightPanel = NEW("Frame",{
    Size=UDim2.new(1,-248,1,0),
    BackgroundColor3=BG3, LayoutOrder=1
}, cfgContainer)
CORNER(8, RightPanel)
STROKE(GOLD, 1, 0.72, RightPanel)

local rpHead = NEW("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=BG_HDR},RightPanel)
CORNER(8,rpHead)
NEW("Frame",{Size=UDim2.new(1,0,0,15),Position=UDim2.new(0,0,1,-15),BackgroundColor3=BG_HDR,BorderSizePixel=0},rpHead)
-- accent bar
local rpAcc = NEW("Frame",{Size=UDim2.new(0,2,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=GOLD2,BorderSizePixel=0},rpHead)
CORNER(1,rpAcc)
NEW("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,0),BackgroundColor3=GOLD,BorderSizePixel=0,BackgroundTransparency=0.5},rpHead)
NEW("TextLabel",{
    Text="▷ ACTIONS",
    Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,
    TextSize=10,TextXAlignment=Enum.TextXAlignment.Left
},rpHead)

local RightLayout = NEW("UIListLayout",{
    SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6),
    HorizontalAlignment=Enum.HorizontalAlignment.Center
},RightPanel)
NEW("UIPadding",{PaddingTop=UDim.new(0,0),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},RightPanel)

local ConfigNameBox = NEW("TextBox",{
    Size=UDim2.new(1,0,0,34), BackgroundColor3=BG5,
    PlaceholderText="  Config name...", Text="",
    TextColor3=GOLD2, Font=Enum.Font.GothamSemibold, TextSize=12
}, RightPanel)
CORNER(6, ConfigNameBox)
local NameStroke = STROKE(GOLD3,1,0,ConfigNameBox)
ConfigNameBox.Focused:Connect(function() TWEEN(NameStroke,0.2,{Color=GOLD2}) end)
ConfigNameBox.FocusLost:Connect(function() TWEEN(NameStroke,0.2,{Color=GOLD3}) end)

NEW("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C(30,28,55),BorderSizePixel=0},RightPanel)

local function CreateActionBtn(iconN, label, bgCol, hoverCol, strokeCol, textCol)
    textCol = textCol or TEXT1
    local btn = NEW("TextButton",{
        Size=UDim2.new(1,0,0,34), BackgroundColor3=bgCol,
        Text="", AutoButtonColor=false
    }, RightPanel)
    CORNER(6, btn)
    STROKE(strokeCol, 1, 0.08, btn)

    -- drawn icon left side
    local iHolder = NEW("Frame",{
        Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,12,0.5,-8),
        BackgroundTransparency=1,BorderSizePixel=0
    },btn)
    DrawIcon(iHolder, iconN, 0, 0, 16, strokeCol)

    NEW("TextLabel",{
        Text=label,Size=UDim2.new(1,-38,1,0),Position=UDim2.new(0,34,0,0),
        BackgroundTransparency=1,TextColor3=textCol,
        Font=Enum.Font.GothamBold,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left
    },btn)

    btn.MouseEnter:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=hoverCol}) end)
    btn.MouseLeave:Connect(function() TWEEN(btn,0.15,{BackgroundColor3=bgCol}) end)
    return btn
end

local CreateBtn      = CreateActionBtn("fruit",   "CREATE CONFIG",  C(8,28,8),   C(12,44,12),  GREEN,   GREEN)
local SaveBtn        = CreateActionBtn("gear",    "SAVE CONFIG",    C(10,12,32), C(16,20,52),  BLUE_A,  BLUE_A)
local LoadBtn        = CreateActionBtn("globe",   "LOAD CONFIG",    C(8,18,40),  C(12,26,58),  CYAN,    CYAN)
local RefreshBtn     = CreateActionBtn("wave",    "REFRESH LIST",   C(8,22,26),  C(12,32,38),  C(48,180,180), C(48,180,180))
local SetAutoLoadBtn = CreateActionBtn("lightning","SET AUTO LOAD", C(30,22,6),  C(46,34,8),   AMBER,   AMBER)
local DeleteBtn      = CreateActionBtn("shield",  "DELETE CONFIG",  C(38,8,8),   C(58,12,12),  RED,     RED)

pcall(function()
    local CL=require("Config/ConfigManager")
    if CL and CL.Init then
        CL.Init({
            ConfigNameBox=ConfigNameBox,ConfigList=ConfigList,
            CreateBtn=CreateBtn,SaveBtn=SaveBtn,LoadBtn=LoadBtn,
            RefreshBtn=RefreshBtn,SetAutoLoadBtn=SetAutoLoadBtn,
            DeleteBtn=DeleteBtn,SearchBox=SearchBoxConfig
        }, AutoStatsData, TogglesData)
    end
end)

-- =====================================================================
-- START AUTO FRUIT MANAGER  (game world only)
-- =====================================================================
if not IS_LOBBY then
    task.spawn(function()
        pcall(function()
            local FM = require("Farm/AutoFruitManager")
            if FM and FM.Start then FM.Start(TogglesData) end
        end)
    end)
end

-- =====================================================================
-- MINIMIZE ANIMATION
-- =====================================================================
local function ToggleHub(isVisible)
    if not isVisible then
        TWEEN_BACK(MainFrame,0,{}) -- cancel active tweens
        TweenService:Create(MainFrame,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=MiniLogo.Position,Size=UDim2.new(0,0,0,0),GroupTransparency=1}):Play()
        task.wait(0.4); MainFrame.Visible=false; MiniLogo.Visible=true
    else
        MiniLogo.Visible=false; MainFrame.Visible=true
        MainFrame.Position=MiniLogo.Position; MainFrame.Size=UDim2.new(0,0,0,0); MainFrame.GroupTransparency=1
        TweenService:Create(MainFrame,TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-360,0.5,-230),Size=UDim2.new(0,720,0,460),GroupTransparency=0}):Play()
    end
end

MinBtn.MouseButton1Click:Connect(function() ToggleHub(false) end)
MiniLogo.MouseButton1Click:Connect(function() ToggleHub(true) end)

CloseBtn.MouseButton1Click:Connect(function()
    d = false
    getgenv().ZiliHub_Loaded = false

    -- Dọn compact widget nếu đang bật
    pcall(function()
        if CompactWidget and CompactWidget.Parent then
            CompactWidget:Destroy()
        end
    end)

    local mStroke = MainFrame:FindFirstChildOfClass("UIStroke")

    -- ── PHASE 1: RED FLASH (0.1s) ──
    TWEEN(CloseBtn, 0.06, {TextColor3 = C(255,40,40)})
    if mStroke then
        TWEEN(mStroke, 0.06, {Color=C(255,40,40), Thickness=3})
    end
    -- Red overlay flash on entire panel
    local redOverlay = NEW("Frame",{
        Size=UDim2.new(1,0,1,0), BackgroundColor3=C(200,20,20),
        BackgroundTransparency=0.85, ZIndex=100, BorderSizePixel=0
    }, MainFrame)
    CORNER(10, redOverlay)
    task.wait(0.06)
    TWEEN(redOverlay, 0.08, {BackgroundTransparency=1})

    -- ── PHASE 2: GLITCH (0.18s) ──
    local origPos = MainFrame.Position
    local ox, oy = origPos.X.Offset, origPos.Y.Offset
    local glitchSeq = {-8, 6, -10, 9, -4, 7, -3, 2, 0}
    for _, dx in ipairs(glitchSeq) do
        -- random vertical micro-shift for glitch feel
        local dy = math.random(-2, 2)
        TweenService:Create(MainFrame, TweenInfo.new(0.02, Enum.EasingStyle.Linear), {
            Position = UDim2.new(origPos.X.Scale, ox+dx, origPos.Y.Scale, oy+dy)
        }):Play()
        task.wait(0.02)
    end

    -- ── PHASE 3: SCANLINE SWEEP (0.12s) ──
    local scanLine = NEW("Frame",{
        Size=UDim2.new(1,0,0,3), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=C(255,80,80), BackgroundTransparency=0.2,
        ZIndex=101, BorderSizePixel=0
    }, MainFrame)
    -- sweep from top to bottom
    TweenService:Create(scanLine, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0,0,1,-3),
        BackgroundTransparency=0.7
    }):Play()
    task.wait(0.12)

    -- ── PHASE 4: SPAWN MULTI-RING PARTICLES ──
    local cx = MainFrame.AbsolutePosition.X + MainFrame.AbsoluteSize.X/2
    local cy = MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y/2
    local allParticles = {}

    -- Ring 1: 8 large GOLD fragments (corners + edges)
    local ring1dirs = {{-1,-1},{0,-1},{1,-1},{-1,0},{1,0},{-1,1},{0,1},{1,1}}
    for _, dir in ipairs(ring1dirs) do
        local sz = math.random(12,20)
        local frag = NEW("Frame",{
            Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(0, cx-sz/2+dir[1]*12, 0, cy-sz/2+dir[2]*12),
            BackgroundColor3=GOLD2, BorderSizePixel=0, ZIndex=102
        }, ScreenGui)
        CORNER(math.random(2,5), frag)
        table.insert(allParticles, {
            frag=frag, dir=dir,
            dist=math.random(200,300), speed=0.55, color=GOLD2
        })
    end

    -- Ring 2: 12 medium RED sparks at diagonal angles
    for i=1,12 do
        local angle = (i/12) * math.pi * 2
        local dir = {math.cos(angle), math.sin(angle)}
        local sz = math.random(5,9)
        local frag = NEW("Frame",{
            Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(0, cx-sz/2+dir[1]*8, 0, cy-sz/2+dir[2]*8),
            BackgroundColor3=C(220,60,60), BorderSizePixel=0, ZIndex=103
        }, ScreenGui)
        CORNER(2, frag)
        table.insert(allParticles, {
            frag=frag, dir=dir,
            dist=math.random(150,260), speed=0.4, color=C(220,60,60)
        })
    end

    -- Ring 3: 16 tiny WHITE sparks, random spread
    for i=1,16 do
        local angle = (i/16) * math.pi * 2 + math.random()*0.3
        local dir = {math.cos(angle), math.sin(angle)}
        local sz = math.random(3,5)
        local frag = NEW("Frame",{
            Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(0, cx-sz/2, 0, cy-sz/2),
            BackgroundColor3=C(255,240,200), BorderSizePixel=0, ZIndex=104
        }, ScreenGui)
        CORNER(2, frag)
        table.insert(allParticles, {
            frag=frag, dir=dir,
            dist=math.random(80,180), speed=0.3, color=C(255,240,200)
        })
    end

    -- Shockwave ring (expanding circle outline)
    local shockwave = NEW("Frame",{
        Size=UDim2.new(0,10,0,10),
        Position=UDim2.new(0, cx-5, 0, cy-5),
        BackgroundTransparency=1, ZIndex=105, BorderSizePixel=0
    }, ScreenGui)
    CORNER(5, shockwave)
    local shockStroke = STROKE(GOLD, 2.5, 0, shockwave)

    -- Inner glow burst
    local glowBurst = NEW("Frame",{
        Size=UDim2.new(0,20,0,20),
        Position=UDim2.new(0, cx-10, 0, cy-10),
        BackgroundColor3=C(255,220,120), BackgroundTransparency=0.3,
        ZIndex=102, BorderSizePixel=0
    }, ScreenGui)
    CORNER(10, glowBurst)

    -- ── PHASE 5: ALL SIMULTANEOUS EXPLOSIONS ──

    -- Panel implode to center
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(origPos.X.Scale, ox + MainFrame.AbsoluteSize.X/2 - 10,
                             origPos.Y.Scale, oy + MainFrame.AbsoluteSize.Y/2 - 10),
        Size = UDim2.new(0,20,0,20),
        GroupTransparency = 1
    }):Play()

    -- Shockwave expand
    TweenService:Create(shockwave, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size=UDim2.new(0,500,0,500),
        Position=UDim2.new(0, cx-250, 0, cy-250),
    }):Play()
    TweenService:Create(shockStroke, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency=1, Thickness=0.5
    }):Play()

    -- Glow burst expand + fade
    TweenService:Create(glowBurst, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size=UDim2.new(0,120,0,120),
        Position=UDim2.new(0, cx-60, 0, cy-60),
        BackgroundTransparency=1
    }):Play()

    -- All particles fly out
    for _, p in ipairs(allParticles) do
        local tx = cx + p.dir[1] * p.dist
        local ty = cy + p.dir[2] * p.dist
        -- stagger by ring (speed difference)
        TweenService:Create(p.frag, TweenInfo.new(p.speed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, tx, 0, ty),
            Size = UDim2.new(0,2,0,2),
            BackgroundTransparency = 1
        }):Play()
    end

    task.wait(0.58)

    -- ── PHASE 6: CLEANUP ──
    for _, p in ipairs(allParticles) do
        if p.frag and p.frag.Parent then p.frag:Destroy() end
    end
    if shockwave and shockwave.Parent then shockwave:Destroy() end
    if glowBurst and glowBurst.Parent then glowBurst:Destroy() end
    ScreenGui:Destroy()
end)

-- Drag
local d,dS,sP
TopBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;dS=i.Position;sP=MainFrame.Position end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then local delta=i.Position-dS;MainFrame.Position=UDim2.new(sP.X.Scale,sP.X.Offset+delta.X,sP.Y.Scale,sP.Y.Offset+delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)

-- =====================================================================
-- 🛡️ ZILI HUB COMPATIBILITY SCANNER
-- =====================================================================
local function RunExecutorDiagnostics()
    local env=getgenv and getgenv() or _G
    local name="Unknown Engine"
    if type(identifyexecutor)=="function" then pcall(function() name=identifyexecutor() end) end

    local critical={"hookmetamethod","hookfunction","getrawmetatable","setreadonly","getnamecallmethod","newcclosure"}
    local missing={}
    for _,v in ipairs(critical) do if type(env[v])~="function" then table.insert(missing,v) end end
    if #missing>0 then
        game.Players.LocalPlayer:Kick(string.format("\n[ZILI SECURITY: FATAL ERROR]\n\nExecutor [%s] missing:\n- %s\n\nPlease upgrade your executor.",name,table.concat(missing,"\n- ")))
        task.wait(9e9); return
    end

    local deps={"hookmetamethod","hookfunction","getrawmetatable","setreadonly","getnamecallmethod","newcclosure","cloneref","fireproximityprompt","getconnections","readfile","writefile","isfile","makefolder","isfolder","getgenv","identifyexecutor","setclipboard","request"}
    local sup=0
    for _,v in ipairs(deps) do
        if type(env[v])=="function" or (v=="request" and (type(env.request)=="function" or type(env.http)=="table")) then sup=sup+1 end
    end
    local pct=math.floor((sup/#deps)*100)

    local TS=game:GetService("TweenService")
    local sg=NEW("ScreenGui",{Name="ZiliDiagnostic"},game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))
    local frame=NEW("Frame",{Size=UDim2.new(0,268,0,104),Position=UDim2.new(1,20,1,-228),BackgroundColor3=BG1,BorderSizePixel=0},sg)
    CORNER(8,frame)
    STROKE(GOLD,1.5,0,frame)

    NEW("TextLabel",{Text="⚡  ZILI HUB COMPATIBILITY",Size=UDim2.new(1,-20,0,24),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,TextColor3=GOLD2,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},frame)
    NEW("TextLabel",{Text="Executor: "..name,Size=UDim2.new(1,-20,0,18),Position=UDim2.new(0,12,0,28),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},frame)

    local barBg=NEW("Frame",{Size=UDim2.new(1,-24,0,5),Position=UDim2.new(0,12,0,56),BackgroundColor3=C(20,18,42)},frame); CORNER(3,barBg)
    local barFill=NEW("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=GOLD},barBg); CORNER(3,barFill)
    NEW("TextLabel",{Text="Support Score: "..pct.."%",Size=UDim2.new(1,-20,0,18),Position=UDim2.new(0,12,0,68),BackgroundTransparency=1,TextColor3=TEXT2,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},frame)

    TS:Create(frame,TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(1,-288,1,-228)}):Play()
    task.wait(0.55)
    TS:Create(barFill,TweenInfo.new(1.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.new(pct/100,0,1,0)}):Play()
    task.delay(7,function()
        TS:Create(frame,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.new(1,20,1,-228)}):Play()
        task.wait(0.5); sg:Destroy()
    end)
end

task.spawn(RunExecutorDiagnostics)
