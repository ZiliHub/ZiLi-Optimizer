-- ==========================================
-- 🏹 SCRIPT: AUTO CUPID (V28)
-- Changes vs V27:
--   [1] Auto block REMOVED for zone 7 & 8
--   [2] Skill detection by asset ID:
--         Flame Pillar (5244141327) → dodge 70 studs
--         Hiken        (5220917407) → hold block
--         Firefly      (13243427337)→ hold block
--         meraUltMax=true           → dodge 115 studs, =nil → resume combat
--   [3] Zone 8 damage sensor: any HP loss → TP +10Y, hold 2s, return to mob
-- ==========================================
local WebhookURL = "https://discord.com/api/webhooks/1472994959404564490/D2gxRseTIKywjtkfRV8xvl1ra2fJ5rVRKtmJYIu23LRIXf_4wD6pbuto07WNzD20DVG4"
local LogoZiLi = "https://cdn.discordapp.com/attachments/1482474210243907747/1482474407300698132/0f77b7f8-7648-4aa3-bf67-545da725301a.png"
local NormalThumb = "https://api.rblx.solutions/v1/asset/thumbnail/108561234878560"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- [GUARD] KICK NẾU CÓ NGƯỜI JOIN SERVER
local function CheckPlayers()
    if #Players:GetPlayers() > 1 then
        local reason = "Another player joined the server — solo-only protection."
        _sessionKickReason = reason
        SendKickWebhookEarly(reason, CurrentZoneIndex or 0)
        task.wait(1)
        Player:Kick("You are banned. if you think this is a false ban, please contact the support team via discord with sufficient evidence.")
    end
end
Players.PlayerAdded:Connect(CheckPlayers)
CheckPlayers()

-- Stamina spoof
local success, Remote = pcall(function()
    return ReplicatedStorage:WaitForChild("Events"):WaitForChild("takestam")
end)
if success and Remote then
    task.spawn(function()
        local staminaCost = 1.075
        local actionType = "dash"
        local spamSpeed = 0.05
        while task.wait(spamSpeed) do
            if not Remote or not Remote.Parent then break end
            pcall(function() Remote:FireServer(staminaCost, actionType) end)
        end
    end)
end

-- Auto equip title
task.spawn(function()
    pcall(function()
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Titles"):InvokeServer("Cupid's Nemesis")
    end)
end)

-- Rare item → permanent postimg URL (drives thumbnail + image in webhook)
local RareImages = {
    ["Cupid's All Seeing Eye"]    = "https://i.postimg.cc/85NCJCWN/Cupid27s_All_Seeing_Eye.webp",
    ["Leo's Inferno Hagoromo"]    = "https://i.postimg.cc/63tQ2QRW/l_Hagoromo.webp",
    ["Prestige Cupid's Chakram"]  = "https://i.postimg.cc/k4q5658X/Chat_GPT_Image_03_16_32_15_thg_3_2026.webp",
    ["Cupid Queen's Maid Outfit"] = "https://i.postimg.cc/63tQ2QR6/cupid_maid_fit.webp",
}
local NormalItems = {
    "Cupid's Harp", "Leo's Blazing Scarf", "Love Shades", "Cupid's Wand",
    "Love Boppers Headband", "Cupid's Battleaxe", "Leo's Blazing Regalia",
    "Virtuous Cupid Queen's Wings", "Maid Outfit", "SP Reset Essence",
    "Virtuous Cupid Queen's Outfit", "Cupid's Chakram"
}
local VIP_Fruits = {"dragon","soul","mochi","venom","tori","pteranodon","ope","buddha","pika","mera","yami","smoke","kage","paw","goru","yuki","magu","suna","goro","hie","gura","zushi"}
local TRASH_Fruits = {"spin","suke","kilo","heal","bari","mero","horo","yomi","bomb","gomu","kira","spring"}

local DungeonStartTime = tick()
local DungeonClearTimeStr = "00:00"
local SessionItems = {}
local ProcessedItems = {}
local ProcessedUITexts = {}
local WebhookSentForSession = false
_G.IsProcessingFruit = false
_G.EndGameStarted = false
_G.GoToPortal = false

-- Forward-declared so the player-guard (above webhook section) can reference them
local _sessionDeathZone  = nil
local _sessionKickReason = nil
local CurrentZoneIndex   = 1  -- will be re-declared below; this just satisfies the guard

local function _SendRawEarly(payload)
    local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not req then return end
    pcall(function()
        req({Url = WebhookURL, Method = "POST",
             Headers = {["Content-Type"] = "application/json"},
             Body = HttpService:JSONEncode(payload)})
    end)
end

