-- ==========================================
-- AUTO CUPID V14
-- Game: GET BETTER OUT | Cupid Dungeon
-- Changes vs V13:
--   [1] Above-head positioning for all zones (removed underground offset)
--   [2] Mera Ultra dodge: 100 studs sideways on meraUltMax attribute
--   [3] Removed anti-stun logic and all print statements
--   [4] Lightning: jump +10 studs on damage while lightning present
--   [5] Smart block: Firefly auto-block, instant resume after skill ends
--   [6] New skill tracking: Hiken (block), Flame Pillar (dodge 75 studs)
--   [7] Code cleanup: removed unused variables and dead code
--   [8] Full English localization
-- ==========================================

local WebhookURL  = "https://discord.com/api/webhooks/1472994959404564490/D2gxRseTIKywjtkfRV8xvl1ra2fJ5rVRKtmJYIu23LRIXf_4wD6pbuto07WNzD20DVG4"
local LogoZiLi    = "https://cdn.discordapp.com/attachments/1482474210243907747/1482474407300698132/0f77b7f8-7648-4aa3-bf67-545da725301a.png"
local NormalThumb = "https://api.rblx.solutions/v1/asset/thumbnail/108561234878560"

local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local Player            = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM               = game:GetService("VirtualInputManager")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

-- ==========================================
-- [0] SESSION ID — PHẢI ĐỨNG ĐẦU
-- ==========================================
if _G.CupidHeartbeat then pcall(function() _G.CupidHeartbeat:Disconnect() end) end
if _G.CupidStepped    then pcall(function() _G.CupidStepped:Disconnect()    end) end

_G.DungeonScriptID = (_G.DungeonScriptID or 0) + 1
local currentScriptID = _G.DungeonScriptID

_G.AutoDungeon       = true
_G.IsProcessingFruit = false
_G.EndGameStarted    = false
_G.GoToPortal        = false
_G.SkillBlocking     = false

-- ==========================================
-- [1] BẢO VỆ TỐI THƯỢNG
-- ==========================================
local function CheckPlayers()
    if #Players:GetPlayers() > 1 then
        Player:Kick("You are banned. if you think this is a false ban, please contact the support team via discord with sufficient evidence.")
    end
end
Players.PlayerAdded:Connect(CheckPlayers)
CheckPlayers()

-- ==========================================
-- [2] AUTO EQUIP TITLE
-- ==========================================
task.spawn(function()
    pcall(function()
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Titles"):InvokeServer("Cupid's Nemesis")
    end)
end)

-- ==========================================
-- [3] DATA
-- ==========================================
local RareImages = {
    ["Prestige Cupid's Chakram"]  = true,
    ["Cupid Queen's Maid Outfit"] = true,
    ["Leo's Inferno Hagoromo"]    = true,
    ["Cupid's All Seeing Eye"]    = true,
}
local NormalItems = {
    "Cupid's Harp","Leo's Blazing Scarf","Love Shades","Cupid's Wand",
    "Love Boppers Headband","Cupid's Battleaxe","Leo's Blazing Regalia",
    "Virtuous Cupid Queen's Wings","Maid Outfit","SP Reset Essence",
    "Virtuous Cupid Queen's Outfit","Cupid's Chakram",
}
local VIP_Fruits   = {"dragon","soul","mochi","venom","tori","pteranodon","ope","buddha","pika","mera","yami","smoke","kage","paw","goru","yuki","magu","suna","goro","hie","gura","zushi"}
local TRASH_Fruits = {"spin","suke","kilo","heal","bari","mero","horo","yomi","bomb","gomu","kira","spring"}

-- ==========================================
-- [4] BIẾN SESSION
-- ==========================================
local DungeonStartTime      = tick()
local DungeonClearTimeStr   = "00:00"
local SessionItems          = {}
local ProcessedItems        = {}
local ProcessedLabels       = setmetatable({}, {__mode = "k"})
local WebhookSentForSession = false

-- ==========================================
-- [5] ANTI KNOCKOUT HOOK
-- ==========================================
if not _G.AntiKnockoutHook then
    _G.AntiKnockoutHook = true
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "FireServer" then
                if self.Name == "KnockedOut" or self.Name == "Ragdoll"
                or self.Name == "Zombie"      or self.Name == "Knock" then
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
end

