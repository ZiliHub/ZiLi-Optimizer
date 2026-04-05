-- ==========================================
-- AUTO CUPID V16
-- Game: GET BETTER OUT | Cupid Dungeon
-- Changes vs V15:
--   [1] All zones: always hover above mob head (AttackOffset = 10.2, no underground clamp)
--   [2] Dungeon dodge events: ONLY Lightning (dmg → +10Y, hold 1.5s, return mob)
--       + ArrowRain (50 studs sideways). No other dungeon event dodges.
--   [3] FPS/Freeze: GetDescendants() cached 150ms TTL; DescendantAdded filtered;
--       standstill / freeze micro-pauses eliminated; chunk size doubled
--   [4] Block: instant DescendantAdded hook for Firefly + Hiken (block the moment they spawn);
--       Flame Pillar stays 75 studs; MeraUlt upgraded 100 → 115 studs
--   [5] Map optimize: Camera MaxAxisFieldOfView = 130; aggressive Light/Decor removal;
--       CanQuery=false on non-essential parts; SpecialMesh scale zeroed; Sound volume 0
--   [6] Script-wide: memory leak audit, dedup connections, tighter intervals
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
-- ==========================================
task.spawn(function()
    local isReplaying = false

    local function FindReplayButton()
        local prompt = Player.PlayerGui:FindFirstChild("ConfirmationPrompt")
        if not prompt then return nil, nil, nil end
        if prompt:IsA("ScreenGui") and not prompt.Enabled then return nil, nil, nil end

        local main = prompt:FindFirstChild("Main")
        if not main or (main:IsA("GuiObject") and not main.Visible) then return nil, nil, nil end

        local options = main:FindFirstChild("OptionsFrame")
        if not options then return nil, nil, nil end

        local targetBtn = nil
        for _, child in ipairs(options:GetChildren()) do
            if child:IsA("ImageButton") then
                local bv = child:GetAttribute("buttonValue")
                if bv then
                    local bvLow = tostring(bv):lower()
                    if bvLow:match("replay") or bvLow:match("again") or bvLow:match("play") then
                        targetBtn = child; break
                    end
                    if not targetBtn then targetBtn = child end
                end
            end
        end
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
                    local isServer = prompt:GetAttribute("isServer")
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
                        local nilFired = false
                        if getnilinstances then
                            for _, v in next, getnilinstances() do
                                if v:IsA("RemoteEvent") and v.Parent == nil then
                                    pcall(function() v:FireServer(val) end)
                                    nilFired = true
                                end
                            end
                        end
                        if not nilFired then
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
local AttackOffset       = 10.2  -- hover above mob head (all zones)
local SearchRadius       = 800
local WaitSpawnTime      = 6
local DangerRadius       = 45
local EvadeDistance      = 60

-- V16: MeraUlt upgraded 100 → 115 studs
local EVADE_ENTEI        = 130
local EVADE_FLAME_PILLAR = 75
local EVADE_MERAULT      = 115   -- was 100
local EVADE_ARROWRAIN    = 50    -- NEW: Arrow Rain dungeon event

local MAX_DT               = 0.1
local MAX_STEP_PER_FRAME   = 8
local MAX_STEP_Y_PER_FRAME = 0.7
local DODGE_RETURN_WAIT    = 1.5

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

-- Dodge flags
local _meraUltDodging     = false
local _lightningDodging   = false   -- V16: NEW — holds +10Y jump for 1.5s
local _lightningHoldUntil = 0

-- ── V16 FIX FPS: cache yaw (avoid ToOrientation() every Heartbeat frame) ──
local _cachedYaw = 0

-- FakePlatform (follows player feet at all times)
local fakePlatform = workspace:FindFirstChild("CupidFakePlatform")
if fakePlatform then fakePlatform:Destroy() end
fakePlatform              = Instance.new("Part")
fakePlatform.Name         = "CupidFakePlatform"
fakePlatform.Size         = Vector3.new(22, 1, 22)
fakePlatform.Anchored     = true
fakePlatform.CanCollide   = true
fakePlatform.Transparency = 1
fakePlatform.CastShadow   = false
fakePlatform.Material     = Enum.Material.SmoothPlastic
fakePlatform.Parent       = workspace

-- ==========================================
-- [5-A] STAMINA SPOOF — always-on
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

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
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
                    if TakeStam and TakeStam.Parent then TakeStam:FireServer(0.545, "dash") end
                end)
            end)
        end
        task.wait(0.05)
    end
