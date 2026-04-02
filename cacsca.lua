-- ==========================================
-- 🏹 SCRIPT: AUTO CUPID (V4 - IMPROVE)
-- Game: GET BETTER OUT | Cupid Dungeon
-- V4 Changes vs V3:
--   [1]  ❌ Removed AUTO BLOCK loop hoàn toàn
--   [2]  ⚡ Mob/statue/zone detection nhanh hơn + cache + workspace-wide scan
--   [3]  🎯 Tween FPS-safe: cap dt, cap step/frame, không bị teleport về
--   [4]  🛡️ Boss dodge: Firefly→block, Hiken→block, FlamePillar→40s, Entei→80s
--   [5]  💨 Stamina spoof noclip tích hợp trong Heartbeat tween
--   [6]  🔄 Replay: ImageButton + isServer attribute (decompile-accurate)
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
_G.SkillBlocking     = false  -- V4: controlled by TriggerSkillBlock()

print("▶️ Auto Cupid V4 (IMPROVE) — Session:", currentScriptID)

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
        table.insert(fields, {name = "🎁  Session Drops", value = "```diff\n- Không có Item / Fruit nào```", inline = false})
    end
    table.insert(fields, {
        name  = "📊  Thống kê",
        value = "```\nRare   : " .. #rareDrops
              .. "\nVIP    : " .. #vipDrops
              .. "\nNormal : " .. #normalDrops
              .. "\nTổng   : " .. #SessionItems .. "```",
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
    if shouldPing then payload["content"] = "@everyone 🚨 DROP HIẾM!" end

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
                        print("🔴 RARE:", rareName)
                    end
                end
            end
            for _, normalName in ipairs(NormalItems) do
                if string.find(txt, string.lower(normalName), 1, true) then
                    if not ProcessedLabels[label][normalName] then
                        ProcessedLabels[label][normalName] = true
                        table.insert(SessionItems, normalName .. " [ Normal Item ]")
                        print("🟢 ITEM:", normalName)
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

    -- Tìm nút replay theo đúng decompile
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
                    print("⏳ Bảng Replay hiện! Đợi 1.5s...")
                    task.wait(1.5)

                    local val      = btn:GetAttribute("buttonValue") or btn.Name
                    local isServer = prompt:GetAttribute("isServer")  -- bool từ decompile
                    local remote   = prompt:FindFirstChild("RemoteEvent")

                    local fired = false
                    if remote then
                        if isServer == true then
                            -- Decompile path: isServer → FireServer
                            pcall(function() remote:FireServer(val) end)
                            print("🚀 Replay (FireServer, isServer=true) val:", tostring(val))
                            fired = true
                        else
                            -- Decompile path: clientEvent:Fire(val)
                            local clientEvent = prompt:FindFirstChild("clientEvent")
                            if clientEvent then
                                pcall(function() clientEvent:Fire(val) end)
                                print("🚀 Replay (clientEvent:Fire) val:", tostring(val))
                                fired = true
                            else
                                -- clientEvent không tìm thấy, thử FireServer
                                pcall(function() remote:FireServer(val) end)
                                print("🚀 Replay (FireServer fallback) val:", tostring(val))
                                fired = true
                            end
                        end
                    end

                    if not fired then
                        -- Không có RemoteEvent, thử nil instances rồi VIM
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
                            print("🚀 Replay (Nil Remote) val:", tostring(val))
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
                            print("🖱️ Replay (VIM Click)")
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
    print("🔴 Replay loop thoát — Session:", currentScriptID)
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
local MoveSpeed     = 110
local AttackOffset  = 10    -- FIX: 10 thay vì 10.5, dùng chung cho flying & underground
local SearchRadius  = 800
local WaitSpawnTime = 6     -- giảm: chờ spawn tối đa 6s
local GatherTime    = 0.2   -- gather nhanh hơn
local DangerRadius  = 45
local EvadeDistance = 60

-- Khoảng cách né skill boss
local EVADE_ENTEI        = 130
local EVADE_FLAME_PILLAR = 75
local EVADE_BOSS_GENERIC = 100

-- Underground noclip (zone 7+8)
-- FIX: dùng mob.Y ± AttackOffset thay vì floorY - depth
-- → khoảng cách tới mob = AttackOffset (10), giống flying
local UNDERGROUND_DEPTH     = AttackOffset   -- = 10, đồng nhất với flying
local UNDERGROUND_DODGE_ADD = 10             -- thêm khi dodge (tổng 20 dưới mob)
local UNDERGROUND_LERP_SPEED = 80            -- studs/s smooth descent

-- Ground AoE (arrow rain, lightning): chui xuống dưới mob thay vì chạy xa
local GROUND_AOE_DEPTH = 20   -- studs dưới mob.Y khi né ground AoE

-- Giới hạn tween
local MAX_DT             = 0.1    -- 100ms cap — an toàn hơn ở FPS thấp
local MAX_STEP_PER_FRAME = 8      -- giảm từ 10 → server ít kick hơn khi FPS < 5

-- Thời gian đứng yên sau khi né dodge xong
local DODGE_RETURN_WAIT = 4  -- giây

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
local SkillBlockUntil   = 0
local CachedZoneFloors  = {}

-- Underground tracking
local _undergroundCurrentY = nil
local _isUndergroundMode   = false

-- Fix 1: track loại dodge để biết có cần BLOCK sau khi dodge không
local _currentDodgeIsAoe = false   -- true = general AoE → block sau khi dodge

-- Fix 3: smooth movement zone 7+8 — velocity accumulator
local _smoothPos    = nil  -- Vector3 vị trí smooth hiện tại (nil = chưa init)
local _smoothVelXZ  = Vector3.new(0,0,0)  -- XZ velocity

local IgnoredHazards = setmetatable({}, {__mode = "k"})
local CurrentHazard  = {Type = "None", Position = nil, Instance = nil, MinDist = DangerRadius, Action = "DODGE"}
local CurrentLava    = {Part = nil, Prompt = nil}
local IsFarmingReady    = false
local HasWaitedForLoad  = false

-- Fake platform chống fall damage
local fakePlatform = workspace:FindFirstChild("CupidFakePlatform")
if not fakePlatform then
    fakePlatform              = Instance.new("Part")
    fakePlatform.Name         = "CupidFakePlatform"
    fakePlatform.Size         = Vector3.new(15, 1, 15)
    fakePlatform.Anchored     = true
    fakePlatform.CanCollide   = true
    fakePlatform.Transparency = 0.5
    fakePlatform.Parent       = workspace
end

-- ==========================================
-- [5-A] STAMINA SPOOF — ALWAYS ON AGGRESSIVE
-- Fire TakeStam 2 lần song song mỗi 0.03s
-- Re-fetch TakeStam trong loop nếu nil
-- ==========================================
local Events   = ReplicatedStorage:WaitForChild("Events", 30)
local TakeStam = nil

local isSpoofingStamina = false

local function StartStaminaSpoof()
    if isSpoofingStamina then return end
    isSpoofingStamina = true
    task.spawn(function()
        while isSpoofingStamina and _G.DungeonScriptID == currentScriptID do
            if not TakeStam then
                pcall(function()
                    local ev = ReplicatedStorage:FindFirstChild("Events")
                    if ev then TakeStam = ev:FindFirstChild("takestam") end
                end)
            end
            if TakeStam then
                pcall(function() TakeStam:FireServer(0.545, "dash") end)
                task.defer(function()
                    pcall(function() TakeStam:FireServer(0.545, "dash") end)
                end)
            end
            task.wait(0.03)
        end
        isSpoofingStamina = false
    end)
end

local function StopStaminaSpoof() end  -- no-op

StartStaminaSpoof()

-- ==========================================
-- [5-B] SKILL BLOCK TRIGGER (V4 NEW)
-- Thay thế auto block loop.
-- Chỉ kích hoạt khi detect Firefly / Hiken.
-- Giữ F và fire BlockEvent trong `duration` giây rồi tự nhả.
-- ==========================================
local function TriggerSkillBlock(weaponName, duration)
    if _G.SkillBlocking then return end  -- Đang block rồi, bỏ qua
    _G.SkillBlocking = true
    SkillBlockUntil  = tick() + (duration or 2.5)

    task.spawn(function()
        pcall(function()
            local BlockEvent = ReplicatedStorage:WaitForChild("Events", 3):WaitForChild("Block", 3)
            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(true, weaponName or "Melee", false)
            else
                BlockEvent:FireServer(true, weaponName or "Melee", false)
            end
            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)

            task.wait(duration or 2.5)

            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(false, weaponName or "Melee", false)
            else
                BlockEvent:FireServer(false, weaponName or "Melee", false)
            end
            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
        _G.SkillBlocking = false
    end)
    print("🛡️ TriggerSkillBlock:", weaponName, "→", duration, "s")
end

-- ==========================================
-- [11] HÀM TIỆN ÍCH COMBAT
-- ==========================================
local function GetZoneFloor(zoneIndex, boxCenter)
    if CachedZoneFloors[zoneIndex] then return CachedZoneFloors[zoneIndex] end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        Player.Character, fakePlatform,
        workspace:FindFirstChild("Effects"),
        workspace:FindFirstChild("Enemies"),
    }
    local result = workspace:Raycast(boxCenter, Vector3.new(0, -300, 0), params)
    if result then CachedZoneFloors[zoneIndex] = result.Position.Y; return result.Position.Y end
    return boxCenter.Y - 10
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
    -- Dùng cache nếu còn hạn và đúng zone
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
        -- FIX: bọc pcall để tránh fail silent khi humanoid đang stun/ragdoll
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

local function IsMobAttacking(hum)
    local isAttacking = false
    pcall(function()
        local animator = hum:FindFirstChild("Animator") or hum
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Weight > 0.01 and track.Animation then
                local n = track.Animation.Name:lower()
                if not (n:match("idle") or n:match("walk") or n:match("run") or n:match("stun") or n:match("hit")) then
                    if n:match("attack") or n:match("slash")  or n:match("punch")  or
                       n:match("swing")  or n:match("cast")   or n:match("skill")  or
                       n:match("m1")     or n:match("slam")   or n:match("smash")  or
                       n:match("charge") or n:match("burst")  or n:match("combo")  or
                       n:match("shoot")  or n:match("fire")   or n:match("gun")    or
                       n:match("ranged") or n:match("magic")  or n:match("throw")  or n:match("shot") then
                        isAttacking = true; break
                    end
                end
            end
        end
    end)
    return isAttacking
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
                                _isUndergroundMode    = false
                                _undergroundCurrentY  = nil
                                StopStaminaSpoof()
                                task.wait(5)
                                CurrentZoneIndex = 1
                                ZoneState        = "FLYING"
                                IsFarmingReady   = true
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

local function DoMapOptimize()
    if _mapOptimized then return end
    _mapOptimized = true
    task.spawn(function()

        -- [A] Lighting
        pcall(function()
            local L = game:GetService("Lighting")
            L.GlobalShadows = false
            L.FogEnd        = 9e9
            L.Brightness    = 2
            L.ClockTime     = 14
            L.Ambient       = Color3.fromRGB(178, 178, 178)
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

        -- [B] Render quality — thử cả 2 cách phổ biến nhất trong executors
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end)

        -- [C] Terrain
        pcall(function()
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                t.Decoration       = false
                t.WaterWaveSize    = 0
                t.WaterWaveSpeed   = 0
                t.WaterReflectance = 0
                t.WaterTransparency = 1
                t.CastShadow       = false
            end
        end)

        -- [D] Effects & Projectiles — ẩn visual, giữ BasePart để detect
        for _, fname in ipairs({"Effects", "Projectiles"}) do
            local f = workspace:FindFirstChild(fname)
            if f then HideFolderEffects(f) end
            workspace.ChildAdded:Connect(function(child)
                if child.Name == fname then
                    task.defer(function() HideFolderEffects(child) end)
                end
            end)
        end

        -- [E] Toàn bộ workspace — tắt shadow + particles + non-collision parts
        task.spawn(function()
            for _, desc in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if desc:IsA("ParticleEmitter") or desc:IsA("Beam")
                    or desc:IsA("Trail") or desc:IsA("Fire")
                    or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                        desc.Enabled = false
                    elseif desc:IsA("BasePart") and not desc:IsA("Terrain") then
                        desc.CastShadow = false
                        -- Ẩn hoàn toàn parts trang trí không có collision
                        if not desc.CanCollide then
                            desc.LocalTransparencyModifier = 1
                        end
                    elseif desc:IsA("Sound") then
                        -- Tắt hầu hết âm thanh ambient
                        if desc.Parent and not (desc.Parent == Player.Character) then
                            desc.Volume = 0
                        end
                    end
                end)
            end
            -- Auto-hide mọi thứ mới spawn vào workspace
            workspace.DescendantAdded:Connect(function(inst)
                task.defer(function()
                    pcall(function()
                        if inst:IsA("ParticleEmitter") or inst:IsA("Beam")
                        or inst:IsA("Trail") or inst:IsA("Fire")
                        or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                            inst.Enabled = false
                        elseif inst:IsA("BasePart") and not inst:IsA("Terrain")
                        and not (Player.Character and inst:IsDescendantOf(Player.Character)) then
                            inst.CastShadow = false
                            if not inst.CanCollide then
                                inst.LocalTransparencyModifier = 1
                            end
                        end
                    end)
                end)
            end)
        end)

        print("🗺️ Map Optimized OK")
    end)