-- ==========================================
-- [6] WEBHOOK
-- ==========================================
local function SendWebhook()
    if WebhookSentForSession then return end
    WebhookSentForSession = true

    local rareDrops, vipDrops, normalDrops = {}, {}, {}
    local shouldPing = false

    for _, item in ipairs(SessionItems) do
        if item:match("%[ RARE ITEM %]") then
            table.insert(rareDrops, item); shouldPing = true
        elseif item:match("VIP Fruit") then
            table.insert(vipDrops, item); shouldPing = true
        else
            table.insert(normalDrops, item)
        end
    end

    local fields = {}
    if #rareDrops > 0 then
        local lines = ""
        for _, v in ipairs(rareDrops) do lines = lines .. "+ " .. v .. "\n" end
        table.insert(fields, {name = "✨  RARE DROP", value = "```diff\n" .. lines .. "```", inline = false})
    end
    if #vipDrops > 0 then
        local lines = ""
        for _, v in ipairs(vipDrops) do lines = lines .. "+ " .. v .. "\n" end
        table.insert(fields, {name = "🍑  VIP Fruit", value = "```diff\n" .. lines .. "```", inline = false})
    end
    if #normalDrops > 0 then
        local lines = ""
        for _, v in ipairs(normalDrops) do lines = lines .. "  " .. v .. "\n" end
        table.insert(fields, {name = "🎁  Normal Drops", value = "```\n" .. lines .. "```", inline = false})
    end
    if #SessionItems == 0 then
        table.insert(fields, {name = "🎁  Session Drops", value = "```diff\n- No Items or Fruits dropped```", inline = false})
    end
    table.insert(fields, {
        name  = "📊  Statistics",
        value = "```\nRare   : " .. #rareDrops
              .. "\nVIP    : " .. #vipDrops
              .. "\nNormal : " .. #normalDrops
              .. "\nTotal  : " .. #SessionItems .. "```",
        inline = true,
    })

    local embedTitle
    if #rareDrops > 0 and #vipDrops > 0 then embedTitle = "🔥  RARE + VIP DROPPED !!!"
    elseif #rareDrops > 0                 then embedTitle = "✨  RARE ITEM DROPPED !!!"
    elseif #vipDrops > 0                  then embedTitle = "🍑  VIP FRUIT DROPPED !!!"
    else                                       embedTitle = "🎁  Dungeon Cleared" end

    local payload = {
        embeds = {{
            author      = {name = "⚔️  Cupid Dungeon  •  Auto Farm", icon_url = LogoZiLi},
            title       = embedTitle,
            color       = shouldPing and 0xFF2222 or 0xFFB347,
            description = "━━━━━━━━━━━━━━━━━━━━━━\n"
                .. "👤  **Player:** ||" .. Player.Name .. "||\n"
                .. "⏱️  **Clear Time:** `" .. DungeonClearTimeStr .. "`\n"
                .. "🗺️  **Map:** `Cupid Dungeon`\n"
                .. "━━━━━━━━━━━━━━━━━━━━━━",
            fields      = fields,
            thumbnail   = {url = NormalThumb},
            footer      = {text = "ZiLi Hub  •  " .. os.date("%d/%m/%Y  %H:%M:%S"), icon_url = LogoZiLi},
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
    if shouldPing then payload["content"] = "@everyone 🚨 RARE DROP!" end

    local req = (syn and syn.request) or (http and http.request)
             or http_request or (fluxus and fluxus.request) or request
    if req then
        task.spawn(function()
            pcall(function()
                req({ Url = WebhookURL, Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload) })
            end)
        end)
    end
end

-- ==========================================
-- [7] RADAR TRACK ĐỒ
-- ==========================================
task.spawn(function()
    local pGui  = Player:WaitForChild("PlayerGui", 9e9)
    local notif = pGui:WaitForChild("Notifications", 9e9)

    local function CheckItemText(label)
        if not label or not label:IsA("TextLabel") then return end
        if not ProcessedLabels[label] then ProcessedLabels[label] = {} end

        local function parseText()
            local txt = string.lower(string.gsub(label.Text, "<[^>]+>", ""))
            if txt == "" then return end
            for rareName in pairs(RareImages) do
                if string.find(txt, string.lower(rareName), 1, true) then
                    if not ProcessedLabels[label][rareName] then
                        ProcessedLabels[label][rareName] = true
                        table.insert(SessionItems, rareName .. " [ RARE ITEM ]")
                    end
                end
            end
            for _, normalName in ipairs(NormalItems) do
                if string.find(txt, string.lower(normalName), 1, true) then
                    if not ProcessedLabels[label][normalName] then
                        ProcessedLabels[label][normalName] = true
                        table.insert(SessionItems, normalName .. " [ Normal Item ]")
                    end
                end
            end
        end

        parseText()
        local conn = label:GetPropertyChangedSignal("Text"):Connect(parseText)
        label.AncestryChanged:Connect(function(_, parent) if not parent then conn:Disconnect() end end)
    end

    local function SetupTracker(frameName)
        local frame = notif:FindFirstChild(frameName)
        if not frame then return end
        for _, v in ipairs(frame:GetChildren()) do CheckItemText(v) end
        frame.ChildAdded:Connect(CheckItemText)
    end

    SetupTracker("Frame"); SetupTracker("Frame2")
    notif.ChildAdded:Connect(function(child)
        if child.Name == "Frame" or child.Name == "Frame2" then SetupTracker(child.Name) end
    end)
end)

-- ==========================================
-- [8] AUTO REPLAY (V4 FIX)
-- Decompile cho thấy:
--   - Nút là ImageButton có attribute "buttonValue"
--   - prompt:GetAttribute("isServer") == true → FireServer
--   - Ngược lại → clientEvent:Fire(val)
--   - RemoteEvent nằm trong chính prompt (script.Parent của code gốc)
-- ==========================================
task.spawn(function()
    local isReplaying = false

    -- Find replay button (matches decompile structure)
    local function FindReplayButton()
        local prompt = Player.PlayerGui:FindFirstChild("ConfirmationPrompt")
        if not prompt then return nil, nil, nil end
        if prompt:IsA("ScreenGui") and not prompt.Enabled then return nil, nil, nil end

        local main = prompt:FindFirstChild("Main")
        if not main or (main:IsA("GuiObject") and not main.Visible) then return nil, nil, nil end

        local options = main:FindFirstChild("OptionsFrame")
        if not options then return nil, nil, nil end

        -- V4: Scan ImageButton như trong decompile
        local targetBtn = nil
        for _, child in ipairs(options:GetChildren()) do
            if child:IsA("ImageButton") then
                local bv = child:GetAttribute("buttonValue")
                if bv then
                    local bvLow = tostring(bv):lower()
                    -- Ưu tiên nút replay/again/play
                    if bvLow:match("replay") or bvLow:match("again") or bvLow:match("play") then
                        targetBtn = child; break
                    end
                    if not targetBtn then targetBtn = child end  -- fallback: nút đầu tiên có buttonValue
                end
            end
        end
        -- Fallback: tìm theo tên (V3 compat)
        if not targetBtn then
            targetBtn = options:FindFirstChild("Replay")
                     or options:FindFirstChild("PlayAgain")
                     or options:FindFirstChild("Again")
        end

        return targetBtn, prompt, main
    end

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and not isReplaying then
            pcall(function()
                local btn, prompt, main = FindReplayButton()
                if btn then
                    isReplaying = true
                    task.wait(1.5)

                    local val      = btn:GetAttribute("buttonValue") or btn.Name
                    local isServer = prompt:GetAttribute("isServer")  -- bool từ decompile
                    local remote   = prompt:FindFirstChild("RemoteEvent")

                    local fired = false
                    if remote then
                        if isServer == true then
                            pcall(function() remote:FireServer(val) end)
                            fired = true
                        else
                            local clientEvent = prompt:FindFirstChild("clientEvent")
                            if clientEvent then
                                pcall(function() clientEvent:Fire(val) end)
                                fired = true
                            else
                                pcall(function() remote:FireServer(val) end)
                                fired = true
                            end
                        end
                    end

                    if not fired then
                        -- No RemoteEvent — try nil instances then VIM click
                        local nilFired = false
                        if getnilinstances then
                            for _, v in next, getnilinstances() do
                                if v:IsA("RemoteEvent") and v.Parent == nil then
                                    pcall(function() v:FireServer(val) end)
                                    nilFired = true
                                end
                            end
                        end
                        if nilFired then
                            -- nil remote fired
                        else
                            pcall(function()
                                local pos  = btn.AbsolutePosition
                                local size = btn.AbsoluteSize
                                local cx   = pos.X + size.X / 2
                                local cy   = pos.Y + size.Y / 2
                                VIM:SendMouseButtonEvent(cx, cy, 0, true,  game, 1)
                                task.wait(0.05)
                                VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                            end)
                        end
                    end

                    -- Ẩn prompt để không re-trigger
                    if prompt:IsA("ScreenGui") then prompt.Enabled = false end
                    if main:IsA("GuiObject")   then main.Visible   = false end

                    task.wait(5)
                    isReplaying = false
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- [9] HÀM TIỆN ÍCH
-- ==========================================
local function IsPotentialFruit(name)
    local n = name:lower()
    if n:match("fruit") or n == "tool" then return true end
    for _, v in ipairs(VIP_Fruits)   do if n:match(v) or n == v then return true end end
    for _, t in ipairs(TRASH_Fruits) do if n:match(t) or n == t then return true end end
    return false
end

-- ==========================================
-- [10] COMBAT CONFIG & STATE
-- ==========================================
local MoveSpeed          = 90
local AttackOffset       = 10.2  -- distance above mob head (all zones)
local SearchRadius       = 800
local WaitSpawnTime      = 6
local DangerRadius       = 45
local EvadeDistance      = 60

local EVADE_ENTEI        = 130
local EVADE_FLAME_PILLAR = 75

local MAX_DT             = 0.1
local MAX_STEP_PER_FRAME = 8
local MAX_STEP_Y_PER_FRAME = 0.7

local DODGE_RETURN_WAIT  = 1.5

local Zone5Points = {
    Vector3.new(-1166.94, 442.27, -3332.41),
    Vector3.new(-995.78,  442.31, -3331.45),
    Vector3.new(-962.64,  442.04, -3084.11),
    Vector3.new(-1135.6,  442.67, -3102.46),
}
local EndPortalPos    = Vector3.new(-1097.87, 672.92, -5379.12)
local Z5Index         = 1

local TargetCFrame      = nil
local CurrentTargetRoot = nil
local IsReadyToAttack   = false
local CurrentZoneIndex  = 1
local ZoneState         = "FLYING"
local PreviousZoneState = "FLYING"
local Timer             = 0
local DodgeTimer        = 0
local CachedZoneFloors  = {}

local IgnoredHazards = setmetatable({}, {__mode = "k"})
local CurrentHazard  = {Type = "None", Position = nil, Instance = nil, MinDist = DangerRadius, Action = "DODGE"}
local CurrentLava    = {Part = nil, Prompt = nil}
local IsFarmingReady    = false
local HasWaitedForLoad  = false

-- Mera Ultra dodge flag
local _meraUltDodging = false

-- ── FIX V6: FakePlatform — tàng hình, size lớn hơn, CanCollide đúng
-- Platform theo chân nhân vật mọi lúc.
-- Khi -90° tilt (IsReadyToAttack): body nằm ngang → lowest world Y ≈ HRP.Y
--   → đặt platform tại root.Y - 0.6 (sát dưới body nằm ngang)
-- Khi đứng bình thường: feet ≈ root.Y - 3.2
--   → đặt platform tại root.Y - 3.7 (top = root.Y - 3.2)
-- Cả 2 trường hợp đều trong 15 studs từ character → qua "Distance from Floor" check
local fakePlatform = workspace:FindFirstChild("CupidFakePlatform")
if fakePlatform then fakePlatform:Destroy() end  -- destroy old platform if present
fakePlatform              = Instance.new("Part")
fakePlatform.Name         = "CupidFakePlatform"
fakePlatform.Size         = Vector3.new(22, 1, 22)
fakePlatform.Anchored     = true
fakePlatform.CanCollide   = true
fakePlatform.Transparency = 1        -- V6: tàng hình hoàn toàn
fakePlatform.CastShadow   = false
fakePlatform.Material     = Enum.Material.SmoothPlastic
fakePlatform.Parent       = workspace

-- ==========================================
-- [5-A] STAMINA SPOOF — V7 ALWAYS-ON
-- V7: Fire liên tục mọi lúc (lobby + dungeon + bất kỳ đâu)
--   • Không có guard IsFarmingReady → không bao giờ ngừng
--   • Không gọi StopStaminaSpoof khi vào dungeon nữa
--   • Case-insensitive fetch giữ nguyên
--   • Dual-fire + task.defer giữ nguyên
-- ==========================================
local Events   = ReplicatedStorage:WaitForChild("Events", 5)

local function FindEventCI(parent, targetName)
    if not parent then return nil end
    local lower = targetName:lower()
    local exact = parent:FindFirstChild(targetName)
    if exact then return exact end
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name:lower() == lower then return child end
    end
    return nil
end

local TakeStam = Events and FindEventCI(Events, "takestam")

-- V7: Chạy 1 lần duy nhất, không bao giờ stop, không cần Start/Stop
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        -- Re-fetch if nil after zone reload
        if not TakeStam or not TakeStam.Parent then
            pcall(function()
                local ev = ReplicatedStorage:FindFirstChild("Events")
                if ev then TakeStam = FindEventCI(ev, "takestam") end
            end)
        end
        if TakeStam and TakeStam.Parent then
            pcall(function() TakeStam:FireServer(0.545, "dash") end)
            task.defer(function()
                pcall(function()
                    if TakeStam and TakeStam.Parent then
                        TakeStam:FireServer(0.545, "dash")
                    end
                end)
            end)
        end
        task.wait(0.05)
    end
end)

-- Stub: giữ lại để không bị lỗi nếu code cũ gọi
local function StartStaminaSpoof() end
local function StopStaminaSpoof() end

-- ==========================================
-- [5-B] SKILL BLOCK TRIGGER
-- ==========================================
local function TriggerSkillBlock(weaponName, duration)
    if _G.SkillBlocking then return end
    _G.SkillBlocking = true

    task.spawn(function()
        pcall(function()
            if fakePlatform and fakePlatform.Parent then
                fakePlatform.CFrame = CFrame.new(0, -9999, 0)
            end

            local r0 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if r0 then
                r0.RotVelocity = Vector3.zero
                pcall(function() r0.AssemblyAngularVelocity = Vector3.zero end)
            end

            local BlockEvent = ReplicatedStorage:WaitForChild("Events", 3)
                :WaitForChild("Block", 3)
            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(true, weaponName or "Melee", false)
            else
                BlockEvent:FireServer(true, weaponName or "Melee", false)
            end
            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)

            task.wait(duration or 0.5)

            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(false, weaponName or "Melee", false)
            else
                BlockEvent:FireServer(false, weaponName or "Melee", false)
            end
            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)

            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            for i = 1, 5 do
                if r and r.Parent then
                    r.RotVelocity = Vector3.zero
                    pcall(function() r.AssemblyAngularVelocity = Vector3.zero end)
                end
                task.wait(0.03)
            end
        end)

        _G.SkillBlocking = false
    end)
end

-- ==========================================
-- [11] HÀM TIỆN ÍCH COMBAT
-- ==========================================
-- V10 FIX: Lưu boxCenter per-zone để Heartbeat dùng khi refY = nil
local CachedZoneBoxCenters = {}

local function GetZoneFloor(zoneIndex, boxCenter)
    -- Cache boxCenter so Heartbeat can reference it later
    if boxCenter then CachedZoneBoxCenters[zoneIndex] = boxCenter end
    if CachedZoneFloors[zoneIndex] then return CachedZoneFloors[zoneIndex] end
    local center = boxCenter or CachedZoneBoxCenters[zoneIndex]
    if not center then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        Player.Character, fakePlatform,
        workspace:FindFirstChild("Effects"),
        workspace:FindFirstChild("Enemies"),
    }
    local result = workspace:Raycast(center, Vector3.new(0, -300, 0), params)
    if result then
        CachedZoneFloors[zoneIndex] = result.Position.Y
        return result.Position.Y
    end
    -- V10 FIX: cache fallback → Heartbeat đọc cache không còn nil
    local fallback = center.Y - 10
    CachedZoneFloors[zoneIndex] = fallback
    return fallback