end)

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
local CachedZoneBoxCenters = {}

local function GetZoneFloor(zoneIndex, boxCenter)
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
    local fallback = center.Y - 10
    CachedZoneFloors[zoneIndex] = fallback
    return fallback
end

local function GetRoot(m)
    if not m then return nil end
    if m:IsA("BasePart") then return m end
    return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

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

local MobSearchCache = {mobs = {}, time = 0, zone = -1}
local MOB_CACHE_TTL  = 0.08

local function GetMobsInZone(zonePos)
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

    local isBladeWeapon = (function()
        local n = weaponName:lower()
        return n:match("sword") or n:match("blade") or n:match("katana") or n:match("axe")
    end)()

    wType  = isBladeWeapon and "Sword" or weaponName
    local folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild(weaponName)
    if not folder then
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
                                _lightningDodging     = false
                                MobSearchCache        = {mobs = {}, time = 0, zone = -1}
                                CachedZoneFloors      = {}
                                StopStaminaSpoof()
                                task.wait(5)
                                -- V16: re-run map optimize on each dungeon entry
                                _mapOptimized = false
                                DoMapOptimize()
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
-- [13-B] MAP OPTIMIZE — V16 AGGRESSIVE POTATO
-- Camera FOV = 130 (was 70)
-- Light instances destroyed; CanQuery = false on props
-- SpecialMesh Scale = 0; max LOD kill
-- ==========================================
local _mapOptimized    = false
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
            -- V16: zero scale (more aggressive than just LODFactor)
            v.Scale = Vector3.zero
        elseif v:IsA("BasePart") and not v:IsA("Terrain") then
            v.LocalTransparencyModifier = 1
            v.CastShadow = false
            v.CanCollide = false
            pcall(function() v.CanQuery = false end)
            pcall(function() v.CanTouch = false end)
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("Sound") then
            v.Volume = 0
        elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
            -- V16: destroy light instances entirely → biggest GPU win
            v:Destroy()
        end
    end)
end

local function HideFolderEffects(folder)
    if not folder then return end
    pcall(function()
        for _, v in ipairs(folder:GetDescendants()) do
            HideVisualOfInst(v)
        end
        -- V16: filter DescendantAdded to relevant types only (prevent per-frame spam)
        folder.DescendantAdded:Connect(function(inst)
            local cls = inst.ClassName
            if cls == "ParticleEmitter" or cls == "Beam" or cls == "Trail"
            or cls == "Fire" or cls == "Smoke" or cls == "Sparkles"
            or cls == "PointLight" or cls == "SpotLight" or cls == "SurfaceLight"
            or cls == "BillboardGui" or cls == "SurfaceGui"
            or cls == "Decal" or cls == "Texture" or cls == "Sound"
            or inst:IsA("BasePart") then
                task.defer(function() HideVisualOfInst(inst) end)
            end
        end)
    end)
end

-- V16: disconnect map connections from old session before creating new ones
if _G.CupidMapConns then
    for _, c in ipairs(_G.CupidMapConns) do pcall(function() c:Disconnect() end) end
end
_G.CupidMapConns = {}