end

-- Gọi ngay khi load script — không chờ dungeon entry
DoMapOptimize()

-- Chạy optimize ngay khi vào dungeon (gọi từ [12] sau IsFarmingReady = true)
-- Và auto re-hide khi có effect mới spawn (DescendantAdded đã connect trong HideFolderEffects)

-- ==========================================
-- [14] HAZARD SCANNER (V5 — EVENT-DRIVEN QUEUE)
--
-- FIX PERFORMANCE: Thay CollectDescendants(workspace, 4) mỗi 20ms
-- bằng workspace.DescendantAdded event queue.
-- Chỉ process instance MỚI khi nó spawn vào game → không scan lại toàn bộ workspace.
-- CPU load giảm ~95% so với cách cũ.
-- ==========================================

-- Priority thấp hơn = quan trọng hơn
-- BossSkillDefs: CHỈ Enkai/Entei
-- FlamePillar, Firefly, Hiken → xử lý bởi general AoE scanner (DODGE 40 + BLOCK)
-- Underground zone (7+8): Enkai → đứng yên sâu hơn 5 studs, đợi hết chiêu
local BossSkillDefs = {
    {pattern = "enkai",  action = "DODGE_DEEP", evadeDist = EVADE_ENTEI, priority = 1, noRadius = true},
    {pattern = "en_kai", action = "DODGE_DEEP", evadeDist = EVADE_ENTEI, priority = 1, noRadius = true},
    {pattern = "entei",  action = "DODGE_DEEP", evadeDist = EVADE_ENTEI, priority = 1, noRadius = true},
}