end

local function GetRoot(m)
    if not m then return nil end
    if m:IsA("BasePart") then return m end
    return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

-- V4: Kiểm tra mob còn sống — hỗ trợ Humanoid lẫn barrelHP (statue)
local function IsMobAlive(mob)
    local hum = mob:FindFirstChildOfClass("Humanoid") or mob:FindFirstChild("Humanoid", true)
    if hum then return hum.Health > 0.1 end
    local barrelHP = mob:FindFirstChild("barrelHP", true)
    if barrelHP and barrelHP:IsA("ValueBase") then
        local v = tonumber(barrelHP.Value)
        return v ~= nil and v > 0
    end
    return false
end

-- V4: GetMobsInZone với cache 80ms + workspace-wide fallback + statue scan
local MobSearchCache = {mobs = {}, time = 0, zone = -1}
local MOB_CACHE_TTL  = 0.08

local function GetMobsInZone(zonePos)
    -- Use cache if still valid for this zone
    if MobSearchCache.zone == CurrentZoneIndex
    and tick() - MobSearchCache.time < MOB_CACHE_TTL then
        local valid = {}
        for _, m in ipairs(MobSearchCache.mobs) do
            if m and m.Parent and IsMobAlive(m) then table.insert(valid, m) end
        end
        MobSearchCache.mobs = valid
        return valid
    end

    local mobs = {}
    local currentSearchRadius = (CurrentZoneIndex == 8) and 1500 or SearchRadius

    -- Zone 8: ưu tiên scan statue trước
    if CurrentZoneIndex == 8 then
        local foundStatue = false
        pcall(function()
            local statueFolders = {}
            local envFolder = workspace:FindFirstChild("Env")
            if envFolder then
                local sf = envFolder:FindFirstChild("Statues")
                if sf then table.insert(statueFolders, sf) end
                for _, c in pairs(envFolder:GetChildren()) do
                    if c.Name:lower():match("statue") then table.insert(statueFolders, c) end
                end
            end
            -- Scan thẳng workspace cho statue
            for _, c in pairs(workspace:GetChildren()) do
                if c.Name:lower():match("statue") then table.insert(statueFolders, c) end
            end
            for _, folder in pairs(statueFolders) do
                if folder then
                    local list = folder:IsA("Model") and {folder} or folder:GetChildren()
                    for _, statue in pairs(list) do
                        if statue:IsA("Model") then
                            local sRoot = GetRoot(statue)
                            if sRoot and IsMobAlive(statue) then
                                table.insert(mobs, statue)
                                foundStatue = true
                            end
                        end
                    end
                end
            end
        end)
        if foundStatue and #mobs > 0 then
            MobSearchCache = {mobs = mobs, time = tick(), zone = CurrentZoneIndex}
            return mobs
        end
    end

    -- Standard scan: nhiều folder + zone folder + 1 cấp grandchild
    local possibleFolders = {}
    for _, name in ipairs({"Enemies","Mob","Mobs","NPCs","Boss","Enemy"}) do
        local f = workspace:FindFirstChild(name)
        if f then table.insert(possibleFolders, f) end
    end
    pcall(function()
        local zf = workspace.Effects.Zones["Zone" .. CurrentZoneIndex]
        if zf then table.insert(possibleFolders, zf) end
    end)

    local seen = {}
    for _, folder in pairs(possibleFolders) do
        if folder then
            local checkList = {}
            for _, c in pairs(folder:GetChildren()) do
                table.insert(checkList, c)
                -- Một cấp sâu hơn để bắt nested folders
                if c:IsA("Folder") or c:IsA("Model") then
                    for _, cc in pairs(c:GetChildren()) do
                        table.insert(checkList, cc)
                    end
                end
            end
            for _, v in pairs(checkList) do
                if v:IsA("Model") and not seen[v] then
                    local hum = v:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0.1 then
                        local root = GetRoot(v)
                        if root then
                            local xzDist = (Vector2.new(root.Position.X, root.Position.Z)
                                         - Vector2.new(zonePos.X, zonePos.Z)).Magnitude
                            if xzDist <= currentSearchRadius then
                                table.insert(mobs, v)
                                seen[v] = true
                            end
                        end
                    end
                end
            end
        end
    end

    MobSearchCache = {mobs = mobs, time = tick(), zone = CurrentZoneIndex}

    -- Ưu tiên "dungeon gun user" lên đầu (zone 1-4)
    if CurrentZoneIndex <= 4 and #mobs > 1 then
        table.sort(mobs, function(a, b)
            local an = a.Name:lower()
            local bn = b.Name:lower()
            local aGun = an:find("gun", 1, true) ~= nil
            local bGun = bn:find("gun", 1, true) ~= nil
            if aGun ~= bGun then return aGun end
            return false
        end)
    end

    return mobs
end

-- FIX: priority scan (sword/blade > axe > katana) + pcall bảo vệ EquipTool
local WEAPON_PRIORITY = {
    {pattern = "sword",  score = 1},
    {pattern = "blade",  score = 1},
    {pattern = "axe",    score = 2},
    {pattern = "katana", score = 3},
}
local function IsWeapon(name)
    local n = name:lower()
    for _, w in ipairs(WEAPON_PRIORITY) do
        if n:match(w.pattern) then return true, w.score end
    end
    return false, math.huge
end

local function CheckAndEquipWeapon()
    if _G.IsProcessingFruit then return nil end
    local char = Player.Character
    if not char then return nil end
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        local ok, _ = IsWeapon(currentTool.Name)
        if ok then return currentTool end
    end
    local bp = Player:FindFirstChild("Backpack")
    if not bp then return currentTool end

    -- FIX: scan toàn bộ backpack, chọn vũ khí ưu tiên cao nhất (score thấp nhất)
    local best, bestScore = nil, math.huge
    for _, t in pairs(bp:GetChildren()) do
        if t:IsA("Tool") then
            local ok, score = IsWeapon(t.Name)
            if ok and score < bestScore then
                best = t; bestScore = score
            end
        end
    end
    if best then
        local hum = char:FindFirstChild("Humanoid")
        -- Wrapped in pcall to avoid silent fail when humanoid is stunned/ragdolled
        if hum then pcall(function() hum:EquipTool(best) end) end
    end
    return best
end

local function GetAttackAnim(weaponName, combo)
    if _G.IsProcessingFruit then return "Melee", nil end
    local wType = "Melee"
    local anim  = nil
    local swordModules = ReplicatedStorage:FindFirstChild("Modules")
        and ReplicatedStorage.Modules:FindFirstChild("SwordHandle")
        and ReplicatedStorage.Modules.SwordHandle:FindFirstChild("Swords")

    if swordModules and swordModules:FindFirstChild(weaponName) then
        wType = "Sword"
        local folder = swordModules[weaponName]:FindFirstChild("Slashes")
        if folder then
            anim = folder:FindFirstChild("Slash"..combo)
                or folder:FindFirstChild("GroundSlash"..combo)
                or folder:FindFirstChild("Swing"..combo)
            if not anim then
                for _, a in pairs(folder:GetChildren()) do
                    if string.find(a.Name, tostring(combo)) then anim = a; break end
                end
            end
        end
        return wType, anim
    end

    -- FIX: nếu tên weapon match sword/blade/katana/axe → dùng "Sword" type khi fallback
    -- Tránh bị tính damage theo melee scaling khi cầm katana không có folder riêng
    local isBladeWeapon = (function()
        local n = weaponName:lower()
        return n:match("sword") or n:match("blade") or n:match("katana") or n:match("axe")
    end)()

    wType  = isBladeWeapon and "Sword" or weaponName
    local folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild(weaponName)
    if not folder then
        -- Thử tìm folder "Sword" trước nếu là blade weapon
        if isBladeWeapon then
            folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild("Sword")
        end
        if not folder then
            folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild("Melee")
            if not isBladeWeapon then wType = "Melee" end
        end
    end
    if folder then
        anim = folder:FindFirstChild("Punch"..combo)
            or folder:FindFirstChild("M1_"..combo)
            or folder:FindFirstChild("Kick"..combo)
            or folder:FindFirstChild("Slash"..combo)
        if not anim then
            for _, a in pairs(folder:GetChildren()) do
                if string.find(a.Name, tostring(combo)) then anim = a; break end
            end
        end
    end
    return wType, anim
end