local function SendKickWebhookEarly(reason, zone)
    _SendRawEarly({
        embeds = {{
            author = {name = "🚫  Auto Cupid Farm  •  ZiLi Hub", icon_url = LogoZiLi},
            title  = "🚫  Player Kicked / Banned",
            color  = 0xFF0000,
            description = "━━━━━━━━━━━━━━━━━━━━━━\n"
                .. "👤  **Player:** ||" .. Player.Name .. "||\n"
                .. "📝  **Reason:** `" .. tostring(reason) .. "`\n"
                .. "🗺️  **Zone at time:** Zone `" .. tostring(zone) .. "`\n"
                .. "━━━━━━━━━━━━━━━━━━━━━━",
            footer    = {text = "ZiLi Hub  •  " .. os.date("%d/%m/%Y  %H:%M:%S"), icon_url = LogoZiLi},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    })
end

-- ==========================================
-- [1] WEBHOOK — Full English, fields layout, image preview
-- ==========================================
local function SendRaw(payload)
    local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if req then
        task.spawn(function()
            pcall(function()
                req({Url = WebhookURL, Method = "POST",
                     Headers = {["Content-Type"] = "application/json"},
                     Body = HttpService:JSONEncode(payload)})
            end)
        end)
    end
end

local function SendWebhook()
    if WebhookSentForSession then return end
    WebhookSentForSession = true

    local rareDrops, vipDrops, normalDrops = {}, {}, {}
    local shouldPing = false
    for _, item in ipairs(SessionItems) do
        if item:match("%[RARE%]") then
            table.insert(rareDrops, item); shouldPing = true
        elseif item:match("%[VIP") then
            table.insert(vipDrops, item); shouldPing = true
        else
            table.insert(normalDrops, item)
        end
    end

    -- Build fields
    local fields = {}
    if #rareDrops > 0 then
        local lines = ""
        for _, v in ipairs(rareDrops) do lines = lines .. "+ " .. v .. "\n" end
        table.insert(fields, {name = "✨  Rare Drops", value = "```diff\n" .. lines .. "```", inline = false})
    end
    if #vipDrops > 0 then
        local lines = ""
        for _, v in ipairs(vipDrops) do lines = lines .. "+ " .. v .. "\n" end
        table.insert(fields, {name = "🍑  VIP Fruits", value = "```diff\n" .. lines .. "```", inline = false})
    end
    if #normalDrops > 0 then
        local lines = ""
        for _, v in ipairs(normalDrops) do lines = lines .. "  " .. v .. "\n" end
        table.insert(fields, {name = "🎁  Normal Drops", value = "```\n" .. lines .. "```", inline = false})
    end
    if #SessionItems == 0 then
        table.insert(fields, {name = "🎁  Session Drops", value = "```diff\n- No items or fruits dropped this run.```", inline = false})
    end

    -- Statistics field
    table.insert(fields, {
        name  = "📊  Statistics",
        value = string.format("```\nRare   : %d\nVIP    : %d\nNormal : %d\nTotal  : %d```",
                    #rareDrops, #vipDrops, #normalDrops, #SessionItems),
        inline = true
    })

    -- Death / kick info field
    local eventLines = ""
    if _sessionDeathZone then
        eventLines = eventLines .. "💀  Died at Zone " .. _sessionDeathZone .. "\n"
    end
    if _sessionKickReason then
        eventLines = eventLines .. "🚫  Kicked — " .. _sessionKickReason .. "\n"
    end
    if eventLines ~= "" then
        table.insert(fields, {name = "⚠️  Session Events", value = "```\n" .. eventLines .. "```", inline = true})
    end

    local embedTitle
    if #rareDrops > 0 and #vipDrops > 0 then embedTitle = "🔥  RARE + VIP DROPPED!"
    elseif #rareDrops > 0                 then embedTitle = "✨  RARE ITEM DROPPED!"
    elseif #vipDrops > 0                  then embedTitle = "🍑  VIP FRUIT DROPPED!"
    else                                       embedTitle = "🎁  Dungeon Cleared" end

    -- Pick thumbnail: first rare item dropped → use its image, else fallback
    local thumbURL = NormalThumb
    local imageURL = NormalThumb
    if #rareDrops > 0 then
        -- rareDrops entries look like "Leo's Inferno Hagoromo  [RARE]"
        -- strip the tag to get the raw item name
        local firstName = rareDrops[1]:match("^(.-)%s+%[")
        if firstName then
            local url = RareImages[firstName]
            if url then
                thumbURL = url   -- small thumbnail (top-right)
                imageURL = url   -- large image (bottom of embed)
            end
        end
    end

    local payload = {
        embeds = {{
            author      = {name = "⚔️  Auto Cupid Farm  •  ZiLi Hub", icon_url = LogoZiLi},
            title       = embedTitle,
            color       = shouldPing and 0xFF2222 or 0xFFB347,
            description = "━━━━━━━━━━━━━━━━━━━━━━\n"
                .. "👤  **Player:** ||" .. Player.Name .. "||\n"
                .. "⏱️  **Clear Time:** `" .. DungeonClearTimeStr .. "`\n"
                .. "🗺️  **Map:** `Cupid Dungeon`\n"
                .. "━━━━━━━━━━━━━━━━━━━━━━",
            fields      = fields,
            thumbnail   = {url = thumbURL},
            image       = {url = imageURL},
            footer      = {text = "ZiLi Hub  •  " .. os.date("%d/%m/%Y  %H:%M:%S"), icon_url = LogoZiLi},
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
    if shouldPing then payload["content"] = "@everyone 🚨 RARE / VIP DROP!" end
    SendRaw(payload)
end

-- Death webhook (zone-aware)
local function SendDeathWebhook(zone)
    local payload = {
        embeds = {{
            author = {name = "💀  Auto Cupid Farm  •  ZiLi Hub", icon_url = LogoZiLi},
            title  = "💀  Character Died!",
            color  = 0x808080,
            description = "━━━━━━━━━━━━━━━━━━━━━━\n"
                .. "👤  **Player:** ||" .. Player.Name .. "||\n"
                .. "🗺️  **Died at:** Zone `" .. tostring(zone) .. "`\n"
                .. "━━━━━━━━━━━━━━━━━━━━━━",
            footer    = {text = "ZiLi Hub  •  " .. os.date("%d/%m/%Y  %H:%M:%S"), icon_url = LogoZiLi},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
    SendRaw(payload)
end

-- Kick / ban webhook
local function SendKickWebhook(reason, zone)
    local payload = {
        embeds = {{
            author = {name = "🚫  Auto Cupid Farm  •  ZiLi Hub", icon_url = LogoZiLi},
            title  = "🚫  Player Kicked / Banned",
            color  = 0xFF0000,
            description = "━━━━━━━━━━━━━━━━━━━━━━\n"
                .. "👤  **Player:** ||" .. Player.Name .. "||\n"
                .. "📝  **Reason:** `" .. tostring(reason) .. "`\n"
                .. "🗺️  **Zone at time:** Zone `" .. tostring(zone) .. "`\n"
                .. "━━━━━━━━━━━━━━━━━━━━━━",
            footer    = {text = "ZiLi Hub  •  " .. os.date("%d/%m/%Y  %H:%M:%S"), icon_url = LogoZiLi},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
    SendRaw(payload)
end

-- ==========================================
-- [2] RADAR TRACK — Item Drop Detector
-- Detects two UI notification patterns from the game:
--   "New Item <item name>"       → item obtained normally
--   "Max capacity of <item name>"→ inventory full for that item (already owned)
-- Also matches known RareImages / NormalItems by name as fallback.
-- ==========================================
task.spawn(function()
    local pGui = Player:WaitForChild("PlayerGui", 9e9)
    local notif = pGui:WaitForChild("Notifications", 9e9)

    local function CheckItemText(label)
        if not label or not label:IsA("TextLabel") then return end

        local function parseText()
            local rawText = string.gsub(label.Text, "<[^>]+>", "")  -- strip rich-text tags
            local txt = string.lower(rawText)
            if txt == "" then return end

            -- [A] "New Item <name>" pattern — item dropped and obtained
            local newItemName = rawText:match("[Nn]ew [Ii]tem%s+<?([^>%\n]+)>?")
                             or rawText:match("[Nn]ew [Ii]tem:%s*(.+)")
            if newItemName then
                newItemName = newItemName:match("^%s*(.-)%s*$")  -- trim
                local uid = tostring(label) .. "new:" .. newItemName
                if not ProcessedUITexts[uid] then
                    ProcessedUITexts[uid] = true
                    table.insert(SessionItems, newItemName .. "  [NEW ITEM]")
                end
                return
            end

            -- [B] "Max capacity of <name>" pattern — already own this item
            local maxCapName = rawText:match("[Mm]ax [Cc]apacity %w* ?<?([^>%\n]+)>?")
                            or rawText:match("[Mm]ax [Cc]apacity%s+of%s+(.+)")
            if maxCapName then
                maxCapName = maxCapName:match("^%s*(.-)%s*$")
                local uid = tostring(label) .. "maxcap:" .. maxCapName
                if not ProcessedUITexts[uid] then
                    ProcessedUITexts[uid] = true
                    table.insert(SessionItems, maxCapName .. "  [MAX CAPACITY — Already Owned]")
                end
                return
            end

            -- [C] Fallback: match known rare/normal item names directly in text
            for rareName, _ in pairs(RareImages) do
                if string.find(txt, string.lower(rareName), 1, true) then
                    local uid = tostring(label) .. rareName
                    if not ProcessedUITexts[uid] then
                        ProcessedUITexts[uid] = true
                        table.insert(SessionItems, rareName .. "  [RARE]")
                    end
                end
            end
            for _, normalName in ipairs(NormalItems) do
                if string.find(txt, string.lower(normalName), 1, true) then
                    local uid = tostring(label) .. normalName
                    if not ProcessedUITexts[uid] then
                        ProcessedUITexts[uid] = true
                        table.insert(SessionItems, normalName .. "  [Normal Item]")
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
        if frame then
            for _, v in ipairs(frame:GetChildren()) do CheckItemText(v) end
            frame.ChildAdded:Connect(CheckItemText)
        end
    end
    SetupTracker("Frame"); SetupTracker("Frame2")
    notif.ChildAdded:Connect(function(child)
        if child.Name == "Frame" or child.Name == "Frame2" then SetupTracker(child.Name) end
    end)
end)

-- ==========================================
-- [3] AUTO REPLAY
-- ==========================================
task.spawn(function()
    local isReplaying = false
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and not isReplaying then
            pcall(function()
                local prompt = Player.PlayerGui:FindFirstChild("ConfirmationPrompt")
                if prompt then
                    local main = prompt:FindFirstChild("Main")
                    local options = main and main:FindFirstChild("OptionsFrame")
                    local btn = options and options:FindFirstChild("Replay")
                    if btn then
                        local isVisible = true
                        if prompt:IsA("ScreenGui") and prompt.Enabled == false then isVisible = false end
                        if main and main:IsA("GuiObject") and main.Visible == false then isVisible = false end
                        if isVisible then
                            isReplaying = true
                            task.wait(1.5)
                            local val = btn:GetAttribute("buttonValue") or "Replay"
                            local remote = prompt:FindFirstChild("RemoteEvent")
                            if not remote then
                                if getnilinstances then
                                    for _, v in next, getnilinstances() do
                                        if v.Name == "RemoteEvent" and v.Parent == nil then
                                            pcall(function() v:FireServer(val) end)
                                        end
                                    end
                                end
                            else
                                pcall(function() remote:FireServer(val) end)
                            end
                            if prompt:IsA("ScreenGui") then prompt.Enabled = false end
                            if main and main:IsA("GuiObject") then main.Visible = false end
                            task.wait(5)
                            isReplaying = false
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

local function IsPotentialFruit(name)
    local n = name:lower()
    if n:match("fruit") or n == "tool" then return true end
    for _, v in ipairs(VIP_Fruits) do if n:match(v) or n == v then return true end end
    for _, t in ipairs(TRASH_Fruits) do if n:match(t) or n == t then return true end end
    return false
end

-- ==========================================
-- [4] COMBAT SETUP
-- ==========================================
if not _G.AntiKnockoutHook then
    _G.AntiKnockoutHook = true
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "FireServer" then
                if self.Name == "KnockedOut" or self.Name == "Ragdoll" or self.Name == "Zombie" or self.Name == "Knock" then
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
end

if _G.CupidHeartbeat then pcall(function() _G.CupidHeartbeat:Disconnect() end) end
if _G.CupidStepped then pcall(function() _G.CupidStepped:Disconnect() end) end
_G.DungeonScriptID = (_G.DungeonScriptID or 0) + 1
local currentScriptID = _G.DungeonScriptID

_G.AutoDungeon = true
_G.ForceReblock = false

local MoveSpeed = 95
local AttackOffset = 10.2
local SearchRadius = 800
local WaitSpawnTime = 15
local GatherTime = 2
local DangerRadius = 45
local EvadeDistance = 60

local Zone5Points = {
    Vector3.new(-1166.94, 442.27, -3332.41),
    Vector3.new(-995.78, 442.31, -3331.45),
    Vector3.new(-962.64, 442.04, -3084.11),
    Vector3.new(-1135.6, 442.67, -3102.46)
}
local EndPortalPos = Vector3.new(-1097.87, 672.92, -5379.12)
local Z5Index = 1

local TargetCFrame = nil
local CurrentTargetRoot = nil
local IsReadyToAttack = false
local CurrentZoneIndex = 1
local ZoneState = "FLYING"
local PreviousZoneState = "FLYING"
local Timer = 0
local DodgeTimer = 0
local CachedZoneFloors = {}

local IgnoredHazards = setmetatable({}, {__mode = "k"})

-- V28: Hazard now carries action type (DODGE or BLOCK) + evade distance
local CurrentHazard = {Type = "None", Position = nil, Instance = nil, MinDist = DangerRadius, Action = "DODGE"}
local CurrentLava = {Part = nil, Prompt = nil}
local IsFarmingReady = false
local HasWaitedForLoad = false

-- V28 state flags
local _meraUltDodging   = false
local _meraUltHoldUntil = 0
local _z8DmgDodging     = false  -- zone 8 damage evasion active
local _z8DmgUntil       = 0
local _dodgeTweenActive = false  -- V29: TweenService dodge owns CFrame while true

local fakePlatform = workspace:FindFirstChild("CupidFakePlatform")
if not fakePlatform then
    fakePlatform = Instance.new("Part")
    fakePlatform.Name = "CupidFakePlatform"
    fakePlatform.Size = Vector3.new(15, 1, 15)
    fakePlatform.Anchored = true
    fakePlatform.CanCollide = true
    fakePlatform.Transparency = 0.5
    fakePlatform.Parent = workspace
end

-- ==========================================
-- DUNGEON LOCATION DETECTION
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
                        local lobby = islands:FindFirstChild("Lobby")
                        local dungeon = islands:FindFirstChild("Cupid Dungeon")
                        local getPos = function(inst)
                            if not inst then return nil end
                            if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart.Position end
                            local part = inst:FindFirstChildWhichIsA("BasePart", true)
                            if part then return part.Position end
                        end
                        local lPos = getPos(lobby)
                        local dPos = getPos(dungeon)
                        local rPos = root.Position
                        local lDist = lPos and (Vector2.new(lPos.X, lPos.Z) - Vector2.new(rPos.X, rPos.Z)).Magnitude or math.huge
                        local dDist = dPos and (Vector2.new(dPos.X, dPos.Z) - Vector2.new(rPos.X, rPos.Z)).Magnitude or math.huge
                        if dDist < lDist and dDist < 5000 then
                            if not HasWaitedForLoad then
                                HasWaitedForLoad = true
                                IsFarmingReady = false
                                DungeonStartTime = tick()
                                SessionItems = {}
                                ProcessedItems = {}
                                ProcessedUITexts = {}
                                WebhookSentForSession = false
                                _G.EndGameStarted = false
                                _G.GoToPortal = false
                                _G.IsProcessingFruit = false
                                _meraUltDodging = false
                                _z8DmgDodging = false
                                task.wait(5)
                                CurrentZoneIndex = 1
                                ZoneState = "FLYING"
                                IsFarmingReady = true
                            end
                        else
                            IsFarmingReady = false
                            HasWaitedForLoad = false
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

local function GetZoneFloor(zoneIndex, boxCenter)
    if CachedZoneFloors[zoneIndex] then return CachedZoneFloors[zoneIndex] end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character, fakePlatform, workspace:FindFirstChild("Effects"), workspace:FindFirstChild("Enemies")}
    local result = workspace:Raycast(boxCenter, Vector3.new(0, -300, 0), params)
    if result then CachedZoneFloors[zoneIndex] = result.Position.Y; return result.Position.Y end
    return boxCenter.Y - 10
end

local function GetRoot(m)
    if not m then return nil end
    if m:IsA("BasePart") then return m end
    return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

local function GetMobsInZone(zonePos)
    local mobs = {}
    local currentSearchRadius = (CurrentZoneIndex == 8) and 1500 or SearchRadius
    if CurrentZoneIndex == 8 then
        local foundStatue = false
        pcall(function()
            local statuesFolder = workspace:FindFirstChild("Env") and workspace.Env:FindFirstChild("Statues")
            if statuesFolder then
                for _, statue in pairs(statuesFolder:GetChildren()) do
                    local sRoot = GetRoot(statue)
                    if sRoot then
                        local isAlive = false
                        local barrelHP = statue:FindFirstChild("barrelHP", true)
                        local hum = statue:FindFirstChild("Humanoid", true)
                        if barrelHP and barrelHP:IsA("ValueBase") then
                            if tonumber(barrelHP.Value) and tonumber(barrelHP.Value) > 0 then isAlive = true end
                        elseif hum and hum.Health > 0.1 then isAlive = true end
                        if isAlive then table.insert(mobs, statue); foundStatue = true end
                    end
                end
            end
        end)
        if foundStatue and #mobs > 0 then return mobs end
    end
    local possibleFolders = {workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Mob"), workspace:FindFirstChild("NPCs")}
    pcall(function() table.insert(possibleFolders, workspace.Effects.Zones["Zone" .. CurrentZoneIndex]) end)
    for _, folder in pairs(possibleFolders) do
        if folder then
            for _, v in pairs(folder:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") then
                    local root = GetRoot(v)
                    if root and (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(zonePos.X, zonePos.Z)).Magnitude <= currentSearchRadius then
                        table.insert(mobs, v)
                    end
                end
            end
        end
    end
    return mobs
end

local function CheckAndEquipWeapon()
    if _G.IsProcessingFruit then return nil end
    local char = Player.Character
    if not char then return nil end
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name:lower():match("sword") or currentTool.Name:lower():match("blade") or currentTool.Name:lower():match("axe") or currentTool.Name:lower():match("katana")) then
        return currentTool
    end
    local bp = Player:FindFirstChild("Backpack")
    if not bp then return currentTool end
    local sword = nil
    for _, t in pairs(bp:GetChildren()) do
        if t:IsA("Tool") and (t.Name:lower():match("sword") or t.Name:lower():match("blade") or t.Name:lower():match("axe") or t.Name:lower():match("katana")) then
            sword = t; break
        end
    end
    if sword and currentTool ~= sword then char.Humanoid:EquipTool(sword) end
    return sword
end

-- Auto equip Haki
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
                        if v.Name:match("Buso") or v.Name:match("Haki") or v.Name:match("HasBuso") then hasHaki = true; break end
                    end
                    if not hasHaki then ReplicatedStorage.Events.Haki:FireServer("Buso") end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- [V28-A] MERA ULT WATCHER
-- Attribute meraUltMax on the Leo model
-- true  → dodge 115 studs immediately
-- nil   → release after 2.5s hold min, return to mob
-- ==========================================
local function HookMeraUlt(leoModel)
    leoModel.AttributeChanged:Connect(function(attr)
        if attr ~= "meraUltMax" then return end
        local val = leoModel:GetAttribute("meraUltMax")
        if val ~= nil then
            -- Activated: snap 115 studs sideways
            _meraUltDodging   = true
            _meraUltHoldUntil = tick() + 2.5
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local right = root.CFrame.RightVector
                TargetCFrame = CFrame.new(Vector3.new(
                    root.Position.X + right.X * 115,
                    root.Position.Y,
                    root.Position.Z + right.Z * 115
                ))
                IsReadyToAttack = false
                CurrentTargetRoot = nil
            end
        else
            -- Deactivated: release after minimum hold
            task.delay(math.max(0, _meraUltHoldUntil - tick()), function()
                _meraUltDodging = false
                TargetCFrame = nil
            end)
        end
    end)
end

-- Hook existing Leo models
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "Leo" and obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
        HookMeraUlt(obj)
    end
end
-- Hook future Leo spawns
local _leoConn
_leoConn = workspace.DescendantAdded:Connect(function(obj)
    if _G.DungeonScriptID ~= currentScriptID then _leoConn:Disconnect(); return end
    if obj.Name == "Leo" and obj:IsA("Model") then
        task.wait(0.5)
        if obj:FindFirstChild("Humanoid") then HookMeraUlt(obj) end
    end
end)

-- ==========================================
-- [V28-B] ZONE 8 DAMAGE SENSOR
-- Any HP loss in zone 8 → TP +10 studs up, hold 2s, resume mob
-- ==========================================
local function HookCharacterZ8(char)
    if not char then return end
    local hum = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum then return end

    -- [4] Death → send zone-aware death webhook
    hum.Died:Connect(function()
        _sessionDeathZone = CurrentZoneIndex
        task.spawn(function() SendDeathWebhook(CurrentZoneIndex) end)
    end)

    local prevHP = hum.Health
    hum.HealthChanged:Connect(function(newHP)
        local dmg = prevHP - newHP
        prevHP = newHP
        if dmg <= 0 then return end
        if CurrentZoneIndex ~= 8 then return end
        if not IsFarmingReady then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = root.CFrame + Vector3.new(0, 10, 0) end

        _z8DmgDodging = true
        _z8DmgUntil   = tick() + 2
        task.delay(2, function()
            if tick() >= _z8DmgUntil then
                _z8DmgDodging = false
                TargetCFrame  = nil
            end
        end)
    end)
end

HookCharacterZ8(Player.Character)
Player.CharacterAdded:Connect(function(newChar)
    task.wait(0.1)
    HookCharacterZ8(newChar)
end)

-- ==========================================
-- [V28-C] HAZARD SCANNER
-- Detects boss skills by ASSET ID (SpecialMesh, Decal, Texture, Sound)
-- AND by name pattern as fallback.
-- Flame Pillar → DODGE 70 studs
-- Hiken        → BLOCK (hold)
-- Firefly      → BLOCK (hold)
-- Enkai/Entei  → DODGE 100 studs
-- ==========================================
local SKILL_ASSET_IDS = {
    -- {id, action, evadeDist}
    {id = "5244141327",  action = "DODGE", evadeDist = 70},   -- Flame Pillar
    {id = "5220917407",  action = "BLOCK", evadeDist = 0},    -- Hiken
    {id = "13243427337", action = "BLOCK", evadeDist = 0},    -- Firefly
}

-- Check if any descendant of `inst` has a property referencing the given asset id
local function InstHasAssetID(inst, id)
    -- Check the instance itself
    local function checkOne(v)
        local ok = false
        pcall(function()
            if v:IsA("SpecialMesh") and (v.MeshId:find(id, 1, true) or v.TextureId:find(id, 1, true)) then ok = true end
        end)
        if ok then return true end
        pcall(function()
            if (v:IsA("Decal") or v:IsA("Texture")) and v.Texture:find(id, 1, true) then ok = true end
        end)
        if ok then return true end
        pcall(function()
            if v:IsA("Sound") and v.SoundId:find(id, 1, true) then ok = true end
        end)
        if ok then return true end
        pcall(function()
            if (v:IsA("ImageLabel") or v:IsA("ImageButton")) and v.Image:find(id, 1, true) then ok = true end
        end)
        return ok
    end

    if checkOne(inst) then return true end
    for _, v in ipairs(inst:GetDescendants()) do
        if checkOne(v) then return true end
    end
    return false
end

-- Name-pattern fallback defs (BLOCK only — no dodge by name, too unreliable)
local NAME_SKILL_DEFS = {
    {patterns = {"hiken","hi_ken","fire_fist","firefist"},  action = "BLOCK", evadeDist = 0},
    {patterns = {"firefly","fire_fly"},                     action = "BLOCK", evadeDist = 0},
}

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                -- Expire ignored hazards
                for obj, expireTime in pairs(IgnoredHazards) do
                    if tick() > expireTime or not obj:IsDescendantOf(workspace) then
                        IgnoredHazards[obj] = nil
                    end
                end

                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local playerPos = root.Position

                local detectedHazard = "None"
                local hazardAction   = "DODGE"
                local hazardPos      = nil
                local hazardInst     = nil
                local hazardDist     = DangerRadius
                local foundLavaPart  = nil
                local foundLavaPrompt = nil

                local efFolder = workspace:FindFirstChild("Effects")
                if efFolder then
                    -- Scan all descendants of Effects for asset-ID matches + name patterns
                    for _, v in ipairs(efFolder:GetDescendants()) do
                        if IgnoredHazards[v] then continue end
                        if not (v:IsA("BasePart") or v:IsA("Model")) then continue end

                        local vPos = nil
                        pcall(function()
                            if v:IsA("BasePart") then
                                vPos = v.Position
                            elseif v:IsA("Model") then
                                vPos = v.PrimaryPart and v.PrimaryPart.Position or v:GetModelCFrame().Position
                            end
                        end)
                        if not vPos then continue end

                        -- Lava curse check (any zone)
                        local vname = v.Name:lower()
                        if vname:match("lava") and vname:match("curse") then
                            local dist = (Vector2.new(vPos.X, vPos.Z) - Vector2.new(playerPos.X, playerPos.Z)).Magnitude
                            if dist < 1500 then
                                local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                                local part   = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                                if part and prompt and prompt.Enabled then
                                    foundLavaPart = part
                                    foundLavaPrompt = prompt
                                end
                            end
                        end

                        -- Only scan for boss skills in zones >= 6
                        if CurrentZoneIndex < 6 then continue end
                        if detectedHazard ~= "None" then continue end  -- already found one

                        -- [A] Asset-ID based detection (highest priority)
                        local foundAsset = false
                        for _, def in ipairs(SKILL_ASSET_IDS) do
                            if InstHasAssetID(v, def.id) then
                                detectedHazard = "SkillAsset"
                                hazardAction   = def.action
                                hazardDist     = def.evadeDist
                                hazardPos      = vPos
                                hazardInst     = v
                                foundAsset     = true
                                break
                            end
                        end
                        if foundAsset then continue end

                        -- [B] Name-pattern fallback
                        for _, def in ipairs(NAME_SKILL_DEFS) do
                            local matched = false
                            for _, pat in ipairs(def.patterns) do
                                if vname:match(pat) then matched = true; break end
                            end
                            if matched then
                                detectedHazard = "SkillName"
                                hazardAction   = def.action
                                hazardDist     = def.evadeDist
                                hazardPos      = vPos
                                hazardInst     = v
                                break
                            end
                        end
                    end

                    -- [C] Normal dungeon hazards (all zones)
                    -- Bao gồm: aoe, circle, bomb, meteor, projectile, lightning, arrow, rain
                    if detectedHazard == "None" then
                        for _, v in pairs(efFolder:GetChildren()) do
                            local name = v.Name:lower()
                            local vPos = v:IsA("Model") and (v.PrimaryPart and v.PrimaryPart.Position or v:GetModelCFrame().Position) or (v:IsA("BasePart") and v.Position or nil)
                            if vPos and not IgnoredHazards[v] then
                                local dist = (Vector2.new(vPos.X, vPos.Z) - Vector2.new(playerPos.X, playerPos.Z)).Magnitude
                                local isHazard = name:match("aoe")        or name:match("circle")
                                             or name:match("bomb")        or name:match("meteor")
                                             or name:match("lightning")   or name:match("thunder")
                                             or name:match("arrow")       or name:match("rain")
                                             or name:match("projectile")
                                if isHazard and dist < DangerRadius then
                                    detectedHazard = "Normal"
                                    hazardAction   = "DODGE"
                                    hazardPos      = vPos
                                    hazardDist     = dist
                                    hazardInst     = v
                                end
                            end
                        end
                    end
                end

                CurrentHazard.Type     = detectedHazard
                CurrentHazard.Action   = hazardAction
                CurrentHazard.Position = hazardPos
                CurrentHazard.Instance = hazardInst
                CurrentHazard.MinDist  = hazardDist
                CurrentLava.Part       = foundLavaPart
                CurrentLava.Prompt     = foundLavaPrompt
            end)
        end
        task.wait(0.05)
    end
end)

-- ==========================================
-- [V29] TWEEN DODGE — thay thế TP, an toàn với server
-- Dùng TweenService để di chuyển mượt sang bên.
-- Heartbeat sẽ không ghi đè CFrame khi _dodgeTweenActive = true.
-- tweenTime = evadeDist / 35  → ~35 studs/s, clamp 0.5-1.4s
-- Sau khi tween xong, hold thêm holdWait rồi resume state.
-- ==========================================
local function ExecuteDodgeTween(root, dodgeTarget, evadeDist, holdWait, onDone)
    if _dodgeTweenActive then return end
    _dodgeTweenActive = true

    -- Dùng MoveSpeed (95 studs/s) giống Heartbeat movement — server không flag
    local tweenTime = math.clamp(evadeDist / MoveSpeed, 0.3, 2.0)
    local goalCF    = CFrame.new(dodgeTarget) * root.CFrame.Rotation

    local info  = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(root, info, {CFrame = goalCF})

    tween.Completed:Connect(function(state)
        -- Hold tại chỗ sau tween trước khi resume
        task.wait(holdWait or 1.5)
        _dodgeTweenActive = false
        if onDone then onDone() end
    end)
    tween:Play()
end

-- ==========================================
-- [V28-D] BLOCK HELPER — called when a BLOCK skill is detected
-- Holds block for ~1.5s then releases, does NOT change ZoneState
-- ==========================================
local _blockActive = false
local function TriggerHoldBlock(weaponName, duration)
    if _blockActive then return end
    _blockActive = true
    task.spawn(function()
        pcall(function()
            local BlockEvent = ReplicatedStorage:WaitForChild("Events", 3):WaitForChild("Block", 3)
            local wn = weaponName or "Melee"
            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(true, wn, false)
            else
                BlockEvent:FireServer(true, wn, false)
            end
            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(duration or 1.5)
            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(false, wn, false)
            else
                BlockEvent:FireServer(false, wn, false)
            end
            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
        _blockActive = false
    end)
end

-- ==========================================
-- MAIN COMBAT LOOP
-- ==========================================
task.spawn(function()
    local lastZone = 0
    local isHoldingLava = false

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                if lastZone ~= CurrentZoneIndex then lastZone = CurrentZoneIndex end
                local char = Player.Character
                if not char or not char.Parent then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                -- END GAME
                if CurrentZoneIndex > 8 then
                    IsReadyToAttack = false
                    CurrentTargetRoot = nil
                    if not _G.EndGameStarted then
                        _G.EndGameStarted = true
                        task.spawn(function()
                            if root then root.Velocity = Vector3.zero end
                            task.wait(2.5)
                            pcall(function()
                                _G.IsProcessingFruit = true
                                local bp = Player:FindFirstChild("Backpack")
                                local hum = char and char:FindFirstChild("Humanoid")
                                if char and bp and hum then
                                    local tools = {}
                                    for _, v in ipairs(char:GetChildren()) do if v:IsA("Tool") and IsPotentialFruit(v.Name) then table.insert(tools, v) end end
                                    for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") and IsPotentialFruit(v.Name) then table.insert(tools, v) end end
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
                                            local activeTool = char:FindFirstChildOfClass("Tool") or tool
                                            local exactName = activeTool.Name:lower()
                                            local displayToolName = activeTool.Name
                                            local isVIP = false
                                            for _, vip in ipairs(VIP_Fruits) do if exactName:match(vip) or exactName == vip then isVIP = true; break end end
                                            if isVIP then
                                                pcall(function() ReplicatedStorage.Events.FruitStorage:InvokeServer("Store", activeTool) end)
                                                task.wait(1.5)
                                                if activeTool.Parent == char or activeTool.Parent == bp then
                                                    pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end)
                                                    table.insert(SessionItems, displayToolName .. " [ VIP Fruit - Dropped ]")
                                                else
                                                    table.insert(SessionItems, displayToolName .. " [ VIP Fruit - Stored ]")
                                                end
                                            else
                                                pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end)
                                                table.insert(SessionItems, displayToolName .. " [ Dropped ]")
                                            end
                                            pcall(function() hum:UnequipTools() end)
                                        end
                                    end
                                end
                            end)
                            _G.IsProcessingFruit = false
                            if not WebhookSentForSession then
                                local elapsed = tick() - DungeonStartTime
                                DungeonClearTimeStr = string.format("%02d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
                                SendWebhook()
                                task.wait(1.5)
                            end
                            _G.GoToPortal = true
                        end)
                    end
                    if _G.GoToPortal then
                        ZoneState = "TO_PORTAL"
                        TargetCFrame = CFrame.new(EndPortalPos)
                    else
                        TargetCFrame = nil
                        if root then root.Velocity = Vector3.zero end
                    end
                    return
                end

                -- LAVA CURSE
                local shouldAbsorbLava = false
                if CurrentLava.Part and CurrentLava.Prompt then
                    local lavaPos = CurrentLava.Part.Position
                    local zonePart = nil
                    pcall(function() zonePart = workspace.Effects.Zones["Zone" .. CurrentZoneIndex]:FindFirstChild("Zone") end)
                    if zonePart then
                        if (Vector2.new(lavaPos.X, lavaPos.Z) - Vector2.new(zonePart.Position.X, zonePart.Position.Z)).Magnitude <= 300 then shouldAbsorbLava = true end
                    else
                        if (Vector2.new(lavaPos.X, lavaPos.Z) - Vector2.new(root.Position.X, root.Position.Z)).Magnitude <= 350 then shouldAbsorbLava = true end
                    end
                end
                if shouldAbsorbLava then
                    if ZoneState ~= "ABSORBING_CURSE" then PreviousZoneState = ZoneState; ZoneState = "ABSORBING_CURSE"; _G.LavaFailSafeTimer = tick() end
                    if tick() - _G.LavaFailSafeTimer > 10 then
                        if CurrentLava.Part and CurrentLava.Part.Parent then IgnoredHazards[CurrentLava.Part.Parent] = tick() + 60 end
                        ZoneState = PreviousZoneState or "FLYING"; return
                    end
                    IsReadyToAttack = false; CurrentTargetRoot = nil
                    TargetCFrame = CFrame.new(CurrentLava.Part.Position)
                    if (root.Position - CurrentLava.Part.Position).Magnitude <= 12 then
                        root.Velocity = Vector3.zero
                        if not isHoldingLava then
                            isHoldingLava = true
                            task.spawn(function()
                                pcall(function()
                                    local p = CurrentLava.Prompt
                                    if p then
                                        p.RequiresLineOfSight = false; p.MaxActivationDistance = 50
                                        local holdTime = p.HoldDuration > 0 and p.HoldDuration or 2.0
                                        p:InputHoldBegin(); VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                        task.wait(holdTime + 0.5)
                                        p:InputHoldEnd(); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    end
                                end)
                                task.wait(0.5); isHoldingLava = false
                            end)
                        end
                    end
                    return
                else
                    if ZoneState == "ABSORBING_CURSE" then ZoneState = PreviousZoneState or "FLYING" end
                end

                -- ── V28: MERA ULT DODGE ──────────────────────────────────────
                if _meraUltDodging then
                    IsReadyToAttack = false
                    CurrentTargetRoot = nil
                    return  -- TargetCFrame already set by HookMeraUlt
                end

                -- ── V28: ZONE 8 DAMAGE EVASION ───────────────────────────────
                if _z8DmgDodging then
                    IsReadyToAttack = false
                    CurrentTargetRoot = nil
                    -- Hold current raised position; timer releases automatically via task.delay
                    return
                end

                -- ── HAZARD RESPONSE (DODGE or BLOCK) ─────────────────────────
                if CurrentZoneIndex ~= 5 and CurrentHazard.Type ~= "None" and ZoneState ~= "DODGING" then
                    local action    = CurrentHazard.Action or "DODGE"
                    local evadeDist = CurrentHazard.MinDist

                    if CurrentHazard.Instance then
                        IgnoredHazards[CurrentHazard.Instance] = tick() + 6
                    end

                    if action == "BLOCK" then
                        -- BLOCK: stay in place, hold block event, DO NOT change ZoneState
                        -- IsReadyToAttack stays true → character keeps attacking after block
                        if not _blockActive then
                            local char2 = Player.Character
                            local wpn2 = char2 and char2:FindFirstChildOfClass("Tool")
                            TriggerHoldBlock(wpn2 and wpn2.Name or "Melee", 1.5)
                        end
                        -- Do not alter ZoneState or IsReadyToAttack
                    else
                        -- DODGE: dùng TweenService (không TP)
                        IsReadyToAttack = false
                        CurrentTargetRoot = nil
                        if ZoneState ~= "ABSORBING_CURSE" then PreviousZoneState = ZoneState end
                        ZoneState = "DODGING"

                        local evadeDir = (root.Position - (CurrentHazard.Position or root.Position))
                        if evadeDir.Magnitude < 0.1 then evadeDir = Vector3.new(1, 0, 0) end
                        local flatDir    = Vector3.new(evadeDir.X, 0, evadeDir.Z).Unit
                        local dodgeTarget = root.Position + flatDir * evadeDist
                        local holdWait   = (CurrentHazard.Type == "SkillAsset" or CurrentHazard.Type == "SkillName") and 2.0 or 1.5

                        ExecuteDodgeTween(root, dodgeTarget, evadeDist, holdWait, function()
                            -- Callback sau khi tween + hold xong → resume
                            ZoneState = PreviousZoneState or "ATTACKING"
                            CurrentHazard.Type = "None"
                            TargetCFrame = nil
                        end)
                    end
                end

                -- Nếu đang tween dodge → không làm gì thêm, callback sẽ resume
                if ZoneState == "DODGING" then
                    IsReadyToAttack = false; CurrentTargetRoot = nil
                    if not _dodgeTweenActive then
                        -- Fallback: tween đã xong nhưng callback chưa kịp chạy
                        ZoneState = PreviousZoneState or "FLYING"
                        CurrentHazard.Type = "None"
                    else
                        return
                    end
                end

                -- ZONE STATE MACHINE
                local zonePart = nil
                pcall(function() zonePart = workspace.Effects.Zones["Zone" .. CurrentZoneIndex]:FindFirstChild("Zone") end)
                if zonePart then
                    local boxCenter = zonePart.Position
                    local floorY = GetZoneFloor(CurrentZoneIndex, boxCenter)
                    local waitPos = Vector3.new(boxCenter.X, floorY + 20, boxCenter.Z)
                    local mobs = GetMobsInZone(boxCenter)

                    if ZoneState == "FLYING" then
                        TargetCFrame = CFrame.new(Vector3.new(boxCenter.X, math.max(root.Position.Y, floorY + 40), boxCenter.Z))
                        CurrentTargetRoot = nil
                        if (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(boxCenter.X, boxCenter.Z)).Magnitude < 15 then
                            if CurrentZoneIndex == 5 then ZoneState = "ZONE5_SURVIVAL"; Timer = tick() + 30; Z5Index = 1
                            else ZoneState = "WAITING_SPAWN"; Timer = tick() + WaitSpawnTime end
                        end
                    elseif ZoneState == "ZONE5_SURVIVAL" then
                        IsReadyToAttack = false; CurrentTargetRoot = nil
                        local currentZ5Target = Zone5Points[Z5Index]
                        TargetCFrame = CFrame.new(currentZ5Target)
                        if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(currentZ5Target.X, 0, currentZ5Target.Z)).Magnitude < 10 then
                            Z5Index = Z5Index < #Zone5Points and Z5Index + 1 or 1
                        end
                        if tick() > Timer then CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; task.wait(0.2) end
                    elseif ZoneState == "WAITING_SPAWN" then
                        TargetCFrame = CFrame.new(waitPos); CurrentTargetRoot = nil
                        if #mobs > 0 then ZoneState = "GATHERING"; Timer = tick() + GatherTime
                        elseif tick() > Timer then CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; task.wait(0.2) end
                    elseif ZoneState == "GATHERING" then
                        if #mobs > 0 then CurrentTargetRoot = GetRoot(mobs[1]) end
                        if tick() > Timer then ZoneState = "ATTACKING" end
                    elseif ZoneState == "ATTACKING" then
                        if #mobs == 0 then ZoneState = "VERIFY_CLEAR"; Timer = tick() + 2
                        else CurrentTargetRoot = GetRoot(mobs[1]); IsReadyToAttack = true end
                    elseif ZoneState == "VERIFY_CLEAR" then
                        if #mobs > 0 then ZoneState = "ATTACKING"
                        elseif tick() > Timer then
                            if CurrentZoneIndex == 7 then ZoneState = "WAIT_30S"; Timer = tick() + 20; IsReadyToAttack = false; CurrentTargetRoot = nil
                            else CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; IsReadyToAttack = false; CurrentTargetRoot = nil; task.wait(0.2) end
                        end
                    elseif ZoneState == "WAIT_30S" then
                        TargetCFrame = CFrame.new(waitPos); CurrentTargetRoot = nil; IsReadyToAttack = false
                        if tick() > Timer then CurrentZoneIndex = 8; ZoneState = "FLYING" end
                    end
                else
                    TargetCFrame = nil; CurrentTargetRoot = nil; IsReadyToAttack = false
                    ZoneState = "FLYING"; task.wait(0.5)
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- AUTO BLOCK (V28: zone 7 & 8 removed)
-- Only blocks when CurrentHazard.Type ~= "None" (Normal hazards)
-- OR when a mob within 80 studs is actively attacking
-- ==========================================
local BlockHoldTime = 0

local function IsMobAttacking(hum)
    local isAttacking = false
    pcall(function()
        local animator = hum:FindFirstChild("Animator") or hum
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Weight > 0.01 and track.Animation then
                local animName = track.Animation.Name:lower()
                if not (animName:match("idle") or animName:match("walk") or animName:match("run") or animName:match("stun") or animName:match("hit")) then
                    if animName:match("attack") or animName:match("slash") or animName:match("punch") or animName:match("swing") or animName:match("cast") or animName:match("skill") or animName:match("m1") or animName:match("slam") or animName:match("smash") or animName:match("charge") or animName:match("burst") or animName:match("combo") or animName:match("shoot") or animName:match("fire") or animName:match("gun") or animName:match("ranged") or animName:match("magic") or animName:match("throw") or animName:match("shot") then
                        isAttacking = true; break
                    end
                end
            end
        end
    end)
    return isAttacking
end

task.spawn(function()
    local BlockEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Block")
    local lastBlockState = false
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local weapon = char and char:FindFirstChildOfClass("Tool")
                local weaponName = weapon and weapon.Name or "Melee"
                local shouldBlock = false

                if root then
                    -- V28: zone 7 & 8 do NOT force-block anymore
                    -- Block only on Normal hazards or mob attacking
                    if CurrentHazard.Type == "Normal" then
                        shouldBlock = true
                    elseif IsReadyToAttack then
                        local blockDist = 80
                        for _, mob in pairs(GetMobsInZone(root.Position)) do
                            local hum = mob:FindFirstChild("Humanoid")
                            if hum and IsMobAttacking(hum) and (GetRoot(mob).Position - root.Position).Magnitude < blockDist then
                                shouldBlock = true; break
                            end
                        end
                    end
                end

                if shouldBlock then
                    BlockHoldTime = tick() + 0.5
                elseif tick() < BlockHoldTime then
                    shouldBlock = true
                end

                if shouldBlock ~= lastBlockState or _G.ForceReblock then
                    lastBlockState = shouldBlock
                    _G.ForceReblock = false
                    task.spawn(function()
                        pcall(function()
                            if BlockEvent:IsA("RemoteFunction") then
                                BlockEvent:InvokeServer(shouldBlock, weaponName, false)
                            else
                                BlockEvent:FireServer(shouldBlock, weaponName, false)
                            end
                        end)
                    end)
                    pcall(function()
                        VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                        if shouldBlock then VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game) end
                    end)
                end
            end)
        end
        task.wait(0.05)
    end
end)

-- ==========================================
-- GET ATTACK ANIM
-- ==========================================
local function GetAttackAnim(weaponName, combo)
    if _G.IsProcessingFruit then return "Melee", nil end
    local wType = "Melee"
    local anim = nil
    local swordModules = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("SwordHandle") and ReplicatedStorage.Modules.SwordHandle:FindFirstChild("Swords")
    if swordModules and swordModules:FindFirstChild(weaponName) then
        wType = "Sword"
        local folder = swordModules[weaponName]:FindFirstChild("Slashes")
        if folder then
            anim = folder:FindFirstChild("Slash"..combo) or folder:FindFirstChild("GroundSlash"..combo) or folder:FindFirstChild("Swing"..combo)
            if not anim then for _, a in pairs(folder:GetChildren()) do if string.find(a.Name, tostring(combo)) then anim = a; break end end end
        end
        return wType, anim
    end
    wType = weaponName
    local folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild(weaponName)
    if not folder then folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild("Melee"); wType = "Melee" end
    if folder then
        anim = folder:FindFirstChild("Punch"..combo) or folder:FindFirstChild("M1_"..combo) or folder:FindFirstChild("Kick"..combo) or folder:FindFirstChild("Slash"..combo)
        if not anim then for _, a in pairs(folder:GetChildren()) do if string.find(a.Name, tostring(combo)) then anim = a; break end end end
    end
    return wType, anim
end

-- ==========================================
-- AUTO ATTACK
-- ==========================================
task.spawn(function()
    local CombatRegister = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
    local currentCombo = 1
    local strikeDelay = 0.366
    local comboResetDelay = 1.0
    while _G.DungeonScriptID == currentScriptID do
        local currentDelay = strikeDelay
        if _G.AutoDungeon and IsReadyToAttack and IsFarmingReady and not _G.IsProcessingFruit then
            local char = Player.Character
            if char and char.Parent then
                pcall(function()
                    local tool = CheckAndEquipWeapon()
                    local realWeaponName = tool and tool.Name or "Melee"
                    local weaponType, fakeAnim = GetAttackAnim(realWeaponName, currentCombo)
                    if not fakeAnim then currentCombo = 1; task.wait(comboResetDelay); return end

                    local enemiesToHit = {}
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local primaryCFrame = nil
                    if root then
                        for _, m in pairs(GetMobsInZone(root.Position)) do
                            local eRoot = GetRoot(m)
                            if eRoot and (eRoot.Position - root.Position).Magnitude <= 300 then
                                table.insert(enemiesToHit, eRoot)
                                table.insert(enemiesToHit, m)
                                if not primaryCFrame then primaryCFrame = eRoot.CFrame end
                            end
                        end
                    end
                    if not primaryCFrame and root then primaryCFrame = root.CFrame end

                    if #enemiesToHit > 0 and primaryCFrame then
                        local state = "Ground"
                        task.spawn(function()
                            pcall(function() CombatRegister:InvokeServer({[1]="swingsfx",[2]=weaponType,[3]=currentCombo,[4]=state,[5]=false,[6]=fakeAnim,[7]=2,[8]=1.5}) end)
                        end)
                        task.spawn(function()
                            pcall(function() CombatRegister:InvokeServer({[1]="damage",[2]=enemiesToHit,[3]=weaponType,[4]={[1]=currentCombo,[2]=state,[3]=weaponType},[5]=true,[6]=primaryCFrame,["aircombo"]=state}) end)
                        end)
                        currentCombo = currentCombo + 1
                        local _, nextAnim = GetAttackAnim(realWeaponName, currentCombo)
                        if not nextAnim then currentDelay = comboResetDelay; currentCombo = 1 end
                    else
                        currentCombo = 1
                    end
                end)
            else currentCombo = 1 end
        else currentCombo = 1 end
        task.wait(currentDelay)
    end
end)

-- ==========================================
-- ANTI RAGDOLL LOOP
-- ==========================================
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if char and char.Parent then
                    if hum then
                        hum.PlatformStand = false; hum.Sit = false; hum.AutoRotate = true
                        local state = hum:GetState()
                        if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Physics then
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                    end
                    if root and root.Anchored then root.Anchored = false end
                    if root then
                        for _, v in pairs(root:GetChildren()) do
                            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition") or v:IsA("LinearVelocity") or v:IsA("VectorForce") or v:IsA("AlignPosition") then
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
-- RUNSERVICE: STEPPED
-- ==========================================
_G.CupidStepped = RunService.Stepped:Connect(function()
    if not _G.AutoDungeon or not IsFarmingReady then return end
    if _G.IsProcessingFruit then return end
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not char.Parent then return end
    pcall(function()
        _G.canuse = true; _G.midM1 = false; _G.blocking = false
        _G.knocked = false; _G.ragdoll = false; _G.stunned = false; _G.zombie = false
        if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
        for attr, _ in pairs(char:GetAttributes()) do
            if type(attr) == "string" then
                local a = attr:lower()
                if a:match("stun") or a:match("busy") or a:match("freeze") or a:match("knock") or a:match("ragdoll") or a:match("zombie") or a:match("down") then
                    char:SetAttribute(attr, nil)
                end
            end
        end
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = false
            elseif v:IsA("ValueBase") then
                local n = v.Name:lower()
                if n:match("stun") or n:match("knock") or n:match("ragdoll") or n:match("zombie") or n:match("busy") then v:Destroy() end
            else
                local name = v.Name:lower()
                if name:match("stun") or name:match("knock") or name == "ragdoll" or name == "zombie" then v:Destroy() end
            end
        end
    end)
end)

-- ==========================================
-- RUNSERVICE: HEARTBEAT (MOVEMENT)
-- ==========================================
_G.CupidHeartbeat = RunService.Heartbeat:Connect(function(dt)
    if not _G.AutoDungeon then return end
    if not IsFarmingReady then
        if fakePlatform then fakePlatform.CFrame = CFrame.new(0, -9999, 0) end
        return
    end
    if _G.IsProcessingFruit then return end

    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root or not char.Parent then return end

    if fakePlatform then
        fakePlatform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.2, root.Position.Z)
    end

    -- V29: Tween đang chạy → Heartbeat không được ghi đè CFrame
    if _dodgeTweenActive then return end

    local activeTargetPos = nil
    if CurrentTargetRoot and CurrentTargetRoot.Parent then
        activeTargetPos = Vector3.new(CurrentTargetRoot.Position.X, CurrentTargetRoot.Position.Y + AttackOffset, CurrentTargetRoot.Position.Z)
    elseif TargetCFrame then
        activeTargetPos = TargetCFrame.Position
    end

    if activeTargetPos then
        local currentPos = root.Position
        local dist = (currentPos - activeTargetPos).Magnitude
        local newPos = currentPos
        if dist > 0.5 then
            local step = (activeTargetPos - currentPos).Unit * MoveSpeed * dt
            newPos = step.Magnitude >= dist and activeTargetPos or currentPos + step
        else
            newPos = activeTargetPos
        end

        if IsReadyToAttack then
            local _, currentYaw, _ = root.CFrame:ToOrientation()
            root.CFrame = CFrame.new(newPos) * CFrame.Angles(0, currentYaw, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        else
            local flatDir = Vector3.new(activeTargetPos.X - currentPos.X, 0, activeTargetPos.Z - currentPos.Z)
            if dist > 0.1 and flatDir.Magnitude > 0.01 then
                local targetRot = CFrame.lookAt(newPos, newPos + flatDir.Unit)
                local smoothRot = root.CFrame:Lerp(targetRot, 1 - math.exp(-12 * dt)).Rotation
                root.CFrame = CFrame.new(newPos) * smoothRot
            else
                root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
            end
        end

        if IsReadyToAttack and ZoneState ~= "ABSORBING_CURSE" then
            if hum then root.Velocity = Vector3.new(root.CFrame.LookVector.X * hum.WalkSpeed, 0, root.CFrame.LookVector.Z * hum.WalkSpeed) end
            root.RotVelocity = Vector3.zero
            pcall(function()
                if hum then hum:Move(Vector3.new(0.01, 0, 0.01), false) end
                local footstepEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("footstep")
                if footstepEvent then footstepEvent:FireServer() end
            end)
        end
    end
end)