function DoMapOptimize()
    if _mapOptimized then return end
    _mapOptimized = true
    task.spawn(function()

        -- [A] Lighting — disable all post-processing + sky
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

        -- [B] Render quality — lowest possible
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function()
            UserSettings():GetService("UserGameSettings").SavedQualityLevel
                = Enum.SavedQualitySetting.QualityLevel1
        end)
        pcall(function() setfflag("DFIntDebugFRMQualityLevelOverride", "1") end)
        pcall(function() setsetting("Graphics Quality", 1) end)

        -- V16: Camera FOV = 130 (wider FOV = less per-pixel cost + clearer view of hazards)
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then cam.MaxAxisFieldOfView = 130 end
        end)

        pcall(function() workspace.StreamingEnabled = false end)

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

        -- [D] Effects & Projectiles folders
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

        -- [E] Full workspace scan — chunked (V16: chunk size 400, up from 200)
        task.spawn(function()
            local descs = workspace:GetDescendants()
            local CHUNK  = 400  -- V16: doubled from 200 → fewer yields → faster finish
            for i = 1, #descs, CHUNK do
                for j = i, math.min(i + CHUNK - 1, #descs) do
                    local desc = descs[j]
                    if Player.Character and desc:IsDescendantOf(Player.Character) then continue end
                    pcall(function()
                        if desc:IsA("ParticleEmitter") or desc:IsA("Beam")
                        or desc:IsA("Trail") or desc:IsA("Fire")
                        or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                            desc.Enabled = false

                        elseif desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
                            -- V16: destroy lights → major GPU gain
                            desc:Destroy()

                        elseif desc:IsA("BasePart") and not desc:IsA("Terrain") then
                            desc.CastShadow  = false
                            desc.Material    = Enum.Material.SmoothPlastic
                            desc.Reflectance = 0
                            pcall(function() desc.CanQuery = false end)
                            if not desc.CanCollide then
                                desc.LocalTransparencyModifier = 1
                                pcall(function() desc.CanTouch = false end)
                            end

                        elseif desc:IsA("Decal") or desc:IsA("Texture") then
                            desc.Transparency = 1

                        elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
                            desc.Enabled = false

                        elseif desc:IsA("Sound") then
                            if not (desc.Parent and Player.Character and desc:IsDescendantOf(Player.Character)) then
                                desc.Volume = 0
                            end

                        elseif desc:IsA("SpecialMesh") then
                            -- V16: zero scale instead of just LODFactor
                            pcall(function() desc.Scale = Vector3.zero end)
                        end
                    end)
                end
                task.wait()  -- yield between chunks
            end

            -- V16: DescendantAdded — filtered to relevant types only (no per-frame spam)
            local connD = workspace.DescendantAdded:Connect(function(inst)
                if Player.Character and inst:IsDescendantOf(Player.Character) then return end
                local cls = inst.ClassName
                -- Only process types we care about (skip Model, Folder, Script, etc.)
                if cls ~= "ParticleEmitter" and cls ~= "Beam" and cls ~= "Trail"
                and cls ~= "Fire" and cls ~= "Smoke" and cls ~= "Sparkles"
                and cls ~= "PointLight" and cls ~= "SpotLight" and cls ~= "SurfaceLight"
                and cls ~= "Decal" and cls ~= "Texture" and cls ~= "Sound"
                and cls ~= "BillboardGui" and cls ~= "SurfaceGui"
                and cls ~= "SpecialMesh"
                and not inst:IsA("BasePart") then
                    return  -- fast exit for irrelevant types
                end
                task.defer(function()
                    if Player.Character and inst:IsDescendantOf(Player.Character) then return end
                    pcall(function()
                        if inst:IsA("ParticleEmitter") or inst:IsA("Beam")
                        or inst:IsA("Trail") or inst:IsA("Fire")
                        or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                            inst.Enabled = false
                        elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
                            inst:Destroy()
                        elseif inst:IsA("BasePart") and not inst:IsA("Terrain") then
                            inst.CastShadow  = false
                            inst.Material    = Enum.Material.SmoothPlastic
                            inst.Reflectance = 0
                            pcall(function() inst.CanQuery = false end)
                            if not inst.CanCollide then
                                inst.LocalTransparencyModifier = 1
                                pcall(function() inst.CanTouch = false end)
                            end
                        elseif inst:IsA("Decal") or inst:IsA("Texture") then
                            inst.Transparency = 1
                        elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
                            inst.Enabled = false
                        elseif inst:IsA("SpecialMesh") then
                            pcall(function() inst.Scale = Vector3.zero end)
                        end
                    end)
                end)
            end)
            table.insert(_G.CupidMapConns, connD)
        end)
    end)
end

-- Run immediately on script load
DoMapOptimize()

-- ==========================================
-- [14] HAZARD SCANNER — V16
-- DUNGEON EVENTS: Lightning (HealthChanged, not scan) + ArrowRain (50s)
-- BOSS SKILLS:    Enkai/Entei (queue), Flame Pillar (75s), Hiken/Firefly (block)
-- ==========================================

-- [A] Queue-based: Enkai / Entei (wide area boss skills, zone >= 5)
local EnkaiDefs = {
    {pattern = "enkai",  evadeDist = EVADE_ENTEI, priority = 1},
    {pattern = "en_kai", evadeDist = EVADE_ENTEI, priority = 1},
    {pattern = "entei",  evadeDist = EVADE_ENTEI, priority = 1},
}