-- ==========================================
-- [12] DUNGEON LOCATION DETECTION
-- ==========================================
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon then
            pcall(function()
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local islands = workspace:FindFirstChild("Islands")
                    if islands then
                        local lobby   = islands:FindFirstChild("Lobby")
                        local dungeon = islands:FindFirstChild("Cupid Dungeon")
                        local getPos  = function(inst)
                            if not inst then return nil end
                            if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart.Position end
                            local part = inst:FindFirstChildWhichIsA("BasePart", true)
                            if part then return part.Position end
                        end
                        local lPos  = getPos(lobby)
                        local dPos  = getPos(dungeon)
                        local rPos  = root.Position
                        local lDist = lPos and (Vector2.new(lPos.X,lPos.Z) - Vector2.new(rPos.X,rPos.Z)).Magnitude or math.huge
                        local dDist = dPos and (Vector2.new(dPos.X,dPos.Z) - Vector2.new(rPos.X,rPos.Z)).Magnitude or math.huge

                        if dDist < lDist and dDist < 5000 then
                            if not HasWaitedForLoad then
                                HasWaitedForLoad      = true
                                IsFarmingReady        = false
                                DungeonStartTime      = tick()
                                SessionItems          = {}
                                ProcessedItems        = {}
                                ProcessedLabels       = setmetatable({}, {__mode = "k"})
                                WebhookSentForSession = false
                                _G.EndGameStarted     = false
                                _G.GoToPortal         = false
                                _G.IsProcessingFruit  = false
                                _G.SkillBlocking      = false
                                MobSearchCache        = {mobs = {}, time = 0, zone = -1}
                                CachedZoneFloors      = {}
                                StopStaminaSpoof()
                                task.wait(5)
                                CurrentZoneIndex = 1
                                ZoneState        = "FLYING"
                                IsFarmingReady   = true
                                StartStaminaSpoof()
                            end
                        else
                            IsFarmingReady   = false
                            HasWaitedForLoad = false
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- [13] AUTO EQUIP HAKI
-- ==========================================
task.spawn(function()
    local lastChar = nil
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                if char and char.Parent and lastChar ~= char then
                    lastChar = char
                    task.wait(2.5)
                    local hasHaki = false
                    for _, v in pairs(char:GetDescendants()) do
                        if v.Name:match("Buso") or v.Name:match("Haki") or v.Name:match("HasBuso") then
                            hasHaki = true; break
                        end
                    end
                    if not hasHaki then ReplicatedStorage.Events.Haki:FireServer("Buso") end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- [13-B] MAP OPTIMIZE + SKILL HIDE
-- FIX: _mapOptimized reset khi script re-run
-- Gọi ngay khi load script (không chờ dungeon entry)
-- ==========================================
local _mapOptimized    = false  -- reset mỗi lần load script (không dùng _G)
local _effectHiddenSet = setmetatable({}, {__mode = "k"})

local function HideVisualOfInst(v)
    if _effectHiddenSet[v] then return end
    _effectHiddenSet[v] = true
    pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")
        or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            v.Enabled = false
        elseif v:IsA("SpecialMesh") then
            v.Scale = Vector3.zero
        elseif v:IsA("BasePart") and not v:IsA("Terrain") then
            v.LocalTransparencyModifier = 1
            v.CastShadow = false
            v.CanCollide = false  -- noclip thêm cho effect parts
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("Sound") then
            v.Volume = 0  -- tắt âm thanh effect → giảm CPU audio
        end
    end)
end

local function HideFolderEffects(folder)
    if not folder then return end
    pcall(function()
        for _, v in ipairs(folder:GetDescendants()) do
            HideVisualOfInst(v)
        end
        folder.DescendantAdded:Connect(function(inst)
            task.defer(function() HideVisualOfInst(inst) end)
        end)
    end)
end

-- V10 FIX LEAK: disconnect map connections từ session cũ trước khi tạo mới
if _G.CupidMapConns then
    for _, c in ipairs(_G.CupidMapConns) do pcall(function() c:Disconnect() end) end
end
_G.CupidMapConns = {}

local function DoMapOptimize()
    if _mapOptimized then return end
    _mapOptimized = true
    task.spawn(function()

        -- [A] Lighting — tắt toàn bộ effect, giảm quality
        pcall(function()
            local L = game:GetService("Lighting")
            L.GlobalShadows    = false
            L.FogEnd           = 9e9
            L.Brightness       = 2
            L.ClockTime        = 14
            L.Ambient          = Color3.fromRGB(178, 178, 178)
            L.EnvironmentDiffuseScale  = 0
            L.EnvironmentSpecularScale = 0
            for _, v in ipairs(L:GetDescendants()) do
                if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect")
                or v:IsA("SunRaysEffect") or v:IsA("BloomEffect")
                or v:IsA("ColorCorrectionEffect") then
                    pcall(function() v.Enabled = false end)
                elseif v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
                    pcall(function() v:Destroy() end)
                end
            end
        end)

        -- [B] Render quality — thử TẤT CẢ các API executor có thể hỗ trợ
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function()
            UserSettings():GetService("UserGameSettings").SavedQualityLevel
                = Enum.SavedQualitySetting.QualityLevel1
        end)
        -- Executor-specific: setfflag / setsetting
        pcall(function() setfflag("DFIntDebugFRMQualityLevelOverride", "1") end)
        pcall(function() setsetting("Graphics Quality", 1) end)
        -- Camera clip distance giảm → ít object render
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then cam.MaxAxisFieldOfView = 70 end
        end)
        -- Tắt StreamingEnabled constraint (nếu script có quyền)
        pcall(function() workspace.StreamingEnabled = false end)
        -- Shadow distance cực thấp
        pcall(function()
            workspace:FindFirstChildOfClass("Terrain") -- luôn tồn tại
        end)

        -- [C] Terrain
        pcall(function()
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                t.Decoration        = false
                t.WaterWaveSize     = 0
                t.WaterWaveSpeed    = 0
                t.WaterReflectance  = 0
                t.WaterTransparency = 1
                t.CastShadow        = false
            end
        end)

        -- [D] Effects & Projectiles
        for _, fname in ipairs({"Effects", "Projectiles"}) do
            local f = workspace:FindFirstChild(fname)
            if f then HideFolderEffects(f) end
            local conn = workspace.ChildAdded:Connect(function(child)
                if child.Name == fname then
                    task.defer(function() HideFolderEffects(child) end)
                end
            end)
            table.insert(_G.CupidMapConns, conn)
        end

        -- [E] Workspace scan — tắt shadow/particle/trang trí
        -- V12: chạy trong coroutine chunked để không spike 1 frame
        task.spawn(function()
            local descs = workspace:GetDescendants()
            local CHUNK  = 200
            for i = 1, #descs, CHUNK do
                for j = i, math.min(i + CHUNK - 1, #descs) do
                    local desc = descs[j]
                    -- Skip character parts
                    if Player.Character and desc:IsDescendantOf(Player.Character) then continue end
                    pcall(function()
                        if desc:IsA("ParticleEmitter") or desc:IsA("Beam")
                        or desc:IsA("Trail") or desc:IsA("Fire")
                        or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                            desc.Enabled = false

                        elseif desc:IsA("BasePart") and not desc:IsA("Terrain") then
                            desc.CastShadow = false
                            -- V13: tất cả BasePart map → SmoothPlastic (loại bỏ texture render)
                            -- + tắt reflection/specular
                            desc.Material     = Enum.Material.SmoothPlastic
                            desc.Reflectance  = 0
                            if not desc.CanCollide then
                                desc.LocalTransparencyModifier = 1
                            end

                        elseif desc:IsA("Decal") or desc:IsA("Texture") then
                            -- Hide all decals/textures on map to reduce draw calls
                            desc.Transparency = 1

                        elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
                            -- Hide map GUIs (mob health bars, NPC names, etc.)
                            -- Only hide if not part of the character
                            desc.Enabled = false

                        elseif desc:IsA("Sound") then
                            if desc.Parent and not (desc.Parent == Player.Character) then
                                desc.Volume = 0
                            end

                        elseif desc:IsA("SpecialMesh") then
                            pcall(function() desc.LODFactor = 0 end)
                        end
                    end)
                end
                task.wait()
            end

            local connD = workspace.DescendantAdded:Connect(function(inst)
                if Player.Character and inst:IsDescendantOf(Player.Character) then return end
                task.defer(function()
                    pcall(function()
                        if inst:IsA("ParticleEmitter") or inst:IsA("Beam")
                        or inst:IsA("Trail") or inst:IsA("Fire")
                        or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                            inst.Enabled = false
                        elseif inst:IsA("BasePart") and not inst:IsA("Terrain") then
                            inst.CastShadow  = false
                            inst.Material    = Enum.Material.SmoothPlastic
                            inst.Reflectance = 0
                            if not inst.CanCollide then
                                inst.LocalTransparencyModifier = 1
                            end
                        elseif inst:IsA("Decal") or inst:IsA("Texture") then
                            inst.Transparency = 1
                        elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
                            inst.Enabled = false
                        end
                    end)
                end)
            end)
            table.insert(_G.CupidMapConns, connD)
        end)
    end)
end

-- Gọi ngay khi load script — không chờ dungeon entry
DoMapOptimize()

-- Chạy optimize ngay khi vào dungeon (gọi từ [12] sau IsFarmingReady = true)
-- Và auto re-hide khi có effect mới spawn (DescendantAdded đã connect trong HideFolderEffects)

-- ==========================================
-- [14] HAZARD SCANNER
-- ==========================================

-- Queue-based only for Enkai/Entei (wide area, one-shot spawn events)
local EnkaiDefs = {
    {pattern = "enkai",  evadeDist = EVADE_ENTEI, priority = 1},
    {pattern = "en_kai", evadeDist = EVADE_ENTEI, priority = 1},
    {pattern = "entei",  evadeDist = EVADE_ENTEI, priority = 1},
}