-- Instance tên match những pattern này → bỏ qua hoàn toàn (không log, không react)
local IGNORE_NAME_PATTERNS = {
    "dmgind", "hitbox", "hurtbox", "indicator", "number",
    "billboard", "sfx", "sound", "particle", "debris",
    "decal", "highlight", "selection", "tag", "gui",
}

-- Khoảng cách tối đa để xét instance là nguy hiểm (boss zone)
local BOSS_PROX_RADIUS = 180  -- studs

-- Lấy vị trí instance — BasePart đệ quy
local function GetInstPos(inst)
    if not inst then return nil end
    local pos = nil
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

-- ==========================================
-- Queue-based: workspace.DescendantAdded đẩy instance vào queue
-- Scan loop chỉ drain queue → không tốn CPU scan lại toàn workspace
-- ==========================================
local _newInstQueue    = {}   -- queue drain mỗi scan tick
local _checkedInsts    = setmetatable({}, {__mode = "k"})  -- đã check (weak)
local _loggedUnknown   = setmetatable({}, {__mode = "k"})

-- Connect một lần duy nhất
local _descAddedConn
_descAddedConn = workspace.DescendantAdded:Connect(function(inst)
    if _G.DungeonScriptID ~= currentScriptID then
        _descAddedConn:Disconnect(); return
    end
    -- Chỉ quan tâm BasePart và Model (có vị trí)
    if inst:IsA("BasePart") or inst:IsA("Model") then
        _newInstQueue[#_newInstQueue + 1] = inst
    end
end)

-- Lấy vị trí instance — BasePart đệ quy
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

-- Drain queue và check hazard — chỉ xử lý instance mới spawn
-- Returns bestDef, bestInst, bestPos
local function DrainQueueScan(playerPos)
    if #_newInstQueue == 0 then return nil, nil, nil end

    -- Ambil queue hiện tại, reset cho lần sau
    local queue = _newInstQueue
    _newInstQueue = {}

    local bestDef, bestInst, bestPos

    local char = Player.Character
    for _, v in ipairs(queue) do
        -- Bỏ qua nếu đã check, không còn trong game, hoặc là của char
        if _checkedInsts[v] then continue end
        if not v:IsDescendantOf(workspace) then continue end
        if char and v:IsDescendantOf(char) then continue end
        _checkedInsts[v] = true

        -- Ignore noise patterns
        local n = v.Name:lower()
        local skip = false
        for _, pat in ipairs(IGNORE_NAME_PATTERNS) do
            if n:find(pat, 1, true) then skip = true; break end
        end
        if skip then continue end

        local vPos = GetInstPos(v)
        if not vPos then continue end

        local dist = (Vector2.new(vPos.X, vPos.Z) - Vector2.new(playerPos.X, playerPos.Z)).Magnitude

        for _, def in ipairs(BossSkillDefs) do
            local inRadius = def.noRadius or (dist <= BOSS_PROX_RADIUS)
            if inRadius and (not bestDef or def.priority < bestDef.priority) and n:match(def.pattern) then
                print("⚠️ [HazardQ] NEW:", v.Name, "→", def.action, "dist:", math.floor(dist))
                bestDef  = def
                bestInst = v
                bestPos  = vPos
            end
        end

        -- Log unknown gần player
        if not bestDef and dist <= BOSS_PROX_RADIUS and not _loggedUnknown[v] then
            _loggedUnknown[v] = true
            print("🔍 [HazardQ] UNKNOWN:", v.Name, "dist:", math.floor(dist), "|", v:GetFullName())
        end
    end

    return bestDef, bestInst, bestPos
end

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                -- Dọn hazard hết hạn
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

                -- Boss skill scan (zone >= 5) — event-driven queue
                if CurrentZoneIndex >= 5 then
                    local def, inst, pos = DrainQueueScan(playerPos)
                    if def and inst then
                        detectedHazard  = "BossSkill"
                        hazardAction    = def.action
                        hazardEvadeDist = def.evadeDist
                        hazardInst      = inst
                        if def.action == "DODGE" and pos then
                            hazardPos = pos
                        elseif CurrentTargetRoot and CurrentTargetRoot.Parent then
                            hazardPos = CurrentTargetRoot.Position
                        else
                            hazardPos = playerPos
                        end
                    end
                end

                -- General AoE + Lava Curse (mọi zone)
                -- Arrow rain / lightning / AoE → DODGE 40 studs như cũ
                if detectedHazard == "None" then
                    local effectsFolder = workspace:FindFirstChild("Effects")
                    if effectsFolder then
                        local minDist = DangerRadius
                        for _, v in ipairs(effectsFolder:GetChildren()) do
                            local name = v.Name:lower()
                            local vPos = GetInstPos(v)
                            if vPos and not IgnoredHazards[v] then
                                local dist = (Vector2.new(vPos.X, vPos.Z) - Vector2.new(playerPos.X, playerPos.Z)).Magnitude
                                if (name:match("aoe") or name:match("circle") or name:match("bomb")
                                or name:match("meteor") or name:match("arrow") or name:match("rain")
                                or name:match("lightning") or name:match("projectile"))
                                and dist < minDist then
                                    detectedHazard  = "Normal"
                                    hazardPos       = vPos
                                    minDist         = dist
                                    hazardInst      = v
                                    hazardAction    = "DODGE"
                                    hazardEvadeDist = 40
                                end
                                if name:match("lava") and name:match("curse") and dist < 1500 then
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
        -- Boss zone quét 0.02s, zone 5-6 quét 0.04s, bình thường 0.06s
        local scanInterval = IsFarmingReady and (
            CurrentZoneIndex >= 7 and 0.02 or
            CurrentZoneIndex >= 5 and 0.04 or 0.06
        ) or 0.1
        task.wait(scanInterval)
    end
end)