-- [B] Active poll: Flame Pillar, Hiken, Firefly, ArrowRain (checked every scan tick)
local ActiveSkillDefs = {
    -- Flame Pillar: dodge 75 studs sideways
    {pattern = "flame_pillar",  action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "flamepillar",   action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "flame pillar",  action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "flamepilla",    action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "eruption",      action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "firepillar",    action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    {pattern = "pillar_dmg",    action = "DODGE", evadeDist = EVADE_FLAME_PILLAR},
    -- Hiken: block in place
    {pattern = "hiken",         action = "BLOCK", evadeDist = 0},
    {pattern = "hi_ken",        action = "BLOCK", evadeDist = 0},
    {pattern = "fire_fist",     action = "BLOCK", evadeDist = 0},
    {pattern = "firefist",      action = "BLOCK", evadeDist = 0},
    {pattern = "hiken_dmg",     action = "BLOCK", evadeDist = 0},
    -- Firefly: block in place
    {pattern = "firefly",       action = "BLOCK", evadeDist = 0},
    {pattern = "fire_fly",      action = "BLOCK", evadeDist = 0},
    -- V16 NEW: Arrow Rain dungeon event → dodge 50 studs sideways only
    {pattern = "arrowrain",     action = "DODGE", evadeDist = EVADE_ARROWRAIN},
    {pattern = "arrow_rain",    action = "DODGE", evadeDist = EVADE_ARROWRAIN},
    {pattern = "arrowstorm",    action = "DODGE", evadeDist = EVADE_ARROWRAIN},
    {pattern = "rain_arrow",    action = "DODGE", evadeDist = EVADE_ARROWRAIN},
    {pattern = "arrowfall",     action = "DODGE", evadeDist = EVADE_ARROWRAIN},
    {pattern = "arrow_volley",  action = "DODGE", evadeDist = EVADE_ARROWRAIN},
}

local IGNORE_NAME_PATTERNS = {
    "dmgind", "hitbox", "hurtbox", "indicator", "number",
    "billboard", "sfx", "sound", "particle", "debris",
    "decal", "highlight", "selection", "tag", "gui",
}

local ACTIVE_POLL_RADIUS = 200

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

-- V16: merged DescendantAdded: Enkai queue + instant Firefly/Hiken block
local _descAddedConn
_descAddedConn = workspace.DescendantAdded:Connect(function(inst)
    if _G.DungeonScriptID ~= currentScriptID then
        _descAddedConn:Disconnect(); return
    end
    if not (inst:IsA("BasePart") or inst:IsA("Model")) then return end

    -- Queue for Enkai/Entei scan
    _newInstQueue[#_newInstQueue + 1] = inst

    -- V16: Instant block the moment Firefly or Hiken appears
    if IsFarmingReady and _G.AutoDungeon and not _G.SkillBlocking then
        local n = inst.Name:lower()
        if n:match("firefly") or n:match("fire_fly")
        or n:match("hiken")   or n:match("hi_ken") or n:match("fire_fist") then
            task.defer(function()
                if not _G.SkillBlocking and IsFarmingReady and _G.AutoDungeon then
                    local char = Player.Character
                    local wpn  = char and char:FindFirstChildOfClass("Tool")
                    TriggerSkillBlock(wpn and wpn.Name or "Melee", 1.2)
                end
            end)
        end
    end
end)

-- Drain queue for Enkai/Entei
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

-- V16 FPS FIX: cache workspace:GetDescendants() with 150ms TTL
-- Prevents GetDescendants() from running 25-100x per second
local _wsDescsCache     = {}
local _wsDescsCacheTime = 0
local WS_DESCS_CACHE_TTL = 0.15

local function GetCachedWsDescs()
    local now = tick()
    if now - _wsDescsCacheTime >= WS_DESCS_CACHE_TTL then
        _wsDescsCacheTime = now
        _wsDescsCache     = workspace:GetDescendants()
    end
    return _wsDescsCache
end

-- Active poll scan (all zones — allows ArrowRain detection before boss area too)
local function ActiveSkillScan(playerPos)
    local bestAction, bestEvadeDist, bestInst, bestPos
    local char = Player.Character
    for _, v in ipairs(GetCachedWsDescs()) do  -- V16: cached
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
        local dist = (Vector3.new(vPos.X, playerPos.Y, vPos.Z)
                    - Vector3.new(playerPos.X, playerPos.Y, playerPos.Z)).Magnitude
        if dist > ACTIVE_POLL_RADIUS then continue end
        for _, def in ipairs(ActiveSkillDefs) do
            if n:match(def.pattern) then
                if not bestAction then
                    bestAction    = def.action
                    bestEvadeDist = def.evadeDist
                    bestInst      = v
                    bestPos       = vPos
                end
                break
            end
        end
        if bestAction then break end
    end
    return bestAction, bestEvadeDist, bestInst, bestPos
end

-- Hazard scan loop
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                for obj, expireTime in pairs(IgnoredHazards) do
                    if tick() > expireTime or not obj:IsDescendantOf(workspace) then
                        IgnoredHazards[obj] = nil
                    end
                end

                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local playerPos       = root.Position
                local detectedHazard  = "None"
                local hazardPos       = nil
                local hazardInst      = nil
                local hazardAction    = "DODGE"
                local hazardEvadeDist = EvadeDistance
                local foundLavaPart   = nil
                local foundLavaPrompt = nil

                -- Enkai/Entei: queue-based (boss zones only)
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

                -- Active skill poll (Flame Pillar, Hiken, Firefly, ArrowRain — all zones)
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

                -- Lava Curse: use cached workspace descs (V16 FPS fix)
                if CurrentZoneIndex >= 5 then
                    local cachedDescs = GetCachedWsDescs()
                    for _, v in ipairs(cachedDescs) do
                        if not (v:IsA("BasePart") or v:IsA("Model")) then continue end
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
-- V16: dodge 115 studs sideways (was 100), hold minimum 2.5s
-- ==========================================
local _meraUltHoldUntil = 0

local function HookLeoAttributes(leoModel)
    leoModel.AttributeChanged:Connect(function(attr)
        if attr ~= "meraUltMax" then return end
        local val = leoModel:GetAttribute("meraUltMax")
        if val ~= nil then
            _meraUltDodging   = true
            _meraUltHoldUntil = tick() + 2.5
            local char = Player.Character
            local root  = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local right = root.CFrame.RightVector
                -- V16: 115 studs (was 100)
                TargetCFrame      = CFrame.new(Vector3.new(
                    root.Position.X + right.X * EVADE_MERAULT,
                    root.Position.Y,
                    root.Position.Z + right.Z * EVADE_MERAULT
                ))
                IsReadyToAttack   = false
                CurrentTargetRoot = nil
            end
        else
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
-- [15] MAIN COMBAT LOOP
-- ==========================================
task.spawn(function()
    local lastZone      = 0
    local isHoldingLava = false

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
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
                        ZoneState = PreviousZoneState or "FLYING"
                    end
                end

                -- ── MERA ULTRA DODGE ────────────────────────────────────────
                if _meraUltDodging then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    return
                end

                -- ── V16: LIGHTNING DODGE — hold 1.5s at raised position then return to mob ──
                if _lightningDodging then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    -- Hold at current elevated position
                    if root then TargetCFrame = CFrame.new(root.Position) end
                    if tick() >= _lightningHoldUntil then
                        _lightningDodging = false
                        TargetCFrame      = nil  -- resume normal mob targeting
                    end
                    return
                end

                -- ── DODGE / BLOCK TRIGGER ──────────────────────────────────
                if CurrentZoneIndex ~= 5 and CurrentHazard.Type ~= "None"
                and ZoneState ~= "DODGING" then

                    local action    = CurrentHazard.Action  or "DODGE"
                    local evadeDist = CurrentHazard.MinDist or EvadeDistance
                    if CurrentHazard.Instance then
                        IgnoredHazards[CurrentHazard.Instance] = tick() + 8
                    end

                    if action == "BLOCK" then
                        if not _G.SkillBlocking then
                            local char2 = Player.Character
                            local wpn2  = char2 and char2:FindFirstChildOfClass("Tool")
                            local dur   = (CurrentHazard.Type == "Firefly") and 1.2 or 1.0
                            TriggerSkillBlock(wpn2 and wpn2.Name or "Melee", dur)
                        end
                    else
                        if ZoneState ~= "ABSORBING_CURSE" then PreviousZoneState = ZoneState end
                        IsReadyToAttack   = false
                        CurrentTargetRoot = nil
                        ZoneState         = "DODGING"

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

                    -- V16: All zones wait at hover height above floor (above mob head)
                    local waitPos = Vector3.new(boxCenter.X, floorY + 20, boxCenter.Z)
                    local mobs    = GetMobsInZone(boxCenter)

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
                        if TargetCFrame == nil then TargetCFrame = CFrame.new(waitPos) end
                        CurrentTargetRoot = nil; IsReadyToAttack = false
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        elseif tick() > Timer then
                            CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; task.wait(0.1)
                        end

                    elseif ZoneState == "GATHERING" then
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
                            local chosen = bestGun or bestMob
                            CurrentTargetRoot = GetRoot(chosen)
                            IsReadyToAttack   = true
                        end

                    elseif ZoneState == "VERIFY_CLEAR" then
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
-- [17] AUTO ATTACK
-- ==========================================
task.spawn(function()
    local CombatRegister   = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
    local currentCombo     = 1
    local MAX_COMBO        = 5
    local strikeDelay      = 0.4
    local comboResetDelay  = 1
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
                            currentCombo  = 1
                            _lastFireTime = now + comboResetDelay - strikeDelay
                            return
                        end

                        local enemiesToHit = {}
                        local root         = char:FindFirstChild("HumanoidRootPart")
                        local primaryCFrame

                        if root then
                            for _, m in ipairs(GetMobsInZone(root.Position)) do
                                local eRoot = GetRoot(m)
                                if eRoot and (eRoot.Position - root.Position).Magnitude <= 300 then
                                    enemiesToHit[#enemiesToHit+1] = eRoot
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
                    if not fired then end
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
                        hum.AutoRotate    = false
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
                            if v.Name == _antiGravName then continue end
                            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition")
                            or v:IsA("LinearVelocity") or v:IsA("VectorForce") or v:IsA("AlignPosition") then
                                v:Destroy()
                            end
                        end
                        root.RotVelocity = Vector3.zero
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- [19] RUNSERVICE: STEPPED (NOCLIP)
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

local _backupNoclipGen = 0
local function _startBackupNoclip()
    _backupNoclipGen = _backupNoclipGen + 1
    local myGen = _backupNoclipGen
    task.spawn(function()
        while _G.DungeonScriptID == currentScriptID and myGen == _backupNoclipGen do
            local char = Player.Character
            if char then
                if char ~= _noclipCharRef then _rebuildNoclipCache(char) end
                for _, p in ipairs(_noclipParts) do
                    if p and p.Parent then p.CanCollide = false end
                end
            end
            if fakePlatform and fakePlatform.Parent then
                if not fakePlatform.CanCollide then fakePlatform.CanCollide = true end
                if fakePlatform.Transparency ~= 1 then fakePlatform.Transparency = 1 end
            end
            task.wait(0.05)
        end
    end)
end
_startBackupNoclip()

-- ==========================================
-- [19-B] CHARACTER DEATH + LIGHTNING DODGE
-- V16: Lightning: damage taken while lightning/thunder in Effects
--      → jump +10Y instantly, hold 1.5s at raised position, then resume mob targeting
-- ==========================================
local _antiGravName = "CVFD_AntiGravity"

local function OnCharacterDied()
    _G.AutoDungeon       = false
    IsFarmingReady       = false
    IsReadyToAttack      = false
    _G.SkillBlocking     = false
    _G.IsProcessingFruit = false
    _lightningDodging    = false
    CurrentTargetRoot    = nil
    TargetCFrame         = nil
    _meraUltDodging      = false
    ZoneState            = "FLYING"
    if fakePlatform and fakePlatform.Parent then
        fakePlatform.CFrame = CFrame.new(0, -9999, 0)
    end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local ag = root:FindFirstChild(_antiGravName)
        if ag then ag:Destroy() end
    end
end

local function HookCharacterDeath(char)
    if not char then return end
    local hum = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum then return end

    hum.Died:Connect(OnCharacterDied)

    local _prevHealth = hum.Health

    hum.HealthChanged:Connect(function(newHealth)
        local dmg = _prevHealth - newHealth
        _prevHealth = newHealth
        if dmg <= 0 or not IsFarmingReady then return end
        -- V16: check for lightning OR thunder event in Effects
        local lightningPresent = false
        local ef = workspace:FindFirstChild("Effects")
        if ef then
            for _, v in ipairs(ef:GetDescendants()) do
                if v:IsA("BasePart") then
                    local n = v.Name:lower()
                    if n:match("lightning") or n:match("thunder") then
                        lightningPresent = true; break
                    end
                end
            end
        end
        if not lightningPresent then return end

        -- Jump +10 studs instantly
        local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if r then
            r.CFrame = r.CFrame + Vector3.new(0, 10, 0)
        end

        -- V16: hold 1.5s at raised position, then let main loop resume mob targeting
        _lightningDodging   = true
        _lightningHoldUntil = tick() + 1.5
        task.delay(1.5, function()
            if _lightningDodging then
                _lightningDodging = false
                TargetCFrame      = nil  -- resume mob targeting via CurrentTargetRoot
            end
        end)
    end)
end

HookCharacterDeath(Player.Character)

Player.CharacterAdded:Connect(function(newChar)
    _noclipCharRef = nil
    _startBackupNoclip()
    HookCharacterDeath(newChar)
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
-- V16: AntiGrav cached per-frame (avoid FindFirstChild every Heartbeat)
-- ==========================================
local _antiGravCache = nil  -- V16: cache to avoid FindFirstChild every frame

local function _ensureAntiGrav(root)
    if _antiGravCache and _antiGravCache.Parent == root then return _antiGravCache end
    local ag = root:FindFirstChild(_antiGravName)
    if not ag then
        ag          = Instance.new("BodyVelocity")
        ag.Name     = _antiGravName
        ag.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        ag.Velocity = Vector3.zero
        ag.Parent   = root
    end
    _antiGravCache = ag
    return ag
end

local function _removeAntiGrav(root)
    if not root then return end
    local ag = root:FindFirstChild(_antiGravName)
    if ag then ag:Destroy() end
    _antiGravCache = nil
end

-- V16: cache footstep event
local _footstepEvent = ReplicatedStorage:FindFirstChild("Events")
    and ReplicatedStorage.Events:FindFirstChild("footstep") or nil
task.spawn(function()
    if not _footstepEvent then
        local ev = ReplicatedStorage:WaitForChild("Events", 10)
        if ev then _footstepEvent = ev:WaitForChild("footstep", 10) end
    end
end)

-- ==========================================
-- [20-A] HITBOX EXPAND — V16
-- ==========================================
task.spawn(function()
    local HITBOX_INTERVAL = 0.08
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsReadyToAttack and IsFarmingReady and not _G.IsProcessingFruit then
            pcall(function()
                if _footstepEvent and _footstepEvent.Parent then
                    _footstepEvent:FireServer()
                end
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local ag = root:FindFirstChild(_antiGravName)
                    if ag then
                        local lv = root.CFrame.LookVector
                        ag.Velocity = Vector3.new(lv.X * 2, 0, lv.Z * 2)
                    end
                end
            end)
        else
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

_G.CupidHeartbeat = RunService.Heartbeat:Connect(function(dt)
    if not _G.AutoDungeon then return end
    if not IsFarmingReady then
        if fakePlatform then fakePlatform.CFrame = CFrame.new(0, -9999, 0) end
        return
    end
    if _G.IsProcessingFruit then return end

    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root or not char.Parent then return end

    -- Fake platform follows player feet
    if fakePlatform then
        local platformY
        if IsReadyToAttack then
            platformY = root.Position.Y - 0.8
        else
            platformY = root.Position.Y - 3.7
        end
        fakePlatform.CFrame = CFrame.new(root.Position.X, platformY, root.Position.Z)
    end

    -- TARGET POSITION — always above mob head (V16: all zones consistent)
    local activeTargetPos = nil
    if CurrentTargetRoot and CurrentTargetRoot.Parent then
        local mobX  = CurrentTargetRoot.Position.X
        local mobY  = CurrentTargetRoot.Position.Y
        local mobZ  = CurrentTargetRoot.Position.Z
        local floorY = GetZoneFloor(CurrentZoneIndex, CachedZoneBoxCenters[CurrentZoneIndex])
        local targetY
        if floorY then
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

        local ag = _ensureAntiGrav(root)  -- V16: cached

        local newPos
        local dist = (currentPos - activeTargetPos).Magnitude
        if dist > 0.1 then
            local step      = math.min(MoveSpeed * effectiveDt, MAX_STEP_PER_FRAME, dist)
            local direction = (activeTargetPos - currentPos).Unit
            local stepVec   = direction * step
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

        if IsReadyToAttack then
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
        _removeAntiGrav(root)
    end
end)