-- Active poll patterns — checked every scan tick against ALL workspace descendants
-- These spawn persistently and need re-detection each tick
local ActiveSkillDefs = {
    -- Flame Pillar: dodge 75 studs sideways
    {pattern = "flame_pillar",  action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "flamepillar",   action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "flame pillar",  action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "flamepilla",    action = "DODGE", evadeDist = EVADE_FLAME_PILLAR}, -- truncated name guard
    {pattern = "eruption",      action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "firepillar",    action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "pillar_dmg",    action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    -- Hiken: block in place
    {pattern = "hiken",         action = "BLOCK", evadeDist = 0},
    {pattern = "hi_ken",        action = "BLOCK", evadeDist = 0},
    {pattern = "fire_fist",     action = "BLOCK", evadeDist = 0},
    {pattern = "firefist",      action = "BLOCK", evadeDist = 0},
    {pattern = "hiken_dmg",     action = "BLOCK", evadeDist = 0},
    -- Firefly: block in place (active Effects scan below also catches this)
    {pattern = "firefly",       action = "BLOCK", evadeDist = 0},
    {pattern = "fire_fly",      action = "BLOCK", evadeDist = 0},
}

local IGNORE_NAME_PATTERNS = {
    "dmgind", "hitbox", "hurtbox", "indicator", "number",
    "billboard", "sfx", "sound", "particle", "debris",
    "decal", "highlight", "selection", "tag", "gui",
}

local ACTIVE_POLL_RADIUS = 200  -- scan within 200 studs for active skills

local function GetInstPos(inst)
    if not inst then return nil end
    local pos
    pcall(function()
        if inst:IsA("BasePart") then
            pos = inst.Position
        elseif inst:IsA("Model") then
            if inst.PrimaryPart then
                pos = inst.PrimaryPart.Position
            else
                local bp = inst:FindFirstChildWhichIsA("BasePart", true)
                if bp then pos = bp.Position end
            end
            if not pos then pos = inst:GetModelCFrame().Position end
        end
    end)
    return pos
end

-- Queue for Enkai/Entei only
local _newInstQueue = {}
local _checkedInsts = setmetatable({}, {__mode = "k"})

local _descAddedConn
_descAddedConn = workspace.DescendantAdded:Connect(function(inst)
    if _G.DungeonScriptID ~= currentScriptID then
        _descAddedConn:Disconnect(); return
    end
    if inst:IsA("BasePart") or inst:IsA("Model") then
        _newInstQueue[#_newInstQueue + 1] = inst
    end
end)

-- Drain queue for Enkai/Entei detection
local function DrainEnkaiScan(playerPos)
    if #_newInstQueue == 0 then return nil, nil, nil end
    local queue = _newInstQueue
    _newInstQueue = {}
    local bestDef, bestInst, bestPos
    local char = Player.Character
    for _, v in ipairs(queue) do
        if _checkedInsts[v] then continue end
        if not v:IsDescendantOf(workspace) then continue end
        if char and v:IsDescendantOf(char) then continue end
        _checkedInsts[v] = true
        local n = v.Name:lower()
        local skip = false
        for _, pat in ipairs(IGNORE_NAME_PATTERNS) do
            if n:find(pat, 1, true) then skip = true; break end
        end
        if skip then continue end
        local vPos = GetInstPos(v)
        if not vPos then continue end
        for _, def in ipairs(EnkaiDefs) do
            if n:match(def.pattern) then
                if not bestDef or def.priority < (bestDef.priority or 99) then
                    bestDef = def; bestInst = v; bestPos = vPos
                end
            end
        end
    end
    return bestDef, bestInst, bestPos
end

-- Active poll scan: checks workspace descendants each tick for persistent boss skills
-- No _checkedInsts — runs fresh every tick so skills are always detected while present
local function ActiveSkillScan(playerPos)
    local bestAction, bestEvadeDist, bestInst, bestPos
    local char = Player.Character
    -- Only scan when in boss zones
    if CurrentZoneIndex < 5 then return nil, nil, nil, nil end
    for _, v in ipairs(workspace:GetDescendants()) do
        if not v:IsDescendantOf(workspace) then continue end
        if char and v:IsDescendantOf(char) then continue end
        if not (v:IsA("BasePart") or v:IsA("Model")) then continue end
        if IgnoredHazards[v] then continue end
        local n = v.Name:lower()
        local skip = false
        for _, pat in ipairs(IGNORE_NAME_PATTERNS) do
            if n:find(pat, 1, true) then skip = true; break end
        end
        if skip then continue end
        local vPos = GetInstPos(v)
        if not vPos then continue end
        local dist = (Vector3.new(vPos.X, playerPos.Y, vPos.Z) - Vector3.new(playerPos.X, playerPos.Y, playerPos.Z)).Magnitude
        if dist > ACTIVE_POLL_RADIUS then continue end
        for _, def in ipairs(ActiveSkillDefs) do
            if n:match(def.pattern) then
                -- Prefer BLOCK over DODGE on tie; first match wins per priority
                if not bestAction then
                    bestAction = def.action
                    bestEvadeDist = def.evadeDist
                    bestInst = v
                    bestPos  = vPos
                end
                break
            end
        end
        if bestAction then break end  -- take first found, stop scanning
    end
    return bestAction, bestEvadeDist, bestInst, bestPos
end

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                -- Clean up expired ignores
                for obj, expireTime in pairs(IgnoredHazards) do
                    if tick() > expireTime or not obj:IsDescendantOf(workspace) then
                        IgnoredHazards[obj] = nil
                    end
                end

                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local playerPos      = root.Position
                local detectedHazard = "None"
                local hazardPos      = nil
                local hazardInst     = nil
                local hazardAction   = "DODGE"
                local hazardEvadeDist = EvadeDistance
                local foundLavaPart  = nil
                local foundLavaPrompt= nil

                -- ── ENKAI/ENTEI: queue-based (zone >= 5 only) ─────────────────
                if CurrentZoneIndex >= 5 then
                    local def, inst, pos = DrainEnkaiScan(playerPos)
                    if def and inst then
                        detectedHazard   = "Enkai"
                        hazardAction     = "DODGE"
                        hazardEvadeDist  = def.evadeDist
                        hazardInst       = inst
                        hazardPos        = pos or playerPos
                    end
                end

                -- ── ACTIVE SKILL POLL: Hiken / FlamePillar / Firefly ──────────
                -- Runs every tick, no _checkedInsts — always detects persistent skills
                if detectedHazard == "None" then
                    local action, evadeDist, inst, pos = ActiveSkillScan(playerPos)
                    if action and inst then
                        detectedHazard  = action == "BLOCK" and "ActiveBlock" or "ActiveDodge"
                        hazardAction    = action
                        hazardEvadeDist = evadeDist
                        hazardInst      = inst
                        hazardPos       = pos or playerPos
                    end
                end

                -- ── LAVA CURSE: all zones ─────────────────────────────────────
                if CurrentZoneIndex >= 5 then
                    local effectsFolder = workspace:FindFirstChild("Effects")
                    if effectsFolder then
                        for _, v in ipairs(effectsFolder:GetDescendants()) do
                            if not v:IsA("BasePart") and not v:IsA("Model") then continue end
                            local name = v.Name:lower()
                            if name:match("lava") and name:match("curse") then
                                local vPos = GetInstPos(v)
                                if vPos then
                                    local dist = (Vector3.new(vPos.X, playerPos.Y, vPos.Z)
                                               - Vector3.new(playerPos.X, playerPos.Y, playerPos.Z)).Magnitude
                                    if dist < 1500 then
                                        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        local part   = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                                        if part and prompt and prompt.Enabled then
                                            foundLavaPart   = part
                                            foundLavaPrompt = prompt
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                CurrentHazard.Type      = detectedHazard
                CurrentHazard.Position  = hazardPos
                CurrentHazard.Instance  = hazardInst
                CurrentHazard.MinDist   = hazardEvadeDist
                CurrentHazard.Action    = hazardAction
                CurrentLava.Part        = foundLavaPart
                CurrentLava.Prompt      = foundLavaPrompt
            end)
        end
        local scanInterval = IsFarmingReady and (
            CurrentZoneIndex >= 8 and 0.01 or
            CurrentZoneIndex >= 7 and 0.02 or
            CurrentZoneIndex >= 5 and 0.04 or 0.1
        ) or 0.1
        task.wait(scanInterval)
    end
end)

-- ==========================================
-- [14-B] MERA ULTRA WATCHER
-- meraUltMax active  → dodge 100 studs sideways, hold minimum 2.5s
-- meraUltMax → nil   → resume combat after hold expires
-- ==========================================
local _meraUltHoldUntil = 0  -- tick() timestamp when hold expires

local function HookLeoAttributes(leoModel)
    leoModel.AttributeChanged:Connect(function(attr)
        if attr ~= "meraUltMax" then return end
        local val = leoModel:GetAttribute("meraUltMax")
        if val ~= nil then
            -- Mera Ult activated — snap sideways 100 studs, lock for minimum 2.5s
            _meraUltDodging  = true
            _meraUltHoldUntil = tick() + 2.5
            local char = Player.Character
            local root  = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local right = root.CFrame.RightVector
                TargetCFrame      = CFrame.new(Vector3.new(
                    root.Position.X + right.X * 100,
                    root.Position.Y,
                    root.Position.Z + right.Z * 100
                ))
                IsReadyToAttack   = false
                CurrentTargetRoot = nil
            end
        else
            -- Attribute cleared — release only after minimum hold time
            task.delay(math.max(0, _meraUltHoldUntil - tick()), function()
                _meraUltDodging = false
                TargetCFrame    = nil
            end)
        end
    end)
end

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "Leo" and obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
        HookLeoAttributes(obj)
    end
end