-- ==========================================
-- [15] MAIN ZONE LOGIC + END GAME
-- ==========================================
task.spawn(function()
    local lastZone      = 0
    local isHoldingLava = false

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                -- Invalidate mob cache khi đổi zone
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
                    if ZoneState == "ABSORBING_CURSE" then ZoneState = PreviousZoneState or "FLYING" end
                end

                -- ── SKILL_BLOCKING đã được xử lý background trong TriggerSkillBlock
                -- ZoneState không còn bị đổi sang SKILL_BLOCKING nữa
                -- → attack loop tiếp tục bình thường khi đỡ Firefly / Hiken

                -- ── DODGE TRIGGER ────────────────────────────────────────────
                if CurrentZoneIndex ~= 5 and CurrentHazard.Type ~= "None"
                and ZoneState ~= "DODGING" then

                    local action    = CurrentHazard.Action  or "DODGE"
                    local evadeDist = CurrentHazard.MinDist or EvadeDistance
                    if CurrentHazard.Instance then
                        IgnoredHazards[CurrentHazard.Instance] = tick() + 8
                    end
                    if ZoneState ~= "ABSORBING_CURSE" then PreviousZoneState = ZoneState end
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil

                    if action == "DODGE_DEEP" and _isUndergroundMode then
                        -- FIX 2: Enkai ở zone 7+8 → đứng yên sâu hơn 5 studs, không di chuyển XZ
                        -- Đợi hết chiêu rồi bay lên đánh lại
                        ZoneState = "DODGING"
                        _currentDodgeIsAoe = false
                        local deeperY = (_undergroundCurrentY or root.Position.Y) - 5
                        TargetCFrame = CFrame.new(root.Position.X, deeperY, root.Position.Z)
                        DodgeTimer = tick() + DODGE_RETURN_WAIT  -- đứng yên chờ
                        print("⬇️ DODGE_DEEP underground: Enkai → sâu thêm 5 studs, đứng yên", DODGE_RETURN_WAIT, "s")

                    else
                        -- DODGE thường (Enkai ở zone 1-6, general AoE, v.v.)
                        ZoneState = "DODGING"
                        _currentDodgeIsAoe = (CurrentHazard.Type == "Normal")  -- chỉ AoE thường mới BLOCK sau

                        local evadeDir = (root.Position - CurrentHazard.Position)
                        if evadeDir.Magnitude < 0.1 then
                            local rand = math.random(0, 3)
                            evadeDir = ({
                                Vector3.new(1,0,0), Vector3.new(-1,0,0),
                                Vector3.new(0,0,1), Vector3.new(0,0,-1)
                            })[rand+1]
                        end
                        local flatDir = Vector3.new(evadeDir.X, 0, evadeDir.Z)
                        -- Giữ Y hiện tại → không thay đổi độ cao khi dodge
                        DodgeTimer   = tick() + (evadeDist / MoveSpeed) + DODGE_RETURN_WAIT
                        TargetCFrame = CFrame.new(root.Position + flatDir.Unit * evadeDist)
                        print("🏃 DODGE:", CurrentHazard.Instance and CurrentHazard.Instance.Name or "Normal",
                              action, "→", evadeDist, "studs | aoe=", _currentDodgeIsAoe)
                    end
                end

                if ZoneState == "DODGING" then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    if tick() > DodgeTimer then
                        ZoneState          = PreviousZoneState or "ATTACKING"
                        CurrentHazard.Type = "None"
                        -- FIX 1: general AoE → BLOCK sau khi dodge xong
                        if _currentDodgeIsAoe then
                            _currentDodgeIsAoe = false
                            local char2 = Player.Character
                            local wpn2  = char2 and char2:FindFirstChildOfClass("Tool")
                            TriggerSkillBlock(wpn2 and wpn2.Name or "Melee", 2.5)
                            print("🛡️ BLOCK sau AoE dodge")
                        end
                        print("✅ DODGE xong → quay lại:", ZoneState)
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

                    -- Zone 7 & 8: đứng dưới lòng đất thay vì bay
                    -- Zone khác: bay trên đầu mob (floorY + 40 / floorY + 20)
                    local isUnderground = (CurrentZoneIndex >= 7)
                    local waitPos
                    if isUnderground then
                        waitPos = Vector3.new(boxCenter.X, floorY - UNDERGROUND_DEPTH, boxCenter.Z)
                        _isUndergroundMode = true
                    else
                        waitPos = Vector3.new(boxCenter.X, floorY + 20, boxCenter.Z)
                        _isUndergroundMode = false
                        _undergroundCurrentY = nil
                    end

                    local mobs = GetMobsInZone(boxCenter)

                    if ZoneState == "FLYING" then
                        local targetY
                        if isUnderground then
                            targetY = floorY - UNDERGROUND_DEPTH
                        else
                            targetY = math.max(root.Position.Y, floorY + 40)
                        end
                        TargetCFrame = CFrame.new(Vector3.new(boxCenter.X, targetY, boxCenter.Z))
                        CurrentTargetRoot = nil
                        local xzDist = (Vector2.new(root.Position.X, root.Position.Z)
                                      - Vector2.new(boxCenter.X, boxCenter.Z)).Magnitude
                        if xzDist < 15 then
                            if CurrentZoneIndex == 5 then
                                ZoneState = "ZONE5_SURVIVAL"; Timer = tick() + 30; Z5Index = 1
                            else
                                -- Nếu đã có mob ngay → attack luôn, không chờ
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
                        -- FIX: đứng ở waitPos nhưng KHÔNG reset mỗi frame
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
                            -- Target mob gần nhất
                            local bestMob, bestD = mobs[1], math.huge
                            for _, m in ipairs(mobs) do
                                local mr = GetRoot(m)
                                if mr then
                                    local d = (mr.Position - root.Position).Magnitude
                                    if d < bestD then bestD = d; bestMob = m end
                                end
                            end
                            CurrentTargetRoot = GetRoot(bestMob)
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
-- Chỉ block khi detect Firefly hoặc Hiken
-- ==========================================

-- ==========================================
-- [17] AUTO ATTACK — FPS-RESILIENT
-- Vấn đề cũ: task.wait(0.366) với FPS < 5:
--   - task.wait có thể trả về sau 0.1s-1s tuỳ frame budget
--   - FPS drop → yield dài → attack thưa; freeze → yield ngắn → double-fire
-- Fix: track _lastFireTime bằng tick() thực tế
--   → chỉ fire khi đã đủ strikeDelay thực (không phụ thuộc task.wait)
--   → freeze/FPS drop không gây double-fire hay bỏ đòn
-- ==========================================
task.spawn(function()
    local CombatRegister   = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
    local CombatAnimFolder = ReplicatedStorage:WaitForChild("CombatAnimations")
    local currentCombo     = 1
    local strikeDelay      = 0.366   -- giây giữa 2 đòn
    local comboResetDelay  = 1.0
    local _lastFireTime    = 0       -- tick() lần fire cuối

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsReadyToAttack and IsFarmingReady and not _G.IsProcessingFruit then
            local char = Player.Character
            if char and char.Parent then
                local now = tick()
                -- FPS guard: chỉ fire khi đã đủ strikeDelay kể từ lần trước
                if now - _lastFireTime >= strikeDelay then
                    local fired = false
                    pcall(function()
                        local tool           = CheckAndEquipWeapon()
                        local realWeaponName = tool and tool.Name or "Melee"
                        local weaponType, fakeAnim = GetAttackAnim(realWeaponName, currentCombo)

                        if not fakeAnim then
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
                                    enemiesToHit[#enemiesToHit+1] = m
                                    if not primaryCFrame then primaryCFrame = eRoot.CFrame end
                                end
                            end
                        end
                        if not primaryCFrame and root then primaryCFrame = root.CFrame end

                        if #enemiesToHit > 0 and primaryCFrame then
                            _lastFireTime = now   -- stamp TRƯỚC khi spawn để không double-fire
                            fired = true
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
                                pcall(function()
                                    CombatRegister:InvokeServer({
                                        [1]="damage",[2]=targets,[3]=wType,
                                        [4]={[1]=combo,[2]="Ground",[3]=wType},
                                        [5]=true,[6]=pCF,["aircombo"]="Ground"
                                    })
                                end)
                            end)
                            currentCombo = currentCombo + 1
                        end
                    end)
                    if not fired then
                        -- Không có enemy hoặc anim — đừng stamp time, thử lại ngay
                    end
                end
            end
        else
            currentCombo  = 1
            _lastFireTime = 0
        end
        -- Poll nhanh để không bỏ lỡ strike window dù FPS thấp
        task.wait(0.05)
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
                        hum.AutoRotate    = true
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
                            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition")
                            or v:IsA("LinearVelocity") or v:IsA("VectorForce") or v:IsA("AlignPosition") then
                                v:Destroy()
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- [19] RUNSERVICE: STEPPED (ANTI STUN/FREEZE + NOCLIP)
-- Noclip improvement: apply CanCollide=false toàn bộ descendants
-- (bao gồm accessories, tools, mesh parts) không chỉ children
-- ==========================================
local _noclipLastApply = 0
local NOCLIP_APPLY_INTERVAL = 0.08  -- apply CanCollide mỗi 80ms (không cần mỗi frame)

_G.CupidStepped = RunService.Stepped:Connect(function()
    if not _G.AutoDungeon or not IsFarmingReady then return end
    if _G.IsProcessingFruit then return end
    local char = Player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not char or not char.Parent then return end

    pcall(function()
        _G.canuse  = true
        _G.midM1   = false
        _G.knocked = false
        _G.ragdoll = false
        _G.stunned = false
        _G.zombie  = false
        if not _G.SkillBlocking then _G.blocking = false end

        if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end

        -- Attributes anti-stun
        for attr in pairs(char:GetAttributes()) do
            if type(attr) == "string" then
                local a = attr:lower()
                if a:match("stun") or a:match("busy") or a:match("freeze")
                or a:match("knock") or a:match("ragdoll") or a:match("zombie") or a:match("down") then
                    char:SetAttribute(attr, nil)
                end
            end
        end

        -- Noclip: apply mỗi NOCLIP_APPLY_INTERVAL giây để không chạy mỗi frame
        local now = tick()
        if now - _noclipLastApply >= NOCLIP_APPLY_INTERVAL then
            _noclipLastApply = now
            -- Apply toàn bộ descendants (bao gồm accessories, tool handles, v.v.)
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide      = false
                    v.CastShadow      = false  -- giảm shadow calculation
                elseif v:IsA("ValueBase") then
                    local n = v.Name:lower()
                    if n:match("stun") or n:match("knock") or n:match("ragdoll")
                    or n:match("zombie") or n:match("busy") then
                        v:Destroy()
                    end
                else
                    local name = v.Name:lower()
                    if name:match("stun") or name:match("knock")
                    or name == "ragdoll" or name == "zombie" then
                        v:Destroy()
                    end
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
local isMovingForStamina = false
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

    -- Fake platform theo chân player
    if fakePlatform then
        fakePlatform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.2, root.Position.Z)
    end

    -- ── UNDERGROUND Y LERP ────────────────────────────────────────────
    -- Zone 7+8: Y target = mob.Y - UNDERGROUND_DEPTH (hoặc sâu hơn khi dodging Enkai)
    local undergroundY = nil
    if _isUndergroundMode then
        local refY = nil
        if CurrentTargetRoot and CurrentTargetRoot.Parent then
            refY = CurrentTargetRoot.Position.Y
        else
            refY = CachedZoneFloors[CurrentZoneIndex]
        end
        if refY then
            -- Nếu đang DODGING Enkai underground: sâu thêm 5 studs nữa
            local targetUnderY = refY - UNDERGROUND_DEPTH
            if ZoneState == "DODGING" and not _currentDodgeIsAoe then
                targetUnderY = targetUnderY - 5
            end
            if _undergroundCurrentY == nil then
                _undergroundCurrentY = root.Position.Y
            end
            local yDiff   = targetUnderY - _undergroundCurrentY
            local maxStep = UNDERGROUND_LERP_SPEED * math.min(dt, MAX_DT)
            -- Exponential approach: nhanh khi xa, chậm khi gần → cực mượt
            local expStep = math.abs(yDiff) * (1 - math.exp(-10 * math.min(dt, MAX_DT)))
            local step    = math.min(math.max(expStep, 0.01), maxStep)
            _undergroundCurrentY = math.abs(yDiff) <= 0.05
                and targetUnderY
                or (_undergroundCurrentY + math.sign(yDiff) * step)
            undergroundY = _undergroundCurrentY
        end
    else
        if _undergroundCurrentY ~= nil then
            _undergroundCurrentY = nil
            _smoothPos = nil  -- reset smooth pos khi thoát underground
        end
    end

    -- ── TARGET POSITION ───────────────────────────────────────────────
    local activeTargetPos = nil
    if CurrentTargetRoot and CurrentTargetRoot.Parent then
        local mobX = CurrentTargetRoot.Position.X
        local mobY = CurrentTargetRoot.Position.Y
        local mobZ = CurrentTargetRoot.Position.Z
        if undergroundY then
            activeTargetPos = Vector3.new(mobX, undergroundY, mobZ)
        else
            activeTargetPos = Vector3.new(mobX, mobY + AttackOffset, mobZ)
        end
    elseif TargetCFrame then
        if undergroundY and ZoneState ~= "DODGING" then
            local tp = TargetCFrame.Position
            activeTargetPos = Vector3.new(tp.X, undergroundY, tp.Z)
        else
            activeTargetPos = TargetCFrame.Position
        end
    end

    if activeTargetPos then
        local currentPos  = root.Position
        local effectiveDt = math.min(dt, MAX_DT)

        -- ── FIX 3: SMOOTH MOVEMENT ZONE 7+8 ────────────────────────────
        -- Zone 1-6: lerp đơn giản, nhanh
        -- Zone 7+8: exponential smoothing riêng cho XZ và Y
        --   → không jitter, không snap, cực mượt dù FPS thấp
        local newPos
        if _isUndergroundMode then
            -- Init smooth pos nếu chưa có
            if _smoothPos == nil then _smoothPos = currentPos end

            -- XZ: exponential approach với acceleration cap
            local targetXZ  = Vector3.new(activeTargetPos.X, _smoothPos.Y, activeTargetPos.Z)
            local xzDist    = (Vector3.new(_smoothPos.X, 0, _smoothPos.Z)
                             - Vector3.new(activeTargetPos.X, 0, activeTargetPos.Z)).Magnitude
            -- Tốc độ XZ: smooth curve — nhanh khi xa (>5 studs), chậm dần khi gần
            local xzSpeed
            if xzDist > 20 then
                xzSpeed = MoveSpeed
            elseif xzDist > 5 then
                -- Ramp down: tránh overshoot khi đến gần
                xzSpeed = MoveSpeed * (0.3 + 0.7 * (xzDist / 20))
            else
                -- Cực gần: creepcrawl để không jitter
                xzSpeed = MoveSpeed * 0.3
            end
            local xzStep    = math.min(xzSpeed * effectiveDt, MAX_STEP_PER_FRAME, xzDist)
            local newXZ     = xzDist > 0.05
                and Vector3.new(_smoothPos.X, 0, _smoothPos.Z)
                   + (Vector3.new(activeTargetPos.X, 0, activeTargetPos.Z)
                   - Vector3.new(_smoothPos.X, 0, _smoothPos.Z)).Unit * xzStep
                or Vector3.new(activeTargetPos.X, 0, activeTargetPos.Z)

            -- Y: đã xử lý bởi undergroundY lerp ở trên — dùng trực tiếp
            _smoothPos = Vector3.new(newXZ.X, undergroundY or _smoothPos.Y, newXZ.Z)
            newPos     = _smoothPos

        else
            -- Zone thường: lerp đơn giản
            _smoothPos = nil
            local dist = (currentPos - activeTargetPos).Magnitude
            if dist > 0.3 then
                local rawStep    = MoveSpeed * effectiveDt
                local cappedStep = math.min(rawStep, MAX_STEP_PER_FRAME)
                newPos = currentPos + (activeTargetPos - currentPos).Unit
                         * math.min(cappedStep, dist)
            else
                newPos = activeTargetPos
            end
        end

        -- ── ROTATION ─────────────────────────────────────────────────
        if IsReadyToAttack then
            if _isUndergroundMode then
                -- Zone 7+8 underground: đứng thẳng, mặt hướng mob theo XZ
                if CurrentTargetRoot and CurrentTargetRoot.Parent then
                    local flat = Vector3.new(
                        CurrentTargetRoot.Position.X - newPos.X, 0,
                        CurrentTargetRoot.Position.Z - newPos.Z)
                    if flat.Magnitude > 0.1 then
                        root.CFrame = CFrame.new(newPos, newPos + flat.Unit)
                    else
                        root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                    end
                else
                    root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                end
            else
                -- Zone thường (bay): giữ nguyên -90 tilt để attack đúng hướng
                local _, currentYaw, _ = root.CFrame:ToOrientation()
                root.CFrame = CFrame.new(newPos)
                    * CFrame.Angles(0, currentYaw, 0)
                    * CFrame.Angles(math.rad(-90), 0, 0)
            end
        else
            local flatDir = Vector3.new(
                activeTargetPos.X - currentPos.X, 0,
                activeTargetPos.Z - currentPos.Z)
            if flatDir.Magnitude > 0.01 then
                -- Zone 7+8: lerp rotation chậm hơn để không xoay giật
                local rotSpeed   = _isUndergroundMode and 8 or 12
                local lerpFactor = 1 - math.exp(-rotSpeed * effectiveDt)
                local targetRot  = CFrame.lookAt(newPos, newPos + flatDir.Unit)
                local smoothRot  = root.CFrame:Lerp(targetRot, lerpFactor).Rotation
                root.CFrame = CFrame.new(newPos) * smoothRot
            else
                root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
            end
        end

        if IsReadyToAttack and ZoneState ~= "ABSORBING_CURSE" then
            if hum then
                root.Velocity = Vector3.new(
                    root.CFrame.LookVector.X * hum.WalkSpeed, 0,
                    root.CFrame.LookVector.Z * hum.WalkSpeed)
            end
            root.RotVelocity = Vector3.new(0, 0, 0)
            pcall(function()
                if hum then hum:Move(Vector3.new(0.01, 0, 0.01), false) end
                if _footstepEvent then _footstepEvent:FireServer() end
            end)
        end
    else
        -- Không có target: reset smooth pos
        if _smoothPos then _smoothPos = nil end
    end
end)