local _leoWatchConn
_leoWatchConn = workspace.DescendantAdded:Connect(function(obj)
    if _G.DungeonScriptID ~= currentScriptID then
        _leoWatchConn:Disconnect(); return
    end
    if obj.Name == "Leo" and obj:IsA("Model") then
        task.wait(0.5)
        if obj:FindFirstChild("Humanoid") then HookLeoAttributes(obj) end
    end
end)
-- ==========================================
task.spawn(function()
    local lastZone      = 0
    local isHoldingLava = false

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                -- Invalidate mob cache on zone change
                if lastZone ~= CurrentZoneIndex then
                    lastZone = CurrentZoneIndex
                    MobSearchCache = {mobs = {}, time = 0, zone = -1}
                end

                local char = Player.Character
                if not char or not char.Parent then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                -- ── END GAME ────────────────────────────────────────────────
                if CurrentZoneIndex > 8 then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    StopStaminaSpoof()

                    if not _G.EndGameStarted then
                        _G.EndGameStarted = true
                        task.spawn(function()
                            if root then root.Velocity = Vector3.zero end
                            task.wait(2.5)

                            pcall(function()
                                _G.IsProcessingFruit = true
                                local bp  = Player:FindFirstChild("Backpack")
                                local hum = char and char:FindFirstChild("Humanoid")
                                if char and bp and hum then
                                    local tools = {}
                                    for _, v in ipairs(char:GetChildren()) do
                                        if v:IsA("Tool") and IsPotentialFruit(v.Name) then table.insert(tools, v) end
                                    end
                                    for _, v in ipairs(bp:GetChildren()) do
                                        if v:IsA("Tool") and IsPotentialFruit(v.Name) then table.insert(tools, v) end
                                    end
                                    for _, tool in ipairs(tools) do
                                        if not ProcessedItems[tool] then
                                            ProcessedItems[tool] = true
                                            pcall(function() hum:UnequipTools() end)
                                            task.wait(0.5)
                                            tool.Parent = char
                                            pcall(function() hum:EquipTool(tool) end)
                                            task.wait(2.5)
                                            pcall(function() ReplicatedStorage:WaitForChild("Events"):WaitForChild("FruitStorage"):InvokeServer(true) end)
                                            task.wait(0.5)

                                            local activeTool  = char:FindFirstChildOfClass("Tool") or tool
                                            local exactName   = activeTool.Name:lower()
                                            local displayName = activeTool.Name
                                            local isVIP       = false
                                            for _, vip in ipairs(VIP_Fruits) do
                                                if exactName:match(vip) or exactName == vip then isVIP = true; break end
                                            end
                                            if isVIP then
                                                pcall(function() ReplicatedStorage.Events.FruitStorage:InvokeServer("Store", activeTool) end)
                                                task.wait(1.5)
                                                if activeTool.Parent == char or activeTool.Parent == bp then
                                                    pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end)
                                                    table.insert(SessionItems, displayName .. " [ VIP Fruit - Dropped ]")
                                                else
                                                    table.insert(SessionItems, displayName .. " [ VIP Fruit - Stored ]")
                                                end
                                            else
                                                pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end)
                                                table.insert(SessionItems, displayName .. " [ Dropped ]")
                                            end
                                            pcall(function() hum:UnequipTools() end)
                                        end
                                    end
                                end
                            end)
                            _G.IsProcessingFruit = false

                            if not WebhookSentForSession then
                                local elapsed = tick() - DungeonStartTime
                                DungeonClearTimeStr = string.format("%02d:%02d", math.floor(elapsed/60), math.floor(elapsed%60))
                                SendWebhook()
                                task.wait(1.5)
                            end
                            _G.GoToPortal = true
                        end)
                    end

                    if _G.GoToPortal then
                        ZoneState    = "TO_PORTAL"
                        TargetCFrame = CFrame.new(EndPortalPos)
                    else
                        TargetCFrame = nil
                        if root then root.Velocity = Vector3.zero end
                    end
                    return
                end

                -- ── LAVA CURSE ──────────────────────────────────────────────
                local shouldAbsorbLava = false
                if CurrentLava.Part and CurrentLava.Prompt then
                    local lavaPos  = CurrentLava.Part.Position
                    local zonePart = nil
                    pcall(function() zonePart = workspace.Effects.Zones["Zone"..CurrentZoneIndex]:FindFirstChild("Zone") end)
                    if zonePart then
                        if (Vector2.new(lavaPos.X,lavaPos.Z) - Vector2.new(zonePart.Position.X,zonePart.Position.Z)).Magnitude <= 300 then
                            shouldAbsorbLava = true
                        end
                    else
                        if (Vector2.new(lavaPos.X,lavaPos.Z) - Vector2.new(root.Position.X,root.Position.Z)).Magnitude <= 350 then
                            shouldAbsorbLava = true
                        end
                    end
                end

                if shouldAbsorbLava then
                    if ZoneState ~= "ABSORBING_CURSE" then
                        PreviousZoneState    = ZoneState
                        ZoneState            = "ABSORBING_CURSE"
                        _G.LavaFailSafeTimer = tick()
                    end
                    if tick() - _G.LavaFailSafeTimer > 10 then
                        if CurrentLava.Part and CurrentLava.Part.Parent then
                            IgnoredHazards[CurrentLava.Part.Parent] = tick() + 60
                        end
                        ZoneState = PreviousZoneState or "FLYING"; return
                    end
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    TargetCFrame      = CFrame.new(CurrentLava.Part.Position)
                    if (root.Position - CurrentLava.Part.Position).Magnitude <= 12 then
                        root.Velocity = Vector3.zero
                        if not isHoldingLava then
                            isHoldingLava = true
                            task.spawn(function()
                                pcall(function()
                                    local p = CurrentLava.Prompt
                                    if p then
                                        p.RequiresLineOfSight   = false
                                        p.MaxActivationDistance = 50
                                        local holdTime = p.HoldDuration > 0 and p.HoldDuration or 2.0
                                        p:InputHoldBegin()
                                        VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
                                        task.wait(holdTime + 0.5)
                                        p:InputHoldEnd()
                                        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    end
                                end)
                                task.wait(0.5)
                                isHoldingLava = false
                            end)
                        end
                    end
                    return
                else
                    if ZoneState == "ABSORBING_CURSE" then
                        _smoothPos = nil
                        ZoneState  = PreviousZoneState or "FLYING"
                    end
                end

                -- Mera Ultra dodge takes priority over normal combat
                if _meraUltDodging then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    -- TargetCFrame already set by HookLeoAttributes when triggered
                    return
                end

                -- ── DODGE / BLOCK TRIGGER ──────────────────────────────────────
                if CurrentZoneIndex ~= 5 and CurrentHazard.Type ~= "None"
                and ZoneState ~= "DODGING" then

                    local action    = CurrentHazard.Action  or "DODGE"
                    local evadeDist = CurrentHazard.MinDist or EvadeDistance
                    if CurrentHazard.Instance then
                        IgnoredHazards[CurrentHazard.Instance] = tick() + 8
                    end

                    if action == "BLOCK" then
                        -- Block in place: Firefly, Hiken, or any BossSkill with BLOCK action.
                        -- IsReadyToAttack and ZoneState are NOT changed — character holds
                        -- attack position and resumes attacking the moment block ends.
                        if not _G.SkillBlocking then
                            local char2 = Player.Character
                            local wpn2  = char2 and char2:FindFirstChildOfClass("Tool")
                            local dur   = (CurrentHazard.Type == "Firefly") and 1.2 or 1.0
                            TriggerSkillBlock(wpn2 and wpn2.Name or "Melee", dur)
                        end
                        -- Do NOT change ZoneState, IsReadyToAttack, or CurrentTargetRoot

                    else
                        -- All DODGE actions: move sideways then resume
                        if ZoneState ~= "ABSORBING_CURSE" then PreviousZoneState = ZoneState end
                        IsReadyToAttack   = false
                        CurrentTargetRoot = nil

                        ZoneState = "DODGING"

                        local evadeDir = (root.Position - CurrentHazard.Position)
                        if evadeDir.Magnitude < 0.1 then
                            local rand = math.random(0, 3)
                            evadeDir = ({
                                Vector3.new(1,0,0), Vector3.new(-1,0,0),
                                Vector3.new(0,0,1), Vector3.new(0,0,-1)
                            })[rand+1]
                        end
                        local flatDir    = Vector3.new(evadeDir.X, 0, evadeDir.Z).Unit
                        local dodgeTarget = Vector3.new(
                            root.Position.X + flatDir.X * evadeDist,
                            root.Position.Y,
                            root.Position.Z + flatDir.Z * evadeDist
                        )
                        TargetCFrame = CFrame.new(dodgeTarget)
                        DodgeTimer   = tick() + (evadeDist / MoveSpeed) + DODGE_RETURN_WAIT
                    end
                end

                if ZoneState == "DODGING" then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    if tick() > DodgeTimer then
                        CurrentHazard.Type = "None"
                        if _G.SkillBlocking then
                            -- Wait for block to fully release before resuming
                            DodgeTimer = tick() + 0.1
                        else
                            ZoneState = PreviousZoneState or "ATTACKING"
                        end
                    else
                        return
                    end
                end

                -- ── ZONE STATE MACHINE ──────────────────────────────────────
                local zonePart = nil
                pcall(function() zonePart = workspace.Effects.Zones["Zone"..CurrentZoneIndex]:FindFirstChild("Zone") end)

                if zonePart then
                    local boxCenter = zonePart.Position
                    local floorY    = GetZoneFloor(CurrentZoneIndex, boxCenter)

                    -- All zones: hover above mob head (floorY + 20 wait position)
                    local waitPos = Vector3.new(boxCenter.X, floorY + 20, boxCenter.Z)

                    local mobs = GetMobsInZone(boxCenter)

                    if ZoneState == "FLYING" then
                        local targetY = math.max(root.Position.Y, floorY + 40)
                        TargetCFrame = CFrame.new(Vector3.new(boxCenter.X, targetY, boxCenter.Z))
                        CurrentTargetRoot = nil
                        local xzDist = (Vector2.new(root.Position.X, root.Position.Z)
                                      - Vector2.new(boxCenter.X, boxCenter.Z)).Magnitude
                        if xzDist < 15 then
                            if CurrentZoneIndex == 5 then
                                ZoneState = "ZONE5_SURVIVAL"; Timer = tick() + 30; Z5Index = 1
                            else
                                if #mobs > 0 then
                                    ZoneState = "ATTACKING"
                                else
                                    ZoneState = "WAITING_SPAWN"; Timer = tick() + WaitSpawnTime
                                end
                            end
                        end

                    elseif ZoneState == "ZONE5_SURVIVAL" then
                        IsReadyToAttack = false; CurrentTargetRoot = nil
                        local z5t = Zone5Points[Z5Index]
                        TargetCFrame = CFrame.new(z5t)
                        if (Vector3.new(root.Position.X,0,root.Position.Z)
                          - Vector3.new(z5t.X,0,z5t.Z)).Magnitude < 10 then
                            Z5Index = Z5Index < #Zone5Points and Z5Index + 1 or 1
                        end
                        if tick() > Timer then
                            CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; task.wait(0.1)
                        end

                    elseif ZoneState == "WAITING_SPAWN" then
                        -- Hold at waitPos without resetting every frame
                        if TargetCFrame == nil then TargetCFrame = CFrame.new(waitPos) end
                        CurrentTargetRoot = nil; IsReadyToAttack = false
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        elseif tick() > Timer then
                            CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; task.wait(0.1)
                        end

                    elseif ZoneState == "GATHERING" then
                        -- Shortcut: luôn vào ATTACKING ngay
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        else
                            ZoneState = "WAITING_SPAWN"; Timer = tick() + WaitSpawnTime
                        end

                    elseif ZoneState == "ATTACKING" then
                        if #mobs == 0 then
                            IsReadyToAttack = false; CurrentTargetRoot = nil
                            ZoneState = "VERIFY_CLEAR"; Timer = tick() + 0.8
                        else
                            -- Prioritize gun users first (all zones), then nearest mob
                            local bestMob, bestD = nil, math.huge
                            local bestGun, bestGunD = nil, math.huge
                            for _, m in ipairs(mobs) do
                                local mr = GetRoot(m)
                                if mr then
                                    local d = (mr.Position - root.Position).Magnitude
                                    local isGun = m.Name:lower():find("gun", 1, true) ~= nil
                                    if isGun and d < bestGunD then
                                        bestGunD = d; bestGun = m
                                    elseif not isGun and d < bestD then
                                        bestD = d; bestMob = m
                                    end
                                end
                            end
                            -- Gun user has absolute priority if present
                            local chosen = bestGun or bestMob
                            CurrentTargetRoot = GetRoot(chosen)
                            IsReadyToAttack   = true
                        end

                    elseif ZoneState == "VERIFY_CLEAR" then
                        -- FIX: không bay về tâm zone, đứng im chờ 0.8s
                        IsReadyToAttack = false; CurrentTargetRoot = nil
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        elseif tick() > Timer then
                            if CurrentZoneIndex == 7 then
                                ZoneState = "WAIT_30S"; Timer = tick() + 20
                            else
                                CurrentZoneIndex = CurrentZoneIndex + 1
                                ZoneState = "FLYING"; task.wait(0.1)
                            end
                        end

                    elseif ZoneState == "WAIT_30S" then
                        TargetCFrame = CFrame.new(waitPos)
                        CurrentTargetRoot = nil; IsReadyToAttack = false
                        if tick() > Timer then CurrentZoneIndex = 8; ZoneState = "FLYING" end
                    end
                else
                    TargetCFrame      = nil
                    CurrentTargetRoot = nil
                    IsReadyToAttack   = false
                    ZoneState         = "FLYING"
                    task.wait(0.5)
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- [16] AUTO BLOCK — ĐÃ XÓA (V4)
-- Thay bằng TriggerSkillBlock() trong [5-B]
-- Block on Firefly and Hiken (handled in [5-B])
-- ==========================================

-- ==========================================
-- [17] AUTO ATTACK — V7 CORRECT SPEED + COMBO
-- V7 Changes vs V6:
--   • MAX_COMBO = 5 (đúng game combo count)
--   • strikeDelay = 0.366s (đúng game attack speed, V5 dùng 0.22 quá nhanh)
--   • comboResetDelay = 0.6s giữ nguyên
--   • Không double-push target list (giữ từ V6)
-- ==========================================
task.spawn(function()
    local CombatRegister   = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
    local currentCombo     = 1
    local MAX_COMBO        = 5      -- V7: đúng game combo (5 hit)
    local strikeDelay      = 0.4  -- V7: đúng game attack speed
    local comboResetDelay  = 1.2
    local _lastFireTime    = 0

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsReadyToAttack and IsFarmingReady and not _G.IsProcessingFruit then
            local char = Player.Character
            if char and char.Parent then
                local now = tick()
                if now - _lastFireTime >= strikeDelay then
                    local fired = false
                    pcall(function()
                        local tool           = CheckAndEquipWeapon()
                        local realWeaponName = tool and tool.Name or "Melee"
                        local weaponType, fakeAnim = GetAttackAnim(realWeaponName, currentCombo)

                        if not fakeAnim or currentCombo > MAX_COMBO then
                            -- Anim không tồn tại hoặc combo vượt max → reset combo
                            currentCombo  = 1
                            _lastFireTime = now + comboResetDelay - strikeDelay
                            return
                        end

                        -- V6 FIX: chỉ push eRoot (BasePart), không push thêm m (Model)
                        -- → tránh server nhận double target, tránh lag/kick
                        local enemiesToHit = {}
                        local root         = char:FindFirstChild("HumanoidRootPart")
                        local primaryCFrame

                        if root then
                            for _, m in ipairs(GetMobsInZone(root.Position)) do
                                local eRoot = GetRoot(m)
                                if eRoot and (eRoot.Position - root.Position).Magnitude <= 300 then
                                    enemiesToHit[#enemiesToHit+1] = eRoot  -- chỉ BasePart, không push m
                                    if not primaryCFrame then primaryCFrame = eRoot.CFrame end
                                end
                            end
                        end
                        if not primaryCFrame and root then primaryCFrame = root.CFrame end

                        if #enemiesToHit > 0 and primaryCFrame then
                            _lastFireTime = now

                            local combo   = currentCombo
                            local wType   = weaponType
                            local anim    = fakeAnim
                            local targets = enemiesToHit
                            local pCF     = primaryCFrame

                            -- Song song: swingsfx + damage đồng thời
                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({
                                        [1]="swingsfx",[2]=wType,[3]=combo,
                                        [4]="Ground",[5]=false,[6]=anim,[7]=2,[8]=1.5
                                    })
                                end)
                            end)
                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({
                                        [1]="damage",[2]=targets,[3]=wType,
                                        [4]={[1]=combo,[2]="Ground",[3]=wType},
                                        [5]=true,[6]=pCF,["aircombo"]="Ground"
                                    })
                                end)
                            end)

                            fired = true
                            currentCombo = currentCombo + 1
                        end
                    end)
                    if not fired then
                        -- Không có enemy / anim → không stamp time, retry ngay
                    end
                end
            end
        else
            currentCombo  = 1
            _lastFireTime = 0
        end
        task.wait(0.015)
    end
end)

-- ==========================================
-- [18] ANTI RAGDOLL / UNFREEZE LOOP
-- ==========================================
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if char and char.Parent then
                    if hum then
                        hum.PlatformStand = false
                        hum.Sit           = false
                        -- V7 FIX: AutoRotate = false khi đang farm
                        -- AutoRotate = true → humanoid tự xoay về hướng velocity → conflict với CFrame manual → spinning
                        hum.AutoRotate = false
                        local state = hum:GetState()
                        if state == Enum.HumanoidStateType.Ragdoll
                        or state == Enum.HumanoidStateType.FallingDown
                        or state == Enum.HumanoidStateType.Physics then
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                    end
                    if root and root.Anchored then root.Anchored = false end
                    if root then
                        for _, v in pairs(root:GetChildren()) do
                            -- V7 FIX: bảo vệ CVFD_AntiGravity — KHÔNG destroy
                            -- V5/V6 bug: destroy ALL BodyVelocity mỗi 0.1s → anti-grav bị xóa → character rơi/xoay
                            if v.Name == _antiGravName then continue end
                            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition")
                            or v:IsA("LinearVelocity") or v:IsA("VectorForce") or v:IsA("AlignPosition") then
                                v:Destroy()
                            end
                        end
                        -- Reset RotVelocity liên tục để tránh spin sau block
                        root.RotVelocity = Vector3.zero
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- [19] RUNSERVICE: STEPPED (ANTI STUN/FREEZE + NOCLIP)
-- V5 IMPROVE (từ fishing module):
--   • Cache BasePart list, chỉ rebuild khi character đổi (tránh GetDescendants mỗi frame)
--   • Backup noclip loop độc lập với task.wait(0.05) — vẫn chạy khi FPS < 5 / freeze
--   • Gen-based invalidation: Stop/Start nhanh không gây loop leak
-- ==========================================
local _noclipLastApply      = 0
local _noclipParts          = {}
local _noclipCharRef        = nil
local NOCLIP_APPLY_INTERVAL = 0.08

local function _rebuildNoclipCache(char)
    _noclipCharRef = char
    _noclipParts   = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then _noclipParts[#_noclipParts + 1] = p end
    end
end

-- Backup noclip loop: chạy song song với Stepped, đảm bảo CanCollide = false
-- ngay cả khi FPS < 5 hoặc game freeze (Stepped ngưng chạy)
local _backupNoclipGen = 0
local function _startBackupNoclip()
    _backupNoclipGen = _backupNoclipGen + 1
    local myGen = _backupNoclipGen
    task.spawn(function()
        while _G.DungeonScriptID == currentScriptID and myGen == _backupNoclipGen do
            -- V11 FIX: noclip xuyên suốt — bỏ guard IsFarmingReady và AutoDungeon
            -- Noclip phải chạy mọi lúc kể cả khi load/die/replay
            local char = Player.Character
            if char then
                if char ~= _noclipCharRef then _rebuildNoclipCache(char) end
                for _, p in ipairs(_noclipParts) do
                    if p and p.Parent then p.CanCollide = false end
                end
            end
            -- Keepalive fakePlatform CanCollide = true
            if fakePlatform and fakePlatform.Parent then
                if not fakePlatform.CanCollide then fakePlatform.CanCollide = true end
                if fakePlatform.Transparency ~= 1 then fakePlatform.Transparency = 1 end
            end
            task.wait(0.05)
        end
    end)
end
_startBackupNoclip()

-- Restart backup loop khi character respawn
-- V7 FIX: game 1 mạng → khi Humanoid.Died, dừng toàn bộ automation ngay
local function OnCharacterDied()
    _G.AutoDungeon       = false
    IsFarmingReady       = false
    IsReadyToAttack      = false
    _G.SkillBlocking     = false
    _G.IsProcessingFruit = false
    CurrentTargetRoot    = nil
    TargetCFrame         = nil
    _meraUltDodging      = false
    ZoneState            = "FLYING"
    if fakePlatform and fakePlatform.Parent then
        fakePlatform.CFrame = CFrame.new(0, -9999, 0)
    end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then _removeAntiGrav(root) end
end

local function HookCharacterDeath(char)
    if not char then return end
    local hum = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum then return end

    hum.Died:Connect(OnCharacterDied)

    -- Lightning jump: when damage is taken while a Lightning part exists in Effects,
    -- instantly jump +10 studs. Ignores all non-lightning damage.
    local _prevHealth      = hum.Health
    local _jumpCooldown    = false

    hum.HealthChanged:Connect(function(newHealth)
        local dmg = _prevHealth - newHealth
        _prevHealth = newHealth
        if dmg <= 0 or _jumpCooldown or not IsFarmingReady then return end

        -- Only react if a Lightning part is currently in workspace Effects
        local lightningPresent = false
        local ef = workspace:FindFirstChild("Effects")
        if ef then
            for _, v in ipairs(ef:GetDescendants()) do
                if v:IsA("BasePart") and v.Name:lower():match("lightning") then
                    lightningPresent = true; break
                end
            end
        end
        if not lightningPresent then return end

        _jumpCooldown = true
        local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if r then
            r.CFrame = r.CFrame + Vector3.new(0, 10, 0)
        end
        task.delay(0.8, function()
            _jumpCooldown = false
        end)
    end)
end

-- Hook ngay với character đang có
HookCharacterDeath(Player.Character)

Player.CharacterAdded:Connect(function(newChar)
    _noclipCharRef = nil  -- force rebuild noclip cache
    _startBackupNoclip()
    -- Hook death cho character mới
    HookCharacterDeath(newChar)
    -- V7: Game 1 mạng → CharacterAdded nghĩa là respawn sau chết
    -- KHÔNG tự động restart dungeon — người dùng phải chủ động re-run script
    -- (AutoDungeon đã = false từ OnCharacterDied)
end)

_G.CupidStepped = RunService.Stepped:Connect(function()
    if not _G.AutoDungeon or not IsFarmingReady then return end
    if _G.IsProcessingFruit then return end
    local char = Player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not char or not char.Parent then return end

    pcall(function()
        if not _G.SkillBlocking then _G.blocking = false end
        if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end

        local now = tick()
        if now - _noclipLastApply >= NOCLIP_APPLY_INTERVAL then
            _noclipLastApply = now
            if char ~= _noclipCharRef then _rebuildNoclipCache(char) end
            for _, v in ipairs(_noclipParts) do
                if v and v.Parent then
                    v.CanCollide = false
                    v.CastShadow = false
                end
            end
        end
    end)
end)

-- ==========================================
-- [20] RUNSERVICE: HEARTBEAT (MOVEMENT)
-- V4 — FPS-safe tween + stamina spoof noclip:
--
--   ① Cap dt → MAX_DT (0.07s): khi FPS < 5 / freeze,
--      dt có thể lên tới 0.5-1s, gây bước nhảy 50-100 studs/frame
--      → bị server kick hoặc teleport về. Cap lại để bước không quá lớn.
--
--   ② Cap step/frame → MAX_STEP_PER_FRAME (10 studs):
--      Bảo vệ thêm một lớp, dù dt cap rồi nhưng tốc độ cao vẫn có thể vượt.
--
--   ③ StartStaminaSpoof khi dist > 1.5:
--      Fire TakeStam:FireServer(0.545, "dash") mỗi 50ms.
--      Server nhận dash liên tục → bypass distance/teleport check.
--      StopStaminaSpoof khi tới nơi.
-- ==========================================
-- V10 FIX FPS: cache yaw để tránh ToOrientation() mỗi Heartbeat frame
-- ToOrientation() decompose quaternion → đắt khi gọi 60fps liên tục
-- Chỉ update khi đang di chuyển (not IsReadyToAttack), lưu lại khi flip sang attack
local _cachedYaw = 0
-- Cache footstep event 1 lần — tránh FindFirstChild mỗi Heartbeat frame
local _footstepEvent = ReplicatedStorage:FindFirstChild("Events")
    and ReplicatedStorage.Events:FindFirstChild("footstep") or nil
task.spawn(function()
    -- Đợi nếu chưa load
    if not _footstepEvent then
        local ev = ReplicatedStorage:WaitForChild("Events", 10)
        if ev then _footstepEvent = ev:WaitForChild("footstep", 10) end
    end
end)

-- ==========================================
-- [20-A] HITBOX EXPAND — V10
-- Server expand hitbox nhẹ khi character đang "moving" (velocity > 0)
-- Sau khi xóa hum:Move + root.Velocity, char đứng yên hoàn toàn → hitbox thu nhỏ
-- Fix: fire footstepEvent liên tục khi IsReadyToAttack → server nhận "running"
--      + set BodyVelocity.Velocity = LookVector * tiny (2 studs/s) thay vì Vector3.zero
--      → hitbox nhẹ mở rộng, không ảnh hưởng position (quá nhỏ để anticheat flag)
-- ==========================================
task.spawn(function()
    local HITBOX_INTERVAL = 0.08  -- fire mỗi 80ms ≈ tương đương WalkSpeed 16
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsReadyToAttack and IsFarmingReady and not _G.IsProcessingFruit then
            pcall(function()
                -- [A] Fire footstep event → server nhận "character is running"
                if _footstepEvent and _footstepEvent.Parent then
                    _footstepEvent:FireServer()
                end
                -- [B] Tiny forward velocity qua BodyVelocity → velocity.Magnitude > 0
                -- Dùng LookVector nhân rất nhỏ (2 studs/s) → không di chuyển thực tế
                -- Không set root.Velocity trực tiếp (xung đột BodyVelocity MaxForce=9e9)
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local ag = root:FindFirstChild(_antiGravName)
                    if ag then
                        -- Giữ anti-gravity nhưng thêm tiny XZ component
                        local lv = root.CFrame.LookVector
                        ag.Velocity = Vector3.new(lv.X * 2, 0, lv.Z * 2)
                    end
                end
            end)
        else
            -- Không attack: reset velocity về 0 hoàn toàn
            pcall(function()
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local ag = root:FindFirstChild(_antiGravName)
                    if ag then ag.Velocity = Vector3.zero end
                end
            end)
        end
        task.wait(HITBOX_INTERVAL)
    end
end)

-- V5: Anti-gravity BodyVelocity (từ fishing module)
-- Giữ character không bị gravity kéo xuống khi tween ngang
-- Tên "CVFD_AntiGravity" để tránh xung đột với fishing
local _antiGravName = "CVFD_AntiGravity"

local function _ensureAntiGrav(root)
    local ag = root:FindFirstChild(_antiGravName)
    if not ag then
        ag             = Instance.new("BodyVelocity")
        ag.Name        = _antiGravName
        ag.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
        ag.Velocity    = Vector3.zero
        ag.Parent      = root
    end
    return ag
end

local function _removeAntiGrav(root)
    if not root then return end
    local ag = root:FindFirstChild(_antiGravName)
    if ag then ag:Destroy() end
end



_G.CupidHeartbeat = RunService.Heartbeat:Connect(function(dt)
    if not _G.AutoDungeon then return end
    if not IsFarmingReady then
        if fakePlatform then fakePlatform.CFrame = CFrame.new(0, -9999, 0) end
        return
    end
    if _G.IsProcessingFruit then return end

    local char = Player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root or not char.Parent then return end

    -- Fake platform theo chân player — V6: Y động theo trạng thái tilt
    -- Khi IsReadyToAttack (tilted -90°): body nằm ngang, lowest Y ≈ HRP.Y → platform gần hơn
    -- Khi bình thường (đứng/bay): feet ≈ HRP.Y - 3.2 → platform center ở HRP.Y - 3.7
    if fakePlatform then
        local platformY
        if IsReadyToAttack then
            -- Tilted -90°: sau khi rotate X, feet trở thành forward/backward
            -- World Y của body parts ≈ root.Y ± limb_radius (~1 stud)
            -- Đặt platform sát phía dưới: root.Y - 0.8 (top ≈ root.Y - 0.3)
            platformY = root.Position.Y - 0.8
        else
            -- Đứng/bay bình thường: feet ≈ root.Y - 3.2
            -- Đặt platform: center root.Y - 3.7, top = root.Y - 3.2 (đúng mức feet)
            platformY = root.Position.Y - 3.7
        end
        fakePlatform.CFrame = CFrame.new(root.Position.X, platformY, root.Position.Z)
    end

    -- ── TARGET POSITION ─────────────────────────────────────────────────
    -- Position above mob head by AttackOffset.
    -- For zones where the mob is underground (zone 7/8), clamp to at least
    -- floorY + AttackOffset so the character stays above the visible ground.
    local activeTargetPos = nil
    if CurrentTargetRoot and CurrentTargetRoot.Parent then
        local mobX  = CurrentTargetRoot.Position.X
        local mobY  = CurrentTargetRoot.Position.Y
        local mobZ  = CurrentTargetRoot.Position.Z
        local floorY = GetZoneFloor(CurrentZoneIndex, CachedZoneBoxCenters[CurrentZoneIndex])
        local targetY
        if floorY then
            -- Never go underground: clamp so character is at least AttackOffset above floor
            targetY = math.max(mobY + AttackOffset, floorY + AttackOffset)
        else
            targetY = mobY + AttackOffset
        end
        activeTargetPos = Vector3.new(mobX, targetY, mobZ)
    elseif TargetCFrame then
        activeTargetPos = TargetCFrame.Position
    end

    if activeTargetPos then
        local currentPos  = root.Position
        local effectiveDt = math.min(dt, MAX_DT)

        local ag = _ensureAntiGrav(root)

        -- ── MOVEMENT: small-step snap, Y+ capped for anticheat ─────────
        _smoothPos = nil
        local newPos
        local dist = (currentPos - activeTargetPos).Magnitude
        if dist > 0.1 then
            local step      = math.min(MoveSpeed * effectiveDt, MAX_STEP_PER_FRAME, dist)
            local direction = (activeTargetPos - currentPos).Unit
            local stepVec   = direction * step
            -- Only cap upward Y movement (anticheat flags +Y axis too fast)
            local cappedStepY = stepVec.Y > 0
                and math.min(stepVec.Y, MAX_STEP_Y_PER_FRAME)
                or  stepVec.Y
            newPos = Vector3.new(
                currentPos.X + stepVec.X,
                currentPos.Y + cappedStepY,
                currentPos.Z + stepVec.Z)
        else
            newPos = activeTargetPos
        end

        -- ── ROTATION ────────────────────────────────────────────────────
        if IsReadyToAttack then
            -- Attack pose: -90° tilt so the character lies horizontal above the mob
            root.CFrame = CFrame.new(newPos)
                * CFrame.Angles(0, _cachedYaw, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            root.RotVelocity = Vector3.zero
        else
            if _G.SkillBlocking then
                root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                root.RotVelocity = Vector3.zero
                pcall(function() root.AssemblyAngularVelocity = Vector3.zero end)
            else
                local flatDir = Vector3.new(
                    activeTargetPos.X - newPos.X, 0,
                    activeTargetPos.Z - newPos.Z)
                if flatDir.Magnitude > 1.5 then
                    local lerpFactor = 1 - math.exp(-12 * effectiveDt)
                    local targetRot  = CFrame.lookAt(newPos, newPos + flatDir.Unit)
                    local smoothRot  = root.CFrame:Lerp(targetRot, lerpFactor).Rotation
                    root.CFrame = CFrame.new(newPos) * smoothRot
                else
                    root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                end
                local _, yaw, _ = root.CFrame:ToOrientation()
                _cachedYaw = yaw
            end
            root.RotVelocity = Vector3.zero
        end
    else
        if _smoothPos then _smoothPos = nil end
        _removeAntiGrav(root)
    end
end)
